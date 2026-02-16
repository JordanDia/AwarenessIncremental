local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

return function(scope, props)
    return scope:New "BillboardGui" {
        Size = UDim2.fromScale(1, 0.5),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Adornee = props.Adornee,

        [Fusion.Children] = {
            scope:New "TextLabel" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "+" .. FormatNumber(props.Amount, ".##"),
                FontFace = Font.fromName(
                    "Montserrat",
                    Enum.FontWeight.Bold
                ),
                TextScaled = true,
                TextColor3 = props.TextColor3
            }
        }
    }
end
