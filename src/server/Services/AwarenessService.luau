-- ServerScriptService/Services/AwarenessService.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeService = require("./UpgradeService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local AwarenessService = Knit.CreateService {
    Name = "AwarenessService",
    Client = {
        AwarenessChanged = Knit.CreateSignal(),
        DeepThoughtEffect = Knit.CreateSignal()
    } -- Knit client functions
}

AwarenessService.DataService = nil
AwarenessService.UpgradeService = nil
AwarenessService.LevelService = nil

AwarenessService.AwarenessChanged = Signal.new() -- Fires (player, newAwareness)

function AwarenessService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UpgradeService = Knit.GetService("UpgradeService")
    self.LevelService = Knit.GetService("LevelService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if not profile then return end
        self:InitializePlayer(player, profile)
    end)

    -- Initialize players already in-game
    for player, profile in self.DataService.Profiles do
        self:InitializePlayer(player, profile)
    end

    self.AwarenessChanged:Connect(function(player, newAwareness, isDeepThought)
        self.Client.AwarenessChanged:Fire(player, newAwareness, isDeepThought)
    end)
   
end

-- Initialize a player's Awareness data
function AwarenessService:InitializePlayer(player, profile)
    --print(`Awareness for player {player.Name} is {profile.Data.Awareness}`)

    local randomGenerator = Random.new(os.clock())

    task.spawn(function()
        while player.Parent do
            local increment = UpgradeService:GetUpgradeEffect(player, "AwarenessPerMeditation")
            local multiplier = UpgradeService:GetUpgradeEffect(player, "MultiplyAwarenessPerMeditation") or 1
            local interval = UpgradeService:GetUpgradeEffect(player, "MeditationSpeed")

            --print(`Incrementing awareness for {player.Name} by {increment} every {interval} seconds`)
            local finalIncrement = math.round(increment * multiplier)

            -- "Deep Thought Chance"
            local deepThoughtChance = UpgradeService:GetUpgradeEffect(player, "IncreaseDeepThoughtChance")
            local randomNumber = randomGenerator:NextInteger(1, 100)
            local isDeepThought = false

            if randomNumber < deepThoughtChance then
                finalIncrement *= 3
                self.Client.DeepThoughtEffect:Fire(player)
                isDeepThought = true
            end

            AwarenessService:AddAwareness(player, finalIncrement, isDeepThought)
            self.LevelService:AddXP(player, 2)
            
            task.wait(interval)
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
    self.AwarenessChanged:Fire(player, profile.Data.Awareness, isDeepThought)
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

-- =======================
-- Client functions exposed via Knit
-- =======================
function AwarenessService.Client:GetAwareness(player)
    return self.Server:GetAwareness(player)
end

function AwarenessService.Client:AddAwareness(player, amount: number)
    return self.Server:AddAwareness(player, amount)
end

function AwarenessService.Client:SetAwareness(player, value: number)
    return self.Server:SetAwareness(player, value)
end

return AwarenessService
