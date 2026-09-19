-- ============================================================
-- TWD Online -- ESP (Fixed)
-- Players + NPCs, skeletons, chams, names, health, items, distance
-- ============================================================

local ESP = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local Config = {
    Enabled = false,
    ShowNPCs = false,
    InfiniteDistance = false,
    MaxDistance = 500,

    Skeletons = false,
    Chams = false,
    Names = true,
    Health = true,
    HeldItem = true,
    Distance = true,

    PlayerColor = Color3.fromRGB(255, 60, 60),
    NPCColor = Color3.fromRGB(60, 255, 60),
}

-- Storage
local PlayerObjects = {}
local NPCObjects = {}
local SkeletonLines = {}

-- Check if Drawing API is available
local DrawingAvailable = pcall(function()
    local test = Drawing.new("Line")
    test:Remove()
end)

print("[TWD] Drawing API available: " .. tostring(DrawingAvailable))

-- ------------------------------------------------------------
-- Skeleton Drawing
-- ------------------------------------------------------------

local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function CreateSkeletonLine()
    if not DrawingAvailable then return nil end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1.5
    line.Transparency = 1
    line.Color = Color3.new(1, 1, 1)
    return line
end

local function UpdateSkeleton(character, color, maxDist)
    if not DrawingAvailable then return false end

    local lines = SkeletonLines[character]
    if not lines then
        lines = {}
        for i = 1, #BONE_CONNECTIONS do
            lines[i] = CreateSkeletonLine()
        end
        SkeletonLines[character] = lines
    end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not localRoot or not root then
        for _, line in ipairs(lines) do
            if line then line.Visible = false end
        end
        return false
    end

    local distance = (root.Position - localRoot.Position).Magnitude
    if not Config.InfiniteDistance and distance > maxDist then
        for _, line in ipairs(lines) do
            if line then line.Visible = false end
        end
        return false
    end

    local visible = false

    for i, connection in ipairs(BONE_CONNECTIONS) do
        local partA = character:FindFirstChild(connection[1])
        local partB = character:FindFirstChild(connection[2])
        local line = lines[i]

        if partA and partB and line then
            local posA, visA = Camera:WorldToViewportPoint(partA.Position)
            local posB, visB = Camera:WorldToViewportPoint(partB.Position)

            if visA and visB then
                line.From = Vector2.new(posA.X, posA.Y)
                line.To = Vector2.new(posB.X, posB.Y)
                line.Color = color
                line.Visible = true
                visible = true
            else
                line.Visible = false
            end
        elseif line then
            line.Visible = false
        end
    end

    return visible
end

local function RemoveSkeleton(character)
    local lines = SkeletonLines[character]
    if lines then
        for _, line in ipairs(lines) do
            if line then line:Remove() end
        end
        SkeletonLines[character] = nil
    end
end

-- ------------------------------------------------------------
-- Entity ESP Creation
-- ------------------------------------------------------------

local function CreateESP(model, isNPC)
    if not model then return nil end

    local head = model:FindFirstChild("Head")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not head or not humanoid or not root then 
        return nil 
    end

    local color = isNPC and Config.NPCColor or Config.PlayerColor

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(200, 80)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    billboard.Parent = head

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = isNPC and (model.Name or "NPC") or (model.Name or "Player")
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    -- Health bar (vertical, left side)
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0, 5, 0, 40)
    healthBg.Position = UDim2.new(0, -10, 0.5, -20)
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BackgroundTransparency = 0.4
    healthBg.BorderSizePixel = 0
    healthBg.Parent = billboard

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg

    -- Held item label
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 14)
    itemLabel.Position = UDim2.new(0, 0, 0, 18)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = ""
    itemLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    itemLabel.TextStrokeTransparency = 0.5
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextSize = 11
    itemLabel.Parent = billboard

    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 1, 2)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 11
    distLabel.Parent = billboard

    -- Chams
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    return {
        model = model,
        humanoid = humanoid,
        root = root,
        billboard = billboard,
        nameLabel = nameLabel,
        healthBg = healthBg,
        healthFill = healthFill,
        itemLabel = itemLabel,
        distLabel = distLabel,
        highlight = highlight,
        isNPC = isNPC,
    }
end

-- ------------------------------------------------------------
-- Update ESP for entity
-- ------------------------------------------------------------

local function UpdateESP(data)
    if not data or not data.model or not data.model.Parent then return false end

    local humanoid = data.humanoid
    if not humanoid or humanoid.Health <= 0 then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        RemoveSkeleton(data.model)
        return false
    end

    if not Config.Enabled then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        RemoveSkeleton(data.model)
        return true
    end

    -- Check NPC toggle
    if data.isNPC and not Config.ShowNPCs then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        RemoveSkeleton(data.model)
        return true
    end

    -- Distance check
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return true end

    local distance = (data.root.Position - localRoot.Position).Magnitude
    if not Config.InfiniteDistance and distance > Config.MaxDistance then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        RemoveSkeleton(data.model)
        return true
    end

    -- Enable billboard
    if data.billboard then
        data.billboard.Enabled = true

        -- Name
        if data.nameLabel then
            data.nameLabel.Visible = Config.Names
        end

        -- Health
        if data.healthBg and data.healthFill then
            data.healthBg.Visible = Config.Health
            local pct = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            data.healthFill.Size = UDim2.new(1, 0, pct, 0)

            if pct > 0.6 then
                data.healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif pct > 0.3 then
                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            else
                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end

        -- Held item
        if data.itemLabel then
            data.itemLabel.Visible = Config.HeldItem
            local tool = data.model:FindFirstChildOfClass("Tool")
            if tool then
                data.itemLabel.Text = tool.Name
            else
                data.itemLabel.Text = ""
            end
        end

        -- Distance
        if data.distLabel then
            data.distLabel.Visible = Config.Distance
            data.distLabel.Text = string.format("%.0f studs", distance)
        end
    end

    -- Chams
    if data.highlight then
        data.highlight.Enabled = Config.Chams
    end

    -- Skeleton
    if Config.Skeletons and DrawingAvailable then
        local color = data.isNPC and Config.NPCColor or Config.PlayerColor
        UpdateSkeleton(data.model, color, Config.MaxDistance)
    else
        RemoveSkeleton(data.model)
    end

    return true
end

-- ------------------------------------------------------------
-- NPC Detection (Improved)
-- ------------------------------------------------------------

local function IsNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Check name patterns
    local name = model.Name:lower()
    if name:find("zombie") or name:find("walker") or name:find("infected")
        or name:find("crawler") or name:find("runner") or name:find("bloater")
        or name:find("npc") or name:find("bandit") or name:find("raider")
        or name:find("shambler") or name:find("ghoul") then
        return true
    end

    -- Check parent folders
    local parent = model.Parent
    while parent and parent ~= workspace do
        local pname = parent.Name:lower()
        if pname:find("zombie") or pname:find("npc") or pname:find("walker") 
            or pname:find("infected") or pname:find("bandit") or pname:find("raider") then
            return true
        end
        parent = parent.Parent
    end

    -- If it has a humanoid but no player, and isn't in Players service, likely NPC
    -- But we need to be careful not to flag player characters
    local isInPlayers = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then
            isInPlayers = true
            break
        end
    end

    if not isInPlayers then
        -- Additional check: NPCs often have specific attributes or names
        if model:GetAttribute("IsNPC") or model:GetAttribute("ZombieType") then
            return true
        end
    end

    return false
end

local function GetNPCs()
    local npcs = {}

    -- Check common containers
    local containers = {
        workspace:FindFirstChild("Zombies"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Walkers"),
        workspace:FindFirstChild("Infected"),
        workspace:FindFirstChild("Entities"),
        workspace:FindFirstChild("Bandits"),
        workspace:FindFirstChild("Enemies"),
    }

    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Model") then
                    local humanoid = child:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        table.insert(npcs, child)
                    end
                end
            end
        end
    end

    -- Scan workspace for any model with humanoid that's not a player
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not Players:GetPlayerFromCharacter(child) then
            local humanoid = child:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local alreadyAdded = false
                for _, n in ipairs(npcs) do
                    if n == child then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(npcs, child)
                end
            end
        end
    end

    return npcs
end

-- ------------------------------------------------------------
-- Player Management
-- ------------------------------------------------------------

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head", 5)
        character:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3)

        if not PlayerObjects[player] then
            local data = CreateESP(character, false)
            if data then
                PlayerObjects[player] = data
                print("[TWD] Created ESP for player: " .. player.Name)
            end
        end
    end)

    if player.Character then
        task.spawn(function()
            player.Character:WaitForChild("Head", 5)
            task.wait(0.3)

            if not PlayerObjects[player] then
                local data = CreateESP(player.Character, false)
                if data then
                    PlayerObjects[player] = data
                    print("[TWD] Created ESP for player: " .. player.Name)
                end
            end
        end)
    end

    player.CharacterRemoving:Connect(function(character)
        if PlayerObjects[player] then
            local data = PlayerObjects[player]
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            RemoveSkeleton(character)
            PlayerObjects[player] = nil
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        OnPlayerAdded(player)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    if PlayerObjects[player] then
        local data = PlayerObjects[player]
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.model then RemoveSkeleton(data.model) end
        PlayerObjects[player] = nil
    end
end)

-- ------------------------------------------------------------
-- Main Update Loop
-- ------------------------------------------------------------

local lastNPCScan = 0
local NPC_SCAN_INTERVAL = 0.5
local frameCount = 0

function ESP.Update()
    frameCount = frameCount + 1

    if not Config.Enabled then
        -- Hide all
        for _, data in pairs(PlayerObjects) do
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.model then RemoveSkeleton(data.model) end
        end
        for _, data in pairs(NPCObjects) do
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.model then RemoveSkeleton(data.model) end
        end
        return
    end

    -- Update players
    for player, data in pairs(PlayerObjects) do
        if not player or not player.Parent then
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.model then RemoveSkeleton(data.model) end
            PlayerObjects[player] = nil
        else
            -- Refresh character reference if needed
            if not data.model or not data.model.Parent then
                if player.Character then
                    local newData = CreateESP(player.Character, false)
                    if newData then
                        PlayerObjects[player] = newData
                    end
                end
            else
                UpdateESP(data)
            end
        end
    end

    -- Scan for NPCs periodically
    local now = tick()
    if now - lastNPCScan > NPC_SCAN_INTERVAL then
        lastNPCScan = now

        local npcs = GetNPCs()

        -- Debug: print NPC count occasionally
        if frameCount % 120 == 0 then
            print("[TWD] Found " .. #npcs .. " NPCs, " .. 
                  tostring(function() local c = 0 for _ in pairs(PlayerObjects) do c = c + 1 end return c end)() .. " players with ESP")
        end

        -- Create ESP for new NPCs
        for _, npc in ipairs(npcs) do
            if not NPCObjects[npc] then
                local data = CreateESP(npc, true)
                if data then
                    NPCObjects[npc] = data
                end
            end
        end

        -- Remove dead/gone NPCs
        for npc, data in pairs(NPCObjects) do
            if not npc or not npc.Parent then
                if data.billboard then data.billboard:Destroy() end
                if data.highlight then data.highlight:Destroy() end
                RemoveSkeleton(npc)
                NPCObjects[npc] = nil
            end
        end
    end

    -- Update NPCs
    for npc, data in pairs(NPCObjects) do
        UpdateESP(data)
    end
end

RunService.RenderStepped:Connect(function()
    local ok, err = pcall(ESP.Update)
    if not ok then
        warn("[TWD] ESP Update error: " .. tostring(err))
    end
end)

-- ------------------------------------------------------------
-- Config Interface
-- ------------------------------------------------------------

function ESP.SetConfig(key, value)
    Config[key] = value
    print("[TWD] Config: " .. key .. " = " .. tostring(value))
end

function ESP.GetConfig(key)
    return Config[key]
end

function ESP.GetConfigTable()
    return Config
end

-- ------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------

function ESP.Init(deps)
    print("[TWD] ESP module initialized.")
    print("[TWD] Drawing API: " .. tostring(DrawingAvailable))
end

function ESP.Cleanup()
    for _, data in pairs(PlayerObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.model then RemoveSkeleton(data.model) end
    end
    table.clear(PlayerObjects)

    for _, data in pairs(NPCObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.model then RemoveSkeleton(data.model) end
    end
    table.clear(NPCObjects)
end

return ESP