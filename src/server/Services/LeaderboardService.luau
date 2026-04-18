local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- OrderedDataStore names
local STORE_AWARENESS = "LB_Awareness_v2"
local STORE_REBIRTHS  = "LB_Rebirths_v2"
local STORE_CRYSTALS  = "LB_Crystals_v2"
local STORE_ECHOES    = "LB_AstralEchoes_v2"
local STORE_ROBUX     = "LB_RobuxSpent"
local STORE_PLAYTIME  = "LB_Playtime"

local CATEGORIES = {
    { id = "TopAwareness",    label = "Top Awareness",     storeId = STORE_AWARENESS, dataKey = "AwarenessTotal",    wholeNumber = true, maxValue = 1e99 },
    { id = "TopRebirths",     label = "Top Rebirths",      storeId = STORE_REBIRTHS,  dataKey = "RebirthsTotal",     wholeNumber = true, maxValue = 1e30 },
    { id = "TopCrystals",     label = "Top Crystals",      storeId = STORE_CRYSTALS,  dataKey = "CrystalsTotal",     wholeNumber = true, maxValue = 1e30 },
    { id = "TopAstralEchoes", label = "Top Astral Echoes", storeId = STORE_ECHOES,    dataKey = "AstralEchoesTotal", wholeNumber = true, maxValue = 1e50 },
    { id = "TopRobuxSpent",   label = "Top Robux Spent",   storeId = STORE_ROBUX,     dataKey = "RobuxSpent",        rawValue = true,    maxValue = 1e99 },
    { id = "TopTimePlayed",   label = "Top Time Played",   storeId = STORE_PLAYTIME,  dataKey = "PlaytimeSeconds",   rawValue = true,    maxValue = 1e8  },
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

local LOG_BASE = 1.0000001

local function encodeValue(value)
    if value <= 0 then return 0 end
    if value ~= value or value == math.huge then return 0 end -- NaN or inf guard
    return math.floor(math.log(value) / math.log(LOG_BASE))
end

local function decodeValue(stored)
    if stored == 0 then return 0 end
    local result = LOG_BASE ^ stored
    if result ~= result or result == math.huge then return nil end -- NaN or inf → exclude
    return result
end

function LeaderboardService:_UpdatePlayerStats(player)
    local profile = self.DataService:GetProfile(player)
    if not profile then return end

    for _, category in ipairs(CATEGORIES) do
        local raw = profile.Data[category.dataKey]
        if raw == nil then continue end
        if category.maxValue and raw > category.maxValue then continue end
        local store = self._stores[category.id]
        local encoded = category.rawValue and math.floor(raw) or encodeValue(raw)
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
        local decoded = category.rawValue and entry.value or decodeValue(entry.value)
        if not decoded then continue end
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
        local displayValue = category.wholeNumber and math.round(item.value) or item.value
        table.insert(entries, {
            rank  = rank,
            name  = names[i],
            value = displayValue,
        })
    end
    self._cache[category.id] = entries
end

function LeaderboardService:_RefreshAllLeaderboards()
    -- Refresh all categories in parallel; notify client as each one completes
    for _, category in ipairs(CATEGORIES) do
        task.spawn(function()
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

    -- Refresh immediately on start, then every 60s
    task.spawn(function()
        self:_RefreshAllLeaderboards()
        while true do
            task.wait(60)
            self:_RefreshAllLeaderboards()
        end
    end)
end

-- Client RPC: return cached leaderboard for a category
function LeaderboardService.Client:GetLeaderboard(_player, categoryId)
    return self.Server._cache[categoryId] or {}
end

return LeaderboardService
