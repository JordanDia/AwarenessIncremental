local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Visible: Value<boolean>
--   RaidState: Value<string>
--   SpiritHealth: Value<number>
--   MaxSpiritHealth: Value<number>
--   CurrentWave: Value<number>
--   TotalWaves: Value<number>

return function(scope: Fusion.Scope, props)
	local healthPct = scope:Computed(function(use)
		local max = use(props.MaxSpiritHealth)
		if max <= 0 then return 0 end
		return math.clamp(use(props.SpiritHealth) / max, 0, 1)
	end)

	local healthColor = scope:Computed(function(use)
		local pct = use(healthPct)
		if pct < 0.15 then
			return Color3.fromRGB(255, 80, 80)
		elseif pct < 0.35 then
			return Color3.fromRGB(255, 200, 80)
		else
			return Color3.fromRGB(100, 200, 100)
		end
	end)

	local stateText = scope:Computed(function(use)
		local state = use(props.RaidState)
		if state == "Active" then
			return "Wave " .. use(props.CurrentWave) .. "/" .. use(props.TotalWaves)
		elseif state == "Warning" then
			return "RAID STARTING SOON"
		else
			return ""
		end
	end)

	local stateColor = scope:Computed(function(use)
		local state = use(props.RaidState)
		if state == "Active" then
			return Color3.fromRGB(255, 100, 100)
		elseif state == "Warning" then
			return Color3.fromRGB(255, 200, 100)
		else
			return Color3.fromRGB(255, 255, 255)
		end
	end)

	return scope:New "Frame" {
		Name = "RaidTimerFrame",
		Size = UDim2.new(0, 250, 0, 80),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		Visible = props.Visible,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 10),
			},

			-- State text
			scope:New "TextLabel" {
				Name = "StateText",
				Size = UDim2.new(1, 0, 0, 25),
				Position = UDim2.fromOffset(0, 5),
				BackgroundTransparency = 1,
				Text = stateText,
				TextColor3 = stateColor,
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			},

			-- Spirit health bar
			scope:New "Frame" {
				Name = "HealthBarBg",
				Size = UDim2.new(0.9, 0, 0, 20),
				Position = UDim2.new(0.5, 0, 0, 35),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),

				[Fusion.Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.3, 0),
					},
					scope:New "Frame" {
						Name = "HealthFill",
						Size = scope:Spring(scope:Computed(function(use)
							return UDim2.new(use(healthPct), 0, 1, 0)
						end), 10, 0.8),
						BackgroundColor3 = scope:Spring(healthColor, 8, 1),

						[Fusion.Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.3, 0),
							},
						},
					},
				},
			},

			-- Spirit label
			scope:New "TextLabel" {
				Name = "SpiritLabel",
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.fromOffset(0, 58),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return "Spirit HP: " .. math.floor(use(props.SpiritHealth)) .. "/" .. math.floor(use(props.MaxSpiritHealth))
				end),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular),
			},
		},
	}
end
