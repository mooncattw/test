-- === TRUBL HUB ===
-- Auto-replace old UI instances
local uiName = "TrublHub_V62_Unified"
local fileName = "TrublHub_Unified_Config.json"
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
if not Player then
    repeat task.wait() until Players.LocalPlayer
    Player = Players.LocalPlayer
end
repeat task.wait() until Player:FindFirstChild("PlayerGui")

for _, oldUI in pairs(Player.PlayerGui:GetChildren()) do
    if oldUI.Name:find("TrublHub") then
        oldUI:Destroy()
    end
end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")



-- ============================================================
-- DATA SAVING
-- ============================================================
_G.Settings = {
    SpeedEnabled = false,
    StealSpeedEnabled = false,
    JumpHeightEnabled = false,
    PlayerESPEnabled = false,
    HeliEnabled = false,
    GravityEnabled = false,
    BatEnabled = false,
    BatFastEnabled = false,
    BatAimEnabled = false,
    BatAimMoveEnabled = false,
    InfJump = false, 
    AntiRagdollV1 = false,
    AntiRagdollV2 = false,
    NoAnimEnabled = false,
    AutoSpeedEnabled = false, 
    AntiLagEnabled = false,
    UIParticlesEnabled = true,
    HeightBoostEnabled = false,
    AutoStealEnabled = false,
    AutoLeftEnabled = false,
    AutoRightEnabled = false,
    AutoLeftMode = "Full",
    AutoRightMode = "Full",
    
    CustomSpeedValue = 50,
    StealSpeedValue = 27, 
    JumpHeightValue = 25, 
    HeliSpeedValue = 50,
    GravityPercent = 70,
    DEFAULT_GRAVITY = 196.2,
    BatRadiusValue = 9,
    HeightBoostValue = 15,
    BatAimMoveSpeed = 55,
    StealRadius = 20,
    StealDuration = 1.3,
    StealStopPercent = 89,
    StealActivateDist = 8,
    EndWaitDelay = 0,
    LEndPos = {x = -484.1, y = -4.95, z = 95.8},
    REndPos = {x = -485, y = -5.09, z = 25.1},
    
    UIOutlineColor = {255, 0, 0},
    
    Keybinds = {}, 
    Pinned = {} 
}

if not _G.Settings.Keybinds["StealSpeedEnabled"] then
    _G.Settings.Keybinds["StealSpeedEnabled"] = "L"
end

-- ============================================================
-- DECLARE EARLY so all functions below can reference them
-- ============================================================
local toggleUpdateFunctions = {}
local textToBoolKey = {}
local toggleCallbacks = {}
 
local function Save()
    if writefile then writefile(fileName, HttpService:JSONEncode(_G.Settings)) end
end
 
local function Load()
    if isfile and isfile(fileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success then
            for k, v in pairs(data) do 
                if k == "Keybinds" then
                    for kbKey, kbVal in pairs(v) do _G.Settings.Keybinds[kbKey] = kbVal end
                else
                    _G.Settings[k] = v 
                end
            end
        end
    end
end
Load()

-- ============================================================
-- ANTI-RAGDOLL SYSTEM
-- ============================================================
local S = { LocalPlayer = Player, RunService = RunService, Lighting = game:GetService("Lighting"), Players = Players }
local ANTI_RAGDOLL = {}
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}

local function cacheCharacterData()
    local char = S.LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = {
        character = char, humanoid = hum, root = root,
        originalWalkSpeed = hum.WalkSpeed, originalJumpPower = hum.JumpPower, isFrozen = false
    }
    return true
end

local function disconnectAll()
    for _, conn in ipairs(ragdollConnections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    local ragStates = {[Enum.HumanoidStateType.Physics]=true, [Enum.HumanoidStateType.Ragdoll]=true, [Enum.HumanoidStateType.FallingDown]=true}
    if ragStates[state] then return true end
    local endTime = S.LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            pcall(function() descendant:Destroy() end)
        end
    end
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function() S.LocalPlayer:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    if cachedCharData.humanoid.Health > 0 then cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running) end
    cachedCharData.root.Anchored = false
    cachedCharData.root.AssemblyLinearVelocity = Vector3.zero
    cachedCharData.root.AssemblyAngularVelocity = Vector3.zero
end

local function freezePlayer()
    if not cachedCharData.humanoid or not cachedCharData.root or cachedCharData.isFrozen then return end
    cachedCharData.originalWalkSpeed = cachedCharData.humanoid.WalkSpeed
    cachedCharData.humanoid.WalkSpeed = 0;
    cachedCharData.root.Anchored = true; cachedCharData.isFrozen = true
end

local function unfreezePlayer()
    if not cachedCharData.humanoid or not cachedCharData.root or not cachedCharData.isFrozen then return end
    cachedCharData.humanoid.WalkSpeed = cachedCharData.originalWalkSpeed or 16;
    cachedCharData.root.Anchored = false; cachedCharData.isFrozen = false
end

local function v1Loop()
    while antiRagdollMode == "v1" and cachedCharData.humanoid do
        task.wait()
        if isRagdolled() then removeRagdollConstraints(); forceExitRagdoll() end
    end
end

local function v2Loop()
    while antiRagdollMode == "v2" and cachedCharData.humanoid do
        task.wait()
        if isRagdolled() then freezePlayer() else unfreezePlayer() end
    end
end

local function setupCameraBinding()
    local conn = S.RunService.RenderStepped:Connect(function()
        if antiRagdollMode ~= "v1" then return end
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    table.insert(ragdollConnections, conn)
end

function ANTI_RAGDOLL.Enable(mode)
    ANTI_RAGDOLL.Disable();
    if not cacheCharacterData() then return end
    antiRagdollMode = mode
    local charConn = S.LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if antiRagdollMode and cacheCharacterData() then
            if antiRagdollMode == "v1" then setupCameraBinding(); task.spawn(v1Loop) else task.spawn(v2Loop) end
        end
    end)
    table.insert(ragdollConnections, charConn)
    if mode == "v1" then setupCameraBinding(); task.spawn(v1Loop) else task.spawn(v2Loop) end
end

function ANTI_RAGDOLL.Disable()
    antiRagdollMode = nil; if cachedCharData.isFrozen then unfreezePlayer() end
    disconnectAll(); cachedCharData = {}
end

-- ============================================================
-- ANTI-LAG SYSTEM
-- ============================================================
local function RemoveAccessories(character)
    if not character then return end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChildOfClass("Decal")
        if face then face:Destroy() end
    end
end

local function ApplyAntiLag()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            RemoveAccessories(player.Character)
        end
    end
end

local antiLagConnections = {}

local function EnableAntiLag()
    ApplyAntiLag()
    
    for _, player in pairs(game.Players:GetPlayers()) do
        local conn = player.CharacterAdded:Connect(function(char)
            if _G.Settings.AntiLagEnabled then
                task.wait(0.5)
                RemoveAccessories(char)
            end
        end)
        table.insert(antiLagConnections, conn)
    end
    
    local conn = game.Players.PlayerAdded:Connect(function(player)
        if _G.Settings.AntiLagEnabled then
            player.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                RemoveAccessories(char)
            end)
        end
    end)
    table.insert(antiLagConnections, conn)
end

local function DisableAntiLag()
    for _, conn in pairs(antiLagConnections) do
        if conn then conn:Disconnect() end
    end
    antiLagConnections = {}
end

-- ============================================================
-- UI DESIGN HELPERS
-- ============================================================
local function ApplyDesign(obj, radius, strokeColor, thickness)
    Instance.new("UICorner", obj).CornerRadius = UDim.new(0, radius)
    local stroke = Instance.new("UIStroke", obj)
    stroke.Color = strokeColor
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

-- Add floating red particles to black UI elements
local function AddParticles(obj)
    if not _G.Settings.UIParticlesEnabled then return end
    if obj.BackgroundColor3 == Color3.fromRGB(10, 10, 10) then
        task.spawn(function()
            for i = 1, 60 do
                local ball = Instance.new("Frame", obj)
                ball.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
                ball.Position = UDim2.new(math.random(2, 98) / 100, 0, math.random(2, 98) / 100, 0)
                ball.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ball.BackgroundTransparency = math.random(10, 40) / 100
                ball.BorderSizePixel = 0
                ball.ZIndex = 0
                Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
                
                task.spawn(function()
                    local startX = ball.Position.X.Scale
                    local startY = ball.Position.Y.Scale
                    local phase = math.random() * math.pi * 2
                    local speedMult = 0.3 + math.random() * 0.4
                    
                    while ball.Parent and _G.Settings.UIParticlesEnabled do
                        local t = tick() + phase
                        local newX = startX + math.sin(t * speedMult) * 0.02
                        local newY = startY + math.cos(t * speedMult * 0.8) * 0.015
                        ball.Position = UDim2.new(math.clamp(newX, 0.01, 0.99), 0, math.clamp(newY, 0.01, 0.99), 0)
                        ball.BackgroundTransparency = 0.2 + math.sin(t * 1.5 + phase) * 0.25
                        task.wait(0.03)
                    end
                    
                    if not _G.Settings.UIParticlesEnabled then
                        ball:Destroy()
                    end
                end)
            end
        end)
    end
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui", Player.PlayerGui)
ScreenGui.Name = uiName
ScreenGui.ResetOnSpawn = false 

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local uiScale = isMobile and 0.55 or 1

-- patch new keys onto _G.Settings after Load()
if _G.Settings.OptimizerEnabled == nil then _G.Settings.OptimizerEnabled = false end
if _G.Settings.AntiBeeDiscoEnabled == nil then _G.Settings.AntiBeeDiscoEnabled = false end
if _G.Settings.FreeMoveEnabled == nil then _G.Settings.FreeMoveEnabled = false end
if _G.Settings.FreeMoveUIW == nil then _G.Settings.FreeMoveUIW = 120 end
if _G.Settings.FreeMoveUIH == nil then _G.Settings.FreeMoveUIH = 44 end
if _G.Settings.FreeMoveUIShape == nil then _G.Settings.FreeMoveUIShape = "Pill" end


-- ============================================================
-- STATS + STEAL DISPLAY (combined)
-- ============================================================
local StatsFrame = Instance.new("Frame", ScreenGui)
StatsFrame.Size = UDim2.new(0, 210 * uiScale, 0, 155 * uiScale)
StatsFrame.Position = UDim2.new(0.5, -105 * uiScale, 0, 10)
StatsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
StatsFrame.BackgroundTransparency = 0.5
StatsFrame.BorderSizePixel = 0
ApplyDesign(StatsFrame, 10, Color3.fromRGB(255, 0, 0), 2)
AddParticles(StatsFrame)

-- Title
local StatsTitle = Instance.new("TextLabel", StatsFrame)
StatsTitle.Size = UDim2.new(1, 0, 0, 22 * uiScale)
StatsTitle.Position = UDim2.new(0, 0, 0, 5)
StatsTitle.BackgroundTransparency = 1
StatsTitle.Text = "Trubl Hub"
StatsTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
StatsTitle.TextSize = 18 * uiScale
StatsTitle.Font = Enum.Font.GothamBold
StatsTitle.TextStrokeTransparency = 0.5
StatsTitle.ZIndex = 2

-- FPS
local FPSLabel = Instance.new("TextLabel", StatsFrame)
FPSLabel.Size = UDim2.new(0.5, -5, 0, 18 * uiScale)
FPSLabel.Position = UDim2.new(0, 5, 0, 30 * uiScale)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 0"
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.TextSize = 13 * uiScale
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.ZIndex = 2

-- Ping
local PingLabel = Instance.new("TextLabel", StatsFrame)
PingLabel.Size = UDim2.new(0.5, -5, 0, 18 * uiScale)
PingLabel.Position = UDim2.new(0.5, 0, 0, 30 * uiScale)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: 0ms"
PingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PingLabel.TextSize = 13 * uiScale
PingLabel.Font = Enum.Font.Gotham
PingLabel.TextXAlignment = Enum.TextXAlignment.Right
PingLabel.ZIndex = 2

-- Discord
local DiscordLabel = Instance.new("TextLabel", StatsFrame)
DiscordLabel.Size = UDim2.new(0.65, 0, 0, 18 * uiScale)
DiscordLabel.Position = UDim2.new(0, 5, 0, 52 * uiScale)
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Text = "discord.gg/G2EuSEWT"
DiscordLabel.TextColor3 = Color3.fromRGB(88, 101, 242)
DiscordLabel.TextSize = 12 * uiScale
DiscordLabel.Font = Enum.Font.GothamBold
DiscordLabel.TextXAlignment = Enum.TextXAlignment.Left
DiscordLabel.ZIndex = 2

-- Settings button
local SettingsBtn = Instance.new("TextButton", StatsFrame)
SettingsBtn.Size = UDim2.new(0.3, -5, 0, 18 * uiScale)
SettingsBtn.Position = UDim2.new(0.7, 0, 0, 52 * uiScale)
SettingsBtn.Text = "⚙️"
SettingsBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
SettingsBtn.TextColor3 = Color3.new(1, 1, 1)
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.TextSize = 14 * uiScale
SettingsBtn.ZIndex = 2
ApplyDesign(SettingsBtn, 4, Color3.fromRGB(255, 0, 0), 1)

-- ── Steal progress bar (under discord row) ──────────────────
local pTrack = Instance.new("Frame", StatsFrame)
pTrack.Size = UDim2.new(1, -14 * uiScale, 0, 9 * uiScale)
pTrack.Position = UDim2.new(0, 7 * uiScale, 0, 76 * uiScale)
pTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
pTrack.ZIndex = 2
ApplyDesign(pTrack, 8, Color3.fromRGB(255, 0, 0), 1)

local ProgressBarFill = Instance.new("Frame", pTrack)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.ZIndex = 3
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

-- Status label overlaid on the bar
local ProgressLabel = Instance.new("TextLabel", pTrack)
ProgressLabel.Size = UDim2.new(1, 0, 1, 0)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 8 * uiScale
ProgressLabel.ZIndex = 4

-- ProgressPercentLabel (animated discord text, hidden in bar, kept for logic)
local ProgressPercentLabel = Instance.new("TextLabel", StatsFrame)
ProgressPercentLabel.Size = UDim2.new(0, 1, 0, 1)
ProgressPercentLabel.BackgroundTransparency = 1
ProgressPercentLabel.Text = ""
ProgressPercentLabel.TextTransparency = 1
ProgressPercentLabel.ZIndex = 1

-- ── 3 input boxes row ───────────────────────────────────────
-- Dur box
local DurInput = Instance.new("TextBox", StatsFrame)
DurInput.Size = UDim2.new(0, 58 * uiScale, 0, 22 * uiScale)
DurInput.Position = UDim2.new(0, 7 * uiScale, 0, 91 * uiScale)
DurInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DurInput.Text = tostring(_G.Settings.StealDuration)
DurInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DurInput.Font = Enum.Font.GothamBold
DurInput.TextSize = 11 * uiScale
DurInput.ZIndex = 3
ApplyDesign(DurInput, 5, Color3.fromRGB(255, 0, 0), 1)

DurInput.FocusLost:Connect(function()
    local n = tonumber(DurInput.Text)
    if n then
        _G.Settings.StealDuration = math.clamp(n, 0.05, 30)
        DurInput.Text = tostring(_G.Settings.StealDuration)
        Save()
    else
        DurInput.Text = tostring(_G.Settings.StealDuration)
    end
end)

-- Studs box
local StudsInput = Instance.new("TextBox", StatsFrame)
StudsInput.Size = UDim2.new(0, 58 * uiScale, 0, 22 * uiScale)
StudsInput.Position = UDim2.new(0, 76 * uiScale, 0, 91 * uiScale)
StudsInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
StudsInput.Text = tostring(_G.Settings.StealActivateDist)
StudsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
StudsInput.Font = Enum.Font.GothamBold
StudsInput.TextSize = 11 * uiScale
StudsInput.ZIndex = 3
ApplyDesign(StudsInput, 5, Color3.fromRGB(255, 0, 0), 1)

StudsInput.FocusLost:Connect(function()
    local n = tonumber(StudsInput.Text)
    if n then
        _G.Settings.StealActivateDist = math.clamp(n, 1, 200)
        StudsInput.Text = tostring(_G.Settings.StealActivateDist)
        Save()
    else
        StudsInput.Text = tostring(_G.Settings.StealActivateDist)
    end
end)

-- Wait box
local WaitInput = Instance.new("TextBox", StatsFrame)
WaitInput.Size = UDim2.new(0, 58 * uiScale, 0, 22 * uiScale)
WaitInput.Position = UDim2.new(0, 145 * uiScale, 0, 91 * uiScale)
WaitInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
WaitInput.Text = (_G.Settings.EndWaitDelay == 0) and "" or tostring(_G.Settings.EndWaitDelay)
WaitInput.PlaceholderText = "0"
WaitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WaitInput.Font = Enum.Font.GothamBold
WaitInput.TextSize = 11 * uiScale
WaitInput.ZIndex = 3
ApplyDesign(WaitInput, 5, Color3.fromRGB(255, 0, 0), 1)

WaitInput.FocusLost:Connect(function()
    local n = tonumber(WaitInput.Text)
    if n then
        _G.Settings.EndWaitDelay = math.max(n, 0)
        WaitInput.Text = tostring(_G.Settings.EndWaitDelay)
    else
        _G.Settings.EndWaitDelay = 0
        WaitInput.Text = ""
    end
    Save()
end)

-- ── Labels under inputs ──────────────────────────────────────
local function makeInputLabel(parent, xOff, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(0, 58 * uiScale, 0, 16 * uiScale)
    lbl.Position = UDim2.new(0, xOff * uiScale, 0, 117 * uiScale)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10 * uiScale
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.ZIndex = 2
end

makeInputLabel(StatsFrame, 7,   "Dur")
makeInputLabel(StatsFrame, 76,  "Studs")
makeInputLabel(StatsFrame, 145, "Wait")

-- Keep StealRadiusInput alias for any references
local StealRadiusInput = DurInput
local StealProgressFrame = StatsFrame  -- alias so show/hide calls still work silently

-- FPS Counter
local lastTime = tick()
local frameCount = 0
local fps = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastTime >= 1 then
        fps = frameCount
        frameCount = 0
        lastTime = currentTime
        FPSLabel.Text = "FPS: " .. tostring(fps)
    end
end)

-- Ping Counter
task.spawn(function()
    while true do
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        PingLabel.Text = "Ping: " .. math.floor(ping) .. "ms"
        task.wait(1)
    end
end)

-- ============================================================
-- AUTO STEAL LOGIC
-- ============================================================
local isStealing = false
local stealStartTime = nil
local progressConnection = nil
local StealData = {}

local DISCORD_TEXT = "discord.gg/G2EuSEWT"

local function getDiscordProgress(percent)
    local totalChars = #DISCORD_TEXT
    local adjustedPercent = math.min(percent * 1.5, 100)
    local charsToShow = math.floor((adjustedPercent / 100) * totalChars)
    return string.sub(DISCORD_TEXT, 1, charsToShow)
end

local function ResetProgressBar()
    if ProgressLabel then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
end

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

-- Returns: prompt, dist, name, spawnPart
local function findNearestStealPrompt()
    local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn, ns = nil, math.huge, nil, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist < nd and dist <= _G.Settings.StealRadius then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn, ns = ch, dist, pod.Name, spawn
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn, ns
end

-- ============================================================
-- STEAL ZONE BOXES  (removed)
-- ============================================================
local STEAL_BOXES = {}



local waitingForZone = false

local stealCooldown = false

local function fireSteal(prompt)
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

local function executeSteal(prompt, name)
    if isStealing or stealCooldown then return end
    if not prompt or not prompt.Parent then return end

    isStealing = true
    waitingForZone = false

    pcall(function() prompt.HoldDuration = 0 end)

    local totalDur   = math.max(_G.Settings.StealDuration or 1.3, 0.05)
    local fillStart  = nil  -- set when we enter range and start filling
    local waiting    = true -- true = waiting for range, false = filling

    local function distToNearest()
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return math.huge end
        local pos = root.Position
        local lep = _G.Settings.LEndPos
        local rep = _G.Settings.REndPos
        local dL = (pos - Vector3.new(lep.x, lep.y, lep.z)).Magnitude
        local dR = (pos - Vector3.new(rep.x, rep.y, rep.z)).Magnitude
        return math.min(dL, dR)
    end

    local function inRange()
        return distToNearest() <= (_G.Settings.StealActivateDist or 8)
    end

    -- If already in range, start filling immediately
    if inRange() then
        waiting = false
        fillStart = tick()
    end

    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end

    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then
            if progressConnection then progressConnection:Disconnect() end
            return
        end

        if waiting then
            -- Show pulsing bar and distance while waiting
            local pulse = 0.5 + 0.5 * math.sin(tick() * 6)
            if ProgressBarFill then
                ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, math.floor(pulse * 120), 0)
                ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
            end
            local dist   = distToNearest()
            local needed = _G.Settings.StealActivateDist or 8
            if ProgressLabel then
                ProgressLabel.Text = string.format("%.1f / %d studs", dist, needed)
            end
            if inRange() then
                waiting = false
                fillStart = tick()
                if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
                if ProgressBarFill then ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
            end
        else
            -- In range — fill 0→100%
            local p = math.clamp((tick() - fillStart) / totalDur, 0, 1)
            if ProgressBarFill then
                ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ProgressBarFill.Size = UDim2.new(p, 0, 1, 0)
            end
            if ProgressPercentLabel then
                ProgressPercentLabel.Text = getDiscordProgress(math.floor(p * 100))
            end
            if p >= 1 then
                progressConnection:Disconnect(); progressConnection = nil
                fireSteal(prompt)
                ResetProgressBar()
                if ProgressBarFill then ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
                isStealing = false
                stealCooldown = true
                task.delay(0.15, function() stealCooldown = false end)
            end
        end
    end)
end

local autoStealConnection = nil

local function startAutoSteal()
    if autoStealConnection then return end
    StealProgressFrame.Visible = true
    autoStealConnection = RunService.Heartbeat:Connect(function()
        if not _G.Settings.AutoStealEnabled or isStealing or stealCooldown then return end
        local p, _, n, _ = findNearestStealPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if autoStealConnection then
        autoStealConnection:Disconnect()
        autoStealConnection = nil
    end
    if progressConnection then
        progressConnection:Disconnect()
        progressConnection = nil
    end
    if waitingForZone or isStealing then
        _G.Settings.StealSpeedEnabled = false
        if toggleUpdateFunctions and toggleUpdateFunctions["StealSpeedEnabled"] then
            toggleUpdateFunctions["StealSpeedEnabled"]()
        end
    end
    waitingForZone = false
    isStealing = false
    stealCooldown = false
    ResetProgressBar()
    if ProgressBarFill then ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
    StealProgressFrame.Visible = false
end

-- ============================================================
-- AUTO LEFT / AUTO RIGHT
-- ============================================================

local AL_POS1 = Vector3.new(-476.48, -6.28,  92.73)
local AL_POS2 = Vector3.new(_G.Settings.LEndPos.x, _G.Settings.LEndPos.y, _G.Settings.LEndPos.z)
local AR_POS1 = Vector3.new(-476.16, -6.52,  25.62)
local AR_POS2 = Vector3.new(_G.Settings.REndPos.x, _G.Settings.REndPos.y, _G.Settings.REndPos.z)

local coordESPFolder = Instance.new("Folder", workspace)
coordESPFolder.Name = "TrublHub_CoordESP"

local function makeCoordMarker(pos, label, col)
    local dot = Instance.new("Part", coordESPFolder)
    dot.Anchored = true; dot.CanCollide = false; dot.CastShadow = false
    dot.Material = Enum.Material.Neon; dot.Shape = Enum.PartType.Ball
    dot.Color = col; dot.Size = Vector3.new(1,1,1)
    dot.Position = pos; dot.Transparency = 1

    local bb = Instance.new("BillboardGui", dot)
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,100,0,20)
    bb.StudsOffset = Vector3.new(0,2,0)
    bb.MaxDistance = 300
    bb.Enabled = false

    local tl = Instance.new("TextLabel", bb)
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.Text = label
    tl.TextColor3 = col
    tl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 12
end

makeCoordMarker(AL_POS1, "L1",    Color3.fromRGB(255, 80, 80))
makeCoordMarker(AL_POS2, "L END", Color3.fromRGB(255, 0,  0))
makeCoordMarker(AR_POS1, "R1",    Color3.fromRGB(255,130,130))
makeCoordMarker(AR_POS2, "R END", Color3.fromRGB(200, 0,  0))


local autoWalkConn = nil
local autoRightConn = nil
local autoWalkPhase  = 1
local autoRightPhase = 1

local function faceSouth()
    local c = Player.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, 0, 0)
    local cam = workspace.CurrentCamera
    if cam then
        local p = h.Position
        cam.CFrame = CFrame.new(p.X, p.Y + 5, p.Z - 12) * CFrame.Angles(math.rad(-15), 0, 0)
    end
end

local function faceNorth()
    local c = Player.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, math.rad(180), 0)
    local cam = workspace.CurrentCamera
    if cam then
        local p = h.Position
        cam.CFrame = CFrame.new(p.X, p.Y + 2, p.Z + 12) * CFrame.Angles(0, math.rad(180), 0)
    end
end

local function stopAutoLeft()
    if autoWalkConn then autoWalkConn:Disconnect(); autoWalkConn = nil end
    autoWalkPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    end
end

local function stopAutoRight()
    if autoRightConn then autoRightConn:Disconnect(); autoRightConn = nil end
    autoRightPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    end
end

local AL_PAST_R1 = Vector3.new(AR_POS1.X, AR_POS1.Y, AR_POS1.Z - 10)

local function startAutoLeft()
    stopAutoLeft()
    autoWalkPhase = 1
    autoWalkConn = RunService.Heartbeat:Connect(function()
        if not _G.Settings.AutoLeftEnabled then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local spd = _G.Settings.CustomSpeedValue or 50

        if autoWalkPhase == 1 then
            local dist = (Vector3.new(AL_POS1.X, h.Position.Y, AL_POS1.Z) - h.Position).Magnitude
            if dist < 1 then autoWalkPhase = 2
            else
                local dir = Vector3.new(AL_POS1.X - h.Position.X, 0, AL_POS1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoWalkPhase == 2 then
            local lep = _G.Settings.LEndPos
            local dist = (Vector3.new(lep.x, h.Position.Y, lep.z) - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                autoWalkPhase = 99 -- lock while waiting
                -- Turn ON steal speed when arriving at L END
                _G.Settings.StealSpeedEnabled = true
                if toggleUpdateFunctions and toggleUpdateFunctions["StealSpeedEnabled"] then
                    toggleUpdateFunctions["StealSpeedEnabled"]()
                end
                local delay = tonumber(_G.Settings.EndWaitDelay) or 0
                task.delay(delay, function()
                    if _G.Settings.AutoLeftEnabled then
                        autoWalkPhase = 3
                    end
                end)
            else
                local dir = Vector3.new(lep.x - h.Position.X, 0, lep.z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoWalkPhase == 3 then
            local dist = (Vector3.new(AL_POS1.X, h.Position.Y, AL_POS1.Z) - h.Position).Magnitude
            if dist < 1 then
                if _G.Settings.AutoLeftMode == "Semi" then
                    hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                    _G.Settings.AutoLeftEnabled = false
                    if toggleUpdateFunctions and toggleUpdateFunctions["AutoLeftEnabled"] then toggleUpdateFunctions["AutoLeftEnabled"]() end
                    stopAutoLeft()
                else
                    autoWalkPhase = 4
                end
            else
                local dir = Vector3.new(AL_POS1.X - h.Position.X, 0, AL_POS1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoWalkPhase == 4 then
            local dist = (Vector3.new(AL_PAST_R1.X, h.Position.Y, AL_PAST_R1.Z) - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                _G.Settings.AutoLeftEnabled = false
                if toggleUpdateFunctions and toggleUpdateFunctions["AutoLeftEnabled"] then toggleUpdateFunctions["AutoLeftEnabled"]() end
                stopAutoLeft()
            else
                local dir = Vector3.new(AL_PAST_R1.X - h.Position.X, 0, AL_PAST_R1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        end
    end)
end

local AR_PAST_L1 = Vector3.new(AL_POS1.X, AL_POS1.Y, AL_POS1.Z + 10)

local function startAutoRight()
    stopAutoRight()
    autoRightPhase = 1
    autoRightConn = RunService.Heartbeat:Connect(function()
        if not _G.Settings.AutoRightEnabled then return end
        local c = Player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local spd = _G.Settings.CustomSpeedValue or 50

        if autoRightPhase == 1 then
            local dist = (Vector3.new(AR_POS1.X, h.Position.Y, AR_POS1.Z) - h.Position).Magnitude
            if dist < 1 then autoRightPhase = 2
            else
                local dir = Vector3.new(AR_POS1.X - h.Position.X, 0, AR_POS1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoRightPhase == 2 then
            local rep = _G.Settings.REndPos
            local dist = (Vector3.new(rep.x, h.Position.Y, rep.z) - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                autoRightPhase = 99 -- lock while waiting
                -- Turn ON steal speed when arriving at R END
                _G.Settings.StealSpeedEnabled = true
                if toggleUpdateFunctions and toggleUpdateFunctions["StealSpeedEnabled"] then
                    toggleUpdateFunctions["StealSpeedEnabled"]()
                end
                local delay = tonumber(_G.Settings.EndWaitDelay) or 0
                task.delay(delay, function()
                    if _G.Settings.AutoRightEnabled then
                        autoRightPhase = 3
                    end
                end)
            else
                local dir = Vector3.new(rep.x - h.Position.X, 0, rep.z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoRightPhase == 3 then
            local dist = (Vector3.new(AR_POS1.X, h.Position.Y, AR_POS1.Z) - h.Position).Magnitude
            if dist < 1 then
                if _G.Settings.AutoRightMode == "Semi" then
                    hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                    _G.Settings.AutoRightEnabled = false
                    if toggleUpdateFunctions and toggleUpdateFunctions["AutoRightEnabled"] then toggleUpdateFunctions["AutoRightEnabled"]() end
                    stopAutoRight()
                else
                    autoRightPhase = 4
                end
            else
                local dir = Vector3.new(AR_POS1.X - h.Position.X, 0, AR_POS1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        elseif autoRightPhase == 4 then
            local dist = (Vector3.new(AR_PAST_L1.X, h.Position.Y, AR_PAST_L1.Z) - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false); h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
                _G.Settings.AutoRightEnabled = false
                if toggleUpdateFunctions and toggleUpdateFunctions["AutoRightEnabled"] then toggleUpdateFunctions["AutoRightEnabled"]() end
                stopAutoRight()
            else
                local dir = Vector3.new(AR_PAST_L1.X - h.Position.X, 0, AR_PAST_L1.Z - h.Position.Z).Unit
                hum:Move(dir, false); h.AssemblyLinearVelocity = Vector3.new(dir.X*spd, h.AssemblyLinearVelocity.Y, dir.Z*spd)
            end
        end
    end)
end

-- ============================================================
-- ============================================================
-- ============================================================
-- NOTIFICATION TOAST SYSTEM
-- ============================================================
local function showNotification(msg, color)
    local toast = Instance.new("TextLabel", ScreenGui)
    toast.Size = UDim2.new(0, 260 * uiScale, 0, 32 * uiScale)
    toast.Position = UDim2.new(0.5, -130 * uiScale, 1, -80)
    toast.BackgroundColor3 = color or Color3.fromRGB(180, 0, 0)
    toast.TextColor3 = Color3.new(1,1,1)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 11 * uiScale
    toast.Text = msg
    toast.ZIndex = 20
    toast.BackgroundTransparency = 0
    ApplyDesign(toast, 8, Color3.fromRGB(255,80,80), 1)
    task.spawn(function()
        task.wait(0.1)
        TweenService:Create(toast, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -130 * uiScale, 1, -110)}):Play()
        task.wait(2)
        TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.wait(0.35)
        toast:Destroy()
    end)
end

local COLORS = {Success = Color3.fromRGB(0, 160, 50), Red = Color3.fromRGB(180, 0, 0)}

-- ============================================================
-- SECTION 12: OPTIMIZER MODULE (ULTRA POTATO MODE)
-- ============================================================

local OPTIMIZER = {}
local optimizerThreads = {}
local optimizerConnections = {}
local originalSettings = {}

local function addThread(func)
    local t = task.spawn(func)
    table.insert(optimizerThreads, t)
    return t
end

local function addConnection(conn)
    table.insert(optimizerConnections, conn)
    return conn
end

local function storeOriginalSettings()
    pcall(function()
        originalSettings = {
            qualityLevel = settings().Rendering.QualityLevel,
            meshPartDetailLevel = settings().Rendering.MeshPartDetailLevel,
            globalShadows = S.Lighting.GlobalShadows,
            brightness = S.Lighting.Brightness,
            fogEnd = S.Lighting.FogEnd,
            technology = S.Lighting.Technology,
            environmentDiffuseScale = S.Lighting.EnvironmentDiffuseScale,
            environmentSpecularScale = S.Lighting.EnvironmentSpecularScale,
            decoration = workspace.Terrain.Decoration,
            waterWaveSize = workspace.Terrain.WaterWaveSize,
            waterWaveSpeed = workspace.Terrain.WaterWaveSpeed,
            waterReflectance = workspace.Terrain.WaterReflectance,
            waterTransparency = workspace.Terrain.WaterTransparency,
        }
    end)
end

local PERFORMANCE_FFLAGS = {
    ["DFIntTaskSchedulerTargetFps"] = 999,
    ["FFlagDebugGraphicsPreferVulkan"] = true,
    ["FFlagDebugGraphicsDisableDirect3D11"] = true,
    ["FFlagDebugGraphicsPreferD3D11FL10"] = false,
    ["DFFlagDebugRenderForceTechnologyVoxel"] = true,
    ["FFlagDisablePostFx"] = true,
    ["FIntRenderShadowIntensity"] = 0,
    ["FIntRenderLocalLightUpdatesMax"] = 0,
    ["FIntRenderLocalLightUpdatesMin"] = 0,
    ["DFIntTextureCompositorActiveJobs"] = 1,
    ["DFIntDebugFRMQualityLevelOverride"] = 1,
    ["FFlagFixPlayerCollisionWhenSwimming"] = false,
    ["DFIntMaxInterpolationSubsteps"] = 0,
    ["DFIntS2PhysicsSenderRate"] = 15,
    ["DFIntConnectionMTUSize"] = 1492,
    ["DFIntHttpCurlConnectionCacheSize"] = 134217728,
    ["DFIntCSGLevelOfDetailSwitchingDistance"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL12"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL23"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL34"] = 0,
    ["FFlagEnableInGameMenuChromeABTest3"] = false,
    ["FFlagEnableInGameMenuModernization"] = false,
    ["FFlagEnableReportAbuseMenuRoactABTest2"] = false,
    ["FFlagDisableNewIGMinDUA"] = true,
    ["FFlagEnableAccessoryValidation"] = false,
    ["FFlagEnableV3MenuABTest3"] = false,
    ["FIntRobloxGuiBlurIntensity"] = 0,
    ["DFIntTimestepArbiterThresholdCFLThou"] = 10,
    ["DFIntTextureQualityOverride"] = 1,
    ["DFIntPerformanceControlTextureQualityBestUtility"] = 1,
    ["DFIntTexturePoolSizeMB"] = 64,
    ["DFIntMaxFrameBufferSize"] = 1,
    ["FFlagDebugDisableParticleRendering"] = false,
    ["DFIntParticleMaxCount"] = 100,
    ["FFlagEnableWaterReflections"] = false,
    ["DFIntWaterReflectionQuality"] = 0,
}

local function applyFFlags()
    local success = 0; local failed = 0
    for flag, value in pairs(PERFORMANCE_FFLAGS) do
        local ok = pcall(function() setfflag(flag, tostring(value)) end)
        if ok then success = success + 1 else failed = failed + 1 end
    end
    print(string.format("[Optimizer] Applied %d/%d FFlags", success, success + failed))
end

local function nukeVisualEffects()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") then
                    obj.Enabled = false; obj.Rate = 0; obj:Destroy()
                elseif obj:IsA("Trail") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Beam") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    obj.Enabled = false; obj.Brightness = 0; obj:Destroy()
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Explosion") then
                    obj:Destroy()
                elseif obj:IsA("SpecialMesh") then
                    obj.TextureId = ""
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if not (obj.Name == "face" and obj.Parent and obj.Parent.Name == "Head") then
                        obj.Transparency = 1
                    end
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false; obj.Material = Enum.Material.Plastic
                    if obj.Material == Enum.Material.Glass then obj.Reflectance = 0 end
                end
            end)
        end
    end)
end

function OPTIMIZER.Enable()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then
        warn("[Optimizer] Already running!"); return
    end
    if getgenv then getgenv().OPTIMIZER_ACTIVE = true end
    storeOriginalSettings()
    pcall(applyFFlags)

    pcall(function()
        local rs = settings().Rendering
        rs.QualityLevel = Enum.QualityLevel.Level01
        rs.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        S.Lighting.GlobalShadows = false
        S.Lighting.Brightness = 3
        S.Lighting.FogEnd = 9e9
        S.Lighting.Technology = Enum.Technology.Legacy
        S.Lighting.EnvironmentDiffuseScale = 0
        S.Lighting.EnvironmentSpecularScale = 0
        for _, effect in ipairs(S.Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then pcall(function() effect.Enabled = false; effect:Destroy() end) end
        end
        for _, cls in ipairs({"Atmosphere","BloomEffect","BlurEffect","ColorCorrectionEffect","SunRaysEffect","DepthOfFieldEffect"}) do
            local obj = S.Lighting:FindFirstChildOfClass(cls); if obj then obj:Destroy() end
        end
    end)

    pcall(function()
        local physics = settings().Physics
        physics.AllowSleep = true
        physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Skip
        physics.ThrottleAdjustTime = 0
    end)

    pcall(function()
        workspace.Terrain.WaterWaveSize = 0; workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0; workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.Decoration = false
    end)

    addThread(function() task.wait(1); nukeVisualEffects() end)

    addConnection(workspace.DescendantAdded:Connect(function(obj)
        if not (getgenv and getgenv().OPTIMIZER_ACTIVE) then return end
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or
               obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") or
               obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CastShadow = false; obj.Material = Enum.Material.Plastic
            end
        end)
    end))

    local function optimizeCharacter(char)
        if not char then return end
        task.spawn(function()
            task.wait(0.5)
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if part:IsA("BasePart") then
                            part.CastShadow = false; part.Material = Enum.Material.Plastic; part.Reflectance = 0
                        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                            part:Destroy()
                        elseif part:IsA("PointLight") or part:IsA("SpotLight") or part:IsA("SurfaceLight") then
                            part:Destroy()
                        elseif part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                            part:Destroy()
                        end
                    end)
                end
            end)
        end)
    end

    for _, player in ipairs(S.Players:GetPlayers()) do
        if player.Character then optimizeCharacter(player.Character) end
        addConnection(player.CharacterAdded:Connect(function(char)
            if getgenv and getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end
        end))
    end
    addConnection(S.Players.PlayerAdded:Connect(function(player)
        addConnection(player.CharacterAdded:Connect(function(char)
            if getgenv and getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end
        end))
    end))

    addThread(function()
        while getgenv and getgenv().OPTIMIZER_ACTIVE do
            task.wait(15); pcall(function() collectgarbage("collect") end)
        end
    end)

    pcall(function() setfpscap(999) end)
    pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)

    showNotification("⚡ ULTRA POTATO Optimizer ON", COLORS.Success)
end

function OPTIMIZER.Disable()
    if not (getgenv and getgenv().OPTIMIZER_ACTIVE) then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE = false end
    for _, t in ipairs(optimizerThreads) do pcall(function() task.cancel(t) end) end
    optimizerThreads = {}
    for _, c in ipairs(optimizerConnections) do pcall(function() c:Disconnect() end) end
    optimizerConnections = {}
    pcall(function()
        local o = originalSettings
        if o.qualityLevel then settings().Rendering.QualityLevel = o.qualityLevel end
        if o.meshPartDetailLevel then settings().Rendering.MeshPartDetailLevel = o.meshPartDetailLevel end
        S.Lighting.GlobalShadows = o.globalShadows ~= false
        S.Lighting.Brightness = o.brightness or 1
        S.Lighting.FogEnd = o.fogEnd or 100000
        S.Lighting.Technology = o.technology or Enum.Technology.ShadowMap
        S.Lighting.EnvironmentDiffuseScale = o.environmentDiffuseScale or 1
        S.Lighting.EnvironmentSpecularScale = o.environmentSpecularScale or 1
        workspace.Terrain.WaterWaveSize = o.waterWaveSize or 0.15
        workspace.Terrain.WaterWaveSpeed = o.waterWaveSpeed or 10
        workspace.Terrain.WaterReflectance = o.waterReflectance or 1
        workspace.Terrain.WaterTransparency = o.waterTransparency or 0.3
        workspace.Terrain.Decoration = o.decoration ~= false
    end)
    showNotification("Optimizer Disabled", COLORS.Red)
end

-- ============================================================
-- SECTION 14: ANTI-BEE & ANTI-DISCO (WITH CONTROL PROTECTION)
-- ============================================================

local FOV_MANAGER = { activeCount = 0, conn = nil, forcedFOV = 70 }

function FOV_MANAGER:Start()
    if self.conn then return end
    self.conn = S.RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= self.forcedFOV then cam.FieldOfView = self.forcedFOV end
    end)
end

function FOV_MANAGER:Stop()
    if self.conn then self.conn:Disconnect(); self.conn = nil end
end

function FOV_MANAGER:Push()
    self.activeCount += 1; self:Start()
end

function FOV_MANAGER:Pop()
    if self.activeCount > 0 then self.activeCount -= 1 end
    if self.activeCount == 0 then self:Stop() end
end

local ANTI_BEE_DISCO = {}
local antiBeeDiscoRunning = false
local antiBeeDiscoConnections = {}
local originalMoveFunction = nil
local controlsProtected = false

local BAD_LIGHTING_NAMES = { Blue = true, DiscoEffect = true, BeeBlur = true, ColorCorrection = true }

local function antiBeeDiscoNuke(obj)
    if not obj or not obj.Parent then return end
    if BAD_LIGHTING_NAMES[obj.Name] then pcall(function() obj:Destroy() end) end
end

local function antiBeeDiscoDisconnectAll()
    for _, conn in ipairs(antiBeeDiscoConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    antiBeeDiscoConnections = {}
end

local function protectControls()
    if controlsProtected then return end
    pcall(function()
        local PlayerScripts = S.LocalPlayer.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        if not Controls then return end
        if not originalMoveFunction then originalMoveFunction = Controls.moveFunction end
        local function protectedMoveFunction(self2, moveVector, relativeToCamera)
            if originalMoveFunction then originalMoveFunction(self2, moveVector, relativeToCamera) end
        end
        local controlCheckConn = S.RunService.Heartbeat:Connect(function()
            if not antiBeeDiscoRunning or not _G.Settings.AntiBeeDiscoEnabled then return end
            if Controls.moveFunction ~= protectedMoveFunction then
                Controls.moveFunction = protectedMoveFunction
            end
        end)
        table.insert(antiBeeDiscoConnections, controlCheckConn)
        Controls.moveFunction = protectedMoveFunction
        controlsProtected = true
    end)
end

local function restoreControls()
    if not controlsProtected then return end
    pcall(function()
        local PlayerScripts = S.LocalPlayer.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        if not Controls or not originalMoveFunction then return end
        Controls.moveFunction = originalMoveFunction
        controlsProtected = false
    end)
end

local function blockBuzzingSound()
    pcall(function()
        local PlayerScripts = S.LocalPlayer.PlayerScripts
        local beeScript = PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then buzzing:Stop(); buzzing.Volume = 0 end
        end
    end)
end

function ANTI_BEE_DISCO.Enable()
    if antiBeeDiscoRunning then return end
    antiBeeDiscoRunning = true
    for _, inst in ipairs(S.Lighting:GetDescendants()) do antiBeeDiscoNuke(inst) end
    table.insert(antiBeeDiscoConnections, S.Lighting.DescendantAdded:Connect(function(obj)
        if not antiBeeDiscoRunning or not _G.Settings.AntiBeeDiscoEnabled then return end
        antiBeeDiscoNuke(obj)
    end))
    protectControls()
    table.insert(antiBeeDiscoConnections, S.RunService.Heartbeat:Connect(function()
        if not antiBeeDiscoRunning or not _G.Settings.AntiBeeDiscoEnabled then return end
        blockBuzzingSound()
    end))
    showNotification("🛡 Anti-Bee & Anti-Disco ON", COLORS.Success)
    FOV_MANAGER:Push()
end

function ANTI_BEE_DISCO.Disable()
    if not antiBeeDiscoRunning then return end
    antiBeeDiscoRunning = false
    restoreControls()
    antiBeeDiscoDisconnectAll()
    showNotification("Anti-Bee & Anti-Disco OFF", COLORS.Red)
    FOV_MANAGER:Pop()
end

-- ============================================================
-- FREE MOVE SYSTEM (Noclip + Fly)
-- ============================================================
local freeMoveConn = nil
local freeMoveBodyVel = nil
local freeMoveBodyGyro = nil

local function EnableFreeMove()
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
    end

    if freeMoveBodyVel then freeMoveBodyVel:Destroy() end
    freeMoveBodyVel = Instance.new("BodyVelocity")
    freeMoveBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    freeMoveBodyVel.Velocity = Vector3.zero
    freeMoveBodyVel.Parent = root

    if freeMoveBodyGyro then freeMoveBodyGyro:Destroy() end
    freeMoveBodyGyro = Instance.new("BodyGyro")
    freeMoveBodyGyro.MaxTorque = Vector3.new(1e4, 1e4, 1e4)
    freeMoveBodyGyro.P = 1e4
    freeMoveBodyGyro.D = 100
    freeMoveBodyGyro.CFrame = root.CFrame
    freeMoveBodyGyro.Parent = root

    if freeMoveConn then freeMoveConn:Disconnect() end
    freeMoveConn = RunService.RenderStepped:Connect(function()
        if not _G.Settings.FreeMoveEnabled then return end
        local c = Player.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local spd = 40

        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
            move = move - Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd = spd * 2.5 end

        if freeMoveBodyVel and freeMoveBodyVel.Parent then
            freeMoveBodyVel.Velocity = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
        end
        if freeMoveBodyGyro and freeMoveBodyGyro.Parent then
            freeMoveBodyGyro.CFrame = CFrame.new(r.Position, r.Position + cam.CFrame.LookVector)
        end
    end)
end

local function DisableFreeMove()
    if freeMoveConn then freeMoveConn:Disconnect(); freeMoveConn = nil end
    if freeMoveBodyVel then freeMoveBodyVel:Destroy(); freeMoveBodyVel = nil end
    if freeMoveBodyGyro then freeMoveBodyGyro:Destroy(); freeMoveBodyGyro = nil end
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
        end
    end
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if _G.Settings.FreeMoveEnabled then EnableFreeMove() end
end)

-- ============================================================
-- SETTINGS MENU  (redesigned with collapsible sections)
-- ============================================================
local SettingsMenu = Instance.new("Frame", ScreenGui)
local settingsW = isMobile and 580 * uiScale or 660
local settingsH = isMobile and 460 * uiScale or 480
SettingsMenu.Size = UDim2.new(0, settingsW, 0, settingsH)
SettingsMenu.Position = UDim2.new(0.5, -settingsW/2, 0.5, -settingsH/2)
SettingsMenu.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
SettingsMenu.BackgroundTransparency = 0.45
SettingsMenu.Visible = false
SettingsMenu.Active = true
SettingsMenu.ClipsDescendants = true
ApplyDesign(SettingsMenu, 14, Color3.fromRGB(255, 0, 0), 2)
AddParticles(SettingsMenu)

-- ── Drag support on settings header ──────────────────────────
local SettingsHeader = Instance.new("Frame", SettingsMenu)
SettingsHeader.Size = UDim2.new(1, 0, 0, 38)
SettingsHeader.BackgroundTransparency = 1
SettingsHeader.Active = true

local smDrag, smDragStart, smStartPos = false, nil, nil
SettingsHeader.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        smDrag = true; smDragStart = i.Position; smStartPos = SettingsMenu.Position
    end
end)
SettingsHeader.InputChanged:Connect(function(i)
    if smDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - smDragStart
        SettingsMenu.Position = UDim2.new(smStartPos.X.Scale, smStartPos.X.Offset + d.X, smStartPos.Y.Scale, smStartPos.Y.Offset + d.Y)
    end
end)
SettingsHeader.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then smDrag = false end
end)

local SettingsTitle = Instance.new("TextLabel", SettingsHeader)
SettingsTitle.Size = UDim2.new(1, -80, 1, 0)
SettingsTitle.Position = UDim2.new(0, 14, 0, 0)
SettingsTitle.Text = "⚙  TRUBL HUB  —  SETTINGS"
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
SettingsTitle.TextSize = 14 * uiScale
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.ZIndex = 2
SettingsTitle.TextStrokeTransparency = 0.6

local SettingsCloseBtn = Instance.new("TextButton", SettingsHeader)
SettingsCloseBtn.Size = UDim2.new(0, 30, 0, 28)
SettingsCloseBtn.Position = UDim2.new(1, -36, 0, 5)
SettingsCloseBtn.Text = "✕"
SettingsCloseBtn.Font = Enum.Font.GothamBold
SettingsCloseBtn.TextSize = 14 * uiScale
SettingsCloseBtn.TextColor3 = Color3.new(1, 1, 1)
SettingsCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
SettingsCloseBtn.ZIndex = 3
ApplyDesign(SettingsCloseBtn, 6, Color3.fromRGB(255, 80, 80), 1)

-- Divider under header
local HeaderDivider = Instance.new("Frame", SettingsMenu)
HeaderDivider.Size = UDim2.new(1, -20, 0, 1)
HeaderDivider.Position = UDim2.new(0, 10, 0, 38)
HeaderDivider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
HeaderDivider.BackgroundTransparency = 0.6
HeaderDivider.BorderSizePixel = 0
HeaderDivider.ZIndex = 2

-- ── Left sidebar ──────────────────────────────────────────────
local sidebarW = 125 * uiScale
local SettingsTabHolder = Instance.new("Frame", SettingsMenu)
SettingsTabHolder.Size = UDim2.new(0, sidebarW, 1, -40)
SettingsTabHolder.Position = UDim2.new(0, 0, 0, 40)
SettingsTabHolder.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
SettingsTabHolder.BackgroundTransparency = 0.3
SettingsTabHolder.BorderSizePixel = 0

local tabPadding = Instance.new("UIPadding", SettingsTabHolder)
tabPadding.PaddingTop = UDim.new(0, 10)
tabPadding.PaddingLeft = UDim.new(0, 5)
tabPadding.PaddingRight = UDim.new(0, 5)

local SettingsTabList = Instance.new("UIListLayout", SettingsTabHolder)
SettingsTabList.FillDirection = Enum.FillDirection.Vertical
SettingsTabList.Padding = UDim.new(0, 5)
SettingsTabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Sidebar right-edge divider
local SidebarDivider = Instance.new("Frame", SettingsMenu)
SidebarDivider.Size = UDim2.new(0, 1, 1, -40)
SidebarDivider.Position = UDim2.new(0, sidebarW, 0, 40)
SidebarDivider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SidebarDivider.BackgroundTransparency = 0.6
SidebarDivider.BorderSizePixel = 0
SidebarDivider.ZIndex = 2

-- ── Content area ──────────────────────────────────────────────
local SettingsContent = Instance.new("Frame", SettingsMenu)
SettingsContent.Size = UDim2.new(1, -(sidebarW + 2), 1, -42)
SettingsContent.Position = UDim2.new(0, sidebarW + 2, 0, 42)
SettingsContent.BackgroundTransparency = 1

-- ── Open / close ──────────────────────────────────────────────
local settingsOpen = false
SettingsBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    if settingsOpen then
        SettingsMenu.Visible = true
        SettingsMenu.Size = UDim2.new(0, 0, 0, settingsH)
        SettingsMenu:TweenSize(UDim2.new(0, settingsW, 0, settingsH), "Out", "Quad", 0.28, true)
    else
        SettingsMenu:TweenSize(UDim2.new(0, 0, 0, settingsH), "Out", "Quad", 0.25, true, function()
            SettingsMenu.Visible = false
        end)
    end
end)
SettingsCloseBtn.MouseButton1Click:Connect(function()
    settingsOpen = false
    SettingsMenu:TweenSize(UDim2.new(0, 0, 0, settingsH), "Out", "Quad", 0.25, true, function()
        SettingsMenu.Visible = false
    end)
end)

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local SettingsPages = {}
local SettingsTabButtons = {}

local function CreateSettingsTab(icon, name)
    local Page = Instance.new("ScrollingFrame", SettingsContent)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
    Page.BorderSizePixel = 0
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local padding = Instance.new("UIPadding", Page)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 14)

    local list = Instance.new("UIListLayout", Page)
    list.Padding = UDim.new(0, 6)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local TabBtn = Instance.new("TextButton", SettingsTabHolder)
    TabBtn.Size = UDim2.new(1, 0, 0, 36 * uiScale)
    TabBtn.Text = icon .. "  " .. name
    TabBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TabBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = isMobile and 10 or 11
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    ApplyDesign(TabBtn, 7, Color3.fromRGB(180, 0, 0), 1)

    local tabIndicator = Instance.new("Frame", TabBtn)
    tabIndicator.Size = UDim2.new(0, 3, 1, -8)
    tabIndicator.Position = UDim2.new(0, 2, 0, 4)
    tabIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    tabIndicator.BackgroundTransparency = 1
    tabIndicator.BorderSizePixel = 0
    Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(1, 0)

    TabBtn.MouseButton1Click:Connect(function()
        for n, p in pairs(SettingsPages) do
            local isThis = (n == name)
            p.Visible = isThis
            SettingsTabButtons[n].TextColor3 = isThis and Color3.new(1,1,1) or Color3.fromRGB(140, 140, 140)
            SettingsTabButtons[n].BackgroundColor3 = isThis and Color3.fromRGB(160, 0, 0) or Color3.fromRGB(15, 15, 15)
            local ind = SettingsTabButtons[n]:FindFirstChildOfClass("Frame")
            if ind then ind.BackgroundTransparency = isThis and 0 or 1 end
        end
    end)

    SettingsPages[name] = Page
    SettingsTabButtons[name] = TabBtn
    return Page
end

local MovementPage = CreateSettingsTab("🏃", "Movement")
local CombatPage   = CreateSettingsTab("⚔️", "Combat")
local VisualPage   = CreateSettingsTab("👁", "Visual")
local UtilityPage  = CreateSettingsTab("🔧", "Utility")

-- ============================================================
-- PINNED / QUICK-ACCESS PANEL
-- ============================================================
local DragHeader = Instance.new("Frame", ScreenGui)
DragHeader.Size = UDim2.new(0, 268 * uiScale, 0, 40 * uiScale)
DragHeader.Position = isMobile and UDim2.new(0.5, -134 * uiScale, 0.5, -248 * uiScale) or UDim2.new(1, -288, 0.5, -248)
DragHeader.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DragHeader.BackgroundTransparency = 0.45
DragHeader.Active = true
ApplyDesign(DragHeader, 12, Color3.fromRGB(255, 0, 0), 2)
AddParticles(DragHeader)

local HeaderTitle = Instance.new("TextLabel", DragHeader)
HeaderTitle.Size = UDim2.new(1, -10, 1, 0)
HeaderTitle.Position = UDim2.new(0, 5, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "📌  QUICK ACCESS"
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
HeaderTitle.TextSize = 13 * uiScale
HeaderTitle.TextStrokeTransparency = 0.5
HeaderTitle.ZIndex = 2

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 268 * uiScale, 0, 400 * uiScale)
MainFrame.Position = isMobile and UDim2.new(0.5, -134 * uiScale, 0.5, -204 * uiScale) or UDim2.new(1, -288, 0.5, -204)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BackgroundTransparency = 0.45
MainFrame.Active = true
MainFrame.ClipsDescendants = true
ApplyDesign(MainFrame, 12, Color3.fromRGB(255, 0, 0), 2)
AddParticles(MainFrame)

local PinnedContainer = Instance.new("ScrollingFrame", MainFrame)
PinnedContainer.Size = UDim2.new(1, 0, 1, -10)
PinnedContainer.Position = UDim2.new(0, 0, 0, 10)
PinnedContainer.BackgroundTransparency = 1
PinnedContainer.ScrollBarThickness = 4
PinnedContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
PinnedContainer.BorderSizePixel = 0
PinnedContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
PinnedContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

local PinnedList = Instance.new("UIListLayout", PinnedContainer)
PinnedList.Padding = UDim.new(0, 7)
PinnedList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local pinnedPadding = Instance.new("UIPadding", PinnedContainer)
pinnedPadding.PaddingTop = UDim.new(0, 8)

-- Drag quick access panel
local d, s, headerPos, framePos
DragHeader.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        d = true; s = i.Position; headerPos = DragHeader.Position; framePos = MainFrame.Position
    end
end)
DragHeader.InputChanged:Connect(function(i)
    if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - s
        DragHeader.Position = UDim2.new(headerPos.X.Scale, headerPos.X.Offset + delta.X, headerPos.Y.Scale, headerPos.Y.Offset + delta.Y)
        MainFrame.Position  = UDim2.new(framePos.X.Scale,  framePos.X.Offset  + delta.X, framePos.Y.Scale,  framePos.Y.Offset  + delta.Y)
    end
end)
DragHeader.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end
end)

-- Forward declare
local RebuildPinnedUIClean
local heightBoostTargetY = nil

-- ============================================================
-- FREE MOVE FLOATING BUTTON
-- ============================================================
local FreeMoveUIFrame = Instance.new("Frame", ScreenGui)
FreeMoveUIFrame.Active = true
FreeMoveUIFrame.ZIndex = 10

local function applyFreeMoveShape()
    local w = math.max(40, _G.Settings.FreeMoveUIW or 120)
    local h = math.max(30, _G.Settings.FreeMoveUIH or 44)
    FreeMoveUIFrame.Size = UDim2.new(0, w, 0, h)
    -- Apply corner radius based on shape
    local corner = FreeMoveUIFrame:FindFirstChildOfClass("UICorner")
    if not corner then corner = Instance.new("UICorner", FreeMoveUIFrame) end
    local shape = _G.Settings.FreeMoveUIShape or "Pill"
    if shape == "Circle" then
        local sz = math.min(w, h)
        FreeMoveUIFrame.Size = UDim2.new(0, sz, 0, sz)
        corner.CornerRadius = UDim.new(0.5, 0)
    elseif shape == "Pill" then
        corner.CornerRadius = UDim.new(0.5, 0)
    else -- Rectangle
        corner.CornerRadius = UDim.new(0, 8)
    end
    local stroke = FreeMoveUIFrame:FindFirstChildOfClass("UIStroke")
    if not stroke then stroke = Instance.new("UIStroke", FreeMoveUIFrame); stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end
    stroke.Color = Color3.fromRGB(255, 0, 0); stroke.Thickness = 2
end

-- Position saved; default to bottom-left on screen
local fmDrag, fmDS, fmSP = false, nil, nil
local freeMoveBtn = Instance.new("TextButton", FreeMoveUIFrame)
freeMoveBtn.Size = UDim2.new(1, 0, 1, 0)
freeMoveBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
freeMoveBtn.BackgroundTransparency = 0.3
freeMoveBtn.Font = Enum.Font.GothamBold
freeMoveBtn.TextSize = 11 * uiScale
freeMoveBtn.ZIndex = 11

local function updateFreeMoveBtn()
    local on = _G.Settings.FreeMoveEnabled
    freeMoveBtn.Text = on and "🕹 FLY: ON" or "🕹 FLY: OFF"
    freeMoveBtn.TextColor3 = on and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(180, 180, 180)
    FreeMoveUIFrame.BackgroundColor3 = on and Color3.fromRGB(30, 5, 5) or Color3.fromRGB(10, 10, 10)
end

freeMoveBtn.MouseButton1Click:Connect(function()
    _G.Settings.FreeMoveEnabled = not _G.Settings.FreeMoveEnabled
    if _G.Settings.FreeMoveEnabled then EnableFreeMove() else DisableFreeMove() end
    updateFreeMoveBtn()
    Save()
end)

-- Long-press to drag the floating button
FreeMoveUIFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 or (i.UserInputType == Enum.UserInputType.Touch and i.UserInputType == Enum.UserInputType.Touch) then
        fmDrag = true; fmDS = i.Position; fmSP = FreeMoveUIFrame.Position
    end
end)
FreeMoveUIFrame.InputChanged:Connect(function(i)
    if fmDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - fmDS
        FreeMoveUIFrame.Position = UDim2.new(fmSP.X.Scale, fmSP.X.Offset + delta.X, fmSP.Y.Scale, fmSP.Y.Offset + delta.Y)
    end
end)
FreeMoveUIFrame.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then fmDrag = false end
end)

-- Initialize floating button appearance
FreeMoveUIFrame.Position = UDim2.new(0, 12, 1, -70)
FreeMoveUIFrame.BackgroundTransparency = 0.3
applyFreeMoveShape()
updateFreeMoveBtn()

-- ============================================================
-- COLLAPSIBLE SECTION HELPER  (only use for 3+ item groups)
-- ============================================================
local function AddSection(page, icon, title)
    -- Outer container so header + wrapper stay together in page's UIListLayout
    local container = Instance.new("Frame", page)
    container.Size = UDim2.new(0.97, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.Name = "Section_" .. title

    local clist = Instance.new("UIListLayout", container)
    clist.Padding = UDim.new(0, 0)
    clist.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Header row: icon + title on left, ▼ collapse btn on right
    local headerRow = Instance.new("Frame", container)
    headerRow.Size = UDim2.new(1, 0, 0, 26 * uiScale)
    headerRow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    headerRow.BorderSizePixel = 0
    Instance.new("UICorner", headerRow).CornerRadius = UDim.new(0, 6)
    local hStroke = Instance.new("UIStroke", headerRow)
    hStroke.Color = Color3.fromRGB(200, 0, 0); hStroke.Thickness = 1
    hStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local headerLabel = Instance.new("TextLabel", headerRow)
    headerLabel.Size = UDim2.new(1, -30, 1, 0)
    headerLabel.Position = UDim2.new(0, 8, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = icon .. "  " .. string.upper(title)
    headerLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 10 * uiScale
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.ZIndex = 2

    -- Small collapse button overlaid on the right of the header
    local collapseBtn = Instance.new("TextButton", headerRow)
    collapseBtn.Size = UDim2.new(0, 26 * uiScale, 0, 22 * uiScale)
    collapseBtn.Position = UDim2.new(1, -28 * uiScale, 0.5, -11 * uiScale)
    collapseBtn.Text = "▼"
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 9 * uiScale
    collapseBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(35, 0, 0)
    collapseBtn.ZIndex = 3
    ApplyDesign(collapseBtn, 4, Color3.fromRGB(255, 0, 0), 1)

    -- Content wrapper
    local wrapper = Instance.new("Frame", container)
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.BackgroundTransparency = 1
    wrapper.ClipsDescendants = true
    wrapper.Name = "SectionWrapper_" .. title

    local wlist = Instance.new("UIListLayout", wrapper)
    wlist.Padding = UDim.new(0, 5)
    wlist.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local wpad = Instance.new("UIPadding", wrapper)
    wpad.PaddingTop = UDim.new(0, 4)
    wpad.PaddingBottom = UDim.new(0, 4)

    local isOpen = true
    local function toggleCollapse()
        isOpen = not isOpen
        if isOpen then
            wrapper.AutomaticSize = Enum.AutomaticSize.Y
            collapseBtn.Text = "▼"
        else
            wrapper.AutomaticSize = Enum.AutomaticSize.None
            wrapper.Size = UDim2.new(1, 0, 0, 0)
            collapseBtn.Text = "▶"
        end
    end

    collapseBtn.MouseButton1Click:Connect(toggleCollapse)
    headerRow.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            toggleCollapse()
        end
    end)

    return wrapper
end

-- ============================================================
-- TOGGLE SYSTEM
-- ============================================================
local function AddToggle(parent, text, boolKey, numKey, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -4, 0, 36 * uiScale)
    frame.BackgroundTransparency = 1
    frame.Name = text

    local pin = Instance.new("TextButton", frame)
    pin.Name = "PinButton"
    pin.Size = UDim2.new(0, 28 * uiScale, 0, 36 * uiScale)
    pin.Position = UDim2.new(0, 0, 0, 0)
    pin.Text = "📌"
    pin.TextSize = 12 * uiScale
    pin.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    pin.TextColor3 = Color3.new(1,1,1)
    ApplyDesign(pin, 5, Color3.fromRGB(255, 0, 0), 1)

    local keyBox = Instance.new("TextButton", frame)
    keyBox.Name = "KeyBind"
    keyBox.Size = UDim2.new(0, 32 * uiScale, 0, 36 * uiScale)
    keyBox.Position = UDim2.new(1, -32 * uiScale, 0, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    keyBox.TextColor3 = Color3.new(1,1,0)
    keyBox.Text = ""
    keyBox.Font = Enum.Font.GothamBold
    keyBox.TextSize = 9 * uiScale
    keyBox.TextScaled = false
    ApplyDesign(keyBox, 5, Color3.fromRGB(255, 0, 0), 1)

    local valBox = nil
    local btnWidthAdjust = 32 * uiScale

    if numKey then
        valBox = Instance.new("TextBox", frame)
        valBox.Name = "ValueInput"
        valBox.Size = UDim2.new(0, 48 * uiScale, 0, 36 * uiScale)
        valBox.Position = UDim2.new(1, -84 * uiScale, 0, 0)
        valBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        valBox.TextColor3 = Color3.new(0,1,1)
        valBox.Text = tostring(_G.Settings[numKey])
        valBox.TextSize = 10 * uiScale
        valBox.Font = Enum.Font.GothamBold
        ApplyDesign(valBox, 5, Color3.fromRGB(255, 0, 0), 1)
        btnWidthAdjust = 88 * uiScale
    end

    local btn = Instance.new("TextButton", frame)
    btn.Name = "TextButton"
    btn.Size = UDim2.new(1, -(28 * uiScale + 4 + btnWidthAdjust), 0, 36 * uiScale)
    btn.Position = UDim2.new(0, 30 * uiScale, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10 * uiScale
    btn.TextColor3 = Color3.new(1,1,1)
    ApplyDesign(btn, 6, Color3.fromRGB(255, 0, 0), 1)

    -- Special: NoAnim button never changes color
    local isNoAnimBtn = (boolKey == "NoAnimEnabled")

    local function updateUI()
        local state = _G.Settings[boolKey]
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        -- NoAnim stays dark always; other toggles go red when ON
        if not isNoAnimBtn then
            btn.BackgroundColor3 = state and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(18, 18, 18)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        end

        local isPinned = table.find(_G.Settings.Pinned, text)
        if isPinned then
            pin.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            pin.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            pin.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            pin.TextColor3 = Color3.fromRGB(150, 150, 150)
        end

        local kb = _G.Settings.Keybinds[boolKey]
        if kb then
            local dn = kb
            if kb:find("MouseButton") then dn = kb:gsub("MouseButton","M")
            elseif kb == "LeftShift" or kb == "RightShift" then dn = "Shft"
            elseif kb == "LeftControl" or kb == "RightControl" then dn = "Ctrl"
            elseif kb == "LeftAlt" or kb == "RightAlt" then dn = "Alt"
            elseif kb:len() > 5 then dn = kb:sub(1,5) end
            keyBox.Text = dn
        else
            keyBox.Text = ""
        end

        local pinnedClone = PinnedContainer:FindFirstChild(text)
        if pinnedClone and pinnedClone:FindFirstChild("TextButton") then
            pinnedClone.TextButton.Text = text .. ": " .. (state and "ON" or "OFF")
            if not isNoAnimBtn then
                pinnedClone.TextButton.BackgroundColor3 = state and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(10, 10, 10)
            end
            if pinnedClone:FindFirstChild("KeyBind") then pinnedClone.KeyBind.Text = keyBox.Text end
            if numKey and pinnedClone:FindFirstChild("ValueInput") then
                pinnedClone.ValueInput.Text = tostring(_G.Settings[numKey])
            end
        end
    end

    toggleUpdateFunctions[boolKey] = updateUI
    textToBoolKey[text] = boolKey
    if callback then toggleCallbacks[boolKey] = callback end

    btn.MouseButton1Click:Connect(function()
        _G.Settings[boolKey] = not _G.Settings[boolKey]
        if callback then callback(_G.Settings[boolKey]) end
        updateUI(); Save()
    end)

    pin.MouseButton1Click:Connect(function()
        local idx = table.find(_G.Settings.Pinned, text)
        if idx then table.remove(_G.Settings.Pinned, idx) else table.insert(_G.Settings.Pinned, text) end
        updateUI(); RebuildPinnedUIClean(); Save()
    end)

    local listeningForKey = false
    local keyInputConnection = nil

    keyBox.MouseButton1Click:Connect(function()
        if not listeningForKey and _G.Settings.Keybinds[boolKey] then
            _G.Settings.Keybinds[boolKey] = nil; keyBox.Text = ""; keyBox.BackgroundColor3 = Color3.fromRGB(10,10,10)
            local pc = PinnedContainer:FindFirstChild(text)
            if pc and pc:FindFirstChild("KeyBind") then pc.KeyBind.Text = "" end
            Save(); return
        end
        if listeningForKey then return end
        listeningForKey = true; keyBox.Text = "..."; keyBox.BackgroundColor3 = Color3.fromRGB(180,0,0)
        if keyInputConnection then keyInputConnection:Disconnect() end
        keyInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not listeningForKey then return end
            local validInput = false; local keyName = ""
            if input.UserInputType == Enum.UserInputType.Keyboard then validInput = true; keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then validInput = true; keyName = "MouseButton1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then validInput = true; keyName = "MouseButton2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then validInput = true; keyName = "MouseButton3"
            end
            if validInput then
                listeningForKey = false; keyInputConnection:Disconnect(); keyInputConnection = nil
                _G.Settings.Keybinds[boolKey] = keyName
                local dn = keyName
                if keyName:find("MouseButton") then dn = keyName:gsub("MouseButton","M")
                elseif keyName:len() > 5 then dn = keyName:sub(1,5) end
                keyBox.Text = dn; keyBox.BackgroundColor3 = Color3.fromRGB(10,10,10)
                local pc = PinnedContainer:FindFirstChild(text)
                if pc and pc:FindFirstChild("KeyBind") then pc.KeyBind.Text = dn end
                Save()
            end
        end)
    end)

    if numKey and valBox then
        valBox.FocusLost:Connect(function()
            local num = tonumber(valBox.Text)
            if num then _G.Settings[numKey] = num; valBox.Text = tostring(num)
            else valBox.Text = tostring(_G.Settings[numKey]) end
            Save()
        end)
    end

    if table.find(_G.Settings.Pinned, text) then
        local clone = frame:Clone(); clone.Parent = PinnedContainer
        if clone:FindFirstChild("PinButton") then clone.PinButton:Destroy() end
        clone.TextButton.Position = UDim2.new(0, 5 * uiScale, 0, 0)
        clone.TextButton.Size = UDim2.new(1, -(10 * uiScale + btnWidthAdjust), 0, 36 * uiScale)
        local state = _G.Settings[boolKey]
        clone.TextButton.Text = text .. ": " .. (state and "ON" or "OFF")
        clone.TextButton.BackgroundColor3 = state and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(25, 25, 25)
        local kb = _G.Settings.Keybinds[boolKey]; clone.KeyBind.Text = kb or ""
        if numKey and clone:FindFirstChild("ValueInput") then clone.ValueInput.Text = tostring(_G.Settings[numKey]) end

        clone.TextButton.MouseButton1Click:Connect(function()
            _G.Settings[boolKey] = not _G.Settings[boolKey]
            if callback then callback(_G.Settings[boolKey]) end
            updateUI(); Save()
        end)
        local c2L = false; local c2C = nil
        clone.KeyBind.MouseButton1Click:Connect(function()
            if not c2L and _G.Settings.Keybinds[boolKey] then
                _G.Settings.Keybinds[boolKey] = nil; clone.KeyBind.Text = ""; clone.KeyBind.BackgroundColor3 = Color3.fromRGB(10,10,10); updateUI(); Save(); return
            end
            if c2L then return end; c2L = true; clone.KeyBind.Text = "..."; clone.KeyBind.BackgroundColor3 = Color3.fromRGB(180,0,0)
            if c2C then c2C:Disconnect() end
            c2C = UserInputService.InputBegan:Connect(function(input, gp)
                if not c2L then return end
                local vi = false; local kn = ""
                if input.UserInputType == Enum.UserInputType.Keyboard then vi=true; kn=input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then vi=true; kn="MouseButton1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then vi=true; kn="MouseButton2"
                elseif input.UserInputType == Enum.UserInputType.MouseButton3 then vi=true; kn="MouseButton3"
                end
                if vi then
                    c2L=false; c2C:Disconnect(); c2C=nil
                    _G.Settings.Keybinds[boolKey] = kn
                    local dn = kn
                    if kn:find("MouseButton") then dn=kn:gsub("MouseButton","M") elseif kn:len()>5 then dn=kn:sub(1,5) end
                    clone.KeyBind.Text = dn; clone.KeyBind.BackgroundColor3 = Color3.fromRGB(10,10,10); updateUI(); Save()
                end
            end)
        end)
        if numKey then
            clone.ValueInput.FocusLost:Connect(function()
                local num = tonumber(clone.ValueInput.Text)
                if num then _G.Settings[numKey] = num; clone.ValueInput.Text = tostring(num); valBox.Text = tostring(num)
                else clone.ValueInput.Text = tostring(_G.Settings[numKey]) end
                Save()
            end)
        end
    end

    updateUI(); return frame
end

-- ============================================================
-- PLAYER ESP SYSTEM (Highlight with Particles)
-- ============================================================
local espHighlights = {}
local espParticles = {}

local function createESPParticles(character)
    if not _G.Settings.PlayerESPEnabled then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:find("Torso") or part.Name:find("Head") or part.Name:find("Arm") or part.Name:find("Leg")) then
            for i = 1, 10 do
                local particle = Instance.new("Part")
                particle.Size = Vector3.new(0.15, 0.15, 0.15)
                particle.Shape = Enum.PartType.Ball
                particle.Material = Enum.Material.Neon
                particle.Color = Color3.fromRGB(255, 0, 0)
                particle.Transparency = math.random(20, 50) / 100
                particle.CanCollide = false
                particle.Anchored = true
                particle.CastShadow = false
                particle.Parent = part
                
                local offset = Vector3.new(
                    (math.random() - 0.5) * part.Size.X,
                    (math.random() - 0.5) * part.Size.Y,
                    (math.random() - 0.5) * part.Size.Z
                )
                
                table.insert(espParticles, {part = particle, bodyPart = part, offset = offset, phase = math.random() * math.pi * 2})
            end
        end
    end
end

local function removeESPParticles(character)
    for i = #espParticles, 1, -1 do
        local data = espParticles[i]
        if data.bodyPart and data.bodyPart:IsDescendantOf(character) then
            if data.part then data.part:Destroy() end
            table.remove(espParticles, i)
        end
    end
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local char = player.Character
            
            if _G.Settings.PlayerESPEnabled then
                if not espHighlights[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.FillColor = Color3.fromRGB(0, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Adornee = char
                    highlight.Parent = char
                    espHighlights[player] = highlight
                    
                    createESPParticles(char)
                end
            else
                if espHighlights[player] then
                    espHighlights[player]:Destroy()
                    espHighlights[player] = nil
                end
                removeESPParticles(char)
            end
        end
    end
    
    for player, highlight in pairs(espHighlights) do
        if not player.Parent or not player.Character then
            highlight:Destroy()
            espHighlights[player] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    if _G.Settings.PlayerESPEnabled then
        for _, data in pairs(espParticles) do
            if data.part and data.bodyPart and data.bodyPart.Parent then
                local t = tick() + data.phase
                local wobble = Vector3.new(
                    math.sin(t * 0.5) * 0.3,
                    math.cos(t * 0.4) * 0.3,
                    math.sin(t * 0.6) * 0.3
                )
                data.part.CFrame = data.bodyPart.CFrame * CFrame.new(data.offset + wobble)
                data.part.Transparency = 0.3 + math.sin(t * 1.5) * 0.2
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if _G.Settings.PlayerESPEnabled then
        updateESP()
    else
        for player, highlight in pairs(espHighlights) do
            highlight:Destroy()
        end
        espHighlights = {}
        for _, data in pairs(espParticles) do
            if data.part then data.part:Destroy() end
        end
        espParticles = {}
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if _G.Settings.PlayerESPEnabled then
            updateESP()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

-- ============================================================
-- BAT AIM HELPER FUNCTION
-- ============================================================
local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

-- ============================================================
-- ADVANCED GRAVITY SYSTEM
-- ============================================================
local galaxyVectorForce = nil
local galaxyAttachment = nil
local originalJumpPower = 50

local function captureJumpPower()
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower > 0 then
            originalJumpPower = hum.JumpPower
        end
    end
end

task.spawn(function()
    task.wait(1)
    captureJumpPower()
end)

Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    captureJumpPower()
end)

local function setupGravityForce()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment then galaxyAttachment:Destroy() end
        galaxyAttachment = Instance.new("Attachment")
        galaxyAttachment.Parent = h
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0, 0, 0)
        galaxyVectorForce.Parent = h
    end)
end

local function updateGravityForce()
    if not _G.Settings.GravityEnabled or not galaxyVectorForce then return end
    local c = Player.Character
    if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            mass = mass + p:GetMass()
        end
    end
    local tg = _G.Settings.DEFAULT_GRAVITY * (_G.Settings.GravityPercent / 100)
    galaxyVectorForce.Force = Vector3.new(0, mass * (_G.Settings.DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function adjustGravityJump()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if not _G.Settings.GravityEnabled then
            hum.JumpPower = originalJumpPower
            return
        end
        local ratio = math.sqrt((_G.Settings.DEFAULT_GRAVITY * (_G.Settings.GravityPercent / 100)) / _G.Settings.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower * ratio
    end)
end


-- ============================================================
-- NO ANIM SYSTEM
-- ============================================================
local noAnimTracks = {}

local function DisableAnimations()
    local char = Player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
            table.insert(noAnimTracks, track)
        end
    end
    -- Disable the Animate script so it doesn't restart animations
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Enabled = false end
end

local function EnableAnimations()
    local char = Player.Character
    if not char then return end
    local animScript = char:FindFirstChild("Animate")
    if animScript then animScript.Enabled = true end
    noAnimTracks = {}
end

local noAnimCharConn = nil

local function StartNoAnim()
    DisableAnimations()
    if noAnimCharConn then noAnimCharConn:Disconnect() end
    noAnimCharConn = Player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if _G.Settings.NoAnimEnabled then DisableAnimations() end
    end)
    -- Keep killing any new tracks that sneak in
    RunService.Heartbeat:Connect(function()
        if not _G.Settings.NoAnimEnabled then return end
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if anim then
            for _, track in pairs(anim:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
    end)
end

local function StopNoAnim()
    if noAnimCharConn then noAnimCharConn:Disconnect(); noAnimCharConn = nil end
    EnableAnimations()
end
-- ============================================================
-- MODE BUTTON HELPER
-- ============================================================
local function AddModeButton(parent, modeKey, label)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -4, 0, 28 * uiScale)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.52, 0, 1, 0)
    lbl.Position = UDim2.new(0, 30 * uiScale, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "└  " .. label .. ":"
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9 * uiScale
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.42, 0, 1, 0)
    btn.Position = UDim2.new(0.55, 0, 0, 0)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9 * uiScale; btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = _G.Settings[modeKey] or "Full"
    btn.BackgroundColor3 = (_G.Settings[modeKey] == "Semi") and Color3.fromRGB(180,80,0) or Color3.fromRGB(180,0,0)
    ApplyDesign(btn, 5, Color3.fromRGB(255,0,0), 1)
    btn.MouseButton1Click:Connect(function()
        local current = _G.Settings[modeKey] or "Full"
        _G.Settings[modeKey] = (current == "Full") and "Semi" or "Full"
        btn.Text = _G.Settings[modeKey]
        btn.BackgroundColor3 = (_G.Settings[modeKey] == "Semi") and Color3.fromRGB(180,80,0) or Color3.fromRGB(180,0,0)
        Save()
    end)
end

-- ============================================================
-- MOVEMENT TAB  — sections only for larger groups
-- ============================================================
local SpeedSection = AddSection(MovementPage, "⚡", "Speed")
AddToggle(SpeedSection, "Speed Boost",  "SpeedEnabled",      "CustomSpeedValue")
AddToggle(SpeedSection, "Steal Speed",  "StealSpeedEnabled", "StealSpeedValue")

local autoSpeedAttrConn = nil
local function InitializeAutoSpeed()
    if autoSpeedAttrConn then pcall(function() autoSpeedAttrConn:Disconnect() end); autoSpeedAttrConn = nil end
    local lastStealing = nil
    autoSpeedAttrConn = RunService.Heartbeat:Connect(function()
        if not _G.Settings.AutoSpeedEnabled then return end
        local val = Player:GetAttribute("Stealing")
        local isStealingAttr = val and true or false
        if isStealingAttr ~= lastStealing then
            lastStealing = isStealingAttr
            _G.Settings.SpeedEnabled = true; _G.Settings.StealSpeedEnabled = isStealingAttr
            if toggleUpdateFunctions["SpeedEnabled"] then toggleUpdateFunctions["SpeedEnabled"]() end
            if toggleUpdateFunctions["StealSpeedEnabled"] then toggleUpdateFunctions["StealSpeedEnabled"]() end
            if toggleUpdateFunctions["AutoSpeedEnabled"] then toggleUpdateFunctions["AutoSpeedEnabled"]() end
            Save()
        end
        if not _G.Settings.SpeedEnabled then
            _G.Settings.SpeedEnabled = true
            if toggleUpdateFunctions["SpeedEnabled"] then toggleUpdateFunctions["SpeedEnabled"]() end
        end
    end)
    local current = Player:GetAttribute("Stealing")
    lastStealing = current and true or false
    _G.Settings.SpeedEnabled = true; _G.Settings.StealSpeedEnabled = lastStealing
    if toggleUpdateFunctions["SpeedEnabled"] then toggleUpdateFunctions["SpeedEnabled"]() end
    if toggleUpdateFunctions["StealSpeedEnabled"] then toggleUpdateFunctions["StealSpeedEnabled"]() end
    if toggleUpdateFunctions["AutoSpeedEnabled"] then toggleUpdateFunctions["AutoSpeedEnabled"]() end
    Save()
end

AddToggle(SpeedSection, "Auto Speed", "AutoSpeedEnabled", nil, function(enabled)
    if enabled then InitializeAutoSpeed()
    else if autoSpeedAttrConn then pcall(function() autoSpeedAttrConn:Disconnect() end); autoSpeedAttrConn = nil end end
end)

local AerialSection = AddSection(MovementPage, "🚁", "Aerial")
AddToggle(AerialSection, "Helicopter",     "HeliEnabled",       "HeliSpeedValue")
AddToggle(AerialSection, "Jump Boost",     "JumpHeightEnabled", "JumpHeightValue")
AddToggle(AerialSection, "Gravity",        "GravityEnabled",    "GravityPercent", function(enabled)
    if enabled then setupGravityForce(); adjustGravityJump() end
end)
AddToggle(AerialSection, "Infinite Jump",  "InfJump")

local function EnableHeightBoost()
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Blacklist; rp.FilterDescendantsInstances = {char}
    local rr = workspace:Raycast(root.Position, Vector3.new(0,-200,0), rp)
    heightBoostTargetY = (rr and rr.Position.Y or (root.Position.Y - 3.1)) + _G.Settings.HeightBoostValue
end
local function DisableHeightBoost()
    heightBoostTargetY = nil
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -80, root.AssemblyLinearVelocity.Z) end
end

AddToggle(AerialSection, "Height Boost", "HeightBoostEnabled", "HeightBoostValue", function(enabled)
    if enabled then EnableHeightBoost() else DisableHeightBoost() end
end)

local AutoWalkSection = AddSection(MovementPage, "🤖", "Auto Walk")
AddToggle(AutoWalkSection, "Auto Left", "AutoLeftEnabled", nil, function(enabled)
    if enabled then startAutoLeft() else stopAutoLeft() end
end)
AddModeButton(AutoWalkSection, "AutoLeftMode", "L Mode")
AddToggle(AutoWalkSection, "Auto Right", "AutoRightEnabled", nil, function(enabled)
    if enabled then startAutoRight() else stopAutoRight() end
end)
AddModeButton(AutoWalkSection, "AutoRightMode", "R Mode")

-- ============================================================
-- COMBAT TAB  — no section wrappers (not enough items)
-- ============================================================
AddToggle(CombatPage, "Smart Bat",   "BatEnabled",      "BatRadiusValue")
AddToggle(CombatPage, "Fast Bat",    "BatFastEnabled")
AddToggle(CombatPage, "Bat Aim",     "BatAimEnabled")

-- BatAimMove: block player movement input while active
local batMoveLockedSpeed = nil
local batAimWasOnBeforeMove = false
AddToggle(CombatPage, "  └ Move to Target", "BatAimMoveEnabled", "BatAimMoveSpeed", function(enabled)
    if enabled then
        batAimWasOnBeforeMove = _G.Settings.BatAimEnabled
        _G.Settings.BatAimEnabled = true
        if toggleUpdateFunctions["BatAimEnabled"] then toggleUpdateFunctions["BatAimEnabled"]() end
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bat = Player.Backpack:FindFirstChild("Bat") or (char and char:FindFirstChild("Bat"))
        if hum and bat then hum:EquipTool(bat) end
        -- Lock player movement so they can't interfere
        if hum then batMoveLockedSpeed = hum.WalkSpeed; hum.WalkSpeed = 0 end
    else
        -- Restore movement
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and batMoveLockedSpeed then hum.WalkSpeed = batMoveLockedSpeed; batMoveLockedSpeed = nil end
        if not batAimWasOnBeforeMove then
            _G.Settings.BatAimEnabled = false
            if toggleUpdateFunctions["BatAimEnabled"] then toggleUpdateFunctions["BatAimEnabled"]() end
        end
    end
end)

AddToggle(CombatPage, "Auto Steal", "AutoStealEnabled", "StealRadius", function(enabled)
    if enabled then startAutoSteal() else stopAutoSteal() end
end)

-- ============================================================
-- VISUAL TAB  — no section wrappers
-- ============================================================
AddToggle(VisualPage, "Player ESP", "PlayerESPEnabled", nil, function(enabled)
    if not enabled then
        for player, highlight in pairs(espHighlights) do highlight:Destroy() end; espHighlights = {}
        for _, data in pairs(espParticles) do if data.part then data.part:Destroy() end end; espParticles = {}
    else updateESP() end
end)
AddToggle(VisualPage, "Anti-Lag", "AntiLagEnabled", nil, function(s)
    if s then EnableAntiLag() else DisableAntiLag() end
end)
AddToggle(VisualPage, "UI Particles", "UIParticlesEnabled", nil, function(s)
    if not s then
        for _, obj in pairs(ScreenGui:GetDescendants()) do
            if obj:IsA("Frame") and obj.Parent and (obj.Size == UDim2.new(0,2,0,2) or obj.Size == UDim2.new(0,3,0,3) or obj.Size == UDim2.new(0,4,0,4)) then
                if obj.BackgroundColor3 == Color3.fromRGB(255,0,0) then obj:Destroy() end
            end
        end
    else
        AddParticles(StatsFrame); AddParticles(SettingsMenu); AddParticles(DragHeader); AddParticles(MainFrame)
    end
end)

-- ============================================================
-- UTILITY TAB  — no section wrappers, includes new features
-- ============================================================
AddToggle(UtilityPage, "Anti-Ragdoll", "AntiRagdollV1", nil, function(s)
    if s then _G.Settings.AntiRagdollV2 = false; if toggleUpdateFunctions["AntiRagdollV2"] then toggleUpdateFunctions["AntiRagdollV2"]() end ANTI_RAGDOLL.Enable("v1")
    else ANTI_RAGDOLL.Disable() end
end)
AddToggle(UtilityPage, "No Anim", "NoAnimEnabled", nil, function(s)
    if s then StartNoAnim() else StopNoAnim() end
end)
AddToggle(UtilityPage, "Optimizer", "OptimizerEnabled", nil, function(s)
    if s then OPTIMIZER.Enable() else OPTIMIZER.Disable() end
end)
AddToggle(UtilityPage, "Anti-Bee & Disco", "AntiBeeDiscoEnabled", nil, function(s)
    if s then ANTI_BEE_DISCO.Enable() else ANTI_BEE_DISCO.Disable() end
end)

-- ── Free Move Button config section ──────────────────────────
-- Small label separator
local fmSepFrame = Instance.new("Frame", UtilityPage)
fmSepFrame.Size = UDim2.new(0.97, 0, 0, 18 * uiScale)
fmSepFrame.BackgroundTransparency = 1
local fmSepLbl = Instance.new("TextLabel", fmSepFrame)
fmSepLbl.Size = UDim2.new(1, 0, 1, 0)
fmSepLbl.BackgroundTransparency = 1
fmSepLbl.Text = "─────  FREE MOVE BUTTON SETTINGS  ─────"
fmSepLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
fmSepLbl.Font = Enum.Font.GothamBold
fmSepLbl.TextSize = 8 * uiScale

-- Width / Height inputs + shape cycle in one row
local fmConfigRow = Instance.new("Frame", UtilityPage)
fmConfigRow.Size = UDim2.new(0.97, 0, 0, 30 * uiScale)
fmConfigRow.BackgroundTransparency = 1

local function makeSmallInput(xOff, lbl, settingKey, minVal, maxVal)
    local container = Instance.new("Frame", fmConfigRow)
    container.Size = UDim2.new(0, 88 * uiScale, 1, 0)
    container.Position = UDim2.new(0, xOff * uiScale, 0, 0)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = lbl
    label.TextColor3 = Color3.fromRGB(160, 160, 160)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9 * uiScale
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(0.52, 0, 0.85, 0)
    box.Position = UDim2.new(0.46, 0, 0.075, 0)
    box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    box.TextColor3 = Color3.fromRGB(0, 220, 220)
    box.Text = tostring(_G.Settings[settingKey])
    box.Font = Enum.Font.GothamBold
    box.TextSize = 9 * uiScale
    ApplyDesign(box, 5, Color3.fromRGB(255,0,0), 1)

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            _G.Settings[settingKey] = math.clamp(n, minVal, maxVal)
            box.Text = tostring(_G.Settings[settingKey])
        else
            box.Text = tostring(_G.Settings[settingKey])
        end
        applyFreeMoveShape()
        Save()
    end)
end

makeSmallInput(0,   "W:",  "FreeMoveUIW",  40, 300)
makeSmallInput(90,  "H:",  "FreeMoveUIH",  30, 200)

local shapeBtn = Instance.new("TextButton", fmConfigRow)
shapeBtn.Size = UDim2.new(0, 68 * uiScale, 0.85, 0)
shapeBtn.Position = UDim2.new(0, 182 * uiScale, 0.075, 0)
shapeBtn.Font = Enum.Font.GothamBold
shapeBtn.TextSize = 9 * uiScale
shapeBtn.TextColor3 = Color3.new(1,1,1)
shapeBtn.Text = (_G.Settings.FreeMoveUIShape or "Pill")
shapeBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
ApplyDesign(shapeBtn, 5, Color3.fromRGB(255,0,0), 1)
shapeBtn.MouseButton1Click:Connect(function()
    local shapes = {"Pill", "Rectangle", "Circle"}
    local cur = _G.Settings.FreeMoveUIShape or "Pill"
    local idx = table.find(shapes, cur) or 1
    local next = shapes[(idx % #shapes) + 1]
    _G.Settings.FreeMoveUIShape = next
    shapeBtn.Text = next
    applyFreeMoveShape()
    Save()
end)

-- ============================================================
-- PRESET BUTTON
-- ============================================================
local sidebarSpacer = Instance.new("Frame", SettingsTabHolder)
sidebarSpacer.Size = UDim2.new(1, 0, 0, 8); sidebarSpacer.BackgroundTransparency = 1

local PresetBtn = Instance.new("TextButton", SettingsTabHolder)
PresetBtn.Size = UDim2.new(1, 0, 0, 38 * uiScale)
PresetBtn.Text = "⚡ Preset"
PresetBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
PresetBtn.TextColor3 = Color3.new(1, 1, 1)
PresetBtn.Font = Enum.Font.GothamBold
PresetBtn.TextSize = isMobile and 10 or 11
PresetBtn.ZIndex = 2
ApplyDesign(PresetBtn, 7, Color3.fromRGB(255, 80, 80), 1)

PresetBtn.MouseButton1Click:Connect(function()
    _G.Settings.SpeedEnabled=true; _G.Settings.CustomSpeedValue=59; _G.Settings.StealSpeedEnabled=false
    _G.Settings.StealSpeedValue=30; _G.Settings.JumpHeightEnabled=false; _G.Settings.JumpHeightValue=30
    _G.Settings.HeliEnabled=false; _G.Settings.HeliSpeedValue=50; _G.Settings.GravityEnabled=false
    _G.Settings.GravityPercent=70; _G.Settings.HeightBoostEnabled=false; _G.Settings.HeightBoostValue=15
    _G.Settings.InfJump=true; _G.Settings.AutoSpeedEnabled=true
    _G.Settings.BatEnabled=true; _G.Settings.BatRadiusValue=5; _G.Settings.BatAimEnabled=true
    _G.Settings.BatFastEnabled=false; _G.Settings.BatAimMoveEnabled=false; _G.Settings.BatAimMoveSpeed=59
    _G.Settings.AutoStealEnabled=true; _G.Settings.StealRadius=20
    _G.Settings.AntiLagEnabled=true; _G.Settings.PlayerESPEnabled=true; _G.Settings.UIParticlesEnabled=false
    _G.Settings.AntiRagdollV1=true; _G.Settings.AntiRagdollV2=false
    _G.Settings.Pinned = {"  └ Move to Target", "Steal Speed"}
    EnableAntiLag(); updateESP(); ANTI_RAGDOLL.Enable("v1"); startAutoSteal()
    for _, fn in pairs(toggleUpdateFunctions) do fn() end
    RebuildPinnedUIClean(); InitializeAutoSpeed()
    PresetBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0); PresetBtn.Text = "✅ Applied!"
    task.delay(1.5, function() PresetBtn.BackgroundColor3 = Color3.fromRGB(180,0,0); PresetBtn.Text = "⚡ Preset" end)
    Save()
end)

-- ============================================================
-- REBUILD PINNED UI
-- ============================================================
RebuildPinnedUIClean = function()
    for _, child in pairs(PinnedContainer:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end

    local allPages = {MovementPage, CombatPage, VisualPage, UtilityPage}

    for _, pinnedName in ipairs(_G.Settings.Pinned) do
        local originalFrame = nil
        for _, page in ipairs(allPages) do
            local found = page:FindFirstChild(pinnedName, true)
            if found then originalFrame = found; break end
        end
        if not originalFrame then continue end

        local boolKey = textToBoolKey[pinnedName]
        if not boolKey then continue end

        local numKey = nil
        local valBoxOrig = originalFrame:FindFirstChild("ValueInput")
        if valBoxOrig then
            for k, v in pairs(_G.Settings) do
                if type(v) == "number" and tostring(v) == valBoxOrig.Text then numKey = k; break end
            end
        end

        local clone = originalFrame:Clone()
        clone.Name = pinnedName; clone.Parent = PinnedContainer
        if clone:FindFirstChild("PinButton") then clone.PinButton:Destroy() end

        local valInput = clone:FindFirstChild("ValueInput")
        local bwa = valInput and (88 * uiScale) or (32 * uiScale)
        local mainBtn = clone:FindFirstChild("TextButton")

        if mainBtn then
            mainBtn.Position = UDim2.new(0, 5 * uiScale, 0, 0)
            mainBtn.Size = UDim2.new(1, -(10 * uiScale + bwa), 0, 36 * uiScale)
            local state = _G.Settings[boolKey]
            mainBtn.Text = pinnedName .. ": " .. (state and "ON" or "OFF")
            mainBtn.BackgroundColor3 = state and Color3.fromRGB(180,0,0) or Color3.fromRGB(25,25,25)
            mainBtn.MouseButton1Click:Connect(function()
                _G.Settings[boolKey] = not _G.Settings[boolKey]
                local cb = toggleCallbacks[boolKey]; if cb then cb(_G.Settings[boolKey]) end
                if toggleUpdateFunctions[boolKey] then toggleUpdateFunctions[boolKey]() end
                Save()
            end)
        end

        local kb = _G.Settings.Keybinds[boolKey]
        local kbb = clone:FindFirstChild("KeyBind")
        if kbb then
            if kb then
                local dn = kb
                if kb:find("MouseButton") then dn = kb:gsub("MouseButton","M") elseif kb:len()>5 then dn=kb:sub(1,5) end
                kbb.Text = dn
            else kbb.Text = "" end
            local cL=false; local cC=nil
            kbb.MouseButton1Click:Connect(function()
                if not cL and _G.Settings.Keybinds[boolKey] then
                    _G.Settings.Keybinds[boolKey]=nil; kbb.Text=""; kbb.BackgroundColor3=Color3.fromRGB(10,10,10)
                    if toggleUpdateFunctions[boolKey] then toggleUpdateFunctions[boolKey]() end; Save(); return
                end
                if cL then return end; cL=true; kbb.Text="..."; kbb.BackgroundColor3=Color3.fromRGB(180,0,0)
                if cC then cC:Disconnect() end
                cC=UserInputService.InputBegan:Connect(function(input)
                    if not cL then return end
                    local vi=false; local kn=""
                    if input.UserInputType==Enum.UserInputType.Keyboard then vi=true; kn=input.KeyCode.Name
                    elseif input.UserInputType==Enum.UserInputType.MouseButton1 then vi=true; kn="MouseButton1"
                    elseif input.UserInputType==Enum.UserInputType.MouseButton2 then vi=true; kn="MouseButton2"
                    elseif input.UserInputType==Enum.UserInputType.MouseButton3 then vi=true; kn="MouseButton3"
                    end
                    if vi then
                        cL=false; cC:Disconnect(); cC=nil; _G.Settings.Keybinds[boolKey]=kn
                        local dn=kn
                        if kn:find("MouseButton") then dn=kn:gsub("MouseButton","M") elseif kn:len()>5 then dn=kn:sub(1,5) end
                        kbb.Text=dn; kbb.BackgroundColor3=Color3.fromRGB(10,10,10)
                        if toggleUpdateFunctions[boolKey] then toggleUpdateFunctions[boolKey]() end; Save()
                    end
                end)
            end)
        end

        if valInput then
            local origVal = originalFrame:FindFirstChild("ValueInput")
            if origVal then valInput.Text = origVal.Text end
            valInput.FocusLost:Connect(function()
                local num = tonumber(valInput.Text)
                if num then
                    if numKey then _G.Settings[numKey] = num end
                    valInput.Text = tostring(num)
                    if toggleUpdateFunctions[boolKey] then toggleUpdateFunctions[boolKey]() end
                else
                    valInput.Text = numKey and tostring(_G.Settings[numKey]) or valInput.Text
                end
                Save()
            end)
        end
    end
end


-- ============================================================
-- RADIUS VISUALIZER
-- ============================================================
local RadiusPart = Instance.new("Part", workspace)
RadiusPart.Name = "RadiusVisual"; RadiusPart.Shape = Enum.PartType.Cylinder; RadiusPart.Color = Color3.new(0,0,0); RadiusPart.Material = Enum.Material.SmoothPlastic; RadiusPart.Transparency = 1; RadiusPart.CanCollide = false; RadiusPart.Anchored = true; RadiusPart.CastShadow = false
local Outline = Instance.new("SelectionPartLasso", RadiusPart)
Outline.Color3 = Color3.fromRGB(255, 0, 0); Outline.Part = RadiusPart

-- ============================================================
-- BAT AIM SETUP (AlignOrientation method)
-- ============================================================
local AlignObj = Instance.new("AlignOrientation")
AlignObj.Mode = Enum.OrientationAlignmentMode.OneAttachment
AlignObj.MaxTorque = math.huge
AlignObj.Responsiveness = 200
AlignObj.Enabled = false
local AimAttachment = Instance.new("Attachment")

-- ============================================================
-- INPUT HANDLING
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    local inputName = ""
    if input.UserInputType == Enum.UserInputType.Keyboard then
        inputName = input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        inputName = "MouseButton1"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        inputName = "MouseButton2"
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        inputName = "MouseButton3"
    end
    
    if inputName == "" then return end
    
    for boolKey, bindKey in pairs(_G.Settings.Keybinds) do
        if inputName == bindKey then
            _G.Settings[boolKey] = not _G.Settings[boolKey]
            if boolKey == "AntiRagdollV1" then 
                if _G.Settings.AntiRagdollV1 then ANTI_RAGDOLL.Enable("v1") else ANTI_RAGDOLL.Disable() end
            elseif boolKey == "AntiRagdollV2" then 
                if _G.Settings.AntiRagdollV2 then ANTI_RAGDOLL.Enable("v2") else ANTI_RAGDOLL.Disable() end 
            elseif boolKey == "AntiLagEnabled" then
                if _G.Settings.AntiLagEnabled then EnableAntiLag() else DisableAntiLag() end
            elseif boolKey == "AutoStealEnabled" then
                if _G.Settings.AutoStealEnabled then startAutoSteal() else stopAutoSteal() end
            elseif boolKey == "HeightBoostEnabled" then
                if _G.Settings.HeightBoostEnabled then EnableHeightBoost() else DisableHeightBoost() end
            elseif boolKey == "GravityEnabled" then
                if _G.Settings.GravityEnabled then
                    setupGravityForce()
                    adjustGravityJump()
                end
            elseif boolKey == "AutoSpeedEnabled" then
                if _G.Settings.AutoSpeedEnabled then
                    print("✅ Auto Speed ENABLED (Keybind)")
                    InitializeAutoSpeed()
                else
                    print("❌ Auto Speed DISABLED (Keybind)")
                    if autoSpeedAttrConn then pcall(function() autoSpeedAttrConn:Disconnect() end) autoSpeedAttrConn = nil end
                end
            end
            if toggleUpdateFunctions[boolKey] then toggleUpdateFunctions[boolKey]() end 
            Save()
        end
    end
end)

-- ============================================================
-- INFINITE JUMP SYSTEM
-- ============================================================
local InfJumpPlatform = nil
local InfJumpVelocity = nil

local function CreateInfJumpPlatform()
    if InfJumpPlatform then return end
    
    InfJumpPlatform = Instance.new("Part")
    InfJumpPlatform.Name = "InfJumpPlatform"
    InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
    InfJumpPlatform.Anchored = true
    InfJumpPlatform.CanCollide = true
    InfJumpPlatform.Transparency = 1
    InfJumpPlatform.Material = Enum.Material.ForceField
    InfJumpPlatform.Parent = workspace
    
    InfJumpVelocity = Instance.new("BodyVelocity")
    InfJumpVelocity.MaxForce = Vector3.new(0, 0, 0)
    InfJumpVelocity.Velocity = Vector3.new(0, 50, 0)
    InfJumpVelocity.Parent = InfJumpPlatform
end

local function RemoveInfJumpPlatform()
    if InfJumpPlatform then
        InfJumpPlatform:Destroy()
        InfJumpPlatform = nil
    end
    InfJumpVelocity = nil
end

RunService.Heartbeat:Connect(function()
    if _G.Settings.InfJump and Player.Character then
        local root = Player.Character:FindFirstChild("HumanoidRootPart")
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if root and hum then
            if not InfJumpPlatform then
                CreateInfJumpPlatform()
            end
            
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or 
                             (hum:GetState() == Enum.HumanoidStateType.Jumping) or
                             hum.Jump
            
            if isJumping then
                InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
                
                if root.AssemblyLinearVelocity.Y < 50 then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 50, root.AssemblyLinearVelocity.Z)
                end
            else
                InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
            end
        end
    else
        RemoveInfJumpPlatform()
    end
end)

-- ============================================================
-- JUMP HEIGHT HANDLER
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and root and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local onGround = (hum.FloorMaterial ~= Enum.Material.Air)
        if onGround and _G.Settings.JumpHeightEnabled then
            local jumpHeight = _G.Settings.JumpHeightValue or 7.2
            root.Velocity = Vector3.new(root.Velocity.X, math.sqrt(2 * workspace.Gravity * jumpHeight), root.Velocity.Z)
        end
    end
end)

-- ============================================================
-- BAT AUTO-HIT SYSTEM
-- ============================================================
RunService.Stepped:Connect(function()
    local char = Player.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hum and root) then return end
    local bat = char:FindFirstChild("Bat")
    if not bat or not bat:IsA("Tool") then return end
    if _G.Settings.BatFastEnabled or _G.Settings.BatEnabled then
        local shouldHit = _G.Settings.BatFastEnabled
        if not shouldHit and _G.Settings.BatEnabled then
            for _, op in pairs(game.Players:GetPlayers()) do
                if op ~= Player and op.Character and op.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHum = op.Character:FindFirstChild("Humanoid")
                    if targetHum and targetHum.Health > 0 then
                        if (root.Position - op.Character.HumanoidRootPart.Position).Magnitude <= _G.Settings.BatRadiusValue then shouldHit = true; break end
                    end
                end
            end
        end
        if shouldHit then bat:Activate() end
    end
end)

-- ============================================================
-- CORE LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    local char = Player.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local spin = root:FindFirstChild("HeliSpin")
        if _G.Settings.HeliEnabled then
            if not spin then
                spin = Instance.new("BodyAngularVelocity")
                spin.Name = "HeliSpin"
                spin.MaxTorque = Vector3.new(0, math.huge, 0)
                spin.P = 1250
                spin.Parent = root
            end
            spin.AngularVelocity = Vector3.new(0, _G.Settings.HeliSpeedValue or 50, 0)
        elseif spin then
            spin:Destroy()
        end
    end

    if _G.Settings.BatEnabled and root then
        local r = _G.Settings.BatRadiusValue * 2
        RadiusPart.Size = Vector3.new(0.5, r, r) RadiusPart.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90)) + Vector3.new(0, -2.8, 0) RadiusPart.Transparency = 0.5 Outline.Humanoid = hum 
    else RadiusPart.Transparency = 1 end

    if _G.Settings.GravityEnabled then
        if not galaxyVectorForce or not galaxyAttachment then
            setupGravityForce()
            adjustGravityJump()
        end
        updateGravityForce()
    else
        if galaxyVectorForce then galaxyVectorForce:Destroy() galaxyVectorForce = nil end
        if galaxyAttachment then galaxyAttachment:Destroy() galaxyAttachment = nil end
        adjustGravityJump()
    end

    -- ============================================================
    -- HEIGHT BOOST HOVER  (velocity-based, no platform)
    -- ============================================================
    if root and hum then
        if _G.Settings.HeightBoostEnabled then
            if not heightBoostTargetY then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams.FilterDescendantsInstances = {char}
                local rayResult = workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayParams)
                local groundY = rayResult and rayResult.Position.Y or (root.Position.Y - 3.1)
                heightBoostTargetY = groundY + _G.Settings.HeightBoostValue
            end
            local diff = heightBoostTargetY - root.Position.Y
            local yVel = math.clamp(diff * 20, -60, 60)
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                yVel,
                root.AssemblyLinearVelocity.Z
            )
        else
            heightBoostTargetY = nil
        end
    end

    if _G.Settings.BatAimEnabled and root and hum then
        local target = (function()
            local closest, dist = nil, math.huge
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local h = p.Character:FindFirstChild("Humanoid")
                    if h and h.Health > 0 then
                        local d = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        if d < dist then dist = d; closest = p end
                    end
                end
            end
            return closest
        end)()
        if target then
            hum.AutoRotate = false 
            AimAttachment.Parent = root 
            AlignObj.Attachment0 = AimAttachment 
            AlignObj.Parent = root 
            AlignObj.Enabled = true
            AlignObj.CFrame = CFrame.lookAt(root.Position, Vector3.new(target.Character.HumanoidRootPart.Position.X, root.Position.Y, target.Character.HumanoidRootPart.Position.Z))
            
            if _G.Settings.BatAimMoveEnabled then
                local targetRoot = target.Character.HumanoidRootPart
                local dir = (targetRoot.Position - root.Position)
                local spd = _G.Settings.BatAimMoveSpeed or 55
                
                -- Lock player's own movement input so they can't interfere
                if hum.WalkSpeed ~= 0 then hum.WalkSpeed = 0 end
                
                local distance3D = dir.Magnitude
                
                if distance3D > 1.5 then
                    local moveDir = dir.Unit
                    root.AssemblyLinearVelocity = Vector3.new(moveDir.X * spd, moveDir.Y * spd, moveDir.Z * spd)
                else
                    local tv = targetRoot.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = tv
                end

                -- Spam bat only if currently equipped in hands
                local bat = char:FindFirstChild("Bat")
                if bat and bat:IsA("Tool") then
                    bat:Activate()
                end
            end
        else 
            AlignObj.Enabled = false 
            hum.AutoRotate = true 
        end
    elseif hum then 
        AlignObj.Enabled = false 
        hum.AutoRotate = true 
    end

    if hum and root and (_G.Settings.SpeedEnabled or _G.Settings.StealSpeedEnabled) then
        local finalSpeed = (_G.Settings.StealSpeedEnabled and _G.Settings.StealSpeedValue) or (_G.Settings.SpeedEnabled and _G.Settings.CustomSpeedValue) or 16
        if hum.MoveDirection.Magnitude > 0 then root.Velocity = Vector3.new(hum.MoveDirection.X * finalSpeed, root.Velocity.Y, hum.MoveDirection.Z * finalSpeed) end
    end
end)

-- ============================================================
-- START-UP
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    if _G.Settings.AntiRagdollV1 then ANTI_RAGDOLL.Enable("v1") end
    if _G.Settings.AntiRagdollV2 then ANTI_RAGDOLL.Enable("v2") end
    if _G.Settings.AntiLagEnabled then EnableAntiLag() end
    if _G.Settings.NoAnimEnabled then StartNoAnim() end
    if _G.Settings.OptimizerEnabled then OPTIMIZER.Enable() end
    if _G.Settings.AntiBeeDiscoEnabled then ANTI_BEE_DISCO.Enable() end
    if _G.Settings.FreeMoveEnabled then EnableFreeMove() end
    
    if _G.Settings.AutoSpeedEnabled then
        InitializeAutoSpeed()
    end

    if _G.Settings.AutoStealEnabled then
        startAutoSteal()
    end
    if _G.Settings.AutoLeftEnabled then
        startAutoLeft()
    end
    if _G.Settings.AutoRightEnabled then
        startAutoRight()
    end
    
    updateFreeMoveBtn()
    
    for boolKey, updateFunc in pairs(toggleUpdateFunctions) do
        updateFunc()
    end
end)

SettingsPages["Movement"].Visible = true 
SettingsTabButtons["Movement"].TextColor3 = Color3.new(1,1,1)
SettingsTabButtons["Movement"].BackgroundColor3 = Color3.fromRGB(160, 0, 0)
local movInd = SettingsTabButtons["Movement"]:FindFirstChildOfClass("Frame")
if movInd then movInd.BackgroundTransparency = 0 end

warn("✅ Trubl Hub Loaded!")
