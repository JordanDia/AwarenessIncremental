local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)

-- Props:
--   Visible           (boolean | Value<boolean>)
--   OnClose           (function)
--   Level             (Value<number>)
--   AwarenessTotal    (Value<number>)
--   Rebirths          (Value<number>)
--   RebirthsTotal     (Value<number>)
--   CrystalsTotal     (Value<number>)
--   AstralEchoesTotal (Value<number>)
--   FirstPlayed       (Value<string>)

return function(scope: Fusion.Scope, props)
    local player = Players.LocalPlayer

    -- Load headshot asynchronously
    local headshotUrl = scope:Value("")
    task.spawn(function()
        local url, _ = Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
        headshotUrl:set(url)
    end)

    -- Stat tile: value is a reactive Value<number>, displayed with FormatNumber
    local function StatTile(order: number, label: string, value: Fusion.UsedAs<number>, color: Color3)
        return scope:New "Frame" {
            LayoutOrder      = order,
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),

            [Fusion.Children] = {
                scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
                scope:New "UIPadding" {
                    PaddingTop    = UDim.new(0.08, 0),
                    PaddingBottom = UDim.new(0.08, 0),
                    PaddingLeft   = UDim.new(0.08, 0),
                    PaddingRight  = UDim.new(0.08, 0),
                },
                scope:New "UIListLayout" {
                    FillDirection     = Enum.FillDirection.Vertical,
                    SortOrder         = Enum.SortOrder.LayoutOrder,
                    Padding           = UDim.new(0.05, 0),
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                },
                scope:New "TextLabel" {
                    LayoutOrder          = 1,
                    Size                 = UDim2.new(1, 0, 0.35, 0),
                    BackgroundTransparency = 1,
                    Text                 = label,
                    TextColor3           = Color3.fromRGB(155, 155, 170),
                    FontFace             = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                    TextScaled           = true,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    TextTruncate         = Enum.TextTruncate.AtEnd,
                },
                scope:New "TextLabel" {
                    LayoutOrder          = 2,
                    Size                 = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    Text                 = scope:Computed(function(use)
                        return FormatNumber(use(value), ".##")
                    end),
                    TextColor3           = color,
                    FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                    TextScaled           = true,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                },
            },
        }
    end

    return scope:New "Frame" {
        Name             = "ProfilePanel",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.fromScale(0.5, 0.5),
        Size             = UDim2.fromScale(0.5, 0.78),
        BackgroundColor3 = Color3.fromRGB(20, 20, 27),
        BorderSizePixel  = 0,
        Visible          = props.Visible,

        [Fusion.Children] = {
            scope:New "UICorner" { CornerRadius = UDim.new(0.025, 0) },
            scope:New "UIStroke" {
                Color     = Color3.fromRGB(55, 55, 70),
                Thickness = 1.5,
            },
            scope:New "UIPadding" {
                PaddingTop    = UDim.new(0.04, 0),
                PaddingBottom = UDim.new(0.04, 0),
                PaddingLeft   = UDim.new(0.04, 0),
                PaddingRight  = UDim.new(0.04, 0),
            },
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder     = Enum.SortOrder.LayoutOrder,
                Padding       = UDim.new(0.03, 0),
            },

            -- Header row
            scope:New "Frame" {
                LayoutOrder          = 1,
                Size                 = UDim2.new(1, 0, 0.07, 0),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "TextLabel" {
                        AnchorPoint          = Vector2.new(0, 0.5),
                        Position             = UDim2.fromScale(0, 0.5),
                        Size                 = UDim2.new(0.88, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text                 = "My Profile",
                        TextColor3           = Color3.fromRGB(255, 255, 255),
                        FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextScaled           = true,
                        TextXAlignment       = Enum.TextXAlignment.Left,
                    },
                    scope:New "ImageButton" {
                        AnchorPoint        = Vector2.new(1, 0.5),
                        Position           = UDim2.fromScale(1, 0.5),
                        Size               = UDim2.fromScale(0, 1),
                        BackgroundTransparency = 1,
                        Image              = "rbxassetid://0", -- replace with close icon
                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnClose then
                                props.OnClose()
                            end
                        end,
                        [Fusion.Children] = {
                            scope:New "UIAspectRatioConstraint" { AspectRatio = 1 },
                        },
                    },
                },
            },

            -- Profile card
            scope:New "Frame" {
                LayoutOrder      = 2,
                Size             = UDim2.new(1, 0, 0.22, 0),
                BackgroundColor3 = Color3.fromRGB(30, 30, 42),

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.08, 0) },

                    -- Circle headshot (square via aspect ratio constraint)
                    scope:New "ImageLabel" {
                        AnchorPoint      = Vector2.new(0, 0.5),
                        Position         = UDim2.fromScale(0.02, 0.5),
                        Size             = UDim2.fromScale(0, 0.8),
                        BackgroundColor3 = Color3.fromRGB(45, 45, 58),
                        Image            = headshotUrl,
                        ScaleType        = Enum.ScaleType.Crop,

                        [Fusion.Children] = {
                            scope:New "UIAspectRatioConstraint" {
                                AspectRatio  = 1,
                                DominantAxis = Enum.DominantAxis.Height,
                            },
                            scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
                            scope:New "UIStroke" {
                                Color     = Color3.fromRGB(70, 70, 90),
                                Thickness = 2,
                            },
                        },
                    },

                    -- Info column (right of headshot)
                    scope:New "Frame" {
                        AnchorPoint          = Vector2.new(0, 0.5),
                        Position             = UDim2.fromScale(0.22, 0.5),
                        Size                 = UDim2.new(0.75, 0, 0.85, 0),
                        BackgroundTransparency = 1,

                        [Fusion.Children] = {
                            scope:New "UIListLayout" {
                                FillDirection     = Enum.FillDirection.Vertical,
                                SortOrder         = Enum.SortOrder.LayoutOrder,
                                Padding           = UDim.new(0.05, 0),
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            },

                            -- Display name
                            scope:New "TextLabel" {
                                LayoutOrder          = 1,
                                Size                 = UDim2.new(1, 0, 0.28, 0),
                                BackgroundTransparency = 1,
                                Text                 = player.DisplayName,
                                TextColor3           = Color3.fromRGB(255, 255, 255),
                                FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                                TextScaled           = true,
                                TextXAlignment       = Enum.TextXAlignment.Left,
                            },

                            -- @handle
                            scope:New "TextLabel" {
                                LayoutOrder          = 2,
                                Size                 = UDim2.new(1, 0, 0.2, 0),
                                BackgroundTransparency = 1,
                                Text                 = "@" .. player.Name,
                                TextColor3           = Color3.fromRGB(130, 130, 150),
                                FontFace             = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                                TextScaled           = true,
                                TextXAlignment       = Enum.TextXAlignment.Left,
                            },

                            -- Level pill + First played row
                            scope:New "Frame" {
                                LayoutOrder          = 3,
                                Size                 = UDim2.new(1, 0, 0.22, 0),
                                BackgroundTransparency = 1,

                                [Fusion.Children] = {
                                    -- Level pill
                                    scope:New "TextLabel" {
                                        AnchorPoint      = Vector2.new(0, 0.5),
                                        Position         = UDim2.fromScale(0, 0.5),
                                        Size             = UDim2.fromScale(0.14, 1),
                                        BackgroundColor3 = Color3.fromRGB(50, 90, 200),
                                        Text             = scope:Computed(function(use)
                                            return "Lv. " .. use(props.Level)
                                        end),
                                        TextColor3       = Color3.fromRGB(255, 255, 255),
                                        FontFace         = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                                        TextScaled       = true,

                                        [Fusion.Children] = {
                                            scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
                                        },
                                    },

                                    -- First played
                                    scope:New "TextLabel" {
                                        AnchorPoint          = Vector2.new(1, 0.5),
                                        Position             = UDim2.fromScale(1, 0.5),
                                        Size                 = UDim2.fromScale(0.68, 1),
                                        BackgroundTransparency = 1,
                                        Text                 = props.FirstPlayed,
                                        TextColor3           = Color3.fromRGB(120, 120, 140),
                                        FontFace             = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                                        TextScaled           = true,
                                        TextXAlignment       = Enum.TextXAlignment.Right,
                                    },
                                },
                            },
                        },
                    },
                },
            },

            -- Lifetime stats section
            scope:New "Frame" {
                LayoutOrder          = 3,
                Size                 = UDim2.fromScale(1, 0.56),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder     = Enum.SortOrder.LayoutOrder,
                        Padding       = UDim.new(0.04, 0),
                    },

                    scope:New "TextLabel" {
                        LayoutOrder          = 1,
                        Size                 = UDim2.fromScale(1, 0.08),
                        BackgroundTransparency = 1,
                        Text                 = "Lifetime Stats",
                        TextColor3           = Color3.fromRGB(190, 190, 205),
                        FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextScaled           = true,
                        TextXAlignment       = Enum.TextXAlignment.Left,
                    },

                    -- Stats grid (3 rows x 3 cols)
                    -- CellSize.X = (1 - 2*0.02) / 3 = 0.32  → exactly 3 per row at any resolution
                    -- CellSize.Y = 0.30 with gap 0.04 → 3*0.30 + 2*0.04 = 0.98, safe 2% margin avoids pixel-clipping
                    scope:New "Frame" {
                        LayoutOrder          = 2,
                        Size                 = UDim2.fromScale(1, 0.88),
                        BackgroundTransparency = 1,

                        [Fusion.Children] = {
                            scope:New "UIGridLayout" {
                                CellSize    = UDim2.fromScale(0.32, 0.30),
                                CellPadding = UDim2.fromScale(0.02, 0.04),
                                SortOrder   = Enum.SortOrder.LayoutOrder,
                            },

                            StatTile(1, "All-Time Awareness", props.AwarenessTotal,    Color3.fromRGB(255, 215, 0)),
                            StatTile(2, "Crystals",           props.CrystalsTotal,     Color3.fromRGB(170, 80,  255)),
                            StatTile(3, "Astral Echoes",      props.AstralEchoesTotal, Color3.fromRGB(0,   210, 200)),
                            StatTile(4, "Rebirths",           props.Rebirths,          Color3.fromRGB(0,   153, 255)),
                            StatTile(5, "Total Rebirths",     props.RebirthsTotal,     Color3.fromRGB(0,   153, 255)),
                            StatTile(6, "Robux Spent",        props.RobuxSpent,        Color3.fromRGB(100, 220, 100)),
                        },
                    },
                },
            },
        },
    }
end
