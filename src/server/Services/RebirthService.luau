local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local AnalyticsService  = game:GetService("AnalyticsService")
local Knit   = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local num    = require(ReplicatedStorage.Shared.Modules.Quicknum)

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
function RebirthService:SetupPlayer(player, _profile)
	self.Client.RebirthsChanged:Fire(player, self.DataService:GetQN(player, "Rebirths"))
	self.Client.RebirthsToGainUpdated:Fire(player, self:GetRebirthsToGain(player))
end

-- Returns the live Quicknum buffer for the player's Rebirths.
function RebirthService:GetRebirths(player)
	return self.DataService:GetQN(player, "Rebirths")
end

-- Returns a Quicknum buffer: floor(awareness / REBIRTH_COST)
function RebirthService:GetRebirthsToGain(player)
	local awareness = self.AwarenessService:GetAwareness(player)
	return num.floor(num.div(awareness, REBIRTH_COST))
end

-- Accounts for upgrade multiplier; returns a Quicknum buffer.
function RebirthService:GetTotalRebirthsToGain(player)
	local baseRebirths = self:GetRebirthsToGain(player)
	local multiplier   = self.MultiplierService:GetMultiplier(player, "Rebirth")
	return num.floor(num.mul(baseRebirths, multiplier))
end
-- Get the cost per rebirth
function RebirthService:GetRebirthCost()
	return REBIRTH_COST
end

-- Check if player can rebirth
function RebirthService:CanRebirth(player)
	return num.gt(self:GetRebirthsToGain(player), 0)
end

-- Perform the rebirth
function RebirthService:PerformRebirth(player)
	local profile = self.DataService:GetProfile(player)
	if not profile then
		warn("No profile for player:", player.Name)
		return false
	end

	if not self:CanRebirth(player) then
		return false
	end

	local multipliedRebirths = self:GetTotalRebirthsToGain(player)

	self.AwarenessService:SetAwareness(player, 0)

	local newRebirths = num.add(self.DataService:GetQN(player, "Rebirths"), multipliedRebirths)
	local newTotal    = num.add(self.DataService:GetQN(player, "RebirthsTotal"), multipliedRebirths)
	self.DataService:SetQN(player, "Rebirths", newRebirths)
	self.DataService:SetQN(player, "RebirthsTotal", newTotal)

	profile.Data.Upgrades.AwarenessPerMeditation = 1
	profile.Data.Upgrades.MeditationSpeed = 1

	self.RebirthsChanged:Fire(player, newRebirths)
	self.Client.RebirthsChanged:Fire(player, newRebirths)
	self.Client.RebirthsTotalChanged:Fire(player, newTotal)
	self.Client.RebirthsToGainUpdated:Fire(player, num.fromNumber(0))

	self.RebirthPerformed:Fire(player, multipliedRebirths)

	if not profile.Data.Analytics_FirstRebirth then
		profile.Data.Analytics_FirstRebirth = true
		pcall(function()
			AnalyticsService:LogProgressionEvent(player, "Rebirth", Enum.AnalyticsProgressionStatus["Complete"], {"FirstRebirth"})
		end)
	end

	return true
end

function RebirthService:RemoveRebirths(player, amount)
	local current = self.DataService:GetQN(player, "Rebirths")
	local amountBuf = type(amount) == "buffer" and amount or num.fromNumber(amount)
	if num.lt(current, amountBuf) then return false end
	local newRebirths = num.sub(current, amountBuf)
	self.DataService:SetQN(player, "Rebirths", newRebirths)
	self.RebirthsChanged:Fire(player, newRebirths)
	self.Client.RebirthsChanged:Fire(player, newRebirths)
	return true
end

function RebirthService:AddRebirths(player, amount)
	local newRebirths = self.DataService:AddQN(player, "Rebirths", amount)
	local newTotal    = self.DataService:AddQN(player, "RebirthsTotal", amount)
	self.RebirthsChanged:Fire(player, newRebirths)
	self.Client.RebirthsChanged:Fire(player, newRebirths)
	self.Client.RebirthsTotalChanged:Fire(player, newTotal)
end

function RebirthService:ResetRebirths(player)
	local zero = num.fromNumber(0)
	self.DataService:SetQN(player, "Rebirths", zero)
	self.RebirthsChanged:Fire(player, zero)
	self.Client.RebirthsChanged:Fire(player, zero)
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

function RebirthService.Client:GetRebirthCost(_player)
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