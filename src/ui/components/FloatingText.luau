local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)

return function(scope, props)
    return scope:New "BillboardGui" {
        Size = UDim2.fromScale(3, 2),
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
                TextColor3 = props.TextColor3,

            }
        }
    }
end
