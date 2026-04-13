local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local REBIRTH_COST = 1000 -- Awareness per rebirth

local RebirthService = Knit.CreateService({
	Name = "RebirthService",
	Client = {
		RebirthsChanged = Knit.CreateSignal(),       -- fires when rebirth count changes
		RebirthsTotalChanged = Knit.CreateSignal(),  -- fires when lifetime total changes
		RebirthsToGainUpdated = Knit.CreateSignal(), -- fires when potential rebirths change
	},
})

RebirthService.RebirthsChanged = Signal.new()    -- (player, rebirths)
RebirthService.RebirthPerformed = Signal.new()   -- (player, count) fires after a rebirth

RebirthService.DataService = nil
RebirthService.AwarenessService = nil
RebirthService.UpgradeService = nil
RebirthService.MultiplierService = nil

function RebirthService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.AwarenessService = Knit.GetService("AwarenessService")
	self.UpgradeService = Knit.GetService("UpgradeService")
	self.MultiplierService = Knit.GetService("MultiplierService")

	self.DataService.ProfileLoaded:Connect(function(player, profile)
		if not profile then return end
		self:SetupPlayer(player, profile)
	end)

	for player, profile in self.DataService.Profiles do
		self:SetupPlayer(player, profile)
	end

	-- Listen to awareness changes to update potential rebirths
	if self.AwarenessService.AwarenessChanged then
		self.AwarenessService.AwarenessChanged:Connect(function(player, newAwareness)
			local potentialRebirths = self:GetRebirthsToGain(player)
			self.Client.RebirthsToGainUpdated:Fire(player, potentialRebirths)
		end)
	end
end

-- Initialize the player's rebirth data
function RebirthService:SetupPlayer(player, profile)
	local rebirths = profile.Data.Rebirths or 0
	self.Client.RebirthsChanged:Fire(player, rebirths)

	local potentialRebirths = self:GetRebirthsToGain(player)
	self.Client.RebirthsToGainUpdated:Fire(player, potentialRebirths)
end

-- Get how many rebirths the player currently has
function RebirthService:GetRebirths(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then return 0 end
	
	return profile.Data.Rebirths or 0
end

-- Get how many rebirths they would gain if they rebirthed now
function RebirthService:GetRebirthsToGain(player)
	local awareness = self.AwarenessService:GetAwareness(player)
	return math.floor(awareness / REBIRTH_COST)
end

-- Accounts for upgrade multiplier
function RebirthService:GetTotalRebirthsToGain(player)
    local baseRebirths = self:GetRebirthsToGain(player)
    local multiplier = self.MultiplierService:GetMultiplier(player, "Rebirth")

    return math.floor(baseRebirths * multiplier)
end
-- Get the cost per rebirth
function RebirthService:GetRebirthCost()
	return REBIRTH_COST
end

-- Check if player can rebirth
function RebirthService:CanRebirth(player)
	local awarenessForRebirth = self:GetRebirthsToGain(player)
	return awarenessForRebirth > 0
end

-- Perform the rebirth
function RebirthService:PerformRebirth(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then 
		warn("No profile for player:", player.Name)
		return false 
	end

	-- Check if they can rebirth
	if not self:CanRebirth(player) then
		--warn("Player cannot rebirth:", player.Name)
		return false
	end

	local rebirthsToGain = self:GetRebirthsToGain(player)
	local multipliedRebirths = self:GetTotalRebirthsToGain(player)

	-- Deduct reset awareness
	self.AwarenessService:SetAwareness(player, 0)
	-- Add rebirths
	profile.Data.Rebirths = (profile.Data.Rebirths or 0) + multipliedRebirths
	profile.Data.RebirthsTotal = (profile.Data.RebirthsTotal or 0) + multipliedRebirths

	profile.Data.Upgrades.AwarenessPerMeditation = 1
	profile.Data.Upgrades.MeditationSpeed = 1

	-- Fire events
	self.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	self.Client.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	self.Client.RebirthsTotalChanged:Fire(player, profile.Data.RebirthsTotal)
	self.Client.RebirthsToGainUpdated:Fire(player, 0) -- Reset to 0 after rebirth

	self.RebirthPerformed:Fire(player, multipliedRebirths)

	print(`Player {player.Name} rebirthed! Gained {rebirthsToGain} rebirths. Total: {profile.Data.Rebirths}`)

	return true
end

function RebirthService:RemoveRebirths(player, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return false end

	if profile.Data.Rebirths < amount then
		return false
	end

	profile.Data.Rebirths = profile.Data.Rebirths - amount
	self.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	self.Client.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	return true
end

function RebirthService:AddRebirths(player, amount)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	profile.Data.Rebirths = (profile.Data.Rebirths or 0) + amount
	profile.Data.RebirthsTotal = (profile.Data.RebirthsTotal or 0) + amount
	self.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	self.Client.RebirthsChanged:Fire(player, profile.Data.Rebirths)
	self.Client.RebirthsTotalChanged:Fire(player, profile.Data.RebirthsTotal)
end

function RebirthService:ResetRebirths(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end
	profile.Data.Rebirths = 0
	self.RebirthsChanged:Fire(player, 0)
	self.Client.RebirthsChanged:Fire(player, 0)
end

-- =======================
-- Client functions exposed via Knit
-- =======================

function RebirthService.Client:GetRebirths(player)
	return self.Server:GetRebirths(player)
end

function RebirthService.Client:GetRebirthsToGain(player)
	return self.Server:GetRebirthsToGain(player)
end

function RebirthService.Client:GetTotalRebirthsToGain(player)
	return self.Server:GetTotalRebirthsToGain(player)
end

function RebirthService.Client:GetRebirthCost(player)
	return self.Server:GetRebirthCost()
end

function RebirthService.Client:CanRebirth(player)
	return self.Server:CanRebirth(player)
end

function RebirthService.Client:PerformRebirth(player)
	return self.Server:PerformRebirth(player)
end

function RebirthService.Client:RemoveRebirths(player, amount)
	return self.Server:RemoveRebirths(player, amount)
end



return RebirthService