local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Draggable = true,
    TpBatKey = Enum.KeyCode.T,
    ResetKey = Enum.KeyCode.R,
}

_G.VampireResetRemote = _G.VampireResetRemote or nil
_G.VampireResetGuid = _G.VampireResetGuid or "f888ee6e-c86d-46e1-93d7-0639d6635d42"

pcall(function()
    if not _G.VampireResetHooked and hookfunction and newcclosure then
        _G.VampireResetHooked = true

        local oldFire
        oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not _G.VampireResetRemote
                and typeof(self) == "Instance"
                and self:IsA("RemoteEvent")
                and self.Name:sub(1, 3) == "RE/" then
                _G.VampireResetRemote = self
            end

            return oldFire(self, ...)
        end))
    end
end)

local function findVampireResetRemote()
    if _G.VampireResetRemote then
        return _G.VampireResetRemote
    end

    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then
            _G.VampireResetRemote = desc
            break
        end
    end

    return _G.VampireResetRemote
end

local function vampireInstaReset()
    local remote = findVampireResetRemote()
    if not remote then
        return false
    end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health <= 0 then
        pcall(function()
            remote:FireServer(_G.VampireResetGuid, LocalPlayer, "balloon")
        end)
        return true
    end

    local resetDetected = false
    local resetConns = {}

    if humanoid then
        table.insert(resetConns, humanoid.Died:Connect(function()
            resetDetected = true
        end))

        table.insert(resetConns, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health <= 0 then
                resetDetected = true
            end
        end))
    end

    if character then
        table.insert(resetConns, character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                resetDetected = true
            end
        end))
    end

    task.spawn(function()
        for _ = 1, 10 do
            if resetDetected then
                break
            end

            pcall(function()
                remote:FireServer(_G.VampireResetGuid, LocalPlayer, "balloon")
            end)

            task.wait(0.05)
        end

        for _, conn in ipairs(resetConns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end)

    return true
end

local function performReset()
    vampireInstaReset()
    resetBtn.Text = "..."
    resetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    task.delay(0.3, function()
        resetBtn.Text = "INSTA RESET"
        resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

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
main.Size = UDim2.new(0, 180, 0, 150)
main.Position = UDim2.new(0.5, -90, 0.5, -75)
main.BackgroundColor3 = BLUE.BG
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.5
mainStroke.Color = BLUE.Border
mainStroke.Transparency = 0.3
mainStroke.Parent = main

local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BackgroundImage"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.Position = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxassetid://133214118279549"
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ZIndex = -1
bgImage.ImageTransparency = 0.1
bgImage.Parent = main

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 15, 1, 15)
glow.Position = UDim2.new(-7.5, 0, -7.5, 0)
glow.BackgroundColor3 = BLUE.Glow
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
title.Text = "Moon Hub"
title.TextColor3 = BLUE.Main
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextStrokeTransparency = 0
title.TextStrokeColor3 = BLUE.Dark
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(0, 24, 0, 24)
LockBtn.Position = UDim2.new(1, -32, 0, 5)
LockBtn.BackgroundColor3 = BLUE.Card
LockBtn.Text = "🔓"
LockBtn.TextColor3 = BLUE.White
LockBtn.Font = Enum.Font.GothamBold
LockBtn.TextSize = 14
LockBtn.AutoButtonColor = false
LockBtn.Parent = main

local LCorner = Instance.new("UICorner")
LCorner.CornerRadius = UDim.new(0, 5)
LCorner.Parent = LockBtn

LockBtn.MouseButton1Click:Connect(function()
    CONFIG.Draggable = not CONFIG.Draggable
    main.Draggable = CONFIG.Draggable
    if CONFIG.Draggable then
        LockBtn.Text = "🔓"
    else
        LockBtn.Text = "🔒"
    end
end)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.85, 0, 0, 1)
divider.Position = UDim2.new(0.075, 0, 0, 42)
divider.BackgroundColor3 = BLUE.Border
divider.BackgroundTransparency = 0.3
divider.BorderSizePixel = 0
divider.Parent = main

local tpLabel = Instance.new("TextLabel")
tpLabel.Size = UDim2.new(0.35, 0, 0, 14)
tpLabel.Position = UDim2.new(0.075, 0, 0, 50)
tpLabel.BackgroundTransparency = 1
tpLabel.Text = "TP BAT"
tpLabel.TextColor3 = BLUE.Light
tpLabel.Font = Enum.Font.GothamBold
tpLabel.TextSize = 9
tpLabel.TextXAlignment = Enum.TextXAlignment.Left
tpLabel.TextStrokeTransparency = 0.3
tpLabel.TextStrokeColor3 = BLUE.Dark
tpLabel.Parent = main

local tpKeyBtn = Instance.new("TextButton")
tpKeyBtn.Size = UDim2.new(0.25, 0, 0, 24)
tpKeyBtn.Position = UDim2.new(0.075, 0, 0, 64)
tpKeyBtn.BackgroundColor3 = BLUE.Card
tpKeyBtn.Text = "T"
tpKeyBtn.TextColor3 = BLUE.Main
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
tpToggleBtn.Size = UDim2.new(0.45, 0, 0, 24)
tpToggleBtn.Position = UDim2.new(0.45, 0, 0, 64)
tpToggleBtn.BackgroundColor3 = BLUE.Card
tpToggleBtn.Text = "TP BAT"
tpToggleBtn.TextColor3 = BLUE.White
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

local resetLabel = Instance.new("TextLabel")
resetLabel.Size = UDim2.new(0.35, 0, 0, 14)
resetLabel.Position = UDim2.new(0.075, 0, 0, 98)
resetLabel.BackgroundTransparency = 1
resetLabel.Text = "INSTA RESET"
resetLabel.TextColor3 = BLUE.Light
resetLabel.Font = Enum.Font.GothamBold
resetLabel.TextSize = 9
resetLabel.TextXAlignment = Enum.TextXAlignment.Left
resetLabel.TextStrokeTransparency = 0.3
resetLabel.TextStrokeColor3 = BLUE.Dark
resetLabel.Parent = main

local resetKeyBtn = Instance.new("TextButton")
resetKeyBtn.Size = UDim2.new(0.25, 0, 0, 24)
resetKeyBtn.Position = UDim2.new(0.075, 0, 0, 112)
resetKeyBtn.BackgroundColor3 = BLUE.Card
resetKeyBtn.Text = "R"
resetKeyBtn.TextColor3 = BLUE.Red
resetKeyBtn.Font = Enum.Font.GothamBold
resetKeyBtn.TextSize = 12
resetKeyBtn.BorderSizePixel = 0
resetKeyBtn.AutoButtonColor = false
resetKeyBtn.Parent = main

local resetKeyCorner = Instance.new("UICorner")
resetKeyCorner.CornerRadius = UDim.new(0, 5)
resetKeyCorner.Parent = resetKeyBtn

resetKeyBtn.MouseButton1Click:Connect(function()
    resetKeyBtn.Text = "..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            CONFIG.ResetKey = input.KeyCode
            resetKeyBtn.Text = input.KeyCode.Name
            connection:Disconnect()
        end
    end)
end)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.45, 0, 0, 24)
resetBtn.Position = UDim2.new(0.45, 0, 0, 112)
resetBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
resetBtn.Text = "INSTA RESET"
resetBtn.TextColor3 = BLUE.White
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 9
resetBtn.BorderSizePixel = 0
resetBtn.AutoButtonColor = false
resetBtn.Parent = main

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 5)
resetCorner.Parent = resetBtn

local resetStroke = Instance.new("UIStroke")
resetStroke.Thickness = 1
resetStroke.Color = BLUE.Red
resetStroke.Transparency = 0.4
resetStroke.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function()
    performReset()
end)

local function updateVisuals()
    if tpBatToggled then
        tpToggleBtn.Text = "ON"
        tpToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
        tpToggleBtn.TextColor3 = BLUE.Main
        mainStroke.Color = BLUE.Glow
        mainStroke.Transparency = 0.1
    else
        tpToggleBtn.Text = "TP BAT"
        tpToggleBtn.BackgroundColor3 = BLUE.Card
        tpToggleBtn.TextColor3 = BLUE.White
        mainStroke.Color = BLUE.Border
        mainStroke.Transparency = 0.3
    end
    tpKeyBtn.Text = CONFIG.TpBatKey.Name
    resetKeyBtn.Text = CONFIG.ResetKey.Name
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == CONFIG.TpBatKey then
        tpBatToggled = not tpBatToggled
        updateVisuals()
    end

    if input.KeyCode == CONFIG.ResetKey then
        performReset()
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
            local pulse = 0.1 + (math.sin(tick() * 3) * 0.2)
            mainStroke.Transparency = pulse
            mainStroke.Color = BLUE.Glow
            glow.BackgroundTransparency = 0.85 + (math.sin(tick() * 2) * 0.1)
        else
            mainStroke.Transparency = 0.3
            mainStroke.Color = BLUE.Border
            glow.BackgroundTransparency = 0.95
        end
        task.wait()
    end
end)

updateVisuals()
