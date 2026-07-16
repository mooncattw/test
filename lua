local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

-- Animasyonlu kenarlık fonksiyonu
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
        while parent and parent.Parent do
            gradient.Rotation = (gradient.Rotation + (speed or 1)) % 360
            task.wait()
        end
    end)
end

-- Ana GUI Yapısı
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_Fixed"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 200) -- Boyut biraz artırıldı
main.Position = UDim2.new(0.5, -130, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 28)
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
createAnimatedStroke(main, 2.2, 0.9)

-- Moon Hub Başlığı (Siyah bar olmadan doğrudan ana gövde üstünde)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = NEON_COLOR
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = main

-- Başlık Altı Şık Çizgi
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.8, 0, 0, 2)
divider.Position = UDim2.new(0.1, 0, 0, 45)
divider.BackgroundColor3 = NEON_COLOR
divider.BorderSizePixel = 0
divider.Parent = main

local dividerGradient = Instance.new("UIGradient")
dividerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1)
})
dividerGradient.Parent = divider

-- Toggle Oluşturma Fonksiyonu
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 50)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(22, 26, 42)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 16, 0, 0)
    label.Parent = row
    
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -56, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 11)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
    
    local state = false
    local function update(stateOn)
        state = stateOn
        local pos = stateOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local color = stateOn and NEON_COLOR or Color3.fromRGB(45, 45, 60)
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = pos}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        callback(stateOn)
    end
    
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(not state)
        end
    end)
end

-- Özellikler
createToggle("Anti-Bat", 65, function(state)
    -- Anti-Bat kodu buraya
end)

createToggle("Inf Jump", 125, function(state)
    -- Inf Jump kodu buraya
end)

-- Sürükleme (makeDraggable) tamamen kaldırıldı. 
-- GUI ekranın ortasında sabit kalacaktır.
