local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- // PALETĂ CULORI
local PURPLE      = Color3.fromRGB(165, 55, 255)  
local PINK_SUB    = Color3.fromRGB(235, 90, 200)  
local LIGHT_GRAY  = Color3.fromRGB(150, 150, 160) 
local WHITE       = Color3.fromRGB(255, 255, 255) 
local DARK_BG     = Color3.fromRGB(10, 6, 14)     
local CARD_BG     = Color3.fromRGB(20, 12, 28)     
local STATUS_OFF  = Color3.fromRGB(220, 60, 90)   
local STATUS_ON   = Color3.fromRGB(60, 220, 120)  

-- // STATE
local State = {
    autoBatToggled = false,
    hittingCooldown = false,
    guiVisible = true,
    isMobileMode = false,
    uiLocked = false,
}

local Keys = {
    autoBat = Enum.KeyCode.X,
    guiHide = Enum.KeyCode.LeftControl,
}

local h, hrp = nil, nil
local kListening = false
local listeningConn = nil -- Salvează conexiunea pentru schimbarea tastei

-- // CONFIG
local function saveConfig()
    local cfg = { autoBatKey = Keys.autoBat.Name, isMobile = State.isMobileMode, uiLocked = State.uiLocked }
    pcall(function() writefile("EthernalAutoBatOnlyConfig.json", HttpService:JSONEncode(cfg)) end)
end

local function loadConfig()
    if isfile and isfile("EthernalAutoBatOnlyConfig.json") then
        local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("EthernalAutoBatOnlyConfig.json")) end)
        if ok and cfg then
            if cfg.autoBatKey and Enum.KeyCode[cfg.autoBatKey] then Keys.autoBat = Enum.KeyCode[cfg.autoBatKey] end
            if cfg.isMobile ~= nil then State.isMobileMode = cfg.isMobile end
            if cfg.uiLocked ~= nil then State.uiLocked = cfg.uiLocked end
        end
    end
end
loadConfig()

-- // CLEANUP
for _, name in pairs({"EthernalHub_AutoBat_Poza"}) do
    local old = game:GetService("CoreGui"):FindFirstChild(name) or LP:WaitForChild("PlayerGui"):FindFirstChild(name)
    if old then old:Destroy() end
end

-- // GUI SETUP
local gui = Instance.new("ScreenGui")
gui.Name = "EthernalHub_AutoBat_Poza"; gui.ResetOnSpawn = false; gui.DisplayOrder = 15
gui.IgnoreGuiInset = true; gui.Parent = LP:WaitForChild("PlayerGui")

local main = Instance.new("ImageLabel", gui)
main.Name = "Main"; main.Size = UDim2.new(0, 270, 0, 195); main.Position = UDim2.new(0.5, -135, 0.5, 45)
main.BackgroundTransparency = 1; main.BorderSizePixel = 0; main.Active = true; main.ClipsDescendants = true
main.Image = "rbxassetid://103472352491221" 
main.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local tint = Instance.new("Frame", main)
tint.Size = UDim2.new(1, 0, 1, 0); tint.BackgroundColor3 = DARK_BG; tint.BackgroundTransparency = 0.85; tint.ZIndex = 1

local mainStroke = Instance.new("UIStroke", main); mainStroke.Color = PURPLE; mainStroke.Thickness = 1.5

-- Dragging logic
do
    local dragging, dragInput, dragStart, mainStart = false, nil, nil, nil
    main.InputBegan:Connect(function(inp)
        if State.uiLocked and State.isMobileMode then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; mainStart = main.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    main.InputChanged:Connect(function(inp) 
        if State.uiLocked and State.isMobileMode then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end 
    end)
    UIS.InputChanged:Connect(function(inp)
        if State.uiLocked and State.isMobileMode then dragging = false; return end
        if inp == dragInput and dragging then
            local dx = inp.Position.X - dragStart.X; local dy = inp.Position.Y - dragStart.Y
            main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + dx, mainStart.Y.Scale, mainStart.Y.Offset + dy)
        end
    end)
end

-- // HEADER
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 42); header.BackgroundTransparency = 1; header.ZIndex = 2

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0, 90, 1, 0); title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1; title.Text = "ETHERNAL"; title.TextColor3 = PURPLE 
title.Font = Enum.Font.GothamBlack; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 3

local subTitle = Instance.new("TextLabel", header)
subTitle.Size = UDim2.new(0, 70, 1, 0); subTitle.Position = UDim2.new(0, 94, 0, 0)
subTitle.BackgroundTransparency = 1; subTitle.Text = "auto bat"; subTitle.TextColor3 = PINK_SUB
subTitle.Font = Enum.Font.Gotham; subTitle.TextSize = 11; subTitle.TextXAlignment = Enum.TextXAlignment.Left; subTitle.ZIndex = 3

-- BUTON SCHIMBARE MOD
local modeBtn = Instance.new("TextButton", header)
modeBtn.Size = UDim2.new(0, 52, 0, 18); modeBtn.Position = UDim2.new(1, -66, 0.5, -9)
modeBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 45); modeBtn.Text = State.isMobileMode and "MOBILE" or "PC"
modeBtn.TextColor3 = WHITE; modeBtn.Font = Enum.Font.GothamBold; modeBtn.TextSize = 9; modeBtn.ZIndex = 4
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 4)
local modeStroke = Instance.new("UIStroke", modeBtn); modeStroke.Color = PURPLE

-- BUTON LOCK UI
local lockBtn = Instance.new("TextButton", header)
lockBtn.Size = UDim2.new(0, 60, 0, 18); lockBtn.Position = UDim2.new(1, -132, 0.5, -9)
lockBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30); lockBtn.Text = State.uiLocked and "🔒 LOCKED" or "🔓 UNLOCK"
lockBtn.TextColor3 = State.uiLocked and STATUS_ON or LIGHT_GRAY
lockBtn.Font = Enum.Font.GothamBold; lockBtn.TextSize = 8; lockBtn.ZIndex = 4; lockBtn.Visible = false
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)
local lockStroke = Instance.new("UIStroke", lockBtn); lockStroke.Color = Color3.fromRGB(60, 40, 90)

local line = Instance.new("Frame", main)
line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 0, 42)
line.BackgroundColor3 = Color3.fromRGB(80, 50, 110); line.BorderSizePixel = 0; line.ZIndex = 2

-- // CONTENT CONTAINERS
local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -24, 1, -54); container.Position = UDim2.new(0, 12, 0, 48)
container.BackgroundTransparency = 1; container.ZIndex = 2

-- [ INTERFAȚA MOD PC ]
local pcCard = Instance.new("Frame", container)
pcCard.Size = UDim2.new(1, 0, 0, 80); pcCard.BackgroundColor3 = CARD_BG; pcCard.BackgroundTransparency = 0.3; pcCard.BorderSizePixel = 0
Instance.new("UICorner", pcCard).CornerRadius = UDim.new(0, 8)
local cardStroke = Instance.new("UIStroke", pcCard); cardStroke.Color = Color3.fromRGB(80, 50, 110)

local autoBatLbl = Instance.new("TextLabel", pcCard)
autoBatLbl.Size = UDim2.new(0, 100, 0, 22); autoBatLbl.Position = UDim2.new(0, 12, 0, 12)
autoBatLbl.BackgroundTransparency = 1; autoBatLbl.Text = "Auto Bat"; autoBatLbl.TextColor3 = WHITE
autoBatLbl.Font = Enum.Font.GothamBold; autoBatLbl.TextSize = 13; autoBatLbl.TextXAlignment = Enum.TextXAlignment.Left

local statusLbl = Instance.new("TextLabel", pcCard)
statusLbl.Size = UDim2.new(0, 100, 0, 16); statusLbl.Position = UDim2.new(0, 12, 0, 32)
statusLbl.BackgroundTransparency = 1; statusLbl.Text = "STATUS: OFF"; statusLbl.TextColor3 = STATUS_OFF
statusLbl.Font = Enum.Font.GothamBlack; statusLbl.TextSize = 9; statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local keyPrefix = Instance.new("TextLabel", pcCard)
keyPrefix.Size = UDim2.new(0, 30, 0, 16); keyPrefix.Position = UDim2.new(0, 12, 0, 52)
keyPrefix.BackgroundTransparency = 1; keyPrefix.Text = "KEY:"; keyPrefix.TextColor3 = LIGHT_GRAY
keyPrefix.Font = Enum.Font.GothamBold; keyPrefix.TextSize = 9; keyPrefix.TextXAlignment = Enum.TextXAlignment.Left

local keyBtn = Instance.new("TextButton", pcCard)
keyBtn.Size = UDim2.new(0, 45, 0, 16); keyBtn.Position = UDim2.new(0, 42, 0, 52)
keyBtn.BackgroundColor3 = Color3.fromRGB(12, 8, 16); keyBtn.BorderSizePixel = 0; keyBtn.Text = Keys.autoBat.Name
keyBtn.TextColor3 = PURPLE; keyBtn.Font = Enum.Font.GothamBlack; keyBtn.TextSize = 10
Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)

local pillBg = Instance.new("Frame", pcCard)
pillBg.Size = UDim2.new(0, 38, 0, 20); pillBg.Position = UDim2.new(1, -50, 0.5, -10)
pillBg.BackgroundColor3 = Color3.fromRGB(30, 20, 40); pillBg.BorderSizePixel = 0
Instance.new("UICorner", pillBg).CornerRadius = UDim.new(0, 10)
local pillStroke = Instance.new("UIStroke", pillBg); pillStroke.Color = Color3.fromRGB(80, 50, 110)

local dot = Instance.new("Frame", pillBg)
dot.Size = UDim2.new(0, 14, 0, 14); dot.Position = UDim2.new(0, 3, 0.5, -7)
dot.BackgroundColor3 = Color3.fromRGB(90, 60, 120); dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 7)

local toggleClk = Instance.new("TextButton", pcCard)
toggleClk.Size = UDim2.new(1, -60, 1, 0); toggleClk.BackgroundTransparency = 1; toggleClk.Text = ""


-- [ INTERFAȚA MOD MOBILE - BUTON MARE ]
local mobileCard = Instance.new("Frame", container)
mobileCard.Size = UDim2.new(1, 0, 0, 80); mobileCard.BackgroundTransparency = 1; mobileCard.BorderSizePixel = 0
mobileCard.Visible = false

local bigMobileBtn = Instance.new("TextButton", mobileCard)
bigMobileBtn.Size = UDim2.new(1, 0, 1, 0); bigMobileBtn.Position = UDim2.new(0, 0, 0, 0)
bigMobileBtn.BackgroundColor3 = STATUS_OFF
bigMobileBtn.Text = "TAP TO ACTIVATE"
bigMobileBtn.TextColor3 = WHITE
bigMobileBtn.Font = Enum.Font.GothamBlack
bigMobileBtn.TextSize = 13 
Instance.new("UICorner", bigMobileBtn).CornerRadius = UDim.new(0, 8) 
local mobileBtnStroke = Instance.new("UIStroke", bigMobileBtn); mobileBtnStroke.Color = PURPLE; mobileBtnStroke.Thickness = 1.5


-- // DISCORD FOOTER ROW
local discordCard = Instance.new("Frame", container)
discordCard.Size = UDim2.new(1, 0, 0, 32); discordCard.Position = UDim2.new(0, 0, 0, 92)
discordCard.BackgroundColor3 = CARD_BG; discordCard.BackgroundTransparency = 0.3; discordCard.BorderSizePixel = 0
Instance.new("UICorner", discordCard).CornerRadius = UDim.new(0, 6)
local discStroke = Instance.new("UIStroke", discordCard); discStroke.Color = Color3.fromRGB(80, 50, 110)

local discLbl = Instance.new("TextLabel", discordCard)
discLbl.Size = UDim2.new(1, 0, 1, 0); discLbl.BackgroundTransparency = 1
discLbl.Text = "DISCORD.GG/ETHERNAL"; discLbl.TextColor3 = PURPLE
discLbl.Font = Enum.Font.GothamBlack; discLbl.TextSize = 10


-- // REFRESH VIEW FUNCTION
local function updateView()
    if State.isMobileMode then
        pcCard.Visible = false
        mobileCard.Visible = true
        lockBtn.Visible = true 
        modeBtn.Position = UDim2.new(1, -66, 0.5, -9)
        modeBtn.Text = "MOBILE"
        bigMobileBtn.BackgroundColor3 = State.autoBatToggled and STATUS_ON or STATUS_OFF
        bigMobileBtn.Text = State.autoBatToggled and "AUTO BAT: ON" or "TAP TO ACTIVATE"
    else
        pcCard.Visible = true
        mobileCard.Visible = false
        lockBtn.Visible = false 
        modeBtn.Position = UDim2.new(1, -66, 0.5, -9)
        modeBtn.Text = "PC"
        statusLbl.Text = State.autoBatToggled and "STATUS: ON" or "STATUS: OFF"
        statusLbl.TextColor3 = State.autoBatToggled and STATUS_ON or STATUS_OFF
        dot.Position = State.autoBatToggled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        dot.BackgroundColor3 = State.autoBatToggled and PURPLE or Color3.fromRGB(90, 60, 120)
    end
    
    lockBtn.Text = State.uiLocked and "🔒 LOCKED" or "🔓 UNLOCK"
    lockBtn.TextColor3 = State.uiLocked and STATUS_ON or LIGHT_GRAY
    lockStroke.Color = State.uiLocked and STATUS_ON or Color3.fromRGB(60, 40, 90)
end
updateView()

-- Switch mod tactil / PC
modeBtn.MouseButton1Click:Connect(function()
    State.isMobileMode = not State.isMobileMode
    saveConfig()
    updateView()
end)

-- Schimbare stare Lock UI
lockBtn.MouseButton1Click:Connect(function()
    State.uiLocked = not State.uiLocked
    saveConfig()
    updateView()
end)

-- // FIXED INTERACTION HANDLERS FOR PC KEYBIND
-- Funcție pentru a opri ascultarea tastelor
local function stopListening()
    if listeningConn then
        listeningConn:Disconnect()
        listeningConn = nil
    end
    kListening = false
    keyBtn.Text = Keys.autoBat.Name
    keyBtn.TextColor3 = PURPLE
end

-- Funcție pentru a începe ascultarea unei taste noi
local function startListeningForNewKey()
    if kListening then 
        stopListening()
        return 
    end
    
    kListening = true
    keyBtn.Text = "..."
    keyBtn.TextColor3 = WHITE
    
    -- Oprește orice conexiune existentă
    if listeningConn then
        listeningConn:Disconnect()
    end
    
    -- Ascultă pentru următoarea tastă apăsată
    listeningConn = UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode ~= Enum.KeyCode.Escape then
                Keys.autoBat = inp.KeyCode
                keyBtn.Text = inp.KeyCode.Name
                saveConfig()
            end
            -- Oprește ascultarea după ce s-a primit o tastă
            stopListening()
        end
    end)
end

keyBtn.MouseButton1Click:Connect(startListeningForNewKey)

-- Toggle PC click - verifică dacă NU suntem în modul de ascultare
toggleClk.MouseButton1Click:Connect(function()
    if kListening then return end -- Împiedică toggle-ul în timp ce schimbi tasta
    State.autoBatToggled = not State.autoBatToggled
    updateView()
end)

-- Toggle MOBILE click
bigMobileBtn.MouseButton1Click:Connect(function()
    State.autoBatToggled = not State.autoBatToggled
    updateView()
end)

-- // BAT AIMBOT LOGIC
local function getBat()
    local char = LP.Character; if not char then return nil end
    local tool = char:FindFirstChild("Bat"); if tool then return tool end
    local bp2 = LP:FindFirstChild("Backpack")
    if bp2 then tool = bp2:FindFirstChild("Bat"); if tool then tool.Parent = char; return tool end end
    return nil
end

local function tryHitBat()
    if State.hittingCooldown then return end; State.hittingCooldown = true
    pcall(function()
        local bat = getBat(); if bat then
            bat:Activate(); local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() State.hittingCooldown = false end)
end

local function getClosestPlayer()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then local d = (hrp.Position - tr.Position).Magnitude; if d < cd then cd = d; cp = p end end
        end
    end
    return cp, cd
end

local function setupChar(char)
    task.wait(0.1)
    h = char:WaitForChild("Humanoid", 5); hrp = char:WaitForChild("HumanoidRootPart", 5)
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

RunService.Heartbeat:Connect(function()
    if not (State.autoBatToggled and h and hrp) then return end
    local target, dist = getClosestPlayer()
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            if sethiddenproperty then sethiddenproperty(hrp, "PhysicsRepRootPart", tr) end
            local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
            if (hrp.Position - targetPos).Magnitude > 8 then hrp.CFrame = CFrame.new(targetPos) end
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
            tryHitBat()
        end
    end
end)

-- KEYBOARD INPUT HANDLER - FIXED
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        if inp.KeyCode == Keys.autoBat then
            if kListening then return end -- NU activa toggle-ul când schimbi tasta
            State.autoBatToggled = not State.autoBatToggled
            updateView()
        elseif inp.KeyCode == Keys.guiHide then
            State.guiVisible = not State.guiVisible
            main.Visible = State.guiVisible
        end
    end
end)

print("[ETHERNAL HUB] Auto Bat Fixed - Keybind change works without toggling auto bat!")
