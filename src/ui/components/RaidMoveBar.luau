local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)

local RaidMoveButton = require(script.Parent.RaidMoveButton)

-- Props:
--   Visible: Value<boolean>
--   QueuedMoveIndex: Value<number?>
--   MoveCooldowns: Value<table>
--   OnMoveActivated: function(index)

return function(scope: Fusion.Scope, props)
	local moveButtons = {}

	for i, move in RaidConfig.Moves do
		local isQueued = scope:Computed(function(use)
			return use(props.QueuedMoveIndex) == i
		end)

		local cooldown = scope:Computed(function(use)
			local cds = use(props.MoveCooldowns) or {}
			return cds[i] or 0
		end)

		table.insert(moveButtons, scope:New "Frame" {
			Size = UDim2.fromOffset(70, 70),
			BackgroundTransparency = 1,
			LayoutOrder = i,

			[Fusion.Children] = {
				RaidMoveButton(scope, {
					Index = i,
					Name = move.Name,
					Keybind = tostring(i),
					MaxCooldown = move.Cooldown,
					Cooldown = cooldown,
					IsQueued = isQueued,
					OnActivated = function()
						if props.OnMoveActivated then
							props.OnMoveActivated(i)
						end
					end,
				}),
			},
		})
	end

	return scope:New "Frame" {
		Name = "RaidMoveBar",
		Size = UDim2.new(0, 320, 0, 80),
		Position = UDim2.new(0.5, 0, 1, -20),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		Visible = props.Visible,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0, 10),
			},
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			},
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			},
			table.unpack(moveButtons),
		},
	}
end
