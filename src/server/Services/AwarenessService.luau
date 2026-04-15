-- ServerScriptService/Services/AwarenessService.lua
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService  = game:GetService("AnalyticsService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local BoostConfig = require(ReplicatedStorage.Shared.Configs.BoostConfig)

local MEDITATION_RADIUS = 60 -- studs

local AwarenessService = Knit.CreateService {
    Name = "AwarenessService",
    Client = {
        AwarenessChanged      = Knit.CreateSignal(),
        AwarenessTotalChanged = Knit.CreateSignal(),
        DeepThoughtEffect     = Knit.CreateSignal(),
        MeditationStarted     = Knit.CreateSignal(),
        MeditationStopped     = Knit.CreateSignal(),
    }
}

AwarenessService.DataService = nil
AwarenessService.UpgradeService = nil
AwarenessService.LevelService = nil
AwarenessService.MultiplierService = nil

AwarenessService.AwarenessChanged = Signal.new() -- Fires (player, newAwareness)
AwarenessService.MeditationTick = Signal.new()  -- Fires (player, interval) while meditating
AwarenessService.AwarenessEarned = Signal.new() -- Fires (player, amount) on each earn
AwarenessService._meditateAnywhereActive    = {}
AwarenessService._meditationSpeedBoostActive = {}

function AwarenessService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UpgradeService = Knit.GetService("UpgradeService")
    self.LevelService = Knit.GetService("LevelService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.GamepassService = Knit.GetService("GamepassService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if not profile then return end
        self:InitializePlayer(player, profile)
    end)

    -- Initialize players already in-game
    for player, profile in self.DataService.Profiles do
        self:InitializePlayer(player, profile)
    end

    Players.PlayerRemoving:Connect(function(player)
        self._meditateAnywhereActive[player]     = nil
        self._meditationSpeedBoostActive[player] = nil
    end)

    self.AwarenessChanged:Connect(function(player, newAwareness, isDeepThought)
        self.Client.AwarenessChanged:Fire(player, newAwareness, isDeepThought)
    end)
   
end

function AwarenessService:InitializePlayer(player, profile)
    --print(`Awareness for player {player.Name} is {profile.Data.Awareness}`)

    local randomGenerator = Random.new(os.clock())
    local meditationGrounds = workspace:WaitForChild("Map"):WaitForChild("MeditationGrounds")

    local wasInRange = false

    task.spawn(function()
        while player.Parent do
            local interval = self.UpgradeService:GetUpgradeEffect(player, "MeditationSpeed")
            if self._meditationSpeedBoostActive[player] then
                interval = interval / BoostConfig.MeditationSpeed.Multiplier
            end

            -- Proximity check (bypassed if Meditate Anywhere is active)
            local inRange = self._meditateAnywhereActive[player] == true
            if not inRange then
                local character = player.Character
                if character then
                    local root = character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local groundsPos = meditationGrounds:IsA("BasePart")
                            and meditationGrounds.Position
                            or meditationGrounds:GetPivot().Position
                        inRange = (root.Position - groundsPos).Magnitude <= MEDITATION_RADIUS
                    end
                end
            end

            if inRange ~= wasInRange then
                if inRange then
                    self.Client.MeditationStarted:Fire(player)
                else
                    self.Client.MeditationStopped:Fire(player)
                end
                wasInRange = inRange
            end

            if inRange then
                local increment = self.UpgradeService:GetUpgradeEffect(player, "AwarenessPerMeditation")
                local multiplier = self.MultiplierService:GetMultiplier(player, "Awareness")
                local finalIncrement = math.round(increment * multiplier)

                -- "Deep Thought Chance"
                local deepThoughtChance = self.UpgradeService:GetUpgradeEffect(player, "IncreaseDeepThoughtChance")
                local isDeepThought = false
                if randomGenerator:NextInteger(1, 100) < deepThoughtChance then
                    finalIncrement *= 3
                    self.Client.DeepThoughtEffect:Fire(player)
                    isDeepThought = true
                end

                AwarenessService:AddAwareness(player, finalIncrement, isDeepThought)
                self.LevelService:AddXP(player, 1)
                AwarenessService.MeditationTick:Fire(player, interval)
            end

            task.wait(interval)
        end

        -- Player left the game; ensure stopped signal fires if they were meditating
        if wasInRange then
            self.Client.MeditationStopped:Fire(player)
        end
    end)
end

-- Get Awareness for a player
function AwarenessService:GetAwareness(player) : number
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.Awareness
end

function AwarenessService:AddAwareness(player: Player, amount: number, isDeepThought: boolean): number
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    profile.Data.Awareness += amount
    profile.Data.AwarenessTotal = (profile.Data.AwarenessTotal or 0) + amount
    self.AwarenessChanged:Fire(player, profile.Data.Awareness, isDeepThought)
    self.Client.AwarenessTotalChanged:Fire(player, profile.Data.AwarenessTotal)
    self.AwarenessEarned:Fire(player, amount)

    -- Log first time reaching 250k awareness (one-time)
    if not profile.Data.Analytics_Reached250kAwareness and profile.Data.AwarenessTotal >= 250000 then
        profile.Data.Analytics_Reached250kAwareness = true
        pcall(function()
            AnalyticsService:LogFunnelStepEvent(player, "PlayerProgression", tostring(player.UserId), 1, "Reached 250k Awareness")
        end)
    end
    return profile.Data.Awareness
end

function AwarenessService:RemoveAwareness(player, amount: number)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.Awareness -= amount
    self.AwarenessChanged:Fire(player, profile.Data.Awareness)
    return profile.Data.Awareness
end

function AwarenessService:SetAwareness(player, value: number)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.Awareness = value
    self.AwarenessChanged:Fire(player, value)
    return value
end

function AwarenessService:ToggleMeditateAnywhereBoost(player)
    local active = not self._meditateAnywhereActive[player]
    self._meditateAnywhereActive[player] = active
end

function AwarenessService:ToggleMeditationSpeedBoost(player)
    local active = not self._meditationSpeedBoostActive[player]
    self._meditationSpeedBoostActive[player] = active
end

-- =======================
-- Client functions exposed via Knit
-- =======================
function AwarenessService.Client:GetAwareness(player)
    return self.Server:GetAwareness(player)
end

-- Toggle Meditate Anywhere for a player. Returns (success, active).
-- success=false means the player doesn't own the gamepass.
function AwarenessService.Client:ToggleMeditateAnywhere(player)
    if not self.Server.GamepassService:OwnsMeditateAnywhere(player) then
        return false, false
    end
    local active = not self.Server._meditateAnywhereActive[player]
    self.Server._meditateAnywhereActive[player] = active
    return true, active
end

function AwarenessService.Client:AddAwareness(player, amount: number)
    return self.Server:AddAwareness(player, amount)
end

function AwarenessService.Client:SetAwareness(player, value: number)
    return self.Server:SetAwareness(player, value)
end

return AwarenessService
