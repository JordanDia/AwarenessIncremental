local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local DebugConfig = require(ReplicatedStorage.Shared.Configs.DebugConfig)

local DebugService = Knit.CreateService { Name = "DebugService" }

function DebugService:KnitStart()
    if not DebugConfig.Enabled then return end
    
    if RunService:IsStudio() then
        print("In studio, starting debug mode!")
    else
        print("Not in studio, disabling debug mode!")
        return
    end

    self.DataService       = Knit.GetService("DataService")
    self.MultiplierService = Knit.GetService("MultiplierService")

    local function ApplyDebugMultipliers(player)
        for _, stat in DebugConfig.Stats do
            self.MultiplierService:SetSource(player, stat, "Debug", DebugConfig.Multiplier)
        end
        print(`[DEBUG] Applied {DebugConfig.Multiplier}x multipliers to {player.Name}`)
    end

    self.DataService.ProfileLoaded:Connect(ApplyDebugMultipliers)

    for player in self.DataService.Profiles do
        ApplyDebugMultipliers(player)
    end
end

return DebugService
