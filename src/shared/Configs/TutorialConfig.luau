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
            Title   = "You are gaining Awareness!",
            ShowBar = true,
            Goal    = 10,
            Type    = "Awareness",
        },
        {
            Title     = "Upgrade to gain Awareness faster!",
            ShowBar   = true,
            Goal      = 2,
            Type      = "UpgradeLevel",
            UpgradeId = "AwarenessPerMeditation",
            Adornee   = { "UpgradeBoards", "MoreAwarenessBoard" },
        },
        {
            Title     = "Upgrade your Meditation Speed!",
            ShowBar   = true,
            Goal      = 2,
            Type      = "UpgradeLevel",
            UpgradeId = "MeditationSpeed",
            Adornee   = { "UpgradeBoards", "MoreMeditationSpeedBoard" },
        },
        {
            Title     = "Reach 50 Awareness!",
            ShowBar   = true,
            Goal      = 50,
            Type      = "Awareness",
        },
    },
}
