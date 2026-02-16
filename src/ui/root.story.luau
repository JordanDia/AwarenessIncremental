local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local CurrencyFrame = require(script.Parent.components.CurrencyFrame)
local scope = scoped(Fusion, {
   CurrencyFrame = CurrencyFrame
})

local function story(target: Frame)
    local awarenessFrame = scope:CurrencyFrame {
        Name = "AwarenessFrame",
        Position = UDim2.fromScale(0.01, 0.5),
        Value = scope:Value(10),
        Parent = target,
    }

   return function()
      awarenessFrame:Destroy()
   end
end
    
return story