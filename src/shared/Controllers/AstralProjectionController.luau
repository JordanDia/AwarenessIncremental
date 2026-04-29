local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")
local Knit              = require(ReplicatedStorage.Packages.Knit)
local num               = require(ReplicatedStorage.Shared.Modules.Quicknum)
local Fusion          = require(ReplicatedStorage.Packages.Fusion)
local SpiritHealthBar = require("../../UI/components/SpiritHealthBar")
local scoped = Fusion.scoped

local Player = Players.LocalPlayer

local TutorialBeamTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("TutorialBeam")

local SPIRIT_SPAWN_INTERVAL  = 2
local SPIRIT_SPAWN_RADIUS    = 20
local SPIRIT_WALKSPEED       = 10
local SPIRIT_FADEIN_TIME     = 1
local SPIRIT_COLLISION_GROUP = "Spirit"

local PURIFY_DISTANCE = 15
local MAX_SPIRITS = 5

local SpiritContainer = {}

local AstralProjectionController = Knit.CreateController {
    Name = "AstralProjectionController",

    CurrentTarget = nil,
    PurifyConnection = nil,
    PurifyCleanup = nil,
    LastDamageTick = 0,
    Cooldown = 0.1,
    _isProjecting = false,
}

local FloatingTextComponent = require(ReplicatedStorage.UI.components.FloatingText)

local AstralProjectionService
local UpgradeService

local function showFloatingText(amount: number, color: Color3)
    local character = Players.LocalPlayer.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local scope = Fusion.scoped(Fusion, { FloatingTextComponent = FloatingTextComponent })

    local gui = scope:FloatingTextComponent {
        Amount    = amount,
        Adornee   = head,
        TextColor3 = color,
    }
    gui.Parent = Players.LocalPlayer.PlayerGui

    local randomX = math.random(-200, 200) / 100
    local randomY = math.random(100, 200) / 100
    gui.StudsOffset = Vector3.new(randomX, randomY, 0)

    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    TweenService:Create(gui, tweenInfo, { StudsOffset = Vector3.new(randomX, randomY + 2.5, 0) }):Play()

    local textLabel = gui:FindFirstChildWhichIsA("TextLabel")
    if textLabel then
        TweenService:Create(textLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    end

    task.delay(2, function()
        scope:doCleanup()
    end)
end

local _lastEssences     = 0
local _lastDarkEssences = 0

local _tutorialBeam        = nil
local _tutorialAttachA     = nil
local _tutorialAttachB     = nil

local function destroyTutorialBeam()
    if _tutorialBeam then
        _tutorialBeam:Destroy()
        _tutorialBeam = nil
    end
    if _tutorialAttachA then
        _tutorialAttachA:Destroy()
        _tutorialAttachA = nil
    end
    if _tutorialAttachB then
        _tutorialAttachB:Destroy()
        _tutorialAttachB = nil
    end
end

local function spawnTutorialBeam()
    destroyTutorialBeam()
    local character = Player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local targetPart = workspace:FindFirstChild("AstralProjectionPart")
    if not targetPart then return end

    _tutorialAttachA = Instance.new("Attachment")
    _tutorialAttachA.Name = "TutorialBeamA"
    _tutorialAttachA.Parent = root

    _tutorialAttachB = Instance.new("Attachment")
    _tutorialAttachB.Name = "TutorialBeamB"
    _tutorialAttachB.Parent = targetPart

    local beam = TutorialBeamTemplate:Clone()
    beam.Attachment0 = _tutorialAttachA
    beam.Attachment1 = _tutorialAttachB
    beam.Parent = root
    _tutorialBeam = beam
end

function AstralProjectionController:KnitStart()
    AstralProjectionService = Knit.GetService("AstralProjectionService")
    UpgradeService = Knit.GetService("UpgradeService")
    local AwakeningService = Knit.GetService("AwakeningService")

    AwakeningService.AstralProjectionBeamChanged:Connect(function(visible)
        if visible then
            spawnTutorialBeam()
            -- Re-attach on respawn while beam is active
            Player.CharacterAdded:Connect(function()
                task.wait()
                if _tutorialBeam then
                    spawnTutorialBeam()
                end
            end)
        else
            destroyTutorialBeam()
        end
    end)

    AstralProjectionService.EssencesChanged:Connect(function(newTotal)
        if num.gt(newTotal, _lastEssences) then
            showFloatingText(num.sub(newTotal, _lastEssences), Color3.fromRGB(255, 255, 255))
        end
        _lastEssences = newTotal
    end)

    AstralProjectionService.DarkEssencesChanged:Connect(function(newTotal)
        if num.gt(newTotal, _lastDarkEssences) then
            showFloatingText(num.sub(newTotal, _lastDarkEssences), Color3.fromRGB(220, 30, 30))
        end
        _lastDarkEssences = newTotal
    end)

    AstralProjectionService.ProjectionStarted:Connect(function()
        self._isProjecting = true
        self:_StartSpiritSpawnLoop()
        self:_StartPurifyLoop()
        self:_StartHighlightPulse()
    end)

    AstralProjectionService.ProjectionEnded:Connect(function()
        self._isProjecting = false
        -- Destroy all active spirits
        for _, spirit in SpiritContainer do
            if spirit and spirit.Parent then
                spirit:Destroy()
            end
        end
        table.clear(SpiritContainer)
        -- Clean up any active purify effects (orb, beams, sound)
        if self.PurifyCleanup then
            self.PurifyCleanup()
            self.PurifyCleanup = nil
        end
        -- Stop highlight pulse
        if self._highlightPulseCleanup then
            self._highlightPulseCleanup()
            self._highlightPulseCleanup = nil
        end
    end)

    AstralProjectionService.DarkSpiritSpawned:Connect(function()
        self:_SpawnDarkSpirit()
    end)
end

function AstralProjectionController:_FindClosestSpirit()
    local character = Player.Character
    if not character then return nil end

    local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end

    local closestSpirit = nil
    local closestDist   = math.huge

    for _, spirit in SpiritContainer do
        if spirit.Parent then
            local spiritRoot = spirit.PrimaryPart
            if spiritRoot then
                local dist = (spiritRoot.Position - rootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist   = dist
                    closestSpirit = spirit
                end
            end
        end
    end

    return closestSpirit, closestDist
end


local PULSE_TIME = 0.8

function AstralProjectionController:_StartHighlightPulse()
    local character = Player.Character
    if not character then return end
    local highlight = character:FindFirstChildOfClass("Highlight")
    if not highlight then return end

    local baseTransparency = highlight.FillTransparency
    local alive = true

    local tweenIn  = TweenService:Create(highlight, TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { FillTransparency = 0 })
    local tweenOut = TweenService:Create(highlight, TweenInfo.new(PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { FillTransparency = baseTransparency })

    task.spawn(function()
        while alive do
            tweenIn:Play()
            tweenIn.Completed:Wait()
            if not alive then break end
            tweenOut:Play()
            tweenOut.Completed:Wait()
        end
        -- Restore original transparency
        highlight.FillTransparency = baseTransparency
    end)

    self._highlightPulseCleanup = function()
        alive = false
        tweenIn:Cancel()
        tweenOut:Cancel()
    end
end

function AstralProjectionController:_StartPurifyLoop()
    task.spawn(function()
        while task.wait(0.3) do
            if not self._isProjecting then continue end
            if self.CurrentTarget then continue end

            local closestSpirit, dist = self:_FindClosestSpirit()
            if closestSpirit and dist < PURIFY_DISTANCE then
                self.CurrentTarget = closestSpirit
                self:_StartPurify(closestSpirit)
            end
        end
    end)
end

local BEAM_COUNT        = 4
local BEAM_COLORS       = {
    Color3.fromRGB(180, 120, 255),
    Color3.fromRGB(255, 180, 80),
    Color3.fromRGB(80,  220, 255),
    Color3.fromRGB(255, 255, 255),
}
local DARK_BEAM_COLORS  = {
    Color3.fromRGB(255, 30,  30),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(200, 0,   0),
}
local DARK_ORB_COLOR    = Color3.fromRGB(220, 0, 0)
local ORB_SIZE_MIN = Vector3.new(0.7, 0.7, 0.7)
local ORB_SIZE_MAX = Vector3.new(1.3, 1.3, 1.3)
local ORB_PULSE_TIME = 0.6

local function _pulseOrb(orb: BasePart)
    local grow, shrink
    grow = function()
        if not orb.Parent then return end
        TweenService:Create(orb, TweenInfo.new(ORB_PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = ORB_SIZE_MAX }):Play()
        task.delay(ORB_PULSE_TIME, shrink)
    end
    shrink = function()
        if not orb.Parent then return end
        TweenService:Create(orb, TweenInfo.new(ORB_PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = ORB_SIZE_MIN }):Play()
        task.delay(ORB_PULSE_TIME, grow)
    end
    grow()
end

function AstralProjectionController:_StartPurify(spirit: Model)
    local character = Player.Character
    local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local isDark   = spirit.Name == "DarkSpirit"
    local orbColor = isDark and DARK_ORB_COLOR or Color3.fromRGB(200, 150, 255)
    local palette  = isDark and DARK_BEAM_COLORS or BEAM_COLORS

    -- Orb: small sphere 2 studs in front of the player
    local orb = Instance.new("Part")
    orb.Shape       = Enum.PartType.Ball
    orb.Size        = Vector3.new(1, 1, 1)
    orb.Anchored    = true
    orb.CanCollide  = false
    orb.CastShadow  = false
    orb.Material    = Enum.Material.Neon
    orb.Color       = orbColor
    orb.CFrame      = rootPart.CFrame * CFrame.new(0, 0, -2)
    orb.Parent      = workspace
    _pulseOrb(orb)

    -- Attachments: one on the orb, one on the spirit
    local attOrb = Instance.new("Attachment")
    attOrb.Parent = orb
    local attSpirit = Instance.new("Attachment")
    attSpirit.Parent = spirit.PrimaryPart

    -- Create multiple beams with different phase offsets
    local beams = {}
    for i = 1, BEAM_COUNT do
        local beam = Instance.new("Beam")
        beam.Attachment0    = attOrb
        beam.Attachment1    = attSpirit
        beam.FaceCamera     = true
        beam.Color          = ColorSequence.new(palette[i] or Color3.new(1, 1, 1))
        beam.Transparency   = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6) })
        beam.Width0         = 0.15
        beam.Width1         = 0.08
        beam.LightEmission  = 1
        beam.LightInfluence = 0
        beam.Segments       = 20
        beam.Parent         = workspace
        beams[i] = beam
    end

    local purifyingSound = SoundService:WaitForChild("Purifying")
    purifyingSound.Volume = 0
    purifyingSound:Play()
    TweenService:Create(purifyingSound, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Volume = 1 }):Play()

    local function cleanup()
        self.CurrentTarget = nil
        self.PurifyCleanup = nil
        if self.PurifyConnection then
            self.PurifyConnection:Disconnect()
            self.PurifyConnection = nil
        end
        local fadeOut = TweenService:Create(purifyingSound, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Volume = 0 })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            purifyingSound:Stop()
        end)
        orb:Destroy()
        attOrb:Destroy()
        attSpirit:Destroy()
        for _, b in beams do
            b:Destroy()
        end
    end
    self.PurifyCleanup = cleanup

    local humanoid = spirit:FindFirstChildOfClass("Humanoid")
    if humanoid then
        self.PurifyConnection = RunService.Heartbeat:Connect(function()
            if not spirit.Parent or humanoid.Health <= 0 then
                cleanup()
                return
            end

            -- Keep orb 2 studs in front of player
            local cf = rootPart.CFrame * CFrame.new(0, 0, -2)
            orb.CFrame = cf

            -- Animate beam curve widths with sine waves, different phase per beam
            local t = os.clock()
            for i, beam in beams do
                local phase  = (i - 1) * (math.pi * 2 / BEAM_COUNT)
                local curve  = math.sin(t * 2 + phase) * 3
                beam.CurveSize0 = curve
                beam.CurveSize1 = -curve
            end

            if os.clock() - self.LastDamageTick < self.Cooldown then return end
            self.LastDamageTick = os.clock()

            local damage = UpgradeService:GetUpgradeEffect("SpiritDamage")
            humanoid:TakeDamage(damage)
        end)

        humanoid.Died:Connect(function()
            cleanup()
            SoundService:WaitForChild("Purified"):Play()
            if spirit.Name == "DarkSpirit" then
                AstralProjectionService:PurifyDarkSpirit()
            else
                AstralProjectionService:PurifySpirit()
            end
        end)
    end
end


function AstralProjectionController:_StartSpiritSpawnLoop()
    local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Spirit")

    task.spawn(function()
        while true do
            if self._isProjecting and #SpiritContainer < MAX_SPIRITS then
                local character = Player.Character
                local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    self:_SpawnSpirit(template, rootPart)
                end
            end
            task.wait(SPIRIT_SPAWN_INTERVAL)
        end
    end)
end

function AstralProjectionController:_SpawnSpirit(template: Model, rootPart: BasePart)
    local angle    = math.random() * math.pi * 2
    local distance = math.random(5, SPIRIT_SPAWN_RADIUS)
    local offset   = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

    local spirit = template:Clone()
    spirit.Name  = "AstralSpirit"

    local humanoid = spirit:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed           = SPIRIT_WALKSPEED
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
        humanoid.NameDisplayDistance = 0
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

        humanoid.BreakJointsOnDeath = false

        humanoid.Died:Connect(function()
            -- Remove from container immediately so it can't be re-targeted during the death tween
            table.remove(SpiritContainer, table.find(SpiritContainer, spirit) or 0)

            local spiritHead = spirit:FindFirstChild("Head")
            if spiritHead then
                local hb = spiritHead:FindFirstChildOfClass("BillboardGui")
                if hb then
                    hb:Destroy()
                end
            end

            local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            local riseTween = TweenService:Create(spirit.PrimaryPart, tweenInfo, {
                CFrame = spirit.PrimaryPart.CFrame * CFrame.new(0, 10, 0)
            })

            for _, part in spirit:GetDescendants() do
                if part:IsA("BasePart") and part.Name ~= "Head" then
                    TweenService:Create(part, tweenInfo, { Transparency = 1 }):Play()
                end
            end

            riseTween:Play()

            task.delay(1.3, function()
                spirit:Destroy()
            end)
        end)
    end

    -- Health bar
    local head = spirit:FindFirstChild("Head")
    if head and humanoid then
        local spiritScope  = scoped(Fusion, {
            SpiritHealthBar = SpiritHealthBar,
        })

        local healthValue  = spiritScope:Value(humanoid.Health)
        local maxHpValue   = spiritScope:Value(humanoid.MaxHealth)

        local bar = SpiritHealthBar(spiritScope, {
            Health    = healthValue,
            MaxHealth = maxHpValue,
        })
        bar.Parent = head

        local conn = humanoid.HealthChanged:Connect(function(hp)
            healthValue:set(hp)
        end)

        spirit.AncestryChanged:Connect(function()
            if not spirit.Parent then
                conn:Disconnect()
                Fusion.doCleanup(spiritScope)
            end
        end)
    end

    local savedTransparencies = {}
    for _, part in spirit:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "Head" then
            savedTransparencies[part] = part.Transparency
            part.Transparency   = 1
            part.CanCollide     = false
            part.CollisionGroup = SPIRIT_COLLISION_GROUP
        end
    end

    table.insert(SpiritContainer, spirit)
    spirit:PivotTo(CFrame.new(rootPart.Position + offset))
    spirit.Parent = workspace

    SoundService:WaitForChild("SpiritSpawn"):Play()

    local tweenInfo = TweenInfo.new(SPIRIT_FADEIN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for part, original in savedTransparencies do
        TweenService:Create(part, tweenInfo, { Transparency = original }):Play()
    end

    local STOP_DISTANCE = 8

    if humanoid then
        task.spawn(function()
            while spirit and spirit.Parent do
                local spiritRoot = spirit.PrimaryPart
                if rootPart and rootPart.Parent and spiritRoot then
                    local dist = (spiritRoot.Position - rootPart.Position).Magnitude
                    if dist > STOP_DISTANCE then
                        humanoid:MoveTo(rootPart.Position)
                    else
                        humanoid:MoveTo(spiritRoot.Position)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end


function AstralProjectionController:_SpawnDarkSpirit()
    local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("DarkSpirit")
    local character = Player.Character
    local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local angle  = math.random() * math.pi * 2
    local offset = Vector3.new(math.cos(angle) * 10, 0, math.sin(angle) * 10)

    local spirit   = template:Clone()
    spirit.Name    = "DarkSpirit"
    local humanoid = spirit:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed           = SPIRIT_WALKSPEED
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
        humanoid.NameDisplayDistance = 0
        humanoid.BreakJointsOnDeath  = false

        humanoid.Died:Connect(function()
            table.remove(SpiritContainer, table.find(SpiritContainer, spirit) or 0)

            local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            TweenService:Create(spirit.PrimaryPart, tweenInfo, {
                CFrame = spirit.PrimaryPart.CFrame * CFrame.new(0, 10, 0)
            }):Play()
            for _, part in spirit:GetDescendants() do
                if part:IsA("BasePart") then
                    TweenService:Create(part, tweenInfo, { Transparency = 1 }):Play()
                end
            end
            task.delay(1.3, function()
                spirit:Destroy()
            end)
        end)
    end

    -- Health bar
    local head = spirit:FindFirstChild("Head")
    if head and humanoid then
        local spiritScope = scoped(Fusion, { SpiritHealthBar = SpiritHealthBar })
        local healthValue = spiritScope:Value(humanoid.Health)
        local maxHpValue  = spiritScope:Value(humanoid.MaxHealth)
        local bar = SpiritHealthBar(spiritScope, { Health = healthValue, MaxHealth = maxHpValue })
        bar.Parent = head
        local conn = humanoid.HealthChanged:Connect(function(hp)
            healthValue:set(hp)
        end)
        spirit.AncestryChanged:Connect(function()
            if not spirit.Parent then
                conn:Disconnect()
                Fusion.doCleanup(spiritScope)
            end
        end)
    end

    for _, part in spirit:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide     = false
            part.CollisionGroup = SPIRIT_COLLISION_GROUP
        end
    end

    table.insert(SpiritContainer, spirit)
    spirit:PivotTo(CFrame.new(rootPart.Position + offset))
    spirit.Parent = workspace

    SoundService:WaitForChild("DarkSpiritSpawn"):Play()

    -- Move toward player, same stop distance
    if humanoid then
        task.spawn(function()
            while spirit and spirit.Parent do
                local spiritRoot = spirit.PrimaryPart
                if rootPart and rootPart.Parent and spiritRoot then
                    local dist = (spiritRoot.Position - rootPart.Position).Magnitude
                    if dist > 8 then
                        humanoid:MoveTo(rootPart.Position)
                    else
                        humanoid:MoveTo(spiritRoot.Position)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end

return AstralProjectionController
