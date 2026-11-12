local RealTweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Skin = { Name = "Classic" }
local Env, P
local NotifHost

-- every TweenService:Create below goes through this wrapper, so the
-- "UI Animations" switch makes all of them instant when it is off
local TweenService = {}
function TweenService:Create(o, info, props)
    local an = Env and Env.Anim
    if an and not an.on() then
        local dummy = {}
        function dummy:Play() for k, v in pairs(props) do pcall(function() o[k] = v end) end end
        function dummy:Cancel() end
        return dummy
    end
    return RealTweenService:Create(o, info, props)
end

local function AN()
    return Env and Env.Anim
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or P.Outline
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function round(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius
    c.Parent = parent
    return c
end

local function layoutRegistry()
    return Env and Env.GetTabLayoutRegistry and Env.GetTabLayoutRegistry() or nil
end

function Skin.MakeTheme(base, _themeName)

    local T = {}
    if type(base) == "table" then
        for k, v in pairs(base) do T[k] = v end
    end
    return T
end

function Skin.SendNotification(text, color)
    if not NotifHost or not NotifHost.Parent then return end

    local accentCol = color or P.Accent

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 0, 0, 34)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.AnchorPoint = Vector2.new(1, 0)
    pill.Position = UDim2.new(1, -12, 0, 0)
    pill.BackgroundColor3 = P.MainBg
    pill.BorderSizePixel = 0
    pill.ClipsDescendants = false
    pill.Parent = NotifHost
    round(pill, UDim.new(0, 17))
    AddStroke(pill, accentCol, 1.5)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 13, 0.5, -4)
    dot.BackgroundColor3 = accentCol
    dot.BorderSizePixel = 0
    dot.Parent = pill
    round(dot, UDim.new(1, 0))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(text) .. "  "
    lbl.TextColor3 = P.TextPrimary
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = pill

    pill.Position = UDim2.new(1, 250, 0, 0)
    TweenService:Create(pill, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(1, -12, 0, 0) }):Play()

    task.spawn(function()
        task.wait(3.2)
        if not pill.Parent then return end
        TweenService:Create(pill, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(1, 250, 0, 0) }):Play()
        task.wait(0.4)
        if pill.Parent then pill:Destroy() end
    end)
end

function Skin.createLayout(parent)
    local layout = Instance.new("UIListLayout")
    layout.Parent, layout.SortOrder, layout.Padding, layout.HorizontalAlignment =
        parent, Enum.SortOrder.LayoutOrder, UDim.new(0, 6), Enum.HorizontalAlignment.Center
    if parent:IsA("ScrollingFrame") then
        local function refresh()
            parent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 150)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
        refresh()
        local reg = layoutRegistry()
        if reg then reg[parent] = refresh end
    end
    return layout
end

function Skin.createSectionHeader(parent, text)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0.96, 0, 0, 24)
    sep.BackgroundTransparency = 1
    sep.Parent = parent

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 0, 0, 20)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.Position = UDim2.new(0, 0, 0.5, -10)
    pill.BackgroundColor3 = P.SidebarBg
    pill.BorderSizePixel = 0
    pill.Parent = sep
    round(pill, UDim.new(0, 10))
    AddStroke(pill, P.Outline, 1)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0, 7, 0.5, -2)
    dot.BackgroundColor3 = P.Accent
    dot.BorderSizePixel = 0
    dot.Parent = pill
    round(dot, UDim.new(1, 0))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0, 17, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = tostring(text) .. "  "
    lbl.TextColor3 = P.TextSecondary
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.BorderSizePixel = 0
    lbl.Parent = pill

    local tailLine = Instance.new("Frame")
    tailLine.Size = UDim2.new(1, -120, 0, 1)
    tailLine.Position = UDim2.new(0, 110, 0.5, 0)
    tailLine.BackgroundColor3 = P.Outline
    tailLine.BorderSizePixel = 0
    tailLine.Parent = sep

    return sep
end

function Skin.createToggleSwitch(parent, text, description, callback, externalControl, noSave)
    local Settings = Env.Settings
    local toggleObj, isOn = {}, false

    local container = Instance.new("TextButton")
    container.Size = UDim2.new(0.96, 0, 0, 52)
    container.BackgroundColor3 = P.ContentBg
    container.AutoButtonColor = false
    container.Text = ""
    container.Parent = parent
    round(container, UDim.new(0, 8))
    local stroke = AddStroke(container, P.Outline, 1)
    if AN() then AN().bindRipple(container, P.Accent) end

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 2, 0.65, 0)
    accentBar.Position = UDim2.new(0, 0, 0.175, 0)
    accentBar.BackgroundColor3 = P.Outline
    accentBar.BorderSizePixel = 0
    accentBar.Parent = container
    round(accentBar, UDim.new(1, 0))

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.68, 0, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.Text = text
    label.TextColor3 = P.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Parent = container

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.68, 0, 0, 0)
    descLabel.Position = UDim2.new(0, 14, 0, 29)
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.Text = description or ""
    descLabel.TextColor3 = P.TextSecondary
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.BackgroundTransparency = 1
    descLabel.TextWrapped = true
    descLabel.Parent = container

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 40, 0, 22)
    switchBg.Position = UDim2.new(1, -50, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    switchBg.Parent = container
    round(switchBg, UDim.new(1, 0))
    AddStroke(switchBg, Color3.fromRGB(70, 70, 85), 1)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(160, 160, 175)
    circle.Parent = switchBg
    round(circle, UDim.new(1, 0))

    local flashOK = false
    local function updateVisuals()
        TweenService:Create(circle, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            BackgroundColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 175),
        }):Play()
        if isOn and flashOK then
            container.BackgroundColor3 = P.ContentBg:Lerp(P.Accent, 0.3)
            TweenService:Create(container, TweenInfo.new(0.55), { BackgroundColor3 = P.ContentBg }):Play()
        end
        TweenService:Create(switchBg, TweenInfo.new(0.22), { BackgroundColor3 = isOn and P.Accent or Color3.fromRGB(45, 45, 55) }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.22), { BackgroundColor3 = isOn and P.Accent or P.Outline }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.22), { Color = isOn and P.Accent or P.Outline, Thickness = isOn and 1.5 or 1 }):Play()
    end

    container.MouseEnter:Connect(function()
        if not isOn then TweenService:Create(container, TweenInfo.new(0.15), { BackgroundColor3 = P.ItemHover }):Play() end
    end)

    local function resetToggleState()
        TweenService:Create(container, TweenInfo.new(0.1), { Size = UDim2.new(0.96, 0, 0, 52) }):Play()
    end

    container.InputBegan:Connect(function(input)
        if isPress(input) then
            TweenService:Create(container, TweenInfo.new(0.1), { Size = UDim2.new(0.94, 0, 0, 50) }):Play()
        end
    end)

    container.InputEnded:Connect(function(input)
        if isPress(input) then resetToggleState() end
    end)

    container.MouseLeave:Connect(function()
        resetToggleState()
        if not isOn then TweenService:Create(container, TweenInfo.new(0.15), { BackgroundColor3 = P.ContentBg }):Play() end
    end)

    local function commit()
        if not noSave then
            Settings[text] = isOn
            Env.saveSettings()
        end
    end

    container.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateVisuals()
        task.spawn(function() callback(isOn) end)
        commit()
    end)

    function toggleObj:SetState(state)
        if isOn ~= state then
            isOn = state
            updateVisuals()
            if not externalControl then task.spawn(function() callback(isOn) end) end
            commit()
        end
    end

    local kbBtn = Instance.new("TextButton")
    kbBtn.Name = "KeybindBtn"
    kbBtn.Size = UDim2.new(0, 24, 0, 24)
    kbBtn.Position = UDim2.new(1, -96, 0.5, -12)
    kbBtn.BackgroundColor3 = P.SidebarBg
    kbBtn.Text = "⌨️"
    kbBtn.TextColor3 = P.TextSecondary
    kbBtn.Font = Enum.Font.GothamBold
    kbBtn.TextSize = 11
    kbBtn.AutoButtonColor = false
    kbBtn.ZIndex = 2
    kbBtn.Parent = container
    round(kbBtn, UDim.new(0, 6))
    local kbStroke = AddStroke(kbBtn, P.Outline, 1)

    local function updateKbVisual()
        local kb = Settings.Keybinds and Settings.Keybinds[text]
        if kb and kb.key then
            local display = (kb.ctrl and "^" or "") .. tostring(kb.key)
            kbBtn.Text = display
            kbBtn.TextSize = (#display > 3) and 7 or 9
            TweenService:Create(kbStroke, TweenInfo.new(0.15), { Color = P.Accent }):Play()
            TweenService:Create(kbBtn, TweenInfo.new(0.15), { TextColor3 = P.Accent, BackgroundColor3 = P.ContentBg }):Play()
        else
            kbBtn.Text = "⌨️"
            kbBtn.TextSize = 11
            TweenService:Create(kbStroke, TweenInfo.new(0.15), { Color = P.Outline }):Play()
            TweenService:Create(kbBtn, TweenInfo.new(0.15), { TextColor3 = P.TextSecondary, BackgroundColor3 = P.SidebarBg }):Play()
        end
    end
    updateKbVisual()

    kbBtn.MouseButton1Click:Connect(function()
        local openPopup = Env.GetOpenKeybindPopup and Env.GetOpenKeybindPopup()
        if openPopup then openPopup(text, updateKbVisual, toggleObj) end
    end)
    kbBtn.MouseEnter:Connect(function()
        TweenService:Create(kbBtn, TweenInfo.new(0.12), { BackgroundColor3 = P.ItemHover }):Play()
    end)
    kbBtn.MouseLeave:Connect(function()
        local kb = Settings.Keybinds and Settings.Keybinds[text]
        TweenService:Create(kbBtn, TweenInfo.new(0.12), { BackgroundColor3 = (kb and kb.key) and P.ContentBg or P.SidebarBg }):Play()
    end)

    function toggleObj:Toggle()
        isOn = not isOn
        updateVisuals()
        task.spawn(function() callback(isOn) end)
        commit()
    end

    function toggleObj:GetState()
        return isOn
    end

    local registry = Env.GetKeybinds and Env.GetKeybinds()
    if registry then registry[text] = toggleObj end

    if not noSave and Settings[text] ~= nil then
        isOn = Settings[text]
        updateVisuals()
        if not externalControl then task.spawn(function() callback(isOn) end) end
    end
    flashOK = true
    return toggleObj
end

function Skin.createSlider(parent, text, description, minVal, maxVal, defaultVal, callback, noSave)
    local Settings = Env.Settings

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.96, 0, 0, 62)
    container.BackgroundColor3 = P.ContentBg
    container.Parent = parent
    round(container, UDim.new(0, 8))
    AddStroke(container, P.Outline, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 18)
    label.Position = UDim2.new(0, 14, 0, 7)
    label.Text = text
    label.TextColor3 = P.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.BackgroundTransparency = 1
    label.Parent = container

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.65, 0, 0, 0)
    descLabel.Position = UDim2.new(0, 14, 0, 26)
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.Text = description or ""
    descLabel.TextColor3 = P.TextSecondary
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.BackgroundTransparency = 1
    descLabel.TextWrapped = true
    descLabel.Parent = container

    local valueBadge = Instance.new("Frame")
    valueBadge.Size = UDim2.new(0, 44, 0, 18)
    valueBadge.Position = UDim2.new(1, -56, 0, 7)
    valueBadge.BackgroundColor3 = P.SidebarBg
    valueBadge.BorderSizePixel = 0
    valueBadge.Parent = container
    round(valueBadge, UDim.new(0, 9))
    AddStroke(valueBadge, P.Accent, 1)

    local valueLabel = Instance.new("TextBox")
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultVal)
    valueLabel.TextColor3 = P.Accent
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 10
    valueLabel.ClearTextOnFocus = false
    valueLabel.Parent = valueBadge

    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(0.88, 0, 0, 4)
    sliderBg.Position = UDim2.new(0.06, 0, 1, -14)
    sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    sliderBg.Parent = container
    round(sliderBg, UDim.new(1, 0))

    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = P.Accent
    sliderFill.Parent = sliderBg
    round(sliderFill, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(1, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
    knob.Parent = sliderFill
    round(knob, UDim.new(1, 0))
    AddStroke(knob, P.Accent, 1.5)

    local currentVal = (not noSave and Settings[text]) or defaultVal
    local ready = false

    local function setSlider(val)
        val = math.clamp(tonumber(val) or currentVal, minVal, maxVal)
        local pos = (maxVal == minVal) and 0 or (val - minVal) / (maxVal - minVal)
        TweenService:Create(sliderFill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(pos, 0, 1, 0) }):Play()
        valueLabel.Text = tostring(val)
        if ready then
            if noSave then
                callback(val)
            elseif Settings[text] ~= val then
                Settings[text] = val
                Env.saveSettings()
                callback(val)
            end
        end
        currentVal = val
    end

    valueLabel.FocusLost:Connect(function()
        local num = tonumber(valueLabel.Text)
        if num then
            setSlider(num)
        else
            valueLabel.Text = tostring(currentVal)
        end
    end)

    local draggingSlider = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / math.max(sliderBg.AbsoluteSize.X, 1), 0, 1)
        setSlider(math.floor(minVal + ((maxVal - minVal) * pos)))
    end

    sliderBg.InputBegan:Connect(function(input)
        if isPress(input) then
            draggingSlider = true
            TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 18, 0, 18) }):Play()
            updateSlider(input)
        end
    end)
    local sliderConn1 = UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and isMove(input) then
            updateSlider(input)
        end
    end)
    local sliderConn2 = UserInputService.InputEnded:Connect(function(input)
        if isPress(input) and draggingSlider then
            draggingSlider = false
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 14, 0, 14) }):Play()
        end
    end)
    container.Destroying:Connect(function()
        if sliderConn1 then sliderConn1:Disconnect(); sliderConn1 = nil end
        if sliderConn2 then sliderConn2:Disconnect(); sliderConn2 = nil end
        draggingSlider = false
    end)

    setSlider(currentVal)
    ready = true
    if not noSave and Settings[text] ~= nil then task.spawn(function() callback(currentVal) end) end
end

function Skin.createButton(parent, text, description, color, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.96, 0, 0, 52)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = P.ContentBg
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container
    round(btn, UDim.new(0, 8))
    local stroke = AddStroke(btn, P.Outline, 1)
    if AN() then AN().bindRipple(btn, color or P.Accent) end

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 3, 0.5, 0)
    stripe.Position = UDim2.new(0, 0, 0.25, 0)
    stripe.BackgroundColor3 = color or P.Accent
    stripe.BorderSizePixel = 0
    stripe.Parent = btn
    round(stripe, UDim.new(1, 0))

    local mainText = Instance.new("TextLabel")
    mainText.Size = UDim2.new(0.85, 0, 0, 22)
    mainText.Position = UDim2.new(0, 14, 0, 6)
    mainText.BackgroundTransparency = 1
    mainText.Text = text
    mainText.TextColor3 = color or P.TextPrimary
    mainText.Font = Enum.Font.GothamBold
    mainText.TextSize = 13
    mainText.TextXAlignment = Enum.TextXAlignment.Left
    mainText.Parent = btn

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.85, 0, 0, 0)
    descLabel.Position = UDim2.new(0, 14, 0, 29)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description or ""
    descLabel.TextColor3 = P.TextSecondary
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 16, 0, 16)
    arrow.Position = UDim2.new(1, -22, 0.5, -8)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = color or P.Accent
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = P.ItemHover }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = color or P.Accent }):Play()
    end)

    local function resetBtnState()
        TweenService:Create(btn, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 1, 0) }):Play()
    end

    btn.InputBegan:Connect(function(input)
        if isPress(input) then
            TweenService:Create(btn, TweenInfo.new(0.1), { Size = UDim2.new(0.97, 0, 0.92, 0) }):Play()
        end
    end)

    btn.InputEnded:Connect(function(input)
        if isPress(input) then resetBtnState() end
    end)

    btn.MouseLeave:Connect(function()
        resetBtnState()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = P.ContentBg }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = P.Outline }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

function Skin.createTextBox(parent, placeholder, description, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.96, 0, 0, 58)
    container.BackgroundColor3 = P.ContentBg
    container.Parent = parent
    round(container, UDim.new(0, 8))
    local stroke = AddStroke(container, P.Outline, 1)

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.95, 0, 0, 16)
    descLabel.Position = UDim2.new(0.025, 0, 0, 6)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description or ""
    descLabel.TextColor3 = P.TextSecondary
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = container

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(0.94, 0, 0, 26)
    inputBg.Position = UDim2.new(0.03, 0, 0, 25)
    inputBg.BackgroundColor3 = P.SidebarBg
    inputBg.BorderSizePixel = 0
    inputBg.Parent = container
    round(inputBg, UDim.new(0, 6))
    AddStroke(inputBg, P.Outline, 1)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = P.TextSecondary
    box.TextColor3 = P.TextPrimary
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = inputBg

    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = P.Accent, Thickness = 1.5 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = P.Outline, Thickness = 1 }):Play()
        if callback then callback(box.Text) end
    end)
    return box
end

function Skin.createConfirmation(parent, text, onYes)

    local host = (Skin.Shell and Skin.Shell.MainFrame)
        or (parent and parent.Parent and parent.Parent.Parent)
    if not host then return end

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 200
    overlay.Parent = host
    TweenService:Create(overlay, TweenInfo.new(0.22), { BackgroundTransparency = 0.5 }):Play()

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 280, 0, 140)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    popup.BackgroundColor3 = P.SidebarBg
    popup.ZIndex = 201
    popup.Parent = overlay
    round(popup, UDim.new(0, 12))
    AddStroke(popup, P.Accent, 1.5)
    if AN() then AN().scaleIn(popup, 0.82, 0.34) end

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = P.ContentBg
    topBar.ZIndex = 202
    topBar.Parent = popup
    round(topBar, UDim.new(0, 12))

    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 12)
    topFix.Position = UDim2.new(0, 0, 1, -12)
    topFix.BackgroundColor3 = P.ContentBg
    topFix.BorderSizePixel = 0
    topFix.ZIndex = 202
    topFix.Parent = topBar

    local topLbl = Instance.new("TextLabel")
    topLbl.Size = UDim2.new(1, -20, 1, 0)
    topLbl.Position = UDim2.new(0, 14, 0, 0)
    topLbl.BackgroundTransparency = 1
    topLbl.Text = "Confirm Action"
    topLbl.TextColor3 = P.Accent
    topLbl.Font = Enum.Font.GothamBold
    topLbl.TextSize = 12
    topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.ZIndex = 203
    topLbl.Parent = topBar

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 0, 0)
    label.Position = UDim2.new(0, 14, 0, 44)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = P.TextPrimary
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 202
    label.Parent = popup

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0, 110, 0, 30)
    yesBtn.Position = UDim2.new(0, 14, 1, -40)
    yesBtn.BackgroundColor3 = P.Green
    yesBtn.Text = "✓  Confirm"
    yesBtn.TextColor3 = Color3.new(0, 0, 0)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 11
    yesBtn.ZIndex = 202
    yesBtn.Parent = popup
    round(yesBtn, UDim.new(0, 8))

    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0, 110, 0, 30)
    noBtn.Position = UDim2.new(1, -124, 1, -40)
    noBtn.BackgroundColor3 = P.ContentBg
    noBtn.Text = "X  Cancel"
    noBtn.TextColor3 = P.Red
    noBtn.Font = Enum.Font.GothamBold
    noBtn.TextSize = 11
    noBtn.ZIndex = 202
    noBtn.Parent = popup
    round(noBtn, UDim.new(0, 8))
    AddStroke(noBtn, P.Red, 1)

    yesBtn.MouseButton1Click:Connect(function()

        local ok, err = pcall(onYes)
        if overlay.Parent then overlay:Destroy() end
        if not ok then warn("[Phantom] Confirmation action failed: " .. tostring(err)) end
    end)
    noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
end

local TAB_LABELS = {
    Discord = "🏠", Changelog = "🏠", Movement = "🏃", Visuals = "👁️",
    ESP = "🎯", Combat = "⚔️", Players = "👥", Tags = "🏷️", Positions = "📍",
    AFK = "💤", Server = "🌐", Info = "ℹ️", Settings = "⚙️", Optimize = "⚡",
    Utility = "🛠️", AI = "🤖",
}

function Skin.Mount(env)
    Env, P = env, env.Theme

    local S = {}
    Skin.Shell = S
    local settings = env.Settings
    local saveSettings = env.saveSettings
    local AddConnection = env.AddConnection
    local gui = env.ScreenGui

    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "PhClassicToasts"
    NotifContainer.Size = UDim2.new(1, 0, 1, 0)
    NotifContainer.Position = UDim2.new(0, 0, 0.03, 0)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.ZIndex = 20000
    NotifContainer.Parent = gui

    NotifHost = NotifContainer

    local NotificationLayout = Instance.new("UIListLayout")
    NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    NotificationLayout.Padding = UDim.new(0, 6)
    NotificationLayout.Parent = NotifContainer

    local W = (settings.MainFrameSize and settings.MainFrameSize.W) or 560
    local H = (settings.MainFrameSize and settings.MainFrameSize.H) or 360
    local mp = settings.MainFramePos

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, W, 0, H)
    MainFrame.Position = mp and UDim2.new(mp.X, mp.XOff, mp.Y, mp.YOff) or UDim2.new(0.5, -280, 0.5, -180)
    MainFrame.BackgroundColor3 = P.MainBg
    MainFrame.Visible = false
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = gui
    round(MainFrame, UDim.new(0, 12))
    AddStroke(MainFrame, P.Outline, 1.5)
    S.MainFrame = MainFrame

    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 38)
    HeaderBar.BackgroundColor3 = P.SidebarBg
    HeaderBar.BorderSizePixel = 0
    HeaderBar.ZIndex = 2
    HeaderBar.Parent = MainFrame
    round(HeaderBar, UDim.new(0, 12))

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = P.SidebarBg
    headerFix.BorderSizePixel = 0
    headerFix.ZIndex = 2
    headerFix.Parent = HeaderBar

    local logoDot = Instance.new("Frame")
    logoDot.Size = UDim2.new(0, 8, 0, 8)
    logoDot.Position = UDim2.new(0, 14, 0.5, -4)
    logoDot.BackgroundColor3 = P.Accent
    logoDot.BorderSizePixel = 0
    logoDot.ZIndex = 3
    logoDot.Parent = HeaderBar
    round(logoDot, UDim.new(1, 0))
    if AN() then AN().breathe(logoDot, { BackgroundTransparency = 0.65 }, 1.3) end

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Size = UDim2.new(0, 120, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 28, 0, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Text = "PHANTOM"
    HeaderTitle.TextColor3 = P.TextPrimary
    HeaderTitle.Font = Enum.Font.GothamBlack
    HeaderTitle.TextSize = 14
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.ZIndex = 3
    HeaderTitle.Parent = HeaderBar

    local HeaderVersion = Instance.new("TextLabel")
    HeaderVersion.Size = UDim2.new(0, 60, 1, 0)
    HeaderVersion.Position = UDim2.new(0, 105, 0, 0)
    HeaderVersion.BackgroundTransparency = 1
    HeaderVersion.Text = "v" .. tostring(env.Version or "")
    HeaderVersion.TextColor3 = P.Accent
    HeaderVersion.Font = Enum.Font.GothamBold
    HeaderVersion.TextSize = 10
    HeaderVersion.TextXAlignment = Enum.TextXAlignment.Left
    HeaderVersion.ZIndex = 3
    HeaderVersion.Parent = HeaderBar

    local SearchBoxBg = Instance.new("Frame")
    SearchBoxBg.Size = UDim2.new(0, 180, 0, 24)
    SearchBoxBg.Position = UDim2.new(0.5, -90, 0.5, -12)
    SearchBoxBg.BackgroundColor3 = P.ContentBg
    SearchBoxBg.ZIndex = 3
    SearchBoxBg.Parent = HeaderBar
    round(SearchBoxBg, UDim.new(0, 12))
    local searchStroke = AddStroke(SearchBoxBg, P.Outline, 1)

    local sicon = Instance.new("TextLabel")
    sicon.Size = UDim2.new(0, 18, 1, 0)
    sicon.Position = UDim2.new(0, 5, 0, 0)
    sicon.BackgroundTransparency = 1
    sicon.Text = "🔍"
    sicon.TextSize = 10
    sicon.Font = Enum.Font.Gotham
    sicon.TextColor3 = P.TextSecondary
    sicon.ZIndex = 4
    sicon.Parent = SearchBoxBg

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -26, 1, -2)
    SearchBox.Position = UDim2.new(0, 22, 0, 1)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Text = ""
    SearchBox.PlaceholderText = "Search features..."
    SearchBox.TextColor3 = P.TextPrimary
    SearchBox.PlaceholderColor3 = P.TextSecondary
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 11
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.ZIndex = 4
    SearchBox.Parent = SearchBoxBg
    SearchBox.Focused:Connect(function() searchStroke.Color = P.Accent; searchStroke.Thickness = 1.5 end)
    SearchBox.FocusLost:Connect(function() searchStroke.Color = P.Outline; searchStroke.Thickness = 1 end)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -11)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = P.Red
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 11
    CloseBtn.ZIndex = 3
    CloseBtn.Parent = HeaderBar
    round(CloseBtn, UDim.new(1, 0))
    CloseBtn.MouseButton1Click:Connect(function()
        local an = AN()
        if an then an.popOut(MainFrame) else MainFrame.Visible = false end
    end)

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, 0)
    headerLine.BackgroundColor3 = P.Outline
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 2
    headerLine.Parent = HeaderBar

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BackgroundColor3 = Color3.new(1, 1, 1)
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 3
    accentLine.Parent = HeaderBar
    local accentGrad = Instance.new("UIGradient")
    accentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.Outline),
        ColorSequenceKeypoint.new(0.42, P.Outline),
        ColorSequenceKeypoint.new(0.5, P.Accent),
        ColorSequenceKeypoint.new(0.58, P.Outline),
        ColorSequenceKeypoint.new(1, P.Outline),
    })
    accentGrad.Parent = accentLine
    if AN() then AN().shimmer(accentGrad, 3) end

    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    local dragWarningCooldown = false

    local function savePos()
        settings.MainFramePos = {
            X = MainFrame.Position.X.Scale, XOff = MainFrame.Position.X.Offset,
            Y = MainFrame.Position.Y.Scale, YOff = MainFrame.Position.Y.Offset,
        }
        saveSettings()
    end

    HeaderBar.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging, dragStart, startPos = true, input.Position, MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and dragging then
                    dragging = false
                    savePos()
                end
            end)
        end
    end)

    HeaderBar.InputChanged:Connect(function(input)
        if isMove(input) then dragInput = input end
    end)

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input ~= dragInput or not dragging then return end
        local delta = input.Position - dragStart
        if settings["🔒 Lock GUI Drag"] == true then
            if not dragWarningCooldown and delta.Magnitude > 10 then
                dragWarningCooldown = true
                Skin.SendNotification("Disable lock gui first", P.Red)
                task.delay(1.5, function() dragWarningCooldown = false end)
                dragging = false
            end
            return
        end
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end))

    local MAIN_MIN_W, MAIN_MIN_H = 400, 280
    local MAIN_MAX_W, MAIN_MAX_H = 1100, 800

    local MainResizeBtn = Instance.new("TextButton")
    MainResizeBtn.Name = "ResizeHandle"
    MainResizeBtn.Size = UDim2.new(0, 20, 0, 20)
    MainResizeBtn.AnchorPoint = Vector2.new(1, 1)
    MainResizeBtn.Position = UDim2.new(1, -4, 1, -4)
    MainResizeBtn.BackgroundTransparency = 1
    MainResizeBtn.Text = ""
    MainResizeBtn.ZIndex = 5
    MainResizeBtn.Parent = MainFrame

    local rArrow1 = Instance.new("TextLabel")
    rArrow1.Size = UDim2.new(0, 14, 0, 14)
    rArrow1.Position = UDim2.new(0, 0, 0, 0)
    rArrow1.BackgroundTransparency = 1
    rArrow1.Text = "↖"
    rArrow1.TextColor3 = P.TextSecondary
    rArrow1.Font = Enum.Font.GothamBold
    rArrow1.TextSize = 12
    rArrow1.ZIndex = 6
    rArrow1.Parent = MainResizeBtn

    local rArrow2 = Instance.new("TextLabel")
    rArrow2.Size = UDim2.new(0, 14, 0, 14)
    rArrow2.AnchorPoint = Vector2.new(1, 1)
    rArrow2.Position = UDim2.new(1, 0, 1, 0)
    rArrow2.BackgroundTransparency = 1
    rArrow2.Text = "↘"
    rArrow2.TextColor3 = P.TextSecondary
    rArrow2.Font = Enum.Font.GothamBold
    rArrow2.TextSize = 12
    rArrow2.ZIndex = 6
    rArrow2.Parent = MainResizeBtn

    MainResizeBtn.MouseEnter:Connect(function()
        rArrow1.TextColor3 = P.Accent
        rArrow2.TextColor3 = P.Accent
    end)
    MainResizeBtn.MouseLeave:Connect(function()
        rArrow1.TextColor3 = P.TextSecondary
        rArrow2.TextColor3 = P.TextSecondary
    end)

    local mainResizing, mainResizeDragStart, mainResizeStartSize = false, nil, nil

    MainResizeBtn.InputBegan:Connect(function(input)
        if isPress(input) then
            mainResizing = true
            mainResizeDragStart = input.Position
            mainResizeStartSize = MainFrame.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and mainResizing then
                    mainResizing = false
                    settings.MainFrameSize = { W = MainFrame.AbsoluteSize.X, H = MainFrame.AbsoluteSize.Y }
                    saveSettings()
                end
            end)
        end
    end)

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if mainResizing and isMove(input) then
            local delta = input.Position - mainResizeDragStart
            local newW = math.clamp(mainResizeStartSize.X + delta.X, MAIN_MIN_W, MAIN_MAX_W)
            local newH = math.clamp(mainResizeStartSize.Y + delta.Y, MAIN_MIN_H, MAIN_MAX_H)
            MainFrame.Size = UDim2.new(0, newW, 0, newH)
            task.defer(function()
                local reg = layoutRegistry()
                if reg then
                    for _, refreshFn in pairs(reg) do pcall(refreshFn) end
                end
            end)
        end
    end))

    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 62, 1, -39)
    SideBar.Position = UDim2.new(0, 0, 0, 39)
    SideBar.BackgroundColor3 = P.SidebarBg
    SideBar.BorderSizePixel = 0
    SideBar.Parent = MainFrame

    local sidebarRightLine = Instance.new("Frame")
    sidebarRightLine.Size = UDim2.new(0, 1, 1, 0)
    sidebarRightLine.Position = UDim2.new(1, -1, 0, 0)
    sidebarRightLine.BackgroundColor3 = P.Outline
    sidebarRightLine.BorderSizePixel = 0
    sidebarRightLine.Parent = SideBar

    local TabButtonsContainer = Instance.new("ScrollingFrame")
    TabButtonsContainer.Size = UDim2.new(1, 0, 1, -4)
    TabButtonsContainer.Position = UDim2.new(0, 0, 0, 4)
    TabButtonsContainer.BackgroundTransparency = 1
    TabButtonsContainer.ScrollBarThickness = 0
    TabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabButtonsContainer.Parent = SideBar
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabButtonsContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 3)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -63, 1, -39)
    ContentArea.Position = UDim2.new(0, 63, 0, 39)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame
    local ContentPad = Instance.new("UIPadding")
    ContentPad.PaddingTop = UDim.new(0, 12)
    ContentPad.PaddingBottom = UDim.new(0, 12)
    ContentPad.PaddingLeft = UDim.new(0, 12)
    ContentPad.PaddingRight = UDim.new(0, 12)
    ContentPad.Parent = ContentArea

    local Frames = {}
    local tabOfFrame = {}
    local currentTab, currentFrame = nil, nil

    do
        local an = AN()
        if an then
            an.watchOpen(MainFrame, function()
                if currentFrame then an.stagger(currentFrame) end
            end)
        end
    end

    function S.CreatePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name .. "Frame"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = P.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Parent = ContentArea
        Skin.createLayout(page)
        Frames[name] = page
        return page
    end

    local SearchResultsFrame = S.CreatePage("SearchResults")

    local function applyTabButtonVisuals(activeBtn)
        for _, child in pairs(TabButtonsContainer:GetChildren()) do
            if child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1 }):Play()
                local ic = child:FindFirstChild("Icon"); if ic then TweenService:Create(ic, TweenInfo.new(0.18), { TextColor3 = P.TextSecondary }):Play() end
                local lb = child:FindFirstChild("Lbl"); if lb then TweenService:Create(lb, TweenInfo.new(0.18), { TextColor3 = P.TextSecondary }):Play() end
                local bar = child:FindFirstChild("Bar"); if bar then TweenService:Create(bar, TweenInfo.new(0.18), { Size = UDim2.new(0, 2, 0, 0), BackgroundTransparency = 1 }):Play() end
                local ic2 = child:FindFirstChild("Icon"); if ic2 then TweenService:Create(ic2, TweenInfo.new(0.2), { TextSize = 16 }):Play() end
            end
        end
        TweenService:Create(activeBtn, TweenInfo.new(0.18), { BackgroundColor3 = P.ContentBg, BackgroundTransparency = 0 }):Play()
        local ic = activeBtn:FindFirstChild("Icon"); if ic then TweenService:Create(ic, TweenInfo.new(0.18), { TextColor3 = P.Accent }):Play() end
        local lb = activeBtn:FindFirstChild("Lbl"); if lb then TweenService:Create(lb, TweenInfo.new(0.18), { TextColor3 = P.Accent }):Play() end
        local bar = activeBtn:FindFirstChild("Bar")
        if bar then
            TweenService:Create(bar, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 2, 0.55, 0) }):Play()
            TweenService:Create(bar, TweenInfo.new(0.18), { BackgroundTransparency = 0 }):Play()
        end
        local ic3 = activeBtn:FindFirstChild("Icon")
        if ic3 then TweenService:Create(ic3, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextSize = 20 }):Play() end
        currentTab = activeBtn
    end

    function S.SwitchTab(btn, frame)
        if not btn or not frame then return end

        if currentTab == btn and frame.Visible then return end
        applyTabButtonVisuals(btn)
        currentFrame = frame

        for _, f in pairs(Frames) do
            if f == frame then
                f.Visible = true
                f.Position = UDim2.new(0, 0, 0, 22)
                TweenService:Create(f, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
                if AN() then AN().stagger(f) end

                task.defer(function()
                    local reg = layoutRegistry()
                    local refreshFn = reg and reg[f]
                    if refreshFn then pcall(refreshFn) end
                end)
            else
                f.Visible = false
            end
        end
    end

    function S.CreateTabButton(iconText, labelText, frame)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 54, 0, 46)
        btn.BackgroundColor3 = P.SidebarBg
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = TabButtonsContainer
        round(btn, UDim.new(0, 8))
        if AN() then AN().bindRipple(btn, P.Accent) end

        local bar = Instance.new("Frame")
        bar.Name = "Bar"
        bar.Size = UDim2.new(0, 2, 0, 0)
        bar.AnchorPoint = Vector2.new(0, 0.5)
        bar.Position = UDim2.new(0, 0, 0.5, 0)
        bar.BackgroundColor3 = P.Accent
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.Parent = btn
        round(bar, UDim.new(1, 0))

        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(1, 0, 0, 22)
        icon.Position = UDim2.new(0, 0, 0, 5)
        icon.BackgroundTransparency = 1
        icon.Text = tostring(iconText or "")
        icon.TextColor3 = P.TextSecondary
        icon.Font = Enum.Font.Gotham
        icon.TextSize = 16
        icon.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Lbl"
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.Position = UDim2.new(0, 0, 0, 28)
        lbl.BackgroundTransparency = 1
        lbl.Text = tostring(labelText or "")
        lbl.TextColor3 = P.TextSecondary
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 7
        lbl.Parent = btn

        if frame then tabOfFrame[frame] = btn end

        btn.MouseEnter:Connect(function()
            if btn ~= currentTab then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = P.ItemHover, BackgroundTransparency = 0 }):Play() end
        end)
        btn.MouseLeave:Connect(function()
            if btn ~= currentTab then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = P.SidebarBg, BackgroundTransparency = 1 }):Play() end
        end)
        btn.MouseButton1Click:Connect(function() S.SwitchTab(btn, frame) end)
        return btn
    end

    local preSearchTab, preSearchFrame = nil, nil
    local searching = false

    local function setTabButtonsVisible(state)
        for _, ch in pairs(TabButtonsContainer:GetChildren()) do
            if ch:IsA("TextButton") then ch.Visible = state end
        end
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower()

        if query == "" then
            searching = false
            SearchResultsFrame.Visible = false
            setTabButtonsVisible(true)
            if preSearchTab and preSearchFrame then
                S.SwitchTab(preSearchTab, preSearchFrame)
            end
            return
        end

        if not searching then
            searching = true
            preSearchTab, preSearchFrame = currentTab, currentFrame
        end

        for _, fr in pairs(Frames) do fr.Visible = false end
        SearchResultsFrame.Visible = true
        setTabButtonsVisible(false)

        for _, c in pairs(SearchResultsFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        local headerLbl = Instance.new("TextLabel")
        headerLbl.Size = UDim2.new(0.96, 0, 0, 28)
        headerLbl.BackgroundTransparency = 1
        headerLbl.Text = '🔍  "' .. SearchBox.Text .. '"'
        headerLbl.TextColor3 = P.TextSecondary
        headerLbl.Font = Enum.Font.GothamMedium
        headerLbl.TextSize = 11
        headerLbl.TextXAlignment = Enum.TextXAlignment.Left
        headerLbl.Parent = SearchResultsFrame

        local rcount = 0
        local feats = env.GetFeatures and env.GetFeatures() or {}
        for _, feat in ipairs(feats) do
            if ((feat.n or "") .. " " .. (feat.d or "")):lower():find(query, 1, true) then
                rcount = rcount + 1
                local capFeat = feat
                local capFrame = feat.f

                local rawName = (capFrame and capFrame.Name or "?"):gsub("Frame", "")
                local tabDisplayName = (TAB_LABELS[rawName] or "") .. " " .. rawName

                local row = Instance.new("TextButton")
                row.Size = UDim2.new(0.96, 0, 0, 62)
                row.BackgroundColor3 = P.ContentBg
                row.Text = ""
                row.AutoButtonColor = false
                row.Parent = SearchResultsFrame
                round(row, UDim.new(0, 8))
                local rowStroke = AddStroke(row, P.Outline, 1)
                if AN() then AN().bindRipple(row, P.Accent) end

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -90, 0, 22)
                nameLbl.Position = UDim2.new(0, 10, 0, 8)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = feat.n or ""
                nameLbl.TextColor3 = P.TextPrimary
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 13
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextWrapped = true
                nameLbl.Parent = row

                local descLbl2 = Instance.new("TextLabel")
                descLbl2.Size = UDim2.new(1, -90, 0, 18)
                descLbl2.Position = UDim2.new(0, 10, 0, 33)
                descLbl2.BackgroundTransparency = 1
                descLbl2.Text = feat.d or ""
                descLbl2.TextColor3 = P.TextSecondary
                descLbl2.Font = Enum.Font.Gotham
                descLbl2.TextSize = 11
                descLbl2.TextXAlignment = Enum.TextXAlignment.Left
                descLbl2.TextWrapped = true
                descLbl2.Parent = row

                local badge = Instance.new("TextLabel")
                badge.Size = UDim2.new(0, 74, 0, 20)
                badge.Position = UDim2.new(1, -80, 0, 8)
                badge.BackgroundColor3 = P.SidebarBg
                badge.Text = tabDisplayName
                badge.TextColor3 = P.Accent
                badge.Font = Enum.Font.GothamBold
                badge.TextSize = 9
                badge.TextTruncate = Enum.TextTruncate.AtEnd
                badge.Parent = row
                round(badge, UDim.new(0, 4))
                AddStroke(badge, P.Accent, 1)

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 20, 0, 20)
                arrow.Position = UDim2.new(1, -26, 1, -28)
                arrow.BackgroundTransparency = 1
                arrow.Text = "→"
                arrow.TextColor3 = P.Accent
                arrow.Font = Enum.Font.GothamBold
                arrow.TextSize = 14
                arrow.Parent = row

                row.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = P.ItemHover }):Play()
                    TweenService:Create(rowStroke, TweenInfo.new(0.15), { Color = P.Accent }):Play()
                end)
                row.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = P.ContentBg }):Play()
                    TweenService:Create(rowStroke, TweenInfo.new(0.15), { Color = P.Outline }):Play()
                end)

                row.MouseButton1Click:Connect(function()
                    local tabBtn = capFrame and tabOfFrame[capFrame]
                    if tabBtn then preSearchTab = tabBtn end
                    if capFrame then preSearchFrame = capFrame end
                    SearchBox.Text = ""
                    task.spawn(function()
                        if not capFrame then return end

                        local layout = capFrame:FindFirstChildOfClass("UIListLayout")
                        if layout then
                            local deadline = tick() + 2
                            while layout.AbsoluteContentSize.Y == 0 and tick() < deadline do
                                task.wait()
                            end
                        end
                        task.wait()

                        for _, child in ipairs(capFrame:GetChildren()) do
                            if child:IsA("Frame") or child:IsA("TextButton") then
                                local found = false
                                for _, lbl in ipairs(child:GetDescendants()) do
                                    if lbl:IsA("TextLabel") and lbl.Text == capFeat.n then
                                        found = true
                                        break
                                    end
                                end
                                if found then
                                    local relY = child.AbsolutePosition.Y - capFrame.AbsolutePosition.Y + capFrame.CanvasPosition.Y
                                    capFrame.CanvasPosition = Vector2.new(0, math.max(0, relY - 10))
                                    local origBg = child.BackgroundColor3
                                    TweenService:Create(child, TweenInfo.new(0.18), { BackgroundColor3 = P.Accent }):Play()
                                    task.wait(0.4)
                                    if child.Parent then
                                        TweenService:Create(child, TweenInfo.new(0.35), { BackgroundColor3 = origBg }):Play()
                                    end
                                    break
                                end
                            end
                        end
                    end)
                end)
            end
        end

        if rcount == 0 then
            local noR = Instance.new("TextLabel")
            noR.Size = UDim2.new(0.96, 0, 0, 50)
            noR.BackgroundTransparency = 1
            noR.Text = '😕  No results for "' .. SearchBox.Text .. '"'
            noR.TextColor3 = P.TextSecondary
            noR.Font = Enum.Font.GothamMedium
            noR.TextSize = 13
            noR.Parent = SearchResultsFrame
        end

        SearchResultsFrame.CanvasSize = UDim2.new(0, 0, 0, 28 + rcount * 68 + 20)
        if AN() then AN().stagger(SearchResultsFrame, 0.025) end
    end)

    return S
end

return Skin
