--[[
    MOON HUB [V10]
    - Blacklist: setcreatorid, timers (38m2s vb.), refreshes, vb.
    - Duyuru (Announcement) Takibi: Global mesajları yakalar ve kutuya yazar.
    - Dinamik Submit: Words 1 ise ilk kelimede, 2 ise ikinci kelimede otomatik tıklar.
    - Tema: Mavi / [F] Tuşu Aktif
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

--// AYARLAR //--
local _enabled = false
local _targetWords = 1 -- Varsayılan 1 yapıldı (İstediğin gibi 1se 1, 2se 2 çalışır)
local _currentWords = 0
local _collectedWords = {}
local _seen = {}
local ANTHROPIC_KEY = "sk-ant-api03-placeholder-replace-with-real-key" 

--// BLACKLIST //--
local BLACKLIST_PHRASES = {
    "setcreatorid", "refreshesin", "restockingin", "freespinin", 
    "font", "ago", "left", "wait", "stock", "timer", "remaining", "update"
}

local function isBlacklisted(txt)
    local l = txt:lower():gsub("%s+", "")
    -- Zaman desenleri engeli (38m2s, 1h vb.)
    if l:match("%d+h") or l:match("%d+m") or l:match("%d+s") or l:match("%d+f") then return true end
    -- Kelime engeli
    for _, word in ipairs(BLACKLIST_PHRASES) do if l:find(word) then return true end end
    return false
end

--// AI RIDDLE MANTIĞI //--
local RIDDLE_KW = {"when was","how old","what year","what month","birthday","age of","released","hint","riddle","guess"}

local function isRiddle(txt)
    local l = txt:lower()
    for _, p in ipairs(RIDDLE_KW) do if l:find(p, 1, true) then return true end end
    return false
end

local function callAI(prompt)
    if not ANTHROPIC_KEY or ANTHROPIC_KEY == "" or ANTHROPIC_KEY:find("placeholder") then return nil end
    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model = "claude-3-sonnet-20240229",
            max_tokens = 40,
            system = "Decode Roblox promo codes. Output ONLY the code uppercase.",
            messages = {{role = "user", content = prompt}}
        })
        local resp = HttpService:RequestAsync({
            Url = "https://api.anthropic.com/v1/messages",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["x-api-key"] = ANTHROPIC_KEY, ["anthropic-version"] = "2023-06-01"},
            Body = body
        })
        return HttpService:JSONDecode(resp.Body).content[1].text
    end)
    return (ok and result) and tostring(result):match("^%s*([A-Z0-9*%-]+)%s*$") or nil
end

--// UI TASARIMI (MAVİ) //--
local GUI = Instance.new("ScreenGui")
GUI.Name = "MoonHubV10"; GUI.ResetOnSpawn = false
if gethui then GUI.Parent = gethui() else GUI.Parent = game.CoreGui end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 310); Main.Position = UDim2.new(0.5, -120, 0.4, -155)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15); Main.BorderSizePixel = 0
Main.Active = true; Main.Draggable = true; Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 160, 255)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45); Title.BackgroundTransparency = 1
Title.Text = "Moon Hub [F]"; Title.TextColor3 = Color3.fromRGB(0, 180, 255)
Title.TextSize = 18; Title.Font = Enum.Font.FredokaOne; Title.Parent = Main

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 110, 0, 40); StartBtn.Position = UDim2.new(0.5, -55, 0, 50)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30); StartBtn.Text = "start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255); StartBtn.TextSize = 22; StartBtn.Font = Enum.Font.FredokaOne; StartBtn.Parent = Main
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", StartBtn).Color = Color3.fromRGB(0, 160, 255)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20); StatusLbl.Position = UDim2.new(0, 0, 0, 95)
StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "disabled"; StatusLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
StatusLbl.TextSize = 14; StatusLbl.Font = Enum.Font.FredokaOne; StatusLbl.Parent = Main

local CounterLbl = Instance.new("TextLabel")
CounterLbl.Size = UDim2.new(1, 0, 0, 30); CounterLbl.Position = UDim2.new(0, 0, 0, 115)
CounterLbl.BackgroundTransparency = 1; CounterLbl.Text = "0/1"; CounterLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
CounterLbl.TextSize = 22; CounterLbl.Font = Enum.Font.FredokaOne; CounterLbl.Parent = Main

local CapturedFrame = Instance.new("Frame")
CapturedFrame.Size = UDim2.new(1, -30, 0, 60); CapturedFrame.Position = UDim2.new(0, 15, 0, 230)
CapturedFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10); CapturedFrame.Parent = Main
Instance.new("UICorner", CapturedFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", CapturedFrame).Color = Color3.fromRGB(0, 100, 200)

local CapturedTxt = Instance.new("TextLabel")
CapturedTxt.Size = UDim2.new(1, -10, 1, -10); CapturedTxt.Position = UDim2.new(0, 5, 0, 5)
CapturedTxt.BackgroundTransparency = 1; CapturedTxt.Text = "Waiting for capture..."; CapturedTxt.TextColor3 = Color3.fromRGB(0, 180, 255)
CapturedTxt.TextSize = 11; CapturedTxt.Font = Enum.Font.SourceSansBold; CapturedTxt.TextWrapped = true; CapturedTxt.Parent = CapturedFrame

-- Words +/- Kontrolü
local function makeAdj(name, y)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -40, 0, 40); f.Position = UDim2.new(0, 20, 0, y); f.BackgroundTransparency = 1; f.Parent = Main
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0, 60, 1, 0); l.BackgroundTransparency = 1; l.Text = name..":"; l.TextColor3 = Color3.fromRGB(150, 150, 150); l.TextSize = 16; l.Font = Enum.Font.FredokaOne; l.Parent = f
    local v = Instance.new("TextLabel"); v.Size = UDim2.new(0, 40, 1, 0); v.Position = UDim2.new(0.5, -20, 0, 0); v.BackgroundTransparency = 1; v.Text = tostring(_targetWords); v.TextColor3 = Color3.fromRGB(0, 180, 255); v.TextSize = 18; v.Font = Enum.Font.FredokaOne; v.Parent = f
    local m = Instance.new("TextButton"); m.Size = UDim2.new(0, 25, 0, 25); m.Position = UDim2.new(0.25, 0, 0.2, 0); m.BackgroundColor3 = Color3.fromRGB(30, 30, 40); m.Text = "-"; m.TextColor3 = Color3.fromRGB(255, 255, 255); m.Parent = f; Instance.new("UICorner", m)
    local p = Instance.new("TextButton"); p.Size = UDim2.new(0, 25, 0, 25); p.Position = UDim2.new(0.75, -5, 0.2, 0); p.BackgroundColor3 = Color3.fromRGB(30, 30, 40); p.Text = "+"; p.TextColor3 = Color3.fromRGB(255, 255, 255); p.Parent = f; Instance.new("UICorner", p)
    return v, m, p
end
local wordVal, mBtn, pBtn = makeAdj("words", 160)

--// SİSTEM FONKSİYONLARI //--

local function updateUI() 
    CounterLbl.Text = _currentWords.."/".._targetWords 
    CapturedTxt.Text = #_collectedWords > 0 and table.concat(_collectedWords, " - ") or "Waiting for capture..."
end

local function submitCode(code)
    local box = nil
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and (v.Name:lower():find("code") or v.PlaceholderText:lower():find("code")) then box = v; break end
    end
    if box then
        box.Text = code
        task.wait(0.1)
        for _, b in ipairs(box.Parent:GetChildren()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                local t = (b:IsA("TextButton") and b.Text:lower() or b.Name:lower())
                if t:find("redeem") or t:find("claim") or t:find("submit") or t:find("enter") then
                    pcall(function()
                        for _, con in ipairs(getconnections(b.MouseButton1Click)) do con:Fire() end
                        for _, con in ipairs(getconnections(b.Activated)) do con:Fire() end
                    end)
                    break
                end
            end
        end
    end
    _currentWords = 0; _collectedWords = {}; updateUI()
end

local function processText(txt)
    if not _enabled or #txt < 2 or _seen[txt] or isBlacklisted(txt) then return end
    _seen[txt] = true; task.delay(10, function() _seen[txt] = nil end)

    -- Bilmece Çözücü AI
    if isRiddle(txt) then
        task.spawn(function()
            StatusLbl.Text = "solving riddle..."; local res = callAI(txt)
            if res then submitCode(res) end
            StatusLbl.Text = "enabled"
        end)
        return
    end

    -- Kod Toplama Mantığı (Strict: 1se 1, 2se 2)
    local clean = txt:gsub("[^A-Za-z0-9]", "")
    if #clean >= 2 then
        table.insert(_collectedWords, clean)
        _currentWords = _currentWords + 1
        updateUI()
        if _currentWords >= _targetWords then
            submitCode(table.concat(_collectedWords, ""))
        end
    end
end

--// ETKİLEŞİMLER //--
local function toggle()
    _enabled = not _enabled
    StartBtn.Text = _enabled and "stop" or "start"
    StatusLbl.Text = _enabled and "enabled" or "disabled"
    StatusLbl.TextColor3 = _enabled and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(255, 60, 60)
    if not _enabled then _collectedWords = {}; _currentWords = 0; updateUI() end
end

StartBtn.MouseButton1Click:Connect(toggle)
pBtn.MouseButton1Click:Connect(function() _targetWords = _targetWords + 1; wordVal.Text = _targetWords; updateUI() end)
mBtn.MouseButton1Click:Connect(function() if _targetWords > 1 then _targetWords = _targetWords - 1; wordVal.Text = _targetWords; updateUI() end end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.F then toggle() end end)

-- DUYURU VE CHAT TAKİBİ
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

print("Moon Hub V10 Loaded - Blacklist: setcreatorid active!")
