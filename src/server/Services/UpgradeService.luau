local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UpgradeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeConfig)

-- Upgrades that feed into MultiplierService. Maps upgradeId -> { stat, source }
local MULTIPLIER_MAP = {
	MultiplyAwarenessPerMeditation = { stat = "Awareness", source = "Rebirth" },
	CrystalAwarenessMultiplier     = { stat = "Awareness", source = "Crystal" },
	AstralEchoMultiplyAwareness    = { stat = "Awareness", source = "AstralEcho" },
	MultiplyRebirthAmount          = { stat = "Rebirth",   source = "Rebirth" },
	CrystalRebirthMultiplier       = { stat = "Rebirth",   source = "Crystal" },
	AstralEchoMultiplyRebirth      = { stat = "Rebirth",   source = "AstralEcho" },
}

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
	Client = {
		UpgradeUpdated = Knit.CreateSignal(), -- fires when level changes (for UI)
	},
})

UpgradeService.UpgradeUpdated = Signal.new() -- (player, upgradeId, level) server-side

UpgradeService.DataService = nil
UpgradeService.AwarenessService = nil
UpgradeService.RebirthService = nil
UpgradeService.CrystalService = nil
UpgradeService.MultiplierService = nil

function UpgradeService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.AwarenessService = Knit.GetService("AwarenessService")
	self.RebirthService = Knit.GetService("RebirthService")
	self.CrystalService = Knit.GetService("CrystalService")
	self.AstralEchoService = Knit.GetService("AstralEchoService")
	self.MultiplierService = Knit.GetService("MultiplierService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if not profile then return end
        self:SetupPlayer(player, profile)
    end)

	for player, profile in self.DataService.Profiles do
        self:SetupPlayer(player, profile)
    end
end

-- If upgradeId feeds a multiplier stat, push the current value to MultiplierService
function UpgradeService:_UpdateMultiplierIfNeeded(player, upgradeId, level)
	local mapping = MULTIPLIER_MAP[upgradeId]
	if not mapping then return end

	if level <= 0 then
		self.MultiplierService:RemoveSource(player, mapping.stat, mapping.source)
	else
		local value = UpgradeConfig[upgradeId].EffectPerLevel(level)
		self.MultiplierService:SetSource(player, mapping.stat, mapping.source, value)
	end
end

-- Initialize the player’s upgrade data
function UpgradeService:SetupPlayer(player, profile)
	local upgrades = profile.Data.Upgrades

	-- Send current upgrade levels to client
	for upgradeId, level in upgrades do
		self.Client.UpgradeUpdated:Fire(player, upgradeId, level)
	end

	-- Seed MultiplierService from saved upgrade levels
	for upgradeId in MULTIPLIER_MAP do
		local config = UpgradeConfig[upgradeId]
		if config then
			local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
			local level = (upgradeTable and upgradeTable[upgradeId]) or 0
			self:_UpdateMultiplierIfNeeded(player, upgradeId, level)
		end
	end
end

-- Buy an upgrade
function UpgradeService:BuyUpgrade(player, upgradeId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end

	local config = UpgradeConfig[upgradeId]
	if not config then return end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return end

	local currentLevel = upgradeTable[upgradeId] or 0

	-- Check max level
	if config.MaxLevel and currentLevel >= config.MaxLevel then
		return
	end

	-- Calculate cost of next level
	local cost = config.CostFunc(currentLevel)


	-- Check currency based on config
	local canAfford = false
	if config.Currency == "Awareness" then
		local awareness = self.AwarenessService:GetAwareness(player)
		if awareness >= cost then
			--print("Taking away", cost, "awareness for upgrade", upgradeId)
			self.AwarenessService:RemoveAwareness(player, cost)
			canAfford = true
		end
	elseif config.Currency == "Rebirths" then
		local rebirths = self.RebirthService:GetRebirths(player)
		if rebirths >= cost then
			-- Deduct rebirths (you'll need to add this method to RebirthService)
			self.RebirthService:RemoveRebirths(player, cost)
			canAfford = true
		end

	elseif config.Currency == "Crystals" then
		local crystals = self.CrystalService:GetCrystals(player)
		if crystals >= cost then
			self.CrystalService:RemoveCrystals(player, cost)
			canAfford = true
		end
	elseif config.Currency == "AstralEchoes" then
		local echoes = self.AstralEchoService:GetEchoes(player)
		if echoes >= cost then
			self.AstralEchoService:RemoveEchoes(player, cost)
			canAfford = true
		end
	end

	if not canAfford then
		return
	end

	-- Increment level
	upgradeTable[upgradeId] = currentLevel + 1
    --print("Current level of", upgradeId, "is", upgradeTable[upgradeId])

	self:_UpdateMultiplierIfNeeded(player, upgradeId, upgradeTable[upgradeId])

	-- Fire events
	self.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
	self.Client.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
end

-- Buy max upgrades (buy until you can't afford the next one)
function UpgradeService:BuyMaxUpgrade(player, upgradeId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return end

	local config = UpgradeConfig[upgradeId]
	if not config then return end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return end

	local currentLevel = upgradeTable[upgradeId] or 0
	local totalCost = 0
	local levelsToBuy = 0

	-- Get current currency amount
	local currentCurrency = 0
	if config.Currency == "Awareness" then
		currentCurrency = self.AwarenessService:GetAwareness(player)
	elseif config.Currency == "Rebirths" then
		currentCurrency = self.RebirthService:GetRebirths(player)
	elseif config.Currency == "Crystals" then
		currentCurrency = self.CrystalService:GetCrystals(player)
	elseif config.Currency == "AstralEchoes" then
		currentCurrency = self.AstralEchoService:GetEchoes(player)
	end

	-- Calculate how many levels we can buy
	local MAX_LEVELS_PER_CALL = 10000 -- safety cap against infinite loops
	while levelsToBuy < MAX_LEVELS_PER_CALL do
		-- Check max level
		if config.MaxLevel and currentLevel + levelsToBuy >= config.MaxLevel then
			break
		end

		-- Calculate cost of next level
		local nextLevelCost = config.CostFunc(currentLevel + levelsToBuy)

		-- Guard: zero or negative cost would loop forever
		if nextLevelCost <= 0 then
			break
		end

		-- Check if we can afford it with remaining currency
		if currentCurrency - totalCost < nextLevelCost then
			break
		end

		-- We can afford this level
		totalCost += nextLevelCost
		levelsToBuy += 1
	end

	-- Only proceed if we can buy at least one level
	if levelsToBuy > 0 then
		-- Deduct currency once
		if config.Currency == "Awareness" then
			self.AwarenessService:RemoveAwareness(player, totalCost)
		elseif config.Currency == "Rebirths" then
			self.RebirthService:RemoveRebirths(player, totalCost)
		elseif config.Currency == "Crystals" then
			self.CrystalService:RemoveCrystals(player, totalCost)
		elseif config.Currency == "AstralEchoes" then
			self.AstralEchoService:RemoveEchoes(player, totalCost)
		end

		-- Update level once
		upgradeTable[upgradeId] = currentLevel + levelsToBuy

		self:_UpdateMultiplierIfNeeded(player, upgradeId, upgradeTable[upgradeId])

		-- Fire event once with final level
		self.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
		self.Client.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
		
		--print(`Player {player.Name} bought {levelsToBuy} levels of {upgradeId}. Total cost: {totalCost}`)
	end

	return levelsToBuy
end



-- Helper to get effect of an upgrade
function UpgradeService:GetUpgradeEffect(player, upgradeId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return -1 end

	local config = UpgradeConfig[upgradeId]
	if not config then return 1 end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return 1 end

	local level = upgradeTable[upgradeId] or 0
	return config.EffectPerLevel(level)
end

function UpgradeService:GetNextUpgradeEffect(player, upgradeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return -1 end

    local config = UpgradeConfig[upgradeId]
    if not config then return 1 end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return 1 end

    local level = upgradeTable[upgradeId] or 0
	if config.MaxLevel and level >= config.MaxLevel then
        --print("Reached max level for", upgradeId, "at level", level)
		return config.EffectPerLevel(level) -- Return current effect if at max level
	end

    return config.EffectPerLevel(level + 1)
end

function UpgradeService:GetLevel(player, upgradeId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return 0 end

	local config = UpgradeConfig[upgradeId]
    if not config then return 0 end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return 0 end

	local level = upgradeTable[upgradeId] or 0
	return level
end

-- Optional: Get next level cost
function UpgradeService:GetNextCost(player, upgradeId)
	local profile = self.DataService:GetProfile(player)
	if not profile then return math.huge end

	local config = UpgradeConfig[upgradeId]
	if not config then return math.huge end

	local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
	if not upgradeTable then return math.huge end

	local level = upgradeTable[upgradeId] or 0
	return config.CostFunc(level)
end

function UpgradeService:GetMaxLevel(upgradeId)
    local config = UpgradeConfig[upgradeId]
    if not config then return 0 end
    return config.MaxLevel or math.huge
end

-- Buy one level of an upgrade for free (no currency deducted). Used by Awakening Level 5 auto-buy.
function UpgradeService:AutoBuyUpgradeFree(player, upgradeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    local config = UpgradeConfig[upgradeId]
    if not config then return end

    local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
    if not upgradeTable then return end

    local currentLevel = upgradeTable[upgradeId] or 0
    if config.MaxLevel and currentLevel >= config.MaxLevel then return end

    upgradeTable[upgradeId] = currentLevel + 1
    self:_UpdateMultiplierIfNeeded(player, upgradeId, upgradeTable[upgradeId])
    self.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
    self.Client.UpgradeUpdated:Fire(player, upgradeId, upgradeTable[upgradeId])
end

-- Helper to get the upgrade data table based on category
-- Reset a single upgrade back to level 1 and fire the updated signal
function UpgradeService:ResetUpgrade(player, upgradeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local config = UpgradeConfig[upgradeId]
    if not config then return end
    local upgradeTable = self:_GetUpgradeDataTable(profile, config.Category)
    if not upgradeTable then return end
    upgradeTable[upgradeId] = 1
    self:_UpdateMultiplierIfNeeded(player, upgradeId, 1)
    self.UpgradeUpdated:Fire(player, upgradeId, 1)
    self.Client.UpgradeUpdated:Fire(player, upgradeId, 1)
end

function UpgradeService:_GetUpgradeDataTable(profile, category)
    return profile.Data[category]
end

-- =======================
-- Client functions exposed via Knit
-- =======================

function UpgradeService.Client:BuyUpgrade(player, upgradeId)
    return self.Server:BuyUpgrade(player, upgradeId)
end

function UpgradeService.Client:BuyMaxUpgrade(player, upgradeId)
	return self.Server:BuyMaxUpgrade(player, upgradeId)
end

function UpgradeService.Client:GetNextCost(player, upgradeId)
    return self.Server:GetNextCost(player, upgradeId)
end

function UpgradeService.Client:GetMaxLevel(player, upgradeId)
    return self.Server:GetMaxLevel(upgradeId)
end

function UpgradeService.Client:GetUpgradeEffect(player, upgradeId)
	return self.Server:GetUpgradeEffect(player, upgradeId)
end

function UpgradeService.Client:GetNextUpgradeEffect(player, upgradeId)
    return self.Server:GetNextUpgradeEffect(player, upgradeId)
end

function UpgradeService.Client:GetLevel(player, upgradeId)
    return self.Server:GetLevel(player, upgradeId)
end

return UpgradeService
