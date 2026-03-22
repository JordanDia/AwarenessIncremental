return {

    MaxLevel = 6,

    -- Cost to advance TO that level (spent from current Awareness balance).
    -- Awakening also resets Awareness, Rebirths, Crystals, and Astral Echoes.
    Levels = {
        {
            Level       = 1,
            Description = "Unlock the second upgrade tree",
            Cost        = 1, -- 1T Awareness
            Reward      = { Type = "Unlock", Value = "Tree2" },
        },
        {
            Level       = 2,
            Description = "2x multiplier for Awareness, Rebirths, and Crystals",
            Cost        = 1, -- 10T
            Reward      = { Type = "Multiplier", Stats = { "Awareness", "Rebirth", "CrystalValue" }, Value = 2 },
        },
        {
            Level       = 3,
            Description = "Astral Echoes are multiplied by your Awakening Level",
            Cost        = 1, -- 100T
            Reward      = { Type = "DynamicEcho" },
        },
        {
            Level       = 4,
            Description = "Auto gain 2% of your Rebirths per second",
            Cost        = 1, -- 1,000T
            Reward      = { Type = "AutoRebirth", Rate = 0.02 },
        },
        {
            Level       = 5,
            Description = "Auto buy Awareness, Rebirth, and Crystal upgrades for free",
            Cost        = 1, -- 10,000T
            Reward      = { Type = "AutoBuy" },
        },
        {
            Level       = 6,
            Description = "Unlock the Tree Connection Zone",
            Cost        = 1, -- 100,000T
            Reward      = { Type = "Unlock", Value = "TreeConnectionZone" },
        },
    },

}
