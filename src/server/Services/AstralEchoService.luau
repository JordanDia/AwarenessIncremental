local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local AstralEchoService = Knit.CreateService {
    Name = "AstralEchoService",
    Client = {
        StartEchoes = Knit.CreateSignal(),    -- server tells client to start spawning
        StopEchoes = Knit.CreateSignal(),
        CollectEcho = Knit.CreateSignal(),    -- client tells server it collected one
        EchoesChanged = Knit.CreateSignal(),  -- server tells client updated echo count
    }
}

AstralEchoService.EchoesChanged = Signal.new()

function AstralEchoService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        if self.UnlockService:IsUnlocked(player, "AstralEchoCollection") then
            self.Client.StartEchoes:Fire(player)
        end

    end)

    for player, profile in self.DataService.Profiles do
        if self.UnlockService:IsUnlocked(player, "AstralEchoCollection") then
            self.Client.StartEchoes:Fire(player)
            AstralEchoService:StartEchoes(player)
        end
    end

    self.Client.CollectEcho:Connect(function(player)
        self:OnEchoCollected(player)
    end)

    self.EchoesChanged:Connect(function(player, echoes)
        self.Client.EchoesChanged:Fire(player, echoes)
    end)

    
end

function AstralEchoService:GetEchoes(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.AstralEchoes or 0
end

function AstralEchoService:AddEchoes(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.AstralEchoes = (profile.Data.AstralEchoes or 0) + amount

    self.EchoesChanged:Fire(player, profile.Data.AstralEchoes)
end

function AstralEchoService:RemoveEchoes(player, amount)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    profile.Data.AstralEchoes = math.max(0, (profile.Data.AstralEchoes or 0) - amount)

    self.EchoesChanged:Fire(player, profile.Data.AstralEchoes)
end

function AstralEchoService:OnEchoCollected(player)
    if not self.UnlockService:IsUnlocked(player, "AstralEchoCollection") then return end

    local value = self.UpgradeService:GetUpgradeEffect(player, "AstralEchoValue")
    local multiplier = self.UpgradeService:GetUpgradeEffect(player, "AstralEchoMultiplier")

    local finalValue = math.round(value * multiplier)

    self:AddEchoes(player, finalValue)
end

function AstralEchoService:StartEchoes(player)
    self.Client.StartEchoes:Fire(player)
end

function AstralEchoService:StopEchoes(player)
    self.Client.StopEchoes:Fire(player)
end

-- Client functions

function AstralEchoService.Client:GetEchoes(player)
    return self.Server:GetEchoes(player)
end

return AstralEchoService
