local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(scope: Fusion.Scope, props)

    local titleVisible = scope:Value(false)


    return scope:New "ImageLabel" {
        Name                   = props.Name or "BoostIcon",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image                  = props.Icon,
        Visible                = props.Visible,

        [Fusion.OnEvent "MouseEnter"] = function()
            titleVisible:set(true)
        end,

        [Fusion.OnEvent "MouseLeave"] = function()
            titleVisible:set(false)
        end,

        [Fusion.Children] = {
            scope:New "UIAspectRatioConstraint" {
                AspectRatio = 1,
            },

            scope:New "TextLabel" {
                Name = "Timer",
                AnchorPoint = Vector2.new(0.5, 0),

                Size = UDim2.fromScale(1, 0.2),
                Position = UDim2.fromScale(0.5, 0.8),
                BackgroundTransparency = 1,

                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextScaled = true,

                TextColor3 = Color3.fromRGB(255, 255, 255),

                Text = props.TimerText or "00m 00s",

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Color = Color3.fromRGB(0, 0, 0),
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                        Thickness = 0.05,
                    },
                },
            },

            scope:New "TextLabel" {
                Name = "Title",
                AnchorPoint = Vector2.new(0.5, 0),

                Size = UDim2.fromScale(1.5, 0.4),
                Position = UDim2.fromScale(0.5, -0.2),
                BackgroundTransparency = 1,

                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextScaled = true,

                TextColor3 = Color3.fromRGB(255, 255, 255),

                Text = props.Title or "Boost",
                
                Visible = scope:Computed(function(use)
                    return use(titleVisible)
                end),

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Color = Color3.fromRGB(0, 0, 0),
                        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                        Thickness = 0.05,
                    },
                },
            }


        }
    }
end
