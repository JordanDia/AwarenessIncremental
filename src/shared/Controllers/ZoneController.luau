local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")

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
ZoneController._inCaveZone = false

local MUSIC_FADE = TweenInfo.new(1, Enum.EasingStyle.Linear)

-- Captured once at startup before any fading touches the volumes
local defaultVolumes: { [Sound]: number } = {}

local function fadeMusic(from: Sound, to: Sound)
    local fromVol = defaultVolumes[from]
    local toVol   = defaultVolumes[to]

    if not to.IsPlaying then
        to.Volume = 0
        to:Play()
    end

    TweenService:Create(from, MUSIC_FADE, { Volume = 0 }):Play()
    TweenService:Create(to,   MUSIC_FADE, { Volume = toVol }):Play()

    task.delay(MUSIC_FADE.Time, function()
        from:Stop()
        from.Volume = fromVol
    end)
end

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
    local caveGround        = workspace.Map:WaitForChild("Cave"):WaitForChild("Ground")

    local forestMusic = SoundService:WaitForChild("SafeForestPath")
    local caveMusic   = SoundService:WaitForChild("CalmElvenAmbience")

    -- Snapshot volumes before any fading can mutate them
    defaultVolumes[forestMusic] = forestMusic.Volume
    defaultVolumes[caveMusic]   = caveMusic.Volume

    -- Stop animation on respawn; zone loop will re-trigger on next check if still in range
    Player.CharacterAdded:Connect(function()
        self._meditationTrack = nil
        self._inMeditationZone = false
    end)

    self:_startZoneLoop(meditationGrounds)

    -- Cave zone: check X/Z bounds of Cave.Ground every heartbeat tick
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < CHECK_INTERVAL then return end
        elapsed = 0

        local character = Player.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local pos  = root.Position
        local cf   = caveGround.CFrame
        local size = caveGround.Size
        local local_ = cf:PointToObjectSpace(pos)
        local inCave = math.abs(local_.X) <= size.X / 2
                   and math.abs(local_.Z) <= size.Z / 2

        if inCave == self._inCaveZone then return end
        self._inCaveZone = inCave

        if inCave then
            fadeMusic(forestMusic, caveMusic)
        else
            fadeMusic(caveMusic, forestMusic)
        end
    end)
end

return ZoneController
