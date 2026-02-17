local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CrystalController = Knit.CreateController { Name = "CrystalController" }

local LocalPlayer = Players.LocalPlayer
local MAX_CRYSTALS = 10
local SPAWN_INTERVAL = 5
local COLLECT_RADIUS = 5

function CrystalController:KnitInit()
    self.crystals = {} -- active crystal parts
    self.spawning = false
end

function CrystalController:KnitStart()
    self.CrystalService = Knit.GetService("CrystalService")
    self.UnlockService = Knit.GetService("UnlockService")

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
    if self.spawning then return end
    self.spawning = true

    task.spawn(function()
        while self.spawning do
            if #self.crystals < MAX_CRYSTALS then
                self:SpawnCrystal()
            end
            task.wait(SPAWN_INTERVAL)
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

    local randomX = origin.X + math.random(-size.X / 2, size.X / 2)
    local randomZ = origin.Z + math.random(-size.Z / 2, size.Z / 2)
    local spawnPos = Vector3.new(randomX, origin.Y + 2, randomZ)

    local crystal = crystalTemplate:Clone()
    crystal:PivotTo(CFrame.new(spawnPos))
    crystal.Parent = workspace

    table.insert(self.crystals, crystal)

    -- Collect on touch via PrimaryPart or any BasePart
    local touchPart = crystal.PrimaryPart or crystal:FindFirstChildWhichIsA("BasePart")
    if touchPart then
        touchPart.Touched:Connect(function(hit)
            if hit.Parent == LocalPlayer.Character then
                self:CollectCrystal(crystal)
            end
        end)
    end
end

function CrystalController:CollectCrystal(crystal)
    -- Remove from list
    table.remove(self.crystals, table.find(self.crystals, crystal))
    crystal:Destroy()

    -- Tell server
    self.CrystalService.CollectCrystal:Fire()
end

return CrystalController