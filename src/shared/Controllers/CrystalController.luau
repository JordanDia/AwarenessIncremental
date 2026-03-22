local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CrystalController = Knit.CreateController { Name = "CrystalController" }

local LocalPlayer = Players.LocalPlayer
local PopSound = SoundService:WaitForChild("Pop")

function CrystalController:KnitInit()
    self.crystals = {} -- active crystal parts
    self.Spawning = false
end

function CrystalController:KnitStart()
    self.CrystalService = Knit.GetService("CrystalService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")

    self.CrystalService.StartCrystals:Connect(function()
        self:StartSpawning()
    end)

    -- Catch the case where signal already fired before we connected
    task.spawn(function()
        local isUnlocked = self.UnlockService:IsUnlocked("CrystalCollection")
        if isUnlocked then
            self:StartSpawning()
        end
    end)
end

function CrystalController:StartSpawning()
    if self.Spawning then return end
    self.Spawning = true

    task.spawn(function()
        while self.Spawning do

            local maxCrystals = self.UpgradeService:GetUpgradeEffect("MaxCrystals")

            if #self.crystals < maxCrystals then
                self:SpawnCrystal()
            end

            local spawnInterval = self.UpgradeService:GetUpgradeEffect("CrystalSpeed")
            task.wait(spawnInterval or 3)
        end
    end)
end

function CrystalController:SpawnCrystal()
    local spawnArea = workspace:FindFirstChild("CrystalSpawn")
    if not spawnArea then return end

    local crystalTemplate = ReplicatedStorage:FindFirstChild("Crystal")
    if not crystalTemplate then
        warn("Crystal model not found in ReplicatedStorage")
        return
    end

    local size = spawnArea.Size
    local origin = spawnArea.Position

    -- Shrink the spawn zone inward so crystals never appear near the edge
    local margin = 2
    local halfX = math.max(0, size.X / 2 - margin)
    local halfZ = math.max(0, size.Z / 2 - margin)

    local randomX = origin.X + (math.random() * 2 - 1) * halfX
    local randomZ = origin.Z + (math.random() * 2 - 1) * halfZ
    local spawnY = origin.Y + 3
    local spawnPos = Vector3.new(randomX, spawnY, randomZ)

    local crystal = crystalTemplate:Clone()

    -- Anchor every BasePart so physics don't interfere with our animations
    for _, part in crystal:GetDescendants() do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end

    crystal:PivotTo(CFrame.new(spawnPos))
    crystal.Parent = workspace

    table.insert(self.crystals, crystal)

    -- ── Bounce animation ──────────────────────────────────────────────────
    local bounceHeight = 1.2
    local bounceDuration = 1.4
    local tweenInfo = TweenInfo.new(bounceDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

    local primaryPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        local upGoal = { Position = primaryPart.Position + Vector3.new(0, bounceHeight, 0) }
        TweenService:Create(primaryPart, tweenInfo, upGoal):Play()
    end

    -- ── Rotation animation (RunService so we can rotate the whole model) ──
    local rotationSpeed = math.random(2, 5) * (math.random() > 0.5 and 1 or -1) -- deg/s
    local rotationConnection = RunService.Heartbeat:Connect(function(dt)
        if not crystal or not crystal.Parent then return end
        local currentCF = crystal:GetPivot()
        crystal:PivotTo(currentCF * CFrame.Angles(0, math.rad(rotationSpeed * dt), 0))
    end)

    -- ── Light pulse animation ─────────────────────────────────────────────
    local lightTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    for _, desc in crystal:GetDescendants() do
        if desc:IsA("PointLight") or desc:IsA("SurfaceLight") then
            TweenService:Create(desc, lightTweenInfo, { Brightness = 1 }):Play()
        end
    end

    -- ── Touch collection ──────────────────────────────────────────────────
    local touchPart = primaryPart
    if touchPart then
        local touchConnection = nil
        touchConnection = touchPart.Touched:Connect(function(hit)
            if hit.Parent == LocalPlayer.Character then
                touchConnection:Disconnect()
                touchConnection = nil
                rotationConnection:Disconnect()

                self:CollectCrystal(crystal)
            end
        end)
    end
end

function CrystalController:CollectCrystal(crystal)
    -- Remove from list immediately so a new one can spawn
    table.remove(self.crystals, table.find(self.crystals, crystal))

    -- Tell server
    self.CrystalService.CollectCrystal:Fire()

    PopSound:Play()

    -- Shrink + fade all parts, then destroy
    local parts = {}
    for _, desc in crystal:GetDescendants() do
        if desc:IsA("BasePart") then
            table.insert(parts, desc)
        end
    end

    local shrinkInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local remaining = #parts

    for _, part in parts do
        local tween = TweenService:Create(part, shrinkInfo, {
            Size = Vector3.zero,
            Transparency = 1,
            Position = part.Position + Vector3.new(0, 0.5, 0),
        })
        tween:Play()
        tween.Completed:Connect(function()
            remaining -= 1
            if remaining <= 0 then
                crystal:Destroy()
            end
        end)
    end
end

return CrystalController