-- Awakening board UI is mounted as a SurfaceGui in src/ui/mount/UpgradeBoards.luau.
-- This controller is kept as a stub so the require chain stays intact.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AwakeningController = Knit.CreateController { Name = "AwakeningController" }

return AwakeningController
