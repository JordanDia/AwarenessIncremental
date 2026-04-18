local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AdminService = Knit.CreateService { Name = "AdminService", Client = {} }

local ADMIN_IDS = { [33124593] = true }

-- Maps chat alias → { dataKey, totalKey? }
local STAT_MAP = {
	awareness   = { key = "Awareness",    total = "AwarenessTotal" },
	rebirths    = { key = "Rebirths",     total = "RebirthsTotal" },
	astralecho  = { key = "AstralEchoes", total = "AstralEchoesTotal" },
	astralEchoes= { key = "AstralEchoes", total = "AstralEchoesTotal" },
	echoes      = { key = "AstralEchoes", total = "AstralEchoesTotal" },
	crystals    = { key = "Crystals",     total = "CrystalsTotal" },
}

local function resolveStatEntry(alias)
	return STAT_MAP[alias] or STAT_MAP[alias:lower()]
end

local function reply(player, msg)
	-- Surface feedback to the admin via a hint above their head or output
	print("[AdminService → " .. player.Name .. "]: " .. msg)
end

-- Apply a stat change to an already-loaded profile table
local function applyToData(data, statEntry, value)
	data[statEntry.key] = value
	if statEntry.total then
		-- Only raise the total, never lower it (it's a lifetime stat)
		data[statEntry.total] = math.max(data[statEntry.total] or 0, value)
	end
end

function AdminService:SetStatForUserId(adminPlayer, userId, statAlias, value)
	local statEntry = resolveStatEntry(statAlias)
	if not statEntry then
		reply(adminPlayer, "Unknown stat '" .. statAlias .. "'")
		return
	end

	-- Check if the target is online on THIS server
	local onlinePlayer = Players:GetPlayerByUserId(userId)
	if onlinePlayer then
		local profile = self.DataService:GetProfile(onlinePlayer)
		if profile then
			applyToData(profile.Data, statEntry, value)
			-- Recalculate dynamic multipliers so infinite cached values don't persist
			self.UpgradeTreeService:RecalculateAllDynamic(onlinePlayer)
			-- Push updated data to the client so their UI refreshes immediately
			self.DataService.Client.DataLoaded:Fire(onlinePlayer, profile.Data)
			reply(adminPlayer, ("Set %s.%s = %s (online)"):format(onlinePlayer.Name, statEntry.key, tostring(value)))
		else
			reply(adminPlayer, "Player is online but profile not loaded yet.")
		end
		return
	end

	-- Player is offline — open a temporary session, edit, and close
	reply(adminPlayer, ("Player %d is offline, editing DataStore directly..."):format(userId))
	task.spawn(function()
		local profile = self.DataService.PlayerStore:StartSessionAsync(tostring(userId), {
			Cancel = function() return false end,
		})
		if not profile then
			reply(adminPlayer, "Failed to load offline profile for userId " .. tostring(userId))
			return
		end
		profile:Reconcile()
		applyToData(profile.Data, statEntry, value)
		profile:EndSession()
		reply(adminPlayer, ("Offline edit done: userId %d → %s = %s"):format(userId, statEntry.key, tostring(value)))
	end)
end

local function parseCommand(text)
	-- :set <playerName> <stat> <value>
	local name, stat, rawVal = text:match("^:set%s+(%S+)%s+(%S+)%s+(%S+)$")
	if name then
		return "set", name, nil, stat, rawVal
	end
	-- :setbyuserid <userId> <stat> <value>
	local uid, stat2, rawVal2 = text:match("^:setbyuserid%s+(%d+)%s+(%S+)%s+(%S+)$")
	if uid then
		return "setbyuserid", nil, tonumber(uid), stat2, rawVal2
	end
	return nil
end

function AdminService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.UpgradeTreeService = Knit.GetService("UpgradeTreeService")

	Players.PlayerAdded:Connect(function(player)
		if not ADMIN_IDS[player.UserId] then return end

		print(("[AdminService] Admin joined: %s (%d)"):format(player.Name, player.UserId))

		player.Chatted:Connect(function(msg)
			local cmd, playerName, userId, stat, rawVal = parseCommand(msg)
			if not cmd then return end

			local value = tonumber(rawVal)
			if not value then
				reply(player, "Invalid value '" .. tostring(rawVal) .. "' — must be a number (e.g. 1e30 or 109)")
				return
			end

			if cmd == "set" then
				-- Resolve player by name (case-insensitive prefix match)
				local target
				local lowerName = playerName:lower()
				for _, p in Players:GetPlayers() do
					if p.Name:lower():sub(1, #lowerName) == lowerName then
						target = p
						break
					end
				end
				if not target then
					reply(player, "No online player found matching '" .. playerName .. "'")
					return
				end
				self:SetStatForUserId(player, target.UserId, stat, value)

			elseif cmd == "setbyuserid" then
				self:SetStatForUserId(player, userId, stat, value)
			end
		end)
	end)
end

return AdminService
