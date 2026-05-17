local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)
local FloatingTextComponent = require(ReplicatedStorage.UI.components.FloatingText)

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
RaidController.SpiritHealth = scope:Value(0)
RaidController.MaxSpiritHealth = scope:Value(1)
RaidController.CurrentWave = scope:Value(0)
RaidController.TotalWaves = scope:Value(3)
RaidController.QueuedMoveIndex = scope:Value(nil)
RaidController.MoveCooldowns = scope:Value({0, 0, 0, 0})
RaidController.Leaderboard = scope:Value({})
RaidController.ShowLeaderboard = scope:Value(false)
RaidController.RaidSuccess = scope:Value(false)
RaidController.LiveLeaderboard = scope:Value({})
RaidController.ShowWarning = scope:Value(false)
RaidController.WarningTime = scope:Value(0)
RaidController.NextRaidTime = 0
RaidController.RaidIcon = nil
RaidController.AwakeningLevel = scope:Value(0)

RaidController.UnlockedMoves = scope:Computed(function(use)
	local level = use(RaidController.AwakeningLevel)
	local unlocked = {}
	for i, move in RaidConfig.Moves do
		unlocked[i] = level >= (move.RequiredAwakeningLevel or 0)
	end
	return unlocked
end)

function RaidController:KnitInit()
	-- Values already initialized above
end

function RaidController:KnitStart()
	self.RaidService = Knit.GetService("RaidService")

	self.RaidService.RaidStateChanged:Connect(function(state, data)
		self.RaidState:set(state)
		if state == "Active" then
			self.ShowWarning:set(false)
			self.LiveLeaderboard:set({})
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
		self.RaidSuccess:set(success)
		self.ShowLeaderboard:set(true)
		task.delay(10, function()
			self.ShowLeaderboard:set(false)
		end)
		-- Refresh next raid time
		task.spawn(function()
			local _, data = self.RaidService:GetRaidState()
			if data.nextRaidTime then
				self.NextRaidTime = data.nextRaidTime
			end
		end)
	end)

	self.RaidService.DamageEffect:Connect(function(demonId, damage)
		self:ShowDamageText(demonId, damage)
	end)

	self.RaidService.SpiritDamageEffect:Connect(function(damage)
		self:ShowSpiritDamageText(damage)
	end)

	self.RaidService.WaveChanged:Connect(function(wave, totalWaves, spiritHealth)
		self.SpiritHealth:set(spiritHealth)
		if wave == 1 then
			self.MaxSpiritHealth:set(spiritHealth)
		end
		self.CurrentWave:set(wave)
		self.TotalWaves:set(totalWaves)
	end)

	self.RaidService.MoveEffect:Connect(function(moveIndex)
		self:PlayMoveSound(moveIndex)
	end)

	self.RaidService.LeaderboardUpdated:Connect(function(leaderboard)
		self.LiveLeaderboard:set(leaderboard)
	end)

	self:SetupKeybinds()
	self:StartAttackLoop()
	self:StartTimerLoop()
	self:SetupRaidIcon()

	-- Sync initial state
	task.spawn(function()
		local state, data = self.RaidService:GetRaidState()
		self.RaidState:set(state)
		if data.spiritHealth then
			self.SpiritHealth:set(data.spiritHealth)
		end
		if data.maxSpiritHealth then
			self.MaxSpiritHealth:set(data.maxSpiritHealth)
		end
		if data.nextRaidTime then
			self.NextRaidTime = data.nextRaidTime
		end
	end)

	-- Get awakening level
	local DataService = Knit.GetService("DataService")
	DataService.DataLoaded:Connect(function(data)
		self.AwakeningLevel:set(data.AwakeningLevel or 0)
	end)
end

function RaidController:SetupRaidIcon()
	local icon = Icon.new()
	icon:setName("RaidTimer")
	icon:setLabel("Raid: --:--")
	icon:align("Right")
	icon:setOrder(-100)
	icon:lock()
	icon:modifyTheme({"IconButton", "BackgroundTransparency", 0.5})
	icon:modifyTheme({"IconButton", "BackgroundColor3", Color3.fromRGB(0, 0, 0)})

	self.RaidIcon = icon

	task.spawn(function()
		while true do
			local state = Fusion.peek(self.RaidState)
			if state == "Active" then
				icon:setLabel("Raid Active")
				icon:modifyTheme({"IconButton", "BackgroundColor3", Color3.fromRGB(180, 50, 50)})
			else
				local timeLeft = math.max(0, self.NextRaidTime - os.time())
				local minutes = math.floor(timeLeft / 60)
				local seconds = timeLeft % 60
				icon:setLabel(string.format("Raid: %02d:%02d", minutes, seconds))
				icon:modifyTheme({"IconButton", "BackgroundColor3", Color3.fromRGB(0, 0, 0)})
			end
			task.wait(1)
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
	if not move then return end

	-- Check if move is unlocked based on awakening level
	local unlocked = Fusion.peek(self.UnlockedMoves)
	if not unlocked[index] then return end

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

			self.RaidService:DamageDemon(target.Name, move.Damage, moveIndex)
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
		local warningAccum = 0
		while true do
			task.wait(0.1)
			warningAccum += 0.1
			if warningAccum >= 1 then
				warningAccum = 0
				local state = Fusion.peek(self.RaidState)
				if state == "Warning" then
					local t = Fusion.peek(self.WarningTime)
					if t > 0 then
						self.WarningTime:set(t - 1)
					end
				end
			end
			self:UpdateCooldownUI()
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

function RaidController:ShowDamageText(demonId: string, damage: number)
	local folder = workspace:FindFirstChild("RaidDemons")
	if not folder then return end

	local demon = folder:FindFirstChild(demonId)
	if not demon then return end

	local rootPart
	if demon:IsA("Model") and demon.PrimaryPart then
		rootPart = demon.PrimaryPart
	elseif demon:IsA("BasePart") then
		rootPart = demon
	end
	if not rootPart then return end

	local floatScope = Fusion.scoped(Fusion, {
		FloatingTextComponent = FloatingTextComponent
	})

	local gui = floatScope:FloatingTextComponent({
		Amount = damage,
		Adornee = rootPart,
		TextColor3 = Color3.fromRGB(255, 0, 0),
		Prefix = "-",
	})

	local duration = 1
	gui.Parent = Player.PlayerGui

	local randomX = math.random(-200, 200) / 100
	local randomY = math.random(100, 200) / 100
	gui.StudsOffset = Vector3.new(randomX, randomY, 0)

	local textLabel = gui:FindFirstChildWhichIsA("TextLabel")
	if textLabel then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local positionTween = TweenService:Create(gui, tweenInfo, {
			StudsOffset = Vector3.new(randomX, randomY + 2.5, 0)
		})

		local transparencyTween = TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})

		positionTween:Play()
		transparencyTween:Play()
	end

	task.delay(duration + 1, function()
		floatScope:doCleanup()
	end)
end

function RaidController:ShowSpiritDamageText(damage: number)
	local spirit = workspace:FindFirstChild("RaidSpirit")
	if not spirit then return end

	local rootPart
	if spirit:IsA("Model") and spirit.PrimaryPart then
		rootPart = spirit.PrimaryPart
	elseif spirit:IsA("BasePart") then
		rootPart = spirit
	end
	if not rootPart then return end

	local floatScope = Fusion.scoped(Fusion, {
		FloatingTextComponent = FloatingTextComponent
	})

	local gui = floatScope:FloatingTextComponent({
		Amount = damage,
		Adornee = rootPart,
		TextColor3 = Color3.fromRGB(255, 100, 100),
		Prefix = "-",
	})

	local duration = 1
	gui.Parent = Player.PlayerGui

	local randomX = math.random(-200, 200) / 100
	local randomY = math.random(100, 200) / 100
	gui.StudsOffset = Vector3.new(randomX, randomY, 0)

	local textLabel = gui:FindFirstChildWhichIsA("TextLabel")
	if textLabel then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local positionTween = TweenService:Create(gui, tweenInfo, {
			StudsOffset = Vector3.new(randomX, randomY + 2.5, 0)
		})

		local transparencyTween = TweenService:Create(textLabel, tweenInfo, {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})

		positionTween:Play()
		transparencyTween:Play()
	end

	task.delay(duration + 1, function()
		floatScope:doCleanup()
	end)
end

function RaidController:PlayMoveSound(moveIndex: number)
	local soundName
	if moveIndex == 2 then
		soundName = "CrystalBlast"
	elseif moveIndex == 3 then
		soundName = "AwarenessBlast"
	elseif moveIndex == 4 then
		soundName = "SummonAlly"
	end
	if not soundName then return end

	local sound = SoundService:FindFirstChild(soundName)
	if sound then
		sound:Play()
	end
end

return RaidController
