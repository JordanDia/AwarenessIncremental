local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped
local RaidShopConfig = require(ReplicatedStorage.Shared.Configs.RaidShopConfig)

local RaidShopFrame = require(ReplicatedStorage.UI.components.RaidShopFrame)

local RaidShopController = Knit.CreateController {
    Name = "RaidShopController"
}

function RaidShopController:KnitStart()
    self._IsOpen = false
    self._Visible = nil
    self._Scope = nil
    self._Fragments = nil
    self._Stock = nil
    self._NextRefreshTime = nil
    self._BoostLevels = nil

    task.spawn(function()
        self:_MountUI()
        self:_SetupPrompt()
    end)
end

function RaidShopController:_MountUI()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local RaidShopService = Knit.GetService("RaidShopService")

    self._Scope = scoped(Fusion, {
        RaidShopFrame = RaidShopFrame,
    })

    self._Visible = self._Scope:Value(false)
    self._Fragments = self._Scope:Value(RaidShopService:GetFragments())
    self._NextRefreshTime = self._Scope:Value(RaidShopService:GetNextRefreshTime())

    local initialStock = RaidShopService:GetStock()
    self._Stock = {}
    for _, item in RaidShopConfig.Items do
        self._Stock[item.Id] = self._Scope:Value(initialStock[item.Id] or 0)
    end

    local initialLevels = RaidShopService:GetBoostLevels()
    self._BoostLevels = {}
    for _, item in RaidShopConfig.Items do
        self._BoostLevels[item.Id] = self._Scope:Value(initialLevels[item.Id] or 0)
    end

    RaidShopService.FragmentsChanged:Connect(function(newFragments)
        self._Fragments:set(newFragments)
    end)

    RaidShopService.StockChanged:Connect(function(stock)
        for itemId, amount in stock do
            if self._Stock[itemId] then
                self._Stock[itemId]:set(amount)
            end
        end
    end)

    RaidShopService.RefreshTimeChanged:Connect(function(time)
        self._NextRefreshTime:set(time)
    end)

    RaidShopService.BoostLevelChanged:Connect(function(itemId, newLevel)
        if self._BoostLevels[itemId] then
            self._BoostLevels[itemId]:set(newLevel)
        end
    end)

    self._Scope:New "ScreenGui" {
        Name = "RaidShopGui",
        Parent = playerGui,
        ResetOnSpawn = false,

        [Fusion.Children] = {
            self._Scope:RaidShopFrame {
                Visible = self._Visible,
                Fragments = self._Fragments,
                Stock = self._Stock,
                BoostLevels = self._BoostLevels,
                NextRefreshTime = self._NextRefreshTime,
                OnClose = function()
                    self:Close()
                end,
                OnPurchase = function(itemId)
                    RaidShopService:Purchase(itemId)
                end,
            },
        },
    }
end

function RaidShopController:_SetupPrompt()
    local promptPart = workspace:WaitForChild("RaidShopPromptPart")
    local prompt = promptPart:WaitForChild("ProximityPrompt")

    prompt.Triggered:Connect(function()
        self._IsOpen = not self._IsOpen
        self._Visible:set(self._IsOpen)
    end)
end

function RaidShopController:Close()
    self._IsOpen = false
    self._Visible:set(false)
end

return RaidShopController