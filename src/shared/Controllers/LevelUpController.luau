local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Player = Players.LocalPlayer
local LevelUpSound = SoundService:WaitForChild("LevelUp")
local LevelUpVFX = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VFX"):WaitForChild("LevelUp")

local LevelUpController = Knit.CreateController {
    Name = "LevelUpController"
}

function LevelUpController:_playLevelUpEffect()
    local character = Player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    LevelUpSound:Play()

    -- Clone each attachment from the VFX folder into the HRP and emit its particles
    for _, attachment in LevelUpVFX:GetChildren() do
        if not attachment:IsA("Attachment") then continue end

        local clone = attachment:Clone()
        clone.Parent = hrp

        for _, emitter in clone:GetChildren() do
            if not emitter:IsA("ParticleEmitter") then continue end
            local count = emitter:GetAttribute("EmitCount") or 10
            emitter:Emit(count)
        end

        -- Remove the attachment after particles have had time to finish
        task.delay(5, function()
            clone:Destroy()
        end)
    end
end

function LevelUpController:KnitStart()
    local LevelService = Knit.GetService("LevelService")

    LevelService.LevelChanged:Connect(function(_newLevel, _oldLevel)
        self:_playLevelUpEffect()
    end)
end

return LevelUpController
