local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService_Roblox = game:GetService("BadgeService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local BadgeConfig = require(ReplicatedStorage.Shared.Configs.BadgeConfig)

local BadgeService = Knit.CreateService { Name = "BadgeService" }

-- Awards a badge if the player doesn't already have it.
-- Skips silently if the Id is 0 (placeholder).
function BadgeService:Award(player, key)
    local id = BadgeConfig[key]
    if not id or id == 0 then return end

    task.spawn(function()
        local success, hasBadge = pcall(function()
            return BadgeService_Roblox:UserHasBadgeAsync(player.UserId, id)
        end)
        if success and not hasBadge then
            BadgeService_Roblox:AwardBadge(player.UserId, id)
        end
    end)
end

function BadgeService:KnitStart()
    local AwarenessService  = Knit.GetService("AwarenessService")
    local CrystalService    = Knit.GetService("CrystalService")
    local RebirthService    = Knit.GetService("RebirthService")
    local AwakeningService  = Knit.GetService("AwakeningService")
    local VeilService       = Knit.GetService("VeilService")
    local AstralEchoService = Knit.GetService("AstralEchoService")
    local DataService       = Knit.GetService("DataService")

    -- First meditation: player gains any awareness for the first time
    AwarenessService.AwarenessChanged:Connect(function(player, newAwareness)
        if num.gte(newAwareness, 1) then
            local profile = DataService:GetProfile(player)
            if profile and not profile.Data.Badges_FirstMeditation then
                profile.Data.Badges_FirstMeditation = true
                self:Award(player, "FirstMeditation")
            end
        end
    end)

    -- First crystal collected
    CrystalService.CrystalCollected:Connect(function(player)
        local profile = DataService:GetProfile(player)
        if profile and not profile.Data.Badges_FirstCrystal then
            profile.Data.Badges_FirstCrystal = true
            self:Award(player, "FirstCrystal")
        end
    end)

    -- First rebirth
    RebirthService.RebirthPerformed:Connect(function(player)
        local profile = DataService:GetProfile(player)
        if profile and not profile.Data.Badges_FirstRebirth then
            profile.Data.Badges_FirstRebirth = true
            self:Award(player, "FirstRebirth")
        end
    end)

    -- First awakening
    AwakeningService.AwakeningLevelChanged:Connect(function(player, level)
        if level == 1 then
            local profile = DataService:GetProfile(player)
            if profile and not profile.Data.Badges_FirstAwakening then
                profile.Data.Badges_FirstAwakening = true
                self:Award(player, "FirstAwakening")
            end
        end
    end)

    -- Lifting the veil for the first time
    VeilService.VeilStateChanged:Connect(function(player, isLifted)
        if not isLifted then return end
        local profile = DataService:GetProfile(player)
        if profile and not profile.Data.Badges_FirstVeil then
            profile.Data.Badges_FirstVeil = true
            self:Award(player, "FirstVeil")
        end
    end)

    -- First astral echo collected
    AstralEchoService.EchoesChanged:Connect(function(player, echoes)
        if num.gte(echoes, 1) then
            local profile = DataService:GetProfile(player)
            if profile and not profile.Data.Badges_FirstAstralEcho then
                profile.Data.Badges_FirstAstralEcho = true
                self:Award(player, "FirstAstralEcho")
            end
        end
    end)
end

return BadgeService
