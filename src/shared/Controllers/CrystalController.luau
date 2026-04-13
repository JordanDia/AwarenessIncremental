local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AUTO_COLLECT_TIMEOUT = 8 -- seconds before skipping a stuck crystal

local CrystalController = Knit.CreateController { Name = "CrystalController" }

local LocalPlayer = Players.LocalPlayer
local PopSound = SoundService:WaitForChild("Pop")

function CrystalController:KnitInit()
    self.crystals = {} -- active crystal parts
    self.Spawning = false
    self._autoCollecting = false
end

function CrystalController:KnitStart()
    self.CrystalService = Knit.GetService("CrystalService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")
    self.AwakeningService = Knit.GetService("AwakeningService")

    self.CrystalService.StartCrystals:Connect(function()
        self:StartSpawning()
    end)

    -- Clear all crystals and stop spawning when the player awakens
    self.AwakeningService.AwakeningLevelChanged:Connect(function()
        self:ClearCrystals()
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
    local idx = table.find(self.crystals, crystal)
    if not idx then return end -- already collected (race between touch and auto-collect)
    table.remove(self.crystals, idx)

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

function CrystalController:_getNearestCrystal()
    local character = LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, crystal in self.crystals do
        if not crystal or not crystal.Parent then continue end
        local part = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
        if not part then continue end
        local dist = (root.Position - part.Position).Magnitude
        if dist < nearestDist then
            nearest = crystal
            nearestDist = dist
        end
    end
    return nearest
end

function CrystalController:StartAutoCollect()
    if self._autoCollecting then return end
    self._autoCollecting = true

    task.spawn(function()
        while self._autoCollecting do
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not root then
                task.wait(0.5)
                continue
            end

            local crystal = self:_getNearestCrystal()
            if not crystal then
                task.wait(0.5)
                continue
            end

            local part = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
            if not part then
                task.wait(0.1)
                continue
            end

            -- Walk toward the crystal; Touched handler on the crystal handles actual collection.
            -- Re-issue MoveTo every tick so we track the bouncing crystal position.
            -- A timeout skips the crystal if the Touched event never fires (e.g. geometry issues).
            local timeout = AUTO_COLLECT_TIMEOUT
            local elapsed = 0

            while self._autoCollecting and table.find(self.crystals, crystal) do
                local currentRoot = character:FindFirstChild("HumanoidRootPart")
                if not currentRoot then break end
                local currentPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
                if not currentPart then break end

                local newTarget = Vector3.new(currentPart.Position.X, currentRoot.Position.Y, currentPart.Position.Z)
                humanoid:MoveTo(newTarget)

                task.wait(0.1)
                elapsed += 0.1
                if elapsed >= timeout then break end -- skip stuck crystal
            end
        end

        -- Stop moving when auto-collect ends
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(character:FindFirstChild("HumanoidRootPart").Position)
        end
    end)
end

function CrystalController:StopAutoCollect()
    self._autoCollecting = false
end

function CrystalController:ClearCrystals()
    self.Spawning = false
    local toDestroy = self.crystals
    self.crystals = {}
    for _, crystal in toDestroy do
        if crystal and crystal.Parent then
            crystal:Destroy()
        end
    end
end

return CrystalController