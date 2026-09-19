-- ============================================================
-- TWD Online -- Simple Aimbot
-- ============================================================

local Aimbot = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = {
    Enabled = false,
    ShowNPCs = false,
    FOVSize = 250,
    Smoothness = 5,
    AimPart = "Head",
}

local aimbotKeybind = nil
local currentTarget = nil

local function isKeybindPressed()
    if not aimbotKeybind then return false end
    if typeof(aimbotKeybind) == "EnumItem" then
        if aimbotKeybind.EnumType == Enum.UserInputType then
            return UserInputService:IsMouseButtonPressed(aimbotKeybind)
        elseif aimbotKeybind.EnumType == Enum.KeyCode then
            return UserInputService:IsKeyDown(aimbotKeybind)
        end
    end
    return false
end

local function formatKeybind(kb)
    if not kb then return "None" end
    if typeof(kb) == "EnumItem" then
        local str = tostring(kb)
        return str:match("%.(%w+)$") or str
    end
    return tostring(kb)
end

local function W2S(position)
    local ok, result = pcall(function()
        return Camera:WorldToViewportPoint(position)
    end)
    if ok and result.Z > 0 then
        return Vector2.new(result.X, result.Y), true
    end
    return nil, false
end

local function IsNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local name = model.Name:lower()
    if name:find("zombie") or name:find("walker") or name:find("infected")
        or name:find("crawler") or name:find("runner") or name:find("npc") then
        return true
    end
    return false
end

local function GetValidTargets()
    local targets = {}

    -- Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local aimPart = player.Character:FindFirstChild(Config.AimPart)
            if humanoid and humanoid.Health > 0 and aimPart then
                table.insert(targets, {
                    character = player.Character,
                    part = aimPart,
                    isNPC = false,
                })
            end
        end
    end

    -- NPCs
    if Config.ShowNPCs then
        for _, child in ipairs(Workspace:GetDescendants()) do
            if child:IsA("Model") and IsNPC(child) then
                local humanoid = child:FindFirstChildOfClass("Humanoid")
                local aimPart = child:FindFirstChild(Config.AimPart)
                if humanoid and humanoid.Health > 0 and aimPart then
                    table.insert(targets, {
                        character = child,
                        part = aimPart,
                        isNPC = true,
                    })
                end
            end
        end
    end

    return targets
end

local function GetClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local closestDist = Config.FOVSize

    for _, target in ipairs(GetValidTargets()) do
        local screenPos, visible = W2S(target.part.Position)
        if screenPos and visible then
            local dist = (screenPos - mousePos).Magnitude
            if dist < closestDist then
                closest = target
                closestDist = dist
            end
        end
    end

    return closest
end

local function ApplyAim(target)
    if not target or not target.part then return end

    local screenPos, visible = W2S(target.part.Position)
    if not screenPos or not visible then return end

    local mousePos = UserInputService:GetMouseLocation()
    local delta = screenPos - mousePos

    -- Apply smoothness
    if Config.Smoothness > 0 then
        delta = delta / (Config.Smoothness + 1)
    end

    pcall(function()
        mousemoverel(delta.X, delta.Y)
    end)
end

function Aimbot.Update()
    if not Config.Enabled then
        currentTarget = nil
        return
    end

    if not isKeybindPressed() then
        currentTarget = nil
        return
    end

    local target = GetClosestTarget()
    if target then
        currentTarget = target
        ApplyAim(target)
    else
        currentTarget = nil
    end
end

RunService.RenderStepped:Connect(function()
    local ok, err = pcall(Aimbot.Update)
    if not ok then warn("[TWD] Aimbot error: " .. tostring(err)) end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if aimbotKeybind then
        if typeof(aimbotKeybind) == "EnumItem" then
            if aimbotKeybind.EnumType == Enum.UserInputType and input.UserInputType == aimbotKeybind then
                -- Key pressed
            elseif aimbotKeybind.EnumType == Enum.KeyCode and input.KeyCode == aimbotKeybind then
                -- Key pressed
            end
        end
    end
end)

function Aimbot.SetKeybind(key)
    aimbotKeybind = key
end

function Aimbot.GetKeybind()
    return aimbotKeybind
end

function Aimbot.FormatKeybind(kb)
    return formatKeybind(kb)
end

function Aimbot.SetConfig(key, value)
    Config[key] = value
end

function Aimbot.GetConfig(key)
    return Config[key]
end

function Aimbot.Init()
    print("[TWD] Aimbot initialized")
end

function Aimbot.Cleanup()
    Config.Enabled = false
    currentTarget = nil
end

return Aimbot
