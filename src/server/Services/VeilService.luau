local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VeilService = Knit.CreateService {
    Name = "VeilService",
    Client = {
        VeilLifted  = Knit.CreateSignal(), -- server → client: veil has been lifted
        VeilLowered = Knit.CreateSignal(), -- server → client: veil has been lowered
    }
}

VeilService.VeilStateChanged = Signal.new() -- (player, isLifted: boolean)
VeilService.LiftedVeils = {}



function VeilService:KnitStart()
    self.DataService       = Knit.GetService("DataService")
    self.UnlockService     = Knit.GetService("UnlockService")
    self.AstralEchoService = Knit.GetService("AstralEchoService")

    -- Hook up the mushroom prompt
    local mushroom = workspace:WaitForChild("Mushroom")
    local prompt = mushroom:FindFirstChildWhichIsA("ProximityPrompt", true)

    if prompt then
        prompt.Triggered:Connect(function(player)
            self:ToggleVeil(player)
        end)
    else
        warn("VeilService: No ProximityPrompt found in workspace.Mushroom")
    end
end

-- Returns whether the veil is currently lifted for a player
function VeilService:IsVeilLifted(player: Player): boolean
    return self.LiftedVeils[player] == true
end


-- TODO: Create effect where STW Blur slowly bounces up and down (tween Size from 7 to 9, then 9 to 7, etc)
function VeilService:LiftVeil(player: Player)
    if self:IsVeilLifted(player) then return end
    self.LiftedVeils[player] = true

    self.AstralEchoService:StartEchoes(player)
    self.Client.VeilLifted:Fire(player)
    self.VeilStateChanged:Fire(player, true)
end

function VeilService:LowerVeil(player: Player)
    if not self:IsVeilLifted(player) then return end
    self.LiftedVeils[player] = false

    self.AstralEchoService:StopEchoes(player)
    self.Client.VeilLowered:Fire(player)
    self.VeilStateChanged:Fire(player, false)
end

-- Toggles the veil state
function VeilService:ToggleVeil(player: Player)
    if self:IsVeilLifted(player) then
        self:LowerVeil(player)
    else
        self:LiftVeil(player)
    end
end

-- Client-exposed functions
function VeilService.Client:LiftVeil(player: Player)
    self.Server:LiftVeil(player)
end

function VeilService.Client:LowerVeil(player: Player)
    self.Server:LowerVeil(player)
end

function VeilService.Client:ToggleVeil(player: Player)
    self.Server:ToggleVeil(player)
end

function VeilService.Client:IsVeilLifted(player: Player): boolean
    return self.Server:IsVeilLifted(player)
end

return VeilService
