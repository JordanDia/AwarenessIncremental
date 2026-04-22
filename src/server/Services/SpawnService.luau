local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit              = require(ReplicatedStorage.Packages.Knit)

local POSITION_TTL = 3600 -- 1 hour in seconds
local SPAWN_Y_OFFSET = 3  -- studs above saved position so the character doesn't clip

local SpawnService = Knit.CreateService {
    Name = "SpawnService",
    Client = {},
}

SpawnService.DataService = nil

local function savePosition(profile, position: Vector3)
    profile.Data.LastPositionX    = position.X
    profile.Data.LastPositionY    = position.Y
    profile.Data.LastPositionZ    = position.Z
    profile.Data.LastPositionTime = os.time()
end

local function clearPosition(profile)
    profile.Data.LastPositionX    = nil
    profile.Data.LastPositionY    = nil
    profile.Data.LastPositionZ    = nil
    profile.Data.LastPositionTime = 0
end

local function getSavedPosition(profile): Vector3?
    local t = profile.Data.LastPositionTime or 0
    if t == 0 then return nil end
    if os.time() - t > POSITION_TTL then return nil end
    local x = profile.Data.LastPositionX
    local y = profile.Data.LastPositionY
    local z = profile.Data.LastPositionZ
    if not x or not y or not z then return nil end
    return Vector3.new(x, y + SPAWN_Y_OFFSET, z)
end

local function applySpawn(player: Player, profile)
    local pos = getSavedPosition(profile)
    if not pos then return end
    clearPosition(profile)

    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Wait a frame so Roblox's default spawn logic has already placed the character
    task.wait()
    root.CFrame = CFrame.new(pos)
end

function SpawnService:KnitStart()
    self.DataService = Knit.GetService("DataService")

    local function onProfileLoaded(player: Player)
        local profile = self.DataService:GetProfile(player)
        if not profile then return end

        -- Apply saved position exactly once: either immediately if character
        -- already exists, or on the very first CharacterAdded this session.
        if player.Character then
            applySpawn(player, profile)
        else
            local conn
            conn = player.CharacterAdded:Connect(function()
                conn:Disconnect()
                applySpawn(player, profile)
            end)
        end

        -- Save position whenever the character is removed (death, reset, etc.)
        player.CharacterRemoving:Connect(function(character)
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                savePosition(profile, root.Position)
            end
        end)
    end

    self.DataService.ProfileLoaded:Connect(onProfileLoaded)

    for player in self.DataService.Profiles do
        onProfileLoaded(player)
    end
end

return SpawnService
