local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local ARROW_ASSET   = "rbxassetid://92841583022055"
local ABOVE_PART    = 4     -- extra studs above the top of the part
local BOUNCE_OFFSET = 1.2   -- studs up/down per bounce
local BOUNCE_TIME   = 0.6   -- seconds per half-cycle

local TutorialBeamTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("TutorialBeam")

return function(parent)
    local scope = scoped(Fusion)

    local TutorialService = Knit.GetService("TutorialService")

    local enabled = scope:Value(false)
    local adornee = scope:Value(nil)

    -- ── Beam state ────────────────────────────────────────────────────────────

    local activeBeam = nil
    local activeAttachmentA = nil -- on HumanoidRootPart
    local activeAttachmentB = nil -- on target part

    local function destroyBeam()
        if activeBeam then
            activeBeam:Destroy()
            activeBeam = nil
        end
        if activeAttachmentA then
            activeAttachmentA:Destroy()
            activeAttachmentA = nil
        end
        if activeAttachmentB then
            activeAttachmentB:Destroy()
            activeAttachmentB = nil
        end
    end

    local function spawnBeam(targetPart)
        destroyBeam()

        local character = Players.LocalPlayer.Character
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        activeAttachmentA = Instance.new("Attachment")
        activeAttachmentA.Name = "TutorialBeamA"
        activeAttachmentA.Parent = root

        activeAttachmentB = Instance.new("Attachment")
        activeAttachmentB.Name = "TutorialBeamB"
        activeAttachmentB.Parent = targetPart

        local beam = TutorialBeamTemplate:Clone()
        beam.Attachment0 = activeAttachmentA
        beam.Attachment1 = activeAttachmentB
        beam.Parent = root
        activeBeam = beam
    end

    local function resolvePart(pathArr)
        if not pathArr then return nil end
        local current = workspace
        for _, name in pathArr do
            current = current:FindFirstChild(name)
            if not current then return nil end
        end
        -- If it's a Model, use the primary part or any BasePart
        if current:IsA("Model") then
            return current.PrimaryPart or current:FindFirstChildWhichIsA("BasePart")
        end
        return current
    end

    -- Created after billboard declaration; forward-declared here
    local billboard

    local tweenUp, tweenDown

    local function rebuildTweens(baseOffset)
        local highOffset = baseOffset + Vector3.new(0, BOUNCE_OFFSET, 0)
        if tweenUp then
            tweenUp:Cancel()
        end
        if tweenDown then
            tweenDown:Cancel()
        end
        local tweenInfo = TweenInfo.new(BOUNCE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        tweenUp   = TweenService:Create(billboard, tweenInfo, { StudsOffset = highOffset })
        tweenDown = TweenService:Create(billboard, tweenInfo, { StudsOffset = baseOffset })
    end

    local function applyStage(stageConfig)
        destroyBeam()

        -- Beam stage: no arrow, just a beam from character to target
        if stageConfig and stageConfig.Beam then
            local targetPart = resolvePart(stageConfig.Beam)
            if targetPart then
                spawnBeam(targetPart)
                -- Re-attach beam when character respawns
                Players.LocalPlayer.CharacterAdded:Connect(function()
                    task.wait() -- let character load
                    if stageConfig.Beam then
                        spawnBeam(targetPart)
                    end
                end)
            end
            enabled:set(false)
            adornee:set(nil)
            return
        end

        if not stageConfig or not stageConfig.Adornee then
            enabled:set(false)
            adornee:set(nil)
            return
        end
        local part = resolvePart(stageConfig.Adornee)
        if not part then
            enabled:set(false)
            adornee:set(nil)
            return
        end

        -- Compute base offset from the part's height + extra clearance
        local halfHeight = 0
        if part:IsA("BasePart") then
            halfHeight = part.Size.Y / 2
        elseif part:IsA("Model") then
            local _, size = part:GetBoundingBox()
            halfHeight = size.Y / 2
        end
        local baseOffset = Vector3.new(0, halfHeight + ABOVE_PART, 0)

        billboard.StudsOffset = baseOffset
        adornee:set(part)
        enabled:set(true)

        rebuildTweens(baseOffset)
    end

    -- ── Billboard GUI ─────────────────────────────────────────────────────────

    billboard = scope:New "BillboardGui" {
        Name         = "TutorialIndicator",
        Parent       = parent,
        ResetOnSpawn = false,
        AlwaysOnTop  = true,
        Adornee      = adornee,
        Size         = UDim2.fromScale(3, 3),
        StudsOffset  = Vector3.new(0, ABOVE_PART, 0),
        Enabled      = enabled,

        [Fusion.Children] = {
            scope:New "ImageLabel" {
                Size                   = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Image                  = ARROW_ASSET,
                ScaleType              = Enum.ScaleType.Fit,
            },
        },
    }

    -- ── Highlight ─────────────────────────────────────────────────────────────

    local _highlight = scope:New "Highlight" {
        Parent              = workspace,
        Adornee             = adornee,
        Enabled             = enabled,
        FillTransparency    = 1,
        OutlineTransparency = 0,
        OutlineColor        = Color3.fromRGB(255, 220, 60),
        DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop,
    }

    -- Build initial tweens with the default offset so the loop can start
    rebuildTweens(Vector3.new(0, ABOVE_PART, 0))

    -- ── Bounce loop ───────────────────────────────────────────────────────────

    local alive = true
    task.spawn(function()
        while alive do
            tweenUp:Play()
            tweenUp.Completed:Wait()
            if not alive then break end
            tweenDown:Play()
            tweenDown.Completed:Wait()
        end
    end)

    -- ── Apply initial stage and listen for changes ────────────────────────────

    local _, stageConfig, _ = TutorialService:GetCurrentStage()
    applyStage(stageConfig)

    TutorialService.StageChanged:Connect(function(_index, cfg, _progress)
        applyStage(cfg)
    end)

    return function()
        alive = false
        destroyBeam()
        if tweenUp then
            tweenUp:Cancel()
        end
        if tweenDown then
            tweenDown:Cancel()
        end
        scope:doCleanup()
    end
end
