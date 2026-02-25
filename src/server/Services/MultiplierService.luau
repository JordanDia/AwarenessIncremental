local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

--[[
    MultiplierService
    
    Tracks named multiplier sources per player per stat.
    All sources are multiplied together (multiplicative stacking).
    
    Example:
        MultiplierService:SetSource(player, "Awareness", "Rebirth", 50)
        MultiplierService:SetSource(player, "Awareness", "Crystal", 250)
        MultiplierService:GetMultiplier(player, "Awareness") --> 12500
        
    Sources:
        "Rebirth"     - bought with rebirth points, up to 50x
        "Crystal"     - crystal upgrades, up to 250x
        "Awakening"   - passive bonus from awakening resets e.g. 1.20x
        "UpgradeTree" - future upgrade tree bonuses
]]

local MultiplierService = Knit.CreateService {
    Name = "MultiplierService",
    Client = {
        MultiplierChanged = Knit.CreateSignal(), -- (stat: string, finalMultiplier: number)
    }
}

MultiplierService.MultiplierChanged = Signal.new() -- (player, stat, finalMultiplier)

-- Structure: _multipliers[player][stat][source] = value
MultiplierService._multipliers = {}

function MultiplierService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        self._multipliers[player] = nil
    end)
end

-- Internal: get or create the table for a player
function MultiplierService:_getPlayerTable(player: Player)
    if not self._multipliers[player] then
        self._multipliers[player] = {}
    end
    return self._multipliers[player]
end

-- Internal: recalculate and fire changed signals
function MultiplierService:_recalculate(player: Player, stat: string)
    local final = self:GetMultiplier(player, stat)
    self.MultiplierChanged:Fire(player, stat, final)
    self.Client.MultiplierChanged:Fire(player, stat, final)
end

--[[ 
    Set a named source's multiplier for a stat.
    
    player  : Player
    stat    : string  e.g. "Awareness", "CrystalValue"
    source  : string  e.g. "Rebirth", "Crystal", "Awakening"
    value   : number  the multiplier value (1 = no effect)
]]
function MultiplierService:SetSource(player: Player, stat: string, source: string, value: number)
    local playerTable = self:_getPlayerTable(player)

    if not playerTable[stat] then
        playerTable[stat] = {}
    end

    playerTable[stat][source] = value
    self:_recalculate(player, stat)
end

--[[
    Remove a named source for a stat (treated as 1x going forward).
]]
function MultiplierService:RemoveSource(player: Player, stat: string, source: string)
    local playerTable = self:_getPlayerTable(player)
    if not playerTable[stat] then return end

    playerTable[stat][source] = nil
    self:_recalculate(player, stat)
end

--[[
    Get the final combined multiplier for a stat.
    Returns 1 if no sources are registered.
]]
function MultiplierService:GetMultiplier(player: Player, stat: string): number
    local playerTable = self._multipliers[player]
    if not playerTable or not playerTable[stat] then return 1 end

    local result = 1
    for _, value in playerTable[stat] do
        result *= value
    end

    return result
end

--[[
    Get a breakdown of all sources for a stat.
    Useful for debug or a stats UI.
    Returns: { [source: string]: value: number }
]]
function MultiplierService:GetSources(player: Player, stat: string): { [string]: number }
    local playerTable = self._multipliers[player]
    if not playerTable or not playerTable[stat] then return {} end

    -- Return a shallow copy so callers can't mutate internals
    local copy = {}
    for source, value in playerTable[stat] do
        copy[source] = value
    end
    return copy
end

--[[
    Reset all sources for a stat. 
    Use this on Awakening reset to wipe upgrade tree bonuses
    while keeping passive awakening bonuses by re-registering them after.
]]
function MultiplierService:ResetStat(player: Player, stat: string)
    local playerTable = self._multipliers[player]
    if not playerTable then return end

    playerTable[stat] = {}
    self:_recalculate(player, stat)
end

--[[
    Reset all multipliers for a player.
    Use on full reset if needed.
]]
function MultiplierService:ResetPlayer(player: Player)
    self._multipliers[player] = {}
end

-- Client: read-only access to their own multipliers
function MultiplierService.Client:GetMultiplier(player: Player, stat: string): number
    return self.Server:GetMultiplier(player, stat)
end

function MultiplierService.Client:GetSources(player: Player, stat: string)
    return self.Server:GetSources(player, stat)
end

return MultiplierService
