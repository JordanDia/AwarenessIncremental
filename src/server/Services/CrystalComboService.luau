local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Knit              = require(ReplicatedStorage.Packages.Knit)

local COMBO_MIN       = 1.0
local COMBO_MAX       = 5.0
local COMBO_INCREMENT = 0.1
local COMBO_DECAY     = 0.2
local DECAY_INTERVAL  = 0.4 -- seconds between each decay tick

local CrystalComboService = Knit.CreateService {
    Name = "CrystalComboService",
    Client = {
        -- Fires (combo: number) on change; 0 means deactivated (hide billboard)
        ComboChanged = Knit.CreateSignal(),
    },
}

CrystalComboService._combo       = {}  -- [player] = number (COMBO_MIN when inactive)
CrystalComboService._active      = {}  -- [player] = bool
CrystalComboService._decayThread = {}  -- [player] = thread

local function round1dp(n)
    return math.round(n * 10) / 10
end

function CrystalComboService:_cancelDecay(player)
    if self._decayThread[player] then
        task.cancel(self._decayThread[player])
        self._decayThread[player] = nil
    end
end

function CrystalComboService:_scheduleDecay(player)
    self:_cancelDecay(player)
    self._decayThread[player] = task.delay(DECAY_INTERVAL, function()
        self._decayThread[player] = nil
        if not player.Parent then return end

        local current = self._combo[player] or COMBO_MIN
        local next = round1dp(math.max(COMBO_MIN, current - COMBO_DECAY))
        self._combo[player] = next

        if next <= COMBO_MIN then
            -- Fully decayed — deactivate display
            self._active[player] = false
            self.Client.ComboChanged:Fire(player, 0)
        else
            self.Client.ComboChanged:Fire(player, next)
            self:_scheduleDecay(player)
        end
    end)
end

-- Called by CrystalService on each collect.
-- Returns the multiplier that should be applied to this crystal's value,
-- then increments the combo and resets the decay timer.
function CrystalComboService:ApplyAndGetCombo(player): number
    local current = self._combo[player] or COMBO_MIN
    self._active[player] = true

    -- Fire with the value the player will see for this collect
    self.Client.ComboChanged:Fire(player, current)

    -- Increment for next collect
    self._combo[player] = round1dp(math.min(COMBO_MAX, current + COMBO_INCREMENT))

    -- Reset decay timer
    self:_scheduleDecay(player)

    return current
end

function CrystalComboService:GetCombo(player): number
    return self._combo[player] or COMBO_MIN
end

function CrystalComboService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        self:_cancelDecay(player)
        self._combo[player]  = nil
        self._active[player] = nil
    end)
end

return CrystalComboService
