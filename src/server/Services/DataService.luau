local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

-- Fields stored as Quicknum-encoded strings in profile.Data
local QN_FIELDS = {
	"Awareness", "AwarenessTotal",
	"Rebirths", "RebirthsTotal",
	"Crystals", "CrystalsTotal",
	"AstralEchoes", "AstralEchoesTotal",
	"Essences", "EssencesTotal",
	"DarkEssences", "DarkEssencesTotal",
}

local DataService = Knit.CreateService{
	Name = "DataService",
	Client = {
		DataLoaded = Knit.CreateSignal(),
	}
}

DataService.Profiles = {}
DataService.ProfileLoaded = Signal.new()
DataService._qnCache = {} -- [player] = { field = buffer }

local CLEAR_DATA_ON_LEAVE = false

local PROFILE_TEMPLATE = {
	Awareness = "0",
	Rebirths = "0",
	Crystals = "0",
	AstralEchoes = "0",
	Essences = "0",
	DarkEssences = "0",
	AwakeningLevel = 0,

	Fragments = 0,
	RaidShopBoosts = {},

	Summons = 1,
	MaxSummons = 1,
	SummonRegenQueue = {}, -- array of os.time() Unix timestamps, one per consumed summon slot

	AwarenessTotal = "0",
	RebirthsTotal = "0",
	CrystalsTotal = "0",
	AstralEchoesTotal = "0",
	EssencesTotal = "0",
	DarkEssencesTotal = "0",

	XP = 0,
	Level = 1,
	PlaytimeSeconds = 0,
	RobuxSpent = 0,
	RaidWins = 0,

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

		SpiritDamage = 1,
		EssenceValue = 1,
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
		Tree3 = {}, -- locked until Awakening Level 2 (TBD)
    },

	PurchasedNodes = {

		Tree1 = {},
		Tree2 = {},
		Tree3 = {},
	},

	Unlocks = {},

	TutorialStage = 1, -- 1-based index into TutorialConfig.Stages; set beyond #Stages when complete

	-- Analytics one-time event flags
	Analytics_JoinedGame          = false,
	Analytics_Reached250kAwareness = false,
	Analytics_Tree1_1_Unlocked    = false,
	Analytics_Tree1_1_Purchased   = false,
	Analytics_FirstRebirth        = false,

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

	-- Last known position for same-session respawn (cleared after use or after 1 hour)
	LastPositionX    = nil,
	LastPositionY    = nil,
	LastPositionZ    = nil,
	LastPositionTime = 0,

}

local PlayerStore = ProfileStore.New("PlayerStoreTest", PROFILE_TEMPLATE)
DataService.PlayerStore = PlayerStore

-- Migrate profile.Data QN fields from legacy plain numbers to encoded strings,
-- then populate the in-memory buffer cache.
function DataService:_initQNCache(player, profile)
	local cache = {}
	for _, field in QN_FIELDS do
		local v = profile.Data[field]
		if type(v) == "number" then
			-- Legacy: convert plain number to buffer, store encoded string for next save
			local buf = num.fromNumber(v)
			profile.Data[field] = num.encode(buf)
			cache[field] = buf
		elseif type(v) == "string" then
			cache[field] = num.decode(v)
		else
			cache[field] = num.fromNumber(0)
		end
	end
	self._qnCache[player] = cache
end

-- Encode all cached buffers back to profile.Data strings before EndSession.
function DataService:_flushQNCache(player, profile)
	local cache = self._qnCache[player]
	if not cache then return end
	for _, field in QN_FIELDS do
		local buf = cache[field]
		if buf then
			profile.Data[field] = num.encode(buf)
		end
	end
	self._qnCache[player] = nil
end

-- Returns the live Quicknum buffer for player/field. Never returns nil.
function DataService:GetQN(player, field)
	local cache = self._qnCache[player]
	if cache and cache[field] then
		return cache[field]
	end
	return num.fromNumber(0)
end

-- Stores a new buffer (or plain number) for player/field in the cache.
function DataService:SetQN(player, field, value)
	local cache = self._qnCache[player]
	if not cache then return end
	if type(value) == "number" then
		value = num.fromNumber(value)
	end
	cache[field] = value
end

-- Add amount (buffer or number) to a cached field and return new value.
function DataService:AddQN(player, field, amount)
	local cache = self._qnCache[player]
	if not cache then return num.fromNumber(0) end
	if type(amount) == "number" then
		amount = num.fromNumber(amount)
	end
	local result = num.add(cache[field] or num.fromNumber(0), amount)
	cache[field] = result
	return result
end

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
			DataService:_initQNCache(player, profile)

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

-- Recursively replace any non-JSON-safe numbers (inf, -inf, NaN) before saving.
-- DataStore serializes via JSON; `inf` becomes invalid and the key is dropped on reload.
local function sanitizeForSave(tbl)
	for k, v in tbl do
		if type(v) == "number" then
			if v ~= v or v == math.huge or v == -math.huge then
				tbl[k] = 0
			end
		elseif type(v) == "table" then
			sanitizeForSave(v)
		end
	end
end

function DataService:PlayerRemoving(player: Player)
	local profile = DataService.Profiles[player]
	if profile ~= nil then
		DataService:_flushQNCache(player, profile)
		sanitizeForSave(profile.Data)

		print(profile.Data)
		if CLEAR_DATA_ON_LEAVE and RunService:IsStudio() then
			print("Clearing data")
			profile.Data = {}
		end
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