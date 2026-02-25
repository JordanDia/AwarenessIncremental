local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local VeilController = Knit.CreateController { Name = "VeilController" }

VeilController.VeilLifted = false

function VeilController:KnitStart()
    self.VeilService = Knit.GetService("VeilService")

    self.VeilService.VeilLifted:Connect(function()
        self:LiftVeil()
    end)

    self.VeilService.VeilLowered:Connect(function()
        self:LowerVeil()
    end)
end

function VeilController:LiftVeil()
    if self.VeilLifted then return end
    self.VeilLifted = true

    local stwLightingFolder = ReplicatedStorage:WaitForChild("SeeThroughWorldLighting")
    Lighting:ClearAllChildren()

    for _, lightingEffect in stwLightingFolder:GetChildren() do
        lightingEffect:Clone().Parent = Lighting
    end

    local playerHighlight = ReplicatedStorage:WaitForChild("STWPlayerHighlight")
    for _, player in Players:GetPlayers() do
        task.spawn(function()
            local character = player.Character or player.CharacterAdded:Wait()
            playerHighlight:Clone().Parent = character
        end)
    end

    SoundService.BellActivate:Play()
end

function VeilController:LowerVeil()
    if not self.VeilLifted then return end
    self.VeilLifted = false

    local defaultLightingFolder = ReplicatedStorage:WaitForChild("DefaultLighting")
    Lighting:ClearAllChildren()

    for _, lightingEffect in defaultLightingFolder:GetChildren() do
        lightingEffect:Clone().Parent = Lighting
    end

    for _, player in Players:GetPlayers() do
        task.spawn(function()
            local character = player.Character or player.CharacterAdded:Wait()

            local highlight = character:FindFirstChild("STWPlayerHighlight")
            if highlight then
                highlight:Destroy()
            end
        end)
    end

    SoundService.BellDeactivate:Play()
end

return VeilController
