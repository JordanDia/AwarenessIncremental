local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RaidShopConfig = require(ReplicatedStorage.Shared.Configs.RaidShopConfig)
local RaidShopEntry = require(script.Parent.RaidShopEntry)

local function formatTime(seconds)
    if seconds <= 0 then return "0s" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

return function(scope, props)
    local timerText = scope:Value("Refreshes in: ...")

    local connection = RunService.Heartbeat:Connect(function()
        local remaining = math.max(0, Fusion.peek(props.NextRefreshTime) - os.time())
        timerText:set("Refreshes in: " .. formatTime(remaining))
    end)

    table.insert(scope, function()
        connection:Disconnect()
    end)

    local entries = {}
    for _, item in RaidShopConfig.Items do
        table.insert(entries, RaidShopEntry(scope, {
            Icon = item.Icon,
            BoostName = item.DisplayName,
            Level = props.BoostLevels[item.Id],
            MaxLevel = item.MaxLevel,
            Stock = props.Stock[item.Id],
            Cost = item.Cost,
            OnBuy = function()
                if props.OnPurchase then
                    props.OnPurchase(item.Id)
                end
            end,
        }))
    end
    return scope:New "CanvasGroup" {
        Name = "RaidShop",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(20, 20, 27),
        BackgroundTransparency = 0.3,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.48, 0.7),
        Visible = scope:Computed(function(use)
            return use(props.Visible)
        end),

        [Fusion.Children] = {
            scope:New "UIStroke" {
                Name = "UIStroke",
                BorderStrokePosition = Enum.BorderStrokePosition.Center,
                Thickness = 6,
            },

            scope:New "UICorner" {
                Name = "UICorner",
                CornerRadius = UDim.new(0, 10),
            },

            scope:New "UIListLayout" {
                Name = "UIListLayout",
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0.01, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            scope:New "Frame" {
                Name = "Header",
                BackgroundColor3 = Color3.fromRGB(255, 255, 127),
                Size = UDim2.fromScale(1, 0.08),

                [Fusion.Children] = {
                    scope:New "TextLabel" {
                        Name = "TextLabel",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/Montserrat.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(1, 0.7),
                        Text = "Raid Shop",
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

                    scope:New "TextButton" {
                        Name = "TextButton",
                        AnchorPoint = Vector2.new(1, 0.5),
                        AutoButtonColor = false,
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        FontFace = Font.new(
                            "rbxasset://fonts/families/Montserrat.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        Position = UDim2.fromScale(0.99, 0.5),
                        Size = UDim2.fromScale(0.08, 0.8),
                        Text = "X",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,

                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnClose then
                                props.OnClose()
                            end
                        end,

                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                Name = "UICorner",
                                CornerRadius = UDim.new(0.25, 0),
                            },

                            scope:New "UIAspectRatioConstraint" {
                                Name = "UIAspectRatioConstraint",
                            },
                        }
                    },

                    scope:New "UIStroke" {
                        Name = "UIStroke",
                        BorderStrokePosition = Enum.BorderStrokePosition.Center,
                        Thickness = 6,
                    },

                    scope:New "UICorner" {
                        Name = "UICorner",
                        CornerRadius = UDim.new(0, 10),
                    },
                }
            },

            scope:New "Frame" {
                Name = "Refresh",
                BackgroundColor3 = Color3.fromRGB(94, 94, 94),
                LayoutOrder = 5,
                Size = UDim2.fromScale(0.8, 0.06),

                [Fusion.Children] = {
                    scope:New "TextLabel" {
                        Name = "RefreshStatus",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        FontFace = Font.new(
                            "rbxasset://fonts/families/Montserrat.json",
                            Enum.FontWeight.Bold,
                            Enum.FontStyle.Normal
                        ),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(1, 0.7),
                        Text = timerText,
                        TextColor3 = Color3.fromRGB(255, 230, 38),
                        TextScaled = true,

                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                Name = "UIStroke",
                                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                Thickness = 0.05,
                            },
                        }
                    },

                    scope:New "UIStroke" {
                        Name = "UIStroke",
                        BorderStrokePosition = Enum.BorderStrokePosition.Center,
                        Color = Color3.fromRGB(199, 199, 199),
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                        Thickness = 0.05,
                    },

                    scope:New "UICorner" {
                        Name = "UICorner",
                        CornerRadius = UDim.new(0, 10),
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
                        Text = scope:Computed(function(use)
                            return tostring(use(props.Fragments))
                        end),
                        TextColor3 = Color3.fromRGB(255, 255, 127),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,

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

            scope:New "ScrollingFrame" {
                Name = "ScrollingFrame",
                AnchorPoint = Vector2.new(0.5, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                LayoutOrder = 20,
                Position = UDim2.fromScale(0.5, 0.1),
                ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
                ScrollBarThickness = 4,
                ScrollingDirection = Enum.ScrollingDirection.X,
                Size = UDim2.fromScale(0.9, 0.8),

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        Name = "UIListLayout",
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0.01, 0),
                    },

                    entries,
                }
            }

            
        }
    }
end