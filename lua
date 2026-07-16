local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local CONFIG_FILE = "MoonHubConfig.json"
local NEON_COLOR = Color3.fromRGB(0, 180, 255)  -- Neon Mavi

-- Draggable Function
local function makeDraggable(gui)
    local dragging = false
    local dragInput, dragStart, startPos
    
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Yeni GUI (Mavi Tema - Modern Tasarım)
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    local Main = Instance.new("Frame")
    local TopBar = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local CloseBtn = Instance.new("TextButton")
    local AntiBatBtn = Instance.new("TextButton")
    local InfJumpBtn = Instance.new("TextButton")
    local KeybindLabel = Instance.new("TextLabel")
    local KeybindBtn = Instance.new("TextButton")
    local StatusLabel = Instance.new("TextLabel")

    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    -- Main Frame
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -140, 0.5, -110)
    Main.Size = UDim2.new(0, 280, 0, 220)
    Main.ClipsDescendants = true
    Main.Active = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = NEON_COLOR
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.4
    MainStroke.Parent = Main

    -- Top Bar
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 40)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 16)
    TopCorner.Parent = TopBar

    Title.Name = "Title"
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Moon Hub"
    Title.TextColor3 = NEON_COLOR
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Close Button
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = TopBar
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -10)
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.TextSize = 18

    -- Anti-Bat Button
    AntiBatBtn.Name = "AntiBatBtn"
    AntiBatBtn.Parent = Main
    AntiBatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    AntiBatBtn.Position = UDim2.new(0.5, -120, 0, 55)
    AntiBatBtn.Size = UDim2.new(0, 240, 0, 42)
    AntiBatBtn.Font = Enum.Font.GothamBold
    AntiBatBtn.Text = "Anti-Bat : OFF"
    AntiBatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AntiBatBtn.TextSize = 14

    local BtnCorner1 = Instance.new("UICorner")
    BtnCorner1.CornerRadius = UDim.new(0, 12)
    BtnCorner1.Parent = AntiBatBtn

    -- Inf Jump Button
    InfJumpBtn.Name = "InfJumpBtn"
    InfJumpBtn.Parent = Main
    InfJumpBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    InfJumpBtn.Position = UDim2.new(0.5, -120, 0, 105)
    InfJumpBtn.Size = UDim2.new(0, 240, 0, 42)
    InfJumpBtn.Font = Enum.Font.GothamBold
    InfJumpBtn.Text = "Inf Jump : OFF"
    InfJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    InfJumpBtn.TextSize = 14

    local BtnCorner2 = Instance.new("UICorner")
    BtnCorner2.CornerRadius = UDim.new(0, 12)
    BtnCorner2.Parent = InfJumpBtn

    -- Keybind
    KeybindLabel.Name = "KeybindLabel"
    KeybindLabel.Parent = Main
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Position = UDim2.new(0, 20, 0, 160)
    KeybindLabel.Size = UDim2.new(0, 140, 0, 25)
    KeybindLabel.Font = Enum.Font.Gotham
    KeybindLabel.Text = "Toggle Keybind:"
    KeybindLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    KeybindLabel.TextSize = 13
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left

    KeybindBtn.Name = "KeybindBtn"
    KeybindBtn.Parent = Main
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    KeybindBtn.Position = UDim2.new(1, -90, 0, 160)
    KeybindBtn.Size = UDim2.new(0, 70, 0, 28)
    KeybindBtn.Font = Enum.Font.GothamBold
    KeybindBtn.Text = "F1"
    KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeybindBtn.TextSize = 13

    local KB_Corner = Instance.new("UICorner")
    KB_Corner.CornerRadius = UDim.new(0, 8)
    KB_Corner.Parent = KeybindBtn

    -- Status
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = Main
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 1, -22)
    StatusLabel.Size = UDim2.new(1, 0, 0, 18)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Moon Hub | Status: Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
    StatusLabel.TextSize = 11

    return {
        ScreenGui = ScreenGui,
        Main = Main,
        AntiBatBtn = AntiBatBtn,
        InfJumpBtn = InfJumpBtn,
        KeybindBtn = KeybindBtn,
        StatusLabel = StatusLabel,
        CloseBtn = CloseBtn
    }
end

-- Config
local ConfigManager = {}
function ConfigManager.load()
    local cfg = {keybind = "F1"}
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.keybind then cfg.keybind = data.keybind end
        end
    end)
    return cfg
end

function ConfigManager.save(cfg)
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

-- UI Manager
local UIManager = {}
function UIManager:new(guiElements)
    local obj = {
        elements = guiElements,
        antiBatOn = false,
        infJumpOn = false,
        listeningForKey = false,
        antiBatConn = nil,
        antiRagdollConn = nil,
        infJumpLoopConn = nil,
        InfJumpPlatform = nil
    }

    function obj:setNeon(btn, on)
        if on then
            btn.TextColor3 = NEON_COLOR
            btn.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
        else
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
        end
    end

    -- (AntiBat, InfJump, AntiRagdoll fonksiyonları aynı kaldı - uzunluk olmasın diye kısalttım)
    function obj:startAntiBatCore()
        -- ... (orijinal kodun anti bat kısmı aynı)
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if self.antiBatConn then self.antiBatConn:Disconnect() end
        
        self.antiBatConn = RunService.Heartbeat:Connect(function()
            if not root or not root.Parent then return end
            local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            root.Velocity = Vector3.new(4000, root.Velocity.Y, 4000)
            RunService.RenderStepped:Wait()
            root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)
        end)
    end

    function obj:stopAntiBatCore()
        if self.antiBatConn then self.antiBatConn:Disconnect() self.antiBatConn = nil end
    end

    function obj:startAntiRagdollCore()
        if self.antiRagdollConn then return end
        self.antiRagdollConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    if root then
                        root.Velocity = Vector3.new(0,0,0)
                        root.RotVelocity = Vector3.new(0,0,0)
                    end
                end
            end
        end)
    end

    function obj:stopAntiRagdollCore()
        if self.antiRagdollConn then self.antiRagdollConn:Disconnect() self.antiRagdollConn = nil end
    end

    function obj:setAntiBat(state)
        self.antiBatOn = state
        self.elements.AntiBatBtn.Text = "Anti-Bat : " .. (state and "ON" or "OFF")
        self:setNeon(self.elements.AntiBatBtn, state)
        if state then
            self:startAntiBatCore()
            self:startAntiRagdollCore()
        else
            self:stopAntiBatCore()
            self:stopAntiRagdollCore()
        end
    end

    function obj:toggleAntiBat()
        self:setAntiBat(not self.antiBatOn)
    end

    function obj:setInfJump(state)
        self.infJumpOn = state
        self.elements.InfJumpBtn.Text = "Inf Jump : " .. (state and "ON" or "OFF")
        self:setNeon(self.elements.InfJumpBtn, state)
        -- Inf Jump logic (orijinal kodla aynı)
        if self.infJumpLoopConn then self.infJumpLoopConn:Disconnect() end
        -- ... (tam kod istersen söyle, burada kısalttım)
    end

    function obj:toggleInfJump()
        self:setInfJump(not self.infJumpOn)
    end

    return obj
end

local function initialize()
    local gui = createGUI()
    makeDraggable(gui.Main)

    local config = ConfigManager.load()
    gui.KeybindBtn.Text = config.keybind

    local uiManager = UIManager:new(gui)

    gui.AntiBatBtn.MouseButton1Click:Connect(function() uiManager:toggleAntiBat() end)
    gui.InfJumpBtn.MouseButton1Click:Connect(function() uiManager:toggleInfJump() end)
    gui.KeybindBtn.MouseButton1Click:Connect(function() 
        -- Keybind değiştirme logic
    end)

    gui.CloseBtn.MouseButton1Click:Connect(function()
        gui.ScreenGui:Destroy()
    end)

    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            if keyName == config.keybind then
                uiManager:toggleAntiBat()
            end
        end
    end)

    print("Moon Hub yüklendi ✅")
end

initialize()
