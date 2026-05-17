local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local num  = require(ReplicatedStorage.Shared.Modules.Quicknum)

-- OrderedDataStore names
local STORE_AWARENESS = "LB_Awareness_v3"
local STORE_REBIRTHS  = "LB_Rebirths_v3"
local STORE_CRYSTALS  = "LB_Crystals_v3"
local STORE_ECHOES    = "LB_AstralEchoes_v3"
local STORE_ROBUX     = "LB_RobuxSpent"
local STORE_PLAYTIME  = "LB_Playtime"
local STORE_ESSENCES  = "LB_Essences_v1"
local STORE_DARK_ESSENCES = "LB_DarkEssences_v1"
local STORE_RAID_WINS = "LB_RaidWins_v1"

-- qnField = true means the value is a Quicknum buffer; use lbencode/lbdecode
local CATEGORIES = {
    { id = "TopAwareness",    label = "Top Awareness",     storeId = STORE_AWARENESS, dataKey = "AwarenessTotal",    qnField = true  },
    { id = "TopRebirths",     label = "Top Rebirths",      storeId = STORE_REBIRTHS,  dataKey = "RebirthsTotal",     qnField = true  },
    { id = "TopCrystals",     label = "Top Crystals",      storeId = STORE_CRYSTALS,  dataKey = "CrystalsTotal",     qnField = true  },
    { id = "TopAstralEchoes", label = "Top Astral Echoes", storeId = STORE_ECHOES,    dataKey = "AstralEchoesTotal", qnField = true  },
    { id = "TopRobuxSpent",   label = "Top Robux Spent",   storeId = STORE_ROBUX,     dataKey = "RobuxSpent",        rawValue = true },
    { id = "TopTimePlayed",   label = "Top Time Played",   storeId = STORE_PLAYTIME,  dataKey = "PlaytimeSeconds",   rawValue = true },
    { id = "TopEssences",     label = "Top Essences",      storeId = STORE_ESSENCES,  dataKey = "EssencesTotal",     qnField = true  },
    { id = "TopDarkEssences", label = "Top Dark Essences", storeId = STORE_DARK_ESSENCES, dataKey = "DarkEssencesTotal", qnField = true },
    { id = "TopRaidWins",     label = "Top Raid Wins",     storeId = STORE_RAID_WINS, dataKey = "RaidWins",          rawValue = true },
}

local BLOCKED_USER_IDS = {
    [33124593] = true,

}

local usernameCache = {}

local function getUserName(userId)
    if usernameCache[userId] then
        return usernameCache[userId]
    end
    -- Resolve instantly if the player is currently in the server
    for _, player in Players:GetPlayers() do
        if player.UserId == userId then
            usernameCache[userId] = player.Name
            return player.Name
        end
    end
    -- Fall back to API with exponential backoff
    for attempt = 1, 5 do
        local ok, name = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        if ok and name then
            usernameCache[userId] = name
            return name
        end
        task.wait(2 ^ attempt) -- 2, 4, 8, 16, 32s back-off
    end
    return nil -- exclude rather than show Player_XXXXX
end

local LeaderboardService = Knit.CreateService {
    Name = "LeaderboardService",
    Client = {
        LeaderboardRefreshed = Knit.CreateSignal(),
    },
}

LeaderboardService._stores = {}
LeaderboardService._cache  = {}

-- Build ordered data stores on init
for _, category in ipairs(CATEGORIES) do
    LeaderboardService._stores[category.id] = DataStoreService:GetOrderedDataStore(category.storeId)
    LeaderboardService._cache[category.id]  = {}
end

function LeaderboardService:_UpdatePlayerStats(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    for _, category in ipairs(CATEGORIES) do
        local encoded
        if category.qnField then
            local buf = self.DataService:GetQN(player, category.dataKey)
            if num.isZero(buf) then continue end
            encoded = num.lbencode(buf)
        else
            local raw = profile.Data[category.dataKey]
            if raw == nil or raw <= 0 then continue end
            encoded = math.floor(raw)
        end
        local store = self._stores[category.id]
        local ok, err = pcall(function()
            store:SetAsync(tostring(player.UserId), encoded)
        end)
        if not ok then
            warn("[LeaderboardService] SetAsync failed for", category.id, ":", err)
        end
    end
end

function LeaderboardService:_RefreshCategory(category)
    local store = self._stores[category.id]
    local ok, pages = pcall(function()
        return store:GetSortedAsync(false, 100)
    end)
    if not ok or not pages then
        warn("[LeaderboardService] GetSortedAsync failed for", category.id, ":", pages)
        return
    end

    local pageOk, pageData = pcall(function()
        return pages:GetCurrentPage()
    end)
    if not pageOk then
        warn("[LeaderboardService] GetCurrentPage failed for", category.id, ":", pageData)
        return
    end

    -- Filter valid entries first
    local valid = {}
    for _, entry in ipairs(pageData) do
        local userId = tonumber(entry.key)
        if not userId or userId <= 0 then continue end
        if BLOCKED_USER_IDS[userId] then continue end
        if entry.value <= 0 then continue end
        local decoded = category.rawValue and entry.value or num.lbdecode(entry.value)
        if decoded == nil then continue end
        table.insert(valid, { userId = userId, value = decoded })
    end

    -- Resolve all usernames in parallel
    local names = table.create(#valid)
    local pending = #valid
    if pending == 0 then
        self._cache[category.id] = {}
        return
    end

    local done = Instance.new("BindableEvent")
    for i, item in ipairs(valid) do
        task.spawn(function()
            names[i] = getUserName(item.userId)
            pending -= 1
            if pending == 0 then
                done:Fire()
            end
        end)
    end
    if pending > 0 then
        done.Event:Wait()
    end
    done:Destroy()

    local entries = {}
    local rank = 0
    for i, item in ipairs(valid) do
        if not names[i] then continue end -- skip if name resolution failed
        rank += 1
        local displayValue = item.value
        table.insert(entries, {
            rank  = rank,
            name  = names[i],
            value = displayValue,
        })
    end
    self._cache[category.id] = entries
end

function LeaderboardService:_RefreshAllLeaderboards()
    -- Stagger refreshes to avoid DataStore throttling (10s between each)
    for i, category in ipairs(CATEGORIES) do
        task.delay((i - 1) * 10, function()
            self:_RefreshCategory(category)
            self.Client.LeaderboardRefreshed:FireAll(category.id)
        end)
    end
end

function LeaderboardService:KnitStart()
    self.DataService  = Knit.GetService("DataService")
    self.DonateService = Knit.GetService("DonateService")

    -- Immediately update RobuxSpent store when a player spends Robux
    self.DonateService.HasRobuxSpentAdded:Connect(function(player, _amount)
        local profile = self.DataService:GetProfile(player)
        if not profile then return end
        pcall(function()
            self._stores["TopRobuxSpent"]:SetAsync(tostring(player.UserId), math.floor(profile.Data.RobuxSpent or 0))
        end)
    end)

    -- Playtime loop: add 60s every minute
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                local profile = self.DataService:GetProfile(player)
                if profile then
                    profile.Data.PlaytimeSeconds = (profile.Data.PlaytimeSeconds or 0) + 60
                end
            end
        end
    end)

    -- Stats update loop: every 60s
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                self:_UpdatePlayerStats(player)
            end
        end
    end)

    -- Refresh immediately on start, then every 3 minutes
    task.spawn(function()
        self:_RefreshAllLeaderboards()
        while true do
            task.wait(180)
            self:_RefreshAllLeaderboards()
        end
    end)
end

-- Client RPC: return cached leaderboard for a category
function LeaderboardService.Client:GetLeaderboard(_player, categoryId)
    return self.Server._cache[categoryId] or {}
end

return LeaderboardService
