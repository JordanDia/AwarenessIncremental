local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(scope, props)
    -- Props: Health (Value<number>), MaxHealth (Value<number>)

    local fillScale = scope:Computed(function(use)
        local hp    = use(props.Health)
        local maxHp = use(props.MaxHealth)
        if maxHp <= 0 then return 1 end
        return math.clamp(hp / maxHp, 0, 1)
    end)

    return scope:New "BillboardGui" {
        Name              = "HealthBar",
        Active            = true,
        ClipsDescendants  = true,
        LightInfluence    = 1,
        Size              = UDim2.fromScale(3, 0.3),
        StudsOffset       = Vector3.new(0, 1.5, 0),
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name            = "Backdrop",
                AnchorPoint     = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(86, 86, 86),
                Position        = UDim2.fromScale(0.5, 0.5),
                Size            = UDim2.fromScale(1, 1),

                [Fusion.Children] = {
                    scope:New "UICorner" {},

                    scope:New "UIPadding" {
                        PaddingBottom = UDim.new(0.05, 0),
                        PaddingLeft   = UDim.new(0.005, 0),
                        PaddingRight  = UDim.new(0.005, 0),
                        PaddingTop    = UDim.new(0.05, 0),
                    },

                    scope:New "Frame" {
                        Name             = "Fill",
                        BackgroundColor3 = Color3.fromRGB(85, 255, 127),
                        Size             = scope:Computed(function(use)
                            return UDim2.fromScale(use(fillScale), 1)
                        end),

                        [Fusion.Children] = {
                            scope:New "UICorner" {},
                        },
                    },
                },
            },
        },
    }
end
