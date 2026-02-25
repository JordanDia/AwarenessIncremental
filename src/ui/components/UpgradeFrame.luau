local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

return function(
    scope: Fusion.Scope,
    props: {
        Level: Fusion.UsedAs<number>?,
        MaxLevel: Fusion.UsedAs<number>?,

        Description: string,
        Icon: string?,

        CurrentValue: Fusion.UsedAs<number>?,
        NextValue: Fusion.UsedAs<number>?,
        
        Cost: Fusion.UsedAs<number>?,
        Units: string?,

        OnBuyOne: (() -> ())?,
        OnBuyMax: (() -> ())?,
    }
): Fusion.Child

    return scope:New "Frame" {
        Name = "UpgradeFrame",
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

            -- Level Header
            scope:New "TextLabel" {
                Name = "Level",
                LayoutOrder = 1,
                Size = UDim2.fromScale(1, 0.1),
                BackgroundTransparency = 1,

                Text = scope:Computed(function(use)
                    local level = props.Level and use(props.Level) or 0
                    return `Level: { level } / { props.MaxLevel }`
                end),
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

            -- Description
            scope:New "TextLabel" {
                Name = "Description",
                LayoutOrder = 3,
                Size = UDim2.fromScale(0.8, 0.12),
                BackgroundTransparency = 1,

                TextWrapped = true,
                Text = props.Description,
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

            -- Upgrade Values
            scope:New "TextLabel" {
                Name = "UpgradeValues",
                LayoutOrder = 4,
                Size = UDim2.fromScale(0.8, 0.08),
                BackgroundTransparency = 1,

                Text = scope:Computed(function(use)
                    
                    local currentValue = props.CurrentValue and use(props.CurrentValue)
                    local nextValue = props.NextValue and use(props.NextValue)

                    -- Check if we are max level
                    local level = props.Level and use(props.Level) or 0
                    local maxLevel = props.MaxLevel and use(props.MaxLevel) or 0
                    if level >= maxLevel then
                        return `Value: +{ currentValue }`
                    end

                    return `+{ currentValue } > +{ nextValue }`

                end),

                TextScaled = true,
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextColor3 = Color3.fromRGB(255, 215, 0),

                [Fusion.Children] = {

                    scope:New "UIStroke" {
                        Thickness = 2,
                    }

                }
            },

            -- Cost Text
            scope:New "TextLabel" {
                LayoutOrder = 5,
                Size = UDim2.fromScale(1, 0.05),
                BackgroundTransparency = 1,

                Text = scope:Computed(function(use)
                    local cost = props.Cost and use(props.Cost) or 0
                    return `Cost: <font color="rgb(150, 255, 150)">{FormatNumber(cost, ".##")} {props.Units or ""}</font>`
                end),

                RichText = true,
                TextScaled = true,
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextColor3 = Color3.fromRGB(255, 255, 255), -- White for "Cost:"

                [Fusion.Children] = {

                    scope:New "UIStroke" {
                        Thickness = 1,
                    }

                }
            },

            -- Buttons Container
            scope:New "Frame" {
                LayoutOrder = 6,
                Size = UDim2.fromScale(1, 0.15),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0.066, 0),
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    },

                    -- Buy One
                    scope:New "TextButton" {
                        Size = UDim2.fromScale(0.4, 1),
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
                            if props.OnBuyOne then
                                props.OnBuyOne()
                            end
                        end,
                        
                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.1, 0), -- Fully round
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

                                Text = "Buy 1",
                                TextScaled = true,
                                BackgroundColor3 = Color3.fromRGB(70, 140, 255),
                                TextColor3 = Color3.new(1, 1, 1),


                                [Fusion.Children] = {

                                    scope:New "UIStroke" {
                                        Thickness = 3,
                                    }

                                }

                            }
                        }
                    },

                    -- Buy Max
                    scope:New "TextButton" {
                        Size = UDim2.fromScale(0.4, 1),
                        Text = "",
                        BackgroundColor3 = Color3.fromRGB(70, 140, 255),
                        TextColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,

                        FontFace = Font.fromName(
                            "Montserrat",
                            Enum.FontWeight.Bold
                        ),
                        
                        TextStrokeTransparency = 0,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnBuyMax then
                                props.OnBuyMax()
                            end
                        end,
                        
                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.1, 0)
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

                                Text = "Buy Max",
                                TextScaled = true,
                                BackgroundColor3 = Color3.fromRGB(70, 140, 255),
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
        }
    }
end
