-- ============================================================
-- TWD Online -- Main
-- ESP + Fullbright + Aimbot
-- ============================================================

local baseUrl = "https://raw.githubusercontent.com/confessess/twds048724972497/main/"

print("[TWD] Loading modules...")
local GUI = loadstring(game:HttpGet(baseUrl .. "gui.lua"))()
local ESP = loadstring(game:HttpGet(baseUrl .. "esp.lua"))()
local Misc = loadstring(game:HttpGet(baseUrl .. "misc.lua"))()
local Aimbot = loadstring(game:HttpGet(baseUrl .. "aimbot.lua"))()

print("[TWD] Initializing...")
GUI.Init()
ESP.Init()
Misc.Init()
Aimbot.Init()

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

        C.Toggle(espSection, "Show NPCs / Zombies", true, function(v)
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

        C.Toggle(visualSection, "Boxes", true, function(v)
            ESP.SetConfig("Boxes", v)
        end, 11)

        C.Toggle(visualSection, "Skeletons", false, function(v)
            ESP.SetConfig("Skeleton", v)
        end, 12)

        C.Toggle(visualSection, "Chams", false, function(v)
            ESP.SetConfig("Chams", v)
        end, 13)

        C.Toggle(visualSection, "Names", true, function(v)
            ESP.SetConfig("Names", v)
        end, 14)

        C.Toggle(visualSection, "Health Bars", true, function(v)
            ESP.SetConfig("Health", v)
        end, 15)

        C.Toggle(visualSection, "Held Item", true, function(v)
            ESP.SetConfig("HeldItem", v)
        end, 16)

        C.Toggle(visualSection, "Distance", true, function(v)
            ESP.SetConfig("Distance", v)
        end, 17)

        C.Toggle(visualSection, "Fullbright", false, function(v)
            Misc.SetConfig("Fullbright", v)
        end, 18)

        setVisualOpen(true)

        -- ========================================
        -- AIMBOT MASTER SECTION
        -- ========================================
        local aimbotSection, setAimbotOpen = C.MasterSection(content, "Aimbot", 30, false)

        C.Toggle(aimbotSection, "Enabled", false, function(v)
            Aimbot.SetConfig("Enabled", v)
        end, 31)

        C.Toggle(aimbotSection, "Target NPCs", false, function(v)
            Aimbot.SetConfig("ShowNPCs", v)
        end, 32)

        C.Slider(aimbotSection, "FOV Size", 50, 1000, 250, function(v)
            Aimbot.SetConfig("FOVSize", v)
        end, 33)

        C.Slider(aimbotSection, "Smoothness", 0, 20, 5, function(v)
            Aimbot.SetConfig("Smoothness", v)
        end, 34)

        -- Aimbot keybind
        local keybindFrame = Instance.new("Frame")
        keybindFrame.Size = UDim2.new(1, 0, 0, 32)
        keybindFrame.BackgroundTransparency = 1
        keybindFrame.LayoutOrder = 35
        keybindFrame.Parent = aimbotSection

        local keybindLbl = Instance.new("TextLabel")
        keybindLbl.Size = UDim2.new(0.4, 0, 1, 0)
        keybindLbl.BackgroundTransparency = 1
        keybindLbl.Text = "Aim Key"
        keybindLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
        keybindLbl.Font = Enum.Font.GothamMedium
        keybindLbl.TextSize = 13
        keybindLbl.TextXAlignment = Enum.TextXAlignment.Left
        keybindLbl.Parent = keybindFrame

        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(0.35, -30, 0, 26)
        keybindBtn.Position = UDim2.new(0.45, 0, 0.5, -13)
        keybindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        keybindBtn.BorderSizePixel = 0
        keybindBtn.Text = "None"
        keybindBtn.TextColor3 = Color3.fromRGB(80, 140, 255)
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.TextSize = 12
        keybindBtn.AutoButtonColor = false
        keybindBtn.Parent = keybindFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = keybindBtn

        local clearBtn = Instance.new("TextButton")
        clearBtn.Size = UDim2.fromOffset(24, 24)
        clearBtn.Position = UDim2.new(1, -24, 0.5, -12)
        clearBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        clearBtn.BorderSizePixel = 0
        clearBtn.Text = "×"
        clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        clearBtn.Font = Enum.Font.GothamBold
        clearBtn.TextSize = 14
        clearBtn.AutoButtonColor = false
        clearBtn.Parent = keybindFrame

        local clearCorner = Instance.new("UICorner")
        clearCorner.CornerRadius = UDim.new(0, 4)
        clearCorner.Parent = clearBtn

        local listening = false
        keybindBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keybindBtn.Text = "..."

            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Aimbot.SetKeybind(input.KeyCode)
                    keybindBtn.Text = Aimbot.FormatKeybind(input.KeyCode)
                    listening = false
                    conn:Disconnect()
                elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    Aimbot.SetKeybind(input.UserInputType)
                    keybindBtn.Text = Aimbot.FormatKeybind(input.UserInputType)
                    listening = false
                    conn:Disconnect()
                end
            end)
        end)

        clearBtn.MouseButton1Click:Connect(function()
            Aimbot.SetKeybind(nil)
            keybindBtn.Text = "None"
        end)

        setAimbotOpen(false)

        -- ========================================
        -- SETTINGS MASTER SECTION
        -- ========================================
        local settingsSection, setSettingsOpen = C.MasterSection(content, "Settings", 40, false)

        C.Keybind(settingsSection, "Menu Keybind", Enum.KeyCode.RightControl, function(k)
            print("[TWD] Menu keybind changed")
        end, 41)

        setSettingsOpen(false)
    end
end

print("================================")
print("[TWD] SCRIPT LOADED")
print("Press RightControl to toggle menu")
print("================================")

return { ESP = ESP, Misc = Misc, Aimbot = Aimbot }