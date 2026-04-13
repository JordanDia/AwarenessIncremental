local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local GamepassConfig = require(ReplicatedStorage.Shared.Configs.GamepassConfig)

local COLOR_BUY   = Color3.fromRGB(80, 200, 120)
local COLOR_OWNED = Color3.fromRGB(80, 80, 90)

local function GamepassBoard(scope, pass, owned: Fusion.Value<boolean>, onBuy: () -> ())
    return scope:New "Frame" {
        Name                   = "GamepassBoard",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,

        [Fusion.Children] = {
            scope:New "UIListLayout" {
                FillDirection       = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment   = Enum.VerticalAlignment.Center,
                Padding             = UDim.new(0.03, 0),
                SortOrder           = Enum.SortOrder.LayoutOrder,
            },

            scope:New "UIPadding" {
                PaddingTop    = UDim.new(0.05, 0),
                PaddingBottom = UDim.new(0.05, 0),
                PaddingLeft   = UDim.new(0.05, 0),
                PaddingRight  = UDim.new(0.05, 0),
            },

            -- Title
            scope:New "TextLabel" {
                LayoutOrder            = 1,
                Size                   = UDim2.fromScale(1, 0.2),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Text                   = pass.Name,
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = Color3.fromRGB(255, 255, 255),
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                },
            },

            -- Icon
            scope:New "ImageLabel" {
                LayoutOrder            = 2,
                Size                   = UDim2.fromScale(0.55, 0.45),
                BackgroundTransparency = 1,
                Image                  = pass.Icon,
                ScaleType              = Enum.ScaleType.Fit,
            },

            -- Buy / Owned button
            scope:New "TextButton" {
                LayoutOrder      = 3,
                Size             = UDim2.fromScale(0.7, 0.18),
                BackgroundColor3 = scope:Computed(function(use)
                    return use(owned) and COLOR_OWNED or COLOR_BUY
                end),
                BorderSizePixel  = 0,
                Text             = "",

                [Fusion.OnEvent "Activated"] = function()
                    if not Fusion.peek(owned) then
                        onBuy()
                    end
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
                    scope:New "UIStroke" {
                        Thickness       = 3,
                        Color           = Color3.fromRGB(0, 0, 0),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },
                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.9, 0.6),
                        BackgroundTransparency = 1,
                        Text                   = scope:Computed(function(use)
                            return use(owned) and "Owned" or "Buy"
                        end),
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = Color3.fromRGB(255, 255, 255),
                        ZIndex                 = 2,
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },
                },
            },
        },
    }
end

return function(parent)
    local scope = scoped(Fusion)

    local GamepassService = Knit.GetService("GamepassService")

    -- Track which passes the local player owns
    local ownedMap: { [number]: Fusion.Value<boolean> } = {}
    for _, pass in ipairs(GamepassConfig) do
        ownedMap[pass.PassId] = scope:Value(false)
    end

    -- Set owned state when the server confirms loaded passes
    GamepassService.PassesLoaded:Connect(function(ownedPassIds: { number })
        for _, passId in ipairs(ownedPassIds) do
            if ownedMap[passId] then
                ownedMap[passId]:set(true)
            end
        end
    end)

    -- Also apply immediately on purchase prompt completion
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_player, passId, wasPurchased)
        if wasPurchased and ownedMap[passId] then
            ownedMap[passId]:set(true)
        end
    end)

    -- Mount a SurfaceGui for each gamepass board part in workspace
    local boardsFolder = workspace:WaitForChild("GamepassBoards")

    for _, pass in ipairs(GamepassConfig) do
        local part = boardsFolder:FindFirstChild(pass.PartName)
        if not part then
            warn("GamepassBoards: no part named '" .. pass.PartName .. "' in workspace.GamepassBoards")
            continue
        end

        local owned = ownedMap[pass.PassId]

        scope:New "SurfaceGui" {
            Name              = "GamepassBoard_" .. pass.PartName,
            Adornee           = part,
            Face              = Enum.NormalId.Front,
            Parent            = parent,
            SizingMode        = Enum.SurfaceGuiSizingMode.PixelsPerStud,
            PixelsPerStud     = 50,
            [Fusion.Children] = {
                GamepassBoard(scope, pass, owned, function()
                    GamepassService:PromptPurchase(pass.PassId)
                end),
            },
        }
    end

    return function()
        scope:doCleanup()
    end
end
