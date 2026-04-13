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
}

-- Upgrades that are only auto-bought when the given unlock is active
local AUTO_BUY_GATED = {
    { unlock = "CrystalCollection", upgrades = {
        "CrystalValue",
        "CrystalSpeed",
        "MaxCrystals",
        "CrystalMultiplier",
        "CrystalAwarenessMultiplier",
        "CrystalRebirthMultiplier",
    }},
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
    self.UpgradeTreeService = Knit.GetService("UpgradeTreeService")

    local function onProfileLoaded(player)
        self.PlayerAlive[player] = true
        self:RestoreRewards(player)
        -- UnlockService:Unlock returns early if already flagged, so explicitly re-unlock
        -- Tree2's root node here to ensure it's visible after any awakening + rejoin.
        if self:GetLevel(player) >= 1 then
            self.UpgradeTreeService:UnlockTreeRoot(player, "Tree2")
        end
    end

    self.DataService.ProfileLoaded:Connect(onProfileLoaded)

    for player in self.DataService.Profiles do
        onProfileLoaded(player)
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
    local entry = AwakeningConfig.Levels[level + 1]
    if not entry then return math.huge end
    return entry.Cost
end

function AwakeningService:CanAwaken(player)
    local level = self:GetLevel(player)
    if level >= AwakeningConfig.MaxLevel then return false end
    local cost = self:GetNextCost(player)
    if cost == math.huge then return false end
    return self.AwarenessService:GetAwareness(player) >= cost
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

    -- Reset upgrade boards back to level 1
    local upgradeResets = {
        -- Awareness
        "AwarenessPerMeditation",
        "MeditationSpeed",
        -- Rebirths
        "MultiplyAwarenessPerMeditation",
        "MultiplyRebirthAmount",
        "IncreaseDeepThoughtChance",
        -- Crystals
        "CrystalValue",
        "CrystalSpeed",
        "MaxCrystals",
        "CrystalMultiplier",
        "CrystalAwarenessMultiplier",
        "CrystalRebirthMultiplier",
        -- Astral Echoes / Veil
        "AstralEchoValue",
        "VeilDuration",
        "AstralEchoMultiplyAwareness",
        "AstralEchoMultiplyRebirth",
    }
    for _, upgradeId in upgradeResets do
        self.UpgradeService:ResetUpgrade(player, upgradeId)
    end

    -- Reset both upgrade trees so the player must re-buy them
    self.UpgradeTreeService:ResetTree(player, "Tree1")
    self.UpgradeTreeService:ResetTree(player, "Tree2")

    -- Re-unlock Tree1's root (always available) since ResetTree wiped it
    self.UpgradeTreeService:UnlockTreeRoot(player, "Tree1")

    -- Revoke unlocks granted by tree nodes (player must re-earn them)
    self.UnlockService:Revoke(player, "CrystalCollection")

    -- Advance level
    profile.Data.AwakeningLevel = (profile.Data.AwakeningLevel or 0) + 1
    local newLevel = profile.Data.AwakeningLevel

    -- Grant reward for the new level
    local levelConfig = AwakeningConfig.Levels[newLevel]
    if levelConfig then
        self:_GrantReward(player, newLevel, levelConfig.Reward)
    end

    -- For awakenings level 2+, the level-1 reward already permanently gave Tree2.
    -- Re-unlock its root since ResetTree just wiped it.
    if newLevel >= 2 then
        self.UpgradeTreeService:UnlockTreeRoot(player, "Tree2")
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
            for _, gate in AUTO_BUY_GATED do
                if self.UnlockService:IsUnlocked(player, gate.unlock) then
                    for _, upgradeId in gate.upgrades do
                        self.UpgradeService:AutoBuyUpgradeFree(player, upgradeId)
                    end
                end
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
