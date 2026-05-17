local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local RaidShopConfig = require(ReplicatedStorage.Shared.Configs.RaidShopConfig)

local RaidShopService = Knit.CreateService {
    Name = "RaidShopService",
    Client = {
        StockChanged = Knit.CreateSignal(),
        RefreshTimeChanged = Knit.CreateSignal(),
        BoostLevelChanged = Knit.CreateSignal(),
        FragmentsChanged = Knit.CreateSignal(),
    },

    Stock = {},
    NextRefreshTime = 0,
}

local DataService
local MultiplierService

function RaidShopService:KnitStart()
    DataService = Knit.GetService("DataService")
    MultiplierService = Knit.GetService("MultiplierService")

    self:RefreshStock()
    task.spawn(function()
        self:RefreshLoop()
    end)

    DataService.ProfileLoaded:Connect(function(player, profile)
        self:InitPlayerMultipliers(player, profile.Data)
    end)

    for player, profile in DataService.Profiles do
        self:InitPlayerMultipliers(player, profile.Data)
    end
end

function RaidShopService:GetFragments(player)
    local data = DataService:GetData(player)
    if not data then return 0 end
    return data.Fragments or 0
end

function RaidShopService:AddFragments(player, amount)
    local data = DataService:GetData(player)
    if not data then return 0 end
    data.Fragments = (data.Fragments or 0) + amount
    self.Client.FragmentsChanged:Fire(player, data.Fragments)
    return data.Fragments
end

function RaidShopService:GetBoostLevel(player, boostId)
    local data = DataService:GetData(player)
    if not data then return 0 end
    return data.RaidShopBoosts[boostId] or 0
end

function RaidShopService:AddBoostLevel(player, boostId, amount)
    local data = DataService:GetData(player)
    if not data then return 0 end
    local current = data.RaidShopBoosts[boostId] or 0
    data.RaidShopBoosts[boostId] = current + amount
    return data.RaidShopBoosts[boostId]
end

function RaidShopService:RefreshLoop()
    while true do
        local now = os.time()
        if now >= self.NextRefreshTime then
            self:RefreshStock()
        end
        task.wait(1)
    end
end

function RaidShopService:RefreshStock()
    for _, item in RaidShopConfig.Items do
        self.Stock[item.Id] = RaidShopConfig.DefaultStock
    end
    self.NextRefreshTime = os.time() + RaidShopConfig.RefreshInterval
    self.Client.StockChanged:FireAll(self.Stock)
    self.Client.RefreshTimeChanged:FireAll(self.NextRefreshTime)
end

function RaidShopService:Purchase(player, itemId)
    local item = nil
    for _, i in RaidShopConfig.Items do
        if i.Id == itemId then
            item = i
            break
        end
    end

    if not item then
        return false, "Invalid item"
    end

    if (self.Stock[itemId] or 0) <= 0 then
        return false, "Out of stock"
    end

    local fragments = self:GetFragments(player)
    if fragments < item.Cost then
        return false, "Not enough fragments"
    end

    local currentLevel = self:GetBoostLevel(player, itemId)
    if currentLevel >= item.MaxLevel then
        return false, "Max level reached"
    end

    self:AddFragments(player, -item.Cost)
    local newLevel = self:AddBoostLevel(player, itemId, 1)

    self.Stock[itemId] -= 1
    self.Client.StockChanged:FireAll(self.Stock)

    local multiplier = 1 + (newLevel * RaidShopConfig.BoostMultiplierPerLevel)
    MultiplierService:SetSource(player, item.Stat, "RaidShop", multiplier)

    self.Client.BoostLevelChanged:Fire(player, itemId, newLevel)

    return true, newLevel
end

function RaidShopService:InitPlayerMultipliers(player)
    for _, item in RaidShopConfig.Items do
        local level = self:GetBoostLevel(player, item.Id)
        if level > 0 then
            local multiplier = 1 + (level * RaidShopConfig.BoostMultiplierPerLevel)
            MultiplierService:SetSource(player, item.Stat, "RaidShop", multiplier)
        end
    end
end

function RaidShopService.Client:GetStock(player)
    return self.Server.Stock
end

function RaidShopService.Client:GetNextRefreshTime(player)
    return self.Server.NextRefreshTime
end

function RaidShopService.Client:Purchase(player, itemId)
    return self.Server:Purchase(player, itemId)
end

function RaidShopService.Client:GetBoostLevels(player)
    local levels = {}
    for _, item in RaidShopConfig.Items do
        levels[item.Id] = self.Server:GetBoostLevel(player, item.Id)
    end
    return levels
end

function RaidShopService.Client:GetFragments(player)
    return self.Server:GetFragments(player)
end

return RaidShopService
