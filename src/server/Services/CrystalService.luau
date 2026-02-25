local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CrystalService = Knit.CreateService {
    Name = "CrystalService",
    Client = {
        StartCrystals = Knit.CreateSignal(), -- server tells client to start spawning
        CollectCrystal = Knit.CreateSignal(), -- client tells server it collected one
        CrystalsChanged = Knit.CreateSignal(),
    }
}

CrystalService.CrystalsChanged = Signal.new()

function CrystalService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")

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
end

function CrystalService:GetCrystals(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.Crystals or 0
end

function CrystalService:AddCrystals(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.Crystals = (profile.Data.Crystals or 0) + amount

    self.CrystalsChanged:Fire(player, profile.Data.Crystals)
end

function CrystalService:RemoveCrystals(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.Crystals = math.max(0, (profile.Data.Crystals or 0) - amount)

    self.CrystalsChanged:Fire(player, profile.Data.Crystals)
end

function CrystalService:OnCrystalCollected(player)
    if not self.UnlockService:IsUnlocked(player, "CrystalCollection") then return end

    local value = self.UpgradeService:GetUpgradeEffect(player, "CrystalValue")
    local multiplier= self.UpgradeService:GetUpgradeEffect(player, "CrystalMultiplier")

    local finalValue = math.round(value * multiplier)

    self:AddCrystals(player, finalValue)
end

function CrystalService:StartCrystals(player)
    self.Client.StartCrystals:Fire(player)
end

-- Client functions

function CrystalService.Client:GetCrystals(player)
    return self.Server:GetCrystals(player)
end

return CrystalService