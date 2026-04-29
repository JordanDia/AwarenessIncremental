local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)

local LeaderstatService = Knit.CreateService { Name = "LeaderstatService" }

local function createLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 0
    level.Parent = leaderstats

    local awareness = Instance.new("StringValue")
    awareness.Name = "Awareness"
    awareness.Value = "0"
    awareness.Parent = leaderstats

    return leaderstats
end

function LeaderstatService:KnitStart()
    local AwarenessService = Knit.GetService("AwarenessService")
    local LevelService     = Knit.GetService("LevelService")
    local DataService      = Knit.GetService("DataService")

    local function setup(player)
        local leaderstats = createLeaderstats(player)
        local levelStat    = leaderstats:FindFirstChild("Level")
        local awarenessStat = leaderstats:FindFirstChild("Awareness")

        -- Seed initial values from profile
        local profile = DataService:GetProfile(player)
        if profile then
            levelStat.Value    = profile.Data.Level or 1
            awarenessStat.Value = FormatNumber(DataService:GetQN(player, "Awareness"))
        end

        -- Keep in sync with live changes
        AwarenessService.AwarenessChanged:Connect(function(p, newAwareness)
            if p ~= player then return end
            awarenessStat.Value = FormatNumber(newAwareness)
        end)

        LevelService.LevelChanged:Connect(function(p, newLevel)
            if p ~= player then return end
            levelStat.Value = newLevel
        end)
    end

    DataService.ProfileLoaded:Connect(function(player)
        setup(player)
    end)

    for player in DataService.Profiles do
        setup(player)
    end
end

return LeaderstatService
