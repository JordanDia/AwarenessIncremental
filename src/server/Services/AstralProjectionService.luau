local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit              = require(ReplicatedStorage.Packages.Knit)

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local SIT_SETTLE_TIME   = 0.6

local AstralProjectionService = Knit.CreateService {
    Name = "AstralProjectionService",
    Client = {
        ProjectionStarted = Knit.CreateSignal(),
    },
}

AstralProjectionService._projecting = {} -- [player] = true

local function makeBodyClone(character: Model)
    character.Archivable = true
    local clone = character:Clone()
    character.Archivable = false

    clone.Name = "AstralBody"

    for _, obj in clone:GetDescendants() do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
            or obj:IsA("ProximityPrompt") or obj:IsA("Animator") or obj:IsA("Humanoid")
        then
            obj:Destroy()
        end
    end

    for _, part in clone:GetDescendants() do
        if part:IsA("BasePart") then
            part.Anchored   = true
            part.CanCollide = false
        end
    end

    clone.Parent = workspace
    return clone
end

function AstralProjectionService:KnitStart()
    local promptPart = workspace:WaitForChild("AstralProjectionPart")
    local prompt     = promptPart:WaitForChild("ProximityPrompt")

    prompt.Triggered:Connect(function(player)
        if self._projecting[player] then return end
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        self._projecting[player] = true

        local prevWalkSpeed = humanoid.WalkSpeed
        local prevJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed     = 0
        humanoid.JumpPower     = 0
        humanoid.PlatformStand = true

        task.wait(SIT_SETTLE_TIME)

        makeBodyClone(character)

        humanoid.PlatformStand = false
        humanoid.WalkSpeed = prevWalkSpeed > 0 and prevWalkSpeed or DEFAULT_WALKSPEED
        humanoid.JumpPower = prevJumpPower > 0 and prevJumpPower or DEFAULT_JUMPPOWER

        local highlight = Instance.new("Highlight")
        highlight.FillColor           = Color3.new(1, 1, 1)
        highlight.FillTransparency    = 0.5
        highlight.OutlineColor        = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.3
        highlight.Parent = character

        self.Client.ProjectionStarted:Fire(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self._projecting[player] = nil
    end)
end

return AstralProjectionService
