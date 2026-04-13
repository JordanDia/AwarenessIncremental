local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit   = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local DonateConfig = require(ReplicatedStorage.Shared.Configs.DonateConfig)

local COLOR_BUTTON  = Color3.fromRGB(80, 200, 120)
local COLOR_BLACK   = Color3.fromRGB(0, 0, 0)
local COLOR_WHITE   = Color3.fromRGB(255, 255, 255)

return function(parent)
    local scope = Fusion.scoped(Fusion)

    local DonateService = Knit.GetService("DonateService")

    local boardPart = workspace:WaitForChild("DonateBoard"):WaitForChild("Root")

    -- Build product button rows
    local productButtons = {}
    for i, product in ipairs(DonateConfig) do
        local capturedProduct = product
        table.insert(productButtons,
            scope:New "TextButton" {
                LayoutOrder      = i + 1,
                Size             = UDim2.fromScale(1, 0.14),
                BackgroundColor3 = COLOR_BUTTON,
                BorderSizePixel  = 0,
                Text             = "",

                [Fusion.OnEvent "Activated"] = function()
                    DonateService:PromptDonate(capturedProduct.ProductId)
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.1, 0) },
                    scope:New "UIStroke" {
                        Thickness       = 2,
                        Color           = COLOR_BLACK,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },

                    -- Robux icon + amount via RichText
                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.9, 0.85),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text                   = "\u{E002} " .. capturedProduct.Label,
                        RichText               = true,
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = COLOR_WHITE,
                        TextXAlignment         = Enum.TextXAlignment.Center,
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2, Color = COLOR_BLACK },
                        },
                    },
                },
            }
        )
    end

    scope:New "SurfaceGui" {
        Name          = "DonateBoardGui",
        Adornee       = boardPart,
        Face          = Enum.NormalId.Front,
        Parent        = parent,
        SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 50,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name                   = "Outer",
                Size                   = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,

                [Fusion.Children] = {
                    scope:New "UIPadding" {
                        PaddingTop    = UDim.new(0.05, 0),
                        PaddingBottom = UDim.new(0.05, 0),
                        PaddingLeft   = UDim.new(0.05, 0),
                        PaddingRight  = UDim.new(0.05, 0),
                    },

                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        Padding             = UDim.new(0.025, 0),
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                    },

                    -- Header
                    scope:New "TextLabel" {
                        LayoutOrder            = 1,
                        Size                   = UDim2.fromScale(1, 0.13),
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        Text                   = "DONATE",
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
                        TextColor3             = COLOR_WHITE,
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 4, Color = COLOR_BLACK },
                        },
                    },

                    table.unpack(productButtons),
                },
            },
        },
    }

    return function()
        scope:doCleanup()
    end
end
