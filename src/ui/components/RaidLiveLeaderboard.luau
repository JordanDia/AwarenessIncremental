local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(scope: Fusion.Scope, props)
	local entries = scope:Computed(function(use)
		local leaderboard = use(props.Leaderboard)
		local children = {}

		for i, entry in leaderboard do
			if i > 5 then break end

			table.insert(children, scope:New "Frame" {
				Name = "Entry_" .. i,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = i,

				[Fusion.Children] = {
					scope:New "TextLabel" {
						Name = "Rank",
						Size = UDim2.fromScale(0.15, 1),
						Position = UDim2.fromScale(0, 0),
						BackgroundTransparency = 1,
						Text = "#" .. i,
						TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 180),
						TextScaled = true,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
						TextXAlignment = Enum.TextXAlignment.Left,
					},
					scope:New "TextLabel" {
						Name = "Name",
						Size = UDim2.fromScale(0.5, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
						Text = entry.name or "Unknown",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextTruncate = Enum.TextTruncate.AtEnd,
					},
					scope:New "TextLabel" {
						Name = "Damage",
						Size = UDim2.fromScale(0.35, 1),
						Position = UDim2.fromScale(0.65, 0),
						BackgroundTransparency = 1,
						Text = tostring(math.floor(entry.damage)),
						TextColor3 = Color3.fromRGB(255, 100, 100),
						TextScaled = true,
						FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
						TextXAlignment = Enum.TextXAlignment.Right,
					},
				},
			})
		end

		return children
	end)

	return scope:New "Frame" {
		Name = "RaidLiveLeaderboard",
		Size = UDim2.new(0, 160, 0, 160),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.4,
		Visible = scope:Computed(function(use)
			return use(props.Visible)
		end),

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 8),
			},
			scope:New "UIPadding" {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			},
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "Damage",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			},
			scope:New "Frame" {
				Name = "Entries",
				Size = UDim2.new(1, 0, 1, -24),
				Position = UDim2.new(0, 0, 0, 22),
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:New "UIListLayout" {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 2),
					},
					entries,
				},
			},
		},
	}
end
