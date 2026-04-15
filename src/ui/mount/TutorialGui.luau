local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

return function(parent)
    local scope = scoped(Fusion)

    local TutorialService = Knit.GetService("TutorialService")

    -- Reactive state
    local visible     = scope:Value(false)
    local titleText   = scope:Value("")
    local showBar     = scope:Value(false)
    local progress    = scope:Value(0)
    local goal        = scope:Value(1)

    local barScale = scope:Computed(function(use)
        local g = use(goal)
        if g <= 0 then return 0 end
        return math.clamp(use(progress) / g, 0, 1)
    end)

    local barText = scope:Computed(function(use)
        return math.floor(use(progress)) .. " / " .. math.floor(use(goal))
    end)

    local endMessageThread = nil

    local function showEndMessage()
        titleText:set("Keep upgrading and exploring the map! Have fun!")
        showBar:set(false)
        visible:set(true)
        endMessageThread = task.delay(6, function()
            endMessageThread = nil
            visible:set(false)
        end)
    end

    local function applyStage(cfg, prog)
        if endMessageThread then
            task.cancel(endMessageThread)
            endMessageThread = nil
        end
        if not cfg then
            showEndMessage()
            return
        end
        titleText:set(cfg.Title)
        showBar:set(cfg.ShowBar)
        goal:set(cfg.Goal or 1)
        progress:set(prog or 0)
        visible:set(true)
    end

    -- Seed from server on load
    local _, initStage, initProg = TutorialService:GetCurrentStage()
    applyStage(initStage, initProg)

    -- Listen for stage advances
    TutorialService.StageChanged:Connect(function(_index, cfg, p)
        applyStage(cfg, p)
    end)

    -- Live progress updates within a stage
    TutorialService.ProgressUpdated:Connect(function(p, g)
        progress:set(p)
        goal:set(g)
    end)

    -- ── UI ────────────────────────────────────────────────────────────────────

    scope:New "ScreenGui" {
        Name            = "TutorialGui",
        Parent          = parent,
        ResetOnSpawn    = false,
        IgnoreGuiInset  = true,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name             = "TutorialFrame",
                AnchorPoint      = Vector2.new(0.5, 0),
                Position         = UDim2.fromScale(0.5, 0.02),
                Size             = UDim2.fromScale(0.42, 0.1),
                BackgroundColor3 = Color3.fromRGB(20, 20, 27),
                BackgroundTransparency = 0.5,
                BorderSizePixel  = 0,
                Visible          = visible,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.12, 0) },
                    -- scope:New "UIStroke" {
                    --     Color     = Color3.fromRGB(55, 55, 70),
                    --     Thickness = 1.5,
                    -- },
                    scope:New "UIPadding" {
                        PaddingTop    = UDim.new(0.1, 0),
                        PaddingBottom = UDim.new(0.1, 0),
                        PaddingLeft   = UDim.new(0.03, 0),
                        PaddingRight  = UDim.new(0.03, 0),
                    },
                    scope:New "UIListLayout" {
                        FillDirection     = Enum.FillDirection.Vertical,
                        SortOrder         = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding           = UDim.new(0.06, 0),
                    },

                    -- Title
                    scope:New "TextLabel" {
                        LayoutOrder          = 1,
                        Size                 = UDim2.fromScale(1, 0.45),
                        BackgroundTransparency = 1,
                        Text                 = titleText,
                        TextColor3           = Color3.fromRGB(255, 255, 255),
                        FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextScaled           = true,
                        TextXAlignment       = Enum.TextXAlignment.Center,
                        TextWrapped          = true,

                        
                    },

                    -- Progress bar container (hidden when ShowBar = false)
                    scope:New "Frame" {
                        LayoutOrder          = 2,
                        Size                 = UDim2.fromScale(1, 0.3),
                        BackgroundTransparency = 1,
                        Visible              = showBar,

                        [Fusion.Children] = {
                            -- Track
                            scope:New "Frame" {
                                Size             = UDim2.fromScale(1, 1),
                                BackgroundColor3 = Color3.fromRGB(40, 40, 52),

                                [Fusion.Children] = {
                                    scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },

                                    -- Fill
                                    scope:New "Frame" {
                                        Size             = scope:Computed(function(use)
                                            return UDim2.fromScale(use(barScale), 1)
                                        end),
                                        BackgroundColor3 = Color3.fromRGB(80, 200, 120),

                                        [Fusion.Children] = {
                                            scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
                                        },
                                    },

                                    -- Label
                                    scope:New "TextLabel" {
                                        Size                 = UDim2.fromScale(1, 1),
                                        BackgroundTransparency = 1,
                                        Text                 = barText,
                                        TextColor3           = Color3.fromRGB(255, 255, 255),
                                        FontFace             = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                                        TextScaled           = true,
                                        ZIndex               = 2,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    return function()
        scope:doCleanup()
    end
end
