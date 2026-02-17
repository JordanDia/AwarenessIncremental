local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CrystalService = Knit.CreateService {
    Name = "CrystalService",
    Client = {
        StartCrystals = Knit.CreateSignal(), -- server tells client to start spawning
        CollectCrystal = Knit.CreateSignal(), -- client tells server it collected one
    }
}

function CrystalService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")


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
end

function CrystalService:RemoveCrystals(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.Crystals = math.max(0, (profile.Data.Crystals or 0) - amount)
end

function CrystalService:OnCrystalCollected(player)
    if not self.UnlockService:IsUnlocked(player, "CrystalCollection") then return end
    self:AddCrystals(player, 1)
end

return CrystalService