local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService  = game:GetService("AnalyticsService")
local UpgradeService = require("./UpgradeService")
local DarkSpiritConfig = require(ReplicatedStorage.Shared.Configs.DarkSpiritConfig)
local Knit              = require(ReplicatedStorage.Packages.Knit)
local num               = require(ReplicatedStorage.Shared.Modules.Quicknum)

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local SIT_SETTLE_TIME   = 0.6

local SUMMON_REGEN_SECONDS = 600 -- 10 minutes
local MAX_SUMMON_PRODUCT_ID = 3578003439

local AstralProjectionService = Knit.CreateService {
    Name = "AstralProjectionService",
    Client = {
        ProjectionStarted   = Knit.CreateSignal(),
        ProjectionEnded     = Knit.CreateSignal(),
        EssencesChanged     = Knit.CreateSignal(),
        DarkEssencesChanged = Knit.CreateSignal(),
        DarkSpiritSpawned   = Knit.CreateSignal(),
        SummonsChanged      = Knit.CreateSignal(), -- fires (summons, maxSummons)
    },
}

AstralProjectionService._projecting      = {} -- [player] = true
AstralProjectionService._astralBodies    = {} -- [player] = clone Model
AstralProjectionService._highlights      = {} -- [player] = Highlight
AstralProjectionService._activeDarkSpirit = {} -- [player] = true (one at a time)
AstralProjectionService.DataService      = nil

local function makeBodyClone(character: Model)
    character.Archivable = true
    local clone = character:Clone()
    character.Archivable = false

    clone.Name = "AstralBody"

    for _, obj in clone:GetDescendants() do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
            or obj:IsA("ProximityPrompt") or obj:IsA("Animator") or obj:IsA("Humanoid")
        then
            obj:Destroy()
        end
    end

    for _, part in clone:GetDescendants() do
        if part:IsA("BasePart") then
            part.Anchored   = true
            part.CanCollide = false
        end
    end

    clone.Parent = workspace
    return clone
end

local REQUIRED_AWAKENING_LEVEL = 6

function AstralProjectionService:KnitInit()
    self.DataService       = Knit.GetService("DataService")
    self.DonateService     = Knit.GetService("DonateService")
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.AwarenessService  = Knit.GetService("AwarenessService")
    self.RebirthService    = Knit.GetService("RebirthService")
    self.CrystalService    = Knit.GetService("CrystalService")
    self.AstralEchoService = Knit.GetService("AstralEchoService")
    self.AwakeningService  = Knit.GetService("AwakeningService")
end

function AstralProjectionService:AddEssences(player: Player, amount: number)
    if not self.DataService:GetProfile(player) then return end
    local multiplied = num.mul(num.fromNumber(amount), self.MultiplierService:GetMultiplier(player, "Essences"))
    local newEssences = self.DataService:AddQN(player, "Essences", multiplied)
    self.Client.EssencesChanged:Fire(player, newEssences)
end

function AstralProjectionService:AddDarkEssences(player: Player, amount: number)
    if not self.DataService:GetProfile(player) then return end
    local multiplied = num.mul(num.fromNumber(amount), self.MultiplierService:GetMultiplier(player, "DarkEssences"))
    local newDark = self.DataService:AddQN(player, "DarkEssences", multiplied)
    self.Client.DarkEssencesChanged:Fire(player, newDark)
end

function AstralProjectionService:_FireSummonsChanged(player: Player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local data = profile.Data
    local queue = data.SummonRegenQueue or {}
    -- Next regen time is the earliest (smallest) timestamp in the queue
    local nextRegen = queue[1] or 0
    self.Client.SummonsChanged:Fire(player, data.Summons, data.MaxSummons, nextRegen)
end

-- Ensures queue has an entry for every missing summon slot.
-- Called after _ProcessSummonQueue so we only fill genuine gaps.
function AstralProjectionService:_FillSummonQueue(player: Player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local data    = profile.Data
    local queue   = data.SummonRegenQueue
    local missing = (data.MaxSummons or 1) - (data.Summons or 1) - #queue

    if missing <= 0 then return end

    -- Chain from the last existing entry, or from now if the queue is empty
    local base = queue[#queue] or os.time()
    for i = 1, missing do
        local regenTime = base + i * SUMMON_REGEN_SECONDS
        table.insert(queue, regenTime)
        self:_ScheduleSummonRegen(player, regenTime)
    end
end

-- Spawns a thread that sleeps until regenTime, then processes the queue.
function AstralProjectionService:_ScheduleSummonRegen(player: Player, regenTime: number)
    task.spawn(function()
        local waitTime = regenTime - os.time()
        if waitTime > 0 then
            task.wait(waitTime)
        end
        if not player.Parent then return end -- player left
        self:_ProcessSummonQueue(player)
    end)
end

-- Process the queue: award summons for any entries that have matured.
-- Call on join and on the regen tick loop.
function AstralProjectionService:_ProcessSummonQueue(player: Player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end
    local data = profile.Data
    local queue = data.SummonRegenQueue
    if not queue then
        data.SummonRegenQueue = {}
        return
    end

    -- Sort so earliest entries are processed first (guards against any save/load reordering)
    table.sort(queue)

    local now = os.time()
    local changed = false

    while #queue > 0 and queue[1] <= now do
        if (data.Summons or 0) < (data.MaxSummons or 1) then
            data.Summons = (data.Summons or 0) + 1
            changed = true
        end
        table.remove(queue, 1)
    end

    if changed then
        self:_FireSummonsChanged(player)
    end
end

function AstralProjectionService:KnitStart()
    -- Register dev product handler for buying an extra max summon
    self.DonateService:RegisterProductHandler(MAX_SUMMON_PRODUCT_ID, function(player, dataService)
        local profile = dataService.Profiles[player]
        if not profile then return nil end
        profile.Data.MaxSummons = (profile.Data.MaxSummons or 1) + 1
        profile.Data.Summons    = (profile.Data.Summons    or 0) + 1
        -- Fire signal via task.defer so we're not inside UpdateAsync
        task.defer(function()
            self:_FireSummonsChanged(player)
        end)
        return true
    end)

    -- On join: award already-matured entries, schedule threads for the rest,
    -- then fill any gaps so the player is always working toward max summons
    self.DataService.ProfileLoaded:Connect(function(player)
        self:_ProcessSummonQueue(player)
        local profile = self.DataService:GetProfile(player)
        if not profile then return end
        for _, regenTime in profile.Data.SummonRegenQueue or {} do
            self:_ScheduleSummonRegen(player, regenTime)
        end
        self:_FillSummonQueue(player)
    end)

    local promptPart = workspace:WaitForChild("AstralProjectionPart")
    local prompt     = promptPart:WaitForChild("ProximityPrompt")

    local function stopProjection(player)
        self._projecting[player] = nil
        self._activeDarkSpirit[player] = nil
        if self._astralBodies[player] then
            self._astralBodies[player]:Destroy()
            self._astralBodies[player] = nil
        end
        if self._highlights[player] then
            self._highlights[player]:Destroy()
            self._highlights[player] = nil
        end
        self.Client.ProjectionEnded:Fire(player)
    end

    local PROJECTION_RANGE = 225

    -- Per-player loop: cancels projection when the player walks out of range
    local function startRangeCheck(player)
        task.spawn(function()
            while self._projecting[player] do
                task.wait(0.5)
                if not self._projecting[player] then break end
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (root.Position - promptPart.Position).Magnitude
                    if dist > PROJECTION_RANGE then
                        stopProjection(player)
                        break
                    end
                end
            end
        end)
    end

    prompt.Triggered:Connect(function(player)
        if self._projecting[player] then
            stopProjection(player)
            return
        end

        if self.AwakeningService:GetLevel(player) < REQUIRED_AWAKENING_LEVEL then
            return
        end

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        self._projecting[player] = true

        local prevWalkSpeed = humanoid.WalkSpeed
        local prevJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed     = 0
        humanoid.JumpPower     = 0
        humanoid.PlatformStand = true

        task.wait(SIT_SETTLE_TIME)

        self._astralBodies[player] = makeBodyClone(character)

        humanoid.PlatformStand = false
        humanoid.WalkSpeed = prevWalkSpeed > 0 and prevWalkSpeed or DEFAULT_WALKSPEED
        humanoid.JumpPower = prevJumpPower > 0 and prevJumpPower or DEFAULT_JUMPPOWER

        local highlight = Instance.new("Highlight")
        highlight.FillColor           = Color3.new(1, 1, 1)
        highlight.FillTransparency    = 0.5
        highlight.OutlineColor        = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = character
        self._highlights[player] = highlight
        startRangeCheck(player)

        -- First-time projection: log funnel and dismiss the tutorial beam
        local profile = self.DataService:GetProfile(player)
        if profile and not profile.Data.Analytics_FirstAstralProjection then
            profile.Data.Analytics_FirstAstralProjection = true
            pcall(function()
                AnalyticsService:LogFunnelStepEvent(player, "PlayerProgression", tostring(player.UserId), 5, "First Astral Projection")
            end)
            self.AwakeningService.Client.AstralProjectionBeamChanged:Fire(player, false)
        end

        self.Client.ProjectionStarted:Fire(player)
    end)

    -- Wire up death and character-added handlers when a character spawns
    local function onCharacterAdded(player, character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            if self._projecting[player] then
                stopProjection(player)
            end
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
        end)
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
    end)

    for _, player in Players:GetPlayers() do
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
        end)
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        if self._projecting[player] then
            stopProjection(player)
        end
        self._activeDarkSpirit[player] = nil
    end)
end

function AstralProjectionService:GetSummons(player: Player): (number, number, number)
    local profile = self.DataService:GetProfile(player)
    if not profile then return 1, 1, 0 end
    local data = profile.Data
    local queue = data.SummonRegenQueue or {}
    return data.Summons or 1, data.MaxSummons or 1, queue[1] or 0
end

function AstralProjectionService.Client:GetSummons(player: Player): (number, number, number)
    return self.Server:GetSummons(player)
end

function AstralProjectionService:GetEssences(player: Player)
    return self.DataService:GetQN(player, "Essences")
end

function AstralProjectionService.Client:PurifySpirit(player: Player)
    local amount = UpgradeService:GetUpgradeEffect(player, "EssenceValue") or 1
    self.Server:AddEssences(player, amount)
end



function AstralProjectionService.Client:GetEssences(player: Player): number
    return self.Server:GetEssences(player)
end

function AstralProjectionService:GetDarkEssences(player: Player)
    return self.DataService:GetQN(player, "DarkEssences")
end

function AstralProjectionService.Client:GetDarkEssences(player: Player): number
    return self.Server:GetDarkEssences(player)
end

function AstralProjectionService.Client:SpawnDarkSpirit(player: Player)
    if not self.Server._projecting[player] then return false end
    if self.Server._activeDarkSpirit[player] then return false end

    local profile = self.Server.DataService:GetProfile(player)
    if not profile then return false end

    local data = profile.Data
    local ds = self.Server.DataService

    -- Check summons
    if (data.Summons or 0) < 1 then return false end

    local cost = DarkSpiritConfig.SpawnCost
    if not DarkSpiritConfig.FreeInStudio then
        if num.lt(ds:GetQN(player, "Essences"),     cost.Essences)     then return false end
        if num.lt(ds:GetQN(player, "Awareness"),    cost.Awareness)    then return false end
        if num.lt(ds:GetQN(player, "Crystals"),     cost.Crystals)     then return false end
        if num.lt(ds:GetQN(player, "AstralEchoes"), cost.AstralEchoes) then return false end
        if num.lt(ds:GetQN(player, "Rebirths"),     cost.Rebirths)     then return false end
    end

    -- Consume one summon, enqueue regen time, and schedule the wake-up thread
    data.Summons = (data.Summons or 1) - 1
    if not data.SummonRegenQueue then
        data.SummonRegenQueue = {}
    end
    local regenTime = os.time() + SUMMON_REGEN_SECONDS
    table.insert(data.SummonRegenQueue, regenTime)
    self.Server:_ScheduleSummonRegen(player, regenTime)
    self.Server:_FireSummonsChanged(player)

    -- Deduct all costs
    local srv = self.Server
    srv.AwarenessService:RemoveAwareness(player, cost.Awareness)
    srv.CrystalService:RemoveCrystals(player, cost.Crystals)
    srv.AstralEchoService:RemoveEchoes(player, cost.AstralEchoes)
    -- Rebirths are fully consumed (spent entirely)
    srv.RebirthService:RemoveRebirths(player, ds:GetQN(player, "Rebirths"))
    -- Essences deducted directly
    local newEssences = num.sub(ds:GetQN(player, "Essences"), cost.Essences)
    ds:SetQN(player, "Essences", newEssences)
    self.Server.Client.EssencesChanged:Fire(player, newEssences)

    self.Server._activeDarkSpirit[player] = true
    self.Server.Client.DarkSpiritSpawned:Fire(player)
    return true
end

function AstralProjectionService.Client:PurifyDarkSpirit(player: Player)
    self.Server:AddDarkEssences(player, 1)
    self.Server._activeDarkSpirit[player] = nil
end

return AstralProjectionService
