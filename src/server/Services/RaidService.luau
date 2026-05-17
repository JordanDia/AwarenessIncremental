local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)

local SPIRIT_COLLISION_GROUP = "Spirit"

local RaidService = Knit.CreateService {
	Name = "RaidService",
	Client = {
		RaidStateChanged = Knit.CreateSignal(), -- (state: string, data: table)
		DemonDamaged = Knit.CreateSignal(), -- (demonId: string, health: number)
		DemonDied = Knit.CreateSignal(), -- (demonId: string)
		SpiritHealthChanged = Knit.CreateSignal(), -- (health: number)
		RaidWarning = Knit.CreateSignal(), -- fires 30s before raid
		RaidEnded = Knit.CreateSignal(), -- (leaderboard: table, success: boolean)
		DamageEffect = Knit.CreateSignal(), -- (demonId: string, damage: number)
		SpiritDamageEffect = Knit.CreateSignal(), -- (damage: number)
		WaveChanged = Knit.CreateSignal(), -- (wave: number, totalWaves: number, spiritHealth: number)
		MoveEffect = Knit.CreateSignal(), -- (moveIndex: number)
		LeaderboardUpdated = Knit.CreateSignal(), -- (leaderboard: table)
	},
}

RaidService.State = "Idle" -- Idle, Warning, Active
RaidService.Demons = {} -- { [id] = { model, health } }
RaidService.Spirit = nil -- Spirit model
RaidService.SpiritHealth = 0
RaidService.PlayerDamage = {} -- { [player] = totalDamage }
RaidService.RaidStartTime = 0
RaidService.NextRaidTime = 0
RaidService.CurrentWave = 0
RaidService.WaveConfig = nil
RaidService.SpiritSpawnPos = nil
RaidService.Boss = nil -- { model, health }
RaidService.BossActive = false

function RaidService:KnitStart()
	self.NextRaidTime = os.time() + 15 -- First raid starts quickly, then uses RaidInterval after
	task.spawn(function()
		self:RaidLoop()
	end)
end

function RaidService:RaidLoop()
	while true do
		local now = os.time()
		local timeUntilRaid = self.NextRaidTime - now

		if timeUntilRaid <= RaidConfig.WarningTime and self.State == "Idle" then
			self.State = "Warning"
			self.Client.RaidWarning:FireAll(RaidConfig.WarningTime)
			self.Client.RaidStateChanged:FireAll("Warning", { timeUntilStart = timeUntilRaid })
		end

		if timeUntilRaid <= 0 and self.State ~= "Active" then
			self:StartRaid()
		end

		if self.State == "Active" then
			self:UpdateRaid()
		end

		task.wait(1)
	end
end

function RaidService:StartRaid()
	self.State = "Active"
	self.PlayerDamage = {}
	self.RaidStartTime = os.time()
	self.CurrentWave = 0

	-- Spawn spirit once at raid start with wave 1 health
	self.WaveConfig = RaidConfig.Waves[1]
	self.SpiritHealth = RaidConfig.SpiritHealth
	self:SpawnSpirit()

	task.spawn(function()
		self:SpiritWanderLoop()
	end)

	task.spawn(function()
		self:SpiritVoicelineLoop()
	end)

	self:StartNextWave()
end

function RaidService:StartNextWave()
	self.CurrentWave += 1

	if self.CurrentWave > RaidConfig.TotalWaves then
		self:EndRaid(true)
		return
	end

	self.WaveConfig = RaidConfig.Waves[self.CurrentWave]

	self:CleanupDemons()
	self:CleanupBoss()

	if self.WaveConfig.IsBossWave then
		self:SpawnBoss()
	else
		self:SpawnDemons()
	end

	self.Client.RaidStateChanged:FireAll("Active", {
		duration = RaidConfig.RaidDuration,
		spiritHealth = self.SpiritHealth,
		wave = self.CurrentWave,
		totalWaves = RaidConfig.TotalWaves,
		isBossWave = self.WaveConfig.IsBossWave,
	})
	self.Client.WaveChanged:FireAll(self.CurrentWave, RaidConfig.TotalWaves, self.SpiritHealth)

	if not self.WaveConfig.IsBossWave then
		task.spawn(function()
			self:DemonAttackLoop()
		end)

		task.spawn(function()
			self:DemonChaseLoop()
		end)
	end
end

function RaidService:SpawnSpirit()
	local spawnsFolder = workspace:FindFirstChild("RaidSpawns")
	local spiritSpawns = spawnsFolder and spawnsFolder:FindFirstChild("SpiritSpawns")
	if not spiritSpawns then
		warn("[RaidService] workspace.RaidSpawns.SpiritSpawns not found")
		return
	end

	local spawnParts = spiritSpawns:GetChildren()
	if #spawnParts == 0 then
		warn("[RaidService] No spawn parts in SpiritSpawns")
		return
	end

	local raidsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Raids")
	local template = raidsFolder and raidsFolder:FindFirstChild("InnocentSpirit")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.Raids.InnocentSpirit not found")
		return
	end

	local spawnPart = spawnParts[math.random(1, #spawnParts)]
	self.SpiritSpawnPos = spawnPart.Position

	local spirit = template:Clone()
	spirit.Name = "RaidSpirit"

	if spirit:IsA("Model") and spirit.PrimaryPart then
		spirit:PivotTo(spawnPart.CFrame)
		local humanoid = spirit:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = RaidConfig.SpiritHealth
			humanoid.Health = RaidConfig.SpiritHealth
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
			humanoid.HealthDisplayDistance = 100
			humanoid.NameDisplayDistance = 0
			humanoid.WalkSpeed = 8
		end
	elseif spirit:IsA("BasePart") then
		spirit.CFrame = spawnPart.CFrame
	end

	for _, part in spirit:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CollisionGroup = SPIRIT_COLLISION_GROUP
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.Parent = spirit

	spirit.Parent = workspace
	self.Spirit = spirit
end

function RaidService:SpiritWanderLoop()
	while self.State == "Active" and self.Spirit do
		local humanoid = self.Spirit:FindFirstChildOfClass("Humanoid")
		if humanoid and self.SpiritSpawnPos then
			local offsetX = math.random(-10, 10)
			local offsetZ = math.random(-10, 10)
			local targetPos = self.SpiritSpawnPos + Vector3.new(offsetX, 0, offsetZ)
			humanoid:MoveTo(targetPos)
		end
		task.wait(math.random(3, 6))
	end
end

function RaidService:SpiritVoicelineLoop()
	task.wait(2) -- Initial delay before first voiceline
	while self.State == "Active" and self.Spirit do
		local voicelines = RaidConfig.Voicelines
		if #voicelines > 0 then
			local line = voicelines[math.random(1, #voicelines)]
			local head = self.Spirit:FindFirstChild("Head")
			if head then
				Chat:Chat(head, line, Enum.ChatColor.White)
			end
		end
		task.wait(RaidConfig.VoicelineCooldown)
	end
end

function RaidService:SpawnDemons()
	local spawnsFolder = workspace:FindFirstChild("RaidSpawns")
	local demonSpawns = spawnsFolder and spawnsFolder:FindFirstChild("DemonSpawns")
	if not demonSpawns then
		warn("[RaidService] workspace.RaidSpawns.DemonSpawns not found")
		return
	end

	local spawnParts = demonSpawns:GetChildren()
	if #spawnParts == 0 then
		warn("[RaidService] No spawn parts in DemonSpawns")
		return
	end

	local raidsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Raids")
	local template = raidsFolder and raidsFolder:FindFirstChild("DarkSpirit")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.Raids.DarkSpirit not found")
		return
	end

	local demonsFolder = workspace:FindFirstChild("RaidDemons") or Instance.new("Folder")
	demonsFolder.Name = "RaidDemons"
	demonsFolder.Parent = workspace

	local waveConfig = self.WaveConfig

	for i = 1, waveConfig.DemonCount do
		local spawnPart = spawnParts[math.random(1, #spawnParts)]
		local demon = template:Clone()
		demon.Name = "Demon_" .. i

		local cf = spawnPart.CFrame * CFrame.new(
			math.random(-5, 5),
			0,
			math.random(-5, 5)
		)

		if demon:IsA("Model") and demon.PrimaryPart then
			demon:PivotTo(cf)
			local humanoid = demon:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = waveConfig.DemonHealth
				humanoid.Health = waveConfig.DemonHealth
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
				humanoid.HealthDisplayDistance = 100
				humanoid.NameDisplayDistance = 0
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged

				humanoid.WalkSpeed = 16
			end
		elseif demon:IsA("BasePart") then
			demon.CFrame = cf
		end

		for _, part in demon:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CollisionGroup = SPIRIT_COLLISION_GROUP
			end
		end

		local highlight = Instance.new("Highlight")
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineTransparency = 0
		highlight.Parent = demon

		demon.Parent = demonsFolder

		self.Demons[demon.Name] = {
			model = demon,
			health = waveConfig.DemonHealth,
		}
	end
end

function RaidService:DemonAttackLoop()
	local currentWave = self.CurrentWave
	while self.State == "Active" and self.CurrentWave == currentWave do
		for _, data in self.Demons do
			if data.health > 0 and data.inRange and data.model then
				self:SpawnDemonProjectile(data.model)
			end
		end
		task.wait(self.WaveConfig.DemonAttackInterval)
	end
end

function RaidService:SpawnDemonProjectile(demonModel: Model | BasePart)
	local demonPos
	local rootPart
	if demonModel:IsA("Model") and demonModel.PrimaryPart then
		rootPart = demonModel.PrimaryPart
		demonPos = rootPart.Position
	elseif demonModel:IsA("BasePart") then
		rootPart = demonModel
		demonPos = demonModel.Position
	end
	if not demonPos then return end

	local blastSound = SoundService:FindFirstChild("AwarenessBlast")
	if blastSound and rootPart then
		local soundClone = blastSound:Clone()
		soundClone.Parent = rootPart
		soundClone:Play()
		soundClone.Ended:Once(function()
			soundClone:Destroy()
		end)
	end

	local orb = Instance.new("Part")
	orb.Name = "DemonProjectile"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2, 2, 2)
	orb.Color = Color3.fromRGB(255, 0, 0)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = demonPos
	orb.Parent = workspace

	local speed = 12
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not self.Spirit or self.State ~= "Active" then
			connection:Disconnect()
			orb:Destroy()
			return
		end

		local targetPos
		if self.Spirit:IsA("Model") and self.Spirit.PrimaryPart then
			targetPos = self.Spirit.PrimaryPart.Position
		elseif self.Spirit:IsA("BasePart") then
			targetPos = self.Spirit.Position
		end

		if not targetPos then
			connection:Disconnect()
			orb:Destroy()
			return
		end

		local direction = (targetPos - orb.Position).Unit
		local distance = (targetPos - orb.Position).Magnitude

		if distance <= speed * dt then
			connection:Disconnect()
			orb:Destroy()

			local damage = self.WaveConfig.DemonDamageToSpirit
			self.SpiritHealth -= damage
			self.Client.SpiritHealthChanged:FireAll(self.SpiritHealth)
			self.Client.SpiritDamageEffect:FireAll(damage)

			if self.Spirit then
				local humanoid = self.Spirit:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = self.SpiritHealth
				end
			end

			if self.SpiritHealth <= 0 then
				self:EndRaid(false)
			end
		else
			orb.Position = orb.Position + direction * speed * dt
		end
	end)
end

function RaidService:DemonChaseLoop()
	local currentWave = self.CurrentWave

	local facingConnection
	facingConnection = RunService.Heartbeat:Connect(function()
		if self.State ~= "Active" or self.CurrentWave ~= currentWave then
			facingConnection:Disconnect()
			return
		end

		if not self.Spirit then return end

		local spiritPos
		if self.Spirit:IsA("Model") and self.Spirit.PrimaryPart then
			spiritPos = self.Spirit.PrimaryPart.Position
		elseif self.Spirit:IsA("BasePart") then
			spiritPos = self.Spirit.Position
		end
		if not spiritPos then return end

		for _, data in self.Demons do
			if data.health > 0 and data.inRange and data.model then
				local rootPart = data.model:IsA("Model") and data.model.PrimaryPart or data.model
				if rootPart then
					local direction = (spiritPos - rootPart.Position) * Vector3.new(1, 0, 1)
					if direction.Magnitude > 0.1 then
						rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + direction.Unit)
					end
				end
			end
		end
	end)

	while self.State == "Active" and self.CurrentWave == currentWave do
		if not self.Spirit then
			task.wait(0.5)
			continue
		end

		local spiritPos
		if self.Spirit:IsA("Model") and self.Spirit.PrimaryPart then
			spiritPos = self.Spirit.PrimaryPart.Position
		elseif self.Spirit:IsA("BasePart") then
			spiritPos = self.Spirit.Position
		end

		if not spiritPos then
			task.wait(0.5)
			continue
		end

		for _, data in self.Demons do
			if data.health > 0 and data.model then
				local demonPos
				if data.model:IsA("Model") and data.model.PrimaryPart then
					demonPos = data.model.PrimaryPart.Position
				elseif data.model:IsA("BasePart") then
					demonPos = data.model.Position
				end

				if demonPos then
					local dist = (spiritPos - demonPos).Magnitude
					data.inRange = dist <= 10

					local humanoid = data.model:FindFirstChildOfClass("Humanoid")
					if humanoid then
						if data.inRange then
							humanoid:MoveTo(demonPos)
						else
							humanoid:MoveTo(spiritPos)
						end
					end
				end
			end
		end

		task.wait(0.5)
	end
end

function RaidService:UpdateRaid()
	local elapsed = os.time() - self.RaidStartTime
	if elapsed >= RaidConfig.RaidDuration then
		self:EndRaid(true)
	end
end

function RaidService:EndRaid(success: boolean)
	self.State = "Idle"
	self.NextRaidTime = os.time() + RaidConfig.RaidInterval

	local leaderboard = {}
	for player, damage in self.PlayerDamage do
		if player.Parent then
			table.insert(leaderboard, { player = player, damage = damage })
		end
	end
	table.sort(leaderboard, function(a, b) return a.damage > b.damage end)

	local RaidShopService = Knit.GetService("RaidShopService")
	local DataService = Knit.GetService("DataService")
	local fragmentReward = success and RaidConfig.FragmentReward or 1
	for player, damage in self.PlayerDamage do
		if player.Parent and damage > 0 then
			RaidShopService:AddFragments(player, fragmentReward)
			if success then
				local profile = DataService:GetProfile(player)
				if profile then
					profile.Data.RaidWins = (profile.Data.RaidWins or 0) + 1
				end
			end
		end
	end

	self.Client.RaidEnded:FireAll(leaderboard, success)
	self.Client.RaidStateChanged:FireAll("Idle", {})

	self:CleanupDemons()
	self:CleanupBoss()
	self:CleanupSpirit()
	self.PlayerDamage = {}
	self.CurrentWave = 0
	self.WaveConfig = nil
end

function RaidService:CleanupDemons()
	local folder = workspace:FindFirstChild("RaidDemons")
	if folder then
		folder:ClearAllChildren()
	end
	self.Demons = {}
end

function RaidService:CleanupSpirit()
	if self.Spirit then
		self.Spirit:Destroy()
		self.Spirit = nil
	end
	self.SpiritSpawnPos = nil
end

function RaidService:CleanupBoss()
	self.BossActive = false
	if self.Boss and self.Boss.model then
		self.Boss.model:Destroy()
	end
	self.Boss = nil
end

function RaidService:SpawnBoss()
	local spawnsFolder = workspace:FindFirstChild("RaidSpawns")
	local demonSpawns = spawnsFolder and spawnsFolder:FindFirstChild("DemonSpawns")
	if not demonSpawns then return end

	local spawnParts = demonSpawns:GetChildren()
	if #spawnParts == 0 then return end

	local raidsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Raids")
	local template = raidsFolder and raidsFolder:FindFirstChild("Imp")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.Raids.Imp not found")
		return
	end

	local spawnPart = spawnParts[math.random(1, #spawnParts)]
	local boss = template:Clone()
	boss.Name = "Boss_Imp"

	if boss:IsA("Model") and boss.PrimaryPart then
		boss:PivotTo(spawnPart.CFrame)
		local humanoid = boss:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = self.WaveConfig.BossHealth
			humanoid.Health = self.WaveConfig.BossHealth
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
			humanoid.HealthDisplayDistance = 100
			humanoid.NameDisplayDistance = 0
			humanoid.WalkSpeed = 14
		end
	end

	for _, part in boss:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CollisionGroup = "Spirit"
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
	highlight.OutlineTransparency = 0
	highlight.Parent = boss

	local demonsFolder = workspace:FindFirstChild("RaidDemons") or Instance.new("Folder")
	demonsFolder.Name = "RaidDemons"
	demonsFolder.Parent = workspace
	boss.Parent = demonsFolder

	self.Boss = {
		model = boss,
		health = self.WaveConfig.BossHealth,
	}
	self.BossActive = true

	-- Boss greeting
	local head = boss:FindFirstChild("Head")
	if head then
		Chat:Chat(head, "You cannot protect the spirit!", Enum.ChatColor.Red)
	end

	task.spawn(function()
		self:BossAILoop()
	end)
end

function RaidService:BossAILoop()
	local attackCooldown = self.WaveConfig.BossAttackInterval
	local lastAttackTime = 0
	local moveIndex = 1

	local moveNames = {
		[1] = "Shadow Blast!",
		[2] = "Dark Beam!",
		[3] = "Infernal Burst!",
	}

	while self.BossActive and self.State == "Active" and self.Boss and self.Boss.model and self.Boss.model.Parent do
		local boss = self.Boss.model
		local humanoid = boss:FindFirstChildOfClass("Humanoid")
		local bossRoot = boss.PrimaryPart
		if not humanoid or not bossRoot then break end

		if not self.Spirit or not self.Spirit.PrimaryPart then
			task.wait(0.5)
			continue
		end

		local spiritPos = self.Spirit.PrimaryPart.Position
		local dist = (bossRoot.Position - spiritPos).Magnitude

		-- Move towards spirit but keep distance
		local attackRange = 12
		if dist > attackRange then
			humanoid:MoveTo(spiritPos)
		else
			humanoid:MoveTo(bossRoot.Position)
		end

		-- Attack if in range
		if dist <= attackRange and os.clock() - lastAttackTime >= attackCooldown then
			lastAttackTime = os.clock()

			local head = boss:FindFirstChild("Head")
			if head then
				Chat:Chat(head, moveNames[moveIndex], Enum.ChatColor.Red)
			end

			local damage = self.WaveConfig.BossDamageToSpirit

			if moveIndex == 1 then
				self:SpawnBossBlast(boss, self.Spirit)
				self:DamageSpiritFromBoss(damage)
			elseif moveIndex == 2 then
				self:SpawnBossBeam(boss, self.Spirit, 2)
				self:DamageSpiritOverTime(damage, 2)
			elseif moveIndex == 3 then
				self:SpawnBossBurst(boss, 15)
				self:DamageSpiritFromBoss(damage)
			end

			moveIndex = moveIndex % 3 + 1
		end

		task.wait(0.2)
	end
end

function RaidService:DamageSpiritFromBoss(damage: number)
	self.SpiritHealth -= damage
	self.Client.SpiritHealthChanged:FireAll(self.SpiritHealth)
	self.Client.SpiritDamageEffect:FireAll(damage)

	if self.Spirit then
		local humanoid = self.Spirit:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = self.SpiritHealth
		end
	end

	if self.SpiritHealth <= 0 then
		self:EndRaid(false)
	end
end

function RaidService:DamageSpiritOverTime(totalDamage: number, duration: number)
	local ticks = 10
	local damagePerTick = totalDamage / ticks
	local interval = duration / ticks

	task.spawn(function()
		for i = 1, ticks do
			task.wait(interval)
			if self.State ~= "Active" then break end
			self:DamageSpiritFromBoss(damagePerTick)
		end
	end)
end

function RaidService:SpawnBossBlast(boss: Model, targetModel: Model)
	local root = boss.PrimaryPart
	if not root then return end

	local targetPos
	if targetModel:IsA("Model") and targetModel.PrimaryPart then
		targetPos = targetModel.PrimaryPart.Position
	end
	if not targetPos then return end

	local orb = Instance.new("Part")
	orb.Name = "BossBlast"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(3, 3, 3)
	orb.Color = Color3.fromRGB(255, 50, 50)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = root.Position
	orb.Parent = workspace

	local tween = TweenService:Create(orb, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
		Position = targetPos
	})
	tween:Play()
	tween.Completed:Connect(function()
		orb:Destroy()
	end)
end

function RaidService:SpawnBossBeam(boss: Model, targetModel: Model, beamDuration: number)
	local root = boss.PrimaryPart
	if not root then return end

	local targetRoot = targetModel.PrimaryPart
	if not targetRoot then return end

	local orbOffset = root.CFrame.LookVector * 3
	local orb = Instance.new("Part")
	orb.Name = "BossBeamOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.5, 0.5, 0.5)
	orb.Color = Color3.fromRGB(255, 50, 50)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = root.Position + orbOffset
	orb.Parent = workspace

	local chargeTween = TweenService:Create(orb, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Size = Vector3.new(4, 4, 4)
	})
	chargeTween:Play()

	task.delay(0.4, function()
		if not orb.Parent or not boss.Parent then return end

		local beam = Instance.new("Part")
		beam.Name = "BossBeam"
		beam.Shape = Enum.PartType.Cylinder
		beam.Color = Color3.fromRGB(255, 50, 50)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		beam.CastShadow = false
		beam.Transparency = 0.2
		beam.Parent = workspace

		local startTime = os.clock()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - startTime
			if elapsed >= beamDuration or not orb.Parent or not boss.Parent or self.State ~= "Active" then
				connection:Disconnect()
				local fadeTween = TweenService:Create(beam, TweenInfo.new(0.3), { Transparency = 1 })
				local orbFade = TweenService:Create(orb, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.5, 0.5, 0.5) })
				fadeTween:Play()
				orbFade:Play()
				fadeTween.Completed:Connect(function()
					beam:Destroy()
					orb:Destroy()
				end)
				return
			end

			local bossRoot = boss.PrimaryPart
			if not bossRoot then return end

			local orbPos = bossRoot.Position + bossRoot.CFrame.LookVector * 3
			orb.Position = orbPos

			local targetPos = targetRoot.Position
			local distance = (targetPos - orbPos).Magnitude
			local midPoint = (orbPos + targetPos) / 2

			local pulse = 3 + math.sin(elapsed * 12) * 0.5
			beam.Size = Vector3.new(distance, pulse, pulse)
			beam.CFrame = CFrame.new(midPoint, targetPos) * CFrame.Angles(0, math.rad(90), 0)
		end)
	end)
end

function RaidService:SpawnBossBurst(boss: Model, radius: number)
	local root = boss.PrimaryPart
	if not root then return end

	local burst = Instance.new("Part")
	burst.Name = "BossBurst"
	burst.Shape = Enum.PartType.Cylinder
	burst.Size = Vector3.new(0.5, 1, 1)
	burst.Color = Color3.fromRGB(255, 50, 50)
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.CastShadow = false
	burst.Transparency = 0.3
	burst.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	burst.Parent = workspace

	local expandTween = TweenService:Create(burst, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, radius * 2, radius * 2),
		Transparency = 1
	})
	expandTween:Play()
	expandTween.Completed:Connect(function()
		burst:Destroy()
	end)
end

function RaidService:DamageBoss(player: Player, damage: number)
	if not self.BossActive or not self.Boss then return false end

	self.Boss.health -= damage
	self.PlayerDamage[player] = (self.PlayerDamage[player] or 0) + damage
	self:BroadcastLeaderboard()

	if self.Boss.model then
		local humanoid = self.Boss.model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = self.Boss.health
		end
	end

	self.Client.DamageEffect:FireAll("Boss_Imp", damage)

	if self.Boss.health <= 0 then
		self.Boss.health = 0
		self:PlayBossDeathEffect()
		self:EndRaid(true)
	end

	return true
end

function RaidService:PlayBossDeathEffect()
	if not self.Boss or not self.Boss.model then return end

	local model = self.Boss.model
	self.BossActive = false
	self.Boss = nil

	local head = model:FindFirstChild("Head")
	if head then
		Chat:Chat(head, "No... impossible!", Enum.ChatColor.Red)
	end

	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	for _, part in parts do
		part.Anchored = true
		TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad), {
			Transparency = 1,
			Color = Color3.fromRGB(50, 50, 50)
		}):Play()
	end

	task.delay(2, function()
		model:Destroy()
	end)
end

function RaidService:DamageDemon(player: Player, demonId: string, damage: number, moveIndex: number?)
	if self.State ~= "Active" then return false end

	local move = moveIndex and RaidConfig.Moves[moveIndex]

	-- Handle summon moves (works on any wave)
	if move and move.Summon then
		self:SpawnAllySpirit(player, move.SummonDuration)
		return true
	end

	-- Boss wave targeting
	if self.BossActive and self.Boss and self.Boss.model then
		if move and move.AOE then
			self:HandleAOEDamageBoss(player, damage, moveIndex, move.AOERadius)
		elseif move and move.Sustained then
			self:HandleSustainedDamageBoss(player, damage, moveIndex, move.Duration)
		else
			if moveIndex == 1 then
				self:SpawnAwarenessBlast(player, self.Boss.model)
			end
			self:DamageBoss(player, damage)
		end
		return true
	end

	-- Handle AOE moves
	if move and move.AOE then
		self:HandleAOEDamage(player, damage, moveIndex, move.AOERadius)
		return true
	end

	-- Handle sustained moves (damage over time)
	if move and move.Sustained then
		self:HandleSustainedDamage(player, demonId, damage, moveIndex, move.Duration)
		return true
	end

	local data = self.Demons[demonId]
	if not data or data.health <= 0 then return false end

	-- Spawn visual effect based on move
	if moveIndex == 1 then
		self:SpawnAwarenessBlast(player, data.model)
	end

	self:ApplyDamageToDemo(player, demonId, data, damage)
	return true
end

function RaidService:ApplyDamageToDemo(player: Player, demonId: string, data, damage: number)
	self.Client.DamageEffect:FireAll(demonId, damage)

	data.health -= damage
	self.PlayerDamage[player] = (self.PlayerDamage[player] or 0) + damage
	self:BroadcastLeaderboard()

	if data.model then
		local humanoid = data.model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = data.health
		end
	end

	if data.health <= 0 then
		data.health = 0
		self.Client.DemonDied:FireAll(demonId)
		if data.model then
			local model = data.model
			data.model = nil
			self:PlayDemonDeathEffect(model)
		end

		local allDead = true
		for _, d in self.Demons do
			if d.health > 0 then
				allDead = false
				break
			end
		end
		if allDead then
			task.delay(RaidConfig.WaveTransitionTime, function()
				if self.State == "Active" then
					self:StartNextWave()
				end
			end)
		end
	end
end

function RaidService:HandleAOEDamage(player: Player, damage: number, moveIndex: number, radius: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local playerPos = root.Position

	-- Spawn AOE visual effect
	if moveIndex == 3 then
		self:SpawnAwarenessBurst(player, radius)
	end

	-- Damage all demons in radius
	for demonId, data in self.Demons do
		if data.health <= 0 or not data.model then continue end

		local demonPos
		if data.model:IsA("Model") and data.model.PrimaryPart then
			demonPos = data.model.PrimaryPart.Position
		elseif data.model:IsA("BasePart") then
			demonPos = data.model.Position
		end

		if demonPos and (playerPos - demonPos).Magnitude <= radius then
			self:ApplyDamageToDemo(player, demonId, data, damage)
		end
	end
end

function RaidService:HandleSustainedDamage(player: Player, demonId: string, totalDamage: number, moveIndex: number, duration: number)
	local data = self.Demons[demonId]
	if not data or data.health <= 0 then return end

	-- Spawn Crystal Blast effect
	if moveIndex == 2 then
		self:SpawnCrystalBlast(player, data.model, duration)
	end

	-- Damage over time
	local ticks = 10
	local damagePerTick = totalDamage / ticks
	local interval = duration / ticks

	task.spawn(function()
		for i = 1, ticks do
			task.wait(interval)
			if self.State ~= "Active" then break end

			local currentData = self.Demons[demonId]
			if not currentData or currentData.health <= 0 then break end

			self:ApplyDamageToDemo(player, demonId, currentData, damagePerTick)
		end
	end)
end

function RaidService:HandleAOEDamageBoss(player: Player, damage: number, moveIndex: number, radius: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if moveIndex == 3 then
		self:SpawnAwarenessBurst(player, radius)
	end

	if not self.Boss or not self.Boss.model then return end

	local bossPos
	if self.Boss.model.PrimaryPart then
		bossPos = self.Boss.model.PrimaryPart.Position
	end

	if bossPos and (root.Position - bossPos).Magnitude <= radius then
		self:DamageBoss(player, damage)
	end
end

function RaidService:HandleSustainedDamageBoss(player: Player, totalDamage: number, moveIndex: number, duration: number)
	if not self.Boss or not self.Boss.model then return end

	if moveIndex == 2 then
		self:SpawnCrystalBlast(player, self.Boss.model, duration)
	end

	local ticks = 10
	local damagePerTick = totalDamage / ticks
	local interval = duration / ticks

	task.spawn(function()
		for i = 1, ticks do
			task.wait(interval)
			if self.State ~= "Active" or not self.BossActive then break end
			self:DamageBoss(player, damagePerTick)
		end
	end)
end

function RaidService:PlayDemonDeathEffect(model)
	-- Move out of RaidDemons folder so CleanupDemons doesn't destroy it
	model.Parent = workspace

	-- Disable humanoid to prevent default death behavior
	if model:IsA("Model") then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Destroy()
		end
	end

	local purifiedSound = SoundService:FindFirstChild("Purified")
	if purifiedSound then
		purifiedSound:Play()
	end

	local duration = 3
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local parts = {}
	if model:IsA("Model") then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end
	elseif model:IsA("BasePart") then
		table.insert(parts, model)
	end

	for _, part in parts do
		part.Anchored = true
		part.CanCollide = false

		local randomX = math.random(1, 3) * (math.random() > 0.5 and 1 or -1)
		local randomZ = math.random(1, 3) * (math.random() > 0.5 and 1 or -1)
		local targetPos = part.Position + Vector3.new(randomX, 4, randomZ)

		local randomRotation = CFrame.Angles(
			math.rad(math.random(-180, 180)),
			math.rad(math.random(-180, 180)),
			math.rad(math.random(-180, 180))
		)
		local targetCFrame = CFrame.new(targetPos) * randomRotation

		local moveTween = TweenService:Create(part, tweenInfo, {
			CFrame = targetCFrame,
			Transparency = 1,
		})
		moveTween:Play()
	end

	task.delay(duration, function()
		model:Destroy()
	end)
end

function RaidService:SpawnCrystalBlast(player: Player, targetModel: Model | BasePart, beamDuration: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	self.Client.MoveEffect:Fire(player, 2)

	local targetRoot
	if targetModel:IsA("Model") and targetModel.PrimaryPart then
		targetRoot = targetModel.PrimaryPart
	elseif targetModel:IsA("BasePart") then
		targetRoot = targetModel
	end
	if not targetRoot then return end

	-- Spawn charging orb in front of player
	local orbOffset = root.CFrame.LookVector * 3
	local orb = Instance.new("Part")
	orb.Name = "CrystalBlastOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.5, 0.5, 0.5)
	orb.Color = Color3.fromRGB(0, 150, 255)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = root.Position + orbOffset
	orb.Parent = workspace

	-- Charge up orb
	local chargeTime = 0.4
	local chargeTween = TweenService:Create(orb, TweenInfo.new(chargeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(3, 3, 3)
	})
	chargeTween:Play()

	task.delay(chargeTime, function()
		if not orb.Parent then return end

		-- Create beam
		local beam = Instance.new("Part")
		beam.Name = "CrystalBlastBeam"
		beam.Shape = Enum.PartType.Cylinder
		beam.Color = Color3.fromRGB(0, 150, 255)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		beam.CastShadow = false
		beam.Transparency = 0.2
		beam.Parent = workspace

		-- Update beam position each frame to track target
		local startTime = os.clock()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - startTime
			if elapsed >= beamDuration or not orb.Parent or self.State ~= "Active" then
				connection:Disconnect()

				-- Fade out
				local fadeTween = TweenService:Create(beam, TweenInfo.new(0.3), { Transparency = 1 })
				local orbFade = TweenService:Create(orb, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.5, 0.5, 0.5) })
				fadeTween:Play()
				orbFade:Play()
				fadeTween.Completed:Connect(function()
					beam:Destroy()
					orb:Destroy()
				end)
				return
			end

			-- Keep orb in front of player
			local orbPos = root.Position + root.CFrame.LookVector * 3
			orb.Position = orbPos

			-- Update beam to target
			local targetPos = targetRoot.Position
			local distance = (targetPos - orbPos).Magnitude
			local midPoint = (orbPos + targetPos) / 2

			-- Pulse beam size
			local pulse = 2.5 + math.sin(elapsed * 12) * 0.4
			beam.Size = Vector3.new(distance, pulse, pulse)
			beam.CFrame = CFrame.new(midPoint, targetPos) * CFrame.Angles(0, math.rad(90), 0)
		end)
	end)
end

function RaidService:SpawnAwarenessBurst(player: Player, radius: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	self.Client.MoveEffect:Fire(player, 3)

	local burst = Instance.new("Part")
	burst.Name = "AwarenessBurst"
	burst.Shape = Enum.PartType.Cylinder
	burst.Size = Vector3.new(0.5, 1, 1)
	burst.Color = Color3.fromRGB(0, 200, 180)
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.CastShadow = false
	burst.Transparency = 0.3
	burst.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	burst.Parent = workspace

	local duration = 1
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local expandTween = TweenService:Create(burst, tweenInfo, {
		Size = Vector3.new(0.5, radius * 2, radius * 2),
		Transparency = 1
	})
	expandTween:Play()
	expandTween.Completed:Connect(function()
		burst:Destroy()
	end)
end

function RaidService:SpawnAllySpirit(player: Player, duration: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	self.Client.MoveEffect:Fire(player, 4)

	local raidsFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Raids")
	local template = raidsFolder and raidsFolder:FindFirstChild("AllySpirit")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.Raids.AllySpirit not found")
		return
	end

	local ally = template:Clone()
	ally.Name = "Ally Spirit (" .. player.Name .. ")"

	local spawnPos = root.Position + root.CFrame.LookVector * 5
	if ally:IsA("Model") and ally.PrimaryPart then
		ally:PivotTo(CFrame.new(spawnPos))
		local humanoid = ally:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 20
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
			humanoid.NameDisplayDistance = 100
			humanoid.DisplayName = "Ally Spirit (" .. player.Name .. ")"
		end
	end

	for _, part in ally:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CollisionGroup = "Spirit"
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(100, 200, 255)
	highlight.OutlineTransparency = 0
	highlight.Parent = ally

	ally.Parent = workspace

	-- Greeting
	local head = ally:FindFirstChild("Head")
	if head then
		Chat:Chat(head, "I'm here to help!", Enum.ChatColor.Blue)
	end

	-- Start ally AI
	task.spawn(function()
		self:AllyAILoop(player, ally, duration)
	end)
end

function RaidService:AllyAILoop(player: Player, ally: Model, duration: number)
	local startTime = os.clock()
	local lastAttackTime = 0
	local attackCooldown = 2
	local moveIndex = 1

	local moveNames = {
		[1] = "Awareness Blast!",
		[2] = "Crystal Blast!",
		[3] = "Astral Burst!",
	}

	while os.clock() - startTime < duration and self.State == "Active" and ally.Parent do
		local humanoid = ally:FindFirstChildOfClass("Humanoid")
		local allyRoot = ally.PrimaryPart
		if not humanoid or not allyRoot then break end

		-- Find nearest demon
		local nearestDemon = nil
		local nearestDist = math.huge
		local nearestId = nil

		for demonId, data in self.Demons do
			if data.health <= 0 or not data.model then continue end

			local demonPos
			if data.model:IsA("Model") and data.model.PrimaryPart then
				demonPos = data.model.PrimaryPart.Position
			elseif data.model:IsA("BasePart") then
				demonPos = data.model.Position
			end

			if demonPos then
				local dist = (allyRoot.Position - demonPos).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestDemon = data
					nearestId = demonId
				end
			end
		end

		if nearestDemon and nearestDemon.model then
			local targetPos
			if nearestDemon.model:IsA("Model") and nearestDemon.model.PrimaryPart then
				targetPos = nearestDemon.model.PrimaryPart.Position
			else
				targetPos = nearestDemon.model.Position
			end

			-- Move towards demon, but stop at attack range
			local attackRange = 12
			if nearestDist > attackRange then
				humanoid:MoveTo(targetPos)
			else
				humanoid:MoveTo(allyRoot.Position)
			end

			-- Attack if in range
			if nearestDist <= attackRange and os.clock() - lastAttackTime >= attackCooldown then
				lastAttackTime = os.clock()

				-- Say move name
				local head = ally:FindFirstChild("Head")
				if head then
					Chat:Chat(head, moveNames[moveIndex], Enum.ChatColor.Blue)
				end

				-- Execute move
				local move = RaidConfig.Moves[moveIndex]
				local damage = move.Damage

				if moveIndex == 1 then
					self:SpawnAwarenessBlast(player, nearestDemon.model, allyRoot)
					self:ApplyDamageToDemo(player, nearestId, nearestDemon, damage)
				elseif moveIndex == 2 then
					self:SpawnCrystalBlastFromAlly(ally, nearestDemon.model, move.Duration)
					self:HandleSustainedDamageFromAlly(player, nearestId, damage, move.Duration)
				elseif moveIndex == 3 then
					self:SpawnAwarenessBurstFromAlly(ally, move.AOERadius)
					self:HandleAOEDamageFromAlly(player, allyRoot.Position, damage, move.AOERadius)
				end

				-- Cycle moves
				moveIndex = moveIndex % 3 + 1
			end
		end

		task.wait(0.2)
	end

	-- Despawn ally
	if ally.Parent then
		local parts = {}
		for _, part in ally:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end

		for _, part in parts do
			TweenService:Create(part, TweenInfo.new(1), { Transparency = 1 }):Play()
		end

		task.delay(1, function()
			ally:Destroy()
		end)
	end
end

function RaidService:SpawnAwarenessBlast(player: Player, targetModel: Model | BasePart, overrideRoot: BasePart?)
	local root = overrideRoot
	if not root then
		local character = player.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
	end
	if not root then return end

	local blastSound = SoundService:FindFirstChild("AwarenessBlast")
	if blastSound then
		local soundClone = blastSound:Clone()
		soundClone.Parent = root
		soundClone:Play()
		soundClone.Ended:Once(function()
			soundClone:Destroy()
		end)
	end

	local targetPos
	if targetModel:IsA("Model") and targetModel.PrimaryPart then
		targetPos = targetModel.PrimaryPart.Position
	elseif targetModel:IsA("BasePart") then
		targetPos = targetModel.Position
	end
	if not targetPos then return end

	local orb = Instance.new("Part")
	orb.Name = "AwarenessBlast"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2, 2, 2)
	orb.Color = Color3.fromRGB(255, 255, 0)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = root.Position
	orb.Parent = workspace

	local tween = TweenService:Create(orb, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		Position = targetPos
	})
	tween:Play()
	tween.Completed:Connect(function()
		orb:Destroy()
	end)
end

function RaidService:SpawnCrystalBlastFromAlly(ally: Model, targetModel: Model | BasePart, beamDuration: number)
	local root = ally.PrimaryPart
	if not root then return end

	local targetRoot
	if targetModel:IsA("Model") and targetModel.PrimaryPart then
		targetRoot = targetModel.PrimaryPart
	elseif targetModel:IsA("BasePart") then
		targetRoot = targetModel
	end
	if not targetRoot then return end

	local orbOffset = root.CFrame.LookVector * 3
	local orb = Instance.new("Part")
	orb.Name = "CrystalBlastOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.5, 0.5, 0.5)
	orb.Color = Color3.fromRGB(0, 150, 255)
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.CastShadow = false
	orb.Position = root.Position + orbOffset
	orb.Parent = workspace

	local chargeTween = TweenService:Create(orb, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Size = Vector3.new(3, 3, 3)
	})
	chargeTween:Play()

	task.delay(0.4, function()
		if not orb.Parent or not ally.Parent then return end

		local beam = Instance.new("Part")
		beam.Name = "CrystalBlastBeam"
		beam.Shape = Enum.PartType.Cylinder
		beam.Color = Color3.fromRGB(0, 150, 255)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		beam.CastShadow = false
		beam.Transparency = 0.2
		beam.Parent = workspace

		local startTime = os.clock()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - startTime
			if elapsed >= beamDuration or not orb.Parent or not ally.Parent or self.State ~= "Active" then
				connection:Disconnect()
				local fadeTween = TweenService:Create(beam, TweenInfo.new(0.3), { Transparency = 1 })
				local orbFade = TweenService:Create(orb, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.5, 0.5, 0.5) })
				fadeTween:Play()
				orbFade:Play()
				fadeTween.Completed:Connect(function()
					beam:Destroy()
					orb:Destroy()
				end)
				return
			end

			local allyRoot = ally.PrimaryPart
			if not allyRoot then return end

			local orbPos = allyRoot.Position + allyRoot.CFrame.LookVector * 3
			orb.Position = orbPos

			local targetPos = targetRoot.Position
			local distance = (targetPos - orbPos).Magnitude
			local midPoint = (orbPos + targetPos) / 2

			-- Pulse beam size
			local pulse = 2.5 + math.sin(elapsed * 12) * 0.4
			beam.Size = Vector3.new(distance, pulse, pulse)
			beam.CFrame = CFrame.new(midPoint, targetPos) * CFrame.Angles(0, math.rad(90), 0)
		end)
	end)
end

function RaidService:SpawnAwarenessBurstFromAlly(ally: Model, radius: number)
	local root = ally.PrimaryPart
	if not root then return end

	local burst = Instance.new("Part")
	burst.Name = "AwarenessBurst"
	burst.Shape = Enum.PartType.Cylinder
	burst.Size = Vector3.new(0.5, 1, 1)
	burst.Color = Color3.fromRGB(0, 200, 180)
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.CastShadow = false
	burst.Transparency = 0.3
	burst.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	burst.Parent = workspace

	local expandTween = TweenService:Create(burst, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, radius * 2, radius * 2),
		Transparency = 1
	})
	expandTween:Play()
	expandTween.Completed:Connect(function()
		burst:Destroy()
	end)
end

function RaidService:HandleSustainedDamageFromAlly(player: Player, demonId: string, totalDamage: number, duration: number)
	local ticks = 10
	local damagePerTick = totalDamage / ticks
	local interval = duration / ticks

	task.spawn(function()
		for i = 1, ticks do
			task.wait(interval)
			if self.State ~= "Active" then break end

			local currentData = self.Demons[demonId]
			if not currentData or currentData.health <= 0 then break end

			self:ApplyDamageToDemo(player, demonId, currentData, damagePerTick)
		end
	end)
end

function RaidService:HandleAOEDamageFromAlly(player: Player, position: Vector3, damage: number, radius: number)
	for demonId, data in self.Demons do
		if data.health <= 0 or not data.model then continue end

		local demonPos
		if data.model:IsA("Model") and data.model.PrimaryPart then
			demonPos = data.model.PrimaryPart.Position
		elseif data.model:IsA("BasePart") then
			demonPos = data.model.Position
		end

		if demonPos and (position - demonPos).Magnitude <= radius then
			self:ApplyDamageToDemo(player, demonId, data, damage)
		end
	end
end

function RaidService:BroadcastLeaderboard()
	local leaderboard = {}
	for player, damage in self.PlayerDamage do
		if player.Parent then
			table.insert(leaderboard, { name = player.Name, damage = damage })
		end
	end
	table.sort(leaderboard, function(a, b) return a.damage > b.damage end)
	self.Client.LeaderboardUpdated:FireAll(leaderboard)
end

-- Client methods
function RaidService.Client:GetRaidState(player)
	return self.Server.State, {
		nextRaidTime = self.Server.NextRaidTime,
		spiritHealth = self.Server.SpiritHealth,
		maxSpiritHealth = self.Server.MaxSpiritHealth,
		raidStartTime = self.Server.RaidStartTime,
		wave = self.Server.CurrentWave,
		totalWaves = RaidConfig.TotalWaves,
	}
end

function RaidService.Client:DamageDemon(player, demonId: string, damage: number, moveIndex: number?)
	return self.Server:DamageDemon(player, demonId, damage, moveIndex)
end

function RaidService.Client:GetPlayerDamage(player)
	return self.Server.PlayerDamage[player] or 0
end

return RaidService
