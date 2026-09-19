-- ============================================================
-- The Walking Dead Online -- Main
-- Entry point, module loader
-- ============================================================

local TWD = {}

-- Load modules
local Config = loadstring(readfile("TWDOnline/config.lua"))()
local Utils = loadstring(readfile("TWDOnline/utils.lua"))()
local GUI = loadstring(readfile("TWDOnline/gui.lua"))()
local ESP = loadstring(readfile("TWDOnline/esp.lua"))()
local Aimbot = loadstring(readfile("TWDOnline/aimbot.lua"))()
local Misc = loadstring(readfile("TWDOnline/misc.lua"))()

-- Dependencies
local deps = {
    Config = Config,
    Utils = Utils,
    GUI = GUI,
}

-- Initialize modules
GUI.Init(deps)
ESP.Init(deps)
Aimbot.Init(deps)
Misc.Init(deps)

-- Register ESP GUI
do
    local page = GUI.GetPage("ESP")
    if page then
        local C = GUI.Components
        local S = Config.Settings

        -- ========================================
        -- PLAYER ESP MASTER SECTION
        -- ========================================
        local playerSection, setPlayerOpen = C.MasterSection(page, "Player ESP", 1, S.PlayerESP_Enabled)

        C.Toggle(playerSection, "Enabled", S.PlayerESP_Enabled, function(v)
            Config.Set("PlayerESP_Enabled", v)
        end, 2)
        C.Toggle(playerSection, "Boxes", S.PlayerESP_Boxes, function(v)
            Config.Set("PlayerESP_Boxes", v)
        end, 3)
        C.Toggle(playerSection, "Names", S.PlayerESP_Names, function(v)
            Config.Set("PlayerESP_Names", v)
        end, 4)
        C.Toggle(playerSection, "Health", S.PlayerESP_Health, function(v)
            Config.Set("PlayerESP_Health", v)
        end, 5)
        C.Toggle(playerSection, "Distance", S.PlayerESP_Distance, function(v)
            Config.Set("PlayerESP_Distance", v)
        end, 6)
        C.Toggle(playerSection, "Weapon", S.PlayerESP_Weapon, function(v)
            Config.Set("PlayerESP_Weapon", v)
        end, 7)
        C.Toggle(playerSection, "Chams", S.PlayerESP_Chams, function(v)
            Config.Set("PlayerESP_Chams", v)
        end, 8)
        C.Toggle(playerSection, "Team Check", S.PlayerESP_TeamCheck, function(v)
            Config.Set("PlayerESP_TeamCheck", v)
        end, 9)
        C.Slider(playerSection, "Max Distance", 100, 2000, S.PlayerESP_MaxDistance, function(v)
            Config.Set("PlayerESP_MaxDistance", v)
        end, 10)

        setPlayerOpen(S.PlayerESP_Enabled)

        -- ========================================
        -- ZOMBIE ESP MASTER SECTION
        -- ========================================
        local zombieSection, setZombieOpen = C.MasterSection(page, "Zombie ESP", 20, S.ZombieESP_Enabled)

        C.Toggle(zombieSection, "Enabled", S.ZombieESP_Enabled, function(v)
            Config.Set("ZombieESP_Enabled", v)
        end, 21)
        C.Toggle(zombieSection, "Boxes", S.ZombieESP_Boxes, function(v)
            Config.Set("ZombieESP_Boxes", v)
        end, 22)
        C.Toggle(zombieSection, "Names", S.ZombieESP_Names, function(v)
            Config.Set("ZombieESP_Names", v)
        end, 23)
        C.Toggle(zombieSection, "Health", S.ZombieESP_Health, function(v)
            Config.Set("ZombieESP_Health", v)
        end, 24)
        C.Toggle(zombieSection, "Distance", S.ZombieESP_Distance, function(v)
            Config.Set("ZombieESP_Distance", v)
        end, 25)
        C.Toggle(zombieSection, "Chams", S.ZombieESP_Chams, function(v)
            Config.Set("ZombieESP_Chams", v)
        end, 26)
        C.Toggle(zombieSection, "Show Type", S.ZombieESP_ShowType, function(v)
            Config.Set("ZombieESP_ShowType", v)
        end, 27)
        C.Slider(zombieSection, "Max Distance", 50, 1000, S.ZombieESP_MaxDistance, function(v)
            Config.Set("ZombieESP_MaxDistance", v)
        end, 28)

        setZombieOpen(S.ZombieESP_Enabled)

        -- ========================================
        -- LOOT ESP MASTER SECTION
        -- ========================================
        local lootSection, setLootOpen = C.MasterSection(page, "Loot ESP", 40, S.LootESP_Enabled)

        C.Toggle(lootSection, "Enabled", S.LootESP_Enabled, function(v)
            Config.Set("LootESP_Enabled", v)
        end, 41)
        C.Toggle(lootSection, "Weapons", S.LootESP_Weapons, function(v)
            Config.Set("LootESP_Weapons", v)
        end, 42)
        C.Toggle(lootSection, "Food", S.LootESP_Food, function(v)
            Config.Set("LootESP_Food", v)
        end, 43)
        C.Toggle(lootSection, "Meds", S.LootESP_Meds, function(v)
            Config.Set("LootESP_Meds", v)
        end, 44)
        C.Toggle(lootSection, "Ammo", S.LootESP_Ammo, function(v)
            Config.Set("LootESP_Ammo", v)
        end, 45)
        C.Toggle(lootSection, "Resources", S.LootESP_Resources, function(v)
            Config.Set("LootESP_Resources", v)
        end, 46)
        C.Toggle(lootSection, "Attachments", S.LootESP_Attachments, function(v)
            Config.Set("LootESP_Attachments", v)
        end, 47)
        C.Toggle(lootSection, "Clothes", S.LootESP_Clothes, function(v)
            Config.Set("LootESP_Clothes", v)
        end, 48)
        C.Toggle(lootSection, "Show Name", S.LootESP_ShowName, function(v)
            Config.Set("LootESP_ShowName", v)
        end, 49)
        C.Toggle(lootSection, "Show Distance", S.LootESP_ShowDistance, function(v)
            Config.Set("LootESP_ShowDistance", v)
        end, 50)
        C.Slider(lootSection, "Max Distance", 50, 500, S.LootESP_MaxDistance, function(v)
            Config.Set("LootESP_MaxDistance", v)
        end, 51)

        setLootOpen(S.LootESP_Enabled)
    end
end

-- Register Aimbot GUI
do
    local page = GUI.GetPage("Aimbot")
    if page then
        local C = GUI.Components
        local S = Config.Settings

        -- ========================================
        -- AIMBOT MASTER SECTION
        -- ========================================
        local aimbotSection, setAimbotOpen = C.MasterSection(page, "Aimbot", 1, S.Aimbot_Enabled)

        C.Toggle(aimbotSection, "Enabled", S.Aimbot_Enabled, function(v)
            Config.Set("Aimbot_Enabled", v)
        end, 2)
        C.Toggle(aimbotSection, "Target Players", S.Aimbot_TargetPlayers, function(v)
            Config.Set("Aimbot_TargetPlayers", v)
        end, 3)
        C.Toggle(aimbotSection, "Target Zombies", S.Aimbot_TargetZombies, function(v)
            Config.Set("Aimbot_TargetZombies", v)
        end, 4)
        C.Toggle(aimbotSection, "Wall Check", S.Aimbot_WallCheck, function(v)
            Config.Set("Aimbot_WallCheck", v)
        end, 5)
        C.Toggle(aimbotSection, "Team Check", S.Aimbot_TeamCheck, function(v)
            Config.Set("Aimbot_TeamCheck", v)
        end, 6)
        C.Toggle(aimbotSection, "Smoothness", S.Aimbot_Smoothness, function(v)
            Config.Set("Aimbot_Smoothness", v)
        end, 7)
        C.Toggle(aimbotSection, "Prediction", S.Aimbot_Prediction, function(v)
            Config.Set("Aimbot_Prediction", v)
        end, 8)
        C.Toggle(aimbotSection, "Show FOV", S.Aimbot_ShowFOV, function(v)
            Config.Set("Aimbot_ShowFOV", v)
        end, 9)
        C.Dropdown(aimbotSection, "Aim Part", {"Head", "HumanoidRootPart", "Torso"}, S.Aimbot_AimPart, function(v)
            Config.Set("Aimbot_AimPart", v)
        end, 10)
        C.Dropdown(aimbotSection, "Priority", {"Crosshair", "Distance", "Health"}, S.Aimbot_Priority, function(v)
            Config.Set("Aimbot_Priority", v)
        end, 11)
        C.Slider(aimbotSection, "FOV Size", 50, 1000, S.Aimbot_FOVSize, function(v)
            Config.Set("Aimbot_FOVSize", v)
        end, 12)
        C.Slider(aimbotSection, "Smooth Value", 0, 20, S.Aimbot_SmoothValue, function(v)
            Config.Set("Aimbot_SmoothValue", v)
        end, 13)
        C.Slider(aimbotSection, "Prediction Strength", 1, 20, S.Aimbot_PredStrength, function(v)
            Config.Set("Aimbot_PredStrength", v)
        end, 14)

        setAimbotOpen(S.Aimbot_Enabled)
    end
end

-- Register Misc GUI
do
    local page = GUI.GetPage("Misc")
    if page then
        local C = GUI.Components
        local S = Config.Settings

        -- ========================================
        -- VISUALS MASTER SECTION
        -- ========================================
        local visualSection, setVisualOpen = C.MasterSection(page, "Visuals", 1, false)

        C.Toggle(visualSection, "No Grass", S.NoGrass_Enabled, function(v)
            Config.Set("NoGrass_Enabled", v)
        end, 2)
        C.Toggle(visualSection, "Fullbright", S.Fullbright_Enabled, function(v)
            Config.Set("Fullbright_Enabled", v)
        end, 3)

        setVisualOpen(false)
    end
end

print("================================")
print("[TWD] SCRIPT LOADED")
print("================================")

return TWD
