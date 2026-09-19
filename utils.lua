-- ============================================================
-- The Walking Dead Online -- Utils
-- Services, screen math, entity detection, raycast
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = {}

Utils.Players           = Players
Utils.LocalPlayer       = Players.LocalPlayer
Utils.Camera            = workspace.CurrentCamera
Utils.RunService        = RunService
Utils.UserInputService  = UserInputService
Utils.ReplicatedStorage = ReplicatedStorage

Utils.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

task.spawn(function()
    while true do
        if workspace.CurrentCamera ~= Utils.Camera then
            Utils.Camera = workspace.CurrentCamera
        end
        task.wait(1)
    end
end)

-- ------------------------------------------------------------
-- Screen math
-- ------------------------------------------------------------

function Utils.GetCrosshairPosition()
    if not Utils.Camera then return Vector2.new(0, 0) end
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        local vp = Utils.Camera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

function Utils.WorldToScreen(position)
    if not Utils.Camera then return nil, false end
    local ok, result = pcall(function()
        return Utils.Camera:WorldToScreenPoint(position)
    end)
    if not ok or not result then return nil, false end
    return Vector2.new(result.X, result.Y), result.Z > 0
end

function Utils.WorldToViewport(position)
    if not Utils.Camera then return nil, false end
    local ok, result = pcall(function()
        return Utils.Camera:WorldToViewportPoint(position)
    end)
    if not ok or not result then return nil, false end
    return Vector2.new(result.X, result.Y), result.Z > 0
end

-- ------------------------------------------------------------
-- Character helpers
-- ------------------------------------------------------------

function Utils.CharacterRoot(player)
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function Utils.CharacterHead(player)
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChild("Head")
end

function Utils.CharacterHumanoid(player)
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ------------------------------------------------------------
-- Entity detection (Zombies vs Players)
-- ------------------------------------------------------------

-- TWD Online specific: Zombies are usually in workspace.Zombies or similar
-- We'll detect them by checking if they're not player characters
function Utils.IsZombie(model)
    if not model or not model:IsA("Model") then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Check if it's a player character
    local player = Players:GetPlayerFromCharacter(model)
    if player then return false end

    -- Check for zombie indicators in name
    local name = model.Name:lower()
    if name:find("zombie") or name:find("walker") or name:find("infected") 
        or name:find("crawler") or name:find("runner") or name:find("bloater")
        or name:find("riot") or name:find("police") or name:find("military") then
        return true
    end

    -- Check if in a zombies folder
    local parent = model.Parent
    while parent and parent ~= workspace do
        local parentName = parent.Name:lower()
        if parentName:find("zombie") or parentName:find("npc") or parentName:find("walker") then
            return true
        end
        parent = parent.Parent
    end

    return false
end

function Utils.GetZombies()
    local zombies = {}

    -- Common zombie container names in TWD games
    local containers = {
        workspace:FindFirstChild("Zombies"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Walkers"),
        workspace:FindFirstChild("Infected"),
        workspace:FindFirstChild("Entities"),
    }

    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Model") and Utils.IsZombie(child) then
                    local humanoid = child:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        table.insert(zombies, child)
                    end
                end
            end
        end
    end

    -- Also scan workspace for any zombie models not in containers
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and Utils.IsZombie(child) then
            local humanoid = child:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Check if already added
                local alreadyAdded = false
                for _, z in ipairs(zombies) do
                    if z == child then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(zombies, child)
                end
            end
        end
    end

    return zombies
end

function Utils.GetPlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Utils.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(players, player)
            end
        end
    end
    return players
end

-- ------------------------------------------------------------
-- Loot detection
-- ------------------------------------------------------------

-- Common loot patterns in TWD Online
local LOOT_PATTERNS = {
    Weapons = {"gun", "rifle", "pistol", "shotgun", "sniper", "bow", "crossbow", "melee", "axe", "knife", "bat", "machete", "katana", "hammer", "crowbar", "pipe", "wrench"},
    Food = {"food", "can", "beans", "soup", "bread", "meat", "fruit", "vegetable", "snack", "candy", "soda", "water", "drink"},
    Meds = {"med", "bandage", "first", "aid", "kit", "pills", "medicine", "antibiotic", "painkiller", "morphine", "adrenaline"},
    Ammo = {"ammo", "bullet", "magazine", "clip", "shell", "cartridge"},
    Resources = {"wood", "metal", "scrap", "cloth", "rope", "nail", "screw", "tape", "glue", "plastic", "leather", "fuel", "gas", "oil"},
    Attachments = {"scope", "sight", "suppressor", "silencer", "grip", "stock", "mag", "extended", "laser", "flashlight"},
    Clothes = {"shirt", "pants", "jacket", "vest", "helmet", "hat", "backpack", "bag", "shoes", "boots", "gloves"},
}

function Utils.GetLootType(itemName)
    local name = itemName:lower()

    for lootType, patterns in pairs(LOOT_PATTERNS) do
        for _, pattern in ipairs(patterns) do
            if name:find(pattern) then
                return lootType
            end
        end
    end

    return "Other"
end

function Utils.IsLootItem(object)
    if not object then return false end

    -- Check if it's a tool or part with a name
    local name = object.Name:lower()

    -- Skip characters and zombies
    if object:IsA("Model") and (object:FindFirstChildOfClass("Humanoid") or Utils.IsZombie(object)) then
        return false
    end

    -- Check against loot patterns
    for _, patterns in pairs(LOOT_PATTERNS) do
        for _, pattern in ipairs(patterns) do
            if name:find(pattern) then
                return true
            end
        end
    end

    -- Check for common loot indicators
    if object:GetAttribute("LootType") or object:GetAttribute("ItemType") or object:GetAttribute("Rarity") then
        return true
    end

    return false
end

function Utils.GetLootItems()
    local loot = {}

    -- Common loot container names
    local containers = {
        workspace:FindFirstChild("Loot"),
        workspace:FindFirstChild("Items"),
        workspace:FindFirstChild("Drops"),
        workspace:FindFirstChild("Pickups"),
        workspace:FindFirstChild("Spawns"),
    }

    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetDescendants()) do
                if Utils.IsLootItem(child) then
                    table.insert(loot, child)
                end
            end
        end
    end

    -- Also scan workspace for loose items
    for _, child in ipairs(workspace:GetDescendants()) do
        if Utils.IsLootItem(child) then
            -- Check if already added
            local alreadyAdded = false
            for _, l in ipairs(loot) do
                if l == child then
                    alreadyAdded = true
                    break
                end
            end
            if not alreadyAdded then
                table.insert(loot, child)
            end
        end
    end

    return loot
end

-- ------------------------------------------------------------
-- Raycast / LOS
-- ------------------------------------------------------------

local sharedParams = RaycastParams.new()
sharedParams.FilterType = Enum.RaycastFilterType.Blacklist

local raycastBlacklistDirty = true
local raycastBlacklistTime  = 0

function Utils.InvalidateRaycast()
    raycastBlacklistDirty = true
end

local function buildBlacklist(targetCharacter)
    local blacklist = {}
    if Utils.LocalPlayer.Character then
        table.insert(blacklist, Utils.LocalPlayer.Character)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Utils.LocalPlayer and player.Character
            and player.Character ~= targetCharacter then
            table.insert(blacklist, player.Character)
        end
    end
    return blacklist
end

function Utils.HasLineOfSight(targetPart)
    if not targetPart or not Utils.Camera then return false end
    local partParent = targetPart.Parent
    if not partParent then return false end

    local cameraPos = Utils.Camera.CFrame.Position
    local okPos, targetPos = pcall(function() return targetPart.Position end)
    if not okPos then return false end

    local offset   = targetPos - cameraPos
    local distance = offset.Magnitude
    if distance <= 0 then return false end

    local now = os.clock()
    if raycastBlacklistDirty or now - raycastBlacklistTime > 0.5 then
        sharedParams.FilterDescendantsInstances = buildBlacklist(partParent)
        raycastBlacklistDirty = false
        raycastBlacklistTime  = now
    end

    local ok, result = pcall(function()
        return workspace:Raycast(cameraPos, offset.Unit * distance, sharedParams)
    end)
    if not ok then return true end
    if not result or not result.Instance then return true end
    return result.Instance:IsDescendantOf(partParent)
end

-- ------------------------------------------------------------
-- Team detection (simplified for TWD - may not have teams)
-- ------------------------------------------------------------

function Utils.IsTeammate(player)
    if not player or player == Utils.LocalPlayer then return true end

    -- Check if game has teams
    local ok1, lTeam = pcall(function() return Utils.LocalPlayer.Team end)
    local ok2, pTeam = pcall(function() return player.Team end)
    if ok1 and ok2 and lTeam and pTeam then
        return lTeam == pTeam
    end

    -- Check for group-based teaming
    local ok3, lGroup = pcall(function() return Utils.LocalPlayer:GetAttribute("GroupId") end)
    local ok4, pGroup = pcall(function() return player:GetAttribute("GroupId") end)
    if ok3 and ok4 and lGroup and pGroup and lGroup ~= "" then
        return lGroup == pGroup
    end

    -- Default: everyone is an enemy in survival games
    return false
end

-- ------------------------------------------------------------
-- Color helper
-- ------------------------------------------------------------

function Utils.HexToColor(hex)
    if not hex or type(hex) ~= "string" then return Color3.fromRGB(255, 255, 255) end
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return Color3.fromRGB(255, 255, 255) end
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

-- ------------------------------------------------------------
-- Drawing helpers (stubs - will use BillboardGui instead)
-- ------------------------------------------------------------

function Utils.NewLine(thickness, color, transparency)
    return nil
end

function Utils.NewCircle(radius, color, thickness)
    return nil
end

function Utils.NewSquare(size, color, transparency)
    return nil
end

function Utils.NewText(size, color)
    return nil
end

function Utils.DestroyDrawing(obj)
    -- No-op
end

return Utils
