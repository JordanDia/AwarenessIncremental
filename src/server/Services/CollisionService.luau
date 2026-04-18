local Players        = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PLAYER_GROUP = "Players"
local SPIRIT_GROUP = "Spirit"

local CollisionService = Knit.CreateService {
    Name = "CollisionService",
}

function CollisionService:KnitInit()
    PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
    PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)

    PhysicsService:RegisterCollisionGroup(SPIRIT_GROUP)
    PhysicsService:CollisionGroupSetCollidable(SPIRIT_GROUP, "Default", false)
    PhysicsService:CollisionGroupSetCollidable(SPIRIT_GROUP, PLAYER_GROUP, false)
end

local function setCharacterGroup(character: Model)
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") then
            part.CollisionGroup = PLAYER_GROUP
        end
    end
    -- Also catch parts added after spawn (accessories, tools, etc.)
    character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            part.CollisionGroup = PLAYER_GROUP
        end
    end)
end

function CollisionService:KnitStart()
    local function onCharacterAdded(character: Model)
        -- Parts may not all exist yet; wait for the root part then assign
        character:WaitForChild("HumanoidRootPart")
        setCharacterGroup(character)
    end

    local function onPlayerAdded(player: Player)
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end
end

return CollisionService
