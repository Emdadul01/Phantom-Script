if not getgenv or not getgenv().PhantomShared then return end

local env = getgenv()
if env.PhantomDashboard then pcall(env.PhantomDashboard.Destroy) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local api, conns, gui = {}, {}, nil
local function track(c) conns[#conns + 1] = c return c end

local function build()
    local S = env.PhantomShared
    local Settings, Theme = S.Settings, S.Theme
    local GUI_NAME = "Phantom_Dashboard"
    local TOGGLE_KEY = "📊 Dashboard"
    local WIDTH = 228
    local SAMPLES = 32
    local SAMPLE_TIME = 0.25

    local function new(class, props, parent)
        local obj = Instance.new(class)
        if obj:IsA("GuiObject") then obj.BorderSizePixel = 0 end
        for k, v in pairs(props) do obj[k] = v end
        obj.Parent = parent
        return obj
    end

    local function skin(obj, radius, strokeColor)
        Instance.new("UICorner", obj).CornerRadius = UDim.new(0, radius)
        if strokeColor then S.AddStroke(obj, strokeColor, 1) end
        return obj
    end

    local function label(parent, text, size, font, color, pos, sz, align)
        return new("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            TextSize = size,
            Font = font,
            TextColor3 = color,
            Position = pos,
            Size = sz,
            TextXAlignment = align or Enum.TextXAlignment.Left,
        }, parent)
    end

    local function viewport()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(800, 600)
    end

    gui = new("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 998,
        Enabled = Settings[TOGGLE_KEY] == true,
    }, PlayerGui)

    local root = new("Frame", {
        Name = "Root",
        Size = UDim2.new(0, WIDTH, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.MainBg,
        BorderSizePixel = 0,
    }, gui)
    skin(root, 10, Theme.Outline)

    do
        local p = Settings.DashboardPos
        if type(p) == "table" and p.X and p.Y then
            local vp = viewport()
            root.Position = UDim2.fromOffset(
                math.clamp(p.X * vp.X, 0, math.max(vp.X - WIDTH, 0)),
                math.clamp(p.Y * vp.Y, 0, math.max(vp.Y - 40, 0)))
        else
            root.Position = UDim2.fromOffset(12, 64)
        end
    end

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.SidebarBg,
        BorderSizePixel = 0,
        Active = true,
    }, root)
    skin(header, 10)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.SidebarBg,
        BorderSizePixel = 0,
    }, header)

    skin(new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, 12, 0.5, -3),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, header), 3)
    label(header, "DASHBOARD", 11, Enum.Font.GothamBold, Theme.TextPrimary,
        UDim2.fromOffset(26, 0), UDim2.new(1, -60, 1, 0))

    local collapseBtn = new("TextButton", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -28, 0.5, -11),
        BackgroundColor3 = Theme.ItemHover,
        Text = "–",
        TextColor3 = Theme.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, header)
    skin(collapseBtn, 6)

    local body = new("Frame", {
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, root)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    }, body)
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, body)

    local function stat(parent, title, order)
        local cell = new("Frame", { BackgroundColor3 = Theme.ContentBg, BorderSizePixel = 0, LayoutOrder = order }, parent)
        skin(cell, 6, Theme.Outline)
        label(cell, title, 9, Enum.Font.GothamBold, Theme.TextSecondary,
            UDim2.fromOffset(8, 5), UDim2.new(1, -16, 0, 11))
        return label(cell, "--", 15, Enum.Font.Code, Theme.TextPrimary,
            UDim2.fromOffset(8, 18), UDim2.new(1, -16, 0, 18))
    end

    local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 86), BackgroundTransparency = 1, LayoutOrder = 1 }, body)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -3, 0, 40),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    local fpsVal = stat(grid, "FPS", 1)
    local pingVal = stat(grid, "PING  ms", 2)
    local speedVal = stat(grid, "SPEED  st/s", 3)
    local hpVal = stat(grid, "HEALTH", 4)

    local histHead = new("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 2 }, body)
    label(histHead, "FRAME RATE  ·  8s", 9, Enum.Font.GothamBold, Theme.TextSecondary,
        UDim2.new(), UDim2.new(0.5, 0, 1, 0))
    local histInfo = label(histHead, "", 9, Enum.Font.Code, Theme.TextSecondary,
        UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Right)

    local graph = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.ContentBg, BorderSizePixel = 0, LayoutOrder = 3 }, body)
    skin(graph, 6, Theme.Outline)
    local plot = new("Frame", {
        Position = UDim2.fromOffset(5, 4), Size = UDim2.new(1, -10, 1, -8),
        BackgroundTransparency = 1, ClipsDescendants = true,
    }, graph)
    local bars = {}
    for i = 1, SAMPLES do
        bars[i] = new("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new((i - 1) / SAMPLES, 0, 1, 0),
            Size = UDim2.new(1 / SAMPLES, -1, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        }, plot)
    end

    local posRow = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.ContentBg,
        Text = "", AutoButtonColor = false, LayoutOrder = 4,
    }, body)
    skin(posRow, 6, Theme.Outline)
    label(posRow, "POS", 9, Enum.Font.GothamBold, Theme.TextSecondary,
        UDim2.fromOffset(8, 0), UDim2.fromOffset(26, 26))
    local posVal = label(posRow, "--", 11, Enum.Font.Code, Theme.TextPrimary,
        UDim2.fromOffset(36, 0), UDim2.new(1, -44, 1, 0))

    local actionHead = label(body, "QUICK ACTIONS", 9, Enum.Font.GothamBold, Theme.TextSecondary,
        UDim2.new(), UDim2.new(1, 0, 0, 12))
    actionHead.LayoutOrder = 5

    local actionGrid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 6 }, body)
    new("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -4, 0, 28),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, actionGrid)

    local footer = new("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 7 }, body)
    local playersLbl = label(footer, "", 9, Enum.Font.Code, Theme.TextSecondary,
        UDim2.new(), UDim2.new(0.5, 0, 1, 0))
    local uptimeLbl = label(footer, "", 9, Enum.Font.Code, Theme.TextSecondary,
        UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, 1, 0), Enum.TextXAlignment.Right)

    local function char()
        local c = Player.Character
        return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
    end

    local A = S.Actions or {}
    local defs = {
        { "Fly", A.Fly },
        { "Noclip", A.Noclip },
        { "Freeze", A.Freeze },
        { "VFly", A.VFly },
        {
            "Sit",
            {
                get = function() local _, h = char() return h and h.Sit or false end,
                set = function(v) local _, h = char() if h then h.Sit = v end end,
            },
        },
        { "Dash", A.Dash },
    }

    local buttons = {}
    for i, d in ipairs(defs) do
        local name, act = d[1], d[2]
        if act then
            local b = new("TextButton", {
                BackgroundColor3 = Theme.ItemHover, Text = name, TextSize = 11,
                TextColor3 = Theme.TextSecondary, Font = Enum.Font.GothamSemibold,
                AutoButtonColor = false, LayoutOrder = i,
            }, actionGrid)
            skin(b, 6)
            local stroke = S.AddStroke(b, Theme.Outline, 1)
            local entry = { btn = b, stroke = stroke, act = act, on = nil }
            buttons[#buttons + 1] = entry

            track(b.MouseButton1Click:Connect(function()
                if act.press then
                    act.press()
                    local t = TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Accent })
                    t:Play()
                    t.Completed:Connect(function()
                        TweenService:Create(b, TweenInfo.new(0.2), { BackgroundColor3 = Theme.ItemHover }):Play()
                    end)
                else
                    act.set(not act.get())
                end
            end))
        end
    end
    if #buttons == 0 then actionHead.Visible = false actionGrid.Visible = false end

    local function paintButton(e, on)
        if e.on == on then return end
        e.on = on
        local col = on and Theme.Green or Theme.TextSecondary
        TweenService:Create(e.btn, TweenInfo.new(0.12), { TextColor3 = col }):Play()
        e.stroke.Color = on and Theme.Green or Theme.Outline
    end

    local function grade(v, good, warn, invert)
        local ok = invert and v <= good or (not invert and v >= good)
        local mid = invert and v <= warn or (not invert and v >= warn)
        return ok and Theme.Green or (mid and Theme.Yellow or Theme.Red)
    end

    local function clock(sec)
        return string.format("%02d:%02d:%02d", sec // 3600, sec % 3600 // 60, sec % 60)
    end

    local fps = table.create(SAMPLES, 0)
    local frames, acc, uiAcc = 0, 0, 0
    local started = S.StartTime or tick()

    local function redraw()
        local lo, sum, n, top = math.huge, 0, 0, 60
        for i = 1, SAMPLES do
            local v = fps[i]
            if v > 0 then lo = math.min(lo, v) sum = sum + v n = n + 1 end
            top = math.max(top, v)
        end
        for i = 1, SAMPLES do
            local v = fps[i]
            bars[i].Size = UDim2.new(1 / SAMPLES, -1, math.clamp(v / top, 0, 1), 0)
            bars[i].BackgroundColor3 = v >= 50 and Theme.Accent or (v >= 30 and Theme.Yellow or Theme.Red)
            bars[i].BackgroundTransparency = v > 0 and 0.15 or 1
        end
        if lo ~= math.huge then
            histInfo.Text = string.format("avg %d  low %d", math.floor(sum / n + 0.5), lo)
        end
    end

    local function readPing()
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        return ok and v or nil
    end

    local function refreshStats(rate)
        if rate then
            fpsVal.Text = tostring(rate)
            fpsVal.TextColor3 = grade(rate, 50, 30)
        end

        local ping = readPing()
        if ping then
            pingVal.Text = tostring(math.floor(ping + 0.5))
            pingVal.TextColor3 = grade(ping, 80, 160, true)
        end

        local _, hum, hrp = char()
        if hrp then
            local v = hrp.AssemblyLinearVelocity
            speedVal.Text = string.format("%.1f", Vector3.new(v.X, 0, v.Z).Magnitude)
            local p = hrp.Position
            posVal.Text = string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
        end
        if hum then
            hpVal.Text = tostring(math.ceil(hum.Health))
            hpVal.TextColor3 = grade(hum.Health / math.max(hum.MaxHealth, 1), 0.6, 0.3)
        end

        for _, e in ipairs(buttons) do
            if e.act.get then paintButton(e, e.act.get() and true or false) end
        end

        playersLbl.Text = string.format("%d / %d players", #Players:GetPlayers(), Players.MaxPlayers)
        uptimeLbl.Text = clock(math.floor(tick() - started))
    end

    track(RunService.Heartbeat:Connect(function(dt)
        if not gui.Enabled then return end
        frames = frames + 1
        acc = acc + dt
        if acc < SAMPLE_TIME then return end
        local rate = math.floor(frames / acc + 0.5)
        frames, acc = 0, 0
        table.remove(fps, 1)
        fps[SAMPLES] = rate
        redraw()
        refreshStats(rate)
    end))

    track(posRow.MouseButton1Click:Connect(function()
        local _, _, hrp = char()
        if hrp and setclipboard then
            local p = hrp.Position
            setclipboard(string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z))
            S.SendNotification("Position copied", Theme.Accent)
        end
    end))

    local collapsed = Settings.DashboardCollapsed == true
    local function applyCollapsed()
        body.Visible = not collapsed
        collapseBtn.Text = collapsed and "+" or "–"
    end
    applyCollapsed()
    track(collapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        Settings.DashboardCollapsed = collapsed
        S.saveSettings()
        applyCollapsed()
    end))

    local dragging, dragFrom, rootFrom, warned
    track(header.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging, dragFrom, warned = true, input.Position, false
            rootFrom = root.AbsolutePosition
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragFrom
        if Settings["🔒 Lock GUI Drag"] == true then
            if d.Magnitude > 5 and not warned then
                warned = true
                S.SendNotification("Disable lock gui first", Theme.Red)
            end
            return
        end
        local vp = viewport()
        root.Position = UDim2.fromOffset(
            math.clamp(rootFrom.X + d.X, 0, math.max(vp.X - WIDTH, 0)),
            math.clamp(rootFrom.Y + d.Y, 0, math.max(vp.Y - 40, 0)))
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if not dragging or (t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch) then return end
        dragging = false
        if Settings["🔒 Lock GUI Drag"] == true then return end
        local vp, abs = viewport(), root.AbsolutePosition
        Settings.DashboardPos = { X = abs.X / vp.X, Y = abs.Y / vp.Y }
        S.saveSettings()
    end))

    redraw()
    refreshStats()
end

function api.SetVisible(v)
    if gui then gui.Enabled = v and true or false end
end

function api.Destroy()
    for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
    table.clear(conns)
    if gui then gui:Destroy() gui = nil end
end

function api.Rebuild()
    api.Destroy()
    build()
end

env.PhantomDashboard = api

local prevCleanup = _G.Phantom_Cleanup
_G.Phantom_Cleanup = function()
    api.Destroy()
    env.PhantomDashboard = nil
    if prevCleanup then prevCleanup() end
end

build()
