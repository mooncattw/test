local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local lp = Players.LocalPlayer

local CONFIG = {
    AUTO_STEAL_ENABLED = true,
    HOLD_MIN = 1.3,
    HOLD_MAX = 2.6,
    ENTRY_DELAY = 0.3,
    COOLDOWN = 0.1,
    STEAL_RANGE = 8,
    PRIME_RANGE = 70,
}

local S = {
    Players = Players,
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = RunService,
}

local Packages = S.ReplicatedStorage:WaitForChild("Packages")
local Datas = S.ReplicatedStorage:WaitForChild("Datas")
local AnimalsData = require(Datas:WaitForChild("Animals"))

local plots = workspace:WaitForChild("Plots")

local syncRemotes = (function()
    local folder = Packages:WaitForChild("Synchronizer")
    return {
        channelFolder = folder:WaitForChild("Channel"),
        routeRemote = folder:WaitForChild("CommunicationRoute"),
        requestData = folder:FindFirstChild("RequestData"),
    }
end)()

local plotAnimalSync = { caches = {}, connections = {} }

local function splitSyncPath(path)
    if typeof(path) == "table" then return path end
    local out = {}
    for part in string.gmatch(tostring(path), "[^%.]+") do
        table.insert(out, tonumber(part) or part)
    end
    return out
end

local function resolveSyncPath(path, root)
    local current = root
    local parent, key
    for _, part in ipairs(splitSyncPath(path)) do
        parent = current
        key = part
        current = current and current[part] or nil
    end
    return current, parent, key
end

local function applyPlotSyncDiff(channelName, packet)
    local cache = plotAnimalSync.caches[channelName]
    if typeof(cache) ~= "table" then return end
    local path, action, a, b = packet[1], packet[2], packet[3], packet[4]
    local current, parent, key = resolveSyncPath(path, cache)
    if action == "Changed" then
        if parent then parent[key] = a end
    elseif action == "ArrayInsert" then
        if current then table.insert(current, b, a) end
    elseif action == "ArrayRemoved" then
        if current then table.remove(current, b) end
    elseif action == "DictionaryInsert" then
        if current then current[b] = a end
    elseif action == "DictionaryRemoved" then
        if current then current[b] = nil end
    end
end

local function attachPlotChannel(remote)
    local channelName = tostring(remote.Name)
    if not plots:FindFirstChild(channelName) then return end
    
    if not plotAnimalSync.caches[channelName] then
        if syncRemotes.requestData then
            local ok, data = pcall(function()
                return syncRemotes.requestData:InvokeServer(channelName)
            end)
            plotAnimalSync.caches[channelName] = ok and data or {}
        else
            plotAnimalSync.caches[channelName] = {}
        end
    end

    plotAnimalSync.connections[remote] = remote.OnClientEvent:Connect(function(queue)
        for _, packet in ipairs(queue) do
            applyPlotSyncDiff(channelName, packet)
        end
    end)
end

for _, child in ipairs(syncRemotes.channelFolder:GetChildren()) do
    if child:IsA("RemoteEvent") then attachPlotChannel(child) end
end
syncRemotes.channelFolder.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") then attachPlotChannel(child) end
end)

local allAnimalsCache = {}
local StealState = { active = false, startTime = 0 }

local progressBarBg, progressFill, statusLabel, infoLabel, bannerFrame, bannerStroke

local function updateUI()
    local statusText = StealState.active and "STEALING" or (#allAnimalsCache > 0 and "READY" or "SCANNING")
    local progressValue = StealState.active and 1 or math.clamp(#allAnimalsCache / 18, 0, 1)

    if progressFill then
        progressFill.Size = UDim2.new(progressValue, 0, 1, 0)
    end

    if statusLabel then
        statusLabel.Text = statusText
    end

    if infoLabel then
        infoLabel.Text = string.format("Auto Steal • %s • %d targets", statusText:lower(), #allAnimalsCache)
    end
end

local function getPlotOwner(plot)
    local sign = plot:FindFirstChild("PlotSign")
    local frame = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
    local label = frame and frame:FindFirstChild("TextLabel")
    if not label or label.Text == "Empty Base" then return nil end
    return label.Text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
end

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then return false end
    local plot = plots:FindFirstChild(animalData.plot)
    return plot and getPlotOwner(plot) == lp.DisplayName
end

local function findProximityPromptForAnimal(animalData)
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    local base = podium:FindFirstChild("Base")
    local spawn = base and base:FindFirstChild("Spawn")
    local attach = spawn and spawn:FindFirstChild("PromptAttachment")
    if not attach then return nil end
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            return p
        end
    end
    return nil
end

local function getAnimalPosition(animalData)
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    local podium = podiums and podiums:FindFirstChild(animalData.slot)
    return podium and podium:GetPivot().Position
end

local function distToAnimal(animalData)
    local character = lp.Character
    if not character then return math.huge end
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    local pos = getAnimalPosition(animalData)
    if not hrp or not pos then return math.huge end
    return (hrp.Position - pos).Magnitude
end

local function pickClosest()
    local character = lp.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge
    for _, animal in ipairs(allAnimalsCache) do
        if isMyBaseAnimal(animal) then continue end
        local dist = distToAnimal(animal)
        if dist <= CONFIG.PRIME_RANGE and dist < bestDist then
            bestDist = dist
            best = animal
        end
    end
    return best
end

local function attemptSteal(animalData)
    if StealState.active then return false end
    
    local prompt = findProximityPromptForAnimal(animalData)
    if not prompt then return false end

    StealState.active = true
    StealState.startTime = tick()

    task.spawn(function()
        if prompt.HoldDuration > 0 then
            prompt:InputHoldBegin()
            task.wait(CONFIG.HOLD_MIN)
            
            while (tick() - StealState.startTime) < CONFIG.HOLD_MAX do
                if distToAnimal(animalData) <= CONFIG.STEAL_RANGE then
                    prompt:InputHoldEnd()
                    task.wait(CONFIG.ENTRY_DELAY)
                    prompt:InputBegan()
                    task.wait(0.1)
                    prompt:InputEnded()
                    break
                end
                task.wait()
            end
        else
        
            prompt:InputBegan()
            task.wait(0.1)
            prompt:InputEnded()
        end

        StealState.active = false
        task.wait(CONFIG.COOLDOWN)
    end)
    return true
end

local function scanAllPlots()
    local newCache = {}
    for _, plot in ipairs(plots:GetChildren()) do
        local cache = plotAnimalSync.caches[plot.Name]
        if not cache or typeof(cache.AnimalList) ~= "table" then continue end
        
        for slot, animalData in pairs(cache.AnimalList) do
            if typeof(animalData) == "table" then
                local info = AnimalsData[animalData.Index]
                if info then
                    table.insert(newCache, {
                        name = info.DisplayName or animalData.Index,
                        plot = plot.Name,
                        slot = tostring(slot),
                        uid = plot.Name .. "_" .. tostring(slot),
                    })
                end
            end
        end
    end
    allAnimalsCache = newCache
end

local function startAutoSteal()
    RunService.Heartbeat:Connect(function()
        if not CONFIG.AUTO_STEAL_ENABLED or StealState.active then return end
        
        local target = pickClosest()
        if target then
            attemptSteal(target)
        end
    end)
end

local function setupUI()
    local sg = lp.PlayerGui:FindFirstChild("Moon Hub")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "Moon Hub"
        sg.ResetOnSpawn = false
        sg.Parent = lp.PlayerGui
    end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 110)
    container.Position = UDim2.new(0.5, -150, 0, 24)
    container.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
    container.BackgroundTransparency = 0.08
    container.Parent = sg
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)

    local containerStroke = Instance.new("UIStroke", container)
    containerStroke.Color = Color3.fromRGB(84, 130, 220)
    containerStroke.Thickness = 1.2

    bannerFrame = Instance.new("Frame")
    bannerFrame.Size = UDim2.new(1, -16, 0, 36)
    bannerFrame.Position = UDim2.new(0, 8, 0, 8)
    bannerFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
    bannerFrame.Parent = container
    Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 10)

    bannerStroke = Instance.new("UIStroke", bannerFrame)
    bannerStroke.Color = Color3.fromRGB(92, 166, 255)
    bannerStroke.Thickness = 1.1

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -12, 1, 0)
    titleLabel.Position = UDim2.new(0, 6, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "AUTO STEAL"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = bannerFrame

    infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -16, 0, 20)
    infoLabel.Position = UDim2.new(0, 8, 0, 48)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 13
    infoLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    infoLabel.Text = "Auto Steal • standby • 0 targets"
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = container

    progressBarBg = Instance.new("Frame")
    progressBarBg.Size = UDim2.new(1, -16, 0, 12)
    progressBarBg.Position = UDim2.new(0, 8, 0, 78)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
    progressBarBg.Parent = container
    Instance.new("UICorner", progressBarBg).CornerRadius = UDim.new(0, 8)

    progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
    progressFill.Parent = progressBarBg
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 8)

    local fillGradient = Instance.new("UIGradient", progressFill)
    fillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 200)),
    })

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 0, 54)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "READY"
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = container
end

setupUI()
updateUI()
startAutoSteal()
task.spawn(function()
    while task.wait(4) do
        scanAllPlots()
        updateUI()
    end
end)
