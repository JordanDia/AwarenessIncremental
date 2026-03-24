return {
    AwarenessPerMeditation = {
        Name = "Awareness Gain",
        Description = "Increase awareness gained per meditation",
        MaxLevel = 100,
        Category = "Upgrades",
        Currency = "Awareness",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25  -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    MeditationSpeed = {
        Name = "Meditation Speed",
        Description = "Decrease cooldown between meditations",
        MaxLevel = 15,
        Category = "Upgrades",
        Currency = "Awareness",
        EffectPerLevel = function(level)
            local value = 3 - 0.2 * (level - 1)
            local roundedValue = math.round(value * 100) / 100
            return roundedValue
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.4  -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    MultiplyAwarenessPerMeditation = {
        Name = "Awareness Multiplier",
        Description = "Multiply awareness gained per meditation",
        MaxLevel = 50,
        Category = "RebirthUpgrades",
        Currency = "Rebirths",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25   -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    MultiplyRebirthAmount = {
        Name = "Rebirth Multiplier",
        Description = "Multiply rebirth amount",
        MaxLevel = 50,
        Category = "RebirthUpgrades",
        Currency = "Rebirths",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25   -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    IncreaseDeepThoughtChance = {
        Name = "Deep Thought Chance",
        Description = "Increase chance to get Deep Thought meditation",
        MaxLevel = 25,
        Category = "RebirthUpgrades",
        Currency = "Rebirths",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1    -- small starting point
            local growth = 1.3 -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },


    CrystalValue = {
        Name = "Crystal Gain",
        Description = "Increase Crystal Value",
        MaxLevel = 100,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25  -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    CrystalSpeed = {
        Name = "Crystal Speed",
        Description = "Increase crystal spawn speed",
        MaxLevel = 15,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            local value = 3 - 0.2 * (level - 1)
            local roundedValue = math.round(value * 100) / 100
            return roundedValue
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.4  -- growth rate

            return math.floor(base * (growth ^ level))
        end
    },

    MaxCrystals = {
        
        Name = "Max Crystals",
        Description = "Max amount of crystals",
        MaxLevel = 50,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.4  -- growth rate

            return math.floor(base * (growth ^ level))
        end

    },

    CrystalMultiplier = {
        
        Name = "Multiply Crystal Value",
        Description = "Multiply crystal value",
        MaxLevel = 150,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25  -- growth rate

            return math.floor(base * (growth ^ level))
        end

    },

    CrystalAwarenessMultiplier = {
        
        Name = "Crystal Awareness Multiplier",
        Description = "Multiply awareness gained per meditation",
        MaxLevel = 200,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25   -- growth rate

            return math.floor(base * (growth ^ level))
        end

    },

    CrystalRebirthMultiplier = {

        Name = "Crystal Rebirth Multiplier",
        Description = "Multiply rebirth amount",
        MaxLevel = 200,
        Category = "Upgrades",
        Currency = "Crystals",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 1     -- small starting point
            local growth = 1.25   -- growth rate

            return math.floor(base * (growth ^ level))
        end

    },

    AstralEchoValue = {
        Name = "Echo Value",
        Description = "Increase Astral Echo value per collection",
        MaxLevel = 100,
        Category = "Upgrades",
        Currency = "AstralEchoes",
        EffectPerLevel = function(level)
            return level
        end,
        CostFunc = function(level)
            local base = 10
            local growth = 1.3
            return math.floor(base * (growth ^ level))
        end,
    },

    VeilDuration = {
        Name = "Veil Duration",
        Description = "Increase how long the Veil lasts (+1 second per level)",
        MaxLevel = 50,
        Category = "Upgrades",
        Currency = "AstralEchoes",
        EffectPerLevel = function(level)
            return 15 + level  -- 15 seconds base + 1 per level
        end,
        CostFunc = function(level)
            local base = 50
            local growth = 1.35
            return math.floor(base * (growth ^ level))
        end,
    },
}
