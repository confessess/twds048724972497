-- ============================================================
-- TWD Online -- ESP
-- Clean ESP: Players + NPCs, Boxes, Chams, Names, Health, Items, Distance
-- ============================================================

local ESP = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- Config
local Config = {
    Enabled = false,
    ShowNPCs = true,
    InfiniteDistance = false,
    MaxDistance = 500,

    Boxes = true,
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

-- ------------------------------------------------------------
-- Create ESP for entity
-- ------------------------------------------------------------

local function CreateESP(model, isNPC)
    if not model then return nil end

    local head = model:FindFirstChild("Head")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not head or not humanoid or not root then return nil end

    local color = isNPC and Config.NPCColor or Config.PlayerColor

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(200, 100)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    billboard.Parent = head

    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = model.Name or (isNPC and "NPC" or "Player")
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    -- Health bar background
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0, 6, 0, 50)
    healthBg.Position = UDim2.new(0, -12, 0.5, -25)
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BackgroundTransparency = 0.3
    healthBg.BorderSizePixel = 0
    healthBg.Parent = billboard

    -- Health fill
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg

    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(0, 40, 0, 14)
    healthText.Position = UDim2.new(0, -50, 0.5, -7)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextStrokeTransparency = 0.5
    healthText.Font = Enum.Font.GothamBold
    healthText.TextSize = 11
    healthText.Parent = billboard

    -- Held item
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

    -- Distance
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 0, 34)
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

    -- Box
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box"
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = color
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Adornee = root
    box.Parent = root

    return {
        model = model,
        humanoid = humanoid,
        root = root,
        billboard = billboard,
        nameLabel = nameLabel,
        healthBg = healthBg,
        healthFill = healthFill,
        healthText = healthText,
        itemLabel = itemLabel,
        distLabel = distLabel,
        highlight = highlight,
        box = box,
        isNPC = isNPC,
    }
end

-- ------------------------------------------------------------
-- Update ESP
-- ------------------------------------------------------------

local function UpdateESP(data)
    if not data or not data.model or not data.model.Parent then return false end

    local humanoid = data.humanoid
    if not humanoid or humanoid.Health <= 0 then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        if data.box then data.box.Enabled = false end
        return false
    end

    -- Check enabled
    if not Config.Enabled then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        if data.box then data.box.Enabled = false end
        return true
    end

    -- Check NPC toggle
    if data.isNPC and not Config.ShowNPCs then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        if data.box then data.box.Enabled = false end
        return true
    end

    -- Distance check
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return true end

    local distance = (data.root.Position - localRoot.Position).Magnitude
    if not Config.InfiniteDistance and distance > Config.MaxDistance then
        if data.billboard then data.billboard.Enabled = false end
        if data.highlight then data.highlight.Enabled = false end
        if data.box then data.box.Enabled = false end
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
            data.healthFill.Visible = Config.Health
            local pct = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            data.healthFill.Size = UDim2.new(1, 0, pct, 0)

            if pct > 0.6 then
                data.healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif pct > 0.3 then
                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            else
                data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end

            if data.healthText then
                data.healthText.Visible = Config.Health
                data.healthText.Text = tostring(math.floor(humanoid.Health))
                data.healthText.TextColor3 = data.healthFill.BackgroundColor3
            end
        end

        -- Held item
        if data.itemLabel then
            data.itemLabel.Visible = Config.HeldItem
            local tool = data.model:FindFirstChildOfClass("Tool")
            data.itemLabel.Text = tool and tool.Name or ""
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

    -- Box
    if data.box then
        data.box.Enabled = Config.Boxes
    end

    return true
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
            if humanoid and humanoid.Health > 0 then
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
                end
            end
        end)
    end

    player.CharacterRemoving:Connect(function(character)
        if PlayerObjects[player] then
            local data = PlayerObjects[player]
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.box then data.box:Destroy() end
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
        if data.box then data.box:Destroy() end
        PlayerObjects[player] = nil
    end
end)

-- ------------------------------------------------------------
-- Main Update
-- ------------------------------------------------------------

local lastNPCScan = 0
local NPC_SCAN_INTERVAL = 0.5

function ESP.Update()
    if not Config.Enabled then
        for _, data in pairs(PlayerObjects) do
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
        end
        for _, data in pairs(NPCObjects) do
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
        end
        return
    end

    -- Update players
    for player, data in pairs(PlayerObjects) do
        if not player or not player.Parent then
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.box then data.box:Destroy() end
            PlayerObjects[player] = nil
        elseif not data.model or not data.model.Parent then
            if player.Character then
                local newData = CreateESP(player.Character, false)
                if newData then PlayerObjects[player] = newData end
            end
        else
            UpdateESP(data)
        end
    end

    -- Scan NPCs
    local now = tick()
    if now - lastNPCScan > NPC_SCAN_INTERVAL then
        lastNPCScan = now

        local npcs = GetNPCs()

        for _, npc in ipairs(npcs) do
            if not NPCObjects[npc] then
                local data = CreateESP(npc, true)
                if data then NPCObjects[npc] = data end
            end
        end

        for npc, data in pairs(NPCObjects) do
            if not npc or not npc.Parent then
                if data.billboard then data.billboard:Destroy() end
                if data.highlight then data.highlight:Destroy() end
                if data.box then data.box:Destroy() end
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
    print("[TWD] ESP initialized")
end

function ESP.Cleanup()
    for _, data in pairs(PlayerObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.box then data.box:Destroy() end
    end
    for _, data in pairs(NPCObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.box then data.box:Destroy() end
    end
    table.clear(PlayerObjects)
    table.clear(NPCObjects)
end

return ESP