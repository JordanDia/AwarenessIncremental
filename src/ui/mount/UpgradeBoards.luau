local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local UpgradeSound: Sound = SoundService:WaitForChild("Upgrade")

local UpgradeFrame    = require("../components/UpgradeFrame")
local RebirthFrame    = require("../components/RebirthFrame")
local AwakeningFrame  = require("../components/AwakeningFrame")

return function(parent)

    local scope = scoped(Fusion, {
        UpgradeFrame   = UpgradeFrame,
        RebirthFrame   = RebirthFrame,
        AwakeningFrame = AwakeningFrame,
    })

    local RebirthService   = Knit.GetService("RebirthService")
    local UpgradeService   = Knit.GetService("UpgradeService")
    local AwakeningService = Knit.GetService("AwakeningService")
    local AwarenessService = Knit.GetService("AwarenessService")

    local function MakeUpgradeBoard(upgradeId, part, description, icon, units)
        return {
            UpgradeId = upgradeId,
            Part = part,
            Description = description,
            Icon = icon,
            Units = units,
            Level = scope:Value(UpgradeService:GetLevel(upgradeId)),
            MaxLevel = UpgradeService:GetMaxLevel(upgradeId),
            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect(upgradeId)),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect(upgradeId)),
            Cost = scope:Value(UpgradeService:GetNextCost(upgradeId)),
            OnBuyOne = function()
                UpgradeService:BuyUpgrade(upgradeId)
                UpgradeSound:Play()
            end,
            OnBuyMax = function()
                UpgradeService:BuyMaxUpgrade(upgradeId)
                UpgradeSound:Play()
            end,
        }
    end

    -- Helper to mount an UpgradeFrame SurfaceGui onto a part
    local function MountUpgradeGui(board)
        return scope:New "SurfaceGui" {
            Name = board.UpgradeId,
            Adornee = board.Part,
            Face = Enum.NormalId.Front,
            Parent = parent,

            [Fusion.Children] = {
                scope:UpgradeFrame {
                    Level = board.Level,
                    MaxLevel = board.MaxLevel,
                    Description = board.Description,
                    Icon = board.Icon,
                    CurrentValue = board.CurrentValue,
                    NextValue = board.NextValue,
                    Cost = board.Cost,
                    Units = board.Units,
                    OnBuyOne = board.OnBuyOne,
                    OnBuyMax = board.OnBuyMax,
                }
            }
        }
    end

    -- Helper to refresh all reactive values on a board
    local function RefreshBoard(board)
        board.Level:set(UpgradeService:GetLevel(board.UpgradeId))
        board.CurrentValue:set(UpgradeService:GetUpgradeEffect(board.UpgradeId))
        board.NextValue:set(UpgradeService:GetNextUpgradeEffect(board.UpgradeId))
        board.Cost:set(UpgradeService:GetNextCost(board.UpgradeId))
    end

    local upgradeBoards = {
        MakeUpgradeBoard("AwarenessPerMeditation", -- UpgradeId
            workspace.UpgradeBoards:WaitForChild("MoreAwarenessBoard"), -- Board name
            "Increase awareness per meditation", -- Description
            "rbxassetid://84930949408431", -- Icon
            "Awareness" -- Currency
        ),
        MakeUpgradeBoard("MeditationSpeed",
            workspace.UpgradeBoards:WaitForChild("MoreMeditationSpeedBoard"),
            "Decrease meditation cooldown",
            "rbxassetid://74165606343290",
            "Awareness"
        ),
        MakeUpgradeBoard("CrystalValue",
            workspace.UpgradeBoards:WaitForChild("CrystalValueBoard"),
            "Increase Crystal Value",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("CrystalSpeed",
            workspace.UpgradeBoards:WaitForChild("CrystalSpeedBoard"),
            "Increase Crystal Spawn Speed",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("MaxCrystals",
            workspace.UpgradeBoards:WaitForChild("MaxCrystalsBoard"),
            "Increase Max Crystals",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("CrystalMultiplier",
            workspace.UpgradeBoards:WaitForChild("MultiplyCrystalBoard"),
            "Crystal Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("CrystalAwarenessMultiplier",
            workspace.UpgradeBoards:WaitForChild("CrystalMultiplyAwarenessBoard"),
            "Awareness Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("CrystalRebirthMultiplier",
            workspace.UpgradeBoards:WaitForChild("CrystalMultiplyRebirthBoard"),
            "Rebirth Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals"
        ),
        MakeUpgradeBoard("AstralEchoValue",
            workspace.UpgradeBoards:WaitForChild("AstralEchoValueBoard"),
            "Increase Astral Echo value per collection",
            "rbxassetid://118132965740444",
            "Astral Echoes"
        ),
        MakeUpgradeBoard("VeilDuration",
            workspace.UpgradeBoards:WaitForChild("VeilDurationBoard"),
            "Increase how long the Veil lasts",
            "rbxassetid://118132965740444",
            "Astral Echoes"
        ),
    }

    local rebirthUpgradeBoards = {
        MakeUpgradeBoard("MultiplyAwarenessPerMeditation", workspace.RebirthUpgradeBoards:WaitForChild("MultiplyAwarenessPerMeditation"), "Multiply awareness per meditation",              "rbxassetid://84930949408431",  "Rebirths"),
        MakeUpgradeBoard("MultiplyRebirthAmount",          workspace.RebirthUpgradeBoards:WaitForChild("MultiplyRebirthAmount"),          "Multiply rebirth amount",                        "rbxassetid://108179584438409", "Rebirths"),
        MakeUpgradeBoard("IncreaseDeepThoughtChance",      workspace.RebirthUpgradeBoards:WaitForChild("IncreaseDeepThoughtChance"),      "Increase chance to get Deep Thought meditation",  "rbxassetid://109609612189140", "Rebirths"),
    }

    local allUpgradeBoards = table.move(rebirthUpgradeBoards, 1, #rebirthUpgradeBoards, #upgradeBoards + 1, upgradeBoards)

     -- Mount all upgrade GUIs in one pass
    for _, board in allUpgradeBoards do
        MountUpgradeGui(board)
    end
    
    

    -- Add rebirth board configuration
    local rebirthBoard = {
        Part = workspace.UpgradeBoards:WaitForChild("RebirthBoard"),
        
        Title = "Rebirth",
        Icon = "rbxassetid://87766693277427",
        Value = scope:Value(RebirthService:GetTotalRebirthsToGain()),
        OnRebirth = function()
            -- Handle rebirth logic
            RebirthService:PerformRebirth()
        end
    }


    UpgradeService.UpgradeUpdated:Connect(function(upgradeId, _newLevel)
        --print(`Upgrade {upgradeId} updated to level {newLevel}`)

        if upgradeId == "MultiplyRebirthAmount" then
            rebirthBoard.Value:set(RebirthService:GetTotalRebirthsToGain())
        end

        for _, board in allUpgradeBoards do
            if board.UpgradeId ~= upgradeId then continue end
            RefreshBoard(board)
        end

    end)

    RebirthService.RebirthsChanged:Connect(function()
        for _, board in allUpgradeBoards do
            RefreshBoard(board)
        end
    end)

 
     -- Mount rebirth board
    scope:New "SurfaceGui" {
        Name = "RebirthBoard",
        Adornee = rebirthBoard.Part,
        Face = Enum.NormalId.Front,
        Parent = parent,
        
        [Fusion.Children] = {
            scope:RebirthFrame {
                Title = rebirthBoard.Title,
                Icon = rebirthBoard.Icon,
                Value = rebirthBoard.Value,
                OnRebirth = rebirthBoard.OnRebirth,
            }
        }
    }

    RebirthService.RebirthsToGainUpdated:Connect(function(_newRebirthsToGain)
        rebirthBoard.Value:set(RebirthService:GetTotalRebirthsToGain())
    end)

    -- ── Awakening board ───────────────────────────────────────────────────
    local awakeningLevel = scope:Value(AwakeningService:GetLevel())
    local awarenessValue = scope:Value(AwarenessService:GetAwareness())

    AwakeningService.AwakeningLevelChanged:Connect(function(level)
        awakeningLevel:set(level)
    end)

    AwarenessService.AwarenessChanged:Connect(function(awareness)
        awarenessValue:set(awareness)
    end)

    scope:New "SurfaceGui" {
        Name    = "AwakeningBoard",
        Adornee = workspace.UpgradeBoards:WaitForChild("AwakeningBoard"),
        Face    = Enum.NormalId.Front,
        Parent  = parent,

        [Fusion.Children] = {
            scope:AwakeningFrame {
                AwakeningLevel = awakeningLevel,
                Awareness      = awarenessValue,
                OnAwaken       = function()
                    AwakeningService:Awaken()
                end,
            }
        }
    }

    return function()
        scope:doCleanup()
    end
end
