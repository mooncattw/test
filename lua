local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

-- Global Ayarlar (Çalışması için)
getgenv().InfJump = false
getgenv().AntiBat = false

-- Animasyonlu Kenarlık Fonksiyonu
local function createAnimatedStroke(parent, thickness, speed)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = NEON_COLOR
    stroke.Parent = parent
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 255))
    }
    gradient.Parent = stroke
    
    task.spawn(function()
        local rot = 0
        while parent and parent.Parent do
            rot = (rot + (speed or 1)) % 360
            gradient.Rotation = rot
            task.wait()
        end
    end)
end

-- Sürükleme Fonksiyonu
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_NeonV3"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

-- Ana Pencere
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 200)
main.Position = UDim2.new(0.5, -130, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 25)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
createAnimatedStroke(main, 2.5, 1) -- Ana menü ışığı
makeDraggable(main) -- Sürükleme aktif

-- Başlık
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "MOON HUB"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = NEON_COLOR
title.Parent = main

local div = Instance.new("Frame")
div.Size = UDim2.new(0.7, 0, 0, 2)
div.Position = UDim2.new(0.15, 0, 0, 42)
div.BackgroundColor3 = NEON_COLOR
div.BorderSizePixel = 0
div.Parent = main

-- Toggle Sistemi (Butonların etrafı da ışıklı)
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 45)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
    row.Parent = main
    
    local corner = Instance.new("UICorner", row)
    corner.CornerRadius = UDim.new(0, 10)
    
    -- BUTON ETRAFINDAKİ HAREKETLİ IŞIK
    createAnimatedStroke(row, 1.5, 1.2) 
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 38, 0, 18)
    switchBg.Position = UDim2.new(1, -48, 0.5, -9)
    switchBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 9)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
    
    local active = false
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = not active
            local pos = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            local color = active and NEON_COLOR or Color3.fromRGB(40, 40, 60)
            
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = pos}):Play()
            TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            callback(active)
        end
    end)
end

-- ÖZELLİKLERİ ÇALIŞTIRAN KODLAR

-- 1. Anti-Bat (Sersemleme/Düşme Engelleme)
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AntiBat then
            pcall(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    -- Prison Life ve benzeri oyunlardaki stun durumlarını iptal eder
                    if hum.PlatformStand then hum.PlatformStand = false end
                    if hum:GetState() == Enum.HumanoidStateType.FallingDown or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end)
        end
    end
end)

-- 2. Infinite Jump (Sonsuz Zıplama)
UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState("Jumping")
        end
    end
end)

-- Menü Butonlarını Ekle
createToggle("Anti-Bat (No Stun)", 60, function(state)
    getgenv().AntiBat = state
end)

createToggle("Infinite Jump", 115, function(state)
    getgenv().InfJump = state
end)

print("Moon Hub: Neon V3 Yüklendi. Buton ışıkları ve özellikler aktif!")
