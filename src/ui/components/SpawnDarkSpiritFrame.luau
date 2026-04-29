local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion      = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Shared.Modules.FormatQN)
local DarkSpiritConfig = require(ReplicatedStorage.Shared.Configs.DarkSpiritConfig)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local function qnToDouble(v)
	if type(v) ~= "buffer" then return v or 0 end
	local d = num.toNumber(v)
	return (d == math.huge or d ~= d) and 1e308 or d
end

-- Props:
--   Essences         Value<number>
--   Awareness        Value<number>
--   Crystals         Value<number>
--   AstralEchoes     Value<number>
--   Rebirths         Value<number>
--   Summons          Value<number>
--   MaxSummons       Value<number>
--   NextSummonRegen  Value<number>  -- os.time() Unix timestamp, 0 = no timer
--   OnSpawn          function()
--   OnBuyMaxSummons  function()

local cost = DarkSpiritConfig.SpawnCost
local freeInStudio = DarkSpiritConfig.FreeInStudio

return function(scope, props)

    -- Countdown: updates every second, shows MM:SS when summons = 0 and timer is running
    local spawnButtonText = scope:Value("SPAWN")

    task.spawn(function()
        while true do
            task.wait(1)
            local summons = Fusion.peek(props.Summons)
            if summons and summons < 1 then
                local nextRegen = Fusion.peek(props.NextSummonRegen)
                if nextRegen and nextRegen > 0 then
                    local remaining = math.max(0, nextRegen - os.time())
                    local minutes = math.floor(remaining / 60)
                    local seconds = remaining % 60
                    spawnButtonText:set(string.format("%d:%02d", minutes, seconds))
                else
                    spawnButtonText:set("0:00")
                end
            else
                spawnButtonText:set("SPAWN")
            end
        end
    end)

    local canAfford = scope:Computed(function(use)
        if use(props.Summons) < 1 then return false end
        if freeInStudio then return true end
        return qnToDouble(use(props.Essences))      >= cost.Essences
            and qnToDouble(use(props.Awareness))    >= cost.Awareness
            and qnToDouble(use(props.Crystals))     >= cost.Crystals
            and qnToDouble(use(props.AstralEchoes)) >= cost.AstralEchoes
            and qnToDouble(use(props.Rebirths))     >= cost.Rebirths
    end)

    local function CostLine(label, valueKey, costAmount, color)
        local meetsReq = scope:Computed(function(use)
            if freeInStudio then return true end
            return qnToDouble(use(props[valueKey])) >= costAmount
        end)

        local textValue = FormatNumber(costAmount) .. " " .. label
        if valueKey == "Rebirths" then
            textValue = textValue .. " (resets)"
        end

        return scope:New "TextLabel" {
            Size                   = UDim2.fromScale(1, 0.09),
            BackgroundTransparency = 1,
            Text                   = textValue,
            TextScaled             = true,
            RichText               = true,
            FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
            TextColor3             = scope:Computed(function(use)
                return use(meetsReq) and color or Color3.fromRGB(180, 60, 60)
            end),
            TextXAlignment         = Enum.TextXAlignment.Center,
            [Fusion.Children] = {
                scope:New "UIStroke" { Thickness = 1 },
            },
        }
    end

    return scope:New "Frame" {
        Name                   = "SpawnDarkSpiritFrame",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,

        [Fusion.Children] = {
            scope:New "UICorner" { CornerRadius = UDim.new(0.02, 0) },

            scope:New "UIPadding" {
                PaddingTop    = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft   = UDim.new(0, 10),
                PaddingRight  = UDim.new(0, 10),
            },

            scope:New "UIListLayout" {
                FillDirection       = Enum.FillDirection.Vertical,
                Padding             = UDim.new(0.015, 0),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder           = Enum.SortOrder.LayoutOrder,
            },

            -- Title
            scope:New "TextLabel" {
                LayoutOrder            = 1,
                Size                   = UDim2.fromScale(1, 0.10),
                BackgroundTransparency = 1,
                Text                   = "SUMMON DARK SPIRIT",
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
                TextColor3             = Color3.fromRGB(200, 50, 255),
                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Thickness = 2,
                        Color     = Color3.fromRGB(80, 0, 120),
                    },
                },
            },

            -- "Requirements:" header
            scope:New "Frame" {
                Name = "RequirementContainer",
                LayoutOrder            = 2,
                Size                   = UDim2.fromScale(1, 0.5),
                BackgroundTransparency = 1,

                [Fusion.Children] = {

                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Vertical,
                        Padding             = UDim.new(0.015, 0),
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                        VerticalFlex = Enum.UIFlexAlignment.Fill
                    },

                    -- maybe use for values here
                    CostLine("Essences",     "Essences",     cost.Essences,     Color3.fromRGB(180, 120, 255)),
                    CostLine("Awareness",    "Awareness",    cost.Awareness,    Color3.fromRGB(255, 215, 0)),
                    CostLine("Crystals",     "Crystals",     cost.Crystals,     Color3.fromRGB(132, 0, 255)),
                    CostLine("Astral Echoes","AstralEchoes", cost.AstralEchoes, Color3.fromRGB(0, 210, 200)),
                    CostLine("Rebirths",     "Rebirths",     cost.Rebirths,     Color3.fromRGB(0, 153, 255)),
                }
            },

            -- Spawn button
            scope:New "TextButton" {
                LayoutOrder      = 10,
                Size             = UDim2.fromScale(0.65, 0.11),
                Text             = "",
                BackgroundColor3 = scope:Computed(function(use)
                    return use(canAfford)
                        and Color3.fromRGB(140, 0, 200)
                        or  Color3.fromRGB(50, 50, 60)
                end),
                BorderSizePixel  = 0,

                [Fusion.OnEvent "Activated"] = function()
                    if Fusion.peek(canAfford) and props.OnSpawn then
                        props.OnSpawn()
                    end
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.15, 0) },
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
                        ZIndex                 = 10,
                        Text                   = spawnButtonText,
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
                        TextColor3             = Color3.new(1, 1, 1),
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 3 },
                        },
                    },
                },
            },

            -- Summons counter
            scope:New "TextLabel" {
                Name                   = "Summons",
                LayoutOrder            = 20,
                Size                   = UDim2.fromScale(1, 0.07),
                BackgroundTransparency = 1,
                Text                   = scope:Computed(function(use)
                    return use(props.Summons) .. "/" .. use(props.MaxSummons) .. " Summons"
                end),
                TextColor3             = scope:Computed(function(use)
                    return use(props.Summons) >= 1
                        and Color3.fromRGB(255, 255, 255)
                        or  Color3.fromRGB(180, 60, 60)
                end),
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
            },

            -- Buy Max Summons button
            scope:New "TextButton" {
                Name             = "BuyMaxSummons",
                LayoutOrder      = 30,
                Size             = UDim2.fromScale(0.75, 0.10),
                Text             = "",
                BackgroundColor3 = Color3.fromRGB(90, 200, 0),
                BorderSizePixel  = 0,

                [Fusion.OnEvent "Activated"] = function()
                    if props.OnBuyMaxSummons then
                        props.OnBuyMaxSummons()
                    end
                end,

                [Fusion.Children] = {
                    scope:New "UICorner" { CornerRadius = UDim.new(0.15, 0) },
                    scope:New "UIStroke" {
                        Thickness       = 2,
                        Color           = Color3.fromRGB(0, 0, 0),
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    },
                    scope:New "TextLabel" {
                        AnchorPoint            = Vector2.new(0.5, 0.5),
                        Position               = UDim2.fromScale(0.5, 0.5),
                        Size                   = UDim2.fromScale(0.9, 0.6),
                        BackgroundTransparency = 1,
                        ZIndex                 = 10,
                        Text                   = "+ Max Summons",
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
                        TextColor3             = Color3.new(1, 1, 1),
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2 },
                        },
                    },
                },
            },
        },
    }
end
