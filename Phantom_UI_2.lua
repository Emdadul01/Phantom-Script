local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Skin = { Name = "Folio" }
local Env, P

local FONT_HEAD = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham
local FONT_SEMI = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right
local CENTER = Enum.TextXAlignment.Center
local WHITE = Color3.new(1, 1, 1)

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end

local function pill(o)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = o
    return c
end

local function outline(o, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function grad(o, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    g.Parent = o
    return g
end

local function tween(o, dur, props, style, dir)
    if not o or not o.Parent then return end
    local an = Env and Env.Anim
    if an and not an.on() then
        for k, v in pairs(props) do o[k] = v end
        return
    end
    TweenService:Create(o, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
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

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shift(c, dh)
    local h, s, v = c:ToHSV()
    return Color3.fromHSV((h + dh) % 1, s, v)
end

local function acc2()
    return (P and P.Accent2) or (P and P.Accent) or WHITE
end

local function tidy(s)
    s = tostring(s or "")
    local t = s:gsub("^[^%w%(%[\"']+", "")
    t = trim((t:gsub("%s+", " ")))
    if t == "" then t = trim(s) end
    if not t:find("%l") then
        local first = true
        t = t:gsub("%a[%w']*", function(w)
            if #w <= 3 then
                first = false
                return w
            end
            local lower = w:lower()
            if first then
                first = false
                return lower:sub(1, 1):upper() .. lower:sub(2)
            end
            return lower
        end)
    end
    return t
end

local function splitIcon(s)
    s = tostring(s or "")
    local pre = s:match("^([^%w%(%[\"']+)") or ""
    pre = trim(pre)
    if #pre > 0 and #pre <= 16 and pre:find("[\128-\255]") then return pre end
    return nil
end

local function label(props, parent)
    props.BackgroundTransparency = 1
    props.BorderSizePixel = 0
    if props.TextXAlignment == nil then props.TextXAlignment = LEFT end
    return make("TextLabel", props, parent)
end

local Rows = {}
local function norm(s)
    return tidy(s):lower()
end
local function registerRow(row, ...)
    for _, name in ipairs({ ... }) do
        if type(name) == "string" and name ~= "" then
            Rows[#Rows + 1] = { key = norm(name), row = row }
        end
    end
    if #Rows > 600 then
        local keep = {}
        for _, r in ipairs(Rows) do
            if r.row and r.row.Parent then keep[#keep + 1] = r end
        end
        Rows = keep
    end
end
local function findRow(name, page)
    local key = norm(name)
    local any
    for _, r in ipairs(Rows) do
        if r.key == key and r.row and r.row.Parent then
            if page and r.row:IsDescendantOf(page) then return r.row end
            any = any or r.row
        end
    end
    if any then return any end

    if page then
        for _, r in ipairs(Rows) do
            if r.row and r.row.Parent and r.row:IsDescendantOf(page)
                and (r.key:find(key, 1, true) or key:find(r.key, 1, true)) then
                return r.row
            end
        end

        for _, d in ipairs(page:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" and norm(d.Text) == key then
                local c = d
                while c.Parent and c.Parent ~= page do c = c.Parent end
                if c.Parent == page then
                    if c:IsA("Frame") and c.BackgroundTransparency >= 1 then
                        local inner = c:FindFirstChildWhichIsA("TextButton")
                        if inner then return inner end
                    end
                    return c
                end
            end
        end
    end
    return nil
end

function Skin.MakeTheme(base, themeName)
    local c = Color3.fromRGB
    local T = {}

    if type(base) == "table" then
        for k, v in pairs(base) do T[k] = v end
    end
    T.MainBg = c(12, 14, 20)
    T.SidebarBg = c(19, 22, 31)
    T.ContentBg = c(25, 29, 40)
    T.ItemHover = c(34, 39, 54)
    T.Outline = c(46, 53, 72)
    T.TextPrimary = c(236, 240, 250)
    T.TextSecondary = c(136, 146, 170)
    T.Accent = c(146, 112, 255)
    T.Red = c(255, 98, 116)
    T.Green = c(96, 226, 164)
    T.Yellow = c(255, 205, 96)

    if themeName and themeName ~= "Phantom Ultimate 8.8" and themeName ~= "Phantom Ultimate 5.0"
        and type(base) == "table" and base.Accent then
        T.Accent = base.Accent
    end
    T.Accent2 = shift(T.Accent, -0.08)
    return T
end

function Skin.createLayout(parent)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 6)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.Parent = parent
    if parent:IsA("ScrollingFrame") then
        local function refresh()
            parent.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 16)
        end
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
        refresh()
    end
    return l
end

function Skin.createSectionHeader(parent, text)
    local row = make("Frame", { Name = "PhHeader", Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    local mark = make("Frame", {
        Position = UDim2.new(0, 2, 0, 12), Size = UDim2.new(0, 3, 0, 12), BackgroundColor3 = P.Accent, BorderSizePixel = 0,
    }, row)
    pill(mark)
    label({
        Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -16, 0, 18),
        Text = tidy(text):upper(), Font = FONT_BOLD, TextSize = 11, TextColor3 = P.Accent,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local line = make("Frame", {
        Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = P.Outline, BackgroundTransparency = 0.45, BorderSizePixel = 0,
    }, row)
    return row
end

function Skin.createToggleSwitch(parent, text, description, callback, externalControl, noSave)
    local obj, isOn = {}, false

    local row = make("TextButton", {
        Size = UDim2.new(1, -8, 0, 54), BackgroundColor3 = P.ContentBg, AutoButtonColor = false,
        Text = "", BorderSizePixel = 0,
    }, parent)
    corner(row, 10)
    local rowLine = outline(row, P.Outline, 1)
    rowLine.Transparency = 0.5
    if AN() then AN().bindRipple(row, P.Accent) end

    label({
        Position = UDim2.new(0, 14, 0, 9), Size = UDim2.new(1, -140, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 14, 0, 29), Size = UDim2.new(1, -140, 0, 16), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local track = make("Frame", {
        Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 44, 0, 24), BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    pill(track)
    local trackGrad = grad(track, P.Accent, acc2(), 0)
    trackGrad.Enabled = false
    local knob = make("Frame", {
        Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = P.TextSecondary, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    pill(knob)

    local hovering = false
    local function paint(instant)
        local pos = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local kc = isOn and WHITE or P.TextSecondary
        local tc = isOn and WHITE or P.Outline
        trackGrad.Enabled = isOn
        if instant then
            knob.Position, knob.BackgroundColor3 = pos, kc
            track.BackgroundColor3 = tc
        else
            if isOn then row.BackgroundColor3 = P.ContentBg:Lerp(P.Accent, 0.35) end
            tween(row, 0.55, { BackgroundColor3 = hovering and P.ItemHover or P.ContentBg })
            tween(knob, 0.32, { Position = pos }, Enum.EasingStyle.Back)
            tween(knob, 0.16, { BackgroundColor3 = kc })
            tween(track, 0.2, { BackgroundColor3 = tc })
        end
    end

    local kb = make("TextButton", {
        Name = "KeybindBtn", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -68, 0.5, 0),
        Size = UDim2.new(0, 42, 0, 22), BackgroundColor3 = P.MainBg, BackgroundTransparency = 0.3,
        AutoButtonColor = false, Text = "bind", Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary,
        ZIndex = 2, BorderSizePixel = 0,
    }, row)
    corner(kb, 6)
    local function paintKb()
        local k = Env.Settings.Keybinds and Env.Settings.Keybinds[text]
        if k and k.key then
            kb.Text = (k.ctrl and "^" or "") .. tostring(k.key)
            kb.TextColor3, kb.Font = P.Accent, FONT_BOLD
        else
            kb.Text = "bind"
            kb.TextColor3, kb.Font = P.TextSecondary, FONT_BODY
        end
    end
    paintKb()
    kb.MouseButton1Click:Connect(function()
        local open = Env.GetOpenKeybindPopup and Env.GetOpenKeybindPopup()
        if open then open(text, paintKb, obj) end
    end)

    row.MouseEnter:Connect(function() hovering = true; tween(row, 0.12, { BackgroundColor3 = P.ItemHover }) end)
    row.MouseLeave:Connect(function() hovering = false; tween(row, 0.12, { BackgroundColor3 = P.ContentBg }) end)

    local function commit()
        if not noSave then
            Env.Settings[text] = isOn
            Env.saveSettings()
        end
    end

    row.MouseButton1Click:Connect(function()
        isOn = not isOn
        paint(false)
        task.spawn(function() callback(isOn) end)
        commit()
    end)

    function obj:SetState(state)
        if isOn ~= state then
            isOn = state
            paint(false)
            if not externalControl then task.spawn(function() callback(isOn) end) end
            commit()
        end
    end
    function obj:Toggle()
        isOn = not isOn
        paint(false)
        task.spawn(function() callback(isOn) end)
        commit()
    end
    function obj:GetState() return isOn end

    registerRow(row, text)
    local registry = Env.GetKeybinds and Env.GetKeybinds()
    if registry then registry[text] = obj end

    if not noSave and Env.Settings[text] ~= nil then
        isOn = Env.Settings[text]
        paint(true)
        if not externalControl then task.spawn(function() callback(isOn) end) end
    end
    return obj
end

function Skin.createSlider(parent, text, description, minVal, maxVal, defaultVal, callback, noSave)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 66), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 10)
    local rowLine = outline(row, P.Outline, 1)
    rowLine.Transparency = 0.5

    label({
        Position = UDim2.new(0, 14, 0, 9), Size = UDim2.new(1, -112, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 14, 0, 27), Size = UDim2.new(1, -112, 0, 14), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local valueBox = make("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0, 72, 0, 24),
        BackgroundColor3 = P.MainBg, BackgroundTransparency = 0.25, Text = "", ClearTextOnFocus = false,
        Font = FONT_BOLD, TextSize = 13, TextColor3 = P.Accent, TextXAlignment = CENTER, BorderSizePixel = 0,
    }, row)
    corner(valueBox, 7)

    local hit = make("Frame", { Position = UDim2.new(0, 14, 0, 44), Size = UDim2.new(1, -28, 0, 18), BackgroundTransparency = 1, Active = true }, row)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, hit)
    pill(track)
    local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
    pill(fill)
    grad(fill, P.Accent, acc2(), 0)
    local handle = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 16, 0, 16),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    pill(handle)
    outline(handle, P.Accent, 2)

    local currentVal = (not noSave and Env.Settings[text]) or defaultVal
    local ready = false

    local function setSlider(val)
        val = math.clamp(tonumber(val) or currentVal, minVal, maxVal)
        local pos = (maxVal == minVal) and 0 or (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        handle.Position = UDim2.new(pos, 0, 0.5, 0)
        valueBox.Text = tostring(val)
        if ready then
            if noSave then
                callback(val)
            elseif Env.Settings[text] ~= val then
                Env.Settings[text] = val
                Env.saveSettings()
                callback(val)
            end
        end
        currentVal = val
    end

    valueBox.FocusLost:Connect(function()
        local n = tonumber(valueBox.Text)
        if n then setSlider(n) else valueBox.Text = tostring(currentVal) end
    end)

    local dragging = false
    local scroller = nil
    local function release()
        dragging = false
        if scroller then
            scroller.ScrollingEnabled = true
            scroller = nil
        end
        tween(handle, 0.18, { Size = UDim2.new(0, 16, 0, 16) }, Enum.EasingStyle.Back)
    end
    local function fromInput(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        setSlider(math.floor(minVal + (maxVal - minVal) * rel))
    end

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true

            scroller = row:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scroller then scroller.ScrollingEnabled = false end
            tween(handle, 0.14, { Size = UDim2.new(0, 20, 0, 20) }, Enum.EasingStyle.Back)
            fromInput(input)
        end
    end)
    local c1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then
            fromInput(input)
        end
    end)
    local c2 = UserInputService.InputEnded:Connect(function(input)
        if isPress(input) and dragging then
            release()
        end
    end)
    row.Destroying:Connect(function()
        if c1 then c1:Disconnect() c1 = nil end
        if c2 then c2:Disconnect() c2 = nil end
        if scroller then scroller.ScrollingEnabled = true scroller = nil end
        dragging = false
    end)

    registerRow(row, text)
    setSlider(currentVal)
    ready = true
    if not noSave and Env.Settings[text] ~= nil then
        task.spawn(function() callback(currentVal) end)
    end
end

function Skin.createButton(parent, text, description, color, callback)
    local accent = color or P.Accent
    local holder = make("Frame", { Size = UDim2.new(1, -8, 0, 50), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = P.ContentBg, AutoButtonColor = false, Text = "",
        BorderSizePixel = 0,
    }, holder)
    corner(btn, 10)
    if AN() then AN().bindRipple(btn, accent) end
    local btnLine = outline(btn, P.Outline, 1)
    btnLine.Transparency = 0.5

    local chip = make("Frame", {
        Position = UDim2.new(0, 10, 0.5, -16), Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = accent, BackgroundTransparency = 0.82, BorderSizePixel = 0,
    }, btn)
    corner(chip, 9)
    local ic = splitIcon(text)
    if ic then
        label({ Size = UDim2.new(1, 0, 1, 0), Text = ic, Font = FONT_BODY, TextSize = 16, TextColor3 = accent, TextXAlignment = CENTER }, chip)
    else
        local dot = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = accent, BorderSizePixel = 0,
        }, chip)
        pill(dot)
    end

    local hasDesc = description ~= nil and description ~= ""
    label({
        Position = UDim2.new(0, 52, 0, hasDesc and 8 or 16), Size = UDim2.new(1, -90, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    if hasDesc then
        label({
            Position = UDim2.new(0, 52, 0, 27), Size = UDim2.new(1, -90, 0, 16), Text = description,
            Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
        }, btn)
    end
    label({
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -1), Size = UDim2.new(0, 16, 0, 24),
        Text = "\226\128\186", Font = FONT_BOLD, TextSize = 20, TextColor3 = P.TextSecondary, TextXAlignment = CENTER,
    }, btn)

    btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = P.ItemHover }) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = P.ContentBg }) end)
    btn.InputBegan:Connect(function(input)
        if isPress(input) then tween(btn, 0.06, { BackgroundColor3 = P.Outline }) end
    end)
    btn.InputEnded:Connect(function(input)
        if isPress(input) then tween(btn, 0.12, { BackgroundColor3 = P.ItemHover }) end
    end)
    registerRow(btn, text)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function Skin.createTextBox(parent, placeholder, description, callback)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 10)
    local rowLine = outline(row, P.Outline, 1)
    rowLine.Transparency = 0.5
    label({
        Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(1, -28, 0, 16), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local field = make("Frame", {
        Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = P.MainBg, BorderSizePixel = 0,
    }, row)
    corner(field, 8)
    local fieldLine = outline(field, P.Outline, 1)
    local box = make("TextBox", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
        Text = "", PlaceholderText = tidy(placeholder), PlaceholderColor3 = P.TextSecondary,
        TextColor3 = P.TextPrimary, Font = FONT_BODY, TextSize = 13, TextXAlignment = LEFT,
        ClearTextOnFocus = false, BorderSizePixel = 0,
    }, field)
    registerRow(row, placeholder, description)
    box.Focused:Connect(function() fieldLine.Color = P.Accent end)
    box.FocusLost:Connect(function()
        fieldLine.Color = P.Outline
        if callback then callback(box.Text) end
    end)
    return box
end

function Skin.createConfirmation(_, text, onYes)
    local shell = Skin.Shell
    if not shell or not shell.MainFrame then return end
    local overlay = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
        AutoButtonColor = false, Text = "", ZIndex = 200, BorderSizePixel = 0,
    }, shell.MainFrame)
    tween(overlay, 0.22, { BackgroundTransparency = 0.4 })
    local panel = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 310, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 201,
    }, overlay)
    corner(panel, 14)
    outline(panel, P.Outline, 1)
    if AN() then AN().scaleIn(panel, 0.82, 0.34) end
    make("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, panel)
    make("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

    label({
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tidy(text), TextWrapped = true,
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, ZIndex = 202, LayoutOrder = 1,
    }, panel)

    local buttons = make("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 202, LayoutOrder = 2 }, panel)
    local function pillBtn(txt, x, fillCol, textCol)
        local b = make("TextButton", {
            Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = fillCol, AutoButtonColor = false, Text = txt, Font = FONT_BOLD, TextSize = 13,
            TextColor3 = textCol, ZIndex = 203, BorderSizePixel = 0,
        }, buttons)
        corner(b, 10)
        return b
    end
    local no = pillBtn("Cancel", 0, P.ContentBg, P.TextPrimary)
    local yes = pillBtn("Confirm", 0.5, P.Accent, WHITE)
    no.MouseButton1Click:Connect(function() overlay:Destroy() end)
    yes.MouseButton1Click:Connect(function()
        overlay:Destroy()
        onYes()
    end)
end

local toastHost
local toasts = {}

function Skin.SendNotification(text, color)
    if not toastHost or not toastHost.Parent then return end
    local accent = color or P.Accent

    local toast = make("Frame", {
        Size = UDim2.new(0, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.SidebarBg,
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toastHost)
    pill(toast)
    local frame = outline(toast, accent, 1)
    frame.Transparency = 1
    make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18) }, toast)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
    }, toast)
    local dot = make("Frame", { Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1 }, toast)
    pill(dot)
    local msg = label({
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = tidy(text),
        Font = FONT_SEMI, TextSize = 13, TextColor3 = P.TextPrimary, TextTransparency = 1, LayoutOrder = 2,
    }, toast)

    if AN() then AN().scaleIn(toast, 0.8, 0.32) end
    table.insert(toasts, toast)
    while #toasts > 4 do
        local old = table.remove(toasts, 1)
        if old and old.Parent then old:Destroy() end
    end

    tween(toast, 0.2, { BackgroundTransparency = 0.05 })
    tween(dot, 0.2, { BackgroundTransparency = 0 })
    tween(msg, 0.2, { TextTransparency = 0 })
    tween(frame, 0.2, { Transparency = 0.35 })

    task.delay(2.8, function()
        if not toast.Parent then return end
        tween(toast, 0.25, { BackgroundTransparency = 1 })
        tween(dot, 0.25, { BackgroundTransparency = 1 })
        tween(msg, 0.25, { TextTransparency = 1 })
        tween(frame, 0.25, { Transparency = 1 })
        task.wait(0.3)
        local i = table.find(toasts, toast)
        if i then table.remove(toasts, i) end
        if toast.Parent then toast:Destroy() end
    end)
end

local RAIL_C, RAIL_E = 56, 164

function Skin.Mount(env)
    Env, P = env, env.Theme
    toasts = {}
    Rows = {}

    local S = {}
    Skin.Shell = S
    local settings = env.Settings
    local gui = env.ScreenGui

    toastHost = make("Frame", {
        Name = "PhFolioToasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.new(0, 380, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 20000,
    }, gui)
    make("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top,
    }, toastHost)

    local W = (settings.MainFrameSize and settings.MainFrameSize.W) or 580
    local H = (settings.MainFrameSize and settings.MainFrameSize.H) or 350
    local mp = settings.MainFramePos
    local main = make("Frame", {
        Name = "MainFrame", Size = UDim2.new(0, W, 0, H),
        Position = mp and UDim2.new(mp.X, mp.XOff, mp.Y, mp.YOff) or UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = P.MainBg, BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
    }, gui)
    corner(main, 16)
    local mainLine = outline(main, P.Outline, 1)
    mainLine.Transparency = 0.2
    S.MainFrame = main

    local glow = make("Frame", { Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -56, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, main)
    local glowGrad = Instance.new("UIGradient")
    glowGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.Accent),
        ColorSequenceKeypoint.new(0.4, acc2()),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.6, acc2()),
        ColorSequenceKeypoint.new(1, P.Accent),
    })
    glowGrad.Parent = glow
    if AN() then AN().shimmer(glowGrad, 2.8) end

    local function savePos()
        settings.MainFramePos = {
            X = main.Position.X.Scale, XOff = main.Position.X.Offset,
            Y = main.Position.Y.Scale, YOff = main.Position.Y.Offset,
        }
        env.saveSettings()
    end

    local expanded = settings.NavExpanded == true
    local railW = expanded and RAIL_E or RAIL_C

    local pages, tabs, tabOf, tabByBtn = {}, {}, {}, {}
    local current
    local suppress = false
    do
        local an = AN()
        if an then
            an.watchOpen(main, function()
                if current then an.stagger(current.frame) end
            end)
        end
    end

    local rail = make("Frame", {
        Name = "Rail", Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, railW, 1, -16),
        BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
    }, main)
    corner(rail, 12)
    local railLine = outline(rail, P.Outline, 1)
    railLine.Transparency = 0.4

    local right = make("Frame", {
        Name = "Right", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, railW + 16, 0, 0), Size = UDim2.new(1, -(railW + 16), 1, 0),
    }, main)

    local logo = make("TextButton", {
        Name = "Logo", Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1,
        AutoButtonColor = false, Text = "", BorderSizePixel = 0, ZIndex = 3,
    }, rail)
    local logoBg = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, logo)
    corner(logoBg, 12)
    grad(logoBg, P.Accent, acc2(), 45)
    label({
        Size = UDim2.new(1, 0, 1, 0), Text = "P", Font = FONT_HEAD, TextSize = 22, TextColor3 = WHITE,
        TextXAlignment = CENTER, ZIndex = 4,
    }, logo)

    local brandName = label({
        Position = UDim2.new(0, 56, 0, 9), Size = UDim2.new(1, -60, 0, 20), Text = "Phantom",
        Font = FONT_HEAD, TextSize = 15, TextColor3 = P.TextPrimary, TextTransparency = expanded and 0 or 1, ZIndex = 3,
    }, rail)
    local brandVer = label({
        Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -60, 0, 14),
        Text = "v" .. tostring(env.Version or "") .. " \194\183 ui 2.2", Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary,
        TextTransparency = expanded and 0 or 1, ZIndex = 3,
    }, rail)

    local nav = make("ScrollingFrame", {
        Name = "Nav", Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 1, -100), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3,
    }, rail)
    make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, nav)
    make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6) }, nav)

    local chevron = make("TextButton", {
        Name = "Collapse", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -6), Size = UDim2.new(1, -12, 0, 32),
        BackgroundColor3 = P.ItemHover, BackgroundTransparency = 1, AutoButtonColor = false,
        Text = expanded and "\226\128\185" or "\226\128\186", Font = FONT_BOLD, TextSize = 22,
        TextColor3 = P.TextSecondary, BorderSizePixel = 0, ZIndex = 3,
    }, rail)
    corner(chevron, 8)
    chevron.MouseEnter:Connect(function() tween(chevron, 0.1, { BackgroundTransparency = 0.4 }) end)
    chevron.MouseLeave:Connect(function() tween(chevron, 0.1, { BackgroundTransparency = 1 }) end)

    local function applyRail(animate)
        local w = expanded and RAIL_E or RAIL_C
        local tr = expanded and 0 or 1
        local function set(o, props)
            if animate then
                tween(o, 0.2, props)
            else
                for k, v in pairs(props) do o[k] = v end
            end
        end
        set(rail, { Size = UDim2.new(0, w, 1, -16) })
        set(right, { Position = UDim2.new(0, w + 16, 0, 0), Size = UDim2.new(1, -(w + 16), 1, 0) })
        set(brandName, { TextTransparency = tr })
        set(brandVer, { TextTransparency = tr })
        for _, t in ipairs(tabs) do set(t.txt, { TextTransparency = tr }) end
        chevron.Text = expanded and "\226\128\185" or "\226\128\186"
    end
    local function toggleRail()
        expanded = not expanded
        settings.NavExpanded = expanded
        env.saveSettings()
        applyRail(true)
    end
    logo.MouseButton1Click:Connect(toggleRail)
    chevron.MouseButton1Click:Connect(toggleRail)

    local header = make("Frame", { Name = "TitleBand", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, ZIndex = 3 }, right)

    local titleLbl = label({
        Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(1, -270, 0, 24), Text = "",
        Font = FONT_HEAD, TextSize = 20, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3,
    }, header)
    local subLbl = label({
        Position = UDim2.new(0, 6, 0, 33), Size = UDim2.new(1, -270, 0, 14), Text = "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, ZIndex = 3,
    }, header)

    local close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0, 28), Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = P.ContentBg, Text = "\195\151", Font = FONT_BOLD, TextSize = 20, TextColor3 = P.TextSecondary,
        AutoButtonColor = false, ZIndex = 4, BorderSizePixel = 0,
    }, header)
    pill(close)
    close.MouseEnter:Connect(function() tween(close, 0.1, { BackgroundColor3 = P.Red, TextColor3 = WHITE }) end)
    close.MouseLeave:Connect(function() tween(close, 0.1, { BackgroundColor3 = P.ContentBg, TextColor3 = P.TextSecondary }) end)
    close.MouseButton1Click:Connect(function()
        local an = AN()
        if an then an.popOut(main) else main.Visible = false end
    end)

    local searchWrap = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0, 28), Size = UDim2.new(0, 150, 0, 32),
        BackgroundColor3 = P.ContentBg, BorderSizePixel = 0, ZIndex = 3,
    }, header)
    pill(searchWrap)
    local searchLine = outline(searchWrap, P.Outline, 1)
    searchLine.Transparency = 0.4
    label({
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 20, 1, 0), Text = "\240\159\148\141", Font = FONT_BODY,
        TextSize = 12, TextColor3 = P.TextSecondary, TextXAlignment = CENTER, ZIndex = 4,
    }, searchWrap)
    local searchBox = make("TextBox", {
        Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Search", PlaceholderColor3 = P.TextSecondary, TextColor3 = P.TextPrimary,
        Font = FONT_BODY, TextSize = 13, TextXAlignment = LEFT, ClearTextOnFocus = false, ZIndex = 4, BorderSizePixel = 0,
    }, searchWrap)
    searchBox.Focused:Connect(function()
        tween(searchWrap, 0.15, { Size = UDim2.new(0, 210, 0, 32), BackgroundColor3 = P.ItemHover })
        searchLine.Color, searchLine.Transparency = P.Accent, 0
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchWrap, 0.15, { Size = UDim2.new(0, 150, 0, 32), BackgroundColor3 = P.ContentBg })
        searchLine.Color, searchLine.Transparency = P.Outline, 0.4
    end)

    make("Frame", {
        Position = UDim2.new(0, 6, 0, 56), Size = UDim2.new(1, -14, 0, 1), BackgroundColor3 = P.Outline,
        BackgroundTransparency = 0.5, BorderSizePixel = 0,
    }, right)

    local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
    local lockWarned = false
    header.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging, dragStart, startPos = true, input.Position, main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and dragging then
                    dragging = false
                    savePos()
                end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if isMove(input) then dragInput = input end
    end)
    env.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input ~= dragInput or not dragging then return end
        local delta = input.Position - dragStart
        if settings["\240\159\148\146 Lock GUI Drag"] == true then
            if not lockWarned and delta.Magnitude > 10 then
                lockWarned = true
                Skin.SendNotification("Unlock the GUI in Settings before moving it", P.Red)
                task.delay(1.5, function() lockWarned = false end)
                dragging = false
            end
            return
        end
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end))

    local body = make("Frame", {
        Name = "Body", Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, -8, 1, -70),
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
    }, right)

    local function updateSub()
        if not current then return end
        local n = 0
        for _, c in ipairs(current.frame:GetChildren()) do
            if c:IsA("GuiObject") and c.Name ~= "PhHeader" then n = n + 1 end
        end
        subLbl.Text = n .. (n == 1 and " item" or " items")
    end
    local subPending = false
    local function queueSub()
        if subPending then return end
        subPending = true
        task.defer(function()
            subPending = false
            if searchBox.Text == "" then updateSub() end
        end)
    end

    function S.CreatePage(name)
        local page = make("ScrollingFrame", {
            Name = name .. "Frame", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false, ScrollBarThickness = 3, ScrollBarImageColor3 = P.Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, body)
        Skin.createLayout(page)
        pages[name] = page
        page.ChildAdded:Connect(queueSub)
        page.ChildRemoved:Connect(queueSub)
        return page
    end

    local searchPage = S.CreatePage("SearchResults")

    local function paintTabs(active)
        for _, t in ipairs(tabs) do
            local on = (t.btn == active)
            tween(t.btn, 0.14, { BackgroundColor3 = on and P.Accent or P.ItemHover, BackgroundTransparency = on and 0.82 or 1 })
            tween(t.bar, 0.34, { Size = UDim2.new(0, 3, 0, on and 18 or 0) }, on and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
            tween(t.bar, 0.16, { BackgroundTransparency = on and 0 or 1 })
            tween(t.txt, 0.16, { TextColor3 = on and P.TextPrimary or P.TextSecondary })
            tween(t.ico, 0.16, { TextTransparency = on and 0 or 0.45 })
            tween(t.ico, 0.3, { TextSize = on and 22 or 19 }, Enum.EasingStyle.Back)
        end
    end

    function S.SwitchTab(btn, frame)
        if searchBox.Text ~= "" then
            suppress = true
            searchBox.Text = ""
            suppress = false
        end
        paintTabs(btn)
        for _, pg in pairs(pages) do pg.Visible = (pg == frame) end
        frame.Position = UDim2.new(0, 0, 0, 18)
        tween(frame, 0.36, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
        local an = AN()
        if an then an.stagger(frame) end
        current = { btn = btn, frame = frame }
        local entry = tabOf[frame] or tabByBtn[btn]
        titleLbl.Text = entry and entry.label or ""
        updateSub()
    end

    function S.CreateTabButton(iconText, labelText, frame)
        local btn = make("TextButton", {
            Name = "Tab" .. tostring(#tabs + 1), Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = P.ItemHover,
            BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0,
            LayoutOrder = #tabs + 1, ZIndex = 3,
        }, nav)
        corner(btn, 10)
        if AN() then AN().bindRipple(btn, P.Accent) end
        local bar = make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0),
            BackgroundColor3 = P.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4,
        }, btn)
        pill(bar)
        local ico = label({
            Size = UDim2.new(0, 44, 1, 0), Text = tostring(iconText or ""), Font = FONT_BODY, TextSize = 19,
            TextColor3 = P.TextPrimary, TextXAlignment = CENTER, TextTransparency = 0.45, ZIndex = 4,
        }, btn)
        local txt = label({
            Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -48, 1, 0), Text = tidy(labelText),
            Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextSecondary, TextTransparency = expanded and 0 or 1,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4,
        }, btn)
        local entry = { btn = btn, frame = frame, bar = bar, ico = ico, txt = txt, label = tidy(labelText) }
        tabs[#tabs + 1] = entry
        tabOf[frame] = entry
        tabByBtn[btn] = entry
        btn.MouseEnter:Connect(function()
            if not (current and current.btn == btn) then
                tween(btn, 0.1, { BackgroundColor3 = P.ItemHover, BackgroundTransparency = 0.5 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not (current and current.btn == btn) then tween(btn, 0.1, { BackgroundTransparency = 1 }) end
        end)
        btn.MouseButton1Click:Connect(function() S.SwitchTab(btn, frame) end)
        return btn
    end

    local function glowRow(target)
        if not target or not target.Parent then return end
        local stroke = target:FindFirstChildOfClass("UIStroke")
        local madeStroke = false
        if not stroke then
            stroke = make("UIStroke", { Color = P.Accent, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, target)
            madeStroke = true
        end
        local oc, ot, otr, obg = stroke.Color, stroke.Thickness, stroke.Transparency, target.BackgroundColor3
        local halo = make("Frame", {
            Name = "PhHalo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 10), BackgroundColor3 = P.Accent, BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 20,
        }, target)
        corner(halo, 14)
        stroke.Color = P.Accent
        local tint = obg:Lerp(P.Accent, 0.3)
        for _ = 1, 2 do
            tween(stroke, 0.2, { Thickness = 3, Transparency = 0 })
            tween(halo, 0.2, { BackgroundTransparency = 0.78 })
            tween(target, 0.2, { BackgroundColor3 = tint })
            task.wait(0.25)
            tween(stroke, 0.2, { Thickness = ot, Transparency = otr })
            tween(halo, 0.2, { BackgroundTransparency = 1 })
            tween(target, 0.2, { BackgroundColor3 = obg })
            task.wait(0.27)
        end
        if halo.Parent then halo:Destroy() end
        if target.Parent then target.BackgroundColor3 = obg end
        if madeStroke then
            if stroke.Parent then stroke:Destroy() end
        else
            stroke.Color, stroke.Thickness, stroke.Transparency = oc, ot, otr
        end
    end

    local focusToken = 0
    function S.FocusFeature(featName, page)
        focusToken = focusToken + 1
        local token = focusToken
        Skin.SendNotification("Jumping to " .. tidy(featName), P.Accent)
        local function run()
            local target = findRow(featName, page)
            if not target then
                Skin.SendNotification("Opened the page, but could not find that option", P.Yellow)
                return
            end

            for _ = 1, 25 do
                if target.AbsoluteSize.Y > 0 and page.AbsoluteSize.Y > 0 and page.CanvasSize.Y.Offset > 0 then break end
                task.wait(0.03)
            end
            task.wait(0.2)
            if token ~= focusToken or not target.Parent then return end
            local maxY = math.max(0, page.CanvasSize.Y.Offset - page.AbsoluteSize.Y)
            local y = target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
            y = math.clamp(y - (page.AbsoluteSize.Y - target.AbsoluteSize.Y) / 2, 0, maxY)
            tween(page, 0.4, { CanvasPosition = Vector2.new(0, y) }, Enum.EasingStyle.Quart)
            task.wait(0.45)
            if token ~= focusToken or not target.Parent then return end
            glowRow(target)
        end
        local ok, err = pcall(run)
        if not ok then
            Skin.SendNotification("Jump error: " .. tostring(err):sub(1, 70), P.Red)
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if suppress then return end
        local q = trim(searchBox.Text):lower()
        if q == "" then
            searchPage.Visible = false
            if current then
                for _, pg in pairs(pages) do pg.Visible = (pg == current.frame) end
                local entry = tabOf[current.frame]
                titleLbl.Text = entry and entry.label or ""
                updateSub()
            end
            return
        end
        for _, pg in pairs(pages) do pg.Visible = false end
        searchPage.Visible = true
        searchPage.CanvasPosition = Vector2.new(0, 0)
        for _, c in ipairs(searchPage:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        local shown = 0
        local feats = env.GetFeatures and env.GetFeatures() or {}
        for _, feat in ipairs(feats) do
            if shown >= 40 then break end
            if ((feat.n or "") .. " " .. (feat.d or "")):lower():find(q, 1, true) then
                shown = shown + 1
                local tab = feat.f and tabOf[feat.f]
                local row = make("TextButton", { Size = UDim2.new(1, -8, 0, 48), BackgroundColor3 = P.ContentBg, AutoButtonColor = false, Text = "", BorderSizePixel = 0 }, searchPage)
                corner(row, 10)
                if AN() then AN().bindRipple(row, P.Accent) end
                label({ Position = UDim2.new(0, 14, 0, 7), Size = UDim2.new(1, -130, 0, 18), Text = tidy(feat.n), Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                label({ Position = UDim2.new(0, 14, 0, 26), Size = UDim2.new(1, -130, 0, 16), Text = feat.d or "", Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                if tab then
                    local chipTag = make("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 88, 0, 22),
                        BackgroundColor3 = P.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0,
                    }, row)
                    pill(chipTag)
                    label({ Size = UDim2.new(1, 0, 1, 0), Text = tab.label, Font = FONT_SEMI, TextSize = 11, TextColor3 = P.Accent, TextXAlignment = CENTER, TextTruncate = Enum.TextTruncate.AtEnd }, chipTag)
                end
                row.MouseEnter:Connect(function() tween(row, 0.1, { BackgroundColor3 = P.ItemHover }) end)
                row.MouseLeave:Connect(function() tween(row, 0.1, { BackgroundColor3 = P.ContentBg }) end)
                row.MouseButton1Click:Connect(function()
                    if tab then
                        searchBox:ReleaseFocus()
                        S.SwitchTab(tab.btn, tab.frame)
                        task.spawn(S.FocusFeature, feat.n, tab.frame)
                    end
                end)
            end
        end
        titleLbl.Text = "Search"
        subLbl.Text = shown .. (shown == 1 and " match" or " matches")
        local an = AN()
        if an then an.stagger(searchPage, 0.025) end
        if shown == 0 then
            label({ Size = UDim2.new(1, -8, 0, 44), Text = "Nothing matches \226\128\156" .. searchBox.Text .. "\226\128\157. Try a shorter word.", Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextWrapped = true }, searchPage)
        end
    end)

    local grip = make("TextButton", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.new(0, 24, 0, 24),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 50, BorderSizePixel = 0,
    }, main)
    for i, len in ipairs({ 14, 8 }) do
        make("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -5, 1, -5 - (i - 1) * 5), Size = UDim2.new(0, len, 0, 2),
            Rotation = -45, BackgroundColor3 = P.TextSecondary, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 51,
        }, grip)
    end
    local resizing, rStart, rSize = false, nil, nil
    grip.InputBegan:Connect(function(input)
        if isPress(input) then
            resizing, rStart, rSize = true, input.Position, main.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and resizing then
                    resizing = false
                    settings.MainFrameSize = { W = main.AbsoluteSize.X, H = main.AbsoluteSize.Y }
                    env.saveSettings()
                end
            end)
        end
    end)
    env.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if resizing and isMove(input) then
            local d = input.Position - rStart
            main.Size = UDim2.new(0, math.clamp(rSize.X + d.X, 440, 1100), 0, math.clamp(rSize.Y + d.Y, 290, 800))
        end
    end))

    local open = env.ToggleBtn
    if open then
        open.BackgroundColor3 = P.SidebarBg
        open.Text = "P"
        open.Font = FONT_HEAD
        open.TextSize = 22
        open.TextColor3 = P.Accent
        local cr = open:FindFirstChildOfClass("UICorner")
        if cr then cr.CornerRadius = UDim.new(0, 12) end
        local st = open:FindFirstChildOfClass("UIStroke")
        if st then st.Color, st.Thickness = P.Accent, 1.5 end
    end

    applyRail(false)
    return S
end

return Skin
