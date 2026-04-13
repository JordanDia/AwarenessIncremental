local Hud = require("./mount/Hud")
local UpgradeBoards = require("./mount/UpgradeBoards")
local MushroomGui = require("./mount/MushroomGui")
local TutorialGui = require("./mount/TutorialGui")
local TutorialIndicator = require("./mount/TutorialIndicator")
local GamepassBoards = require("./mount/GamepassBoards")
local SocialBoard = require("./mount/SocialBoard")
local GamepassOverviewBoard = require("./mount/GamepassOverviewBoard")
local LeaderboardBoards = require("./mount/LeaderboardBoards")
local DonateBoard = require("./mount/DonateBoard")

return function(parent: Instance)
    local mounted = {}

    mounted.Hud = Hud(parent)
    mounted.UpgradeBoards = UpgradeBoards(parent)
    mounted.MushroomGui = MushroomGui(parent)
    mounted.TutorialGui = TutorialGui(parent)
    mounted.TutorialIndicator = TutorialIndicator(parent)
    mounted.GamepassBoards = GamepassBoards(parent)
    mounted.SocialBoard = SocialBoard(parent)
    mounted.GamepassOverviewBoard = GamepassOverviewBoard(parent)
    mounted.LeaderboardBoards = LeaderboardBoards(parent)
    mounted.DonateBoard = DonateBoard(parent)
    
    return function()
        for _, gui in pairs(mounted) do
            if gui.Destroy then
                gui:Destroy()
            end
        end
    end
end
