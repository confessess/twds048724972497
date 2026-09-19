-- ============================================================
-- TWD Online -- Misc (Fullbright)
-- ============================================================

local Misc = {}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Config = {
    Fullbright = false,
}

local originalLighting = {}
local fullbrightActive = false

local function ApplyFullbright()
    if Config.Fullbright and not fullbrightActive then
        -- Store original
        originalLighting.Ambient = Lighting.Ambient
        originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        originalLighting.Brightness = Lighting.Brightness
        originalLighting.GlobalShadows = Lighting.GlobalShadows

        -- Apply fullbright
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false

        fullbrightActive = true
    elseif not Config.Fullbright and fullbrightActive then
        -- Restore
        Lighting.Ambient = originalLighting.Ambient or Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.new(0, 0, 0)
        Lighting.Brightness = originalLighting.Brightness or 1
        Lighting.GlobalShadows = originalLighting.GlobalShadows ~= false

        fullbrightActive = false
    end
end

function Misc.Update()
    ApplyFullbright()
end

RunService.RenderStepped:Connect(function()
    Misc.Update()
end)

function Misc.SetConfig(key, value)
    Config[key] = value
end

function Misc.GetConfig(key)
    return Config[key]
end

function Misc.Init()
    print("[TWD] Misc initialized")
end

function Misc.Cleanup()
    Config.Fullbright = false
    ApplyFullbright()
end

return Misc
