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
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-2",
            Unlocks = {"1-3", "1-4"},
            Rewards = {
                { Type = "Multiplier", Stat = "Rebirth", Value = 2 },
            },
            Title = "Upgrade: 1-2",
            UpgradeName = "2x Rebirths",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-3",
            Unlocks = {"1-5", "1-7"},
            Rewards = {
                { Type = "Unlock", Value = "CrystalCollection" },
            },
            Title = "Upgrade: 1-3",
            UpgradeName = "Unlock Crystal Collection",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-4",
            Unlocks = {"1-6"},
            Rewards = {
                { Type = "Multiplier", Stat = "Awareness", Value = 1.5 },
            },
            Title = "Upgrade: 1-4",
            UpgradeName = "1.5x Awareness",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-5",
            Unlocks = {"1-10"},
            Rewards = {
                { Type = "Multiplier", Stat = "CrystalValue", Value = 2 },
            },
            Title = "Upgrade: 1-5",
            UpgradeName = "2x Crystals",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-6",
            Unlocks = {"1-8"},
            Rewards = {
                { Type = "Multiplier", Stat = "Rebirth", Value = 1.5 },
            },
            Title = "Upgrade: 1-6",
            UpgradeName = "1.5x Rebirths",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-7",
            Unlocks = {"1-12"},
            Rewards = {
                { Type = "Multiplier", Stat = "WalkSpeed", Value = 1.5 },
            },
            Title = "Upgrade: 1-7",
            UpgradeName = "1.5x Walk Speed",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-8",
            Unlocks = {"1-9", "1-13"},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "Playtime" },
            },
            Title = "Upgrade: 1-8",
            UpgradeName = "Awareness boosted by playtime",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-9",
            Unlocks = {"1-11"},
            Rewards = {
                { Type = "Dynamic", Stat = "Rebirth", Source = "Playtime" },
            },
            Title = "Upgrade: 1-9",
            UpgradeName = "Rebirths boosted by playtime",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-10",
            Unlocks = {"1-14"},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "CrystalCount" },
            },
            Title = "Upgrade: 1-10",
            UpgradeName = "Awareness boosted by Crystals",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-11",
            Unlocks = {},
            Rewards = {
                { Type = "Dynamic", Stat = "Awareness", Source = "Level" },
            },
            Title = "Upgrade: 1-11",
            UpgradeName = "Awareness multiplied by level",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-12",
            Unlocks = {},
            Rewards = {
                { Type = "Multiplier", Stat = "Awareness", Value = 3 },
            },
            Title = "Upgrade: 1-12",
            UpgradeName = "3x Awareness",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-13",
            Unlocks = {},
            Rewards = {
                { Type = "Multiplier", Stat = "CrystalValue", Value = 3 },
            },
            Title = "Upgrade: 1-13",
            UpgradeName = "3x Crystals",
            Cost = { Amount = 0, Currency = "Awareness" },
        },

        {
            NodeId = "1-14",
            Unlocks = {},
            Rewards = {
                { Type = "Dynamic", Stat = "CrystalValue", Source = "Level" },
            },
            Title = "Upgrade: 1-14",
            UpgradeName = "Crystals multiplied by level",
            Cost = { Amount = 0, Currency = "Awareness" },
        },
    },

    -- Tree2 is locked by default; its root is unlocked when the player reaches Awakening Level 1.
    Tree2 = {
        {
            NodeId      = "2-1",
            Unlocks     = {},
            Rewards     = {
                { Type = "Multiplier", Stat = "Awareness", Value = 2 },
            },
            Title       = "Upgrade: 2-1",
            UpgradeName = "2x Awareness",
            Cost        = { Amount = 0, Currency = "Awareness" },
        },
    },

}
