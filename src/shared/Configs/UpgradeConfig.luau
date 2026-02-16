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
    }
}
