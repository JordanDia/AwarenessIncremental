local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus)

local UpdateLogFrame = require(ReplicatedStorage.UI.components.UpdateLogFrame)

local UpdateLogController = Knit.CreateController {
    Name = "UpdateLogController"
}

function UpdateLogController:KnitStart()
    local scope = Fusion:scoped()

    local isOpen = false
    local isVisible = scope:Value(false)
    local icon

    local screenGui = scope:New "ScreenGui" {
        Name = "UpdateLog",
        Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 15,

        [Fusion.Children] = {
            UpdateLogFrame(scope, {
                Visible = isVisible,
                OnClose = function()
                    isOpen = false
                    isVisible:set(false)
                    icon:deselect()
                end,
            }),
        },
    }

    icon = Icon.new()
    icon:setName("UpdateLogs")
    icon:setImage("rbxassetid://137011612291151")
    icon:setOrder(3)

    icon:bindEvent("selected", function()
        isOpen = true
        isVisible:set(true)
    end)

    icon:bindEvent("deselected", function()
        isOpen = false
        isVisible:set(false)
    end)
end

return UpdateLogController
