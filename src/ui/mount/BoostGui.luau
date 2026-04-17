local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Fusion  = require(ReplicatedStorage.Packages.Fusion)
local Knit    = require(ReplicatedStorage.Packages.Knit)
local scoped  = Fusion.scoped

local BoostIcon = require("../components/BoostIcon")

local function formatTimer(seconds: number): string
    local s = math.max(0, math.floor(seconds))
    return string.format("%02dm %02ds", math.floor(s / 60), s % 60)
end

return function(parent)
    local scope = scoped(Fusion, {
        BoostIcon = BoostIcon,
    })

    local BoostService = Knit.GetService("BoostService")

    -- Server end times (0 = not active)
    local maEndTime = scope:Value(0)
    local msEndTime = scope:Value(0)

    -- Current time updated every frame
    local currentTime = scope:Value(os.time())
    local heartbeatConn = RunService.Heartbeat:Connect(function()
        currentTime:set(os.time())
    end)

    -- Computed timer strings and visibility
    local maTimerText = scope:Computed(function(use)
        return formatTimer(use(maEndTime) - use(currentTime))
    end)
    local maVisible = scope:Computed(function(use)
        return use(maEndTime) > use(currentTime)
    end)

    local msTimerText = scope:Computed(function(use)
        return formatTimer(use(msEndTime) - use(currentTime))
    end)
    local msVisible = scope:Computed(function(use)
        return use(msEndTime) > use(currentTime)
    end)

    -- Connect first so we never miss a signal that fires during the RPC below
    local maConn = BoostService.MeditateAnywhereBoostChanged:Connect(function(endTime)
        maEndTime:set(endTime)
    end)
    local msConn = BoostService.MeditationSpeedBoostChanged:Connect(function(endTime)
        msEndTime:set(endTime)
    end)

    -- Fetch initial state (yields, but BoostGui is already inside UIRoot's task.spawn)
    local endTimes = BoostService:GetBoostEndTimes()
    maEndTime:set(endTimes.MeditateAnywhere)
    msEndTime:set(endTimes.MeditationSpeed)

    scope:New "ScreenGui" {
        Name           = "BoostGui",
        Parent         = parent,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,

        [Fusion.Children] = {
            scope:New "Frame" {
                Name                   = "BoostFrame",
                Size                   = UDim2.fromScale(0.15, 0.1),
                Position               = UDim2.fromScale(0.84, 0.89),
                BackgroundTransparency = 1,

                [Fusion.Children] = {
                    scope:New "UIListLayout" {
                        FillDirection       = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment   = Enum.VerticalAlignment.Center,
                        Padding             = UDim.new(0.05, 0),
                    },

                    scope:BoostIcon {
                        Name      = "MeditateAnywhereBoost",
                        Title     = "Meditate Anywhere",
                        Icon      = "rbxassetid://122877191236434",
                        TimerText = maTimerText,
                        Visible   = maVisible,
                    },

                    scope:BoostIcon {
                        Name      = "MeditateSpeedBoost",
                        Title     = "Meditation Speed Boost",
                        Icon      = "rbxassetid://74165606343290",
                        TimerText = msTimerText,
                        Visible   = msVisible,
                    },
                },
            },
        },
    }

    return function()
        heartbeatConn:Disconnect()
        maConn:Disconnect()
        msConn:Disconnect()
        scope:doCleanup()
    end
end
