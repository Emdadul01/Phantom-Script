--[[
    Phantom UI: Folio
    Standalone interface skin for Phantom 8.9. Loaded by the main script only
    when Settings > UI Style is set to "Folio". Returns a table:

        Skin.MakeTheme(baseTheme, themeName) -> Theme table
        Skin.Mount(env)                      -> Shell (builds the window)
        Skin.createLayout / createSectionHeader / createToggleSwitch /
        Skin.createSlider / createButton / createTextBox / createConfirmation /
        Skin.SendNotification                -> same signatures as the classic UI

    env fields (all supplied by the main script):
        ScreenGui, Theme, Settings, saveSettings, AddConnection, ToggleBtn,
        Version, GetFeatures(), GetKeybinds(), GetOpenKeybindPopup()
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Skin = { Name = "Folio" }
local Env, P

local FONT_HEAD = Enum.Font.Arvo
local FONT_BODY = Enum.Font.SourceSans
local FONT_SEMI = Enum.Font.SourceSansSemibold
local FONT_BOLD = Enum.Font.SourceSansBold

local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

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

local function tween(o, dur, props)
    if not o or not o.Parent then return end
    TweenService:Create(o, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Drops leading emoji/symbols and turns SHOUTING labels into sentence case.
-- Short words (AI, ESP, PVP, R6, V2) are kept as they are.
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

----------------------------------------------------------------------
-- palette
----------------------------------------------------------------------

function Skin.MakeTheme(base, themeName)
    local c = Color3.fromRGB
    local T = {
        MainBg = c(18, 38, 47),        -- window body
        SidebarBg = c(11, 24, 30),     -- title band + tab strip
        ContentBg = c(24, 52, 64),     -- rows
        ItemHover = c(31, 66, 79),
        Outline = c(42, 81, 96),
        TextPrimary = c(232, 242, 238),
        TextSecondary = c(141, 170, 170),
        Accent = c(183, 164, 255),
        Red = c(255, 111, 125),
        Green = c(127, 227, 178),
        Yellow = c(245, 211, 107),
    }
    -- A theme picked by the user only recolours the accent; the surfaces stay Folio.
    if themeName and themeName ~= "Phantom Ultimate 8.8" and themeName ~= "Phantom Ultimate 5.0"
        and base and base.Accent then
        T.Accent = base.Accent
    end
    return T
end

----------------------------------------------------------------------
-- layout + rows
----------------------------------------------------------------------

function Skin.createLayout(parent)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 5)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.Parent = parent
    if parent:IsA("ScrollingFrame") then
        local function refresh()
            parent.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 14)
        end
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
        refresh()
    end
    return l
end

function Skin.createSectionHeader(parent, text)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    label({
        Position = UDim2.new(0, 2, 0, 6), Size = UDim2.new(1, -4, 0, 22),
        Text = tidy(text), Font = FONT_HEAD, TextSize = 15, TextColor3 = P.TextPrimary,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    make("Frame", {
        Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    return row
end

function Skin.createToggleSwitch(parent, text, description, callback, externalControl, noSave)
    local obj, isOn = {}, false

    local row = make("TextButton", {
        Size = UDim2.new(1, -8, 0, 50), BackgroundColor3 = P.ContentBg, AutoButtonColor = false,
        Text = "", BorderSizePixel = 0,
    }, parent)
    corner(row, 5)

    label({
        Position = UDim2.new(0, 12, 0, 7), Size = UDim2.new(1, -150, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 16, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 12, 0, 27), Size = UDim2.new(1, -150, 0, 16), Text = description or "",
        Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local seg = make("Frame", {
        Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 72, 0, 26), BackgroundColor3 = P.MainBg, BorderSizePixel = 0,
    }, row)
    corner(seg, 5)
    outline(seg, P.Outline, 1)
    local thumb = make("Frame", {
        Size = UDim2.new(0.5, -4, 1, -6), Position = UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0, ZIndex = 2,
    }, seg)
    corner(thumb, 3)
    local offLbl = label({
        Size = UDim2.new(0.5, 0, 1, 0), Text = "Off", Font = FONT_SEMI, TextSize = 14,
        TextColor3 = P.TextPrimary, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
    }, seg)
    local onLbl = label({
        Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), Text = "On",
        Font = FONT_SEMI, TextSize = 14, TextColor3 = P.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3,
    }, seg)

    local function paint(instant)
        local pos = isOn and UDim2.new(0.5, 1, 0, 3) or UDim2.new(0, 3, 0, 3)
        local col = isOn and P.Accent or P.Outline
        if instant then
            thumb.Position, thumb.BackgroundColor3 = pos, col
        else
            tween(thumb, 0.16, { Position = pos, BackgroundColor3 = col })
        end
        offLbl.TextColor3 = isOn and P.TextSecondary or P.TextPrimary
        onLbl.TextColor3 = isOn and P.MainBg or P.TextSecondary
    end

    local kb = make("TextButton", {
        Name = "KeybindBtn", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -92, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 26), BackgroundTransparency = 1, AutoButtonColor = false, Text = "bind",
        Font = FONT_BODY, TextSize = 14, TextColor3 = P.TextSecondary, ZIndex = 2, BorderSizePixel = 0,
    }, row)
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

    row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundColor3 = P.ItemHover }) end)
    row.MouseLeave:Connect(function() tween(row, 0.12, { BackgroundColor3 = P.ContentBg }) end)

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
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 5)

    label({
        Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -100, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 16, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    label({
        Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -100, 0, 15), Text = description or "",
        Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local valueBox = make("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0, 64, 0, 22),
        BackgroundTransparency = 1, Text = "", ClearTextOnFocus = false, Font = FONT_BOLD, TextSize = 16,
        TextColor3 = P.Accent, TextXAlignment = RIGHT, BorderSizePixel = 0,
    }, row)

    local hit = make("Frame", { Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 16), BackgroundTransparency = 1, Active = true }, row)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, hit)
    corner(track, 2)
    local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = P.Accent, BorderSizePixel = 0 }, track)
    corner(fill, 2)
    local handle = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 4, 0, 16),
        BackgroundColor3 = P.TextPrimary, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(handle, 2)

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
    local function fromInput(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        setSlider(math.floor(minVal + (maxVal - minVal) * rel))
    end

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            tween(handle, 0.08, { Size = UDim2.new(0, 6, 0, 20) })
            fromInput(input)
        end
    end)
    local c1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    local c2 = UserInputService.InputEnded:Connect(function(input)
        if isPress(input) and dragging then
            dragging = false
            tween(handle, 0.08, { Size = UDim2.new(0, 4, 0, 16) })
        end
    end)
    row.Destroying:Connect(function()
        if c1 then c1:Disconnect() c1 = nil end
        if c2 then c2:Disconnect() c2 = nil end
        dragging = false
    end)

    setSlider(currentVal)
    ready = true
    if not noSave and Env.Settings[text] ~= nil then
        task.spawn(function() callback(currentVal) end)
    end
end

function Skin.createButton(parent, text, description, color, callback)
    local holder = make("Frame", { Size = UDim2.new(1, -8, 0, 48), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = P.ContentBg, AutoButtonColor = false, Text = "",
        BorderSizePixel = 0,
    }, holder)
    corner(btn, 5)
    local edge = make("Frame", {
        Position = UDim2.new(0, 0, 0, 7), Size = UDim2.new(0, 3, 1, -14),
        BackgroundColor3 = color or P.Accent, BorderSizePixel = 0,
    }, btn)
    corner(edge, 2)

    local hasDesc = description ~= nil and description ~= ""
    label({
        Position = UDim2.new(0, 14, 0, hasDesc and 6 or 14), Size = UDim2.new(1, -28, 0, 18), Text = tidy(text),
        Font = FONT_SEMI, TextSize = 16, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    if hasDesc then
        label({
            Position = UDim2.new(0, 14, 0, 26), Size = UDim2.new(1, -28, 0, 16), Text = description,
            Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
        }, btn)
    end

    btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = P.ItemHover }) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = P.ContentBg }) end)
    btn.InputBegan:Connect(function(input)
        if isPress(input) then tween(btn, 0.06, { BackgroundColor3 = P.Outline }) end
    end)
    btn.InputEnded:Connect(function(input)
        if isPress(input) then tween(btn, 0.12, { BackgroundColor3 = P.ItemHover }) end
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function Skin.createTextBox(parent, placeholder, description, callback)
    local row = make("Frame", { Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = P.ContentBg, BorderSizePixel = 0 }, parent)
    corner(row, 5)
    label({
        Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 16), Text = description or "",
        Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local box = make("TextBox", {
        Position = UDim2.new(0, 12, 0, 25), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1,
        Text = "", PlaceholderText = tidy(placeholder), PlaceholderColor3 = P.TextSecondary,
        TextColor3 = P.TextPrimary, Font = FONT_BODY, TextSize = 16, TextXAlignment = LEFT,
        ClearTextOnFocus = false, BorderSizePixel = 0,
    }, row)
    local line = make("Frame", {
        Position = UDim2.new(0, 12, 1, -6), Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = P.Outline, BorderSizePixel = 0,
    }, row)
    box.Focused:Connect(function() tween(line, 0.15, { BackgroundColor3 = P.Accent, Size = UDim2.new(1, -24, 0, 2) }) end)
    box.FocusLost:Connect(function()
        tween(line, 0.15, { BackgroundColor3 = P.Outline, Size = UDim2.new(1, -24, 0, 1) })
        if callback then callback(box.Text) end
    end)
    return box
end

function Skin.createConfirmation(_, text, onYes)
    local shell = Skin.Shell
    if not shell or not shell.MainFrame then return end
    local overlay = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
        AutoButtonColor = false, Text = "", ZIndex = 200, BorderSizePixel = 0,
    }, shell.MainFrame)
    local panel = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 201,
    }, overlay)
    corner(panel, 6)
    outline(panel, P.Outline, 1)
    make("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, panel)
    make("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

    label({
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tidy(text), TextWrapped = true,
        Font = FONT_BODY, TextSize = 17, TextColor3 = P.TextPrimary, ZIndex = 202, LayoutOrder = 1,
    }, panel)

    local buttons = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 202, LayoutOrder = 2 }, panel)
    local function pill(txt, x, fillCol, textCol)
        local b = make("TextButton", {
            Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = fillCol, AutoButtonColor = false, Text = txt, Font = FONT_SEMI, TextSize = 16,
            TextColor3 = textCol, ZIndex = 203, BorderSizePixel = 0,
        }, buttons)
        corner(b, 5)
        return b
    end
    local no = pill("Cancel", 0, P.ContentBg, P.TextPrimary)
    local yes = pill("Confirm", 0.5, P.Accent, P.MainBg)
    no.MouseButton1Click:Connect(function() overlay:Destroy() end)
    yes.MouseButton1Click:Connect(function()
        overlay:Destroy()
        onYes()
    end)
end

----------------------------------------------------------------------
-- notifications (stacked toasts, bottom centre)
----------------------------------------------------------------------

local toastHost
local toasts = {}

function Skin.SendNotification(text, color)
    if not toastHost or not toastHost.Parent then return end
    local accent = color or P.Accent

    local toast = make("Frame", {
        Size = UDim2.new(0, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.SidebarBg,
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, toastHost)
    corner(toast, 5)
    local frame = outline(toast, P.Outline, 1)
    frame.Transparency = 1
    make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16) }, toast)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
    }, toast)
    local bar = make("Frame", { Size = UDim2.new(0, 3, 0, 20), BackgroundColor3 = accent, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1 }, toast)
    corner(bar, 2)
    local msg = label({
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = tidy(text),
        Font = FONT_SEMI, TextSize = 16, TextColor3 = P.TextPrimary, TextTransparency = 1, LayoutOrder = 2,
    }, toast)

    table.insert(toasts, toast)
    while #toasts > 4 do
        local old = table.remove(toasts, 1)
        if old and old.Parent then old:Destroy() end
    end

    tween(toast, 0.18, { BackgroundTransparency = 0.04 })
    tween(bar, 0.18, { BackgroundTransparency = 0 })
    tween(msg, 0.18, { TextTransparency = 0 })
    tween(frame, 0.18, { Transparency = 0 })

    task.delay(2.8, function()
        if not toast.Parent then return end
        tween(toast, 0.25, { BackgroundTransparency = 1 })
        tween(bar, 0.25, { BackgroundTransparency = 1 })
        tween(msg, 0.25, { TextTransparency = 1 })
        tween(frame, 0.25, { Transparency = 1 })
        task.wait(0.3)
        local i = table.find(toasts, toast)
        if i then table.remove(toasts, i) end
        if toast.Parent then toast:Destroy() end
    end)
end

----------------------------------------------------------------------
-- window
----------------------------------------------------------------------

function Skin.Mount(env)
    Env, P = env, env.Theme
    toasts = {}

    local S = {}
    Skin.Shell = S
    local settings = env.Settings
    local gui = env.ScreenGui

    toastHost = make("Frame", {
        Name = "PhFolioToasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
        Size = UDim2.new(0, 360, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 20000,
    }, gui)
    make("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }, toastHost)

    local W = (settings.MainFrameSize and settings.MainFrameSize.W) or 540
    local H = (settings.MainFrameSize and settings.MainFrameSize.H) or 340
    local mp = settings.MainFramePos
    local main = make("Frame", {
        Name = "MainFrame", Size = UDim2.new(0, W, 0, H),
        Position = mp and UDim2.new(mp.X, mp.XOff, mp.Y, mp.YOff) or UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = P.MainBg, BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
    }, gui)
    corner(main, 6)
    outline(main, P.Outline, 1)
    S.MainFrame = main

    local function savePos()
        settings.MainFramePos = {
            X = main.Position.X.Scale, XOff = main.Position.X.Offset,
            Y = main.Position.Y.Scale, YOff = main.Position.Y.Offset,
        }
        env.saveSettings()
    end

    -- title band ------------------------------------------------------
    local band = make("Frame", { Name = "TitleBand", Size = UDim2.new(1, 0, 0, 68), BackgroundColor3 = P.SidebarBg, BorderSizePixel = 0, ZIndex = 2 }, main)
    local bar = make("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 3 }, band)

    local brand = make("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, ZIndex = 3 }, bar)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), VerticalAlignment = Enum.VerticalAlignment.Center }, brand)
    label({ Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "Phantom", Font = FONT_HEAD, TextSize = 18, TextColor3 = P.TextPrimary, ZIndex = 3, LayoutOrder = 1 }, brand)
    label({ Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = tostring(env.Version or ""), Font = FONT_BODY, TextSize = 14, TextColor3 = P.TextSecondary, ZIndex = 3, LayoutOrder = 2 }, brand)

    local close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 28, 0, 28),
        BackgroundTransparency = 1, Text = "\195\151", Font = FONT_BOLD, TextSize = 26, TextColor3 = P.TextSecondary,
        AutoButtonColor = false, ZIndex = 4, BorderSizePixel = 0,
    }, bar)
    close.MouseEnter:Connect(function() tween(close, 0.1, { TextColor3 = P.Red }) end)
    close.MouseLeave:Connect(function() tween(close, 0.1, { TextColor3 = P.TextSecondary }) end)
    close.MouseButton1Click:Connect(function() main.Visible = false end)

    local searchWrap = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0), Size = UDim2.new(0, 180, 0, 24),
        BackgroundColor3 = P.ContentBg, BorderSizePixel = 0, ZIndex = 3,
    }, bar)
    corner(searchWrap, 4)
    local searchLine = outline(searchWrap, P.Outline, 1)
    local searchBox = make("TextBox", {
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Find a feature", PlaceholderColor3 = P.TextSecondary, TextColor3 = P.TextPrimary,
        Font = FONT_BODY, TextSize = 15, TextXAlignment = LEFT, ClearTextOnFocus = false, ZIndex = 4, BorderSizePixel = 0,
    }, searchWrap)
    searchBox.Focused:Connect(function() tween(searchWrap, 0.12, { BackgroundColor3 = P.ItemHover }); searchLine.Color = P.Accent end)
    searchBox.FocusLost:Connect(function() tween(searchWrap, 0.12, { BackgroundColor3 = P.ContentBg }); searchLine.Color = P.Outline end)

    -- drag ------------------------------------------------------------
    local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
    local lockWarned = false
    bar.InputBegan:Connect(function(input)
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
    bar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
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

    -- tab strip + body ------------------------------------------------
    local strip = make("ScrollingFrame", {
        Name = "Tabs", Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3,
    }, band)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }, strip)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, strip)

    local body = make("Frame", { Name = "Body", Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68), BackgroundColor3 = P.MainBg, BorderSizePixel = 0 }, main)
    make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, body)

    local pages, tabs, tabOf = {}, {}, {}
    local current
    local suppress = false

    function S.CreatePage(name)
        local page = make("ScrollingFrame", {
            Name = name .. "Frame", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            Visible = false, ScrollBarThickness = 3, ScrollBarImageColor3 = P.Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, body)
        Skin.createLayout(page)
        pages[name] = page
        return page
    end

    local searchPage = S.CreatePage("SearchResults")

    local function paintTabs(active)
        for _, t in ipairs(tabs) do
            local on = (t.btn == active)
            tween(t.btn, 0.12, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and P.TextPrimary or P.TextSecondary })
            t.foot.BackgroundTransparency = on and 0 or 1
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
        frame.Position = UDim2.new(0, 0, 0, 8)
        tween(frame, 0.14, { Position = UDim2.new(0, 0, 0, 0) })
        current = { btn = btn, frame = frame }
    end

    function S.CreateTabButton(_, labelText, frame)
        local btn = make("TextButton", {
            Size = UDim2.new(0, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.MainBg,
            BackgroundTransparency = 1, AutoButtonColor = false, Text = tidy(labelText), Font = FONT_SEMI, TextSize = 16,
            TextColor3 = P.TextSecondary, BorderSizePixel = 0, ZIndex = 3, LayoutOrder = #tabs + 1,
        }, strip)
        make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, btn)
        corner(btn, 6)
        local foot = make("Frame", {
            Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = P.MainBg,
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
        }, btn)
        local entry = { btn = btn, frame = frame, foot = foot, label = btn.Text }
        tabs[#tabs + 1] = entry
        tabOf[frame] = entry
        btn.MouseEnter:Connect(function()
            if not (current and current.btn == btn) then tween(btn, 0.1, { TextColor3 = P.TextPrimary }) end
        end)
        btn.MouseLeave:Connect(function()
            if not (current and current.btn == btn) then tween(btn, 0.1, { TextColor3 = P.TextSecondary }) end
        end)
        btn.MouseButton1Click:Connect(function() S.SwitchTab(btn, frame) end)
        return btn
    end

    -- search ----------------------------------------------------------
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if suppress then return end
        local q = trim(searchBox.Text):lower()
        if q == "" then
            searchPage.Visible = false
            if current then
                for _, pg in pairs(pages) do pg.Visible = (pg == current.frame) end
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
                local row = make("TextButton", { Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = P.ContentBg, AutoButtonColor = false, Text = "", BorderSizePixel = 0 }, searchPage)
                corner(row, 5)
                label({ Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -130, 0, 18), Text = tidy(feat.n), Font = FONT_SEMI, TextSize = 16, TextColor3 = P.TextPrimary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                label({ Position = UDim2.new(0, 12, 0, 25), Size = UDim2.new(1, -130, 0, 16), Text = feat.d or "", Font = FONT_BODY, TextSize = 13, TextColor3 = P.TextSecondary, TextTruncate = Enum.TextTruncate.AtEnd }, row)
                label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0, 100, 0, 18), Text = tab and tab.label or "", Font = FONT_BODY, TextSize = 14, TextColor3 = P.Accent, TextXAlignment = RIGHT }, row)
                row.MouseEnter:Connect(function() tween(row, 0.1, { BackgroundColor3 = P.ItemHover }) end)
                row.MouseLeave:Connect(function() tween(row, 0.1, { BackgroundColor3 = P.ContentBg }) end)
                row.MouseButton1Click:Connect(function()
                    if tab then S.SwitchTab(tab.btn, tab.frame) end
                end)
            end
        end
        if shown == 0 then
            label({ Size = UDim2.new(1, -8, 0, 40), Text = "Nothing matches \226\128\156" .. searchBox.Text .. "\226\128\157. Try a shorter word.", Font = FONT_BODY, TextSize = 16, TextColor3 = P.TextSecondary, TextWrapped = true }, searchPage)
        end
    end)

    -- resize ----------------------------------------------------------
    local grip = make("TextButton", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.new(0, 22, 0, 22),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 50, BorderSizePixel = 0,
    }, main)
    for i, len in ipairs({ 14, 8 }) do
        make("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3 - (i - 1) * 5), Size = UDim2.new(0, len, 0, 2),
            Rotation = -45, BackgroundColor3 = P.TextSecondary, BorderSizePixel = 0, ZIndex = 51,
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
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - rStart
            main.Size = UDim2.new(0, math.clamp(rSize.X + d.X, 400, 1100), 0, math.clamp(rSize.Y + d.Y, 280, 800))
        end
    end))

    -- floating open button gets the same identity ---------------------
    local open = env.ToggleBtn
    if open then
        open.BackgroundColor3 = P.MainBg
        open.Text = "P"
        open.Font = FONT_HEAD
        open.TextSize = 24
        open.TextColor3 = P.Accent
        local cr = open:FindFirstChildOfClass("UICorner")
        if cr then cr.CornerRadius = UDim.new(0, 8) end
        local st = open:FindFirstChildOfClass("UIStroke")
        if st then st.Color, st.Thickness = P.Accent, 1.5 end
    end

    return S
end

return Skin
