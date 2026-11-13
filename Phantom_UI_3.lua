-- Phantom UI 3 : "Ember"
-- Layout : title bar + horizontal tab strip on top (no side rail), footer status bar
-- Look   : graphite + amber, squared corners, ON/OFF block switches, notch-handle sliders,
--          underline-on-focus inputs, bottom-centre toasts with a countdown line.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Skin = { Name = "Ember" }
local Env, P

local FONT_HEAD = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham
local FONT_SEMI = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right
local CENTER = Enum.TextXAlignment.Center
local WHITE = Color3.new(1, 1, 1)

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------
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

local function label(props, parent)
    props.BackgroundTransparency = 1
    props.BorderSizePixel = 0
    if props.TextXAlignment == nil then props.TextXAlignment = LEFT end
    return make("TextLabel", props, parent)
end

local function layoutRegistry()
    return Env and Env.GetTabLayoutRegistry and Env.GetTabLayoutRegistry() or nil
end

-- row registry (used by search -> "jump to feature")
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

----------------------------------------------------------------------
-- theme
----------------------------------------------------------------------
function Skin.MakeTheme(base, themeName)
    local c = Color3.fromRGB
    local T = {}
    if type(base) == "table" then
        for k, v in pairs(base) do T[k] = v end
    end
    T.MainBg = c(15, 15, 17)
    T.SidebarBg = c(22, 22, 26)
    T.ContentBg = c(28, 28, 33)
    T.ItemHover = c(40, 40, 47)
    T.Outline = c(54, 54, 64)
    T.TextPrimary = c(243, 241, 236)
    T.TextSecondary = c(143, 141, 152)
    T.Accent = c(255, 150, 64)
    T.Red = c(255, 92, 92)
    T.Green = c(92, 222, 140)
    T.Yellow = c(255, 206, 86)

    -- a theme the user picked in Settings keeps its own accent colour
    if themeName and themeName ~= "Phantom Ultimate 8.8" and themeName ~= "Phantom Ultimate 5.0"
        and type(base) == "table" and base.Accent then
        T.Accent = base.Accent
    end
    T.Accent2 = shift(T.Accent, -0.05)
    return T
end

----------------------------------------------------------------------
-- layout + section header
----------------------------------------------------------------------
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
        local reg = layoutRegistry()
        if reg then reg[parent] = refresh end
    end
    return l
end

local Headers = {}

function Skin.createSectionHeader(parent, text)
    local row = make("TextButton", {
        Name = "PhHeader", Size = UDim2.new(1, -8, 0, 28), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, BorderSizePixel = 0,
    }, parent)
    make("Frame", {
        Position = UDim2.new(0, 2, 0.5, -1), Size = UDim2.new(0, 10, 0, 2), BackgroundColor3 = P.Accent, BorderSizePixel = 0,
    }, row)
    local lbl = label({
        Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        Text = tidy(text):upper(), Font = FONT_BOLD, TextSize = 11, TextColor3 = P.TextSecondary,
    }, row)
    local line = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 120, 0.5, 0), Size = UDim2.new(1, -150, 0, 1),
        BackgroundColor3 = P.Outline, BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }, row)
    local chev = label({
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 16, 0, 16),
        Text = "\226\128\186", Font = FONT_BOLD, TextSize = 16, TextColor3 = P.TextSecondary,
        TextXAlignment = CENTER, Rotation = 90,
    }, row)
    local function fit()
        local x = 20 + lbl.AbsoluteSize.X + 10
        line.Position = UDim2.new(0, x, 0.5, 0)
        line.Size = UDim2.new(1, -(x + 30), 0, 1)
    end
    lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()

    -- tap a header to fold / unfold the rows under it (until the next header)
    local state = { header = row, collapsed = false, saved = {} }
    Headers[#Headers + 1] = state
    local function followers()
        local list, started = {}, false
        local par = row.Parent
        if not par then return list end
        for _, c in ipairs(par:GetChildren()) do
            if c == row then
                started = true
            elseif started then
                if c.Name == "PhHeader" then break end
                if c:IsA("GuiObject") then list[#list + 1] = c end
            end
        end
        return list
    end
    function state.set(collapsed)
        if collapsed == state.collapsed or not row.Parent then return end
        state.collapsed = collapsed
        if collapsed then
            for _, c in ipairs(followers()) do
                state.saved[c] = c.Visible
                c.Visible = false
            end
        else
            for c, vis in pairs(state.saved) do
                if c.Parent then c.Visible = vis end
            end
            state.saved = {}
            local an = AN()
            if an then an.staggerList(followers(), 0.03) end
        end
        tween(chev, 0.15, { Rotation = collapsed and 0 or 90 })
        tween(lbl, 0.15, { TextColor3 = collapsed and P.Accent or P.TextSecondary })
    end
    row.MouseButton1Click:Connect(function() state.set(not state.collapsed) end)
    return row
end

----------------------------------------------------------------------
-- toggle (block switch)
----------------------------------------------------------------------
function Skin.createToggleSwitch(parent, text, description, callback, externalControl, noSave)
    local obj, isOn = {}, false

    local row = make("TextButton", {
        Size = UDim2.new(1, -8, 0, 50), BackgroundColor3 = P.ContentBg, AutoButtonColor = false,
        Text = "", BorderSizePixel = 0,
    }, parent)
    corner(row, 6)
    if AN() then AN().bindRipple(row, P.Accent) end

    local stripe = make("Frame", {
        Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    corner(stripe, 2)

    label({
        Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -134, 0, 18), Text = text,
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 16, 0, 27), Size = UDim2.new(1, -134, 0, 15), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local track = make("Frame", {
        Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 54, 0, 24), BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    corner(track, 5)
    local stateLbl = label({
        Size = UDim2.new(1, 0, 1, 0), Text = "OFF", Font = FONT_BOLD, TextSize = 10,
        TextColor3 = P.TextSecondary, TextXAlignment = RIGHT, ZIndex = 2,
    }, track)
    make("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, stateLbl)
    local knob = make("Frame", {
        Size = UDim2.new(0, 20, 0, 18), Position = UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = P.TextSecondary, BorderSizePixel = 0, ZIndex = 3,
    }, track)
    corner(knob, 4)

    local hovering = false
    local function rowCol()
        local base = hovering and P.ItemHover or P.ContentBg
        return isOn and base:Lerp(P.Accent, 0.1) or base
    end

    local function paint(instant)
        local pos = isOn and UDim2.new(1, -23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local trackCol = isOn and P.Accent or P.Outline
        local knobCol = isOn and P.MainBg or P.TextSecondary
        local textCol = isOn and P.MainBg or P.TextSecondary
        local stripeCol = isOn and P.Accent or P.Outline
        stateLbl.Text = isOn and "ON" or "OFF"
        stateLbl.TextXAlignment = isOn and LEFT or RIGHT
        if instant then
            knob.Position, knob.BackgroundColor3 = pos, knobCol
            track.BackgroundColor3 = trackCol
            stateLbl.TextColor3 = textCol
            stripe.BackgroundColor3 = stripeCol
            row.BackgroundColor3 = rowCol()
        else
            if isOn then row.BackgroundColor3 = P.ContentBg:Lerp(P.Accent, 0.4) end
            tween(row, 0.55, { BackgroundColor3 = rowCol() })
            tween(knob, 0.3, { Position = pos }, Enum.EasingStyle.Back)
            tween(knob, 0.16, { BackgroundColor3 = knobCol })
            tween(track, 0.16, { BackgroundColor3 = trackCol })
            tween(stateLbl, 0.16, { TextColor3 = textCol })
            tween(stripe, 0.16, { BackgroundColor3 = stripeCol })
        end
    end

    local kb = make("TextButton", {
        Name = "KeybindBtn", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -78, 0.5, 0),
        Size = UDim2.new(0, 42, 0, 20), BackgroundTransparency = 1, AutoButtonColor = false,
        Text = "bind", Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, ZIndex = 2, BorderSizePixel = 0,
    }, row)
    corner(kb, 4)
    local kbLine = outline(kb, P.Outline, 1)
    local function paintKb()
        local k = Env.Settings.Keybinds and Env.Settings.Keybinds[text]
        if k and k.key then
            kb.Text = (k.ctrl and "^" or "") .. tostring(k.key)
            kb.TextColor3, kb.Font = P.Accent, FONT_BOLD
            kbLine.Color = P.Accent
        else
            kb.Text = "bind"
            kb.TextColor3, kb.Font = P.TextSecondary, FONT_BODY
            kbLine.Color = P.Outline
        end
    end
    paintKb()
    kb.MouseButton1Click:Connect(function()
        local open = Env.GetOpenKeybindPopup and Env.GetOpenKeybindPopup()
        if open then open(text, paintKb, obj) end
    end)

    row.MouseEnter:Connect(function() hovering = true; tween(row, 0.12, { BackgroundColor3 = rowCol() }) end)
    row.MouseLeave:Connect(function() hovering = false; tween(row, 0.12, { BackgroundColor3 = rowCol() }) end)

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

----------------------------------------------------------------------
-- slider (notch handle)
----------------------------------------------------------------------
function Skin.createSlider(parent, text, description, minVal, maxVal, defaultVal, callback, noSave)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 6)
    local stripe = make("Frame", {
        Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = P.Accent, BorderSizePixel = 0,
    }, row)
    corner(stripe, 2)

    label({
        Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -110, 0, 18), Text = text,
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -110, 0, 14), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local valueBox = make("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0, 70, 0, 24),
        BackgroundColor3 = P.MainBg, Text = "", ClearTextOnFocus = false, Font = FONT_BOLD, TextSize = 13,
        TextColor3 = P.Accent, TextXAlignment = CENTER, BorderSizePixel = 0,
    }, row)
    corner(valueBox, 4)
    local valueLine = outline(valueBox, P.Outline, 1)
    valueBox.Focused:Connect(function() valueLine.Color = P.Accent end)

    local hit = make("Frame", { Position = UDim2.new(0, 16, 0, 42), Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1, Active = true }, row)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, hit)
    corner(track, 2)
    local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.Accent, BorderSizePixel = 0 }, track)
    corner(fill, 2)
    local handle = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 8, 0, 18),
        BackgroundColor3 = P.TextPrimary, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(handle, 3)
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
        valueLine.Color = P.Outline
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
        tween(handle, 0.16, { Size = UDim2.new(0, 8, 0, 18) }, Enum.EasingStyle.Back)
        tween(track, 0.16, { Size = UDim2.new(1, 0, 0, 6) })
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
            tween(handle, 0.12, { Size = UDim2.new(0, 10, 0, 22) }, Enum.EasingStyle.Back)
            tween(track, 0.12, { Size = UDim2.new(1, 0, 0, 8) })
            fromInput(input)
        end
    end)
    local c1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and isMove(input) then fromInput(input) end
    end)
    local c2 = UserInputService.InputEnded:Connect(function(input)
        if isPress(input) and dragging then release() end
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

----------------------------------------------------------------------
-- button
-- NOTE: the returned object is the TextButton itself and its title is a
-- direct child TextLabel (the main script edits those labels for dropdowns).
----------------------------------------------------------------------
function Skin.createButton(parent, text, description, color, callback)
    local accent = color or P.Accent
    local hasDesc = description ~= nil and description ~= ""

    local btn = make("TextButton", {
        Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = P.ContentBg, AutoButtonColor = false,
        Text = "", BorderSizePixel = 0,
    }, parent)
    corner(btn, 6)
    if AN() then AN().bindRipple(btn, accent) end

    local stripe = make("Frame", {
        Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = accent, BorderSizePixel = 0,
    }, btn)
    corner(stripe, 2)

    label({
        Position = UDim2.new(0, 16, 0, hasDesc and 7 or 14), Size = UDim2.new(1, -64, 0, 18), Text = text,
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    if hasDesc then
        label({
            Position = UDim2.new(0, 16, 0, 25), Size = UDim2.new(1, -64, 0, 15), Text = description,
            Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
        }, btn)
    end

    local arrowBox = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 28, 0, 24),
        BackgroundColor3 = accent, BackgroundTransparency = 0.85, BorderSizePixel = 0,
    }, btn)
    corner(arrowBox, 5)
    local arrow = label({
        Size = UDim2.new(1, 0, 1, 0), Text = "\226\134\146", Font = FONT_BOLD, TextSize = 14,
        TextColor3 = accent, TextXAlignment = CENTER,
    }, arrowBox)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.12, { BackgroundColor3 = P.ItemHover })
        tween(arrowBox, 0.12, { BackgroundTransparency = 0.6 })
        tween(arrow, 0.12, { Position = UDim2.new(0, 2, 0, 0) })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.12, { BackgroundColor3 = P.ContentBg })
        tween(arrowBox, 0.12, { BackgroundTransparency = 0.85 })
        tween(arrow, 0.12, { Position = UDim2.new(0, 0, 0, 0) })
    end)
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

----------------------------------------------------------------------
-- text box (underline grows on focus)
----------------------------------------------------------------------
function Skin.createTextBox(parent, placeholder, description, callback)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 6)
    local stripe = make("Frame", {
        Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    corner(stripe, 2)

    label({
        Position = UDim2.new(0, 16, 0, 6), Size = UDim2.new(1, -30, 0, 16), Text = description or "",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local field = make("Frame", {
        Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -30, 0, 28), BackgroundColor3 = P.MainBg,
        BorderSizePixel = 0, ClipsDescendants = true,
    }, row)
    corner(field, 4)
    local underline = make("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = P.Accent, BorderSizePixel = 0, ZIndex = 3,
    }, field)
    local box = make("TextBox", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = tidy(placeholder), PlaceholderColor3 = P.TextSecondary, TextColor3 = P.TextPrimary,
        Font = FONT_BODY, TextSize = 13, TextXAlignment = LEFT, ClearTextOnFocus = false, BorderSizePixel = 0,
    }, field)

    registerRow(row, placeholder, description)
    box.Focused:Connect(function()
        tween(underline, 0.22, { Size = UDim2.new(1, 0, 0, 2) })
        tween(stripe, 0.15, { BackgroundColor3 = P.Accent })
    end)
    box.FocusLost:Connect(function()
        tween(underline, 0.18, { Size = UDim2.new(0, 0, 0, 2) })
        tween(stripe, 0.15, { BackgroundColor3 = P.Outline })
        if callback then callback(box.Text) end
    end)
    return box
end

----------------------------------------------------------------------
-- confirmation dialog
----------------------------------------------------------------------
function Skin.createConfirmation(_, text, onYes)
    local shell = Skin.Shell
    if not shell or not shell.MainFrame then return end

    local overlay = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
        AutoButtonColor = false, Text = "", ZIndex = 200, BorderSizePixel = 0,
    }, shell.MainFrame)
    overlay.BackgroundTransparency = 1
    tween(overlay, 0.22, { BackgroundTransparency = 0.45 })
    local panel = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 201,
    }, overlay)
    corner(panel, 8)
    outline(panel, P.Outline, 1)
    if AN() then AN().scaleIn(panel, 0.82, 0.34) end
    make("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = P.Accent, BorderSizePixel = 0, ZIndex = 203 }, panel)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
    }, panel)
    make("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

    label({
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tidy(text), TextWrapped = true,
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, ZIndex = 202, LayoutOrder = 1,
    }, panel)

    local buttons = make("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 202, LayoutOrder = 2 }, panel)
    local function blockBtn(txt, x, fillCol, textCol)
        local b = make("TextButton", {
            Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = fillCol, AutoButtonColor = false, Text = txt, Font = FONT_BOLD, TextSize = 12,
            TextColor3 = textCol, ZIndex = 203, BorderSizePixel = 0,
        }, buttons)
        corner(b, 5)
        return b
    end
    local no = blockBtn("NO", 0, P.ContentBg, P.TextPrimary)
    local yes = blockBtn("YES", 0.5, P.Accent, P.MainBg)
    no.MouseButton1Click:Connect(function() overlay:Destroy() end)
    yes.MouseButton1Click:Connect(function()
        overlay:Destroy()
        onYes()
    end)
end

----------------------------------------------------------------------
-- notifications (bottom-centre toast with countdown line)
----------------------------------------------------------------------
local toastHost
local toasts = {}
local toastOrder = 0

function Skin.SendNotification(text, color)
    if not toastHost or not toastHost.Parent then return end
    local accent = color or P.Accent

    toastOrder = toastOrder + 1
    local toast = make("Frame", {
        Size = UDim2.new(0, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.SidebarBg,
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = toastOrder,
    }, toastHost)
    corner(toast, 6)
    local line = outline(toast, P.Outline, 1)
    line.Transparency = 1

    local bar = make("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0 }, toast)
    local content = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toast)
    make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, content)
    local msg = label({
        Size = UDim2.new(0, 0, 1, -2), AutomaticSize = Enum.AutomaticSize.X, Text = tidy(text),
        Font = FONT_SEMI, TextSize = 13, TextColor3 = P.TextPrimary, TextTransparency = 1,
    }, content)
    local timer = make("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toast)

    if AN() then AN().scaleIn(toast, 0.8, 0.32) end
    table.insert(toasts, toast)
    while #toasts > 4 do
        local old = table.remove(toasts, 1)
        if old and old.Parent then old:Destroy() end
    end

    tween(toast, 0.2, { BackgroundTransparency = 0.04 })
    tween(line, 0.2, { Transparency = 0 })
    tween(bar, 0.2, { BackgroundTransparency = 0 })
    tween(msg, 0.2, { TextTransparency = 0 })
    tween(timer, 0.2, { BackgroundTransparency = 0.3 })
    task.delay(0.2, function()
        if timer.Parent then
            TweenService:Create(timer, TweenInfo.new(2.6, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
        end
    end)

    task.delay(2.8, function()
        if not toast.Parent then return end
        tween(toast, 0.25, { BackgroundTransparency = 1 })
        tween(line, 0.25, { Transparency = 1 })
        tween(bar, 0.25, { BackgroundTransparency = 1 })
        tween(msg, 0.25, { TextTransparency = 1 })
        tween(timer, 0.25, { BackgroundTransparency = 1 })
        task.wait(0.3)
        local i = table.find(toasts, toast)
        if i then table.remove(toasts, i) end
        if toast.Parent then toast:Destroy() end
    end)
end

----------------------------------------------------------------------
-- shell
----------------------------------------------------------------------
local HEADER_H, STRIP_H, FOOTER_H = 44, 36, 24

function Skin.Mount(env)
    Env, P = env, env.Theme
    toasts = {}
    toastOrder = 0
    Rows = {}
    Headers = {}

    local S = {}
    Skin.Shell = S
    local settings = env.Settings
    local gui = env.ScreenGui

    toastHost = make("Frame", {
        Name = "PhEmberToasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18),
        Size = UDim2.new(0, 420, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 20000,
    }, gui)
    make("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }, toastHost)

    local vp = gui.AbsoluteSize
    local maxW = (vp.X > 0) and math.min(1100, vp.X - 16) or 1100
    local maxH = (vp.Y > 0) and math.min(800, vp.Y - 16) or 800
    local minW, minH = math.min(460, maxW), math.min(300, maxH)
    local W = math.clamp((settings.MainFrameSize and settings.MainFrameSize.W) or 600, minW, maxW)
    local H = math.clamp((settings.MainFrameSize and settings.MainFrameSize.H) or 360, minH, maxH)
    local mp = settings.MainFramePos
    local main = make("Frame", {
        Name = "MainFrame", Size = UDim2.new(0, W, 0, H),
        Position = mp and UDim2.new(mp.X, mp.XOff, mp.Y, mp.YOff) or UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = P.MainBg, BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
    }, gui)
    corner(main, 8)
    outline(main, P.Outline, 1)
    S.MainFrame = main

    local topLine = make("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, main)
    local topGrad = Instance.new("UIGradient")
    topGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.Accent),
        ColorSequenceKeypoint.new(0.4, acc2()),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.6, acc2()),
        ColorSequenceKeypoint.new(1, P.Accent),
    })
    topGrad.Parent = topLine


    local function savePos()
        settings.MainFramePos = {
            X = main.Position.X.Scale, XOff = main.Position.X.Offset,
            Y = main.Position.Y.Scale, YOff = main.Position.Y.Offset,
        }
        env.saveSettings()
    end

    ------------------------------------------------------------------ header
    local header = make("Frame", { Name = "TitleBand", Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(1, 0, 0, HEADER_H - 2), BackgroundTransparency = 1, ZIndex = 3 }, main)

    local brandHolder = make("Frame", { Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 3 }, header)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, brandHolder)
    label({
        Size = UDim2.new(0, 16, 0, 20), Text = "\226\151\134", Font = FONT_BOLD, TextSize = 16, TextColor3 = P.Accent,
        TextXAlignment = CENTER, LayoutOrder = 1, ZIndex = 3,
    }, brandHolder)
    label({
        Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = "PHANTOM", Font = FONT_HEAD, TextSize = 15,
        TextColor3 = P.TextPrimary, LayoutOrder = 2, ZIndex = 3,
    }, brandHolder)
    local chip = make("Frame", {
        Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.Accent,
        BackgroundTransparency = 0.85, BorderSizePixel = 0, LayoutOrder = 3, ZIndex = 3,
    }, brandHolder)
    corner(chip, 4)
    make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, chip)
    label({
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "v" .. tostring(env.Version or ""),
        Font = FONT_BOLD, TextSize = 10, TextColor3 = P.Accent, ZIndex = 4,
    }, chip)

    local close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = P.ContentBg, Text = "\195\151", Font = FONT_BOLD, TextSize = 20, TextColor3 = P.TextSecondary,
        AutoButtonColor = false, ZIndex = 4, BorderSizePixel = 0,
    }, header)
    corner(close, 6)
    close.MouseEnter:Connect(function() tween(close, 0.1, { BackgroundColor3 = P.Red, TextColor3 = WHITE }) end)
    close.MouseLeave:Connect(function() tween(close, 0.1, { BackgroundColor3 = P.ContentBg, TextColor3 = P.TextSecondary }) end)
    close.MouseButton1Click:Connect(function()
        local an = AN()
        if an then an.popOut(main) else main.Visible = false end
    end)

    local searchWrap = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.new(0, 160, 0, 28),
        BackgroundColor3 = P.ContentBg, BorderSizePixel = 0, ZIndex = 3,
    }, header)
    corner(searchWrap, 6)
    local searchLine = outline(searchWrap, P.Outline, 1)
    label({
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 20, 1, 0), Text = "\240\159\148\141", Font = FONT_BODY,
        TextSize = 12, TextColor3 = P.TextSecondary, TextXAlignment = CENTER, ZIndex = 4,
    }, searchWrap)
    local searchBox = make("TextBox", {
        Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Search features", PlaceholderColor3 = P.TextSecondary, TextColor3 = P.TextPrimary,
        Font = FONT_BODY, TextSize = 12, TextXAlignment = LEFT, ClearTextOnFocus = false, ZIndex = 4, BorderSizePixel = 0,
    }, searchWrap)
    searchBox.Focused:Connect(function()
        tween(searchWrap, 0.15, { Size = UDim2.new(0, 220, 0, 28), BackgroundColor3 = P.ItemHover })
        searchLine.Color = P.Accent
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchWrap, 0.15, { Size = UDim2.new(0, 160, 0, 28), BackgroundColor3 = P.ContentBg })
        searchLine.Color = P.Outline
    end)

    ------------------------------------------------------------------ tab strip
    local strip = make("Frame", {
        Name = "TabStrip", Position = UDim2.new(0, 0, 0, HEADER_H), Size = UDim2.new(1, 0, 0, STRIP_H),
        BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 2,
    }, main)
    make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Outline, BorderSizePixel = 0, ZIndex = 3 }, strip)

    local tabScroll = make("ScrollingFrame", {
        Name = "Tabs", Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3,
    }, strip)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabScroll)

    local function scrollTabs(dx)
        local maxX = math.max(0, tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X)
        local target = math.clamp(tabScroll.CanvasPosition.X + dx, 0, maxX)
        tween(tabScroll, 0.18, { CanvasPosition = Vector2.new(target, 0) })
    end
    local function arrowBtn(txt, anchorX, posX, dx)
        local b = make("TextButton", {
            AnchorPoint = Vector2.new(anchorX, 0), Position = UDim2.new(posX, 0, 0, 0), Size = UDim2.new(0, 26, 1, 0),
            BackgroundTransparency = 1, Text = txt, Font = FONT_BOLD, TextSize = 20, TextColor3 = P.TextSecondary,
            AutoButtonColor = false, ZIndex = 5, BorderSizePixel = 0,
        }, strip)
        b.MouseEnter:Connect(function() tween(b, 0.1, { TextColor3 = P.Accent }) end)
        b.MouseLeave:Connect(function() tween(b, 0.1, { TextColor3 = P.TextSecondary }) end)
        b.MouseButton1Click:Connect(function() scrollTabs(dx) end)
        return b
    end
    arrowBtn("\226\128\185", 0, 0, -220)
    arrowBtn("\226\128\186", 1, 1, 220)
    strip.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            scrollTabs(-input.Position.Z * 140)
        end
    end)

    ------------------------------------------------------------------ drag (title band)
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

    ------------------------------------------------------------------ body + footer
    local bodyTop = HEADER_H + STRIP_H + 6
    local body = make("Frame", {
        Name = "Body", Position = UDim2.new(0, 10, 0, bodyTop), Size = UDim2.new(1, -18, 1, -(bodyTop + FOOTER_H + 2)),
        BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
    }, main)

    local footer = make("Frame", {
        Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, FOOTER_H),
        BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 2,
    }, main)
    make("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Outline, BorderSizePixel = 0, ZIndex = 3 }, footer)
    local footL = label({
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Text = "Ember ui",
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, ZIndex = 3,
    }, footer)
    label({
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -32, 0, 0), Size = UDim2.new(0.4, 0, 1, 0),
        Text = "Toggle  \194\183  " .. tostring(settings.MenuKey or "RightControl"),
        Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextXAlignment = RIGHT, ZIndex = 3,
    }, footer)

    ------------------------------------------------------------------ pages + tabs
    local pages, tabs, tabOf, tabByBtn = {}, {}, {}, {}
    local current
    local suppress = false

    do
        local an = AN()
        if an then
            an.watchOpen(main, function()
                an.shimmer(topGrad, 1.4)
                if current then an.stagger(current.frame) end
            end)
        end
    end

    local function updateSub()
        if not current then return end
        local n = 0
        for _, c in ipairs(current.frame:GetChildren()) do
            if c:IsA("GuiObject") and c.Name ~= "PhHeader" then n = n + 1 end
        end
        local entry = tabOf[current.frame]
        footL.Text = (entry and entry.label or "") .. "  \194\183  " .. n .. (n == 1 and " item" or " items")
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
            if t.on ~= on then            -- only repaint the tabs that actually changed
                t.on = on
                tween(t.bar, 0.3, { Size = on and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Quint)
                tween(t.bar, 0.16, { BackgroundTransparency = on and 0 or 1 })
                tween(t.txt, 0.16, { TextColor3 = on and P.TextPrimary or P.TextSecondary })
                tween(t.ico, 0.16, { TextTransparency = on and 0 or 0.4 })
                tween(t.btn, 0.2, { BackgroundTransparency = on and 0.9 or 1 })
            end
        end
    end

    local function reveal(btn)
        task.defer(function()
            if not btn.Parent then return end
            local view = tabScroll.AbsoluteSize.X
            local left = btn.AbsolutePosition.X - tabScroll.AbsolutePosition.X + tabScroll.CanvasPosition.X
            local right = left + btn.AbsoluteSize.X
            local target = tabScroll.CanvasPosition.X
            if left < target then
                target = left - 8
            elseif right > target + view then
                target = right - view + 8
            end
            target = math.max(0, target)
            if target ~= tabScroll.CanvasPosition.X then
                tween(tabScroll, 0.2, { CanvasPosition = Vector2.new(target, 0) })
            end
        end)
    end

    function S.SwitchTab(btn, frame)
        if searchBox.Text ~= "" then
            suppress = true
            searchBox.Text = ""
            suppress = false
        end
        paintTabs(btn)
        for _, pg in pairs(pages) do pg.Visible = (pg == frame) end
        frame.Position = UDim2.new(0, 0, 0, 16)
        tween(frame, 0.34, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
        local an = AN()
        if an then an.stagger(frame) end
        current = { btn = btn, frame = frame }
        updateSub()
        reveal(btn)
    end

    function S.CreateTabButton(iconText, labelText, frame)
        local btn = make("TextButton", {
            Name = "Tab" .. tostring(#tabs + 1), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = P.Accent, BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
            BorderSizePixel = 0, LayoutOrder = #tabs + 1, ZIndex = 4,
        }, tabScroll)
        local holder = make("Frame", {
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4,
        }, btn)
        make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, holder)
        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }, holder)
        local ico = label({
            Size = UDim2.new(0, 18, 0, 20), Text = tostring(iconText or ""), Font = FONT_BODY, TextSize = 15,
            TextColor3 = P.TextPrimary, TextXAlignment = CENTER, TextTransparency = 0.4, LayoutOrder = 1, ZIndex = 5,
        }, holder)
        local txt = label({
            Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = tidy(labelText):upper(),
            Font = FONT_BOLD, TextSize = 12, TextColor3 = P.TextSecondary, LayoutOrder = 2, ZIndex = 5,
        }, holder)
        local bar = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -1), Size = UDim2.new(0, 0, 0, 2),
            BackgroundColor3 = P.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6,
        }, btn)
        corner(bar, 1)

        if AN() then AN().bindRipple(btn, P.Accent) end
        local entry = { btn = btn, frame = frame, bar = bar, ico = ico, txt = txt, label = tidy(labelText) }
        tabs[#tabs + 1] = entry
        tabOf[frame] = entry
        tabByBtn[btn] = entry

        btn.MouseEnter:Connect(function()
            if not (current and current.btn == btn) then
                tween(txt, 0.1, { TextColor3 = P.TextPrimary })
                tween(btn, 0.1, { BackgroundTransparency = 0.94 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not (current and current.btn == btn) then
                tween(txt, 0.1, { TextColor3 = P.TextSecondary })
                tween(btn, 0.1, { BackgroundTransparency = 1 })
            end
        end)
        btn.MouseButton1Click:Connect(function() S.SwitchTab(btn, frame) end)
        return btn
    end

    ------------------------------------------------------------------ search -> jump
    local function glowRow(target)
        if not target or not target.Parent then return end
        local stroke = target:FindFirstChildOfClass("UIStroke")
        local madeStroke = false
        if not stroke then
            stroke = make("UIStroke", { Color = P.Accent, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, target)
            madeStroke = true
        end
        local oc, ot, otr, obg = stroke.Color, stroke.Thickness, stroke.Transparency, target.BackgroundColor3
        stroke.Color = P.Accent
        local tint = obg:Lerp(P.Accent, 0.3)
        for _ = 1, 2 do
            tween(stroke, 0.2, { Thickness = 2, Transparency = 0 })
            tween(target, 0.2, { BackgroundColor3 = tint })
            task.wait(0.25)
            tween(stroke, 0.2, { Thickness = ot, Transparency = otr })
            tween(target, 0.2, { BackgroundColor3 = obg })
            task.wait(0.27)
        end
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
            for _, h in ipairs(Headers) do
                if h.collapsed and h.header.Parent == page then h.set(false) end
            end
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
                corner(row, 6)
                if AN() then AN().bindRipple(row, P.Accent) end
                make("Frame", { Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = P.Accent, BorderSizePixel = 0 }, row)
                label({ Position = UDim2.new(0, 16, 0, 7), Size = UDim2.new(1, -140, 0, 18), Text = tidy(feat.n), Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                label({ Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -140, 0, 16), Text = feat.d or "", Font = FONT_BODY, TextSize = 11, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                if tab then
                    local tag = make("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 88, 0, 22),
                        BackgroundColor3 = P.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0,
                    }, row)
                    corner(tag, 4)
                    label({ Size = UDim2.new(1, 0, 1, 0), Text = tab.label:upper(), Font = FONT_BOLD, TextSize = 10, TextColor3 = P.Accent, TextXAlignment = CENTER, TextTruncate = Enum.TextTruncate.AtEnd }, tag)
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
        footL.Text = "Search  \194\183  " .. shown .. (shown == 1 and " match" or " matches")
        if shown == 0 then
            label({ Size = UDim2.new(1, -8, 0, 44), Text = "Nothing matches \226\128\156" .. searchBox.Text .. "\226\128\157. Try a shorter word.", Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextWrapped = true }, searchPage)
        end
    end)

    ------------------------------------------------------------------ resize grip
    local grip = make("TextButton", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.new(0, 24, 0, 22),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 50, BorderSizePixel = 0,
    }, main)
    for i = 1, 3 do
        make("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -5 - (i - 1) * 4, 1, -5), Size = UDim2.new(0, 2, 0, 2 + (i - 1) * 3),
            BackgroundColor3 = P.TextSecondary, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 51,
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
            main.Size = UDim2.new(0, math.clamp(rSize.X + d.X, minW, maxW), 0, math.clamp(rSize.Y + d.Y, minH, maxH))
        end
    end))

    ------------------------------------------------------------------ floating open button
    local open = env.ToggleBtn
    if open then
        open.BackgroundColor3 = P.SidebarBg
        open.Text = "\226\151\134"
        open.Font = FONT_HEAD
        open.TextSize = 22
        open.TextColor3 = P.Accent
        local cr = open:FindFirstChildOfClass("UICorner")
        if cr then cr.CornerRadius = UDim.new(0, 8) end
        local st = open:FindFirstChildOfClass("UIStroke")
        if st then st.Color, st.Thickness = P.Accent, 1.5 end
    end

    return S
end

return Skin
