local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local COOLDOWN = 30

return function(parent)
    local scope = scoped(Fusion)

    local VeilService = Knit.GetService("VeilService")

    -- "veil" | "cooldown" | "none"
    local mode       = scope:Value("none")
    local expiresAt  = scope:Value(0) -- os.clock() timestamp when current phase ends

    -- Reactive countdown integer (seconds remaining)
    local countdown = scope:Value(0)

    -- Heartbeat drives the countdown
    local connection = RunService.Heartbeat:Connect(function()
        local m = Fusion.peek(mode)
        if m == "none" then return end
        local remaining = math.max(0, math.ceil(Fusion.peek(expiresAt) - os.clock()))
        countdown:set(remaining)
        if remaining == 0 then
            if m == "veil" then
                -- Veil just expired locally — switch to cooldown phase
                mode:set("cooldown")
                expiresAt:set(os.clock() + COOLDOWN)
            else
                mode:set("none")
            end
        end
    end)

    -- Server tells us the veil started with a given duration
    VeilService.VeilStarted:Connect(function(duration)
        mode:set("veil")
        expiresAt:set(os.clock() + duration)
        countdown:set(duration)
    end)

    -- Server confirms veil lowered (e.g. if server lowers it early in future)
    VeilService.VeilLowered:Connect(function()
        if Fusion.peek(mode) == "veil" then
            mode:set("cooldown")
            expiresAt:set(os.clock() + COOLDOWN)
        end
    end)

    -- Reactive label text
    local labelText = scope:Computed(function(use)
        local m = use(mode)
        local secs = use(countdown)
        if m == "veil" then
            return "Veil: " .. secs .. "s"
        elseif m == "cooldown" then
            return "Cooldown: " .. secs .. "s"
        end
        return ""
    end)

    local labelVisible = scope:Computed(function(use)
        return use(mode) ~= "none"
    end)

    scope:New "BillboardGui" {
        Name            = "MushroomGui",
        Adornee         = workspace:WaitForChild("MysticalForest"):WaitForChild("Mushroom"),
        Size            = UDim2.fromScale(6, 4),
        StudsOffset     = Vector3.new(0, 7, 0),
        AlwaysOnTop     = false,
        ResetOnSpawn    = false,
        Parent          = parent,

        [Fusion.Children] = {
            scope:New "TextLabel" {
                Size                 = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text                 = labelText,
                Visible              = labelVisible,
                TextColor3           = Color3.fromRGB(255, 255, 255),
                FontFace             = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                TextScaled           = true,

                [Fusion.Children] = {
                    scope:New "UIStroke" {
                        Color     = Color3.fromRGB(0, 0, 0),
                        Thickness = 3,
                    },
                },
            },
        },
    }

    return function()
        connection:Disconnect()
        scope:doCleanup()
    end
end
