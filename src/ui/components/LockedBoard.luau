local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(
    scope: Fusion.Scope,
    props: {
        RewardText: string?,
        RequirementText: string?,
    }
): Fusion.Child

    return scope:New "Frame" {
        Name = "LockedBoard",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        [Fusion.Children] = {
            scope:New "ImageLabel" {
                Name = "LockIcon",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = "rbxassetid://96048118970163",
                Position = UDim2.fromScale(0.5, 0.35),
                Size = UDim2.fromScale(0.4, 0.4),

                [Fusion.Children] = {
                    scope:New "UIAspectRatioConstraint" {
                        Name = "UIAspectRatioConstraint",
                    },
                }
            },

            scope:New "TextLabel" {
                Name = "Reward",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Position = UDim2.fromScale(0.5, 0.57),
                Size = UDim2.fromScale(0.9, 0.15),
                Text = props.RewardText or "???",
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
            },

            scope:New "TextLabel" {
                Name = "Requirement",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.new(
                    "rbxasset://fonts/families/GothamSSm.json",
                    Enum.FontWeight.Bold,
                    Enum.FontStyle.Normal
                ),
                Position = UDim2.fromScale(0.5, 0.75),
                Size = UDim2.fromScale(0.9, 0.15),
                Text = props.RequirementText or "???",
                TextColor3 = Color3.fromRGB(255, 255, 127),
                TextScaled = true,
            },
        }
    }
end
