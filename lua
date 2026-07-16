local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

-- Global Ayarlar
getgenv().AntiBat = false
getgenv().InfJump = false

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

-- Animasyonlu Neon Kenarlık Fonksiyonu
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

-- GUI Oluşturma
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_Ultimate"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 200)
main.Position = UDim2.new(0.5, -130, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
createAnimatedStroke(main, 2.5, 1)
makeDraggable(main)

-- MOON HUB YAZI ŞERİDİ (EFEKTLİ)
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(0, 150, 0, 35)
titleContainer.Position = UDim2.new(0.5, -75, 0, 12)
titleContainer.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
titleContainer.Parent = main
Instance.new("UICorner", titleContainer).CornerRadius = UDim.new(0, 8)
createAnimatedStroke(titleContainer, 2, 1.5) -- Yazı etrafındaki şerit

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = titleContainer

-- ÖZELLİK KODLARI

-- 1. Anti Bat (Stun Boşaltma ve Ragdoll Engelleme)
RunService.Heartbeat:Connect(function()
    if getgenv().AntiBat then
        pcall(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                -- Titreşimli Velocity (Bayılmayı önler)
                local oldV = root.Velocity
                root.Velocity = Vector3.new(4000, oldV.Y, 4000)
                RunService.RenderStepped:Wait()
                root.Velocity = oldV
                
                -- Durum Kontrolü
                local s = hum:GetState()
                if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
end)

-- 2. Infinite Jump (FIXED: Hareket Kesilmez)
UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump then
        pcall(function()
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Sadece durumu değiştirir, fiziksel hızlara dokunmaz
                -- Böylece Roblox'un kendi hareket sistemi (WASD) bozulmaz.
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- Toggle UI Fonksiyonu
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 48)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 45)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
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
    switchBg.Size = UDim2.new(0, 40, 0, 20)
    switchBg.Position = UDim2.new(1, -50, 0.5, -10)
    switchBg.BackgroundColor3 = Color3.fromRGB(40, 42, 60)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 10)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)
    
    local state = false
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            local pos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            local color = state and NEON_COLOR or Color3.fromRGB(40, 42, 60)
            
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = pos}):Play()
            TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            callback(state)
        end
    end)
end

-- Butonlar
createToggle("Anti Bat", 65, function(state)
    getgenv().AntiBat = state
end)

createToggle("Inf Jump", 125, function(state)
    getgenv().InfJump = state
end)

print("Moon Hub Başlatıldı. Infinite Jump Fixlendi.")
