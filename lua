local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local CONFIG_FILE = "MoonHubantibat.json"

local Settings = {
    AntiBatOn = false,
    InfJumpOn = false,
    AntiBatKey = nil,
    InfJumpKey = nil
}

local function SaveConfig()
    pcall(function()
        local data = {
            AntiBatKey = Settings.AntiBatKey and Settings.AntiBatKey.Name or nil,
            InfJumpKey = Settings.InfJumpKey and Settings.InfJumpKey.Name or nil
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.AntiBatKey then Settings.AntiBatKey = Enum.KeyCode[data.AntiBatKey] end
            if data.InfJumpKey then Settings.InfJumpKey = Enum.KeyCode[data.InfJumpKey] end
        end
    end)
end
LoadConfig()

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Color3.new(1, 1, 1)
    s.Parent = parent

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 50, 150)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 50, 150)),
    })
    g.Rotation = 0
    g.Parent = s

    task.spawn(function()
        local spd = speed or 1.2
        while parent.Parent do
            g.Rotation = (g.Rotation + spd) % 360
            task.wait()
        end
    end)

    return s, g
end

local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_Mini"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

-- Boyut ve tasarım TP Bat ile aynı yapıldı
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 145)
main.Position = UDim2.new(0.5, -110, 0.5, -72)
main.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
main.BackgroundTransparency = 0.25
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

-- Sürükleme Sistemi
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 20)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 9
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 160, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 160, 255)),
})
titleGrad.Parent = title

task.spawn(function()
    while main.Parent do
        titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
        task.wait()
    end
end)

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 15)
subtitle.Position = UDim2.new(0, 10, 0, 23)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Anti Bat / Inf Jump"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.new(1, 1, 1)
subtitle.TextTransparency = 0.3
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 9
subtitle.Parent = main

-- Karakter Fonksiyonları
local InfJumpPart = nil
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
                if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
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
                if not InfJumpPart then
                    InfJumpPart = Instance.new("Part", workspace)
                    InfJumpPart.Size = Vector3.new(8, 0.5, 8)
                    InfJumpPart.Anchored, InfJumpPart.Transparency = true, 1
                end
                InfJumpPart.Position = root.Position - Vector3.new(0, 3.5, 0)
                if root.Velocity.Y < 50 then root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z) end
            elseif InfJumpPart then InfJumpPart.Position = Vector3.new(0, -1000, 0) end
        end
    elseif InfJumpPart then InfJumpPart.Position = Vector3.new(0, -1000, 0) end
end)

-- Özellik Satırı Oluşturucu (Tasarım tamamen TP Bat ile eşitlendi)
local function createFeature(text, yOffset, featureType)
    local toggleRow = Instance.new("Frame")
    toggleRow.Size = UDim2.new(1, -20, 0, 40)
    toggleRow.Position = UDim2.new(0, 10, 0, yOffset)
    toggleRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
    toggleRow.ZIndex = 2
    toggleRow.Parent = main

    Instance.new("UICorner", toggleRow)
    createAnimatedStroke(toggleRow, 1, 1.2)

    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0, 60, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.Font = Enum.Font.GothamBlack
    toggleLabel.TextSize = 13
    toggleLabel.TextColor3 = Color3.new(1, 1, 1)
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.ZIndex = 3
    toggleLabel.Parent = toggleRow

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 36, 0, 18)
    switchBg.Position = UDim2.new(1, -46, 0.5, -9)
    switchBg.BackgroundTransparency = 1
    switchBg.ZIndex = 3
    switchBg.Parent = toggleRow

    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 9)
    createAnimatedStroke(switchBg, 2, 1.5)

    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 14, 0, 14)
    switchKnob.Position = UDim2.new(0, 2, 0.5, -7)
    switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    switchKnob.ZIndex = 4
    switchKnob.Parent = switchBg

    Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 7)

    -- Her yerden basılabilen ana buton alanı
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 4
    toggleBtn.Parent = toggleRow

    -- Yanındaki Keybind Butonu
    local kbBtn = Instance.new("TextButton")
    kbBtn.Size = UDim2.new(0, 55, 0, 22)
    kbBtn.Position = UDim2.new(0, 65, 0.5, -11)
    kbBtn.BackgroundColor3 = Color3.fromRGB(25, 45, 95)
    kbBtn.BackgroundTransparency = 0.3
    kbBtn.AutoButtonColor = false
    kbBtn.Font = Enum.Font.GothamBlack
    kbBtn.ZIndex = 5

    local function updateKeybindText()
        if Settings[featureType.."Key"] then
            kbBtn.Text = "[ " .. Settings[featureType.."Key"].Name .. " ]"
        else
            kbBtn.Text = "[ ... ]"
        end
    end
    updateKeybindText()

    kbBtn.TextSize = 10
    kbBtn.TextColor3 = Color3.new(1, 1, 1)
    kbBtn.Parent = toggleRow

    Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)
    createAnimatedStroke(kbBtn, 1, 1.5)

    local function setToggle(newState)
        Settings[featureType.."On"] = newState
        local goal = newState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        local color = newState and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
        TweenService:Create(switchKnob, TweenInfo.new(0.15), {Position = goal}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end

    toggleBtn.MouseButton1Click:Connect(function()
        setToggle(not Settings[featureType.."On"])
    end)

    local listeningForKey = false
    kbBtn.MouseButton1Click:Connect(function()
        listeningForKey = true
        kbBtn.Text = "[ ... ]"
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listeningForKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Settings[featureType.."Key"] = input.KeyCode
                updateKeybindText()
                SaveConfig()
                listeningForKey = false
            end
            return
        end
        if Settings[featureType.."Key"] and input.KeyCode == Settings[featureType.."Key"] then
            setToggle(not Settings[featureType.."On"])
        end
    end)

    setToggle(false)
end

createFeature("Anti Bat", 45, "AntiBat")
createFeature("Inf Jump", 95, "InfJump")
