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
local BoostGui = require("./mount/BoostGui")

return function(parent: Instance)
    local mounted = {}

    local mountFns = {
        Hud                   = Hud,
        UpgradeBoards         = UpgradeBoards,
        MushroomGui           = MushroomGui,
        TutorialGui           = TutorialGui,
        TutorialIndicator     = TutorialIndicator,
        GamepassBoards        = GamepassBoards,
        SocialBoard           = SocialBoard,
        GamepassOverviewBoard = GamepassOverviewBoard,
        LeaderboardBoards     = LeaderboardBoards,
        DonateBoard           = DonateBoard,
        BoostGui              = BoostGui,
    }

    -- Mount all UIs in parallel so WaitForChild calls don't block each other
    for name, fn in mountFns do
        task.spawn(function()
            mounted[name] = fn(parent)
        end)
    end

    return function()
        for _, gui in pairs(mounted) do
            if type(gui) == "function" then
                gui()
            elseif gui and gui.Destroy then
                gui:Destroy()
            end
        end
    end
end
