local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local GamepassConfig = require(ReplicatedStorage.Shared.Configs.GamepassConfig)
local MonetizationShopItem = require(script.Parent.MonetizationShopItem)

-- Props:
--   Visible  (Value<boolean>)
--   OnClose  (function)

-- Fetch prices up front (pcall so a bad ID doesn't break the whole shop)
local function getPrice(passId)
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
    end)
    if ok and info then
        return info.PriceInRobux
    end
    return nil
end

return function(scope, props)
    return scope:New "CanvasGroup" {
        Name = "ShopPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(20, 20, 27),
        BackgroundTransparency = 0.3,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.48, 0.7),
        Visible = props.Visible,

        [Fusion.Children] = {
            scope:New "UIStroke" {
                Name = "UIStroke",
                BorderStrokePosition = Enum.BorderStrokePosition.Center,
                Thickness = 6,
            },

            scope:New "ScrollingFrame" {
                Name = "ScrollingFrame",
                AnchorPoint = Vector2.new(0.5, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                Position = UDim2.fromScale(0.5, 0.1),
                ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
                ScrollBarThickness = 4,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.fromScale(0.9, 0.85),

                [Fusion.Children] = (function()
                    local children = {
                        scope:New "UIGridLayout" {
                            Name = "UIGridLayout",
                            CellPadding = UDim2.new(0.02, 0, 0, 8),
                            CellSize = UDim2.new(0.485, 0, 0, 130),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                        },
                        scope:New "UIPadding" {
                            Name = "UIPadding",
                            PaddingLeft = UDim.new(0, 10),
                            PaddingRight = UDim.new(0, 10),
                            PaddingTop = UDim.new(0, 10),
                        },
                    }

                    for i, pass in ipairs(GamepassConfig) do
                        local price = getPrice(pass.PassId)
                        table.insert(children, MonetizationShopItem(scope, {
                            LayoutOrder = i,
                            Title       = pass.Name,
                            Description = pass.Description,
                            Price       = price,
                            OnBuy       = function()
                                props.GamepassService:PromptPurchase(pass.PassId)
                            end,
                        }))
                    end

                    return children
                end)(),
            },

            scope:New "Frame" {
                Name = "Frame",
                BackgroundColor3 = Color3.fromRGB(85, 170, 127),
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
                        Text = "Shop",
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
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.fromScale(0, 1),
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

            scope:New "UICorner" {
                Name = "UICorner",
                CornerRadius = UDim.new(0, 10),
            },
        }
    }
end
