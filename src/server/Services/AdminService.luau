local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)
local FormatQN = require(ReplicatedStorage.Shared.Modules.FormatQN)

local AdminService = Knit.CreateService { Name = "AdminService", Client = {} }

local ADMIN_IDS = { [33124593] = true }

-- Maps chat alias → { dataKey, totalKey? }
local STAT_MAP = {
	awareness    = { key = "Awareness",    total = "AwarenessTotal" },
	rebirths     = { key = "Rebirths",     total = "RebirthsTotal" },
	astralecho   = { key = "AstralEchoes", total = "AstralEchoesTotal" },
	astralEchoes = { key = "AstralEchoes", total = "AstralEchoesTotal" },
	echoes       = { key = "AstralEchoes", total = "AstralEchoesTotal" },
	crystals     = { key = "Crystals",     total = "CrystalsTotal" },
	essences     = { key = "Essences",     total = "EssencesTotal" },
	darkessences = { key = "DarkEssences", total = "DarkEssencesTotal" },
}

local LOG10_2 = math.log10(2)

-- Parses a value string into a Quicknum buffer.
-- Handles plain integers, doubles (1e30), and super-large exponents (1e400+)
-- that exceed Lua's double range.
local function parseQNValue(str)
	-- Try normal tonumber first (handles values up to ~1.8e308)
	local n = tonumber(str)
	if n and n ~= math.huge and n == n and n > 0 then
		return num.fromNumber(n), FormatQN(num.fromNumber(n))
	end

	-- Parse scientific notation manually: "2.5e400" or "1e999"
	local mantissaStr, expStr = str:match("^([%d%.]+)[eE][+]?(%d+)$")
	if mantissaStr and expStr then
		local mDec = tonumber(mantissaStr) or 1
		local e10  = tonumber(expStr) or 0
		-- mDec * 10^e10 = mBin * 2^eBin  →  solve for binary representation
		local totalLog10 = math.log10(mDec) + e10
		local eBin = math.ceil(totalLog10 / LOG10_2)
		local mBin = math.pow(10, totalLog10 - eBin * LOG10_2)
		-- mBin should be in [0.5, 1); nudge if floating point puts it just outside
		if mBin >= 1 then
			mBin = mBin / 2
			eBin += 1
		end
		if mBin < 0.5 then
			mBin = mBin * 2
			eBin -= 1
		end
		local buf = buffer.create(16)
		buffer.writef64(buf, 0, mBin)
		buffer.writef64(buf, 8, eBin)
		-- Format for display using scientific notation since it's beyond suffix range
		local display = string.format("%.2fe+%d", mDec, e10)
		return buf, display
	end

	return nil, nil
end

local function resolveStatEntry(alias)
	return STAT_MAP[alias] or STAT_MAP[alias:lower()]
end

local function reply(player, msg)
	print("[AdminService → " .. player.Name .. "]: " .. msg)
end

function AdminService:SetStatForUserId(adminPlayer, userId, statAlias, buf, displayStr)
	local statEntry = resolveStatEntry(statAlias)
	if not statEntry then
		reply(adminPlayer, "Unknown stat '" .. statAlias .. "'")
		return
	end

	local onlinePlayer = Players:GetPlayerByUserId(userId)
	if onlinePlayer then
		local profile = self.DataService:GetProfile(onlinePlayer)
		if profile then
			self.DataService:SetQN(onlinePlayer, statEntry.key, buf)
			if statEntry.total then
				if num.gt(buf, self.DataService:GetQN(onlinePlayer, statEntry.total)) then
					self.DataService:SetQN(onlinePlayer, statEntry.total, buf)
				end
			end
			self.UpgradeTreeService:RecalculateAllDynamic(onlinePlayer)
			self.DataService.Client.DataLoaded:Fire(onlinePlayer, profile.Data)
			reply(adminPlayer, ("Set %s.%s = %s (online)"):format(onlinePlayer.Name, statEntry.key, displayStr))
		else
			reply(adminPlayer, "Player is online but profile not loaded yet.")
		end
		return
	end

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
		local encoded = num.encode(buf)
		profile.Data[statEntry.key] = encoded
		if statEntry.total then
			local existing = profile.Data[statEntry.total]
			local currentBuf = num.decode(type(existing) == "string" and existing or "0")
			if num.gt(buf, currentBuf) then
				profile.Data[statEntry.total] = encoded
			end
		end
		profile:EndSession()
		reply(adminPlayer, ("Offline edit done: userId %d → %s = %s"):format(userId, statEntry.key, displayStr))
	end)
end

local function parseCommand(text)
	local name, stat, rawVal = text:match("^:set%s+(%S+)%s+(%S+)%s+(%S+)$")
	if name then
		return "set", name, nil, stat, rawVal
	end
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

			local buf, displayStr = parseQNValue(rawVal)
			if not buf then
				reply(player, "Invalid value '" .. tostring(rawVal) .. "' — must be a number (e.g. 1e30, 109, or 1e400)")
				return
			end

			if cmd == "set" then
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
				self:SetStatForUserId(player, target.UserId, stat, buf, displayStr)

			elseif cmd == "setbyuserid" then
				self:SetStatForUserId(player, userId, stat, buf, displayStr)
			end
		end)
	end)
end

return AdminService
