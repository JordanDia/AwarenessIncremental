local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local ButtonFrame = require("../components/ButtonFrame")

return function(scope: Fusion.Scope, props)

    return scope:New "Frame" {
        Name = "ButtonHolder",
        Position = UDim2.fromScale(0.025, 0.52),
        AnchorPoint = Vector2.new(0, 0),
        Size = UDim2.fromScale(0.18, 0.2),
        BackgroundTransparency = 1,

        [Fusion.Children] = {

            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Wraps = true,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.03, 0),
            },

            scope:ForValues(props.Buttons, function(use, innerScope, button)
                return innerScope:ButtonFrame {
                    Name = button.Name,
                    Size = UDim2.fromScale(0.25, 0.25),
                    Icon = button.Icon,
                    LayoutOrder = button.LayoutOrder,
                    Visible = button.Visible,
                    OnActivated = button.OnActivated,
                }
            end)

        }
    }
end