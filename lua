local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Draggable = true,
    TpBatKey = Enum.KeyCode.T,
}

local tpBatToggled = false
local tpBatCooldown = false

local function getHRP()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getBat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        tool = bp:FindFirstChild("Bat")
        if tool then
            tool.Parent = char
            return tool
        end
    end
    return nil
end

local function tryHitBat()
    if tpBatCooldown then return end
    tpBatCooldown = true
    pcall(function()
        local bat = getBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() tpBatCooldown = false end)
end

local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp, cd
end

local BLUE = {
    Main = Color3.fromRGB(70, 140, 255),
    Light = Color3.fromRGB(180, 220, 255),
    Dark = Color3.fromRGB(20, 60, 140),
    Glow = Color3.fromRGB(40, 120, 255),
    White = Color3.fromRGB(255, 255, 255),
    Card = Color3.fromRGB(25, 35, 60),
    Border = Color3.fromRGB(70, 140, 255),
    BG = Color3.fromRGB(8, 16, 30),
    Red = Color3.fromRGB(255, 90, 90),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 180, 0, 100)
main.Position = UDim2.new(0.5, -90, 0.5, -50)
main.BackgroundColor3 = Color3.fromRGB(10, 18, 40)
main.BackgroundTransparency = 0
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.fromRGB(80, 170, 255)
mainStroke.Transparency = 0.2
mainStroke.Parent = main

local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BackgroundImage"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.Position = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = ""
bgImage.ZIndex = -1
bgImage.ImageTransparency = 1
bgImage.Parent = main

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 24, 58)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 35, 75))
}
mainGradient.Rotation = 90
mainGradient.Parent = main

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 0, 1, 0)
glow.Position = UDim2.new(0, 0, 0, 0)
glow.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
glow.BackgroundTransparency = 0.95
glow.BorderSizePixel = 0
glow.Parent = main

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 15)
glowCorner.Parent = glow

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 35)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "MOON HUB"
title.TextColor3 = Color3.fromRGB(245, 245, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextStrokeTransparency = 0.7
title.TextStrokeColor3 = Color3.fromRGB(10, 25, 85)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.85, 0, 0, 1)
divider.Position = UDim2.new(0.075, 0, 0, 42)
divider.BackgroundColor3 = Color3.fromRGB(150, 205, 255)
divider.BackgroundTransparency = 0.45
divider.BorderSizePixel = 0
divider.Parent = main

local tpLabel = Instance.new("TextLabel")
tpLabel.Size = UDim2.new(0.2, 0, 0, 14)
tpLabel.Position = UDim2.new(0.05, 0, 0, 50)
tpLabel.BackgroundTransparency = 1
tpLabel.Text = "TP BAT"
tpLabel.TextColor3 = Color3.fromRGB(180, 200, 245)
tpLabel.Font = Enum.Font.GothamBold
tpLabel.TextSize = 10
tpLabel.TextXAlignment = Enum.TextXAlignment.Left
tpLabel.TextStrokeTransparency = 0.4
tpLabel.TextStrokeColor3 = Color3.fromRGB(15, 30, 65)
tpLabel.Parent = main

local tpKeyBtn = Instance.new("TextButton")
tpKeyBtn.Size = UDim2.new(0.22, 0, 0, 24)
tpKeyBtn.Position = UDim2.new(0.28, 0, 0, 50)
tpKeyBtn.BackgroundColor3 = Color3.fromRGB(15, 35, 90)
tpKeyBtn.Text = "T"
tpKeyBtn.TextColor3 = Color3.fromRGB(175, 215, 255)
tpKeyBtn.Font = Enum.Font.GothamBold
tpKeyBtn.TextSize = 12
tpKeyBtn.BorderSizePixel = 0
tpKeyBtn.AutoButtonColor = false
tpKeyBtn.Parent = main

local tpKeyCorner = Instance.new("UICorner")
tpKeyCorner.CornerRadius = UDim.new(0, 5)
tpKeyCorner.Parent = tpKeyBtn

tpKeyBtn.MouseButton1Click:Connect(function()
    tpKeyBtn.Text = "..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            CONFIG.TpBatKey = input.KeyCode
            tpKeyBtn.Text = input.KeyCode.Name
            connection:Disconnect()
        end
    end)
end)

local tpToggleBtn = Instance.new("TextButton")
tpToggleBtn.Size = UDim2.new(0.42, 0, 0, 24)
tpToggleBtn.Position = UDim2.new(0.55, 0, 0, 50)
tpToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 210)
tpToggleBtn.Text = "TP BAT"
tpToggleBtn.TextColor3 = Color3.fromRGB(235, 240, 255)
tpToggleBtn.Font = Enum.Font.GothamBold
tpToggleBtn.TextSize = 10
tpToggleBtn.BorderSizePixel = 0
tpToggleBtn.AutoButtonColor = false
tpToggleBtn.Parent = main

local tpCorner = Instance.new("UICorner")
tpCorner.CornerRadius = UDim.new(0, 5)
tpCorner.Parent = tpToggleBtn

tpToggleBtn.MouseButton1Click:Connect(function()
    tpBatToggled = not tpBatToggled
    updateVisuals()
end)


local function updateVisuals()
    if tpBatToggled then
        tpToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 45, 120)
        tpToggleBtn.TextColor3 = Color3.fromRGB(225, 235, 255)
        mainStroke.Color = Color3.fromRGB(90, 160, 220)
        mainStroke.Transparency = 0.18
    else
        tpToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 90, 170)
        tpToggleBtn.TextColor3 = Color3.fromRGB(235, 240, 255)
        mainStroke.Color = Color3.fromRGB(100, 170, 210)
        mainStroke.Transparency = 0.22
    end
    tpKeyBtn.Text = CONFIG.TpBatKey.Name
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == CONFIG.TpBatKey then
        tpBatToggled = not tpBatToggled
        updateVisuals()
    end
end)

RunService.Heartbeat:Connect(function()
    if not tpBatToggled then return end
    local hrp = getHRP()
    if not hrp then return end

    local target = getClosestPlayer()
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            if sethiddenproperty then
                sethiddenproperty(hrp, "PhysicsRepRootPart", tr)
            end
            local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
            if (hrp.Position - targetPos).Magnitude > 8 then
                hrp.CFrame = CFrame.new(targetPos)
            end
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
            tryHitBat()
        end
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        if tpBatToggled then
            mainStroke.Transparency = 0.1
            mainStroke.Color = BLUE.Glow
            glow.BackgroundTransparency = 0.9
        else
            mainStroke.Transparency = 0.2
            mainStroke.Color = BLUE.Border
            glow.BackgroundTransparency = 0.9
        end
        task.wait()
    end
end)

updateVisuals()
