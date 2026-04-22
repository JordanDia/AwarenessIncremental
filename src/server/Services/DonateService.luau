local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService   = game:GetService("DataStoreService")
local Players            = game:GetService("Players")

local Knit           = require(ReplicatedStorage.Packages.Knit)
local Signal         = require(ReplicatedStorage.Packages.Signal)
local GamepassConfig = require(ReplicatedStorage.Shared.Configs.GamepassConfig)
local DonateConfig   = require(ReplicatedStorage.Shared.Configs.DonateConfig)

local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- Cache of passId -> price in Robux, populated in KnitStart
local gamepassPrices = {}

local DonateService = Knit.CreateService {
    Name = "DonateService",
    Client = {
        RobuxSpentAdded = Knit.CreateSignal(), -- fires (amount) to the spender
    },
}

-- Fires (player, amount) whenever RobuxSpent is incremented
DonateService.HasRobuxSpentAdded = Signal.new()
DonateService.CustomProductHandlers = {} -- [productId] = function(player, dataService)

function DonateService:RegisterProductHandler(productId: number, handler)
    self.CustomProductHandlers[productId] = handler
end

-- Build grant handlers from DonateConfig (keyed by ProductId)
local grantPurchaseHandlerByProductId = {}
for _, product in ipairs(DonateConfig) do
    local robux = product.Robux
    grantPurchaseHandlerByProductId[product.ProductId] = function(player, dataService)
        -- Must NOT yield — access Profiles directly
        local profile = dataService.Profiles[player]
        if profile then
            profile.Data.RobuxSpent = (profile.Data.RobuxSpent or 0) + robux
            return true
        end
        return nil
    end
end

function DonateService:AddRobuxSpent(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.RobuxSpent = (profile.Data.RobuxSpent or 0) + amount
    self.HasRobuxSpentAdded:Fire(player, amount)
    self.Client.RobuxSpentAdded:Fire(player, amount)
end

function DonateService:KnitStart()
    self.DataService = Knit.GetService("DataService")

    -- Cache gamepass prices
    for _, pass in ipairs(GamepassConfig) do
        task.spawn(function()
            local ok, info = pcall(function()
                return MarketplaceService:GetProductInfo(pass.PassId, Enum.InfoType.GamePass)
            end)
            if ok and info and info.PriceInRobux then
                gamepassPrices[pass.PassId] = info.PriceInRobux
            end
        end)
    end

    -- Award RobuxSpent when a gamepass is purchased
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
        if not wasPurchased then return end
        local price = gamepassPrices[passId]
        if price and price > 0 then
            self:AddRobuxSpent(player, price)
        end
    end)

    -- ProcessReceipt following the official Roblox docs pattern
    local function processReceipt(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

        local handler = grantPurchaseHandlerByProductId[receiptInfo.ProductId]
            or self.CustomProductHandlers[receiptInfo.ProductId]
        if not handler then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local success, result = pcall(function()
            return purchaseHistoryStore:UpdateAsync(tostring(receiptInfo.PurchaseId), function(alreadyGranted)
                if alreadyGranted then
                    -- Already processed; do nothing but acknowledge
                    return true
                end

                if player and player.Parent == Players then
                    local granted = handler(player, self.DataService)
                    if granted then
                        -- Fire signal (safe outside UpdateAsync callback via task.defer)
                        task.defer(function()
                            local profile = self.DataService.Profiles[player]
                            if profile then
                                local robux = 0
                                for _, product in ipairs(DonateConfig) do
                                    if product.ProductId == receiptInfo.ProductId then
                                        robux = product.Robux
                                        break
                                    end
                                end
                                if robux > 0 then
                                    self.HasRobuxSpentAdded:Fire(player, robux)
                                    self.Client.RobuxSpentAdded:Fire(player, robux)
                                end
                            end
                        end)
                        return true
                    end
                end

                -- Player not available yet; do not mark as processed
                return nil
            end)
        end)

        if not success then
            warn("[DonateService] ProcessReceipt UpdateAsync failed:", result)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    MarketplaceService.ProcessReceipt = processReceipt
end

-- Client RPC: prompt a developer product purchase
function DonateService.Client:PromptDonate(player, productId)
    MarketplaceService:PromptProductPurchase(player, productId)
end

return DonateService
