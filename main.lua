-- ============================================================
-- TWD Online -- Main (Fixed)
-- ESP Only - Loads from GitHub
-- ============================================================

local baseUrl = "https://raw.githubusercontent.com/confessess/twds048724972497/main/"

print("[TWD] Loading GUI...")
local GUI = loadstring(game:HttpGet(baseUrl .. "gui.lua"))()

print("[TWD] Loading ESP...")
local ESP = loadstring(game:HttpGet(baseUrl .. "esp.lua"))()

print("[TWD] Initializing...")
GUI.Init()
ESP.Init()

-- Build GUI
do
    local content = GUI.GetContent()
    if content then
        local C = GUI.Components

        -- ========================================
        -- ESP MASTER SECTION
        -- ========================================
        local espSection, setEspOpen = C.MasterSection(content, "ESP", 1, true)

        C.Toggle(espSection, "Enabled", false, function(v)
            ESP.SetConfig("Enabled", v)
        end, 2)

        C.Toggle(espSection, "Show NPCs / Zombies", false, function(v)
            ESP.SetConfig("ShowNPCs", v)
        end, 3)

        C.Toggle(espSection, "Infinite Distance", false, function(v)
            ESP.SetConfig("InfiniteDistance", v)
        end, 4)

        C.Slider(espSection, "Max Distance", 50, 5000, 500, function(v)
            ESP.SetConfig("MaxDistance", v)
        end, 5)

        setEspOpen(true)

        -- ========================================
        -- VISUALS MASTER SECTION
        -- ========================================
        local visualSection, setVisualOpen = C.MasterSection(content, "Visuals", 10, true)

        C.Toggle(visualSection, "Skeletons", false, function(v)
            ESP.SetConfig("Skeletons", v)
        end, 11)

        C.Toggle(visualSection, "Chams", false, function(v)
            ESP.SetConfig("Chams", v)
        end, 12)

        C.Toggle(visualSection, "Names", true, function(v)
            ESP.SetConfig("Names", v)
        end, 13)

        C.Toggle(visualSection, "Health Bars", true, function(v)
            ESP.SetConfig("Health", v)
        end, 14)

        C.Toggle(visualSection, "Held Item", true, function(v)
            ESP.SetConfig("HeldItem", v)
        end, 15)

        C.Toggle(visualSection, "Distance", true, function(v)
            ESP.SetConfig("Distance", v)
        end, 16)

        setVisualOpen(true)

        -- ========================================
        -- SETTINGS MASTER SECTION
        -- ========================================
        local settingsSection, setSettingsOpen = C.MasterSection(content, "Settings", 20, false)

        C.Keybind(settingsSection, "Menu Keybind", Enum.KeyCode.RightControl, function(k)
            print("[TWD] Menu keybind changed")
        end, 21)

        setSettingsOpen(false)
    else
        warn("[TWD] Failed to get content host!")
    end
end

print("================================")
print("[TWD] ESP SCRIPT LOADED")
print("Press RightControl to toggle menu")
print("================================")

return ESP