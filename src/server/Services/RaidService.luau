local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RaidConfig = require(ReplicatedStorage.Shared.Configs.RaidConfig)

local RaidService = Knit.CreateService {
	Name = "RaidService",
	Client = {
		RaidStateChanged = Knit.CreateSignal(), -- (state: string, data: table)
		DemonDamaged = Knit.CreateSignal(), -- (demonId: string, health: number)
		DemonDied = Knit.CreateSignal(), -- (demonId: string)
		SpiritHealthChanged = Knit.CreateSignal(), -- (health: number)
		RaidWarning = Knit.CreateSignal(), -- fires 30s before raid
		RaidEnded = Knit.CreateSignal(), -- (leaderboard: table, success: boolean)
	},
}

RaidService.State = "Idle" -- Idle, Warning, Active
RaidService.Demons = {} -- { [id] = { model, health } }
RaidService.Spirit = nil -- Spirit model
RaidService.SpiritHealth = RaidConfig.SpiritHealth
RaidService.PlayerDamage = {} -- { [player] = totalDamage }
RaidService.RaidStartTime = 0
RaidService.NextRaidTime = 0

function RaidService:KnitStart()
	self.NextRaidTime = os.time() + RaidConfig.RaidInterval
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
	self.SpiritHealth = RaidConfig.SpiritHealth
	self.PlayerDamage = {}
	self.RaidStartTime = os.time()

	self:SpawnSpirit()
	self:SpawnDemons()
	self.Client.RaidStateChanged:FireAll("Active", {
		duration = RaidConfig.RaidDuration,
		spiritHealth = self.SpiritHealth,
	})

	task.spawn(function()
		self:DemonAttackLoop()
	end)

	task.spawn(function()
		self:DemonChaseLoop()
	end)
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

	local template = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Spirit")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.Spirit not found")
		return
	end

	local spawnPart = spawnParts[math.random(1, #spawnParts)]
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
		end
	elseif spirit:IsA("BasePart") then
		spirit.CFrame = spawnPart.CFrame
	end

	spirit.Parent = workspace
	self.Spirit = spirit
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

	local template = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("DarkSpirit")
	if not template then
		warn("[RaidService] ReplicatedStorage.Assets.DarkSpirit not found")
		return
	end

	local demonsFolder = workspace:FindFirstChild("RaidDemons") or Instance.new("Folder")
	demonsFolder.Name = "RaidDemons"
	demonsFolder.Parent = workspace

	for i = 1, RaidConfig.DemonCount do
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
				humanoid.MaxHealth = RaidConfig.DemonHealth
				humanoid.Health = RaidConfig.DemonHealth
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
				humanoid.HealthDisplayDistance = 100
				humanoid.NameDisplayDistance = 0
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
			end
		elseif demon:IsA("BasePart") then
			demon.CFrame = cf
		end

		demon.Parent = demonsFolder

		self.Demons[demon.Name] = {
			model = demon,
			health = RaidConfig.DemonHealth,
		}
	end
end

function RaidService:DemonAttackLoop()
	while self.State == "Active" do
		for _, data in self.Demons do
			if data.health > 0 and data.inRange then
				self.SpiritHealth -= RaidConfig.DemonDamageToSpirit
				self.Client.SpiritHealthChanged:FireAll(self.SpiritHealth)

				-- Update Spirit humanoid health bar
				if self.Spirit then
					local humanoid = self.Spirit:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.Health = self.SpiritHealth
					end
				end

				if self.SpiritHealth <= 0 then
					self:EndRaid(false)
					return
				end
			end
		end
		task.wait(RaidConfig.DemonAttackInterval)
	end
end

function RaidService:DemonChaseLoop()
	while self.State == "Active" do
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
					data.inRange = dist <= 6

					if not data.inRange then
						local humanoid = data.model:FindFirstChildOfClass("Humanoid")
						if humanoid then
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

	self.Client.RaidEnded:FireAll(leaderboard, success)
	self.Client.RaidStateChanged:FireAll("Idle", {})

	self:CleanupDemons()
	self.Demons = {}
	self.PlayerDamage = {}
end

function RaidService:CleanupDemons()
	local folder = workspace:FindFirstChild("RaidDemons")
	if folder then
		folder:ClearAllChildren()
	end
	if self.Spirit then
		self.Spirit:Destroy()
		self.Spirit = nil
	end
end

function RaidService:DamageDemon(player: Player, demonId: string, damage: number)
	if self.State ~= "Active" then return false end

	local data = self.Demons[demonId]
	if not data or data.health <= 0 then return false end

	data.health -= damage
	self.PlayerDamage[player] = (self.PlayerDamage[player] or 0) + damage

	-- Update Humanoid health for visual health bar
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
			data.model:Destroy()
		end

		local allDead = true
		for _, d in self.Demons do
			if d.health > 0 then
				allDead = false
				break
			end
		end
		if allDead then
			self:EndRaid(true)
		end
	else
		self.Client.DemonDamaged:FireAll(demonId, data.health)
	end

	return true
end

-- Client methods
function RaidService.Client:GetRaidState(player)
	return self.Server.State, {
		nextRaidTime = self.Server.NextRaidTime,
		spiritHealth = self.Server.SpiritHealth,
		raidStartTime = self.Server.RaidStartTime,
	}
end

function RaidService.Client:DamageDemon(player, demonId: string, damage: number)
	return self.Server:DamageDemon(player, demonId, damage)
end

function RaidService.Client:GetPlayerDamage(player)
	return self.Server.PlayerDamage[player] or 0
end

return RaidService
