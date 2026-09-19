-- ============================================================
-- The Walking Dead Online -- Config
-- Defaults, JSON persistence
-- ============================================================

local HttpService = game:GetService("HttpService")

local CACHE_FOLDER  = "TWDOnline"
local SETTINGS_FILE = CACHE_FOLDER .. "/settings.json"

local Defaults = {
    -- Menu
    MenuKeybind      = "RightControl",
    MenuAccent       = "#64b4ff",

    -- Player ESP
    PlayerESP_Enabled      = false,
    PlayerESP_Boxes        = false,
    PlayerESP_Names        = false,
    PlayerESP_Health       = false,
    PlayerESP_Distance     = false,
    PlayerESP_Weapon       = false,
    PlayerESP_Tracers      = false,
    PlayerESP_Chams        = false,
    PlayerESP_MaxDistance  = 500,
    PlayerESP_TeamCheck    = false,

    -- Zombie/NPC ESP
    ZombieESP_Enabled      = false,
    ZombieESP_Boxes        = false,
    ZombieESP_Names        = false,
    ZombieESP_Health       = false,
    ZombieESP_Distance     = false,
    ZombieESP_Tracers      = false,
    ZombieESP_Chams        = false,
    ZombieESP_MaxDistance  = 300,
    ZombieESP_ShowType     = false,

    -- Loot ESP
    LootESP_Enabled        = false,
    LootESP_Weapons        = false,
    LootESP_Food           = false,
    LootESP_Meds           = false,
    LootESP_Resources      = false,
    LootESP_Ammo           = false,
    LootESP_Attachments    = false,
    LootESP_Clothes        = false,
    LootESP_MaxDistance    = 200,
    LootESP_ShowName       = false,
    LootESP_ShowDistance   = false,

    -- Aimbot
    Aimbot_Enabled         = false,
    Aimbot_WallCheck       = false,
    Aimbot_TeamCheck       = false,
    Aimbot_Smoothness      = false,
    Aimbot_SmoothValue     = 5,
    Aimbot_Prediction      = false,
    Aimbot_PredStrength    = 5,
    Aimbot_AimPart         = "Head",
    Aimbot_ShowFOV         = false,
    Aimbot_FOVSize         = 250,
    Aimbot_TargetZombies   = false,
    Aimbot_TargetPlayers   = false,
    Aimbot_Priority        = "Crosshair", -- Crosshair, Distance, Health

    -- Misc
    NoGrass_Enabled        = false,
    Fullbright_Enabled     = false,
}

local Config = {}
Config._folder = CACHE_FOLDER
Config._file   = SETTINGS_FILE

local SERIALIZABLE = { boolean = true, number = true, string = true }

local function deepCopy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

local function ensureFolder()
    pcall(function()
        if makefolder and not (isfolder and isfolder(CACHE_FOLDER)) then
            makefolder(CACHE_FOLDER)
        end
    end)
end

function Config.Load()
    ensureFolder()
    local settings = deepCopy(Defaults)

    pcall(function()
        if isfile and isfile(SETTINGS_FILE) then
            local raw = readfile(SETTINGS_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if typeof(decoded) == "table" then
                for k, v in pairs(decoded) do
                    if Defaults[k] ~= nil and SERIALIZABLE[typeof(v)] then
                        settings[k] = v
                    end
                end
            end
        end
    end)

    Config.Settings = settings
    return settings
end

function Config.Save()
    ensureFolder()
    pcall(function()
        if writefile and Config.Settings then
            local clean = {}
            for k, v in pairs(Config.Settings) do
                if SERIALIZABLE[typeof(v)] then
                    clean[k] = v
                end
            end
            writefile(SETTINGS_FILE, HttpService:JSONEncode(clean))
        end
    end)
end

function Config.Reset()
    Config.Settings = deepCopy(Defaults)
    pcall(function()
        if writefile then
            writefile(SETTINGS_FILE, "{}")
        end
    end)
end

function Config.Get(key)
    return Config.Settings and Config.Settings[key]
end

function Config.Set(key, value)
    if Config.Settings then
        Config.Settings[key] = value
        Config.Save()
    end
end

Config.Load()
return Config
