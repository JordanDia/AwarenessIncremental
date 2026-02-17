local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact
local UpgradeTreeConfig = require(ReplicatedStorage.Shared.Configs.UpgradeTreeConfig)
local UpgradeTreeFrame = require(ReplicatedStorage.UI.components.UpgradeTreeFrame)

local scope = Fusion:scoped()

local UpgradeTreeController = Knit.CreateController {
    Name = "UpgradeTreeController" 
}

UpgradeTreeController.UpgradeTreeService = nil


function UpgradeTreeController:KnitStart()
    self.UpgradeTreeService = Knit.GetService("UpgradeTreeService")

    -- Server tells us to refresh visuals (on init and after unlocks)
    self.UpgradeTreeService.UpdateVisuals:Connect(function()
        self:UpdateTreeVisuals()
    end)

    -- Setup SurfaceGuis once trees are ready
    self.UpgradeTreeService.TreeInitialized:Connect(function()
        self:SetupNodeGuis()
    end)

    self:SetupNodeGuis()
end

function UpgradeTreeController:CreateNodeGui(touchPart, nodeConfig)
    local existing = touchPart:FindFirstChild("NodeGui")
    if existing then existing:Destroy() end

    local surfaceGui = scope:New "SurfaceGui" {
        Name = "NodeGui",
        Face = Enum.NormalId.Top,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 50,
        Parent = touchPart,
        Enabled = false
    }

    local costText = string.format("%s %s",
        FormatNumber(nodeConfig.Cost.Amount),
        nodeConfig.Cost.Currency
    )

    scope:Hydrate(surfaceGui) {
        [Fusion.Children] = {
            UpgradeTreeFrame(scope, {
                Title = nodeConfig.Title,
                UpgradeName = nodeConfig.UpgradeName,
                Cost = costText,
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

            self:CreateNodeGui(touchPart, nodeConfig)
        end
    end
end

-- Hide all links in a tree
function UpgradeTreeController:HideAllLinks(treeName)
    local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
    if not treeFolder then return end

    for _, linkPart in treeFolder:GetChildren() do
        if linkPart:IsA("BasePart") and linkPart.Name:match("^Link%d+$") then
            linkPart.Transparency = 1
            linkPart.CanCollide = false
        end
    end
end

-- Update a single link
function UpgradeTreeController:UpdateLinkVisual(treeName, linkNumber)
    local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
    if not treeFolder then return end

    local linkPart = treeFolder:FindFirstChild("Link" .. linkNumber)
    if not linkPart then return end

    linkPart.Transparency = 0
    linkPart.CanCollide = false
end

-- Update a single node's visual state
function UpgradeTreeController:UpdateNodeVisual(treeName, nodeId)
    local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
    if not treeFolder then return end

    local nodeModel = treeFolder:FindFirstChild(nodeId)
    if not nodeModel then return end

    local isUnlocked = self.UpgradeTreeService:IsNodeUnlocked(treeName, nodeId)

    for _, nodePart in nodeModel:GetDescendants() do
        if nodePart:IsA("BasePart") then
            nodePart.Transparency = isUnlocked and 0 or 1
            nodePart.CanCollide = isUnlocked
        end
    end

    if isUnlocked then
        local surfaceGui = nodeModel:WaitForChild("TouchPart"):WaitForChild("NodeGui")
        surfaceGui.Enabled = true
    end
end

-- Full tree visual update
function UpgradeTreeController:UpdateTreeVisuals()
    for treeName, config in pairs(UpgradeTreeConfig) do
        local treeFolder = workspace.UpgradeTrees:FindFirstChild(treeName)
        if not treeFolder then continue end

        -- Build set of links that should be visible
        local visibleLinks = {}
        for _, nodeConfig in ipairs(config) do
            if self.UpgradeTreeService:IsNodeUnlocked(treeName, nodeConfig.NodeId) and nodeConfig.UnlockLinks then
                for _, linkNumber in ipairs(nodeConfig.UnlockLinks) do
                    visibleLinks[linkNumber] = true
                end
            end
        end

        -- Set all links in one pass, no hide-then-show
        for _, linkPart in treeFolder:GetChildren() do
            if linkPart:IsA("BasePart") and linkPart.Name:match("^Link%d+$") then
                local linkNumber = tonumber(linkPart.Name:match("%d+"))
                linkPart.Transparency = visibleLinks[linkNumber] and 0 or 1
                linkPart.CanCollide = false
            end
        end

        -- Update node visuals
        for _, nodeModel in treeFolder:GetChildren() do
            if not nodeModel:IsA("Model") then continue end
            self:UpdateNodeVisual(treeName, nodeModel.Name)
        end
    end
end


return UpgradeTreeController