local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local UnlockService = Knit.CreateService { Name = "UnlockService" }

function UnlockService:KnitStart()
    self.DataService = Knit.GetService("DataService")
end

function UnlockService:IsUnlocked(player, unlockId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end
    return profile.Data.Unlocks[unlockId] == true
end

function UnlockService:Unlock(player, unlockId)
    local profile = self.DataService:GetProfile(player)
    if not profile then return false end
    if profile.Data.Unlocks[unlockId] then return false end -- already unlocked

    profile.Data.Unlocks[unlockId] = true
    print(`Player {player.Name} unlocked: {unlockId}`)
    return true
end

function UnlockService.Client:IsUnlocked(player, unlockId)
    return self.Server:IsUnlocked(player, unlockId)
end

return UnlockService