local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local CrystalService = Knit.CreateService {
    Name = "CrystalService",
    Client = {
        StartCrystals = Knit.CreateSignal(),      -- server tells client to start spawning
        CollectCrystal = Knit.CreateSignal(),     -- client tells server it collected one
        CrystalsChanged = Knit.CreateSignal(),
        CrystalsTotalChanged = Knit.CreateSignal(),
    }
}

CrystalService.CrystalsChanged = Signal.new()
CrystalService.CrystalsTotalChanged = Signal.new()
CrystalService.CrystalCollected = Signal.new() -- (player, amount) fires on each collect

local LevelService

function CrystalService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.CrystalComboService = Knit.GetService("CrystalComboService")

    LevelService = Knit.GetService("LevelService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if self.UnlockService:IsUnlocked(player, "CrystalCollection") then
            self.Client.StartCrystals:Fire(player)
        end
    end)

    for player, profile in self.DataService.Profiles do
        if self.UnlockService:IsUnlocked(player, "CrystalCollection") then
            self.Client.StartCrystals:Fire(player)
        end
    end

    self.Client.CollectCrystal:Connect(function(player)
        self:OnCrystalCollected(player)
    end)

    self.CrystalsChanged:Connect(function(player, crystals)
        self.Client.CrystalsChanged:Fire(player, crystals)
    end)

    self.CrystalsTotalChanged:Connect(function(player, total)
        self.Client.CrystalsTotalChanged:Fire(player, total)
    end)
end

function CrystalService:GetCrystals(player)
    return self.DataService:GetQN(player, "Crystals")
end

function CrystalService:AddCrystals(player, amount)
    local newCrystals = self.DataService:AddQN(player, "Crystals", amount)
    local newTotal    = self.DataService:AddQN(player, "CrystalsTotal", amount)
    self.CrystalsChanged:Fire(player, newCrystals)
    self.CrystalsTotalChanged:Fire(player, newTotal)
end

function CrystalService:RemoveCrystals(player, amount)
    local current = self.DataService:GetQN(player, "Crystals")
    local newCrystals = num.isPositive(num.sub(current, amount))
        and num.sub(current, amount)
        or num.fromNumber(0)
    self.DataService:SetQN(player, "Crystals", newCrystals)
    self.CrystalsChanged:Fire(player, newCrystals)
end

function CrystalService:ResetCrystals(player)
    local zero = num.fromNumber(0)
    self.DataService:SetQN(player, "Crystals", zero)
    self.CrystalsChanged:Fire(player, zero)
end

function CrystalService:OnCrystalCollected(player)
    if not self.UnlockService:IsUnlocked(player, "CrystalCollection") then return end

    local value = self.UpgradeService:GetUpgradeEffect(player, "CrystalValue")
    local upgradeMultiplier = self.UpgradeService:GetUpgradeEffect(player, "CrystalMultiplier")
    local treeMultiplier = self.MultiplierService:GetMultiplier(player, "CrystalValue")
    local comboMultiplier = self.CrystalComboService:ApplyAndGetCombo(player)

    local finalValue = num.mul(num.fromNumber(value * upgradeMultiplier * comboMultiplier), treeMultiplier)

    self:AddCrystals(player, finalValue)
    LevelService:AddXP(player, 1)
    self.CrystalCollected:Fire(player, finalValue)
end

function CrystalService:StartCrystals(player)
    self.Client.StartCrystals:Fire(player)
end

-- Client functions

function CrystalService.Client:GetCrystals(player)
    return self.Server:GetCrystals(player)
end

return CrystalService