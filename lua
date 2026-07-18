local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)
local CONFIG_FILE = "MoonHubantibat.json"

local Settings = {
    AntiBatOn = false,
    InfJumpOn = false,
    AntiBatKey = "...",
    InfJumpKey = "..."
}

local function SaveConfig()
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Settings)) end)
end

local function LoadConfig()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            Settings.AntiBatKey = data.AntiBatKey or "..."
            Settings.InfJumpKey = data.InfJumpKey or "..."
        end
    end)
end
LoadConfig()

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function createAnimatedStroke(parent, thickness, speed)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = NEON_COLOR
    stroke.Parent = parent
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
    }
    gradient.Parent = stroke
    task.spawn(function()
        local rot = 0
        while parent and parent.Parent do
            rot = (rot + (speed or 1.2)) % 360
            gradient.Rotation = rot
            task.wait()
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub_Mini"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 175)
main.Position = UDim2.new(0.5, -130, 0.5, -87)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 25)
main.BackgroundTransparency = 0.1
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
createAnimatedStroke(main, 2.2, 0.8)
makeDraggable(main)

local titleBox = Instance.new("Frame")
titleBox.Size = UDim2.new(0, 130, 0, 30)
titleBox.Position = UDim2.new(0.5, -65, 0, 12)
titleBox.BackgroundColor3 = Color3.fromRGB(20, 22, 40)
titleBox.Parent = main
Instance.new("UICorner", titleBox).CornerRadius = UDim.new(0, 8)
createAnimatedStroke(titleBox, 1.8, 1.5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = titleBox

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

local function createFeature(text, yOffset, featureType)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 42)
    row.Position = UDim2.new(0, 10, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(22, 25, 42)
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    createAnimatedStroke(row, 1.2, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local kbBtn = Instance.new("TextButton")
    kbBtn.Size = UDim2.new(0, 55, 0, 24)
    kbBtn.Position = UDim2.new(1, -95, 0.5, -12)
    kbBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 55)
    kbBtn.Text = Settings[featureType.."Key"]
    kbBtn.Font = Enum.Font.GothamBold
    kbBtn.TextSize = 11
    kbBtn.TextColor3 = NEON_COLOR
    kbBtn.Parent = row
    Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)
    createAnimatedStroke(kbBtn, 1, 2)

    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 32, 0, 18)
    switch.Position = UDim2.new(1, -38, 0.5, -9)
    switch.BackgroundColor3 = Color3.fromRGB(45, 48, 70)
    switch.Parent = row
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switch
    Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 9)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)

    local function update()
        local on = Settings[featureType.."On"]
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = on and NEON_COLOR or Color3.fromRGB(45, 48, 70)}):Play()
    end
    update()

    row.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Settings[featureType.."On"] = not Settings[featureType.."On"] update() end end)

    local listen = false
    kbBtn.MouseButton1Click:Connect(function() listen = true kbBtn.Text = "..." end)
    UserInputService.InputBegan:Connect(function(i)
        if listen and i.UserInputType == Enum.UserInputType.Keyboard then
            local key = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            Settings[featureType.."Key"] = key
            kbBtn.Text = key
            listen = false
            SaveConfig()
        elseif not listen and i.UserInputType == Enum.UserInputType.Keyboard then
            if tostring(i.KeyCode):gsub("Enum.KeyCode.", "") == Settings[featureType.."Key"] then
                Settings[featureType.."On"] = not Settings[featureType.."On"]
                update()
            end
        end
    end)
end

createFeature("Anti Bat", 55, "AntiBat")
createFeature("Inf Jump", 105, "InfJump")
