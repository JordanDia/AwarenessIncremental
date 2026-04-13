local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Player = Players.LocalPlayer

local MEDITATION_ANIM_ID = "rbxassetid://103840936162021"
local MEDITATION_RADIUS  = 60 -- studs; must match AwarenessService
local CHECK_INTERVAL     = 0.1 -- seconds between proximity checks

local ZoneController = Knit.CreateController {
    Name = "ZoneController"
}

ZoneController._meditationTrack = nil
ZoneController._inMeditationZone = false
ZoneController._meditateAnywhereOverride = false

function ZoneController:_playMeditationAnim()
    local character = Player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = MEDITATION_ANIM_ID
    self._meditationTrack = animator:LoadAnimation(anim)
    self._meditationTrack.Looped = true
    self._meditationTrack.Priority = Enum.AnimationPriority.Action4
    self._meditationTrack:Play()
end

function ZoneController:_stopMeditationAnim()
    if self._meditationTrack then
        self._meditationTrack:Stop()
        self._meditationTrack = nil
    end
end

function ZoneController:_startZoneLoop(meditationGrounds)
    local elapsed = 0

    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < CHECK_INTERVAL then return end
        elapsed = 0

        local inRange = self._meditateAnywhereOverride

        if not inRange then
            local character = Player.Character
            if character then
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    local groundsPos = meditationGrounds:IsA("BasePart")
                        and meditationGrounds.Position
                        or meditationGrounds:GetPivot().Position
                    inRange = (root.Position - groundsPos).Magnitude <= MEDITATION_RADIUS
                end
            end
        end

        if inRange == self._inMeditationZone then return end
        self._inMeditationZone = inRange

        if inRange then
            self:_playMeditationAnim()
        else
            self:_stopMeditationAnim()
        end
    end)
end

-- Called by Hud when Meditate Anywhere is toggled on or off.
function ZoneController:SetMeditateAnywhereOverride(active: boolean)
    self._meditateAnywhereOverride = active
    -- Immediately apply so the animation doesn't wait for the next heartbeat tick
    if active and not self._inMeditationZone then
        self._inMeditationZone = true
        self:_playMeditationAnim()
    elseif not active and self._inMeditationZone then
        -- Only stop if the player is also out of the physical zone;
        -- the heartbeat will correct this on the next tick naturally,
        -- so just clear the override flag and let the loop handle it.
        self._inMeditationZone = false
        self:_stopMeditationAnim()
    end
end

function ZoneController:KnitStart()
    local meditationGrounds = workspace:WaitForChild("Map"):WaitForChild("MeditationGrounds")

    -- Stop animation on respawn; zone loop will re-trigger on next check if still in range
    Player.CharacterAdded:Connect(function()
        self._meditationTrack = nil
        self._inMeditationZone = false
    end)

    self:_startZoneLoop(meditationGrounds)
end

return ZoneController
