local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GamepassConfig = require(ReplicatedStorage.Shared.Configs.GamepassConfig)

local GamepassService = Knit.CreateService {
    Name = "GamepassService",
    Client = {
        -- Fires to a client when their owned passes are confirmed, so the UI can reflect ownership
        PassesLoaded = Knit.CreateSignal(), -- (ownedPassIds: {number})
    },
}

-- Build a lookup table: PassId -> config entry
local PASS_BY_ID = {}
for _, pass in ipairs(GamepassConfig) do
    PASS_BY_ID[pass.PassId] = pass
end

function GamepassService:KnitStart()
    self.MultiplierService = Knit.GetService("MultiplierService")
    self.DataService = Knit.GetService("DataService")

    -- Apply passes for players already loaded (handles race condition on start)
    for player in self.DataService.Profiles do
        task.spawn(function()
            self:_ApplyPassesForPlayer(player)
        end)
    end

    self.DataService.ProfileLoaded:Connect(function(player)
        task.spawn(function()
            self:_ApplyPassesForPlayer(player)
        end)
    end)

    -- Handle purchases made while the game is running
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
        if not wasPurchased then return end
        local pass = PASS_BY_ID[passId]
        if not pass then return end
        self:_ApplyPass(player, pass)
        print(`[GamepassService] {player.Name} purchased {pass.Name}`)
    end)
end

-- Check all passes for a player and apply any they own
function GamepassService:_ApplyPassesForPlayer(player)
    local owned = {}
    for _, pass in ipairs(GamepassConfig) do
        local ok, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.PassId)
        end)
        if ok and owns then
            self:_ApplyPass(player, pass)
            table.insert(owned, pass.PassId)
        end
    end
    self.Client.PassesLoaded:Fire(player, owned)
end

-- Apply the multiplier effect for a single pass
function GamepassService:_ApplyPass(player, pass)
    if pass.Stat and pass.Value then
        self.MultiplierService:SetSource(player, pass.Stat, "Gamepass_" .. pass.PassId, pass.Value)
    end
    -- Custom pass logic (e.g. MeditateAnywhere) would go here with an if on pass.PassId
end

-- Client calls this to open the purchase prompt for a pass
function GamepassService.Client:PromptPurchase(player, passId)
    MarketplaceService:PromptGamePassPurchase(player, passId)
end

return GamepassService
