local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local UpgradeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeConfig)

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
	Client = {
		UpgradeUpdated = Knit.CreateSignal(), -- fires when level changes (for UI)
	},
})

UpgradeService.DataService = nil
UpgradeService.AwarenessService = nil
UpgradeService.RebirthService = nil

function UpgradeService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.AwarenessService = Knit.GetService("AwarenessService")
	self.RebirthService = Knit.GetService("RebirthService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if not profile then return end
        self:SetupPlayer(player, profile)
    end)

	for player, profile in self.DataService.Profiles do
        self:SetupPlayer(player, profile)
    end
end

-- Initialize the player’s upgrade data
function UpgradeService:SetupPlayer(player, profile)
	local upgrades = profile.Data.Upgrades

	-- Send current upgrade levels to client
	for upgradeId, level in upgrades do
		self.Client.UpgradeUpdated:Fire(player, upgradeId, level)
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
    --print("Cost to upgrade", upgradeId, "from level", currentLevel, "to level", currentLevel + 1, "is", cost)


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
	end

	if not canAfford then
		--print("Not enough", config.Currency, "! Needed:", cost)
		return
	end

	-- Increment level
	upgradeTable[upgradeId] = currentLevel + 1
    --print("Current level of", upgradeId, "is", upgradeTable[upgradeId])

	-- Fire events
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
	end

	-- Calculate how many levels we can buy
	while true do
		-- Check max level
		if config.MaxLevel and currentLevel + levelsToBuy >= config.MaxLevel then
			break
		end

		-- Calculate cost of next level
		local nextLevelCost = config.CostFunc(currentLevel + levelsToBuy)

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
		end

		-- Update level once
		upgradeTable[upgradeId] = currentLevel + levelsToBuy
		
		-- Fire event once with final level
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

-- Helper to get the upgrade data table based on category
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
