local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

--// AYARLAR //--
local _enabled = false
local _targetWords = 3
local _currentWords = 0
local _delayMs = 0
local _collectedWords = {}
local _seen = {}

--// KARA LİSTE (BLACKLIST) //--
local BLACKLIST_WORDS = {"refreshes", "restocking", "ago", "in", "left", "seconds", "minutes", "wait", "stock", "next", "timer"}

local function isBlacklisted(txt)
    local l = txt:lower()
    -- Zaman desenlerini yakala: "38m2s", "8m1s", "30s", "10m"
    if l:match("%d+m%d+s") or l:match("%d+s") or l:match("%d+m") or l:match("%d+h") then
        return true
    end
    -- Yasaklı kelimeleri kontrol et
    for _, word in ipairs(BLACKLIST_WORDS) do
        if l:find(word) then return true end
    end
    return false
end

--// UI TASARIMI //--
local GUI = Instance.new("ScreenGui")
GUI.Name = "TokinuRedeemerV3"
GUI.IgnoreGuiInset = true
GUI.ResetOnSpawn = false
if gethui then GUI.Parent = gethui() else GUI.Parent = game.CoreGui end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 270)
Main.Position = UDim2.new(0.5, -120, 0.4, -135)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "tokinu el code redeemer [F]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.FredokaOne
Title.Parent = Main

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 110, 0, 40)
StartBtn.Position = UDim2.new(0.5, -55, 0, 50)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StartBtn.Text = "start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 22
StartBtn.Font = Enum.Font.FredokaOne
StartBtn.AutoButtonColor = false
StartBtn.Parent = Main
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0, 95)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "disabled"
StatusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
StatusLbl.TextSize = 13
StatusLbl.Font = Enum.Font.FredokaOne
StatusLbl.Parent = Main

local CounterLbl = Instance.new("TextLabel")
CounterLbl.Size = UDim2.new(1, 0, 0, 30)
CounterLbl.Position = UDim2.new(0, 0, 0, 115)
CounterLbl.BackgroundTransparency = 1
CounterLbl.Text = "0/3"
CounterLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
CounterLbl.TextSize = 20
CounterLbl.Font = Enum.Font.FredokaOne
CounterLbl.Parent = Main

-- Ayar Yapıcı Fonksiyon
local function makeSetting(name, y, val, suffix)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -30, 0, 40)
    f.Position = UDim2.new(0, 15, 0, y)
    f.BackgroundTransparency = 1
    f.Parent = Main

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 60, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = name .. ":"
    l.TextColor3 = Color3.fromRGB(180, 180, 180)
    l.TextSize = 16; l.Font = Enum.Font.FredokaOne; l.TextXAlignment = 0; l.Parent = f

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0, 50, 1, 0)
    v.Position = UDim2.new(0.5, -25, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = tostring(val) .. (suffix or "")
    v.TextColor3 = Color3.fromRGB(255, 255, 255)
    v.TextSize = 18; v.Font = Enum.Font.FredokaOne; v.Parent = f

    local btnM = Instance.new("TextButton")
    btnM.Size = UDim2.new(0, 25, 0, 25); btnM.Position = UDim2.new(0.3, 0, 0.2, 0)
    btnM.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btnM.Text = "-"; btnM.TextColor3 = Color3.fromRGB(255,255,255)
    btnM.Parent = f; Instance.new("UICorner", btnM)

    local btnP = Instance.new("TextButton")
    btnP.Size = UDim2.new(0, 25, 0, 25); btnP.Position = UDim2.new(0.7, 5, 0.2, 0)
    btnP.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btnP.Text = "+"; btnP.TextColor3 = Color3.fromRGB(255,255,255)
    btnP.Parent = f; Instance.new("UICorner", btnP)

    return v, btnM, btnP
end

local wordVal, wordM, wordP = makeSetting("words", 160, 3)
local delayVal, delayM, delayP = makeSetting("delay", 205, 0, "ms")

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 20)
Footer.Position = UDim2.new(0, 0, 1, -25)
Footer.BackgroundTransparency = 1
Footer.Text = "discord.gg/tokinu"
Footer.TextColor3 = Color3.fromRGB(80, 80, 80)
Footer.TextSize = 11; Footer.Parent = Main

--// SİSTEM FONKSİYONLARI //--

local function updateCounter()
    CounterLbl.Text = _currentWords .. "/" .. _targetWords
end

local function toggle()
    _enabled = not _enabled
    if _enabled then
        StartBtn.Text = "stop"
        StatusLbl.Text = "enabled"
        StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        StartBtn.Text = "start"
        StatusLbl.Text = "disabled"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
        _currentWords = 0
        _collectedWords = {}
        updateCounter()
    end
end

-- Buton Etkileşimleri
wordP.MouseButton1Click:Connect(function() _targetWords = _targetWords + 1; wordVal.Text = _targetWords; updateCounter() end)
wordM.MouseButton1Click:Connect(function() if _targetWords > 1 then _targetWords = _targetWords - 1; wordVal.Text = _targetWords; updateCounter() end end)
delayP.MouseButton1Click:Connect(function() _delayMs = _delayMs + 50; delayVal.Text = _delayMs .. "ms" end)
delayM.MouseButton1Click:Connect(function() if _delayMs > 0 then _delayMs = _delayMs - 50; delayVal.Text = _delayMs .. "ms" end end)
StartBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(io, g) if not g and io.KeyCode == Enum.KeyCode.F then toggle() end end)

-- Otomatik Gönderme (Redeem)
local function autoRedeem(fullCode)
    task.wait(_delayMs / 1000)
    local box = nil
    -- Kodu yazacak kutuyu bul
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and (v.Name:lower():find("code") or v.PlaceholderText:lower():find("code")) then
            box = v; break
        end
    end

    if box then
        box.Text = fullCode
        task.wait(0.1)
        -- Butonu bul ve tıkla
        local parent = box.Parent
        for _, b in ipairs(parent:GetChildren()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                local t = (b:IsA("TextButton") and b.Text:lower() or b.Name:lower())
                if t:find("redeem") or t:find("claim") or t:find("enter") or t:find("submit") then
                    pcall(function()
                        for _, con in ipairs(getconnections(b.MouseButton1Click)) do con:Fire() end
                        for _, con in ipairs(getconnections(b.Activated)) do con:Fire() end
                    end)
                    break
                end
            end
        end
    end
    _currentWords = 0; _collectedWords = {}; updateCounter()
end

local function processText(txt)
    if not _enabled or #txt < 2 or _seen[txt] then return end
    if isBlacklisted(txt) then return end

    local clean = txt:gsub("[^A-Za-z0-9]", "")
    if #clean < 2 then return end

    _seen[txt] = true
    task.delay(8, function() _seen[txt] = nil end)

    table.insert(_collectedWords, clean)
    _currentWords = _currentWords + 1
    updateCounter()

    if _currentWords >= _targetWords then
        local code = table.concat(_collectedWords, "")
        autoRedeem(code)
    end
end

-- Dinleyicileri Başlat
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

print("Tokinu El Code Redeemer V3 Loaded! [F] to Toggle")
