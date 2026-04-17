local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit           = require(ReplicatedStorage.Packages.Knit)
local Fusion         = require(ReplicatedStorage.Packages.Fusion)
local scoped         = Fusion.scoped

local NORMAL_SIZE = UDim2.fromScale(4, 1.2)   -- studs, scale maps 1:1 in BillboardGui
local BUBBLE_SIZE = UDim2.fromScale(4.6, 1.5)
local BUBBLE_IN   = TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local BUBBLE_OUT  = TweenInfo.new(0.1,  Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function formatCombo(value: number): string
    -- Show one decimal only when needed: 1 → "1x", 1.1 → "1.1x"
    local s = value % 1 == 0 and tostring(math.floor(value)) or string.format("%.1f", value)
    return s .. "x Combo"
end

-- Mounts the BillboardGui onto `head` and returns a cleanup function.
local function mountOnHead(head: BasePart, comboText, visible)
    local scope = scoped(Fusion)

    local billboard = scope:New "BillboardGui" {
        Name            = "CrystalComboGui",
        Parent          = head,
        Adornee         = head,
        Size            = NORMAL_SIZE,
        StudsOffset     = Vector3.new(0, 2.5, 0),
        AlwaysOnTop     = true,
        ResetOnSpawn    = false,
        -- Only the local player sees this
        MaxDistance     = 0,

        Enabled         = visible,

        [Fusion.Children] = {
            scope:New "TextLabel" {
                Size                   = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text                   = comboText,
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 220, 60),
                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                        Color     = Color3.fromRGB(80, 60, 0),
                    },
                },
            },
        },
    }

    local function bubble()
        local t1 = TweenService:Create(billboard, BUBBLE_IN,  { Size = BUBBLE_SIZE })
        local t2 = TweenService:Create(billboard, BUBBLE_OUT, { Size = NORMAL_SIZE })
        t1:Play()
        t1.Completed:Connect(function()
            t2:Play()
        end)
    end

    return billboard, bubble, function()
        scope:doCleanup()
    end
end

-- Top-level factory — manages the full lifecycle including respawns.
return function()
    local CrystalComboService = Knit.GetService("CrystalComboService")
    local scope = scoped(Fusion)

    local comboText = scope:Value("1x Combo")
    local visible   = scope:Value(false)

    local currentCleanup = nil
    local lastBubble     = nil

    local function attachToCharacter(character: Model)
        if currentCleanup then
            currentCleanup()
            currentCleanup = nil
        end

        local head = character:WaitForChild("Head")
        local _, bubble, cleanup = mountOnHead(head, comboText, visible)
        currentCleanup = cleanup
        lastBubble = bubble
    end

    -- Connect to respawn
    Players.LocalPlayer.CharacterAdded:Connect(attachToCharacter)
    if Players.LocalPlayer.Character then
        attachToCharacter(Players.LocalPlayer.Character)
    end

    -- Listen for combo updates from server
    CrystalComboService.ComboChanged:Connect(function(value)
        if value <= 0 then
            visible:set(false)
            return
        end
        comboText:set(formatCombo(value))
        visible:set(true)
        if lastBubble then
            lastBubble()
        end
    end)

    return function()
        if currentCleanup then currentCleanup() end
        scope:doCleanup()
    end
end
