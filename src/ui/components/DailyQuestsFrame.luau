local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local QuestItem = require(script.Parent.QuestItem)

-- Props:
--   Visible       Value<boolean>
--   OnClose       function
--   QuestService  (Knit client proxy)

return function(scope, props)
    local QuestService = props.QuestService

    -- Single clock Value that ticks every second — drives all timers reactively
    local clock = scope:Value(os.clock())

    task.spawn(function()
        while true do
            task.wait(1)
            clock:set(os.clock())
        end
    end)

    -- Per-quest state: progress, claimed, buffEndTime (absolute os.clock() timestamp)
    local questStates = {}

    local questList = QuestService:GetQuests()
    for _, q in questList do
        questStates[q.Id] = {
            progress    = scope:Value(q.Progress),
            claimed     = scope:Value(q.Claimed),
            buffEndTime = scope:Value(0), -- 0 = no active buff
        }
    end

    -- Absolute end time for the daily reset
    local resetEndTime = scope:Value(
        os.clock() + (questList[1] and questList[1].TimeUntilReset or 0)
    )

    local resetText = scope:Computed(function(use)
        local s = math.floor(math.max(0, use(resetEndTime) - use(clock)))
        local h = math.floor(s / 3600)
        local m = math.floor((s % 3600) / 60)
        local sec = s % 60
        return string.format("Resets in %02d:%02d:%02d", h, m, sec)
    end)

    -- Server pushes: (questId, progress, claimed, duration)
    QuestService.QuestProgressUpdated:Connect(function(questId, progress, claimed, duration)
        local state = questStates[questId]
        if not state then return end
        state.progress:set(progress)
        state.claimed:set(claimed)
        if claimed and duration and duration > 0 then
            state.buffEndTime:set(os.clock() + duration)
        end
    end)

    -- Full daily reset
    QuestService.QuestsReset:Connect(function()
        for _, state in questStates do
            state.progress:set(0)
            state.claimed:set(false)
            state.buffEndTime:set(0)
        end
        resetEndTime:set(os.clock() + 86400)
    end)

    -- Build quest items
    local questChildren = {
        scope:New "UIListLayout" {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        },
        scope:New "UIPadding" {
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        },
    }

    for i, q in questList do
        local state = questStates[q.Id]
        table.insert(questChildren, QuestItem(scope, {
            Title       = q.Title,
            Description = q.Description,
            Goal        = q.Goal,
            Format      = q.Format,
            Reward      = q.Reward,
            Progress    = state.progress,
            Claimed     = state.claimed,
            BuffEndTime = state.buffEndTime,
            Clock       = clock,
            LayoutOrder = i,
        }))
    end

    return scope:New "CanvasGroup" {
        Name = "DailyQuestsPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(20, 20, 27),
        BackgroundTransparency = 0.3,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.48, 0.7),
        Visible = props.Visible,

        [Fusion.Children] = {
            scope:New "UIStroke" {
                BorderStrokePosition = Enum.BorderStrokePosition.Center,
                Thickness = 6,
            },

            scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },

            scope:New "Frame" {
                Name = "Header",
                BackgroundColor3 = Color3.fromRGB(85, 170, 127),
                Size = UDim2.fromScale(1, 0.08),

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0, 10) },
                    scope:New "UIStroke" {
                        BorderStrokePosition = Enum.BorderStrokePosition.Center,
                        Thickness = 6,
                    },

                    scope:New "TextLabel" {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0.7, 0.7),
                        Text = "Daily Quests",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
                        [Fusion.Children] = {
                            scope:New "UIStroke" {
                                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                                Thickness = 0.05,
                            },
                        },
                    },

                    scope:New "TextButton" {
                        AnchorPoint = Vector2.new(1, 0.5),
                        AutoButtonColor = false,
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.fromScale(0, 1),
                        Text = "X",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold),
                        [Fusion.OnEvent "Activated"] = function()
                            if props.OnClose then
                                props.OnClose()
                            end
                        end,
                        [Fusion.Children] = {
                            scope:New "UICorner" { CornerRadius = UDim.new(0.25, 0) },
                            scope:New "UIAspectRatioConstraint" {},
                        },
                    },
                },
            },

            scope:New "ScrollingFrame" {
                AnchorPoint = Vector2.new(0.5, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.new(),
                Position = UDim2.fromScale(0.5, 0.09),
                ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
                ScrollBarThickness = 4,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.fromScale(0.95, 0.82),

                [Fusion.Children] = questChildren,
            },

            scope:New "TextLabel" {
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 1),
                Size = UDim2.fromScale(1, 0.07),
                Text = resetText,
                TextColor3 = Color3.fromRGB(160, 160, 180),
                TextScaled = true,
                FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular),
            },
        },
    }
end
