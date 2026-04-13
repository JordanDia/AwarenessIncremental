local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- OrderedDataStore names
local STORE_AWARENESS = "LB_Awareness"
local STORE_REBIRTHS  = "LB_Rebirths"
local STORE_CRYSTALS  = "LB_Crystals"
local STORE_ECHOES    = "LB_AstralEchoes"
local STORE_ROBUX     = "LB_RobuxSpent"
local STORE_PLAYTIME  = "LB_Playtime"

local CATEGORIES = {
    { id = "TopAwareness",    label = "Top Awareness",     storeId = STORE_AWARENESS, dataKey = "AwarenessTotal" },
    { id = "TopRebirths",     label = "Top Rebirths",      storeId = STORE_REBIRTHS,  dataKey = "RebirthsTotal" },
    { id = "TopCrystals",     label = "Top Crystals",      storeId = STORE_CRYSTALS,  dataKey = "CrystalsTotal" },
    { id = "TopAstralEchoes", label = "Top Astral Echoes", storeId = STORE_ECHOES,    dataKey = "AstralEchoesTotal" },
    { id = "TopRobuxSpent",   label = "Top Robux Spent",   storeId = STORE_ROBUX,     dataKey = "RobuxSpent" },
    { id = "TopTimePlayed",   label = "Top Time Played",   storeId = STORE_PLAYTIME,  dataKey = "PlaytimeSeconds" },
}

local BLOCKED_USER_IDS = { [33124593] = true }

local usernameCache = {}

local function getUserName(userId)
    if usernameCache[userId] then
        return usernameCache[userId]
    end
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

    local MAX_INT = 2^53 - 1

    for _, category in ipairs(CATEGORIES) do
        local raw = profile.Data[category.dataKey]
        if raw == nil then continue end
        local value = math.min(math.floor(raw), MAX_INT)
        if value < 0 then
            value = 0
        end
        local store = self._stores[category.id]
        pcall(function()
            store:SetAsync(tostring(player.UserId), value)
        end)
    end
end

function LeaderboardService:_RefreshCategory(category)
    local store = self._stores[category.id]
    local ok, pages = pcall(function()
        return store:GetSortedAsync(false, 100)
    end)
    if not ok or not pages then return end

    local pageOk, pageData = pcall(function()
        return pages:GetCurrentPage()
    end)
    if not pageOk then return end

    -- Filter valid entries first
    local valid = {}
    for _, entry in ipairs(pageData) do
        local userId = tonumber(entry.key)
        if not userId or userId <= 0 then continue end
        if BLOCKED_USER_IDS[userId] then continue end
        if entry.value <= 0 then continue end
        table.insert(valid, { userId = userId, value = entry.value })
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
    done.Event:Wait()
    done:Destroy()

    local entries = {}
    local rank = 0
    for i, item in ipairs(valid) do
        if not names[i] then continue end -- skip if name resolution failed
        rank += 1
        table.insert(entries, {
            rank  = rank,
            name  = names[i],
            value = item.value,
        })
    end
    self._cache[category.id] = entries
end

function LeaderboardService:_RefreshAllLeaderboards()
    -- Refresh all categories in parallel
    local pending = #CATEGORIES
    local done = Instance.new("BindableEvent")
    for _, category in ipairs(CATEGORIES) do
        task.spawn(function()
            self:_RefreshCategory(category)
            pending -= 1
            if pending == 0 then
                done:Fire()
            end
        end)
    end
    done.Event:Wait()
    done:Destroy()

    self.Client.LeaderboardRefreshed:FireAll()
end

function LeaderboardService:KnitStart()
    self.DataService  = Knit.GetService("DataService")
    self.DonateService = Knit.GetService("DonateService")

    -- Immediately update RobuxSpent store when a player spends Robux
    self.DonateService.HasRobuxSpentAdded:Connect(function(player, _amount)
        local profile = self.DataService:GetProfile(player)
        if not profile then return end
        local value = math.min(math.floor(profile.Data.RobuxSpent or 0), 2^53 - 1)
        if value < 0 then
            value = 0
        end
        pcall(function()
            self._stores["TopRobuxSpent"]:SetAsync(tostring(player.UserId), value)
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
