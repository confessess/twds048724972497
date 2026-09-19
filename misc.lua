-- ============================================================
-- The Walking Dead Online -- Misc
-- NoGrass, Fullbright, other visual tweaks
-- ============================================================

local Misc = {}

local Config = nil
local Utils = nil
local GUI = nil
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local noGrassEnabled = false
local fullbrightEnabled = false
local originalLighting = {}

local function setNoGrass(enabled)
    noGrassEnabled = enabled

    -- TWD Online has grass decorations we can hide
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        -- Can't fully disable terrain grass, but we can reduce decoration
        pcall(function()
            if enabled then
                -- Store original
                originalLighting.GrassDecoration = terrain.Decoration
                terrain.Decoration = false
            else
                terrain.Decoration = originalLighting.GrassDecoration or true
            end
        end)
    end

    -- Look for grass models/parts
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("grass") or name:find("bush") or name:find("shrub") or name:find("plant") or name:find("fern") then
                if obj:IsA("BasePart") then
                    if enabled then
                        obj.LocalTransparencyModifier = 1
                    else
                        obj.LocalTransparencyModifier = 0
                    end
                elseif obj:IsA("Model") then
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if enabled then
                                part.LocalTransparencyModifier = 1
                            else
                                part.LocalTransparencyModifier = 0
                            end
                        end
                    end
                end
            end
        end
    end
end

local function setFullbright(enabled)
    fullbrightEnabled = enabled

    if enabled then
        -- Store original values
        originalLighting.Ambient = Lighting.Ambient
        originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        originalLighting.Brightness = Lighting.Brightness
        originalLighting.GlobalShadows = Lighting.GlobalShadows

        -- Apply fullbright
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        -- Restore original
        Lighting.Ambient = originalLighting.Ambient or Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.new(0, 0, 0)
        Lighting.Brightness = originalLighting.Brightness or 1
        Lighting.GlobalShadows = originalLighting.GlobalShadows ~= false
    end
end

function Misc.Update()
    if not Config or not Config.Settings then return end
    -- Check for config changes
    local S = Config.Settings

    if S.NoGrass_Enabled ~= noGrassEnabled then
        setNoGrass(S.NoGrass_Enabled)
    end

    if S.Fullbright_Enabled ~= fullbrightEnabled then
        setFullbright(S.Fullbright_Enabled)
    end
end

RunService.RenderStepped:Connect(function()
    Misc.Update()
end)

function Misc.Init(deps)
    Config = deps.Config
    Utils = deps.Utils
    GUI = deps.GUI

    print("[TWD] Misc module initialized.")
end

function Misc.Cleanup()
    setNoGrass(false)
    setFullbright(false)
end

return Misc