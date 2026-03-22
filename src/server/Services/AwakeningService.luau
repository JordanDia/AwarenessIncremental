local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local AwakeningConfig = require(ReplicatedStorage.Shared.Configs.AwakeningConfig)

-- All upgrade IDs that are auto-bought for free at Awakening Level 5
local AUTO_BUY_UPGRADES = {
    "AwarenessPerMeditation",
    "MeditationSpeed",
    "MultiplyAwarenessPerMeditation",
    "MultiplyRebirthAmount",
    "IncreaseDeepThoughtChance",
    "CrystalValue",
    "CrystalSpeed",
    "MaxCrystals",
    "CrystalMultiplier",
    "CrystalAwarenessMultiplier",
    "CrystalRebirthMultiplier",
}

local AwakeningService = Knit.CreateService {
    Name = "AwakeningService",
    Client = {
        AwakeningLevelChanged = Knit.CreateSignal(), -- fires (newLevel: number)
    }
}

AwakeningService.AwakeningLevelChanged = Signal.new() -- fires (player, newLevel)

-- [player] = true while the player is connected; set to nil on leave to stop loops
AwakeningService.PlayerAlive = {}

-- [player] = { autoRebirth = bool, autoBuy = bool } — prevents duplicate loops
AwakeningService.ActiveLoops = {}

function AwakeningService:KnitStart()
    self.DataService        = Knit.GetService("DataService")
    self.AwarenessService   = Knit.GetService("AwarenessService")
    self.RebirthService     = Knit.GetService("RebirthService")
    self.CrystalService     = Knit.GetService("CrystalService")
    self.AstralEchoService  = Knit.GetService("AstralEchoService")
    self.MultiplierService  = Knit.GetService("MultiplierService")
    self.UpgradeService     = Knit.GetService("UpgradeService")
    self.UnlockService      = Knit.GetService("UnlockService")

    self.DataService.ProfileLoaded:Connect(function(player)
        self.PlayerAlive[player] = true
        self:RestoreRewards(player)
    end)

    for player in self.DataService.Profiles do
        self.PlayerAlive[player] = true
        self:RestoreRewards(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        self.PlayerAlive[player] = nil
        self.ActiveLoops[player] = nil
    end)

    self.AwakeningLevelChanged:Connect(function(player, level)
        self.Client.AwakeningLevelChanged:Fire(player, level)
    end)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Public API
-- ────────────────────────────────────────────────────────────────────────────

function AwakeningService:GetLevel(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.AwakeningLevel or 0
end

function AwakeningService:GetNextCost(player)
    local level = self:GetLevel(player)
    if level >= AwakeningConfig.MaxLevel then return math.huge end
    return AwakeningConfig.Levels[level + 1].Cost
end

function AwakeningService:CanAwaken(player)
    local level = self:GetLevel(player)
    if level >= AwakeningConfig.MaxLevel then return false end
    return self.AwarenessService:GetAwareness(player) >= self:GetNextCost(player)
end

-- Prestige-reset Awareness / Rebirths / Crystals / AstralEchoes, advance level, grant reward.
function AwakeningService:Awaken(player)
    if not self:CanAwaken(player) then return false end

    local profile = self.DataService:GetProfile(player)
    if not profile then return false end

    -- Prestige reset (awareness was already >= cost, just zero everything)
    self.AwarenessService:SetAwareness(player, 0)
    self.RebirthService:ResetRebirths(player)
    self.CrystalService:ResetCrystals(player)
    self.AstralEchoService:ResetEchoes(player)

    -- Advance level
    profile.Data.AwakeningLevel = (profile.Data.AwakeningLevel or 0) + 1
    local newLevel = profile.Data.AwakeningLevel

    -- Grant reward for the new level
    local levelConfig = AwakeningConfig.Levels[newLevel]
    if levelConfig then
        self:_GrantReward(player, newLevel, levelConfig.Reward)
    end

    self.AwakeningLevelChanged:Fire(player, newLevel)

    print(`{player.Name} awakened to level {newLevel}`)
    return true
end

-- Re-apply all rewards for all already-achieved levels (called on login).
function AwakeningService:RestoreRewards(player)
    local level = self:GetLevel(player)
    for i = 1, level do
        local levelConfig = AwakeningConfig.Levels[i]
        if levelConfig then
            self:_GrantReward(player, i, levelConfig.Reward)
        end
    end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Internal
-- ────────────────────────────────────────────────────────────────────────────

function AwakeningService:_GrantReward(player, level, reward)
    if reward.Type == "Unlock" then
        self.UnlockService:Unlock(player, reward.Value)

    elseif reward.Type == "Multiplier" then
        local source = "Awakening_" .. level
        for _, stat in reward.Stats do
            self.MultiplierService:SetSource(player, stat, source, reward.Value)
        end

    elseif reward.Type == "DynamicEcho" then
        -- AstralEcho multiplier = current awakening level (updates on each restore/awaken)
        local currentLevel = self:GetLevel(player)
        self.MultiplierService:SetSource(player, "AstralEcho", "Awakening", math.max(1, currentLevel))

    elseif reward.Type == "AutoRebirth" then
        self:_StartAutoRebirth(player, reward.Rate)

    elseif reward.Type == "AutoBuy" then
        self:_StartAutoBuy(player)
    end
end

-- Adds `rate` × current rebirths to the player's rebirth count every second.
function AwakeningService:_StartAutoRebirth(player, rate)
    local loops = self.ActiveLoops[player]
    if loops and loops.autoRebirth then return end
    if not loops then
        self.ActiveLoops[player] = {}
        loops = self.ActiveLoops[player]
    end
    loops.autoRebirth = true

    task.spawn(function()
        while self.PlayerAlive[player] do
            local rebirths = self.RebirthService:GetRebirths(player)
            local gain = if rebirths > 0 then math.max(2, math.round(rebirths * rate)) else 0
            self.RebirthService:AddRebirths(player, gain)
            task.wait(1)
        end
    end)
end

-- Buys one level of every upgrade for free every second.
function AwakeningService:_StartAutoBuy(player)
    local loops = self.ActiveLoops[player]
    if loops and loops.autoBuy then return end
    if not loops then
        self.ActiveLoops[player] = {}
        loops = self.ActiveLoops[player]
    end
    loops.autoBuy = true

    task.spawn(function()
        while self.PlayerAlive[player] do
            for _, upgradeId in AUTO_BUY_UPGRADES do
                self.UpgradeService:AutoBuyUpgradeFree(player, upgradeId)
            end
            task.wait(1)
        end
    end)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Client methods
-- ────────────────────────────────────────────────────────────────────────────

function AwakeningService.Client:GetLevel(player)
    return self.Server:GetLevel(player)
end

function AwakeningService.Client:GetNextCost(player)
    return self.Server:GetNextCost(player)
end

function AwakeningService.Client:CanAwaken(player)
    return self.Server:CanAwaken(player)
end

function AwakeningService.Client:Awaken(player)
    return self.Server:Awaken(player)
end

return AwakeningService
