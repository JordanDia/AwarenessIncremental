local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PopSound: Sound = SoundService:WaitForChild("Pop")

local AstralEchoController = Knit.CreateController { Name = "AstralEchoController" }

local LocalPlayer = Players.LocalPlayer

local COLLECT_RADIUS  = 20   -- studs — within this distance the echo starts chasing

local SPAWN_Y_MIN     = 2   -- studs above ground top surface
local SPAWN_Y_MAX     = 8
local MAX_ECHOES      = 1000
local SPAWN_INTERVAL  = 0.02  -- seconds between spawns

-- Drift parameters while idle (small wander around spawn origin)
local DRIFT_RADIUS = 5
local DRIFT_TIME   = 2.0

local ground: BasePart = workspace:WaitForChild("MysticalForest"):WaitForChild("Ground")

local function randomSpawnCFrame(): CFrame
    local size = ground.Size
    local pos  = ground.Position
    local topY = pos.Y + size.Y / 2

    local x = pos.X + (math.random() - 0.5) * size.X
    local z = pos.Z + (math.random() - 0.5) * size.Z
    local y = topY + SPAWN_Y_MIN + math.random() * (SPAWN_Y_MAX - SPAWN_Y_MIN)

    return CFrame.new(x, y, z)
end

-- Active drift tweens keyed by echoPart so StartChasing can cancel them immediately
local activeDriftTweens: { [BasePart]: Tween } = {}

-- Gentle drift loop — keeps echo near its spawn origin
local function startDrifting(echo: BasePart, origin: Vector3)
    echo:SetAttribute("Drifting", true)

    task.spawn(function()
        while echo.Parent and echo:GetAttribute("Drifting") do
            local angle = math.random() * math.pi * 2
            local r = math.random() * DRIFT_RADIUS
            local target = CFrame.new(
                origin.X + math.cos(angle) * r,
                origin.Y + (math.random() - 0.5) * 2,
                origin.Z + math.sin(angle) * r
            )

            local tween = TweenService:Create(echo, TweenInfo.new(
                DRIFT_TIME,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ), { CFrame = target })

            activeDriftTweens[echo] = tween
            tween:Play()
            tween.Completed:Wait()
        end
        activeDriftTweens[echo] = nil
    end)
end

function AstralEchoController:KnitInit()
    self.Echoes   = {}
    self.Spawning = false
end

function AstralEchoController:KnitStart()
    self.AstralEchoService = Knit.GetService("AstralEchoService")
    self.UpgradeService    = Knit.GetService("UpgradeService")

    self.AstralEchoService.StartEchoes:Connect(function()
        self:StartSpawning()
    end)

    self.AstralEchoService.StopEchoes:Connect(function()
        self:StopSpawning()
    end)

    -- Spatial query: only check parts near the player instead of all 1000 echoes
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = { LocalPlayer.Character or workspace }

    RunService.PreRender:Connect(function()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Update exclusion list so we never hit the character itself
        overlapParams.FilterDescendantsInstances = { character }

        local nearby = workspace:GetPartBoundsInRadius(root.Position, COLLECT_RADIUS, overlapParams)
        for _, part in nearby do
            if not part:GetAttribute("IsAstralEcho") then continue end
            if part:GetAttribute("Chasing") then continue end
            self:StartChasing(part)
        end
    end)
end

function AstralEchoController:StartSpawning()
    if self.Spawning then return end
    self.Spawning = true

    task.spawn(function()
        while self.Spawning do
            if #self.Echoes < MAX_ECHOES then
                self:SpawnEcho()
            end
            local interval = SPAWN_INTERVAL
            task.wait(interval)
        end
    end)
end

function AstralEchoController:StopSpawning()
    self.Spawning = false

    for _, echo in self.Echoes do
        if echo.Parent then
            echo:Destroy()
        end
    end
    self.Echoes = {}
end

function AstralEchoController:SpawnEcho()
    local echoTemplate = ReplicatedStorage:FindFirstChild("AstralEcho")
    if not echoTemplate then
        warn("AstralEcho template not found in ReplicatedStorage")
        return
    end

    local spawnCF = randomSpawnCFrame()
    local echo = echoTemplate:Clone()
    echo:PivotTo(spawnCF)
    echo.Parent = workspace

    -- If the template is a Model, operate on its PrimaryPart; otherwise use it directly
    local echoPart: BasePart = echo:IsA("BasePart") and echo or echo.PrimaryPart
    if not echoPart then
        warn("AstralEcho has no BasePart to tween")
        echo:Destroy()
        return
    end

    -- Must be anchored so physics doesn't override the drift tween
    echoPart.Anchored = true
    -- Tag so GetPartBoundsInRadius results can be identified as echoes
    echoPart:SetAttribute("IsAstralEcho", true)

    table.insert(self.Echoes, echoPart)
    startDrifting(echoPart, spawnCF.Position)
end

local CHASE_SPEED     = 40  -- studs per second toward player
local COLLECT_DIST    = 1.5 -- studs — collected when this close

-- Called when the echo enters the player's collection radius
function AstralEchoController:StartChasing(echoPart: BasePart)
    echoPart:SetAttribute("Drifting", false)

    -- Cancel the in-flight drift tween immediately so chasing starts without delay
    local driftTween = activeDriftTweens[echoPart]
    if driftTween then
        driftTween:Cancel()
        activeDriftTweens[echoPart] = nil
    end

    echoPart:SetAttribute("Chasing", true)

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if not echoPart.Parent then
            connection:Disconnect()
            return
        end

        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local toPlayer = root.Position - echoPart.Position
        local dist = toPlayer.Magnitude

        if dist <= COLLECT_DIST then
            connection:Disconnect()
            self:CollectEcho(echoPart)
            return
        end

        -- Move toward player at constant speed each frame
        local step = math.min(CHASE_SPEED * dt, dist)
        echoPart.CFrame = CFrame.new(echoPart.Position + toPlayer.Unit * step)
    end)
end

function AstralEchoController:CollectEcho(echoPart: BasePart)
    echoPart:SetAttribute("Drifting", false)
    echoPart:SetAttribute("Chasing", false)

    local idx = table.find(self.Echoes, echoPart)
    if idx then
        table.remove(self.Echoes, idx)
    end

    -- Destroy the whole model if it's parented to one, otherwise the part itself
    echoPart:Destroy()

    PopSound:Play()
    self.AstralEchoService.CollectEcho:Fire()
end

return AstralEchoController
