local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(
    scope: Fusion.Scope,
    props: {
        Name: string?,
        Size: UDim2,
        Position: UDim2?,
        Icon: string,
        LayoutOrder: number?,
        Visible: Fusion.UsedAs<boolean>?,
        OnActivated: (() -> ())?
    }
) : Fusion.Child

    return scope:New "ImageButton" {
        Name = props.Name or "Button",
        Size = props.Size,
        Position = props.Position or UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Image = props.Icon,
        LayoutOrder = props.LayoutOrder or 0,
        Visible = props.Visible or true,

        [Fusion.OnEvent "Activated"] = props.OnActivated or function() end,

        [Fusion.Children] = {

            scope:New "UICorner" {
                CornerRadius = UDim.new(0.15, 0),
            },

            scope:New "UIAspectRatioConstraint" {
                AspectRatio = 1,
                AspectType = Enum.AspectType.ScaleWithParentSize,
                DominantAxis = Enum.DominantAxis.Width,
            },

        }
    }
end