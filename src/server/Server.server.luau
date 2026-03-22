local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServicesDeep(ServerScriptService.Server.Services)
Knit.AddServicesDeep(ReplicatedStorage.Shared.Services)

Knit.Start({ServicePromises = false}):catch(warn):await()


local AwarenessService = Knit.GetService("AwarenessService")

workspace:WaitForChild("FreeAwareness").Touched:Connect(function(otherPart)
    local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
    if not player then return end
    AwarenessService:AddAwareness(player, 1e12)
end)
