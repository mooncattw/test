local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

-- Global Ayarlar
getgenv().AntiBatOn = false
getgenv().InfJumpOn = false
local InfJumpPlatform = nil

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

-- Animasyonlu Neon Kenarlık
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
gui.Name = "MoonHub_Pro"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 220)
main.Position = UDim2.new(0.5, -130, 0.5, -110)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 25)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
createAnimatedStroke(main, 2.5, 1)
makeDraggable(main)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "MOON HUB"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = NEON_COLOR
title.Parent = main

-- MANTIK (LOGIC) KODLARI --

-- Anti-Bat / Anti-Ragdoll Sistemi
RunService.Heartbeat:Connect(function()
    if getgenv().AntiBatOn then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and hum then
            -- Velocity Trick (Stun bozmak için)
            local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            root.Velocity = Vector3.new(4000, root.Velocity.Y, 4000)
            RunService.RenderStepped:Wait()
            root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)

            -- Ragdoll Engelleme
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)

-- Infinite Jump Sistemi (Platform Destekli)
local function CreateIJP()
    if InfJumpPlatform then return end
    InfJumpPlatform = Instance.new("Part")
    InfJumpPlatform.Name = "MoonInfJumpPart"
    InfJumpPlatform.Size = Vector3.new(10, 0.5, 10)
    InfJumpPlatform.Anchored = true
    InfJumpPlatform.Transparency = 1
    InfJumpPlatform.Parent = workspace
end

RunService.Heartbeat:Connect(function()
    if getgenv().InfJumpOn then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and hum then
            local jumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
            if jumping then
                CreateIJP()
                InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.4, 0)
                if root.Velocity.Y < 50 then
                    root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
                end
            else
                if InfJumpPlatform then InfJumpPlatform.Position = Vector3.new(0, -1000, 0) end
            end
        end
    else
        if InfJumpPlatform then InfJumpPlatform.Position = Vector3.new(0, -1000, 0) end
    end
end)

-- Toggle Fonksiyonu (Dönen ışıklı butonlar)
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 48)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    createAnimatedStroke(row, 1.5, 1.2) -- Buton etrafındaki ışık
    
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

-- Butonları Yerleştir
createToggle("Anti-Bat (God Mode)", 60, function(state)
    getgenv().AntiBatOn = state
end)

createToggle("Infinite Jump (New)", 125, function(state)
    getgenv().InfJumpOn = state
end)

-- Keybind Ayarı (Menüyü Kapatıp Açma)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F1 then
        main.Visible = not main.Visible
    end
end)

print("Moon Hub v3: Space Hub Logic Entegre Edildi! F1 ile menüyü gizle.")
