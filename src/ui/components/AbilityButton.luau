local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Label       (string | Value<string>)
--   LayoutOrder (number)
--   Visible     (boolean | Value<boolean>)
--   OnActivated (function)

return function(scope: Fusion.Scope, props)

    local isHovered = scope:Value(false)
    local isPressed = scope:Value(false)

    local bgColor = scope:Computed(function(use)
        if use(isPressed) then
            return Color3.fromRGB(50, 50, 50)
        elseif use(isHovered) then
            return Color3.fromRGB(75, 75, 75)
        else
            return Color3.fromRGB(60, 60, 60)
        end
    end)

    return scope:New "TextButton" {
        Name = props.Name or "AbilityButton",
        Size = UDim2.fromScale(0.15, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = bgColor,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder or 0,
        Visible = props.Visible ~= nil and props.Visible or true,
        AutoButtonColor = false,

        Text = props.Label or "",
        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
        TextScaled = true,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextStrokeTransparency = 0.6,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

        [Fusion.OnEvent "MouseEnter"] = function()
            isHovered:set(true)
        end,
        [Fusion.OnEvent "MouseLeave"] = function()
            isHovered:set(false)
            isPressed:set(false)
        end,
        [Fusion.OnEvent "MouseButton1Down"] = function()
            isPressed:set(true)
        end,
        [Fusion.OnEvent "MouseButton1Up"] = function()
            isPressed:set(false)
        end,
        [Fusion.OnEvent "Activated"] = function()
            if props.OnActivated then
                props.OnActivated()
            end
        end,

        [Fusion.Children] = {
            scope:New "UICorner" {
                CornerRadius = UDim.new(0.2, 0),
            },
            scope:New "UIStroke" {
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = 2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            },
            scope:New "UIPadding" {
                PaddingTop = UDim.new(0.1, 0),
                PaddingBottom = UDim.new(0.1, 0),
                PaddingLeft  = UDim.new(0.1, 0),
                PaddingRight = UDim.new(0.1, 0),
            },
        }
    }
end
