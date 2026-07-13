local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Toggles = { AntiBat = true, InfJump = true, Draggable = true },
    ToggleKey = Enum.KeyCode.V
}

local function getHRP()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

-- SCREEN SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeathGGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- MAIN GUI
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 185)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -92)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 80)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "death.gg"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Parent = MainFrame

-- LOCK BUTTON
local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(0, 25, 0, 25)
LockBtn.Position = UDim2.new(1, -32, 0, 5)
LockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LockBtn.Text = "🔓"
LockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LockBtn.Font = Enum.Font.GothamBold
LockBtn.TextSize = 14
LockBtn.AutoButtonColor = false
LockBtn.Parent = MainFrame

local LCorner = Instance.new("UICorner")
LCorner.CornerRadius = UDim.new(0, 5)
LCorner.Parent = LockBtn

-- CONTENT AREA
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -45)
Content.Position = UDim2.new(0, 10, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Content

-- ANTI BAT
local AntiBatButton = Instance.new("TextButton")
AntiBatButton.Size = UDim2.new(1, 0, 0, 35)
AntiBatButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AntiBatButton.Font = Enum.Font.GothamBold
AntiBatButton.TextSize = 13
AntiBatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiBatButton.AutoButtonColor = false
AntiBatButton.Parent = Content

local ABCorner = Instance.new("UICorner")
ABCorner.CornerRadius = UDim.new(0, 8)
ABCorner.Parent = AntiBatButton

-- INF JUMP
local InfJumpButton = Instance.new("TextButton")
InfJumpButton.Size = UDim2.new(1, 0, 0, 35)
InfJumpButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfJumpButton.Font = Enum.Font.GothamBold
InfJumpButton.TextSize = 13
InfJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
InfJumpButton.AutoButtonColor = false
InfJumpButton.Parent = Content

local IJCorner = Instance.new("UICorner")
IJCorner.CornerRadius = UDim.new(0, 8)
IJCorner.Parent = InfJumpButton

-- KEYBIND ROW
local Row = Instance.new("Frame")
Row.Size = UDim2.new(1, 0, 0, 25)
Row.BackgroundTransparency = 1
Row.Parent = Content

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(0.4, 0, 1, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "Toggle Key:"
KeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
KeyLabel.Font = Enum.Font.Gotham
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyLabel.Parent = Row

local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Size = UDim2.new(0, 60, 1, 0)
KeybindBtn.Position = UDim2.new(0.5, 0, 0, 0)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeybindBtn.Text = "V"
KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindBtn.Font = Enum.Font.GothamBold
KeybindBtn.TextSize = 12
KeybindBtn.AutoButtonColor = false
KeybindBtn.Parent = Row

local KBCorner = Instance.new("UICorner")
KBCorner.CornerRadius = UDim.new(0, 5)
KBCorner.Parent = KeybindBtn

-- UPDATE VISUALS
local function updateVisuals()
    if CONFIG.Toggles.AntiBat then
        AntiBatButton.Text = "Anti-Bat : ON"
        AntiBatButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    else
        AntiBatButton.Text = "Anti-Bat : OFF"
        AntiBatButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end

    if CONFIG.Toggles.InfJump then
        InfJumpButton.Text = "Inf Jump : ON"
        InfJumpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    else
        InfJumpButton.Text = "Inf Jump : OFF"
        InfJumpButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end

    if CONFIG.Toggles.Draggable then
        LockBtn.Text = "🔓"
    else
        LockBtn.Text = "🔒"
    end
    
    KeybindBtn.Text = CONFIG.ToggleKey.Name
end

-- BUTTON EVENTS
AntiBatButton.MouseButton1Click:Connect(function()
    CONFIG.Toggles.AntiBat = not CONFIG.Toggles.AntiBat
    updateVisuals()
end)

InfJumpButton.MouseButton1Click:Connect(function()
    CONFIG.Toggles.InfJump = not CONFIG.Toggles.InfJump
    updateVisuals()
end)

LockBtn.MouseButton1Click:Connect(function()
    CONFIG.Toggles.Draggable = not CONFIG.Toggles.Draggable
    MainFrame.Draggable = CONFIG.Toggles.Draggable
    updateVisuals()
end)

KeybindBtn.MouseButton1Click:Connect(function()
    KeybindBtn.Text = "..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            CONFIG.ToggleKey = input.KeyCode
            updateVisuals()
            connection:Disconnect()
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.ToggleKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if CONFIG.Toggles.InfJump then
        local hrp = getHRP()
        if hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 40, hrp.Velocity.Z)
        end
    end
end)

-- ANTI BAT
RunService.PostSimulation:Connect(function()
    if CONFIG.Toggles.AntiBat then
        local hrp = getHRP()
        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
                    child:Destroy()
                elseif child:IsA("Velocity") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end)

-- RUN IT
updateVisuals()
