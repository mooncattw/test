local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local CONFIG_FILE = "MoonHubConfig.json"
local NEON_COLOR = Color3.fromRGB(0, 200, 255)   -- Daha parlak mavi

-- Sadece Üst Bardandan Sürüklenebilir
local function makeDraggable(topBar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

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

    -- Ana Frame
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -150, 0.5, -130)
    Main.Size = UDim2.new(0, 300, 0, 240)
    Main.Active = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 18)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = NEON_COLOR
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.35
    MainStroke.Parent = Main

    -- Top Bar (Sadece buradan sürüklenecek)
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 45)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 18)
    TopCorner.Parent = TopBar

    -- Gradient efekt için
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 25))
    }
    Gradient.Parent = TopBar

    Title.Name = "Title"
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Font = Enum.Font.GothamBlack
    Title.Text = "Moon Hub"
    Title.TextColor3 = NEON_COLOR
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Close Button
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = TopBar
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -12)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
    CloseBtn.TextSize = 20

    -- Butonlar
    local function createStyledButton(name, text, yPos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Parent = Main
        btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
        btn.Position = UDim2.new(0.5, -125, 0, yPos)
        btn.Size = UDim2.new(0, 250, 0, 48)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 15

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = NEON_COLOR
        stroke.Thickness = 1.2
        stroke.Transparency = 0.6
        stroke.Parent = btn

        return btn
    end

    AntiBatBtn = createStyledButton("AntiBatBtn", "Anti-Bat : OFF", 60)
    InfJumpBtn = createStyledButton("InfJumpBtn", "Inf Jump : OFF", 118)

    -- Keybind
    KeybindLabel.Name = "KeybindLabel"
    KeybindLabel.Parent = Main
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Position = UDim2.new(0, 25, 0, 175)
    KeybindLabel.Size = UDim2.new(0.5, 0, 0, 30)
    KeybindLabel.Font = Enum.Font.Gotham
    KeybindLabel.Text = "Toggle Keybind :"
    KeybindLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
    KeybindLabel.TextSize = 13
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left

    KeybindBtn.Name = "KeybindBtn"
    KeybindBtn.Parent = Main
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
    KeybindBtn.Position = UDim2.new(1, -95, 0, 175)
    KeybindBtn.Size = UDim2.new(0, 75, 0, 30)
    KeybindBtn.Font = Enum.Font.GothamBold
    KeybindBtn.Text = "F1"
    KeybindBtn.TextColor3 = NEON_COLOR
    KeybindBtn.TextSize = 14

    local kbCorner = Instance.new("UICorner")
    kbCorner.CornerRadius = UDim.new(0, 10)
    kbCorner.Parent = KeybindBtn

    -- Status
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = Main
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 1, -25)
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Moon Hub • Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(130, 200, 255)
    StatusLabel.TextSize = 12

    return {
        ScreenGui = ScreenGui,
        Main = Main,
        TopBar = TopBar,
        AntiBatBtn = AntiBatBtn,
        InfJumpBtn = InfJumpBtn,
        KeybindBtn = KeybindBtn,
        StatusLabel = StatusLabel,
        CloseBtn = CloseBtn
    }
end

-- Config ve UIManager (önceki kodla aynı, sadece gerekli kısımlar)
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

local UIManager = {}
function UIManager:new(guiElements)
    local obj = { elements = guiElements, antiBatOn = false, infJumpOn = false, listeningForKey = false }

    function obj:setNeon(btn, on)
        if on then
            btn.TextColor3 = NEON_COLOR
            btn.BackgroundColor3 = Color3.fromRGB(25, 40, 70)
        else
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
        end
    end

    function obj:toggleAntiBat()
        self.antiBatOn = not self.antiBatOn
        self.elements.AntiBatBtn.Text = "Anti-Bat : " .. (self.antiBatOn and "ON" or "OFF")
        self:setNeon(self.elements.AntiBatBtn, self.antiBatOn)
        -- Anti-Bat ve Anti-Ragdoll logic buraya eklenecek
    end

    function obj:toggleInfJump()
        self.infJumpOn = not self.infJumpOn
        self.elements.InfJumpBtn.Text = "Inf Jump : " .. (self.infJumpOn and "ON" or "OFF")
        self:setNeon(self.elements.InfJumpBtn, self.infJumpOn)
    end

    return obj
end

local function initialize()
    local gui = createGUI()
    
    -- Sadece TopBar'dan sürüklenebilir
    makeDraggable(gui.TopBar, gui.Main)

    local config = ConfigManager.load()
    gui.KeybindBtn.Text = config.keybind

    local uiManager = UIManager:new(gui)

    gui.AntiBatBtn.MouseButton1Click:Connect(function() uiManager:toggleAntiBat() end)
    gui.InfJumpBtn.MouseButton1Click:Connect(function() uiManager:toggleInfJump() end)
    gui.CloseBtn.MouseButton1Click:Connect(function() gui.ScreenGui:Destroy() end)

    print("Moon Hub - Yeni Tasarım Yüklendi")
end

initialize()
