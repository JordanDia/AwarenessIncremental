local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local CurrencyFrame = require("../components/CurrencyFrame")

return function(parent)
    local scope = scoped(Fusion, {
        CurrencyFrame = CurrencyFrame
    })

    local player = Players.LocalPlayer
    
    local AwarenessService = Knit.GetService("AwarenessService")
    local RebirthService = Knit.GetService("RebirthService")

    local awarenessValue = scope:Value(AwarenessService:GetAwareness())
    AwarenessService.AwarenessChanged:Connect(function(newAwareness)
        --print("Awareness updated to", newAwareness)
        awarenessValue:set(newAwareness)
    end)

    local rebirthValue = scope:Value(RebirthService:GetRebirths())
    RebirthService.RebirthsChanged:Connect(function(newRebirths)
        --print("Rebirths updated to", newRebirths)
        rebirthValue:set(newRebirths)
    end)

    local screenGui = scope:New "ScreenGui" {
        Name = "ScreenGui",
        Parent = parent,
        ResetOnSpawn = false,

        [Fusion.Children] = {
            scope:CurrencyFrame {
                Name = "AwarenessFrame",
                Position = UDim2.fromScale(0.01, 0.3),
                Value = awarenessValue,
                Icon = "rbxassetid://108300702326871",
                TextColor3 = Color3.fromRGB(255, 215, 0)
            },

            scope:CurrencyFrame {
                Name = "RebirthFrame",
                Position = UDim2.fromScale(0.01, 0.39),
                Value = rebirthValue,
                Icon = "rbxassetid://87766693277427",
                TextColor3 = Color3.fromRGB(0, 153, 255),
            }
        }
    }

    return screenGui
end




