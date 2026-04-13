local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TWEEN_TIME = 2

local VeilController = Knit.CreateController { Name = "VeilController" }

VeilController.VeilLifted = false
VeilController._veilTweens = {}

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

    -- Tween ColorCorrection TintColor: original <-> white, looping
    local colorCorrection = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
    if colorCorrection then
        local originalTint = colorCorrection.TintColor
        local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(colorCorrection, tweenInfo, { TintColor = Color3.fromRGB(127, 127, 190) })
        tween:Play()
        table.insert(self._veilTweens, tween)

        -- Restore original on lower (stored for LowerVeil)
        self._colorCorrectionOriginalTint = originalTint
    end

    -- Tween BlurEffect Size: 10 <-> 2, looping
    local blur = Lighting:FindFirstChildWhichIsA("BlurEffect")
    if blur then
        local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(blur, tweenInfo, { Size = 3 })
        tween:Play()
        table.insert(self._veilTweens, tween)
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

    -- Cancel all running veil tweens
    for _, tween in self._veilTweens do
        tween:Cancel()
    end
    self._veilTweens = {}

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
