-- ============================================================
-- TWD Online -- ESP (Drawing API + NPC Support)
-- Based on Pouncing.exe style ESP
-- ============================================================

local ESP = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Config
local Config = {
    Enabled = false,
    ShowNPCs = true,
    InfiniteDistance = false,
    MaxDistance = 500,

    Boxes = true,
    Box3D = false,
    Names = true,
    Health = true,
    HeldItem = true,
    Distance = true,
    Skeleton = false,
    Chams = false,
    HeadDot = false,

    PlayerColor = Color3.fromRGB(255, 60, 60),
    NPCColor = Color3.fromRGB(60, 255, 60),
    BoxThickness = 1.5,
}

-- Storage
local PlayerObjects = {}
local NPCObjects = {}
local ESPDrawingObjects = {}
local NPCDrawingObjects = {}

-- ------------------------------------------------------------
-- Drawing Helpers
-- ------------------------------------------------------------

local function MakeDrawing(type, props)
    local s, obj = pcall(Drawing.new, type)
    if not s or not obj then return nil end
    for k, v in pairs(props or {}) do 
        pcall(function() obj[k] = v end) 
    end
    return obj
end

local function SetDrawing(obj, key, value)
    if obj then pcall(function() obj[key] = value end) end
end

local function RemoveDrawing(obj)
    if obj then pcall(function() obj:Remove() end) end
end

local function W2S(position)
    local s, x, y, z = pcall(function()
        local v = Camera:WorldToViewportPoint(position)
        return v.X, v.Y, v.Z
    end)
    if s and z and z > 0 then return Vector2.new(x, y), true, z end
    return Vector2.new(-999, -999), false, 0
end

-- ------------------------------------------------------------
-- Box Calculations
-- ------------------------------------------------------------

local function GetBoxData(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then return nil end
    local s, extents = pcall(function() return character:GetExtentsSize() end)
    if not s or not extents then return nil end
    local size = extents * 1.1
    local topPos = root.Position + Vector3.new(0, size.Y / 2, 0)
    local botPos = root.Position - Vector3.new(0, size.Y / 2, 0)
    local topScr, topVis, topZ = W2S(topPos)
    local botScr, botVis, botZ = W2S(botPos)
    if (not topVis and not botVis) or topZ <= 0 or botZ <= 0 then return nil end
    local h = math.abs(botScr.Y - topScr.Y)
    local w = h * 0.6
    if h <= 1 or w <= 1 then return nil end
    return {
        TL = Vector2.new(topScr.X - w / 2, topScr.Y),
        BR = Vector2.new(topScr.X + w / 2, botScr.Y),
        Size = Vector2.new(w, h),
        Center = Vector2.new(topScr.X, (topScr.Y + botScr.Y) / 2),
        Pos = root.Position,
        Extents = extents
    }
end

local function Get3DCorners(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not root then return nil end
    local s, extents = pcall(function() return character:GetExtentsSize() end)
    if not s or not extents then return nil end
    local p = root.Position
    local hx, hy, hz = extents.X / 2, extents.Y / 2, extents.Z / 2
    local corners = {
        p + Vector3.new(-hx, -hy, -hz), p + Vector3.new(hx, -hy, -hz),
        p + Vector3.new(hx, -hy, hz), p + Vector3.new(-hx, -hy, hz),
        p + Vector3.new(-hx, hy, -hz), p + Vector3.new(hx, hy, -hz),
        p + Vector3.new(hx, hy, hz), p + Vector3.new(-hx, hy, hz)
    }
    local screenCorners = {}
    for i = 1, 8 do
        local sp, vis, z = W2S(corners[i])
        if not vis or z <= 0 then return nil end
        screenCorners[i] = sp
    end
    return screenCorners
end

local Box3DEdges = {
    {1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}
}

local SkeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

-- ------------------------------------------------------------
-- Initialize ESP for entity
-- ------------------------------------------------------------

local function InitESP(character, isNPC, storageTable)
    if not character or storageTable[character] then return end

    local color = isNPC and Config.NPCColor or Config.PlayerColor
    local name = isNPC and (character.Name or "NPC") or character.Name

    local skel = {}
    for i = 1, #SkeletonConnections do
        table.insert(skel, MakeDrawing("Line", {Visible = false, Thickness = 1.5, Color = color, Transparency = 0.8}))
        table.insert(skel, MakeDrawing("Line", {Visible = false, Thickness = 3, Color = Color3.fromRGB(0,0,0), Transparency = 0.5}))
    end

    local b3d = {}
    for i = 1, 12 do
        table.insert(b3d, MakeDrawing("Line", {Visible = false, Thickness = 1.5, Color = color, Transparency = 0.9}))
    end

    storageTable[character] = {
        Box = MakeDrawing("Square", {Visible = false, Thickness = Config.BoxThickness, Color = color, Transparency = 0.9, Filled = false}),
        B3D = b3d,
        Name = MakeDrawing("Text", {Visible = false, Text = name, Size = 16, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = Color3.fromRGB(255,255,255)}),
        HB = MakeDrawing("Square", {Visible = false, Thickness = 1, Filled = true, Color = Color3.fromRGB(0,255,100)}),
        HBO = MakeDrawing("Square", {Visible = false, Thickness = 1, Filled = true, Color = Color3.fromRGB(0,0,0)}),
        HT = MakeDrawing("Text", {Visible = false, Text = "100", Size = 13, Center = false, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = Color3.fromRGB(255,255,255)}),
        Skel = skel,
        Dist = MakeDrawing("Text", {Visible = false, Text = "", Size = 14, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = Color3.fromRGB(200,200,200)}),
        HeadDot = MakeDrawing("Circle", {Visible = false, Thickness = 1, Color = Color3.fromRGB(255,255,255), Transparency = 0.9, NumSides = 16, Filled = true}),
        Weapon = MakeDrawing("Text", {Visible = false, Text = "", Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Color = Color3.fromRGB(255,200,100)}),
        isNPC = isNPC,
    }
end

local function ClearESP(character, storageTable)
    if not storageTable[character] then return end
    local o = storageTable[character]
    for k, v in pairs(o) do
        if k == "Skel" or k == "B3D" then
            for _, line in pairs(v) do RemoveDrawing(line) end
        elseif k ~= "isNPC" then
            RemoveDrawing(v)
        end
    end
    storageTable[character] = nil

    -- Remove chams
    local h = character:FindFirstChild("ESP_Chams")
    if h then h:Destroy() end
end

local function HideAllESP(o)
    SetDrawing(o.Box, "Visible", false)
    SetDrawing(o.Name, "Visible", false)
    SetDrawing(o.Dist, "Visible", false)
    SetDrawing(o.HB, "Visible", false)
    SetDrawing(o.HBO, "Visible", false)
    SetDrawing(o.HT, "Visible", false)
    SetDrawing(o.HeadDot, "Visible", false)
    SetDrawing(o.Weapon, "Visible", false)
    for _, l in pairs(o.Skel) do SetDrawing(l, "Visible", false) end
    for _, l in pairs(o.B3D) do SetDrawing(l, "Visible", false) end
end

-- ------------------------------------------------------------
-- Update ESP for entity
-- ------------------------------------------------------------

local function UpdateESPForEntity(character, o)
    if not character or not character.Parent then
        ClearESP(character, o.isNPC and NPCDrawingObjects or ESPDrawingObjects)
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")

    if not hum or not root or hum.Health <= 0 then
        HideAllESP(o)
        local hl = character:FindFirstChild("ESP_Chams")
        if hl then hl.Enabled = false end
        return
    end

    -- Check if should show
    if not Config.Enabled then
        HideAllESP(o)
        local hl = character:FindFirstChild("ESP_Chams")
        if hl then hl.Enabled = false end
        return
    end

    -- Check NPC toggle
    if o.isNPC and not Config.ShowNPCs then
        HideAllESP(o)
        local hl = character:FindFirstChild("ESP_Chams")
        if hl then hl.Enabled = false end
        return
    end

    -- Distance check
    local dist = (root.Position - Camera.CFrame.Position).Magnitude
    if not Config.InfiniteDistance and dist > Config.MaxDistance then
        HideAllESP(o)
        local hl = character:FindFirstChild("ESP_Chams")
        if hl then hl.Enabled = false end
        return
    end

    local color = o.isNPC and Config.NPCColor or Config.PlayerColor

    -- Update Chams
    if Config.Chams then
        local hl = character:FindFirstChild("ESP_Chams")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "ESP_Chams"
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = character
        end
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.2
        hl.Enabled = true
    else
        local hl = character:FindFirstChild("ESP_Chams")
        if hl then hl.Enabled = false end
    end

    -- Get box data
    local box = GetBoxData(character)
    if not box then
        HideAllESP(o)
        return
    end

    -- Box
    if Config.Boxes and not Config.Box3D then
        SetDrawing(o.Box, "Size", box.Size)
        SetDrawing(o.Box, "Position", box.TL)
        SetDrawing(o.Box, "Color", color)
        SetDrawing(o.Box, "Thickness", Config.BoxThickness)
        SetDrawing(o.Box, "Visible", true)
    else
        SetDrawing(o.Box, "Visible", false)
    end

    -- 3D Box
    if Config.Boxes and Config.Box3D then
        local c = Get3DCorners(character)
        if c then
            for i, e in ipairs(Box3DEdges) do
                SetDrawing(o.B3D[i], "From", c[e[1]])
                SetDrawing(o.B3D[i], "To", c[e[2]])
                SetDrawing(o.B3D[i], "Color", color)
                SetDrawing(o.B3D[i], "Visible", true)
            end
        else
            for _, l in pairs(o.B3D) do SetDrawing(l, "Visible", false) end
        end
    else
        for _, l in pairs(o.B3D) do SetDrawing(l, "Visible", false) end
    end

    -- Name
    if Config.Names then
        SetDrawing(o.Name, "Position", Vector2.new(box.Center.X, box.TL.Y - 16))
        SetDrawing(o.Name, "Text", character.Name)
        SetDrawing(o.Name, "Color", color)
        SetDrawing(o.Name, "Visible", true)
    else
        SetDrawing(o.Name, "Visible", false)
    end

    -- Distance
    if Config.Distance then
        SetDrawing(o.Dist, "Position", Vector2.new(box.Center.X, box.BR.Y + 4))
        SetDrawing(o.Dist, "Text", math.floor(dist) .. "m")
        SetDrawing(o.Dist, "Color", Color3.fromRGB(200, 200, 200))
        SetDrawing(o.Dist, "Visible", true)
    else
        SetDrawing(o.Dist, "Visible", false)
    end

    -- Health
    if Config.Health then
        local mh = hum.MaxHealth
        local ch = hum.Health
        if mh and mh > 0 and ch and ch >= 0 then
            local pct = math.clamp(ch / mh, 0, 1)
            local bh = math.max(box.Size.Y * pct, 2)
            local bw = 4

            SetDrawing(o.HBO, "Size", Vector2.new(bw + 2, box.Size.Y + 2))
            SetDrawing(o.HBO, "Position", Vector2.new(box.TL.X - bw - 6, box.TL.Y - 1))
            SetDrawing(o.HBO, "Visible", true)

            SetDrawing(o.HB, "Size", Vector2.new(bw, bh))
            SetDrawing(o.HB, "Position", Vector2.new(box.TL.X - bw - 5, box.BR.Y - bh))

            local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 100), pct)
            SetDrawing(o.HB, "Color", healthColor)
            SetDrawing(o.HB, "Visible", true)

            SetDrawing(o.HT, "Position", Vector2.new(box.TL.X - bw - 28, box.BR.Y - bh - 6))
            SetDrawing(o.HT, "Text", math.floor(ch))
            SetDrawing(o.HT, "Visible", true)
        else
            SetDrawing(o.HB, "Visible", false)
            SetDrawing(o.HBO, "Visible", false)
            SetDrawing(o.HT, "Visible", false)
        end
    else
        SetDrawing(o.HB, "Visible", false)
        SetDrawing(o.HBO, "Visible", false)
        SetDrawing(o.HT, "Visible", false)
    end

    -- Skeleton
    if Config.Skeleton then
        local idx = 1
        for _, conn in ipairs(SkeletonConnections) do
            local p1 = character:FindFirstChild(conn[1])
            local p2 = character:FindFirstChild(conn[2])
            local line = o.Skel[idx]
            local outline = o.Skel[idx + 1]
            idx = idx + 2

            if p1 and p2 and line and outline then
                local s1, v1 = W2S(p1.Position)
                local s2, v2 = W2S(p2.Position)
                if v1 and v2 then
                    SetDrawing(outline, "From", s1)
                    SetDrawing(outline, "To", s2)
                    SetDrawing(outline, "Visible", true)
                    SetDrawing(line, "From", s1)
                    SetDrawing(line, "To", s2)
                    SetDrawing(line, "Color", color)
                    SetDrawing(line, "Visible", true)
                else
                    SetDrawing(line, "Visible", false)
                    SetDrawing(outline, "Visible", false)
                end
            else
                if line then SetDrawing(line, "Visible", false) end
                if outline then SetDrawing(outline, "Visible", false) end
            end
        end
    else
        for _, l in pairs(o.Skel) do SetDrawing(l, "Visible", false) end
    end

    -- Head Dot
    if Config.HeadDot then
        local head = character:FindFirstChild("Head")
        if head then
            local headPos, onScreen = W2S(head.Position)
            if onScreen then
                local radius = math.clamp(3000 / dist, 3, 12)
                SetDrawing(o.HeadDot, "Position", headPos)
                SetDrawing(o.HeadDot, "Radius", radius)
                SetDrawing(o.HeadDot, "Color", color)
                SetDrawing(o.HeadDot, "Visible", true)
            else
                SetDrawing(o.HeadDot, "Visible", false)
            end
        else
            SetDrawing(o.HeadDot, "Visible", false)
        end
    else
        SetDrawing(o.HeadDot, "Visible", false)
    end

    -- Held Item / Weapon
    if Config.HeldItem then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            SetDrawing(o.Weapon, "Position", Vector2.new(box.Center.X, box.BR.Y + 18))
            SetDrawing(o.Weapon, "Text", "[" .. tool.Name .. "]")
            SetDrawing(o.Weapon, "Visible", true)
        else
            SetDrawing(o.Weapon, "Visible", false)
        end
    else
        SetDrawing(o.Weapon, "Visible", false)
    end
end

-- ------------------------------------------------------------
-- NPC Detection
-- ------------------------------------------------------------

local function IsNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local name = model.Name:lower()
    if name:find("zombie") or name:find("walker") or name:find("infected")
        or name:find("crawler") or name:find("runner") or name:find("bloater")
        or name:find("npc") or name:find("bandit") or name:find("raider")
        or name:find("shambler") or name:find("ghoul") then
        return true
    end

    local parent = model.Parent
    while parent and parent ~= workspace do
        local pname = parent.Name:lower()
        if pname:find("zombie") or pname:find("npc") or pname:find("walker") 
            or pname:find("infected") or pname:find("bandit") or pname:find("raider") then
            return true
        end
        parent = parent.Parent
    end

    return false
end

local function GetNPCs()
    local npcs = {}

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

    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not Players:GetPlayerFromCharacter(child) then
            local humanoid = child:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and IsNPC(child) then
                local exists = false
                for _, n in ipairs(npcs) do
                    if n == child then exists = true break end
                end
                if not exists then
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

local function OnPlayerCharacterAdded(player, character)
    task.wait(0.1)
    InitESP(character, false, ESPDrawingObjects)
end

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function(character)
        OnPlayerCharacterAdded(player, character)
    end)

    if player.Character then
        task.spawn(function()
            OnPlayerCharacterAdded(player, player.Character)
        end)
    end
end

-- Initial setup
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        OnPlayerAdded(player)
    end
end

-- CONSTANT: Watch for new players joining
Players.PlayerAdded:Connect(function(player)
    print("[TWD] New player joined: " .. player.Name)
    OnPlayerAdded(player)

    -- Also try to init immediately if they have a character
    if player.Character then
        task.spawn(function()
            task.wait(0.1)
            if not ESPDrawingObjects[player] then
                InitESP(player.Character, false, ESPDrawingObjects)
            end
        end)
    end
end)

-- Watch for players leaving
Players.PlayerRemoving:Connect(function(player)
    print("[TWD] Player left: " .. player.Name)
    if player.Character then
        ClearESP(player.Character, ESPDrawingObjects)
    end
    ESPDrawingObjects[player] = nil
end)

-- Watch for character spawns (respawns)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        print("[TWD] " .. player.Name .. " respawned")
        task.wait(0.2)
        -- Clear old ESP if exists
        if ESPDrawingObjects[player] then
            ClearESP(ESPDrawingObjects[player].model, ESPDrawingObjects)
        end
        -- Create new ESP
        InitESP(character, false, ESPDrawingObjects)
    end)
end)

-- ------------------------------------------------------------
-- Main Update
-- ------------------------------------------------------------

local lastNPCScan = 0
local NPC_SCAN_INTERVAL = 0.5

function ESP.Update()
    if not Config.Enabled then
        -- Hide all
        for char, o in pairs(ESPDrawingObjects) do
            HideAllESP(o)
            local hl = char:FindFirstChild("ESP_Chams")
            if hl then hl.Enabled = false end
        end
        for char, o in pairs(NPCDrawingObjects) do
            HideAllESP(o)
            local hl = char:FindFirstChild("ESP_Chams")
            if hl then hl.Enabled = false end
        end
        return
    end

    -- Update players
    for char, o in pairs(ESPDrawingObjects) do
        if not char or not char.Parent then
            ClearESP(char, ESPDrawingObjects)
        else
            pcall(function() UpdateESPForEntity(char, o) end)
        end
    end

    -- Scan for NPCs
    local now = tick()
    if now - lastNPCScan > NPC_SCAN_INTERVAL then
        lastNPCScan = now

        local npcs = GetNPCs()

        -- Init new NPCs
        for _, npc in ipairs(npcs) do
            if not NPCDrawingObjects[npc] then
                InitESP(npc, true, NPCDrawingObjects)
            end
        end

        -- Clear gone NPCs
        for char, o in pairs(NPCDrawingObjects) do
            if not char or not char.Parent then
                ClearESP(char, NPCDrawingObjects)
            end
        end
    end

    -- Update NPCs
    for char, o in pairs(NPCDrawingObjects) do
        pcall(function() UpdateESPForEntity(char, o) end)
    end
end

RunService.RenderStepped:Connect(function()
    local ok, err = pcall(ESP.Update)
    if not ok then warn("[TWD] ESP error: " .. tostring(err)) end
end)

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------

function ESP.SetConfig(key, value)
    Config[key] = value
end

function ESP.GetConfig(key)
    return Config[key]
end

function ESP.Init()
    print("[TWD] ESP initialized (Drawing API)")
end

function ESP.Cleanup()
    for char, _ in pairs(ESPDrawingObjects) do
        ClearESP(char, ESPDrawingObjects)
    end
    for char, _ in pairs(NPCDrawingObjects) do
        ClearESP(char, NPCDrawingObjects)
    end
end

return ESP