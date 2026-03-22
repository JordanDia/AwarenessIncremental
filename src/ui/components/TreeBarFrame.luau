local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local MAX_PROGRESS = 10

-- BillboardGui that sits above the tree and shows the connection progress bar.
-- Parented to PlayerGui (local-only) with Adornee = tree so only the interacting
-- player sees it.
return function(
    scope: Fusion.Scope,
    props: {
        Adornee: Instance?,
        Progress: Fusion.UsedAs<number>,  -- 0 to MAX_PROGRESS
        Enabled: Fusion.UsedAs<boolean>,
        Parent: Instance,
    }
): Instance
    return scope:New "BillboardGui" {
        Name = "TreeProgressBar",
        Adornee = props.Adornee,
        Size = UDim2.fromScale(10, 1.2), -- BillboardGui Scale = studs; 10 wide × 1.2 tall in world space
        StudsOffset = Vector3.new(0, 10, 0),
        AlwaysOnTop = true,
        Enabled = props.Enabled,
        ResetOnSpawn = false,
        Parent = props.Parent,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name = "Background",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,

                [Fusion.Children] = {
                    scope:New "Frame" {
                        Name = "Fill",
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.fromScale(0, 0),
                        Size = scope:Computed(function(use)
                            local pct = math.clamp(use(props.Progress) / MAX_PROGRESS, 0, 1)
                            return UDim2.fromScale(pct, 1)
                        end),
                        BackgroundColor3 = Color3.fromRGB(55, 210, 95),
                        BorderSizePixel = 0,

                        [Fusion.Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.4, 0),
                            },
                        },
                    },

                    -- Progress label drawn over the fill bar
                    scope:New "TextLabel" {
                        Name = "ProgressText",
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        ZIndex = 2,
                        Text = scope:Computed(function(use)
                            local p = math.clamp(use(props.Progress), 0, MAX_PROGRESS)
                            return string.format("%.1f", p) .. "/" .. MAX_PROGRESS
                        end),
                        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                        TextScaled = true,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextStrokeTransparency = 0.3,
                        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                    },

                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0.4, 0),
                    },

                    scope:New "UIPadding" {
                        PaddingLeft = UDim.new(0, 3),
                        PaddingRight = UDim.new(0, 3),
                        PaddingTop = UDim.new(0, 3),
                        PaddingBottom = UDim.new(0, 3),
                    },
                },
            },
        },
    }
end
