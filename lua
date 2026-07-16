local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 180, 255)

-- Draggable (Üst bardan)
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

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 160)
main.Position = UDim2.new(0.5, -140, 0.5, -80)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = NEON_COLOR
stroke.Thickness = 1.8
stroke.Parent = main

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = NEON_COLOR
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = titleBar

-- Toggle Fonksiyonu
local function createToggle(text, yOffset, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 42)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 48, 0, 26)
    switchBg.Position = UDim2.new(1, -65, 0.5, -13)
    switchBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    switchBg.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 13)
    sCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = UDim2.new(0, 2, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.Parent = switchBg

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(0, 11)
    kCorner.Parent = knob

    local state = false

    local function update(on)
        state = on
        local goal = on and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        local color = on and NEON_COLOR or Color3.fromRGB(35, 35, 45)
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = goal}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        callback(on)
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(not state)
        end
    end)
end

-- Anti-Bat & Inf Jump Logic (tam)
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
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.FallingDown then
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
        infJumpPlatform.Size = Vector3.new(8,0.5,8)
        infJumpPlatform.Transparency = 1
        infJumpPlatform.Anchored = true
        infJumpPlatform.CanCollide = true
        infJumpPlatform.Parent = workspace
    end
    infJumpConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
                infJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
                if root.Velocity.Y < 50 then
                    root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
                end
            else
                infJumpPlatform.Position = Vector3.new(0, -1000, 0)
            end
        end
    end)
end

local function stopInfJump()
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if infJumpPlatform then infJumpPlatform.Position = Vector3.new(0, -1000, 0) end
end

-- Toggle'lar
createToggle("Anti Bat", 50, function(state)
    if state then
        startAntiBat()
        startAntiRagdoll()
    else
        stopAntiBat()
        stopAntiRagdoll()
    end
end)

createToggle("Inf Jump", 100, function(state)
    if state then
        startInfJump()
    else
        stopInfJump()
    end
end)

-- Draggable
makeDraggable(titleBar)

print("Moon Hub Yüklendi")
