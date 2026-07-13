repeat task.wait() until game:IsLoaded()
-- ============================================================
-- F.9 Hub v5.3 - FULL SIZE, NO PILL ACCENT, CUSTOM BG
-- ============================================================

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local Lighting        = game:GetService("Lighting")
local LP              = Players.LocalPlayer

local _isfile   = isfile   or (syn and syn.isfile)   or function() return false end
local _readfile = readfile  or (syn and syn.readfile)  or function() return nil  end
local _writefile= writefile or (syn and syn.writefile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    normalSpeed=59, carrySpeed=30, laggerSpeed=60,
    aimbotSpeed=56.5,
    speedToggled=false, laggerEnabled=false,
    infJumpEnabled=false, antiRagdollEnabled=false, fpsBoostEnabled=false,
    guiVisible=true, uiLocked=false,
    isStealing=false, stealStartTime=nil, lastStealTick=0,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false,
    hittingCooldown=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, batLockEnabled=false,
    lastMoveDir=Vector3.new(0,0,0),
    unwalkEnabled=false,
    _prevCarry=30, _prevSpeed=false,
    _laggerOriginalCarry=30,
    autoStealEnabled=false,
    duelLaggerActive=false,
    duelLaggerThread=nil,
    countdownActive=false,
    espEnabled=false,
}

local Keys = {
    speed      = Enum.KeyCode.Q,
    lagger     = Enum.KeyCode.R,
    autoLeft   = Enum.KeyCode.Z,
    autoRight  = Enum.KeyCode.C,
    drop       = Enum.KeyCode.H,
    tpDown     = Enum.KeyCode.V,
    aimbot     = Enum.KeyCode.E,
    unwalk     = Enum.KeyCode.U,
    guiHide    = Enum.KeyCode.LeftControl,
    duelLagger = Enum.KeyCode.F,
    instaReset = Enum.KeyCode.G,
}

local Steal = {
    AutoStealEnabled=false, StealRadius=20, StealDuration=0.25,
    Data={}, plotCache={}, plotCacheTime={}, cachedPrompts={}, promptCacheTime=0,
}

local Presets = {}
local PRESET_FILE = "F9HubPresets.json"
local LAST_PRESET_FILE = "F9HubLastPreset.json"
local CONFIG_FILE = "F9HubConfig.json"

local POS={
    L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
    R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,anchor={},progress=nil,batCounter=nil,unwalk=nil,esp=nil}

local PLOT_CACHE_DURATION=2
local PROMPT_CACHE_REFRESH=0.15
local STEAL_COOLDOWN=0.1
local MEDUSA_COOLDOWN=25
local DROP_AUTO_OFF_DELAY=0.15

local isTouchEnabled = UIS.TouchEnabled
local duelLaggerWaitTime = isTouchEnabled and 5.8 or 0.25

local h,hrp
local speedBoxRefs={}
local keybindBtnRefs={}
local toggleRefs={}
local mbGroup
local setAL, setAR, setAB

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function getKeyName(kc)
    if not kc then return "—" end
    local n = kc.Name
    if n == "Unknown" then return "—" end
    if n == "LeftControl" then return "CTRL" end
    if n == "RightControl" then return "RCTL" end
    if n == "LeftShift" then return "SHFT" end
    if n == "Space" then return "SPC" end
    return n:sub(1, 4):upper()
end

-- ============================================================
-- PRESET FUNCTIONS
-- ============================================================
local function buildPresetSnapshot()
    return {
        normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed, laggerSpeed=State.laggerSpeed,
        aimbotSpeed=State.aimbotSpeed,
        stealRadius=Steal.StealRadius, stealDuration=Steal.StealDuration,
        infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
        fpsBoost=State.fpsBoostEnabled, medusaCounter=State.medusaCounterEnabled,
        batCounter=State.batCounterEnabled, autoSteal=Steal.AutoStealEnabled,
        espEnabled=State.espEnabled,
    }
end

local function savePresetsFile()
    local ok,encoded=pcall(function() return HttpService:JSONEncode(Presets) end)
    if ok then pcall(function() _writefile(PRESET_FILE,encoded) end) end
end

local function loadPresetsFile()
    local hasFile=false; pcall(function() hasFile=_isfile(PRESET_FILE) end)
    if not hasFile then return end
    local raw; pcall(function() raw=_readfile(PRESET_FILE) end)
    if not raw then return end
    local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then Presets=decoded end
end

local function saveLastPresetName(name)
    local ok,encoded=pcall(function() return HttpService:JSONEncode({lastPreset=name}) end)
    if ok then pcall(function() _writefile(LAST_PRESET_FILE,encoded) end) end
end

local function loadLastPresetName()
    local hasFile=false; pcall(function() hasFile=_isfile(LAST_PRESET_FILE) end)
    if not hasFile then return nil end
    local raw; pcall(function() raw=_readfile(LAST_PRESET_FILE) end)
    if not raw then return nil end
    local ok,decoded=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then return decoded.lastPreset end
    return nil
end

-- ============================================================
-- CONFIG SAVE/LOAD
-- ============================================================
local function saveConfig()
    local cfg = {
        normalSpeed = State.normalSpeed,
        carrySpeed = State.carrySpeed,
        laggerSpeed = State.laggerSpeed,
        aimbotSpeed = State.aimbotSpeed,
        stealRadius = Steal.StealRadius,
        stealDuration = Steal.StealDuration,
        speedKey = Keys.speed.Name,
        autoLeftKey = Keys.autoLeft.Name,
        autoRightKey = Keys.autoRight.Name,
        guiHideKey = Keys.guiHide.Name,
        dropKey = Keys.drop.Name,
        laggerKey = Keys.lagger.Name,
        tpDownKey = Keys.tpDown.Name,
        aimbotKey = Keys.aimbot.Name,
        unwalkKey = Keys.unwalk.Name,
        duelLaggerKey = Keys.duelLagger.Name,
        instaResetKey = Keys.instaReset.Name,
        espEnabled = State.espEnabled,
    }
    local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok and enc then 
        pcall(function() _writefile(CONFIG_FILE, enc) end) 
    end
end

local function loadConfig()
    local has = false
    pcall(function() has = _isfile(CONFIG_FILE) end)
    if not has then return end
    local raw
    pcall(function() raw = _readfile(CONFIG_FILE) end)
    if not raw then return end
    local cfg
    local ok = pcall(function() cfg = HttpService:JSONDecode(raw) end)
    if not ok or not cfg then return end
    
    if cfg.normalSpeed then State.normalSpeed = cfg.normalSpeed end
    if cfg.carrySpeed then State.carrySpeed = cfg.carrySpeed end
    if cfg.laggerSpeed then State.laggerSpeed = cfg.laggerSpeed end
    if cfg.aimbotSpeed then State.aimbotSpeed = cfg.aimbotSpeed end
    if cfg.stealRadius then Steal.StealRadius = cfg.stealRadius end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration end
    if cfg.espEnabled ~= nil then State.espEnabled = cfg.espEnabled end
    
    local function tryKey(field, kt)
        if cfg[field] and Enum.KeyCode[cfg[field]] then
            Keys[kt] = Enum.KeyCode[cfg[field]]
        end
    end
    tryKey("speedKey", "speed")
    tryKey("autoLeftKey", "autoLeft")
    tryKey("autoRightKey", "autoRight")
    tryKey("guiHideKey", "guiHide")
    tryKey("dropKey", "drop")
    tryKey("laggerKey", "lagger")
    tryKey("tpDownKey", "tpDown")
    tryKey("aimbotKey", "aimbot")
    tryKey("unwalkKey", "unwalk")
    tryKey("duelLaggerKey", "duelLagger")
    tryKey("instaResetKey", "instaReset")
end

-- ============================================================
-- CLEANUP OLD GUIs
-- ============================================================
for _,name in pairs({"F9Hub_v5_3"}) do
    pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
    pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
end

-- ============================================================
-- ROOT GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "F9Hub_v5_3"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then pcall(function() gui.Parent = LP.PlayerGui end) end

local uiScaleObj = Instance.new("UIScale", gui)
uiScaleObj.Scale = 0.7

-- ============================================================
-- COLORS
-- ============================================================
local YELLOW = Color3.fromRGB(255, 255, 0)
local DARK_YELLOW = Color3.fromRGB(200, 180, 0)
local BLACKISH = Color3.fromRGB(20,20,20)
local C = {
    bg          = Color3.fromRGB(0, 0, 0),
    panel       = Color3.fromRGB(20, 20, 20),
    card        = Color3.fromRGB(25, 25, 25),
    cardHov     = Color3.fromRGB(35, 35, 35),
    border      = Color3.fromRGB(60, 60, 60),
    borderDim   = Color3.fromRGB(40, 40, 40),
    text        = YELLOW,
    textSub     = DARK_YELLOW,
    textDim     = Color3.fromRGB(100, 100, 0),
    accent      = YELLOW,
    pillOff     = Color3.fromRGB(38, 38, 38),
    pillOn      = Color3.fromRGB(50, 50, 50),
    dotOff      = Color3.fromRGB(65, 65, 65),
    dotOn       = YELLOW,
    header      = Color3.fromRGB(0, 0, 0),
    chipBg      = Color3.fromRGB(40, 40, 40),
    chipText    = YELLOW,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function mkStroke(p,col,th)
    local s=Instance.new("UIStroke",p); s.Color=col or Color3.fromRGB(50,50,50); s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function makeDraggable(frame, handle, force)
    local src=handle or frame
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
    src.InputBegan:Connect(function(inp)
        if State.uiLocked and not force then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=frame.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    src.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp==dragInput and dragging and (force or not State.uiLocked) then
            local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
        end
    end)
end

local function setTextStyle(lbl, size)
    lbl.TextColor3 = YELLOW
    lbl.TextStrokeColor3 = Color3.fromRGB(20,20,20)
    lbl.TextStrokeTransparency = 0.2
    if size then lbl.TextSize = size end
end

local function animateTitle(lbl)
    local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(lbl, tweenInfo, {TextColor3 = BLACKISH})
    tween:Play()
    task.wait(1.2)
    local tween2 = TweenService:Create(lbl, tweenInfo, {TextColor3 = YELLOW})
    tween2:Play()
end

-- ============================================================
-- MAIN WINDOW (230x420)
-- ============================================================
local WIN_W = 230
local WIN_H = 420

local mainOuter = Instance.new("Frame", gui)
mainOuter.Name = "MainOuter"
mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainOuter.Position = UDim2.new(0, 8, 0, 8)
mainOuter.BackgroundColor3 = Color3.fromRGB(0,0,0)
mainOuter.BackgroundTransparency = 0.3
mainOuter.BorderSizePixel = 0
mainOuter.ClipsDescendants = true
mkCorner(mainOuter, 14)
mainOuter.ZIndex = 1

-- Background Image
local bgDecal = Instance.new("ImageLabel", mainOuter)
bgDecal.Size = UDim2.new(1, 0, 1, 0)
bgDecal.Position = UDim2.new(0, 0, 0, 0)
bgDecal.BackgroundTransparency = 1
bgDecal.Image = "rbxassetid://108437082962917"
bgDecal.ZIndex = 0
bgDecal.ScaleType = Enum.ScaleType.Crop
mkCorner(bgDecal, 14)

-- Pulsing outline
local borderStroke = Instance.new("UIStroke", mainOuter)
borderStroke.Color = YELLOW
borderStroke.Thickness = 0.6
borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mkCorner(mainOuter, 14)
task.spawn(function()
    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local tween1 = TweenService:Create(borderStroke, tweenInfo, {Color = BLACKISH})
    local tween2 = TweenService:Create(borderStroke, tweenInfo, {Color = YELLOW})
    while borderStroke and borderStroke.Parent do
        tween1:Play()
        task.wait(1.5)
        tween2:Play()
        task.wait(1.5)
    end
end)

makeDraggable(mainOuter)

-- ============================================================
-- HEADER (no pill accent)
-- ============================================================
local HEADER_H = 40
local headerFrame = Instance.new("Frame", mainOuter)
headerFrame.Size = UDim2.new(1, 0, 0, HEADER_H)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
headerFrame.BackgroundTransparency = 0.5
headerFrame.BorderSizePixel = 0
headerFrame.ZIndex = 3
mkCorner(headerFrame, 14)

local headerTitle = Instance.new("TextLabel", headerFrame)
headerTitle.Size = UDim2.new(1, -80, 1, 0)
headerTitle.Position = UDim2.new(0, 16, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "F.9 Hub"
headerTitle.Font = Enum.Font.GothamBlack
setTextStyle(headerTitle, 18)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.ZIndex = 4
task.spawn(function()
    while headerTitle and headerTitle.Parent do
        animateTitle(headerTitle)
        task.wait(0.5)
    end
end)

local minimizeBtn = Instance.new("TextButton", headerFrame)
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -38, 0.5, -13)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = YELLOW
minimizeBtn.TextStrokeColor3 = Color3.fromRGB(20,20,20)
minimizeBtn.TextStrokeTransparency = 0.2
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.ZIndex = 5
mkCorner(minimizeBtn, 6)
mkStroke(minimizeBtn, C.border, 1)
minimizeBtn.MouseButton1Click:Connect(function()
    mainOuter.Visible = not mainOuter.Visible
end)

local headerDiv = Instance.new("Frame", mainOuter)
headerDiv.Size = UDim2.new(1, 0, 0, 1)
headerDiv.Position = UDim2.new(0, 0, 0, HEADER_H)
headerDiv.BackgroundColor3 = C.border
headerDiv.BackgroundTransparency = 0.5
headerDiv.BorderSizePixel = 0
headerDiv.ZIndex = 3

-- ============================================================
-- SCROLL AREA
-- ============================================================
local SCROLL_Y = HEADER_H + 1
local scrollFrame = Instance.new("ScrollingFrame", mainOuter)
scrollFrame.Size = UDim2.new(1, 0, 1, -SCROLL_Y)
scrollFrame.Position = UDim2.new(0, 0, 0, SCROLL_Y)
scrollFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
scrollFrame.BackgroundTransparency = 0.85
scrollFrame.BorderSizePixel = 0
scrollFrame.ClipsDescendants = true
scrollFrame.ScrollBarThickness = 2
scrollFrame.ScrollBarImageColor3 = C.border
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ZIndex = 2
mkCorner(scrollFrame, 14)

local scrollLL = Instance.new("UIListLayout", scrollFrame)
scrollLL.SortOrder = Enum.SortOrder.LayoutOrder
scrollLL.Padding = UDim.new(0, 2)
local scrollPad = Instance.new("UIPadding", scrollFrame)
scrollPad.PaddingLeft = UDim.new(0, 6)
scrollPad.PaddingRight = UDim.new(0, 6)
scrollPad.PaddingTop = UDim.new(0, 4)
scrollPad.PaddingBottom = UDim.new(0, 8)

local loCount = 0
local function LO() loCount = loCount + 1; return loCount end

-- ============================================================
-- UI BUILDERS (transparent)
-- ============================================================
local function makeSectionHeader(label)
    local gap = Instance.new("Frame", scrollFrame)
    gap.Size = UDim2.new(1, 0, 0, 2)
    gap.BackgroundTransparency = 1
    gap.BorderSizePixel = 0
    gap.LayoutOrder = LO()
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label:upper()
    lbl.Font = Enum.Font.GothamBold
    setTextStyle(lbl, 9)
    lbl.TextColor3 = DARK_YELLOW
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
end

local function makeDivider()
    local f = Instance.new("Frame", scrollFrame)
    f.Size = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    f.BackgroundTransparency = 0.6
    f.BorderSizePixel = 0
    f.LayoutOrder = LO()
end

local function makeToggleRow(label, defaultOn, onToggle, keyRef)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = C.bg
    row.BackgroundTransparency = 0.8
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3
    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -20, 0, 1)
    div.Position = UDim2.new(0, 10, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BackgroundTransparency = 0.7
    div.BorderSizePixel = 0
    div.ZIndex = 4
    local lblX = 12
    if keyRef then
        local chip = Instance.new("TextButton", row)
        chip.Size = UDim2.new(0, 28, 0, 20)
        chip.Position = UDim2.new(0, 10, 0.5, -10)
        chip.BackgroundColor3 = C.chipBg
        chip.BackgroundTransparency = 0.7
        chip.BorderSizePixel = 0
        chip.Text = getKeyName(Keys[keyRef] or Enum.KeyCode.Unknown)
        chip.TextColor3 = YELLOW
        chip.TextStrokeColor3 = Color3.fromRGB(20,20,20)
        chip.TextStrokeTransparency = 0.2
        chip.Font = Enum.Font.GothamBold
        chip.TextSize = 9
        chip.ZIndex = 5
        mkCorner(chip, 5)
        mkStroke(chip, C.borderDim, 1)
        keybindBtnRefs[keyRef] = chip
        local listening = false
        local lkb, lgp = nil, nil
        local function stopListening(key)
            listening = false
            if lkb then lkb:Disconnect(); lkb = nil end
            if lgp then lgp:Disconnect(); lgp = nil end
            chip.TextColor3 = YELLOW
            if key then
                Keys[keyRef] = key
                chip.Text = getKeyName(key)
                task.spawn(saveConfig)
            else
                chip.Text = getKeyName(Keys[keyRef] or Enum.KeyCode.Unknown)
            end
        end
        chip.MouseButton1Click:Connect(function()
            if listening then stopListening(nil); return end
            listening = true
            chip.Text = "···"
            chip.TextColor3 = Color3.fromRGB(255,255,255)
            lkb = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then stopListening(nil); return end
                stopListening(inp.KeyCode)
            end)
            lgp = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                local isGp = inp.UserInputType == Enum.UserInputType.Gamepad1 or 
                            inp.UserInputType == Enum.UserInputType.Gamepad2
                if not isGp then return end
                if inp.KeyCode == Enum.KeyCode.Unknown then return end
                stopListening(inp.KeyCode)
            end)
        end)
        lblX = 46
    end
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -(lblX + 56), 1, 0)
    lbl.Position = UDim2.new(0, lblX, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    setTextStyle(lbl, 11)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.Position = UDim2.new(1, -48, 0.5, -10)
    pill.BackgroundColor3 = defaultOn and C.pillOn or C.pillOff
    pill.BackgroundTransparency = 0.7
    pill.BorderSizePixel = 0
    pill.ZIndex = 5
    mkCorner(pill, 10)
    mkStroke(pill, C.border, 1)
    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = defaultOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = defaultOn and C.dotOn or C.dotOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 6
    mkCorner(dot, 6)
    local isOn = defaultOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
    end
    local function toggle() isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end end
    local clk = Instance.new("TextButton", row)
    clk.Size = UDim2.new(1, -56, 1, 0)
    clk.Position = UDim2.new(0, lblX, 0, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 5
    clk.BorderSizePixel = 0
    clk.MouseButton1Click:Connect(toggle)
    local pClk = Instance.new("TextButton", pill)
    pClk.Size = UDim2.new(1, 0, 1, 0)
    pClk.BackgroundTransparency = 1
    pClk.Text = ""
    pClk.ZIndex = 7
    pClk.BorderSizePixel = 0
    pClk.MouseButton1Click:Connect(toggle)
    return setV
end

local function makeInputRow(label, default, onChange)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = C.bg
    row.BackgroundTransparency = 0.8
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3
    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -20, 0, 1)
    div.Position = UDim2.new(0, 10, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BackgroundTransparency = 0.7
    div.BorderSizePixel = 0
    div.ZIndex = 4
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    setTextStyle(lbl, 11)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    local boxWrap = Instance.new("Frame", row)
    boxWrap.Size = UDim2.new(0, 56, 0, 24)
    boxWrap.Position = UDim2.new(1, -66, 0.5, -12)
    boxWrap.BackgroundColor3 = C.card
    boxWrap.BackgroundTransparency = 0.7
    boxWrap.BorderSizePixel = 0
    mkCorner(boxWrap, 5)
    local bs = mkStroke(boxWrap, C.border, 1)
    local box = Instance.new("TextBox", boxWrap)
    box.Size = UDim2.new(1, -6, 1, 0)
    box.Position = UDim2.new(0, 3, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = tostring(default)
    box.TextColor3 = YELLOW
    box.TextStrokeColor3 = Color3.fromRGB(20,20,20)
    box.TextStrokeTransparency = 0.2
    box.Font = Enum.Font.GothamBold
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.ZIndex = 5
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.Focused:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=Color3.fromRGB(120,120,120)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=C.border}):Play()
        if onChange then
            local n=tonumber(box.Text)
            if n then onChange(n) else box.Text=tostring(default) end
        end
    end)
    return box, row
end

local function makeButtonRow(label, btnText, onClick)
    local row = Instance.new("Frame", scrollFrame)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = C.bg
    row.BackgroundTransparency = 0.8
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    row.ZIndex = 3
    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -20, 0, 1)
    div.Position = UDim2.new(0, 10, 1, -1)
    div.BackgroundColor3 = C.borderDim
    div.BackgroundTransparency = 0.7
    div.BorderSizePixel = 0
    div.ZIndex = 4
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    setTextStyle(lbl, 11)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 64, 0, 24)
    btn.Position = UDim2.new(1, -74, 0.5, -12)
    btn.BackgroundColor3 = C.card
    btn.BackgroundTransparency = 0.7
    btn.BorderSizePixel = 0
    btn.Text = btnText
    btn.TextColor3 = YELLOW
    btn.TextStrokeColor3 = Color3.fromRGB(20,20,20)
    btn.TextStrokeTransparency = 0.2
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.ZIndex = 5
    mkCorner(btn, 6)
    mkStroke(btn, C.border, 1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C.cardHov}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play() end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ============================================================
-- CORE FUNCTIONS (all of them)
-- ============================================================

-- TP DOWN
local function doTpDown()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local res=workspace:Raycast(root.Position,Vector3.new(0,-1000,0),rp)
        if res then
            root.CFrame=CFrame.new(res.Position+Vector3.new(0,root.Size.Y/2+0.5,0))
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end)
end

-- DROP BRAINROT
local function runDropBrainrot()
    if State.dropEnabled then return end
    State.dropEnabled=true
    task.spawn(function()
        local colConn=RunService.Stepped:Connect(function()
            if not State.dropEnabled then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and p.Character then
                    for _,part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide=false end
                    end
                end
            end
        end)
        task.spawn(function()
            while State.dropEnabled do
                RunService.Heartbeat:Wait()
                local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local vel=root.Velocity
                root.Velocity=vel*10000+Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.Velocity=vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
            end
        end)
        task.wait(DROP_AUTO_OFF_DELAY)
        State.dropEnabled=false
        colConn:Disconnect()
    end)
end

-- BAT AIMBOT
local VYSE_HIT_DIST = 5
local SWING_COOLDOWN = 0.08
local function getBat()
    local char = LP.Character; if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool and tool:IsA("Tool") then return tool end
    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        tool = backpack:FindFirstChild("Bat")
        if tool and tool:IsA("Tool") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(tool) end) end
            return tool
        end
    end
    return nil
end
local function tryHitBat()
    if State.hittingCooldown then return end
    State.hittingCooldown = true
    pcall(function()
        local bat = getBat()
        if bat then
            pcall(function() bat:Activate() end)
            local remote = bat:FindFirstChildWhichIsA("RemoteEvent")
            if remote then pcall(function() remote:FireServer() end) end
        end
    end)
    task.delay(SWING_COOLDOWN, function() State.hittingCooldown = false end)
end
local function getClosestPlayer()
    local char = LP.Character; if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil, math.huge end
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health > 0 then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < dist then dist = d; closest = p end
            end
        end
    end
    return closest, dist
end
local function startBatAimbot()
    if Conns.aimbot then return end
    Conns.aimbot = RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled or State.countdownActive then return end
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local target, dist = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local aimPoint = tr.Position + tr.CFrame.LookVector * 1.5
                local direction = (aimPoint - hrp.Position).Unit
                hrp.Velocity = direction * State.aimbotSpeed
                if dist <= VYSE_HIT_DIST and State.autoSwingEnabled then tryHitBat() end
            end
        else
            hrp.Velocity = Vector3.zero
        end
    end)
end
local function stopBatAimbot()
    if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot = nil end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Vector3.zero end
    State.hittingCooldown = false
end

-- INFINITE JUMP
UIS.JumpRequest:Connect(function()
    if not State.infJumpEnabled then return end
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
end)
RunService.Heartbeat:Connect(function()
    if not State.infJumpEnabled then return end
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.Velocity.Y < -120 then root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z) end
end)

-- DUEL LAGGER
local function duelBomb(amt)
    local main, spam = {}, {{}}
    local z = spam[1]
    for i = 1, amt do local t = {} table.insert(z, t); z = t end
    local max = math.min(499999/(amt+2), 1500)
    for i = 1, max do table.insert(main, spam) end
    pcall(function() game:GetService("RobloxReplicatedStorage").SetPlayerBlockList:FireServer(main) end)
end
local duelLaggerStatusLabel, duelLaggerSwitchBall = nil, nil
local function toggleDuelLagger()
    State.duelLaggerActive = not State.duelLaggerActive
    if duelLaggerStatusLabel then
        duelLaggerStatusLabel.Text = State.duelLaggerActive and "STATUS: ACTIVE" or "STATUS: INACTIVE"
        duelLaggerStatusLabel.TextColor3 = State.duelLaggerActive and Color3.fromRGB(220,220,220) or Color3.fromRGB(90,90,90)
    end
    if duelLaggerSwitchBall then
        TweenService:Create(duelLaggerSwitchBall, TweenInfo.new(0.2), {
            Position = State.duelLaggerActive and UDim2.new(1, -16, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = State.duelLaggerActive and Color3.fromRGB(220,220,220) or Color3.fromRGB(60,60,60),
        }):Play()
    end
    if State.duelLaggerActive then
        State.duelLaggerThread = task.spawn(function()
            while State.duelLaggerActive do
                pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
                duelBomb(270)
                task.wait(duelLaggerWaitTime)
            end
        end)
    else
        if State.duelLaggerThread then task.cancel(State.duelLaggerThread); State.duelLaggerThread = nil end
    end
end

-- MEDUSA COUNTER
local function findMedusa()
    local c=LP.Character; if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n=t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then return t end
        end
    end
    local bp=LP:FindFirstChild("Backpack")
    if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n=t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then return t end
            end
        end
    end
    return nil
end
local function useMedusaCounter()
    if State.medusaDebounce or tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
    local c=LP.Character; if not c then return end
    State.medusaDebounce=true
    local med=findMedusa()
    if med then
        if med.Parent~=c then
            local hum2=c:FindFirstChildOfClass("Humanoid")
            if hum2 then hum2:EquipTool(med) end
        end
        pcall(function() med:Activate() end)
        State.medusaLastUsed=tick()
    end
    State.medusaDebounce=false
end
local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency==1 then useMedusaCounter() end
    end)
end
local function setupMedusaCounter(char)
    for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end
    Conns.anchor={}
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
    end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
    end))
end
local function stopMedusaCounter()
    for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end
    Conns.anchor={}
end

-- ANTI RAGDOLL
local function startAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect() end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        if not State.antiRagdollEnabled then return end
        local c=LP.Character; if not c then return end
        local hum2=c:FindFirstChildOfClass("Humanoid"); local root=c:FindFirstChild("HumanoidRootPart")
        if not hum2 or not root or hum2.Health<=0 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Dead then return end
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            pcall(function() workspace.CurrentCamera.CameraSubject=hum2 end)
            pcall(function()
                local PM=LP.PlayerScripts:FindFirstChild("PlayerModule")
                if PM then
                    local CM=require(PM:FindFirstChild("ControlModule"))
                    if CM then CM:Enable() end
                end
            end)
            root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero
        end
        for _,obj in ipairs(c:GetDescendants()) do
            pcall(function() if obj:IsA("Motor6D") and obj.Enabled==false then obj.Enabled=true end end)
        end
    end)
end
local function stopAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end
end

-- AUTO LEFT / RIGHT
local function faceSouth()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,0,0) end
    end)
end
local function faceNorth()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.rad(180),0) end
    end)
end
local function startAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect() end
    State.autoLeftPhase=1
    Conns.autoLeft=RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled or State.countdownActive then return end
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoLeftPhase==1 then
            local tgt=Vector3.new(POS.L1.X,root.Position.Y,POS.L1.Z)
            if (tgt-root.Position).Magnitude<1 then
                State.autoLeftPhase=2
                local d=(POS.L2-root.Position)
                local mv=Vector3.new(d.X,0,d.Z).Unit
                hum2:Move(mv,false)
                root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=(POS.L1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoLeftPhase==2 then
            local tgt=Vector3.new(POS.L2.X,root.Position.Y,POS.L2.Z)
            if (tgt-root.Position).Magnitude<1 then
                hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero
                State.autoLeftEnabled=false
                if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end
                State.autoLeftPhase=1; faceSouth()
                return
            end
            local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end
    State.autoLeftPhase=1
    local c=LP.Character; if c then
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero,false) end
    end
end
local function startAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect() end
    State.autoRightPhase=1
    Conns.autoRight=RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled or State.countdownActive then return end
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoRightPhase==1 then
            local tgt=Vector3.new(POS.R1.X,root.Position.Y,POS.R1.Z)
            if (tgt-root.Position).Magnitude<1 then
                State.autoRightPhase=2
                local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
                hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=(POS.R1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoRightPhase==2 then
            local tgt=Vector3.new(POS.R2.X,root.Position.Y,POS.R2.Z)
            if (tgt-root.Position).Magnitude<1 then
                hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero
                State.autoRightEnabled=false
                if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end
                State.autoRightPhase=1; faceNorth()
                return
            end
            local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end
    State.autoRightPhase=1
    local c=LP.Character; if c then
        local hum2=c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero,false) end
    end
end

-- BAT COUNTER
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
    local c=LP.Character; if not c then return nil end
    local bp=LP:FindFirstChildOfClass("Backpack")
    for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end
local function swingBatForCounter(bat,char)
    local hum2=char:FindFirstChildOfClass("Humanoid")
    if bat.Parent~=char then
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
        task.wait(0.05)
    end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end); task.wait(0.15); pcall(function() remote:FireServer() end)
    else
        pcall(function() bat:Activate() end); task.wait(0.15); pcall(function() bat:Activate() end)
    end
end
local function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled or State.batCounterDebounce then return end
        local char=LP.Character; if not char then return end
        local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            State.batCounterDebounce=true
            task.spawn(function()
                local bat=findBatForCounter()
                if bat then swingBatForCounter(bat,char) end
                task.wait(0.5)
                State.batCounterDebounce=false
            end)
        end
    end)
end
local function stopBatCounter()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
    State.batCounterDebounce=false
end

-- UNWALK
local _unwalkAnimations={}
local function _disableAnimations()
    local char=LP.Character; if not char then return end
    local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
    for _,track in pairs(_unwalkAnimations) do pcall(function() track:Stop() end) end
    _unwalkAnimations={}
    local animator=hum2:FindFirstChildOfClass("Animator")
    if animator then
        for _,track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
            table.insert(_unwalkAnimations,track)
        end
    end
end
local function startUnwalk()
    _disableAnimations()
    if Conns.unwalk then Conns.unwalk:Disconnect() end
    Conns.unwalk=RunService.Heartbeat:Connect(function()
        if not State.unwalkEnabled then return end
        _disableAnimations()
    end)
end
local function stopUnwalk()
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    _unwalkAnimations={}
    local c=LP.Character
    if c then
        local anim=c:FindFirstChild("Animate")
        if anim and anim:IsA("LocalScript") and anim.Disabled then anim.Disabled=false end
    end
end

-- FPS BOOST
local function applyFPSBoost()
    pcall(function() setfpscap(999999999) end)
    local function pO(v) pcall(function()
        if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode=Enum.ModelStreamingMode.Nonatomic
        elseif v:IsA("MeshPart") then v.CastShadow=false; v.DoubleSided=false; v.RenderFidelity=Enum.RenderFidelity.Performance
        elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
        elseif v:IsA("SpecialMesh") then v.TextureId=""
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
        elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
        elseif v:IsA("Attachment") then v.Visible=false end
    end) end
    for _,v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        for _,v in pairs(Lighting:GetDescendants()) do pcall(function() if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end end) end
        pcall(function() sethiddenproperty(Lighting,"Technology",Enum.Technology.Legacy) end)
        Lighting.GlobalShadows=false; Lighting.FogEnd=9e9; Lighting.Brightness=0
        local ter=workspace:FindFirstChildOfClass("Terrain")
        if ter then pcall(function() sethiddenproperty(ter,"Decoration",false) end); ter.WaterReflectance=0; ter.WaterTransparency=0.7; ter.WaterWaveSize=0; ter.WaterWaveSpeed=0 end
    end)
    workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(pO,v) end end)
end

-- AUTO STEAL
local function isMyPlotByName(pn)
    local ct=tick()
    if Steal.plotCache[pn] and (ct-(Steal.plotCacheTime[pn] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[pn] end
    local plots=workspace:FindFirstChild("Plots")
    if not plots then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local plot=plots:FindFirstChild(pn)
    if not plot then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then
        local yb=sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            local r=yb.Enabled==true
            Steal.plotCache[pn]=r; Steal.plotCacheTime[pn]=ct; return r
        end
    end
    Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false
end
local function findNearestPrompt()
    local c=LP.Character; if not c then return nil end
    local root=c:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local ct=tick()
    if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
        local np,nd=nil,math.huge
        for _,data in ipairs(Steal.cachedPrompts) do
            if data.spawn then
                local dist=(data.spawn.Position-root.Position).Magnitude
                if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist end
            end
        end
        if np then return np end
    end
    Steal.cachedPrompts={}
    Steal.promptCacheTime=ct
    local plots=workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np,nd=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods=plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base=pod:FindFirstChild("Base")
                local sp=base and base:FindFirstChild("Spawn")
                if sp then
                    local att=sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _,child in ipairs(att:GetChildren()) do
                            if child:IsA("ProximityPrompt") then
                                local dist=(sp.Position-root.Position).Magnitude
                                table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp})
                                if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    return np
end
local function executeSteal(prompt)
    local ct=tick()
    if ct-State.lastStealTick<STEAL_COOLDOWN or State.isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt]={hold={},trigger={},ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end
                end
                for _,c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end
                end
            else
                Steal.Data[prompt].useFallback=true
            end
        end)
    end
    local data=Steal.Data[prompt]
    if not data.ready then return end
    data.ready=false
    State.isStealing=true
    State.stealStartTime=ct
    State.lastStealTick=ct
    task.spawn(function()
        local ok=false
        pcall(function()
            if not data.useFallback then
                for _,fn in ipairs(data.hold) do task.spawn(fn) end
                task.wait(Steal.StealDuration)
                for _,fn in ipairs(data.trigger) do task.spawn(fn) end
                ok=true
            end
        end)
        if not ok and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt); ok=true end)
        end
        if not ok then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(Steal.StealDuration)
                prompt:InputHoldEnd()
            end)
        end
        task.wait(Steal.StealDuration*0.3)
        task.wait(0.05)
        data.ready=true
        State.isStealing=false
    end)
end
local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or State.isStealing then return end
        local p=findNearestPrompt()
        if p then executeSteal(p) end
    end)
end
local function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
    State.isStealing=false; State.lastStealTick=0
    Steal.plotCache={}; Steal.plotCacheTime={}; Steal.cachedPrompts={}
end

-- PRESET APPLY
local function applyPreset(data)
    if data.normalSpeed then State.normalSpeed=data.normalSpeed; if speedBoxRefs.normalSpeed then speedBoxRefs.normalSpeed.Text=tostring(data.normalSpeed) end end
    if data.carrySpeed then State.carrySpeed=data.carrySpeed; if speedBoxRefs.carrySpeed then speedBoxRefs.carrySpeed.Text=tostring(data.carrySpeed) end end
    if data.laggerSpeed then State.laggerSpeed=data.laggerSpeed; if speedBoxRefs.laggerSpeed then speedBoxRefs.laggerSpeed.Text=tostring(data.laggerSpeed) end end
    if data.aimbotSpeed then State.aimbotSpeed=data.aimbotSpeed end
    if data.stealRadius then Steal.StealRadius=data.stealRadius; Steal.cachedPrompts={}; Steal.promptCacheTime=0 end
    if data.stealDuration then Steal.StealDuration=data.stealDuration end
    if data.infJump~=nil and toggleRefs.infJump then State.infJumpEnabled=data.infJump; toggleRefs.infJump(data.infJump) end
    if data.antiRagdoll~=nil and toggleRefs.antiRagdoll then State.antiRagdollEnabled=data.antiRagdoll; toggleRefs.antiRagdoll(data.antiRagdoll); if data.antiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end end
    if data.fpsBoost~=nil and toggleRefs.fpsBoost then State.fpsBoostEnabled=data.fpsBoost; toggleRefs.fpsBoost(data.fpsBoost); if data.fpsBoost then pcall(applyFPSBoost) end end
    if data.medusaCounter~=nil and toggleRefs.medusaCounter then State.medusaCounterEnabled=data.medusaCounter; toggleRefs.medusaCounter(data.medusaCounter); if data.medusaCounter then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end
    if data.batCounter~=nil and toggleRefs.batCounter then State.batCounterEnabled=data.batCounter; toggleRefs.batCounter(data.batCounter); if data.batCounter then startBatCounter() else stopBatCounter() end end
    if data.autoSteal~=nil and toggleRefs.autoSteal then Steal.AutoStealEnabled=data.autoSteal; toggleRefs.autoSteal(data.autoSteal); if data.autoSteal then pcall(startAutoSteal) else stopAutoSteal() end end
    if data.espEnabled~=nil and toggleRefs.esp then State.espEnabled=data.espEnabled; toggleRefs.esp(data.espEnabled); if data.espEnabled then pcall(startESP) else pcall(stopESP) end end
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local espObjects = {}
local espConnection = nil
local function cleanupESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    for _, obj in pairs(espObjects) do
        pcall(function()
            if obj.line then obj.line:Remove() end
            if obj.box then obj.box:Remove() end
            if obj.text then obj.text:Remove() end
        end)
    end
    espObjects = {}
end
local function startESP()
    if espConnection then return end
    if not Drawing then print("[ESP] Drawing not supported.") return end
    local cam = workspace.CurrentCamera
    espConnection = RunService.RenderStepped:Connect(function()
        if not State.espEnabled then return end
        local myChar = LP.Character; if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
        for userId, obj in pairs(espObjects) do
            local p = Players:FindFirstChild(tostring(userId))
            if not p or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    if obj.line then obj.line:Remove() end
                    if obj.box then obj.box:Remove() end
                    if obj.text then obj.text:Remove() end
                end)
                espObjects[userId] = nil
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                local rootPart = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if not rootPart then
                    if espObjects[p.UserId] then
                        pcall(function()
                            local obj = espObjects[p.UserId]
                            if obj.line then obj.line:Remove() end
                            if obj.box then obj.box:Remove() end
                            if obj.text then obj.text:Remove() end
                        end)
                        espObjects[p.UserId] = nil
                    end
                    continue
                end
                local pos, onScreen = cam:WorldToScreenPoint(rootPart.Position)
                if not onScreen then
                    if espObjects[p.UserId] then
                        pcall(function()
                            local obj = espObjects[p.UserId]
                            if obj.line then obj.line:Remove() end
                            if obj.box then obj.box:Remove() end
                            if obj.text then obj.text:Remove() end
                        end)
                        espObjects[p.UserId] = nil
                    end
                    continue
                end
                local screenPos = Vector2.new(pos.X, pos.Y)
                local obj = espObjects[p.UserId]
                if not obj then
                    obj = {}
                    obj.line = Drawing.new("Line")
                    obj.line.Color = YELLOW
                    obj.line.Thickness = 1.5
                    obj.line.Visible = true
                    obj.box = Drawing.new("Square")
                    obj.box.Color = YELLOW
                    obj.box.Thickness = 1.5
                    obj.box.Filled = false
                    obj.box.Visible = true
                    obj.text = Drawing.new("Text")
                    obj.text.Color = YELLOW
                    obj.text.Size = 14
                    obj.text.Center = true
                    obj.text.Visible = true
                    espObjects[p.UserId] = obj
                end
                local myScreen, _ = cam:WorldToScreenPoint(myRoot.Position)
                if myScreen then
                    obj.line.From = Vector2.new(myScreen.X, myScreen.Y)
                    obj.line.To = screenPos
                end
                local char = p.Character
                if char then
                    local min = Vector3.new(math.huge, math.huge, math.huge)
                    local max = Vector3.new(-math.huge, -math.huge, -math.huge)
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            local ppos = part.Position
                            local s = part.Size
                            local corners = {
                                ppos + Vector3.new(-s.X/2, -s.Y/2, -s.Z/2),
                                ppos + Vector3.new(s.X/2, s.Y/2, s.Z/2),
                                ppos + Vector3.new(-s.X/2, s.Y/2, -s.Z/2),
                                ppos + Vector3.new(s.X/2, -s.Y/2, s.Z/2),
                            }
                            for _, c in ipairs(corners) do
                                if c.X < min.X then min.X = c.X end
                                if c.Y < min.Y then min.Y = c.Y end
                                if c.Z < min.Z then min.Z = c.Z end
                                if c.X > max.X then max.X = c.X end
                                if c.Y > max.Y then max.Y = c.Y end
                                if c.Z > max.Z then max.Z = c.Z end
                            end
                        end
                    end
                    local tl, _ = cam:WorldToScreenPoint(Vector3.new(min.X, max.Y, min.Z))
                    local br, _ = cam:WorldToScreenPoint(Vector3.new(max.X, min.Y, max.Z))
                    if tl and br then
                        local posBox = Vector2.new(tl.X, tl.Y)
                        local sizeBox = Vector2.new(br.X - tl.X, br.Y - tl.Y)
                        if sizeBox.X > 0 and sizeBox.Y > 0 then
                            obj.box.Position = posBox
                            obj.box.Size = sizeBox
                            obj.box.Visible = true
                        else
                            obj.box.Visible = false
                        end
                    else
                        obj.box.Visible = false
                    end
                end
                local vel = rootPart.Velocity
                local speed = (Vector3.new(vel.X, 0, vel.Z)).Magnitude
                obj.text.Text = string.format("%.1f", speed)
                obj.text.Position = Vector2.new(screenPos.X, screenPos.Y - 50)
                obj.text.Visible = true
            end
        end
    end)
end
local function stopESP()
    cleanupESP()
end

-- ============================================================
-- BUILD MENU
-- ============================================================
makeSectionHeader("AUTO")
toggleRefs.autoSteal = makeToggleRow("Auto Steal", false, function(on)
    Steal.AutoStealEnabled = on
    State.autoStealEnabled = on
    if on then
        if not pcall(startAutoSteal) then
            Steal.AutoStealEnabled=false
            if toggleRefs.autoSteal then toggleRefs.autoSteal(false) end
        end
    else
        stopAutoSteal()
    end
end)
toggleRefs.antiRagdoll = makeToggleRow("Anti Ragdoll", false, function(on)
    State.antiRagdollEnabled = on
    if on then startAntiRagdoll() else stopAntiRagdoll() end
end)
toggleRefs.infJump = makeToggleRow("Infinite Jump", false, function(on)
    State.infJumpEnabled = on
end)
toggleRefs.medusaCounter = makeToggleRow("Medusa Counter", false, function(on)
    State.medusaCounterEnabled = on
    if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
end)
makeInputRow("Steal Radius", Steal.StealRadius, function(n)
    if n >= 5 and n <= 300 then
        Steal.StealRadius = math.floor(n)
        Steal.cachedPrompts={}
        Steal.promptCacheTime=0
        task.spawn(saveConfig)
    end
end)
makeInputRow("Steal Duration", Steal.StealDuration, function(n)
    if n >= 0.05 and n <= 2 then 
        Steal.StealDuration = n
        task.spawn(saveConfig)
    end
end)
makeDivider()

makeSectionHeader("COMBAT")
toggleRefs.autoLeft = makeToggleRow("Auto Left", false, function(on)
    State.autoLeftEnabled = on
    if on and State.batAimbotToggled then
        State.batAimbotToggled = false
        stopBatAimbot()
        if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        if setAB then setAB(false) end
    end
    if on then startAutoLeft() else stopAutoLeft() end
end, "autoLeft")
toggleRefs.autoRight = makeToggleRow("Auto Right", false, function(on)
    State.autoRightEnabled = on
    if on and State.batAimbotToggled then
        State.batAimbotToggled = false
        stopBatAimbot()
        if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        if setAB then setAB(false) end
    end
    if on then startAutoRight() else stopAutoRight() end
end, "autoRight")
toggleRefs.aimbot = makeToggleRow("Bat Aimbot", false, function(on)
    State.batAimbotToggled = on
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            stopAutoLeft()
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            if setAL then setAL(false) end
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            stopAutoRight()
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            if setAR then setAR(false) end
        end
        pcall(startBatAimbot)
    else
        stopBatAimbot()
    end
end, "aimbot")
makeInputRow("Aimbot Speed", State.aimbotSpeed, function(n)
    if n >= 1 and n <= 500 then 
        State.aimbotSpeed = n
        task.spawn(saveConfig)
    end
end)
toggleRefs.autoSwing = makeToggleRow("Auto Swing", false, function(on)
    State.autoSwingEnabled = on
end)
makeToggleRow("Drop Brainrot", false, function(on)
    if on and not State.dropEnabled then runDropBrainrot() end
end, "drop")
makeToggleRow("TP Down", false, function(on)
    if on then doTpDown() end
end, "tpDown")
makeDivider()

makeSectionHeader("VISUALS")
toggleRefs.unwalk = makeToggleRow("Unwalk", false, function(on)
    State.unwalkEnabled = on
    if on then startUnwalk() else stopUnwalk() end
end, "unwalk")
makeToggleRow("Remove Accessories", false, function(on)
    if on then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                for _, obj in ipairs(p.Character:GetDescendants()) do
                    if obj:IsA("Accessory") or obj:IsA("Hat") then pcall(function() obj:Destroy() end) end
                end
            end
        end
    end
end)
toggleRefs.esp = makeToggleRow("ESP", false, function(on)
    State.espEnabled = on
    if on then pcall(startESP) else pcall(stopESP) end
    task.spawn(saveConfig)
end)
local nightModeEnabled = false
local defBrightness = Lighting.Brightness
local defClockTime = Lighting.ClockTime
local defOutdoorAmbient = Lighting.OutdoorAmbient
local defExposureComp = Lighting.ExposureCompensation
makeToggleRow("Dark Mode", false, function(on)
    nightModeEnabled = on
    if on then
        local sky = Lighting:FindFirstChild("F9DarkSky") or Instance.new("Sky")
        sky.Name = "F9DarkSky"
        sky.SkyboxBk = "rbxassetid://159454299"; sky.SkyboxDn = "rbxassetid://159454296"
        sky.SkyboxFt = "rbxassetid://159454293"; sky.SkyboxLf = "rbxassetid://159454286"
        sky.SkyboxRt = "rbxassetid://159454289"; sky.SkyboxUp = "rbxassetid://159454291"
        sky.Parent = Lighting
        Lighting.Brightness = 0; Lighting.ClockTime = 0
        Lighting.ExposureCompensation = -2
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    else
        local s = Lighting:FindFirstChild("F9DarkSky"); if s then s:Destroy() end
        Lighting.Brightness = defBrightness; Lighting.ClockTime = defClockTime
        Lighting.ExposureCompensation = defExposureComp; Lighting.OutdoorAmbient = defOutdoorAmbient
    end
end)

-- FOV Changer
do
    local cam = workspace.CurrentCamera
    local defaultFOV = cam.FieldOfView
    local currentFOV = defaultFOV
    local fovRow = Instance.new("Frame", scrollFrame)
    fovRow.Size = UDim2.new(1, 0, 0, 56)
    fovRow.BackgroundColor3 = C.bg
    fovRow.BackgroundTransparency = 0.8
    fovRow.BorderSizePixel = 0
    fovRow.LayoutOrder = LO()
    fovRow.ZIndex = 3
    local fovDiv = Instance.new("Frame", fovRow)
    fovDiv.Size = UDim2.new(1, -20, 0, 1)
    fovDiv.Position = UDim2.new(0, 10, 1, -1)
    fovDiv.BackgroundColor3 = C.borderDim
    fovDiv.BackgroundTransparency = 0.7
    fovDiv.BorderSizePixel = 0
    fovDiv.ZIndex = 4
    local fovLbl = Instance.new("TextLabel", fovRow)
    fovLbl.Size = UDim2.new(0.5, 0, 0, 18)
    fovLbl.Position = UDim2.new(0, 10, 0, 4)
    fovLbl.BackgroundTransparency = 1
    fovLbl.Text = "FOV Changer"
    fovLbl.Font = Enum.Font.GothamBold
    setTextStyle(fovLbl, 11)
    fovLbl.TextXAlignment = Enum.TextXAlignment.Left
    fovLbl.ZIndex = 4
    local fovValLbl = Instance.new("TextLabel", fovRow)
    fovValLbl.Size = UDim2.new(0, 32, 0, 18)
    fovValLbl.Position = UDim2.new(1, -42, 0, 4)
    fovValLbl.BackgroundTransparency = 1
    fovValLbl.Text = tostring(math.floor(currentFOV))
    fovValLbl.Font = Enum.Font.GothamBold
    setTextStyle(fovValLbl, 10)
    fovValLbl.TextXAlignment = Enum.TextXAlignment.Right
    fovValLbl.ZIndex = 4
    local slTrack = Instance.new("Frame", fovRow)
    slTrack.Size = UDim2.new(1, -20, 0, 5)
    slTrack.Position = UDim2.new(0, 10, 0, 34)
    slTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    slTrack.BackgroundTransparency = 0.7
    slTrack.BorderSizePixel = 0
    mkCorner(slTrack, 3)
    slTrack.ZIndex = 4
    local slFill = Instance.new("Frame", slTrack)
    slFill.Size = UDim2.new((currentFOV - 60) / 140, 0, 1, 0)
    slFill.BackgroundColor3 = YELLOW
    slFill.BorderSizePixel = 0
    mkCorner(slFill, 3)
    slFill.ZIndex = 5
    local slHandle = Instance.new("Frame", slTrack)
    slHandle.Size = UDim2.new(0, 10, 0, 10)
    slHandle.Position = UDim2.new((currentFOV - 60) / 140, -5, 0.5, -5)
    slHandle.BackgroundColor3 = YELLOW
    slHandle.BorderSizePixel = 0
    mkCorner(slHandle, 5)
    slHandle.ZIndex = 6
    local slBtn = Instance.new("TextButton", slTrack)
    slBtn.Size = UDim2.new(1, 0, 0, 30)
    slBtn.Position = UDim2.new(0, 0, 0.5, -15)
    slBtn.BackgroundTransparency = 1
    slBtn.Text = ""
    slBtn.ZIndex = 7
    slBtn.BorderSizePixel = 0
    local function setFOV(fov)
        fov = math.clamp(math.floor(fov), 60, 200)
        currentFOV = fov
        local t = (fov - 60) / 140
        slFill.Size = UDim2.new(t, 0, 1, 0)
        slHandle.Position = UDim2.new(t, -5, 0.5, -5)
        fovValLbl.Text = fov
        pcall(function() workspace.CurrentCamera.FieldOfView = fov end)
    end
    local fovDragging = false
    local function updateFromInput(inp)
        local trackAbs = slTrack.AbsolutePosition
        local trackW = slTrack.AbsoluteSize.X
        local rx = math.clamp(inp.Position.X - trackAbs.X, 0, trackW)
        setFOV(60 + (rx / trackW) * 140)
    end
    slBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fovDragging = true
            updateFromInput(inp)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not fovDragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(inp)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fovDragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if workspace.CurrentCamera.FieldOfView ~= currentFOV then
            pcall(function() workspace.CurrentCamera.FieldOfView = currentFOV end)
        end
    end)
end
makeDivider()

makeSectionHeader("SETTINGS")
toggleRefs.fpsBoost = makeToggleRow("FPS Boost", false, function(on)
    State.fpsBoostEnabled = on
    if on then pcall(applyFPSBoost) end
end)
makeToggleRow("Lock UI", false, function(on)
    State.uiLocked = on
end)
toggleRefs.hideButtons = makeToggleRow("Hide Buttons", false, function(on)
    if mbGroup then mbGroup.Visible = not on end
end)
makeDivider()

-- PRESETS
makeSectionHeader("PRESETS")
local pNameWrap = Instance.new("Frame", scrollFrame)
pNameWrap.Size = UDim2.new(1, 0, 0, 40)
pNameWrap.BackgroundColor3 = C.bg
pNameWrap.BackgroundTransparency = 0.8
pNameWrap.BorderSizePixel = 0
pNameWrap.LayoutOrder = LO()
pNameWrap.ZIndex = 3
local pDiv = Instance.new("Frame", pNameWrap)
pDiv.Size = UDim2.new(1, -20, 0, 1)
pDiv.Position = UDim2.new(0, 10, 1, -1)
pDiv.BackgroundColor3 = C.borderDim
pDiv.BackgroundTransparency = 0.7
pDiv.BorderSizePixel = 0
pDiv.ZIndex = 4
local pBoxWrap = Instance.new("Frame", pNameWrap)
pBoxWrap.Size = UDim2.new(1, -20, 0, 26)
pBoxWrap.Position = UDim2.new(0, 10, 0.5, -13)
pBoxWrap.BackgroundColor3 = C.card
pBoxWrap.BackgroundTransparency = 0.8
pBoxWrap.BorderSizePixel = 0
mkCorner(pBoxWrap, 7)
local pbs = mkStroke(pBoxWrap, C.border, 1)
local presetNameBox = Instance.new("TextBox", pBoxWrap)
presetNameBox.Size = UDim2.new(1, -14, 1, 0)
presetNameBox.Position = UDim2.new(0, 7, 0, 0)
presetNameBox.BackgroundTransparency = 1
presetNameBox.PlaceholderText = "Preset name..."
presetNameBox.PlaceholderColor3 = DARK_YELLOW
presetNameBox.Text = ""
presetNameBox.TextColor3 = YELLOW
presetNameBox.TextStrokeColor3 = Color3.fromRGB(20,20,20)
presetNameBox.TextStrokeTransparency = 0.2
presetNameBox.Font = Enum.Font.GothamBold
presetNameBox.TextSize = 11
presetNameBox.ClearTextOnFocus = false
presetNameBox.ZIndex = 5
presetNameBox.TextXAlignment = Enum.TextXAlignment.Left
presetNameBox.Focused:Connect(function()
    TweenService:Create(pbs,TweenInfo.new(0.15),{Color=Color3.fromRGB(120,120,120)}):Play()
end)
presetNameBox.FocusLost:Connect(function()
    TweenService:Create(pbs,TweenInfo.new(0.15),{Color=C.border}):Play()
end)
local savePRow = Instance.new("Frame", scrollFrame)
savePRow.Size = UDim2.new(1, 0, 0, 38)
savePRow.BackgroundColor3 = C.bg
savePRow.BackgroundTransparency = 0.8
savePRow.BorderSizePixel = 0
savePRow.LayoutOrder = LO()
local savePDiv = Instance.new("Frame", savePRow)
savePDiv.Size = UDim2.new(1, -20, 0, 1)
savePDiv.Position = UDim2.new(0, 10, 1, -1)
savePDiv.BackgroundColor3 = C.borderDim
savePDiv.BackgroundTransparency = 0.7
savePDiv.BorderSizePixel = 0
local savePBtn = Instance.new("TextButton", savePRow)
savePBtn.Size = UDim2.new(1, -20, 0, 26)
savePBtn.Position = UDim2.new(0, 10, 0.5, -13)
savePBtn.BackgroundColor3 = C.card
savePBtn.BackgroundTransparency = 0.7
savePBtn.BorderSizePixel = 0
savePBtn.Text = "+ Save Preset"
savePBtn.TextColor3 = YELLOW
savePBtn.TextStrokeColor3 = Color3.fromRGB(20,20,20)
savePBtn.TextStrokeTransparency = 0.2
savePBtn.Font = Enum.Font.GothamBold
savePBtn.TextSize = 11
savePBtn.ZIndex = 4
mkCorner(savePBtn, 7)
mkStroke(savePBtn, C.border, 1)
savePBtn.MouseEnter:Connect(function() TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.cardHov}):Play() end)
savePBtn.MouseLeave:Connect(function() TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.card}):Play() end)
local presetListFrame = Instance.new("Frame", scrollFrame)
presetListFrame.Size = UDim2.new(1, 0, 0, 0)
presetListFrame.AutomaticSize = Enum.AutomaticSize.Y
presetListFrame.BackgroundTransparency = 1
presetListFrame.BorderSizePixel = 0
presetListFrame.LayoutOrder = LO()
presetListFrame.ZIndex = 3
local pListLL = Instance.new("UIListLayout", presetListFrame)
pListLL.SortOrder = Enum.SortOrder.LayoutOrder
pListLL.Padding = UDim.new(0, 0)
local pListPad = Instance.new("UIPadding", presetListFrame)
pListPad.PaddingLeft = UDim.new(0, 10)
pListPad.PaddingRight = UDim.new(0, 10)
pListPad.PaddingTop = UDim.new(0, 4)
pListPad.PaddingBottom = UDim.new(0, 6)
local emptyLbl = Instance.new("TextLabel", presetListFrame)
emptyLbl.Name = "EmptyLabel"
emptyLbl.Size = UDim2.new(1, 0, 0, 22)
emptyLbl.BackgroundTransparency = 1
emptyLbl.Text = "No presets saved yet."
emptyLbl.Font = Enum.Font.Gotham
setTextStyle(emptyLbl, 10)
emptyLbl.TextColor3 = C.textSub
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.LayoutOrder = 1
emptyLbl.ZIndex = 4
local rebuildPresetList
rebuildPresetList = function()
    if not presetListFrame then return end
    for _, child in ipairs(presetListFrame:GetChildren()) do
        if child.Name ~= "EmptyLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    local el = presetListFrame:FindFirstChild("EmptyLabel")
    if el then el.Visible = (#Presets == 0) end
    for i, preset in ipairs(Presets) do
        local row = Instance.new("Frame", presetListFrame)
        row.Name = "Preset_"..i
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = C.card
        row.BackgroundTransparency = 0.8
        row.BorderSizePixel = 0
        row.LayoutOrder = i+1
        row.ZIndex = 4
        mkCorner(row, 7)
        mkStroke(row, C.border, 1)
        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -80, 1, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = preset.name
        nameLbl.Font = Enum.Font.GothamBold
        setTextStyle(nameLbl, 10)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 5
        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0, 38, 0, 22)
        loadBtn.Position = UDim2.new(1, -82, 0.5, -11)
        loadBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        loadBtn.BackgroundTransparency = 0.7
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = YELLOW
        loadBtn.TextStrokeColor3 = Color3.fromRGB(20,20,20)
        loadBtn.TextStrokeTransparency = 0.2
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 9
        loadBtn.ZIndex = 5
        mkCorner(loadBtn, 5)
        mkStroke(loadBtn, C.border, 1)
        loadBtn.MouseButton1Click:Connect(function()
            applyPreset(preset.data)
            saveLastPresetName(preset.name)
            loadBtn.Text = "✓"
            task.delay(1.2, function()
                if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
            end)
        end)
        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 26, 0, 22)
        delBtn.Position = UDim2.new(1, -42, 0.5, -11)
        delBtn.BackgroundColor3 = Color3.fromRGB(55,22,22)
        delBtn.BackgroundTransparency = 0.7
        delBtn.BorderSizePixel = 0
        delBtn.Text = "✕"
        delBtn.TextColor3 = Color3.fromRGB(200,70,70)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 9
        delBtn.ZIndex = 5
        mkCorner(delBtn, 5)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(Presets, i)
            savePresetsFile()
            rebuildPresetList()
        end)
    end
end
savePBtn.MouseButton1Click:Connect(function()
    local nm = presetNameBox.Text:match("^%s*(.-)%s*$")
    if nm == "" then
        savePBtn.Text = "Name required!"
        task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end)
        return
    end
    local found = false
    for i, p in ipairs(Presets) do
        if p.name == nm then
            Presets[i].data = buildPresetSnapshot()
            found = true
            break
        end
    end
    if not found then
        table.insert(Presets, {name=nm, data=buildPresetSnapshot()})
    end
    savePresetsFile()
    presetNameBox.Text = ""
    savePBtn.Text = "✓ Saved!"
    task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end)
    rebuildPresetList()
end)

-- ============================================================
-- MOBILE BUTTONS (1px outline)
-- ============================================================
local MB_W = 60
local MB_H = 46
local GAP = 5
local RADIUS = 7
local Q_OFF = Color3.fromRGB(10, 10, 10)
local QW = MB_W * 2 + GAP
local QH = MB_H * 3 + GAP * 2
mbGroup = Instance.new("Frame", gui)
mbGroup.Name = "MobileButtons"
mbGroup.Size = UDim2.new(0, QW + 18, 0, QH + 18)
mbGroup.Position = UDim2.new(1, -QW - 30, 0.5, -QH/2 - 8)
mbGroup.BackgroundTransparency = 1
mbGroup.BorderSizePixel = 0
mbGroup.Active = true
mbGroup.ZIndex = 100
makeDraggable(mbGroup)

local function makeMobileBtn(label, col, row, isToggle, onAction)
    local relX = 9 + col*(MB_W+GAP)
    local relY = 9 + row*(MB_H+GAP)
    local frame = Instance.new("Frame", mbGroup)
    frame.Size = UDim2.new(0, MB_W, 0, MB_H)
    frame.Position = UDim2.new(0, relX, 0, relY)
    frame.BackgroundColor3 = Q_OFF
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 102
    mkCorner(frame, RADIUS)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = YELLOW
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 0.7, 0)
    btn.Position = UDim2.new(0, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = label
    btn.TextColor3 = YELLOW
    btn.TextStrokeColor3 = Color3.fromRGB(20,20,20)
    btn.TextStrokeTransparency = 0.2
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextWrapped = true
    btn.LineHeight = 1.0
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 103
    local dot = Instance.new("Frame", frame)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0.5, -4, 1, -10)
    dot.BackgroundColor3 = Color3.fromRGB(60,60,60)
    dot.BorderSizePixel = 0
    dot.ZIndex = 104
    mkCorner(dot, 4)
    local isOn = false
    btn.MouseButton1Click:Connect(function()
        if isToggle then
            isOn = not isOn
            TweenService:Create(dot, TweenInfo.new(0.15), {
                BackgroundColor3 = isOn and YELLOW or Color3.fromRGB(60,60,60)
            }):Play()
            if onAction then onAction(isOn) end
        else
            TweenService:Create(dot, TweenInfo.new(0.08), {BackgroundColor3 = YELLOW}):Play()
            task.delay(0.25, function()
                TweenService:Create(dot, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
            end)
            if onAction then onAction() end
        end
    end)
    local function setter(s)
        isOn = s
        TweenService:Create(dot, TweenInfo.new(0.15), {
            BackgroundColor3 = s and YELLOW or Color3.fromRGB(60,60,60)
        }):Play()
    end
    return frame, setter
end

makeMobileBtn("DROP", 0, 0, false, function()
    if not State.dropEnabled then runDropBrainrot() end
end)
local _, setALfn = makeMobileBtn("AUTO L", 1, 0, true, function(on)
    State.autoLeftEnabled = on
    if toggleRefs.autoLeft then toggleRefs.autoLeft(on) end
    if on then
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if setAR then setAR(false) end
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            stopAutoRight()
        end
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
            stopBatAimbot()
        end
        startAutoLeft()
    else
        stopAutoLeft()
    end
end)
setAL = setALfn
local _, setABfn = makeMobileBtn("BAT", 0, 1, true, function(on)
    State.batAimbotToggled = on
    if toggleRefs.aimbot then toggleRefs.aimbot(on) end
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if setAL then setAL(false) end
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            stopAutoLeft()
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if setAR then setAR(false) end
            if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            stopAutoRight()
        end
        startBatAimbot()
    else
        stopBatAimbot()
    end
end)
setAB = setABfn
local _, setARfn = makeMobileBtn("AUTO R", 1, 1, true, function(on)
    State.autoRightEnabled = on
    if toggleRefs.autoRight then toggleRefs.autoRight(on) end
    if on then
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if setAL then setAL(false) end
            if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            stopAutoLeft()
        end
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
            stopBatAimbot()
        end
        startAutoRight()
    else
        stopAutoRight()
    end
end)
setAR = setARfn
makeMobileBtn("TP", 0, 2, false, function()
    doTpDown()
end)
makeMobileBtn("CARRY", 1, 2, true, function(on)
    State.speedToggled = on
    if toggleRefs.carryMode then toggleRefs.carryMode(on) end
end)

-- ============================================================
-- CHARACTER SETUP (billboard)
-- ============================================================
local function setupChar(char)
    task.wait(0.1)
    h=char:WaitForChild("Humanoid",5)
    hrp=char:WaitForChild("HumanoidRootPart",5)
    if not h or not hrp then return end
    local head=char:FindFirstChild("Head")
    if head then
        local oldBB=head:FindFirstChild("F9HubBB")
        if oldBB then oldBB:Destroy() end
        local bb=Instance.new("BillboardGui",head)
        bb.Name="F9HubBB"
        bb.Size=UDim2.new(0,180,0,52)
        bb.StudsOffset=Vector3.new(0,3,0)
        bb.AlwaysOnTop=true
        local ragdollLbl=Instance.new("TextLabel",bb)
        ragdollLbl.Name="RagdollTimerLbl"
        ragdollLbl.Size=UDim2.new(1,0,0,26)
        ragdollLbl.Position=UDim2.new(0,0,0,0)
        ragdollLbl.BackgroundTransparency=1
        ragdollLbl.Text=""
        ragdollLbl.TextColor3=Color3.fromRGB(255,80,80)
        ragdollLbl.Font=Enum.Font.GothamBlack
        ragdollLbl.TextScaled=true
        ragdollLbl.TextStrokeTransparency=0.1
        ragdollLbl.TextStrokeColor3=Color3.new(0,0,0)
        ragdollLbl.Visible=false
        local speedBillLbl = Instance.new("TextLabel",bb)
        speedBillLbl.Name="SpeedBillLbl"
        speedBillLbl.Size=UDim2.new(1,0,0,24)
        speedBillLbl.Position=UDim2.new(0,0,0,26)
        speedBillLbl.BackgroundTransparency=1
        speedBillLbl.Text="0.0"
        speedBillLbl.TextColor3 = YELLOW
        speedBillLbl.TextStrokeColor3 = Color3.new(0,0,0)
        speedBillLbl.TextStrokeTransparency = 0.1
        speedBillLbl.Font = Enum.Font.GothamBlack
        speedBillLbl.TextScaled = true
        task.spawn(function()
            while speedBillLbl and speedBillLbl.Parent do
                local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
                local tween = TweenService:Create(speedBillLbl, tweenInfo, {TextColor3 = BLACKISH})
                tween:Play()
                task.wait(1.2)
                local tween2 = TweenService:Create(speedBillLbl, tweenInfo, {TextColor3 = YELLOW})
                tween2:Play()
                task.wait(1.2)
            end
        end)
    end
    local ragTimerActive = false
    local function startRagdollTimer()
        if ragTimerActive then return end
        ragTimerActive = true
        State.countdownActive = true
        task.spawn(function()
            local char2 = LP.Character
            local head2 = char2 and char2:FindFirstChild("Head")
            local bb2 = head2 and head2:FindFirstChild("F9HubBB")
            local timerLbl = bb2 and bb2:FindFirstChild("RagdollTimerLbl")
            if not timerLbl then ragTimerActive = false; State.countdownActive = false; return end
            local countdown = 3
            timerLbl.Visible = true
            timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            while countdown > 0 do
                timerLbl.Text = tostring(countdown)
                timerLbl.TextColor3 = ({Color3.fromRGB(255, 60, 60),Color3.fromRGB(255, 140, 40),Color3.fromRGB(255, 220, 40)})[math.max(1, 4 - countdown)]
                task.wait(1)
                countdown = countdown - 1
            end
            timerLbl.Text = "READY TO STEAL"
            timerLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            repeat task.wait(0.1) until (function()
                local c3 = LP.Character
                local hum3 = c3 and c3:FindFirstChildOfClass("Humanoid")
                if not hum3 then return true end
                local st3 = hum3:GetState()
                return st3 ~= Enum.HumanoidStateType.Physics and st3 ~= Enum.HumanoidStateType.Ragdoll and st3 ~= Enum.HumanoidStateType.FallingDown
            end)()
            timerLbl.Visible = false
            timerLbl.Text = ""
            ragTimerActive = false
            State.countdownActive = false
        end)
    end
    RunService.Heartbeat:Connect(function()
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            startRagdollTimer()
        end
    end)
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    _unwalkAnimations={}
    if State.unwalkEnabled then task.wait(0.3); startUnwalk() end
    stopAntiRagdoll()
    if State.antiRagdollEnabled then task.wait(0.5); startAntiRagdoll() end
    if State.medusaCounterEnabled then setupMedusaCounter(char) end
    if State.batAimbotToggled then stopBatAimbot(); task.wait(0.2); pcall(startBatAimbot) end
    if State.batCounterEnabled then task.wait(0.3); startBatCounter() end
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ============================================================
-- RUNTIME LOOPS
-- ============================================================
RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)
local MOVE_KEYS={
    [Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true
}
RunService.RenderStepped:Connect(function()
    if not (h and hrp) then return end
    if not State.batAimbotToggled and not State.autoLeftEnabled and not State.autoRightEnabled then
        local md=h.MoveDirection
        local spd = State.laggerEnabled and State.laggerSpeed or (State.speedToggled and State.carrySpeed or State.normalSpeed)
        if md.Magnitude>0 then
            State.lastMoveDir=md
            hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
            local anyHeld=false
            for key in pairs(MOVE_KEYS) do
                if UIS:IsKeyDown(key) then anyHeld=true; break end
            end
            if anyHeld then
                hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd)
            end
        end
    end
    pcall(function()
        local head2=LP.Character and LP.Character:FindFirstChild("Head")
        if head2 then
            local bb2=head2:FindFirstChild("F9HubBB")
            local sl=bb2 and bb2:FindFirstChild("SpeedBillLbl")
            if sl then
                sl.Text=string.format("%.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude)
            end
        end
    end)
end)

-- ============================================================
-- INPUT HANDLERS
-- ============================================================
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    local t = inp.UserInputType
    local isKb = t==Enum.UserInputType.Keyboard
    local isGP = t==Enum.UserInputType.Gamepad1 or t==Enum.UserInputType.Gamepad2
    if not isKb and not isGP then return end
    local kc = inp.KeyCode
    if kc == Enum.KeyCode.Unknown then return end
    if kc == Keys.speed then
        State.speedToggled = not State.speedToggled
        if toggleRefs.carryMode then toggleRefs.carryMode(State.speedToggled) end
    elseif kc == Keys.lagger then
        State.laggerEnabled = not State.laggerEnabled
        if toggleRefs.laggerMode then toggleRefs.laggerMode(State.laggerEnabled) end
        if State.laggerEnabled then
            State._laggerOriginalCarry = State.carrySpeed
            State._prevSpeed = State.speedToggled
            State.speedToggled = false
        else
            State.carrySpeed = State._laggerOriginalCarry or 30
            State.speedToggled = State._prevSpeed or false
            if speedBoxRefs.carrySpeed then
                speedBoxRefs.carrySpeed.Text = tostring(State.carrySpeed)
            end
        end
    elseif kc == Keys.autoLeft then
        State.autoLeftEnabled = not State.autoLeftEnabled
        if toggleRefs.autoLeft then toggleRefs.autoLeft(State.autoLeftEnabled) end
        if setAL then setAL(State.autoLeftEnabled) end
        if State.autoLeftEnabled and State.batAimbotToggled then
            State.batAimbotToggled = false
            stopBatAimbot()
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        end
        if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
    elseif kc == Keys.autoRight then
        State.autoRightEnabled = not State.autoRightEnabled
        if toggleRefs.autoRight then toggleRefs.autoRight(State.autoRightEnabled) end
        if setAR then setAR(State.autoRightEnabled) end
        if State.autoRightEnabled and State.batAimbotToggled then
            State.batAimbotToggled = false
            stopBatAimbot()
            if setAB then setAB(false) end
            if toggleRefs.aimbot then toggleRefs.aimbot(false) end
        end
        if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
    elseif kc == Keys.drop then
        if not State.dropEnabled then runDropBrainrot() end
    elseif kc == Keys.tpDown then
        doTpDown()
    elseif kc == Keys.aimbot then
        State.batAimbotToggled = not State.batAimbotToggled
        if toggleRefs.aimbot then toggleRefs.aimbot(State.batAimbotToggled) end
        if setAB then setAB(State.batAimbotToggled) end
        if State.batAimbotToggled then
            if State.autoLeftEnabled then
                State.autoLeftEnabled = false
                stopAutoLeft()
                if setAL then setAL(false) end
                if toggleRefs.autoLeft then toggleRefs.autoLeft(false) end
            end
            if State.autoRightEnabled then
                State.autoRightEnabled = false
                stopAutoRight()
                if setAR then setAR(false) end
                if toggleRefs.autoRight then toggleRefs.autoRight(false) end
            end
            pcall(startBatAimbot)
        else
            stopBatAimbot()
        end
    elseif kc == Keys.unwalk then
        State.unwalkEnabled = not State.unwalkEnabled
        if toggleRefs.unwalk then toggleRefs.unwalk(State.unwalkEnabled) end
        if State.unwalkEnabled then startUnwalk() else stopUnwalk() end
    elseif kc == Keys.duelLagger then
        toggleDuelLagger()
    elseif kc == Keys.instaReset then
        doInstaReset()
    elseif kc == Keys.guiHide then
        mbGroup.Visible = not mbGroup.Visible
    end
end)

-- ============================================================
-- INIT
-- ============================================================
loadPresetsFile()
loadConfig()
rebuildPresetList()
do
    local lastPresetName = loadLastPresetName()
    if lastPresetName and lastPresetName ~= "" then
        for _, preset in ipairs(Presets) do
            if preset.name == lastPresetName then
                applyPreset(preset.data)
                print("[F.9 Hub] Auto-loaded preset: " .. lastPresetName)
                break
            end
        end
    end
end
for keyRef, btn in pairs(keybindBtnRefs) do
    if Keys[keyRef] then
        btn.Text = getKeyName(Keys[keyRef])
    end
end
mainOuter.Size = UDim2.new(0, 0, 0, 0)
mainOuter.Visible = true
TweenService:Create(mainOuter, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, WIN_W, 0, WIN_H)
}):Play()
task.spawn(function()
    while task.wait(10) do
        pcall(saveConfig)
    end
end)
print("[F.9 Hub] ✅ Full size, no pill accent, custom BG, ESP active.")
