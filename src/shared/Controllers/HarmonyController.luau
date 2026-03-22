local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local TreeBarFrame = require(ReplicatedStorage.UI.components.TreeBarFrame)

local LocalPlayer = Players.LocalPlayer

local HarmonyController = Knit.CreateController { Name = "HarmonyController" }

local FILL_SPEED    = 1   -- progress units per second (10 units total = 10 seconds)
local MAX_PROGRESS  = 10
local COOLDOWN      = 1   -- seconds between earning Harmony
local ORB_OFFSET    = Vector3.new(0, 1, -3) -- relative to HumanoidRootPart (in front, slightly up)

-- Colour of the orb and beam
local ORB_COLOR  = Color3.fromRGB(55, 210, 95)

function HarmonyController:KnitInit()
    self.IsUnlocked  = false
    self.IsHolding   = false
    self.IsConnecting = false
    self.OnCooldown  = false
    self.Progress    = 0
    self.ActiveInput = nil

    -- 3D objects
    self.OrbPart           = nil
    self.TreeAttachment    = nil
    self.OrbTrackConnection = nil
end

function HarmonyController:KnitStart()
    self.HarmonyService = Knit.GetService("HarmonyService")
    self.UnlockService  = Knit.GetService("UnlockService")

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local tree = Workspace:FindFirstChild("LargeTree")

    -- Reactive state for the bar
    local fusionScope = scoped(Fusion, {
        TreeBarFrame = TreeBarFrame,
    })
    self.progressValue = fusionScope:Value(0)
    self.barEnabled    = fusionScope:Value(false)

    fusionScope:TreeBarFrame {
        Adornee  = tree,
        Progress = self.progressValue,
        Enabled  = self.barEnabled,
        Parent   = PlayerGui,
    }

    -- Check unlock state (catch the case where signal already fired)
    task.spawn(function()
        self.IsUnlocked = self.UnlockService:IsUnlocked("TreeInteraction")
    end)

    -- Server confirms the unlock
    self.HarmonyService.TreeUnlocked:Connect(function()
        self.IsUnlocked = true
    end)

    -- Input: start holding
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not self.IsUnlocked then return end
        if self.IsHolding then return end

        local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
        local isTouch = input.UserInputType == Enum.UserInputType.Touch
        if not (isClick or isTouch) then return end

        if self:_IsTreeTarget(input.Position) then
            self.ActiveInput = input
            self.IsHolding   = true
            self:_StartInteraction()
        end
    end)

    -- Input: release
    UserInputService.InputEnded:Connect(function(input)
        if input ~= self.ActiveInput then return end
        self.ActiveInput = nil
        self.IsHolding   = false
        self:_StopInteraction()
    end)
end

-- Returns true when a screen position ray-casts onto the LargeTree
function HarmonyController:_IsTreeTarget(screenPos: Vector3): boolean
    local tree = Workspace:FindFirstChild("LargeTree")
    if not tree then return false end

    local camera = Workspace.CurrentCamera
    local ray    = camera:ScreenPointToRay(screenPos.X, screenPos.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = LocalPlayer.Character
    if character then
        params.FilterDescendantsInstances = { character }
    end

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if not result then return false end

    return result.Instance == tree or result.Instance:IsDescendantOf(tree)
end

function HarmonyController:_StartInteraction()
    if self.OnCooldown then return end

    self.IsConnecting = true
    self.barEnabled:set(true)
    self:_SpawnOrb()

    task.spawn(function()
        while self.IsConnecting do
            local dt = task.wait(0.05)
            self.Progress += dt * FILL_SPEED
            self.progressValue:set(self.Progress)

            if self.Progress >= MAX_PROGRESS then
                self.Progress = 0
                self.progressValue:set(0)
                self.IsConnecting = false
                self:_OnBarFilled()
            end
        end
    end)
end

function HarmonyController:_StopInteraction()
    self.IsConnecting = false
    self.barEnabled:set(false)
    self:_DespawnOrb()
    -- Progress is intentionally preserved so the next hold resumes where this one left off
end

function HarmonyController:_OnBarFilled()
    -- Tell the server to award 1 Harmony
    self.HarmonyService:EarnHarmony()

    -- Hide the bar and orb during the cooldown
    self.barEnabled:set(false)
    self:_DespawnOrb()

    -- 1-second cooldown before the bar can fill again
    self.OnCooldown = true
    task.delay(COOLDOWN, function()
        self.OnCooldown = false
        -- If the player is still holding, resume immediately
        if self.IsHolding then
            self:_StartInteraction()
        end
    end)
end

-- Spawn a glowing orb Part and a Beam connecting it to the tree
function HarmonyController:_SpawnOrb()
    self:_DespawnOrb() -- clean up any previous orb/beam before creating new ones

    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local tree = Workspace:FindFirstChild("LargeTree")
    if not tree then return end

    -- Resolve the tree part to attach the beam to
    local treePart: BasePart?
    if tree:IsA("BasePart") then
        treePart = tree
    else
        treePart = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
    end
    if not treePart then return end

    -- Create orb
    local orb      = Instance.new("Part")
    orb.Name       = "HarmonyOrb"
    orb.Shape      = Enum.PartType.Ball
    orb.Size       = Vector3.new(0.8, 0.8, 0.8)
    orb.CFrame     = root.CFrame * CFrame.new(ORB_OFFSET)
    orb.Anchored   = true
    orb.CanCollide = false
    orb.CastShadow = false
    orb.Material   = Enum.Material.Neon
    orb.Color      = ORB_COLOR
    orb.Parent     = Workspace

    local orbAttachment      = Instance.new("Attachment")
    orbAttachment.Position   = Vector3.zero
    orbAttachment.Parent     = orb

    -- Attachment on the tree
    local treeAttachment     = Instance.new("Attachment")
    treeAttachment.Position  = Vector3.zero
    treeAttachment.Parent    = treePart

    -- Beam between orb and tree
    local beam              = Instance.new("Beam")
    beam.Attachment0        = orbAttachment
    beam.Attachment1        = treeAttachment
    beam.Color              = ColorSequence.new(ORB_COLOR)
    beam.Width0             = 0.15
    beam.Width1             = 0.15
    beam.FaceCamera         = true
    beam.Transparency       = NumberSequence.new(0.3)
    beam.LightEmission      = 0.8
    beam.Parent             = orb

    self.OrbPart        = orb
    self.TreeAttachment = treeAttachment

    -- Track the player every frame so the orb stays in front of them as they move
    self.OrbTrackConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        orb.CFrame = rootPart.CFrame * CFrame.new(ORB_OFFSET)
    end)
end

function HarmonyController:_DespawnOrb()
    if self.OrbTrackConnection then
        self.OrbTrackConnection:Disconnect()
        self.OrbTrackConnection = nil
    end
    -- Destroying the orb cleans up orbAttachment and beam (they are parented to the orb)
    if self.OrbPart then
        self.OrbPart:Destroy()
        self.OrbPart = nil
    end
    -- Tree attachment must be cleaned up separately
    if self.TreeAttachment then
        self.TreeAttachment:Destroy()
        self.TreeAttachment = nil
    end
end

return HarmonyController
