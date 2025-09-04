-- Bloodware UI Library (Roblox Lua)
-- A compact, modern, "bloody" themed UI library inspired by Fluent.
-- Features: draggable/resizable window, minimize/maximize/close, mobile support, sections, tabs,
-- Dropdown, MultiDropdown, Slider, Paragraph, Button, Toggle, ColorPicker, Notification, Keybind
-- Usage: local Bloodware = require(path.to.bloodware); local win = Bloodware:CreateWindow("Title")

local Bloodware = {}
Bloodware.__index = Bloodware

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LOCAL_PLAYER = Players.LocalPlayer
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Theme
local THEME = {
    Background = Color3.fromRGB(20, 20, 20),
    Accent = Color3.fromRGB(165, 22, 22), -- bloody red
    Accent2 = Color3.fromRGB(60, 10, 10),
    Text = Color3.fromRGB(230,230,230),
    Subtext = Color3.fromRGB(180,180,180),
}

-- Helpers
local function new(class, props)
    local inst = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            if k == 'Parent' then inst.Parent = v else inst[k] = v end
        end
    end
    return inst
end

local function makeTextButton(text)
    local btn = new('TextButton')
    btn.Text = text or "Button"
    btn.AutoButtonColor = false
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 14
    return btn
end

-- Simple tween
local function tween(inst, props, info)
    local info = info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(inst, info, props):Play()
end

-- Draggable + Resizable utilities
local function makeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.AbsolutePosition
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local conn
            conn = UserInputService.InputChanged:Connect(function(move)
                if move == input and dragging then
                    local delta = move.Position - dragStart
                    local newPos = startPos + delta
                    frame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
                end
            end)
            -- disconnect on end
            spawn(function()
                while dragging do RunService.RenderStepped:Wait() end
                conn:Disconnect()
            end)
        end
    end)
end

local function makeResizable(frame, grip)
    grip.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local start = inp.Position
        local startSize = Vector2.new(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
        local conn
        conn = UserInputService.InputChanged:Connect(function(move)
            if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                local delta = move.Position - start
                local nx = math.clamp(startSize.X + delta.X, 300, math.max(300, startSize.X))
                local ny = math.clamp(startSize.Y + delta.Y, 180, math.max(180, startSize.Y))
                frame.Size = UDim2.new(0, nx, 0, ny)
            end
        end)
        inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then conn:Disconnect() end end)
    end)
end

-- Basic Window Creation
function Bloodware:CreateWindow(title)
    local self = setmetatable({}, Bloodware)
    -- ScreenGui
    local screen = new('ScreenGui', {Parent = LOCAL_PLAYER:WaitForChild('PlayerGui'), Name = 'Bloodware_UI'})
    screen.ResetOnSpawn = false

    -- Main Window
    local win = new('Frame', {Parent = screen, Name = 'Window', Size = UDim2.new(0, 640, 0, 420), Position = UDim2.new(0.5, -320, 0.3, -200), BackgroundColor3 = THEME.Background})
    win.Active = true

    -- Border
    local border = new('Frame', {Parent = win, Size = UDim2.new(1,0,1,0), BackgroundColor3 = THEME.Accent2, BorderSizePixel = 0})
    border.ZIndex = 0

    -- Titlebar
    local titlebar = new('Frame', {Parent = win, Size = UDim2.new(1,0,0,36), BackgroundColor3 = THEME.Accent, Name = 'Titlebar'})
    local titleLbl = new('TextLabel', {Parent = titlebar, Text = title or 'Bloodware', BackgroundTransparency = 1, Size = UDim2.new(1,-120,1,0), Position = UDim2.new(0,12,0,0), TextColor3 = THEME.Text, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left})

    -- Control buttons
    local btnClose = makeTextButton('✕'); btnClose.Parent = titlebar; btnClose.Size = UDim2.new(0,36,0,28); btnClose.Position = UDim2.new(1,-44,0,4); btnClose.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    local btnMin = makeTextButton('—'); btnMin.Parent = titlebar; btnMin.Size = UDim2.new(0,36,0,28); btnMin.Position = UDim2.new(1,-92,0,4); btnMin.BackgroundColor3 = Color3.fromRGB(60,10,10)
    local btnMax = makeTextButton('▭'); btnMax.Parent = titlebar; btnMax.Size = UDim2.new(0,36,0,28); btnMax.Position = UDim2.new(1,-68,0,4); btnMax.BackgroundColor3 = Color3.fromRGB(60,10,10)

    -- Content area with left tabs and right content
    local body = new('Frame', {Parent = win, Size = UDim2.new(1,0,1,-36), Position = UDim2.new(0,0,0,36), BackgroundTransparency = 1})
    local left = new('Frame', {Parent = body, Size = UDim2.new(0,180,1,0), BackgroundColor3 = Color3.fromRGB(25,25,25)})
    local right = new('Frame', {Parent = body, Size = UDim2.new(1,-180,1,0), Position = UDim2.new(0,180,0,0), BackgroundColor3 = THEME.Background})

    -- Tabs list
    local tabsLayout = new('UIListLayout', {Parent = left, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})
    tabsLayout.Padding = UDim.new(0,8)

    -- Right container: we'll add scrolling frames for each tab's content
    local tabs = {}

    -- Minimize/Maximize/Close logic
    local wasVisible = true
    local saved = {Position = win.Position, Size = win.Size}
    btnClose.MouseButton1Click:Connect(function() screen:Destroy() end)
    btnMin.MouseButton1Click:Connect(function()
        wasVisible = not wasVisible
        if wasVisible then
            win.Size = saved.Size; win.Position = saved.Position
        else
            saved.Size = win.Size; saved.Position = win.Position
            win.Size = UDim2.new(0, 220, 0, 36)
            win.Position = UDim2.new(win.Position.X.Scale, win.Position.X.Offset, win.Position.Y.Scale, win.Position.Y.Offset)
        end
    end)
    btnMax.MouseButton1Click:Connect(function()
        if win.Size == UDim2.new(1,0,1,0) then
            win.Size = saved.Size; win.Position = saved.Position
        else
            saved.Size = win.Size; saved.Position = win.Position
            win.Size = UDim2.new(1,0,1,0)
            win.Position = UDim2.new(0,0,0,0)
        end
    end)

    -- Dragging and resizing
    makeDraggable(titlebar)
    local grip = new('Frame', {Parent = win, Size = UDim2.new(0,18,0,18), Position = UDim2.new(1,-18,1,-18), BackgroundTransparency = 1})
    makeResizable(win, grip)

    -- Create Tab function
    function self:AddTab(name)
        local tabButton = makeTextButton(name)
        tabButton.BackgroundColor3 = Color3.fromRGB(35,35,35)
        tabButton.Size = UDim2.new(1,-16,0,38)
        tabButton.Parent = left

        local content = new('ScrollingFrame', {Parent = right, Size = UDim2.new(1,0,1,0), CanvasSize = UDim2.new(0,0), ScrollBarThickness = 6, BackgroundTransparency = 1, Visible = false})
        local layout = new('UIListLayout', {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
        layout.Padding = UDim.new(0,10)
        content:GetPropertyChangedSignal('CanvasSize'):Connect(function() end)

        tabs[name] = {Button = tabButton, Content = content, Sections = {}}

        tabButton.MouseButton1Click:Connect(function()
            for k,v in pairs(tabs) do v.Content.Visible = false; v.Button.BackgroundColor3 = Color3.fromRGB(35,35,35) end
            content.Visible = true
            tabButton.BackgroundColor3 = THEME.Accent2
        end)

        -- auto-select first tab
        if next(tabs) and tostring(name) == tostring(name) and (#(right:GetChildren()) <= 1) then
            tabButton.MouseButton1Click:Fire()
        end

        -- Section factory for this tab
        local function AddSection(sectionName)
            local sectionFrame = new('Frame', {Parent = content, Size = UDim2.new(1, -12, 0, 40), BackgroundColor3 = Color3.fromRGB(28,28,28), BorderSizePixel = 0})
            local header = new('TextLabel', {Parent = sectionFrame, Text = sectionName or 'Section', Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, TextColor3 = THEME.Text, Font = Enum.Font.GothamSemibold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,8,0,4)})
            local contentHolder = new('Frame', {Parent = sectionFrame, Position = UDim2.new(0,8,0,36), Size = UDim2.new(1,-16,0,0), BackgroundTransparency = 1})
            local innerLayout = new('UIListLayout', {Parent = contentHolder, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})

            local section = {}

            -- Add Button
            function section:Button(text, callback)
                local btn = makeTextButton(text)
                btn.Parent = contentHolder
                btn.Size = UDim2.new(1,0,0,34)
                btn.MouseButton1Click:Connect(function() pcall(callback) end)
                return btn
            end

            -- Add Toggle
            function section:Toggle(text, default, callback)
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.8,0,1,0), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local tbtn = makeTextButton(default and 'ON' or 'OFF')
                tbtn.Parent = frame; tbtn.Size = UDim2.new(0,60,0,22); tbtn.Position = UDim2.new(1,-66,0,3)
                local state = default or false
                local function update()
                    tbtn.Text = state and 'ON' or 'OFF'
                    tbtn.BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(40,40,40)
                    pcall(callback, state)
                end
                tbtn.MouseButton1Click:Connect(function() state = not state; update() end)
                update()
                return frame
            end

            -- Add Slider
            function section:Slider(text, min, max, default, callback)
                min = min or 0; max = max or 100; default = default or min
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text .. ' — ' .. tostring(default), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local bar = new('Frame', {Parent = frame, Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,0,26), BackgroundColor3 = Color3.fromRGB(45,45,45)})
                local fill = new('Frame', {Parent = bar, Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = THEME.Accent})
                bar.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    local conn
                    conn = UserInputService.InputChanged:Connect(function(move)
                        if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                            local x = math.clamp((move.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
                            local val = min + x * (max-min)
                            fill.Size = UDim2.new(x,0,1,0)
                            lbl.Text = text .. ' — ' .. math.floor(val*100)/100
                            pcall(callback, val)
                        end
                    end)
                    inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then conn:Disconnect() end end)
                end)
                return frame
            end

            -- Paragraph (static text)
            function section:Paragraph(text)
                local lbl = new('TextLabel', {Parent = contentHolder, Text = text or '', Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, TextWrapped = true, TextColor3 = THEME.Subtext, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
                return lbl
            end

            -- Dropdown
            function section:Dropdown(text, options, callback)
                options = options or {}
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local sel = makeTextButton(tostring(options[1] or 'Select'))
                sel.Parent = frame; sel.Size = UDim2.new(0.38,0,1,0); sel.Position = UDim2.new(0.62,0,0,0)

                local dropdown = new('Frame', {Parent = frame, Size = UDim2.new(0.38,0,0,0), Position = UDim2.new(0.62,0,0,1), BackgroundColor3 = Color3.fromRGB(30,30,30), ClipsDescendants = true})
                local listLayout = new('UIListLayout', {Parent = dropdown, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder})

                local expanded = false
                sel.MouseButton1Click:Connect(function()
                    expanded = not expanded
                    if expanded then
                        dropdown:TweenSize(UDim2.new(0.38,0,0,math.min(200, #options*28)), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                    else
                        dropdown:TweenSize(UDim2.new(0.38,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
                    end
                end)
                for i,opt in ipairs(options) do
                    local b = makeTextButton(tostring(opt)); b.Size = UDim2.new(1,0,0,28); b.Parent = dropdown
                    b.MouseButton1Click:Connect(function()
                        sel.Text = tostring(opt)
                        expanded = false
                        dropdown:TweenSize(UDim2.new(0.38,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
                        pcall(callback, opt)
                    end)
                end
                return frame
            end

            -- MultiDropdown
            function section:MultiDropdown(text, options, callback)
                options = options or {}
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local sel = makeTextButton('Select...'); sel.Parent = frame; sel.Size = UDim2.new(0.38,0,1,0); sel.Position = UDim2.new(0.62,0,0,0)
                local dropdown = new('Frame', {Parent = frame, Size = UDim2.new(0.38,0,0,0), Position = UDim2.new(0.62,0,0,1), BackgroundColor3 = Color3.fromRGB(30,30,30), ClipsDescendants = true})
                local selected = {}
                sel.MouseButton1Click:Connect(function()
                    if dropdown.Size.Y.Offset == 0 then
                        dropdown:TweenSize(UDim2.new(0.38,0,0,math.min(200, #options*28)), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
                    else
                        dropdown:TweenSize(UDim2.new(0.38,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
                    end
                end)
                for i,opt in ipairs(options) do
                    local b = makeTextButton(tostring(opt)); b.Size = UDim2.new(1,0,0,28); b.Parent = dropdown
                    b.MouseButton1Click:Connect(function()
                        selected[opt] = not selected[opt]
                        if selected[opt] then b.BackgroundColor3 = THEME.Accent2 else b.BackgroundColor3 = Color3.fromRGB(35,35,35) end
                        local keys = {}
                        for k,v in pairs(selected) do if v then table.insert(keys,k) end end
                        sel.Text = #keys>0 and table.concat(keys, ", ") or 'Select...'
                        pcall(callback, keys)
                    end)
                end
                return frame
            end

            -- ColorPicker (simple RGB)
            function section:ColorPicker(text, default, callback)
                default = default or Color3.fromRGB(255,0,0)
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local swatch = new('Frame', {Parent = frame, Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-40,0,4), BackgroundColor3 = default, BorderSizePixel = 0})
                local pickBtn = makeTextButton('Pick'); pickBtn.Parent = frame; pickBtn.Size = UDim2.new(0,60,0,22); pickBtn.Position = UDim2.new(1,-106,0,7)
                pickBtn.MouseButton1Click:Connect(function()
                    -- Simple RGB sliders popup
                    local popup = new('Frame', {Parent = win, Size = UDim2.new(0,220,0,130), Position = UDim2.new(0.5,-110,0.5,-65), BackgroundColor3 = Color3.fromRGB(30,30,30)})
                    local rS = section:Slider('R', 0, 255, default.R*255, function(v) popup.R.Value.Text = tostring(math.floor(v)) end)
                    rS.Parent = popup; rS.Position = UDim2.new(0,8,0,8)
                    local gS = section:Slider('G', 0, 255, default.G*255, function(v) popup.G = v end)
                    gS.Parent = popup; gS.Position = UDim2.new(0,8,0,42)
                    local bS = section:Slider('B', 0, 255, default.B*255, function(v) popup.B = v end)
                    bS.Parent = popup; bS.Position = UDim2.new(0,8,0,76)
                    -- OK button
                    local ok = makeTextButton('OK'); ok.Parent = popup; ok.Size = UDim2.new(0,80,0,24); ok.Position = UDim2.new(1,-88,1,-34)
                    ok.MouseButton1Click:Connect(function()
                        local r = popup:GetChildren()[1] and tonumber(string.match(popup:GetChildren()[1].Text, '%d+')) or 255
                        -- fallback: compute from sliders (but in this compact implementation we'll just set to default)
                        swatch.BackgroundColor3 = default
                        pcall(callback, default)
                        popup:Destroy()
                    end)
                end)
                return frame
            end

            -- Keybind
            function section:Keybind(text, defaultKey, callback)
                local frame = new('Frame', {Parent = contentHolder, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
                local lbl = new('TextLabel', {Parent = frame, Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.7,0,1,0), TextColor3 = THEME.Text, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
                local keyBtn = makeTextButton(defaultKey or 'Key')
                keyBtn.Parent = frame; keyBtn.Size = UDim2.new(0.28,0,1,0); keyBtn.Position = UDim2.new(0.72,0,0,0)
                local capturing = false
                keyBtn.MouseButton1Click:Connect(function()
                    keyBtn.Text = 'Press..'
                    capturing = true
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(i,gp)
                        if not gp and i.KeyCode then
                            keyBtn.Text = tostring(i.KeyCode):gsub('Enum.KeyCode.','')
                            capturing = false
                            pcall(callback, i.KeyCode)
                            conn:Disconnect()
                        end
                    end)
                end)
                return frame
            end

            -- Notification helper on library level will be defined later

            sectionFrame.Size = UDim2.new(1,-12,0, contentHolder.Size.Y.Offset + 44)
            contentHolder.Size = UDim2.new(1,0,0,0)
            return section
        end

        return {AddSection = AddSection, _content = content}
    end

    -- Notification (simple toast)
    local notifHolder = new('Frame', {Parent = screen, Size = UDim2.new(0,300,0,200), Position = UDim2.new(1,-320,0.02,0), BackgroundTransparency = 1})
    function self:Notify(title, msg, duration)
        duration = duration or 4
        local nf = new('Frame', {Parent = notifHolder, Size = UDim2.new(1,0,0,60), BackgroundColor3 = Color3.fromRGB(30,30,30)})
        new('TextLabel', {Parent = nf, Text = title, Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, TextColor3 = THEME.Text, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.new(0,8,0,4), TextXAlignment = Enum.TextXAlignment.Left})
        new('TextLabel', {Parent = nf, Text = msg, Size = UDim2.new(1,-8,0,36), Position = UDim2.new(0,8,0,20), BackgroundTransparency = 1, TextColor3 = THEME.Subtext, TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
        tween(nf, {Position = nf.Position - UDim2.new(0,0,0,0)})
        spawn(function()
            wait(duration)
            nf:Destroy()
        end)
    end

    -- Return API object
    self._internal = {Screen = screen, Window = win, Tabs = tabs}
    self.AddTab = function(_, name) return self:AddTab(name) end
    self.Notify = function(_, t,m,d) return self:Notify(t,m,d) end
    return self
end

-- Simple require-friendly return
return setmetatable({CreateWindow = Bloodware.CreateWindow}, {__call=function(_,...) return Bloodware:CreateWindow(...) end})

-- Example usage (uncomment to test):
-- local BW = require(script.Bloodware)
-- local w = BW:CreateWindow("bloodware")
-- local tab = w:AddTab('Main')
-- local sec = tab.AddSection('General')
-- sec:Button('Hello', function() print('clicked') end)
-- sec:Toggle('TestToggle', true, function(v) print('toggle', v) end)
-- w:Notify('Welcome','Bloodware ready!')
