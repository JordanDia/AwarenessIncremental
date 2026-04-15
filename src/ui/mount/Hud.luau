local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local CurrencyHolder = require("../components/CurrencyHolder")
local CurrencyFrame = require("../components/CurrencyFrame")
local LevelBar = require("../components/LevelBar")
local ButtonFrame = require("../components/ButtonFrame")
local ButtonHolder = require("../components/ButtonHolder")
local AbilityButton = require("../components/AbilityButton")
local AbilityButtonHolder = require("../components/AbilityButtonHolder")
local ProfileFrame = require("../components/ProfileFrame")
local ShopFrame = require("../components/ShopFrame")
local DailyQuestsFrame = require("../components/DailyQuestsFrame")

return function(parent)
    local scope = scoped(Fusion, {
        CurrencyHolder = CurrencyHolder,
        CurrencyFrame = CurrencyFrame,
        LevelBar = LevelBar,
        ButtonFrame = ButtonFrame,
        ButtonHolder = ButtonHolder,
        AbilityButton = AbilityButton,
        AbilityButtonHolder = AbilityButtonHolder,
        ProfileFrame = ProfileFrame,
        ShopFrame = ShopFrame,
        DailyQuestsFrame = DailyQuestsFrame,
    })


    local isProfileOpen = false
    local isProfileVisible = scope:Value(false)

    local isShopOpen = false
    local isShopVisible = scope:Value(false)

    local isQuestsOpen = false
    local isQuestsVisible = scope:Value(false)

    local QuestService = Knit.GetService("QuestService")
    
    local DataService = Knit.GetService("DataService")
    local AwarenessService = Knit.GetService("AwarenessService")
    local RebirthService = Knit.GetService("RebirthService")
    local CrystalService = Knit.GetService("CrystalService")
    local AstralEchoService = Knit.GetService("AstralEchoService")
    local HarmonyService = Knit.GetService("HarmonyService")
    local LevelService = Knit.GetService("LevelService")
    local DonateService = Knit.GetService("DonateService")
    local GamepassService = Knit.GetService("GamepassService")
    local BoostService = Knit.GetService("BoostService")

    local awarenessValue = scope:Value(AwarenessService:GetAwareness())
    local rebirthValue = scope:Value(RebirthService:GetRebirths())
    local crystalValue = scope:Value(CrystalService:GetCrystals())
    local echoValue = scope:Value(AstralEchoService:GetEchoes())
    local harmonyValue = scope:Value(HarmonyService:GetHarmony())

    -- Lifetime totals for the profile panel
    local awarnessTotalValue = scope:Value(0)
    local rebirthsTotalValue = scope:Value(0)
    local crystalsTotalValue = scope:Value(0)
    local echoesTotalValue = scope:Value(0)
    local robuxSpentValue = scope:Value(0)
    local firstPlayedValue = scope:Value("...")

    DataService.DataLoaded:Connect(function(data)
        awarenessValue:set(data.Awareness)
        rebirthValue:set(data.Rebirths)
        crystalValue:set(data.Crystals)
        echoValue:set(data.AstralEchoes or 0)
        harmonyValue:set(data.Harmony or 0)
        awarnessTotalValue:set(data.AwarenessTotal or 0)
        rebirthsTotalValue:set(data.RebirthsTotal or 0)
        crystalsTotalValue:set(data.CrystalsTotal or 0)
        echoesTotalValue:set(data.AstralEchoesTotal or 0)
        robuxSpentValue:set(data.RobuxSpent or 0)
    end)

    DonateService.RobuxSpentAdded:Connect(function(amount)
        robuxSpentValue:set(Fusion.peek(robuxSpentValue) + amount)
    end)

    AwarenessService.AwarenessChanged:Connect(function(newAwareness)
        --print("Awareness updated to", newAwareness)
        awarenessValue:set(newAwareness)
    end)

    AwarenessService.AwarenessTotalChanged:Connect(function(total)
        awarnessTotalValue:set(total)
    end)

    RebirthService.RebirthsChanged:Connect(function(newRebirths)
        --print("Rebirths updated to", newRebirths)
        rebirthValue:set(newRebirths)
    end)

    RebirthService.RebirthsTotalChanged:Connect(function(total)
        rebirthsTotalValue:set(total)
    end)

    CrystalService.CrystalsChanged:Connect(function(crystals)
        crystalValue:set(crystals)
    end)

    CrystalService.CrystalsTotalChanged:Connect(function(total)
        crystalsTotalValue:set(total)
    end)

    AstralEchoService.EchoesChanged:Connect(function(echoes)
        echoValue:set(echoes)
    end)

    AstralEchoService.EchoesTotalChanged:Connect(function(total)
        echoesTotalValue:set(total)
    end)

    HarmonyService.HarmonyChanged:Connect(function(harmony)
        harmonyValue:set(harmony)
    end)

    -- Fetch first session time and format as readable date
    task.spawn(function()
        local MONTHS = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
        local t = DataService:GetFirstSessionTime()
        if t then
            local dt = os.date("*t", t)
            firstPlayedValue:set(string.format("First played: %s %d, %d", MONTHS[dt.month], dt.day, dt.year))
        else
            firstPlayedValue:set("")
        end
    end)

    -- Level System
    local level = LevelService:GetLevel()
    local currentXP, neededXP = LevelService:GetXPProgress()
    
    local levelValue = scope:Value(level)
    local currentXPValue = scope:Value(currentXP)
    local neededXPValue = scope:Value(neededXP)

    -- Function to update level UI
    local function UpdateLevelUI()
        local level = LevelService:GetLevel()
        local xp = LevelService:GetXPProgress()

        levelValue:set(level)
        currentXPValue:set(xp.current)
        neededXPValue:set(xp.needed)
    end

    -- Initial update
    UpdateLevelUI()

    -- Listen for XP changes
    LevelService.XPChanged:Connect(UpdateLevelUI)

    -- Listen for level changes
    LevelService.LevelChanged:Connect(function(newLevel, oldLevel)
        UpdateLevelUI()
        --print(`Level up! {oldLevel} -> {newLevel}`)
    end)

    local currencies = scope:Value {

        {
            Name = "AwarenessFrame",
            Value = awarenessValue,
            Icon = "rbxassetid://108300702326871",
            TextColor3 = Color3.fromRGB(255, 215, 0),
            LayoutOrder = 90,
            Visible = scope:Value(true),
        },

        {
            Name = "RebirthFrame",
            Value = rebirthValue,
            Icon = "rbxassetid://87766693277427",
            TextColor3 = Color3.fromRGB(0, 153, 255),
            LayoutOrder = 100,
            Visible = scope:Value(true),
        },

        {
            Name = "CrystalFrame",
            Value = crystalValue,
            Icon = "rbxassetid://78458877619165",
            TextColor3 = Color3.fromRGB(132, 0, 255),
            LayoutOrder = 80,
            Visible = scope:Value(true),
        },

        {
            Name = "AstralEchoFrame",
            Value = echoValue,
            Icon = "rbxassetid://118132965740444",
            TextColor3 = Color3.fromRGB(0, 210, 200),
            LayoutOrder = 70,
            Visible = scope:Value(true),
        },

        -- {
        --     Name = "HarmonyFrame",
        --     Value = harmonyValue,
        --     Icon = "rbxassetid://70601939887941", -- TODO: replace with a Harmony icon
        --     TextColor3 = Color3.fromRGB(55, 210, 95),
        --     LayoutOrder = 60,
        --     Visible = scope:Value(true),
        -- },

    }

    local buttons = scope:Value {

        {
            Name = "ShopButton",
            Icon = "rbxassetid://103530311715340",
            LayoutOrder = 1,
            Visible = true,
            OnActivated = function()
                isShopOpen = not isShopOpen
                isShopVisible:set(isShopOpen)
            end,
        },
        {
            Name = "DailyQuests",
            Icon = "rbxassetid://124847421234505",
            LayoutOrder = 2,
            Visible = true,
            OnActivated = function()
                isQuestsOpen = not isQuestsOpen
                isQuestsVisible:set(isQuestsOpen)
            end,
        },

        -- {
        --     Name = "Spin Wheel",
        --     Icon = "rbxassetid://126776054809349",
        --     LayoutOrder = 3,
        --     Visible = true,
        --     OnActivated = function() print("Spin wheel opened") end,
        -- },

        {
            Name = "Profile",
            Icon = "rbxassetid://126097416319421",
            LayoutOrder = 4,
            Visible = true,
            OnActivated = function()
                isProfileOpen = not isProfileOpen
                isProfileVisible:set(isProfileOpen)
            end,
        },

    }

    local meditateAnywhereActive = scope:Value(false)
    local MEDITATE_ANYWHERE_PASS_ID = 1760349159

    local AUTO_COLLECT_GROUP_ID = 307417534
    local AUTO_COLLECT_RADIUS   = 25 -- studs from CrystalSpawn

    local ZoneController    = Knit.GetController("ZoneController")
    local CrystalController = Knit.GetController("CrystalController")

    local autoCollectVisible = scope:Value(false)
    local autoCollectActive  = scope:Value(false)

    -- Cache group membership so we only check once (IsInGroup yields)
    local isInAutoCollectGroup = false
    task.spawn(function()
        local ok, result = pcall(function()
            return Players.LocalPlayer:IsInGroup(AUTO_COLLECT_GROUP_ID)
        end)
        isInAutoCollectGroup = ok and result
    end)

    -- Proximity check for CrystalSpawn visibility
    local crystalSpawn = workspace:WaitForChild("CrystalSpawn")
    local crystalSpawnPos = crystalSpawn.Position

    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.2 then return end
        elapsed = 0

        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local inRange = root and (root.Position - crystalSpawnPos).Magnitude <= AUTO_COLLECT_RADIUS

        if not inRange and Fusion.peek(autoCollectActive) then
            -- Left the zone while active — turn it off
            autoCollectActive:set(false)
            CrystalController:StopAutoCollect()
        end

        autoCollectVisible:set(inRange and true or false)
    end)

    -- when boost service toggles meditate anywhere, update the button state
    BoostService.MeditateAnywhereBoostChanged:Connect(function(endTime)
        local active = endTime > os.time()
        meditateAnywhereActive:set(active)
        ZoneController:SetMeditateAnywhereOverride(active)
    end)

    local abilityButtons = scope:Value {
        {
            Name = "MeditateAnywhere",
            Label = "Meditate Anywhere",
            LayoutOrder = 1,
            Visible = true,
            Active = meditateAnywhereActive,
            OnActivated = function()
                local success, active = AwarenessService:ToggleMeditateAnywhere()
                if success then
                    meditateAnywhereActive:set(active)
                    ZoneController:SetMeditateAnywhereOverride(active)
                else
                    GamepassService:PromptPurchase(MEDITATE_ANYWHERE_PASS_ID)
                end
            end,
        },
        {
            Name = "AutoCollect",
            Label = "Auto Collect",
            LayoutOrder = 2,
            Visible = autoCollectVisible,
            Active = autoCollectActive,
            OnActivated = function()
                if not isInAutoCollectGroup then
                    StarterGui:SetCore("SendNotification", {
                        Title = "Group Required",
                        Text = "Join group " .. AUTO_COLLECT_GROUP_ID .. " to use Auto Collect!",
                        Duration = 5,
                    })
                    return
                end
                local active = not Fusion.peek(autoCollectActive)
                autoCollectActive:set(active)
                if active then
                    CrystalController:StartAutoCollect()
                else
                    CrystalController:StopAutoCollect()
                end
            end,
        },
    }

    local screenGui = scope:New "ScreenGui" {
        Name = "Hud",
        Parent = parent,
        ResetOnSpawn = false,

        [Fusion.Children] = {
        
            scope:CurrencyHolder {
                Currencies = currencies,
            },

            scope:LevelBar {
                Level = levelValue,
                CurrentXP = currentXPValue,
                NeededXP = neededXPValue
            },

            scope:ButtonHolder {
                Buttons = buttons
            },

            scope:AbilityButtonHolder {
                Buttons = abilityButtons
            },

            scope:ShopFrame {
                Visible = isShopVisible,
                GamepassService = GamepassService,
                OnClose = function()
                    isShopOpen = false
                    isShopVisible:set(false)
                end,
            },

            scope:DailyQuestsFrame {
                Visible = isQuestsVisible,
                QuestService = QuestService,
                OnClose = function()
                    isQuestsOpen = false
                    isQuestsVisible:set(false)
                end,
            },

            scope:ProfileFrame {
                Visible = isProfileVisible,
                OnClose = function()
                    isProfileOpen = false
                    isProfileVisible:set(false)
                end,
                Level = levelValue,
                AwarenessTotal = awarnessTotalValue,
                Rebirths = rebirthValue,
                RebirthsTotal = rebirthsTotalValue,
                CrystalsTotal = crystalsTotalValue,
                AstralEchoesTotal = echoesTotalValue,
                RobuxSpent = robuxSpentValue,
                FirstPlayed = firstPlayedValue,
            },

        }


    }

    return screenGui
end




