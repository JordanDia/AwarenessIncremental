local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Visible: Value<boolean>
--   TimeRemaining: Value<number>

return function(scope: Fusion.Scope, props)
	local pulse = scope:Value(1)

	task.spawn(function()
		while true do
			pulse:set(1.1)
			task.wait(0.5)
			pulse:set(1)
			task.wait(0.5)
		end
	end)

	return scope:New "Frame" {
		Name = "RaidWarningFrame",
		Size = UDim2.new(0, 350, 0, 80),
		Position = UDim2.fromScale(0.5, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(50, 20, 20),
		BackgroundTransparency = 0.2,
		Visible = props.Visible,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 12),
			},
			scope:New "UIStroke" {
				Color = Color3.fromRGB(200, 50, 50),
				Thickness = 3,
			},
			scope:New "UIScale" {
				Scale = scope:Spring(pulse, 8, 0.5),
			},

			scope:New "TextLabel" {
				Name = "WarningText",
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.fromScale(0, 0.1),
				BackgroundTransparency = 1,
				Text = "RAID INCOMING!",
				TextColor3 = Color3.fromRGB(255, 100, 100),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.ExtraBold),
			},

			scope:New "TextLabel" {
				Name = "TimeText",
				Size = UDim2.new(1, 0, 0.35, 0),
				Position = UDim2.fromScale(0, 0.55),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					local t = math.ceil(use(props.TimeRemaining))
					if t < 1 then t = 1 end
					return "Starting in " .. t .. "s"
				end),
				TextColor3 = Color3.fromRGB(255, 200, 200),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
			},
		},
	}
end
