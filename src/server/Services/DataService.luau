local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local DataService = Knit.CreateService{
	Name = "DataService",
	Client = {
		DataLoaded = Knit.CreateSignal()
	}
}

DataService.Profiles = {}
DataService.ProfileLoaded = Signal.new()

local PROFILE_TEMPLATE = {
	Awareness = 0,
	Rebirths = 0,
	Crystals = 0,
	AstralEchoes = 0,
	Harmony = 0,
	AwakeningLevel = 0,

	AwarenessTotal = 0,
	RebirthsTotal = 0,
	CrystalsTotal = 0,
	AstralEchoesTotal = 0,
	HarmonyTotal = 0,

	XP = 0,
	Level = 1,
	PlaytimeSeconds = 0,
	RobuxSpent = 0,

	LastMeditateAnywhereBoost = 0,
	LastMeditationSpeedBoost  = 0,

	Upgrades = {

		-- Meditation
		AwarenessPerMeditation = 1,
		MeditationSpeed = 1,

		-- Crystals
		CrystalValue = 1,
		CrystalSpeed = 1,
		MaxCrystals = 1,
		CrystalMultiplier = 1,
		CrystalAwarenessMultiplier = 1,
		CrystalRebirthMultiplier = 1,

		AstralEchoMultiplyAwareness = 1,
		AstralEchoMultiplyRebirth = 1,
		AstralEchoValue = 1,
		VeilDuration = 1,
	},

	RebirthUpgrades = {
		MultiplyAwarenessPerMeditation = 1,
		MultiplyRebirthAmount = 1,
		IncreaseDeepThoughtChance = 1,
	},

	-- New: Upgrade Tree Data
    UnlockedNodes = {
        -- Dynamically populated per tree
        -- Example: Tree1 = { RootNode = true, NodeA = false }

		Tree1 = {},
		Tree2 = {}, -- locked until Awakening Level 1
    },

	PurchasedNodes = {

		Tree1 = {},
		Tree2 = {},
	},

	Unlocks = {},

	TutorialStage = 1, -- 1-based index into TutorialConfig.Stages; set beyond #Stages when complete

	-- Badge tracking (prevents duplicate awards across sessions)
	Badges_FirstMeditation = false,
	Badges_FirstCrystal    = false,
	Badges_FirstRebirth    = false,
	Badges_FirstAwakening  = false,
	Badges_FirstVeil       = false,
	Badges_FirstAstralEcho = false,

	DailyQuests = {
		LastReset = 0,  -- os.time() of last reset
		Progress  = {}, -- [questId] = number
		Claimed   = {}, -- [questId] = true
	},

	Boosts = {},

}

local PlayerStore = ProfileStore.New("PlayerStoreTest", PROFILE_TEMPLATE)

function DataService:KnitInit()
	Players.PlayerAdded:Connect(function(player: Player)
		self:LoadPlayer(player)
	end)

	for _, player: Player in Players:GetPlayers() do
		self:LoadPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		DataService:PlayerRemoving(player)
	end)

	self.ProfileLoaded:Connect(function(player, profile)
		self.Client.DataLoaded:Fire(player, profile.Data)
	end)
end

function DataService:LoadPlayer(player: Player)
    local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

		profile.OnSessionEnd:Connect(function()
			DataService.Profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)

		if player.Parent == Players then
			DataService.Profiles[player] = profile
			DataService.ProfileLoaded:Fire(player, profile)

		else
			-- The player has left before the profile session started
			profile:EndSession()
		end
	else
		-- This condition should only happen when the Roblox server is shutting down
		player:Kick(`Profile load fail - Please rejoin`)
	end
end

function DataService:PlayerRemoving(player: Player)
	local profile = DataService.Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

function DataService:GetProfile(player: Player)
	return DataService.Profiles[player] or nil
end

function DataService:GetData(player: Player)
	local profile = DataService.Profiles[player]
	if not profile then return nil end
	return profile.Data
end

function DataService.Client:GetFirstSessionTime(player: Player)
	local profile = DataService.Profiles[player]
	if not profile then return nil end
	return profile.FirstSessionTime
end

return DataService