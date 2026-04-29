local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Visible: Value<boolean>
--   Leaderboard: Value<table> -- { { player, damage }, ... }

return function(scope: Fusion.Scope, props)
	local entries = scope:Computed(function(use)
		local lb = use(props.Leaderboard)
		local children = {}

		for i, entry in lb do
			if i > 10 then break end
			table.insert(children, scope:New "Frame" {
				Name = "Entry_" .. i,
				Size = UDim2.new(1, 0, 0, 25),
				BackgroundTransparency = 1,
				LayoutOrder = i,

				[Fusion.Children] = {
					scope:New "TextLabel" {
						Size = UDim2.new(0.1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "#" .. i,
						TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or
							i == 2 and Color3.fromRGB(192, 192, 192) or
							i == 3 and Color3.fromRGB(205, 127, 50) or
							Color3.fromRGB(200, 200, 200),
						TextScaled = true,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
					},
					scope:New "TextLabel" {
						Size = UDim2.new(0.5, 0, 1, 0),
						Position = UDim2.fromScale(0.12, 0),
						BackgroundTransparency = 1,
						Text = entry.player and entry.player.Name or "Unknown",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular),
					},
					scope:New "TextLabel" {
						Size = UDim2.new(0.35, 0, 1, 0),
						Position = UDim2.fromScale(0.65, 0),
						BackgroundTransparency = 1,
						Text = tostring(math.floor(entry.damage)) .. " dmg",
						TextColor3 = Color3.fromRGB(255, 150, 150),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Right,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
					},
				},
			})
		end

		return children
	end)

	return scope:New "Frame" {
		Name = "RaidLeaderboard",
		Size = UDim2.new(0, 300, 0, 350),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BackgroundTransparency = 0.1,
		Visible = props.Visible,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 12),
			},
			scope:New "UIStroke" {
				Color = Color3.fromRGB(100, 100, 120),
				Thickness = 2,
			},

			-- Title
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				Text = "RAID COMPLETE",
				TextColor3 = Color3.fromRGB(255, 215, 0),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			},

			-- Entries container
			scope:New "ScrollingFrame" {
				Name = "EntriesContainer",
				Size = UDim2.new(0.95, 0, 1, -50),
				Position = UDim2.new(0.5, 0, 0, 45),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 4,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				[Fusion.Children] = {
					scope:New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
					},
					entries,
				},
			},
		},
	}
end
