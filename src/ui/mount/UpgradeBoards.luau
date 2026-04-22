local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local scoped = Fusion.scoped

local UpgradeSound: Sound = SoundService:WaitForChild("Upgrade")

local UpgradeFrame           = require("../components/UpgradeFrame")
local LockedBoard            = require("../components/LockedBoard")
local RebirthFrame           = require("../components/RebirthFrame")
local AwakeningFrame         = require("../components/AwakeningFrame")
local SpawnDarkSpiritFrame   = require("../components/SpawnDarkSpiritFrame")

return function(parent)

    local scope = scoped(Fusion, {
        UpgradeFrame          = UpgradeFrame,
        LockedBoard           = LockedBoard,
        RebirthFrame          = RebirthFrame,
        AwakeningFrame        = AwakeningFrame,
        SpawnDarkSpiritFrame  = SpawnDarkSpiritFrame,
    })

    local DataService         = Knit.GetService("DataService") 
    local RebirthService      = Knit.GetService("RebirthService")
    local UpgradeService      = Knit.GetService("UpgradeService")
    local AwakeningService    = Knit.GetService("AwakeningService")
    local AwarenessService    = Knit.GetService("AwarenessService")
    local CrystalService      = Knit.GetService("CrystalService")
    local AstralEchoService          = Knit.GetService("AstralEchoService")
    local AstralProjectionService    = Knit.GetService("AstralProjectionService")
    local UnlockService       = Knit.GetService("UnlockService")
    local UpgradeTreeService  = Knit.GetService("UpgradeTreeService")

    -- ── Reactive lock conditions ───────────────────────────────────────────
    -- crystalUnlocked: true once the player buys tree node 1-3 (CrystalCollection)
    local crystalUnlocked = scope:Value(UnlockService:IsUnlocked("CrystalCollection"))
    -- tree1Node9Purchased: true once node 1-9 is bought (unlocks Awakening board)
    local tree1Node9Purchased = scope:Value(UpgradeTreeService:IsNodePurchased("Tree1", "1-9"))
    -- awakeningLevel: reactive awakening level (unlocks Veil / AstralEcho boards at >= 1)
    local awakeningLevel = scope:Value(AwakeningService:GetLevel())
    -- eliteSpiritSpawnerUnlocked: true once node 3-5 is purchased (unlocks SpawnDarkSpirit + spirit upgrade boards)
    local eliteSpiritSpawnerUnlocked = scope:Value(UnlockService:IsUnlocked("EliteSpiritSpawner"))

    -- Update lock states when tree nodes are purchased
    UpgradeTreeService.NodeUnlocked:Connect(function(treeName, nodeId)
        if treeName == "Tree1" and nodeId == "1-3" then
            crystalUnlocked:set(true)
        end
        if treeName == "Tree1" and nodeId == "1-9" then
            tree1Node9Purchased:set(true)
        end
        if treeName == "Tree3" and nodeId == "3-5" then
            eliteSpiritSpawnerUnlocked:set(true)
        end
    end)

    DataService.DataLoaded:Connect(function(data)
        crystalUnlocked:set(UnlockService:IsUnlocked("CrystalCollection"))
        tree1Node9Purchased:set(UpgradeTreeService:IsNodePurchased("Tree1", "1-9"))
        eliteSpiritSpawnerUnlocked:set(UnlockService:IsUnlocked("EliteSpiritSpawner"))
    end)

    -- Update awakening level whenever it changes (also used later for the awakening board)
    AwakeningService.AwakeningLevelChanged:Connect(function(level)
        awakeningLevel:set(level)
        -- Re-check unlock states that get revoked on awakening
        crystalUnlocked:set(UnlockService:IsUnlocked("CrystalCollection"))
        tree1Node9Purchased:set(UpgradeTreeService:IsNodePurchased("Tree1", "1-9"))
        eliteSpiritSpawnerUnlocked:set(UnlockService:IsUnlocked("EliteSpiritSpawner"))
    end)

    -- ── Reactive currency balances (for CanAfford) ─────────────────────────
    local currencyBalances = {
        Awareness        = scope:Value(AwarenessService:GetAwareness()),
        Crystals         = scope:Value(CrystalService:GetCrystals()),
        Rebirths         = scope:Value(RebirthService:GetRebirths()),
        ["Astral Echoes"] = scope:Value(AstralEchoService:GetEchoes()),
        Essences          = scope:Value(AstralProjectionService:GetEssences()),
        ["Dark Essences"] = scope:Value(AstralProjectionService:GetDarkEssences()),
    }

    AwarenessService.AwarenessChanged:Connect(function(amount)
        currencyBalances.Awareness:set(amount)
    end)
    CrystalService.CrystalsChanged:Connect(function(amount)
        currencyBalances.Crystals:set(amount)
    end)
    RebirthService.RebirthsChanged:Connect(function(amount)
        currencyBalances.Rebirths:set(amount)
    end)
    AstralEchoService.EchoesChanged:Connect(function(amount)
        currencyBalances["Astral Echoes"]:set(amount)
    end)
    AstralProjectionService.EssencesChanged:Connect(function(essences)
        currencyBalances.Essences:set(essences)
    end)
    AstralProjectionService.DarkEssencesChanged:Connect(function(dark)
        currencyBalances["Dark Essences"]:set(dark)
    end)

    -- ── Board factory ──────────────────────────────────────────────────────
    local function MakeUpgradeBoard(upgradeId, part, description, icon, units, lockState)
        local maxLevel  = UpgradeService:GetMaxLevel(upgradeId)
        local level     = scope:Value(UpgradeService:GetLevel(upgradeId))
        local cost      = scope:Value(UpgradeService:GetNextCost(upgradeId))
        local balance   = currencyBalances[units] or scope:Value(math.huge)
        local canAfford = scope:Computed(function(use)
            if use(level) >= maxLevel then return false end
            local c = use(cost)
            local b = use(balance)
            if type(c) ~= "number" or type(b) ~= "number" then return false end
            return b >= c
        end)
        return {
            UpgradeId    = upgradeId,
            Part         = part,
            Description  = description,
            Icon         = icon,
            Units        = units,
            Level        = level,
            MaxLevel     = maxLevel,
            CurrentValue = scope:Value(UpgradeService:GetUpgradeEffect(upgradeId)),
            NextValue    = scope:Value(UpgradeService:GetNextUpgradeEffect(upgradeId)),
            Cost         = cost,
            CanAfford    = canAfford,
            -- lockState is a Fusion.UsedAs<boolean> (true = locked). nil means never locked.
            LockState    = lockState,
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

    -- Mount one board: shows LockedBoard or UpgradeFrame depending on LockState
    local function MountUpgradeGui(board, rewardText, requirementText)
        if board.LockState then
            scope:New "SurfaceGui" {
                Name    = board.UpgradeId .. "_Locked",
                Adornee = board.Part,
                Face    = Enum.NormalId.Front,
                Parent  = parent,
                Enabled = scope:Computed(function(use) return use(board.LockState) end),
                [Fusion.Children] = {
                    scope:LockedBoard {
                        RewardText      = rewardText,
                        RequirementText = requirementText,
                    }
                }
            }

            scope:New "SurfaceGui" {
                Name    = board.UpgradeId,
                Adornee = board.Part,
                Face    = Enum.NormalId.Front,
                Parent  = parent,
                Enabled = scope:Computed(function(use) return not use(board.LockState) end),
                [Fusion.Children] = {
                    scope:UpgradeFrame {
                        Level        = board.Level,
                        MaxLevel     = board.MaxLevel,
                        Description  = board.Description,
                        Icon         = board.Icon,
                        CurrentValue = board.CurrentValue,
                        NextValue    = board.NextValue,
                        Cost         = board.Cost,
                        Units        = board.Units,
                        CanAfford    = board.CanAfford,
                        OnBuyOne     = board.OnBuyOne,
                        OnBuyMax     = board.OnBuyMax,
                    }
                }
            }
        else
            scope:New "SurfaceGui" {
                Name    = board.UpgradeId,
                Adornee = board.Part,
                Face    = Enum.NormalId.Front,
                Parent  = parent,
                [Fusion.Children] = {
                    scope:UpgradeFrame {
                        Level        = board.Level,
                        MaxLevel     = board.MaxLevel,
                        Description  = board.Description,
                        Icon         = board.Icon,
                        CurrentValue = board.CurrentValue,
                        NextValue    = board.NextValue,
                        Cost         = board.Cost,
                        Units        = board.Units,
                        CanAfford    = board.CanAfford,
                        OnBuyOne     = board.OnBuyOne,
                        OnBuyMax     = board.OnBuyMax,
                    }
                }
            }
        end
    end

    -- Helper to refresh all reactive values on a board after a purchase
    local function RefreshBoard(board)
        board.Level:set(UpgradeService:GetLevel(board.UpgradeId))
        board.CurrentValue:set(UpgradeService:GetUpgradeEffect(board.UpgradeId))
        board.NextValue:set(UpgradeService:GetNextUpgradeEffect(board.UpgradeId))
        board.Cost:set(UpgradeService:GetNextCost(board.UpgradeId))
    end

    -- ── Lock conditions ────────────────────────────────────────────────────
    -- crystalLocked: inverse of crystalUnlocked
    local crystalLocked = scope:Computed(function(use)
        return not use(crystalUnlocked)
    end)
    -- awakeningBoardLocked: locked until tree node 1-9 is purchased, OR permanently unlocked if awakening level >= 1
    local awakeningBoardLocked = scope:Computed(function(use)
        if use(awakeningLevel) >= 1 then return false end
        return not use(tree1Node9Purchased)
    end)
    -- veilAndEchoLocked: locked until the player has at least 1 awakening
    local veilAndEchoLocked = scope:Computed(function(use)
        return use(awakeningLevel) < 1
    end)
    -- spiritBoardLocked: locked until node 3-5 (EliteSpiritSpawner) is purchased
    local spiritBoardLocked = scope:Computed(function(use)
        return not use(eliteSpiritSpawnerUnlocked)
    end)
    -- awakening6Locked: locked until player reaches Awakening level 6
    local awakening6Locked = scope:Computed(function(use)
        return use(awakeningLevel) < 6
    end)

    -- ── Awareness upgrade boards (no lock requirement) ─────────────────────
    local upgradeBoards = {
        MakeUpgradeBoard("AwarenessPerMeditation",
            workspace.UpgradeBoards:WaitForChild("MoreAwarenessBoard"),
            "Increase awareness per meditation",
            "rbxassetid://84930949408431",
            "Awareness"
        ),
        MakeUpgradeBoard("MeditationSpeed",
            workspace.UpgradeBoards:WaitForChild("MoreMeditationSpeedBoard"),
            "Decrease meditation cooldown",
            "rbxassetid://74165606343290",
            "Awareness"
        ),

        -- Crystal boards (locked until CrystalCollection unlocked via node 1-3)
        MakeUpgradeBoard("CrystalValue",
            workspace.UpgradeBoards:WaitForChild("CrystalValueBoard"),
            "Increase Crystal Value",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),
        MakeUpgradeBoard("CrystalSpeed",
            workspace.UpgradeBoards:WaitForChild("CrystalSpeedBoard"),
            "Increase Crystal Spawn Speed",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),
        MakeUpgradeBoard("MaxCrystals",
            workspace.UpgradeBoards:WaitForChild("MaxCrystalsBoard"),
            "Increase Max Crystals",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),
        MakeUpgradeBoard("CrystalMultiplier",
            workspace.UpgradeBoards:WaitForChild("MultiplyCrystalBoard"),
            "Crystal Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),
        MakeUpgradeBoard("CrystalAwarenessMultiplier",
            workspace.UpgradeBoards:WaitForChild("CrystalMultiplyAwarenessBoard"),
            "Awareness Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),
        MakeUpgradeBoard("CrystalRebirthMultiplier",
            workspace.UpgradeBoards:WaitForChild("CrystalMultiplyRebirthBoard"),
            "Rebirth Value Multiplier",
            "rbxassetid://74165606343290",
            "Crystals",
            crystalLocked
        ),

        -- Astral Echo / Veil boards (locked until awakening level >= 1)
        MakeUpgradeBoard("AstralEchoValue",
            workspace.UpgradeBoards:WaitForChild("AstralEchoValueBoard"),
            "Increase Astral Echo value per collection",
            "rbxassetid://118132965740444",
            "Astral Echoes",
            veilAndEchoLocked
        ),
        MakeUpgradeBoard("VeilDuration",
            workspace.UpgradeBoards:WaitForChild("VeilDurationBoard"),
            "Increase how long the Veil lasts",
            "rbxassetid://118132965740444",
            "Astral Echoes",
            veilAndEchoLocked
        ),
        MakeUpgradeBoard("AstralEchoMultiplyAwareness",
            workspace.UpgradeBoards:WaitForChild("AstralEchoMultiplyAwarenessBoard"),
            "Multiply awareness gained per meditation",
            "rbxassetid://84930949408431",
            "Astral Echoes",
            veilAndEchoLocked
        ),
        MakeUpgradeBoard("AstralEchoMultiplyRebirth",
            workspace.UpgradeBoards:WaitForChild("AstralEchoMultiplyRebirthBoard"),
            "Multiply rebirth amount",
            "rbxassetid://87766693277427",
            "Astral Echoes",
            veilAndEchoLocked
        ),
        MakeUpgradeBoard("SpiritDamage",
            workspace.UpgradeBoards:WaitForChild("SpiritDamage"),
            "Spirit Damage",
            "rbxassetid://87766693277427",
            "Essences",
            awakening6Locked
        ),
        MakeUpgradeBoard("EssenceValue",
            workspace.UpgradeBoards:WaitForChild("EssenceValue"),
            "Essence Value",
            "rbxassetid://87766693277427",
            "Dark Essences",
            spiritBoardLocked
        ),
    }

    local rebirthUpgradeBoards = {
        MakeUpgradeBoard("MultiplyAwarenessPerMeditation", workspace.RebirthUpgradeBoards:WaitForChild("MultiplyAwarenessPerMeditation"), "Multiply awareness per meditation",              "rbxassetid://84930949408431",  "Rebirths"),
        MakeUpgradeBoard("MultiplyRebirthAmount",          workspace.RebirthUpgradeBoards:WaitForChild("MultiplyRebirthAmount"),          "Multiply rebirth amount",                        "rbxassetid://108179584438409", "Rebirths"),
        MakeUpgradeBoard("IncreaseDeepThoughtChance",      workspace.RebirthUpgradeBoards:WaitForChild("IncreaseDeepThoughtChance"),      "Increase chance to get Deep Thought meditation",  "rbxassetid://109609612189140", "Rebirths"),
    }

    local allUpgradeBoards = table.move(rebirthUpgradeBoards, 1, #rebirthUpgradeBoards, #upgradeBoards + 1, upgradeBoards)

    -- Mount all upgrade boards
    for _, board in upgradeBoards do
        local rewardText, requirementText
        if board.LockState == crystalLocked then
            rewardText      = "Crystal Upgrades"
            requirementText = "Unlock Crystal Collection\n(Upgrade Tree 1-3)"
        elseif board.LockState == veilAndEchoLocked then
            rewardText      = "Astral Echo Upgrades"
            requirementText = "Reach Awakening Level 1"
        elseif board.LockState == spiritBoardLocked then
            rewardText      = "Spirit Upgrades"
            requirementText = "Unlock Dark Spirit Spawner\n(Upgrade Tree 3-5)"
        elseif board.LockState == awakening6Locked then
            rewardText      = "Spirit Damage"
            requirementText = "Reach Awakening Level 6"
        end
        MountUpgradeGui(board, rewardText, requirementText)
    end

    for _, board in rebirthUpgradeBoards do
        MountUpgradeGui(board)
    end

    -- ── Rebirth board ──────────────────────────────────────────────────────
    local rebirthBoard = {
        Part     = workspace.UpgradeBoards:WaitForChild("RebirthBoard"),
        Title    = "Rebirth",
        Icon     = "rbxassetid://87766693277427",
        Value    = scope:Value(RebirthService:GetTotalRebirthsToGain()),
        OnRebirth = function()
            RebirthService:PerformRebirth()
        end
    }

    UpgradeService.UpgradeUpdated:Connect(function(upgradeId, _newLevel)
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

    scope:New "SurfaceGui" {
        Name    = "RebirthBoard",
        Adornee = rebirthBoard.Part,
        Face    = Enum.NormalId.Front,
        Parent  = parent,
        [Fusion.Children] = {
            scope:RebirthFrame {
                Title     = rebirthBoard.Title,
                Icon      = rebirthBoard.Icon,
                Value     = rebirthBoard.Value,
                OnRebirth = rebirthBoard.OnRebirth,
            }
        }
    }

    RebirthService.RebirthsToGainUpdated:Connect(function(_newRebirthsToGain)
        rebirthBoard.Value:set(RebirthService:GetTotalRebirthsToGain())
    end)

    -- ── Awakening board (locked until tree node 1-9 purchased) ────────────
    local awarenessValue = scope:Value(AwarenessService:GetAwareness())

    AwarenessService.AwarenessChanged:Connect(function(awareness)
        awarenessValue:set(awareness)
    end)

    local awakeningPart = workspace.UpgradeBoards:WaitForChild("AwakeningBoard")

    scope:New "SurfaceGui" {
        Name    = "AwakeningBoard_Locked",
        Adornee = awakeningPart,
        Face    = Enum.NormalId.Front,
        Parent  = parent,
        Enabled = scope:Computed(function(use) return use(awakeningBoardLocked) end),
        [Fusion.Children] = {
            scope:LockedBoard {
                RewardText      = "Awakening",
                RequirementText = "Buy Upgrade Tree 1-9",
            }
        }
    }

    scope:New "SurfaceGui" {
        Name    = "AwakeningBoard",
        Adornee = awakeningPart,
        Face    = Enum.NormalId.Front,
        Parent  = parent,
        Enabled = scope:Computed(function(use) return not use(awakeningBoardLocked) end),
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

    -- ── Spawn Dark Spirit board ───────────────────────────────────────────
    local initSummons, initMaxSummons, initNextRegen = AstralProjectionService:GetSummons()
    local summonsValue       = scope:Value(initSummons)
    local maxSummonsValue    = scope:Value(initMaxSummons)
    local nextRegenTimeValue = scope:Value(initNextRegen)

    AstralProjectionService.SummonsChanged:Connect(function(summons, maxSummons, nextRegen)
        summonsValue:set(summons)
        maxSummonsValue:set(maxSummons)
        nextRegenTimeValue:set(nextRegen)
    end)

    local DonateService = Knit.GetService("DonateService")

    local spawnDarkSpiritPart = workspace:WaitForChild("SpawnDarkSpirit")

    scope:New "SurfaceGui" {
        Name    = "SpawnDarkSpiritBoard_Locked",
        Adornee = spawnDarkSpiritPart,
        Face    = Enum.NormalId.Front,
        Parent  = parent,
        Enabled = scope:Computed(function(use) return use(spiritBoardLocked) end),
        [Fusion.Children] = {
            scope:LockedBoard {
                RewardText      = "Dark Spirit Summoning",
                RequirementText = "Unlock Dark Spirit Spawner\n(Upgrade Tree 3-5)",
            }
        }
    }

    scope:New "SurfaceGui" {
        Name    = "SpawnDarkSpiritBoard",
        Adornee = spawnDarkSpiritPart,
        Face    = Enum.NormalId.Front,
        Parent  = parent,
        Enabled = scope:Computed(function(use) return not use(spiritBoardLocked) end),
        [Fusion.Children] = {
            scope:SpawnDarkSpiritFrame {
                Essences     = currencyBalances.Essences,
                Awareness    = currencyBalances.Awareness,
                Crystals     = currencyBalances.Crystals,
                AstralEchoes = currencyBalances["Astral Echoes"],
                Rebirths     = currencyBalances.Rebirths,
                Summons        = summonsValue,
                MaxSummons     = maxSummonsValue,
                NextSummonRegen = nextRegenTimeValue,
                OnSpawn      = function()
                    AstralProjectionService:SpawnDarkSpirit()
                end,
                OnBuyMaxSummons = function()
                    DonateService:PromptDonate(3578003439)
                end,
            }
        }
    }

    return function()
        scope:doCleanup()
    end
end
