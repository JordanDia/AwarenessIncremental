local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)

local RaidMoveButton = require(script.Parent.RaidMoveButton)

-- Props:
--   Visible: Value<boolean>
--   QueuedMoveIndex: Value<number?>
--   MoveCooldowns: Value<table>
--   UnlockedMoves: Value<table>
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

		local isLocked = scope:Computed(function(use)
			local unlocked = use(props.UnlockedMoves) or {}
			return not unlocked[i]
		end)

		table.insert(moveButtons, scope:New "Frame" {
			Size = UDim2.fromScale(0.2, 0.85),
			BackgroundTransparency = 1,
			LayoutOrder = i,

			[Fusion.Children] = {
				scope:New "UIAspectRatioConstraint" {
					AspectRatio = 1,
				},
				RaidMoveButton(scope, {
					Index = i,
					Name = move.Name,
					Keybind = tostring(i),
					MaxCooldown = move.Cooldown,
					Cooldown = cooldown,
					IsQueued = isQueued,
					IsLocked = isLocked,
					RequiredLevel = move.RequiredAwakeningLevel or 0,
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
		Size = UDim2.fromScale(0.25, 0.1),
		Position = UDim2.fromScale(0.5, 0.82),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		Visible = props.Visible,

		[Fusion.Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.1, 0),
			},
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
			},
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0.02, 0),
				PaddingRight = UDim.new(0.02, 0),
			},
			table.unpack(moveButtons),
		},
	}
end
