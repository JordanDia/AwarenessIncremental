local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local DataService = Knit.CreateService{
	Name = "DataService",
}

DataService.Profiles = {}
DataService.ProfileLoaded = Signal.new()

local PROFILE_TEMPLATE = {
	Awareness = 0,
	Rebirths = 0,
	Crystals = 0,

	XP = 0,
	Level = 1,

	Upgrades = {
		AwarenessPerMeditation = 1,
		MeditationSpeed = 1,
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
    },

	PurchasedNodes = {


		Tree1 = {},
	},

	Unlocks = {},

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

			print(`Profile loaded for player {player.Name} ({player.UserId})`)
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
		--profile.Data = {}
		profile:EndSession()
	end
end

function DataService:GetProfile(player: Player)
	return DataService.Profiles[player] or nil
end

return DataService