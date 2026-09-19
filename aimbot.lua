-- ============================================================
-- The Walking Dead Online -- Aimbot
-- Dynamic prediction based on target distance
-- ============================================================

local Aimbot = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Config = nil
local Utils = nil
local GUI = nil

-- State
local currentTarget = nil
local aimbotKeybind = nil
local aimbotKeyDown = false
local fovCircle = nil

-- Prediction tuning
local PREDICTION_BASE = 0.1  -- Base prediction strength
local PREDICTION_SCALE = 0.01  -- Scales with distance

-- Helper to check if keybind is pressed
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

-- Helper to format keybind for display
local function formatKeybind(kb)
    if not kb then return "None" end
    if typeof(kb) == "EnumItem" then
        local str = tostring(kb)
        local name = str:match("%.(%w+)$") or str
        return name
    end
    return tostring(kb)
end

-- ------------------------------------------------------------
-- Target validation
-- ------------------------------------------------------------

local function isValidTarget(entity, isZombie)
    if not entity then return false end

    if isZombie then
        -- Zombie validation
        local humanoid = entity:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        return true
    else
        -- Player validation
        if not entity.Character then return false end
        local humanoid = entity.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        return true
    end
end

-- ------------------------------------------------------------
-- Get target position with prediction
-- ------------------------------------------------------------

local function getTargetPosition(target, isZombie, distance)
    local S = Config.Settings

    local root = nil
    local aimPart = nil

    if isZombie then
        root = target:FindFirstChild("HumanoidRootPart")
        aimPart = target:FindFirstChild(S.Aimbot_AimPart) or target:FindFirstChild("Head") or root
    else
        root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        aimPart = target.Character and target.Character:FindFirstChild(S.Aimbot_AimPart) or root
    end

    if not aimPart then return nil end

    local targetPos = aimPart.Position

    -- Dynamic prediction based on distance
    if S.Aimbot_Prediction and root then
        local velocity = root.Velocity

        -- Scale prediction with distance
        -- Closer targets need less prediction, farther need more
        local predStrength = (S.Aimbot_PredStrength or 5) * 0.01
        local distanceFactor = math.clamp(distance / 100, 0.5, 3)  -- Scales from 0.5x to 3x

        local predX = velocity.X * predStrength * distanceFactor
        local predY = velocity.Y * predStrength * distanceFactor * 0.5  -- Less vertical prediction
        local predZ = velocity.Z * predStrength * distanceFactor

        targetPos = targetPos + Vector3.new(predX, predY, predZ)
    end

    return targetPos
end

-- ------------------------------------------------------------
-- Target selection
-- ------------------------------------------------------------

local function getBestTarget()
    local S = Config.Settings

    local crosshair = Utils.GetCrosshairPosition()
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil, false end

    local fovSize = S.Aimbot_FOVSize or 250
    local wallCheck = S.Aimbot_WallCheck == true
    local teamCheck = S.Aimbot_TeamCheck ~= false
    local priority = S.Aimbot_Priority or "Crosshair"

    local bestTarget = nil
    local bestIsZombie = false
    local bestScore = math.huge

    -- Check players
    if S.Aimbot_TargetPlayers then
        for _, player in ipairs(Utils.GetPlayers()) do
            if teamCheck and Utils.IsTeammate(player) then continue end
            if not isValidTarget(player, false) then continue end

            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local aimPart = player.Character:FindFirstChild(S.Aimbot_AimPart) or root
            if not aimPart then continue end

            if wallCheck and not Utils.HasLineOfSight(aimPart) then continue end

            local screenPos, onScreen = Utils.WorldToScreen(aimPart.Position)
            if not screenPos or not onScreen then continue end

            local dist2d = (screenPos - crosshair).Magnitude
            if dist2d > fovSize then continue end

            local dist3d = (root.Position - localRoot.Position).Magnitude

            -- Calculate score based on priority
            local score = 0
            if priority == "Crosshair" then
                score = dist2d
            elseif priority == "Distance" then
                score = dist3d
            elseif priority == "Health" then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                score = humanoid and humanoid.Health or 100
            end

            if score < bestScore then
                bestScore = score
                bestTarget = player
                bestIsZombie = false
            end
        end
    end

    -- Check zombies
    if S.Aimbot_TargetZombies then
        for _, zombie in ipairs(Utils.GetZombies()) do
            if not isValidTarget(zombie, true) then continue end

            local root = zombie:FindFirstChild("HumanoidRootPart")
            local aimPart = zombie:FindFirstChild(S.Aimbot_AimPart) or zombie:FindFirstChild("Head") or root
            if not aimPart then continue end

            if wallCheck and not Utils.HasLineOfSight(aimPart) then continue end

            local screenPos, onScreen = Utils.WorldToScreen(aimPart.Position)
            if not screenPos or not onScreen then continue end

            local dist2d = (screenPos - crosshair).Magnitude
            if dist2d > fovSize then continue end

            local dist3d = (root.Position - localRoot.Position).Magnitude

            -- Calculate score based on priority
            local score = 0
            if priority == "Crosshair" then
                score = dist2d
            elseif priority == "Distance" then
                score = dist3d
            elseif priority == "Health" then
                local humanoid = zombie:FindFirstChildOfClass("Humanoid")
                score = humanoid and humanoid.Health or 100
            end

            if score < bestScore then
                bestScore = score
                bestTarget = zombie
                bestIsZombie = true
            end
        end
    end

    return bestTarget, bestIsZombie
end

-- ------------------------------------------------------------
-- Apply aim with dynamic smoothing
-- ------------------------------------------------------------

local function applyAim(target, isZombie)
    if not target then return end

    local S = Config.Settings
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    -- Get root for distance calculation
    local root = nil
    if isZombie then
        root = target:FindFirstChild("HumanoidRootPart")
    else
        root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    end

    if not root then return end

    local distance = (root.Position - localRoot.Position).Magnitude

    -- Get predicted position
    local targetPos = getTargetPosition(target, isZombie, distance)
    if not targetPos then return end

    -- Convert to screen
    local screenPos, onScreen = Utils.WorldToScreen(targetPos)
    if not screenPos or not onScreen then return end

    -- Calculate delta from crosshair
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local delta = screenPos - center

    -- Dynamic smoothing based on distance
    -- Closer targets = smoother (harder to track)
    -- Farther targets = snappier (easier to track)
    local useSmooth = S.Aimbot_Smoothness == true
    local smoothValue = S.Aimbot_SmoothValue or 5

    if useSmooth and smoothValue > 0 then
        -- Reduce smoothing for far targets
        local distanceFactor = math.clamp(1 - (distance / 500), 0.3, 1)
        local adjustedSmooth = smoothValue * distanceFactor
        delta = delta / (adjustedSmooth + 1)
    end

    -- Apply mouse movement
    pcall(function()
        mousemoverel(delta.X, delta.Y)
    end)
end

-- ------------------------------------------------------------
-- Update loop
-- ------------------------------------------------------------

local function updateAimbot()
    local S = Config.Settings

    if not S.Aimbot_Enabled then
        if fovCircle then fovCircle.Visible = false end
        currentTarget = nil
        return
    end

    -- Show FOV circle
    if S.Aimbot_ShowFOV then
        if not fovCircle then
            fovCircle = Utils.NewCircle(
                S.Aimbot_FOVSize or 250,
                Utils.HexToColor("#64b4ff"),
                2
            )
        end
        if fovCircle then
            fovCircle.Position = Utils.GetCrosshairPosition()
            fovCircle.Radius = S.Aimbot_FOVSize or 250
            fovCircle.Visible = true
        end
    elseif fovCircle then
        fovCircle.Visible = false
    end

    -- Check keybind
    if not isKeybindPressed() then
        currentTarget = nil
        return
    end

    -- Get target
    local target, isZombie = getBestTarget()
    if target then
        currentTarget = target
        applyAim(target, isZombie)
    else
        currentTarget = nil
    end
end

-- ------------------------------------------------------------
-- Main Update
-- ------------------------------------------------------------

function Aimbot.Update()
    if not Config or not Config.Settings then return end
    updateAimbot()
end

-- Update loop
RunService.RenderStepped:Connect(function()
    Aimbot.Update()
end)

-- ------------------------------------------------------------
-- Input handling
-- ------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if aimbotKeybind then
        if typeof(aimbotKeybind) == "EnumItem" then
            if aimbotKeybind.EnumType == Enum.UserInputType and input.UserInputType == aimbotKeybind then
                aimbotKeyDown = true
            elseif aimbotKeybind.EnumType == Enum.KeyCode and input.KeyCode == aimbotKeybind then
                aimbotKeyDown = true
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if aimbotKeybind then
        if typeof(aimbotKeybind) == "EnumItem" then
            if aimbotKeybind.EnumType == Enum.UserInputType and input.UserInputType == aimbotKeybind then
                aimbotKeyDown = false
            elseif aimbotKeybind.EnumType == Enum.KeyCode and input.KeyCode == aimbotKeybind then
                aimbotKeyDown = false
            end
        end
    end
end)

-- ------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------

function Aimbot.Init(deps)
    Config = deps.Config
    Utils = deps.Utils
    GUI = deps.GUI

    -- Verify Config loaded
    if not Config then
        warn("[TWD] Aimbot: Config not loaded!")
        return
    end
    if not Config.Settings then
        warn("[TWD] Aimbot: Config.Settings not loaded!")
        return
    end

    print("[TWD] Aimbot module initialized.")
end

function Aimbot.Cleanup()
    if fovCircle then
        Utils.DestroyDrawing(fovCircle)
        fovCircle = nil
    end
    currentTarget = nil
end

return Aimbot