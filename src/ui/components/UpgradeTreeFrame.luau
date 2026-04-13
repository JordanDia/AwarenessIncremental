local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

return function(
    scope: Fusion.Scope,
    props: {
        Title: string,
        UpgradeName: string?,
        Cost: Fusion.UsedAs<any>?,
    }
): Fusion.Child

    return scope:New "Frame" {
        Name = "UpgradeTreeFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromScale(0.8, 0.8),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,

        [Fusion.Children] = {

            scope:New "TextLabel" {
                Name = "Title",
                Size = UDim2.fromScale(1, 0.3),
                Position = UDim2.fromScale(0, 0),
                Text = props.Title,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                TextScaled = true,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(160, 160, 160),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                    }
                }

            },

            scope:New "TextLabel" {
                Name = "UpgradeName",
                Size = UDim2.fromScale(1, 0.3),
                Position = UDim2.fromScale(0, 0.3),
                Text = props.UpgradeName,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                TextScaled = true,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                    }
                }

            },

            scope:New "TextLabel" {
                Name = "Cost",
                Size = UDim2.fromScale(1, 0.3),
                Position = UDim2.fromScale(0, 0.6),
                Text = props.Cost,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                TextScaled = true,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(123, 255, 0),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                    }
                }

            }

        }
    }
end
