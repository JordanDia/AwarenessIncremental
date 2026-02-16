local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)


local Player = Players.LocalPlayer
local FloatingTextComponent = require(ReplicatedStorage.UI.components.FloatingText)
local PopSound = SoundService:WaitForChild("Pop")

local AwarenessController = Knit.CreateController {
    Name = "AwarenessController"
}

AwarenessController.AwarenessService = nil

function AwarenessController:KnitStart()
    self.AwarenessService = Knit.GetService("AwarenessService")

    local lastAwareness = self.AwarenessService:GetAwareness() or 0
    self.AwarenessService.AwarenessChanged:Connect(function(awareness, isDeepThought)

        if awareness > lastAwareness then
            self:ShowFloatingText(awareness - lastAwareness, isDeepThought)
            PopSound:Play()
        end

        lastAwareness = awareness
    end)

    self.AwarenessService.DeepThoughtEffect:Connect(function()
        self:DeepThoughtEffect()
    end)
end

function AwarenessController:ShowFloatingText(delta: number, isDeepThought: boolean)
    local character = Player.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local scope = Fusion.scoped(Fusion, {
        FloatingTextComponent = FloatingTextComponent
    })

    local textColor = Color3.fromRGB(85, 170, 255)
    if isDeepThought then
        textColor = Color3.fromRGB(255, 255, 255)
    end


    local gui = scope:FloatingTextComponent {
        Amount = delta,
        Adornee = head,
        TextColor3 = textColor
    }

    local duration = 1

    gui.Parent = Player.PlayerGui

    -- Set random starting position
    local randomX = math.random(-200, 200) / 100  -- Random between -3 and 3
    local randomY = math.random(100, 200) / 100   -- Random between 1 and 3
    gui.StudsOffset = Vector3.new(randomX, randomY, 0)

    -- Get the TextLabel (assuming it's the first child or named TextLabel)
    local textLabel = gui:FindFirstChildWhichIsA("TextLabel")
    
    if textLabel then
        -- Tween the position upward
        local tweenInfo = TweenInfo.new(
            duration,                              -- Duration (1 second)
            Enum.EasingStyle.Linear,        -- Easing style
            Enum.EasingDirection.Out        -- Easing direction
        )

        local positionTween = TweenService:Create(gui, tweenInfo, {
            StudsOffset = Vector3.new(randomX, randomY + 2.5, 0)  -- Move up 2.5 studs
        })

        local transparencyTween = TweenService:Create(textLabel, tweenInfo, {
            TextTransparency = 1,           -- Fade to invisible
            TextStrokeTransparency = 1      -- Fade stroke too
        })

        positionTween:Play()
        transparencyTween:Play()
    end

    task.delay(duration + 1, function()
        scope:doCleanup()
    end)
end

function AwarenessController:DeepThoughtEffect()
    local character = Player.Character


    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(85, 170, 255)
    highlight.OutlineColor = Color3.fromRGB(85, 170, 255)
    highlight.FillTransparency = 0
    highlight.OutlineTransparency = 0

    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(highlight, tweenInfo, {
        FillTransparency = 1,
        OutlineTransparency = 1,
    })

    tween:Play()

    tween.Completed:Connect(function()
        highlight:Destroy()
    end)


    highlight.Parent = character
end

return AwarenessController
