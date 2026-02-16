local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local UpgradeFrame = require("../components/UpgradeFrame")
local RebirthFrame = require("../components/RebirthFrame")

return function(parent)

    local scope = scoped(Fusion, {
        UpgradeFrame = UpgradeFrame,
        RebirthFrame = RebirthFrame
    })

    local RebirthService = Knit.GetService("RebirthService")
    local UpgradeService = Knit.GetService("UpgradeService")
    
    local upgradeBoards = {
        {
            UpgradeId = "AwarenessPerMeditation",
            Part = workspace.UpgradeBoards:WaitForChild("MoreAwarenessBoard"),
            
            Level = scope:Value(UpgradeService:GetLevel("AwarenessPerMeditation")),
            MaxLevel = UpgradeService:GetMaxLevel("AwarenessPerMeditation"),

            Description = "Increase awareness per meditation",
            Icon = "rbxassetid://84930949408431",

            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect("AwarenessPerMeditation")),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect("AwarenessPerMeditation")),

            Cost = scope:Value(UpgradeService:GetNextCost("AwarenessPerMeditation")),
            Units = "Awareness",

            OnBuyOne = function()
                UpgradeService:BuyUpgrade("AwarenessPerMeditation")
            end,
            OnBuyMax = function()
                --print("Bought max Awareness upgrades")
                UpgradeService:BuyMaxUpgrade("AwarenessPerMeditation")
            end
        },
        {
            UpgradeId = "MeditationSpeed",
            Part = workspace.UpgradeBoards:WaitForChild("MoreMeditationSpeedBoard"),
            Level = scope:Value(UpgradeService:GetLevel("MeditationSpeed")),
            MaxLevel = UpgradeService:GetMaxLevel("MeditationSpeed"),

            Description = "Decrease meditation cooldown",
            Icon = "rbxassetid://74165606343290",

            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect("MeditationSpeed")),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect("MeditationSpeed")),

            Cost = scope:Value(UpgradeService:GetNextCost("MeditationSpeed")),
            Units = "Awareness",

            OnBuyOne = function()
                UpgradeService:BuyUpgrade("MeditationSpeed")
            end,
            OnBuyMax = function()
                UpgradeService:BuyMaxUpgrade("MeditationSpeed")
            end
        },
    }

    -- Add rebirth board configuration
    print(RebirthService:GetTotalRebirthsToGain())
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

    local rebirthUpgradeBoards = {
        {
            UpgradeId = "MultiplyAwarenessPerMeditation",
            Part = workspace.RebirthUpgradeBoards:WaitForChild("MultiplyAwarenessPerMeditation"),

            Level = scope:Value(UpgradeService:GetLevel("MultiplyAwarenessPerMeditation")),
            MaxLevel = UpgradeService:GetMaxLevel("MultiplyAwarenessPerMeditation"),

            Description = "Multiply awareness per meditation",
            Icon = "rbxassetid://84930949408431",

            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect("MultiplyAwarenessPerMeditation")),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect("MultiplyAwarenessPerMeditation")),

            Cost = scope:Value(UpgradeService:GetNextCost("MultiplyAwarenessPerMeditation")),
            Units = "Rebirths",

            OnBuyOne = function()
                UpgradeService:BuyUpgrade("MultiplyAwarenessPerMeditation")
            end,
            OnBuyMax = function()
                UpgradeService:BuyMaxUpgrade("MultiplyAwarenessPerMeditation")
            end
        },
        {
            UpgradeId = "MultiplyRebirthAmount",
            Part = workspace.RebirthUpgradeBoards:WaitForChild("MultiplyRebirthAmount"),

            Level = scope:Value(UpgradeService:GetLevel("MultiplyRebirthAmount")),
            MaxLevel = UpgradeService:GetMaxLevel("MultiplyRebirthAmount"),

            Description = "Multiply rebirth amount",
            Icon = "rbxassetid://108179584438409",

            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect("MultiplyRebirthAmount")),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect("MultiplyRebirthAmount")),

            Cost = scope:Value(UpgradeService:GetNextCost("MultiplyRebirthAmount")),
            Units = "Rebirths",

            OnBuyOne = function()
                UpgradeService:BuyUpgrade("MultiplyRebirthAmount")
            end,
            OnBuyMax = function()
                UpgradeService:BuyMaxUpgrade("MultiplyRebirthAmount")
            end
        },
        {
            UpgradeId = "IncreaseDeepThoughtChance",
            Part = workspace.RebirthUpgradeBoards:WaitForChild("IncreaseDeepThoughtChance"),

            Level = scope:Value(UpgradeService:GetLevel("IncreaseDeepThoughtChance")),
            MaxLevel = UpgradeService:GetMaxLevel("IncreaseDeepThoughtChance"),

            Description = "Increase chance to get Deep Thought meditation",
            Icon = "rbxassetid://109609612189140",

            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect("IncreaseDeepThoughtChance")),
            NextValue = scope:Value(UpgradeService:GetNextUpgradeEffect("IncreaseDeepThoughtChance")),

            Cost = scope:Value(UpgradeService:GetNextCost("IncreaseDeepThoughtChance")),
            Units = "Rebirths",

            OnBuyOne = function()
                UpgradeService:BuyUpgrade("IncreaseDeepThoughtChance")
            end,
            OnBuyMax = function()
                UpgradeService:BuyMaxUpgrade("IncreaseDeepThoughtChance")
            end
        }
    }

    local function UpdateUpgradeBoards()
        for _, board in upgradeBoards do
            board.Level:set(UpgradeService:GetLevel(board.UpgradeId))
            board.CurrentValue:set(UpgradeService:GetUpgradeEffect(board.UpgradeId))
            board.NextValue:set(UpgradeService:GetNextUpgradeEffect(board.UpgradeId))
            board.Cost:set(UpgradeService:GetNextCost(board.UpgradeId))
        end
    end

    local function UpdateRebirthUpgradeBoards()
        for _, board in rebirthUpgradeBoards do
            board.Level:set(UpgradeService:GetLevel(board.UpgradeId))
            board.CurrentValue:set(UpgradeService:GetUpgradeEffect(board.UpgradeId))
            board.NextValue:set(UpgradeService:GetNextUpgradeEffect(board.UpgradeId))
            board.Cost:set(UpgradeService:GetNextCost(board.UpgradeId))
        end
    end


    UpgradeService.UpgradeUpdated:Connect(function(upgradeId, newLevel)
        --print(`Upgrade {upgradeId} updated to level {newLevel}`)

        if upgradeId == "MultiplyRebirthAmount" then
            rebirthBoard.Value:set(RebirthService:GetTotalRebirthsToGain())
        end

        UpdateUpgradeBoards()
        UpdateRebirthUpgradeBoards()
    end)

    RebirthService.RebirthsChanged:Connect(function(rebirths)
        UpdateUpgradeBoards()
        UpdateRebirthUpgradeBoards()
    end)

    local mounted = {}
   
    for _, board in upgradeBoards do
        local surfaceGui = scope:New "SurfaceGui" {
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

        table.insert(mounted, surfaceGui)
    end

    for _, board in rebirthUpgradeBoards do
        local surfaceGui = scope:New "SurfaceGui" {
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

        table.insert(mounted, surfaceGui)
    end

     -- Mount rebirth board
    local rebirthSurfaceGui = scope:New "SurfaceGui" {
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

    RebirthService.RebirthsToGainUpdated:Connect(function(newRebirthsToGain)
        rebirthBoard.Value:set(RebirthService:GetTotalRebirthsToGain())
    end)

    return function()
        scope:doCleanup()
    end
end
