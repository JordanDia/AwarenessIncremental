local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService  = game:GetService("AnalyticsService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TutorialConfig = require(ReplicatedStorage.Shared.Configs.TutorialConfig)
local STAGES = TutorialConfig.Stages

local Quicknum = require(ReplicatedStorage.Shared.Modules.Quicknum)

local TutorialService = Knit.CreateService {
    Name = "TutorialService",
    Client = {
        -- Fires on join and whenever the stage advances
        -- (stageIndex: number, stageConfig: table | nil, progress: number)
        -- stageConfig is nil when all stages are complete
        StageChanged    = Knit.CreateSignal(),
        -- Fires whenever the progress value updates for the current stage
        ProgressUpdated = Knit.CreateSignal(),
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

function TutorialService:_GetStage(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.TutorialStage or 1
end

function TutorialService:_IsComplete(player)
    return self:_GetStage(player) > #STAGES
end

-- Returns the current progress value (0..Goal) for the player's current stage
function TutorialService:_GetProgress(player)
    local stage = STAGES[self:_GetStage(player)]
    if not stage then return 0 end

    if stage.Type == "Awareness" then
        return math.min(Quicknum.toNumber(self.AwarenessService:GetAwareness(player)), stage.Goal)

    elseif stage.Type == "UpgradeLevel" then
        return math.min(self.UpgradeService:GetLevel(player, stage.UpgradeId), stage.Goal)

    elseif stage.Type == "RebirthCount" then
        local profile = self.DataService:GetProfile(player)
        return math.min(profile and profile.Data.RebirthsTotal or 0, stage.Goal)

    elseif stage.Type == "TreeNode" then
        local purchased = self.UpgradeTreeService:IsNodePurchased(player, stage.TreeName, stage.NodeId)
        return purchased and 1 or 0

    end

    return 0
end

-- Advance to the next stage if the current one is satisfied
function TutorialService:_CheckAdvance(player)
    if self:_IsComplete(player) then return end

    local stageIndex = self:_GetStage(player)
    local stage = STAGES[stageIndex]
    if not stage then return end

    local progress = self:_GetProgress(player)

    -- Fire progress update
    self.Client.ProgressUpdated:Fire(player, progress, stage.Goal)

    -- Check completion
    if progress >= stage.Goal then
        local profile = self.DataService:GetProfile(player)
        profile.Data.TutorialStage = stageIndex + 1

        local nextStage = STAGES[stageIndex + 1]
        self.Client.StageChanged:Fire(player, stageIndex + 1, nextStage, 0)
    end
end

-- Fast-forward through any stages the player already satisfies, then broadcast
function TutorialService:_AdvanceAndBroadcast(player)
    -- Keep advancing while the current stage is already met
    while not self:_IsComplete(player) do
        local stageIndex = self:_GetStage(player)
        local stage = STAGES[stageIndex]
        if not stage then break end
        if self:_GetProgress(player) >= stage.Goal then
            local profile = self.DataService:GetProfile(player)
            profile.Data.TutorialStage += 1
            -- Stage N complete = funnel step N+1 (step 1 is "Joined Game")
            pcall(function()
                AnalyticsService:LogOnboardingFunnelStepEvent(player, stageIndex + 1, stage.Title)
            end)
        else
            break
        end
    end

    local stageIndex = self:_GetStage(player)
    local stage = STAGES[stageIndex]
    local progress = not self:_IsComplete(player) and self:_GetProgress(player) or 0
    self.Client.StageChanged:Fire(player, stageIndex, stage, progress)
    if stage then
        self.Client.ProgressUpdated:Fire(player, progress, stage.Goal)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- KnitStart
-- ─────────────────────────────────────────────────────────────────────────────

function TutorialService:KnitStart()
    self.DataService         = Knit.GetService("DataService")
    self.AwarenessService    = Knit.GetService("AwarenessService")
    self.UpgradeService      = Knit.GetService("UpgradeService")
    self.RebirthService      = Knit.GetService("RebirthService")
    self.UpgradeTreeService  = Knit.GetService("UpgradeTreeService")

    -- Send current stage to client on load.
    -- task.defer ensures all other ProfileLoaded handlers (e.g. AwarenessService)
    -- have run first so GetAwareness returns the correct stored value.
    self.DataService.ProfileLoaded:Connect(function(player)
        -- Step 1: only log the very first time this player ever joins
        local profile = self.DataService:GetProfile(player)
        if profile and not profile.Data.Analytics_JoinedGame then
            profile.Data.Analytics_JoinedGame = true
            pcall(function()
                AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Joined Game")
            end)
        end
        task.defer(function()
            self:_AdvanceAndBroadcast(player)
        end)
    end)

    for player in self.DataService.Profiles do
        task.defer(function()
            self:_AdvanceAndBroadcast(player)
        end)
    end

    -- Awareness changed
    self.AwarenessService.AwarenessChanged:Connect(function(player, _)
        if self:_IsComplete(player) then return end
        local stage = STAGES[self:_GetStage(player)]
        if stage and stage.Type == "Awareness" then
            self:_AdvanceAndBroadcast(player)
        end
    end)

    -- Upgrade purchased — use _AdvanceAndBroadcast so that if the purchased upgrade
    -- satisfies the current stage AND the next stage is already met, we cascade through.
    self.UpgradeService.UpgradeUpdated:Connect(function(player, upgradeId, _)
        if self:_IsComplete(player) then return end
        local stage = STAGES[self:_GetStage(player)]
        if not stage then return end
        if stage.Type == "UpgradeLevel" and stage.UpgradeId == upgradeId then
            self:_AdvanceAndBroadcast(player)
        end
    end)

    -- Rebirth performed
    self.RebirthService.RebirthsChanged:Connect(function(player, _)
        if self:_IsComplete(player) then return end
        local stage = STAGES[self:_GetStage(player)]
        if stage and stage.Type == "RebirthCount" then
            self:_AdvanceAndBroadcast(player)
        end
    end)

    -- Tree node purchased
    self.UpgradeTreeService.NodePurchased:Connect(function(player, treeName, nodeId)
        if self:_IsComplete(player) then return end
        local stage = STAGES[self:_GetStage(player)]
        if stage and stage.Type == "TreeNode"
            and stage.TreeName == treeName
            and stage.NodeId == nodeId
        then
            self:_AdvanceAndBroadcast(player)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Client methods
-- ─────────────────────────────────────────────────────────────────────────────

function TutorialService.Client:GetCurrentStage(player)
    local stageIndex = self.Server:_GetStage(player)
    local stage = STAGES[stageIndex]
    local progress = not self.Server:_IsComplete(player) and self.Server:_GetProgress(player) or 0
    return stageIndex, stage, progress
end

return TutorialService
