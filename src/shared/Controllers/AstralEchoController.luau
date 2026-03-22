local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AstralEchoController = Knit.CreateController { Name = "AstralEchoController" }

AstralEchoController.SeeThroughWorldActivated = false

local LocalPlayer = Players.LocalPlayer

-- How long each individual drift tween lasts
local DRIFT_TIME_MIN = 1.0
local DRIFT_TIME_MAX = 2.0

-- How far an echo can drift from its spawn origin per step
local DRIFT_RADIUS = 8

-- How much it bobs up/down
local BOB_HEIGHT = 3

local function randomDriftTarget(origin: Vector3): CFrame
    local angle = math.random() * math.pi * 2
    local radius = math.random() * DRIFT_RADIUS
    local dx = math.cos(angle) * radius
    local dz = math.sin(angle) * radius
    local dy = (math.random() - 0.5) * 2 * BOB_HEIGHT

    return CFrame.new(origin + Vector3.new(dx, dy, dz))
end

local function startDrifting(echo: BasePart, origin: Vector3)
    -- Store a flag on the model so we can stop drifting on collect
    echo:SetAttribute("Drifting", true)

    task.spawn(function()
        while echo.Parent and echo:GetAttribute("Drifting") do
            local target = randomDriftTarget(origin)
            local duration = DRIFT_TIME_MIN + math.random() * (DRIFT_TIME_MAX - DRIFT_TIME_MIN)

            local tween = TweenService:Create(echo, TweenInfo.new(
                duration,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ), { CFrame = target })

            tween:Play()
            tween.Completed:Wait()
        end
    end)
end

function AstralEchoController:KnitInit()
    self.Echoes = {}
    self.Spawning = false
end

function AstralEchoController:KnitStart()
    self.AstralEchoService = Knit.GetService("AstralEchoService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")

    self.AstralEchoService.StartEchoes:Connect(function()
        self:StartSpawning()
    end)

    self.AstralEchoService.StopEchoes:Connect(function()
        self:StopSpawning()
    end)
end

function AstralEchoController:StartSpawning()
    if self.Spawning then return end
    self.Spawning = true


    task.spawn(function()
        while self.Spawning do
            local maxEchoes = self.UpgradeService:GetUpgradeEffect("MaxAstralEchoes")

            if #self.Echoes < 10 then
                self:SpawnEcho()
            end

            local spawnInterval = self.UpgradeService:GetUpgradeEffect("AstralEchoSpeed")
            task.wait(spawnInterval or 3)
        end
    end)
end

function AstralEchoController:StopSpawning()
    self.Spawning = false

    for _, echo in self.Echoes do
        echo:Destroy()
    end
    self.Echoes = {}
end

function AstralEchoController:SpawnEcho()
    local spawnArea = workspace:FindFirstChild("AstralEchoSpawn")
    if not spawnArea then return end

    local echoTemplate = ReplicatedStorage:FindFirstChild("AstralEcho")
    if not echoTemplate then
        warn("AstralEcho model not found in ReplicatedStorage")
        return
    end

    local size = spawnArea.Size
    local origin = spawnArea.Position

    -- Random point fully within the part's volume
    local randomX = origin.X + (math.random() - 0.5) * size.X
    local randomY = origin.Y + (math.random() - 0.5) * size.Y
    local randomZ = origin.Z + (math.random() - 0.5) * size.Z
    local spawnPos = Vector3.new(randomX, randomY, randomZ)

    local echo = echoTemplate:Clone()
    echo:PivotTo(CFrame.new(spawnPos))
    echo.Parent = workspace

    table.insert(self.Echoes, echo)

    -- Begin smooth spirit drifting from spawn position
    startDrifting(echo, spawnPos)

    -- Collect on touch
    local touchConnection
    touchConnection = echo.Touched:Connect(function(hit)
        if hit.Parent == LocalPlayer.Character then
            touchConnection:Disconnect()
            touchConnection = nil
            self:CollectEcho(echo)
        end
    end)
end

function AstralEchoController:CollectEcho(echo: Model)
    -- Stop the drift loop
    echo:SetAttribute("Drifting", false)

    local idx = table.find(self.Echoes, echo)
    if idx then
        table.remove(self.Echoes, idx)
    end

    echo:Destroy()

    -- Tell server
    self.AstralEchoService.CollectEcho:Fire()
end


return AstralEchoController
