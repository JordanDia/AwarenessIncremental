local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local AbilityButton = require("../components/AbilityButton")

-- Props:
--   Buttons  (Value<{ { Name, Label, LayoutOrder, Visible, OnActivated } }>)
--
-- Sits directly above the LevelFrame which is at Y=0.87.
-- The holder is full width, centered, and auto-sizes its height to its content.

return function(scope: Fusion.Scope, props)

    return scope:New "Frame" {
        Name = "AbilityButtonHolder",

        -- Full screen width, anchored bottom-center just above the level bar
        Size = UDim2.fromScale(0.25, 0.04),
        Position = UDim2.fromScale(0.5, 0.87),
        AnchorPoint = Vector2.new(0.5, 1), -- anchor to bottom so it sits above LevelFrame
        BackgroundTransparency = 1,

        [Fusion.Children] = {

            -- Centers buttons horizontally; wraps if too many
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Wraps = false,
            },

            scope:ForValues(props.Buttons, function(use, innerScope, button)
                return innerScope:AbilityButton {
                    Name        = button.Name,
                    Label       = button.Label,
                    LayoutOrder = button.LayoutOrder,
                    Visible     = button.Visible,
                    OnActivated = button.OnActivated,
                }
            end),
        }
    }
end
