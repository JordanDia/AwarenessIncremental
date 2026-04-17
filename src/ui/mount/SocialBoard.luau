local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local SocialService = game:GetService("SocialService")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local LocalPlayer = Players.LocalPlayer

-- ── Icons ──────────────────────────────────────────────────────────────────
local ICON_FRIENDS  = "rbxassetid://114914589995541"
local ICON_PREMIUM  = "rbxassetid://109492215786226"

local COLOR_TEXT    = Color3.fromRGB(255, 255, 255)
local COLOR_DESC    = Color3.fromRGB(220, 220, 220)
local COLOR_DIVIDER = Color3.fromRGB(80, 80, 90)

-- ── Social data helpers ────────────────────────────────────────────────────

local function buildSocialData(scope)
    local friendships: { [number]: boolean } = {}
    local friendCount = scope:Value(0)

    local hasPremium = LocalPlayer.MembershipType == Enum.MembershipType.Premium
    local premiumBonus = scope:Value(hasPremium and 10 or 0)

    local function refreshCount()
        local n = 0
        for _, isFriend in pairs(friendships) do
            if isFriend then
                n += 1
            end
        end
        friendCount:set(n)
    end

    local function checkFriendship(player)
        if player == LocalPlayer then return end
        local userId = player.UserId
        task.spawn(function()
            local ok, result = pcall(function()
                return LocalPlayer:IsFriendsWith(userId)
            end)
            friendships[userId] = ok and result or false
            refreshCount()
        end)
    end

    for _, player in Players:GetPlayers() do
        checkFriendship(player)
    end
    Players.PlayerAdded:Connect(checkFriendship)
    Players.PlayerRemoving:Connect(function(player)
        friendships[player.UserId] = nil
        refreshCount()
    end)

    local friendBonus = scope:Computed(function(use)
        return use(friendCount) * 10
    end)

    return friendBonus, premiumBonus
end

-- ── Board row (used inside the SurfaceGui) ─────────────────────────────────

local function BoardRow(scope, icon: string, bonusValue: Fusion.Value<number>, description: string)
    return scope:New "Frame" {
        Size                   = UDim2.fromScale(1, 0.5),
        BackgroundTransparency = 1,

        [Fusion.Children] = {
            scope:New "UIListLayout" {
                FillDirection       = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment   = Enum.VerticalAlignment.Center,
                Padding             = UDim.new(0.02, 0),
                SortOrder           = Enum.SortOrder.LayoutOrder,
            },

            -- Icon + Percentage row
            scope:New "Frame" {
                LayoutOrder            = 1,
                Size                   = UDim2.fromScale(0.9, 0.55),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment   = Enum.VerticalAlignment.Center,
                        Padding             = UDim.new(0.03, 0),
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                    },

                    scope:New "ImageLabel" {
                        LayoutOrder            = 1,
                        Size                   = UDim2.fromScale(0.25, 1),
                        BackgroundTransparency = 1,
                        Image                  = icon,
                        ScaleType              = Enum.ScaleType.Fit,
                        [Fusion.Children] = {
                            scope:New "UIAspectRatioConstraint" { AspectRatio = 1 },
                        },
                    },

                    scope:New "TextLabel" {
                        LayoutOrder            = 2,
                        Size                   = UDim2.fromScale(0.65, 1),
                        BackgroundTransparency = 1,
                        Text                   = scope:Computed(function(use)
                            return "+" .. use(bonusValue) .. "%"
                        end),
                        TextScaled             = true,
                        FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                        TextColor3             = COLOR_TEXT,
                        TextXAlignment         = Enum.TextXAlignment.Left,
                        [Fusion.Children] = {
                            scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                        },
                    },
                },
            },

            -- Description
            scope:New "TextLabel" {
                LayoutOrder            = 2,
                Size                   = UDim2.fromScale(0.9, 0.3),
                BackgroundTransparency = 1,
                Text                   = description,
                TextScaled             = true,
                TextWrapped            = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                TextColor3             = COLOR_DESC,
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) },
                },
            },
        },
    }
end

-- ── Social HUD button (ScreenGui) ──────────────────────────────────────────

local function SocialButton(scope, icon: string, bonusValue: Fusion.Value<number>, layoutOrder: number, onActivated: () -> ())
    return scope:New "ImageButton" {
        Name            = "SocialButton",
        Image = icon,
        Size            = UDim2.fromScale(0.9, 0.9),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = layoutOrder,

        [Fusion.OnEvent "Activated"] = onActivated,

        [Fusion.Children] = {
            scope:New "UICorner" { CornerRadius = UDim.new(0.15, 0) },

            scope:New "UIAspectRatioConstraint" {
                AspectRatio = 1,
            },

            -- Percentage badge at bottom
            scope:New "TextLabel" {
                AnchorPoint            = Vector2.new(0.5, 1),
                Position               = UDim2.fromScale(0.5, 0.98),
                Size                   = UDim2.fromScale(1, 0.32),
                BackgroundTransparency = 1,
                Text                   = scope:Computed(function(use)
                    return "+" .. use(bonusValue) .. "%"
                end),
                TextScaled             = true,
                FontFace               = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextColor3             = COLOR_TEXT,
                [Fusion.Children] = {
                    scope:New "UIStroke" { Thickness = 2, Color = Color3.fromRGB(0, 0, 0) },
                },
            },
        },
    }
end

-- ── Mount ──────────────────────────────────────────────────────────────────

return function(parent)
    local scope = scoped(Fusion)

    local friendBonus, premiumBonus = buildSocialData(scope)

    -- ── SurfaceGui board ──────────────────────────────────────────────────
    local boardPart = workspace:WaitForChild("SocialBoardModel"):WaitForChild("SocialBoard")

    scope:New "SurfaceGui" {
        Name          = "SocialBoard",
        Adornee       = boardPart,
        Face          = Enum.NormalId.Front,
        Parent        = parent,
        SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 50,

        [Fusion.Children] = {
            scope:New "Frame" {
                Size                   = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

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
                        VerticalAlignment   = Enum.VerticalAlignment.Center,
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                    },

                    -- Friends row
                    BoardRow(scope, ICON_FRIENDS, friendBonus, "Friends give +10% Faith each"),

                    -- Premium row
                    BoardRow(scope, ICON_PREMIUM, premiumBonus, "Premium gives +10% Faith"),
                },
            },
        },
    }

    -- ── HUD social buttons (ScreenGui) ────────────────────────────────────
    scope:New "ScreenGui" {
        Name         = "SocialButtons",
        Parent       = parent,
        ResetOnSpawn = false,
        DisplayOrder = 5,
        IgnoreGuiInset = true,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name                   = "SocialButtonHolder",
                AnchorPoint            = Vector2.new(0, 0),
                Position               = UDim2.fromScale(0.01, 0.89),
                Size                   = UDim2.fromScale(0.15, 0.1),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment   = Enum.VerticalAlignment.Center,
                        Padding             = UDim.new(0, 8),
                        SortOrder           = Enum.SortOrder.LayoutOrder,
                    },

                    -- Premium button
                    SocialButton(scope, ICON_PREMIUM, premiumBonus, 1, function()
                        pcall(function()
                            MarketplaceService:PromptPremiumPurchase(LocalPlayer)
                        end)
                    end),

                    -- Invite friends button
                    SocialButton(scope, ICON_FRIENDS, friendBonus, 2, function()
                        pcall(function()
                            SocialService:PromptGameInvite(LocalPlayer)
                        end)
                    end),
                },
            },
        },
    }

    return function()
        scope:doCleanup()
    end
end
