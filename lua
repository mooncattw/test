local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)
local CONFIG_FILE = "MoonHubConfig.json"

-- Ayarlar ve Kayıt Sistemi
local Settings = {
    AntiBatOn = false,
    InfJumpOn = false,
    AntiBatKey = "None",
    InfJumpKey = "None"
}

local function SaveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Settings))
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            Settings.AntiBatKey = data.AntiBatKey or "None"
            Settings.InfJumpKey = data.InfJumpKey or "None"
        end
    end)
end
LoadConfig()

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

-- Neon Şerit Fonksiyonu
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
main.Size = UDim2.new(0, 320, 0, 220)
main.Position = UDim2.new(0.5, -160, 0.5, -110)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
createAnimatedStroke(main, 2.5, 1)
makeDraggable(main)

-- Başlık Şeridi
local titleBox = Instance.new("Frame")
titleBox.Size = UDim2.new(0, 180, 0, 36)
titleBox.Position = UDim2.new(0.5, -90, 0, 15)
titleBox.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
titleBox.Parent = main
Instance.new("UICorner", titleBox).CornerRadius = UDim.new(0, 10)
createAnimatedStroke(titleBox, 2, 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = titleBox

-- MANTIKLAR (LOGIC)
local InfJumpPlatform = nil
RunService.Heartbeat:Connect(function()
    if Settings.AntiBatOn then
        pcall(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                local ov = root.Velocity
                root.Velocity = Vector3.new(4000, ov.Y, 4000)
                RunService.RenderStepped:Wait()
                root.Velocity = Vector3.new(ov.X, root.Velocity.Y, ov.Z)
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end
    
    if Settings.InfJumpOn then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
                if not InfJumpPlatform then
                    InfJumpPlatform = Instance.new("Part")
                    InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
                    InfJumpPlatform.Anchored = true
                    InfJumpPlatform.Transparency = 1
                    InfJumpPlatform.Parent = workspace
                end
                InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
                if root.Velocity.Y < 50 then
                    root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
                end
            elseif InfJumpPlatform then
                InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
            end
        end
    elseif InfJumpPlatform then
        InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
    end
end)

-- Satır Oluşturma Fonksiyonu (Toggle + Keybind Box)
local function createFeature(text, yOffset, featureType)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 50)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 45)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
    createAnimatedStroke(row, 1.5, 1.2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    -- Keybind Kutusu
    local kbBox = Instance.new("TextButton")
    kbBox.Size = UDim2.new(0, 65, 0, 28)
    kbBox.Position = UDim2.new(1, -115, 0.5, -14)
    kbBox.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
    kbBox.Text = Settings[featureType.."Key"]
    kbBox.Font = Enum.Font.GothamBold
    kbBox.TextSize = 12
    kbBox.TextColor3 = NEON_COLOR
    kbBox.Parent = row
    Instance.new("UICorner", kbBox).CornerRadius = UDim.new(0, 6)
    createAnimatedStroke(kbBox, 1.2, 2)

    -- Toggle Düğmesi
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 38, 0, 20)
    switchBg.Position = UDim2.new(1, -45, 0.5, -10)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 50, 75)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 10)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)

    local function updateUI()
        local active = Settings[featureType.."On"]
        local pos = active and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local color = active and NEON_COLOR or Color3.fromRGB(45, 50, 75)
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = pos}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end
    updateUI()

    -- Toggle Tıkla
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Settings[featureType.."On"] = not Settings[featureType.."On"]
            updateUI()
        end
    end)

    -- Keybind Tıkla (Kayıt Modu)
    local listening = false
    kbBox.MouseButton1Click:Connect(function()
        listening = true
        kbBox.Text = "..."
        kbBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            local key = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            Settings[featureType.."Key"] = key
            kbBox.Text = key
            kbBox.TextColor3 = NEON_COLOR
            listening = false
            SaveConfig()
        elseif not listening and input.UserInputType == Enum.UserInputType.Keyboard then
            local key = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            if key == Settings[featureType.."Key"] then
                Settings[featureType.."On"] = not Settings[featureType.."On"]
                updateUI()
            end
        end
    end)
end

-- Özellikleri Oluştur
createFeature("Anti Bat", 75, "AntiBat")
createFeature("Inf Jump", 135, "InfJump")

print("Moon Hub Ultimate: Keybind & Save System Aktif!")
