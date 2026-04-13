local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local UpgradeTreeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeTreeConfig)

-- Trees whose root node must NOT be auto-unlocked on join.
-- They are unlocked explicitly via UnlockTreeRoot() when the player meets the requirement.
local LOCKED_TREES = {
    Tree2 = true,
}

local UpgradeTreeService = Knit.CreateService {
    Name = "UpgradeTreeService",
    -- Server-side signal: fires (player, treeName, nodeId) after a successful purchase
    NodePurchased = Signal.new(),
    Client = {
        NodeUnlocked = Knit.CreateSignal(),
        TreeInitialized = Knit.CreateSignal(),
        UpdateVisuals = Knit.CreateSignal(),
        UnlockGranted = Knit.CreateSignal(),
        DynamicNodeUpdated = Knit.CreateSignal(), -- (treeName, nodeId, value)
    }
}

function UpgradeTreeService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.AwarenessService = Knit.GetService("AwarenessService")
    self.RebirthService = Knit.GetService("RebirthService")
    self.CrystalService = Knit.GetService("CrystalService")
    self.AstralEchoService = Knit.GetService("AstralEchoService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.LevelService = Knit.GetService("LevelService")

    -- Per-player tables for dynamic reward tracking
    self.DynamicRewards = {} -- [player] = { {treeName, nodeId, reward}, ... }
    self.JoinTimes = {}      -- [player] = os.clock() at profile load

    -- Listen for new players
    self.DataService.ProfileLoaded:Connect(function(player, profile)
        self.JoinTimes[player] = os.clock()
        self:InitializePlayer(player, profile)
    end)

    for player, profile in self.DataService.Profiles do
        self.JoinTimes[player] = os.clock()
        self:InitializePlayer(player, profile)
    end

    -- Save session playtime and clean up dynamic state on leave
    Players.PlayerRemoving:Connect(function(player)
        local profile = self.DataService:GetProfile(player)
        if profile and self.JoinTimes[player] then
            local sessionSeconds = os.clock() - self.JoinTimes[player]
            profile.Data.PlaytimeSeconds = (profile.Data.PlaytimeSeconds or 0) + sessionSeconds
        end
        self.JoinTimes[player] = nil
        self.DynamicRewards[player] = nil
    end)

    -- Update level-based dynamic rewards whenever a player levels up
    self.LevelService.LevelChanged:Connect(function(player)
        self:_UpdateDynamicRewardsForSource(player, "Level")
    end)

    -- Update crystal-based dynamic rewards whenever crystals change
    self.CrystalService.CrystalsChanged:Connect(function(player)
        self:_UpdateDynamicRewardsForSource(player, "CrystalCount")
    end)

    -- Update echo-based dynamic rewards whenever astral echoes change
    self.AstralEchoService.EchoesChanged:Connect(function(player)
        self:_UpdateDynamicRewardsForSource(player, "AstralEchoCount")
    end)

    -- Update rebirth-based dynamic rewards whenever rebirths change
    self.RebirthService.RebirthsChanged:Connect(function(player)
        self:_UpdateDynamicRewardsForSource(player, "RebirthCount")
    end)

    -- Update playtime-based rewards every 60 seconds
    task.spawn(function()
        while true do
            task.wait(60)
            for player in self.DynamicRewards do
                self:_UpdateDynamicRewardsForSource(player, "Playtime")
            end
        end
    end)

    -- Map currency names to get/remove functions
    self.CurrencyHandlers = {
        Awareness = {
            Get = function(player) return self.AwarenessService:GetAwareness(player) end,
            Remove = function(player, amount) return self.AwarenessService:RemoveAwareness(player, amount) end,
        },
        
        Rebirths = {
            Get = function(player) return self.RebirthService:GetRebirths(player) end,
            Remove = function(player, amount) return self.RebirthService:RemoveRebirths(player, amount) end,
        },

        Crystals = {
            Get = function(player) return self.CrystalService:GetCrystals(player) end,
            Remove = function(player, amount) return self.CrystalService:RemoveCrystals(player, amount) end,
        },

        ["Astral Echoes"] = {
            Get = function(player) return self.AstralEchoService:GetEchoes(player) end,
            Remove = function(player, amount) return self.AstralEchoService:RemoveEchoes(player, amount) end,
        },
    }

    -- Setup interactions after all services are started
    self:SetupTreeInteractions()
end

-- Initialize player's upgrade tree data
function UpgradeTreeService:InitializePlayer(player, profile)
    -- Make sure UnlockedNodes exists in profile
    if not profile.Data.UnlockedNodes then
        profile.Data.UnlockedNodes = {}
    end
    if not profile.Data.PurchasedNodes then
        profile.Data.UnlockedNodes = {}
    end

    -- Initialize each tree's nodes if not already present
    for treeName in UpgradeTreeConfig do
        if not profile.Data.UnlockedNodes[treeName] then
            profile.Data.UnlockedNodes[treeName] = {}
        end
        if not profile.Data.PurchasedNodes[treeName] then
            profile.Data.PurchasedNodes[treeName] = {}
        end

        -- Auto-unlock the root node only for trees that don't require a special unlock
        if not LOCKED_TREES[treeName] then
            local rootNodeId = UpgradeTreeConfig[treeName][1].NodeId
            profile.Data.UnlockedNodes[treeName][rootNodeId] = true
        end
    end

    -- Re-apply multiplier rewards for nodes purchased in a previous session
    self:RestoreRewards(player)

    --print(`Initialized upgrade trees for {player.Name}`)

    -- Update visual state of all trees
    self.Client.UpdateVisuals:Fire(player)

    -- Fire to client that trees are ready
    self.Client.TreeInitialized:Fire(player)
end

-- Re-applies Multiplier rewards on login. Unlock rewards are already stored in profile.Data.Unlocks
function UpgradeTreeService:RestoreRewards(player)
    for treeName, nodes in UpgradeTreeConfig do
        for _, nodeConfig in nodes do
            if self:IsNodePurchased(player, treeName, nodeConfig.NodeId) then
                for _, reward in ipairs(nodeConfig.Rewards) do
                    if reward.Type == "Multiplier" then
                        local source = treeName .. "_" .. nodeConfig.NodeId
                        self.MultiplierService:SetSource(player, reward.Stat, source, reward.Value)
                    elseif reward.Type == "Dynamic" then
                        self:SetupDynamicReward(player, treeName, nodeConfig.NodeId, reward)
                    end
                end
            end
        end
    end
end

-- Get node config
function UpgradeTreeService:GetNodeConfig(treeName, nodeId)
    local config = UpgradeTreeConfig[treeName]
    if not config then return nil end
    
    for _, node in config do
        if node.NodeId == nodeId then
            return node
        end
    end
    
    return nil
end

function UpgradeTreeService:IsNodeUnlocked(player, treeName, nodeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end

    if not profile.Data.UnlockedNodes[treeName] then
        return false
    end
    return profile.Data.UnlockedNodes[treeName][nodeId] == true
end

function UpgradeTreeService:IsNodePurchased(player, treeName, nodeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end

    if not profile.Data.PurchasedNodes[treeName] then
        return false
    end
    return profile.Data.PurchasedNodes[treeName][nodeId] == true
end

function UpgradeTreeService:CanAffordNode(player, treeName, nodeId)
    local nodeConfig = self:GetNodeConfig(treeName, nodeId)
    if not nodeConfig or not nodeConfig.Cost then return true end -- no cost = free

    local handler = self.CurrencyHandlers[nodeConfig.Cost.Currency]
    if not handler then
        --warn(`Unknown currency: {nodeConfig.Cost.Currency}`)
        return false
    end

    return handler.Get(player) >= nodeConfig.Cost.Amount
end


-- Check if player can interact with this node (at least one parent is unlocked)
function UpgradeTreeService:CanUnlockNode(player, treeName, nodeId)
    if self:IsNodeUnlocked(player, treeName, nodeId) then
        return false
    end
    
    -- Check if any parent node unlocks this node
    local config = UpgradeTreeConfig[treeName]
    if not config then return false end
    
    for _, parentNode in config do
        -- Check if this parent node unlocks the target node
        for _, unlockedNodeId in ipairs(parentNode.Unlocks) do
            if unlockedNodeId == nodeId then
                -- Found a parent that unlocks this node, check if parent is unlocked
                if self:IsNodeUnlocked(player, treeName, parentNode.NodeId) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Touching a node = attempting to purchase it
function UpgradeTreeService:UnlockNode(player, treeName, nodeId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end

    local nodeConfig = self:GetNodeConfig(treeName, nodeId)
    if not nodeConfig then return false end

    -- Must be visible/available
    if not self:IsNodeUnlocked(player, treeName, nodeId) then
        --warn(`Node {nodeId} is not available yet`)
        return false
    end

    -- Must not already be purchased
    if self:IsNodePurchased(player, treeName, nodeId) then
        --warn(`Node {nodeId} already purchased`)
        return false
    end

    -- Must be able to afford it
    if not self:CanAffordNode(player, treeName, nodeId) then
        --warn(`Player {player.Name} cannot afford node {nodeId}`)
        return false
    end

    -- Deduct cost
    if nodeConfig.Cost then
        local handler = self.CurrencyHandlers[nodeConfig.Cost.Currency]
        if handler then
            handler.Remove(player, nodeConfig.Cost.Amount)
        end
    end

    -- Mark as purchased
    profile.Data.PurchasedNodes[treeName][nodeId] = true

    -- Grant rewards
    for _, reward in ipairs(nodeConfig.Rewards) do
        self:GrantReward(player, treeName, nodeId, reward)
    end

    -- Unlock children (make them visible)
    for _, childNodeId in ipairs(nodeConfig.Unlocks) do
        profile.Data.UnlockedNodes[treeName][childNodeId] = true
    end

    self.Client.NodeUnlocked:Fire(player, treeName, nodeId, nodeConfig.Rewards)
    self.Client.UpdateVisuals:Fire(player)
    self.NodePurchased:Fire(player, treeName, nodeId)

    print(`Player {player.Name} purchased node {nodeId} in tree {treeName}`)
    return true
end

function UpgradeTreeService:GrantReward(player, treeName, nodeId, reward)
    if reward.Type == "Unlock" then
        self.UnlockService:Unlock(player, reward.Value)
        self.Client.UnlockGranted:Fire(player, reward.Value)
    elseif reward.Type == "Multiplier" then
        local source = treeName .. "_" .. nodeId
        self.MultiplierService:SetSource(player, reward.Stat, source, reward.Value)
    elseif reward.Type == "Dynamic" then
        self:SetupDynamicReward(player, treeName, nodeId, reward)
    end
end

-- Compute the current multiplier value for a given dynamic source
function UpgradeTreeService:ComputeDynamicValue(player, source)
    if source == "Playtime" then
        local profile = self.DataService:GetProfile(player)
        if not profile then return 1 end
        local storedSeconds = profile.Data.PlaytimeSeconds or 0
        local sessionSeconds = os.clock() - (self.JoinTimes[player] or os.clock())
        local totalHours = (storedSeconds + sessionSeconds) / 3600
        -- formula: 1 + sqrt(hours / 7)  →  at 32.5h gives ~3.15x
        return 1 + math.sqrt(math.max(0, totalHours / 7))

    elseif source == "Level" then
        -- multiplier = current level directly  →  level 41 gives 41x
        return math.max(1, self.LevelService:GetLevel(player))

    elseif source == "CrystalCount" then
        local crystals = self.CrystalService:GetCrystals(player)
        -- formula: 1 + log10(1 + crystals) * 1.4  →  at 100B gives ~16x
        return 1 + math.log(1 + crystals, 10) * 1.4

    elseif source == "RebirthCount" then
        local rebirths = self.RebirthService:GetRebirths(player)
        -- formula: 1 + log10(1 + rebirths) * 1.4
        return 1 + math.log(1 + rebirths, 10) * 1.4

    elseif source == "AstralEchoCount" then
        local echoes = self.AstralEchoService:GetEchoes(player)
        -- formula: 1 + log10(1 + echoes) * 1.4
        return 1 + math.log(1 + echoes, 10) * 1.4
    end

    return 1
end

-- Register a dynamic reward and apply it immediately
function UpgradeTreeService:SetupDynamicReward(player, treeName, nodeId, reward)
    if not self.DynamicRewards[player] then
        self.DynamicRewards[player] = {}
    end
    -- Avoid duplicate registrations (e.g. RestoreRewards called twice)
    for _, entry in self.DynamicRewards[player] do
        if entry.treeName == treeName and entry.nodeId == nodeId and entry.reward.Source == reward.Source then
            return
        end
    end
    table.insert(self.DynamicRewards[player], { treeName = treeName, nodeId = nodeId, reward = reward })
    self:_ApplyDynamicReward(player, treeName, nodeId, reward)
end

-- Compute current value and push it to MultiplierService + notify client
function UpgradeTreeService:_ApplyDynamicReward(player, treeName, nodeId, reward)
    local value = self:ComputeDynamicValue(player, reward.Source)
    local source = treeName .. "_" .. nodeId
    self.MultiplierService:SetSource(player, reward.Stat, source, value)
    self.Client.DynamicNodeUpdated:Fire(player, treeName, nodeId, value)
end

-- Re-compute all dynamic rewards matching a given source for one player
function UpgradeTreeService:_UpdateDynamicRewardsForSource(player, source)
    local rewards = self.DynamicRewards[player]
    if not rewards then return end
    for _, entry in rewards do
        if entry.reward.Source == source then
            self:_ApplyDynamicReward(player, entry.treeName, entry.nodeId, entry.reward)
        end
    end
end

-- Return all current dynamic values for the player (keyed by "treeName_nodeId")
function UpgradeTreeService:GetAllDynamicValues(player)
    local result = {}
    local rewards = self.DynamicRewards[player]
    if rewards then
        for _, entry in rewards do
            local key = entry.treeName .. "_" .. entry.nodeId
            result[key] = self:ComputeDynamicValue(player, entry.reward.Source)
        end
    end
    return result
end

-- Setup touch events for nodes
function UpgradeTreeService:SetupTreeInteractions()
    for treeName, _ in UpgradeTreeConfig do
        local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
        if not treeFolder then
            warn(`Tree folder {treeName} not found in workspace.UpgradeTrees`)
            continue
        end
        
        for _, nodeModel in treeFolder:GetChildren() do
            if not nodeModel:IsA("Model") or nodeModel.Name == "Link" then continue end

            local touchPart = nodeModel:FindFirstChild("TouchPart")
            if touchPart then
                touchPart.Touched:Connect(function(hit)
                    local character = hit.Parent
                    local player = game.Players:GetPlayerFromCharacter(character)
                    
                    if player then
                        self:UnlockNode(player, treeName, nodeModel.Name)
                    end
                end)
            end
        end
    end
end

function UpgradeTreeService:GetAllNodeStates(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return { unlocked = {}, purchased = {} } end
    return {
        unlocked = profile.Data.UnlockedNodes or {},
        purchased = profile.Data.PurchasedNodes or {},
    }
end

-- Called by UnlockService when a locked tree is unlocked (e.g. Tree2 via Awakening Level 1).
-- Unlocks the root node, re-restores all purchased rewards, and refreshes client visuals.
function UpgradeTreeService:UnlockTreeRoot(player, treeName)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    local treeConfig = UpgradeTreeConfig[treeName]
    if not treeConfig or #treeConfig == 0 then return end

    if not profile.Data.UnlockedNodes[treeName] then
        profile.Data.UnlockedNodes[treeName] = {}
    end
    if not profile.Data.PurchasedNodes[treeName] then
        profile.Data.PurchasedNodes[treeName] = {}
    end

    local rootNodeId = treeConfig[1].NodeId
    profile.Data.UnlockedNodes[treeName][rootNodeId] = true

    self:RestoreRewards(player)
    self.Client.UpdateVisuals:Fire(player)
end

-- Wipes all purchased and unlocked nodes for a tree, removes their multiplier sources,
-- and refreshes client visuals. Called on awakening so the player must re-buy the tree.
function UpgradeTreeService:ResetTree(player, treeName)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    local treeConfig = UpgradeTreeConfig[treeName]
    if not treeConfig then return end

    -- Remove multiplier sources for every purchased node before wiping
    for _, nodeConfig in treeConfig do
        if self:IsNodePurchased(player, treeName, nodeConfig.NodeId) then
            for _, reward in ipairs(nodeConfig.Rewards) do
                if reward.Type == "Multiplier" then
                    local source = treeName .. "_" .. nodeConfig.NodeId
                    self.MultiplierService:SetSource(player, reward.Stat, source, 1)
                end
            end
        end
    end

    -- Clear all node state for this tree
    profile.Data.PurchasedNodes[treeName] = {}
    profile.Data.UnlockedNodes[treeName] = {}

    self.Client.UpdateVisuals:Fire(player)
end

-- Client-facing methods
function UpgradeTreeService.Client:IsNodeUnlocked(player, treeName, nodeId)
    return self.Server:IsNodeUnlocked(player, treeName, nodeId)
end

function UpgradeTreeService.Client:IsNodePurchased(player, treeName, nodeId)
    return self.Server:IsNodePurchased(player, treeName, nodeId)
end

function UpgradeTreeService.Client:CanUnlockNode(player, treeName, nodeId)
    return self.Server:CanUnlockNode(player, treeName, nodeId)
end

function UpgradeTreeService.Client:GetAllNodeStates(player)
    return self.Server:GetAllNodeStates(player)
end

function UpgradeTreeService.Client:GetAllDynamicValues(player)
    return self.Server:GetAllDynamicValues(player)
end

return UpgradeTreeService