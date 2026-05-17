local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- Props:
--   Index: number
--   Name: string
--   Keybind: string (e.g. "1")
--   Cooldown: Value<number> (remaining seconds)
--   IsQueued: Value<boolean>
--   IsLocked: Value<boolean>
--   RequiredLevel: number
--   OnActivated: function

return function(scope: Fusion.Scope, props)
	local isHovered = scope:Value(false)
	local lastCooldown = 0
	local activeTween = nil

	-- Create overlay frame first so we can reference it
	local overlay = scope:New "Frame" {
		Name = "CooldownOverlay",
		Size = UDim2.fromScale(1, 0),
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
	}

	local bgColor = scope:Computed(function(use)
		local locked = props.IsLocked and use(props.IsLocked)
		if locked then
			return Color3.fromRGB(30, 30, 30)
		end
		local queued = props.IsQueued and use(props.IsQueued)
		if queued then
			return Color3.fromRGB(100, 180, 100)
		elseif use(isHovered) then
			return Color3.fromRGB(80, 80, 80)
		else
			return Color3.fromRGB(50, 50, 50)
		end
	end)

	local button = scope:New "TextButton" {
		Name = "RaidMove_" .. props.Index,
		Size = UDim2.fromScale(1, 1),
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

			-- Keybind (top left)
			scope:New "TextLabel" {
				Name = "Keybind",
				Size = UDim2.fromScale(0.25, 0.25),
				Position = UDim2.fromScale(0.05, 0.05),
				BackgroundTransparency = 1,
				Text = props.Keybind,
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Regular),
			},

			-- Move name (centered)
			scope:New "TextLabel" {
				Name = "MoveName",
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					local locked = props.IsLocked and use(props.IsLocked)
					if locked then
						return "AWK Lvl. " .. (props.RequiredLevel or 0)
					end
					return props.Name
				end),
				TextColor3 = scope:Computed(function(use)
					local locked = props.IsLocked and use(props.IsLocked)
					if locked then
						return Color3.fromRGB(100, 100, 100)
					end
					return Color3.fromRGB(255, 255, 255)
				end),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			},

			-- Cooldown timer (bottom)
			scope:New "TextLabel" {
				Name = "CooldownTimer",
				Size = UDim2.new(1, 0, 0.25, 0),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					local cd = use(props.Cooldown) or 0
					if cd > 0 then
						return string.format("%.1fs", cd)
					elseif props.Index == 1 then
						return "AUTO"
					end
					return ""
				end),
				TextColor3 = scope:Computed(function(use)
					local cd = use(props.Cooldown) or 0
					if cd <= 0 and props.Index == 1 then
						return Color3.fromRGB(100, 255, 100)
					end
					return Color3.fromRGB(255, 200, 100)
				end),
				TextScaled = true,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				ZIndex = 3,
			},

			-- Cooldown overlay
			overlay,
		},
	}

	-- Watch cooldown changes and tween overlay
	scope:Observer(props.Cooldown):onChange(function()
		local cd = Fusion.peek(props.Cooldown) or 0

		if cd > lastCooldown + 0.05 then
			-- Cooldown just started, set to full and tween to 0
			if activeTween then
				activeTween:Cancel()
			end
			overlay.Size = UDim2.fromScale(1, 1)
			local tweenInfo = TweenInfo.new(cd, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			activeTween = TweenService:Create(overlay, tweenInfo, {
				Size = UDim2.fromScale(1, 0)
			})
			activeTween:Play()
		elseif cd <= 0 then
			-- Cooldown ended
			if activeTween then
				activeTween:Cancel()
			end
			overlay.Size = UDim2.fromScale(1, 0)
		end

		lastCooldown = cd
	end)

	return button
end
