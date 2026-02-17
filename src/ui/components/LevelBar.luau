local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(scope, props)
    -- Props: Level (Value), CurrentXP (Value), NeededXP (Value)
    
    local progress = scope:Computed(function(use)
        local current = use(props.CurrentXP)
        local needed = use(props.NeededXP)
        
        if needed == 0 then return 1 end -- Max level
        return math.clamp(current / needed, 0, 1)
    end)
    
    return scope:New "Frame" {
        Name = "LevelFrame",
        Size = UDim2.new(0.4, 0, 0, 60), -- Width: 40% of screen, Height: 60px
        Position = UDim2.new(0.5, 0, 1, -80), -- Bottom center, 80px from bottom
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        
        [Fusion.Children] = {
            -- Level Label
            scope:New "TextLabel" {
                Name = "LevelLabel",
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                
                Text = scope:Computed(function(use)
                    return "Level " .. use(props.Level)
                end),
                
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextSize = 20,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                
                -- Text stroke for better visibility
                TextStrokeTransparency = 0.5,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            },
            
            -- XP Bar Container (background)
            scope:New "Frame" {
                Name = "XPBarContainer",
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                
                [Fusion.Children] = {
                    -- Corner rounding
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0, 6),
                    },
                    
                    -- Fill Bar (progress)
                    scope:New "Frame" {
                        Name = "FillBar",
                        Size = scope:Computed(function(use)
                            return UDim2.new(use(progress), 0, 1, 0)
                        end),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromRGB(100, 150, 255), -- Soft blue
                        BorderSizePixel = 0,
                        
                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 6),
                            },
                        }
                    },
                    
                    -- XP Text (centered on bar)
                    scope:New "TextLabel" {
                        Name = "XPText",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 2, -- Make sure text is above the fill bar
                        
                        Text = scope:Computed(function(use)
                            local current = use(props.CurrentXP)
                            local needed = use(props.NeededXP)
                            
                            if needed == 0 then
                                return "MAX LEVEL"
                            end
                            
                            return current .. "/" .. needed
                        end),
                        
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                        TextSize = 16,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        
                        -- Text stroke for better visibility
                        TextStrokeTransparency = 0.3,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    }
                }
            }
        }
    }
end