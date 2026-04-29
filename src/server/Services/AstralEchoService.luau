local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local AstralEchoService = Knit.CreateService {
    Name = "AstralEchoService",
    Client = {
        StartEchoes = Knit.CreateSignal(),        -- server tells client to start spawning
        StopEchoes = Knit.CreateSignal(),
        CollectEcho = Knit.CreateSignal(),        -- client tells server it collected one
        EchoesChanged = Knit.CreateSignal(),      -- server tells client updated echo count
        EchoesTotalChanged = Knit.CreateSignal(), -- server tells client updated lifetime total
    }
}

AstralEchoService.EchoesChanged = Signal.new()
AstralEchoService.EchoesTotalChanged = Signal.new()

function AstralEchoService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.UpgradeService = Knit.GetService("UpgradeService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.LevelService = Knit.GetService("LevelService")

    self.DataService.ProfileLoaded:Connect(function(player, profile)
        -- if self.UnlockService:IsUnlocked(player, "AstralEchoCollection") then
        --     self.Client.StartEchoes:Fire(player)
        -- end

    end)

    for player, profile in self.DataService.Profiles do
        -- if self.UnlockService:IsUnlocked(player, "AstralEchoCollection") then
        --     self.Client.StartEchoes:Fire(player)
        --     AstralEchoService:StartEchoes(player)
        -- end
    end

    self.Client.CollectEcho:Connect(function(player)
        self:OnEchoCollected(player)
    end)

    self.EchoesChanged:Connect(function(player, echoes)
        self.Client.EchoesChanged:Fire(player, echoes)
    end)

    self.EchoesTotalChanged:Connect(function(player, total)
        self.Client.EchoesTotalChanged:Fire(player, total)
    end)

    
end

function AstralEchoService:GetEchoes(player)
    return self.DataService:GetQN(player, "AstralEchoes")
end

function AstralEchoService:AddEchoes(player, amount)
    local newEchoes = self.DataService:AddQN(player, "AstralEchoes", amount)
    local newTotal  = self.DataService:AddQN(player, "AstralEchoesTotal", amount)
    self.EchoesChanged:Fire(player, newEchoes)
    self.EchoesTotalChanged:Fire(player, newTotal)
end

function AstralEchoService:RemoveEchoes(player, amount)
    local current = self.DataService:GetQN(player, "AstralEchoes")
    local diff = num.sub(current, amount)
    local newEchoes = num.isPositive(diff) and diff or num.fromNumber(0)
    self.DataService:SetQN(player, "AstralEchoes", newEchoes)
    self.EchoesChanged:Fire(player, newEchoes)
end

function AstralEchoService:ResetEchoes(player)
    local zero = num.fromNumber(0)
    self.DataService:SetQN(player, "AstralEchoes", zero)
    self.EchoesChanged:Fire(player, zero)
end

function AstralEchoService:OnEchoCollected(player)
    local value = self.UpgradeService:GetUpgradeEffect(player, "AstralEchoValue")
    local multiplier = self.MultiplierService:GetMultiplier(player, "AstralEcho")

    local finalValue = num.mul(num.fromNumber(value), multiplier)

    self:AddEchoes(player, finalValue)
    self.LevelService:AddXP(player, 4)
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
