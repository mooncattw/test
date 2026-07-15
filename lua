local noWalkConnection1
local noWalkConnection2
local lastPos

local fovConnection = nil
local oldFOV = nil

local TweenService = game:GetService("TweenService")
 
--// NOVA HUB CONFIG SYSTEM

local HttpService = game:GetService("HttpService")

local FolderName = "Nova Hub"
local FileName = FolderName.."/config.json"

local Config = {

    ["Super Jump"] = false,
    ["FOV"] = false,
    ["Lock UI"] = false,
    ["No Camera Collision"] = false,
    ["Auto Exit Duel"] = false,
    ["Speed Enabled"] = false,
    ["Speed Minimized"] = false,
    ["AutoPlay Minimized"] = false,
    ["Speed Customizer"] = false,
    ["Optimizer"] = false,
    ["Spin Body"] = false,
    ["Anti Ragdoll"] = false,
    ["Anti FPS Devourer"] = false,
    ["Anti Sentry"] = false,
    ["Infinite Jump"] = false,
    ["Xray Base"] = false,
    ["ESP Players"] = false,
    ["No Walk Animation"] = false,
    ["Auto Bat"] = false,
    ["Lock Target"] = false,
    ["Auto Medusa"] = false,
    ["Melee Aimbot"] = false,
    ["TP Down"] = false,
    ["Auto Play"] = false,
    ["Fast Steal"] = false,
    ["Drop Brainrot"] = false,
    ["No Player Collision"] = false,
    ["Fling"] = false,
    ["Instant Grab"] = false,

    ["LockButtonX"] = 0.9,
    ["LockButtonY"] = 0.85,
    ["LockButtonOffsetX"] = -70,
    ["LockButtonOffsetY"] = 0,

    ["Toggle Button X"] = 1,
    ["Toggle Button Y"] = 0,
    ["Toggle Button OffsetX"] = -70,
    ["Toggle Button OffsetY"] = 70,

    ["TP Down Button X"] = 0.5,
    ["TP Down Button Y"] = 0.7,
    ["TP Down Button OffsetX"] = -70,
    ["TP Down Button OffsetY"] = 0,

    ["Fling Button X"] = 0.5,
    ["Fling Button Y"] = 0.85,
    ["Fling Button OffsetX"] = -70,
    ["Fling Button OffsetY"] = 0,

    ["Walk GUI X"] = 0.5,
    ["Walk GUI Y"] = 0.15,
    ["Walk GUI OffsetX"] = -100,
    ["Walk GUI OffsetY"] = 0,

    ["Drop Button X"] = 0.5,
    ["Drop Button Y"] = 0.55,
    ["Drop Button OffsetX"] = -70,
    ["Drop Button OffsetY"] = 0,

    ["Spin Button X"] = 0.5,
    ["Spin Button Y"] = 0.75,
    ["Spin Button OffsetX"] = -70,
    ["Spin Button OffsetY"] = 0,

    ["AutoPlay GUI X"] = 0.5,
    ["AutoPlay GUI Y"] = 0.15,
    ["AutoPlay GUI OffsetX"] = -100,
    ["AutoPlay GUI OffsetY"] = 0,

    ["Speed GUI X"] = 0.5,
    ["Speed GUI Y"] = 0.2,
    ["Speed GUI OffsetX"] = -100,
    ["Speed GUI OffsetY"] = 0,

    ["Manual TP"] = 0.8,
    ["TP Button X"] = false,
    ["TP Button Y"] = 0.6,
    ["TP Button OffsetX"] = 0,
    ["TP Button OffsetY"] = 0,

    -- TEXTBOX VALUES
    ["Speed Value"] = 40,
    ["Steal Speed Value"] = 21.2,
    ["Jump Value"] = 60,

    ["AutoPlay Speed"] = 59.2,
    ["AutoPlay StealSpeed"] = 28.9,
    ["AutoPlay Cooldown"] = 0.1,

    ["Melee Range"] = 20,
    ["Spin Speed"] = 40,
    ["FOV Value"] = 90,

    -- AUTOPLAY POINTS
    ["AutoPlay Point1 X"] = 1,
    ["AutoPlay Point1 Z"] = 1,

    ["AutoPlay Point2 X"] = 1,
    ["AutoPlay Point2 Z"] = 1,

    ["AutoPlay Point3 X"] = 1,
    ["AutoPlay Point3 Z"] = 1,

    ["AutoPlay Point4 X"] = 1,
    ["AutoPlay Point4 Z"] = 1,

    ["AutoPlay Point5 X"] = 1,
    ["AutoPlay Point5 Z"] = 1
}

if not isfolder(FolderName) then
    makefolder(FolderName)
end

if not isfile(FileName) then
    writefile(FileName, HttpService:JSONEncode(Config))
end

local function LoadConfig()

    local success,data = pcall(readfile,FileName)

    if success then
        local decoded = HttpService:JSONDecode(data)

        for k,v in pairs(decoded) do
            Config[k] = v
        end
    end

end


function SaveConfig()
    writefile(FileName,HttpService:JSONEncode(Config))
end

LoadConfig()

task.spawn(function()
    task.wait(1)

    for text, enabled in pairs(Config) do
        if enabled then
            ApplyToggle(text, true)
        end
    end
end)

local playActive = false
local currentRoute = nil
local minimized = false

local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")

local optimizerEnabled = false
local savedLighting = {}
local optimized = {}
local optimizerConnection

-- 🔥 ANTI-LAG
local function applyAntiLag(instance)
    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Smoke") or instance:IsA("Fire") then
        
        if optimized[instance] == nil then
            optimized[instance] = instance.Enabled
            instance.Enabled = false
        end

    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        
        if optimized[instance] == nil then
            optimized[instance] = instance.Transparency
            instance.Transparency = 1
        end

    elseif instance:IsA("BasePart") then
        
        if not optimized[instance] then
            optimized[instance] = {
                instance.Material,
                instance.Reflectance,
                instance.CastShadow
            }
        end

        instance.Material = Enum.Material.Plastic
        instance.Reflectance = 0
        instance.CastShadow = false
    end
end

-- ✅ ACTIVAR (MISMA LÓGICA QUE TU SCRIPT)
function enableOptimizer()
    if optimizerEnabled then return end
    optimizerEnabled = true

    savedLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }

    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- Quitar efectos (igual que tu script)
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("BloomEffect") or child:IsA("BlurEffect") or child:IsA("SunRaysEffect") or child:IsA("ColorCorrectionEffect") then
            if optimized[child] == nil then
                optimized[child] = child.Enabled
                child.Enabled = false
            end
        end
    end

    -- Aplicar a TODO + lógica ULTRA (CastShadow forzado)
    for _, v in ipairs(workspace:GetDescendants()) do
        applyAntiLag(v)

        if v:IsA("BasePart") then
            v.CastShadow = false
        end
    end

    -- Tiempo real
    optimizerConnection = workspace.DescendantAdded:Connect(function(desc)
        if optimizerEnabled then
            applyAntiLag(desc)

            if desc:IsA("BasePart") then
                desc.CastShadow = false
            end
        end
    end)
end

-- ❌ DESACTIVAR
function disableOptimizer()
    if not optimizerEnabled then return end
    optimizerEnabled = false

    if optimizerConnection then
        optimizerConnection:Disconnect()
        optimizerConnection = nil
    end

    for k,v in pairs(savedLighting) do
        Lighting[k] = v
    end

    for obj,val in pairs(optimized) do
        if obj and obj.Parent then
            if typeof(val) == "table" then
                obj.Material = val[1]
                obj.Reflectance = val[2]
                obj.CastShadow = val[3]

            elseif typeof(val) == "boolean" then
                pcall(function() obj.Enabled = val end)

            elseif typeof(val) == "number" then
                pcall(function() obj.Transparency = val end)
            end
        end
    end

    optimized = {}
end

--// XRAY BASE

local baseOriginalTransparencies = {}
local plotConnections = {}
local xrayConnection

local function applyXray(plot)
    if baseOriginalTransparencies[plot] then return end

    baseOriginalTransparencies[plot] = {}

    local oldHL = plot:FindFirstChild("BaseXRayHighlight")
    if oldHL then
        oldHL:Destroy()
    end

    for _, part in ipairs(plot:GetDescendants()) do
        if part:IsA("BasePart") then
            
            local oldPartHL = part:FindFirstChild("BaseXRayHighlight")
            if oldPartHL then
                oldPartHL:Destroy()
            end

            if part.Transparency < 0.6 then
                baseOriginalTransparencies[plot][part] = part.Transparency
                part.Transparency = 0.68
            end
        end
    end

    plotConnections[plot] = plot.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            if desc.Transparency < 0.6 then
                baseOriginalTransparencies[plot][desc] = desc.Transparency
                desc.Transparency = 0.68
            end
        end
    end)
end

function toggleESPBases(enable)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end

    if not enable then
        for _, conn in pairs(plotConnections) do
            conn:Disconnect()
        end
        plotConnections = {}

        if xrayConnection then
            xrayConnection:Disconnect()
            xrayConnection = nil
        end

        for plot, parts in pairs(baseOriginalTransparencies) do
            for part, original in pairs(parts) do
                if part and part.Parent then
                    part.Transparency = original
                end
            end
        end

        baseOriginalTransparencies = {}
        return
    end

    for _, plot in ipairs(plots:GetChildren()) do
        applyXray(plot)
    end

    xrayConnection = plots.ChildAdded:Connect(function(newPlot)
        task.wait(0.2)
        applyXray(newPlot)
    end)
end

--// ESP PLAYERS

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local espConnections = {}
local espEnabled = false

local function createESP(plr)
	if plr == lp then return end
	if not plr.Character then return end
	if plr.Character:FindFirstChild("ESP_BLUE") then return end

	local char = plr.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not (hrp and head) then return end

--------------------------------------------------
-- HIGHLIGHT AZUL EQUILIBRADO
--------------------------------------------------

local highlight = Instance.new("Highlight")
highlight.Name = "ESP_BLUE"

highlight.FillColor = Color3.fromRGB(0, 110, 220)
highlight.OutlineColor = Color3.fromRGB(0, 110, 220)

highlight.FillTransparency = 0.4
highlight.OutlineTransparency = 0.15

highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

highlight.Parent = char
end

local function removeESP(plr)
	if not plr.Character then return end

	local char = plr.Character

	local highlight = char:FindFirstChild("ESP_BLUE")
	if highlight then highlight:Destroy() end
end

function toggleESPPlayers(enable)
	espEnabled = enable

	if enable then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				if plr.Character then
					createESP(plr)
				end

				local conn = plr.CharacterAdded:Connect(function()
					task.wait(0.2)
					if espEnabled then
						createESP(plr)
					end
				end)

				table.insert(espConnections, conn)
			end
		end

		local playerAddedConn = Players.PlayerAdded:Connect(function(plr)
			if plr == lp then return end

			local charAddedConn = plr.CharacterAdded:Connect(function()
				task.wait(0.2)
				if espEnabled then
					createESP(plr)
				end
			end)

			table.insert(espConnections, charAddedConn)
		end)

		table.insert(espConnections, playerAddedConn)

	else
		for _, plr in ipairs(Players:GetPlayers()) do
			removeESP(plr)
		end

		for _, conn in ipairs(espConnections) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end

		espConnections = {}
	end
end

-- =========================
-- MANUAL TP SISTEMA
-- =========================

ManualTPEnabled = false

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local char
local hrp
local humanoid

local tpGui
local debounce = false

local function setupCharacter(c)
    char = c
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

-- SPAWN DETECTION

local PUNTOS_ACTIVACION = {
    Vector3.new(-465.7, -7.1, 4.8),
    Vector3.new(-465.9, -6.9, 113.2)
}

local DISTANCIA_ACTIVACION = 5

local TP_COORDS = {

    [1] = {
        Vector3.new(-471,-8,91),
        Vector3.new(-486,-5,95)
    },

    [2] = {
        Vector3.new(-463,-8,40),
        Vector3.new(-488,-6,19)
    }

}

local coords = nil
local detectedSpawn = nil

task.spawn(function()

    while true do
        task.wait(0.5)

        if detectedSpawn then continue end
        if not hrp then continue end

        local pos = hrp.Position

        for i,punto in ipairs(PUNTOS_ACTIVACION) do

            local dist = (pos - punto).Magnitude

            if dist < DISTANCIA_ACTIVACION then
                detectedSpawn = i
                coords = TP_COORDS[i]
                break
            end

        end

    end

end)

-- =========================
-- TP FUNCTION
-- =========================

local function doTP()

    if not coords then return end
    if not hrp then return end

    for _,v in ipairs(coords) do

        hrp.CFrame = CFrame.new(v)
        task.wait(0.1)

    end

end

-- TELEPORT

local function teleport(pos)

    if not hrp then return end

    local cf = CFrame.new(pos)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = cf

    local lowerTorso = char:FindFirstChild("LowerTorso")
    if lowerTorso then
        lowerTorso.CFrame = cf
    end

    if camera then
        camera.CFrame = cf
    end

end

local function doTP()

    if not coords then return end

    teleport(coords[1])
    task.wait(0.15)
    teleport(coords[2])

end

-- BOTON

function CreateTPButton()

    if tpGui then return end

    tpGui = Instance.new("ScreenGui")
    tpGui.Name = "TPButtonGui"
    tpGui.ResetOnSpawn = false
    tpGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)

    button.Position = UDim2.new(
        Config["TP Button X"],
        Config["TP Button OffsetX"],
        Config["TP Button Y"],
        Config["TP Button OffsetY"]
    )

    button.Text = "TP"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(0,120,255)
    button.Parent = tpGui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

    -- MISMO DRAG QUE TUS OTROS BOTONES
    button.Active = true
    button.Draggable = not UILocked

    -- GUARDAR POSICIÓN
    button.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            local pos = button.Position

            Config["TP Button X"] = pos.X.Scale
            Config["TP Button OffsetX"] = pos.X.Offset
            Config["TP Button Y"] = pos.Y.Scale
            Config["TP Button OffsetY"] = pos.Y.Offset

            SaveConfig()

        end
    end)

    -- CLICK TP
    button.MouseButton1Click:Connect(function()

        if not ManualTPEnabled then return end
        if debounce then return end

        debounce = true
        button.BackgroundColor3 = Color3.fromRGB(200,0,0)

        doTP()

        task.wait(0.2)

        button.BackgroundColor3 = Color3.fromRGB(0,120,255)
        debounce = false

    end)

end

function RemoveTPButton()

    if tpGui then
        tpGui:Destroy()
        tpGui = nil
    end

end

-- FLING SISTEMA

local flingGui
local flingActive = false
local flingConnection

local function startFling()

    if flingConnection then return end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    flingConnection = RunService.Heartbeat:Connect(function()

        if not flingActive then return end

        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if character and root then

            local vel = root.Velocity
            local movel = 0.1

            root.Velocity = vel * 10000 + Vector3.new(0,10000,0)

            RunService.RenderStepped:Wait()

            if root then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()

            if root then
                root.Velocity = vel + Vector3.new(0,movel,0)
            end

        end

    end)

end

local function stopFling()
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
end

local function setupFlingTouch()

    local char = lp.Character
    if not char then return end

    local root = char:WaitForChild("HumanoidRootPart")

    root.Touched:Connect(function(hit)

        local otherChar = hit.Parent
        local otherPlayer = game.Players:GetPlayerFromCharacter(otherChar)

        if otherPlayer and otherPlayer ~= lp then

            local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                otherRoot.AssemblyLinearVelocity = Vector3.new(0,200,0)
            end

        end

    end)

end

--// =========================
-- ANTI FPS DEVOURER SISTEMA
-- =========================

local ANTI_FPS_DEVOURER = {
    enabled = false,
    connections = {},
    hiddenAccessories = {}
}

-- Ocultar accesorio específico
local function removeAccessory(accessory)
    if not ANTI_FPS_DEVOURER.hiddenAccessories[accessory] then
        ANTI_FPS_DEVOURER.hiddenAccessories[accessory] = accessory.Parent
        accessory.Parent = nil
    end
end

-- Escanear modelo completo
local function scanModel(model)
    for _, obj in ipairs(model:GetDescendants()) do
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
    end
end

function enableAntiFPSDevourer()
    if ANTI_FPS_DEVOURER.enabled then return end
    ANTI_FPS_DEVOURER.enabled = true

    -- Escanea cualquier accesorio o ropa 3d de modelos y usuarios 
    for _, obj in ipairs(workspace:GetDescendants()) do
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
    end

    -- Detectar nuevos objetos 
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if ANTI_FPS_DEVOURER.enabled then
if obj:IsA("Accessory")
or obj:IsA("Shirt")
or obj:IsA("Pants")
or obj:IsA("ShirtGraphic") then
    removeAccessory(obj)
end
        end
    end)

    table.insert(ANTI_FPS_DEVOURER.connections, conn)
end

function disableAntiFPSDevourer()
    if not ANTI_FPS_DEVOURER.enabled then return end
    ANTI_FPS_DEVOURER.enabled = false

    -- Desconectar
    for _, conn in ipairs(ANTI_FPS_DEVOURER.connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end

    ANTI_FPS_DEVOURER.connections = {}

    -- Restaurar accesorios
for accessory, originalParent in pairs(ANTI_FPS_DEVOURER.hiddenAccessories) do
    if accessory and accessory.Parent ~= originalParent then
        if originalParent then
            accessory.Parent = originalParent
        end
    end
end

    ANTI_FPS_DEVOURER.hiddenAccessories = {}
end

--// SERVICIOS 

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Hitbox Expander (controlado por toggle "Aimbot")
local hitboxExpanded = false
local originalHRPSizes = {}          -- para guardar y restaurar
local hitboxPlayerAddedConn = nil

local character, hrp, hum

--// MELEE AIMBOT

local MELEE_RANGE = 45
local MELEE_ONLY_ENEMIES = true

local meleeEnabled = false
local meleeConnection
local meleeAlignOrientation
local meleeAttachment

local function isValidMeleeTarget(humanoid, rootPart)
    if not (humanoid and rootPart) then return false end
    if humanoid.Health <= 0 then return false end
    
    if MELEE_ONLY_ENEMIES then
        local targetPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
        if not targetPlayer or targetPlayer == player then
            return false
        end
    end
    
    return true
end

local function getClosestMeleeTarget(hrp)
    local closest
    local minDist = MELEE_RANGE
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local char = p.Character
        if not char then continue end
        
        local targetHrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if isValidMeleeTarget(hum, targetHrp) then
            local dist = (targetHrp.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = targetHrp
            end
        end
    end
    
    return closest
end

local function createMeleeAimbot(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 8)
    local humanoid = char:WaitForChild("Humanoid", 8)
    
    if not (hrp and humanoid) then return end
    
    -- Cleanup viejo
    if meleeAlignOrientation then
        pcall(function() meleeAlignOrientation:Destroy() end)
    end
    if meleeAttachment then
        pcall(function() meleeAttachment:Destroy() end)
    end
    
    meleeAttachment = Instance.new("Attachment")
    meleeAttachment.Parent = hrp
    
    meleeAlignOrientation = Instance.new("AlignOrientation")
    meleeAlignOrientation.Attachment0 = meleeAttachment
    meleeAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    meleeAlignOrientation.RigidityEnabled = true
    meleeAlignOrientation.MaxTorque = 100000
    meleeAlignOrientation.Responsiveness = 200
    meleeAlignOrientation.Parent = hrp
    
    if meleeConnection then
        meleeConnection:Disconnect()
    end
    
    meleeConnection = RunService.RenderStepped:Connect(function()
        if not char.Parent or not meleeEnabled then return end
        
        local target = getClosestMeleeTarget(hrp)
        
        if target then
            humanoid.AutoRotate = false
            meleeAlignOrientation.Enabled = true
            local targetPos = Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
            meleeAlignOrientation.CFrame = CFrame.lookAt(hrp.Position, targetPos)
        else
            meleeAlignOrientation.Enabled = false
            humanoid.AutoRotate = true
        end
    end)
end

local function disableMeleeAimbot()
    meleeEnabled = false
    
    if meleeConnection then
        meleeConnection:Disconnect()
        meleeConnection = nil
    end
    
    if meleeAlignOrientation then
        meleeAlignOrientation.Enabled = false
        pcall(function() meleeAlignOrientation:Destroy() end)
        meleeAlignOrientation = nil
    end
    
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.AutoRotate = true
    end
    
    if meleeAttachment then
        pcall(function() meleeAttachment:Destroy() end)
        meleeAttachment = nil
    end
end

local function createAutoPlayGui()

--// SPEED CUSTOMIZER GUI (GUI + DRAG + MINIMIZE + ROUTE CUBES)

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPlayGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,200,0,320)
main.Position = UDim2.new(
    Config["AutoPlay GUI X"],
    Config["AutoPlay GUI OffsetX"],
    Config["AutoPlay GUI Y"],
    Config["AutoPlay GUI OffsetY"]
)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.BackgroundTransparency = 0.35
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,120,255)
stroke.Thickness = 2
stroke.Parent = main

-- DRAG AREA
local dragHandle = Instance.new("Frame")
dragHandle.Size = UDim2.new(1,0,0,30)
dragHandle.BackgroundTransparency = 1
dragHandle.Parent = main

local playButton = Instance.new("TextButton")
playButton.Size = UDim2.new(0,180,0,34)
playButton.Position = UDim2.new(0.5,-90,0,30)
playButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
playButton.Text = "Play"
playButton.TextColor3 = Color3.fromRGB(255,255,255)
playButton.TextSize = 14
playButton.Font = Enum.Font.GothamBold
playButton.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,120,255)
stroke.Thickness = 1
stroke.Parent = playButton

Instance.new("UICorner", playButton).CornerRadius = UDim.new(0,6)

main.Active = true
main.Draggable = not UILocked

-- TITLE (centered)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Auto Play"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(0,120,255)
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = main

-- MINIMIZE BUTTON
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0,18,0,18)
minimizeButton.Position = UDim2.new(0,8,0,6)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "▲"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.TextColor3 = Color3.fromRGB(0,120,255)
minimizeButton.Parent = main

local pointElements = {}

-- ======================
-- PUNTOS FIJOS
-- ======================

local pointsData = {}

local function createPoint(yPos, text, index)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9,0,0,25)
    frame.Position = UDim2.new(0.05,0,0,yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = main
    table.insert(pointElements, frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.3,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

local box1 = Instance.new("TextBox")
box1.Size = UDim2.new(0.3,0,1,0)
box1.Position = UDim2.new(0.35,0,0,0)
box1.BackgroundColor3 = Color3.fromRGB(25,25,25)
box1.Text = tostring(Config["AutoPlay Point"..index.." Z"])
box1.TextColor3 = Color3.fromRGB(255,255,255)
box1.Font = Enum.Font.Gotham
box1.TextSize = 13
box1.Parent = frame
Instance.new("UICorner", box1)

-- BORDE AZUL
local stroke1 = Instance.new("UIStroke")
stroke1.Color = Color3.fromRGB(0,120,255)
stroke1.Parent = box1

local box2 = Instance.new("TextBox")
box2.Size = UDim2.new(0.3,0,1,0)
box2.Position = UDim2.new(0.7,0,0,0)
box2.BackgroundColor3 = Color3.fromRGB(25,25,25)
box2.Text = tostring(Config["AutoPlay Point"..index.." X"])
box2.TextColor3 = Color3.fromRGB(255,255,255)
box2.Font = Enum.Font.Gotham
box2.TextSize = 13
box2.Parent = frame
Instance.new("UICorner", box2)

-- BORDE AZUL
local stroke2 = Instance.new("UIStroke")
stroke2.Color = Color3.fromRGB(0,120,255)
stroke2.Parent = box2

box1.FocusLost:Connect(function()

    Config["AutoPlay Point"..index.." Z"] = tonumber(box1.Text) or 0
    SaveConfig()

end)

box2.FocusLost:Connect(function()

    Config["AutoPlay Point"..index.." X"] = tonumber(box2.Text) or 0
    SaveConfig()

end)

    -- GUARDAR REFERENCIA
    pointsData[index] = {
        zBox = box1,
        xBox = box2
    }
end

-- CREAR 4 PUNTOS
createPoint(65, "Point 1", 1)
createPoint(95, "Point 2", 2)
createPoint(125, "Point 3", 3)
createPoint(155, "Point 4", 4)
createPoint(185, "Point 5", 5)

-- ======================
-- POINT SETTINGS
-- ======================

local function createSetting(yPos, text, defaultValue)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.9,0,0,25)
frame.Position = UDim2.new(0.05,0,0,yPos)
frame.BackgroundTransparency = 1
frame.Parent = main

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.45,0,1,0)
label.BackgroundTransparency = 1
label.Text = text
label.Font = Enum.Font.Gotham
label.TextSize = 13
label.TextColor3 = Color3.fromRGB(255,255,255)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(0.45,0,1,0)
box.Position = UDim2.new(0.55,0,0,0)
box.BackgroundColor3 = Color3.fromRGB(25,25,25)
box.Text = tostring(defaultValue or "")
box.TextColor3 = Color3.fromRGB(255,255,255)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.Parent = frame

Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0,120,255)
stroke.Parent = box

return frame, box

end

local speedFrame, speedBox = createSetting(220,"Speed",59.2)
local stealSpeedFrame, stealSpeedBox = createSetting(250,"Steal Spd",28.9)
local cooldownFrame, cooldownBox = createSetting(280,"Cooldown",0.1)

speedBox.FocusLost:Connect(function()

    Config["AutoPlay Speed"] = tonumber(speedBox.Text)
    SaveConfig()

end)

stealSpeedBox.FocusLost:Connect(function()

    Config["AutoPlay StealSpeed"] = tonumber(stealSpeedBox.Text)
    SaveConfig()

end)

cooldownBox.FocusLost:Connect(function()

    Config["AutoPlay Cooldown"] = tonumber(cooldownBox.Text)
    SaveConfig()

end)

speedBox.Text = tostring(Config["AutoPlay Speed"])
stealSpeedBox.Text = tostring(Config["AutoPlay StealSpeed"])
cooldownBox.Text = tostring(Config["AutoPlay Cooldown"])

main.Size = UDim2.new(0,200,0,320)

-- ======================
-- CUBOS VISUALES AUTO WALK
-- ======================

local autoWalkParts = {}

local function clearAutoWalkParts()

for _,p in pairs(autoWalkParts) do
if p then
p:Destroy()
end
end

autoWalkParts = {}

end

local function createAutoWalkPart(pos)

local part = Instance.new("Part")
part.Size = Vector3.new(1.2,1.2,1.2)
part.Anchored = true
part.CanCollide = false
part.CanTouch = false
part.CanQuery = false
part.Material = Enum.Material.Neon
part.Color = Color3.fromRGB(0,120,255)
part.Position = pos
part.Name = "AutoWalkPoint"
part.Parent = workspace

table.insert(autoWalkParts, part)

end

local function drawRoute(route)

clearAutoWalkParts()

-- cubo en StartPoint
createAutoWalkPart(route.StartPoint)

-- cubos en cada punto de la ruta
for _,point in ipairs(route.Route) do
createAutoWalkPart(point)
end

end

-- ======================
-- RUTAS
-- ======================

local routes = {

    START_A = {

        StartPoint = Vector3.new(-484.37, -5.22, 94.32),

        Route = {

            Vector3.new(-476, -8, 29),
            Vector3.new(-480, -6, 25),
            Vector3.new(-486, -6, 25),
            Vector3.new(-475.75, -7.03, 94.03)

        }

    },

    START_B = {

        StartPoint = Vector3.new(-485.08, -5.22, 25.94),

        Route = {

            Vector3.new(-476.07, -8, 91.05),
            Vector3.new(-480.07, -6, 95.05),
            Vector3.new(-486.07, -6, 95.05),
            Vector3.new(-476.08, -6.89, 25.65)

        }

    }

}

local function round(n)
    return math.floor(n + 0.5)
end

local function loadRouteToTextboxes()

    for i = 1,4 do
        if pointsData[i] then
            pointsData[i].zBox.Text = "1"
            pointsData[i].xBox.Text = "1"
        end
    end

end

local function buildRouteFromTextboxes(originalRoute)

    local newRoute = {
        Route = {},
        StartPoint = nil
    }

    local invertZ = (detectedSpawn == 1)

-- PUNTOS 1-4
for i = 1,4 do
    local original = originalRoute.Route[i] -- ahora también toma Route[4]

    local offsetX = tonumber(pointsData[i].xBox.Text) or 0
    local offsetZ = tonumber(pointsData[i].zBox.Text) or 0

    if invertZ then
        offsetZ = -offsetZ
    end

    table.insert(newRoute.Route, Vector3.new(
        original.X + offsetX,
        original.Y,
        original.Z + offsetZ
    ))
end

-- PUNTO 5 = igual que punto 4 (usa StartPoint de la ruta base)
do
    local baseStart = originalRoute.StartPoint -- toma StartPoint de la ruta base según detectedSpawn

    local offsetX = tonumber(pointsData[5].xBox.Text) or 0
    local offsetZ = tonumber(pointsData[5].zBox.Text) or 0

    if invertZ then
        offsetZ = -offsetZ
    end

    newRoute.StartPoint = Vector3.new(
        baseStart.X + offsetX,
        baseStart.Y,
        baseStart.Z + offsetZ
    )
end

    return newRoute
end

-- ======================
-- MOVEMENT SYSTEM (PATHFINDING)
-- ======================

local leftEnabled = false
local rightEnabled = false
local stealMode = false
local currentRouteId = 0
local selectedRoute = nil
local routeRunning = false

local RunService = game:GetService("RunService")

local function getSpeed()

local n = tonumber(speedBox.Text)

if n and n > 0 then
return n
end

return 59.2

end

local function getStealSpeed()

local n = tonumber(stealSpeedBox.Text)

if n and n > 0 then
return n
end

return 28.9

end

local function pathMove(point)

local char = player.Character
if not char then return end

local humanoid = char:FindFirstChild("Humanoid")
local root = char:FindFirstChild("HumanoidRootPart")

if not humanoid or not root then return end

local path = PathfindingService:CreatePath({
AgentRadius = 2,
AgentHeight = 5,
AgentCanJump = false
})

path:ComputeAsync(root.Position, point)

local waypoints = {}

if path.Status == Enum.PathStatus.Success then
waypoints = path:GetWaypoints()
else
table.insert(waypoints,{Position = point})
end

local index = 2

while routeRunning and index <= #waypoints do

if not routeRunning then
root.AssemblyLinearVelocity = Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
break
end

local target = waypoints[index].Position

local direction = target - root.Position
direction = Vector3.new(direction.X,0,direction.Z)

local distance = direction.Magnitude

if distance < 2 then
index += 1
else

direction = direction.Unit

local currentSpeed

if stealMode then
currentSpeed = getStealSpeed()
else
currentSpeed = getSpeed()
end

root.AssemblyLinearVelocity = Vector3.new(
direction.X * currentSpeed,
root.AssemblyLinearVelocity.Y,
direction.Z * currentSpeed
)

end

task.wait()

end

root.AssemblyLinearVelocity = Vector3.new(0,root.AssemblyLinearVelocity.Y,0)

end

local function directMove(point,myRouteId)

local char = player.Character
if not char then return end

local root = char:FindFirstChild("HumanoidRootPart")
if not root then return end

while routeRunning and currentRouteId == myRouteId do

local direction = point - root.Position
direction = Vector3.new(direction.X,0,direction.Z)

if direction.Magnitude < 2 then
break
end

direction = direction.Unit

local speed

if stealMode then
speed = getStealSpeed()
else
speed = getSpeed()
end

root.AssemblyLinearVelocity = Vector3.new(
direction.X * speed,
root.AssemblyLinearVelocity.Y,
direction.Z * speed
)

task.wait()

end

root.AssemblyLinearVelocity = Vector3.new(0,root.AssemblyLinearVelocity.Y,0)

end

local function resetPlayButton()
    routeRunning = false
    playButton.Text = "Play"
    playButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
end

local function walkRoute(route)

    local myRouteId = currentRouteId
    local activeRoute = route

    routeRunning = true
    stealMode = false

    -- ======================
    -- IDA
    -- ======================

    -- Start → Route1 (PATHFINDING)
    if myRouteId ~= currentRouteId then return end
    pathMove(route.Route[1])

    -- Route1 → Route2
    if myRouteId ~= currentRouteId then return end
    directMove(route.Route[2], myRouteId)

    -- Route2 → Route3
    if myRouteId ~= currentRouteId then return end
    directMove(route.Route[3], myRouteId)

    -- ======================
    -- STEAL
    -- ======================

    stealMode = true

    local cd = tonumber(cooldownBox.Text)
    if cd and cd > 0 then
        task.wait(cd)
    end

    -- ======================
    -- REGRESO
    -- ======================

    -- Route3 → Route2
    if myRouteId ~= currentRouteId then return end
    directMove(route.Route[2], myRouteId)

    -- Route2 → Route1
    if myRouteId ~= currentRouteId then return end
    directMove(route.Route[1], myRouteId)

    -- 🔥 Route1 → antiguo StartPoint (Route[4])
    if myRouteId ~= currentRouteId then return end
    if route.Route[4] then
        directMove(route.Route[4], myRouteId)
    end

    -- 🔥 antiguo StartPoint → nuevo StartPoint (Point 5)
    if myRouteId ~= currentRouteId then return end
    directMove(activeRoute.StartPoint, myRouteId)

    -- ======================
    -- TERMINAR
    -- ======================

    clearAutoWalkParts()

    if activeRoute == routes.START_A then
        leftEnabled = false
        leftButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
    end

    if activeRoute == routes.START_B then
        rightEnabled = false
        rightButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
    end

    selectedRoute = nil
    routeRunning = false

    resetPlayButton()

end

-- ======================
-- BOTONES
-- ======================

playButton.MouseButton1Click:Connect(function()

    if routeRunning then
        -- STOP
        routeRunning = false
        currentRouteId += 1

        playButton.Text = "Play"
        playButton.BackgroundColor3 = Color3.fromRGB(25,25,25)

        clearAutoWalkParts()
        return
    end

    if not detectedSpawn then
        warn("No spawn detectado")
        return
    end

    local route

    if detectedSpawn == 1 then
        route = routes.START_B
    elseif detectedSpawn == 2 then
        route = routes.START_A
    end

    if route then
        currentRouteId += 1
routeRunning = true
        playButton.Text = "STOP"
        playButton.BackgroundColor3 = Color3.fromRGB(0,120,255)

        if not routeRunning then
    loadRouteToTextboxes(route)
end

local customRoute = buildRouteFromTextboxes(route)

drawRoute(customRoute)

task.spawn(function()

    walkRoute(customRoute)

    -- SOLO resetear si SIGUE siendo la misma ruta
    if routeRunning then
        routeRunning = false
    end

    playButton.Text = "Play"
    playButton.BackgroundColor3 = Color3.fromRGB(25,25,25)

end)
    end

end)

-- ======================
-- MINIMIZE
-- ======================


local elementsToHide = {
speedFrame,
stealSpeedFrame,
cooldownFrame
}
for _,v in pairs(pointElements) do
    table.insert(elementsToHide, v)
end

minimized = Config["AutoPlay Minimized"]

if minimized then

    minimizeButton.Text = "▼"

    for _,v in pairs(elementsToHide) do
        v.Visible = false
    end

    main.Size = UDim2.new(0,200,0,70)

else

    minimizeButton.Text = "▲"

    for _,v in pairs(elementsToHide) do
        v.Visible = true
    end

    main.Size = UDim2.new(0,200,0,320)

end

minimizeButton.MouseButton1Click:Connect(function()

minimized = not minimized

    Config["AutoPlay Minimized"] = minimized
    SaveConfig()

if minimized then

minimizeButton.Text = "▼"

for _,v in pairs(elementsToHide) do
v.Visible = false
end

TweenService:Create(
main,
TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{Size = UDim2.new(0,200,0,70)}
):Play()

else

minimizeButton.Text = "▲"

local tween = TweenService:Create(
main,
TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{Size = UDim2.new(0,200,0,320)}
)

tween:Play()

tween.Completed:Connect(function()

for _,v in pairs(elementsToHide) do
v.Visible = true
end

end)

end

end)

main:GetPropertyChangedSignal("Position"):Connect(function()

    Config["AutoPlay GUI X"] = main.Position.X.Scale
    Config["AutoPlay GUI OffsetX"] = main.Position.X.Offset
    Config["AutoPlay GUI Y"] = main.Position.Y.Scale
    Config["AutoPlay GUI OffsetY"] = main.Position.Y.Offset

    SaveConfig()

end)

end

local function destroyAutoPlayGui()

    local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AutoPlayGUI")

    if gui then
        gui:Destroy()
    end

end


--// ANTI RAGDOLL NUEVO (MEJORADO)

local Connections = {}
local AntiRagdollEnabled = false

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    
    Connections.antiRagdoll = game:GetService("RunService").Heartbeat:Connect(function()
        if not AntiRagdollEnabled then return end
        
        local char = player.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        
        local s = hum:GetState()
        local ragdolled = (s == Enum.HumanoidStateType.Physics
        or s == Enum.HumanoidStateType.Ragdoll
        or s == Enum.HumanoidStateType.FallingDown)
        
        local endTime = player:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then 
            ragdolled = true 
        end
        
        if ragdolled then
            pcall(function() player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
            
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then 
                    d:Destroy() 
                end
            end
            
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and obj.Enabled == false then 
                    obj.Enabled = true 
                end
            end
            
            if hum.Health > 0 then 
                hum:ChangeState(Enum.HumanoidStateType.Running) 
            end
            
            workspace.CurrentCamera.CameraSubject = hum
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function stopAntiRagdoll()
    if Connections.antiRagdoll then 
        Connections.antiRagdoll:Disconnect() 
        Connections.antiRagdoll = nil 
    end
end

--// SETUP CHARACTER 

local function setupCharacter(char)

    character = char

    hrp = character:WaitForChild("HumanoidRootPart")

    hum = character:WaitForChild("Humanoid")

    -- recrear melee aimbot si está activo al reiniciar personaje 
    if meleeEnabled then
        task.spawn(function()
            task.wait(0.3)
            createMeleeAimbot(char)
        end)
    end

end

if player.Character then

    setupCharacter(player.Character)

end

player.CharacterAdded:Connect(setupCharacter)

--// GUI

local gui = Instance.new("ScreenGui")

gui.Name = "BoosterCustomizer"

gui.ResetOnSpawn = false

gui.Enabled = false

gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")

main.Size = UDim2.new(0,200,0,185)

main.Position = UDim2.new(
    Config["Speed GUI X"],
    Config["Speed GUI OffsetX"],
    Config["Speed GUI Y"],
    Config["Speed GUI OffsetY"]
)

main.BackgroundColor3 = Color3.fromRGB(0,0,0)

main.BackgroundTransparency = 0.35

main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke", main)

stroke.Color = Color3.fromRGB(0,120,255)

stroke.Thickness = 2

--// DRAG

local dragHandle = Instance.new("Frame")

dragHandle.Size = UDim2.new(1,0,0,30)

dragHandle.Position = UDim2.new(0,0,0,0)

dragHandle.BackgroundTransparency = 1

dragHandle.Parent = main

main.Active = true
main.Draggable = not UILocked

main:GetPropertyChangedSignal("Position"):Connect(function()

    Config["Speed GUI X"] = main.Position.X.Scale
    Config["Speed GUI OffsetX"] = main.Position.X.Offset
    Config["Speed GUI Y"] = main.Position.Y.Scale
    Config["Speed GUI OffsetY"] = main.Position.Y.Offset

    SaveConfig()

end)

--// TÍTULO 

local title = Instance.new("TextLabel")

title.Size = UDim2.new(1,-40,0,30)
title.Position = UDim2.new(0,30,0,0)

title.BackgroundTransparency = 1

title.Text = "Speed Customizer"

title.Font = Enum.Font.GothamBold

title.TextSize = 15

title.TextColor3 = Color3.fromRGB(0,120,255)

title.TextXAlignment = Enum.TextXAlignment.Left

title.Parent = main

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0,18,0,18)
minimizeButton.Position = UDim2.new(0,8,0,6)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "▲"
if minimized then
    minimizeButton.Text = "▼"
else
    minimizeButton.Text = "▲"
end
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.TextColor3 = title.TextColor3
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = main

--// BOTÓN DE ACTIVAR

local activate = Instance.new("TextButton")

activate.Size = UDim2.new(1,-20,0,30)

activate.Position = UDim2.new(0,10,0,35)

activate.BackgroundColor3 = Color3.fromRGB(25,25,25)

activate.TextColor3 = Color3.fromRGB(255,255,255)

activate.Text = "OFF"

activate.Font = Enum.Font.GothamBold

activate.TextSize = 14

activate.Parent = main

Instance.new("UICorner", activate).CornerRadius = UDim.new(0,8)

local activateStroke = Instance.new("UIStroke", activate)

activateStroke.Color = Color3.fromRGB(0,120,255)

--// CREAR ROW FUNCIÓN 

local function createRow(text,posY,default)

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(0.55,0,0,25)

    label.Position = UDim2.new(0,10,0,posY)

    label.BackgroundTransparency = 1

    label.Text = text

    label.Font = Enum.Font.GothamBold

    label.TextSize = 13

    label.TextColor3 = Color3.fromRGB(255,255,255)

    label.TextXAlignment = Enum.TextXAlignment.Left

    label.Parent = main

    local box = Instance.new("TextBox")

    box.Size = UDim2.new(0.4,0,0,25)

    box.Position = UDim2.new(0.55,5,0,posY)

    box.BackgroundColor3 = Color3.fromRGB(20,20,20)

    box.TextColor3 = Color3.fromRGB(255,255,255)

    box.Text = tostring(default)

    box.Font = Enum.Font.GothamBold

    box.TextSize = 13

    box.ClearTextOnFocus = false

    box.Parent = main

    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

    local s = Instance.new("UIStroke", box)

    s.Color = Color3.fromRGB(0,120,255)

    return box, label

end

--// ROWS

local speedBox, speedLabel = createRow("Speed",75,40)
local stealBox, stealLabel = createRow("Steal Speed",110,21.2)
local jumpBox, jumpLabel = createRow("Jump",145,60)

speedBox.Text = tostring(Config["Speed Value"])
stealBox.Text = tostring(Config["Steal Speed Value"])
jumpBox.Text = tostring(Config["Jump Value"])

--// VALUES

local active = false

local speedConnection

local speedNoStealValue = 40

local speedStealValue = 21.2

local jumpValue = 50

--// SANITIZE

local function applyInput(box,min,max,default,key)

box.FocusLost:Connect(function()

local text = box.Text:gsub("[^%d%.]","")
local num = tonumber(text) or default
num = math.clamp(num,min,max)

box.Text = tostring(num)

Config[key] = num
SaveConfig()

end)

end

applyInput(speedBox,15,200,40,"Speed Value")
applyInput(stealBox,15,200,21.2,"Steal Speed Value")
applyInput(jumpBox,50,200,60,"Jump Value")

--// BOTÓN LÓGICA 

activate.MouseButton1Click:Connect(function()

    active = not active

Config["Speed Enabled"] = active
SaveConfig()

    if active then

        activate.Text = "ON"

        activate.BackgroundColor3 = Color3.fromRGB(0,120,255)

        speedConnection = RunService.Heartbeat:Connect(function()

            if character and hrp and hum then

                speedNoStealValue = tonumber(speedBox.Text) or 40

                speedStealValue = tonumber(stealBox.Text) or 21.2

                jumpValue = tonumber(jumpBox.Text) or 60

                local moveDirection = hum.MoveDirection

                if moveDirection.Magnitude > 0 then

                    local isSteal = hum.WalkSpeed < 25

                    local currentSpeed = isSteal and speedStealValue or speedNoStealValue

                    hrp.AssemblyLinearVelocity = Vector3.new(

                        moveDirection.X * currentSpeed,

                        hrp.AssemblyLinearVelocity.Y,

                        moveDirection.Z * currentSpeed

                    )

                end

            end

        end)

    else

        activate.Text = "OFF"

        activate.BackgroundColor3 = Color3.fromRGB(25,25,25)

        if speedConnection then

            speedConnection:Disconnect()

            speedConnection = nil

        end

    end

end)

if Config["Speed Enabled"] then

    active = true
    activate.Text = "ON"
    activate.BackgroundColor3 = Color3.fromRGB(0,120,255)

    speedConnection = RunService.Heartbeat:Connect(function()

        if character and hrp and hum then

            speedNoStealValue = tonumber(speedBox.Text) or 40
            speedStealValue = tonumber(stealBox.Text) or 21.2
            jumpValue = tonumber(jumpBox.Text) or 60

            local moveDirection = hum.MoveDirection

            if moveDirection.Magnitude > 0 then

                local isSteal = hum.WalkSpeed < 25
                local currentSpeed = isSteal and speedStealValue or speedNoStealValue

                hrp.AssemblyLinearVelocity = Vector3.new(
                    moveDirection.X * currentSpeed,
                    hrp.AssemblyLinearVelocity.Y,
                    moveDirection.Z * currentSpeed
                )

            end

        end

    end)

end

task.defer(function()

    if Config["Speed Enabled"] then
        activate:Activate()
    end

end)

--// JUMP

UserInputService.JumpRequest:Connect(function()
    if not character or not hum or not hrp then return end

    local state = hum:GetState()

    -- JUMP BOOSTER
    if active then
        if state == Enum.HumanoidStateType.Running 
        or state == Enum.HumanoidStateType.Landed then

            local jumpPower = tonumber(jumpBox.Text) or 70

            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                jumpPower,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end

    -- INFINITE JUMP
    if infiniteJumpEnabled then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            50,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end)

-- ======================
-- MINIMIZE
-- ======================

local elementsToHide = {
speedBox,
stealBox,
jumpBox,
speedLabel,
stealLabel,
jumpLabel
}

if Config["Speed Minimized"] then

    minimized = true
    minimizeButton.Text = "▼"

    for _,v in pairs(elementsToHide) do
        v.Visible = false
    end

    main.Size = UDim2.new(0,200,0,70)

end

minimizeButton.MouseButton1Click:Connect(function()

minimized = not minimized

    Config["Speed Minimized"] = minimized
    SaveConfig()

if minimized then

minimizeButton.Text = "▼"

for _,v in pairs(elementsToHide) do
v.Visible = false
end

TweenService:Create(
main,
TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{Size = UDim2.new(0,200,0,70)}
):Play()

else

minimizeButton.Text = "▲"

local tween = TweenService:Create(
main,
TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{Size = UDim2.new(0,200,0,185)}
)

tween:Play()

tween.Completed:Connect(function()

for _,v in pairs(elementsToHide) do
v.Visible = true
end

end)

end

end)

--// NOVA HUB (código interno en si xd)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local lp = Players.LocalPlayer
local RunService = game:GetService("RunService")

local function ApplyToggle(text, enabled)

    if text == "No Walk Animation" then
        local char = lp.Character
        if not char then return end

        local animate = char:FindFirstChild("Animate")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if enabled then
            if animate then
                savedAnimate = animate
                animate.Disabled = true
            end

            if humanoid then
                local animator = humanoid:FindFirstChildOfClass("Animator")

                if animator then
                    for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:Stop(0)
                        track:Destroy()
                    end
                end

                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end

        else
            if savedAnimate then
                savedAnimate.Disabled = false
                savedAnimate = nil
            end
        end


    elseif text == "Instant Grab" then
        autoStealEnabled = enabled

        if enabled then

            task.spawn(function()

                repeat task.wait() until progressBarBg and progressFill and percentLabel

                progressBarBg.Visible = true

                if instantGrabConnection then
                    instantGrabConnection:Disconnect()
                end

                while autoStealEnabled do

                    local char = lp.Character
                    if char then

                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then

                            if fastStealEnabled and autoStealEnabled then
                                grabRadius = 10
                            end

                            local prompt = findNearestSteal(root)

                            if prompt then
                                progressBarBg.Visible = true
                                local start = tick()

                                while autoStealEnabled and findNearestSteal(root) == prompt do

                                    local duration = (fastStealEnabled and autoStealEnabled) and 0.10 or 0.10
                                    local p = math.clamp((tick() - start) / duration, 0, 1)

                                    progressFill.Size = UDim2.new(p,0,1,0)
                                    percentLabel.Text = math.floor(p*100).."%"

                                    if p >= 0.99 then
                                        pcall(fireproximityprompt, prompt)
                                        task.wait(0.1)
                                        pcall(fireproximityprompt, prompt)
                                        start = tick()
                                    end

                                    task.wait()
                                end
                            end

                        end
                    end

                    resetBar()
                    task.wait(0.15)

                end

                resetBar(true)
                hideSquare()

                if instantGrabConnection then
                    instantGrabConnection:Disconnect()
                    instantGrabConnection = nil
                end

            end)

        else

            autoStealEnabled = false

            resetBar(true)
            hideSquare()

            if instantGrabConnection then
                instantGrabConnection:Disconnect()
                instantGrabConnection = nil
            end

        end
    end

end

local instantGrabLoop

local spinForce

local function startSpinBody()

    local char = lp.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "SpinForce"
    spinForce.AngularVelocity = Vector3.new(0, Config["Spin Speed"], 0)
    spinForce.MaxTorque = Vector3.new(0,math.huge,0)
    spinForce.P = 1000
    spinForce.Parent = root

end


local function stopSpinBody()

    local char = lp.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local spin = root:FindFirstChild("SpinForce")
    if spin then
        spin:Destroy()
    end

end

local spinGui
local spinActive = false

-- DROP SISTEMA

local player = game.Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local dropGui
local debounce = false

local wfConns = {}
local wfActive = false

local function startWalkFling()

    wfActive = true

    table.insert(wfConns, RunService.Stepped:Connect(function()

        if not wfActive then return end

        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then

                for _,part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

            end
        end

    end))

    local co = coroutine.create(function()

        while wfActive do

            RunService.Heartbeat:Wait()

            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if not root then
                RunService.Heartbeat:Wait()
                continue
            end

            local vel = root.Velocity

            root.Velocity = vel * 10000 + Vector3.new(0,10000,0)

            RunService.RenderStepped:Wait()

            if root and root.Parent then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()

            if root and root.Parent then
                root.Velocity = vel + Vector3.new(0,0.1,0)
            end

        end

    end)

    coroutine.resume(co)
    table.insert(wfConns, co)

end


local function stopWalkFling()

    wfActive = false

    for _,c in ipairs(wfConns) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        elseif typeof(c) == "thread" then
            pcall(task.cancel, c)
        end
    end

    wfConns = {}

end


local function doDrop()

    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then return end

    -- guardar altura original
    local originalY = root.Position.Y

    -- registrar salto
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

    -- fuerza real del salto
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        100,
        root.AssemblyLinearVelocity.Z
    )

    -- bloquear solo la altura (no movimiento)
    local start = tick()
    while tick() - start < 0.2 do

        local pos = root.Position
        root.CFrame = CFrame.new(pos.X, originalY, pos.Z) * CFrame.Angles(0, root.Orientation.Y * math.pi/180, 0)

        task.wait()

    end

end


local function createDropButton()

    if dropGui then return end

    dropGui = Instance.new("ScreenGui")
    dropGui.Name = "DropButtonGui"
    dropGui.ResetOnSpawn = false
    dropGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)
    button.Position = UDim2.new(
    Config["Drop Button X"],
    Config["Drop Button OffsetX"],
    Config["Drop Button Y"],
    Config["Drop Button OffsetY"]
)
    button.Text = "DROP"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(0,120,255)
    button.Parent = dropGui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

    button.Active = true
    button.Draggable = not UILocked

    button.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            local pos = button.Position

            Config["Drop Button X"] = pos.X.Scale
            Config["Drop Button OffsetX"] = pos.X.Offset
            Config["Drop Button Y"] = pos.Y.Scale
            Config["Drop Button OffsetY"] = pos.Y.Offset

            SaveConfig()

        end
    end)

    button.MouseButton1Click:Connect(function()

        if debounce then return end
        debounce = true

        button.BackgroundColor3 = Color3.fromRGB(200,0,0)

        doDrop()

        task.wait(0.2)

        button.BackgroundColor3 = Color3.fromRGB(0,120,255)
        debounce = false

    end)

end


local function removeDropButton()

    if dropGui then
        dropGui:Destroy()
        dropGui = nil
    end

end

local function createSpinButton()
    if spinGui then return end

    spinGui = Instance.new("ScreenGui")
    spinGui.Name = "SpinButtonGui"
    spinGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)
    button.Position = UDim2.new(
    Config["Spin Button X"],
    Config["Spin Button OffsetX"],
    Config["Spin Button Y"],
    Config["Spin Button OffsetY"]
)
    button.Text = "SPIN"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    button.Parent = spinGui

    -- Esquinas curvas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = button

    -- Draggable
    button.Active = true
    button.Draggable = not UILocked

button.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		local pos = button.Position

		Config["Spin Button X"] = pos.X.Scale
		Config["Spin Button OffsetX"] = pos.X.Offset
		Config["Spin Button Y"] = pos.Y.Scale
		Config["Spin Button OffsetY"] = pos.Y.Offset

		SaveConfig()

	end
end)

    button.MouseButton1Click:Connect(function()
        spinActive = not spinActive

        if spinActive then
            button.Text = "SPINNING"
            button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            startSpinBody()
        else
            button.Text = "SPIN"
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            stopSpinBody()
        end
    end)
end

local function removeSpinButton()
    stopSpinBody()
    spinActive = false

    if spinGui then
        spinGui:Destroy()
        spinGui = nil
    end
end

function createFlingGui()

    if flingGui then return end

    flingGui = Instance.new("ScreenGui")
    flingGui.Name = "NovaHubFling"
    flingGui.ResetOnSpawn = false
    flingGui.Parent = game:GetService("CoreGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,120,0,40)
    btn.Position = UDim2.new(
    Config["Fling Button X"],
    Config["Fling Button OffsetX"],
    Config["Fling Button Y"],
    Config["Fling Button OffsetY"]
)
    btn.Text = "FLING"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(0,120,255)
    btn.Parent = flingGui

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    btn.Active = true
    btn.Draggable = not UILocked

btn.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		local pos = btn.Position

		Config["Fling Button X"] = pos.X.Scale
		Config["Fling Button OffsetX"] = pos.X.Offset
		Config["Fling Button Y"] = pos.Y.Scale
		Config["Fling Button OffsetY"] = pos.Y.Offset

		SaveConfig()

	end
end)

    btn.MouseButton1Click:Connect(function()

        flingActive = not flingActive

        if flingActive then

            btn.Text = "FLING ON"
            btn.BackgroundColor3 = Color3.fromRGB(200,0,0)
            startFling()

        else

            btn.Text = "FLING"
            btn.BackgroundColor3 = Color3.fromRGB(0,120,255)
            stopFling()

        end

    end)

end

function destroyFlingGui()

    flingActive = false
    stopFling()

    if flingGui then
        flingGui:Destroy()
        flingGui = nil
    end

end

-- =========================
-- LOCK TARGET FLOATING BUTTON (BAT AIMBOT)
-- =========================

local lockTargetGui = nil
local batAimbotEnabled = false
local aimbotConn = nil
local lockedTarget = nil
local BAT_ENGAGE_RANGE = 8
local AIMBOT_SPEED = 55
local MELEE_OFFSET = 3

-- Create highlight for target
local aimbotHighlight = Instance.new("Highlight")
aimbotHighlight.Name = "NovaAimbotESP"
aimbotHighlight.FillColor = Color3.fromRGB(180, 0, 255)
aimbotHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
aimbotHighlight.FillTransparency = 0.5
aimbotHighlight.OutlineTransparency = 0
pcall(function() aimbotHighlight.Parent = lp:WaitForChild("PlayerGui") end)

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum2 = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp2 = targetChar:FindFirstChild("HumanoidRootPart")
    local ff = targetChar:FindFirstChildOfClass("ForceField")
    return hum2 and hrp2 and hum2.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist, newTargetChar, newTargetHRP = math.huge, nil, nil
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and isTargetValid(targetPlayer.Character) then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = (targetHRP.Position - myHRP.Position).Magnitude
            if distance < shortestDist then
                shortestDist = distance
                newTargetHRP = targetHRP
                newTargetChar = targetPlayer.Character
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function findBatTool()
    local c = lp.Character; if not c then return nil end
    local bp = lp:FindFirstChildOfClass("Backpack")
    local SlapList = {
        "Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
        "Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap",
        "Galaxy Slap","Glitched Slap"
    }
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
                return ch
            end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
end

function startBatAimbot()
    if aimbotConn then return end
    local c = lp.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    local hm = c:FindFirstChildOfClass("Humanoid")
    if not h or not hm then return end
    pcall(function() hm.AutoRotate = false end)
    
    local attachment = h:FindFirstChild("AimbotAttachment") or Instance.new("Attachment", h)
    attachment.Name = "AimbotAttachment"
    local align = h:FindFirstChild("AimbotAlign") or Instance.new("AlignOrientation", h)
    align.Name = "AimbotAlign"
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.MaxTorque = math.huge
    align.Responsiveness = 200
    
    batAimbotEnabled = true
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not batAimbotEnabled then return end
        local c2 = lp.Character; if not c2 then return end
        local h2 = c2:FindFirstChild("HumanoidRootPart"); if not h2 then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid")
        
        local bat = findBatTool()
        if bat and bat.Parent ~= c2 then
            pcall(function() hm2:EquipTool(bat) end)
        end
        
        local targetHRP, targetChar = getBestTarget(h2)
        if targetHRP and targetChar then
            aimbotHighlight.Adornee = targetChar
            
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            local dir = (predictedPos - h2.Position)
            local dist3D = dir.Magnitude
            local standPos = predictedPos
            if dist3D > 0 then standPos = predictedPos - (dir.Unit * MELEE_OFFSET) end
            
            align.CFrame = CFrame.lookAt(h2.Position, predictedPos)
            
            local moveDir2 = (standPos - h2.Position)
            local distToStand = moveDir2.Magnitude
            if distToStand > 1 then
                h2.AssemblyLinearVelocity = moveDir2.Unit * AIMBOT_SPEED
            else
                h2.AssemblyLinearVelocity = targetVel
            end
            
            if distToStand <= BAT_ENGAGE_RANGE then
                if bat and bat.Parent == c2 then
                    pcall(function() bat:Activate() end)
                end
            end
        else
            lockedTarget = nil
            h2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            aimbotHighlight.Adornee = nil
        end
    end)
    
    -- Update button text when enabled
    if lockTargetButton then
        lockTargetButton.Text = "LOCKED"
        lockTargetButton.BackgroundColor3 = Color3.fromRGB(200,0,0)
    end
end

function stopBatAimbot()
    batAimbotEnabled = false
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    local c = lp.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    local hm = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        local att = h:FindFirstChild("AimbotAttachment"); if att then att:Destroy() end
        local al = h:FindFirstChild("AimbotAlign"); if al then al:Destroy() end
        h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    if hm then pcall(function() hm.AutoRotate = true end) end
    lockedTarget = nil
    aimbotHighlight.Adornee = nil
    
    -- Update button text when disabled
    if lockTargetButton then
        lockTargetButton.Text = "LOCK"
        lockTargetButton.BackgroundColor3 = Color3.fromRGB(0,120,255)
    end
end

function toggleBatAimbot()
    if batAimbotEnabled then 
        stopBatAimbot() 
    else 
        startBatAimbot() 
    end
end

-- Create floating button for Lock Target
local lockTargetButton = nil

function createLockTargetButton()
    if lockTargetGui then return end

    lockTargetGui = Instance.new("ScreenGui")
    lockTargetGui.Name = "LockTargetButtonGui"
    lockTargetGui.ResetOnSpawn = false
    lockTargetGui.Parent = game:GetService("CoreGui")

    lockTargetButton = Instance.new("TextButton")
    lockTargetButton.Size = UDim2.new(0,120,0,40)
    lockTargetButton.Position = UDim2.new(
        Config["LockButtonX"],
        Config["LockButtonOffsetX"],
        Config["LockButtonY"],
        Config["LockButtonOffsetY"]
    )
    lockTargetButton.Text = "LOCK"
    lockTargetButton.Font = Enum.Font.GothamBold
    lockTargetButton.TextSize = 14
    lockTargetButton.TextColor3 = Color3.new(1,1,1)
    lockTargetButton.BackgroundColor3 = Color3.fromRGB(0,120,255)
    lockTargetButton.Parent = lockTargetGui

    Instance.new("UICorner", lockTargetButton).CornerRadius = UDim.new(0,8)

    lockTargetButton.Active = true
    lockTargetButton.Draggable = not UILocked

    lockTargetButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local pos = lockTargetButton.Position
            Config["LockButtonX"] = pos.X.Scale
            Config["LockButtonOffsetX"] = pos.X.Offset
            Config["LockButtonY"] = pos.Y.Scale
            Config["LockButtonOffsetY"] = pos.Y.Offset
            SaveConfig()
        end
    end)

    lockTargetButton.MouseButton1Click:Connect(function()
        toggleBatAimbot()
    end)
end

function destroyLockTargetButton()
    if batAimbotEnabled then
        stopBatAimbot()
    end
    if lockTargetGui then
        lockTargetGui:Destroy()
        lockTargetGui = nil
    end
    lockTargetButton = nil
end

-- Auto deactivate conflicting toggles
local function checkConflictingToggles(toggledFeature, enabled)
    -- List of features that conflict with each other
    local conflicts = {
        ["Lock Target"] = {"Auto Play", "Auto Bat", "Melee Aimbot"},
        ["Auto Play"] = {"Lock Target", "Auto Bat", "Melee Aimbot", "Fling", "TP Down", "Manual TP"},
        ["Auto Bat"] = {"Lock Target", "Auto Play", "Melee Aimbot"},
        ["Melee Aimbot"] = {"Lock Target", "Auto Play", "Auto Bat"},
        ["Fling"] = {"Auto Play", "TP Down", "Manual TP"},
        ["TP Down"] = {"Auto Play", "Fling", "Manual TP"},
        ["Manual TP"] = {"Auto Play", "Fling", "TP Down"}
    }
    
    if enabled and conflicts[toggledFeature] then
        for _, conflict in ipairs(conflicts[toggledFeature]) do
            if Config[conflict] == true then
                -- Disable the conflicting feature
                Config[conflict] = false
                SaveConfig()
                
                -- Update UI toggle if it exists
                for _, frame in pairs(frames) do
                    for _, container in ipairs(frame:GetChildren()) do
                        local label = container:FindFirstChildOfClass("TextLabel")
                        if label and label.Text == conflict then
                            local toggleButton = container:FindFirstChildOfClass("TextButton")
                            if toggleButton then
                                local circle = toggleButton:FindFirstChildOfClass("Frame")
                                toggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
                                if circle then circle.Position = UDim2.new(0,2,0.5,-9) end
                            end
                        end
                    end
                end
                
                -- Also update the floating button if it's Lock Target being disabled
                if conflict == "Lock Target" and lockTargetButton then
                    if batAimbotEnabled then
                        stopBatAimbot()
                    end
                end
                
                -- Also update Auto Play GUI if it's being disabled
                if conflict == "Auto Play" then
                    destroyAutoPlayGui()
                end
            end
        end
    end
end

task.wait(1)

--////////////////////////////////////////////////////
-- SCREEN GUI
--////////////////////////////////////////////////////
local sg = Instance.new("ScreenGui")
sg.Name = "NovaHub"
sg.ResetOnSpawn = false
sg.Parent = lp:WaitForChild("PlayerGui")

-- CONTENEDOR (progressBarBg)
local progressBarBg = Instance.new("Frame")
progressBarBg.Size = UDim2.new(0,240,0,18)
progressBarBg.Position = UDim2.new(0.5,-120,0,52)
progressBarBg.BackgroundColor3 = Color3.fromRGB(0,120,255)
progressBarBg.BackgroundTransparency = 0.2
progressBarBg.Visible = false
progressBarBg.Parent = sg
Instance.new("UICorner", progressBarBg).CornerRadius = UDim.new(0,10)

-- SOMBRA INTERNA
local progressShadow = Instance.new("Frame")
progressShadow.Size = UDim2.new(1,-4,1,-4)
progressShadow.Position = UDim2.new(0,2,0,2)
progressShadow.BackgroundColor3 = Color3.fromRGB(10,10,10)
progressShadow.BackgroundTransparency = 0.35
progressShadow.Parent = progressBarBg
Instance.new("UICorner", progressShadow).CornerRadius = UDim.new(0,8)

-- FONDO DE BARRA
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1,-14,0,4)
barBg.Position = UDim2.new(0,7,0.5,-2)
barBg.BackgroundColor3 = Color3.fromRGB(10,10,10)
barBg.Parent = progressShadow
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0,4)

-- PROGRESO
local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0,0,1,0)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 80)),
})
grad.Parent = progressFill
progressFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
progressFill.Parent = barBg
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0,4)

-- TEXTO %
local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(1,0,1,0)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 11
percentLabel.TextColor3 = Color3.fromRGB(255,255,255)
percentLabel.Text = "0%"
percentLabel.Visible = false
percentLabel.Parent = progressShadow

-- RADIO CÍRCULAR EN EL SUELO
local stealSquarePart = nil
local circleConnection = nil

local function hideSquare()
    if stealSquarePart then
        stealSquarePart:Destroy()
        stealSquarePart = nil
    end
end

local grabRadius = 8

local function createOrUpdateSquare(radius)
    if not stealSquarePart then
        stealSquarePart = Instance.new("Part")
        stealSquarePart.Name = "StealCircle"
        stealSquarePart.Anchored = true
        stealSquarePart.CanCollide = false
        stealSquarePart.Transparency = 0.7
        stealSquarePart.Material = Enum.Material.Neon
        stealSquarePart.Color = Color3.fromRGB(0, 120, 255)

        stealSquarePart.Shape = Enum.PartType.Cylinder

        -- IMPORTANTE: el cilindro necesita rotación

        stealSquarePart.Size = Vector3.new(0.05, radius*2, radius*2)

        stealSquarePart.Parent = workspace
    else
        stealSquarePart.Size = Vector3.new(0.05, radius*2, radius*2)
    end
end

local function updateSquarePosition()
    if stealSquarePart and lp.Character then
        local root = lp.Character:FindFirstChild("HumanoidRootPart")
        if root then
            stealSquarePart.CFrame =
                CFrame.new(root.Position + Vector3.new(0, -2.5, 0))
                * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end

--////////////////////////////////////////////////////
-- BARRA SUPERIOR (SIN FPS Y PING)
--////////////////////////////////////////////////////
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0,240,0,32)
topBar.Position = UDim2.new(0.5,-120,0,15)
topBar.BackgroundColor3 = Color3.fromRGB(15,15,15)
topBar.BackgroundTransparency = 0.15
topBar.Parent = sg
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,10)

local strokeTop = Instance.new("UIStroke", topBar)
strokeTop.Color = Color3.fromRGB(0,120,255)
strokeTop.Thickness = 1.5

local topLabel = Instance.new("TextLabel")
topLabel.Size = UDim2.new(1,0,1,0)
topLabel.BackgroundTransparency = 1
topLabel.Font = Enum.Font.GothamBold
topLabel.TextSize = 14
topLabel.TextColor3 = Color3.fromRGB(0,120,255)
topLabel.Text = "Nova Hub"
topLabel.Parent = topBar

-- BOTÓN ABRIR Y CERRAR GUI
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0,55,0,55)
toggleBtn.Position = UDim2.new(
    Config["Toggle Button X"],
    Config["Toggle Button OffsetX"],
    Config["Toggle Button Y"],
    Config["Toggle Button OffsetY"]
)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggleBtn.Text = "≡"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 38
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,14)

toggleBtn.Active = true
toggleBtn.Draggable = not UILocked

toggleBtn:GetPropertyChangedSignal("Position"):Connect(function()

    local p = toggleBtn.Position

    Config["Toggle Button X"] = p.X.Scale
    Config["Toggle Button Y"] = p.Y.Scale
    Config["Toggle Button OffsetX"] = p.X.Offset
    Config["Toggle Button OffsetY"] = p.Y.Offset

    SaveConfig()

end)

-- HUB PANEL
local HUB_WIDTH = 260
local HUB_HEIGHT = 320
local hub = Instance.new("Frame")
hub.Size = UDim2.new(0,HUB_WIDTH,0,HUB_HEIGHT)
hub.Position = UDim2.new(0,-350,0.5,-HUB_HEIGHT/2)
hub.BackgroundColor3 = Color3.fromRGB(0,0,0)
hub.BackgroundTransparency = 0.25
hub.Parent = sg
Instance.new("UICorner", hub).CornerRadius = UDim.new(0,14)

local strokeHub = Instance.new("UIStroke", hub)
strokeHub.Color = Color3.fromRGB(0,120,255)
strokeHub.Thickness = 2

local titleHub = Instance.new("TextLabel")
titleHub.Size = UDim2.new(0.55,0,0,40)
titleHub.Position = UDim2.new(0,12,0,8)
titleHub.BackgroundTransparency = 1
titleHub.Font = Enum.Font.GothamBold
titleHub.TextSize = 20
titleHub.TextXAlignment = Enum.TextXAlignment.Left
titleHub.TextColor3 = Color3.fromRGB(0,120,255)
titleHub.Text = "Nova Hub"
titleHub.Parent = hub

-- AUTO STEAL NEAREST
autoStealEnabled = false
local dropBrainrotRunning = false
local fastStealEnabled = false
local normalGrabRadius = grabRadius
local radioTextbox

--// AUTO STEAL / INSTANT GRAB (LOGICA VANDER + STEALHITBOX)

local function isInsideStealHitbox(root)
	if not root or not root.Parent then return false end

	local plots = workspace:FindFirstChild("Plots")
	if not plots then return false end

	for _, plot in ipairs(plots:GetChildren()) do
		local hitbox = plot:FindFirstChild("StealHitbox", true)

		if hitbox and hitbox:IsA("BasePart") then
			local parts = workspace:GetPartsInPart(hitbox)

			for _, p in ipairs(parts) do
				if p:IsDescendantOf(root.Parent) then
					return true
				end
			end
		end
	end

	return false
end


local function getPromptPos(prompt)
	if not prompt or not prompt.Parent then return nil end

	local p = prompt.Parent
	if p:IsA("BasePart") then
		return p.Position
	end

	if p:IsA("Model") then
		local prim = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
		return prim and prim.Position
	end

	if p:IsA("Attachment") then
		return p.WorldPosition
	end

	local part = p:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end


local function findNearestStealPrompt(root)
	if not root then return nil end

	-- SOLO BUSCAR SI ESTAS EN STEALHITBOX
	if not isInsideStealHitbox(root) then
		return nil
	end

	local plots = workspace:FindFirstChild("Plots")
	if not plots then return nil end

	local myPos = root.Position
	local nearest = nil
	local nearestDist = math.huge

	for _, plot in ipairs(plots:GetChildren()) do
		for _, obj in ipairs(plot:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj.Enabled and obj.ActionText == "Steal" then

				local pos = getPromptPos(obj)

				if pos then
					local dist = (myPos - pos).Magnitude

					if dist <= obj.MaxActivationDistance and dist < nearestDist then
						nearest = obj
						nearestDist = dist
					end
				end
			end
		end
	end

	return nearest
end


local function fireStealPrompt(prompt)
	if not prompt then return end

	task.spawn(function()
		pcall(function()
			fireproximityprompt(prompt, 10000)
			prompt:InputHoldBegin()
			task.wait(0.04)
			prompt:InputHoldEnd()
		end)
	end)
end

local function resetBar(hide)
    progressFill.Size = UDim2.new(0,0,1,0)
    percentLabel.Text = "0%"
    if hide then
        progressBarBg.Visible = false
    end
end

-- AUTO MEDUSA LOGICA
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local MEDUSA_RADIUS = 10
local SPAM_DELAY = 0.15

local medusaPart
local lastUse = 0
local AutoMedusaEnabled = false
local MedusaInitialized = false

local function InitMedusa()

    if MedusaInitialized then return end
    MedusaInitialized = true

    local function createRadius()
        if medusaPart then medusaPart:Destroy() end

        medusaPart = Instance.new("Part")
        medusaPart.Name = "MedusaRadius"
        medusaPart.Anchored = true
        medusaPart.CanCollide = false
        medusaPart.Transparency = 0
        medusaPart.Material = Enum.Material.Neon
        medusaPart.Color = Color3.fromRGB(255, 40, 40)
        medusaPart.Shape = Enum.PartType.Cylinder
        medusaPart.Size = Vector3.new(0.2, MEDUSA_RADIUS*2, MEDUSA_RADIUS*2)
        medusaPart.Parent = workspace
    end

    local function isMedusaEquipped()
        local char = lp.Character
        if not char then return nil end

        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Medusa's Head" then
                return tool
            end
        end
        return nil
    end

    createRadius()

    -- VISUAL
    RunService.RenderStepped:Connect(function()

        if not AutoMedusaEnabled then
            if medusaPart then medusaPart.Transparency = 1 end
            return
        end

        medusaPart.Transparency = 0

        local char = lp.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        medusaPart.CFrame =
            CFrame.new(root.Position + Vector3.new(0, -2.5, 0))
            * CFrame.Angles(0, 0, math.rad(90))
    end)

    -- SPAM
    RunService.Heartbeat:Connect(function()

        if not AutoMedusaEnabled then return end

        local char = lp.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local tool = isMedusaEquipped()
        if not tool then return end

        if tick() - lastUse < SPAM_DELAY then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                local pChar = plr.Character
                local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                if pRoot then
                    if (pRoot.Position - root.Position).Magnitude <= MEDUSA_RADIUS then
                        tool:Activate()
                        lastUse = tick()
                        break
                    end
                end
            end
        end
    end)
end

-- TP DOWN SISTEMA

tpDownGui = tpDownGui or nil
tpDownEnabled = tpDownEnabled or false
tpDownDebounce = tpDownDebounce or false

function getGroundPosition()
    local char = game.Players.LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local rayOrigin = root.Position
    local rayDirection = Vector3.new(0, -500, 0)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(rayOrigin, rayDirection, params)

    if result then
        return result.Position
    end
end

function doTPDown()
    local char = game.Players.LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local targetY = -8

    -- mover solo en Y sin rotar
    root.CFrame = root.CFrame * CFrame.new(0, targetY - root.Position.Y, 0)
end

function CreateTPDownButton()

    if tpDownGui then return end

    tpDownGui = Instance.new("ScreenGui")
    tpDownGui.Name = "TPDownButtonGui"
    tpDownGui.ResetOnSpawn = false
    tpDownGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)
    button.Position = UDim2.new(
    Config["TP Down Button X"],
    Config["TP Down Button OffsetX"],
    Config["TP Down Button Y"],
    Config["TP Down Button OffsetY"]
)

    button.Text = "TP DOWN"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(0,120,255)
    button.Parent = tpDownGui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

    button.Active = true
    button.Draggable = not UILocked

button.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        local pos = button.Position

        Config["TP Down Button X"] = pos.X.Scale
        Config["TP Down Button OffsetX"] = pos.X.Offset
        Config["TP Down Button Y"] = pos.Y.Scale
        Config["TP Down Button OffsetY"] = pos.Y.Offset

        SaveConfig()
    end

end)

    button.MouseButton1Click:Connect(function()

        if tpDownDebounce then return end
        tpDownDebounce = true

        button.BackgroundColor3 = Color3.fromRGB(200,0,0)

        doTPDown()

        task.wait(0.2)

        button.BackgroundColor3 = Color3.fromRGB(0,120,255)
        tpDownDebounce = false

    end)
end

function RemoveTPDownButton()
    if tpDownGui then
        tpDownGui:Destroy()
        tpDownGui = nil
    end
end

-- SECCIONES Y TOGGLES
local sections = {"Combat","Player","Visual","Settings"}
local sectionButtons = {}
local frames = {}

local startX = 12
local spacing = 6
local sectionWidth = (260 - 2*startX - (spacing*(#sections-1))) / #sections
local sectionY = 55

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-20,1,-110)
content.Position = UDim2.new(0,10,0,95)
content.BackgroundTransparency = 1
content.Parent = hub

for _,name in ipairs(sections) do
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 4
    scroll.BackgroundTransparency = 1
    scroll.Visible = false
    scroll.Name = name.."Frame"
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,8)
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    end)

    frames[name] = scroll
end

local function ShowSection(sectionName)
    for _,frame in pairs(frames) do frame.Visible = false end
    frames[sectionName].Visible = true
    for _,b in pairs(sectionButtons) do b.BackgroundColor3 = Color3.fromRGB(10,10,10) end
    for _,b in pairs(sectionButtons) do
        if b.Text == sectionName then b.BackgroundColor3 = Color3.fromRGB(0,120,255) end
    end
end

for i,v in ipairs(sections) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, sectionWidth,0,28)
    btn.Position = UDim2.new(0,startX + (i-1)*(sectionWidth+spacing),0,sectionY)
    btn.BackgroundColor3 = Color3.fromRGB(10,10,10)
    btn.Text = v
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = hub
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(0,120,255)
    table.insert(sectionButtons, btn)
    btn.MouseButton1Click:Connect(function() ShowSection(v) end)
end

local function CreateToggle(sectionName,text)
    local parentFrame = frames[sectionName]

    if text == "Radio Steal Nearest" and sectionName == "Settings" then
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,0,0,45)
        container.BackgroundColor3 = Color3.fromRGB(15,15,15)
        container.BackgroundTransparency = 0.2
        container.Parent = parentFrame
        Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
        Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6,0,1,0)
        label.Position = UDim2.new(0,12,0,0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(0,120,255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "Instant Grab Range"
        label.Parent = container

        local textbox = Instance.new("TextBox")
radioTextbox = textbox
        textbox.Size = UDim2.new(0,80,0,30)
        textbox.Position = UDim2.new(1,-90,0.5,-15)
        textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
        textbox.TextColor3 = Color3.new(1,1,1)
        textbox.Font = Enum.Font.Gotham
        textbox.TextSize = 14
        textbox.Text = tostring(grabRadius)
        textbox.ClearTextOnFocus = false
        textbox.Parent = container
        Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)
        Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)

        textbox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local num = tonumber(textbox.Text)
                if num and num > 0 and num <= 1000 then
                    grabRadius = num
                    if stealSquarePart then
                        stealSquarePart.Size = Vector3.new(0.05,grabRadius*2, grabRadius*2)
                    end
                else
                    textbox.Text = tostring(grabRadius)
                end
            end
        end)

        return
    end

    -- Toggle normal
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,45)
    container.BackgroundColor3 = Color3.fromRGB(15,15,15)
    container.BackgroundTransparency = 0.2
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0,120,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,50,0,22)
    button.Position = UDim2.new(1,-60,0.5,-11)
    button.BackgroundColor3 = Color3.fromRGB(50,50,50)
    button.Text = ""
    button.Parent = container
    Instance.new("UICorner", button).CornerRadius = UDim.new(1,0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0,18,0,18)
    circle.Position = UDim2.new(0,2,0.5,-9)
    circle.BackgroundColor3 = Color3.fromRGB(220,220,220)
    circle.Parent = button
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

    local enabled = Config[text] or false

-- Aplicar estado visual al cargar
task.defer(function()
    if enabled then
        button.BackgroundColor3 = Color3.fromRGB(0,120,255)
        circle.Position = UDim2.new(1,-20,0.5,-9)

    else
        button.BackgroundColor3 = Color3.fromRGB(50,50,50)
        circle.Position = UDim2.new(0,2,0.5,-9)
    end
end)

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        -- Check for conflicts before enabling
        if enabled then
            checkConflictingToggles(text, true)
        end
        
        if enabled then
            TweenService:Create(button, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(0,120,255)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.25), {Position = UDim2.new(1,-20,0.5,-9)}):Play()
        else
            TweenService:Create(button, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.25), {Position = UDim2.new(0,2,0.5,-9)}):Play()
        end

if Config[text] ~= nil then
    Config[text] = enabled
    SaveConfig()
end

ApplyToggle(text, enabled)

if text == "Speed Customizer" then
    local boosterGui = lp.PlayerGui:FindFirstChild("BoosterCustomizer")
    if boosterGui then
        boosterGui.Enabled = enabled
    end

elseif text == "Optimizer" then
    if enabled then
        enableOptimizer()
    else
        disableOptimizer()
    end

elseif text == "Spin Body" then

    if enabled then
        task.spawn(function()
            createSpinButton()
        end)
    else
        removeSpinButton()
    end

elseif text == "Anti Ragdoll" then

    AntiRagdollEnabled = enabled

    if enabled then
        startAntiRagdoll()
    else
        stopAntiRagdoll()
    end

elseif text == "Anti FPS Devourer" then
    if enabled then
        enableAntiFPSDevourer()
    else
        disableAntiFPSDevourer()
    end

elseif text == "Infinite Jump" then
    infiniteJumpEnabled = enabled

elseif text == "Xray Base" then
    toggleESPBases(enabled)

elseif text == "ESP Players" then
    toggleESPPlayers(enabled)

elseif text == "No Walk Animation" then

    if enabled then

        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")
        local animator = humanoid:WaitForChild("Animator")

        lastPos = root.Position

        local function isMoving()
            local currentPos = root.Position
            local distance = (currentPos - lastPos).Magnitude
            lastPos = currentPos
            return distance > 0.05
        end

        -- conexión animaciones nuevas
        noWalkConnection1 = animator.AnimationPlayed:Connect(function(track)
            task.defer(function()
                if isMoving() then
                    pcall(function()
                        track:Stop()
                    end)
                end
            end)
        end)

        -- loop anti bypass
        noWalkConnection2 = game:GetService("RunService").RenderStepped:Connect(function()
            if isMoving() then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function()
                        track:Stop()
                    end)
                end
            end
        end)

    else

        if noWalkConnection1 then
            noWalkConnection1:Disconnect()
            noWalkConnection1 = nil
        end

        if noWalkConnection2 then
            noWalkConnection2:Disconnect()
            noWalkConnection2 = nil
        end

    end

elseif text == "Auto Bat" then
    autoBatActive = enabled

    if enabled then
        if autoBatLoop then
            autoBatActive = false
            autoBatLoop = nil
        end

        autoBatActive = true

        autoBatLoop = task.spawn(function()
            while autoBatActive do
                local char = lp.Character
                if char then
                    local tool = char:FindFirstChild("Bat")
                    if tool and tool:IsA("Tool") then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                end
                task.wait(0.4) -- velocidad del golpe
            end
        end)

    else
        autoBatActive = false
    end

elseif text == "Lock Target" then
    if enabled then
        createLockTargetButton()
    else
        destroyLockTargetButton()
    end

elseif text == "Auto Medusa" then
    AutoMedusaEnabled = enabled
    InitMedusa()

elseif text == "Melee Aimbot" then
    meleeEnabled = enabled
    
    if enabled then
        if character then
            createMeleeAimbot(character)
        end
    else
        disableMeleeAimbot()
    end

elseif text == "TP Down" then
    tpDownEnabled = enabled

    if enabled then
        CreateTPDownButton()
    else
        RemoveTPDownButton()
    end

    if enabled then
        createAutoWalkGui()
    else
        destroyAutoWalkGui()
    end

elseif text == "Auto Play" then
    autoPlayEnabled = enabled

    if enabled then
        createAutoPlayGui()
    else
        destroyAutoPlayGui()
    end

elseif text == "Manual TP" then

    ManualTPEnabled = enabled

    if enabled then
        CreateTPButton()
    else
        RemoveTPButton()
    end

elseif text == "Drop Brainrot" then

    if enabled then
        createDropButton()
    else
        removeDropButton()
    end

elseif text == "FOV" then

    if enabled then
        local cam = workspace.CurrentCamera

        -- Guardar FOV original SOLO una vez
        if cam and not oldFOV then
            oldFOV = cam.FieldOfView
        end

        if fovConnection then
            fovConnection:Disconnect()
        end

        fovConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if camera then
                camera.FieldOfView = Config["FOV Value"]
            end
        end)

    else
        if fovConnection then
            fovConnection:Disconnect()
            fovConnection = nil
        end

        local cam = workspace.CurrentCamera
        if cam and oldFOV then
            cam.FieldOfView = oldFOV
        end

        oldFOV = nil -- reset
    end

elseif text == "Auto Exit Duel" then

	local Players = game:GetService("Players")

	local function watch(sound)

		if sound:IsA("Sound") and sound.Name == "GameWin" then

			sound:GetPropertyChangedSignal("Playing"):Connect(function()

				if sound.Playing then
					Players.LocalPlayer:Kick("NOVA HUB ON TOP")
				end

			end)

		end

	end

	for _,v in ipairs(game:GetDescendants()) do
		watch(v)
	end

	game.DescendantAdded:Connect(function(v)
		watch(v)
	end)

elseif text == "No Player Collision" then

    if enabled then

        local player = game.Players.LocalPlayer

        if not _G.NoPlayerCollisionConnection then
            _G.NoPlayerCollisionConnection = game:GetService("RunService").Stepped:Connect(function()

                if not player.Character then return end

                for _,plr in pairs(game.Players:GetPlayers()) do
                    if plr ~= player and plr.Character then

                        for _,part in pairs(plr.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end

                    end
                end

            end)
        end

    else

        if _G.NoPlayerCollisionConnection then
            _G.NoPlayerCollisionConnection:Disconnect()
            _G.NoPlayerCollisionConnection = nil
        end

    end

elseif text == "Lock UI" then
    UILocked = enabled

    _G.OriginalDrag = _G.OriginalDrag or {}

    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("GuiObject") and v.Active then

            -- guardar estado original SOLO UNA VEZ
            if _G.OriginalDrag[v] == nil then
                _G.OriginalDrag[v] = v.Draggable
            end

            if UILocked then
                v.Draggable = false
            else
                v.Draggable = _G.OriginalDrag[v]
            end

        end
    end

elseif text == "Super Jump" then

    superJumpEnabled = enabled  

    if superJumpEnabled then  

        if superJumpConnection then  
            superJumpConnection:Disconnect()  
        end  

        local wasJumping = false
        local canFallTP = false
        local didFallTP = false  

        superJumpConnection = RunService.Heartbeat:Connect(function()  

            if not character or not hrp or not hum then return end  

            local vel = hrp.AssemblyLinearVelocity  
            local isJumping = hum.Jump  

            -- 🟢 SUPER JUMP ORIGINAL  
            if isJumping then  

                if vel.Y < 30 then  
                    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 30, vel.Z)  
                end  

                if vel.Y > 35 then  
                    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 20, vel.Z)  
                end  

            end  

            -- Detectar inicio del salto
            if isJumping and not wasJumping then  
                canFallTP = true  
                didFallTP = false  
            end  

            -- 🔴 TP A Y = -8
            if canFallTP and not isJumping and vel.Y < -5 and not didFallTP then  

                local targetY = -8

                -- mover SIN rotar
                hrp.CFrame = hrp.CFrame * CFrame.new(0, targetY - hrp.Position.Y, 0)

                -- ajustar velocidad
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -10), vel.Z)

                didFallTP = true
            end  

            wasJumping = isJumping  

        end)  

    else  
        if superJumpConnection then  
            superJumpConnection:Disconnect()  
            superJumpConnection = nil  
        end  
    end

elseif text == "Fling" then

    if enabled then
        createFlingGui()
    else
        destroyFlingGui()
    end

elseif text == "No Camera Collision" then

    local player = game.Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")

    if enabled then

        camParts = {}

        noCamConn = runService.RenderStepped:Connect(function()

            local char = player.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local camPos = camera.CFrame.Position
            local targetPos = hrp.Position

            local size = Vector3.new(6,6,(camPos - targetPos).Magnitude)

            local cf = CFrame.new(camPos, targetPos) * CFrame.new(0,0,-size.Z/2)

            local parts = workspace:GetPartBoundsInBox(cf, size)

            local current = {}

            for _,part in ipairs(parts) do
                if part:IsA("BasePart") then

                    if not part:IsDescendantOf(char) then
                        if not game.Players:GetPlayerFromCharacter(part.Parent) then

                            -- IGNORAR SUELO
                            if part.Position.Y > hrp.Position.Y - 1 then

                                part.LocalTransparencyModifier = 0.75
                                current[part] = true
                                camParts[part] = true

                            end

                        end
                    end

                end
            end

            for part,_ in pairs(camParts) do
                if not current[part] then
                    if part and part.Parent then
                        part.LocalTransparencyModifier = 0
                    end
                    camParts[part] = nil
                end
            end

        end)

    else

        if noCamConn then
            noCamConn:Disconnect()
            noCamConn = nil
        end

        if camParts then
            for part,_ in pairs(camParts) do
                if part and part.Parent then
                    part.LocalTransparencyModifier = 0
                end
            end
        end

        camParts = {}

    end

elseif text == "Instant Grab" then

    autoStealEnabled = enabled

    if enabled then

        instantGrabLoop = task.spawn(function()

            repeat task.wait() until progressBarBg and progressFill and percentLabel
            progressBarBg.Visible = true

            while autoStealEnabled do

                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if root and hum and hum.Health > 0 then

                    local prompt = findNearestStealPrompt(root)

                    if prompt then

                        local duration = fastStealEnabled and 0.06 or 0.12
                        local start = tick()

                        while autoStealEnabled and prompt and prompt.Parent and prompt.Enabled do

                            local pos = getPromptPos(prompt)
                            if not pos then break end

                            local dist = (root.Position - pos).Magnitude

                            if dist > prompt.MaxActivationDistance then
                                break
                            end

                            local p = math.clamp((tick() - start) / duration, 0, 1)

                            progressFill.Size = UDim2.new(p,0,1,0)
                            percentLabel.Text = math.floor(p*100).."%"

                            if p >= 0.99 then
                                fireStealPrompt(prompt)
                                start = tick()
                            end

                            task.wait()
                        end
                    end
                end

                resetBar()
                task.wait(0.15)

            end

            resetBar(true)
            hideSquare()

        end)

    else
        autoStealEnabled = false
        resetBar(true)
        hideSquare()
    end
end
    end)
end

--// DELTA DESYNC (LAGBACK)

do
local parentFrame = frames["Combat"]

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

-- 🔴 SERVER POS
local serverPart
local serverConnection
local realServerPos

local function enableServerPos()
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    serverPart = Instance.new("Part")
    serverPart.Size = Vector3.new(2,2,2)
    serverPart.Shape = Enum.PartType.Ball
    serverPart.Anchored = true
    serverPart.CanCollide = false
    serverPart.Material = Enum.Material.Neon
    serverPart.Color = Color3.fromRGB(255,0,0)
    serverPart.Name = "ServerPos"
    serverPart.Parent = workspace

    serverConnection = RunService.Heartbeat:Connect(function()
        if realServerPos then
            serverPart.Position = realServerPos
        end
    end)
end

local function disableServerPos()
    if serverConnection then
        serverConnection:Disconnect()
        serverConnection = nil
    end

    if serverPart then
        serverPart:Destroy()
        serverPart = nil
    end
end

-- GUI
local container = Instance.new("Frame")  
container.Size = UDim2.new(1,0,0,55)  
container.BackgroundColor3 = Color3.fromRGB(15,15,15)  
container.BackgroundTransparency = 0.2  
container.LayoutOrder = -999  
container.Parent = parentFrame  

local corner = Instance.new("UICorner")  
corner.CornerRadius = UDim.new(0,10)  
corner.Parent = container  

local stroke = Instance.new("UIStroke")  
stroke.Color = Color3.fromRGB(0,120,255)  
stroke.Thickness = 1  
stroke.Parent = container  

local button = Instance.new("TextButton")  
button.Size = UDim2.new(1,-8,1,-8)  
button.Position = UDim2.new(0,4,0,4)  
button.BackgroundTransparency = 1  
button.Font = Enum.Font.GothamBold  
button.TextSize = 15  
button.TextColor3 = Color3.fromRGB(0,120,255)  
button.Text = "Delta Desync (Lagback) : OFF"  
button.Parent = container  

local enabled = false  

button.MouseButton1Click:Connect(function()  

enabled = not enabled  

if enabled then  

    -- 🧠 GUARDAR POS REAL ANTES DEL DESYNC
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            realServerPos = hrp.Position
        end
    end

    raknet.desync(true)  

    -- 🔴 ACTIVAR SERVER POS
    enableServerPos()

    -- 💀 RESET MANUAL
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end

    button.Text = "Delta Desync (Lagback) : ON"  

else  

    raknet.desync(false)  

    -- ❌ DESACTIVAR SERVER POS
    disableServerPos()

    button.Text = "Delta Desync (Lagback) : OFF"  

end

end)

-- 🔄 ACTUALIZAR POS REAL CONSTANTEMENTE
RunService.Heartbeat:Connect(function()
    if enabled then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                realServerPos = hrp.Position
            end
        end
    end
end)

end

local combatFuncs = {"Melee Aimbot","Instant Grab","TP Down","Auto Play","Drop Brainrot","Lock Target","Auto Medusa","Auto Bat","Fling","Manual TP","Auto Exit Duel"}
for _,f in ipairs(combatFuncs) do CreateToggle("Combat",f) end

local playerFuncs = {"Speed Customizer","No Walk Animation","Anti Ragdoll","Spin Body","Infinite Jump","Super Jump","No Player Collision"}
for _,f in ipairs(playerFuncs) do CreateToggle("Player",f) end

local visualFuncs = {"ESP Players","Xray Base","Optimizer","Anti FPS Devourer","No Camera Collision","FOV"}
for _,f in ipairs(visualFuncs) do CreateToggle("Visual",f) end

-- Radio Steal Nearest en Settings
CreateToggle("Settings","Lock UI")
CreateToggle("Settings","Radio Steal Nearest")

-- Radio Lock Target Range
do
    local parentFrame = frames["Settings"]

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,45)
    container.BackgroundColor3 = Color3.fromRGB(15,15,15)
    container.BackgroundTransparency = 0.2
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0,120,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Lock Target Range"
    label.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(0,80,0,30)
    textbox.Position = UDim2.new(1,-90,0.5,-15)
    textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 14
    textbox.Text = tostring(BAT_ENGAGE_RANGE)
    textbox.ClearTextOnFocus = false
    textbox.Parent = container
    Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)

    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textbox.Text)
            if num and num > 1 and num <= 50 then
                BAT_ENGAGE_RANGE = num
                AIMBOT_SPEED = math.max(30, math.min(120, num * 10))
            else
                textbox.Text = tostring(BAT_ENGAGE_RANGE)
            end
        end
    end)
end

-- Radio Auto Medusa
do
local parentFrame = frames["Settings"]

local container = Instance.new("Frame")  
container.Size = UDim2.new(1,0,0,45)  
container.BackgroundColor3 = Color3.fromRGB(15,15,15)  
container.BackgroundTransparency = 0.2  
container.Parent = parentFrame  
Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)  
Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)  

local label = Instance.new("TextLabel")  
label.Size = UDim2.new(0.6,0,1,0)  
label.Position = UDim2.new(0,12,0,0)  
label.BackgroundTransparency = 1  
label.Font = Enum.Font.GothamBold  
label.TextSize = 14  
label.TextColor3 = Color3.fromRGB(0,120,255)  
label.TextXAlignment = Enum.TextXAlignment.Left  
label.Text = "Auto Medusa Range"  
label.Parent = container  

local textbox = Instance.new("TextBox")  
textbox.Size = UDim2.new(0,80,0,30)  
textbox.Position = UDim2.new(1,-90,0.5,-15)  
textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)  
textbox.TextColor3 = Color3.new(1,1,1)  
textbox.Font = Enum.Font.Gotham  
textbox.TextSize = 14  
textbox.Text = tostring(MEDUSA_RADIUS)  
textbox.ClearTextOnFocus = false  
textbox.Parent = container  
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)  
Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)  

textbox.FocusLost:Connect(function(enterPressed)  
    if enterPressed then  
        local num = tonumber(textbox.Text)  
        if num and num > 1 and num <= 200 then  
            MEDUSA_RADIUS = num  

            if medusaPart then  
                medusaPart.Size = Vector3.new(0.2, MEDUSA_RADIUS*2, MEDUSA_RADIUS*2)  
            end  
        else  
            textbox.Text = tostring(MEDUSA_RADIUS)  
        end  
    end  
end)

end

-- Spin Speed
do
    local parentFrame = frames["Settings"]

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,45)
    container.BackgroundColor3 = Color3.fromRGB(15,15,15)
    container.BackgroundTransparency = 0.2
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0,120,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Spin Speed"
    label.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(0,80,0,30)
    textbox.Position = UDim2.new(1,-90,0.5,-15)
    textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 14
    textbox.Text = tostring(Config["Spin Speed"] or 30)
    textbox.ClearTextOnFocus = false
    textbox.Parent = container

    Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)

textbox.FocusLost:Connect(function()
    local num = tonumber(textbox.Text)
    if num then
        Config["Spin Speed"] = num
        SaveConfig()
    end
end)
end


-- Melee Aimbot Range
do
    local parentFrame = frames["Settings"]

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,45)
    container.BackgroundColor3 = Color3.fromRGB(15,15,15)
    container.BackgroundTransparency = 0.2
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0,120,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Melee Aimbot Range"
    label.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(0,80,0,30)
    textbox.Position = UDim2.new(1,-90,0.5,-15)
    textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 14
    textbox.Text = tostring(MELEE_RANGE)
    textbox.ClearTextOnFocus = false
    textbox.Parent = container
    Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)

    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textbox.Text)
            if num and num > 1 and num <= 50 then
                MELEE_RANGE = num
            else
                textbox.Text = tostring(MELEE_RANGE)
            end
        end
    end)
end

-- FOV SETTING
do
    local parentFrame = frames["Settings"]

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,0,0,45)
    container.BackgroundColor3 = Color3.fromRGB(15,15,15)
    container.BackgroundTransparency = 0.2
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0,120,255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0,120,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "FOV"
    label.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(0,80,0,30)
    textbox.Position = UDim2.new(1,-90,0.5,-15)
    textbox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 14
    textbox.Text = tostring(Config["FOV Value"])
    textbox.ClearTextOnFocus = false
    textbox.Parent = container
    Instance.new("UICorner", textbox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", textbox).Color = Color3.fromRGB(0,120,255)

    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(textbox.Text)

            if num and num >= 30 and num <= 150 then
    FOV_VALUE = num
    Config["FOV Value"] = num
    SaveConfig()
            else
                textbox.Text = tostring(Config["FOV Value"])
            end
        end
    end)
end

ShowSection("Combat")

-- OPEN / CLOSE HUB
local opened = false
toggleBtn.MouseButton1Click:Connect(function()
    opened = not opened
    if opened then
        TweenService:Create(hub, TweenInfo.new(0.3), {Position = UDim2.new(0,20,0.5,-HUB_HEIGHT/2)}):Play()
    else
        TweenService:Create(hub, TweenInfo.new(0.3), {Position = UDim2.new(0,-350,0.5,-HUB_HEIGHT/2)}):Play()
    end
end)

--// =========================
-- APPLY SAVED CONFIG (FIXED)
-- =========================

task.spawn(function()

    task.wait(1.5)

    local char = lp.Character or lp.CharacterAdded:Wait()

for text,enabled in pairs(Config) do
    if enabled then

        task.spawn(function()

            if text == "Speed Customizer" then
                local boosterGui = lp.PlayerGui:FindFirstChild("BoosterCustomizer")
                if boosterGui then
                    boosterGui.Enabled = true
                end

            elseif text == "Infinite Jump" then
                infiniteJumpEnabled = true

elseif text == "Optimizer" then
    if enabled then
        enableOptimizer()
    else
        disableOptimizer()
    end

            elseif text == "Xray Base" then
                toggleESPBases(true)

            elseif text == "ESP Players" then
                toggleESPPlayers(enabled)

elseif text == "Anti FPS Devourer" then
    if enabled then
        enableAntiFPSDevourer()
    else
        disableAntiFPSDevourer()
    end

elseif text == "Lock UI" then
    UILocked = enabled

    _G.OriginalDrag = _G.OriginalDrag or {}

    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("GuiObject") and v.Active then

            -- guardar estado original SOLO UNA VEZ
            if _G.OriginalDrag[v] == nil then
                _G.OriginalDrag[v] = v.Draggable
            end

            if UILocked then
                v.Draggable = false
            else
                v.Draggable = _G.OriginalDrag[v]
            end

        end
    end

elseif text == "No Walk Animation" then

    if enabled then

        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")
        local animator = humanoid:WaitForChild("Animator")

        lastPos = root.Position

        local function isMoving()
            local currentPos = root.Position
            local distance = (currentPos - lastPos).Magnitude
            lastPos = currentPos
            return distance > 0.05
        end

        -- conexión animaciones nuevas
        noWalkConnection1 = animator.AnimationPlayed:Connect(function(track)
            task.defer(function()
                if isMoving() then
                    pcall(function()
                        track:Stop()
                    end)
                end
            end)
        end)

        -- loop anti bypass
        noWalkConnection2 = game:GetService("RunService").RenderStepped:Connect(function()
            if isMoving() then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function()
                        track:Stop()
                    end)
                end
            end
        end)

    else

        if noWalkConnection1 then
            noWalkConnection1:Disconnect()
            noWalkConnection1 = nil
        end

        if noWalkConnection2 then
            noWalkConnection2:Disconnect()
            noWalkConnection2 = nil
        end

    end

            elseif text == "Auto Bat" then
                autoBatActive = true

                task.spawn(function()
                    while autoBatActive do
                        local char = lp.Character
                        if char then
                            local tool = char:FindFirstChild("Bat")
                            if tool then
                                pcall(function()
                                    tool:Activate()
                                end)
                            end
                        end
                        task.wait(0.4)
                    end
                end)

            elseif text == "Auto Medusa" then
                AutoMedusaEnabled = true
                InitMedusa()

            elseif text == "Melee Aimbot" then
                meleeEnabled = true
                if lp.Character then
                    createMeleeAimbot(lp.Character)
                end

            elseif text == "Lock Target" then
                createLockTargetButton()

elseif text == "Super Jump" then

    superJumpEnabled = enabled  

    if superJumpEnabled then  

        if superJumpConnection then  
            superJumpConnection:Disconnect()  
        end  

        local wasJumping = false
        local canFallTP = false
        local didFallTP = false  

        superJumpConnection = RunService.Heartbeat:Connect(function()  

            if not character or not hrp or not hum then return end  

            local vel = hrp.AssemblyLinearVelocity  
            local isJumping = hum.Jump  

            -- 🟢 SUPER JUMP ORIGINAL  
            if isJumping then  

                if vel.Y < 30 then  
                    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 30, vel.Z)  
                end  

                if vel.Y > 35 then  
                    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 20, vel.Z)  
                end  

            end  

            -- Detectar inicio del salto
            if isJumping and not wasJumping then  
                canFallTP = true  
                didFallTP = false  
            end  

            -- 🔴 TP A Y = -8
            if canFallTP and not isJumping and vel.Y < -5 and not didFallTP then  

                local targetY = -8

                -- mover SIN rotar
                hrp.CFrame = hrp.CFrame * CFrame.new(0, targetY - hrp.Position.Y, 0)

                -- ajustar velocidad
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -10), vel.Z)

                didFallTP = true
            end  

            wasJumping = isJumping  

        end)  

    else  
        if superJumpConnection then  
            superJumpConnection:Disconnect()  
            superJumpConnection = nil  
        end  
    end

elseif text == "TP Down" then
    tpDownEnabled = enabled

    if enabled then
        CreateTPDownButton()
    else
        RemoveTPDownButton()
    end

            elseif text == "Auto Play" then
                createAutoPlayGui()

elseif text == "Manual TP" then

    ManualTPEnabled = enabled

    if enabled then
        CreateTPButton()
    else
        RemoveTPButton()
    end

elseif text == "Auto Exit Duel" then

	local Players = game:GetService("Players")

	local function watch(sound)

		if sound:IsA("Sound") and sound.Name == "GameWin" then

			sound:GetPropertyChangedSignal("Playing"):Connect(function()

				if sound.Playing then
					Players.LocalPlayer:Kick("NOVA HUB ON TOP")
				end

			end)

		end

	end

	for _,v in ipairs(game:GetDescendants()) do
		watch(v)
	end

	game.DescendantAdded:Connect(function(v)
		watch(v)
	end)

            elseif text == "Drop Brainrot" then
                createDropButton()

            elseif text == "Fling" then
                createFlingGui()

elseif text == "No Camera Collision" then

    local player = game.Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local runService = game:GetService("RunService")

    if enabled then

        camParts = {}

        noCamConn = runService.RenderStepped:Connect(function()

            local char = player.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local camPos = camera.CFrame.Position
            local targetPos = hrp.Position

            local size = Vector3.new(6,6,(camPos - targetPos).Magnitude)

            local cf = CFrame.new(camPos, targetPos) * CFrame.new(0,0,-size.Z/2)

            local parts = workspace:GetPartBoundsInBox(cf, size)

            local current = {}

            for _,part in ipairs(parts) do
                if part:IsA("BasePart") then

                    if not part:IsDescendantOf(char) then
                        if not game.Players:GetPlayerFromCharacter(part.Parent) then

                            -- IGNORAR SUELO
                            if part.Position.Y > hrp.Position.Y - 1 then

                                part.LocalTransparencyModifier = 0.75
                                current[part] = true
                                camParts[part] = true

                            end

                        end
                    end

                end
            end

            for part,_ in pairs(camParts) do
                if not current[part] then
                    if part and part.Parent then
                        part.LocalTransparencyModifier = 0
                    end
                    camParts[part] = nil
                end
            end

        end)

    else

        if noCamConn then
            noCamConn:Disconnect()
            noCamConn = nil
        end

        if camParts then
            for part,_ in pairs(camParts) do
                if part and part.Parent then
                    part.LocalTransparencyModifier = 0
                end
            end
        end

        camParts = {}

    end

elseif text == "Spin Body" then

    if enabled then
        createSpinButton()
    else
        removeSpinButton()
    end

elseif text == "FOV" then

    if enabled then
        local cam = workspace.CurrentCamera

        -- Guardar FOV original SOLO una vez
        if cam and not oldFOV then
            oldFOV = cam.FieldOfView
        end

        if fovConnection then
            fovConnection:Disconnect()
        end

        fovConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if camera then
                camera.FieldOfView = Config["FOV Value"]
            end
        end)

    else
        if fovConnection then
            fovConnection:Disconnect()
            fovConnection = nil
        end

        local cam = workspace.CurrentCamera
        if cam and oldFOV then
            cam.FieldOfView = oldFOV
        end

        oldFOV = nil -- reset
    end

elseif text == "No Player Collision" then

    if enabled then

        if not _G.NoPlayerCollisionConnection then
            _G.NoPlayerCollisionConnection = RunService.Stepped:Connect(function()

                local player = game.Players.LocalPlayer

                for _,plr in pairs(game.Players:GetPlayers()) do
                    if plr ~= player and plr.Character then

                        for _,part in pairs(plr.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end

                    end
                end

            end)
        end

    end

elseif text == "Anti Ragdoll" then
    AntiRagdollEnabled = true
    startAntiRagdoll()

            elseif text == "Anti Sentry" then
                startAntiSentry()

elseif text == "Instant Grab" then

    autoStealEnabled = enabled

    if enabled then

        instantGrabLoop = task.spawn(function()

            repeat task.wait() until progressBarBg and progressFill and percentLabel
            progressBarBg.Visible = true

            while autoStealEnabled do

                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if root and hum and hum.Health > 0 then

                    local prompt = findNearestStealPrompt(root)

                    if prompt then

                        local duration = fastStealEnabled and 0.06 or 0.12
                        local start = tick()

                        while autoStealEnabled and prompt and prompt.Parent and prompt.Enabled do

                            local pos = getPromptPos(prompt)
                            if not pos then break end

                            local dist = (root.Position - pos).Magnitude

                            if dist > prompt.MaxActivationDistance then
                                break
                            end

                            local p = math.clamp((tick() - start) / duration, 0, 1)

                            progressFill.Size = UDim2.new(p,0,1,0)
                            percentLabel.Text = math.floor(p*100).."%"

                            if p >= 0.99 then
                                fireStealPrompt(prompt)
                                start = tick()
                            end

                            task.wait()
                        end
                    end
                end

                resetBar()
                task.wait(0.15)

            end

            resetBar(true)
            hideSquare()

        end)

    else
        autoStealEnabled = false
        resetBar(true)
        hideSquare()
    end
end

        end)

    end
end
end)

task.spawn(function()

    if game:GetService("CoreGui"):FindFirstChild("TauntButtonGui") then
        game:GetService("CoreGui").TauntButtonGui:Destroy()
    end

    local TextChatService = game:GetService("TextChatService")

    local function sendMessage(msg)
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(msg)
            end
        else
            game:GetService("ReplicatedStorage")
                .DefaultChatSystemChatEvents
                .SayMessageRequest
                :FireServer(msg, "All")
        end
    end

    local tauntGui = Instance.new("ScreenGui")
    tauntGui.Name = "TauntButtonGui"
    tauntGui.ResetOnSpawn = false
    tauntGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,120,0,40)
    button.Position = UDim2.new(1, -130, 0, 10)  -- Top right corner

    button.Text = "TAUNT"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.new(1,1,1)
    button.BackgroundColor3 = Color3.fromRGB(0,120,255)
    button.Parent = tauntGui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

    button.Active = true
    button.Draggable = not UILocked

    local tauntActive = false

    button.MouseButton1Click:Connect(function()

        tauntActive = not tauntActive

        if tauntActive then
            button.Text = "TAUNTING"
            button.BackgroundColor3 = Color3.fromRGB(200,0,0)

            task.spawn(function()
                while tauntActive do
                    sendMessage("Nova Hub On Top")
                    task.wait(1)
                end
            end)

        else
            button.Text = "TAUNT"
            button.BackgroundColor3 = Color3.fromRGB(0,120,255)
        end

    end)

end)

-- =========================
-- MODIFIED SPEED DISPLAY (Smaller, "VOL", No Outline)
-- =========================

local function makeSpeedGui()
	local c = lp.Character or lp.CharacterAdded:Wait()
	local h = c:WaitForChild("Head")
	if h:FindFirstChild("SpeedGui") then h.SpeedGui:Destroy() end

	local g = Instance.new("BillboardGui", h)
	g.Name = "SpeedGui"
	g.Adornee = h
	g.Size = UDim2.new(0, 80, 0, 20)  -- Smaller size
	g.StudsOffset = Vector3.new(0, 2.6, 0)
	g.AlwaysOnTop = true

	local f = Instance.new("Frame", g)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, 0, 0.5, 0)
	f.Size = UDim2.new(1, 0, 1, 0)
	f.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	f.BackgroundTransparency = 0.18
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

	-- NO OUTLINE (UIStroke removed)

	local t = Instance.new("TextLabel", f)
	t.Size = UDim2.new(1, -4, 1, 0)
	t.Position = UDim2.new(0, 2, 0, 0)
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.fromRGB(0, 170, 255)
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.RichText = true
	t.Text = "<font transparency='0.10'>VOL</font> 0"  -- Changed from SPD to VOL

	local baseY = 2.6
	local start = tick()

	RunService.RenderStepped:Connect(function()
		local rt = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		if rt then
			local v = rt.AssemblyLinearVelocity
			t.Text = "<font transparency='0.35'>VOL</font> " .. math.floor(Vector3.new(v.X, 0, v.Z).Magnitude + 0.5)
		end

		local wave = math.sin((tick() - start) * 3.8)
		g.StudsOffset = Vector3.new(0, baseY + wave * 0.4, 0)

		local pulse = (wave + 1) / 2
		f.Size = UDim2.new(1, pulse * 3, 1, pulse * 1.5)
	end)
end

lp.CharacterAdded:Connect(function() task.wait(0.3) makeSpeedGui() end)
makeSpeedGui()

-- =========================
-- DUEL FINDER (INVISIBLE)
-- =========================

-- The Duel Finder GUI is now invisible. The button and its functionality are removed as requested.

-- =========================
-- MEDUSA COUNTER - ALWAYS ENABLED
-- =========================

-- Automatically activates Medusa whenever you get frozen/stunned

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local State = {
	medusaLastUsed = 0,
	medusaDebounce = false,
}

local MEDUSA_COOLDOWN = 25

-- Find Medusa tool in inventory or backpack
local function findMedusa()
	local char = LP.Character
	if not char then return nil end
	
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then
			local tn = tool.Name:lower()
			if tn:find("medusa") or tn:find("head") or tn:find("stone") or tn:find("gorgon") then
				return tool
			end
		end
	end
	
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") then
				local tn = tool.Name:lower()
				if tn:find("medusa") or tn:find("head") or tn:find("stone") or tn:find("gorgon") then
					return tool
				end
			end
		end
	end
	
	return nil
end

-- Activate Medusa
local function activateMedusa()
	if State.medusaDebounce then return end
	if tick() - State.medusaLastUsed < MEDUSA_COOLDOWN then return end
	
	local char = LP.Character
	if not char then return end
	
	State.medusaDebounce = true
	
	local medusa = findMedusa()
	if medusa then
		if medusa.Parent ~= char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:EquipTool(medusa)
			end
		end
		
		pcall(function()
			medusa:Activate()
			local ev = medusa:FindFirstChildWhichIsA("RemoteEvent")
			if ev then ev:FireServer() end
		end)
		
		State.medusaLastUsed = tick()
	end
	
	State.medusaDebounce = false
end

-- Watch for anchored parts (frozen/stunned)
local function watchCharacter(char)
	if not char then return end
	
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part:GetPropertyChangedSignal("Anchored"):Connect(function()
				if part.Anchored and part.Transparency == 1 then
					activateMedusa()
				end
			end)
		end
	end
	
	char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			part:GetPropertyChangedSignal("Anchored"):Connect(function()
				if part.Anchored and part.Transparency == 1 then
					activateMedusa()
				end
			end)
		end
	end)
end

-- Initial setup
if LP.Character then
	watchCharacter(LP.Character)
end

-- Handle respawns
LP.CharacterAdded:Connect(watchCharacter)
 
print("hi bj")
