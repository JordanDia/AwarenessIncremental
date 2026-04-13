local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local QuestConfig = require(ReplicatedStorage.Shared.Configs.QuestConfig)

local RESET_INTERVAL = 86400 -- 24 hours in seconds

local QuestService = Knit.CreateService {
    Name = "QuestService",
    Client = {
        QuestProgressUpdated = Knit.CreateSignal(), -- (questId, progress, claimed)
        QuestsReset          = Knit.CreateSignal(), -- () all quests wiped
    }
}

local function getQuestData(profile)
    return profile.Data.DailyQuests
end

function QuestService:_getProgress(player, questId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return getQuestData(profile).Progress[questId] or 0
end

function QuestService:_isClaimed(player, questId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end
    return getQuestData(profile).Claimed[questId] == true
end

function QuestService:_addProgress(player, questId, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    -- Find quest config
    local questCfg
    for _, q in QuestConfig do
        if q.Id == questId then questCfg = q break end
    end
    if not questCfg then return end

    local data = getQuestData(profile)
    if data.Claimed[questId] then return end -- already claimed, ignore

    local current = data.Progress[questId] or 0
    local newProgress = math.min(current + amount, questCfg.Goal)
    data.Progress[questId] = newProgress

    if newProgress >= questCfg.Goal then
        -- Auto-claim immediately when goal is reached
        self:ClaimQuest(player, questId)
    else
        self.Client.QuestProgressUpdated:Fire(player, questId, newProgress, false)
    end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Reset logic
-- ────────────────────────────────────────────────────────────────────────────

function QuestService:CheckReset(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local data = getQuestData(profile)

    if os.time() - (data.LastReset or 0) >= RESET_INTERVAL then
        data.LastReset = os.time()
        data.Progress  = {}
        data.Claimed   = {}
        self.Client.QuestsReset:Fire(player)
    end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Public API
-- ────────────────────────────────────────────────────────────────────────────

-- Returns a list of { config, progress, claimed, timeUntilReset }
function QuestService:GetQuests(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return {} end
    local data = getQuestData(profile)
    local timeUntilReset = math.max(0, RESET_INTERVAL - (os.time() - (data.LastReset or 0)))

    local result = {}
    for _, q in QuestConfig do
        table.insert(result, {
            Id           = q.Id,
            Title        = q.Title,
            Description  = q.Description,
            Goal         = q.Goal,
            Format       = q.Format,
            Reward       = q.Reward,
            Progress     = data.Progress[q.Id] or 0,
            Claimed      = data.Claimed[q.Id] == true,
            TimeUntilReset = timeUntilReset,
        })
    end
    return result
end

function QuestService:ClaimQuest(player, questId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end

    local questCfg
    for _, q in QuestConfig do
        if q.Id == questId then questCfg = q break end
    end
    if not questCfg then return false end

    local data = getQuestData(profile)
    if data.Claimed[questId] then return false end

    local progress = data.Progress[questId] or 0
    if progress < questCfg.Goal then return false end

    -- Grant reward
    local reward = questCfg.Reward
    if reward.Type == "Multiplier" then
        local source = "DailyQuest_" .. questId
        self.MultiplierService:SetSource(player, reward.Stat, source, reward.Value)
        task.delay(reward.Duration, function()
            if player.Parent then -- player still in game
                self.MultiplierService:SetSource(player, reward.Stat, source, 1)
            end
        end)
    end

    data.Claimed[questId] = true
    -- Pass the buff duration so the client can start a countdown
    local duration = (reward.Type == "Multiplier") and reward.Duration or 0
    self.Client.QuestProgressUpdated:Fire(player, questId, progress, true, duration)
    return true
end

-- ────────────────────────────────────────────────────────────────────────────
-- Knit lifecycle
-- ────────────────────────────────────────────────────────────────────────────

function QuestService:KnitStart()
    self.DataService       = Knit.GetService("DataService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.AwarenessService  = Knit.GetService("AwarenessService")
    self.CrystalService    = Knit.GetService("CrystalService")
    self.RebirthService    = Knit.GetService("RebirthService")

    -- Check reset on login
    self.DataService.ProfileLoaded:Connect(function(player)
        self:CheckReset(player)
    end)

    -- Periodic reset check (every minute)
    task.spawn(function()
        while true do
            task.wait(60)
            for player in self.DataService.Profiles do
                self:CheckReset(player)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        -- nothing to clean up, profile handles persistence
    end)

    -- Meditation tracking (MeditationTick fires (player, interval) each tick)
    self.AwarenessService.MeditationTick:Connect(function(player, interval)
        self:_addProgress(player, "Meditate", interval)
    end)

    -- Crystal collection
    -- Count individual crystal touches, not currency value
    self.CrystalService.CrystalCollected:Connect(function(player, _amount)
        self:_addProgress(player, "CollectCrystals", 1)
    end)

    -- Rebirths
    self.RebirthService.RebirthPerformed:Connect(function(player, count)
        self:_addProgress(player, "Rebirth", count)
    end)

    -- Awareness earned
    self.AwarenessService.AwarenessEarned:Connect(function(player, amount)
        self:_addProgress(player, "EarnAwareness", amount)
    end)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Client methods
-- ────────────────────────────────────────────────────────────────────────────

function QuestService.Client:GetQuests(player)
    return self.Server:GetQuests(player)
end

function QuestService.Client:ClaimQuest(player, questId)
    return self.Server:ClaimQuest(player, questId)
end

return QuestService
