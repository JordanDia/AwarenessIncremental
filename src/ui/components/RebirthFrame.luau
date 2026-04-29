local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)

return function(
    scope: Fusion.Scope,
    props: {
        Title: string,
        Icon: string?,
        Value: Fusion.UsedAs<number>?,
        
        OnRebirth: (() -> ())?,
    }
): Fusion.Child

    return scope:New "Frame" {
        Name = "RebirthFrame",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        [Fusion.Children] = {

            -- Padding
            scope:New "UIPadding" {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
            },

            -- Layout
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0.035, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            -- Title Header
            scope:New "TextLabel" {
                Name = "Title",
                LayoutOrder = 1,
                Size = UDim2.fromScale(1, 0.1),
                BackgroundTransparency = 1,

                Text = "Rebirth",
                TextScaled = true,
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                    }
                }
            },

            -- Icon
            scope:New "ImageLabel" {
                Name = "Icon",
                LayoutOrder = 2,
                Size = UDim2.fromScale(1, 0.3),
                AnchorPoint = Vector2.new(0.5, 0),
                Image = props.Icon,
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                    }
                }
            },
        
            -- Spacer (matches Description size in UpgradeFrame)
            scope:New "Frame" {
                Name = "Spacer",
                LayoutOrder = 3,
                Size = UDim2.fromScale(0.8, 0.12),
                BackgroundTransparency = 1,
            },

            -- Rebirth Value
            scope:New "TextLabel" {
                Name = "RebirthValue",
                LayoutOrder = 3,
                Size = UDim2.fromScale(0.8, 0.08),
                BackgroundTransparency = 1,

                Text = scope:Computed(function(use)
                    local value = props.Value and use(props.Value)
                    return `+{ FormatNumber(value) }`
                end),

                TextScaled = true,
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextColor3 = Color3.fromRGB(162, 0, 255),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                    }
                }
            },

            -- Cost Text
            scope:New "TextLabel" {
                LayoutOrder = 4,
                Size = UDim2.fromScale(1, 0.05),
                BackgroundTransparency = 1,

                Text = "Cost: 1K Awareness",
                RichText = true,
                TextScaled = true,
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 1,
                    }
                }
            },

            -- Rebirth Button
            scope:New "TextButton" {
                LayoutOrder = 5,
                Size = UDim2.fromScale(0.4, 0.15),
                Text = "",
                BackgroundColor3 = Color3.fromRGB(80, 200, 120),
                TextColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,

                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),

                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

                [Fusion.OnEvent "Activated"] = function()
                    if props.OnRebirth then
                        props.OnRebirth()
                    end
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0.1, 0),
                    },

                    scope:New "UIStroke" {
                        Thickness = 4,
                        Color = Color3.fromRGB(0, 0, 0),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },

                    scope:New "TextLabel" {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.9, 0.5),
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        BackgroundTransparency = 1,
                        ZIndex = 10,

                        Text = "Rebirth",
                        TextScaled = true,
                        TextColor3 = Color3.new(1, 1, 1),

                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                Thickness = 3,
                            }
                        }
                    }
                }
            },
        }
    }
end