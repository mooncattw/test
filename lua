local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- LEAKED AND DEOBFED BY BJ 🤑
local player = Players.LocalPlayer

local CONFIG_FILE = "SpaceHubConfig.json"
local NEON_COLOR = Color3.fromRGB(57, 255, 20)

local function makeDraggable(gui)
	local dragging = false
	local dragInput, dragStart, startPos

	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- LEAKED AND DEOBFED BY BJ 🤑
local function createGUI()
	local ScreenGui = Instance.new("ScreenGui")
	local Main = Instance.new("Frame")
	local Overlay = Instance.new("Frame")
	local UICorner_Main = Instance.new("UICorner")
	local UICorner_Overlay = Instance.new("UICorner")
	local BG = Instance.new("ImageLabel")
	local UICorner_BG = Instance.new("UICorner")
	local Title = Instance.new("TextLabel")
	local AntiBatBtn = Instance.new("TextButton")
	local UICorner_AB = Instance.new("UICorner")
	local InfJumpBtn = Instance.new("TextButton")
	local UICorner_IJ = Instance.new("UICorner")
	local KeybindLabel = Instance.new("TextLabel")
	local KeybindBtn = Instance.new("TextButton")
	local UICorner_KB = Instance.new("UICorner")
	local StatusLabel = Instance.new("TextLabel")

	ScreenGui.Parent = CoreGui
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false

	Main.Name = "Main"
	Main.Parent = ScreenGui
	Main.BackgroundTransparency = 1
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0.5, -122, 0.5, -93)
	Main.Size = UDim2.new(0, 244, 0, 196)
	Main.ClipsDescendants = true
	Main.Active = true

	UICorner_Main.CornerRadius = UDim.new(0, 12)
	UICorner_Main.Parent = Main

	Overlay.Name = "Overlay"
	Overlay.Parent = Main
	Overlay.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Overlay.BackgroundTransparency = 0.45
	Overlay.BorderSizePixel = 0
	Overlay.Size = UDim2.new(1, 0, 1, 0)
	Overlay.ZIndex = 1

	UICorner_Overlay.CornerRadius = UDim.new(0, 12)
	UICorner_Overlay.Parent = Overlay

	BG.Name = "BG"
	BG.Parent = Main
	BG.BackgroundTransparency = 1
	BG.Size = UDim2.new(1, 0, 1, 0)
	BG.ZIndex = 0
	BG.Image = "rbxassetid://101895084367519"
	BG.ScaleType = Enum.ScaleType.Crop

	UICorner_BG.CornerRadius = UDim.new(0, 12)
	UICorner_BG.Parent = BG

	Title.Name = "Title"
	Title.Parent = Main
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 12, 0, 10)
	Title.Size = UDim2.new(1, -12, 0, 22)
	Title.ZIndex = 2
	Title.Font = Enum.Font.GothamBold
	Title.Text = "Space Hub"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left

	AntiBatBtn.Name = "AntiBatBtn"
	AntiBatBtn.Parent = Main
	AntiBatBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	AntiBatBtn.BackgroundTransparency = 0.35
	AntiBatBtn.BorderSizePixel = 0
	AntiBatBtn.Position = UDim2.new(0, 10, 0, 38)
	AntiBatBtn.Size = UDim2.new(1, -20, 0, 36)
	AntiBatBtn.ZIndex = 2
	AntiBatBtn.Font = Enum.Font.GothamBold
	AntiBatBtn.Text = "Anti-Bat : OFF"
	AntiBatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	AntiBatBtn.TextSize = 13

	UICorner_AB.CornerRadius = UDim.new(0, 8)
	UICorner_AB.Parent = AntiBatBtn

	InfJumpBtn.Name = "InfJumpBtn"
	InfJumpBtn.Parent = Main
	InfJumpBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	InfJumpBtn.BackgroundTransparency = 0.35
	InfJumpBtn.BorderSizePixel = 0
	InfJumpBtn.Position = UDim2.new(0, 10, 0, 82)
	InfJumpBtn.Size = UDim2.new(1, -20, 0, 36)
	InfJumpBtn.ZIndex = 2
	InfJumpBtn.Font = Enum.Font.GothamBold
	InfJumpBtn.Text = "Inf Jump : OFF"
	InfJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	InfJumpBtn.TextSize = 13

	UICorner_IJ.CornerRadius = UDim.new(0, 8)
	UICorner_IJ.Parent = InfJumpBtn

	KeybindLabel.Name = "KeybindLabel"
	KeybindLabel.Parent = Main
	KeybindLabel.BackgroundTransparency = 1
	KeybindLabel.Position = UDim2.new(0, 12, 0, 134)
	KeybindLabel.Size = UDim2.new(0, 120, 0, 26)
	KeybindLabel.ZIndex = 2
	KeybindLabel.Font = Enum.Font.Gotham
	KeybindLabel.Text = "Toggle Keybind:"
	KeybindLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	KeybindLabel.TextSize = 12
	KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left

	KeybindBtn.Name = "KeybindBtn"
	KeybindBtn.Parent = Main
	KeybindBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	KeybindBtn.BackgroundTransparency = 0.35
	KeybindBtn.BorderSizePixel = 0
	KeybindBtn.Position = UDim2.new(0, 164, 0, 134)
	KeybindBtn.Size = UDim2.new(0, 70, 0, 26)
	KeybindBtn.ZIndex = 2
	KeybindBtn.Font = Enum.Font.GothamBold
	KeybindBtn.Text = "F1"
	KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeybindBtn.TextSize = 12

	UICorner_KB.CornerRadius = UDim.new(0, 6)
	UICorner_KB.Parent = KeybindBtn

	StatusLabel.Name = "StatusLabel"
	StatusLabel.Parent = Main
	StatusLabel.BackgroundTransparency = 1
	StatusLabel.Position = UDim2.new(0, 0, 1, -20)
	StatusLabel.Size = UDim2.new(1, 0, 0, 16)
	StatusLabel.ZIndex = 2
	StatusLabel.Font = Enum.Font.Gotham
	StatusLabel.Text = "Anti-Bat | Power: 4000 | Inf Jump"
	StatusLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
	StatusLabel.TextSize = 9
	StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

	return {
		ScreenGui = ScreenGui,
		Main = Main,
		AntiBatBtn = AntiBatBtn,
		InfJumpBtn = InfJumpBtn,
		KeybindBtn = KeybindBtn,
		StatusLabel = StatusLabel
	}
end

local ConfigManager = {}
function ConfigManager.load()
	local cfg = {keybind = "F1"}
	pcall(function()
		if isfile(CONFIG_FILE) then
			local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
			if data.keybind then cfg.keybind = data.keybind end
		end
	end)
	return cfg
end

function ConfigManager.save(cfg)
	pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
	end)
end

-- LEAKED AND DEOBFED BY BJ 🤑
local UIManager = {}
function UIManager:new(guiElements)
	local obj = {
		elements = guiElements,
		antiBatOn = false,
		infJumpOn = false,
		listeningForKey = false,
		antiBatConn = nil,
		antiRagdollConn = nil,
		infJumpLoopConn = nil,
		InfJumpPlatform = nil
	}

	function obj:setNeon(btn, on)
		if on then
			btn.TextColor3 = NEON_COLOR
			btn.TextStrokeColor3 = NEON_COLOR
			btn.TextStrokeTransparency = 0
		else
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			btn.TextStrokeTransparency = 1
		end
	end

	function obj:startAntiBatCore()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		if self.antiBatConn then self.antiBatConn:Disconnect() end
		self.antiBatConn = RunService.Heartbeat:Connect(function()
			if not root or not root.Parent then return end
			local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
			root.Velocity = Vector3.new(4000, root.Velocity.Y, 4000)
			RunService.RenderStepped:Wait()
			root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)
		end)
	end

	function obj:stopAntiBatCore()
		if self.antiBatConn then
			self.antiBatConn:Disconnect()
			self.antiBatConn = nil
		end
	end

	function obj:startAntiRagdollCore()
		if self.antiRagdollConn then return end
		self.antiRagdollConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if not char then return end
			local hum2 = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			if hum2 then
				local st = hum2:GetState()
				if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
					hum2:ChangeState(Enum.HumanoidStateType.Running)
					workspace.CurrentCamera.CameraSubject = hum2
					pcall(function()
						local pm = player.PlayerScripts:FindFirstChild("PlayerModule")
						if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
					end)
					if root then
						root.Velocity = Vector3.new(0,0,0)
						root.RotVelocity = Vector3.new(0,0,0)
					end
				end
			end
			for _, obj in ipairs(char:GetDescendants()) do
				if obj:IsA("Motor6D") and not obj.Enabled then
					obj.Enabled = true
				end
			end
		end)
	end

	function obj:stopAntiRagdollCore()
		if self.antiRagdollConn then
			self.antiRagdollConn:Disconnect()
			self.antiRagdollConn = nil
		end
	end

	function obj:setAntiBat(state)
		self.antiBatOn = state
		self.elements.AntiBatBtn.Text = "Anti-Bat : " .. (state and "ON" or "OFF")
		self:setNeon(self.elements.AntiBatBtn, state)

		if state then
			self:startAntiBatCore()
			self:startAntiRagdollCore()
		else
			self:stopAntiBatCore()
			self:stopAntiRagdollCore()
		end
	end

	function obj:toggleAntiBat()
		self:setAntiBat(not self.antiBatOn)
	end

	function obj:CreateIJP()
		if self.InfJumpPlatform then return end
		self.InfJumpPlatform = Instance.new("Part")
		self.InfJumpPlatform.Name = "InfJumpPlatform"
		self.InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
		self.InfJumpPlatform.Anchored = true
		self.InfJumpPlatform.CanCollide = true
		self.InfJumpPlatform.Transparency = 1
		self.InfJumpPlatform.Material = Enum.Material.ForceField
		self.InfJumpPlatform.Parent = workspace
	end

	function obj:setInfJump(state)
		self.infJumpOn = state
		self.elements.InfJumpBtn.Text = "Inf Jump : " .. (state and "ON" or "OFF")
		self:setNeon(self.elements.InfJumpBtn, state)

		if self.infJumpLoopConn then 
			self.infJumpLoopConn:Disconnect()
			self.infJumpLoopConn = nil 
		end

		self:CreateIJP()

		if state then
			self.infJumpLoopConn = RunService.Heartbeat:Connect(function()
				if not self.infJumpOn then
					if self.InfJumpPlatform then
						self.InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
					end
					return
				end
				
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				
				if not (char and root and hum) then
					if self.InfJumpPlatform then
						self.InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
					end
					return
				end
				
				local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space)
					or hum:GetState() == Enum.HumanoidStateType.Jumping
					or hum.Jump
					
				if isJumping then
					if not self.InfJumpPlatform then self:CreateIJP() end
					self.InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
					if root.Velocity.Y < 50 then
						root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
					end
				else
					if self.InfJumpPlatform then
						self.InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
					end
				end
			end)
		else
			if self.InfJumpPlatform then
				self.InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
			end
		end
	end

	function obj:toggleInfJump()
		self:setInfJump(not self.infJumpOn)
	end

	function obj:startKeybindListen()
		if self.listeningForKey then return end
		self.listeningForKey = true
		self.elements.KeybindBtn.Text = "..."
		self.elements.KeybindBtn.TextColor3 = Color3.fromRGB(255, 220, 60)
	end

	function obj:stopKeybindListen(keyName)
		self.listeningForKey = false
		self.elements.KeybindBtn.Text = keyName
		self.elements.KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	return obj
end

-- LEAKED AND DEOBFED BY BJ 🤑
local function initialize()
	local gui = createGUI()
	
	makeDraggable(gui.Main)
	
	local config = ConfigManager.load()
	gui.KeybindBtn.Text = config.keybind

	local uiManager = UIManager:new(gui)

	gui.AntiBatBtn.MouseButton1Click:Connect(function()
		uiManager:toggleAntiBat()
	end)

	gui.InfJumpBtn.MouseButton1Click:Connect(function()
		uiManager:toggleInfJump()
	end)

	gui.KeybindBtn.MouseButton1Click:Connect(function()
		uiManager:startKeybindListen()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if uiManager.listeningForKey then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
				config.keybind = keyName
				uiManager:stopKeybindListen(keyName)
				ConfigManager.save(config)
			end
			return
		end

		if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
			local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
			if keyName == config.keybind then
				uiManager:toggleAntiBat()
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if uiManager.antiBatOn then
			uiManager:startAntiBatCore()
			uiManager:startAntiRagdollCore()
		end
	end)
end

-- LEAKED AND DEOBFED BY BJ 🤑
initialize()

print("LEAKED AND DEOBFED BY BJ 🤑😂")
