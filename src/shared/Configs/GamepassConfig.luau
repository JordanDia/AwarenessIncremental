-- Each entry maps a gamepass to the MultiplierService stat it affects.
-- Stat = nil means the pass has a custom effect handled separately (e.g. MeditateAnywhere).
return {
    {
        Name        = "2x Awareness",
        Description = "Double all Awareness earned permanently!",
        PassId      = 1760277172,
        Stat        = "Awareness",
        Value       = 2,
    },
    {
        Name        = "2x Crystals",
        Description = "Double all Crystals collected permanently!",
        PassId      = 1760457186,
        Stat        = "CrystalValue",
        Value       = 2,
    },
    {
        Name        = "2x Astral Echoes",
        Description = "Double all Astral Echoes earned permanently!",
        PassId      = 1761369114,
        Stat        = "AstralEcho",
        Value       = 2,
    },
    {
        Name        = "2x Harmony",
        Description = "Double all Harmony earned permanently!",
        PassId      = 1759545059,
        Stat        = "Harmony",
        Value       = 2,
    },
    {
        Name        = "2x Walk Speed",
        Description = "Move twice as fast across all zones permanently!",
        PassId      = 1761326995,
        Stat        = "WalkSpeed",
        Value       = 2,
    },
    {
        Name        = "Meditate Anywhere",
        Description = "Meditate and earn Awareness from anywhere on the map!",
        PassId      = 1760349159,
        Stat        = nil, -- custom effect, handled separately
        Value       = nil,
    },
}
