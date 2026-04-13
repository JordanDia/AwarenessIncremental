local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local GamepassConfig = require(ReplicatedStorage.Shared.Configs.GamepassConfig)

return function(parent)
    local scope = scoped(Fusion)

    local GamepassService = Knit.GetService("GamepassService")

    -- Track owned passes
    local ownedMap: { [number]: Fusion.Value<boolean> } = {}
    for _, pass in ipairs(GamepassConfig) do
        ownedMap[pass.PassId] = scope:Value(false)
    end

    GamepassService.PassesLoaded:Connect(function(ownedPassIds: { number })
        for _, passId in ipairs(ownedPassIds) do
            if ownedMap[passId] then
                ownedMap[passId]:set(true)
            end
        end
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_player, passId, wasPurchased)
        if wasPurchased and ownedMap[passId] then
            ownedMap[passId]:set(true)
        end
    end)

    -- Build grid cells
    local cells = {}
    for i, pass in ipairs(GamepassConfig) do
        local owned = ownedMap[pass.PassId]

        local cell = scope:New "TextButton" {
            Name             = pass.PartName,
            LayoutOrder      = i,
            -- Width controlled by UIGridLayout; height via AspectRatio on the cell
            Size             = UDim2.fromScale(1, 1),
            BackgroundColor3 = scope:Computed(function(use)
                return use(owned) and Color3.fromRGB(60, 60, 60) or pass.Color
            end),
            BorderSizePixel  = 0,
            Text             = "",
            AutoButtonColor  = false,

            [Fusion.OnEvent "Activated"] = function()
                if not Fusion.peek(owned) then
                    GamepassService:PromptPurchase(pass.PassId)
                end
            end,

            [Fusion.Children] = {
                scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
                scope:New "UIStroke" {
                    Thickness       = 2,
                    Color           = Color3.fromRGB(0, 0, 0),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                },
                scope:New "UIPadding" {
                    PaddingLeft   = UDim.new(0.06, 0),
                    PaddingRight  = UDim.new(0.06, 0),
                    PaddingTop    = UDim.new(0.08, 0),
                    PaddingBottom = UDim.new(0.08, 0),
                },

                scope:New "Frame" {
                    Size                   = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    [Fusion.Children] = {
                        scope:New "UIListLayout" {
                            FillDirection       = Enum.FillDirection.Horizontal,
                            VerticalAlignment   = Enum.VerticalAlignment.Center,
                            HorizontalAlignment = Enum.HorizontalAlignment.Left,
                            Padding             = UDim.new(0.06, 0),
                            SortOrder           = Enum.SortOrder.LayoutOrder,
                        },

                        -- Icon
                        scope:New "ImageLabel" {
                            LayoutOrder            = 1,
                            Size                   = UDim2.fromScale(0.35, 1),
                            BackgroundTransparency = 1,
                            Image                  = pass.Icon,
                            ScaleType              = Enum.ScaleType.Fit,
                            [Fusion.Children] = {
                                scope:New "UIAspectRatioConstraint" { AspectRatio = 1 },
                            },
                        },

                        -- Name
                        scope:New "TextLabel" {
                            LayoutOrder            = 2,
                            Size                   = UDim2.fromScale(0.59, 1),
                            BackgroundTransparency = 1,
                            Text                   = scope:Computed(function(use)
                                return use(owned) and (pass.Name .. "\n✓ Owned") or pass.Name
                            end),
                            TextScaled             = true,
                            TextWrapped            = true,
                            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                            TextColor3             = Color3.fromRGB(255, 255, 255),
                            TextXAlignment         = Enum.TextXAlignment.Left,
                            [Fusion.Children] = {
                                scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                            },
                        },
                    },
                },
            },
        }

        table.insert(cells, cell)
    end

    local boardPart = workspace:WaitForChild("GamepassBoardModel"):WaitForChild("GamepassOverviewBoard")

    scope:New "SurfaceGui" {
        Name          = "GamepassOverviewBoard",
        Adornee       = boardPart,
        Face          = Enum.NormalId.Front,
        Parent        = parent,
        SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 50,

        [Fusion.Children] = {
            scope:New "Frame" {
                Size                   = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,

                [Fusion.Children] = {
                    scope:New "UIPadding" {
                        PaddingTop    = UDim.new(0.04, 0),
                        PaddingBottom = UDim.new(0.04, 0),
                        PaddingLeft   = UDim.new(0.04, 0),
                        PaddingRight  = UDim.new(0.04, 0),
                    },

                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding             = UDim.new(0.02, 0),
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                    },

                    -- Header
                    scope:New "TextLabel" {
                        LayoutOrder            = 1,
                        Size                   = UDim2.fromScale(1, 0.12),
                        BackgroundTransparency = 1,
                        Text                   = "Gamepasses",
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = Color3.fromRGB(255, 255, 255),
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 3, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },

                    -- Scrolling grid (fills remaining 86%)
                    scope:New "ScrollingFrame" {
                        LayoutOrder              = 2,
                        Size                     = UDim2.fromScale(1, 0.86),
                        CanvasSize               = UDim2.fromScale(1, 0),
                        AutomaticCanvasSize      = Enum.AutomaticSize.Y,
                        BackgroundTransparency   = 1,
                        BorderSizePixel          = 0,
                        ScrollBarThickness       = 4,
                        ScrollBarImageColor3     = Color3.fromRGB(180, 180, 180),
                        ScrollingDirection       = Enum.ScrollingDirection.Y,

                        [Fusion.Children] = {
                            -- CellSize X=scale (each of 2 columns), Y=scale relative to frame
                            scope:New "UIGridLayout" {
                                CellSize            = UDim2.fromScale(0.47, 0.28),
                                CellPadding         = UDim2.fromScale(0.03, 0.03),
                                FillDirection       = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                SortOrder           = Enum.SortOrder.LayoutOrder,
                            },

                            scope:New "UIPadding" {
                                PaddingTop = UDim.new(0.02, 0)
                            },

                            table.unpack(cells),
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
