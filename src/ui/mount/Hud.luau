local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
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
    })

    local isProfileOpen = false
    local isProfileVisible = scope:Value(false)

    local isShopOpen = false
    local isShopVisible = scope:Value(false)
    
    local DataService = Knit.GetService("DataService")
    local AwarenessService = Knit.GetService("AwarenessService")
    local RebirthService = Knit.GetService("RebirthService")
    local CrystalService = Knit.GetService("CrystalService")
    local AstralEchoService = Knit.GetService("AstralEchoService")
    local HarmonyService = Knit.GetService("HarmonyService")
    local LevelService = Knit.GetService("LevelService")
    local GamepassService = Knit.GetService("GamepassService")

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
    local harmonyTotalValue = scope:Value(0)

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
        harmonyTotalValue:set(data.HarmonyTotal or 0)
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

    HarmonyService.HarmonyTotalChanged:Connect(function(total)
        harmonyTotalValue:set(total)
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
        local currentXP, neededXP = LevelService:GetXPProgress()
        
        levelValue:set(level)
        currentXPValue:set(currentXP)
        neededXPValue:set(neededXP)
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

        {
            Name = "HarmonyFrame",
            Value = harmonyValue,
            Icon = "rbxassetid://70601939887941", -- TODO: replace with a Harmony icon
            TextColor3 = Color3.fromRGB(55, 210, 95),
            LayoutOrder = 60,
            Visible = scope:Value(true),
        },

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
            Name = "Inventory",
            Icon = "rbxassetid://112883503105803",
            LayoutOrder = 2,
            Visible = true,
            OnActivated = function() print("Rebirth opened") end,
        },

        {
            Name = "Spin Wheel",
            Icon = "rbxassetid://126776054809349",
            LayoutOrder = 3,
            Visible = true,
            OnActivated = function() print("Spin wheel opened") end,
        },

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

    local abilityButtons = scope:Value {
        {
            Name = "PrayAnywhere",
            Label = "Pray Anywhere",
            LayoutOrder = 1,
            Visible = true,
            OnActivated = function()
                -- PrayService:PrayAnywhere() or similar
                print("Pray Anywhere activated")
            end,
        },
        {
            Name = "AutoDrain",
            Label = "Auto Drain",
            LayoutOrder = 2,
            Visible = true,
            OnActivated = function()
                print("Auto Drain activated")
            end,
        },
        {
            Name = "SeeThroughWorld",
            Label = "See Through World",
            LayoutOrder = 3,
            Visible = true,
            OnActivated = function()
                -- AstralEchoController:ActivateSeeThroughWorld()
                print("See Through World activated")
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
                HarmonyTotal = harmonyTotalValue,
            },

        }

       
    }

    return screenGui
end




