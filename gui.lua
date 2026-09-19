-- ============================================================
-- The Walking Dead Online -- GUI
-- Lightweight GUI with Master Sections
-- ============================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GUI = {}

local Theme = {
    Background = Color3.fromRGB(20, 20, 28),
    Darker = Color3.fromRGB(15, 15, 22),
    Element = Color3.fromRGB(35, 35, 48),
    ElementHover = Color3.fromRGB(42, 42, 58),
    Stroke = Color3.fromRGB(50, 50, 68),
    Text = Color3.fromRGB(220, 220, 235),
    TextDim = Color3.fromRGB(100, 100, 120),
    Accent = Color3.fromRGB(100, 180, 255),
    Blue = Color3.fromRGB(80, 140, 255),
    Green = Color3.fromRGB(60, 255, 60),
    Red = Color3.fromRGB(255, 60, 60),
}

local ScreenGui, MainFrame, TabBar, ContentHost
local Pages = {}
local ActiveTab = nil
local IsOpen = false
local IsLoading = true
local MenuKeybind = Enum.KeyCode.RightControl

local function tween(obj, props)
    TweenService:Create(obj, TweenInfo.new(0.15), props):Play()
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = parent
end

local function stroke(parent, color, t)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = t or 1
    s.Parent = parent
end

-- Components
local Components = {}

function Components.Section(page, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text)
    lbl.TextColor3 = Theme.Accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    lbl.Parent = page
end

function Components.MasterSection(page, text, order, defaultOpen)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(1, 0, 0, 28)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.LayoutOrder = order or 0
    sectionFrame.ClipsDescendants = false
    sectionFrame.Parent = page

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Theme.Element
    header.BorderSizePixel = 0
    header.Text = ""
    header.AutoButtonColor = false
    header.Parent = sectionFrame
    corner(header, 4)

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, -40, 1, 0)
    headerLbl.Position = UDim2.new(0, 12, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Text = string.upper(text)
    headerLbl.TextColor3 = Theme.Accent
    headerLbl.Font = Enum.Font.GothamBold
    headerLbl.TextSize = 12
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Parent = header

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(20, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = defaultOpen and "▼" or "▶"
    arrow.TextColor3 = Theme.Accent
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 10
    arrow.Parent = header

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Visible = defaultOpen or false
    content.Parent = sectionFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    local isOpen = defaultOpen or false
    local contentHeight = 0

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentHeight = contentLayout.AbsoluteContentSize.Y
        if isOpen then
            content.Size = UDim2.new(1, 0, 0, contentHeight)
            sectionFrame.Size = UDim2.new(1, 0, 0, 28 + contentHeight + 4)
        end
    end)

    local function setOpen(open)
        isOpen = open
        if isOpen then
            arrow.Text = "▼"
            content.Visible = true
            content.Size = UDim2.new(1, 0, 0, contentHeight)
            sectionFrame.Size = UDim2.new(1, 0, 0, 28 + contentHeight + 4)
        else
            arrow.Text = "▶"
            content.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.Size = UDim2.new(1, 0, 0, 28)
            task.delay(0.15, function()
                if not isOpen then
                    content.Visible = false
                end
            end)
        end
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not isOpen)
    end)

    return content, setOpen
end

function Components.Toggle(page, label, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromOffset(36, 20)
    bg.Position = UDim2.new(1, -36, 0.5, -10)
    bg.BackgroundColor3 = default and Theme.Blue or Theme.Element
    bg.BorderSizePixel = 0
    bg.Parent = frame
    corner(bg, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    corner(knob, 7)

    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function()
            state = not state
            if state then
                tween(bg, {BackgroundColor3 = Theme.Blue})
                tween(knob, {Position = UDim2.new(1, -17, 0.5, -7)})
            else
                tween(bg, {BackgroundColor3 = Theme.Element})
                tween(knob, {Position = UDim2.new(0, 3, 0.5, -7)})
            end
            if callback then callback(state) end
        end)
        if not ok then warn("[GUI] Toggle error: " .. tostring(err)) end
    end)

    return {Set = function(v) state = v end, Get = function() return state end}
end

function Components.Dropdown(page, label, options, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.ClipsDescendants = false
    frame.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 0, 32)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0.55, 0, 0, 28)
    box.Position = UDim2.new(0.45, 0, 0, 2)
    box.BackgroundColor3 = Theme.Element
    box.BorderSizePixel = 0
    box.Text = ""
    box.AutoButtonColor = false
    box.Parent = frame
    corner(box, 4)
    stroke(box)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(1, -30, 1, 0)
    valueLbl.Position = UDim2.new(0, 10, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(default or "Select...")
    valueLbl.TextColor3 = Theme.TextDim
    valueLbl.Font = Enum.Font.GothamMedium
    valueLbl.TextSize = 12
    valueLbl.TextXAlignment = Enum.TextXAlignment.Left
    valueLbl.Parent = box

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(16, 16)
    arrow.Position = UDim2.new(1, -22, 0.5, -8)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.TextDim
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 8
    arrow.Parent = box

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(0.55, 0, 0, 0)
    list.Position = UDim2.new(0.45, 0, 0, 34)
    list.BackgroundColor3 = Theme.Background
    list.BorderSizePixel = 0
    list.ClipsDescendants = true
    list.Visible = false
    list.ZIndex = 10
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = Theme.Stroke
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromScale(0, 0)
    list.Parent = frame
    corner(list, 4)
    stroke(list)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local expanded = false
    local currentValue = default

    local function getOptions()
        if type(options) == "function" then
            return options()
        end
        return options
    end

    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local opts = getOptions()
        for i, opt in ipairs(opts) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = Theme.Element
            optBtn.BorderSizePixel = 0
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.LayoutOrder = i
            optBtn.ZIndex = 11
            optBtn.Parent = list

            local optLbl = Instance.new("TextLabel")
            optLbl.Size = UDim2.new(1, -16, 1, 0)
            optLbl.Position = UDim2.new(0, 8, 0, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.Text = tostring(opt)
            optLbl.TextColor3 = (currentValue == opt) and Theme.Blue or Theme.TextDim
            optLbl.Font = Enum.Font.GothamMedium
            optLbl.TextSize = 12
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.ZIndex = 12
            optLbl.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                local ok, err = pcall(function()
                    currentValue = opt
                    valueLbl.Text = tostring(opt)
                    if callback then callback(opt) end
                    expanded = false
                    tween(list, {Size = UDim2.new(0.55, 0, 0, 0)})
                    task.delay(0.15, function() list.Visible = false end)
                end)
                if not ok then warn("[GUI] Dropdown error: " .. tostring(err)) end
            end)
        end
    end

    box.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            rebuild()
            list.Visible = true
            local opts = getOptions()
            tween(list, {Size = UDim2.new(0.55, 0, 0, math.min(#opts * 28, 150))})
        else
            tween(list, {Size = UDim2.new(0.55, 0, 0, 0)})
            task.delay(0.15, function() list.Visible = false end)
        end
    end)

    return {Set = function(v) currentValue = v valueLbl.Text = tostring(v) end, Get = function() return currentValue end}
end

function Components.Slider(page, label, min, max, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0.2, 0, 0, 20)
    valueLbl.Position = UDim2.new(0.8, 0, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(default)
    valueLbl.TextColor3 = Theme.TextDim
    valueLbl.Font = Enum.Font.GothamMedium
    valueLbl.TextSize = 12
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 28)
    track.BackgroundColor3 = Theme.Element
    track.BorderSizePixel = 0
    track.Parent = frame
    corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = Theme.Blue
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 2)

    local value = default
    local dragging = false

    local function update()
        valueLbl.Text = tostring(value)
        fill.Size = UDim2.fromScale((value - min) / (max - min), 1)
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + rel * (max - min) + 0.5)
            update()
            if callback then callback(value) end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + rel * (max - min) + 0.5)
            update()
            if callback then callback(value) end
        end
    end)

    return {Set = function(v) value = v update() end, Get = function() return value end}
end

function Components.Button(page, label, callback, order, isDanger)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = isDanger and Color3.fromRGB(180, 60, 60) or Theme.Element
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 0
    btn.Parent = page
    corner(btn, 4)

    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    return btn
end

function Components.Keybind(page, label, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0
    frame.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.fromOffset(70, 24)
    keyBtn.Position = UDim2.new(1, -70, 0.5, -12)
    keyBtn.BackgroundColor3 = Theme.Element
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = default and tostring(default):gsub("Enum.KeyCode.", "") or "..."
    keyBtn.TextColor3 = Theme.Blue
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = frame
    corner(keyBtn, 4)
    stroke(keyBtn)

    local listening = false
    local current = default

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."

        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                keyBtn.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                listening = false
                if callback then pcall(callback, input.KeyCode) end
                conn:Disconnect()
            end
        end)
    end)

    return {Set = function(k) current = k keyBtn.Text = tostring(k):gsub("Enum.KeyCode.", "") end, Get = function() return current end}
end

GUI.Components = Components

-- Tab system
local function switchTab(name)
    if IsLoading then return end
    if ActiveTab == name then return end
    ActiveTab = name
    for tabName, page in pairs(Pages) do
        page.Visible = (tabName == name)
    end
    for _, child in ipairs(TabBar:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = (child.Name == "Tab_" .. name)
            local lbl = child:FindFirstChild("Label")
            if lbl then
                tween(lbl, {TextColor3 = isActive and Theme.Accent or Theme.TextDim})
            end
        end
    end
end

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Size = UDim2.new(0, 90, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = TabBar

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Theme.TextDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Stroke
    page.Visible = false
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.fromScale(0, 0)
    page.ClipsDescendants = true
    page.Parent = ContentHost

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 15)
    pad.PaddingTop = UDim.new(0, 15)
    pad.PaddingRight = UDim.new(0, 15)
    pad.PaddingBottom = UDim.new(0, 15)
    pad.Parent = page

    Pages[name] = page
    return page
end

-- Build main GUI
local function build()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TWDOnlineGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = playerGui

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.Size = UDim2.fromOffset(600, 400)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    corner(MainFrame, 8)
    stroke(MainFrame)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 150, 0, 35)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "TWD ONLINE"
    title.TextColor3 = Theme.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 4)
    closeBtn.BackgroundColor3 = Theme.Element
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Theme.TextDim
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = MainFrame
    corner(closeBtn, 4)

    closeBtn.MouseButton1Click:Connect(function()
        GUI.ToggleMenu()
    end)

    TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -30, 0, 35)
    TabBar.Position = UDim2.new(0, 15, 0, 40)
    TabBar.BackgroundColor3 = Theme.Darker
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame
    corner(TabBar, 6)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = TabBar

    ContentHost = Instance.new("Frame")
    ContentHost.Size = UDim2.new(1, -30, 1, -85)
    ContentHost.Position = UDim2.new(0, 15, 0, 80)
    ContentHost.BackgroundTransparency = 1
    ContentHost.ClipsDescendants = true
    ContentHost.Parent = MainFrame

    createTab("ESP", 1)
    createTab("Aimbot", 2)
    createTab("Misc", 3)
    createTab("Settings", 4)

    UserInputService.InputBegan:Connect(function(input, gp)
        local ok, err = pcall(function()
            if gp then return end
            if input.KeyCode == MenuKeybind then
                if IsLoading then return end
                GUI.ToggleMenu()
            end
        end)
    end)

    switchTab("ESP")
end

function GUI.ToggleMenu()
    if IsLoading then return end
    IsOpen = not IsOpen
    if MainFrame then
        MainFrame.Visible = IsOpen
    end
end

function GUI.IsOpen()
    return IsOpen
end

function GUI.GetPage(name)
    return Pages[name]
end

function GUI.Cleanup()
    if ScreenGui then ScreenGui:Destroy() end
end

function GUI.Init(deps)
    Config = deps.Config
    Utils = deps.Utils

    local ok, err = pcall(function()
        build()
    end)
    if not ok then
        warn("[GUI] Error: " .. tostring(err))
    end

    -- Register Settings tab
    local settings = GUI.GetPage("Settings")
    if settings then
        local C = GUI.Components

        local savedKeybind = Enum.KeyCode.RightControl
        if Config and Config.Get then
            local saved = Config.Get("MenuKeybind")
            if saved then
                local ok, parsed = pcall(function()
                    return Enum.KeyCode[saved]
                end)
                if ok and parsed then
                    savedKeybind = parsed
                end
            end
        end

        C.Section(settings, "Menu", 1)
        C.Keybind(settings, "Menu Keybind", savedKeybind, function(k)
            print("[GUI] Keybind changed to: " .. tostring(k))
            if Config and Config.Set then
                Config.Set("MenuKeybind", tostring(k):gsub("Enum.KeyCode.", ""))
            end
            MenuKeybind = k
        end, 2)

        C.Section(settings, "Config", 10)
        C.Button(settings, "Reset Config", function()
            if Config and Config.Reset then Config.Reset() end
        end, 11, false)
    end

    IsLoading = true
    if MainFrame then MainFrame.Active = false end

    task.delay(2, function()
        IsLoading = false
        if MainFrame then MainFrame.Active = true end
        print("[TWD] GUI READY")
    end)

    print("[TWD] GUI initialized.")
end

return GUI
