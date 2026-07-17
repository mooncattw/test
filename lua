-- // 1 (Services) //
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- // 2 (Player) //
local player = Players.LocalPlayer

-- // 3 (Performance Strip - Sadece Görsel Hafiflik İçin) //
for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("Texture") or v:IsA("Decal") then
		v:Destroy()
	elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
		v.Material = Enum.Material.SmoothPlastic
	end
end

-- // 4 (HiddenUI management) //
if not CoreGui:FindFirstChild("HiddenUI") then
	local f = Instance.new("Folder")
	f.Name = "HiddenUI"
	f.Parent = CoreGui
end
if CoreGui.HiddenUI:FindFirstChild("CrasherUI_Toggle") then
	CoreGui.HiddenUI.CrasherUI_Toggle:Destroy()
end

-- // 5 (ScreenGui) //
local gui = Instance.new("ScreenGui")
gui.Name = "CrasherUI_Toggle"
gui.ResetOnSpawn = false
gui.Parent = CoreGui.HiddenUI

-- // 6 (Mavi/Beyaz Animasyonlu Çizgi Efekti Fonksiyonu) //
local function createAnimatedStroke(parent, thickness, speed)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Color3.new(1, 1, 1)
	s.Parent = parent

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 25, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 140, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 140, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 25, 60)),
	})
	g.Rotation = 0
	g.Parent = s

	task.spawn(function()
		local spd = speed or 1.2
		while parent and parent.Parent and gui.Parent do
			g.Rotation = (g.Rotation + spd) % 360
			task.wait()
		end
	end)

	return s, g
end

-- // 7 (Main Frame — Koyu Gece Mavisi Tema / Yeniden Boyutlandırıldı) //
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 95)
main.Position = UDim2.new(0.5, -110, 0.5, -47)
main.BackgroundColor3 = Color3.fromRGB(8, 12, 28)
main.BackgroundTransparency = 0.15
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

-- // 8 (Başlık — Moon Hub) //
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 12, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 160, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 160, 255)),
})
titleGrad.Parent = title

task.spawn(function()
	while main.Parent and gui.Parent do
		titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
		task.wait()
	end
end)

-- // 9 (Durum Satırı — Temiz Görünüm) //
local infoRow = Instance.new("Frame")
infoRow.Size = UDim2.new(1, -20, 0, 34)
infoRow.Position = UDim2.new(0, 10, 0, 46)
infoRow.BackgroundColor3 = Color3.fromRGB(18, 26, 48)
infoRow.Parent = main

Instance.new("UICorner", infoRow)
createAnimatedStroke(infoRow, 1, 1.2)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, 0)
infoLabel.Position = UDim2.new(0, 10, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Ready to build..."
infoLabel.Font = Enum.Font.GothamBlack
infoLabel.TextSize = 12
infoLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = infoRow

-- // 10 (Akıcı ve Sınırsız Sürükleme Sistemi) //
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

main.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)
