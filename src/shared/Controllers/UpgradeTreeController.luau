local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact
local UpgradeTreeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeTreeConfig)
local UpgradeTreeFrame = require(ReplicatedStorage.UI.components.UpgradeTreeFrame)

local scope = Fusion:scoped()

local CURRENCY_COLORS = {
    Awareness    = Color3.fromRGB(50,  120, 220),
    Rebirths     = Color3.fromRGB(130, 50,  220),
    Crystals     = Color3.fromRGB(220, 185, 30),
    ["Astral Echoes"] = Color3.fromRGB(0,   200, 160),
}

local UpgradeTreeController = Knit.CreateController {
    Name = "UpgradeTreeController"
}

function UpgradeTreeController:KnitStart()
    self.UpgradeTreeService = Knit.GetService("UpgradeTreeService")
    -- Local cache of unlocked/purchased state — avoids per-node remote calls on each visual refresh
    self.NodeState = { unlocked = {}, purchased = {} }
    -- Reactive cost Values keyed by "treeName_nodeId" — allows flipping text to "Purchased"
    self.NodeCostValues = {}
    -- Latest computed dynamic multiplier values keyed by "treeName_nodeId"
    self.NodeDynamicValues = {}

    -- Full refresh: re-fetch state from server then update visuals
    self.UpgradeTreeService.UpdateVisuals:Connect(function()
        self:FetchAndRefresh()
    end)

    -- Trees are ready: build GUIs then fetch initial state
    self.UpgradeTreeService.TreeInitialized:Connect(function()
        self:SetupNodeGuis()
        self:FetchAndRefresh()
    end)

    -- Node purchased: update local state immediately (no server round-trip)
    self.UpgradeTreeService.NodeUnlocked:Connect(function(treeName, nodeId)
        self:ApplyLocalPurchase(treeName, nodeId)
    end)

    -- Server pushes updated dynamic multiplier values (live updates)
    self.UpgradeTreeService.DynamicNodeUpdated:Connect(function(treeName, nodeId, value)
        local key = treeName .. "_" .. nodeId
        self.NodeDynamicValues[key] = value
        local costValue = self.NodeCostValues[key]
        if costValue then
            costValue:set("Current: " .. FormatNumber(value, ".##") .. "x")
        end
    end)

    self:SetupNodeGuis()
end

-- Fetch full unlocked/purchased + current dynamic values from server, then refresh visuals
function UpgradeTreeController:FetchAndRefresh()
    local state = self.UpgradeTreeService:GetAllNodeStates()
    self.NodeState.unlocked = state.unlocked or {}
    self.NodeState.purchased = state.purchased or {}

    local dynamicValues = self.UpgradeTreeService:GetAllDynamicValues()
    for key, value in dynamicValues do
        self.NodeDynamicValues[key] = value
    end

    self:UpdateTreeVisuals()
end

-- Apply a purchase locally from config so visuals update instantly
function UpgradeTreeController:ApplyLocalPurchase(treeName, nodeId)
    if not self.NodeState.purchased[treeName] then
        self.NodeState.purchased[treeName] = {}
    end
    if not self.NodeState.unlocked[treeName] then
        self.NodeState.unlocked[treeName] = {}
    end

    self.NodeState.purchased[treeName][nodeId] = true

    -- Mark children as unlocked using local config (no server call)
    for _, nodeConfig in UpgradeTreeConfig[treeName] do
        if nodeConfig.NodeId == nodeId then
            for _, childId in nodeConfig.Unlocks do
                self.NodeState.unlocked[treeName][childId] = true
            end
            break
        end
    end

    self:UpdateTreeVisuals()
end

function UpgradeTreeController:_GetNodeConfig(treeName, nodeId)
    local tree = UpgradeTreeConfig[treeName]
    if not tree then return nil end
    for _, nodeConfig in tree do
        if nodeConfig.NodeId == nodeId then return nodeConfig end
    end
    return nil
end

function UpgradeTreeController:CreateNodeGui(treeName, touchPart, nodeConfig)
    local existing = touchPart:FindFirstChild("NodeGui")
    if existing then
        existing:Destroy()
    end

    local surfaceGui = scope:New "SurfaceGui" {
        Name = "NodeGui",
        Face = Enum.NormalId.Top,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 50,
        Parent = touchPart,
        Enabled = false,
    }

    local costText = nodeConfig.Cost and string.format("%s %s",
        FormatNumber(nodeConfig.Cost.Amount),
        nodeConfig.Cost.Currency
    ) or "Free"

    local costValue = scope:Value(costText)
    self.NodeCostValues[treeName .. "_" .. nodeConfig.NodeId] = costValue

    scope:Hydrate(surfaceGui) {
        [Fusion.Children] = {
            UpgradeTreeFrame(scope, {
                Title = nodeConfig.Title,
                UpgradeName = nodeConfig.UpgradeName,
                Cost = costValue,
            })
        }
    }
end

function UpgradeTreeController:SetupNodeGuis()
    for treeName, nodes in UpgradeTreeConfig do
        local treeFolder = workspace.UpgradeTrees:WaitForChild(treeName)
        if not treeFolder then continue end

        for _, nodeConfig in nodes do
            local nodeModel = treeFolder:WaitForChild(nodeConfig.NodeId)
            if not nodeModel then continue end

            local touchPart = nodeModel:WaitForChild("TouchPart")
            if not touchPart then continue end

            local currency = nodeConfig.Cost and nodeConfig.Cost.Currency
            local color = currency and CURRENCY_COLORS[currency]
            if color then
                touchPart.Color = color

                -- Color the link whose number matches this node's suffix (e.g. "2-1" -> Link1)
                local linkNumber = nodeConfig.NodeId:match("%-(%d+)$")
                if linkNumber then
                    local linkPart = treeFolder:FindFirstChild("Link" .. linkNumber)
                    if linkPart and linkPart:IsA("BasePart") then
                        linkPart.Color = color
                    end
                end
            end

            self:CreateNodeGui(treeName, touchPart, nodeConfig)
        end
    end
end

-- Update a single node's visual state using local cached NodeState (no remote calls)
function UpgradeTreeController:UpdateNodeVisual(treeName, nodeId)
    local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
    if not treeFolder then return end

    local nodeModel = treeFolder:FindFirstChild(nodeId)
    if not nodeModel then return end

    local unlockedMap = self.NodeState.unlocked[treeName]
    local purchasedMap = self.NodeState.purchased[treeName]
    local isUnlocked = unlockedMap and unlockedMap[nodeId] == true
    local isPurchased = purchasedMap and purchasedMap[nodeId] == true

    for _, nodePart in nodeModel:GetDescendants() do
        if nodePart:IsA("BasePart") then
            nodePart.Transparency = isUnlocked and 0 or 1
            nodePart.CanCollide = isUnlocked
        end
    end

    local touchPart = nodeModel:FindFirstChild("TouchPart")
    if touchPart then
        local surfaceGui = touchPart:FindFirstChild("NodeGui")
        if surfaceGui then
            surfaceGui.Enabled = isUnlocked
        end
    end

    if isUnlocked then
        local key = treeName .. "_" .. nodeId
        local costValue = self.NodeCostValues[key]
        if costValue and isPurchased then
            local dynamicValue = self.NodeDynamicValues[key]
            if dynamicValue then
                costValue:set("Current: " .. FormatNumber(dynamicValue, ".##") .. "x")
            else
                costValue:set("Purchased!")
            end
        elseif costValue and not isPurchased then
            -- Reset cost text back to original after a tree reset
            local nodeConfig = self:_GetNodeConfig(treeName, nodeId)
            if nodeConfig and nodeConfig.Cost then
                costValue:set(string.format("%s %s",
                    FormatNumber(nodeConfig.Cost.Amount),
                    nodeConfig.Cost.Currency
                ))
            end
        end
    end
end

-- Full tree visual update using local NodeState (no remote calls)
function UpgradeTreeController:UpdateTreeVisuals()
    for treeName, config in pairs(UpgradeTreeConfig) do
        local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
        if not treeFolder then continue end

        local unlockedMap = self.NodeState.unlocked[treeName] or {}

        -- A link is visible when its destination node is unlocked.
        -- Link number matches the node number: node "1-9" -> Link9
        local visibleLinks = {}
        for _, nodeConfig in ipairs(config) do
            if unlockedMap[nodeConfig.NodeId] then
                local linkNumber = tonumber(nodeConfig.NodeId:match("%-(%d+)$"))
                if linkNumber then
                    visibleLinks[linkNumber] = true
                end
            end
        end

        for _, linkPart in treeFolder:GetChildren() do
            if linkPart:IsA("BasePart") and linkPart.Name:match("^Link%d+$") then
                local linkNumber = tonumber(linkPart.Name:match("%d+"))
                linkPart.Transparency = visibleLinks[linkNumber] and 0 or 1
                linkPart.CanCollide = false
            end
        end

        for _, nodeModel in treeFolder:GetChildren() do
            if not nodeModel:IsA("Model") then continue end
            self:UpdateNodeVisual(treeName, nodeModel.Name)
        end
    end
end

return UpgradeTreeController
