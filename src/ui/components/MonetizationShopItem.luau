local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   LayoutOrder  (number)
--   Title        (string)
--   Description  (string)
--   Price        (number)  -- fetched from MarketplaceService

return function(scope, props)
    return scope:New "Frame" {
        Name = "Entry",
        BackgroundColor3 = Color3.new(1, 1, 1),
        LayoutOrder = props.LayoutOrder or 1,

        [Fusion.Children] = {
            scope:New "UICorner" {
                Name = "UICorner",
                CornerRadius = UDim.new(0.08, 0),
            },

            scope:New "Frame" {
                Name = "TitleDesc",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0.72, 1),

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        Name = "UIListLayout",
                        Padding = UDim.new(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    },

                    scope:New "TextLabel" {
                        Name = "Title",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/Montserrat.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        LayoutOrder = 1,
                        Size = UDim2.new(1, 0, 0, 22),
                        Text = props.Title or "",
                        TextColor3 = Color3.fromRGB(240, 240, 255),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,

                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                Name = "UIStroke",
                            },
                        }
                    },

                    scope:New "TextLabel" {
                        Name = "Desc",
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/Montserrat.json",
                            Enum.FontWeight.SemiBold,
                            Enum.FontStyle.Normal
                        ),
                        LayoutOrder = 2,
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = props.Description or "",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    },
                }
            },

            scope:New "UIPadding" {
                Name = "UIPadding",
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
                PaddingTop = UDim.new(0, 12),
            },

            scope:New "Frame" {
                Name = "Buttons",
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.7),
                Size = UDim2.fromScale(1, 0.3),

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        Name = "UIListLayout",
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding = UDim.new(0.02, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    },

                    scope:New "ImageButton" {
                        Name = "Gift",
                        AnchorPoint = Vector2.new(1, 0.5),
                        AutoButtonColor = false,
                        BackgroundColor3 = Color3.fromRGB(85, 0, 255),
                        Position = UDim2.fromScale(1, 0.5),
                        ScaleType = Enum.ScaleType.Crop,
                        Size = UDim2.fromScale(0.1, 1),

                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                Name = "UICorner",
                                CornerRadius = UDim.new(0.2, 0),
                            },

                            scope:New "UIAspectRatioConstraint" {
                                Name = "UIAspectRatioConstraint",
                            },

                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                Thickness = 2,
                            },

                            scope:New "ImageLabel" {
                                Name = "ImageLabel",
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://112347673767632",
                                Position = UDim2.fromScale(0.5, 0.5),
                                Size = UDim2.fromScale(0.8, 0.88),
                            },
                        }
                    },

                    scope:New "ImageButton" {
                        Name = "Buy",
                        AnchorPoint = Vector2.new(1, 0.5),
                        AutoButtonColor = false,
                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnBuy then
                                props.OnBuy()
                            end
                        end,
                        BackgroundColor3 = Color3.fromRGB(50, 180, 80),
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.fromScale(0.6, 1),

                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                Name = "UICorner",
                                CornerRadius = UDim.new(0.2, 0),
                            },

                            scope:New "ImageLabel" {
                                Name = "RobuxIcon",
                                AnchorPoint = Vector2.new(0, 0.5),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://112918896118724",
                                Position = UDim2.fromScale(0.06, 0.5),
                                Size = UDim2.fromScale(0.8, 0.8),

                                [Fusion.Children] = {
                                    scope:New "UIAspectRatioConstraint" {
                                        Name = "UIAspectRatioConstraint",
                                    },
                                }
                            },

                            scope:New "TextLabel" {
                                Name = "Price",
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                FontFace = Font.new(
                                    "rbxasset://fonts/families/Montserrat.json",
                                    Enum.FontWeight.Bold,
                                    Enum.FontStyle.Normal
                                ),
                                Position = UDim2.fromScale(0.5, 0.5),
                                Size = UDim2.fromScale(0.68, 0.7),
                                Text = tostring(props.Price or "…"),
                                TextColor3 = Color3.new(1, 1, 1),
                                TextScaled = true,

                                [Fusion.Children] = {
                                    scope:New "UIStroke" {
                                        Name = "UIStroke",
                                    },
                                }
                            },

                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                Thickness = 2,
                            },
                        }
                    },
                }
            },

            scope:New "UIStroke" {
                Name = "UIStroke",
                Thickness = 2,
            },

            scope:New "UIGradient" {
                Name = "UIGradient",
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 49, 49)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 89, 89)),
                }),
            },
        }
        }

end


