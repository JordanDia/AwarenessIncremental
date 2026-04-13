local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local REG  = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)

local COLOR_INCOMPLETE = Color3.fromRGB(28, 28, 38)
local COLOR_COMPLETE   = Color3.fromRGB(60, 140, 100)

local function formatProgress(value, goal, fmt)
    if fmt == "time" then
        local function toMS(s)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        return toMS(math.floor(value)) .. "/" .. toMS(goal)
    else
        return FormatNumber(math.floor(value)) .. "/" .. FormatNumber(goal)
    end
end

-- e.g. 600 -> "10m00s", 75 -> "1m15s", 30 -> "0m30s"
local function formatTime(s)
    local m = math.floor(s / 60)
    local sec = s % 60
    return string.format("%dm%02ds", m, sec)
end

-- Props:
--   Title, Description  string
--   Goal                number
--   Format              "time" | "number"
--   Reward              { Label, Duration, ... }
--   Progress            Value<number>
--   Claimed             Value<boolean>
--   BuffEndTime         Value<number>   absolute os.clock() timestamp; 0 = no buff
--   Clock               Value<number>   shared clock that ticks every second
--   LayoutOrder         number

return function(scope, props)
    local fillPct = scope:Computed(function(use)
        return math.clamp(use(props.Progress) / props.Goal, 0, 1)
    end)

    local progressText = scope:Computed(function(use)
        return formatProgress(use(props.Progress), props.Goal, props.Format)
    end)

    local remaining = scope:Computed(function(use)
        local endTime = use(props.BuffEndTime)
        if endTime <= 0 then
            return 0
        end
        return math.max(0, endTime - use(props.Clock))
    end)

    local rewardBg = scope:Computed(function(use)
        return use(props.Claimed) and COLOR_COMPLETE or COLOR_INCOMPLETE
    end)

    -- Bottom label: static duration before completion, countdown while active, "Completed!" when done
    local timerText = scope:Computed(function(use)
        local claimed = use(props.Claimed)
        local rem = use(remaining)
        if not claimed then
            return formatTime(props.Reward.Duration)
        elseif rem > 0 then
            return formatTime(math.ceil(rem))
        else
            return "Completed!"
        end
    end)

    local timerColor = scope:Computed(function(use)
        local claimed = use(props.Claimed)
        local rem = use(remaining)
        if not claimed then
            return Color3.fromRGB(160, 160, 180)
        elseif rem > 0 then
            return Color3.fromRGB(200, 255, 220)
        else
            return Color3.fromRGB(180, 255, 200)
        end
    end)

    return scope:New "Frame" {
        Name = "QuestItem",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 88),
        LayoutOrder = props.LayoutOrder,

        [Fusion.Children] = {
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },

            -- Left info panel
            scope:New "Frame" {
                Name = "InfoPanel",
                BackgroundColor3 = Color3.fromRGB(22, 22, 30),
                Size = UDim2.fromScale(0.68, 1),
                LayoutOrder = 1,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
                    scope:New "UIPadding" {
                        PaddingLeft   = UDim.new(0, 12),
                        PaddingRight  = UDim.new(0, 12),
                        PaddingTop    = UDim.new(0, 10),
                        PaddingBottom = UDim.new(0, 10),
                    },

                    scope:New "TextLabel" {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, 0),
                        Size = UDim2.new(1, 0, 0, 22),
                        Text = props.Title,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        FontFace = BOLD,
                    },

                    scope:New "TextLabel" {
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(0, 24),
                        Size = UDim2.new(1, 0, 0, 16),
                        Text = props.Description,
                        TextColor3 = Color3.fromRGB(170, 170, 190),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        FontFace = REG,
                    },

                    scope:New "Frame" {
                        BackgroundColor3 = Color3.fromRGB(14, 14, 20),
                        Position = UDim2.new(0, 0, 1, -28),
                        Size = UDim2.new(1, 0, 0, 12),
                        [Fusion.Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
                            scope:New "Frame" {
                                Name = "Fill",
                                BackgroundColor3 = Color3.fromRGB(200, 170, 50),
                                Size = scope:Computed(function(use)
                                    return UDim2.fromScale(use(fillPct), 1)
                                end),
                                [Fusion.Children] = {
                                    scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
                                },
                            },
                        },
                    },

                    scope:New "TextLabel" {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 1, -14),
                        Size = UDim2.new(1, 0, 0, 13),
                        Text = progressText,
                        TextColor3 = Color3.fromRGB(150, 150, 170),
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        FontFace = REG,
                    },
                },
            },

            -- Right reward panel: top half = reward label, bottom half = timer
            scope:New "Frame" {
                Name = "RewardPanel",
                BackgroundColor3 = rewardBg,
                Size = UDim2.new(0.32, -8, 1, 0),
                LayoutOrder = 2,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },

                    -- Top half: reward name
                    scope:New "TextLabel" {
                        AnchorPoint = Vector2.new(0.5, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(0.5, 0.05),
                        Size = UDim2.fromScale(0.9, 0.45),
                        Text = props.Reward.Label,
                        TextColor3 = Color3.fromRGB(255, 210, 60),
                        TextScaled = true,
                        TextWrapped = true,
                        FontFace = BOLD,
                    },

                    -- Bottom half: timer / completed
                    scope:New "TextLabel" {
                        AnchorPoint = Vector2.new(0.5, 1),
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(0.5, 0.95),
                        Size = UDim2.fromScale(0.9, 0.45),
                        Text = timerText,
                        TextColor3 = timerColor,
                        TextScaled = true,
                        FontFace = BOLD,
                    },
                },
            },
        },
    }
end
