local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

local CONFIG_FILE = "MoonHubConfig.json"

-- Draggable (Sadece üst bardan)
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

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
        if dragging and dragInput == input then
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

-- Animated Stroke
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
        while parent.Parent do
            gradient.Rotation = (gradient.Rotation + (speed or 1)) % 360
            task.wait()
        end
    end)
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 190)
main.Position = UDim2.new(0.5, -130, 0.5, -95)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
main.BackgroundTransparency = 0.35
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
createAnimatedStroke(main, 2.2, 0.9)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(8, 10, 22)
titleBar.Parent = main

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = NEON_COLOR
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = titleBar

-- Toggle Oluşturma Fonksiyonu
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 50)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
    row.Parent = main

    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
    createAnimatedStroke(row, 1.4, 1)

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
    switchBg.Size = UDim2.new(0, 46, 0, 24)
    switchBg.Position = UDim2.new(1, -60, 0.5, -12)
    switchBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)

    local state = false

    local function update(stateOn)
        state = stateOn
        local pos = stateOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local color = stateOn and NEON_COLOR or Color3.fromRGB(40, 40, 55)
        TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = pos}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.25), {BackgroundColor3 = color}):Play()
        callback(stateOn)
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(not state)
        end
    end)

    return update
end

-- Anti-Bat & Inf Jump Logic
local antiBatConn, antiRagdollConn, infJumpConn = nil, nil, nil
local infJumpPlatform = nil

local function startAntiBat()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if antiBatConn then antiBatConn:Disconnect() end
    antiBatConn = RunService.Heartbeat:Connect(function()
        if root and root.Parent then
            local orig = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            root.Velocity = Vector3.new(4000, root.Velocity.Y, 4000)
            RunService.RenderStepped:Wait()
            root.Velocity = Vector3.new(orig.X, root.Velocity.Y, orig.Z)
        end
    end)
end

local function stopAntiBat()
    if antiBatConn then antiBatConn:Disconnect() antiBatConn = nil end
end

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                root.Velocity = Vector3.new(0,0,0)
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() antiRagdollConn = nil end
end

local function startInfJump()
    if infJumpConn then infJumpConn:Disconnect() end
    if not infJumpPlatform then
        infJumpPlatform = Instance.new("Part")
        infJumpPlatform.Size = Vector3.new(8, 0.5, 8)
        infJumpPlatform.Transparency = 1
        infJumpPlatform.Anchored = true
        infJumpPlatform.CanCollide = true
        infJumpPlatform.Parent = workspace
    end

    infJumpConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (root and hum) then return end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
            infJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
            if root.Velocity.Y < 50 then
                root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
            end
        else
            infJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
    end)
end

local function stopInfJump()
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if infJumpPlatform then
        infJumpPlatform.Position = Vector3.new(0, -1000, 0)
    end
end

-- Toggle'lar
local toggleAntiBat = createToggle("Anti-Bat", 55, function(state)
    if state then
        startAntiBat()
        startAntiRagdoll()
    else
        stopAntiBat()
        stopAntiRagdoll()
    end
end)

local toggleInfJump = createToggle("Inf Jump", 115, function(state)
    if state then
        startInfJump()
    else
        stopInfJump()
    end
end)

-- Draggable
makeDraggable(titleBar)

print("Moon Hub Yüklendi - Tam Çalışır")
