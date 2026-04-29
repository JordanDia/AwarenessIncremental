local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Index: number
--   Name: string
--   Keybind: string (e.g. "1")
--   Cooldown: Value<number> (remaining seconds)
--   IsQueued: Value<boolean>
--   OnActivated: function

return function(scope: Fusion.Scope, props)
	local isHovered = scope:Value(false)

	local cooldownPct = scope:Computed(function(use)
		local cd = use(props.Cooldown) or 0
		local maxCd = props.MaxCooldown or 2
		return math.clamp(cd / maxCd, 0, 1)
	end)

	local bgColor = scope:Computed(function(use)
		local queued = props.IsQueued and use(props.IsQueued)
		if queued then
			return Color3.fromRGB(100, 180, 100)
		elseif use(isHovered) then
			return Color3.fromRGB(80, 80, 80)
		else
			return Color3.fromRGB(50, 50, 50)
		end
	end)

	return scope:New "TextButton" {
		Name = "RaidMove_" .. props.Index,
		Size = UDim2.fromOffset(70, 70),
		BackgroundColor3 = scope:Spring(bgColor, 15, 0.8),
		BorderSizePixel = 0,
		LayoutOrder = props.Index,
		AutoButtonColor = false,
		Text = "",

		[Fusion.OnEvent "MouseEnter"] = function()
			isHovered:set(true)
		end,
		[Fusion.OnEvent "MouseLeave"] = function()
			isHovered:set(false)
		end,
		[Fusion.OnEvent "Activated"] = function()
			if props.OnActivated then
				props.OnActivated()
			end
		end,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.15, 0),
			},
			scope:New "UIStroke" {
				Color = scope:Computed(function(use)
					return use(props.IsQueued) and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(30, 30, 30)
				end),
				Thickness = 2,
			},

			-- Move name
			scope:New "TextLabel" {
				Name = "MoveName",
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.fromScale(0, 0.1),
				BackgroundTransparency = 1,
				Text = props.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			},

			-- Keybind
			scope:New "TextLabel" {
				Name = "Keybind",
				Size = UDim2.new(1, 0, 0.3, 0),
				Position = UDim2.fromScale(0, 0.6),
				BackgroundTransparency = 1,
				Text = "[" .. props.Keybind .. "]",
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular),
			},

			-- Cooldown overlay
			scope:New "Frame" {
				Name = "CooldownOverlay",
				Size = scope:Computed(function(use)
					return UDim2.new(1, 0, use(cooldownPct), 0)
				end),
				Position = UDim2.fromScale(0, 0),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.5,
				ZIndex = 2,

				[Fusion.Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.15, 0),
					},
				},
			},
		},
	}
end
