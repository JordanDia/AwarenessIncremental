local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BoostConfig = require(ReplicatedStorage.Shared.Configs.BoostConfig)

local BoostService = Knit.CreateService {
    Name = "BoostService",
    Client = {
        MeditateAnywhereBoostChanged = Knit.CreateSignal(), -- (endTime: number)  0 = expired
        MeditationSpeedBoostChanged  = Knit.CreateSignal(), -- (endTime: number)  0 = expired
    },
}

local DataService
local AwarenessService

function BoostService:KnitStart()
    DataService      = Knit.GetService("DataService")
    AwarenessService = Knit.GetService("AwarenessService")

    local function SetupBoosts(player, profile)
        if not profile then return end
        local data = profile.Data
        local now  = os.time()

        -- Meditate Anywhere
        local maSince = now - data.LastMeditateAnywhereBoost
        if maSince < BoostConfig.MeditateAnywhere.Duration then
            -- Boost still active from a previous session
            self:_GiveMeditateAnywhereBoost(player, BoostConfig.MeditateAnywhere.Duration - maSince, data.LastMeditateAnywhereBoost)
        elseif maSince >= BoostConfig.MeditateAnywhere.Cooldown then
            -- Cooldown elapsed, grant fresh boost
            self:_GiveMeditateAnywhereBoost(player, BoostConfig.MeditateAnywhere.Duration)
        end

        -- Meditation Speed
        local msSince = now - data.LastMeditationSpeedBoost
        if msSince < BoostConfig.MeditationSpeed.Duration then
            self:_GiveMeditationSpeedBoost(player, BoostConfig.MeditationSpeed.Duration - msSince, data.LastMeditationSpeedBoost)
        elseif msSince >= BoostConfig.MeditationSpeed.Cooldown then
            self:_GiveMeditationSpeedBoost(player, BoostConfig.MeditationSpeed.Duration)
        end
    end

    DataService.ProfileLoaded:Connect(SetupBoosts)
    for player, profile in DataService.Profiles do
        SetupBoosts(player, profile)
    end
end

-- startedAt: optional, used when restoring a boost from a previous session
function BoostService:_GiveMeditateAnywhereBoost(player: Player, duration: number, startedAt: number?)
    local profile = DataService:GetProfile(player)
    if not profile then return end
    local data = profile.Data
    local now  = os.time()

    local recordedAt = startedAt or now
    data.LastMeditateAnywhereBoost = recordedAt

    local endTime = recordedAt + BoostConfig.MeditateAnywhere.Duration
    AwarenessService:ToggleMeditateAnywhereBoost(player)
    self.Client.MeditateAnywhereBoostChanged:Fire(player, endTime)

    task.delay(duration, function()
        if not player.Parent then return end
        AwarenessService:ToggleMeditateAnywhereBoost(player)
        self.Client.MeditateAnywhereBoostChanged:Fire(player, 0)
    end)
end

function BoostService:_GiveMeditationSpeedBoost(player: Player, duration: number, startedAt: number?)
    local profile = DataService:GetProfile(player)
    if not profile then return end
    local data = profile.Data
    local now  = os.time()

    local recordedAt = startedAt or now
    data.LastMeditationSpeedBoost = recordedAt

    local endTime = recordedAt + BoostConfig.MeditationSpeed.Duration
    AwarenessService:ToggleMeditationSpeedBoost(player)
    self.Client.MeditationSpeedBoostChanged:Fire(player, endTime)

    task.delay(duration, function()
        if not player.Parent then return end
        AwarenessService:ToggleMeditationSpeedBoost(player)
        self.Client.MeditationSpeedBoostChanged:Fire(player, 0)
    end)
end

-- Returns the current end times for all boosts so clients can sync on join
function BoostService.Client:GetBoostEndTimes(player)
    local profile = DataService:GetProfile(player)
    if not profile then return { MeditateAnywhere = 0, MeditationSpeed = 0 } end
    local data = profile.Data
    return {
        MeditateAnywhere = data.LastMeditateAnywhereBoost + BoostConfig.MeditateAnywhere.Duration,
        MeditationSpeed  = data.LastMeditationSpeedBoost  + BoostConfig.MeditationSpeed.Duration,
    }
end

return BoostService
