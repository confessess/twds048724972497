-- ============================================================
-- The Walking Dead Online -- ESP
-- Player ESP, Zombie ESP, Loot ESP with toggles
-- ============================================================

local ESP = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local Config, Utils, GUI

-- ESP Colors
local COLORS = {
    Player = Color3.fromRGB(255, 60, 60),      -- Red for players
    Zombie = Color3.fromRGB(60, 255, 60),      -- Green for zombies
    Loot = {
        Weapons = Color3.fromRGB(255, 100, 100),    -- Red-ish
        Food = Color3.fromRGB(255, 200, 100),       -- Orange
        Meds = Color3.fromRGB(100, 255, 100),       -- Green
        Ammo = Color3.fromRGB(255, 255, 100),       -- Yellow
        Resources = Color3.fromRGB(150, 150, 150),  -- Gray
        Attachments = Color3.fromRGB(200, 100, 255),-- Purple
        Clothes = Color3.fromRGB(100, 200, 255),    -- Light blue
        Other = Color3.fromRGB(200, 200, 200),      -- Light gray
    }
}

-- ESP Objects storage
local PlayerESPObjects = {}
local ZombieESPObjects = {}
local LootESPObjects = {}

-- ------------------------------------------------------------
-- Helper: Create Billboard ESP
-- ------------------------------------------------------------

local function CreateBillboardESP(parent, name, color, size)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. name
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = size or UDim2.fromOffset(200, 60)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    billboard.Parent = parent
    return billboard
end

local function CreateBoxESP(parent, color)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box"
    box.Color3 = color
    box.Transparency = 0.5
    box.Size = Vector3.new(4, 6, 2)
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Adornee = parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChild("Head") or parent
    box.Parent = parent
    return box
end

local function CreateTracer(from, to, color)
    -- Tracers would use Beam or LineHandleAdornment
    -- For simplicity, we'll use a Highlight for now
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Tracer"
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.5
    highlight.Adornee = to
    highlight.Parent = from
    return highlight
end

-- ------------------------------------------------------------
-- PLAYER ESP
-- ------------------------------------------------------------

local function CreatePlayerESP(player)
    if PlayerESPObjects[player] then return end
    if not player.Character then return end

    local character = player.Character
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not head or not humanoid or not root then return end

    local S = Config.Settings

    -- Main billboard
    local billboard = CreateBillboardESP(head, "Player", COLORS.Player)
    billboard.MaxDistance = S.PlayerESP_MaxDistance

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = COLORS.Player
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    -- Health bar (vertical)
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

    -- Weapon label (if they have one equipped)
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(1, 0, 0, 12)
    weaponLabel.Position = UDim2.new(0, 0, 0, 18)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = ""
    weaponLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    weaponLabel.TextStrokeTransparency = 0.5
    weaponLabel.Font = Enum.Font.GothamMedium
    weaponLabel.TextSize = 10
    weaponLabel.Parent = billboard

    -- Chams (Highlight)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = COLORS.Player
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Box ESP
    local box = CreateBoxESP(character, COLORS.Player)

    PlayerESPObjects[player] = {
        player = player,
        character = character,
        humanoid = humanoid,
        root = root,
        billboard = billboard,
        nameLabel = nameLabel,
        healthBg = healthBg,
        healthFill = healthFill,
        distLabel = distLabel,
        weaponLabel = weaponLabel,
        highlight = highlight,
        box = box,
    }
end

local function UpdatePlayerESP()
    local S = Config.Settings

    for player, data in pairs(PlayerESPObjects) do
        -- Check if player still valid
        if not player or not player.Parent or not data.character or not data.character.Parent then
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.box then data.box:Destroy() end
            PlayerESPObjects[player] = nil
            continue
        end

        -- Check if ESP enabled
        if not S.PlayerESP_Enabled then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Check if player alive
        local humanoid = data.humanoid
        if not humanoid or humanoid.Health <= 0 then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Team check
        if S.PlayerESP_TeamCheck and Utils.IsTeammate(player) then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Calculate distance
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = 0
        if localRoot and data.root then
            distance = (data.root.Position - localRoot.Position).Magnitude
        end

        -- Max distance check
        if distance > S.PlayerESP_MaxDistance then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Enable ESP elements
        if data.billboard then
            data.billboard.Enabled = true
            data.billboard.MaxDistance = S.PlayerESP_MaxDistance

            -- Name
            if data.nameLabel then
                data.nameLabel.Visible = S.PlayerESP_Names
            end

            -- Health
            if data.healthBg and data.healthFill then
                data.healthBg.Visible = S.PlayerESP_Health
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

            -- Distance
            if data.distLabel then
                data.distLabel.Visible = S.PlayerESP_Distance
                data.distLabel.Text = string.format("%.0f studs", distance)
            end

            -- Weapon (check what they're holding)
            if data.weaponLabel then
                data.weaponLabel.Visible = S.PlayerESP_Weapon
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if tool then
                    data.weaponLabel.Text = tool.Name
                else
                    data.weaponLabel.Text = "Unarmed"
                end
            end
        end

        -- Chams
        if data.highlight then
            data.highlight.Enabled = S.PlayerESP_Chams
        end

        -- Box
        if data.box then
            data.box.Enabled = S.PlayerESP_Boxes
        end
    end
end

-- ------------------------------------------------------------
-- ZOMBIE ESP
-- ------------------------------------------------------------

local function CreateZombieESP(zombie)
    if ZombieESPObjects[zombie] then return end

    local head = zombie:FindFirstChild("Head")
    local humanoid = zombie:FindFirstChildOfClass("Humanoid")
    local root = zombie:FindFirstChild("HumanoidRootPart")

    if not head or not humanoid or not root then return end

    local S = Config.Settings

    -- Main billboard
    local billboard = CreateBillboardESP(head, "Zombie", COLORS.Zombie)
    billboard.MaxDistance = S.ZombieESP_MaxDistance
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)

    -- Name/Type label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = zombie.Name
    nameLabel.TextColor3 = COLORS.Zombie
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Parent = billboard

    -- Health bar
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(0, 4, 0, 30)
    healthBg.Position = UDim2.new(0, -8, 0.5, -15)
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

    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 12)
    distLabel.Position = UDim2.new(0, 0, 1, 2)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 10
    distLabel.Parent = billboard

    -- Chams
    local highlight = Instance.new("Highlight")
    highlight.Adornee = zombie
    highlight.FillColor = COLORS.Zombie
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = zombie

    -- Box
    local box = CreateBoxESP(zombie, COLORS.Zombie)

    ZombieESPObjects[zombie] = {
        zombie = zombie,
        humanoid = humanoid,
        root = root,
        billboard = billboard,
        nameLabel = nameLabel,
        healthBg = healthBg,
        healthFill = healthFill,
        distLabel = distLabel,
        highlight = highlight,
        box = box,
    }
end

local function UpdateZombieESP()
    local S = Config.Settings

    -- Get current zombies
    local zombies = Utils.GetZombies()

    -- Create ESP for new zombies
    for _, zombie in ipairs(zombies) do
        if not ZombieESPObjects[zombie] then
            CreateZombieESP(zombie)
        end
    end

    -- Update all zombie ESP
    for zombie, data in pairs(ZombieESPObjects) do
        -- Check if zombie still exists
        if not zombie or not zombie.Parent then
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.box then data.box:Destroy() end
            ZombieESPObjects[zombie] = nil
            continue
        end

        -- Check if enabled
        if not S.ZombieESP_Enabled then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Check if alive
        local humanoid = data.humanoid
        if not humanoid or humanoid.Health <= 0 then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Calculate distance
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = 0
        if localRoot and data.root then
            distance = (data.root.Position - localRoot.Position).Magnitude
        end

        -- Max distance
        if distance > S.ZombieESP_MaxDistance then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            if data.box then data.box.Enabled = false end
            continue
        end

        -- Enable ESP
        if data.billboard then
            data.billboard.Enabled = true

            -- Name
            if data.nameLabel then
                data.nameLabel.Visible = S.ZombieESP_Names or S.ZombieESP_ShowType
            end

            -- Health
            if data.healthBg and data.healthFill then
                data.healthBg.Visible = S.ZombieESP_Health
                local pct = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                data.healthFill.Size = UDim2.new(1, 0, pct, 0)

                if pct > 0.5 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                elseif pct > 0.25 then
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                else
                    data.healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end

            -- Distance
            if data.distLabel then
                data.distLabel.Visible = S.ZombieESP_Distance
                data.distLabel.Text = string.format("%.0f studs", distance)
            end
        end

        -- Chams
        if data.highlight then
            data.highlight.Enabled = S.ZombieESP_Chams
        end

        -- Box
        if data.box then
            data.box.Enabled = S.ZombieESP_Boxes
        end
    end
end

-- ------------------------------------------------------------
-- LOOT ESP
-- ------------------------------------------------------------

local function CreateLootESP(item)
    if LootESPObjects[item] then return end

    local S = Config.Settings

    -- Determine loot type and color
    local lootType = Utils.GetLootType(item.Name)
    local color = COLORS.Loot[lootType] or COLORS.Loot.Other

    -- Find the part to attach to
    local attachPart = item
    if item:IsA("Model") then
        attachPart = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
    end

    if not attachPart then return end

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Loot"
    billboard.Adornee = attachPart
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(150, 40)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
    billboard.MaxDistance = S.LootESP_MaxDistance
    billboard.Parent = attachPart

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 14)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.Name
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.Parent = billboard

    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 12)
    distLabel.Position = UDim2.new(0, 0, 0, 16)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 10
    distLabel.Parent = billboard

    -- Highlight for visibility
    local highlight = Instance.new("Highlight")
    highlight.Adornee = item
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = item

    LootESPObjects[item] = {
        item = item,
        lootType = lootType,
        color = color,
        billboard = billboard,
        nameLabel = nameLabel,
        distLabel = distLabel,
        highlight = highlight,
        attachPart = attachPart,
    }
end

local function UpdateLootESP()
    local S = Config.Settings

    -- Get current loot
    local lootItems = Utils.GetLootItems()

    -- Create ESP for new items
    for _, item in ipairs(lootItems) do
        if not LootESPObjects[item] then
            CreateLootESP(item)
        end
    end

    -- Update all loot ESP
    for item, data in pairs(LootESPObjects) do
        -- Check if item still exists
        if not item or not item.Parent then
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            LootESPObjects[item] = nil
            continue
        end

        -- Check if loot ESP enabled
        if not S.LootESP_Enabled then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            continue
        end

        -- Check if this loot type is enabled
        local typeEnabled = false
        if data.lootType == "Weapons" and S.LootESP_Weapons then typeEnabled = true
        elseif data.lootType == "Food" and S.LootESP_Food then typeEnabled = true
        elseif data.lootType == "Meds" and S.LootESP_Meds then typeEnabled = true
        elseif data.lootType == "Ammo" and S.LootESP_Ammo then typeEnabled = true
        elseif data.lootType == "Resources" and S.LootESP_Resources then typeEnabled = true
        elseif data.lootType == "Attachments" and S.LootESP_Attachments then typeEnabled = true
        elseif data.lootType == "Clothes" and S.LootESP_Clothes then typeEnabled = true
        elseif data.lootType == "Other" then typeEnabled = true -- Always show unknown items
        end

        if not typeEnabled then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            continue
        end

        -- Calculate distance
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = 0
        if localRoot and data.attachPart then
            local ok, pos = pcall(function() return data.attachPart.Position end)
            if ok and pos then
                distance = (pos - localRoot.Position).Magnitude
            end
        end

        -- Max distance
        if distance > S.LootESP_MaxDistance then
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
            continue
        end

        -- Enable ESP
        if data.billboard then
            data.billboard.Enabled = true

            -- Name
            if data.nameLabel then
                data.nameLabel.Visible = S.LootESP_ShowName
            end

            -- Distance
            if data.distLabel then
                data.distLabel.Visible = S.LootESP_ShowDistance
                data.distLabel.Text = string.format("%.0f studs", distance)
            end
        end

        -- Highlight
        if data.highlight then
            data.highlight.Enabled = true
        end
    end
end

-- ------------------------------------------------------------
-- Player management
-- ------------------------------------------------------------

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end

    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head", 5)
        character:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.3)

        CreatePlayerESP(player)
    end)

    if player.Character then
        task.spawn(function()
            player.Character:WaitForChild("Head", 5)
            task.wait(0.3)

            CreatePlayerESP(player)
        end)
    end

    player.CharacterRemoving:Connect(function(character)
        if PlayerESPObjects[player] then
            local data = PlayerESPObjects[player]
            if data.billboard then data.billboard:Destroy() end
            if data.highlight then data.highlight:Destroy() end
            if data.box then data.box:Destroy() end
            PlayerESPObjects[player] = nil
        end
    end)
end

-- Init
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        OnPlayerAdded(player)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    if PlayerESPObjects[player] then
        local data = PlayerESPObjects[player]
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.box then data.box:Destroy() end
        PlayerESPObjects[player] = nil
    end
end)

-- ------------------------------------------------------------
-- Main Update
-- ------------------------------------------------------------

function ESP.Update()
    UpdatePlayerESP()
    UpdateZombieESP()
    UpdateLootESP()
end

-- Update loop
RunService.RenderStepped:Connect(function()
    ESP.Update()
end)

-- ------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------

function ESP.Init(deps)
    Config = deps.Config
    Utils = deps.Utils
    GUI = deps.GUI

    print("[TWD] ESP module initialized.")
end

function ESP.Cleanup()
    for player, data in pairs(PlayerESPObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.box then data.box:Destroy() end
    end
    table.clear(PlayerESPObjects)

    for zombie, data in pairs(ZombieESPObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.box then data.box:Destroy() end
    end
    table.clear(ZombieESPObjects)

    for item, data in pairs(LootESPObjects) do
        if data.billboard then data.billboard:Destroy() end
        if data.highlight then data.highlight:Destroy() end
    end
    table.clear(LootESPObjects)
end

return ESP
