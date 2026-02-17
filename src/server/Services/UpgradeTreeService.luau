local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local UpgradeTreeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeTreeConfig)

local UpgradeTreeService = Knit.CreateService {
    Name = "UpgradeTreeService",
    Client = {
        NodeUnlocked = Knit.CreateSignal(),
        TreeInitialized = Knit.CreateSignal(),
        UpdateVisuals = Knit.CreateSignal(),
        UnlockGranted = Knit.CreateSignal(),
    }
}

function UpgradeTreeService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.AwarenessService = Knit.GetService("AwarenessService")
    self.RebirthService = Knit.GetService("RebirthService")
    self.UnlockService = Knit.GetService("UnlockService")
    
    -- Listen for new players
    self.DataService.ProfileLoaded:Connect(function(player, profile)
        self:InitializePlayer(player, profile)
    end)

    for player, profile in self.DataService.Profiles do
        self:InitializePlayer(player, profile)
    end

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

        -- Crystals = {
        --     Get = function(player) return self.CrystalService:GetCrystals(player) end,
        --     Remove = function(player, amount) return self.CrystalService:RemoveCrystals(player, amount) end,
        -- },
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
    for treeName, nodes in pairs(UpgradeTreeConfig) do
        if not profile.Data.UnlockedNodes[treeName] then
            profile.Data.UnlockedNodes[treeName] = {}
        end
        if not profile.Data.PurchasedNodes[treeName] then
            profile.Data.PurchasedNodes[treeName] = {}
        end
        
        -- Always unlock RootNode by default
        profile.Data.UnlockedNodes[treeName]["RootNode"] = true
    end
    
    --print(`Initialized upgrade trees for {player.Name}`)
    
    -- Update visual state of all trees
    self.Client.UpdateVisuals:Fire(player)
    
    -- Fire to client that trees are ready
    self.Client.TreeInitialized:Fire(player)
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
        warn(`Unknown currency: {nodeConfig.Cost.Currency}`)
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
        warn(`Node {nodeId} is not available yet`)
        return false
    end

    -- Must not already be purchased
    if self:IsNodePurchased(player, treeName, nodeId) then
        warn(`Node {nodeId} already purchased`)
        return false
    end

    -- Must be able to afford it
    if not self:CanAffordNode(player, treeName, nodeId) then
        warn(`Player {player.Name} cannot afford node {nodeId}`)
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
        self:GrantReward(player, reward)
    end

    -- Unlock children (make them visible)
    for _, childNodeId in ipairs(nodeConfig.Unlocks) do
        profile.Data.UnlockedNodes[treeName][childNodeId] = true
    end

    self.Client.NodeUnlocked:Fire(player, treeName, nodeId, nodeConfig.Rewards)
    self.Client.UpdateVisuals:Fire(player)

    print(`Player {player.Name} purchased node {nodeId} in tree {treeName}`)
    return true
end

function UpgradeTreeService:GrantReward(player, reward)
    if reward == "Crystals" then
        self.UnlockService:Unlock(player, "CrystalCollection")
        -- Fire to client so it can start spawning immediately without waiting for rejoin
        self.Client.UnlockGranted:Fire(player, "CrystalCollection")
    end
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

return UpgradeTreeService