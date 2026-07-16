local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- ─── Core State ───────────────────────────────────────────────────────────
local State = {
	guiVisible = true,
	autoBatToggled = false,
	hittingCooldown = false,
	dropActive = false,
	introEnabled = false,
	infJumpEnabled = false,
	autoLeftEnabled = false,
	autoRightEnabled = false,
	autoLeftPhase = 1,
	autoRightPhase = 1,
}

-- ─── Keybinds ─────────────────────────────────────────────────────────────
local KB = {
	Drop   = {kb = Enum.KeyCode.X, gp = nil},
	AutoLeft = {kb = Enum.KeyCode.L, gp = nil},
	AutoRight = {kb = Enum.KeyCode.R, gp = nil},
	AutoBat = {kb = Enum.KeyCode.E, gp = nil},
	GuiHide = {kb = Enum.KeyCode.LeftControl, gp = nil},
}

local function kbMatch(entry, kc)
	return kc == entry.kb or (entry.gp and kc == entry.gp)
end

-- ─── Positions ────────────────────────────────────────────────────────────
local POS = {
	L1 = Vector3.new(-476.48, -6.28, 92.73),
	L2 = Vector3.new(-483.12, -4.95, 94.80),
	R1 = Vector3.new(-476.16, -6.52, 25.62),
	R2 = Vector3.new(-483.04, -5.09, 23.14),
}

-- ─── Utility ──────────────────────────────────────────────────────────────
local _anyKeyListening = false
local uiLocked = false
local Conns = {aimbot = nil, batCounter = nil, anchor = {}, autoLeft = nil, autoRight = nil}

local function faceSouth()
	pcall(function()
		local c = LP.Character
		if not c then return end
		local root = c:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
		end
	end)
end

local function faceNorth()
	pcall(function()
		local c = LP.Character
		if not c then return end
		local root = c:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(180), 0)
		end
	end)
end

-- ─── Auto Left ──────────────────────────────────────────────────────────
local function startAutoLeft()
	if Conns.autoLeft then Conns.autoLeft:Disconnect() end
	State.autoLeftPhase = 1
	
	Conns.autoLeft = RunService.Heartbeat:Connect(function()
		if not State.autoLeftEnabled then return end
		
		local c = LP.Character
		if not c then return end
		local root = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if not root or not hum then return end
		
		local speed = 60
		
		if State.autoLeftPhase == 1 then
			local target = Vector3.new(POS.L1.X, root.Position.Y, POS.L1.Z)
			if (target - root.Position).Magnitude < 1 then
				State.autoLeftPhase = 2
				local direction = (POS.L2 - root.Position)
				local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
				hum:Move(moveVec, false)
				root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
				return
			end
			local direction = (POS.L1 - root.Position)
			local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
			hum:Move(moveVec, false)
			root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
		elseif State.autoLeftPhase == 2 then
			local target = Vector3.new(POS.L2.X, root.Position.Y, POS.L2.Z)
			if (target - root.Position).Magnitude < 1 then
				hum:Move(Vector3.zero, false)
				root.AssemblyLinearVelocity = Vector3.zero
				State.autoLeftEnabled = false
				if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft = nil end
				State.autoLeftPhase = 1
				faceSouth()
				return
			end
			local direction = (POS.L2 - root.Position)
			local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
			hum:Move(moveVec, false)
			root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
		end
	end)
end

local function stopAutoLeft()
	if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft = nil end
	State.autoLeftPhase = 1
	local c = LP.Character
	if c then
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then hum:Move(Vector3.zero, false) end
	end
end

local function toggleAutoLeft()
	State.autoLeftEnabled = not State.autoLeftEnabled
	if State.autoLeftEnabled then
		if State.autoRightEnabled then toggleAutoRight() end
		startAutoLeft()
	else
		stopAutoLeft()
	end
end

-- ─── Auto Right ──────────────────────────────────────────────────────────
local function startAutoRight()
	if Conns.autoRight then Conns.autoRight:Disconnect() end
	State.autoRightPhase = 1
	
	Conns.autoRight = RunService.Heartbeat:Connect(function()
		if not State.autoRightEnabled then return end
		
		local c = LP.Character
		if not c then return end
		local root = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if not root or not hum then return end
		
		local speed = 60
		
		if State.autoRightPhase == 1 then
			local target = Vector3.new(POS.R1.X, root.Position.Y, POS.R1.Z)
			if (target - root.Position).Magnitude < 1 then
				State.autoRightPhase = 2
				local direction = (POS.R2 - root.Position)
				local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
				hum:Move(moveVec, false)
				root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
				return
			end
			local direction = (POS.R1 - root.Position)
			local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
			hum:Move(moveVec, false)
			root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
		elseif State.autoRightPhase == 2 then
			local target = Vector3.new(POS.R2.X, root.Position.Y, POS.R2.Z)
			if (target - root.Position).Magnitude < 1 then
				hum:Move(Vector3.zero, false)
				root.AssemblyLinearVelocity = Vector3.zero
				State.autoRightEnabled = false
				if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight = nil end
				State.autoRightPhase = 1
				faceNorth()
				return
			end
			local direction = (POS.R2 - root.Position)
			local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
			hum:Move(moveVec, false)
			root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
		end
	end)
end

local function stopAutoRight()
	if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight = nil end
	State.autoRightPhase = 1
	local c = LP.Character
	if c then
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then hum:Move(Vector3.zero, false) end
	end
end

local function toggleAutoRight()
	State.autoRightEnabled = not State.autoRightEnabled
	if State.autoRightEnabled then
		if State.autoLeftEnabled then toggleAutoLeft() end
		startAutoRight()
	else
		stopAutoRight()
	end
end

-- ─── Drop ──────────────────────────────────────────────────────────────────
local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150

local function runDrop()
	if State.dropActive then return end
	local char = LP.Character; if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	State.dropActive = true; local t0 = tick(); local dc
	dc = RunService.Heartbeat:Connect(function()
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not r then dc:Disconnect(); State.dropActive = false; return end
		if tick() - t0 >= DROP_ASCEND_DURATION then
			dc:Disconnect()
			local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
			local rr = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), rp)
			if rr then
				local hum2 = char:FindFirstChildOfClass("Humanoid")
				local off = (hum2 and hum2.HipHeight or 2) + (r.Size.Y / 2)
				r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z); r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end
			State.dropActive = false; return
		end
		r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DROP_ASCEND_SPEED, r.AssemblyLinearVelocity.Z)
	end)
end

-- ─── Bat Aimbot ───────────────────────────────────────────────────────────
local _aimbotTarget = nil

local function findBat()
	local char = LP.Character; if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
		end
	end
	return nil
end

local function getClosestTarget()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local closest, minDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health > 0 then
				local dist = (tRoot.Position - root.Position).Magnitude
				if dist < minDist then minDist = dist; closest = tRoot end
			end
		end
	end
	return closest
end

local function startBatAimbot()
	if Conns.aimbot then Conns.aimbot:Disconnect() end

	local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum0 then hum0.AutoRotate = false end

	Conns.aimbot = RunService.RenderStepped:Connect(function()
		if not State.autoBatToggled then return end
		local char = LP.Character; if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
		local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

		if not char:FindFirstChildOfClass("Tool") then
			local bat = findBat()
			if bat then pcall(function() hum:EquipTool(bat) end) end
		end

		local target = getClosestTarget()
		if not target then return end
		_aimbotTarget = target

		local targetVel = target.AssemblyLinearVelocity
		local myPos = root.Position
		local targetPos = target.Position

		local predictPos = targetPos + targetVel * 0.14
		predictPos = predictPos + target.CFrame.LookVector * 0.3

		local direction = predictPos - myPos
		local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
		local chaseSpeed = 58

		local desiredHeight = targetPos.Y + 3.7
		local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
		if hum.FloorMaterial ~= Enum.Material.Air then
			yVel = math.max(yVel, 13)
		end
		yVel = math.clamp(yVel, -70, 110)

		local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)

		local speed3 = targetVel.Magnitude
		local predictTime = math.clamp(speed3 / 150, 0.05, 0.2)
		local predictedPos = targetPos + targetVel * predictTime
		local toPredict = predictedPos - myPos
		if toPredict.Magnitude > 0.1 then
			local goalCF = CFrame.lookAt(myPos, predictedPos)
			local curCF  = root.CFrame
			local diffCF = curCF:Inverse() * goalCF
			local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
			rx = math.clamp(rx, -2.5, 2.5)
			ry = math.clamp(ry, -2.5, 2.5)
			rz = math.clamp(rz, -2.5, 2.5)
			local tiltSpeed = 42
			root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(
				Vector3.new(rx * tiltSpeed, ry * tiltSpeed, rz * tiltSpeed)
			)
		end
	end)
end

local function stopBatAimbot()
	if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot = nil end
	_aimbotTarget = nil
	local c = LP.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
	local hum2 = c and c:FindFirstChildOfClass("Humanoid")
	if hum2 then hum2.AutoRotate = true end
	State.hittingCooldown = false
end

-- ─── Unwalk ───────────────────────────────────────────────────────────────
local unwalkEnabled = false
local unwalkSavedAnimate = nil
local setUnwalkVisual = nil

local function startUnwalk()
    local c = LP.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then 
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do 
            t:Stop() 
        end 
    end
    local anim = c:FindFirstChild("Animate")
    if anim then 
        unwalkSavedAnimate = anim:Clone() 
        anim:Destroy() 
    end
end

local function stopUnwalk()
    local c = LP.Character
    if c and unwalkSavedAnimate then 
        unwalkSavedAnimate:Clone().Parent = c 
        unwalkSavedAnimate = nil 
    end
end

-- ─── Bat Counter ──────────────────────────────────────────────────────────
local batCounterEnabled = false
local batCounterDebounce = false
local setBatCounterVisual = nil
local startBatCounter, stopBatCounter

local BAT_COUNTER_SLAP_LIST = {
    "Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", 
    "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", 
    "Nuclear Slap", "Galaxy Slap", "Glitched Slap"
}

local function findBatForCounter()
    local c = LP.Character
    if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    
    for _, ch in ipairs(c:GetChildren()) do 
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then 
            return ch 
        end 
    end
    if bp then 
        for _, ch in ipairs(bp:GetChildren()) do 
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then 
                return ch 
            end 
        end 
    end
    return nil
end

local function swingBatForCounter(bat, char)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then 
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
        task.wait(0.05) 
    end
    
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end)
        task.wait(0.15)
        pcall(function() remote:FireServer() end)
    else 
        pcall(function() bat:Activate() end)
        task.wait(0.15)
        pcall(function() bat:Activate() end)
    end
end

startBatCounter = function()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not batCounterEnabled then return end
        if batCounterDebounce then return end
        
        local char = LP.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics or 
           st == Enum.HumanoidStateType.Ragdoll or 
           st == Enum.HumanoidStateType.FallingDown then
            
            batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatForCounter(bat, char) end
                task.wait(0.5)
                batCounterDebounce = false
            end)
        end
    end)
end

stopBatCounter = function()
    if Conns.batCounter then 
        Conns.batCounter:Disconnect()
        Conns.batCounter = nil 
    end
    batCounterDebounce = false
end

-- ─── Medusa Counter ──────────────────────────────────────────────────────
local medusaCounterEnabled = false
local medusaDebounce = false
local medusaLastUsed = 0
local MEDUSA_COOLDOWN = 25
local setMedusaVisual = nil

local function findMedusa()
    local c = LP.Character
    if not c then return nil end
    
    for _, t in ipairs(c:GetChildren()) do 
        if t:IsA("Tool") then 
            local n = t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then 
                return t 
            end 
        end 
    end
    
    local bp = LP:FindFirstChild("Backpack")
    if bp then 
        for _, t in ipairs(bp:GetChildren()) do 
            if t:IsA("Tool") then 
                local n = t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then 
                    return t 
                end 
            end 
        end 
    end
    return nil
end

local function useMedusaCounter()
    if medusaDebounce then return end
    if tick() - medusaLastUsed < MEDUSA_COOLDOWN then return end
    
    local c = LP.Character
    if not c then return end
    
    medusaDebounce = true
    local med = findMedusa()
    if not med then 
        medusaDebounce = false
        return 
    end
    
    if med.Parent ~= c then 
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:EquipTool(med) end 
    end
    
    pcall(function() med:Activate() end)
    medusaLastUsed = tick()
    medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 then 
            useMedusaCounter() 
        end
    end)
end

local function setupMedusa(char)
    for _, c in pairs(Conns.anchor) do 
        pcall(function() c:Disconnect() end) 
    end
    Conns.anchor = {}
    
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do 
        if part:IsA("BasePart") then 
            table.insert(Conns.anchor, onAnchorChanged(part)) 
        end 
    end
    
    table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then 
            table.insert(Conns.anchor, onAnchorChanged(part)) 
        end
    end))
end

local function stopMedusaCounter()
    for _, c in pairs(Conns.anchor) do 
        pcall(function() c:Disconnect() end) 
    end
    Conns.anchor = {}
end

-- ─── Infinite Jump ──────────────────────────────────────────────────────
local InfJumpPlatform = nil

local function CreateIJP()
    if InfJumpPlatform then return end
    InfJumpPlatform = Instance.new("Part")
    InfJumpPlatform.Name = "InfJumpPlatform"
    InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
    InfJumpPlatform.Anchored = true
    InfJumpPlatform.CanCollide = true
    InfJumpPlatform.Transparency = 1
    InfJumpPlatform.Material = Enum.Material.ForceField
    InfJumpPlatform.Parent = workspace
end

CreateIJP()

RunService.Heartbeat:Connect(function()
    if not State.infJumpEnabled then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end
    
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not (char and root and hum) then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end

    local isJumping = UIS:IsKeyDown(Enum.KeyCode.Space)
        or hum:GetState() == Enum.HumanoidStateType.Jumping
        or hum.Jump

    if isJumping then
        if not InfJumpPlatform then CreateIJP() end
        InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
        if root.Velocity.Y < 50 then
            root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
        end
    else
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
    end
end)

-- ─── Stretch Rez ─────────────────────────────────────────────────────────
local stretchRezEnabled = false
local stretchConn = nil
local fovConn = nil
local isStretched = false
local originalFOV = 70
local setStretchVisual = nil

local StretchRez = {
    Enabled = false,
    FOV = 120,
    ResolutionScale = 0.7,
}

local function applyStretch(aspect, fov)
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    pcall(function()
        cam.FieldOfView = fov
        local matrix = CFrame.new(0, 0, 0, 
            1, 0, 0,
            0, aspect, 0,
            0, 0, 1
        )
        cam.CFrame = cam.CFrame * matrix
    end)
end

local function enableStretchRez()
    if isStretched then return end
    
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    isStretched = true
    originalFOV = cam.FieldOfView
    
    if stretchConn then stretchConn:Disconnect() end
    if fovConn then fovConn:Disconnect() end
    
    local aspect = StretchRez.ResolutionScale
    
    stretchConn = RunService.RenderStepped:Connect(function()
        if not isStretched then
            if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
            return
        end
        applyStretch(aspect, StretchRez.FOV)
    end)
    
    fovConn = RunService.Heartbeat:Connect(function()
        if not isStretched then
            if fovConn then fovConn:Disconnect(); fovConn = nil end
            return
        end
        local cam2 = workspace.CurrentCamera
        if cam2 and cam2.FieldOfView ~= StretchRez.FOV then
            pcall(function() cam2.FieldOfView = StretchRez.FOV end)
        end
    end)
    
    StretchRez.Enabled = true
end

local function disableStretchRez()
    isStretched = false
    StretchRez.Enabled = false
    
    if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
    if fovConn then fovConn:Disconnect(); fovConn = nil end
    
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
    end)
end

local function toggleStretchRez()
    if isStretched then disableStretchRez() else enableStretchRez() end
    return isStretched
end

-- ─── Shiny Graphics ──────────────────────────────────────────────────────
local shinyEnabled = false
local originalSkybox = nil
local shinyGraphicsSky = nil
local shinyGraphicsConn = nil
local shinyPlanets = {}
local shinyBloom = nil
local shinyCC = nil
local setShinyVisual = nil

local function enableShinyGraphics()
    if shinyGraphicsSky then return end
    
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    
    shinyGraphicsSky = Instance.new("Sky")
    for _, prop in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do
        shinyGraphicsSky[prop] = "rbxassetid://1534951537"
    end
    shinyGraphicsSky.StarCount = 10000
    shinyGraphicsSky.CelestialBodiesShown = false
    shinyGraphicsSky.Parent = Lighting
    
    shinyBloom = Instance.new("BloomEffect")
    shinyBloom.Intensity = 1.5
    shinyBloom.Size = 40
    shinyBloom.Threshold = 0.8
    shinyBloom.Parent = Lighting
    
    shinyCC = Instance.new("ColorCorrectionEffect")
    shinyCC.Saturation = 0.8
    shinyCC.Contrast = 0.3
    shinyCC.TintColor = Color3.fromRGB(200, 200, 200)
    shinyCC.Parent = Lighting
    
    Lighting.Ambient = Color3.fromRGB(100, 100, 110)
    Lighting.Brightness = 3
    Lighting.ClockTime = 0
    
    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800 + i * 200, 800 + i * 200, 800 + i * 200)
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(160 + i * 15, 160 + i * 15, 165 + i * 15)
        p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i * 2) * (3000 + i * 500), 1500 + i * 300, math.sin(i * 2) * (3000 + i * 500))
        p.Parent = workspace
        table.insert(shinyPlanets, p)
    end
    
    shinyGraphicsConn = RunService.Heartbeat:Connect(function()
        if not shinyEnabled then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(100 + math.sin(t) * 30, 100 + math.sin(t * 0.8) * 30, 110 + math.sin(t * 1.2) * 30)
        if shinyBloom then shinyBloom.Intensity = 1.2 + math.sin(t * 2) * 0.4 end
    end)
    
    shinyEnabled = true
end

local function disableShinyGraphics()
    if shinyGraphicsConn then
        shinyGraphicsConn:Disconnect()
        shinyGraphicsConn = nil
    end
    if shinyGraphicsSky then
        shinyGraphicsSky:Destroy()
        shinyGraphicsSky = nil
    end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if shinyBloom then
        shinyBloom:Destroy()
        shinyBloom = nil
    end
    if shinyCC then
        shinyCC:Destroy()
        shinyCC = nil
    end
    for _, obj in ipairs(shinyPlanets) do
        if obj then obj:Destroy() end
    end
    shinyPlanets = {}
    
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    shinyEnabled = false
end

-- ─── Auto-apply on character respawn ─────────────────────────────────────
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if unwalkEnabled then 
        task.wait(0.5)
        startUnwalk() 
    end
    if medusaCounterEnabled then 
        setupMedusa(char) 
    end
end)

-- ─── UI Setup ─────────────────────────────────────────────────────────────
-- Clean up any existing GUI
for _, name in pairs({"FadedGUI"}) do
	local old = game:GetService("CoreGui"):FindFirstChild(name)
	if old then old:Destroy() end
	local pg = LP:FindFirstChild("PlayerGui")
	if pg then local o = pg:FindFirstChild(name); if o then o:Destroy() end end
end

local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	frame.InputBegan:Connect(function(inp)
		if uiLocked then return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = inp.Position; startPos = frame.Position
			inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	frame.InputChanged:Connect(function(inp)
		if uiLocked then dragging = false; return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
	end)
	UIS.InputChanged:Connect(function(inp)
		if uiLocked then dragging = false; return end
		if inp == dragInput and dragging then
			local d = inp.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)
end

-- Colors - Black and Grey theme
local BG = Color3.fromRGB(0,0,0)
local SIDEBAR_BG = Color3.fromRGB(8,8,8)
local CARD_BG = Color3.fromRGB(15,15,15)
local CARD_HOV = Color3.fromRGB(25,25,25)
local BORDER = Color3.fromRGB(45,45,45)
local BORDER2 = Color3.fromRGB(60,60,60)
local WHITE = Color3.fromRGB(230,230,230)
local DIM = Color3.fromRGB(140,140,140)
local DIM2 = Color3.fromRGB(50,50,50)
local KB_BG = Color3.fromRGB(12,12,12)
local INPUT_BG = Color3.fromRGB(12,12,12)

local W, H, SW = 350, 520, 90
local CORNER = 12
local uiScaleValue = 100
local mainUIScale = nil

local gui = Instance.new("ScreenGui")
gui.Name = "FadedGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
if not pcall(function() gui.Parent = game:GetService("CoreGui") end) then
	gui.Parent = LP:WaitForChild("PlayerGui")
end

local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0, 50, 0, 50)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, CORNER)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(0, 0, 0)
mainStroke.Thickness = 1
makeDraggable(main)
mainUIScale = Instance.new("UIScale", main)
mainUIScale.Scale = uiScaleValue / 100

-- Topbar
local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 44)
topbar.BackgroundColor3 = Color3.fromRGB(6,6,6)
topbar.BorderSizePixel = 0
topbar.ZIndex = 10
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, CORNER)

local titleLbl = Instance.new("TextLabel", topbar)
titleLbl.Size = UDim2.new(0, 160, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "FADED.VS"
titleLbl.TextColor3 = WHITE
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12

local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -36, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 16
minBtn.ZIndex = 13
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", minBtn).Color = BORDER

local mini = Instance.new("TextButton", gui)
mini.Name = "FadedMini"
mini.Size = UDim2.new(0, 160, 0, 30)
mini.Position = UDim2.new(0, 50, 0, 50)
mini.BackgroundColor3 = Color3.fromRGB(6,6,6)
mini.BorderSizePixel = 0
mini.Text = "FADED.VS"
mini.TextColor3 = WHITE
mini.Font = Enum.Font.GothamBold
mini.TextSize = 11
mini.TextXAlignment = Enum.TextXAlignment.Center
mini.ZIndex = 20
mini.Visible = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
local miniStroke = Instance.new("UIStroke", mini)
miniStroke.Color = Color3.fromRGB(0, 0, 0)
miniStroke.Thickness = 1
makeDraggable(mini)

local function showGui() main.Visible=true; mini.Visible=false; State.guiVisible=true end
local function hideGui() main.Visible=false; mini.Visible=true; State.guiVisible=false end
minBtn.MouseButton1Click:Connect(hideGui)
mini.MouseButton1Click:Connect(showGui)

-- Sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, SW, 1, -44)
sidebar.Position = UDim2.new(0, 0, 0, 44)
sidebar.BackgroundColor3 = SIDEBAR_BG
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
sidebar.ClipsDescendants = false

-- Content
local content = Instance.new("Frame", main)
content.Name = "ContentArea"
content.Size = UDim2.new(1, -(SW + 1), 1, -44)
content.Position = UDim2.new(0, SW + 1, 0, 44)
content.BackgroundColor3 = BG
content.BackgroundTransparency = 0
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 2

-- ─── Tabs ─────────────────────────────────────────────────────────────────
local tabs = {}
local tabPages = {}
local activeTabName = nil
local tabDefs = {
	{name="Main"},
	{name="Settings"},
	{name="Visuals"},
	{name="Keys"},
	{name="Duel"},
}
local switchTab
local pageLOs = {}

local tabListFrame = Instance.new("Frame", sidebar)
tabListFrame.Size = UDim2.new(1, 0, 1, 0)
tabListFrame.Position = UDim2.new(0, 0, 0, 0)
tabListFrame.BackgroundTransparency = 1
tabListFrame.BorderSizePixel = 0
tabListFrame.ZIndex = 6

local tabLL = Instance.new("UIListLayout", tabListFrame)
tabLL.SortOrder = Enum.SortOrder.LayoutOrder
tabLL.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabListFrame)
tabPad.PaddingTop = UDim.new(0, 10)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)

local ACTIVE_TAB_BG  = Color3.fromRGB(45,45,45)
local ACTIVE_TAB_TXT = Color3.fromRGB(230,230,230)
local IDLE_TAB_BG    = Color3.fromRGB(12,12,12)
local IDLE_TAB_TXT   = Color3.fromRGB(160,160,160)

switchTab = function(name)
	activeTabName = name
	for _, td in ipairs(tabDefs) do
		local t = tabs[td.name]
		local isA = td.name == name
		TweenService:Create(t.frame, TweenInfo.new(0.14), {BackgroundColor3 = isA and ACTIVE_TAB_BG or IDLE_TAB_BG}):Play()
		TweenService:Create(t.lbl,   TweenInfo.new(0.14), {TextColor3 = isA and ACTIVE_TAB_TXT or IDLE_TAB_TXT}):Play()
		tabPages[td.name].Visible = isA
	end
end

for i, td in ipairs(tabDefs) do
	local btn = Instance.new("TextButton", tabListFrame)
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = IDLE_TAB_BG
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.LayoutOrder = i
	btn.ZIndex = 7
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	local lbl = Instance.new("TextLabel", btn)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = td.name
	lbl.TextColor3 = IDLE_TAB_TXT
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 9
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextWrapped = true
	lbl.ZIndex = 9
	tabs[td.name] = {frame=btn, lbl=lbl}

	local page = Instance.new("ScrollingFrame", content)
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundColor3 = BG
	page.BackgroundTransparency = 0
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = BORDER2
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.ZIndex = 3
	local pll = Instance.new("UIListLayout", page)
	pll.SortOrder = Enum.SortOrder.LayoutOrder
	pll.Padding = UDim.new(0, 4)
	local pp = Instance.new("UIPadding", page)
	pp.PaddingLeft = UDim.new(0, 8)
	pp.PaddingRight = UDim.new(0, 8)
	pp.PaddingTop = UDim.new(0, 10)
	pp.PaddingBottom = UDim.new(0, 10)
	tabPages[td.name] = page
	pageLOs[td.name] = 0
	btn.Activated:Connect(function() switchTab(td.name) end)
end

local function lo(tabName) pageLOs[tabName] = pageLOs[tabName] + 1; return pageLOs[tabName] end
local function pg(tabName) return tabPages[tabName] end

local function makeSecHeader(tabName, text)
	local f = Instance.new("Frame", pg(tabName))
	f.Size = UDim2.new(1, 0, 0, 18)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.LayoutOrder = lo(tabName)
	f.ZIndex = 4
	local t = Instance.new("TextLabel", f)
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = text:upper()
	t.TextColor3 = DIM
	t.Font = Enum.Font.GothamBold
	t.TextSize = 8
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 5
	local line = Instance.new("Frame", f)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 1, -1)
	line.BackgroundColor3 = BORDER
	line.BorderSizePixel = 0
	line.ZIndex = 4
end

local function baseCard(tabName, h2)
	local c = Instance.new("Frame", pg(tabName))
	c.Size = UDim2.new(1, 0, 0, h2 or 38)
	c.BackgroundColor3 = CARD_BG
	c.BorderSizePixel = 0
	c.LayoutOrder = lo(tabName)
	c.ZIndex = 4
	Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", c).Color = BORDER
	c.MouseEnter:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_HOV}):Play() end)
	c.MouseLeave:Connect(function() TweenService:Create(c, TweenInfo.new(0.1), {BackgroundColor3=CARD_BG}):Play() end)
	return c
end

local function cLabel(p, text, x, w, sz, col, font, xa)
	local l = Instance.new("TextLabel", p)
	l.Size = UDim2.new(0, w or 140, 1, 0)
	l.Position = UDim2.new(0, x or 10, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = col or WHITE
	l.Font = font or Enum.Font.GothamBold
	l.TextSize = sz or 11
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.ZIndex = 10
	return l
end

local function makePillToggle(parent, defOn, onToggle)
	local PW, PH = 36, 19
	local pbg = Instance.new("Frame", parent)
	pbg.Size = UDim2.new(0, PW, 0, PH)
	pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
	pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(20,20,20)
	pbg.BorderSizePixel = 0
	pbg.ZIndex = 8
	Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
	local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
	local dot = Instance.new("Frame", pbg)
	dot.Size = UDim2.new(0, 13, 0, 13)
	dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
	dot.BackgroundColor3 = defOn and BG or DIM2
	dot.BorderSizePixel = 0
	dot.ZIndex = 9
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
	local isOn = defOn or false
	local function setV(on)
		isOn = on
		TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(20,20,20)}):Play()
		TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
		TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
			Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
			BackgroundColor3 = on and BG or DIM2
		}):Play()
	end
	local clk = Instance.new("TextButton", parent)
	clk.Size = UDim2.new(1, 0, 1, 0)
	clk.BackgroundTransparency = 1
	clk.Text = ""
	clk.ZIndex = 6
	clk.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end
	end)
	return setV
end

local function makeKB(parent, kbEntry, onChange)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(0, 44, 0, 20)
	b.BackgroundColor3 = KB_BG
	b.BorderSizePixel = 0
	local function getDisplayText()
		if kbEntry.gp then return "GP:"..kbEntry.gp.Name
		elseif kbEntry.kb then return kbEntry.kb.Name
		else return "None" end
	end
	b.Text = getDisplayText()
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamBold
	b.TextSize = 8
	b.ZIndex = 11
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	local bs = Instance.new("UIStroke", b); bs.Color = BORDER2; bs.Thickness = 1
	local li = false; local lc; local pv = b.Text
	b.MouseButton1Click:Connect(function()
		if li then li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end; b.Text=pv; b.TextColor3=WHITE; return end
		pv=b.Text; li=true; _anyKeyListening=true; b.Text="···"; b.TextColor3=DIM
		TweenService:Create(bs, TweenInfo.new(0.1), {Color=WHITE}):Play()
		lc = UIS.InputBegan:Connect(function(inp)
			if not li then return end
			local isKb = inp.UserInputType == Enum.UserInputType.Keyboard
			local isGp = inp.UserInputType == Enum.UserInputType.Gamepad1
			if not isKb and not isGp then return end
			if inp.KeyCode == Enum.KeyCode.Escape then
				li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end
				b.Text=pv; b.TextColor3=WHITE; TweenService:Create(bs,TweenInfo.new(0.1),{Color=BORDER2}):Play(); return
			end
			if isGp then
				kbEntry.gp = inp.KeyCode; kbEntry.kb = nil
				b.Text = "GP:"..inp.KeyCode.Name; pv = b.Text
			else
				kbEntry.kb = inp.KeyCode; kbEntry.gp = nil
				b.Text = inp.KeyCode.Name; pv = b.Text
			end
			b.TextColor3=WHITE
			li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end
			TweenService:Create(bs, TweenInfo.new(0.1), {Color=BORDER2}):Play()
			if onChange then onChange(inp.KeyCode) end
		end)
	end)
	return b
end

local function rowToggle(tabName, label, sub, defOn, onToggle)
	local c = baseCard(tabName, sub and 48 or 38)
	cLabel(c, label, 10, 120, 11, WHITE, Enum.Font.GothamBold)
	if sub then
		local sl = cLabel(c, sub, 10, 150, 9, DIM, Enum.Font.Gotham)
		sl.Size = UDim2.new(0, 150, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
	end
	local PW, PH = 36, 19
	local pbg = Instance.new("Frame", c)
	pbg.Size = UDim2.new(0, PW, 0, PH)
	pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
	pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(20,20,20)
	pbg.BorderSizePixel = 0
	pbg.ZIndex = 8
	Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
	local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
	local dot = Instance.new("Frame", pbg)
	dot.Size = UDim2.new(0, 13, 0, 13)
	dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
	dot.BackgroundColor3 = defOn and BG or DIM2
	dot.BorderSizePixel = 0
	dot.ZIndex = 9
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
	local isOn = defOn or false
	local function setV(on)
		isOn = on
		TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(20,20,20)}):Play()
		TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
		TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
			Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
			BackgroundColor3 = on and BG or DIM2
		}):Play()
	end
	local clk = Instance.new("TextButton", c)
	clk.Size = UDim2.new(1, 0, 1, 0)
	clk.BackgroundTransparency = 1
	clk.Text = ""
	clk.ZIndex = 6
	clk.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end
	end)
	return setV
end

local function rowToggleKB(tabName, label, sub, kbEntry, defOn, onToggle, onKeyChange)
	local c = baseCard(tabName, sub and 48 or 38)
	cLabel(c, label, 10, 120, 11, WHITE, Enum.Font.GothamBold)
	if sub then
		local sl = cLabel(c, sub, 10, 150, 9, DIM, Enum.Font.Gotham)
		sl.Size = UDim2.new(0, 150, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
	end
	local kb = makeKB(c, kbEntry, function(k) if onKeyChange then onKeyChange(k) end end)
	kb.Position = UDim2.new(1, -(44+10+36+8), 0.5, -10)
	kb.ZIndex = 11
	local PW, PH = 36, 19
	local pbg = Instance.new("Frame", c)
	pbg.Size = UDim2.new(0, PW, 0, PH)
	pbg.Position = UDim2.new(1, -(PW+10), 0.5, -PH/2)
	pbg.BackgroundColor3 = defOn and WHITE or Color3.fromRGB(20,20,20)
	pbg.BorderSizePixel = 0
	pbg.ZIndex = 8
	Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 10)
	local ps = Instance.new("UIStroke", pbg); ps.Color = defOn and WHITE or BORDER2; ps.Thickness = 1
	local dot = Instance.new("Frame", pbg)
	dot.Size = UDim2.new(0, 13, 0, 13)
	dot.Position = defOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
	dot.BackgroundColor3 = defOn and BG or DIM2
	dot.BorderSizePixel = 0
	dot.ZIndex = 9
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
	local isOn = defOn or false
	local function setV(on)
		isOn = on
		TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3=on and WHITE or Color3.fromRGB(20,20,20)}):Play()
		TweenService:Create(ps,  TweenInfo.new(0.18), {Color=on and WHITE or BORDER2}):Play()
		TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
			Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,2,0.5,-6),
			BackgroundColor3 = on and BG or DIM2
		}):Play()
	end
	local clk = Instance.new("TextButton", c)
	clk.Size = UDim2.new(1, 0, 1, 0)
	clk.BackgroundTransparency = 1
	clk.Text = ""
	clk.ZIndex = 6
	clk.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		isOn = not isOn; setV(isOn); if onToggle then pcall(onToggle, isOn) end
	end)
	return setV, kb
end

local function rowKBOnly(tabName, label, sub, kbEntry, onKeyChange)
	local c = baseCard(tabName, sub and 48 or 38)
	cLabel(c, label, 10, 160, 11, WHITE, Enum.Font.GothamBold)
	if sub then
		local sl = cLabel(c, sub, 10, 170, 9, DIM, Enum.Font.Gotham)
		sl.Size = UDim2.new(0, 170, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
	end
	local kb = makeKB(c, kbEntry, function(k) if onKeyChange then onKeyChange(k) end end)
	kb.Position = UDim2.new(1, -(44+10), 0.5, -10)
	kb.ZIndex = 11
	return kb
end

local function rowActionBtn(tabName, label, onClick)
	local b = Instance.new("TextButton", pg(tabName))
	b.Size = UDim2.new(1, 0, 0, 36)
	b.BackgroundColor3 = WHITE
	b.BorderSizePixel = 0
	b.Text = label
	b.TextColor3 = BG
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.LayoutOrder = lo(tabName)
	b.ZIndex = 5
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3=Color3.fromRGB(200,200,200)}):Play()
		task.delay(0.15, function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=WHITE}):Play() end)
		if onClick then pcall(onClick) end
	end)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(210,210,210)}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3=WHITE}):Play() end)
	return b
end

local function rowInput(tabName, label, sub, default, onChange)
	local c = baseCard(tabName, sub and 48 or 38)
	cLabel(c, label, 10, 130, 11, WHITE, Enum.Font.GothamBold)
	if sub then
		local sl = cLabel(c, sub, 10, 160, 9, DIM, Enum.Font.Gotham)
		sl.Size = UDim2.new(0, 160, 0, 13); sl.Position = UDim2.new(0, 10, 0, 24)
	end
	local box = Instance.new("TextBox", c)
	box.Size = UDim2.new(0, 64, 0, 24)
	box.Position = UDim2.new(1, -74, 0.5, -12)
	box.BackgroundColor3 = INPUT_BG
	box.BorderSizePixel = 0
	box.Text = tostring(default)
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.ZIndex = 11
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
	local bs = Instance.new("UIStroke", box); bs.Color = BORDER2; bs.Thickness = 1; bs.ZIndex = 12
	box.Focused:Connect(function() TweenService:Create(bs, TweenInfo.new(0.1), {Color=WHITE}):Play() end)
	box.FocusLost:Connect(function()
		TweenService:Create(bs, TweenInfo.new(0.1), {Color=BORDER2}):Play()
		if onChange then local n = tonumber(box.Text); if n then onChange(n) else box.Text = tostring(default) end end
	end)
	return box
end

-- ─── Tab Content ──────────────────────────────────────────────────────────

-- MAIN TAB
makeSecHeader("Main", "Movement Features")
rowToggle("Main", "Auto Left", nil, false,
	function(on)
		State.autoLeftEnabled = on
		if on then
			if State.autoRightEnabled then 
				State.autoRightEnabled = false
				stopAutoRight()
				if autoRightSetVisual then autoRightSetVisual(false) end
			end
			startAutoLeft()
		else
			stopAutoLeft()
		end
		if autoLeftSetVisual then autoLeftSetVisual(on) end
	end
)

rowToggle("Main", "Auto Right", nil, false,
	function(on)
		State.autoRightEnabled = on
		if on then
			if State.autoLeftEnabled then 
				State.autoLeftEnabled = false
				stopAutoLeft()
				if autoLeftSetVisual then autoLeftSetVisual(false) end
			end
			startAutoRight()
		else
			stopAutoRight()
		end
		if autoRightSetVisual then autoRightSetVisual(on) end
	end
)

rowToggle("Main", "Drop", nil, false,
	function(on)
		if on then task.spawn(runDrop) end
	end
)

makeSecHeader("Main", "Combat Features")
local autoBatSetVisual
autoBatSetVisual, _ = rowToggleKB("Main", "Auto Bat", nil, KB.AutoBat, false,
	function(on)
		State.autoBatToggled = on
		if on then startBatAimbot() else stopBatAimbot() end
	end,
	function(k) KB.AutoBat.kb = k end
)

setUnwalkVisual = rowToggle("Main", "Unwalk", nil, false,
	function(on)
		unwalkEnabled = on
		if on then startUnwalk() else stopUnwalk() end
	end
)

setBatCounterVisual = rowToggle("Main", "Bat Counter", nil, false,
	function(on)
		batCounterEnabled = on
		if on then startBatCounter() else stopBatCounter() end
	end
)

setMedusaVisual = rowToggle("Main", "Medusa Counter", nil, false,
	function(on)
		medusaCounterEnabled = on
		if on then 
			setupMedusa(LP.Character) 
		else 
			stopMedusaCounter() 
		end
	end
)

makeSecHeader("Main", "Movement Features")
setInfJump = rowToggle("Main", "Infinite Jump", nil, false,
	function(on)
		State.infJumpEnabled = on
	end
)

setStretchVisual = rowToggle("Main", "Stretch Rez", nil, false,
	function(on)
		if on then enableStretchRez() else disableStretchRez() end
		if setStretchVisual then setStretchVisual(on) end
	end
)

setShinyVisual = rowToggle("Main", "Shiny Graphics", nil, false,
	function(on)
		if on then enableShinyGraphics() else disableShinyGraphics() end
		if setShinyVisual then setShinyVisual(on) end
	end
)

-- SETTINGS TAB
makeSecHeader("Settings", "Interface Settings")
local setLockUIVisual = rowToggleKB("Settings", "Lock UI", nil, {kb = nil, gp = nil}, false, function(on)
	uiLocked = on
end)

uiScaleBox = rowInput("Settings", "UI Scale", nil, uiScaleValue, function(v)
	local n = math.clamp(math.floor(v + 0.5), 50, 150)
	uiScaleValue = n
	if mainUIScale then mainUIScale.Scale = n / 100 end
end)

-- Save Config
local saveBtn
local function saveConfig(btn)
	local function ks(e) return {kb=e.kb and e.kb.Name or nil, gp=e.gp and e.gp.Name or nil} end
	local function sp(f) if not f then return nil end; local p=f.Position; return {xs=p.X.Scale,xo=p.X.Offset,ys=p.Y.Scale,yo=p.Y.Offset} end
	local cfg = {
		uiScale=uiScaleValue,
		uiLocked=uiLocked,
		dropKey=ks(KB.Drop), autoLeftKey=ks(KB.AutoLeft), autoRightKey=ks(KB.AutoRight), autoBatKey=ks(KB.AutoBat), guiHideKey=ks(KB.GuiHide),
		unwalkEnabled=unwalkEnabled,
		batCounterEnabled=batCounterEnabled,
		medusaCounterEnabled=medusaCounterEnabled,
		infJumpEnabled=State.infJumpEnabled,
		stretchEnabled=StretchRez.Enabled,
		shinyEnabled=shinyEnabled,
		autoLeftEnabled=State.autoLeftEnabled,
		autoRightEnabled=State.autoRightEnabled,
		mainPos=sp(main), miniPos=sp(mini),
	}
	local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
	if ok and enc then
		local wf = writefile or (syn and syn.writefile) or (getgenv and getgenv().writefile)
		if wf then pcall(wf, "FadedConfig.json", enc) end
	end
	if btn then
		local prev = btn.Text
		btn.Text = "Saved!"
		task.wait(1.5)
		if btn and btn.Parent then btn.Text = prev end
	end
end

saveBtn = rowActionBtn("Settings", "Save Config", function()
	pcall(function() saveConfig(saveBtn) end)
end)

-- VISUALS TAB
makeSecHeader("Visuals", "Visual Settings")
rowActionBtn("Visuals", "Toggle Dark Mode", function()
	print("Dark Mode toggled")
end)

rowActionBtn("Visuals", "Toggle Anti-Lag", function()
	print("Anti-Lag toggled")
end)

-- KEYS TAB
makeSecHeader("Keys", "Keybinds")
rowKBOnly("Keys", "Drop Key", nil, KB.Drop, function(k) KB.Drop.kb = k end)
rowKBOnly("Keys", "Auto Left Key", nil, KB.AutoLeft, function(k) KB.AutoLeft.kb = k end)
rowKBOnly("Keys", "Auto Right Key", nil, KB.AutoRight, function(k) KB.AutoRight.kb = k end)
rowKBOnly("Keys", "Auto Bat Key", nil, KB.AutoBat, function(k) KB.AutoBat.kb = k end)
rowKBOnly("Keys", "Hide GUI Key", nil, KB.GuiHide, function(k) KB.GuiHide.kb = k end)

-- DUEL TAB
makeSecHeader("Duel", "Duel Settings")
rowActionBtn("Duel", "Start Duel", function()
	print("Duel started!")
end)

rowActionBtn("Duel", "Stop Duel", function()
	print("Duel stopped!")
end)

rowInput("Duel", "Duel Duration", nil, 60, function(v)
	print("Duel duration set to: " .. tostring(v))
end)

-- ─── Visual Setters ──────────────────────────────────────────────────────
local autoLeftSetVisual, autoRightSetVisual

autoLeftSetVisual = function(on)
	-- Update UI toggle state
	if autoLeftSetVisual then autoLeftSetVisual(on) end
end

autoRightSetVisual = function(on)
	-- Update UI toggle state
	if autoRightSetVisual then autoRightSetVisual(on) end
end

-- ─── Load Config ──────────────────────────────────────────────────────────
local function loadConfig()
	local isf = isfile or (syn and syn.isfile) or (getgenv and getgenv().isfile)
	local rdf = readfile or (syn and syn.readfile) or (getgenv and getgenv().readfile)
	local hasFile = false; pcall(function() hasFile = isf("FadedConfig.json") end)
	if not hasFile then return end
	local raw; pcall(function() raw = rdf("FadedConfig.json") end)
	if not raw then return end
	local cfg; pcall(function() cfg = HttpService:JSONDecode(raw) end)
	if not cfg then return end

	if cfg.uiScale and type(cfg.uiScale)=="number" then
		uiScaleValue=math.clamp(math.floor(cfg.uiScale+0.5),50,150)
		if mainUIScale then mainUIScale.Scale=uiScaleValue/100 end
		task.defer(function() if uiScaleBox then uiScaleBox.Text=tostring(uiScaleValue) end end)
	end
	if cfg.uiLocked then
		uiLocked=true
		task.defer(function() if setLockUIVisual then setLockUIVisual(true) end end)
	end

	local function lk(e,d) if not d then return end
		if d.kb and Enum.KeyCode[d.kb] then e.kb=Enum.KeyCode[d.kb] end
		if d.gp and Enum.KeyCode[d.gp] then e.gp=Enum.KeyCode[d.gp] end
	end
	lk(KB.Drop, cfg.dropKey); lk(KB.AutoLeft, cfg.autoLeftKey)
	lk(KB.AutoRight, cfg.autoRightKey); lk(KB.AutoBat, cfg.autoBatKey)
	lk(KB.GuiHide, cfg.guiHideKey)

	if cfg.autoLeftEnabled then
		State.autoLeftEnabled = true
		task.defer(function() startAutoLeft() end)
	end
	if cfg.autoRightEnabled then
		State.autoRightEnabled = true
		task.defer(function() startAutoRight() end)
	end
	if cfg.unwalkEnabled then
		unwalkEnabled = true
		task.defer(function() if setUnwalkVisual then setUnwalkVisual(true) end; startUnwalk() end)
	end
	if cfg.batCounterEnabled then
		batCounterEnabled = true
		task.defer(function() if setBatCounterVisual then setBatCounterVisual(true) end; startBatCounter() end)
	end
	if cfg.medusaCounterEnabled then
		medusaCounterEnabled = true
		task.defer(function() if setMedusaVisual then setMedusaVisual(true) end; setupMedusa(LP.Character) end)
	end
	if cfg.infJumpEnabled then
		State.infJumpEnabled = true
		task.defer(function() if setInfJump then setInfJump(true) end end)
	end
	if cfg.stretchEnabled then
		task.defer(function() if setStretchVisual then setStretchVisual(true) end; enableStretchRez() end)
	end
	if cfg.shinyEnabled then
		task.defer(function() if setShinyVisual then setShinyVisual(true) end; enableShinyGraphics() end)
	end

	task.spawn(function()
		task.wait(0.5)
		local function lp(frame, d) if frame and type(d)=="table" and d.xs~=nil then frame.Position=UDim2.new(d.xs,d.xo,d.ys,d.yo) end end
		lp(main, cfg.mainPos); lp(mini, cfg.miniPos)
	end)
end

loadConfig()

-- Save periodically
task.spawn(function()
	while task.wait(30) do
		pcall(saveConfig)
	end
end)

-- ─── Input Handling ──────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gp)
	if gp and inp.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
	local kc = inp.KeyCode
	if kc == Enum.KeyCode.Unknown then return end

	if kbMatch(KB.Drop, kc) then
		if not State.dropActive then task.spawn(runDrop) end
	elseif kbMatch(KB.AutoLeft, kc) then
		toggleAutoLeft()
	elseif kbMatch(KB.AutoRight, kc) then
		toggleAutoRight()
	elseif kbMatch(KB.AutoBat, kc) then
		State.autoBatToggled = not State.autoBatToggled
		if State.autoBatToggled then
			pcall(startBatAimbot)
		else
			stopBatAimbot()
		end
		if autoBatSetVisual then autoBatSetVisual(State.autoBatToggled) end
	elseif kbMatch(KB.GuiHide, kc) then
		State.guiVisible = not State.guiVisible
		pcall(function() main.Visible = State.guiVisible end)
		pcall(function() mini.Visible = not State.guiVisible end)
	end
end)

-- ─── Character Setup ──────────────────────────────────────────────────────
LP.CharacterAdded:Connect(function(char)
	if State.autoBatToggled then
		stopBatAimbot()
		task.wait(0.2)
		pcall(startBatAimbot)
	end
	if unwalkEnabled then
		task.wait(0.5)
		startUnwalk()
	end
	if medusaCounterEnabled then
		setupMedusa(char)
	end
end)

if LP.Character then
	task.spawn(function()
		task.wait(0.5)
		if State.autoBatToggled then pcall(startBatAimbot) end
		if unwalkEnabled then startUnwalk() end
		if medusaCounterEnabled then setupMedusa(LP.Character) end
	end)
end

print("[Faded.vs] Loaded!")
print("Keybinds: L=Auto Left, R=Auto Right, X=Drop, E=Auto Bat")
