local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local HarmonyService = Knit.CreateService {
    Name = "HarmonyService",
    Client = {
        HarmonyChanged = Knit.CreateSignal(),      -- (harmony: number)
        HarmonyTotalChanged = Knit.CreateSignal(), -- (total: number)
        TreeUnlocked = Knit.CreateSignal(),        -- () notifies client that tree interaction is unlocked
    }
}

HarmonyService.HarmonyChanged = Signal.new()
HarmonyService.HarmonyTotalChanged = Signal.new()

function HarmonyService:KnitStart()
    self.DataService = Knit.GetService("DataService")
    self.UnlockService = Knit.GetService("UnlockService")
    self.MultiplierService = Knit.GetService("MultiplierService")

    -- For testing: auto-unlock TreeInteraction for every player on profile load
    self.DataService.ProfileLoaded:Connect(function(player)
        self.UnlockService:Unlock(player, "TreeInteraction")
        self.Client.TreeUnlocked:Fire(player)
    end)

    -- Handle players whose profiles already loaded before KnitStart
    for player, _ in self.DataService.Profiles do
        self.UnlockService:Unlock(player, "TreeInteraction")
        self.Client.TreeUnlocked:Fire(player)
    end

    self.HarmonyChanged:Connect(function(player, harmony)
        self.Client.HarmonyChanged:Fire(player, harmony)
    end)

    self.HarmonyTotalChanged:Connect(function(player, total)
        self.Client.HarmonyTotalChanged:Fire(player, total)
    end)
end

function HarmonyService:GetHarmony(player: Player): number
    local profile = self.DataService:GetProfile(player)
    if not profile then return 0 end
    return profile.Data.Harmony or 0
end

function HarmonyService:AddHarmony(player: Player, amount: number)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local multiplier = self.MultiplierService:GetMultiplier(player, "Harmony")
    local final = amount * multiplier
    profile.Data.Harmony = (profile.Data.Harmony or 0) + final
    profile.Data.HarmonyTotal = (profile.Data.HarmonyTotal or 0) + final

    self.HarmonyChanged:Fire(player, profile.Data.Harmony)
    self.HarmonyTotalChanged:Fire(player, profile.Data.HarmonyTotal)
end

-- Client RPC: called by HarmonyController when the progress bar finishes filling
function HarmonyService.Client:EarnHarmony(player: Player)
    self.Server:AddHarmony(player, 1)
end

function HarmonyService.Client:GetHarmony(player: Player): number
    return self.Server:GetHarmony(player)
end

return HarmonyService
