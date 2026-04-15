local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local FALL_THRESHOLD = -10 -- studs

local FallService = Knit.CreateService { Name = "FallService" }

function FallService:KnitStart()
    local function getSpawnCFrame()
        local spawn = workspace:FindFirstChild("Map"):FindFirstChildWhichIsA("SpawnLocation")
        if spawn then
return CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
        end
        return CFrame.new(0, 3, 0)
    end

    RunService.Heartbeat:Connect(function()
        for _, player in Players:GetPlayers() do
            local character = player.Character
            if not character then continue end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end

            if root.Position.Y < FALL_THRESHOLD then
                root.CFrame = getSpawnCFrame()
            end
        end
    end)
end

return FallService
