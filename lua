local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

-- Global Durumlar
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

-- Animasyonlu Şerit/Işık Fonksiyonu
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

-- GUI Yapısı
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_Ultimate"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 210)
main.Position = UDim2.new(0.5, -130, 0.5, -105)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
createAnimatedStroke(main, 2.5, 1)
makeDraggable(main)

-- Moon Hub Başlık Kutusu (Neon Şeritli)
local titleBox = Instance.new("Frame")
titleBox.Size = UDim2.new(0, 160, 0, 36)
titleBox.Position = UDim2.new(0.5, -80, 0, 15)
titleBox.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
titleBox.Parent = main
Instance.new("UICorner", titleBox).CornerRadius = UDim.new(0, 10)
createAnimatedStroke(titleBox, 2, 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = titleBox

-- ÖZELLİK MANTIKLARI (BJ SCRIPT LOGIC)

-- Anti Bat Sistemi (BJ'nin Gelişmiş Versiyonu)
RunService.Heartbeat:Connect(function()
    if getgenv().AntiBatOn then
        pcall(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum then
                -- Velocity Flicker (Bayılmayı önleyen BJ taktiği)
                local origVel = root.Velocity
                root.Velocity = Vector3.new(4000, origVel.Y, 4000)
                RunService.RenderStepped:Wait()
                root.Velocity = Vector3.new(origVel.X, root.Velocity.Y, origVel.Z)

                -- Ragdoll & State Fix
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
                
                -- Motor6D Fix (BJ'nin Ragdoll önleyici kodu)
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("Motor6D") and not part.Enabled then
                        part.Enabled = true
                    end
                end
            end
        end)
    end
end)

-- Inf Jump Sistemi (BJ'nin Platform Versiyonu - Takılma Yapmaz)
local function CreateIJP()
    if InfJumpPlatform then return end
    InfJumpPlatform = Instance.new("Part")
    InfJumpPlatform.Name = "MoonJumpPlatform"
    InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
    InfJumpPlatform.Anchored = true
    InfJumpPlatform.CanCollide = true
    InfJumpPlatform.Transparency = 1
    InfJumpPlatform.Material = Enum.Material.ForceField
    InfJumpPlatform.Parent = workspace
end

RunService.Heartbeat:Connect(function()
    if getgenv().InfJumpOn then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if root and hum then
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
            if isJumping then
                CreateIJP()
                InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
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

-- Toggle Arayüzü
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 50)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 45)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
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
    switchBg.Size = UDim2.new(0, 42, 0, 22)
    switchBg.Position = UDim2.new(1, -54, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 50, 75)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 11)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
    
    local state = false
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            local pos = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            local color = state and NEON_COLOR or Color3.fromRGB(45, 50, 75)
            
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = pos}):Play()
            TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            callback(state)
        end
    end)
end

-- Butonlar
createToggle("Anti Bat", 70, function(state)
    getgenv().AntiBatOn = state
end)

createToggle("Inf Jump", 130, function(state)
    getgenv().InfJumpOn = state
end)

print("Moon Hub Ultimate Yüklendi! Space Hub özellikleri entegre edildi.")
