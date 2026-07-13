-- ============================================================
-- ASIREHUB  v5.2  (
-- ============================================================

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Stats           = game:GetService("Stats")
local LP              = Players.LocalPlayer

local LOGO_ID = "rbxassetid://96255128725816"
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({LOGO_ID}) end) end)

local _isfile   = isfile   or (syn and syn.isfile)   or (getgenv and getgenv().isfile)   or function() return false end
local _readfile = readfile  or (syn and syn.readfile)  or (getgenv and getgenv().readfile)  or function() return nil  end
local _writefile= writefile or (syn and syn.writefile) or (getgenv and getgenv().writefile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    normalSpeed=59.5, carrySpeed=28.5, laggerSpeed=23.2, laggerCarrySpeed=18.4,
    speedToggled=false, laggerEnabled=false,
    infJumpEnabled=false, antiRagdollEnabled=false, fpsBoostEnabled=false,
    guiVisible=true, uiLocked=false,
    isStealing=false, stealStartTime=nil, lastStealTick=0,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false, aimbotSpeed=56.5,
    hittingCooldown=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, _tpInProgress=false,
    lastMoveDir=Vector3.new(0,0,0),
    unwalkEnabled=false, stackButtonsHidden=false,
    _prevCarry=28.5, _prevSpeed=false,
    autoTPEnabled=false, autoTPHeight=20,
    noAnimEnabled=false, optimizerEnabled=false,
    purpleSkyEnabled=false, nightTimeEnabled=false, stretchRezEnabled=false,
}

local Keys = {
    speed=Enum.KeyCode.Q, guiHide=Enum.KeyCode.LeftControl,
    autoLeft=Enum.KeyCode.L, autoRight=Enum.KeyCode.R,
    lagger=Enum.KeyCode.Unknown, tpDown=Enum.KeyCode.Unknown,
    drop=Enum.KeyCode.H, aimbot=Enum.KeyCode.Unknown,
}

-- ============================================================
-- DEFAULT STACK BUTTON POSITIONS (for reset)
-- ============================================================
local BTN_W=64; local BTN_H=54; local BTN_GAP=5; local COLS=2
local stackDefs = {
    {key="autoLeft",   label="AUTO\nLEFT"},
    {key="autoRight",  label="AUTO\nRIGHT"},
    {key="aimbot",     label="AIMBOT"},
    {key="lagger",     label="LAGGER\nMODE"},
    {key="drop",       label="DROP\nBR"},
    {key="tpDown",     label="TP\nDOWN"},
    {key="carrySpeed", label="CARRY\nSPEED"},
}
local GRID_W=COLS*(BTN_W+BTN_GAP)-BTN_GAP
local GRID_H=math.ceil(#stackDefs/COLS)*(BTN_H+BTN_GAP)-BTN_GAP

local function getDefaultStackPos(i)
    local col=(i-1)%COLS
    local row2=math.floor((i-1)/COLS)
    return UDim2.new(1,-(GRID_W+14)+col*(BTN_W+BTN_GAP),0.5,-(GRID_H/2)+row2*(BTN_H+BTN_GAP))
end

local Steal = {
    AutoStealEnabled=false, StealRadius=20, StealDuration=1.3,
    Data={}, plotCache={}, plotCacheTime={}, cachedPrompts={}, promptCacheTime=0,
}

-- ============================================================
-- PRESETS
-- ============================================================
local Presets = {}
local PRESET_FILE = "AsireHubPresets.json"
local LAST_PRESET_FILE = "AsireHubLastPreset.json"
local CONFIG_FILE = "AsireHubConfig.json"

local function buildPresetSnapshot()
    -- Keybinds are intentionally excluded; they are saved in saveConfig separately
    return {
        normalSpeed   = State.normalSpeed,
        carrySpeed    = State.carrySpeed,
        laggerSpeed   = State.laggerSpeed,
        stealRadius   = Steal.StealRadius,
        stealDuration = Steal.StealDuration,
        infJump       = State.infJumpEnabled,
        antiRagdoll   = State.antiRagdollEnabled,
        fpsBoost      = State.fpsBoostEnabled,
        medusaCounter = State.medusaCounterEnabled,
        batCounter    = State.batCounterEnabled,
        autoSteal     = Steal.AutoStealEnabled,
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
    local ok, encoded = pcall(function() return HttpService:JSONEncode({lastPreset=name}) end)
    if ok then pcall(function() _writefile(LAST_PRESET_FILE, encoded) end) end
end

local function loadLastPresetName()
    local hasFile = false; pcall(function() hasFile = _isfile(LAST_PRESET_FILE) end)
    if not hasFile then return nil end
    local raw; pcall(function() raw = _readfile(LAST_PRESET_FILE) end)
    if not raw then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then return decoded.lastPreset end
    return nil
end

local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

local PLOT_CACHE_DURATION=2; local PROMPT_CACHE_REFRESH=0.15
local STEAL_COOLDOWN=0.1; local MEDUSA_COOLDOWN=25; local DROP_AUTO_OFF_DELAY=0.15

local POS={
    L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
    R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,anchor={},progress=nil,batCounter=nil,unwalk=nil}

local h,hrp
local setAutoLeft,setAutoRight,setInfJump,setAntiRag,setFps
local setMedusaCounter,setUnwalkToggle,setAimbot,setAutoSwing
local setLagger,setDropBrainrot,setInstaGrab
local setupMedusaCounter,stopMedusaCounter,startAntiRagdoll,stopAntiRagdoll
local applyFPSBoost,startAutoSteal,stopAutoSteal
local startAutoLeft,stopAutoLeft,startAutoRight,stopAutoRight
local saveConfig,loadConfig,runDropBrainrot,stopDropBrainrot,doTpDown
local startBatAimbot,stopBatAimbot,startBatCounter,stopBatCounter,setBatCounter
local stackBtnRefs={}; local stackWrappers={}; local keybindBtnRefs={}
local normalBox,carryBox,laggerBox,laggerCarryBox,uiScaleBox
local carryModeToggle,laggerModeToggle,modeDisplayLbl,stealRadBox,lockBtn
local setHideButtonsToggle
local radTB

local presetListFrame=nil
local presetNameBox=nil
local rebuildPresetList

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    -- Xerion V2 All-Black palette
    bg          = Color3.fromRGB(8,   8,   8  ),
    winBg       = Color3.fromRGB(8,   8,   8  ),
    winBorder   = Color3.fromRGB(42,  42,  42 ),
    header      = Color3.fromRGB(5,   5,   5  ),
    topBg       = Color3.fromRGB(5,   5,   5  ),
    topTitle    = Color3.fromRGB(240, 240, 240),
    topBtn      = Color3.fromRGB(100, 100, 100),
    topBtnHov   = Color3.fromRGB(160, 160, 160),
    topDivider  = Color3.fromRGB(42,  42,  42 ),
    tabBarBg    = Color3.fromRGB(5,   5,   5  ),
    tabBarDiv   = Color3.fromRGB(42,  42,  42 ),
    tabIdle     = Color3.fromRGB(100, 100, 100),
    tabActive   = Color3.fromRGB(255, 255, 255),
    tabActiveBg = Color3.fromRGB(5,   5,   5  ),
    tabUnderline= Color3.fromRGB(255, 255, 255),
    sectionTxt  = Color3.fromRGB(140, 140, 140),
    sectionDiv  = Color3.fromRGB(26,  26,  26 ),
    rowBg       = Color3.fromRGB(8,   8,   8  ),
    rowBorder   = Color3.fromRGB(26,  26,  26 ),
    rowLabel    = Color3.fromRGB(240, 240, 240),
    rowSub      = Color3.fromRGB(160, 160, 160),
    rowValue    = Color3.fromRGB(210, 210, 210),
    rowHov      = Color3.fromRGB(18,  18,  18 ),
    inputBg     = Color3.fromRGB(10,  10,  10 ),
    inputBorder = Color3.fromRGB(42,  42,  42 ),
    inputFocus  = Color3.fromRGB(255, 255, 255),
    inputTxt    = Color3.fromRGB(210, 210, 210),
    pillOff     = Color3.fromRGB(20,  20,  20 ),
    pillOn      = Color3.fromRGB(58,  58,  58 ),
    dotOff      = Color3.fromRGB(55,  55,  55 ),
    dotOn       = Color3.fromRGB(210, 210, 210),
    pillBorder  = Color3.fromRGB(42,  42,  42 ),
    modeBtnBg   = Color3.fromRGB(18,  18,  18 ),
    modeBtnBrd  = Color3.fromRGB(38,  38,  38 ),
    modeBtnTxt  = Color3.fromRGB(90,  90,  90 ),
    modeBtnActBg= Color3.fromRGB(45,  45,  45 ),
    modeBtnActTx= Color3.fromRGB(210, 210, 210),
    chipBg      = Color3.fromRGB(18,  18,  18 ),
    chipBorder  = Color3.fromRGB(26,  26,  26 ),
    chipTxt     = Color3.fromRGB(130, 130, 130),
    btnBg       = Color3.fromRGB(18,  18,  18 ),
    btnBorder   = Color3.fromRGB(42,  42,  42 ),
    btnTxt      = Color3.fromRGB(180, 180, 180),
    btnHov      = Color3.fromRGB(30,  30,  30 ),
    stackBg     = Color3.fromRGB(8,   8,   8  ),
    stackBrd    = Color3.fromRGB(38,  38,  38 ),
    stackTxt    = Color3.fromRGB(90,  90,  90 ),
    stackActBg  = Color3.fromRGB(38,  38,  38 ),
    stackActBrd = Color3.fromRGB(160, 160, 160),
    stackActTxt = Color3.fromRGB(220, 220, 220),
    stackDot    = Color3.fromRGB(35,  35,  35 ),
    stackDotOn  = Color3.fromRGB(180, 180, 180),
    infoBg      = Color3.fromRGB(8,   8,   8  ),
    infoBrd     = Color3.fromRGB(42,  42,  42 ),
    infoTxt     = Color3.fromRGB(70,  70,  70 ),
    infoVal     = Color3.fromRGB(160, 160, 160),
    infoFill    = Color3.fromRGB(90,  90,  90 ),
    accent      = Color3.fromRGB(255, 255, 255),
    accentDim   = Color3.fromRGB(140, 140, 140),
    presetBg    = Color3.fromRGB(18,  18,  18 ),
    presetBrd   = Color3.fromRGB(38,  38,  38 ),
    presetLoad  = Color3.fromRGB(50,  50,  50 ),
    presetDel   = Color3.fromRGB(55,  25,  25 ),
    delBrd      = Color3.fromRGB(80,  35,  35 ),
    lockOn      = Color3.fromRGB(200, 200, 200),
    divider     = Color3.fromRGB(26,  26,  26 ),
}

-- ============================================================
-- CLEANUP
-- ============================================================
for _,name in pairs({"VyseSlottedGUI","VyseAsireGUI","VyseAsireHubV4","VyseAsireHubV5","VyseAsireHubV5_1","AsireHubV5_1","AsireHubV5_2"}) do
    pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
    pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
end

-- ============================================================
-- ROOT GUI
-- ============================================================
local gui=Instance.new("ScreenGui")
gui.Name="AsireHubV5_2"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=LP:WaitForChild("PlayerGui")

local uiScaleObj=Instance.new("UIScale",gui); uiScaleObj.Scale=0.8

-- ============================================================
-- HELPERS
-- ============================================================
local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function mkStroke(p,col,th)
    local s=Instance.new("UIStroke",p); s.Color=col; s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function mkPad(p,t,b,l,r)
    local pd=Instance.new("UIPadding",p)
    pd.PaddingTop=UDim.new(0,t or 0); pd.PaddingBottom=UDim.new(0,b or 0)
    pd.PaddingLeft=UDim.new(0,l or 0); pd.PaddingRight=UDim.new(0,r or 0)
    return pd
end

-- ============================================================
-- DRAG
-- ============================================================
local function makeDraggable(frame,handle)
    local src=handle or frame
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
    src.InputBegan:Connect(function(inp)
        if State.uiLocked then return end
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=frame.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    src.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp==dragInput and dragging and not State.uiLocked then
            local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
        end
    end)
end

local function makeStackDraggable(frame,onTap)
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil; local moved=false
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
        dragging=true; moved=false; dragStart=inp.Position; startPos=frame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then
                if not moved and onTap then onTap() end; dragging=false; moved=false
            end
        end)
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp~=dragInput or not dragging then return end
        local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
        if math.abs(dx)>4 or math.abs(dy)>4 then moved=true end
        if moved and not State.uiLocked then
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
        end
    end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local WIN_W = 340
local WIN_H = 570
local TITLE_H = 48
local TAB_H   = 46

local mainOuter = Instance.new("Frame", gui)
mainOuter.Name = "MainOuter"
mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainOuter.Position = UDim2.new(0, 8, 0, 8)
mainOuter.BackgroundColor3 = C.winBg
mainOuter.BorderSizePixel = 0
mainOuter.ClipsDescendants = true
mkCorner(mainOuter, 14)
mkStroke(mainOuter, C.winBorder, 1)
makeDraggable(mainOuter)

-- ============================================================
-- TITLE BAR  (Xerion V2 style)
-- ============================================================
local titleBar = Instance.new("Frame", mainOuter)
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.topBg
titleBar.BorderSizePixel = 0; titleBar.ZIndex = 3
mkCorner(titleBar, 14)
-- Square the bottom half so corners only show at top
local tbBot = Instance.new("Frame", titleBar)
tbBot.Size = UDim2.new(1, 0, 0.5, 0); tbBot.Position = UDim2.new(0, 0, 0.5, 0)
tbBot.BackgroundColor3 = C.topBg; tbBot.BorderSizePixel = 0; tbBot.ZIndex = 3

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, -70, 1, 0); titleLbl.Position = UDim2.new(0, 18, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "XERION HUB"
titleLbl.TextColor3 = C.topTitle; titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 20; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 4

-- Minimize button  (hides window, use reopen btn to bring back)
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 26, 0, 26); closeBtn.Position = UDim2.new(1, -36, 0.5, -13)
closeBtn.BackgroundColor3 = C.modeBtnBg; closeBtn.BorderSizePixel = 0
closeBtn.Text = "--"; closeBtn.TextColor3 = C.topBtn
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12; closeBtn.ZIndex = 5
mkCorner(closeBtn, 6); mkStroke(closeBtn, C.chipBorder, 1)
closeBtn.MouseButton1Click:Connect(function() State.guiVisible = false; mainOuter.Visible = false end)

-- Lock button
lockBtn = Instance.new("TextButton", titleBar)
lockBtn.Size = UDim2.new(0, 26, 0, 26); lockBtn.Position = UDim2.new(1, -66, 0.5, -13)
lockBtn.BackgroundColor3 = C.modeBtnBg; lockBtn.BorderSizePixel = 0
lockBtn.Text = "🔓"; lockBtn.Font = Enum.Font.GothamBold; lockBtn.TextSize = 11; lockBtn.ZIndex = 5
mkCorner(lockBtn, 6); mkStroke(lockBtn, C.chipBorder, 1)
lockBtn.MouseButton1Click:Connect(function()
    State.uiLocked = not State.uiLocked
    lockBtn.Text = State.uiLocked and "🔒" or "🔓"
end)

local titleDiv = Instance.new("Frame", mainOuter)
titleDiv.Size = UDim2.new(1, 0, 0, 1); titleDiv.Position = UDim2.new(0, 0, 0, TITLE_H)
titleDiv.BackgroundColor3 = C.topDivider; titleDiv.BorderSizePixel = 0; titleDiv.ZIndex = 3

-- ============================================================
-- CONTENT AREA  (tabs are at the bottom — Xerion V2 style)
-- ============================================================
local CONTENT_Y = TITLE_H + 1
local CONTENT_H = WIN_H - CONTENT_Y - TAB_H - 1

local contentBg = Instance.new("Frame", mainOuter)
contentBg.Size = UDim2.new(1, 0, 0, CONTENT_H)
contentBg.Position = UDim2.new(0, 0, 0, CONTENT_Y)
contentBg.BackgroundColor3 = C.winBg
contentBg.BackgroundTransparency = 1
contentBg.BorderSizePixel = 0
contentBg.ClipsDescendants = true
contentBg.ZIndex = 2

-- Divider above tab bar
local tabDiv = Instance.new("Frame", mainOuter)
tabDiv.Size = UDim2.new(1, 0, 0, 1); tabDiv.Position = UDim2.new(0, 0, 1, -TAB_H - 1)
tabDiv.BackgroundColor3 = C.tabBarDiv; tabDiv.BorderSizePixel = 0; tabDiv.ZIndex = 3

-- Tab bar at bottom
local tabBar = Instance.new("Frame", mainOuter)
tabBar.Size = UDim2.new(1, 0, 0, TAB_H); tabBar.Position = UDim2.new(0, 0, 1, -TAB_H)
tabBar.BackgroundColor3 = C.tabBarBg; tabBar.BorderSizePixel = 0; tabBar.ZIndex = 3
mkCorner(tabBar, 14)
-- Square top corners by overlaying a flat strip
local tabFlatTop = Instance.new("Frame", mainOuter)
tabFlatTop.Size = UDim2.new(1, 0, 0, 8); tabFlatTop.Position = UDim2.new(0, 0, 1, -TAB_H)
tabFlatTop.BackgroundColor3 = C.tabBarBg; tabFlatTop.BorderSizePixel = 0; tabFlatTop.ZIndex = 4

-- ============================================================
-- TAB SYSTEM  (Xerion V2 style — underline at top, vertical dividers)
-- ============================================================
local TABS = {"Speed", "Performance", "Mechanics", "Movement", "Settings"}
local currentTab = "Speed"
local tabBtns = {}; local tabPages = {}

local TAB_COUNT = #TABS
local tabW = math.floor(WIN_W / TAB_COUNT)
for i, name in ipairs(TABS) do
    local xOff = (i - 1) * tabW
    local col = Instance.new("Frame", tabBar)
    col.Size = UDim2.new(0, tabW, 1, 0); col.Position = UDim2.new(0, xOff, 0, 0)
    col.BackgroundTransparency = 1; col.BorderSizePixel = 0; col.ZIndex = 4

    local btn = Instance.new("TextButton", col)
    btn.Size = UDim2.new(1, 0, 1, -4); btn.Position = UDim2.new(0, 0, 0, 4)
    btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = (name == currentTab) and C.tabActive or C.tabIdle
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9
    btn.TextWrapped = true; btn.AutoButtonColor = false; btn.ZIndex = 5

    -- Underline at top of tab bar (Xerion V2 style)
    local underline = Instance.new("Frame", col)
    underline.Size = UDim2.new(0.65, 0, 0, 2); underline.Position = UDim2.new(0.175, 0, 0, 0)
    underline.BackgroundColor3 = C.tabUnderline; underline.BorderSizePixel = 0
    underline.ZIndex = 6; underline.Visible = (name == currentTab)
    mkCorner(underline, 1)

    -- Vertical divider between tabs
    if i < TAB_COUNT then
        local vd = Instance.new("Frame", col)
        vd.Size = UDim2.new(0, 1, 0.5, 0); vd.Position = UDim2.new(1, -1, 0.25, 0)
        vd.BackgroundColor3 = C.sectionDiv; vd.BorderSizePixel = 0; vd.ZIndex = 5
    end

    tabBtns[name] = {btn = btn, underline = underline}

    btn.MouseButton1Click:Connect(function()
        currentTab = name
        for _, n in ipairs(TABS) do
            local t = tabBtns[n]; local active = (n == name)
            t.btn.TextColor3 = active and C.tabActive or C.tabIdle
            t.underline.Visible = active
            if tabPages[n] then tabPages[n].Visible = active end
        end
    end)
end

-- ============================================================
-- ROW / PAGE BUILDERS
-- ============================================================
local currentPage = nil; local lo = 0
local function LO() lo = lo + 1; return lo end

local function makeGap(px)
    local f = Instance.new("Frame", currentPage)
    f.Size = UDim2.new(1, 0, 0, px or 6)
    f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.LayoutOrder = LO()
end

local function makeSectionHeader(label)
    local gap = Instance.new("Frame", currentPage)
    gap.Size = UDim2.new(1, 0, 0, 4); gap.BackgroundTransparency = 1; gap.BorderSizePixel = 0; gap.LayoutOrder = LO()
    local wrap = Instance.new("Frame", currentPage)
    wrap.Size = UDim2.new(1, 0, 0, 22); wrap.BackgroundTransparency = 1; wrap.BorderSizePixel = 0; wrap.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label and label:upper() or ""
    lbl.TextColor3 = C.sectionTxt
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4
end

local function makeInputRow(label, default, onChange)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 58)   -- Xerion V2 taller row
    row.BackgroundColor3 = C.rowBg; row.BackgroundTransparency = 0
    row.BorderSizePixel = 0; row.LayoutOrder = LO(); row.ZIndex = 3

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -24, 0, 1); div.Position = UDim2.new(0, 12, 1, -1)
    div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel = 0; div.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 0, 22); lbl.Position = UDim2.new(0, 14, 0, 10)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = C.rowSub
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

    -- Xerion V2 large value box
    local boxWrap = Instance.new("Frame", row)
    boxWrap.Size = UDim2.new(0, 74, 0, 34); boxWrap.Position = UDim2.new(1, -88, 0.5, -17)
    boxWrap.BackgroundColor3 = C.inputBg; boxWrap.BorderSizePixel = 0; boxWrap.ZIndex = 4
    mkCorner(boxWrap, 8); local bs = mkStroke(boxWrap, C.inputBorder, 1)

    local box = Instance.new("TextBox", boxWrap)
    box.Size = UDim2.new(1, 0, 1, 0); box.BackgroundTransparency = 1
    box.Text = tostring(default); box.TextColor3 = C.inputTxt
    box.Font = Enum.Font.GothamBlack; box.TextSize = 20
    box.ClearTextOnFocus = false; box.ZIndex = 5; box.TextXAlignment = Enum.TextXAlignment.Center
    box.Focused:Connect(function() TweenService:Create(bs, TweenInfo.new(0.15), {Color=C.inputFocus}):Play() end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs, TweenInfo.new(0.15), {Color=C.inputBorder}):Play()
        if onChange then local n = tonumber(box.Text); if n then onChange(n) else box.Text = tostring(default) end end
    end)
    return box, row
end

local function makeToggleRow(label, defaultOn, onToggle)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 50)   -- Xerion V2 height
    row.BackgroundColor3 = C.rowBg; row.BackgroundTransparency = 0
    row.BorderSizePixel = 0; row.LayoutOrder = LO(); row.ZIndex = 3

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -24, 0, 1); div.Position = UDim2.new(0, 12, 1, -1)
    div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel = 0; div.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = C.rowLabel; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4

    local pillBg = Instance.new("Frame", row)
    pillBg.Size = UDim2.new(0, 42, 0, 22); pillBg.Position = UDim2.new(1, -54, 0.5, -11)
    pillBg.BackgroundColor3 = defaultOn and C.pillOn or C.pillOff
    pillBg.BorderSizePixel = 0; pillBg.ZIndex = 5
    mkCorner(pillBg, 11); mkStroke(pillBg, C.pillBorder, 1)

    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = defaultOn and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    dot.BackgroundColor3 = defaultOn and C.dotOn or C.dotOff
    dot.BorderSizePixel = 0; dot.ZIndex = 6; mkCorner(dot, 7)

    local isOn = defaultOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pillBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
    end
    local function toggle() isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end end

    local clk = Instance.new("TextButton", row)
    clk.Size = UDim2.new(1, -64, 1, 0); clk.Position = UDim2.new(0, 14, 0, 0)
    clk.BackgroundTransparency = 1; clk.Text = ""; clk.ZIndex = 5; clk.BorderSizePixel = 0
    clk.MouseButton1Click:Connect(toggle)
    local pClk = Instance.new("TextButton", pillBg)
    pClk.Size = UDim2.new(1, 0, 1, 0); pClk.BackgroundTransparency = 1
    pClk.Text = ""; pClk.ZIndex = 7; pClk.BorderSizePixel = 0
    pClk.MouseButton1Click:Connect(toggle)
    return setV
end

-- ============================================================
-- KEYBIND ROW
-- ============================================================
local function getKeyDisplayName(kc)
    local n = kc.Name
    local gpNames = {
        ButtonA="A",ButtonB="B",ButtonX="X",ButtonY="Y",
        ButtonL1="LB",ButtonL2="LT",ButtonL3="LS",
        ButtonR1="RB",ButtonR2="RT",ButtonR3="RS",
        ButtonSelect="SEL",ButtonStart="STA",
        DPadUp="D↑",DPadDown="D↓",DPadLeft="D←",DPadRight="D→",
        Thumbstick1="LS",Thumbstick2="RS",
    }
    if gpNames[n] then return gpNames[n] end
    return n:sub(1, 5)
end

local function makeKeybindRow(label, currentKey, onChanged, keyName)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1; row.BorderSizePixel = 0; row.LayoutOrder = LO()

    local div = Instance.new("Frame", row)
    div.Size = UDim2.new(1, -28, 0, 1); div.Position = UDim2.new(0, 14, 1, -1)
    div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -80, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = C.rowLabel; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local kbtn = Instance.new("TextButton", row)
    kbtn.Size = UDim2.new(0, 52, 0, 26); kbtn.Position = UDim2.new(1, -64, 0.5, -13)
    kbtn.BackgroundColor3 = C.chipBg; kbtn.BorderSizePixel = 0
    kbtn.Text = getKeyDisplayName(currentKey); kbtn.TextColor3 = C.chipTxt
    kbtn.Font = Enum.Font.GothamBold; kbtn.TextSize = 11; kbtn.ZIndex = 8
    mkCorner(kbtn, 5); local ks = mkStroke(kbtn, C.chipBorder, 1)

    local listening = false; local lconnKeyboard = nil; local lconnGamepad = nil
    local function stopL(key)
        listening = false
        if lconnKeyboard then lconnKeyboard:Disconnect(); lconnKeyboard = nil end
        if lconnGamepad  then lconnGamepad:Disconnect();  lconnGamepad = nil  end
        TweenService:Create(ks, TweenInfo.new(0.12), {Color=C.chipBorder}):Play()
        kbtn.TextColor3 = C.chipTxt
        if key then
            kbtn.Text = getKeyDisplayName(key)
            if onChanged then onChanged(key) end
            -- Save config whenever a keybind changes
            task.spawn(function() if saveConfig then pcall(saveConfig) end end)
        end
    end
    kbtn.MouseButton1Click:Connect(function()
        if listening then stopL(nil); return end
        listening = true; kbtn.Text = "···"; kbtn.TextColor3 = C.inputTxt
        TweenService:Create(ks, TweenInfo.new(0.12), {Color=C.inputFocus}):Play()
        lconnKeyboard = UIS.InputBegan:Connect(function(inp)
            if not listening then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then stopL(nil); return end
            stopL(inp.KeyCode)
        end)
        lconnGamepad = UIS.InputBegan:Connect(function(inp)
            if not listening then return end
            if inp.UserInputType ~= Enum.UserInputType.Gamepad1
            and inp.UserInputType ~= Enum.UserInputType.Gamepad2
            and inp.UserInputType ~= Enum.UserInputType.Gamepad3
            and inp.UserInputType ~= Enum.UserInputType.Gamepad4 then return end
            local kc = inp.KeyCode; if kc == Enum.KeyCode.Unknown then return end
            stopL(kc)
        end)
    end)
    if keyName then keybindBtnRefs[keyName] = kbtn end
    return kbtn
end

-- ============================================================
-- BUILD PAGES
-- ============================================================
local function buildPage(tabName, buildFn)
    local page = Instance.new("ScrollingFrame", contentBg)
    page.Name = tabName; page.Visible = (tabName == "Speed")
    page.Size = UDim2.new(1, 0, 1, 0); page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 55)
    page.ScrollBarImageTransparency = 0
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local ll = Instance.new("UIListLayout", page)
    ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 0)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 12)
    tabPages[tabName] = page; currentPage = page; lo = 0
    buildFn()
    currentPage = nil
end

-- ============================================================
-- ============================================================
-- PURPLE SKY / NIGHT TIME / STRETCH REZ / ANTI CLEAN (File 1)
-- ============================================================
local _purpleSkyCC = nil
local function applyPurpleSky(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(60,30,90); Lighting.FogColor = Color3.fromRGB(80,40,120)
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
        sky.SkyboxBk="rbxassetid://1534951537"; sky.SkyboxDn="rbxassetid://1534951537"
        sky.SkyboxFt="rbxassetid://1534951537"; sky.SkyboxLf="rbxassetid://1534951537"
        sky.SkyboxRt="rbxassetid://1534951537"; sky.SkyboxUp="rbxassetid://1534951537"
        sky.StarCount=8000; sky.Parent=Lighting
        _purpleSkyCC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
        _purpleSkyCC.TintColor=Color3.fromRGB(180,140,255); _purpleSkyCC.Saturation=0.6
        _purpleSkyCC.Contrast=0.15; _purpleSkyCC.Parent=Lighting
    else
        Lighting.Ambient=Color3.fromRGB(0.5,0.5,0.5); Lighting.FogColor=Color3.fromRGB(0.75,0.75,0.75)
        if _purpleSkyCC then pcall(function() _purpleSkyCC:Destroy() end); _purpleSkyCC=nil end
    end
end

local _origLightingTime, _origLightingBright, _origLightingAmb = 14, 2, Color3.fromRGB(0.5,0.5,0.5)
local function applyNightTime(on)
    if on then
        Lighting.ClockTime=0; Lighting.Brightness=0.2; Lighting.Ambient=Color3.fromRGB(20,20,35)
    else
        Lighting.ClockTime=_origLightingTime; Lighting.Brightness=_origLightingBright; Lighting.Ambient=_origLightingAmb
    end
end

local function applyStretchRez(on)
    local cam=workspace.CurrentCamera; if not cam then return end
    cam.FieldOfView = on and 120 or 70
end

local function doAntiClean()
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("PointLight") or obj:IsA("SpotLight")
        or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- ============================================================
-- NO ANIM (File 4)
-- ============================================================
local _noAnimConns = {}
local _noAnimCharConn = nil
local function _disableAnims(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid"); if not humanoid then return end
    for _,track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
    if _noAnimConns[character] then pcall(function() _noAnimConns[character]:Disconnect() end) end
    _noAnimConns[character] = humanoid.AnimationPlayed:Connect(function(track) track:Stop() end)
end
local function startNoAnim()
    if _noAnimCharConn then return end
    if LP.Character then _disableAnims(LP.Character) end
    _noAnimCharConn = LP.CharacterAdded:Connect(function(char) _disableAnims(char) end)
end
local function stopNoAnim()
    if _noAnimCharConn then _noAnimCharConn:Disconnect(); _noAnimCharConn=nil end
    for char,conn in pairs(_noAnimConns) do pcall(function() if type(conn)~="string" then conn:Disconnect() end end) end
    _noAnimConns={}
end

-- ============================================================
-- OPTIMIZER (File 4)
-- ============================================================
local _optimizerEnabled = false
local _optimizerDescConn = nil
local function applyOptimizer()
    if _optimizerEnabled then return end; _optimizerEnabled=true
    pcall(function() setfpscap(999999999) end)
    pcall(function() local r=settings().Rendering; r.QualityLevel=Enum.QualityLevel.Level01 end)
    local function pO(v) pcall(function()
        if v:IsA("MeshPart") then v.CastShadow=false; v.RenderFidelity=Enum.RenderFidelity.Performance
        elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
        elseif v:IsA("SpecialMesh") then v.TextureId=""
        elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
        elseif v:IsA("SurfaceAppearance") then v:Destroy() end
    end) end
    for _,v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        local L=Lighting
        for _,v in pairs(L:GetDescendants()) do
            pcall(function() if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("PostEffect") then v:Destroy() end end)
        end
        L.GlobalShadows=false; L.FogEnd=9e9; L.Brightness=0
    end)
    _optimizerDescConn = workspace.DescendantAdded:Connect(function(v) if _optimizerEnabled then task.spawn(pO,v) end end)
end

-- ============================================================
-- AUTO TP DOWN (File 3)
-- ============================================================
local _autoTPConn = nil
local function startAutoTP()
    if _autoTPConn then return end
    _autoTPConn = task.spawn(function()
        while State.autoTPEnabled do
            task.wait(0.1)
            pcall(function()
                local char=LP.Character; if not char then return end
                local hrp2=char:FindFirstChild("HumanoidRootPart"); if not hrp2 then return end
                if hrp2.Position.Y >= math.abs(State.autoTPHeight) then
                    hrp2.CFrame=CFrame.new(hrp2.Position.X,-8.80,hrp2.Position.Z)
                    hrp2.AssemblyLinearVelocity=Vector3.zero
                end
            end)
        end
    end)
end
local function stopAutoTP()
    State.autoTPEnabled=false
    if _autoTPConn then pcall(function() task.cancel(_autoTPConn) end); _autoTPConn=nil end
end

-- SPEED PAGE
-- ============================================================
buildPage("Speed", function()
    makeGap(2)
    makeSectionHeader("Speed Settings")
    makeGap(2)
    normalBox = makeInputRow("Normal Speed", State.normalSpeed, function(n)
        if n > 0 and n <= 500 then State.normalSpeed = n end
    end)
    carryBox = makeInputRow("Carry Speed", State.carrySpeed, function(n)
        if n > 0 and n <= 500 then State.carrySpeed = n end
    end)
    laggerBox = makeInputRow("Lagger Speed", State.laggerSpeed, function(n)
        if n > 0 and n <= 500 then State.laggerSpeed = n end
    end)
    laggerCarryBox = makeInputRow("Lagger Carry Speed", State.laggerCarrySpeed, function(n)
        if n > 0 and n <= 500 then State.laggerCarrySpeed = n end
    end)

    makeGap(6)

    -- Mode display (read-only label)
    do
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1, 0, 0, 50); row.BackgroundColor3 = C.rowBg
        row.BackgroundTransparency = 0; row.BorderSizePixel = 0; row.LayoutOrder = LO(); row.ZIndex = 3
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1, -24, 0, 1); div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel = 0; div.ZIndex = 4
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Mode"; lbl.TextColor3 = C.rowLabel
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4
        modeDisplayLbl = Instance.new("TextLabel", row)
        modeDisplayLbl.Size = UDim2.new(0.5, -14, 1, 0); modeDisplayLbl.Position = UDim2.new(0.5, 0, 0, 0)
        modeDisplayLbl.BackgroundTransparency = 1; modeDisplayLbl.Text = "Normal"
        modeDisplayLbl.TextColor3 = C.accent; modeDisplayLbl.Font = Enum.Font.GothamBold
        modeDisplayLbl.TextSize = 12; modeDisplayLbl.TextXAlignment = Enum.TextXAlignment.Right; modeDisplayLbl.ZIndex = 4
    end

    -- Carry Mode toggle + Speed keybind chip
    do
        local row = makeToggleRow("Carry Mode", false, function(on)
            State.speedToggled = on
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(on) end
            if modeDisplayLbl then modeDisplayLbl.Text = State.laggerEnabled and "Lagger" or (on and "Carry" or "Normal") end
        end)
        carryModeToggle = row
        makeKeybindRow("  Speed Key", Keys.speed, function(k) Keys.speed = k end, "speed")
    end

    -- Lagger Mode toggle + Lagger keybind chip
    do
        local row = makeToggleRow("Lagger Mode", false, function(on)
            State.laggerEnabled = on
            if on then
                State._prevCarry = State.carrySpeed; State._prevSpeed = State.speedToggled; State.speedToggled = false
                if carryModeToggle then carryModeToggle(false) end
                if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(true) end
                if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
            else
                State.carrySpeed = State._prevCarry or 28.5; State.speedToggled = State._prevSpeed or false
                if carryBox then carryBox.Text = tostring(State.carrySpeed) end
                if carryModeToggle then carryModeToggle(State.speedToggled) end
                if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(false) end
                if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
            end
            if modeDisplayLbl then modeDisplayLbl.Text = on and "Lagger" or (State.speedToggled and "Carry" or "Normal") end
        end)
        laggerModeToggle = row
        makeKeybindRow("  Lagger Key", Keys.lagger, function(k) Keys.lagger = k end, "lagger")
    end
end)

-- ============================================================
-- PERFORMANCE PAGE
-- ============================================================
buildPage("Performance", function()
    makeGap(2)
    makeSectionHeader("Performance / Aimbot")
    makeGap(2)
    setBatAimbot = makeToggleRow("Bat Aimbot", false, function(on)
        State.batAimbotToggled = on
        if on then
            if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
            if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
            pcall(startBatAimbot)
        else stopBatAimbot() end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(on) end
    end)
    makeInputRow("Aimbot Speed", State.aimbotSpeed or 56.5, function(n)
        if n > 0 and n <= 500 then State.aimbotSpeed = n end
    end)
end)

-- ============================================================
-- MECHANICS PAGE
-- ============================================================
buildPage("Mechanics", function()
    makeGap(2)
    makeSectionHeader("Auto")
    makeGap(2)
    setInstaGrab = makeToggleRow("Insta Grab", false, function(on)
        Steal.AutoStealEnabled = on
        if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled = false; setInstaGrab(false) end
        else stopAutoSteal() end
    end)
    setAntiRag = makeToggleRow("Anti Ragdoll", false, function(on)
        State.antiRagdollEnabled = on; if on then startAntiRagdoll() else stopAntiRagdoll() end
    end)
    setInfJump = makeToggleRow("Infinite Jump", false, function(on) State.infJumpEnabled = on end)
    setMedusaCounter = makeToggleRow("Medusa Counter", false, function(on)
        State.medusaCounterEnabled = on
        if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
    end)
    stealRadBox = makeInputRow("Steal Radius", Steal.StealRadius, function(n)
        if n >= 5 and n <= 300 then Steal.StealRadius = math.floor(n); Steal.cachedPrompts = {}; Steal.promptCacheTime = 0 end
    end)

    makeGap(8)
    makeSectionHeader("Combat / Defense")
    makeGap(2)
    setAutoSwing = makeToggleRow("Auto Swing", false, function(on) State.autoSwingEnabled = on end)
    setBatCounter = makeToggleRow("Bat Counter", false, function(on)
        State.batCounterEnabled = on
        if on then startBatCounter() else stopBatCounter() end
    end)
    setAutoTP = makeToggleRow("Auto TP Down", false, function(on)
        State.autoTPEnabled = on
        if on then startAutoTP() else stopAutoTP() end
    end)
    makeInputRow("TP Height Threshold", State.autoTPHeight, function(n)
        if n >= 5 and n <= 500 then State.autoTPHeight = n end
    end)

    makeGap(8)
    makeSectionHeader("Misc")
    makeGap(2)
    setUnwalkToggle = makeToggleRow("Unwalk", false, function(on)
        State.unwalkEnabled = on
        if on then startUnwalk() else stopUnwalk() end
    end)
end)

-- ============================================================
-- MOVEMENT PAGE
-- ============================================================
buildPage("Movement", function()
    makeGap(2)
    makeSectionHeader("Auto Movement")
    makeGap(2)
    makeKeybindRow("Auto Left Key", Keys.autoLeft, function(k) Keys.autoLeft = k end, "autoLeft")
    makeKeybindRow("Auto Right Key", Keys.autoRight, function(k) Keys.autoRight = k end, "autoRight")
    makeKeybindRow("Aimbot Key", Keys.aimbot, function(k) Keys.aimbot = k end, "aimbot")
    makeKeybindRow("Drop Key", Keys.drop, function(k) Keys.drop = k end, "drop")
    makeKeybindRow("TP Down Key", Keys.tpDown, function(k) Keys.tpDown = k end, "tpDown")
end)

-- ============================================================
-- SETTINGS PAGE
-- ============================================================
local function applyStackButtonsVisible(visible)
    State.stackButtonsHidden = not visible
    for _, wrapper in pairs(stackWrappers) do wrapper.Visible = visible end
end

local function applyPreset(data)
    -- Speeds
    if data.normalSpeed then State.normalSpeed=data.normalSpeed; if normalBox then normalBox.Text=tostring(data.normalSpeed) end end
    if data.carrySpeed  then State.carrySpeed=data.carrySpeed;   if carryBox  then carryBox.Text=tostring(data.carrySpeed)   end end
    if data.laggerSpeed then State.laggerSpeed=data.laggerSpeed; if laggerBox then laggerBox.Text=tostring(data.laggerSpeed)  end end
    -- Steal
    if data.stealRadius then
        Steal.StealRadius=data.stealRadius; Steal.cachedPrompts={}; Steal.promptCacheTime=0
        if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text=tostring(data.stealRadius) end
        if radTB and not radTB:IsFocused() then radTB.Text=tostring(data.stealRadius) end
    end
    if data.stealDuration then Steal.StealDuration=data.stealDuration end
    -- Toggles (NO keybinds — those are managed by saveConfig/loadConfig only)
    if data.infJump~=nil       and setInfJump       then State.infJumpEnabled=data.infJump;           setInfJump(data.infJump) end
    if data.antiRagdoll~=nil   and setAntiRag       then State.antiRagdollEnabled=data.antiRagdoll;   setAntiRag(data.antiRagdoll); if data.antiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end end
    if data.fpsBoost~=nil      and setFps           then State.fpsBoostEnabled=data.fpsBoost;         setFps(data.fpsBoost);         if data.fpsBoost then pcall(applyFPSBoost) end end
    if data.medusaCounter~=nil and setMedusaCounter then State.medusaCounterEnabled=data.medusaCounter; setMedusaCounter(data.medusaCounter); if data.medusaCounter then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end
    if data.batCounter~=nil    and setBatCounter    then State.batCounterEnabled=data.batCounter;     setBatCounter(data.batCounter);     if data.batCounter then startBatCounter() else stopBatCounter() end end
    if data.autoSteal~=nil     and setInstaGrab     then
        Steal.AutoStealEnabled=data.autoSteal; setInstaGrab(data.autoSteal)
        if data.autoSteal then pcall(startAutoSteal) else stopAutoSteal() end
    end
end

buildPage("Settings", function()
    makeGap(2)
    makeSectionHeader("Interface")
    makeGap(2)
    makeKeybindRow("Hide GUI", Keys.guiHide, function(k) Keys.guiHide = k end, "guiHide")
    uiScaleBox = makeInputRow("UI Scale", 0.8, function(n)
        if n >= 0.5 and n <= 2.0 then if uiScaleObj then uiScaleObj.Scale = n end end
    end)
    setHideButtonsToggle = makeToggleRow("Hide Buttons", false, function(on)
        applyStackButtonsVisible(not on)
    end)

    makeGap(8)
    makeSectionHeader("Visual / World")
    makeGap(2)
    makeToggleRow("Purple Sky", false, function(on)
        State.purpleSkyEnabled=on; applyPurpleSky(on)
    end)
    makeToggleRow("Night Time", false, function(on)
        State.nightTimeEnabled=on; applyNightTime(on)
    end)
    makeToggleRow("Stretch Rez", false, function(on)
        State.stretchRezEnabled=on; applyStretchRez(on)
    end)
    do  -- Anti Clean is one-shot
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1, 0, 0, 50); row.BackgroundColor3 = C.rowBg
        row.BackgroundTransparency = 0; row.BorderSizePixel = 0; row.LayoutOrder = LO(); row.ZIndex = 3
        local div = Instance.new("Frame", row); div.Size = UDim2.new(1,-24,0,1); div.Position = UDim2.new(0,12,1,-1)
        div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel = 0; div.ZIndex = 4
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -90, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Anti Clean"; lbl.TextColor3 = C.rowLabel
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4
        local cleanBtn = Instance.new("TextButton", row)
        cleanBtn.Size = UDim2.new(0, 60, 0, 28); cleanBtn.Position = UDim2.new(1, -72, 0.5, -14)
        cleanBtn.BackgroundColor3 = C.btnBg; cleanBtn.BorderSizePixel = 0
        cleanBtn.Text = "RUN"; cleanBtn.TextColor3 = C.btnTxt
        cleanBtn.Font = Enum.Font.GothamBold; cleanBtn.TextSize = 11; cleanBtn.ZIndex = 5
        mkCorner(cleanBtn, 6); mkStroke(cleanBtn, C.btnBorder, 1)
        cleanBtn.MouseButton1Click:Connect(function()
            doAntiClean(); cleanBtn.Text = "DONE"
            task.delay(2, function() if cleanBtn and cleanBtn.Parent then cleanBtn.Text = "RUN" end end)
        end)
    end
    makeToggleRow("No Anim", false, function(on)
        State.noAnimEnabled=on; if on then startNoAnim() else stopNoAnim() end
    end)
    makeToggleRow("Optimizer", false, function(on)
        State.optimizerEnabled=on; if on then pcall(applyOptimizer) end
    end)
    setFps = makeToggleRow("FPS Boost", false, function(on)
        State.fpsBoostEnabled = on; if on then pcall(applyFPSBoost) end
    end)

    makeGap(8)

    local rWrap = Instance.new("Frame", currentPage)
    rWrap.Size = UDim2.new(1, 0, 0, 46); rWrap.BackgroundTransparency = 1
    rWrap.BorderSizePixel = 0; rWrap.LayoutOrder = LO()
    local resetBtn = Instance.new("TextButton", rWrap)
    resetBtn.Size = UDim2.new(1, -28, 0, 32); resetBtn.Position = UDim2.new(0, 14, 0, 7)
    resetBtn.BackgroundColor3 = C.btnBg; resetBtn.BorderSizePixel = 0
    resetBtn.Text = "↺  Reset Button Positions"; resetBtn.TextColor3 = C.btnTxt
    resetBtn.Font = Enum.Font.GothamBold; resetBtn.TextSize = 12; resetBtn.ZIndex = 5
    mkCorner(resetBtn, 6); mkStroke(resetBtn, C.btnBorder, 1)
    resetBtn.MouseEnter:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnHov}):Play() end)
    resetBtn.MouseLeave:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnBg}):Play() end)
    resetBtn.MouseButton1Click:Connect(function()
        for i, def in ipairs(stackDefs) do
            local wrapper = stackWrappers[def.key]
            if wrapper then TweenService:Create(wrapper,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play() end
        end
        resetBtn.Text = "✓  Positions Reset!"
        task.delay(1.8, function() if resetBtn and resetBtn.Parent then resetBtn.Text = "↺  Reset Button Positions" end end)
    end)

    makeGap(8)
    makeSectionHeader("Presets")
    makeGap(4)

    local nameWrap = Instance.new("Frame", currentPage)
    nameWrap.Size = UDim2.new(1, 0, 0, 38); nameWrap.BackgroundTransparency = 1
    nameWrap.BorderSizePixel = 0; nameWrap.LayoutOrder = LO()
    local nameBoxWrap = Instance.new("Frame", nameWrap)
    nameBoxWrap.Size = UDim2.new(1, -28, 0, 30); nameBoxWrap.Position = UDim2.new(0, 14, 0, 4)
    nameBoxWrap.BackgroundColor3 = C.inputBg; nameBoxWrap.BorderSizePixel = 0; mkCorner(nameBoxWrap, 6)
    local nbs = mkStroke(nameBoxWrap, C.inputBorder, 1)
    presetNameBox = Instance.new("TextBox", nameBoxWrap)
    presetNameBox.Size = UDim2.new(1, -8, 1, 0); presetNameBox.Position = UDim2.new(0, 4, 0, 0)
    presetNameBox.BackgroundTransparency = 1; presetNameBox.PlaceholderText = "Preset name..."
    presetNameBox.PlaceholderColor3 = C.rowSub; presetNameBox.Text = ""
    presetNameBox.TextColor3 = C.inputTxt; presetNameBox.Font = Enum.Font.GothamBold
    presetNameBox.TextSize = 12; presetNameBox.ClearTextOnFocus = false; presetNameBox.ZIndex = 9
    presetNameBox.TextXAlignment = Enum.TextXAlignment.Left
    presetNameBox.Focused:Connect(function() TweenService:Create(nbs,TweenInfo.new(0.15),{Color=C.inputFocus}):Play() end)
    presetNameBox.FocusLost:Connect(function() TweenService:Create(nbs,TweenInfo.new(0.15),{Color=C.inputBorder}):Play() end)

    makeGap(4)

    local sWrap = Instance.new("Frame", currentPage)
    sWrap.Size = UDim2.new(1, 0, 0, 38); sWrap.BackgroundTransparency = 1
    sWrap.BorderSizePixel = 0; sWrap.LayoutOrder = LO()
    local savePBtn = Instance.new("TextButton", sWrap)
    savePBtn.Size = UDim2.new(1, -28, 0, 30); savePBtn.Position = UDim2.new(0, 14, 0, 4)
    savePBtn.BackgroundColor3 = C.btnBg; savePBtn.BorderSizePixel = 0
    savePBtn.Text = "+ Save Preset"; savePBtn.TextColor3 = C.btnTxt
    savePBtn.Font = Enum.Font.GothamBold; savePBtn.TextSize = 12; savePBtn.ZIndex = 9
    mkCorner(savePBtn, 6); mkStroke(savePBtn, C.btnBorder, 1)
    savePBtn.MouseEnter:Connect(function() TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnHov}):Play() end)
    savePBtn.MouseLeave:Connect(function() TweenService:Create(savePBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnBg}):Play() end)
    savePBtn.MouseButton1Click:Connect(function()
        local nm = presetNameBox.Text:match("^%s*(.-)%s*$")
        if nm == "" then savePBtn.Text = "Name required!"; task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end); return end
        local found = false
        for i, p in ipairs(Presets) do if p.name == nm then Presets[i].data = buildPresetSnapshot(); found = true; break end end
        if not found then table.insert(Presets, {name=nm, data=buildPresetSnapshot()}) end
        savePresetsFile(); presetNameBox.Text = ""
        savePBtn.Text = "✓ Saved!"; task.delay(1.5, function() savePBtn.Text = "+ Save Preset" end)
        rebuildPresetList()
    end)

    makeGap(4)

    local listWrap = Instance.new("Frame", currentPage)
    listWrap.Size = UDim2.new(1, 0, 0, 0); listWrap.AutomaticSize = Enum.AutomaticSize.Y
    listWrap.BackgroundTransparency = 1; listWrap.BorderSizePixel = 0; listWrap.LayoutOrder = LO()
    local listLL = Instance.new("UIListLayout", listWrap)
    listLL.SortOrder = Enum.SortOrder.LayoutOrder; listLL.Padding = UDim.new(0, 4)
    local listPad = Instance.new("UIPadding", listWrap)
    listPad.PaddingLeft = UDim.new(0, 14); listPad.PaddingRight = UDim.new(0, 14)
    presetListFrame = listWrap

    local emptyLbl = Instance.new("TextLabel", listWrap)
    emptyLbl.Name = "EmptyLabel"; emptyLbl.Size = UDim2.new(1, 0, 0, 28)
    emptyLbl.BackgroundTransparency = 1; emptyLbl.Text = "No presets saved yet."
    emptyLbl.TextColor3 = C.rowSub; emptyLbl.Font = Enum.Font.Gotham; emptyLbl.TextSize = 11
    emptyLbl.TextXAlignment = Enum.TextXAlignment.Center; emptyLbl.LayoutOrder = 1

    makeGap(10)

    -- BIG WHITE SAVE CONFIG BUTTON
    do
        local sRow = Instance.new("Frame", currentPage)
        sRow.Size = UDim2.new(1, 0, 0, 54); sRow.BackgroundTransparency = 1
        sRow.BorderSizePixel = 0; sRow.LayoutOrder = LO()
        local saveBtn = Instance.new("TextButton", sRow)
        saveBtn.Size = UDim2.new(1, -28, 0, 44); saveBtn.Position = UDim2.new(0, 14, 0, 5)
        saveBtn.BackgroundColor3 = Color3.fromRGB(240,240,240); saveBtn.BorderSizePixel = 0
        saveBtn.Text = "SAVE CONFIG"; saveBtn.TextColor3 = Color3.fromRGB(15,15,15)
        saveBtn.Font = Enum.Font.GothamBlack; saveBtn.TextSize = 16; saveBtn.ZIndex = 9
        mkCorner(saveBtn, 10); mkStroke(saveBtn, Color3.fromRGB(200,200,200), 1.5)
        saveBtn.MouseButton1Click:Connect(function()
            -- Save steal radius, insta steal, unwalk, bat counter, medusa counter + keybinds
            local function ksn(kc) return kc and kc.Name or "Unknown" end
            local cfg = {
                stealRadius = Steal.StealRadius,
                autoSteal   = Steal.AutoStealEnabled,
                unwalk      = State.unwalkEnabled,
                batCounter  = State.batCounterEnabled,
                medusaCounter = State.medusaCounterEnabled,
                normalSpeed = State.normalSpeed, carrySpeed = State.carrySpeed,
                laggerSpeed = State.laggerSpeed, laggerCarrySpeed = State.laggerCarrySpeed,
                speedKey    = ksn(Keys.speed), laggerKey   = ksn(Keys.lagger),
                autoLeftKey = ksn(Keys.autoLeft), autoRightKey = ksn(Keys.autoRight),
                aimbotKey   = ksn(Keys.aimbot), dropKey  = ksn(Keys.drop),
                tpDownKey   = ksn(Keys.tpDown), guiHideKey = ksn(Keys.guiHide),
                uiScale     = uiScaleObj and uiScaleObj.Scale or 0.8,
            }
            pcall(function()
                local hs = game:GetService("HttpService")
                local enc = hs:JSONEncode(cfg)
                if writefile then writefile("AsireHubConfig.json", enc) end
            end)
            saveBtn.Text = "✓ SAVED!"; saveBtn.BackgroundColor3 = Color3.fromRGB(200,255,200)
            task.delay(1.8, function()
                if saveBtn and saveBtn.Parent then
                    saveBtn.Text = "SAVE CONFIG"; saveBtn.BackgroundColor3 = Color3.fromRGB(240,240,240)
                end
            end)
        end)
    end

    makeGap(10)

    local fw = Instance.new("Frame", currentPage); fw.Size = UDim2.new(1, 0, 0, 22)
    fw.BackgroundTransparency = 1; fw.BorderSizePixel = 0; fw.LayoutOrder = LO()
    local fl = Instance.new("TextLabel", fw); fl.Size = UDim2.new(1, 0, 1, 0)
    fl.BackgroundTransparency = 1; fl.Text = "asirehub  ·  v5.3"
    fl.TextColor3 = Color3.fromRGB(35,35,35); fl.Font = Enum.Font.Gotham; fl.TextSize = 10
    fl.TextXAlignment = Enum.TextXAlignment.Center
end)

-- ============================================================
-- REBUILD PRESET LIST UI
-- ============================================================
rebuildPresetList = function()
    if not presetListFrame then return end
    for _, child in ipairs(presetListFrame:GetChildren()) do
        if child.Name ~= "EmptyLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    local emptyLbl = presetListFrame:FindFirstChild("EmptyLabel")
    if emptyLbl then emptyLbl.Visible = (#Presets == 0) end
    for i, preset in ipairs(Presets) do
        local row = Instance.new("Frame", presetListFrame)
        row.Name = "Preset_"..i; row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = C.presetBg; row.BorderSizePixel = 0; row.LayoutOrder = i+1
        mkCorner(row, 6); mkStroke(row, C.presetBrd, 1)
        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -94, 1, 0); nameLbl.Position = UDim2.new(0, 10, 0, 0)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = preset.name
        nameLbl.TextColor3 = C.rowLabel; nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0, 44, 0, 26); loadBtn.Position = UDim2.new(1, -96, 0.5, -13)
        loadBtn.BackgroundColor3 = C.presetLoad; loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"; loadBtn.TextColor3 = Color3.fromRGB(210,210,210)
        loadBtn.Font = Enum.Font.GothamBold; loadBtn.TextSize = 11; loadBtn.ZIndex = 9
        mkCorner(loadBtn, 5)
        loadBtn.MouseEnter:Connect(function() TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(70,70,70)}):Play() end)
        loadBtn.MouseLeave:Connect(function() TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetLoad}):Play() end)
        loadBtn.MouseButton1Click:Connect(function()
            applyPreset(preset.data); saveLastPresetName(preset.name)
            loadBtn.Text = "✓"; task.delay(1.2, function() if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end end)
        end)
        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 34, 0, 26); delBtn.Position = UDim2.new(1, -48, 0.5, -13)
        delBtn.BackgroundColor3 = C.presetDel; delBtn.BorderSizePixel = 0
        delBtn.Text = "✕"; delBtn.TextColor3 = Color3.fromRGB(200,80,80)
        delBtn.Font = Enum.Font.GothamBold; delBtn.TextSize = 11; delBtn.ZIndex = 9
        mkCorner(delBtn, 5)
        delBtn.MouseEnter:Connect(function() TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(80,28,28)}):Play() end)
        delBtn.MouseLeave:Connect(function() TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetDel}):Play() end)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(Presets, i); savePresetsFile(); rebuildPresetList()
        end)
    end
end

-- Init tab states
for _, n in ipairs(TABS) do
    local t = tabBtns[n]; local active = (n == "Speed")
    t.btn.TextColor3 = active and C.tabActive or C.tabIdle
    t.btn.BackgroundColor3 = active and C.tabActiveBg or C.tabBarBg
    t.underline.Visible = active
    if tabPages[n] then tabPages[n].Visible = active end
end

-- ============================================================
-- VBTN (floating logo toggle)
-- ============================================================
local vBtnFrame = Instance.new("Frame", gui)
vBtnFrame.Name = "AsireVBtn"; vBtnFrame.Size = UDim2.new(0, 36, 0, 36)
vBtnFrame.Position = UDim2.new(1, -50, 0, 14)
vBtnFrame.BackgroundColor3 = C.accent; vBtnFrame.BorderSizePixel = 0
vBtnFrame.Active = true; vBtnFrame.ZIndex = 20
mkCorner(vBtnFrame, 8); mkStroke(vBtnFrame, C.accentDim, 1)
local vBtnImg = Instance.new("ImageLabel", vBtnFrame)
vBtnImg.Size = UDim2.new(1, -6, 1, -6); vBtnImg.Position = UDim2.new(0, 3, 0, 3)
vBtnImg.BackgroundTransparency = 1; vBtnImg.Image = LOGO_ID
vBtnImg.ScaleType = Enum.ScaleType.Fit; vBtnImg.ZIndex = 21
local vDragging,vDragInput,vDragStart,vStartPos=false,nil,nil,nil; local vMoved=false
vBtnFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    vDragging=true; vMoved=false; vDragStart=inp.Position; vStartPos=vBtnFrame.Position
    inp.Changed:Connect(function()
        if inp.UserInputState==Enum.UserInputState.End then
            if not vMoved then State.guiVisible=not State.guiVisible; mainOuter.Visible=State.guiVisible end
            vDragging=false; vMoved=false
        end
    end)
end)
vBtnFrame.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then vDragInput=inp end
end)
UIS.InputChanged:Connect(function(inp)
    if inp~=vDragInput or not vDragging then return end
    local dx=inp.Position.X-vDragStart.X; local dy=inp.Position.Y-vDragStart.Y
    if math.abs(dx)>4 or math.abs(dy)>4 then vMoved=true end
    if vMoved then vBtnFrame.Position=UDim2.new(vStartPos.X.Scale,vStartPos.X.Offset+dx,vStartPos.Y.Scale,vStartPos.Y.Offset+dy) end
end)

-- ============================================================
-- ============================================================
-- STEAL PROGRESS BAR  (Colt_Duels style)
-- ============================================================
local pbFrame = Instance.new("Frame", gui)
pbFrame.Size = UDim2.new(0, 280, 0, 54); pbFrame.Position = UDim2.new(0.5, -140, 1, -66)
pbFrame.BackgroundColor3 = Color3.fromRGB(8,8,8); pbFrame.BorderSizePixel = 0; pbFrame.Active = true
pbFrame.ClipsDescendants = false; pbFrame.ZIndex = 35
mkCorner(pbFrame, 9); mkStroke(pbFrame, Color3.fromRGB(42,42,42), 1.2)
makeDraggable(pbFrame)

local progressPct = Instance.new("TextLabel", pbFrame)
progressPct.Size = UDim2.new(0.5, -6, 0, 16); progressPct.Position = UDim2.new(0, 9, 0, 7)
progressPct.BackgroundTransparency = 1; progressPct.Text = "IDLE"
progressPct.TextColor3 = Color3.fromRGB(110,110,110); progressPct.Font = Enum.Font.GothamBlack
progressPct.TextSize = 11; progressPct.TextXAlignment = Enum.TextXAlignment.Left; progressPct.ZIndex = 36

local progressRadLbl = Instance.new("TextLabel", pbFrame)
progressRadLbl.Size = UDim2.new(0.5, -6, 0, 16); progressRadLbl.Position = UDim2.new(0.5, 0, 0, 7)
progressRadLbl.BackgroundTransparency = 1
progressRadLbl.Text = "Radius: "..tostring(Steal.StealRadius)
progressRadLbl.TextColor3 = Color3.fromRGB(110,110,110); progressRadLbl.Font = Enum.Font.GothamBold
progressRadLbl.TextSize = 11; progressRadLbl.TextXAlignment = Enum.TextXAlignment.Right; progressRadLbl.ZIndex = 36

local pbTrack = Instance.new("Frame", pbFrame)
pbTrack.Size = UDim2.new(1,-18,0,10); pbTrack.Position = UDim2.new(0,9,0,28)
pbTrack.BackgroundColor3 = Color3.fromRGB(20,20,20); pbTrack.BorderSizePixel = 0; pbTrack.ZIndex = 36
mkCorner(pbTrack, 5)

local progressFill = Instance.new("Frame", pbTrack)
progressFill.Size = UDim2.new(0,0,1,0); progressFill.BackgroundColor3 = Color3.fromRGB(200,200,200)
progressFill.BorderSizePixel = 0; progressFill.ZIndex = 37; mkCorner(progressFill, 5)

local pbLbl = Instance.new("TextLabel", pbFrame)
pbLbl.Size = UDim2.new(1,-18,0,10); pbLbl.Position = UDim2.new(0,9,0,44)
pbLbl.BackgroundTransparency = 1; pbLbl.Text = "ASIRE HUB  v5.3"
pbLbl.TextColor3 = Color3.fromRGB(60,60,60); pbLbl.Font = Enum.Font.Gotham
pbLbl.TextSize = 8; pbLbl.TextXAlignment = Enum.TextXAlignment.Center; pbLbl.ZIndex = 36

-- Idle pulse
task.spawn(function()
    while pbFrame and pbFrame.Parent do
        if not State.isStealing then
            local t=tick()*0.6; local pct=(math.sin(t)+1)*0.5
            pcall(function()
                progressFill.Size=UDim2.new(pct,0,1,0)
                progressPct.Text = Steal.AutoStealEnabled and "SCAN" or "IDLE"
                progressPct.TextColor3 = Steal.AutoStealEnabled and Color3.fromRGB(200,200,200) or Color3.fromRGB(90,90,90)
            end)
        end
        task.wait(0.04)
    end
end)

-- STACK BUTTONS
-- ============================================================


-- ============================================================
-- HELPERS
-- ============================================================
local function resetProgressBar() progressPct.Text="0%"; progressFill.Size=UDim2.new(0,0,1,0) end

doTpDown = function()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local res=workspace:Raycast(root.Position,Vector3.new(0,-1000,0),rp)
        if res then root.CFrame=CFrame.new(res.Position+Vector3.new(0,root.Size.Y/2+0.5,0)); root.AssemblyLinearVelocity=Vector3.zero end
    end)
end

-- ============================================================
-- DROP BRAINROT
-- ============================================================
local _dropConns={}
runDropBrainrot=function()
    if State.dropEnabled then return end; State.dropEnabled=true
    if stackBtnRefs.drop then stackBtnRefs.drop.setOn(true) end
    task.spawn(function()
        local colConn=RunService.Stepped:Connect(function()
            if not State.dropEnabled then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and p.Character then
                    for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end
                end
            end
        end)
        table.insert(_dropConns,colConn)
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
        task.wait(DROP_AUTO_OFF_DELAY); stopDropBrainrot()
    end)
end
stopDropBrainrot=function()
    State.dropEnabled=false
    for _,cn in ipairs(_dropConns) do pcall(function() cn:Disconnect() end) end; _dropConns={}
    if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
end

-- ============================================================
-- VYSE-STYLE BAT AIMBOT
-- ============================================================
local VYSE_AIMBOT_SPEED=56.5; local VYSE_HIT_DIST=5; local SWING_COOLDOWN=0.08

local function findAnyTool()
    local c=LP.Character
    if c then for _,v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return v end end end
    local bp=LP:FindFirstChildOfClass("Backpack")
    if bp then for _,v in ipairs(bp:GetChildren()) do if v:IsA("Tool") then return v end end end
    return nil
end

local function getClosestPlayer()
    if not hrp then return nil,math.huge end
    local cp,cd=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local tr=p.Character:FindFirstChild("HumanoidRootPart")
            local ph=p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health>0 then
                local d=(hrp.Position-tr.Position).Magnitude
                if d<cd then cd=d; cp=p end
            end
        end
    end
    return cp,cd
end

local function tryHitBat()
    if State.hittingCooldown then return end; State.hittingCooldown=true
    pcall(function()
        local c=LP.Character; if not c then return end
        local hum2=c:FindFirstChildOfClass("Humanoid")
        local tool=findAnyTool()
        if tool then
            if tool.Parent~=c and hum2 then pcall(function() hum2:EquipTool(tool) end) end
            local remote=tool:FindFirstChildOfClass("RemoteEvent")
            if remote then pcall(function() remote:FireServer() end)
            else pcall(function() tool:Activate() end) end
        end
    end)
    task.delay(SWING_COOLDOWN,function() State.hittingCooldown=false end)
end

startBatAimbot=function()
    if Conns.aimbot then return end
    Conns.aimbot=RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum2=c:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local target,dist=getClosestPlayer()
        if target and target.Character then
            local tr=target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local fp=tr.Position+tr.CFrame.LookVector*1.5
                local dir=(fp-root.Position).Unit
                root.AssemblyLinearVelocity=Vector3.new(dir.X*VYSE_AIMBOT_SPEED,dir.Y*VYSE_AIMBOT_SPEED,dir.Z*VYSE_AIMBOT_SPEED)
                if dist<=VYSE_HIT_DIST and State.autoSwingEnabled then tryHitBat() end
            end
        else root.AssemblyLinearVelocity=Vector3.zero end
    end)
end
stopBatAimbot=function()
    if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot=nil end
    local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity=Vector3.zero end; State.hittingCooldown=false
end

-- ============================================================
-- BAT COUNTER
-- ============================================================
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
    if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.05) end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end); task.wait(0.15); pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end); task.wait(0.15); pcall(function() bat:Activate() end) end
end

startBatCounter=function()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled then return end
        if State.batCounterDebounce then return end
        local char=LP.Character; if not char then return end
        local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local st=hum2:GetState()
        local isRagdolled=st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
        if isRagdolled then
            State.batCounterDebounce=true
            task.spawn(function()
                local bat=findBatForCounter()
                if bat then swingBatForCounter(bat,char) end
                task.wait(0.5); State.batCounterDebounce=false
            end)
        end
    end)
end
stopBatCounter=function()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
    State.batCounterDebounce=false
end

-- ============================================================
-- MEDUSA
-- ============================================================
local function findMedusa()
    local c=LP.Character; if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
    local bp=LP:FindFirstChild("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
    return nil
end
local function useMedusaCounter()
    if State.medusaDebounce then return end; if tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
    local c=LP.Character; if not c then return end; State.medusaDebounce=true
    local med=findMedusa(); if not med then State.medusaDebounce=false; return end
    if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
    pcall(function() med:Activate() end); State.medusaLastUsed=tick(); State.medusaDebounce=false
end
local function onAnchorChanged(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if part.Anchored and part.Transparency==1 then useMedusaCounter() end end) end
setupMedusaCounter=function(char)
    stopMedusaCounter(); if not char then return end
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
end
stopMedusaCounter=function() for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end; Conns.anchor={} end

-- ============================================================
-- AUTO LEFT / RIGHT
-- ============================================================
local function faceSouth() pcall(function() local c=LP.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart"); if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,0,0) end end) end
local function faceNorth() pcall(function() local c=LP.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart"); if root then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.rad(180),0) end end) end

startAutoLeft=function()
    if Conns.autoLeft then Conns.autoLeft:Disconnect() end; State.autoLeftPhase=1
    Conns.autoLeft=RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled then return end; local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid"); if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoLeftPhase==1 then
            local tgt=Vector3.new(POS.L1.X,root.Position.Y,POS.L1.Z); if (tgt-root.Position).Magnitude<1 then State.autoLeftPhase=2; local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd); return end
            local d=(POS.L1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoLeftPhase==2 then
            local tgt=Vector3.new(POS.L2.X,root.Position.Y,POS.L2.Z); if (tgt-root.Position).Magnitude<1 then hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero; State.autoLeftEnabled=false; if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end; State.autoLeftPhase=1; if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end; faceSouth(); return end
            local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
stopAutoLeft=function()
    if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end; State.autoLeftPhase=1
    local c=LP.Character; if c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
    if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
end

startAutoRight=function()
    if Conns.autoRight then Conns.autoRight:Disconnect() end; State.autoRightPhase=1
    Conns.autoRight=RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled then return end; local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid"); if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoRightPhase==1 then
            local tgt=Vector3.new(POS.R1.X,root.Position.Y,POS.R1.Z); if (tgt-root.Position).Magnitude<1 then State.autoRightPhase=2; local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd); return end
            local d=(POS.R1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoRightPhase==2 then
            local tgt=Vector3.new(POS.R2.X,root.Position.Y,POS.R2.Z); if (tgt-root.Position).Magnitude<1 then hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero; State.autoRightEnabled=false; if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end; State.autoRightPhase=1; if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end; faceNorth(); return end
            local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
stopAutoRight=function()
    if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end; State.autoRightPhase=1
    local c=LP.Character; if c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
    if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
end

-- ============================================================
-- ANTI RAGDOLL
-- ============================================================
startAntiRagdoll=function()
    if Conns.antiRag then return end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        if not State.antiRagdollEnabled then return end
        local c=LP.Character; if not c then return end
        local hum2=c:FindFirstChildOfClass("Humanoid"); local root=c:FindFirstChild("HumanoidRootPart")
        if not hum2 or not root then return end; if hum2.Health<=0 then return end
        local st=hum2:GetState(); if st==Enum.HumanoidStateType.Dead then return end
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            pcall(function() workspace.CurrentCamera.CameraSubject=hum2 end)
            pcall(function() local PM=LP.PlayerScripts:FindFirstChild("PlayerModule"); if PM then local CM=require(PM:FindFirstChild("ControlModule")); if CM then CM:Enable() end end end)
            root.Velocity=Vector3.new(0,0,0); root.RotVelocity=Vector3.new(0,0,0)
        end
        for _,obj in ipairs(c:GetDescendants()) do pcall(function() if obj:IsA("Motor6D") and obj.Enabled==false then obj.Enabled=true end end) end
    end)
end
stopAntiRagdoll=function() if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end end

-- ============================================================
-- UNWALK
-- ============================================================
local unwalkAnimateRef=nil
local function startUnwalk()
    local c=LP.Character; if not c then return end
    local hum2=c:FindFirstChildOfClass("Humanoid")
    if hum2 then pcall(function() for _,track in ipairs(hum2:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    local animCtrl=c:FindFirstChildOfClass("AnimationController")
    if animCtrl then pcall(function() for _,track in ipairs(animCtrl:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    local anim=c:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then anim.Disabled=true; unwalkAnimateRef=anim end
    if Conns.unwalk then Conns.unwalk:Disconnect() end
    Conns.unwalk=RunService.Heartbeat:Connect(function()
        if not State.unwalkEnabled then return end
        local c2=LP.Character; if not c2 then return end
        local hum3=c2:FindFirstChildOfClass("Humanoid")
        if hum3 then pcall(function() for _,track in ipairs(hum3:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    end)
end
local function stopUnwalk()
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    local c=LP.Character
    if c and unwalkAnimateRef and unwalkAnimateRef.Parent==c then unwalkAnimateRef.Disabled=false end
    unwalkAnimateRef=nil
end

-- ============================================================
-- FPS BOOST
-- ============================================================
applyFPSBoost=function()
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
        local L=game:GetService("Lighting")
        for _,v in pairs(L:GetDescendants()) do pcall(function() if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end end) end
        pcall(function() sethiddenproperty(L,"Technology",Enum.Technology.Legacy) end)
        L.GlobalShadows=false; L.FogEnd=9e9; L.Brightness=0
        local ter=workspace:FindFirstChildOfClass("Terrain")
        if ter then pcall(function() sethiddenproperty(ter,"Decoration",false) end); ter.WaterReflectance=0; ter.WaterTransparency=0.7; ter.WaterWaveSize=0; ter.WaterWaveSpeed=0 end
    end)
    workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(pO,v) end end)
end

-- ============================================================
-- STEAL
-- ============================================================
local function isMyPlotByName(pn)
    local ct=tick(); if Steal.plotCache[pn] and (ct-(Steal.plotCacheTime[pn] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[pn] end
    local plots=workspace:FindFirstChild("Plots"); if not plots then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local plot=plots:FindFirstChild(pn); if not plot then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local sign=plot:FindFirstChild("PlotSign"); if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then local r=yb.Enabled==true; Steal.plotCache[pn]=r; Steal.plotCacheTime[pn]=ct; return r end end
    Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false
end
local function findNearestPrompt()
    local c=LP.Character; if not c then return nil end; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local ct=tick(); if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then local np,nd=nil,math.huge; for _,data in ipairs(Steal.cachedPrompts) do if data.spawn then local dist=(data.spawn.Position-root.Position).Magnitude; if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist end end end; if np then return np end end
    Steal.cachedPrompts={}; Steal.promptCacheTime=ct; local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end; local np,nd=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do if isMyPlotByName(plot.Name) then continue end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do pcall(function() local base=pod:FindFirstChild("Base"); local sp=base and base:FindFirstChild("Spawn"); if sp then local att=sp:FindFirstChild("PromptAttachment"); if att then for _,child in ipairs(att:GetChildren()) do if child:IsA("ProximityPrompt") then local dist=(sp.Position-root.Position).Magnitude; table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp}); if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist end; break end end end end end) end
    end; return np
end
local function executeSteal(prompt)
    local ct=tick(); if ct-State.lastStealTick<STEAL_COOLDOWN then return end; if State.isStealing then return end
    if not Steal.Data[prompt] then Steal.Data[prompt]={hold={},trigger={},ready=true}; pcall(function() if getconnections then for _,c2 in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c2.Function then table.insert(Steal.Data[prompt].hold,c2.Function) end end; for _,c2 in ipairs(getconnections(prompt.Triggered)) do if c2.Function then table.insert(Steal.Data[prompt].trigger,c2.Function) end end else Steal.Data[prompt].useFallback=true end end) end
    local data=Steal.Data[prompt]; if not data.ready then return end; data.ready=false; State.isStealing=true; State.stealStartTime=ct; State.lastStealTick=ct
    if Conns.progress then Conns.progress:Disconnect() end
    Conns.progress=RunService.Heartbeat:Connect(function() if not State.isStealing then Conns.progress:Disconnect(); return end; local prog=math.clamp((tick()-State.stealStartTime)/Steal.StealDuration,0,1); progressFill.Size=UDim2.new(prog,0,1,0); progressPct.Text=math.floor(prog*100).."%" end)
    task.spawn(function()
        local ok=false; pcall(function() if not data.useFallback then for _,fn in ipairs(data.hold) do task.spawn(fn) end; task.wait(Steal.StealDuration); for _,fn in ipairs(data.trigger) do task.spawn(fn) end; ok=true end end)
        if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt); ok=true end) end
        if not ok then pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end) end
        task.wait(Steal.StealDuration*0.3); if Conns.progress then Conns.progress:Disconnect() end; resetProgressBar(); task.wait(0.05); data.ready=true; State.isStealing=false
    end)
end
startAutoSteal=function()
    if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function() if not Steal.AutoStealEnabled or State.isStealing then return end; local p=findNearestPrompt(); if p then executeSteal(p) end end)
end
stopAutoSteal=function()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
    State.isStealing=false; State.lastStealTick=0; Steal.plotCache={}; Steal.plotCacheTime={}; Steal.cachedPrompts={}; resetProgressBar()
end

-- ============================================================
-- SAVE CONFIG  (keybinds + UI — separate from presets)
-- ============================================================
saveConfig = function()
    local cfg = {
        normalSpeed   = State.normalSpeed,
        carrySpeed    = State.carrySpeed,
        laggerSpeed   = State.laggerSpeed,
        stealRadius   = Steal.StealRadius,
        stealDuration = Steal.StealDuration,
        uiScale       = uiScaleObj and uiScaleObj.Scale or 1.0,
        stackButtonsHidden = State.stackButtonsHidden,
        -- keybinds saved by name so they survive restarts
        speedKey     = Keys.speed.Name,
        autoLeftKey  = Keys.autoLeft.Name,
        autoRightKey = Keys.autoRight.Name,
        guiHideKey   = Keys.guiHide.Name,
        dropKey      = Keys.drop.Name,
        laggerKey    = Keys.lagger.Name,
        tpDownKey    = Keys.tpDown.Name,
        aimbotKey    = Keys.aimbot.Name,
        -- toggle states
        infJump          = State.infJumpEnabled,
        antiRagdoll      = State.antiRagdollEnabled,
        fpsBoost         = State.fpsBoostEnabled,
        medusaCounter    = State.medusaCounterEnabled,
        batCounter       = State.batCounterEnabled,
        autoStealEnabled = Steal.AutoStealEnabled,
    }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then pcall(function() _writefile(CONFIG_FILE, encoded) end) end
end

-- ============================================================
-- LOAD CONFIG  (reads keybinds + UI state)
-- ============================================================
loadConfig = function()
    local hasFile = false
    pcall(function() hasFile = _isfile(CONFIG_FILE) end)
    -- fallback to old filenames
    if not hasFile then pcall(function() hasFile = _isfile("VyseAsireConfig.json") end) end
    if not hasFile then return end

    local raw
    local ok = pcall(function() raw = _readfile(CONFIG_FILE) end)
    if not ok or not raw then pcall(function() raw = _readfile("VyseAsireConfig.json") end) end
    if not raw then return end

    local cfg; local ok2 = pcall(function() cfg = HttpService:JSONDecode(raw) end)
    if not ok2 or not cfg then return end

    -- Speeds
    if cfg.normalSpeed then State.normalSpeed = cfg.normalSpeed; if normalBox then normalBox.Text = tostring(cfg.normalSpeed) end end
    if cfg.carrySpeed  then State.carrySpeed  = cfg.carrySpeed;  if carryBox  then carryBox.Text  = tostring(cfg.carrySpeed)  end end
    if cfg.laggerSpeed then State.laggerSpeed = cfg.laggerSpeed; if laggerBox then laggerBox.Text = tostring(cfg.laggerSpeed) end end

    -- Steal
    if cfg.stealRadius   then Steal.StealRadius   = cfg.stealRadius   end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration end

    -- UI
    if cfg.uiScale and uiScaleObj then
        uiScaleObj.Scale = cfg.uiScale
        if uiScaleBox then uiScaleBox.Text = tostring(cfg.uiScale) end
    end
    if cfg.stackButtonsHidden then
        applyStackButtonsVisible(false)
        if setHideButtonsToggle then setHideButtonsToggle(true) end
    end

    -- Keybinds — restore into Keys table AND update button labels
    local function tryKey(field, keyTarget)
        if cfg[field] and Enum.KeyCode[cfg[field]] then
            local kc = Enum.KeyCode[cfg[field]]
            Keys[keyTarget] = kc
            if keybindBtnRefs[keyTarget] then
                keybindBtnRefs[keyTarget].Text = getKeyDisplayName(kc)
            end
        end
    end
    tryKey("speedKey",    "speed")
    tryKey("autoLeftKey", "autoLeft")
    tryKey("autoRightKey","autoRight")
    tryKey("guiHideKey",  "guiHide")
    tryKey("dropKey",     "drop")
    tryKey("laggerKey",   "lagger")
    tryKey("tpDownKey",   "tpDown")
    tryKey("aimbotKey",   "aimbot")

    -- Toggles
    if cfg.autoStealEnabled then Steal.AutoStealEnabled = true; if setInstaGrab     then setInstaGrab(true)     end; pcall(startAutoSteal)  end
    if cfg.infJump          then State.infJumpEnabled = true;   if setInfJump       then setInfJump(true)       end end
    if cfg.antiRagdoll      then State.antiRagdollEnabled = true; if setAntiRag     then setAntiRag(true)       end; startAntiRagdoll()    end
    if cfg.fpsBoost         then State.fpsBoostEnabled = true;  if setFps           then setFps(true)           end; applyFPSBoost()       end
    if cfg.medusaCounter    then State.medusaCounterEnabled = true; if setMedusaCounter then setMedusaCounter(true) end; setupMedusaCounter(LP.Character) end
    if cfg.batCounter       then State.batCounterEnabled = true; if setBatCounter   then setBatCounter(true)    end; startBatCounter()     end
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function setupChar(char)
    task.wait(0.1)
    h=char:WaitForChild("Humanoid",5)
    hrp=char:WaitForChild("HumanoidRootPart",5)
    if not h or not hrp then return end

    local head=char:FindFirstChild("Head")
    if head then
        local oldBB=head:FindFirstChild("AsireHubBB"); if oldBB then oldBB:Destroy() end

        local bb=Instance.new("BillboardGui", head)
        bb.Name="AsireHubBB"
        bb.Size=UDim2.new(0, 160, 0, 52)
        bb.StudsOffset=Vector3.new(0, 3, 0)
        bb.AlwaysOnTop=true

        local speedBillLbl=Instance.new("TextLabel", bb)
        speedBillLbl.Name="SpeedBillLbl"
        speedBillLbl.Size=UDim2.new(1, 0, 0, 24)
        speedBillLbl.Position=UDim2.new(0, 0, 0, 0)
        speedBillLbl.BackgroundTransparency=1
        speedBillLbl.Text="0.0"
        speedBillLbl.TextColor3=Color3.fromRGB(210, 210, 210)
        speedBillLbl.Font=Enum.Font.GothamBlack
        speedBillLbl.TextScaled=true
        speedBillLbl.TextStrokeTransparency=0.1
        speedBillLbl.TextStrokeColor3=Color3.new(0, 0, 0)

        local lbl2=Instance.new("TextLabel", bb)
        lbl2.Size=UDim2.new(1, 0, 0, 24)
        lbl2.Position=UDim2.new(0, 0, 0, 28)
        lbl2.BackgroundTransparency=1
        lbl2.Text=""
        lbl2.TextColor3=Color3.fromRGB(160, 160, 160)
        lbl2.Font=Enum.Font.GothamBold
        lbl2.TextScaled=true
        lbl2.TextStrokeTransparency=0.1
        lbl2.TextStrokeColor3=Color3.new(0, 0, 0)
    end

    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end; unwalkAnimateRef=nil
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
            for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if not State.infJumpEnabled then return end
    local c=LP.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart")
    if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
end)

RunService.RenderStepped:Connect(function()
    if not (h and hrp) then return end; if State._tpInProgress then return end

    if not State.batAimbotToggled and not State.autoLeftEnabled and not State.autoRightEnabled then
        local md=h.MoveDirection
        local spd
        if State.laggerEnabled then
            spd = State.laggerSpeed
        elseif State.speedToggled then
            spd = State.carrySpeed
        else
            spd = State.normalSpeed
        end
        if md.Magnitude>0 then State.lastMoveDir=md; hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
            local anyHeld=false; for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
            if anyHeld then hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd) end
        end
    end

    pcall(function()
        local head2 = LP.Character and LP.Character:FindFirstChild("Head")
        if head2 then
            local bb2 = head2:FindFirstChild("AsireHubBB")
            local sl = bb2 and bb2:FindFirstChild("SpeedBillLbl")
            if sl then
                local hspd = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
                sl.Text = string.format("%.1f", hspd)
            end
        end
    end)
end)

-- ============================================================
-- INPUT
-- ============================================================
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    local isKb=inp.UserInputType==Enum.UserInputType.Keyboard
    local isGp=inp.UserInputType==Enum.UserInputType.Gamepad1 or inp.UserInputType==Enum.UserInputType.Gamepad2 or inp.UserInputType==Enum.UserInputType.Gamepad3 or inp.UserInputType==Enum.UserInputType.Gamepad4
    if not isKb and not isGp then return end
    local kc=inp.KeyCode; if kc==Enum.KeyCode.Unknown then return end

    if kc==Keys.speed then
        State.speedToggled=not State.speedToggled
        if carryModeToggle then carryModeToggle(State.speedToggled) end
        if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        if modeDisplayLbl then modeDisplayLbl.Text = State.laggerEnabled and "Lagger" or (State.speedToggled and "Carry" or "Normal") end
    elseif kc==Keys.autoLeft then
        State.autoLeftEnabled=not State.autoLeftEnabled
        if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
        if State.autoLeftEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
        if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
    elseif kc==Keys.autoRight then
        State.autoRightEnabled=not State.autoRightEnabled
        if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end
        if State.autoRightEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
        if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
    elseif kc==Keys.drop then
        if not State.dropEnabled then runDropBrainrot() end
    elseif kc==Keys.lagger then
        State.laggerEnabled = not State.laggerEnabled
        if laggerModeToggle then laggerModeToggle(State.laggerEnabled) end
        if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerEnabled) end
        if State.laggerEnabled then
            State._prevCarry = State.carrySpeed; State._prevSpeed = State.speedToggled; State.speedToggled = false
            if carryModeToggle then carryModeToggle(false) end
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
        else
            State.carrySpeed = State._prevCarry or 28.5; State.speedToggled = State._prevSpeed or false
            if carryBox then carryBox.Text = tostring(State.carrySpeed) end
            if carryModeToggle then carryModeToggle(State.speedToggled) end
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        end
        if modeDisplayLbl then modeDisplayLbl.Text = State.laggerEnabled and "Lagger" or (State.speedToggled and "Carry" or "Normal") end
    elseif kc==Keys.tpDown then
        doTpDown()
    elseif kc==Keys.aimbot then
        State.batAimbotToggled=not State.batAimbotToggled
        if State.batAimbotToggled then
            if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
            if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
            pcall(startBatAimbot)
        else stopBatAimbot() end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
    elseif kc==Keys.guiHide then
        if isKb then State.guiVisible=not State.guiVisible; mainOuter.Visible=State.guiVisible end
    end
end)

-- ============================================================
-- INIT
-- ============================================================
loadPresetsFile()
rebuildPresetList()

-- Load config first (restores keybinds + toggles)
loadConfig()

-- Auto-load last used preset (speeds/toggles only, never touches keybinds)
task.spawn(function()
    task.wait(0.3)
    local lastPresetName = loadLastPresetName()
    if lastPresetName and lastPresetName ~= "" then
        for _, preset in ipairs(Presets) do
            if preset.name == lastPresetName then
                applyPreset(preset.data)
                print("[AsireHub v5.2] Auto-loaded last preset: " .. lastPresetName)
                break
            end
        end
    end
end)

-- Write config once on startup so the file always exists
task.delay(1, function() pcall(saveConfig) end)

print("[AsireHub v5.2] Loaded")
