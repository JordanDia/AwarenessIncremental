local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local UpdateLogConfig = require(ReplicatedStorage.Shared.Configs.UpdateLogConfig)

local COLOR_HEADER  = Color3.fromRGB(80, 200, 200)
local COLOR_BG      = Color3.fromRGB(30, 32, 38)
local COLOR_CARD    = Color3.fromRGB(45, 48, 55)
local COLOR_DIVIDER = Color3.fromRGB(65, 68, 78)
local COLOR_VERSION = Color3.fromRGB(80, 200, 120)
local COLOR_DATE    = Color3.fromRGB(160, 165, 175)
local COLOR_WHITE   = Color3.fromRGB(255, 255, 255)
local COLOR_CLOSE   = Color3.fromRGB(200, 60, 60)

-- Props:
--   Visible  Value<boolean>
--   OnClose  function

return function(scope, props)

    local function VersionCard(entry)
        -- Bullet point children
        local bullets = {}
        for _, bullet in ipairs(entry.Bullets) do
            table.insert(bullets, scope:New "TextLabel" {
                Size                   = UDim2.fromScale(1, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text                   = "• " .. bullet,
                TextScaled             = false,
                TextSize               = 15,
                TextWrapped            = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Regular),
                TextColor3             = COLOR_WHITE,
                TextXAlignment         = Enum.TextXAlignment.Center,
            })
        end

        return scope:New "Frame" {
            Size          = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = COLOR_CARD,
            BorderSizePixel  = 0,

            [Fusion.Children] = {
                scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
                scope:New "UIPadding" {
                    PaddingTop    = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 12),
                    PaddingLeft   = UDim.new(0, 12),
                    PaddingRight  = UDim.new(0, 12),
                },
                scope:New "UIListLayout" {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding       = UDim.new(0, 6),
                    SortOrder     = Enum.SortOrder.LayoutOrder,
                },

                -- Header row: version badge + title + date
                scope:New "Frame" {
                    LayoutOrder   = 1,
                    Size          = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,

                    [Fusion.Children] = {
                        scope:New "UIListLayout" {
                            FillDirection       = Enum.FillDirection.Horizontal,
                            VerticalAlignment   = Enum.VerticalAlignment.Center,
                            Padding             = UDim.new(0, 8),
                            SortOrder           = Enum.SortOrder.LayoutOrder,
                        },

                        -- Version badge
                        scope:New "TextLabel" {
                            LayoutOrder      = 1,
                            Size             = UDim2.fromOffset(56, 26),
                            BackgroundColor3 = COLOR_VERSION,
                            BorderSizePixel  = 0,
                            Text             = entry.Version,
                            TextScaled       = true,
                            FontFace         = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                            TextColor3       = COLOR_WHITE,
                            [Fusion.Children] = {
                                scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
                                scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0,0,0) },
                            },
                        },

                        -- Title
                        scope:New "TextLabel" {
                            LayoutOrder            = 2,
                            Size                   = UDim2.fromScale(0, 0),
                            AutomaticSize          = Enum.AutomaticSize.XY,
                            BackgroundTransparency = 1,
                            Text                   = entry.Title,
                            TextSize               = 17,
                            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                            TextColor3             = COLOR_WHITE,
                        },

                        -- Date
                        scope:New "TextLabel" {
                            LayoutOrder            = 3,
                            Size                   = UDim2.fromScale(0, 0),
                            AutomaticSize          = Enum.AutomaticSize.XY,
                            BackgroundTransparency = 1,
                            Text                   = entry.Date,
                            TextSize               = 13,
                            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Regular),
                            TextColor3             = COLOR_DATE,
                        },
                    },
                },

                -- Divider
                scope:New "Frame" {
                    LayoutOrder      = 2,
                    Size             = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = COLOR_DIVIDER,
                    BorderSizePixel  = 0,
                },

                -- Bullet points
                scope:New "Frame" {
                    LayoutOrder   = 3,
                    Size          = UDim2.fromScale(1, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,

                    [Fusion.Children] = {
                        scope:New "UIListLayout" {
                            FillDirection = Enum.FillDirection.Vertical,
                            Padding       = UDim.new(0, 4),
                            SortOrder     = Enum.SortOrder.LayoutOrder,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        },
                        table.unpack(bullets),
                    },
                },
            },
        }
    end

    -- Build all version cards
    local cards = {}
    for _, entry in ipairs(UpdateLogConfig) do
        table.insert(cards, VersionCard(entry))
    end

    return scope:New "Frame" {
        Name                   = "UpdateLogFrame",
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        Size                   = UDim2.fromScale(0.42, 0.82),
        BackgroundColor3       = COLOR_BG,
        BorderSizePixel        = 0,
        Visible                = props.Visible,
        ZIndex                 = 10,

        [Fusion.Children] = {
            scope:New "UICorner" { CornerRadius = UDim.new(0, 14) },
            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },

            -- Header bar
            scope:New "Frame" {
                Name             = "Header",
                Size             = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = COLOR_HEADER,
                BorderSizePixel  = 0,
                ZIndex           = 11,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 14) },

                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.7, 0.75),
                        BackgroundTransparency = 1,
                        Text                   = "Update Logs",
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = COLOR_WHITE,
                        ZIndex                 = 12,
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },

                    -- Close button
                    scope:New "TextButton" {
                        AnchorPoint      = Vector2.new(1, 0.5),
                        Position         = UDim2.new(1, -8, 0.5, 0),
                        Size             = UDim2.fromOffset(36, 36),
                        BackgroundColor3 = COLOR_CLOSE,
                        BorderSizePixel  = 0,
                        Text             = "X",
                        TextScaled       = true,
                        FontFace         = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3       = COLOR_WHITE,
                        ZIndex           = 12,

                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnClose then props.OnClose() end
                        end,

                        [Fusion.Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
                            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },
                },
            },

            -- Scroll area
            scope:New "ScrollingFrame" {
                AnchorPoint          = Vector2.new(0, 1),
                Position             = UDim2.new(0, 0, 1, 0),
                Size                 = UDim2.new(1, 0, 1, -52),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                CanvasSize           = UDim2.fromScale(1, 0),
                ScrollBarThickness   = 5,
                ScrollBarImageColor3 = Color3.fromRGB(120, 125, 140),
                ZIndex               = 11,

                [Fusion.Children] = {
                    scope:New "UIPadding" {
                        PaddingTop    = UDim.new(0, 10),
                        PaddingBottom = UDim.new(0, 10),
                        PaddingLeft   = UDim.new(0, 10),
                        PaddingRight  = UDim.new(0, 10),
                    },
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        Padding       = UDim.new(0, 10),
                        SortOrder     = Enum.SortOrder.LayoutOrder,
                    },
                    table.unpack(cards),
                },
            },
        },
    }
end
