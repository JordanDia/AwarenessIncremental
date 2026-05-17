local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage.Packages.Knit)
local Fusion      = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)

local CATEGORIES = {
    {
        id         = "TopAwareness",
        label      = "Top Awareness",
        dataKey    = "Awareness",
        color      = Color3.fromRGB(255, 200, 40),
    },
    {
        id         = "TopRebirths",
        label      = "Top Rebirths",
        dataKey    = "Rebirths",
        color      = Color3.fromRGB(50, 140, 230),
    },
    {
        id         = "TopCrystals",
        label      = "Top Crystals",
        dataKey    = "Crystals",
        color      = Color3.fromRGB(140, 60, 230),
    },
    {
        id         = "TopAstralEchoes",
        label      = "Top Astral Echoes",
        dataKey    = "AstralEchoes",
        color      = Color3.fromRGB(0, 190, 180),
    },
    {
        id         = "TopRobuxSpent",
        label      = "Top Robux Spent",
        dataKey    = "RobuxSpent",
        color      = Color3.fromRGB(80, 200, 120),
    },
    {
        id         = "TopTimePlayed",
        label      = "Top Time Played",
        dataKey    = "PlaytimeSeconds",
        color      = Color3.fromRGB(230, 130, 50),
    },
    {
        id         = "TopEssences",
        label      = "Top Essences",
        dataKey    = "Essences",
        color      = Color3.fromRGB(255, 255, 255),
    },
    {
        id         = "TopDarkEssences",
        label      = "Top Dark Essences",
        dataKey    = "DarkEssences",
        color      = Color3.fromRGB(255, 60, 60),
    },
    {
        id         = "TopRaidWins",
        label      = "Top Raid Wins",
        dataKey    = "RaidWins",
        color      = Color3.fromRGB(255, 180, 50),
    },
}

local function formatValue(categoryId, value)
    if categoryId == "TopTimePlayed" then
        local h = math.floor(value / 3600)
        local m = math.floor((value % 3600) / 60)
        return h .. "h " .. m .. "m"
    elseif categoryId == "TopRobuxSpent" then
        return "R$" .. FormatNumber(value)
    else
        return FormatNumber(value)
    end
end

local function rankBadgeColor(rank)
    if rank == 1 then
        return Color3.fromRGB(255, 200, 50)
    elseif rank == 2 then
        return Color3.fromRGB(180, 180, 180)
    elseif rank == 3 then
        return Color3.fromRGB(180, 100, 50)
    else
        return Color3.fromRGB(60, 80, 120)
    end
end

local ENTRY_HEIGHT = 68

local function buildEntryRow(scope, entry)
    local badgeColor = rankBadgeColor(entry.rank)

    return scope:New "Frame" {
        Name                   = "Entry_" .. entry.rank,
        Size                   = UDim2.new(1, 0, 0, ENTRY_HEIGHT),
        BackgroundColor3       = Color3.fromRGB(70, 74, 82),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,

        [Fusion.Children] = {
            scope:New "UICorner" { CornerRadius = UDim.new(0.12, 0) },

            scope:New "UIPadding" {
                PaddingLeft   = UDim.new(0.02, 0),
                PaddingRight  = UDim.new(0.02, 0),
            },

            scope:New "UIListLayout" {
                FillDirection       = Enum.FillDirection.Horizontal,
                VerticalAlignment   = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding             = UDim.new(0.02, 0),
                SortOrder           = Enum.SortOrder.LayoutOrder,
            },

            -- Rank badge
            scope:New "Frame" {
                LayoutOrder      = 1,
                Size             = UDim2.fromOffset(ENTRY_HEIGHT - 12, ENTRY_HEIGHT - 12),
                BackgroundColor3 = badgeColor,
                BorderSizePixel  = 0,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.9, 0.75),
                        BackgroundTransparency = 1,
                        Text                   = "#" .. entry.rank,
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = Color3.fromRGB(255, 255, 255),
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },
                },
            },

            -- Player name
            scope:New "TextLabel" {
                LayoutOrder            = 2,
                Size                   = UDim2.fromScale(0.5, 0.75),
                BackgroundTransparency = 1,
                Text                   = entry.name,
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 255, 255),
                TextXAlignment         = Enum.TextXAlignment.Center,
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) },
                },
            },

            -- Value
            scope:New "TextLabel" {
                LayoutOrder            = 3,
                Size                   = UDim2.fromScale(0.3, 0.75),
                BackgroundTransparency = 1,
                Text                   = entry.displayValue,
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 255, 255),
                TextXAlignment         = Enum.TextXAlignment.Right,
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) },
                },
            },
        },
    }
end

return function(parent)
    local scope = Fusion.scoped(Fusion)

    local LeaderboardService = Knit.GetService("LeaderboardService")

    local boardsFolder = workspace:WaitForChild("LeaderboardBoards")

    for _, category in ipairs(CATEGORIES) do
        local part = boardsFolder:WaitForChild(category.id):WaitForChild("Root")

        local data      = scope:Value({})
        local isLoading = scope:Value(true)

        -- Fetch and refresh data
        local function fetchData()
            local result = LeaderboardService:GetLeaderboard(category.id)
            -- Pre-format values to avoid calling formatValue inside ForValues
            local formatted = {}
            for _, entry in ipairs(result) do
                table.insert(formatted, {
                    rank         = entry.rank,
                    name         = entry.name,
                    value        = entry.value,
                    displayValue = formatValue(category.id, entry.value),
                })
            end
            data:set(formatted)
            isLoading:set(false)
        end

        task.spawn(fetchData)

        -- Re-fetch whenever this specific category finishes refreshing
        LeaderboardService.LeaderboardRefreshed:Connect(function(refreshedId)
            if refreshedId == category.id then
                fetchData()
            end
        end)

        scope:New "SurfaceGui" {
            Name          = "LeaderboardGui_" .. category.id,
            Adornee       = part,
            Face          = Enum.NormalId.Front,
            Parent        = parent,
            SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud,
            PixelsPerStud = 50,

            [Fusion.Children] = {
                -- Outer frame
                scope:New "Frame" {
                    Name                   = "Outer",
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
                            Size                   = UDim2.fromScale(1, 0.13),
                            BackgroundTransparency = 1,
                            BorderSizePixel        = 0,
                            Text                   = category.label,
                            TextScaled             = true,
                            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                            TextColor3             = Color3.fromRGB(255, 255, 255),
                            [Fusion.Children] = {
                                scope:New "UIStroke" { Thickness = 4, Color = Color3.fromRGB(0, 0, 0) },
                            },
                        },

                        -- Loading label
                        scope:New "TextLabel" {
                            LayoutOrder            = 2,
                            Size                   = UDim2.fromScale(1, 0.05),
                            BackgroundTransparency = 1,
                            Text                   = "Loading...",
                            TextScaled             = true,
                            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Regular),
                            TextColor3             = Color3.fromRGB(200, 200, 200),
                            Visible                = scope:Computed(function(use)
                                return use(isLoading)
                            end),
                        },

                        -- Scrolling frame with entries
                        scope:New "ScrollingFrame" {
                            LayoutOrder            = 3,
                            Size                   = UDim2.fromScale(1, 0.88),
                            BackgroundTransparency = 1,
                            BorderSizePixel        = 0,
                            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                            CanvasSize             = UDim2.fromScale(1, 0),
                            ScrollBarThickness     = 4,

                            [Fusion.Children] = {
                                scope:New "UIListLayout" {
                                    FillDirection       = Enum.FillDirection.Vertical,
                                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                    Padding             = UDim.new(0.01, 0),
                                    SortOrder           = Enum.SortOrder.LayoutOrder,
                                },

                                scope:ForValues(data, function(use, innerScope, entry)
                                    return buildEntryRow(innerScope, entry)
                                end),
                            },
                        },
                    },
                },
            },
        }
    end

    return function()
        scope:doCleanup()
    end
end
