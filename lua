local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local NEON_COLOR = Color3.fromRGB(0, 170, 255)

local CONFIG_FILE = "MoonHubConfig.json"

-- Mobile/PC Detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Draggable (Hem PC hem Mobile için düzeltilmiş)
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end

    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
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

    UserInputService.InputChanged:Connect(update)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Animated Stroke
local function createAnimatedStroke(parent, thickness, speed)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.8
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = NEON_COLOR
    stroke.Parent = parent

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
    }
    gradient.Rotation = 0
    gradient.Parent = stroke

    task.spawn(function()
        while parent.Parent do
            gradient.Rotation = (gradient.Rotation + (speed or 1.2)) % 360
            task.wait()
        end
    end)
    return stroke
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MoonHub"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 180)
main.Position = UDim2.new(0.5, -130, 0.5, -90)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 28)
main.BackgroundTransparency = 0.35
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = main

createAnimatedStroke(main, 2.2, 0.9)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(8, 10, 22)
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 18, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = NEON_COLOR
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -35, 0.5, -14)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

-- Toggle Buttons
local function createToggle(name, text, yOffset)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 48)
    row.Position = UDim2.new(0, 15, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
    row.Parent = main

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 12)
    rc.Parent = row

    createAnimatedStroke(row, 1.4, 1.1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 15
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 16, 0, 0)
    label.Parent = row

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 42, 0, 22)
    switchBg.Position = UDim2.new(1, -55, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    switchBg.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 11)
    sCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.Parent = switchBg

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(0, 9)
    kCorner.Parent = knob

    local toggleState = false

    local function updateToggle(state)
        toggleState = state
        local goalPos = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local goalColor = state and NEON_COLOR or Color3.fromRGB(40, 40, 55)
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = goalPos}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateToggle(not toggleState)
        end
    end)

    return row, updateToggle
end

local antiBatRow, toggleAntiBat = createToggle("AntiBat", "Anti-Bat", 55)
local infJumpRow, toggleInfJump = createToggle("InfJump", "Inf Jump", 115)

-- Draggable (Sadece TitleBar'dan)
makeDraggable(titleBar)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

print("Moon Hub yüklendi")
