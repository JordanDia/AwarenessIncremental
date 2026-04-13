-- Each stage drives one step of the guide UI.
--
-- Fields:
--   Title     (string)   Text shown at the top of the guide frame
--   ShowBar   (bool)     Whether to show the progress bar
--   Goal      (number)   Max value for the progress bar (ignored when ShowBar = false)
--   Type      (string)   What the service checks to measure progress:
--                          "Awareness"    – current awareness value
--                          "UpgradeLevel" – level of a specific upgrade
--                          "RebirthCount" – number of rebirths (uses RebirthsTotal)
--   UpgradeId (string)   Required when Type == "UpgradeLevel"
--   Adornee   (string[]) Optional workspace path to a part the indicator arrow should hover over
--                        e.g. {"UpgradeBoards", "MoreMeditationSpeedBoard"}

return {
    Stages = {
        {
            Title   = "Walk to the Meditation Ground and start meditating!",
            ShowBar = false,
            Goal    = 1,
            Type    = "Awareness",
            -- Beam from the player character to the meditation ground
            Beam    = { "Map", "MeditationGrounds" },
        },
        {
            Title     = "Meditate to gain Awareness! Reach 3 Awareness.",
            ShowBar   = true,
            Goal      = 3,
            Type      = "Awareness",
        },
        {
            Title     = "Buy the Meditation Speed upgrade to level 10!",
            ShowBar   = true,
            Goal      = 10,
            Type      = "UpgradeLevel",
            UpgradeId = "MeditationSpeed",
            Adornee   = { "UpgradeBoards", "MoreMeditationSpeedBoard" },
        },
        {
            Title     = "Buy the Awareness Gain upgrade to level 10!",
            ShowBar   = true,
            Goal      = 10,
            Type      = "UpgradeLevel",
            UpgradeId = "AwarenessPerMeditation",
            Adornee   = { "UpgradeBoards", "MoreAwarenessBoard" },
        },
        {
            Title     = "Get 1,000 Awareness and Rebirth for permanent bonuses!",
            ShowBar   = true,
            Goal      = 1000,
            Type      = "Awareness",
        },
        {
            Title     = "Perform your first Rebirth at the Rebirth board!",
            ShowBar   = false,
            Goal      = 1,
            Type      = "RebirthCount",
            Adornee   = { "UpgradeBoards", "RebirthBoard" },
        },
        {
            Title     = "Spend Rebirths on the Awareness Multiplier upgrade! Reach level 5.",
            ShowBar   = true,
            Goal      = 5,
            Type      = "UpgradeLevel",
            UpgradeId = "MultiplyAwarenessPerMeditation",
            Adornee   = { "RebirthUpgradeBoards", "MultiplyAwarenessPerMeditation" },
        },
        {
            Title     = "Spend Rebirths on the Rebirth Multiplier upgrade! Reach level 5.",
            ShowBar   = true,
            Goal      = 5,
            Type      = "UpgradeLevel",
            UpgradeId = "MultiplyRebirthAmount",
            Adornee   = { "RebirthUpgradeBoards", "MultiplyRebirthAmount" },
        },
        {
            Title     = "Get 250,000 Awareness to unlock the first Upgrade Tree node!",
            ShowBar   = true,
            Goal      = 250000,
            Type      = "Awareness",
        },
        {
            Title   = "Purchase upgrade 1-1: 2x Awareness in the Upgrade Tree!",
            ShowBar = false,
            Goal    = 1,
            Type    = "TreeNode",
            TreeName = "Tree1",
            NodeId  = "1-1",
            Beam    = { "UpgradeTrees", "Tree1", "1-1", "TouchPart" },
        },
        {
            Title   = "Get 500,000 Awareness to unlock node 1-2!",
            ShowBar = true,
            Goal    = 500000,
            Type    = "Awareness",
        },
        {
            Title   = "Purchase upgrade 1-2: 2x Rebirths in the Upgrade Tree!",
            ShowBar = false,
            Goal    = 1,
            Type    = "TreeNode",
            TreeName = "Tree1",
            NodeId  = "1-2",
            Beam    = { "UpgradeTrees", "Tree1", "1-2", "TouchPart" },
        },
        {
            Title   = "Get 1,000,000 Awareness to unlock node 1-3!",
            ShowBar = true,
            Goal    = 1000000,
            Type    = "Awareness",
        },
        {
            Title   = "Purchase upgrade 1-3: Unlock Crystal Collection!",
            ShowBar = false,
            Goal    = 1,
            Type    = "TreeNode",
            TreeName = "Tree1",
            NodeId  = "1-3",
            Beam    = { "UpgradeTrees", "Tree1", "1-3", "TouchPart" },
        },
    },
}
