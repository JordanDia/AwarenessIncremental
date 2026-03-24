local Hud = require("./mount/Hud")
local UpgradeBoards = require("./mount/UpgradeBoards")
local MushroomGui = require("./mount/MushroomGui")

return function(parent: Instance)
    local mounted = {}

    mounted.Hud = Hud(parent)
    mounted.UpgradeBoards = UpgradeBoards(parent)
    mounted.MushroomGui = MushroomGui(parent)
    
    return function()
        for _, gui in pairs(mounted) do
            if gui.Destroy then
                gui:Destroy()
            end
        end
    end
end
