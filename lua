local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local Animals = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
local Notif = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("NotificationController"))

local ZOOM_DISTANCE = 40
local cameraLockConnection
local scriptEnabled = false
local debounce = false

-- =============================================================================
-- GAME MECHANICS FUNCTIONS
-- =============================================================================

local function startCameraLock(hrp, distance)
    if not hrp then return end
    camera.CameraType = Enum.CameraType.Scriptable
    if cameraLockConnection then cameraLockConnection:Disconnect() end

    cameraLockConnection = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        local offset = -hrp.CFrame.LookVector * distance + Vector3.new(0, 5, 0)
        local pos = hrp.Position + offset
        camera.CFrame = CFrame.new(pos, hrp.Position)
    end)
end

local function stopCameraLock()
    if cameraLockConnection then
        cameraLockConnection:Disconnect()
        cameraLockConnection = nil
    end
end

local function getMyBasePosition()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            local label = plot:FindFirstChild("PlotSign") and plot.PlotSign:FindFirstChild("SurfaceGui") and plot.PlotSign.SurfaceGui:FindFirstChild("Frame") and plot.PlotSign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if label then
                local owner = label.Text:match("(.+)'s Base")
                if owner == player.Name or owner == player.DisplayName then
                    local spawn = plot:FindFirstChild("Spawn")
                    return spawn and spawn.Position or plot:GetPivot().Position
                end
            end
        end
    end
    return nil
end

local function getChar()
    local char = player.Character
    if not char then return end
    return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function getFormattedItem(itemName, rarity)
    if rarity == "Secret" then return string.format("<zebra>%s</zebra>", itemName)
    elseif rarity == "Rare" then return string.format('<font color="#0083ab">%s</font>', itemName)
    elseif rarity == "Common" then return string.format('<font color="#00ab28">%s</font>', itemName)
    elseif rarity == "Epic" then return string.format('<font color="#8600ab">%s</font>', itemName)
    elseif rarity == "Legendary" then return string.format('<font color="#fbff00">%s</font>', itemName)
    elseif rarity == "Mythic" then return string.format('<font color="#ff2a2a">%s</font>', itemName)
    elseif rarity == "Brainrot God" then return string.format("<rainbow>%s</rainbow>", itemName)
    elseif rarity == "OG" then return string.format("<og>%s</og>", itemName)
    end
    return itemName
end

local function runSequence()
    if debounce or not scriptEnabled then return end
    debounce = true

    task.spawn(function()
        local stolenItem = player:GetAttribute("StealingIndex")
        local rarity = "Unknown"

        if stolenItem and Animals[stolenItem] then
            rarity = Animals[stolenItem].Rarity or "Unknown"
        end

        task.wait(0.1)
        local base = getMyBasePosition()
        local char, _, hrp = getChar()

        if hrp and scriptEnabled then startCameraLock(hrp, ZOOM_DISTANCE) end
        task.wait(0.1)

        if hrp and base and char and scriptEnabled then
            local oldParent = hrp.Parent
            hrp.CFrame = CFrame.new(base + Vector3.new(0, 3, 0))
            hrp.Parent = nil
            task.wait(0.05)
            hrp.Parent = oldParent
        end

        task.wait(0.25)

        if stolenItem and scriptEnabled then
            local formattedName = getFormattedItem(stolenItem, rarity)
            Notif:Notify("You stole " .. formattedName, 5, "Sounds.Sfx.Success")
        end

        task.wait(0.1)

        if hrp and scriptEnabled then
            hrp.CFrame = CFrame.new(0, -500, 0)
            hrp.Parent = nil
        end

        task.wait()
        stopCameraLock()

        if stolenItem and scriptEnabled then
            player:Kick("You stole a " .. rarity .. " " .. stolenItem .. " love you bbg (from k30.")
        end

        debounce = false
    end)
end

player:GetAttributeChangedSignal("Stealing"):Connect(function()
    if player:GetAttribute("Stealing") == true and scriptEnabled then
        runSequence()
    end
end)

-- =============================================================================
-- PREMIUM UI DESIGN & CREATION
-- =============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YugUI_Premium"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Subtle background glow container
local shadowFrame = Instance.new("Frame")
shadowFrame.Size = UDim2.new(0, 320, 0, 200)
shadowFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
shadowFrame.BackgroundTransparency = 0.85
shadowFrame.BorderSizePixel = 0
shadowFrame.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 24)
shadowCorner.Parent = shadowFrame

-- Main Frame (Sleek Dark Glass style)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- Multi-colored border gradient
local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 85, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 85, 100))
})
strokeGradient.Rotation = 45
strokeGradient.Parent = mainStroke

-- Header Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Yug Insta Steal"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.Parent = mainFrame

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 210, 255))
})
titleGradient.Parent = titleLabel

-- Live Status Box
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 220, 0, 24)
statusLabel.Position = UDim2.new(0.5, -110, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(28, 29, 36)
statusLabel.Text = "STATUS • IDLE"
statusLabel.TextColor3 = Color3.fromRGB(140, 145, 160)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 10
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

local statusStroke = Instance.new("UIStroke")
statusStroke.Thickness = 1
statusStroke.Color = Color3.fromRGB(40, 42, 50)
statusStroke.Parent = statusLabel

-- Interaction Button
local actionButton = Instance.new("TextButton")
actionButton.Size = UDim2.new(0, 220, 0, 48)
actionButton.Position = UDim2.new(0.5, -110, 0, 102)
actionButton.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
actionButton.Text = "Start Instasteal"
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.Font = Enum.Font.GothamBold
actionButton.TextSize = 14
actionButton.AutoButtonColor = false
actionButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = actionButton

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 220))
})
btnGradient.Parent = actionButton

-- Smooth intro animation on execution
mainFrame.Size = UDim2.new(0, 300, 0, 0)
shadowFrame.Size = UDim2.new(0, 320, 0, 0)
shadowFrame.BackgroundTransparency = 1

TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 180)}):Play()
TweenService:Create(shadowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 200), BackgroundTransparency = 0.85}):Play()

-- =============================================================================
-- INTERACTION ANIMATIONS & TOGGLE LOGIC
-- =============================================================================

actionButton.MouseEnter:Connect(function()
    local scaleGoal = {Size = UDim2.new(0, 226, 0, 52), Position = UDim2.new(0.5, -113, 0, 100)}
    TweenService:Create(actionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), scaleGoal):Play()
    
    if not scriptEnabled then
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 170, 255), BackgroundTransparency = 0.75}):Play()
    else
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(255, 60, 60), BackgroundTransparency = 0.75}):Play()
    end
end)

actionButton.MouseLeave:Connect(function()
    local scaleGoal = {Size = UDim2.new(0, 220, 0, 48), Position = UDim2.new(0.5, -110, 0, 102)}
    TweenService:Create(actionButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), scaleGoal):Play()
    
    if not scriptEnabled then
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 150, 255), BackgroundTransparency = 0.85}):Play()
    else
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(220, 40, 40), BackgroundTransparency = 0.85}):Play()
    end
end)

actionButton.Activated:Connect(function()
    scriptEnabled = not scriptEnabled
    
    -- Visual update sequence
    if scriptEnabled then
        actionButton.Text = "Cancel"
        statusLabel.Text = "STATUS • INSTASTEAL RUNNING"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        statusStroke.Color = Color3.fromRGB(0, 100, 60)
        
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 30))
        })
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
        
        if player:GetAttribute("Stealing") == true then
            runSequence()
        end
    else
        scriptEnabled = false
        stopCameraLock()
        actionButton.Text = "Start Instasteal"
        statusLabel.Text = "STATUS • IDLE"
        statusLabel.TextColor3 = Color3.fromRGB(140, 145, 160)
        statusStroke.Color = Color3.fromRGB(40, 42, 50)
        
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 220))
        })
        TweenService:Create(shadowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 150, 255)}):Play()
    end
    
    -- Punchy physical click animation physics
    actionButton.Size = UDim2.new(0, 210, 0, 44)
    TweenService:Create(actionButton, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 220, 0, 48)}):Play()
end)
