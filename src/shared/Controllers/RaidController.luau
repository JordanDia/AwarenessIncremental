local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)

local scope = Fusion.scoped(Fusion)

local RaidController = Knit.CreateController {
	Name = "RaidController",
}

local Player = Players.LocalPlayer

RaidController.RaidService = nil
RaidController.CurrentTarget = nil
RaidController.QueuedMove = nil
RaidController.Cooldowns = {} -- { [moveIndex] = endTime }
RaidController.LastAttackTime = 0

-- Fusion state for UI (initialized immediately with scope)
RaidController.RaidState = scope:Value("Idle")
RaidController.TimeRemaining = scope:Value(0)
RaidController.SpiritHealth = scope:Value(RaidConfig.SpiritHealth)
RaidController.QueuedMoveIndex = scope:Value(nil)
RaidController.MoveCooldowns = scope:Value({0, 0, 0, 0})
RaidController.Leaderboard = scope:Value({})
RaidController.ShowLeaderboard = scope:Value(false)
RaidController.ShowWarning = scope:Value(false)
RaidController.WarningTime = scope:Value(0)

function RaidController:KnitInit()
	-- Values already initialized above
end

function RaidController:KnitStart()
	self.RaidService = Knit.GetService("RaidService")

	self.RaidService.RaidStateChanged:Connect(function(state, data)
		self.RaidState:set(state)
		if state == "Active" then
			self.ShowWarning:set(false)
		end
	end)

	self.RaidService.SpiritHealthChanged:Connect(function(health)
		self.SpiritHealth:set(health)
	end)

	self.RaidService.RaidWarning:Connect(function(timeUntil)
		self.ShowWarning:set(true)
		self.WarningTime:set(timeUntil)
	end)

	self.RaidService.RaidEnded:Connect(function(leaderboard, success)
		self.Leaderboard:set(leaderboard)
		self.ShowLeaderboard:set(true)
		task.delay(10, function()
			self.ShowLeaderboard:set(false)
		end)
	end)

	self:SetupKeybinds()
	self:StartAttackLoop()
	self:StartTimerLoop()

	-- Sync initial state
	task.spawn(function()
		local state, data = self.RaidService:GetRaidState()
		self.RaidState:set(state)
		if data.spiritHealth then
			self.SpiritHealth:set(data.spiritHealth)
		end
	end)
end

function RaidController:SetupKeybinds()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		for i, move in RaidConfig.Moves do
			if input.KeyCode == move.Keybind then
				self:QueueMove(i)
				break
			end
		end
	end)
end

function RaidController:QueueMove(index: number)
	local move = RaidConfig.Moves[index]
	if not move or not move.Unlocked then return end

	local now = os.clock()
	if self.Cooldowns[index] and now < self.Cooldowns[index] then
		return -- still on cooldown
	end

	self.QueuedMove = index
	self.QueuedMoveIndex:set(index)
end

function RaidController:StartAttackLoop()
	task.spawn(function()
		while true do
			task.wait(1)

			if Fusion.peek(self.RaidState) ~= "Active" then continue end

			local character = Player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then continue end

			local target = self:FindNearestDemon(root.Position)
			if not target then continue end

			local now = os.clock()
			local moveIndex = self.QueuedMove or 1
			local move = RaidConfig.Moves[moveIndex]

			if self.Cooldowns[moveIndex] and now < self.Cooldowns[moveIndex] then
				continue
			end

			self.RaidService:DamageDemon(target.Name, move.Damage)
			self.Cooldowns[moveIndex] = now + move.Cooldown

			if self.QueuedMove then
				self.QueuedMove = nil
				self.QueuedMoveIndex:set(nil)
			end

			self:UpdateCooldownUI()
		end
	end)
end

function RaidController:FindNearestDemon(position: Vector3)
	local folder = workspace:FindFirstChild("RaidDemons")
	if not folder then return nil end

	local nearest = nil
	local nearestDist = RaidConfig.AttackRange

	for _, demon in folder:GetChildren() do
		local demonPos
		if demon:IsA("Model") and demon.PrimaryPart then
			demonPos = demon.PrimaryPart.Position
		elseif demon:IsA("BasePart") then
			demonPos = demon.Position
		end

		if demonPos then
			local dist = (position - demonPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = demon
			end
		end
	end

	return nearest
end

function RaidController:StartTimerLoop()
	task.spawn(function()
		while true do
			local state = Fusion.peek(self.RaidState)
			if state == "Warning" then
				local t = Fusion.peek(self.WarningTime)
				if t > 0 then
					self.WarningTime:set(t - 1)
				end
			end
			self:UpdateCooldownUI()
			task.wait(1)
		end
	end)
end

function RaidController:UpdateCooldownUI()
	local now = os.clock()
	local cooldowns = {}
	for i, move in RaidConfig.Moves do
		local endTime = self.Cooldowns[i] or 0
		cooldowns[i] = math.max(0, endTime - now)
	end
	self.MoveCooldowns:set(cooldowns)
end

return RaidController
