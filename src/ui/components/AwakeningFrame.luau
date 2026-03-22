local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

local AwakeningConfig = require(ReplicatedStorage.Shared.Configs.AwakeningConfig)

local MAX_LEVEL = AwakeningConfig.MaxLevel

-- ────────────────────────────────────────────────────────────────────────────
-- Props:
--   AwakeningLevel  Value<number>
--   Awareness       Value<number>
--   OnAwaken        function()
-- ────────────────────────────────────────────────────────────────────────────
return function(scope, props)

    local isMaxed = scope:Computed(function(use)
        return use(props.AwakeningLevel) >= MAX_LEVEL
    end)

    local canAfford = scope:Computed(function(use)
        local level = use(props.AwakeningLevel)
        if level >= MAX_LEVEL then return false end
        local cost = AwakeningConfig.Levels[level + 1].Cost
        return use(props.Awareness) >= cost
    end)

    local costText = scope:Computed(function(use)
        local level = use(props.AwakeningLevel)
        if level >= MAX_LEVEL then return "" end
        local cost = AwakeningConfig.Levels[level + 1].Cost
        return `Cost: <font color="rgb(150, 255, 150)">{FormatNumber(cost)} Awareness</font>`
    end)

    -- One label per level (LayoutOrder 2–7)
    local levelLabels = {}
    for i, levelConfig in ipairs(AwakeningConfig.Levels) do
        levelLabels[i] = scope:New "TextLabel" {
            Name                   = "Level" .. i,
            LayoutOrder            = i + 1,
            Size                   = UDim2.fromScale(1, 0.065),
            BackgroundTransparency = 1,
            Text                   = string.format("%d. %s", i, levelConfig.Description),
            TextScaled             = true,
            TextXAlignment         = Enum.TextXAlignment.Left,
            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
            TextColor3             = Color3.fromRGB(220, 220, 220),
            [Fusion.Children] = {
                scope:New "UIStroke" { Thickness = 1 },
            },
        }
    end

    return scope:New "Frame" {
        Name                   = "AwakeningFrame",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,

        [Fusion.Children] = {

            scope:New "UIPadding" {
                PaddingTop    = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft   = UDim.new(0, 12),
                PaddingRight  = UDim.new(0, 12),
            },

            scope:New "UIListLayout" {
                FillDirection       = Enum.FillDirection.Vertical,
                Padding             = UDim.new(0.02, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder           = Enum.SortOrder.LayoutOrder,
            },

            -- Title ──────────────────────────────────────────────────────────
            scope:New "TextLabel" {
                Name                   = "Title",
                LayoutOrder            = 1,
                Size                   = UDim2.fromScale(1, 0.09),
                BackgroundTransparency = 1,
                Text                   = scope:Computed(function(use)
                    return "Awakening Level: " .. use(props.AwakeningLevel)
                end),
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 255, 255),
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 2 },
                },
            },

            -- Level descriptions (LayoutOrder 2–7) ──────────────────────────
            levelLabels,

            -- Warning ────────────────────────────────────────────────────────
            scope:New "TextLabel" {
                Name                   = "Warning",
                LayoutOrder            = 9,
                Size                   = UDim2.fromScale(0.9, 0.07),
                BackgroundTransparency = 1,
                Text                   = "⚠ Resets Awareness, Rebirths, Crystals & Astral Echoes",
                TextScaled             = true,
                TextWrapped            = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(220, 70, 70),
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 1 },
                },
            },

            -- Cost ───────────────────────────────────────────────────────────
            scope:New "TextLabel" {
                Name                   = "Cost",
                LayoutOrder            = 10,
                Size                   = UDim2.fromScale(1, 0.05),
                BackgroundTransparency = 1,
                Text                   = costText,
                RichText               = true,
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 255, 255),
                Visible                = scope:Computed(function(use) return not use(isMaxed) end),
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 1 },
                },
            },

            -- Awaken / Maxed button ──────────────────────────────────────────
            scope:New "TextButton" {
                LayoutOrder     = 11,
                Size            = UDim2.fromScale(0.5, 0.10),
                Text            = "",
                BackgroundColor3 = scope:Computed(function(use)
                    if use(isMaxed) then return Color3.fromRGB(255, 200, 50) end
                    return use(canAfford) and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 90)
                end),
                BorderSizePixel = 0,

                [Fusion.OnEvent "Activated"] = function()
                    if not Fusion.peek(isMaxed) and Fusion.peek(canAfford) then
                        if props.OnAwaken then
                            props.OnAwaken()
                        end
                    end
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0.1, 0),
                    },
                    scope:New "UIStroke" {
                        Thickness        = 4,
                        Color            = Color3.fromRGB(0, 0, 0),
                        ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
                    },
                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.9, 0.5),
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        BackgroundTransparency = 1,
                        ZIndex                 = 10,
                        Text                   = scope:Computed(function(use)
                            return use(isMaxed) and "MAXED" or "AWAKEN"
                        end),
                        TextScaled  = true,
                        TextColor3  = Color3.new(1, 1, 1),
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 3 },
                        },
                    },
                },
            },

        },
    }
end
