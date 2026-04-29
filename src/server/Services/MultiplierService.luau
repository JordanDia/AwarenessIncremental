local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local MultiplierService = Knit.CreateService {
    Name = "MultiplierService",
    Client = {},
}

MultiplierService.MultiplierChanged = Signal.new() -- (player, stat, finalMultiplier)

-- Structure: Multipliers[player][stat][source] = value
MultiplierService.Multipliers = {}

function MultiplierService:_ApplyWalkSpeed(player: Player, multiplier)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local m = type(multiplier) == "buffer" and num.toNumber(multiplier) or multiplier
    humanoid.WalkSpeed = 16 * m
end

function MultiplierService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        self.Multipliers[player] = nil
    end)

    self.MultiplierChanged:Connect(function(player, stat, multiplier)
        if stat == "WalkSpeed" then
            self:_ApplyWalkSpeed(player, multiplier)
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            local multiplier = self:GetMultiplier(player, "WalkSpeed")
            self:_ApplyWalkSpeed(player, multiplier)
        end)
    end)
end

-- Internal: get or create the table for a player
function MultiplierService:_GetPlayerTable(player: Player)
    if not self.Multipliers[player] then
        self.Multipliers[player] = {}
    end
    return self.Multipliers[player]
end

-- Internal: recalculate and fire changed signals
function MultiplierService:_Recalculate(player: Player, stat: string)
    local final = self:GetMultiplier(player, stat)
    self.MultiplierChanged:Fire(player, stat, final)
end

-- Set a named source's multiplier for a stat (e.g. stat="Awareness", source="Rebirth", value=50)
function MultiplierService:SetSource(player: Player, stat: string, source: string, value: number)
    local playerTable = self:_GetPlayerTable(player)

    if not playerTable[stat] then
        playerTable[stat] = {}
    end

    playerTable[stat][source] = value
    self:_Recalculate(player, stat)
end

-- Remove a named source for a stat (treated as 1x going forward)
function MultiplierService:RemoveSource(player: Player, stat: string, source: string)
    local playerTable = self:_GetPlayerTable(player)
    if not playerTable[stat] then return end

    playerTable[stat][source] = nil
    self:_Recalculate(player, stat)
end

-- Get the final combined multiplier for a stat as a Quicknum buffer.
-- Returns num.fromNumber(1) if no sources are registered.
function MultiplierService:GetMultiplier(player: Player, stat: string)
    local playerTable = self.Multipliers[player]
    if not playerTable or not playerTable[stat] then return num.fromNumber(1) end

    local result = num.fromNumber(1)
    for _, value in playerTable[stat] do
        if value ~= value or value == math.huge then continue end
        result = num.mul(result, num.fromNumber(value))
    end

    return result
end

-- Get a breakdown of all sources for a stat, useful for debug or a stats UI
function MultiplierService:GetSources(player: Player, stat: string): { [string]: number }
    local playerTable = self.Multipliers[player]
    if not playerTable or not playerTable[stat] then return {} end

    -- Return a shallow copy so callers can't mutate internals
    local copy = {}
    for source, value in playerTable[stat] do
        copy[source] = value
    end
    return copy
end

-- Reset all sources for a stat
function MultiplierService:ResetStat(player: Player, stat: string)
    local playerTable = self.Multipliers[player]
    if not playerTable then return end

    playerTable[stat] = {}
    self:_Recalculate(player, stat)
end

-- Reset all multipliers for a player
function MultiplierService:ResetPlayer(player: Player)
    self.Multipliers[player] = {}
end

-- Client: read-only access to their own multipliers (returns buffer)
function MultiplierService.Client:GetMultiplier(player: Player, stat: string)
    return self.Server:GetMultiplier(player, stat)
end

function MultiplierService.Client:GetSources(player: Player, stat: string)
    return self.Server:GetSources(player, stat)
end

return MultiplierService
