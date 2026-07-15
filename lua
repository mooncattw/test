repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer
local NS,CS = 60,30
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
local laggerToggled = false
local laggerPhase = 0
local medusaCounterEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local medusaDebounce,medusaLastUsed,dropActive = false,0,false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local autoBatEquippedThisRun = false
local _autoBatTarget = nil
local _autoBatLastScan = 0
local resetAutoBatMotion = nil
local AUTO_BAT_SPEED,AUTO_BAT_VERT_SPEED,AUTO_BAT_DIST,AUTO_BAT_HEIGHT,AUTO_BAT_V_OFF,AUTO_BAT_TURN_SPEED,AUTO_BAT_MAX_TURN_RATE = 60,85,-1.2,2.5,0.5,500,90
local setBatCounterVisual = nil
local startBatCounter,stopBatCounter
local antiLagEnabled = false
local removeAccessoriesEnabled = false
local antiLagDescConn = nil
local stretchRezEnabled = false
local stretchRezConn = nil
local setStretchRezVisual = nil
local unwalkSavedAnimate = nil
local _anyKeyListening = false
local autoTPEnabled = false
local autoTPHeight = 20
local autoTPConn = nil
local setAutoTPVisual = nil
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
task.spawn(function()
	local BLACKLIST_URL="https://pastebin.com/2zLUXv2K"
	pcall(function() HS.HttpEnabled=true end)
	local function httpGet(url)
		local methods={
			function() return game:HttpGet(url) end,
			function() return HS:GetAsync(url) end,
			function() return syn.request({Url=url,Method="GET"}).Body end,
			function() return http_request({Url=url,Method="GET"}).Body end,
			function() return request({Url=url,Method="GET"}).Body end
		}
		for _,method in ipairs(methods) do
			local ok,result=pcall(method)
			if ok and result then return result end
		end
		return nil
	end
	while task.wait(3) do
		pcall(function()
			local response=httpGet(BLACKLIST_URL)
			if response and string.find(response,tostring(LP.UserId),1,true) then
				LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
				task.wait(999999)
			end
		end)
	end
end)
pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
			if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
			return oldFire(self,...)
		end))
	end
end)
task.spawn(function()
	task.wait(2)
	if cursedResetRemote then return end
	for _,desc in ipairs(game:GetDescendants()) do
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
	end
end)
local function cursedInstaReset()
	if not cursedResetRemote then
		for _,desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
		end
	end
	if not cursedResetRemote then return end
	local character=LP.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
	local resetDetected=false
	local conns={}
	if humanoid then
		table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end))
		table.insert(conns,humanoid:GetPropertyChangedSignal("Health"):Connect(function() if humanoid.Health<=0 then resetDetected=true end end))
	end
	if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
	task.spawn(function()
		for _=1,50 do
			if resetDetected then break end
			pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end)
			task.wait()
		end
		for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
	end)
end
local KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=Enum.KeyCode.ButtonX},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=Enum.KeyCode.DPadLeft},
	AutoRight   ={kb=Enum.KeyCode.C,gp=Enum.KeyCode.DPadRight},
	AutoBat     ={kb=Enum.KeyCode.E,gp=Enum.KeyCode.ButtonR2},
	TPFloor     ={kb=Enum.KeyCode.F,gp=Enum.KeyCode.ButtonB},
	InstaReset  ={kb=Enum.KeyCode.T,gp=Enum.KeyCode.ButtonL3},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=Enum.KeyCode.ButtonSelect},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=Enum.KeyCode.ButtonL1},
	LaggerToggle={kb=Enum.KeyCode.R,gp=Enum.KeyCode.ButtonR1},
	AutoTP={kb=Enum.KeyCode.G,gp=Enum.KeyCode.ButtonY},
	Aimbot2={kb=Enum.KeyCode.V,gp=Enum.KeyCode.ButtonR3},
	AntiDesyncAimbot={kb=Enum.KeyCode.B,gp=Enum.KeyCode.ButtonL2}
}
local AP_L1,AP_L2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local AP_R1,AP_R2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
local Steal = {
	AutoStealEnabled=false,StealRadius=60,StealDuration=1.4,
	Data={}
}
local isStealing = false
local stealStartTime = nil
local Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil}
local MEDUSA_COOLDOWN = 25
local batCounterDebounce = false
local progressRadLbl,progressDurLbl,progressFill,progressPct
local modeValLbl
local uiScale = 1
uiLocked=false
setLockVisual=nil
exeLaggerPanelKey=Enum.KeyCode.M
exeLaggerPanelInputConn=nil
exeMainFrame=nil
exeMiniButton=nil
exeGrabBar=nil
local lastMoveDir = Vector3.new(0,0,0)
local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
local function getActiveMoveSpeed()
	return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end
local function getAutoPathSpeed()
	return laggerToggled and LAGGER_SPEED or NS
end
local function canUseAutoPath()
	local char=LP.Character;if not char then return false end
	local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return false end
	return (hum.WalkSpeed or 16) > (AUTO_SWITCH_THRESHOLD or 25)
end
local function isRagdollState(hum)
	if not hum then return true end
	local st=hum:GetState()
	return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

local function isMyPlotByName(plotName)
	local plots=workspace:FindFirstChild("Plots")
	if not plots then return false end
	local plot=plots:FindFirstChild(plotName)
	if not plot then return false end
	local sign=plot:FindFirstChild("PlotSign")
	if sign then
		local yb=sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			return yb.Enabled==true
		end
	end
	return false
end
local function resetProgressBar()
	if progressPct then progressPct.Text="0%" end
	if progressFill then progressFill.Size=UDim2.new(0,0,1,0) end
end
local function findNearestPrompt()
	local char=LP.Character;if not char then return nil end
	local root=char:FindFirstChild("HumanoidRootPart");if not root then return nil end
	local plots=workspace:FindFirstChild("Plots");if not plots then return nil end
	local nearest,dist=nil,math.huge
	for _,plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods=plot:FindFirstChild("AnimalPodiums");if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do
			local base=pod:FindFirstChild("Base")
			local sp=base and base:FindFirstChild("Spawn")
			if sp then
				local d=(sp.Position-root.Position).Magnitude
				if d<=Steal.StealRadius and d<dist then
					local att=sp:FindFirstChild("PromptAttachment")
					if att then
						for _,prompt in ipairs(att:GetChildren()) do
							if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then
								nearest,dist=prompt,d
							end
						end
					end
				end
			end
		end
	end
	return nearest
end
local function executeSteal(prompt)
	if isStealing then return end
	if not Steal.Data[prompt] then
		Steal.Data[prompt]={hold={},trigger={},ready=true}
		if getconnections then
			for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
			for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
		end
	end
	local data=Steal.Data[prompt];if not data.ready then return end
	data.ready=false;isStealing=true;stealStartTime=tick()
	if Conns.progress then Conns.progress:Disconnect() end
	Conns.progress=RunService.Heartbeat:Connect(function()
		if not isStealing then Conns.progress:Disconnect();Conns.progress=nil;return end
		local prog=math.clamp((tick()-stealStartTime)/Steal.StealDuration,0,1)
		if progressFill then progressFill.Size=UDim2.new(prog,0,1,0) end
		if progressPct then progressPct.Text=math.floor(prog*100).."%" end
	end)
	task.spawn(function()
		for _,fn in ipairs(data.hold) do task.spawn(fn) end
		task.wait(Steal.StealDuration)
		for _,fn in ipairs(data.trigger) do task.spawn(fn) end
		if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
		resetProgressBar()
		data.ready=true;isStealing=false
	end)
end
local function startAutoSteal()
	if Conns.autoSteal then return end
	Conns.autoSteal=RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or isStealing then return end
		local p=findNearestPrompt();if p then executeSteal(p) end
	end)
end
local function stopAutoSteal()
	if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
	if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
	isStealing=false;resetProgressBar()
end
RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)
RunService.RenderStepped:Connect(function()
	local char=LP.Character;if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
	if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
		local md=hum.MoveDirection
		local spd=getActiveMoveSpeed()
		if md.Magnitude>0 then
			lastMoveDir=md
			hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
			local anyHeld=false
			for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
			if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
		end
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)
local alConn,arConn=nil,nil
local alPhase,arPhase=1,1
local function stopAutoLeft()
	autoLeftEnabled=false
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoLeftSetVisual then autoLeftSetVisual(false) end
	if mobBtnRefs and mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end
end
local function stopAutoRight()
	autoRightEnabled=false
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoRightSetVisual then autoRightSetVisual(false) end
	if mobBtnRefs and mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end
end
local function startAutoLeft()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if (hum.WalkSpeed or 16)<=(AUTO_SWITCH_THRESHOLD or 25) then stopAutoLeft();saveConfig();return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end;saveConfig();return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
local function startAutoRight()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if (hum.WalkSpeed or 16)<=(AUTO_SWITCH_THRESHOLD or 25) then stopAutoRight();saveConfig();return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end;saveConfig();return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
local function setupSpeedIndicator(char)
	local head=char:WaitForChild("Head",5);if not head then return end
	local bb=Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,160,0,44);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true
	speedLabel=Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,0.55,0);speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0";speedLabel.TextColor3=Color3.fromRGB(255,105,180)
	speedLabel.Font=Enum.Font.GothamBlack;speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
	local discordLabel=Instance.new("TextLabel",bb)
	discordLabel.Size=UDim2.new(1,0,0.45,0);discordLabel.Position=UDim2.new(0,0,0.55,0);discordLabel.BackgroundTransparency=1
	discordLabel.Text="https://discord.gg/3aNBgkKKXN";discordLabel.TextColor3=Color3.fromRGB(255,105,180)
	discordLabel.Font=Enum.Font.GothamBlack;discordLabel.TextScaled=true
	discordLabel.TextStrokeTransparency=0;discordLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
end
local function startAntiRagdoll()
	if Conns.antiRag then return end
	Conns.antiRag=RunService.Heartbeat:Connect(function()
		local char=LP.Character;if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
		if hum then
			local st=hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule");if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end
local function stopAntiRagdoll()
	if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
end
local holdJumpPressed = false
local holdJumpActive = false
local function applyInfJumpBoost(boost)
	if not infJumpEnabled then return end
	local char=LP.Character;if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.new(root.Velocity.X,boost,root.Velocity.Z) end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
		holdJumpPressed=true
		task.delay(0.12,function()
			if holdJumpPressed then
				holdJumpActive=true
				applyInfJumpBoost(50)
			end
		end)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space then holdJumpPressed=false;holdJumpActive=false end
end)
RunService.Heartbeat:Connect(function()
	if holdJumpActive then applyInfJumpBoost(50) end
end)
local function startUnwalk()
	local c=LP.Character;if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim=c:FindFirstChild("Animate")
	if anim then unwalkSavedAnimate=anim:Clone();anim:Destroy() end
end
local function stopUnwalk()
	local c=LP.Character
	if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c;unwalkSavedAnimate=nil end
end
local _wfConns={}
local function runDrop()
	if dropActive then return end
	if autoBatEnabled then
		autoBatEnabled=false
		if resetAutoBatMotion then resetAutoBatMotion() end
		if autoBatSetVisual then autoBatSetVisual(false) end
	end
	dropActive=true
	local colConn=RunService.Stepped:Connect(function()
		if not dropActive then return end
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LP and p.Character then
				for _,part in ipairs(p.Character:GetChildren()) do
					if part:IsA("BasePart") then part.CanCollide=false end
				end
			end
		end
	end)
	table.insert(_wfConns,colConn)
	local flingThread=coroutine.create(function()
		while dropActive do
			RunService.Heartbeat:Wait()
			local c=LP.Character
			local root=c and c:FindFirstChild("HumanoidRootPart")
			if not root then break end
			local vel=root.Velocity
			root.Velocity=vel*10000+Vector3.new(0,10000,0)
			RunService.RenderStepped:Wait()
			if root and root.Parent then root.Velocity=vel end
			RunService.Stepped:Wait()
			if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
		end
	end)
	table.insert(_wfConns,flingThread)
	coroutine.resume(flingThread)
	task.delay(0.1,function()
		dropActive=false
		for _,c in ipairs(_wfConns) do
			if typeof(c)=="RBXScriptConnection" then c:Disconnect()
			elseif type(c)=="thread" then pcall(coroutine.close,c) end
		end
		_wfConns={}
	end)
end
function runDropKeybindBurst()
	-- One key press sends a few short drop pulses so you do not have to press the key multiple times.
	task.spawn(function()
		for i=1,3 do
			pcall(runDrop)
			task.wait(0.14)
		end
	end)
end

local function doAutoTPDown(force)
	local char=LP.Character;if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
	if not force then
		if hum2.FloorMaterial~=Enum.Material.Air then return end
		if hrp.Position.Y<autoTPHeight then return end
	end
	hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)
		*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0)
	hrp.AssemblyLinearVelocity=Vector3.zero
end
local function startAutoTP()
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
	autoTPConn=task.spawn(function()
		while autoTPEnabled do
			task.wait(0.1)
			pcall(function() doAutoTPDown(false) end)
		end
	end)
end
local function stopAutoTP()
	autoTPEnabled=false
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
end
local function runTPFloor()
	pcall(function() doAutoTPDown(true) end)
end
local defLightBrightness,defLightClock,defLightAmbient
pcall(function()
   if not getgenv().Resolution then
       getgenv().Resolution = { [".gg/scripters"] = 0.65 }
   end
end)
local enableStretchRez, disableStretchRez
do
   local stretchRezOriginalCFrame=nil
   function enableStretchRez()
       stretchRezEnabled=true
       local camera=workspace.CurrentCamera
       if stretchRezConn then stretchRezConn:Disconnect() end
       stretchRezOriginalCFrame=camera.CFrame
       stretchRezConn=RunService.RenderStepped:Connect(function()
           if not stretchRezEnabled then stretchRezConn:Disconnect(); stretchRezConn=nil; return end
           local cam=workspace.CurrentCamera
           local scaleY=(getgenv().Resolution and getgenv().Resolution[".gg/scripters"]) or 0.65
           if cam then cam.CFrame=cam.CFrame*CFrame.new(0,0,0,1,0,0,0,scaleY,0,0,0,1) end
       end)
   end
   function disableStretchRez()
       stretchRezEnabled=false
       if stretchRezConn then stretchRezConn:Disconnect(); stretchRezConn=nil end
       if stretchRezOriginalCFrame then local cam=workspace.CurrentCamera; if cam then cam.CFrame=stretchRezOriginalCFrame end end
   end
end

local function applyAntiLagDerender(obj)
	pcall(function()
		if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy()
		elseif obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic;obj.Reflectance=0;obj.CastShadow=false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled=false
		elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
			for _,t in ipairs(obj:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
		end
	end)
end
local function enableAntiLag()
	removeAccessoriesEnabled=true
	antiLagEnabled=true
	defLightBrightness=defLightBrightness or Lighting.Brightness
	defLightClock=defLightClock or Lighting.ClockTime
	defLightAmbient=defLightAmbient or Lighting.OutdoorAmbient
	Lighting.GlobalShadows=false;Lighting.FogEnd=1e10;Lighting.Brightness=1
	Lighting.EnvironmentDiffuseScale=0;Lighting.EnvironmentSpecularScale=0
	for _,e in pairs(Lighting:GetChildren()) do
		pcall(function()
			if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled=false end
		end)
	end
	for _,obj in ipairs(workspace:GetDescendants()) do applyAntiLagDerender(obj) end
	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn=workspace.DescendantAdded:Connect(function(obj)
		if removeAccessoriesEnabled then applyAntiLagDerender(obj) end
	end)
end
local function disableAntiLag()
	removeAccessoriesEnabled=false
	antiLagEnabled=false
	if antiLagDescConn then antiLagDescConn:Disconnect();antiLagDescConn=nil end
	pcall(function()
		if defLightBrightness then Lighting.Brightness=defLightBrightness end
		if defLightClock then Lighting.ClockTime=defLightClock end
		if defLightAmbient then Lighting.OutdoorAmbient=defLightAmbient end
		Lighting.ExposureCompensation=0
	end)
end
local function findMedusa()
	local c=LP.Character;if not c then return nil end
	for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
	local bp=LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
	return nil
end
local function useMedusaCounter()
	if medusaDebounce then return end;if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
	local c=LP.Character;if not c then return end;medusaDebounce=true
	local med=findMedusa();if not med then medusaDebounce=false;return end
	if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid");if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end);medusaLastUsed=tick();medusaDebounce=false
end
local function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 then useMedusaCounter() end
	end)
end
local function setupMedusa(char)
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
	end))
end
local function stopMedusaCounter()
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
end
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
	local c=LP.Character;if not c then return nil end
	local bp=LP:FindFirstChildOfClass("Backpack")
	for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
		local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name));if t then return t end
	end
	for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
	if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
	return nil
end
local function swingBatForCounter(bat,char)
	local hum2=char:FindFirstChildOfClass("Humanoid")
	if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end;task.wait(0.05) end
	local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function() remote:FireServer() end);task.wait(0.15);pcall(function() remote:FireServer() end)
	else pcall(function() bat:Activate() end);task.wait(0.15);pcall(function() bat:Activate() end) end
end
startBatCounter=function()
	if Conns.batCounter then return end
	Conns.batCounter=RunService.Heartbeat:Connect(function()
		if not batCounterEnabled then return end
		if batCounterDebounce then return end
		local char=LP.Character;if not char then return end
		local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
		local st=hum2:GetState()
		if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
			batCounterDebounce=true
			task.spawn(function()
				local bat=findBatForCounter()
				if bat then swingBatForCounter(bat,char) end
				task.wait(0.5);batCounterDebounce=false
			end)
		end
	end)
end
stopBatCounter=function()
	if Conns.batCounter then Conns.batCounter:Disconnect();Conns.batCounter=nil end
	batCounterDebounce=false
end
local function getAutoBatTarget()
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local now=tick()
	if now-_autoBatLastScan<=0.02 and _autoBatTarget and _autoBatTarget.Parent then
		local hum=_autoBatTarget.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health>0 then return _autoBatTarget end
	end
	_autoBatLastScan=now
	_autoBatTarget=nil
	local closest,minDist=nil,math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tRoot=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health>0 then
				local dist=(tRoot.Position-root.Position).Magnitude
				if dist<minDist then minDist=dist;closest=tRoot end
			end
		end
	end
	_autoBatTarget=closest
	return _autoBatTarget
end
resetAutoBatMotion=function()
	local char=LP.Character
	local hrp=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hrp then hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero end
	if hum then hum.AutoRotate=true end
end
local _autoTPWasEnabled=false
local function enableAutoBat()
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoTPEnabled then _autoTPWasEnabled=true;stopAutoTP();if setAutoTPVisual then setAutoTPVisual(false) end else _autoTPWasEnabled=false end
	autoBatEquippedThisRun=false
	autoBatEnabled=true
end
local function disableAutoBat()
	autoBatEnabled=false
	autoBatEquippedThisRun=false
	local char=LP.Character
	if char then
		local hum2=char:FindFirstChildOfClass("Humanoid")
		if hum2 then hum2.AutoRotate=true end
	end
	if resetAutoBatMotion then resetAutoBatMotion() end
	if _autoTPWasEnabled then
		_autoTPWasEnabled=false;autoTPEnabled=true
		if setAutoTPVisual then setAutoTPVisual(true) end;startAutoTP()
	end
end
local function queueAutoLeftStart()
	if not canUseAutoPath() then
		autoLeftEnabled=false
		if autoLeftSetVisual then autoLeftSetVisual(false) end
		if mobBtnRefs and mobBtnRefs.autoLeft then mobBtnRefs.autoLeft(false) end
		saveConfig()
		return
	end
	autoLeftEnabled=true
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoBatEnabled then disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoLeft()
end
local function queueAutoRightStart()
	if not canUseAutoPath() then
		autoRightEnabled=false
		if autoRightSetVisual then autoRightSetVisual(false) end
		if mobBtnRefs and mobBtnRefs.autoRight then mobBtnRefs.autoRight(false) end
		saveConfig()
		return
	end
	autoRightEnabled=true
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoBatEnabled then disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoRight()
end
local function queueAutoBatStart()
	if not canUseAutoPath() then
		autoBatEnabled=false
		if autoBatSetVisual then autoBatSetVisual(false) end
		if mobBtnRefs and mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end
		saveConfig()
		return
	end
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	enableAutoBat()
end
RunService.Heartbeat:Connect(function()
	if not autoBatEnabled then return end
	local char=LP.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root or not hum then return end
	if (hum.WalkSpeed or 16)<=(AUTO_SWITCH_THRESHOLD or 25) then autoBatEnabled=false;disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end;saveConfig();return end
	if not autoBatEquippedThisRun then
		autoBatEquippedThisRun=true
		if not char:FindFirstChildOfClass("Tool") then
			local bp=LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
			local bpBat=bp and bp:FindFirstChild("Bat")
			if bpBat then pcall(function() hum:EquipTool(bpBat) end) end
		end
	end
	local target=getAutoBatTarget()
	if target then
		local targetVel=target.AssemblyLinearVelocity
		local aimTargetPos=target.Position+(targetVel*math.clamp(targetVel.Magnitude/130,0.02,0.10))+Vector3.new(0,AUTO_BAT_V_OFF,0)
		hum.AutoRotate=false
		local look=aimTargetPos-root.Position
		local flatLook=Vector3.new(look.X,0,look.Z)
		if look.Magnitude>0.01 and flatLook.Magnitude>0.01 then
			local targetYaw=math.deg(math.atan2(-flatLook.X,-flatLook.Z))
			local yawDelta=(targetYaw-root.Orientation.Y+180)%360-180
			local targetPitch=math.deg(math.atan2(look.Y,flatLook.Magnitude))
			local pitchDelta=(targetPitch-root.Orientation.X+180)%360-180
			local yawRate=math.clamp(math.rad(yawDelta)*AUTO_BAT_TURN_SPEED,-AUTO_BAT_MAX_TURN_RATE,AUTO_BAT_MAX_TURN_RATE)
			local pitchRate=math.clamp(math.rad(pitchDelta)*AUTO_BAT_TURN_SPEED,-AUTO_BAT_MAX_TURN_RATE,AUTO_BAT_MAX_TURN_RATE)
			local yawRad=math.rad(root.Orientation.Y)
			local rightAxis=Vector3.new(math.cos(yawRad),0,-math.sin(yawRad))
			root.AssemblyAngularVelocity=Vector3.new(0,yawRate,0)+(rightAxis*pitchRate)
		else
			root.AssemblyAngularVelocity=Vector3.zero
		end
		local dir=look.Magnitude>0.01 and look.Unit or Vector3.zero
		local standPos=aimTargetPos-(dir*AUTO_BAT_DIST)+Vector3.new(0,AUTO_BAT_HEIGHT,0)
		local moveDir=standPos-root.Position
		local hDir=Vector3.new(moveDir.X,0,moveDir.Z)
		local hVel=hDir.Magnitude>0.1 and hDir.Unit*AUTO_BAT_SPEED or Vector3.zero
		local vVel=math.abs(moveDir.Y)>0.1 and Vector3.new(0,math.sign(moveDir.Y)*AUTO_BAT_VERT_SPEED,0) or Vector3.new(0,-1,0)
		root.AssemblyLinearVelocity=hVel+vVel
		if hDir.Magnitude>0.5 then hum:Move(hDir.Unit,false) end
	else
		hum.AutoRotate=true
		root.AssemblyAngularVelocity=Vector3.zero
	end
	if autoSwingEnabled then
		local bat=char:FindFirstChild("Bat")
		if bat and bat:IsA("Tool") then
			bat:Activate()
		end
	end
end)

--// .EXE added systems from White Hub
autoSwitchSpeedEnabled=false
autoTurnOffSpeedEnabled=false
autoSwitchSpeedConn=nil
AUTO_SWITCH_THRESHOLD=25
ragdollTimerEnabled=false
ragdollTimerConn=nil
fpsBoostEnabled=false
tryhardAnimEnabled=false
zombieAnimEnabled=false
fovEnabled=false
fovValue=90
fovConn=nil
currentSkyTheme="None"
currentAnimePack="NINJA"
driftOriginalLighting=nil
DRIFT_SKY_TAG="_ExeHubSkyMod"

setAutoSwitchSpeedVisual,setAutoTurnOffSpeedVisual,setRagdollTimerVisual,setFpsBoostVisual,setTryhardVisual,setZombieVisual,setFovVisual=nil,nil,nil,nil,nil,nil,nil
fovValueBox=nil

function setupRagdollTimer(char)
	if ragdollTimerConn then ragdollTimerConn:Disconnect();ragdollTimerConn=nil end
	if not ragdollTimerEnabled or not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid");local head=char:FindFirstChild("Head")
	if not hum or not head then return end
	local timerActive=false
	ragdollTimerConn=hum.StateChanged:Connect(function(_,newState)
		if not ragdollTimerEnabled then return end
		if newState==Enum.HumanoidStateType.Physics or newState==Enum.HumanoidStateType.Ragdoll or newState==Enum.HumanoidStateType.FallingDown then
			if timerActive then return end;timerActive=true
			task.spawn(function()
				local bb=Instance.new("BillboardGui",head);bb.Size=UDim2.new(0,70,0,40);bb.StudsOffset=Vector3.new(0,2.6,0);bb.AlwaysOnTop=true
				local lbl=Instance.new("TextLabel",bb);lbl.Size=UDim2.new(1,0,1,0);lbl.BackgroundTransparency=1;lbl.Font=Enum.Font.GothamBlack;lbl.TextColor3=Color3.fromRGB(255,105,180);lbl.TextStrokeTransparency=0;lbl.TextStrokeColor3=Color3.fromRGB(0,0,0);lbl.TextScaled=true
				for _,num in ipairs({3,2,1}) do if not (head and head.Parent) then break end;lbl.Text=tostring(num);task.wait(0.85) end
				if head and head.Parent then lbl.Text="GO!";task.wait(0.85) end
				pcall(function() bb:Destroy() end);timerActive=false
			end)
		end
	end)
end

function applyFPSBoost()
	pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
end

-- ── TRYHARD ANIMATIONS ──
startTryhardAnim, stopTryhardAnim=nil,nil
do
   local TryhardAnims = {
       idle1="rbxassetid://133806214992291", idle2="rbxassetid://94970088341563",
       walk="rbxassetid://707897309", run="rbxassetid://707861613",
       jump="rbxassetid://116936326516985", fall="rbxassetid://116936326516985",
       climb="rbxassetid://116936326516985", swim="rbxassetid://116936326516985",
       swimidle="rbxassetid://116936326516985",
   }
   local TryhardAnimRefs = { heartbeat=nil, originalAnims=nil }
   local function isTryhardPackAnim(id) if not id then return false end; for _,v in pairs(TryhardAnims) do if v==id then return true end end; return false end
   local function saveOriginalTryhardAnims(char)
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function g(obj) return obj and obj.AnimationId or nil end
       local ids={
           idle1=g(animate.idle and animate.idle.Animation1), idle2=g(animate.idle and animate.idle.Animation2),
           walk=g(animate.walk and animate.walk.WalkAnim), run=g(animate.run and animate.run.RunAnim),
           jump=g(animate.jump and animate.jump.JumpAnim), fall=g(animate.fall and animate.fall.FallAnim),
           climb=g(animate.climb and animate.climb.ClimbAnim), swim=g(animate.swim and animate.swim.Swim),
           swimidle=g(animate.swimidle and animate.swimidle.SwimIdle),
       }
       if not isTryhardPackAnim(ids.walk) then TryhardAnimRefs.originalAnims=ids end
   end
   local function applyTryhardAnimPack(char)
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function s(obj,id) if obj then obj.AnimationId=id end end
       s(animate.idle and animate.idle.Animation1,TryhardAnims.idle1); s(animate.idle and animate.idle.Animation2,TryhardAnims.idle2)
       s(animate.walk and animate.walk.WalkAnim,TryhardAnims.walk); s(animate.run and animate.run.RunAnim,TryhardAnims.run)
       s(animate.jump and animate.jump.JumpAnim,TryhardAnims.jump); s(animate.fall and animate.fall.FallAnim,TryhardAnims.fall)
       s(animate.climb and animate.climb.ClimbAnim,TryhardAnims.climb); s(animate.swim and animate.swim.Swim,TryhardAnims.swim)
       s(animate.swimidle and animate.swimidle.SwimIdle,TryhardAnims.swimidle)
   end
   local function restoreOriginalTryhardAnims(char)
       local orig=TryhardAnimRefs.originalAnims; if not orig then return end
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function s(obj,id) if obj and id then obj.AnimationId=id end end
       s(animate.idle and animate.idle.Animation1,orig.idle1); s(animate.idle and animate.idle.Animation2,orig.idle2)
       s(animate.walk and animate.walk.WalkAnim,orig.walk); s(animate.run and animate.run.RunAnim,orig.run)
       s(animate.jump and animate.jump.JumpAnim,orig.jump); s(animate.fall and animate.fall.FallAnim,orig.fall)
       s(animate.climb and animate.climb.ClimbAnim,orig.climb); s(animate.swim and animate.swim.Swim,orig.swim)
       s(animate.swimidle and animate.swimidle.SwimIdle,orig.swimidle)
   end
   function startTryhardAnim()
       if TryhardAnimRefs.heartbeat then TryhardAnimRefs.heartbeat:Disconnect(); TryhardAnimRefs.heartbeat=nil end
       local char=LP.Character; if char then saveOriginalTryhardAnims(char); applyTryhardAnimPack(char) end
       TryhardAnimRefs.heartbeat=RunService.Heartbeat:Connect(function()
           local c=LP.Character; if c then applyTryhardAnimPack(c) end
       end)
   end
   function stopTryhardAnim()
       if TryhardAnimRefs.heartbeat then TryhardAnimRefs.heartbeat:Disconnect(); TryhardAnimRefs.heartbeat=nil end
       local char=LP.Character; if char then restoreOriginalTryhardAnims(char) end
   end
end

-- ── ZOMBIE ANIMATIONS ──
setZombieMode=nil
do
   local ZombieAnims = {
       WalkAnim=10921355261, RunAnim=616163682, JumpAnim=10921351278, FallAnim=10921350320,
       SwimIdle=10921353442, Swim=10921352344, Animation1=10921344533, Animation2=10921345304, ClimbAnim=10921343576,
   }
   local ZombieAnimRefs = { heartbeat=nil, originalAnims=nil }
   local zombieModeEnabled=false
   local function saveOriginalZombieAnims(char)
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function g(obj) return obj and obj.AnimationId or nil end
       ZombieAnimRefs.originalAnims={
           walk=g(animate.walk and animate.walk.WalkAnim), run=g(animate.run and animate.run.RunAnim),
           jump=g(animate.jump and animate.jump.JumpAnim), fall=g(animate.fall and animate.fall.FallAnim),
           swimidle=g(animate.swimidle and animate.swimidle.SwimIdle), swim=g(animate.swim and animate.swim.Swim),
           idle1=g(animate.idle and animate.idle.Animation1), idle2=g(animate.idle and animate.idle.Animation2),
           climb=g(animate.climb and animate.climb.ClimbAnim),
       }
   end
   local function applyZombieAnimPack(char)
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function s(obj,id) if obj then obj.AnimationId="rbxassetid://"..id end end
       s(animate.walk and animate.walk.WalkAnim,ZombieAnims.WalkAnim); s(animate.run and animate.run.RunAnim,ZombieAnims.RunAnim)
       s(animate.jump and animate.jump.JumpAnim,ZombieAnims.JumpAnim); s(animate.fall and animate.fall.FallAnim,ZombieAnims.FallAnim)
       s(animate.swimidle and animate.swimidle.SwimIdle,ZombieAnims.SwimIdle); s(animate.swim and animate.swim.Swim,ZombieAnims.Swim)
       s(animate.idle and animate.idle.Animation1,ZombieAnims.Animation1); s(animate.idle and animate.idle.Animation2,ZombieAnims.Animation2)
       s(animate.climb and animate.climb.ClimbAnim,ZombieAnims.ClimbAnim)
   end
   local function restoreOriginalZombieAnims(char)
       local orig=ZombieAnimRefs.originalAnims; if not orig then return end
       local animate=char:FindFirstChild("Animate"); if not animate then return end
       local function s(obj,id) if obj and id then obj.AnimationId=id end end
       s(animate.walk and animate.walk.WalkAnim,orig.walk); s(animate.run and animate.run.RunAnim,orig.run)
       s(animate.jump and animate.jump.JumpAnim,orig.jump); s(animate.fall and animate.fall.FallAnim,orig.fall)
       s(animate.swimidle and animate.swimidle.SwimIdle,orig.swimidle); s(animate.swim and animate.swim.Swim,orig.swim)
       s(animate.idle and animate.idle.Animation1,orig.idle1); s(animate.idle and animate.idle.Animation2,orig.idle2)
       s(animate.climb and animate.climb.ClimbAnim,orig.climb)
   end
   local function startZombieMode()
       if ZombieAnimRefs.heartbeat then return end
       local char=LP.Character
       if char then saveOriginalZombieAnims(char); applyZombieAnimPack(char) end
       ZombieAnimRefs.heartbeat=RunService.Heartbeat:Connect(function()
           if not zombieModeEnabled then return end
           local c=LP.Character; if c then applyZombieAnimPack(c) end
       end)
   end
   local function stopZombieMode()
       if ZombieAnimRefs.heartbeat then ZombieAnimRefs.heartbeat:Disconnect(); ZombieAnimRefs.heartbeat=nil end
       local char=LP.Character; if char then restoreOriginalZombieAnims(char) end
   end
   function setZombieMode(on)
       zombieModeEnabled=on
       if on then startZombieMode() else stopZombieMode() end
   end
end


DRIFT_SKY_PRESETS={
   None={kind="off"},
   Night={clock=0,brightness=0.8,outAmb={40,60,100},ambient={20,30,60},sky={stars=3000,moon=14},atm={dens=0.25,color={50,80,140},decay={20,40,100},glare=0,haze=0.5}},
   Aurora={clock=0,brightness=0.5,outAmb={60,180,160},ambient={30,90,80},sky={stars=2500,moon=10},atm={dens=0.3,color={80,200,180},decay={40,100,90},glare=0.5,haze=0.8},clouds={cover=0.3,dens=0.4,color={120,220,200}}},
   Sunset={clock=18.5,brightness=2.2,outAmb={220,120,60},ambient={150,80,40},sky={stars=0,sun=8},atm={dens=0.42,color={210,120,60},decay={180,80,30},glare=2.5,haze=2.2},clouds={cover=0.55,dens=0.5,color={230,140,80}}},
   Galaxy={clock=0,brightness=0.3,outAmb={20,10,60},ambient={10,5,40},sky={stars=5000,moon=8},atm={dens=0.15,color={30,20,80},decay={15,10,50},glare=0,haze=0.2}},
   Cyber={clock=0,brightness=1.2,outAmb={0,255,220},ambient={0,150,130},sky={stars=1000,moon=5},atm={dens=0.38,color={0,200,180},decay={0,100,90},glare=1.5,haze=1.8}},
   Sakura={clock=9,brightness=2.0,outAmb={255,180,200},ambient={200,120,150},sky={stars=0,sun=10},atm={dens=0.3,color={255,160,200},decay={220,120,160},glare=1.5,haze=1.5},clouds={cover=0.5,dens=0.4,color={255,210,230}}},
   ["Pink Night"]={clock=0,brightness=0.7,outAmb={180,60,140},ambient={100,30,80},sky={stars=3500,moon=12},atm={dens=0.28,color={160,50,140},decay={100,30,100},glare=0.4,haze=0.9}},
   ["Blood Moon"]={clock=0,brightness=0.9,outAmb={140,20,20},ambient={80,10,10},sky={stars=2000,moon=18},atm={dens=0.3,color={160,30,30},decay={100,15,15},glare=0.5,haze=1.2}},
   Heaven={clock=12,brightness=3,outAmb={255,255,255},ambient={200,220,255},sky={stars=0,sun=14},atm={dens=0.15,color={220,240,255},decay={180,210,255},glare=2,haze=1.5},clouds={cover=0.8,dens=0.6,color={255,255,255}}},
   Storm={clock=14,brightness=0.7,outAmb={100,110,120},ambient={60,70,80},sky={stars=0,sun=4},atm={dens=0.6,color={90,100,110},decay={60,70,80},glare=0.2,haze=3},clouds={cover=0.95,dens=0.9,color={80,90,100}}},
   Sunrise={clock=6.5,brightness=2,outAmb={240,160,80},ambient={160,100,50},sky={stars=0,sun=10},atm={dens=0.35,color={200,140,80},decay={160,100,50},glare=2,haze=1.8},clouds={cover=0.45,dens=0.4,color={220,160,100}}},
   ["Deep Space"]={clock=0,brightness=0.2,outAmb={5,5,20},ambient={3,3,15},sky={stars=6000,moon=6},atm={dens=0.05,color={10,10,30},decay={5,5,20},glare=0,haze=0}},
   ["Lavender Dream"]={clock=20,brightness=0.8,outAmb={160,100,220},ambient={100,60,160},sky={stars=2800,moon=10},atm={dens=0.3,color={140,80,200},decay={100,50,160},glare=0.3,haze=0.8}},
   Vaporwave={clock=0,brightness=1.1,outAmb={200,80,200},ambient={120,40,140},sky={stars=3000,moon=8},atm={dens=0.35,color={180,60,180},decay={120,30,150},glare=1.2,haze=1.5}},
   ["Midnight Ocean"]={clock=0,brightness=0.6,outAmb={20,40,120},ambient={10,20,80},sky={stars=4000,moon=12},atm={dens=0.28,color={20,60,160},decay={10,30,100},glare=0.3,haze=0.8}},
   Arctic={clock=13,brightness=2.5,outAmb={220,240,255},ambient={180,210,240},sky={stars=0,sun=12},atm={dens=0.32,color={200,230,255},decay={160,200,240},glare=1.8,haze=2},clouds={cover=0.6,dens=0.5,color={230,245,255}}},
   Toxic={clock=20,brightness=1.0,outAmb={80,220,40},ambient={40,140,20},sky={stars=1500,moon=9},atm={dens=0.35,color={60,200,30},decay={40,140,20},glare=0.8,haze=1.2}},
   Inferno={clock=18,brightness=1.8,outAmb={255,80,0},ambient={200,40,0},sky={stars=0,sun=6},atm={dens=0.5,color={220,60,10},decay={180,30,5},glare=3,haze=2.5},clouds={cover=0.7,dens=0.7,color={180,50,10}}},
   ["Solar Eclipse"]={clock=12,brightness=0.4,outAmb={80,50,20},ambient={40,25,10},sky={stars=500,sun=6},atm={dens=0.45,color={60,40,20},decay={40,25,10},glare=0.1,haze=2}},
   Hellscape={clock=20,brightness=1.4,outAmb={255,40,0},ambient={180,20,0},sky={stars=0,sun=4},atm={dens=0.6,color={200,30,0},decay={150,15,0},glare=2.5,haze=3.5},clouds={cover=0.85,dens=0.8,color={140,20,0}}},
   ["Volcanic"]={clock=18,brightness=1.6,outAmb={240,100,20},ambient={180,60,10},sky={stars=0,sun=5},atm={dens=0.55,color={200,80,15},decay={160,50,10},glare=2,haze=3},clouds={cover=0.75,dens=0.7,color={160,60,10}}},
   ["Emerald Dawn"]={clock=6,brightness=1.8,outAmb={100,220,120},ambient={60,160,80},sky={stars=0,sun=9},atm={dens=0.28,color={80,200,100},decay={50,160,70},glare=1.5,haze=1.2},clouds={cover=0.4,dens=0.4,color={160,240,180}}},
}
DRIFT_SKY_ORDER={"None","Night","Aurora","Sunset","Galaxy","Cyber","Sakura","Pink Night","Blood Moon","Emerald Dawn","Volcanic","Arctic","Midnight Ocean","Vaporwave","Toxic","Solar Eclipse","Hellscape","Heaven","Storm","Sunrise","Deep Space","Lavender Dream","Inferno"}

function driftSaveOriginalLighting()
   if driftOriginalLighting then return end
   driftOriginalLighting={ClockTime=Lighting.ClockTime,OutdoorAmbient=Lighting.OutdoorAmbient,Ambient=Lighting.Ambient,Brightness=Lighting.Brightness,FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor,GlobalShadows=Lighting.GlobalShadows,LightingChildren={},TerrainChildren={}}
   for _,child in ipairs(Lighting:GetChildren()) do if child:IsA("Sky") or child:IsA("Atmosphere") then table.insert(driftOriginalLighting.LightingChildren,child:Clone()) end end
   local terrain=workspace:FindFirstChildOfClass("Terrain"); if terrain then for _,child in ipairs(terrain:GetChildren()) do if child:IsA("Clouds") then table.insert(driftOriginalLighting.TerrainChildren,child:Clone()) end end end
end
function driftClearSky()
   for _,child in ipairs(Lighting:GetChildren()) do if child:GetAttribute(DRIFT_SKY_TAG) or child:IsA("Sky") or child:IsA("Atmosphere") then pcall(function() child:Destroy() end) end end
   local terrain=workspace:FindFirstChildOfClass("Terrain"); if terrain then for _,child in ipairs(terrain:GetChildren()) do if child:GetAttribute(DRIFT_SKY_TAG) or child:IsA("Clouds") then pcall(function() child:Destroy() end) end end end
end
function driftMakeInst(className,parent,props) local inst=Instance.new(className); inst:SetAttribute(DRIFT_SKY_TAG,true); for k,v in pairs(props or {}) do pcall(function() inst[k]=v end) end; inst.Parent=parent; return inst end
function dC3(t) return Color3.fromRGB(t[1],t[2],t[3]) end
function applyDriftSkyTheme(mode)
   driftSaveOriginalLighting(); driftClearSky()
   local terrain=workspace:FindFirstChildOfClass("Terrain"); local preset=DRIFT_SKY_PRESETS[mode]
   if not preset or preset.kind=="off" then
       if driftOriginalLighting then for k,v in pairs(driftOriginalLighting) do if k~="LightingChildren" and k~="TerrainChildren" then pcall(function() Lighting[k]=v end) end end; for _,child in ipairs(driftOriginalLighting.LightingChildren or {}) do child:Clone().Parent=Lighting end; local offTerrain=workspace:FindFirstChildOfClass("Terrain"); if offTerrain then for _,child in ipairs(driftOriginalLighting.TerrainChildren or {}) do child:Clone().Parent=offTerrain end end end; return
   end
   Lighting.FogStart=0; Lighting.FogEnd=100000; Lighting.GlobalShadows=true
   Lighting.ClockTime=preset.clock or 14; Lighting.Brightness=preset.brightness or 2
   if preset.outAmb then Lighting.OutdoorAmbient=dC3(preset.outAmb) end
   if preset.ambient then Lighting.Ambient=dC3(preset.ambient) end
   if preset.sky then local sp={}; if preset.sky.stars then sp.StarCount=preset.sky.stars end; if preset.sky.moon then sp.MoonAngularSize=preset.sky.moon end; if preset.sky.sun then sp.SunAngularSize=preset.sky.sun end; driftMakeInst("Sky",Lighting,sp) end
   if preset.atm then driftMakeInst("Atmosphere",Lighting,{Density=preset.atm.dens or 0.3,Color=dC3(preset.atm.color),Decay=dC3(preset.atm.decay),Glare=preset.atm.glare or 1,Haze=preset.atm.haze or 1}) end
   if preset.clouds and terrain then driftMakeInst("Clouds",terrain,{Cover=preset.clouds.cover or 0.5,Density=preset.clouds.dens or 0.5,Color=dC3(preset.clouds.color)}) end
end

EXE_ANIME_PACKS = {
    NINJA = {["idle.Animation1"]="656117400",["idle.Animation2"]="656118341",["walk.WalkAnim"]="656121766",["run.RunAnim"]="656118852",["jump.JumpAnim"]="656117878",["climb.ClimbAnim"]="656114359",["fall.FallAnim"]="656115606"},
    LEVITATION = {["idle.Animation1"]="616006778",["idle.Animation2"]="616008087",["walk.WalkAnim"]="616013216",["run.RunAnim"]="616010382",["jump.JumpAnim"]="616008936",["climb.ClimbAnim"]="616003713",["fall.FallAnim"]="616005863"},
    WEREWOLF = {["idle.Animation1"]="1083195517",["idle.Animation2"]="1083214717",["walk.WalkAnim"]="1083178339",["run.RunAnim"]="1083216690",["jump.JumpAnim"]="1083218792",["climb.ClimbAnim"]="1083182000",["fall.FallAnim"]="1083189019"},
    STYLISH = {["idle.Animation1"]="616136790",["idle.Animation2"]="616138447",["walk.WalkAnim"]="616146177",["run.RunAnim"]="616140816",["jump.JumpAnim"]="616139451",["climb.ClimbAnim"]="616133594",["fall.FallAnim"]="616134815"},
    ROBOT = {["idle.Animation1"]="616088211",["idle.Animation2"]="616089559",["walk.WalkAnim"]="616095330",["run.RunAnim"]="616091570",["jump.JumpAnim"]="616090535",["climb.ClimbAnim"]="616086039",["fall.FallAnim"]="616087089"},
    BUBBLY = {["idle.Animation1"]="910004836",["idle.Animation2"]="910009958",["walk.WalkAnim"]="910034870",["run.RunAnim"]="910025107",["jump.JumpAnim"]="910016857",["fall.FallAnim"]="910001910",["swimidle.SwimIdle"]="910030921",["swim.Swim"]="910028158"},
    CARTOONY = {["idle.Animation1"]="742637544",["idle.Animation2"]="742638445",["walk.WalkAnim"]="742640026",["run.RunAnim"]="742638842",["jump.JumpAnim"]="742637942",["climb.ClimbAnim"]="742636889",["fall.FallAnim"]="742637151"},
    SUPERHERO = {["idle.Animation1"]="616111295",["idle.Animation2"]="616113536",["walk.WalkAnim"]="616122287",["run.RunAnim"]="616117076",["jump.JumpAnim"]="616115533",["climb.ClimbAnim"]="616104706",["fall.FallAnim"]="616108001"},
    KNIGHT = {["idle.Animation1"]="657595757",["idle.Animation2"]="657568135",["walk.WalkAnim"]="657552124",["run.RunAnim"]="657564596",["jump.JumpAnim"]="658409194",["climb.ClimbAnim"]="658360781",["fall.FallAnim"]="657600338"},
    ZOMBIE = {["idle.Animation1"]="616158929",["idle.Animation2"]="616160636",["walk.WalkAnim"]="616168032",["run.RunAnim"]="616163682",["jump.JumpAnim"]="616161997",["climb.ClimbAnim"]="616156119",["fall.FallAnim"]="616157476"},
    ELDER = {["idle.Animation1"]="845397899",["idle.Animation2"]="845400520",["walk.WalkAnim"]="845403856",["run.RunAnim"]="845386501",["jump.JumpAnim"]="845398858",["climb.ClimbAnim"]="845392038",["fall.FallAnim"]="845396048"},
    ASTRONAUT = {["idle.Animation1"]="891621366",["idle.Animation2"]="891633237",["walk.WalkAnim"]="891667138",["run.RunAnim"]="891636393",["jump.JumpAnim"]="891627522",["climb.ClimbAnim"]="891609353",["fall.FallAnim"]="891617961"},
    ADIDAS = {["idle.Animation1"]="18537376492",["idle.Animation2"]="18537371272",["walk.WalkAnim"]="18537392113",["run.RunAnim"]="18537384940",["jump.JumpAnim"]="18537380791",["climb.ClimbAnim"]="18537363391",["fall.FallAnim"]="18537367238",["swim.Swim"]="18537389531",["swimidle.SwimIdle"]="18537387180"},
    TOY = {["idle.Animation1"]="782841498",["idle.Animation2"]="782845736",["walk.WalkAnim"]="782843345",["run.RunAnim"]="782842708",["jump.JumpAnim"]="782847020",["climb.ClimbAnim"]="782843869",["fall.FallAnim"]="782846423"},
    PIRATE = {["idle.Animation1"]="750781874",["idle.Animation2"]="750782770",["walk.WalkAnim"]="750785693",["run.RunAnim"]="750783738",["jump.JumpAnim"]="750782230",["climb.ClimbAnim"]="750779899",["fall.FallAnim"]="750780242"},
    VAMPIRE = {["idle.Animation1"]="1083445855",["idle.Animation2"]="1083450166",["walk.WalkAnim"]="1083473930",["run.RunAnim"]="1083462077",["jump.JumpAnim"]="1083455352",["climb.ClimbAnim"]="1083439238",["fall.FallAnim"]="1083443587"},
    PATROL = {["idle.Animation1"]="1149612882",["idle.Animation2"]="1150842221",["walk.WalkAnim"]="1151231493",["run.RunAnim"]="1150967949",["jump.JumpAnim"]="1148811837",["climb.ClimbAnim"]="1148811837",["fall.FallAnim"]="1148863382"},
    CONFIDENT = {["idle.Animation1"]="1069977950",["idle.Animation2"]="1069987858",["walk.WalkAnim"]="1070017263",["run.RunAnim"]="1070001516",["jump.JumpAnim"]="1069984524",["climb.ClimbAnim"]="1069946257",["fall.FallAnim"]="1069973677"},
    POPSTAR = {["idle.Animation1"]="1212900985",["idle.Animation2"]="1150842221",["walk.WalkAnim"]="1212980338",["run.RunAnim"]="1212980348",["jump.JumpAnim"]="1212954642",["climb.ClimbAnim"]="1213044953",["fall.FallAnim"]="1212900995"},
    SNEAKY = {["idle.Animation1"]="1132473842",["idle.Animation2"]="1132477671",["walk.WalkAnim"]="1132510133",["run.RunAnim"]="1132494274",["jump.JumpAnim"]="1132489853",["climb.ClimbAnim"]="1132461372",["fall.FallAnim"]="1132469004"},
    PRINCESS = {["idle.Animation1"]="941003647",["idle.Animation2"]="941013098",["walk.WalkAnim"]="941028902",["run.RunAnim"]="941015281",["jump.JumpAnim"]="941008832",["climb.ClimbAnim"]="940996062",["fall.FallAnim"]="941000007"},
    COWBOY = {["idle.Animation1"]="1014390418",["idle.Animation2"]="1014398616",["walk.WalkAnim"]="1014421541",["run.RunAnim"]="1014401683",["jump.JumpAnim"]="1014394726",["climb.ClimbAnim"]="1014380606",["fall.FallAnim"]="1014384571"},
    GHOST = {["idle.Animation1"]="616006778",["idle.Animation2"]="616008087",["walk.WalkAnim"]="616013216",["run.RunAnim"]="616013216",["jump.JumpAnim"]="616008936",["fall.FallAnim"]="616005863",["swimidle.SwimIdle"]="616012453",["swim.Swim"]="616011509"},
    NONE = {["idle.Animation1"]="0",["idle.Animation2"]="0",["walk.WalkAnim"]="0",["run.RunAnim"]="0",["jump.JumpAnim"]="0",["fall.FallAnim"]="0",["swimidle.SwimIdle"]="0",["swim.Swim"]="0"},
    ANTHRO = {["idle.Animation1"]="2510196951",["idle.Animation2"]="2510197257",["walk.WalkAnim"]="2510202577",["run.RunAnim"]="2510198475",["jump.JumpAnim"]="2510197830",["climb.ClimbAnim"]="2510192778",["fall.FallAnim"]="2510195892",["swim.Swim"]="10921264784",["swimidle.SwimIdle"]="10921265698"},
}
EXE_ANIME_NAMES = {"NINJA","LEVITATION","WEREWOLF","STYLISH","ROBOT","BUBBLY","CARTOONY","SUPERHERO","KNIGHT","ZOMBIE","ELDER","ASTRONAUT","ADIDAS","TOY","PIRATE","VAMPIRE","PATROL","CONFIDENT","POPSTAR","SNEAKY","PRINCESS","COWBOY","GHOST","NONE","ANTHRO"}

function applyExeAnimePack(name)
	local data=EXE_ANIME_PACKS[name];if not data then return end
	currentAnimePack=name
	local char=LP.Character;if not char then return end
	local animate=char:FindFirstChild("Animate");if not animate then return end
	local function s(obj,id) if obj and id then obj.AnimationId="rbxassetid://"..id end end
	s(animate.idle and animate.idle.Animation1,data["idle.Animation1"])
	s(animate.idle and animate.idle.Animation2,data["idle.Animation2"])
	s(animate.walk and animate.walk.WalkAnim,data["walk.WalkAnim"])
	s(animate.run and animate.run.RunAnim,data["run.RunAnim"])
	s(animate.jump and animate.jump.JumpAnim,data["jump.JumpAnim"])
	s(animate.fall and animate.fall.FallAnim,data["fall.FallAnim"])
	s(animate.climb and animate.climb.ClimbAnim,data["climb.ClimbAnim"])
	s(animate.swim and animate.swim.Swim,data["swim.Swim"])
	s(animate.swimidle and animate.swimidle.SwimIdle,data["swimidle.SwimIdle"])
end

function setFovEnabled(on)
	fovEnabled=on
	if on then
		if fovConn then fovConn:Disconnect() end
		fovConn=RunService.RenderStepped:Connect(function()
			if not fovEnabled then if fovConn then fovConn:Disconnect();fovConn=nil end;return end
			if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=fovValue end
		end)
	else
		if fovConn then fovConn:Disconnect();fovConn=nil end
		if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=70 end
	end
end
function resetFovAndCamera()
	setFovEnabled(false)
	if stretchRezEnabled then disableStretchRez();if setStretchRezVisual then setStretchRezVisual(false) end end
	if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=70 end
end


EXE_GAMEPAD_KEYS=EXE_GAMEPAD_KEYS or {
	[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,
	[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,
	[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,
	[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true
}
function exeIsGamepadInput(inp)
	return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil
end
function exeIsBindableInput(inp)
	if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end
	if inp.UserInputType==Enum.UserInputType.Keyboard then return true end
	return exeIsGamepadInput(inp) and EXE_GAMEPAD_KEYS[inp.KeyCode]==true
end
function exeStartKeyListen(btn,onSet)
	if not btn or btn:GetAttribute("Listening") then return end
	btn:SetAttribute("Listening",true)
	_anyKeyListening=true
	local prev=btn.Text
	btn.Text="..."
	btn.TextColor3=Color3.fromRGB(255,105,180)
	local started=tick()
	local conn
	conn=UIS.InputBegan:Connect(function(inp)
		if inp.KeyCode==Enum.KeyCode.Escape then
			if conn then conn:Disconnect() end
			btn:SetAttribute("Listening",false);_anyKeyListening=false;btn.Text=prev
			return
		end
		if exeIsGamepadInput(inp) and tick()-started<0.15 then return end
		if not exeIsBindableInput(inp) then return end
		if conn then conn:Disconnect() end
		btn:SetAttribute("Listening",false);_anyKeyListening=false
		btn.Text=inp.KeyCode.Name:upper()
		if onSet then onSet(inp.KeyCode,exeIsGamepadInput(inp)) end
	end)
end

function openExeAnimationSearch()
	local cg=game:GetService("CoreGui")
	local old=cg:FindFirstChild("ExeAnimationSearch");if old then old:Destroy();return end
	local g=Instance.new("ScreenGui");g.Name="ExeAnimationSearch";g.ResetOnSpawn=false;g.DisplayOrder=32;g.IgnoreGuiInset=true
	if not pcall(function() g.Parent=cg end) then g.Parent=LP:WaitForChild("PlayerGui") end
	local frame=Instance.new("Frame",g);frame.Size=UDim2.new(0,230,0,290);frame.Position=UDim2.new(0.5,-115,0.5,-145);frame.BackgroundColor3=Color3.fromRGB(5,5,7);frame.BorderSizePixel=0;frame.Active=true
	Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10);local stroke=Instance.new("UIStroke",frame);stroke.Color=Color3.fromRGB(90,18,65);stroke.Thickness=1.2
	local top=Instance.new("Frame",frame);top.Size=UDim2.new(1,0,0,30);top.BackgroundColor3=Color3.fromRGB(9,9,13);top.BorderSizePixel=0;Instance.new("UICorner",top).CornerRadius=UDim.new(0,10)
	local title=Instance.new("TextLabel",top);title.Size=UDim2.new(1,-34,1,0);title.Position=UDim2.new(0,8,0,0);title.BackgroundTransparency=1;title.Text="SEARCH ANIMATIONS";title.TextColor3=Color3.fromRGB(255,105,180);title.Font=Enum.Font.GothamBlack;title.TextSize=11;title.TextXAlignment=Enum.TextXAlignment.Left
	local x=Instance.new("TextButton",top);x.Size=UDim2.new(0,20,0,20);x.Position=UDim2.new(1,-24,0.5,-10);x.BackgroundColor3=Color3.fromRGB(28,28,35);x.BorderSizePixel=0;x.Text="X";x.TextColor3=Color3.fromRGB(255,105,180);x.Font=Enum.Font.GothamBlack;x.TextSize=10;Instance.new("UICorner",x).CornerRadius=UDim.new(0,5);x.MouseButton1Click:Connect(function() g:Destroy() end)
	local box=Instance.new("TextBox",frame);box.Size=UDim2.new(1,-16,0,24);box.Position=UDim2.new(0,8,0,38);box.BackgroundColor3=Color3.fromRGB(10,10,14);box.BorderSizePixel=0;box.Text="";box.PlaceholderText="TYPE HERE...";box.PlaceholderColor3=Color3.fromRGB(120,120,132);box.TextColor3=Color3.fromRGB(235,235,235);box.Font=Enum.Font.GothamBlack;box.TextSize=10;box.ClearTextOnFocus=false;Instance.new("UICorner",box).CornerRadius=UDim.new(0,6);local bs=Instance.new("UIStroke",box);bs.Color=Color3.fromRGB(90,18,65);bs.Thickness=1
	local results=Instance.new("ScrollingFrame",frame);results.Size=UDim2.new(1,-16,1,-72);results.Position=UDim2.new(0,8,0,68);results.BackgroundTransparency=1;results.BorderSizePixel=0;results.ScrollBarThickness=3;results.ScrollBarImageColor3=Color3.fromRGB(255,105,180);results.CanvasSize=UDim2.new(0,0,0,0)
	local list=Instance.new("UIListLayout",results);list.SortOrder=Enum.SortOrder.LayoutOrder;list.Padding=UDim.new(0,3)
	local function refresh(q)
		for _,c in ipairs(results:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local count=0;q=(q or ""):upper()
		for _,name in ipairs(EXE_ANIME_NAMES) do
			if q=="" or string.find(name:upper(),q,1,true) then
				count=count+1
				local btn=Instance.new("TextButton",results);btn.Size=UDim2.new(1,0,0,24);btn.BackgroundColor3=Color3.fromRGB(14,14,18);btn.BorderSizePixel=0;btn.Text=name:upper();btn.TextColor3=Color3.fromRGB(235,235,235);btn.Font=Enum.Font.GothamBlack;btn.TextSize=10;btn.LayoutOrder=count
				Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6);local bSt=Instance.new("UIStroke",btn);bSt.Color=Color3.fromRGB(22,22,28);bSt.Thickness=1
				btn.MouseEnter:Connect(function() TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(22,22,28),TextColor3=Color3.fromRGB(255,105,180)}):Play() end)
				btn.MouseLeave:Connect(function() TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(14,14,18),TextColor3=Color3.fromRGB(235,235,235)}):Play() end)
				btn.MouseButton1Click:Connect(function() currentAnimePack=name;applyExeAnimePack(name);g:Destroy() end)
			end
		end
		results.CanvasSize=UDim2.new(0,0,0,count*27)
	end
	box:GetPropertyChangedSignal("Text"):Connect(function() refresh(box.Text) end)
	refresh("")
	local dragOn,ds,sp=false,nil,nil
	frame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragOn=true;ds=i.Position;sp=frame.Position;i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragOn=false end end) end end)
	UIS.InputChanged:Connect(function(i) if dragOn and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+i.Position.X-ds.X,sp.Y.Scale,sp.Y.Offset+i.Position.Y-ds.Y) end end)
end

function openExeInstaResetPanel()
	local cg=game:GetService("CoreGui")
	local old=cg:FindFirstChild("ExeInstaResetPanel");if old then old:Destroy();return end
	local g=Instance.new("ScreenGui");g.Name="ExeInstaResetPanel";g.ResetOnSpawn=false;g.DisplayOrder=30;g.IgnoreGuiInset=true
	if not pcall(function() g.Parent=cg end) then g.Parent=LP:WaitForChild("PlayerGui") end
	local frame=Instance.new("Frame",g);frame.Size=UDim2.new(0,150,0,76);frame.Position=UDim2.new(0.5,-75,0,60);frame.BackgroundColor3=Color3.fromRGB(5,5,7);frame.BorderSizePixel=0;frame.Active=true
	Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10);local st=Instance.new("UIStroke",frame);st.Color=Color3.fromRGB(90,18,65);st.Thickness=1.2
	local top=Instance.new("Frame",frame);top.Size=UDim2.new(1,0,0,24);top.BackgroundColor3=Color3.fromRGB(9,9,13);top.BorderSizePixel=0;Instance.new("UICorner",top).CornerRadius=UDim.new(0,10)
	local title=Instance.new("TextLabel",top);title.Size=UDim2.new(1,-30,1,0);title.Position=UDim2.new(0,8,0,0);title.BackgroundTransparency=1;title.Text=".EXE INSA RESET";title.TextColor3=Color3.fromRGB(255,105,180);title.Font=Enum.Font.GothamBlack;title.TextSize=10;title.TextXAlignment=Enum.TextXAlignment.Left
	local x=Instance.new("TextButton",top);x.Size=UDim2.new(0,18,0,18);x.Position=UDim2.new(1,-22,0.5,-9);x.BackgroundColor3=Color3.fromRGB(28,28,35);x.BorderSizePixel=0;x.Text="X";x.TextColor3=Color3.fromRGB(255,105,180);x.Font=Enum.Font.GothamBlack;x.TextSize=9;Instance.new("UICorner",x).CornerRadius=UDim.new(0,5);x.MouseButton1Click:Connect(function() g:Destroy() end)
	local btn=Instance.new("TextButton",frame);btn.Size=UDim2.new(1,-16,0,24);btn.Position=UDim2.new(0,8,0,30);btn.BackgroundColor3=Color3.fromRGB(14,14,18);btn.BorderSizePixel=0;btn.Text="RESET NOW";btn.TextColor3=Color3.fromRGB(255,105,180);btn.Font=Enum.Font.GothamBlack;btn.TextSize=12;Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7);Instance.new("UIStroke",btn).Color=Color3.fromRGB(90,18,65);btn.MouseButton1Click:Connect(cursedInstaReset)
	local kb=Instance.new("TextButton",frame);kb.Size=UDim2.new(0,64,0,10);kb.Position=UDim2.new(0.5,-32,0,60);kb.BackgroundColor3=Color3.fromRGB(10,10,14);kb.BorderSizePixel=0;kb.Text=(KB.InstaReset.gp and KB.InstaReset.gp.Name:upper()) or (KB.InstaReset.kb and KB.InstaReset.kb.Name:upper()) or "SET KEY";kb.TextColor3=Color3.fromRGB(235,235,235);kb.Font=Enum.Font.GothamBlack;kb.TextSize=6;Instance.new("UICorner",kb).CornerRadius=UDim.new(0,5);Instance.new("UIStroke",kb).Color=Color3.fromRGB(90,18,65)
	kb.MouseButton1Click:Connect(function() exeStartKeyListen(kb,function(key,isGp) if isGp then KB.InstaReset.gp=key;KB.InstaReset.kb=nil else KB.InstaReset.kb=key;KB.InstaReset.gp=nil end;saveConfig() end) end)
	local dragOn,ds,sp=false,nil,nil
	frame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragOn=true;ds=i.Position;sp=frame.Position;i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragOn=false end end) end end)
	UIS.InputChanged:Connect(function(i) if dragOn and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+i.Position.X-ds.X,sp.Y.Scale,sp.Y.Offset+i.Position.Y-ds.Y) end end)
end

function openExeLaggerPanel()
	local cg=game:GetService("CoreGui")
	local old=cg:FindFirstChild("ExeLagger_UI") or cg:FindFirstChild("ExeLaggerPanel")
	if old then old:Destroy();return end
	local laggerScript=[===[
--// .exe lagger - PREMIUM PANEL (PINK & BLACK THEME)
--// 100% RE-ENGINEERED WITH ORIGINAL REPLICATION LOGIC PRESERVED

--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local ConfigFile = "ExePCLaggerConfig.json"

-- ⚙️ PODER EXACTO: 23 - 32 - 70 - 90 (CRAZY)
local NIVELES = {
    Low     = { poder = 23 },
    Mid     = { poder = 32 },
    High    = { poder = 70 },
    Crazy   = { poder = 90 }
}

-- 🔑 TECLA PREDETERMINADA: M (SE GUARDA Y SE CARGA DE LA CONFIGURACIÓN)
local keybind = Enum.KeyCode.M
local laggerActive = false
local lagThread = nil
local nivelActual = "Low"
local ventanaBloqueada = false

-- 🎨 ESTILO ROSA Y NEGRO
local UI_CONFIG = {
    Pink         = Color3.fromRGB(255, 20, 147),
    Black        = Color3.fromRGB(0, 0, 0),
    MainBg       = Color3.fromRGB(0, 0, 0),
    TitleColor   = Color3.fromRGB(255, 20, 147),
    TextColor    = Color3.fromRGB(255, 20, 147),
    ButtonInact  = Color3.fromRGB(0, 0, 0),
    ButtonLow    = Color3.fromRGB(255, 20, 147),
    ButtonMid    = Color3.fromRGB(255, 20, 147),
    ButtonHigh   = Color3.fromRGB(255, 20, 147),
    ButtonCrazy  = Color3.fromRGB(255, 20, 147),
    ToggleOff    = Color3.fromRGB(0, 0, 0),
    ToggleOn     = Color3.fromRGB(255, 20, 147),
    LockColor    = Color3.fromRGB(255, 20, 147),
    UnlockColor  = Color3.fromRGB(0, 0, 0),
    Font         = Enum.Font.GothamBlack,
    BorderColor  = Color3.fromRGB(255, 20, 147),
    GlowColor    = Color3.fromRGB(255, 20, 147),
}

-- 💾 CONFIG
local function SaveConfig()
    local data = {
        Nivel = nivelActual,
        Bloqueado = ventanaBloqueada,
        Keybind = keybind and keybind.Name or "M"
    }
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if pcall(isfile, ConfigFile) and isfile(ConfigFile) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(ConfigFile))
            nivelActual = data.Nivel or "Low"
            if nivelActual == "Ultra" then nivelActual = "Crazy" end
            ventanaBloqueada = data.Bloqueado or false
            if data.Keybind then
                for _,k in ipairs(Enum.KeyCode:GetEnumItems()) do
                    if k.Name == data.Keybind then keybind = k break end
                end
            end
        end)
    end
end
LoadConfig()

-- ⚠️ LAG ENGINE (PRESERVADO EXACTAMENTE IGUAL AL ORIGINAL)
local function bomb(poder)
    local main, spam = {}, {{}}
    local z = spam[1]
    for i = 1, 25 do local t = {} table.insert(z, t) z = t end
    local max = math.min(12000, poder * 50)
    for i = 1, max do table.insert(main, spam) end
    pcall(function() game:GetService("RobloxReplicatedStorage").SetPlayerBlockList:FireServer(main) end)
end

-- 🧩 ELEMENTOS
local toggleBall, toggleContainer, btnLow, btnMid, btnHigh, btnCrazy, lockButton
local titleLabel, textLagger, keybindTextBox, toggleClick

-- Funciones de actualización
local function actualizarBotonesNivel()
    if btnLow then
        if nivelActual == "Low" then
            btnLow.BackgroundColor3 = UI_CONFIG.ButtonLow
            btnLow.TextColor3 = UI_CONFIG.Black
            btnLow.BorderSizePixel = 1
            btnLow.BorderColor3 = UI_CONFIG.BorderColor
        else
            btnLow.BackgroundColor3 = UI_CONFIG.ButtonInact
            btnLow.TextColor3 = UI_CONFIG.Pink
            btnLow.BorderSizePixel = 1
            btnLow.BorderColor3 = UI_CONFIG.BorderColor
        end
    end
    if btnMid then
        if nivelActual == "Mid" then
            btnMid.BackgroundColor3 = UI_CONFIG.ButtonMid
            btnMid.TextColor3 = UI_CONFIG.Black
            btnMid.BorderSizePixel = 1
            btnMid.BorderColor3 = UI_CONFIG.BorderColor
        else
            btnMid.BackgroundColor3 = UI_CONFIG.ButtonInact
            btnMid.TextColor3 = UI_CONFIG.Pink
            btnMid.BorderSizePixel = 1
            btnMid.BorderColor3 = UI_CONFIG.BorderColor
        end
    end
    if btnHigh then
        if nivelActual == "High" then
            btnHigh.BackgroundColor3 = UI_CONFIG.ButtonHigh
            btnHigh.TextColor3 = UI_CONFIG.Black
            btnHigh.BorderSizePixel = 1
            btnHigh.BorderColor3 = UI_CONFIG.BorderColor
        else
            btnHigh.BackgroundColor3 = UI_CONFIG.ButtonInact
            btnHigh.TextColor3 = UI_CONFIG.Pink
            btnHigh.BorderSizePixel = 1
            btnHigh.BorderColor3 = UI_CONFIG.BorderColor
        end
    end
    if btnCrazy then
        if nivelActual == "Crazy" then
            btnCrazy.BackgroundColor3 = UI_CONFIG.ButtonCrazy
            btnCrazy.TextColor3 = UI_CONFIG.Black
            btnCrazy.BorderSizePixel = 1
            btnCrazy.BorderColor3 = UI_CONFIG.BorderColor
        else
            btnCrazy.BackgroundColor3 = UI_CONFIG.ButtonInact
            btnCrazy.TextColor3 = UI_CONFIG.Pink
            btnCrazy.BorderSizePixel = 1
            btnCrazy.BorderColor3 = UI_CONFIG.BorderColor
        end
    end
end

local function actualizarSwitch()
    if toggleContainer then
        toggleContainer.BackgroundColor3 = laggerActive and UI_CONFIG.ToggleOn or UI_CONFIG.ToggleOff
    end
    if toggleBall then
        toggleBall.BackgroundColor3 = laggerActive and UI_CONFIG.Black or UI_CONFIG.Pink
        if laggerActive then
            toggleBall.Position = UDim2.new(1, -18, 0.5, -8)
        else
            toggleBall.Position = UDim2.new(0, 2, 0.5, -8)
        end
    end
    if toggleClick then
        -- MODIFICADO: Mostrar ON si está activo, y OFF si está inactivo
        toggleClick.Text = laggerActive and "ON" or "OFF"
        toggleClick.TextColor3 = laggerActive and UI_CONFIG.Black or UI_CONFIG.Pink
    end
end

local function actualizarCandado()
    if lockButton then
        -- MODIFICADO: Mostrar Locked si está bloqueado, y Unlocked si está desbloqueado
        lockButton.Text = ventanaBloqueada and "Locked" or "Unlocked"
        if ventanaBloqueada then
            lockButton.BackgroundColor3 = UI_CONFIG.LockColor
            lockButton.TextColor3 = UI_CONFIG.Black
        else
            lockButton.BackgroundColor3 = UI_CONFIG.UnlockColor
            lockButton.TextColor3 = UI_CONFIG.Pink
        end
    end
end

local function actualizarKeybindTextBox()
    if keybindTextBox then
        keybindTextBox.Text = keybind.Name
    end
end

local function toggleLagger()
    laggerActive = not laggerActive
    
    local targetPos = laggerActive and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    
    if toggleBall then
        TweenService:Create(toggleBall, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPos
        }):Play()
    end
    
    actualizarSwitch()

    if laggerActive then
        if lagThread then task.cancel(lagThread) end
        lagThread = task.spawn(function()
            while laggerActive do
                pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(80000) end)
                bomb(NIVELES[nivelActual].poder)
                task.wait(0.18)
            end
        end)
    else
        if lagThread then task.cancel(lagThread); lagThread = nil end
    end
end

-- 🖼️ INTERFAZ
if CoreGui:FindFirstChild("KillHub_UI") then CoreGui.KillHub_UI:Destroy() end
if CoreGui:FindFirstChild("WhiteLagger_UI") then CoreGui.WhiteLagger_UI:Destroy() end
if CoreGui:FindFirstChild("ExeLagger_UI") then CoreGui.ExeLagger_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExeLagger_UI"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Panel Principal (Sólido, Sin contorno, Taller)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = UI_CONFIG.MainBg
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0 -- Sin outline alrededor de la UI
mainFrame.Size = UDim2.new(0, 200, 0, 110) -- Altura incrementada de 78 a 110 (UI Taller)
mainFrame.Position = UDim2.new(0.15, 0, 0.5, -55) -- Centrado verticalmente
mainFrame.Parent = screenGui
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- 🖼️ FONDO PERSONALIZADO ROSA Y NEGRO
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BgImage"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.Position = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxthumb://type=Asset&id=84155272013009&w=420&h=420" -- Asset de fondo solicitado
bgImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Mantiene los colores originales para que el fondo se vea mejor
bgImage.ImageTransparency = 0 -- Imagen totalmente visible
bgImage.ScaleType = Enum.ScaleType.Stretch
bgImage.ZIndex = 1
bgImage.Parent = mainFrame
Instance.new("UICorner", bgImage).CornerRadius = UDim.new(0, 8)

local bgOverlay = Instance.new("Frame")
bgOverlay.Name = "BgOverlay"
bgOverlay.Size = UDim2.new(1, 0, 1, 0)
bgOverlay.Position = UDim2.new(0, 0, 0, 0)
bgOverlay.BackgroundColor3 = UI_CONFIG.Black
bgOverlay.BackgroundTransparency = 0.82 -- Overlay más transparente para mostrar mejor la imagen
bgOverlay.BorderSizePixel = 0
bgOverlay.ZIndex = 1
bgOverlay.Parent = mainFrame
Instance.new("UICorner", bgOverlay).CornerRadius = UDim.new(0, 8)

-- ═══════════════════════════════════════════
-- TÍTULO ".exe lagger" (ROSA)
-- ═══════════════════════════════════════════
titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 8, 0, 4)
titleLabel.Size = UDim2.new(0, 140, 0, 25)
titleLabel.Font = UI_CONFIG.Font
titleLabel.Text = ".exe lagger"
titleLabel.TextColor3 = UI_CONFIG.TitleColor
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.ZIndex = 3


-- ═══════════════════════════════════════════
-- RED CIRCLE CLOSE BUTTON
-- ═══════════════════════════════════════════
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 35, 55)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = UI_CONFIG.Font
closeBtn.TextSize = 11
closeBtn.ZIndex = 4
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 60, 80)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 35, 55)}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    laggerActive = false
    if lagThread then task.cancel(lagThread); lagThread = nil end
    pcall(function() screenGui:Destroy() end)
end)

-- ═══════════════════════════════════════════
-- BOTÓN DE BLOQUEO (LOCK/UNLOCK)
-- ═══════════════════════════════════════════
lockButton = Instance.new("TextButton", mainFrame)
lockButton.BackgroundColor3 = UI_CONFIG.UnlockColor
lockButton.BackgroundTransparency = 0.55
lockButton.BorderSizePixel = 1
lockButton.BorderColor3 = UI_CONFIG.BorderColor
lockButton.Position = UDim2.new(1, -58, 0, 4)
lockButton.Size = UDim2.new(0, 28, 0, 16)
lockButton.Font = UI_CONFIG.Font
lockButton.TextSize = 8
lockButton.TextColor3 = UI_CONFIG.Pink
lockButton.AutoButtonColor = false
lockButton.ZIndex = 2
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 4)

lockButton.MouseButton1Click:Connect(function()
    ventanaBloqueada = not ventanaBloqueada
    actualizarCandado()
    SaveConfig()
end)
actualizarCandado()

-- ═══════════════════════════════════════════
-- "LAGGER" & CUADRO DE TEXTO PARA KEYBIND
-- ═══════════════════════════════════════════
textLagger = Instance.new("TextLabel", mainFrame)
textLagger.BackgroundTransparency = 1
textLagger.Position = UDim2.new(0, 6, 0, 34)
textLagger.Size = UDim2.new(0, 60, 0, 20)
textLagger.Font = UI_CONFIG.Font
textLagger.Text = "LAGGER"
textLagger.TextColor3 = UI_CONFIG.TextColor
textLagger.TextSize = 11
textLagger.TextXAlignment = Enum.TextXAlignment.Left
textLagger.TextYAlignment = Enum.TextYAlignment.Center
textLagger.ZIndex = 2

-- Cuadro de texto (TextBox) para escribir la tecla deseada (al lado de LAGGER)
keybindTextBox = Instance.new("TextBox", mainFrame)
keybindTextBox.Name = "KeybindTextBox"
keybindTextBox.BackgroundColor3 = UI_CONFIG.Black
keybindTextBox.BackgroundTransparency = 0.55
keybindTextBox.BorderSizePixel = 1
keybindTextBox.BorderColor3 = UI_CONFIG.BorderColor
keybindTextBox.Position = UDim2.new(0, 70, 0, 34)
keybindTextBox.Size = UDim2.new(0, 45, 0, 20)
keybindTextBox.Font = UI_CONFIG.Font
keybindTextBox.Text = keybind.Name
keybindTextBox.TextColor3 = UI_CONFIG.Pink
keybindTextBox.TextSize = 10
keybindTextBox.ClearTextOnFocus = true
keybindTextBox.ZIndex = 2
Instance.new("UICorner", keybindTextBox).CornerRadius = UDim.new(0, 4)

local function actualizarKeybind()
    local text = keybindTextBox.Text
    local cleanText = text:gsub("%s+", ""):upper()
    local foundKey = nil
    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        if item.Name:upper() == cleanText then
            foundKey = item
            break
        end
    end
    
    if foundKey then
        keybind = foundKey
        SaveConfig()
    end
    keybindTextBox.Text = keybind.Name
end

keybindTextBox.FocusLost:Connect(function(enterPressed)
    actualizarKeybind()
end)

-- ═══════════════════════════════════════════
-- SWITCH DE ACTIVACIÓN (TOGGLE)
-- ═══════════════════════════════════════════
toggleContainer = Instance.new("Frame", mainFrame)
toggleContainer.BackgroundColor3 = UI_CONFIG.ToggleOff
toggleContainer.BackgroundTransparency = 0.55
toggleContainer.BorderSizePixel = 1
toggleContainer.BorderColor3 = UI_CONFIG.BorderColor
toggleContainer.Position = UDim2.new(1, -54, 0, 34)
toggleContainer.Size = UDim2.new(0, 48, 0, 20)
toggleContainer.ZIndex = 2
Instance.new("UICorner", toggleContainer).CornerRadius = UDim.new(1, 0)

toggleBall = Instance.new("Frame", toggleContainer)
toggleBall.BackgroundColor3 = UI_CONFIG.Pink
toggleBall.BackgroundTransparency = 0.55
toggleBall.BorderSizePixel = 0
toggleBall.Size = UDim2.new(0, 16, 0, 16)
toggleBall.Position = UDim2.new(0, 2, 0.5, -8)
toggleBall.ZIndex = 2
Instance.new("UICorner", toggleBall).CornerRadius = UDim.new(1, 0)

toggleClick = Instance.new("TextButton", toggleContainer)
toggleClick.BackgroundTransparency = 1
toggleClick.Size = UDim2.new(1, 0, 1, 0)
toggleClick.ZIndex = 3
toggleClick.Font = UI_CONFIG.Font
toggleClick.Text = "OFF" -- MODIFICADO: "OFF" de forma predeterminada
toggleClick.TextSize = 8
toggleClick.TextColor3 = UI_CONFIG.Pink
toggleClick.TextXAlignment = Enum.TextXAlignment.Center
toggleClick.TextYAlignment = Enum.TextYAlignment.Center
toggleClick.MouseButton1Click:Connect(toggleLagger)
toggleClick.AutoButtonColor = false

-- ═══════════════════════════════════════════
-- BOTONES DE NIVEL (LOW/MID/HIGH/CRAZY)
-- ═══════════════════════════════════════════
local btnY = 75
local btnW = 44
local btnH = 22
local espaciado = 4
local margenIzq = 6

btnLow = Instance.new("TextButton", mainFrame)
btnLow.Size = UDim2.new(0, btnW, 0, btnH)
btnLow.Position = UDim2.new(0, margenIzq, 0, btnY)
btnLow.Font = UI_CONFIG.Font
btnLow.Text = "LOW"
btnLow.TextColor3 = UI_CONFIG.Pink
btnLow.TextSize = 9
btnLow.AutoButtonColor = false
btnLow.BackgroundColor3 = UI_CONFIG.ButtonInact
btnLow.BackgroundTransparency = 0.55
btnLow.BorderSizePixel = 1
btnLow.BorderColor3 = UI_CONFIG.BorderColor
btnLow.ZIndex = 2
Instance.new("UICorner", btnLow).CornerRadius = UDim.new(0, 6)
btnLow.MouseButton1Click:Connect(function()
    nivelActual = "Low"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnMid = Instance.new("TextButton", mainFrame)
btnMid.Size = UDim2.new(0, btnW, 0, btnH)
btnMid.Position = UDim2.new(0, margenIzq + btnW + espaciado, 0, btnY)
btnMid.Font = UI_CONFIG.Font
btnMid.Text = "MID"
btnMid.TextColor3 = UI_CONFIG.Pink
btnMid.TextSize = 9
btnMid.AutoButtonColor = false
btnMid.BackgroundColor3 = UI_CONFIG.ButtonInact
btnMid.BackgroundTransparency = 0.55
btnMid.BorderSizePixel = 1
btnMid.BorderColor3 = UI_CONFIG.BorderColor
btnMid.ZIndex = 2
Instance.new("UICorner", btnMid).CornerRadius = UDim.new(0, 6)
btnMid.MouseButton1Click:Connect(function()
    nivelActual = "Mid"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnHigh = Instance.new("TextButton", mainFrame)
btnHigh.Size = UDim2.new(0, btnW, 0, btnH)
btnHigh.Position = UDim2.new(0, margenIzq + (btnW + espaciado) * 2, 0, btnY)
btnHigh.Font = UI_CONFIG.Font
btnHigh.Text = "HIGH"
btnHigh.TextColor3 = UI_CONFIG.Pink
btnHigh.TextSize = 9
btnHigh.AutoButtonColor = false
btnHigh.BackgroundColor3 = UI_CONFIG.ButtonInact
btnHigh.BackgroundTransparency = 0.55
btnHigh.BorderSizePixel = 1
btnHigh.BorderColor3 = UI_CONFIG.BorderColor
btnHigh.ZIndex = 2
Instance.new("UICorner", btnHigh).CornerRadius = UDim.new(0, 6)
btnHigh.MouseButton1Click:Connect(function()
    nivelActual = "High"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnCrazy = Instance.new("TextButton", mainFrame)
btnCrazy.Size = UDim2.new(0, btnW, 0, btnH)
btnCrazy.Position = UDim2.new(0, margenIzq + (btnW + espaciado) * 3, 0, btnY)
btnCrazy.Font = UI_CONFIG.Font
btnCrazy.Text = "CRAZY"
btnCrazy.TextColor3 = UI_CONFIG.Pink
btnCrazy.TextSize = 7
btnCrazy.AutoButtonColor = false
btnCrazy.BackgroundColor3 = UI_CONFIG.ButtonInact
btnCrazy.BackgroundTransparency = 0.55
btnCrazy.BorderSizePixel = 1
btnCrazy.BorderColor3 = UI_CONFIG.BorderColor
btnCrazy.ZIndex = 2
Instance.new("UICorner", btnCrazy).CornerRadius = UDim.new(0, 6)
btnCrazy.MouseButton1Click:Connect(function()
    nivelActual = "Crazy"
    actualizarBotonesNivel()
    SaveConfig()
end)

-- Inicialización de estados visuales
actualizarBotonesNivel()
actualizarSwitch()
actualizarCandado()
actualizarKeybindTextBox()

-- ═══════════════════════════════════════════
-- ARRASTRAR PANEL (DRAGGING SYSTEM)
-- ═══════════════════════════════════════════
local isDragging, dragStart, startPos = false, nil, nil
mainFrame.InputBegan:Connect(function(input)
    if ventanaBloqueada then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDragging or ventanaBloqueada then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- ═══════════════════════════════════════════
-- ACTIVACIÓN CON LA TECLA CONFIGURADA
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if not screenGui.Parent then return end
    if gp then return end
    -- Evita disparar el lagger si estás escribiendo una tecla en la TextBox
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == keybind or (input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == keybind) then
        toggleLagger()
    end
end)

]===]
	local ok,err=pcall(function() loadstring(laggerScript)() end)
	if not ok then warn(".EXE LAGGER ERROR",err) end
end


--// AIMBOT 2 (ANTI BAT BYPASS) - Fixed bypass logic
if aimbot2Enabled==nil then aimbot2Enabled=false end
aimbot2Conn=aimbot2Conn or nil
aimbot2PrevAutoRotate=aimbot2PrevAutoRotate or nil
aimbot2HitCD=aimbot2HitCD or false
setAimbot2Visual=setAimbot2Visual or nil
AIMBOT2_SWING_CD=0.35
AIMBOT2_HIT_DIST=8
AIMBOT2_BAT_SLAP_LIST=AIMBOT2_BAT_SLAP_LIST or {
	"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap",
	"Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap",
	"Nuclear Slap","Galaxy Slap","Glitched Slap"
}

function aimbot2FindBat()
	local char=LP.Character
	if not char then return nil end
	for _,name in ipairs(AIMBOT2_BAT_SLAP_LIST) do
		local t=char:FindFirstChild(name)
		if t and t:IsA("Tool") then return t end
	end
	local bp=LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
	if bp then
		for _,name in ipairs(AIMBOT2_BAT_SLAP_LIST) do
			local t=bp:FindFirstChild(name)
			if t and t:IsA("Tool") then
				local hum=char:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum:EquipTool(t) end) end
				return t
			end
		end
	end
	for _,ch in ipairs(char:GetChildren()) do
		if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then return ch end
	end
	return nil
end

function aimbot2TrySwing()
	if aimbot2HitCD then return end
	aimbot2HitCD=true
	pcall(function()
		local char=LP.Character
		if not char then return end
		local bat=aimbot2FindBat()
		if bat then
			if bat.Parent~=char then
				local hum=char:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum:EquipTool(bat) end) end
			end
			pcall(function() bat:Activate() end)
		end
	end)
	task.delay(AIMBOT2_SWING_CD,function() aimbot2HitCD=false end)
end

function aimbot2GetClosestTarget()
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil,math.huge end
	local closest,minDist=nil,math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tRoot=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health>0 then
				local dist=(tRoot.Position-root.Position).Magnitude
				if dist<minDist then minDist=dist;closest=tRoot end
			end
		end
	end
	return closest,minDist
end

function startAimbot2()
	if aimbot2Conn then aimbot2Conn:Disconnect();aimbot2Conn=nil end
	aimbot2Enabled=true
	local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		if aimbot2PrevAutoRotate==nil then aimbot2PrevAutoRotate=hum.AutoRotate end
		hum.AutoRotate=false
	end
	aimbot2Conn=RunService.RenderStepped:Connect(function()
		if not aimbot2Enabled then return end
		if not canUseAutoPath() then setAimbot2(false);return end
		local char=LP.Character;if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
		local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end
		if not char:FindFirstChildOfClass("Tool") then
			local bat=aimbot2FindBat()
			if bat then pcall(function() hum:EquipTool(bat) end) end
		end
		local target,targetDist=aimbot2GetClosestTarget()
		if not target then return end
		local myPos=root.Position
		local targetPos=target.Position
		local direction=targetPos-myPos
		local flatDir=Vector3.new(direction.X,0,direction.Z)
		if flatDir.Magnitude>0 then flatDir=flatDir.Unit else flatDir=Vector3.zero end
		local chaseSpeed=58
		local desiredHeight=targetPos.Y+3.7
		local yVel=(desiredHeight-myPos.Y)*19.5
		if hum.FloorMaterial~=Enum.Material.Air then yVel=math.max(yVel,13) end
		yVel=math.clamp(yVel,-70,110)
		local desiredVel=Vector3.new(flatDir.X*chaseSpeed,yVel,flatDir.Z*chaseSpeed)
		root.AssemblyLinearVelocity=root.AssemblyLinearVelocity:Lerp(desiredVel,0.8)
		local toTarget=targetPos-myPos
		if toTarget.Magnitude>0.1 then
			local goalCF=CFrame.lookAt(myPos,targetPos)
			local diffCF=root.CFrame:Inverse()*goalCF
			local rx,ry,rz=diffCF:ToEulerAnglesXYZ()
			rx=math.clamp(rx,-2.5,2.5);ry=math.clamp(ry,-2.5,2.5);rz=math.clamp(rz,-2.5,2.5)
			root.AssemblyAngularVelocity=root.CFrame:VectorToWorldSpace(Vector3.new(rx*42,ry*42,rz*42))
		end
		if targetDist<=AIMBOT2_HIT_DIST then aimbot2TrySwing() end
	end)
end

function stopAimbot2()
	aimbot2Enabled=false
	if aimbot2Conn then aimbot2Conn:Disconnect();aimbot2Conn=nil end
	local c=LP.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
	end
	local hum=c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.AutoRotate=(aimbot2PrevAutoRotate==nil) and true or aimbot2PrevAutoRotate
		hum.PlatformStand=false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
	aimbot2HitCD=false
end

function setAimbot2(on)
	if on and not canUseAutoPath() then
		aimbot2Enabled=false
		if setAimbot2Visual then setAimbot2Visual(false) end
		if mobBtnRefs and mobBtnRefs.aimbot2 then mobBtnRefs.aimbot2(false) end
		pcall(saveConfig)
		return
	end
	aimbot2Enabled=on
	if on then startAimbot2() else stopAimbot2() end
	if setAimbot2Visual then setAimbot2Visual(on) end
	if mobBtnRefs and mobBtnRefs.aimbot2 then mobBtnRefs.aimbot2(on) end
	pcall(saveConfig)
end

--// ANTI DESYNC AIMBOT - .EXE integration
if antiDesyncAimbotEnabled==nil then antiDesyncAimbotEnabled=false end
antiDesyncCooldown=antiDesyncCooldown or false
antiDesyncConn=antiDesyncConn or nil
setAntiDesyncAimbotVisual=setAntiDesyncAimbotVisual or nil

function antiDesyncGetBat()
	local char=LP.Character
	if not char then return nil end
	local tool=char:FindFirstChild("Bat")
	if tool then return tool end
	local bp=LP:FindFirstChild("Backpack")
	if bp then
		tool=bp:FindFirstChild("Bat")
		if tool then tool.Parent=char;return tool end
	end
	return nil
end
function antiDesyncTryHitBat()
	if antiDesyncCooldown then return end
	antiDesyncCooldown=true
	pcall(function()
		local bat=antiDesyncGetBat()
		if bat then
			bat:Activate()
			local ev=bat:FindFirstChildWhichIsA("RemoteEvent")
			if ev then ev:FireServer() end
		end
	end)
	task.delay(0.08,function() antiDesyncCooldown=false end)
end
function antiDesyncClosestPlayer(hrp)
	if not hrp then return nil,math.huge end
	local closest,dist=nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			local tr=p.Character:FindFirstChild("HumanoidRootPart")
			if tr then
				local d=(hrp.Position-tr.Position).Magnitude
				if d<dist then dist=d;closest=p end
			end
		end
	end
	return closest,dist
end
function startAntiDesyncAimbot()
	if antiDesyncConn then return end
	antiDesyncAimbotEnabled=true
	antiDesyncConn=RunService.Heartbeat:Connect(function()
		if not antiDesyncAimbotEnabled then return end
		if not canUseAutoPath() then setAntiDesyncAimbot(false);return end
		local char=LP.Character;if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid")
		local hrp=char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end
		local target=antiDesyncClosestPlayer(hrp)
		if target and target.Character then
			local tr=target.Character:FindFirstChild("HumanoidRootPart")
			if tr then
				pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",tr) end end)
				local targetPos=tr.Position+Vector3.new(0,0.9,0)
				if (hrp.Position-targetPos).Magnitude>8 then
					hrp.CFrame=CFrame.new(targetPos)
				end
				pcall(function()
					local cam=workspace.CurrentCamera
					if cam then cam.CFrame=CFrame.new(cam.CFrame.Position,tr.Position) end
				end)
				antiDesyncTryHitBat()
			end
		end
	end)
end
function stopAntiDesyncAimbot()
	antiDesyncAimbotEnabled=false
	if antiDesyncConn then antiDesyncConn:Disconnect();antiDesyncConn=nil end
end
function setAntiDesyncAimbot(on)
	if on and not canUseAutoPath() then
		antiDesyncAimbotEnabled=false
		if setAntiDesyncAimbotVisual then setAntiDesyncAimbotVisual(false) end
		if mobBtnRefs and mobBtnRefs.antiDesync then mobBtnRefs.antiDesync(false) end
		pcall(saveConfig)
		return
	end
	antiDesyncAimbotEnabled=on
	if on then startAntiDesyncAimbot() else stopAntiDesyncAimbot() end
	if setAntiDesyncAimbotVisual then setAntiDesyncAimbotVisual(on) end
	if mobBtnRefs and mobBtnRefs.antiDesync then mobBtnRefs.antiDesync(on) end
	pcall(saveConfig)
end


--// BODY LOCK
if bodyLockEnabled==nil then bodyLockEnabled=false end
bodyLockRadius=bodyLockRadius or 60
bodyLockConn=bodyLockConn or nil
setBodyLockVisual=setBodyLockVisual or nil
bodyLockRadiusBox=bodyLockRadiusBox or nil

function getNearestBodyLockTarget()
	local character=LP.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local nearest=nil
	local shortest=math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tr=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tr and hum and hum.Health>0 then
				local d=(tr.Position-root.Position).Magnitude
				if d<=bodyLockRadius and d<shortest then
					shortest=d
					nearest=plr
				end
			end
		end
	end
	return nearest
end

function startBodyLock()
	if bodyLockConn then return end
	bodyLockEnabled=true
	bodyLockConn=RunService.Heartbeat:Connect(function()
		if not bodyLockEnabled then return end
		local character=LP.Character
		local myRoot=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not myRoot or not humanoid or humanoid.Health<=0 then return end
		local target=getNearestBodyLockTarget()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local targetPos=target.Character.HumanoidRootPart.Position
			local myPos=myRoot.Position
			local offset=Vector3.new(targetPos.X,myPos.Y,targetPos.Z)-myPos
			if offset.Magnitude>0.1 then
				humanoid.AutoRotate=false
				local lookDir=offset.Unit
				local currentDir=myRoot.CFrame.LookVector
				local cross=currentDir:Cross(lookDir)
				local currentVel=myRoot.AssemblyAngularVelocity
				myRoot.AssemblyAngularVelocity=Vector3.new(currentVel.X,cross.Y*40,currentVel.Z)
			end
		else
			humanoid.AutoRotate=true
		end
	end)
end

function stopBodyLock()
	bodyLockEnabled=false
	if bodyLockConn then bodyLockConn:Disconnect();bodyLockConn=nil end
	local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.AutoRotate=true end
end

function setBodyLock(on)
	bodyLockEnabled=on
	if on then startBodyLock() else stopBodyLock() end
	if setBodyLockVisual then setBodyLockVisual(on) end
	pcall(saveConfig)
end

LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupSpeedIndicator(char)
	if ragdollTimerEnabled then setupRagdollTimer(char) end
	if medusaCounterEnabled then setupMedusa(char) end
	if batCounterEnabled then startBatCounter() end
	if tryhardAnimEnabled then startTryhardAnim() end
	if zombieAnimEnabled then setZombieMode(true) end
	if currentAnimePack and currentAnimePack~="NINJA" then applyExeAnimePack(currentAnimePack) end
	if unwalkEnabled then task.wait(0.5);startUnwalk() end
end)
if LP.Character then setupSpeedIndicator(LP.Character); if ragdollTimerEnabled then setupRagdollTimer(LP.Character) end end
function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local function ps(o) return o and {xs=o.Position.X.Scale,xo=o.Position.X.Offset,ys=o.Position.Y.Scale,yo=o.Position.Y.Offset} or nil end
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),
		autoBatKey=ks(KB.AutoBat),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),autoTPKey=ks(KB.AutoTP),instaResetKey=ks(KB.InstaReset),guiHideKey=ks(KB.GuiHide),
		speedToggleKey=ks(KB.SpeedToggle),aimbot2Key=ks(KB.Aimbot2),antiDesyncAimbotKey=ks(KB.AntiDesyncAimbot),laggerPanelKey=exeLaggerPanelKey and exeLaggerPanelKey.Name or nil,
		grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,
		antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		batCounter=batCounterEnabled,bodyLockEnabled=bodyLockEnabled,bodyLockRadius=bodyLockRadius,
		carryMode=speedMode,laggerMode=laggerToggled,laggerCarryMode=laggerPhase==2,laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,
		autoBat=autoBatEnabled,autoSwing=autoSwingEnabled,autoBatSpeed=AUTO_BAT_SPEED,aimbot2=aimbot2Enabled,antiDesyncAimbot=antiDesyncAimbotEnabled,
		unwalkEnabled=unwalkEnabled,
		antiLag=antiLagEnabled,stretchRez=stretchRezEnabled,fpsBoostEnabled=fpsBoostEnabled,ragdollTimer=ragdollTimerEnabled,
		autoSwitchSpeed=autoSwitchSpeedEnabled,autoTurnOffSpeed=autoTurnOffSpeedEnabled,
		tryhardAnim=tryhardAnimEnabled,zombieMode=zombieAnimEnabled,
		fovEnabled=fovEnabled,fovValue=fovValue,skyTheme=currentSkyTheme,animePack=currentAnimePack,
		autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight,uiScale=uiScale,uiLocked=uiLocked,
			guiPos=ps(exeMainFrame),miniPos=ps(exeMiniButton),grabBarPos=ps(exeGrabBar)
	}
	if writefile then pcall(function() writefile("exePC.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(1) do pcall(saveConfig) end end)

-- EXE extra autosave hooks
pcall(function() game:BindToClose(function() pcall(saveConfig) end) end)
pcall(function() LP.AncestryChanged:Connect(function(_,parent) if not parent then pcall(saveConfig) end end) end)
local setInstaGrab,setInfJumpVisual,setAntiRagVisual,setMedusaVisual
local setUnwalkVisual,setAntiLagVisual,setAutoSwingVisual
local normalBox,carryBox,laggerBox,laggerCarryBox,radInput,durationBox,autoTPHeightBox,uiScaleBox
local function refreshSpeedModeLabel()
	if modeValLbl then modeValLbl.Text=laggerToggled and (laggerPhase==2 and "LAGGER CARRY" or "LAGGER NORMAL") or (speedMode and "CARRY" or "NORMAL") end
end
local function toggleCarryMode()
	if laggerToggled then
		laggerToggled=false
		laggerPhase=0
		speedMode=true
	else
		speedMode=not speedMode
	end
	refreshSpeedModeLabel()
end
local function toggleLaggerMode()
	if not laggerToggled then
		speedMode=false
		laggerToggled=true
		laggerPhase=2
	elseif laggerPhase==2 then
		laggerPhase=1
	else
		laggerPhase=2
	end
	refreshSpeedModeLabel()
end

local function setModeNormal()
	speedMode=false;laggerToggled=false;laggerPhase=0;refreshSpeedModeLabel()
	if mobBtnRefs and mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(false) end
	if mobBtnRefs and mobBtnRefs.lagger then mobBtnRefs.lagger(false) end
end
local function setModeCarry()
	speedMode=true;laggerToggled=false;laggerPhase=0;refreshSpeedModeLabel()
	if mobBtnRefs and mobBtnRefs.carrySpeed then mobBtnRefs.carrySpeed(true) end
	if mobBtnRefs and mobBtnRefs.lagger then mobBtnRefs.lagger(false) end
end
local function stopAutoSwitchSpeed()
	if autoSwitchSpeedConn then autoSwitchSpeedConn:Disconnect();autoSwitchSpeedConn=nil end
end
local function startAutoSwitchSpeed()
	if autoSwitchSpeedConn then return end
	autoSwitchSpeedConn=RunService.Heartbeat:Connect(function()
		if not autoSwitchSpeedEnabled and not autoTurnOffSpeedEnabled then stopAutoSwitchSpeed();return end
		local char=LP.Character;if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end
		local ws=hum.WalkSpeed or 16
		-- White Hub logic: when the game lowers WalkSpeed, switch to carry speed.
		if autoSwitchSpeedEnabled and ws<=AUTO_SWITCH_THRESHOLD and not speedMode then
			setModeCarry()
		-- If enabled, turn carry speed back off when WalkSpeed returns above threshold.
		elseif autoTurnOffSpeedEnabled and ws>AUTO_SWITCH_THRESHOLD and speedMode then
			setModeNormal()
		end
	end)
end

local function buildGui()
	local BG    = Color3.fromRGB(5,5,7)
	local BG2   = Color3.fromRGB(9,9,13)
	local CARD  = Color3.fromRGB(14,14,18)
	local HOV   = Color3.fromRGB(22,22,28)
	local RED   = Color3.fromRGB(255,105,180)
	local REDDIM= Color3.fromRGB(190,55,130)
	local STROKE= Color3.fromRGB(90,18,65)
	local W     = Color3.fromRGB(235,235,235)
	local DIM   = Color3.fromRGB(120,120,132)
	local INP   = Color3.fromRGB(10,10,14)
	local OFF   = Color3.fromRGB(28,28,35)
	local old=game:GetService("CoreGui"):FindFirstChild("CursedHub") or game:GetService("CoreGui"):FindFirstChild(".exe");if old then old:Destroy() end
	local pg=LP:FindFirstChild("PlayerGui");if pg then local o=pg:FindFirstChild("CursedHub") or pg:FindFirstChild(".exe");if o then o:Destroy() end end
	local gui=Instance.new("ScreenGui")
	gui.Name=".exe";gui.ResetOnSpawn=false;gui.DisplayOrder=10;gui.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end
	local main=Instance.new("Frame",gui)
	main.Size=UDim2.new(0,315,0,460);main.Position=UDim2.new(0,20,0,20);exeMainFrame=main
	main.BackgroundColor3=BG;main.BackgroundTransparency=0;main.BorderSizePixel=0;main.ClipsDescendants=false
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
	local menuBg=Instance.new("ImageLabel",main)
	menuBg.Name="ExeMenuBackground";menuBg.Size=UDim2.new(1,0,1,0);menuBg.Position=UDim2.new(0,0,0,0)
	menuBg.BackgroundTransparency=1;menuBg.Image="rbxthumb://type=Asset&id=129219792103700&w=420&h=420";menuBg.ScaleType=Enum.ScaleType.Crop;menuBg.ImageTransparency=0;menuBg.ZIndex=1
	Instance.new("UICorner",menuBg).CornerRadius=UDim.new(0,12)
	local scaleObj=Instance.new("UIScale",main);scaleObj.Scale=uiScale
	local function drag(f,lockable)
		local dn,ds,sp,di=false
		f.InputBegan:Connect(function(i)
			if lockable and uiLocked then return end
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true;ds=i.Position;sp=f.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false;pcall(saveConfig) end end)
			end
		end)
		f.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if lockable and uiLocked then dn=false;return end
			if i==di and dn then
				local nX=sp.X.Offset+(i.Position.X-ds.X)
				local nY=sp.Y.Offset+(i.Position.Y-ds.Y)
				f.Position=UDim2.new(sp.X.Scale,nX,sp.Y.Scale,nY)
			end
		end)
	end
	drag(main,true)
	local hdr=Instance.new("Frame",main)
	hdr.Size=UDim2.new(1,0,0,44);hdr.BackgroundColor3=BG2;hdr.BackgroundTransparency=1;hdr.BorderSizePixel=0;hdr.ZIndex=2
	Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,12)
	local ttl=Instance.new("TextLabel",hdr)
	ttl.Size=UDim2.new(0,42,1,0);ttl.Position=UDim2.new(0,10,0,0)
	ttl.BackgroundTransparency=1;ttl.Text=".EXE";ttl.ZIndex=4
	ttl.TextColor3=RED;ttl.Font=Enum.Font.GothamBlack;ttl.TextSize=15
	ttl.TextXAlignment=Enum.TextXAlignment.Left
	local pages,tabButtons={},{}
	local function selectPage(id)
		for name,page in pairs(pages) do page.Visible=(name==id) end
		for name,btn in pairs(tabButtons) do
			local active=name==id
			TS:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=active and Color3.fromRGB(38,13,30) or BG2,TextColor3=active and RED or DIM}):Play()
		end
	end
	local tabs={{"mov","mov"},{"combat","combat"},{"keys","keys"},{"pad","pad"},{"util","util"},{"set","set"}}
	for i,t in ipairs(tabs) do
		local btn=Instance.new("TextButton",hdr)
		btn.Size=UDim2.new(0,32,0,24);btn.Position=UDim2.new(0,58+(i-1)*34,0.5,-12)
		btn.BackgroundColor3=BG2;btn.BackgroundTransparency=0;btn.BorderSizePixel=0;btn.Text=t[2]:upper();btn.TextColor3=DIM
		btn.Font=Enum.Font.GothamBlack;btn.TextSize=8;btn.ZIndex=3
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
		Instance.new("UIStroke",btn).Color=STROKE
		tabButtons[t[1]]=btn
		btn.MouseEnter:Connect(function() if not pages[t[1]].Visible then TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=HOV,TextColor3=W}):Play() end end)
		btn.MouseLeave:Connect(function() if not pages[t[1]].Visible then TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=BG2,TextColor3=DIM}):Play() end end)
		btn.Activated:Connect(function() selectPage(t[1]) end)
	end
	local closeBtn=Instance.new("TextButton",hdr)
	closeBtn.Size=UDim2.new(0,28,0,28);closeBtn.Position=UDim2.new(1,-34,0.5,-14)
	closeBtn.BackgroundColor3=BG2;closeBtn.BackgroundTransparency=1;closeBtn.BorderSizePixel=0;closeBtn.ZIndex=4
	closeBtn.Text="-";closeBtn.TextColor3=REDDIM;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=22
	Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
	closeBtn.MouseEnter:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(32,12,28),TextColor3=REDDIM}):Play() end)
	closeBtn.MouseLeave:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=BG2,TextColor3=REDDIM}):Play() end)
	local miniBtn=Instance.new("TextButton",gui)
	miniBtn.Size=UDim2.new(0,108,0,28);miniBtn.Position=UDim2.new(0,26,0,26);exeMiniButton=miniBtn
	miniBtn.BackgroundColor3=BG2;miniBtn.BorderSizePixel=0
	miniBtn.Text=".EXE";miniBtn.TextColor3=RED;miniBtn.Font=Enum.Font.GothamBold;miniBtn.TextSize=11
	miniBtn.ZIndex=20;miniBtn.Visible=false
	Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,8)
	local miniStroke=Instance.new("UIStroke",miniBtn);miniStroke.Color=STROKE;miniStroke.Thickness=1.2
	drag(miniBtn,false)
	miniBtn.MouseEnter:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=HOV}):Play() end)
	miniBtn.MouseLeave:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=BG2}):Play() end)
	local function showGui() main.Visible=true;miniBtn.Visible=false end
	local function hideGui() main.Visible=false;miniBtn.Visible=true end
	closeBtn.MouseButton1Click:Connect(hideGui)
	miniBtn.MouseButton1Click:Connect(showGui)
	local function mkPage(id)
		local sf=Instance.new("ScrollingFrame",main)
		sf.Size=UDim2.new(1,0,1,-44);sf.Position=UDim2.new(0,0,0,44)
		sf.BackgroundTransparency=1;sf.BorderSizePixel=0;sf.ClipsDescendants=true;sf.Visible=false;sf.ZIndex=2
		sf.ScrollBarThickness=0;sf.ScrollBarImageTransparency=1
		sf.CanvasSize=UDim2.new(0,0,0,0);sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
		local ll=Instance.new("UIListLayout",sf);ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Padding=UDim.new(0,2)
		local pad=Instance.new("UIPadding",sf)
		pad.PaddingLeft=UDim.new(0,7);pad.PaddingRight=UDim.new(0,7)
		pad.PaddingTop=UDim.new(0,7);pad.PaddingBottom=UDim.new(0,10)
		pages[id]=sf
		return sf
	end
	local movPage,combatPage,keysPage,padPage,utilPage,setPage=mkPage("mov"),mkPage("combat"),mkPage("keys"),mkPage("pad"),mkPage("util"),mkPage("set")
	local loByPage={}
	local function LO(page) loByPage[page]=(loByPage[page] or 0)+1;return loByPage[page] end
	local function mkSect(page,txt)
		local f=Instance.new("Frame",page);f.Size=UDim2.new(1,0,0,22);f.BackgroundTransparency=1;f.BorderSizePixel=0;f.LayoutOrder=LO(page);f.ZIndex=3
		local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,-8,1,0);l.Position=UDim2.new(0,8,0,0)
		l.BackgroundTransparency=1;l.Text=txt:upper();l.TextColor3=RED;l.ZIndex=4
		l.Font=Enum.Font.GothamBlack;l.TextSize=9;l.TextXAlignment=Enum.TextXAlignment.Left
		l.TextStrokeTransparency=0.85;l.TextStrokeColor3=Color3.fromRGB(0,0,0)
	end
	local function mkRow(page,h)
		local f=Instance.new("Frame",page);f.Size=UDim2.new(1,0,0,h or 32)
		f.BackgroundColor3=CARD;f.BackgroundTransparency=0.55;f.BorderSizePixel=0;f.LayoutOrder=LO(page);f.ZIndex=3
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
		local rowStroke=Instance.new("UIStroke",f);rowStroke.Color=Color3.fromRGB(45,45,52);rowStroke.Thickness=0.7;rowStroke.Transparency=0
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=HOV,BackgroundTransparency=0.55}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=CARD,BackgroundTransparency=0.55}):Play() end)
		return f
	end
	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row);l.Size=UDim2.new(0.62,0,1,0);l.Position=UDim2.new(0,9,0,0)
		l.BackgroundTransparency=1;l.Text=txt:upper();l.TextColor3=W;l.ZIndex=4
		l.Font=Enum.Font.GothamBlack;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left
	end
	local function mkPill(row,offset)
		local pill=Instance.new("Frame",row);pill.Size=UDim2.new(0,36,0,19)
		pill.Position=UDim2.new(1,-(offset or 42),0.5,-9.5)
		pill.BackgroundColor3=OFF;pill.BorderSizePixel=0;pill.ZIndex=3
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pill);dot.Size=UDim2.new(0,13,0,13);dot.Position=UDim2.new(0,3,0.5,-6.5)
		dot.BackgroundColor3=DIM;dot.BorderSizePixel=0;dot.ZIndex=4
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		return pill,dot
	end
	local function animPill(pill,dot,on)
		TS:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundColor3=on and Color3.fromRGB(100,18,70) or OFF}):Play()
		TS:Create(dot,TweenInfo.new(0.18,Enum.EasingStyle.Back),{
			Position=on and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5),
			BackgroundColor3=on and RED or DIM
		}):Play()
	end
	local function mkToggle(page,txt,cb)
		local row=mkRow(page,32);mkLabel(row,txt)
		local pill,dot=mkPill(row,42)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() if _anyKeyListening then return end;on=not on;sv(on);cb(on) end)
		pill.ZIndex=3;dot.ZIndex=4
		return sv
	end
	local function mkBox(parent,default,w,xOff,cb)
		local tb=Instance.new("TextBox",parent)
		tb.Size=UDim2.new(0,w or 50,0,22);tb.Position=UDim2.new(1,-(xOff or 56),0.5,-11)
		tb.BackgroundColor3=INP;tb.BorderSizePixel=0;tb.Text=tostring(default);tb.TextColor3=W
		tb.Font=Enum.Font.GothamBlack;tb.TextSize=11;tb.ClearTextOnFocus=false;tb.ZIndex=5
		Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
		local bs=Instance.new("UIStroke",tb);bs.Color=Color3.fromRGB(30,30,38);bs.Thickness=1
		tb.Focused:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Color=REDDIM}):Play() end)
		tb.FocusLost:Connect(function()
			TS:Create(bs,TweenInfo.new(0.12),{Color=Color3.fromRGB(30,30,38)}):Play()
			if cb then local n=tonumber(tb.Text);if n then cb(n) else tb.Text=tostring(default) end end
		end)
		return tb
	end
	local GAMEPAD_KEYS={
		[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,
		[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,
		[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,
		[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true
	}
	local function isGamepadInput(inp) return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil end
	local function isBindableInput(inp)
		if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end
		if inp.UserInputType==Enum.UserInputType.Keyboard then return true end
		return isGamepadInput(inp) and GAMEPAD_KEYS[inp.KeyCode]==true
	end
	local function kbMatch(entry,kc) return kc and (kc==entry.kb or (entry.gp and kc==entry.gp)) end
	local keyRefs={}
	local function keyLabel(entry,mode)
		if mode=="pad" then return (entry.gp and entry.gp.Name:upper()) or "NONE" end
		return (entry.kb and entry.kb.Name:upper()) or "NONE"
	end
	local function refreshKeyRefs(entry)
		for _,r in ipairs(keyRefs) do if r.entry==entry then r.btn.Text=keyLabel(entry,r.mode) end end
	end
	local function mkKBButton(parent,kbEntry,mode)
		local btn=Instance.new("TextButton",parent)
		btn.Size=UDim2.new(0,70,0,22);btn.Position=UDim2.new(1,-76,0.5,-11)
		btn.BackgroundColor3=INP;btn.BorderSizePixel=0
		btn.Text=keyLabel(kbEntry,mode);btn.TextColor3=W
		btn.Font=Enum.Font.GothamBlack;btn.TextSize=9;btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
		table.insert(keyRefs,{entry=kbEntry,btn=btn,mode=mode})
		local listening=false
		local conn=nil
		local previous=btn.Text
		local listenStart=0
		local function stopListen(cancel)
			listening=false
			_anyKeyListening=false
			if conn then conn:Disconnect();conn=nil end
			if cancel then btn.Text=previous else refreshKeyRefs(kbEntry) end
			btn.TextColor3=W
		end
		btn.Activated:Connect(function()
			if listening then stopListen(true);return end
			previous=btn.Text
			listening=true
			_anyKeyListening=true
			listenStart=tick()
			btn.Text="..."
			btn.TextColor3=RED
			conn=UIS.InputBegan:Connect(function(inp,gpe)
				if not listening then return end
				if inp.KeyCode==Enum.KeyCode.Escape then stopListen(true);return end
				if inp.KeyCode==Enum.KeyCode.Unknown then return end
				if mode=="pad" then
					-- Accept Xbox/PlayStation controller button KeyCodes directly.
					-- Some executors report gamepad input weirdly, so do not rely only on UserInputType.
					if tick()-listenStart<0.05 then return end
					if not GAMEPAD_KEYS[inp.KeyCode] then return end
					kbEntry.gp=inp.KeyCode
				else
					if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
					kbEntry.kb=inp.KeyCode
				end
				stopListen(false)
				pcall(saveConfig)
				pcall(function() if saveMobileButtonsConfigOnly then saveMobileButtonsConfigOnly() end end)
			end)
		end)
		return btn
	end
	local function mkKeyRow(page,txt,kbEntry,mode)
		local row=mkRow(page,32);mkLabel(row,txt);mkKBButton(row,kbEntry,mode or "key")
	end
	local function mkModeRow(page)
		local row=mkRow(page,32);mkLabel(row,"Mode")
		modeValLbl=Instance.new("TextLabel",row)
		modeValLbl.Size=UDim2.new(0,110,1,0);modeValLbl.Position=UDim2.new(1,-116,0,0)
		modeValLbl.BackgroundTransparency=1;modeValLbl.Text="NORMAL";modeValLbl.TextColor3=RED
		modeValLbl.Font=Enum.Font.GothamBlack;modeValLbl.TextSize=11;modeValLbl.TextXAlignment=Enum.TextXAlignment.Right
		-- Mode display only; pressing it does nothing.
		refreshSpeedModeLabel()
	end
	local function mkActionButton(page,labelTxt,btnTxt,cb)
		local row=mkRow(page,32);mkLabel(row,labelTxt)
		local btn=Instance.new("TextButton",row)
		btn.Size=UDim2.new(0,74,0,22);btn.Position=UDim2.new(1,-80,0.5,-11)
		btn.BackgroundColor3=INP;btn.BorderSizePixel=0;btn.Text=btnTxt:upper();btn.TextColor3=RED
		btn.Font=Enum.Font.GothamBlack;btn.TextSize=9;btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
		local bs=Instance.new("UIStroke",btn);bs.Color=STROKE;bs.Thickness=1
		btn.MouseEnter:Connect(function() TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=HOV}):Play() end)
		btn.MouseLeave:Connect(function() TS:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=INP}):Play() end)
		btn.Activated:Connect(cb)
		return btn
	end
	local function mkArrowSelector(page,labelTxt,names,current,cb)
		local row=mkRow(page,36);mkLabel(row,labelTxt)
		local idx=1
		for i,n in ipairs(names) do if n==current then idx=i;break end end
		local prev=Instance.new("TextButton",row);prev.Size=UDim2.new(0,26,0,22);prev.Position=UDim2.new(1,-128,0.5,-11);prev.BackgroundColor3=INP;prev.BorderSizePixel=0;prev.Text="<";prev.TextColor3=RED;prev.Font=Enum.Font.GothamBlack;prev.TextSize=12;prev.ZIndex=5;Instance.new("UICorner",prev).CornerRadius=UDim.new(0,5)
		local val=Instance.new("TextLabel",row);val.Size=UDim2.new(0,70,0,22);val.Position=UDim2.new(1,-98,0.5,-11);val.BackgroundColor3=INP;val.BorderSizePixel=0;val.Text=tostring(names[idx]):upper();val.TextColor3=W;val.Font=Enum.Font.GothamBlack;val.TextSize=8;val.TextXAlignment=Enum.TextXAlignment.Center;val.ZIndex=5;Instance.new("UICorner",val).CornerRadius=UDim.new(0,5)
		local nxt=Instance.new("TextButton",row);nxt.Size=UDim2.new(0,26,0,22);nxt.Position=UDim2.new(1,-26,0.5,-11);nxt.BackgroundColor3=INP;nxt.BorderSizePixel=0;nxt.Text=">";nxt.TextColor3=RED;nxt.Font=Enum.Font.GothamBlack;nxt.TextSize=12;nxt.ZIndex=5;Instance.new("UICorner",nxt).CornerRadius=UDim.new(0,5)
		local function apply()
			local name=names[idx];val.Text=tostring(name):upper();cb(name)
		end
		prev.Activated:Connect(function() idx=(idx-2+#names)%#names+1;apply() end)
		nxt.Activated:Connect(function() idx=idx%#names+1;apply() end)
		return val
	end

	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,220,0,34);pbFrame.Position=UDim2.new(0.5,-110,1,-50);exeGrabBar=pbFrame
	pbFrame.BackgroundColor3=BG2;pbFrame.BorderSizePixel=0;pbFrame.Active=true;pbFrame.ClipsDescendants=false
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,9)
	drag(pbFrame,false)
	progressPct=Instance.new("TextLabel",pbFrame)
	progressPct.Size=UDim2.new(0,44,0,14);progressPct.Position=UDim2.new(0,9,0,3)
	progressPct.BackgroundTransparency=1;progressPct.Text="0%";progressPct.TextColor3=W
	progressPct.Font=Enum.Font.GothamBlack;progressPct.TextSize=10;progressPct.TextXAlignment=Enum.TextXAlignment.Left
	progressRadLbl=Instance.new("TextLabel",pbFrame)
	progressRadLbl.Size=UDim2.new(0,120,0,16);progressRadLbl.Position=UDim2.new(1,-128,0,7)
	progressRadLbl.BackgroundTransparency=1;progressRadLbl.Text=string.format("RADIUS: %.2g",Steal.StealRadius)
	progressRadLbl.TextColor3=W;progressRadLbl.Font=Enum.Font.GothamBlack;progressRadLbl.TextSize=11;progressRadLbl.TextXAlignment=Enum.TextXAlignment.Right;progressRadLbl.Visible=false
	progressDurLbl=Instance.new("TextLabel",pbFrame)
	progressDurLbl.Size=UDim2.new(0,120,0,14);progressDurLbl.Position=UDim2.new(1,-128,0,21)
	progressDurLbl.BackgroundTransparency=1;progressDurLbl.Text=string.format("DURATION: %.2gs",Steal.StealDuration)
	progressDurLbl.TextColor3=W;progressDurLbl.Font=Enum.Font.GothamBlack;progressDurLbl.TextSize=10;progressDurLbl.TextXAlignment=Enum.TextXAlignment.Right;progressDurLbl.Visible=false
	local pbg=Instance.new("Frame",pbFrame)
	pbg.Size=UDim2.new(1,-18,0,8);pbg.Position=UDim2.new(0,9,0,21)
	pbg.BackgroundColor3=Color3.fromRGB(15,15,17);pbg.BorderSizePixel=0
	Instance.new("UICorner",pbg).CornerRadius=UDim.new(1,0)
	progressFill=Instance.new("Frame",pbg)
	progressFill.Size=UDim2.new(0,0,1,0);progressFill.BackgroundColor3=RED;progressFill.BorderSizePixel=0
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)

	mkSect(movPage,"Speed Configuration")
	do local row=mkRow(movPage,32);mkLabel(row,"Normal Speed");normalBox=mkBox(row,NS,55,62,function(v) if v>0 and v<=500 then NS=v end;saveConfig() end) end
	do local row=mkRow(movPage,32);mkLabel(row,"Carry Speed");carryBox=mkBox(row,CS,55,62,function(v) if v>0 and v<=500 then CS=v end;saveConfig() end) end
	mkKeyRow(movPage,"Speed Key",KB.SpeedToggle,"key")
	mkModeRow(movPage)
	mkSect(movPage,"Auto Speed")
	setAutoSwitchSpeedVisual=mkToggle(movPage,"Auto Switch Speed",function(on) autoSwitchSpeedEnabled=on;if on or autoTurnOffSpeedEnabled then startAutoSwitchSpeed() else stopAutoSwitchSpeed() end;saveConfig() end)
	setAutoTurnOffSpeedVisual=mkToggle(movPage,"Auto Turn Off Speed",function(on) autoTurnOffSpeedEnabled=on;if on or autoSwitchSpeedEnabled then startAutoSwitchSpeed() else stopAutoSwitchSpeed() end;saveConfig() end)
	mkSect(movPage,"Lagger Speed")
	do local row=mkRow(movPage,32);mkLabel(row,"Lagger Normal Speed");laggerBox=mkBox(row,LAGGER_SPEED,55,62,function(v) if v>0 and v<=500 then LAGGER_SPEED=v end;saveConfig() end) end
	do local row=mkRow(movPage,32);mkLabel(row,"Lagger Carry Speed");laggerCarryBox=mkBox(row,LAGGER_CARRY_SPEED,55,62,function(v) if v>0 and v<=500 then LAGGER_CARRY_SPEED=v end;saveConfig() end) end
	mkKeyRow(movPage,"Lagger Key",KB.LaggerToggle,"key")
	mkSect(movPage,"Jump")
	setInfJumpVisual=mkToggle(movPage,"Infinite Jump",function(on) infJumpEnabled=on;saveConfig() end)
	setAntiRagVisual=mkToggle(movPage,"Anti Ragdoll",function(on) antiRagdollEnabled=on;if on then startAntiRagdoll() else stopAntiRagdoll() end;saveConfig() end)
	setUnwalkVisual=mkToggle(movPage,"Unwalk",function(on) unwalkEnabled=on;if on then startUnwalk() else stopUnwalk() end;saveConfig() end)
	mkSect(movPage,"Animations")
	setTryhardVisual=mkToggle(movPage,"Try Hard Animation",function(on) tryhardAnimEnabled=on;if on then startTryhardAnim() else stopTryhardAnim() end;saveConfig() end)
	setZombieVisual=mkToggle(movPage,"Zombie Animation",function(on) zombieAnimEnabled=on;setZombieMode(on);saveConfig() end)

	mkSect(combatPage,"Steal Configuration")
	do local row=mkRow(combatPage,32);mkLabel(row,"Radius");radInput=mkBox(row,Steal.StealRadius,55,62,function(v) if v>=0.5 and v<=300 then Steal.StealRadius=v;if progressRadLbl then progressRadLbl.Text=string.format("RADIUS: %.2g",Steal.StealRadius) end end;saveConfig() end) end
	do local row=mkRow(combatPage,32);mkLabel(row,"Duration");durationBox=mkBox(row,Steal.StealDuration,55,62,function(v) if v>=0.05 and v<=10 then Steal.StealDuration=v;if progressDurLbl then progressDurLbl.Text=string.format("DURATION: %.2gs",Steal.StealDuration) end elseif durationBox then durationBox.Text=tostring(Steal.StealDuration) end;saveConfig() end) end
	setInstaGrab=mkToggle(combatPage,"Auto Steal",function(on) Steal.AutoStealEnabled=on;if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false;if setInstaGrab then setInstaGrab(false) end end else stopAutoSteal() end;saveConfig() end)
	mkSect(combatPage,"Bat Aimbot")
	do
		local row=mkRow(combatPage,32);mkLabel(row,"Bat Aimbot")
		local pill,dot=mkPill(row,42)
		local abOn=false
		local function svAutoBat(s) abOn=s;animPill(pill,dot,s) end
		autoBatSetVisual=svAutoBat
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() if _anyKeyListening then return end;abOn=not abOn;svAutoBat(abOn);if abOn then queueAutoBatStart() else autoBatEnabled=false;disableAutoBat() end;saveConfig() end)
	end
	do local row=mkRow(combatPage,32);mkLabel(row,"Bat Aimbot Speed");autoBatSpeedBox=mkBox(row,AUTO_BAT_SPEED,55,62,function(v) if v and v>0 and v<=500 then AUTO_BAT_SPEED=v else autoBatSpeedBox.Text=tostring(AUTO_BAT_SPEED) end;saveConfig() end) end
	setAimbot2Visual=mkToggle(combatPage,"Aimbot 2 (Anti Bat Bypass)",function(on) setAimbot2(on) end)
	setAntiDesyncAimbotVisual=mkToggle(combatPage,"Anti Desync Aimbot",function(on) setAntiDesyncAimbot(on) end)
	setAutoSwingVisual=mkToggle(combatPage,"Auto Swing",function(on) autoSwingEnabled=on;saveConfig() end)
	if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
	mkSect(combatPage,"Auto Path")
	autoLeftSetVisual=mkToggle(combatPage,"Auto Left",function(on) autoLeftEnabled=on;if on then queueAutoLeftStart() else stopAutoLeft() end;saveConfig() end)
	autoRightSetVisual=mkToggle(combatPage,"Auto Right",function(on) autoRightEnabled=on;if on then queueAutoRightStart() else stopAutoRight() end;saveConfig() end)
	mkSect(combatPage,"Counter")
	setMedusaVisual=mkToggle(combatPage,"Medusa Counter",function(on) medusaCounterEnabled=on;if on then setupMedusa(LP.Character) else stopMedusaCounter() end;saveConfig() end)
	setBatCounterVisual=mkToggle(combatPage,"Bat Counter",function(on) batCounterEnabled=on;if on then startBatCounter() else stopBatCounter() end;saveConfig() end)
	mkSect(combatPage,"Body Lock")
	setBodyLockVisual=mkToggle(combatPage,"Body Lock",function(on) setBodyLock(on) end)
	do local row=mkRow(combatPage,32);mkLabel(row,"Body Lock Radius");bodyLockRadiusBox=mkBox(row,bodyLockRadius,55,62,function(v) if v>=1 and v<=500 then bodyLockRadius=v else bodyLockRadiusBox.Text=tostring(bodyLockRadius) end;saveConfig() end) end

	mkSect(keysPage,"Move Keys")
	mkKeyRow(keysPage,"Speed Key",KB.SpeedToggle,"key")
	mkKeyRow(keysPage,"Lagger Key",KB.LaggerToggle,"key")
	mkKeyRow(keysPage,"Drop Brainrot Key",KB.DropBrainrot,"key")
	mkKeyRow(keysPage,"TP Down Key",KB.TPFloor,"key")
	mkKeyRow(keysPage,"Auto TP Down",KB.AutoTP,"key")
	mkSect(keysPage,"Combat")
	mkKeyRow(keysPage,"Bat Aimbot Key",KB.AutoBat,"key")
	mkKeyRow(keysPage,"Aimbot 2 Key",KB.Aimbot2,"key")
	mkKeyRow(keysPage,"Anti Desync Aimbot Key",KB.AntiDesyncAimbot,"key")
	mkKeyRow(keysPage,"Auto Right Key",KB.AutoRight,"key")
	mkKeyRow(keysPage,"Auto Left Key",KB.AutoLeft,"key")
	mkKeyRow(keysPage,"Insta Reset Key",KB.InstaReset,"key")
	mkSect(keysPage,"Interface")
	mkKeyRow(keysPage,"UI Toggle Key",KB.GuiHide,"key")

	mkSect(padPage,"Move Keys")
	mkKeyRow(padPage,"Speed Key",KB.SpeedToggle,"pad")
	mkKeyRow(padPage,"Lagger Key",KB.LaggerToggle,"pad")
	mkKeyRow(padPage,"Drop Brainrot Key",KB.DropBrainrot,"pad")
	mkKeyRow(padPage,"TP Down Key",KB.TPFloor,"pad")
	mkKeyRow(padPage,"Auto TP Down",KB.AutoTP,"pad")
	mkSect(padPage,"Combat")
	mkKeyRow(padPage,"Bat Aimbot Key",KB.AutoBat,"pad")
	mkKeyRow(padPage,"Aimbot 2 Key",KB.Aimbot2,"pad")
	mkKeyRow(padPage,"Anti Desync Aimbot Key",KB.AntiDesyncAimbot,"pad")
	mkKeyRow(padPage,"Auto Right Key",KB.AutoRight,"pad")
	mkKeyRow(padPage,"Auto Left Key",KB.AutoLeft,"pad")
	mkKeyRow(padPage,"Insta Reset Key",KB.InstaReset,"pad")
	mkSect(padPage,"Interface")
	mkKeyRow(padPage,"UI Toggle Key",KB.GuiHide,"pad")

	mkSect(utilPage,"Visual")
	setAntiLagVisual=mkToggle(utilPage,"Anti Lag",function(on) if on then enableAntiLag() else disableAntiLag() end;saveConfig() end)
	setFpsBoostVisual=mkToggle(utilPage,"FPS Boost",function(on) fpsBoostEnabled=on;if on then applyFPSBoost() end;saveConfig() end)
	setRagdollTimerVisual=mkToggle(utilPage,"Ragdoll Timer",function(on) ragdollTimerEnabled=on;if LP.Character then setupRagdollTimer(LP.Character) end;saveConfig() end)
	mkSect(utilPage,"Custom Sky")
	mkArrowSelector(utilPage,"Custom Sky",DRIFT_SKY_ORDER,currentSkyTheme,function(name) currentSkyTheme=name;applyDriftSkyTheme(name);saveConfig() end)
	mkSect(utilPage,"Animation Pack")
	mkArrowSelector(utilPage,"Animations",EXE_ANIME_NAMES,currentAnimePack,function(name) currentAnimePack=name;applyExeAnimePack(name);saveConfig() end)
	mkActionButton(utilPage,"Search Animations","Search",function() openExeAnimationSearch() end)
	mkSect(utilPage,"Camera")
	setFovVisual=mkToggle(utilPage,"FOV Change",function(on) setFovEnabled(on);saveConfig() end)
	do local row=mkRow(utilPage,32);mkLabel(row,"FOV Value");fovValueBox=mkBox(row,fovValue,55,62,function(v) if v>=30 and v<=120 then fovValue=v;if fovEnabled and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v end else fovValueBox.Text=tostring(fovValue) end;saveConfig() end) end
	setStretchRezVisual=mkToggle(utilPage,"Stretch Rez",function(on) if on then enableStretchRez() else disableStretchRez() end;saveConfig() end)
	mkActionButton(utilPage,"Reset FOV","Reset",function() resetFovAndCamera();if setFovVisual then setFovVisual(false) end;saveConfig() end)
	mkSect(utilPage,"Insta Reset")
	mkActionButton(utilPage,"Insta Reset","Open",function() openExeInstaResetPanel() end)
	mkSect(setPage,"Lagger Panel")
	mkActionButton(setPage,"Lagger Panel","Open",function() openExeLaggerPanel() end)
	mkSect(setPage,"Interface Configuration")
	setLockVisual=mkToggle(setPage,"Lock UI",function(on) uiLocked=on;saveConfig() end)
	do
		local row=mkRow(setPage,32);mkLabel(row,"UI Scale")
		local UI_SCALES={75,90,100,110,125,150}
		local uiBtnW=28
		local uiStartX=-6-(#UI_SCALES*(uiBtnW+2))
		local refs={}
		local function refreshBtns(selected)
			for _,ref in ipairs(refs) do
				local active=ref.sz==selected
				ref.btn.BackgroundColor3=active and Color3.fromRGB(100,18,70) or INP
				ref.btn.TextColor3=active and RED or W
			end
		end
		local selected=math.floor((uiScale*100)+0.5)
		for i,sz in ipairs(UI_SCALES) do
			local sb=Instance.new("TextButton",row)
			sb.Size=UDim2.new(0,uiBtnW,0,20);sb.Position=UDim2.new(1,uiStartX+(i-1)*(uiBtnW+2),0.5,-10)
			sb.BackgroundColor3=(selected==sz) and Color3.fromRGB(100,18,70) or INP;sb.BorderSizePixel=0
			sb.Text=tostring(sz);sb.TextColor3=(selected==sz) and RED or W;sb.Font=Enum.Font.GothamBlack;sb.TextSize=8;sb.ZIndex=5
			Instance.new("UICorner",sb).CornerRadius=UDim.new(0,5)
			local bs=Instance.new("UIStroke",sb);bs.Color=STROKE;bs.Thickness=1
			table.insert(refs,{btn=sb,sz=sz})
			sb.Activated:Connect(function() uiScale=sz/100;scaleObj.Scale=uiScale;refreshBtns(sz);saveConfig() end)
		end
	end

	UIS.InputBegan:Connect(function(input,gpe)
		if _anyKeyListening then return end
		if input.UserInputType==Enum.UserInputType.Keyboard then
			if gpe or UIS:GetFocusedTextBox() then return end
		elseif not isGamepadInput(input) then return end
		if not isBindableInput(input) then return end
		local kc=input.KeyCode
		if kbMatch(KB.LaggerToggle,kc) then
			toggleLaggerMode();saveConfig()
		elseif kbMatch(KB.SpeedToggle,kc) then
			toggleCarryMode();saveConfig()
		elseif kbMatch(KB.DropBrainrot,kc) then runDropKeybindBurst()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.AutoTP,kc) then
			autoTPEnabled=not autoTPEnabled
			if autoTPEnabled then startAutoTP() else stopAutoTP() end
			if setAutoTPVisual then setAutoTPVisual(autoTPEnabled) end
			saveConfig()
		elseif kbMatch(KB.InstaReset,kc) then cursedInstaReset()
		elseif kbMatch(KB.AutoLeft,kc) then
			autoLeftEnabled=not autoLeftEnabled
			if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end
			if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
			saveConfig()
		elseif kbMatch(KB.AutoRight,kc) then
			autoRightEnabled=not autoRightEnabled
			if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end
			if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
			saveConfig()
		elseif kbMatch(KB.AutoBat,kc) then
			if not autoBatEnabled then queueAutoBatStart();if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end;if mobBtnRefs and mobBtnRefs.autoBat then mobBtnRefs.autoBat(autoBatEnabled) end else autoBatEnabled=false;disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end;if mobBtnRefs and mobBtnRefs.autoBat then mobBtnRefs.autoBat(false) end end
			saveConfig()
		elseif kbMatch(KB.GuiHide,kc) then if main.Visible then hideGui() else showGui() end
		end
	end)
	selectPage("mov")
end

local _savedCfg = nil
local function loadConfigKeys()
	if not(isfile and isfile("exePC.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("exePC.json")) end)
	if not ok or not cfg then return end
	_savedCfg=cfg
	local function lk(e,d) if type(d)~="table" then return end;if d.kb and Enum.KeyCode[d.kb] then e.kb=Enum.KeyCode[d.kb] end;if d.gp and Enum.KeyCode[d.gp] then e.gp=Enum.KeyCode[d.gp] end end
	lk(KB.DropBrainrot,cfg.dropBrainrotKey);lk(KB.AutoLeft,cfg.autoLeftKey);lk(KB.AutoRight,cfg.autoRightKey)
	lk(KB.AutoBat,cfg.autoBatKey);lk(KB.LaggerToggle,cfg.laggerToggleKey)
	lk(KB.TPFloor,cfg.tpFloorKey);lk(KB.AutoTP,cfg.autoTPKey);lk(KB.InstaReset,cfg.instaResetKey);lk(KB.GuiHide,cfg.guiHideKey);lk(KB.SpeedToggle,cfg.speedToggleKey);lk(KB.Aimbot2,cfg.aimbot2Key);lk(KB.AntiDesyncAimbot,cfg.antiDesyncAimbotKey)
	if cfg.laggerPanelKey and Enum.KeyCode[cfg.laggerPanelKey] then exeLaggerPanelKey=Enum.KeyCode[cfg.laggerPanelKey] end
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.grabRadius and type(cfg.grabRadius)=="number" then Steal.StealRadius=cfg.grabRadius else Steal.StealRadius=60 end
	if cfg.stealDuration and type(cfg.stealDuration)=="number" then Steal.StealDuration=cfg.stealDuration else Steal.StealDuration=1.4 end
	if cfg.laggerSpeed and type(cfg.laggerSpeed)=="number" then LAGGER_SPEED=cfg.laggerSpeed end
	if cfg.laggerCarrySpeed and type(cfg.laggerCarrySpeed)=="number" then LAGGER_CARRY_SPEED=cfg.laggerCarrySpeed end
	if cfg.autoTPHeight and type(cfg.autoTPHeight)=="number" then autoTPHeight=cfg.autoTPHeight end
	if cfg.autoSwing~=nil then autoSwingEnabled=cfg.autoSwing==true end
	if cfg.autoBatSpeed and type(cfg.autoBatSpeed)=="number" then AUTO_BAT_SPEED=math.clamp(cfg.autoBatSpeed,1,500) end
	if cfg.bodyLockRadius and type(cfg.bodyLockRadius)=="number" then bodyLockRadius=math.clamp(cfg.bodyLockRadius,1,500) end
	if cfg.uiScale and type(cfg.uiScale)=="number" then uiScale=math.clamp(cfg.uiScale,0.6,1.6) end
	if cfg.uiLocked~=nil then uiLocked=cfg.uiLocked==true end
	if cfg.fovValue and type(cfg.fovValue)=="number" then fovValue=math.clamp(cfg.fovValue,30,120) end
	if cfg.skyTheme and DRIFT_SKY_PRESETS[cfg.skyTheme] then currentSkyTheme=cfg.skyTheme end
	if cfg.animePack and EXE_ANIME_PACKS[cfg.animePack] then currentAnimePack=cfg.animePack end
end
local function loadConfigState()
	local cfg=_savedCfg;if not cfg then return end
	if normalBox then normalBox.Text=tostring(NS) end
	if carryBox then carryBox.Text=tostring(CS) end
	if radInput then radInput.Text=tostring(Steal.StealRadius) end
	if durationBox then durationBox.Text=tostring(Steal.StealDuration) end
	if progressRadLbl then progressRadLbl.Text=string.format("RADIUS: %.2g",Steal.StealRadius) end
	if progressDurLbl then progressDurLbl.Text=string.format("DURATION: %.2gs",Steal.StealDuration) end
	if laggerBox then laggerBox.Text=tostring(LAGGER_SPEED) end
	if laggerCarryBox then laggerCarryBox.Text=tostring(LAGGER_CARRY_SPEED) end
	if autoTPHeightBox then autoTPHeightBox.Text=tostring(autoTPHeight) end
	if uiScaleBox then uiScaleBox.Text=tostring(uiScale) end
	if fovValueBox then fovValueBox.Text=tostring(fovValue) end
	if bodyLockRadiusBox then bodyLockRadiusBox.Text=tostring(bodyLockRadius) end
	if autoBatSpeedBox then autoBatSpeedBox.Text=tostring(AUTO_BAT_SPEED) end
	if cfg.guiPos and exeMainFrame then exeMainFrame.Position=UDim2.new(cfg.guiPos.xs or 0,cfg.guiPos.xo or 20,cfg.guiPos.ys or 0,cfg.guiPos.yo or 20) end
	if cfg.miniPos and exeMiniButton then exeMiniButton.Position=UDim2.new(cfg.miniPos.xs or 0,cfg.miniPos.xo or 26,cfg.miniPos.ys or 0,cfg.miniPos.yo or 26) end
	if cfg.grabBarPos and exeGrabBar then exeGrabBar.Position=UDim2.new(cfg.grabBarPos.xs or 0.5,cfg.grabBarPos.xo or -110,cfg.grabBarPos.ys or 1,cfg.grabBarPos.yo or -50) end
	if setLockVisual then setLockVisual(uiLocked) end
	task.spawn(function()
		task.wait(0.15)
		if cfg.antiRagdoll then antiRagdollEnabled=true;if setAntiRagVisual then setAntiRagVisual(true) end;startAntiRagdoll() end
		if cfg.autoStealEnabled then Steal.AutoStealEnabled=true;if setInstaGrab then setInstaGrab(true) end;pcall(startAutoSteal) end
		if cfg.infiniteJump then infJumpEnabled=true;if setInfJumpVisual then setInfJumpVisual(true) end end
		if cfg.medusaCounter then medusaCounterEnabled=true;if setMedusaVisual then setMedusaVisual(true) end;setupMedusa(LP.Character) end
		if cfg.batCounter then batCounterEnabled=true;if setBatCounterVisual then setBatCounterVisual(true) end;startBatCounter() end
		if cfg.bodyLockEnabled then bodyLockEnabled=true;if setBodyLockVisual then setBodyLockVisual(true) end;startBodyLock() end
		if cfg.laggerMode then laggerToggled=true;speedMode=false;laggerPhase=cfg.laggerCarryMode and 2 or 1;refreshSpeedModeLabel()
		elseif cfg.carryMode then speedMode=false;toggleCarryMode() end
		if cfg.autoTPEnabled then autoTPEnabled=true;if setAutoTPVisual then setAutoTPVisual(true) end;startAutoTP() end
		if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
		if cfg.autoBat then autoBatEnabled=true;if autoBatSetVisual then autoBatSetVisual(true) end;queueAutoBatStart() end
		if cfg.aimbot2 then setAimbot2(true) end
		if cfg.antiDesyncAimbot then setAntiDesyncAimbot(true) end
		if cfg.unwalkEnabled then unwalkEnabled=true;if setUnwalkVisual then setUnwalkVisual(true) end;task.spawn(function() task.wait(0.5);startUnwalk() end) end
		if cfg.autoSwitchSpeed then autoSwitchSpeedEnabled=true;if setAutoSwitchSpeedVisual then setAutoSwitchSpeedVisual(true) end;startAutoSwitchSpeed() end
		if cfg.autoTurnOffSpeed then autoTurnOffSpeedEnabled=true;if setAutoTurnOffSpeedVisual then setAutoTurnOffSpeedVisual(true) end;startAutoSwitchSpeed() end
		if cfg.ragdollTimer then ragdollTimerEnabled=true;if setRagdollTimerVisual then setRagdollTimerVisual(true) end;if LP.Character then setupRagdollTimer(LP.Character) end end
		if cfg.tryhardAnim then tryhardAnimEnabled=true;if setTryhardVisual then setTryhardVisual(true) end;startTryhardAnim() end
		if cfg.zombieMode then zombieAnimEnabled=true;if setZombieVisual then setZombieVisual(true) end;setZombieMode(true) end
		if cfg.fpsBoostEnabled then fpsBoostEnabled=true;if setFpsBoostVisual then setFpsBoostVisual(true) end;applyFPSBoost() end
		if cfg.fovEnabled then fovEnabled=true;if setFovVisual then setFovVisual(true) end;setFovEnabled(true) end
		if currentSkyTheme and currentSkyTheme~="None" then applyDriftSkyTheme(currentSkyTheme) end
		if currentAnimePack and currentAnimePack~="NINJA" then applyExeAnimePack(currentAnimePack) end
		if cfg.antiLag then enableAntiLag();if setAntiLagVisual then setAntiLagVisual(true) end end
		if cfg.stretchRez then enableStretchRez();if setStretchRezVisual then setStretchRezVisual(true) end end
	end)
end
loadConfigKeys()
buildGui()
loadConfigState()


-- EXE dedicated new aimbot keybind listener
UIS.InputBegan:Connect(function(input,gpe)
	if _anyKeyListening then return end
	if UIS:GetFocusedTextBox() then return end
	if input.KeyCode==Enum.KeyCode.Unknown then return end
	local kc=input.KeyCode
	local function matches(entry)
		return entry and (kc==entry.kb or (entry.gp and kc==entry.gp))
	end
	if matches(KB.Aimbot2) then
		setAimbot2(not aimbot2Enabled)
		pcall(saveConfig)
	elseif matches(KB.AntiDesyncAimbot) then
		setAntiDesyncAimbot(not antiDesyncAimbotEnabled)
		pcall(saveConfig)
	end
end)

print(".EXE PC LOADED")
