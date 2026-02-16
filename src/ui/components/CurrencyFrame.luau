local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

return function(
    scope: Fusion.Scope,
    props: {
        Name: string?,
        Position: UDim2,
        Value: Fusion.UsedAs<number>,
        Icon: string,
        TextColor3: Color3,
        Parent: Instance?
    }
) : Fusion.Child
    
    return scope:New "Frame" {
        Name = props.Name,
        Size = UDim2.fromScale(0.18, 0.08),
        Position = props.Position,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = props.Parent,

        [Fusion.Children] = {

            scope:New "ImageLabel" {
                Name = "Icon",
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromScale(1, 0.6),
                Position = UDim2.fromScale(0.05, 0.5),
                BackgroundTransparency = 1,
                Image = props.Icon,
                ImageTransparency = 0,

                [Fusion.Children] = {
                    scope:New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                    }
                }
            },

            scope:New "TextLabel" {
                Name = "AwarenessLabel",
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromScale(0.7, 0.6),
                Position = UDim2.fromScale(0.25, 0.5),
                BackgroundTransparency = 1,

                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                TextScaled = true,
                TextColor3 = props.TextColor3,
                Text = scope:Computed(function(use)
                    return FormatNumber(use(props.Value), ".##")
                end),
                TextXAlignment = Enum.TextXAlignment.Left,

            },

            scope:New "UICorner" {
                CornerRadius = UDim.new(0.1, 0),
            }
        }
    }
end




