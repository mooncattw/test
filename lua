--[[
    MOON HUB - CODE REDEEMER
    Özellikler:
    - Renk: Mavi (Blue)
    - Başlık: Moon Hub [F]
    - Gelişmiş Blacklist: Sayaçlar (m, s, h, f), restocking, refreshes, font vb. engellendi.
    - Sadece Yazma: Kodu bulur ve yazar, butona basmaz.
    - Ayar: ms/delay kaldırıldı.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

--// AYARLAR //--
local _enabled = false
local _targetWords = 3
local _currentWords = 0
local _collectedWords = {}
local _seen = {}

--// GELİŞMİŞ KARA LİSTE (BLACKLIST) //--
local BLACKLIST_PHRASES = {
    "refreshesin", "restockingin", "freespinin", "font", "hub", "ago", 
    "left", "wait", "stock", "next", "timer", "remaining"
}

local function isBlacklisted(txt)
    local l = txt:lower():gsub("%s+", "") -- Boşlukları silip küçük harfe çevir
    
    -- Zaman/Sayı desenlerini yakala (38m2s, 30s, 1h, 200f, 5m16s vb.)
    if l:match("%d+h") or l:match("%d+m") or l:match("%d+s") or l:match("%d+f") then
        return true
    end
    
    -- Kelime bazlı kontrol
    for _, word in ipairs(BLACKLIST_PHRASES) do
        if l:find(word) then return true end
    end
    
    return false
end

--// UI TASARIMI (MAVİ TEMA) //--
local GUI = Instance.new("ScreenGui")
GUI.Name = "MoonHubRedeemer"
GUI.IgnoreGuiInset = true
GUI.ResetOnSpawn = false
if gethui then GUI.Parent = gethui() else GUI.Parent = game.CoreGui end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 220) -- ms kalktığı için boyutu küçültüldü
Main.Position = UDim2.new(0.5, -120, 0.4, -110)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Mavi Kenarlık (Görsellik için)
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 170, 255)
Stroke.Thickness = 1.5
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "Moon Hub [F]"
Title.TextColor3 = Color3.fromRGB(0, 170, 255) -- MAVİ
Title.TextSize = 18
Title.Font = Enum.Font.FredokaOne
Title.Parent = Main

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 110, 0, 40)
StartBtn.Position = UDim2.new(0.5, -55, 0, 50)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
StartBtn.Text = "start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 22
StartBtn.Font = Enum.Font.FredokaOne
StartBtn.AutoButtonColor = false
StartBtn.Parent = Main
local btnCorner = Instance.new("UICorner", StartBtn)
btnCorner.CornerRadius = UDim.new(0, 8)
local btnStroke = Instance.new("UIStroke", StartBtn)
btnStroke.Color = Color3.fromRGB(0, 170, 255)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0, 95)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "disabled"
StatusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
StatusLbl.TextSize = 14
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

-- Words Ayarı
local wordFrame = Instance.new("Frame")
wordFrame.Size = UDim2.new(1, -30, 0, 40)
wordFrame.Position = UDim2.new(0, 15, 0, 155)
wordFrame.BackgroundTransparency = 1
wordFrame.Parent = Main

local wordText = Instance.new("TextLabel")
wordText.Size = UDim2.new(0, 70, 1, 0)
wordText.BackgroundTransparency = 1
wordText.Text = "words:"
wordText.TextColor3 = Color3.fromRGB(180, 180, 180)
wordText.TextSize = 16; wordText.Font = Enum.Font.FredokaOne; wordText.TextXAlignment = 0; wordText.Parent = wordFrame

local wordVal = Instance.new("TextLabel")
wordVal.Size = UDim2.new(0, 50, 1, 0)
wordVal.Position = UDim2.new(0.5, -25, 0, 0)
wordVal.BackgroundTransparency = 1
wordVal.Text = tostring(_targetWords)
wordVal.TextColor3 = Color3.fromRGB(0, 170, 255)
wordVal.TextSize = 18; wordVal.Font = Enum.Font.FredokaOne; wordVal.Parent = wordFrame

local btnM = Instance.new("TextButton")
btnM.Size = UDim2.new(0, 25, 0, 25); btnM.Position = UDim2.new(0.3, 0, 0.2, 0)
btnM.BackgroundColor3 = Color3.fromRGB(30, 30, 35); btnM.Text = "-"; btnM.TextColor3 = Color3.fromRGB(255,255,255)
btnM.Parent = wordFrame; Instance.new("UICorner", btnM)

local btnP = Instance.new("TextButton")
btnP.Size = UDim2.new(0, 25, 0, 25); btnP.Position = UDim2.new(0.7, 5, 0.2, 0)
btnP.BackgroundColor3 = Color3.fromRGB(30, 30, 35); btnP.Text = "+"; btnP.TextColor3 = Color3.fromRGB(255,255,255)
btnP.Parent = wordFrame; Instance.new("UICorner", btnP)

--// SİSTEM FONKSİYONLARI //--

local function updateCounter()
    CounterLbl.Text = _currentWords .. "/" .. _targetWords
end

local function toggle()
    _enabled = not _enabled
    if _enabled then
        StartBtn.Text = "stop"
        StatusLbl.Text = "enabled"
        StatusLbl.TextColor3 = Color3.fromRGB(0, 170, 255)
    else
        StartBtn.Text = "start"
        StatusLbl.Text = "disabled"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
        _currentWords = 0
        _collectedWords = {}
        updateCounter()
    end
end

btnP.MouseButton1Click:Connect(function() _targetWords = _targetWords + 1; wordVal.Text = _targetWords; updateCounter() end)
btnM.MouseButton1Click:Connect(function() if _targetWords > 1 then _targetWords = _targetWords - 1; wordVal.Text = _targetWords; updateCounter() end end)
StartBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(io, g) if not g and io.KeyCode == Enum.KeyCode.F then toggle() end end)

-- Kodu Sadece Yazma (Tıklama Yapmaz)
local function typeOnly(fullCode)
    local box = nil
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and (v.Name:lower():find("code") or v.PlaceholderText:lower():find("code")) then
            box = v; break
        end
    end
    if box then
        box.Text = fullCode
    end
    -- Sıfırla
    _currentWords = 0; _collectedWords = {}; updateCounter()
end

local function processText(txt)
    if not _enabled or #txt < 2 or _seen[txt] then return end
    
    -- Belirttiğin tüm filtreler burada çalışır
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
        typeOnly(code)
    end
end

-- Dinleyiciler
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

print("Moon Hub Loaded! Color: Blue | Blacklist: Active")
