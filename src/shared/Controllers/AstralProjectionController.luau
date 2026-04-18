local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Knit              = require(ReplicatedStorage.Packages.Knit)

local Player = Players.LocalPlayer

local SPIRIT_SPAWN_INTERVAL  = 2
local SPIRIT_SPAWN_RADIUS    = 20
local SPIRIT_WALKSPEED       = 10
local SPIRIT_FADEIN_TIME     = 1
local SPIRIT_COLLISION_GROUP = "Spirit"

local AstralProjectionController = Knit.CreateController {
    Name = "AstralProjectionController",
}

local function spawnSpirit(template: Model, rootPart: BasePart)
    local angle    = math.random() * math.pi * 2
    local distance = math.random(5, SPIRIT_SPAWN_RADIUS)
    local offset   = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

    local spirit = template:Clone()
    spirit.Name  = "AstralSpirit"

    local humanoid = spirit:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed           = SPIRIT_WALKSPEED
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
        humanoid.NameDisplayDistance = 0
    end

    local savedTransparencies = {}
    for _, part in spirit:GetDescendants() do
        if part:IsA("BasePart") then
            savedTransparencies[part] = part.Transparency
            part.Transparency   = 1
            part.CanCollide     = false
            part.CollisionGroup = SPIRIT_COLLISION_GROUP
        end
    end

    spirit:PivotTo(CFrame.new(rootPart.Position + offset))
    spirit.Parent = workspace

    local tweenInfo = TweenInfo.new(SPIRIT_FADEIN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for part, original in savedTransparencies do
        TweenService:Create(part, tweenInfo, { Transparency = original }):Play()
    end

    if humanoid then
        task.spawn(function()
            while spirit and spirit.Parent do
                if rootPart and rootPart.Parent then
                    humanoid:MoveTo(rootPart.Position)
                end
                task.wait(0.5)
            end
        end)
    end
end

function AstralProjectionController:_startSpiritLoop()
    local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Spirit")

    task.spawn(function()
        while true do
            local character = Player.Character
            local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                spawnSpirit(template, rootPart)
            end
            task.wait(SPIRIT_SPAWN_INTERVAL)
        end
    end)
end

function AstralProjectionController:KnitStart()
    local AstralProjectionService = Knit.GetService("AstralProjectionService")

    AstralProjectionService.ProjectionStarted:Connect(function()
        self:_startSpiritLoop()
    end)
end

return AstralProjectionController
