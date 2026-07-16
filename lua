--[[
    MOON HUB [V7 - FINAL]
    - AI Riddle Solver (Claude API)
    - Advanced Timer Blacklist (38m2s, 1h, 200f vb. engelli)
    - Auto Submit (Click Event)
    - Blue Theme & Words Counter
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

--// AYARLAR //--
local _enabled = false
local _targetWords = 3
local _currentWords = 0
local _collectedWords = {}
local _seen = {}
local ANTHROPIC_KEY = "sk-ant-api03-placeholder-replace-with-real-key" -- Buraya kendi API anahtarını koy

--// BLACKLIST SİSTEMİ (Sayaç ve Gereksiz Kelime Engelleme) //--
local BLACKLIST_PHRASES = {
    "refreshesin", "restockingin", "freespinin", "font", "hub", "ago", 
    "left", "wait", "stock", "next", "timer", "remaining", "update"
}

local function isBlacklisted(txt)
    local l = txt:lower():gsub("%s+", "") -- Boşlukları silip küçült
    
    -- Zaman desenlerini yakala: 38m2s, 5m16s, 30s, 1h, 200f
    if l:match("%d+h") or l:match("%d+m") or l:match("%d+s") or l:match("%d+f") then
        return true
    end
    
    -- Kelime bazlı kontrol
    for _, word in ipairs(BLACKLIST_PHRASES) do
        if l:find(word) then return true end
    end
    
    return false
end

--// AI & RIDDLE (BİLMECE) MANTIĞI //--
local RIDDLE_KW = {
    "when was","how old","what year","what month","birthday","age of",
    "released","hint","riddle","figure out","guess","backwards","combine"
}

local function isRiddle(txt)
    local l = txt:lower()
    for _, p in ipairs(RIDDLE_KW) do
        if l:find(p, 1, true) then return true end
    end
    return false
end

local function callAI(prompt)
    if not ANTHROPIC_KEY or ANTHROPIC_KEY == "" or ANTHROPIC_KEY:find("placeholder") then return nil end
    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model = "claude-3-sonnet-20240229",
            max_tokens = 40,
            system = "Decode Roblox promo codes for Steal a Brainrot (SAB). SAB released May 2024. Sammy is 24. Output ONLY the code uppercase no spaces.",
            messages = {{role = "user", content = prompt}}
        })
        local resp = HttpService:RequestAsync({
            Url = "https://api.anthropic.com/v1/messages",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json", 
                ["x-api-key"] = ANTHROPIC_KEY, 
                ["anthropic-version"] = "2023-06-01"
            },
            Body = body
        })
        if resp.StatusCode == 200 then
            local data = HttpService:JSONDecode(resp.Body)
            return data.content[1].text
        end
    end)
    if ok and result then 
        return tostring(result):match("^%s*([A-Z0-9*%-]+)%s*$") 
    end
    return nil
end

--// UI TASARIMI (MOON HUB MAVİ) //--
local GUI = Instance.new("ScreenGui")
GUI.Name = "MoonHubFinal"; GUI.ResetOnSpawn = false
if gethui then GUI.Parent = gethui() else GUI.Parent = game.CoreGui end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 230); Main.Position = UDim2.new(0.5, -120, 0.4, -115)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15); Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true; Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(0, 160, 255); MainStroke.Thickness = 2

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45); Title.BackgroundTransparency = 1
Title.Text = "Moon Hub [F]"; Title.TextColor3 = Color3.fromRGB(0, 180, 255)
Title.TextSize = 20; Title.Font = Enum.Font.FredokaOne; Title.Parent = Main

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 110, 0, 40); StartBtn.Position = UDim2.new(0.5, -55, 0, 55)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30); StartBtn.Text = "start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255); StartBtn.TextSize = 22
StartBtn.Font = Enum.Font.FredokaOne; StartBtn.Parent = Main
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)
local BtnStroke = Instance.new("UIStroke", StartBtn)
BtnStroke.Color = Color3.fromRGB(0, 160, 255)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20); StatusLbl.Position = UDim2.new(0, 0, 0, 105)
StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "disabled"; StatusLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
StatusLbl.TextSize = 14; StatusLbl.Font = Enum.Font.FredokaOne; StatusLbl.Parent = Main

local CounterLbl = Instance.new("TextLabel")
CounterLbl.Size = UDim2.new(1, 0, 0, 30); CounterLbl.Position = UDim2.new(0, 0, 0, 130)
CounterLbl.BackgroundTransparency = 1; CounterLbl.Text = "0/3"; CounterLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
CounterLbl.TextSize = 22; CounterLbl.Font = Enum.Font.FredokaOne; CounterLbl.Parent = Main

-- Words Ayarı (+/-)
local wordFrame = Instance.new("Frame")
wordFrame.Size = UDim2.new(1, -40, 0, 40); wordFrame.Position = UDim2.new(0, 20, 0, 175)
wordFrame.BackgroundTransparency = 1; wordFrame.Parent = Main

local wordText = Instance.new("TextLabel")
wordText.Size = UDim2.new(0, 70, 1, 0); wordText.BackgroundTransparency = 1; wordText.Text = "words:"
wordText.TextColor3 = Color3.fromRGB(150, 150, 150); wordText.TextSize = 16; wordText.Font = Enum.Font.FredokaOne; wordText.Parent = wordFrame

local wordVal = Instance.new("TextLabel")
wordVal.Size = UDim2.new(0, 40, 1, 0); wordVal.Position = UDim2.new(0.5, -20, 0, 0); wordVal.BackgroundTransparency = 1
wordVal.Text = tostring(_targetWords); wordVal.TextColor3 = Color3.fromRGB(0, 180, 255); wordVal.TextSize = 18; wordVal.Font = Enum.Font.FredokaOne; wordVal.Parent = wordFrame

local mBtn = Instance.new("TextButton")
mBtn.Size = UDim2.new(0, 25, 0, 25); mBtn.Position = UDim2.new(0.25, 0, 0.2, 0); mBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); mBtn.Text = "-"; mBtn.TextColor3 = Color3.fromRGB(255, 255, 255); mBtn.Parent = wordFrame; Instance.new("UICorner", mBtn)

local pBtn = Instance.new("TextButton")
pBtn.Size = UDim2.new(0, 25, 0, 25); pBtn.Position = UDim2.new(0.75, -5, 0.2, 0); pBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); pBtn.Text = "+"; pBtn.TextColor3 = Color3.fromRGB(255, 255, 255); pBtn.Parent = wordFrame; Instance.new("UICorner", pBtn)

--// SİSTEM FONKSİYONLARI //--

local function updateCounter() CounterLbl.Text = _currentWords .. "/" .. _targetWords end

local function submitCode(code)
    local box = nil
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and (v.Name:lower():find("code") or v.PlaceholderText:lower():find("code")) then
            box = v; break
        end
    end
    if box then
        box.Text = code
        task.wait(0.1)
        local btn = nil
        for _, b in ipairs(box.Parent:GetChildren()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                local t = (b:IsA("TextButton") and b.Text:lower() or b.Name:lower())
                if t:find("redeem") or t:find("claim") or t:find("submit") or t:find("enter") then
                    btn = b; break
                end
            end
        end
        if btn then
            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
            for _, event in ipairs(events) do
                if btn[event] then
                    for _, con in ipairs(getconnections(btn[event])) do con:Fire() end
                end
            end
        end
    end
    _currentWords = 0; _collectedWords = {}; updateCounter()
end

local function processText(txt)
    if not _enabled or #txt < 2 or _seen[txt] or isBlacklisted(txt) then return end
    _seen[txt] = true; task.delay(10, function() _seen[txt] = nil end)

    -- Bilmece mi? AI Çözsün
    if isRiddle(txt) then
        task.spawn(function()
            StatusLbl.Text = "solving riddle..."; StatusLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
            local aiRes = callAI(txt)
            if aiRes then submitCode(aiRes) end
            StatusLbl.Text = "enabled"; StatusLbl.TextColor3 = Color3.fromRGB(0, 180, 255)
        end)
        return
    end

    -- Normal Kelime Parçası Toplama
    local clean = txt:gsub("[^A-Za-z0-9]", "")
    if #clean >= 2 then
        table.insert(_collectedWords, clean)
        _currentWords = _currentWords + 1
        updateCounter()
        if _currentWords >= _targetWords then
            submitCode(table.concat(_collectedWords, ""))
        end
    end
end

--// ETKİLEŞİM VE DİNLEYİCİLER //--

local function toggle()
    _enabled = not _enabled
    StartBtn.Text = _enabled and "stop" or "start"
    StatusLbl.Text = _enabled and "enabled" or "disabled"
    StatusLbl.TextColor3 = _enabled and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(255, 60, 60)
end

StartBtn.MouseButton1Click:Connect(toggle)
pBtn.MouseButton1Click:Connect(function() _targetWords = _targetWords + 1; wordVal.Text = _targetWords; updateCounter() end)
mBtn.MouseButton1Click:Connect(function() if _targetWords > 1 then _targetWords = _targetWords - 1; wordVal.Text = _targetWords; updateCounter() end end)
UserInputService.InputBegan:Connect(function(io, g) if not g and io.KeyCode == Enum.KeyCode.F then toggle() end end)

playerGui.DescendantAdded:Connect(function(o)
    if o:IsA("TextLabel") then
        o:GetPropertyChangedSignal("Text"):Connect(function() processText(o.Text) end)
        processText(o.Text)
    end
end)

for _, v in ipairs(playerGui:GetDescendants()) do
    if v:IsA("TextLabel") then
        v:GetPropertyChangedSignal("Text"):Connect(function() processText(v.Text) end)
    end
end

pcall(function()
    game:GetService("TextChatService").MessageReceived:Connect(function(m) processText(m.Text) end)
end)

print("Moon Hub V7 Loaded - Blacklist & AI & Clicker Active!")
