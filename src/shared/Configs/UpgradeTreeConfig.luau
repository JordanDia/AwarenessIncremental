return {

    Tree1 = {
        {
            NodeId = "1-1",
            Unlocks = {"1-2"},
            Rewards = {
                { Type = "Multiplier", Stat = "Awareness", Value = 2 },
            },
            Title = "Upgrade: 1-1",
            UpgradeName = "2x Awareness",
            Cost = { Amount = 250_000, Currency = "Awareness" },
        },

        {
            NodeId = "1-2",
            Unlocks = {"1-3", "1-4"},
            Rewards = {
                { Type = "Multiplier", Stat = "Rebirth", Value = 2 },
            },
            Title = "Upgrade: 1-2",
            UpgradeName = "2x Rebirths",
            Cost = { Amount = 500_000, Currency = "Awareness" },
        },

        {
            NodeId = "1-3",
            Unlocks = {"1-5", "1-7"},
            Rewards = {
                { Type = "Unlock", Value = "CrystalCollection" },
            },
            Title = "Upgrade: 1-3",
            UpgradeName = "Unlock Crystal Collection",
            Cost = { Amount = 1_000_000, Currency = "Awareness" },
        },

        {
            NodeId = "1-4",
            Unlocks = {"1-6"},
            Rewards = {
                { Type = "Multiplier", Stat = "Awareness", Value = 1.5 },
            },
            Title = "Upgrade: 1-4",
            UpgradeName = "1.5x Awareness",
            Cost = { Amount = 50_000, Currency = "Rebirths" },
        },

        {
            NodeId = "1-5",
            Unlocks = {"1-10"},
            Rewards = {
                { Type = "Multiplier", Stat = "CrystalValue", Value = 2 },
            },
            Title = "Upgrade: 1-5",
            UpgradeName = "2x Crystals",
            Cost = { Amount = 100 * 1e6, Currency = "Awareness" },
        },

        {
            NodeId = "1-6",
            Unlocks = {"1-8"},
            Rewards = {
                { Type = "Multiplier", Stat = "Rebirth", Value = 1.5 },
            },
            Title = "Upgrade: 1-6",
            UpgradeName = "1.5x Rebirths",
            Cost = { Amount = 1e6, Currency = "Rebirths" },
        },

        {
            NodeId = "1-7",
            Unlocks = {"1-12"},
            Rewards = {
                { Type = "Multiplier", Stat = "WalkSpeed", Value = 1.5 },
            },
            Title = "Upgrade: 1-7",
            UpgradeName = "1.5x Walk Speed",
            Cost = { Amount = 1e9, Currency = "Awareness" },
        },

        {
            NodeId = "1-8",
            Unlocks = {"1-9", "1-13"},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "Playtime" },
            },
            Title = "Upgrade: 1-8",
            UpgradeName = "Awareness boosted by playtime",
            Cost = { Amount = 50 * 1e6, Currency = "Rebirths" },
        },

        {
            NodeId = "1-9",
            Unlocks = {"1-11"},
            Rewards = {
                { Type = "Dynamic", Stat = "Rebirth", Source = "Playtime" },
            },
            Title = "Upgrade: 1-9",
            UpgradeName = "Rebirths boosted by playtime",
            Cost = { Amount = 1e9, Currency = "Rebirths" },
        },

        {
            NodeId = "1-10",
            Unlocks = {"1-14"},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "CrystalCount" },
            },
            Title = "Upgrade: 1-10",
            UpgradeName = "Awareness boosted by Crystals",
            Cost = { Amount = 1e6, Currency = "Crystals" },
        },

        {
            NodeId = "1-11",
            Unlocks = {},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "Level" },
            },
            Title = "Upgrade: 1-11",
            UpgradeName = "Awareness multiplied by level",
            Cost = { Amount = 100 * 1e9, Currency = "Rebirths" },
        },

        {
            NodeId = "1-12",
            Unlocks = {},
            Rewards = {
                { Type = "Multiplier", Stat = "Awareness", Value = 3 },
            },
            Title = "Upgrade: 1-12",
            UpgradeName = "3x Awareness",
            Cost = { Amount = 100 * 1e9, Currency = "Awareness" },
        },

        {
            NodeId = "1-13",
            Unlocks = {},
            Rewards = {
                { Type = "Multiplier", Stat = "CrystalValue", Value = 3 },
            },
            Title = "Upgrade: 1-13",
            UpgradeName = "3x Crystals",
            Cost = { Amount = 10 * 1e9, Currency = "Rebirths" },
        },

        {
            NodeId = "1-14",
            Unlocks = {},
            Rewards = {
                { Type = "Dynamic", Stat = "CrystalValue", Source = "Level" },
            },
            Title = "Upgrade: 1-14",
            UpgradeName = "Crystals multiplied by level",
            Cost = { Amount = 200 * 1e6, Currency = "Crystals" },
        },
    },

    -- Tree2 is locked by default; its root is unlocked when the player reaches Awakening Level 1.
    Tree2 = {
        {
            NodeId      = "2-1",
            Unlocks     = { "2-2" },
            Rewards     = { { Type = "Multiplier", Stat = "AstralEcho", Value = 2 } },
            Title       = "Upgrade: 2-1",
            UpgradeName = "2x Astral Echoes",
            Cost        = { Amount = 1_000, Currency = "Astral Echoes" },
        },
        {
            NodeId      = "2-2",
            Unlocks     = { "2-3", "2-4", "2-8" },
            Rewards     = { { Type = "Multiplier", Stat = "CrystalValue", Value = 3 } },
            Title       = "Upgrade: 2-2",
            UpgradeName = "3x Crystals",
            Cost        = { Amount = 75_000, Currency = "Astral Echoes" },
        },
        {
            NodeId      = "2-3",
            Unlocks     = { "2-5" },
            Rewards     = { { Type = "Dynamic", Stat = "AstralEcho", Source = "RebirthCount" } },
            Title       = "Upgrade: 2-3",
            UpgradeName = "Astral Echoes boosted by rebirths",
            Cost        = { Amount = 150_000, Currency = "Astral Echoes" },
        },
        {
            NodeId      = "2-4",
            Unlocks     = { "2-6" },
            Rewards     = { { Type = "Dynamic", Stat = "AstralEcho", Source = "Playtime" } },
            Title       = "Upgrade: 2-4",
            UpgradeName = "Astral Echoes boosted by playtime",
            Cost        = { Amount = 1e12, Currency = "Rebirths" },
        },
        {
            NodeId      = "2-5",
            Unlocks     = { "2-10" },
            Rewards     = { { Type = "Dynamic", Stat = "CrystalValue", Source = "Playtime" } },
            Title       = "Upgrade: 2-5",
            UpgradeName = "Crystals boosted by playtime",
            Cost        = { Amount = 50 * 1e6, Currency = "Astral Echoes" },
        },
        {
            NodeId      = "2-6",
            Unlocks     = { "2-7", "2-11" },
            Rewards     = { { Type = "Multiplier", Stat = "Awareness", Value = 5 } },
            Title       = "Upgrade: 2-6",
            UpgradeName = "5x Awareness",
            Cost        = { Amount = 10 * 1e12, Currency = "Rebirths" },
        },
        {
            NodeId      = "2-7",
            Unlocks     = { "2-9" },
            Rewards     = { { Type = "Multiplier", Stat = "AstralEcho", Value = 3 } },
            Title       = "Upgrade: 2-7",
            UpgradeName = "3x Astral Echoes",
            Cost        = { Amount = 1 * 1e9, Currency = "Crystals" },
        },
        {
            NodeId      = "2-8",
            Unlocks     = { "2-12" },
            Rewards     = { { Type = "Multiplier", Stat = "AstralEcho", Value = 2 } },
            Title       = "Upgrade: 2-8",
            UpgradeName = "2x Astral Echoes",
            Cost        = { Amount = 50 * 1e12, Currency = "Awareness" },
        },
        {
            NodeId      = "2-9",
            Unlocks     = {},
            Rewards     = { { Type = "Dynamic", Stat = "AstralEcho", Source = "Level" } },
            Title       = "Upgrade: 2-9",
            UpgradeName = "Astral Echoes multiplied by level",
            Cost        = { Amount = 1e12, Currency = "Awareness" },
        },
        {
            NodeId      = "2-10",
            Unlocks     = { "2-14" },
            Rewards     = { { Type = "Dynamic", Stat = "Rebirth", Source = "CrystalCount" } },
            Title       = "Upgrade: 2-10",
            UpgradeName = "Rebirths boosted by crystals",
            Cost        = { Amount = 250 * 1e6, Currency = "Astral Echoes" },
        },
        {
            NodeId      = "2-11",
            Unlocks     = {},
            Rewards     = { { Type = "Multiplier", Stat = "Rebirth", Value = 5 } },
            Title       = "Upgrade: 2-11",
            UpgradeName = "5x Rebirths",
            Cost        = { Amount = 100 * 1e15, Currency = "Rebirths" },
        },
        {
            NodeId      = "2-12",
            Unlocks     = { "2-13" },
            Rewards     = { { Type = "Dynamic", Stat = "Awareness", Source = "AstralEchoCount" } },
            Title       = "Upgrade: 2-12",
            UpgradeName = "Awareness boosted by Astral Echoes",
            Cost        = { Amount = 500 * 1e12, Currency = "Awareness" },
        },
        {
            NodeId      = "2-13",
            Unlocks     = {},
            Rewards     = { { Type = "Dynamic", Stat = "Awareness", Source = "RebirthCount" } },
            Title       = "Upgrade: 2-13",
            UpgradeName = "Awareness boosted by rebirths",
            Cost        = { Amount = 5 * 1e15, Currency = "Awareness" },
        },
        {
            NodeId      = "2-14",
            Unlocks     = {},
            Rewards     = { { Type = "Dynamic", Stat = "Rebirth", Source = "Level" } },
            Title       = "Upgrade: 2-14",
            UpgradeName = "Rebirth multiplied by level",
            Cost        = { Amount = 5 * 1e9, Currency = "Astral Echoes" },
        },
    },

    -- Tree3: Essence/Dark Essence tree. Root unlocked after reaching Awakening Level 2 (TBD).
    Tree3 = {
        -- ── Root ─────────────────────────────────────────────────────────────
        {
            NodeId      = "3-1",
            Unlocks     = { "3-2" },
            Rewards     = { { Type = "Multiplier", Stat = "Essences", Value = 2 } },
            Title       = "Upgrade: 3-1",
            UpgradeName = "2x Essences",
            Cost        = { Amount = 50, Currency = "Essences" },
        },

        -- ── Row 2 ─────────────────────────────────────────────────────────────
        {
            NodeId      = "3-2",
            Unlocks     = { "3-3", "3-4", "3-5" },
            Rewards     = { { Type = "Multiplier", Stat = "Awareness", Value = 2 } },
            Title       = "Upgrade: 3-2",
            UpgradeName = "2x Awareness",
            Cost        = { Amount = 150, Currency = "Essences" },
        },

        {
            NodeId      = "3-3",
            Unlocks     = { "3-6" },
            Rewards     = { { Type = "Multiplier", Stat = "AstralEcho", Value = 5 } },
            Title       = "Upgrade: 3-3",
            UpgradeName = "5x Astral Echoes",
            Cost        = { Amount = 1e9, Currency = "Astral Echoes" },
        },

        {
            NodeId      = "3-4",
            Unlocks     = { "3-7" },
            Rewards     = { { Type = "Dynamic", Stat = "Awareness", Source = "EssenceCount" } },
            Title       = "Upgrade: 3-4",
            UpgradeName = "Awareness boosted by Essences",
            Cost        = { Amount = 200, Currency = "Essences" },
        },

        -- ── Row 3 ─────────────────────────────────────────────────────────────
        {
            NodeId      = "3-5",
            Unlocks     = { "3-10" },
            Rewards     = { { Type = "Unlock", Value = "EliteSpiritSpawner" } },
            Title       = "Upgrade: 3-5",
            UpgradeName = "Unlock Dark Spirit Spawner",
            Cost        = { Amount = 500, Currency = "Essences" },
        },

        {
            NodeId      = "3-6",
            Unlocks     = { "3-8", "3-11" },
            Rewards     = { { Type = "Unlock", Value = "AutoBuyAstralEcho" } },
            Title       = "Upgrade: 3-6",
            UpgradeName = "Auto Buy Astral Echo Upgrades",
            Cost        = { Amount = 300, Currency = "Essences" },
        },

        {
            NodeId      = "3-7",
            Unlocks     = { "3-9", "3-12" },
            Rewards     = { { Type = "Multiplier", Stat = "Awareness", Value = 3 } },
            Title       = "Upgrade: 3-7",
            UpgradeName = "3x Awareness",
            Cost        = { Amount = 300, Currency = "Essences" },
        },

        -- ── Row 4 ─────────────────────────────────────────────────────────────
        {
            NodeId      = "3-8",
            Unlocks     = {},
            Rewards     = { { Type = "Multiplier", Stat = "AstralEcho", Value = 3 } },
            Title       = "Upgrade: 3-8",
            UpgradeName = "3x Astral Echoes",
            Cost        = { Amount = 800, Currency = "Essences" },
        },

        {
            NodeId      = "3-9",
            Unlocks     = {},
            Rewards     = { { Type = "Multiplier", Stat = "SpiritDamage", Value = 2 } },
            Title       = "Upgrade: 3-9",
            UpgradeName = "2x Spirit Damage",
            Cost        = { Amount = 2_000, Currency = "Essences" },
        },

        {
            NodeId      = "3-10",
            Unlocks     = { "3-13" },
            Rewards     = { { Type = "Dynamic", Stat = "Awareness", Source = "DarkEssenceCount" } },
            Title       = "Upgrade: 3-10",
            UpgradeName = "Awareness boosted by Dark Essences",
            Cost        = { Amount = 10, Currency = "Dark Essences" },
        },

        -- ── Row 5 (top) ───────────────────────────────────────────────────────
        {
            NodeId      = "3-11",
            Unlocks     = {},
            Rewards     = { { Type = "Dynamic", Stat = "Rebirth", Source = "EssenceCount" } },
            Title       = "Upgrade: 3-11",
            UpgradeName = "Rebirths boosted by Essences",
            Cost        = { Amount = 5_000, Currency = "Essences" },
        },

        {
            NodeId      = "3-12",
            Unlocks     = {},
            Rewards     = { { Type = "Multiplier", Stat = "DarkEssences", Value = 2 } },
            Title       = "Upgrade: 3-12",
            UpgradeName = "2x Dark Essences",
            Cost        = { Amount = 15, Currency = "Dark Essences" },
                
        },

        {
            NodeId      = "3-13",
            Unlocks     = {},
            Rewards     = { { Type = "Multiplier", Stat = "Awareness", Value = 5 } },
            Title       = "Upgrade: 3-13",
            UpgradeName = "5x Awareness",
            Cost        = { Amount = 1e21, Currency = "Awareness" },
        },
    },

}
