-- Daily quest definitions. Resets every 24 hours.
-- Reward.Type = "Multiplier": temporarily boosts a MultiplierService stat
--   Stat     — the stat key passed to MultiplierService
--   Value    — multiplier value (e.g. 2 = 2x)
--   Duration — seconds the buff lasts
--   Label    — short display string shown in the reward panel
--   Icon     — asset ID for the reward icon

local AWARENESS_ICON = "rbxassetid://108300702326871"
local REBIRTH_ICON   = "rbxassetid://87766693277427"
local CRYSTAL_ICON   = "rbxassetid://78458877619165"

return {
    {
        Id          = "Meditate",
        Title       = "Peaceful Mind",
        Description = "Meditate for 2 minutes",
        Goal        = 120,
        Format      = "time",
        Type        = "Meditate",
        Reward = {
            Type     = "Multiplier",
            Stat     = "Awareness",
            Value    = 2,
            Duration = 600, -- 10 minutes
            Label    = "2x Awareness",
            Sublabel = "10 min",
            Icon     = AWARENESS_ICON,
        },
    },
    {
        Id          = "CollectCrystals",
        Title       = "Crystal Collector",
        Description = "Collect 500 crystals",
        Goal        = 500,
        Format      = "number",
        Type        = "CollectCrystals",
        Reward = {
            Type     = "Multiplier",
            Stat     = "CrystalValue",
            Value    = 2,
            Duration = 600,
            Label    = "2x Crystals",
            Sublabel = "10 min",
            Icon     = CRYSTAL_ICON,
        },
    },
    {
        Id          = "Rebirth",
        Title       = "Cycle of Rebirth",
        Description = "Perform 3 rebirths",
        Goal        = 3,
        Format      = "number",
        Type        = "Rebirth",
        Reward = {
            Type     = "Multiplier",
            Stat     = "Rebirth",
            Value    = 2,
            Duration = 600,
            Label    = "2x Rebirths",
            Sublabel = "10 min",
            Icon     = REBIRTH_ICON,
        },
    },
    {
        Id          = "EarnAwareness",
        Title       = "Growing Awareness",
        Description = "Earn 10,000 Awareness",
        Goal        = 10000,
        Format      = "number",
        Type        = "EarnAwareness",
        Reward = {
            Type     = "Multiplier",
            Stat     = "Awareness",
            Value    = 3,
            Duration = 900, -- 15 minutes
            Label    = "3x Awareness",
            Sublabel = "15 min",
            Icon     = AWARENESS_ICON,
        },
    },
}
