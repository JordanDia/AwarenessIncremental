local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require("./DataService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local LevelService = Knit.CreateService {
    Name = "LevelService",
    Client = {
        LevelChanged = Knit.CreateSignal(),
        XPChanged = Knit.CreateSignal(),
    }
}

LevelService.DataService = nil

-- Level configuration
local LevelConfig = {
    BaseXP = 100,           -- XP needed for level 2
    ScalingFactor = 1.8,   -- Each level requires 15% more XP (adjust as needed)
    MaxLevel = nil,         -- nil for unlimited, or set a number
}

function LevelService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    
    -- Listen for new players
    self.DataService.ProfileLoaded:Connect(function(player, profile)
        self:SetupPlayer(player, profile)
    end)

    for player, profile in DataService.Profiles do
        self:SetupPlayer(player, profile)
    end

end

-- Initialize player level data
function LevelService:SetupPlayer(player, profile)
    -- Validate that level matches XP (in case of formula changes)
    local calculatedLevel = self:GetLevelFromXP(profile.Data.XP)
    
    if profile.Data.Level ~= calculatedLevel then
        warn(`Level mismatch for {player.Name}! Stored: {profile.Data.Level}, Calculated: {calculatedLevel}`)
        profile.Data.Level = calculatedLevel
    end
    
    print(`Initialized level for {player.Name}: Level {profile.Data.Level}, XP {profile.Data.XP}`)
end

-- Calculate XP required for a specific level
function LevelService:GetXPForLevel(level)
    if level < 1 then return 0 end
    
    -- Exponential scaling: each level requires more XP than the last
    return math.floor(LevelConfig.BaseXP * (LevelConfig.ScalingFactor ^ (level - 2)))
end

-- Calculate total XP needed to reach a level from level 1
function LevelService:GetTotalXPForLevel(level)
    if level < 1 then return 0 end
    
    local total = 0
    for i = 2, level do
        total += self:GetXPForLevel(i)
    end
    return total
end

-- Get current level from XP amount
function LevelService:GetLevelFromXP(xp)
    local level = 1
    
    -- Keep checking if XP is enough for next level
    while true do
        if LevelConfig.MaxLevel and level >= LevelConfig.MaxLevel then
            break
        end
        
        local xpForNextLevel = self:GetTotalXPForLevel(level + 1)
        if xp < xpForNextLevel then
            break
        end
        
        level += 1
    end
    
    return level
end

-- Get player's current level
function LevelService:GetLevel(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 1 end
    
    return profile.Data.Level
end

-- Get player's current XP
function LevelService:GetXP(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    
    return profile.Data.XP
end

-- Get XP progress to next level (returns current progress and total needed)
function LevelService:GetXPProgress(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then
        return 0, 0
    end
    
    local currentXP = profile.Data.XP
    local currentLevel = profile.Data.Level
    
    -- Check if at max level
    if LevelConfig.MaxLevel and currentLevel >= LevelConfig.MaxLevel then
        return 0, 0 -- Max level reached
    end
    
    local xpForCurrentLevel = self:GetTotalXPForLevel(currentLevel)
    local xpForNextLevel = self:GetTotalXPForLevel(currentLevel + 1)
    
    local xpIntoLevel = currentXP - xpForCurrentLevel
    local xpNeededForLevel = xpForNextLevel - xpForCurrentLevel
    
    return xpIntoLevel, xpNeededForLevel
end

-- Add XP to a player (with automatic level-up checking)
function LevelService:AddXP(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    
    -- Add XP
    profile.Data.XP += amount
    
    -- Check for level ups (can level up multiple times at once)
    local oldLevel = profile.Data.Level
    local newLevel = self:GetLevelFromXP(profile.Data.XP)
    
    if newLevel > oldLevel then
        profile.Data.Level = newLevel
        
        -- Fire level up event for each level gained
        for level = oldLevel + 1, newLevel do
            self.Client.LevelChanged:Fire(player, level, level - 1)
            print(`Player {player.Name} leveled up! Level {level - 1} -> {level}`)
        end
    end
    
    -- Fire XP changed event
    self.Client.XPChanged:Fire(player, profile.Data.XP)
end

-- Set XP directly (useful for admin commands or testing)
function LevelService:SetXP(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    
    local oldLevel = profile.Data.Level
    profile.Data.XP = amount
    
    -- Recalculate level
    local newLevel = self:GetLevelFromXP(amount)
    profile.Data.Level = newLevel
    
    if newLevel ~= oldLevel then
        self.Client.LevelChanged:Fire(player, newLevel, oldLevel)
    end
    
    self.Client.XPChanged:Fire(player, profile.Data.XP)
end

-- Client-facing methods (these are automatically exposed to client)
function LevelService.Client:GetLevel(player)
    return self.Server:GetLevel(player)
end

function LevelService.Client:GetXP(player)
    return self.Server:GetXP(player)
end

function LevelService.Client:GetXPProgress(player)
    return self.Server:GetXPProgress(player)
end

function LevelService.Client:GetXPForLevel(player, level)
    return self.Server:GetXPForLevel(level)
end

function LevelService.Client:GetTotalXPForLevel(player, level)
    return self.Server:GetTotalXPForLevel(level)
end

return LevelService