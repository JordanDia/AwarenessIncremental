local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VEIL_COOLDOWN = 30 -- seconds before the player can re-enter after the veil expires

local VeilService = Knit.CreateService {
    Name = "VeilService",
    Client = {
        VeilLifted  = Knit.CreateSignal(), -- server → client: veil has been lifted
        VeilLowered = Knit.CreateSignal(), -- server → client: veil has been lowered
        VeilStarted = Knit.CreateSignal(), -- server → client: fires (duration: number) when veil begins
    }
}

VeilService.VeilStateChanged = Signal.new() -- (player, isLifted: boolean)
VeilService.LiftedVeils  = {} -- [player] = true while inside
VeilService.Cooldowns    = {} -- [player] = os.clock() when cooldown started

function VeilService:KnitStart()
    self.DataService       = Knit.GetService("DataService")
    self.UnlockService     = Knit.GetService("UnlockService")
    self.AstralEchoService = Knit.GetService("AstralEchoService")
    self.UpgradeService    = Knit.GetService("UpgradeService")

    -- Hook up the mushroom prompt — enter-only, no toggle
    local mushroom = workspace:WaitForChild("Mushroom")
    local prompt = mushroom:FindFirstChildWhichIsA("ProximityPrompt", true)

    if prompt then
        prompt.Triggered:Connect(function(player)
            -- Ignore if already inside or on cooldown
            if self:IsVeilLifted(player) then return end
            if self:IsOnCooldown(player) then return end
            self:LiftVeil(player)
        end)
    else
        warn("VeilService: No ProximityPrompt found in workspace.Mushroom")
    end

    game.Players.PlayerRemoving:Connect(function(player)
        self.LiftedVeils[player] = nil
        self.Cooldowns[player] = nil
    end)
end

function VeilService:IsVeilLifted(player: Player): boolean
    return self.LiftedVeils[player] == true
end

function VeilService:IsOnCooldown(player: Player): boolean
    local start = self.Cooldowns[player]
    if not start then return false end
    return (os.clock() - start) < VEIL_COOLDOWN
end

function VeilService:GetDuration(player: Player): number
    return self.UpgradeService:GetUpgradeEffect(player, "VeilDuration")
end

function VeilService:LiftVeil(player: Player)
    if self:IsVeilLifted(player) then return end
    self.LiftedVeils[player] = true

    local duration = self:GetDuration(player)
    self.AstralEchoService:StartEchoes(player)
    self.Client.VeilStarted:Fire(player, duration)
    self.Client.VeilLifted:Fire(player)
    self.VeilStateChanged:Fire(player, true)

    -- Auto-lower after duration expires
    task.delay(duration, function()
        if self:IsVeilLifted(player) then
            self:LowerVeil(player)
        end
    end)
end

function VeilService:LowerVeil(player: Player)
    if not self:IsVeilLifted(player) then return end
    self.LiftedVeils[player] = false
    self.Cooldowns[player] = os.clock()

    self.AstralEchoService:StopEchoes(player)
    self.Client.VeilLowered:Fire(player)
    self.VeilStateChanged:Fire(player, false)
end

-- Client-exposed functions (kept for any future use, but mushroom no longer calls toggle)
function VeilService.Client:IsVeilLifted(player: Player): boolean
    return self.Server:IsVeilLifted(player)
end

function VeilService.Client:IsOnCooldown(player: Player): boolean
    return self.Server:IsOnCooldown(player)
end

return VeilService
