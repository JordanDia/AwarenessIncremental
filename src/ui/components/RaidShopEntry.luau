local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(scope, props)

    return scope:New "Frame" {
        Name = "RaidShopEntry",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.6,
        Size = UDim2.fromScale(0.4, 1),

        [Fusion.Children] = {
            scope:New "UICorner" {
                Name = "UICorner",
            },

            scope:New "UIListLayout" {
                Name = "UIListLayout",
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0.03, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            scope:New "Frame" {
                Name = "Frame",
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 1.00918e-07),
                Size = UDim2.fromScale(1, 0.6),

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        Name = "UIListLayout",
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0.01, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    scope:New "ImageLabel" {
                        Name = "Icon",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = props.Icon,
                        LayoutOrder = 10,
                        Position = UDim2.fromScale(0.5, 0.299934),
                        Size = UDim2.fromOffset(100, 100),
                    },

                    scope:New "TextLabel" {
                        Name = "BoostName",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        Position = UDim2.fromScale(0.124801, 0.0611772),
                        Size = UDim2.fromScale(0.9, 0.138),
                        Text = props.BoostName .. "(+5%)",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,

                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                Thickness = 0.05,
                            },
                        }
                    },

                    scope:New "TextLabel" {
                        Name = "Level",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        LayoutOrder = 20,
                        Position = UDim2.fromScale(0.124801, 0.0611772),
                        Size = UDim2.fromScale(0.9, 0.08),
                        Text = scope:Computed(function(use)
                            return `Lvl. {use(props.Level)}/{props.MaxLevel}`
                        end),
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                    },

                    scope:New "TextLabel" {
                        Name = "Stock",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        LayoutOrder = 30,
                        Position = UDim2.fromScale(0.124801, 0.0611772),
                        Size = UDim2.fromScale(0.9, 0.08),
                        Text = scope:Computed(function(use)
                            return `Stock: {use(props.Stock)}`
                        end),
                        TextColor3 = Color3.fromRGB(85, 255, 127),
                        TextScaled = true,
                    },
                }
            },

            scope:New "Frame" {
                Name = "Frame",
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0.63),
                Size = UDim2.fromScale(1, 0.355355),

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        Name = "UIListLayout",
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0.08, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    scope:New "TextButton" {
                        Name = "BuyButton",
                        BackgroundColor3 = Color3.fromRGB(85, 255, 127),
                        FontFace = Font.new(
                            "rbxasset://fonts/families/GothamSSm.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        LayoutOrder = 60,
                        Position = UDim2.fromScale(0.196017, 0.873016),
                        Size = UDim2.fromScale(0.60313, 0.232646),
                        Text = "Buy",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,

                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnBuy then
                                props.OnBuy()
                            end
                        end,

                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                Thickness = 0.05,
                            },

                            scope:New "UICorner" {
                                Name = "UICorner",
                            },

                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                Thickness = 0.05,
                            },

                            scope:New "UIPadding" {
                                Name = "UIPadding",
                                PaddingBottom = UDim.new(0.1, 0),
                                PaddingLeft = UDim.new(0.1, 0),
                                PaddingRight = UDim.new(0.1, 0),
                                PaddingTop = UDim.new(0.1, 0),
                            },
                        }
                    },

                    scope:New "Frame" {
                        Name = "CostFrame",
                        BackgroundTransparency = 1,
                        LayoutOrder = 40,
                        Position = UDim2.fromScale(0.124801, 0.762235),
                        Size = UDim2.fromScale(0.747882, 0.232646),

                        [Fusion.Children] = {
                            scope:New "UIListLayout" {
                                Name = "UIListLayout",
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                Padding = UDim.new(0.01, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            },

                            scope:New "ImageLabel" {
                                Name = "FragmentIcon",
                                AnchorPoint = Vector2.new(0, 0.5),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://114746804586222",
                                Position = UDim2.fromScale(0.01, 0.5),
                                Size = UDim2.fromScale(0.1, 0.8),

                                [Fusion.Children] = {
                                    scope:New "UIAspectRatioConstraint" {
                                        Name = "UIAspectRatioConstraint",
                                    },
                                }
                            },

                            scope:New "TextLabel" {
                                Name = "FragmentAmount",
                                AnchorPoint = Vector2.new(0, 0.5),
                                BackgroundTransparency = 1,
                                FontFace = Font.new(
                                    "rbxasset://fonts/families/GothamSSm.json",
                                    Enum.FontWeight.Bold,
                                    Enum.FontStyle.Normal
                                ),
                                Position = UDim2.fromScale(0.0714296, 0.5),
                                Size = UDim2.fromScale(0.2, 0.7),
                                Text = tostring(props.Cost),

                                TextColor3 = Color3.fromRGB(255, 255, 127),
                                TextScaled = true,

                                [Fusion.Children] = {
                                    scope:New "UIStroke" {
                                        Name = "UIStroke",
                                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                        Thickness = 0.05,
                                    },
                                }
                            },
                        }
                    },
                }
            },

            scope:New "UIGradient" {
                Name = "UIGradient",
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 255)),
                }),
                Rotation = 45,
                Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0),
                                                    NumberSequenceKeypoint.new(1, 0.2625),
                }),
            },
        }
    }
end
