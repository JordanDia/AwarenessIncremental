local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local CurrencyFrame = require("../components/CurrencyFrame")

return function(scope: Fusion.Scope, props)

    return scope:New "Frame" {
        Name = "CurrencyHolder",
        -- Match position/width of RebirthFrame, anchor to bottom
        Position = UDim2.fromScale(0.01, 0),
        AnchorPoint = Vector2.new(0, 0),
        Size = UDim2.fromScale(0.18, 0.5), -- width matches CurrencyFrame, height auto
        BackgroundTransparency = 1,

        [Fusion.Children] = {
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.None,
                Padding = UDim.new(0.01, 0)
                -- Grows upward by reversing order
                -- New items added will push existing ones up
            },

            scope:ForValues(props.Currencies, function(use, innerScope, currency)
                return innerScope:CurrencyFrame {
                    Name = currency.Name,
                    Size = UDim2.fromScale(1, 0.14),
                    Value = currency.Value,
                    Icon = currency.Icon,
                    TextColor3 = currency.TextColor3,
                    LayoutOrder = currency.LayoutOrder,
                    Visible = currency.Visible,
                }
            end)
        }
    }
end