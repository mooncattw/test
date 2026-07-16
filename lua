local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

--// AYARLAR //--
local _enabled = false
local _targetWords = 3
local _currentWords = 0
local _delayMs = 0
local _collectedWords = {}
local _seen = {}

--// GUI OLUŞTURMA //--
local GUI = Instance.new("ScreenGui")
GUI.Name = "TokinuRedeemer"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then GUI.Parent = gethui() else GUI.Parent = game.CoreGui end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 280)
Main.Position = UDim2.new(0.5, -130, 0.4, -140)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "tokinu el code redeemer [F]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.FredokaOne
Title.Parent = Main

local StartBtn = Instance.new("TextButton")
StartBtn.Name = "StartBtn"
StartBtn.Size = UDim2.new(0, 120, 0, 45)
StartBtn.Position = UDim2.new(0.5, -60, 0, 50)
StartBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StartBtn.Text = "start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 22
StartBtn.Font = Enum.Font.FredokaOne
StartBtn.AutoButtonColor = false
StartBtn.Parent = Main
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 10)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 25)
StatusLbl.Position = UDim2.new(0, 0, 0, 100)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "disabled"
StatusLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
StatusLbl.TextSize = 14
StatusLbl.Font = Enum.Font.FredokaOne
StatusLbl.Parent = Main

local CounterLbl = Instance.new("TextLabel")
CounterLbl.Size = UDim2.new(1, 0, 0, 25)
CounterLbl.Position = UDim2.new(0, 0, 0, 125)
CounterLbl.BackgroundTransparency = 1
CounterLbl.Text = "0/3"
CounterLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
CounterLbl.TextSize = 18
CounterLbl.Font = Enum.Font.FredokaOne
CounterLbl.Parent = Main

-- Ayar Satırları Fonksiyonu
local function createSetting(name, yPos, defaultVal, suffix)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -40, 0, 40)
    frame.Position = UDim2.new(0, 20, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = Main

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 70, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ":"
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.FredokaOne
    lbl.Parent = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 1, 0)
    valLbl.Position = UDim2.new(0.5, -30, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(defaultVal) .. (suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLbl.TextSize = 18
    valLbl.Font = Enum.Font.FredokaOne
    valLbl.Parent = frame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 30, 0, 30)
    minus.Position = UDim2.new(0.3, 0, 0.1, 0)
    minus.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.Parent = frame
    Instance.new("UICorner", minus)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 30, 0, 30)
    plus.Position = UDim2.new(0.7, 0, 0.1, 0)
    plus.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.Parent = frame
    Instance.new("UICorner", plus)

    return valLbl, minus, plus
end

local wordVal, wordMinus, wordPlus = createSetting("words", 160, 3)
local delayVal, delayMinus, delayPlus = createSetting("delay", 210, 0, "ms")

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 20)
Footer.Position = UDim2.new(0, 0, 1, -25)
Footer.BackgroundTransparency = 1
Footer.Text = "discord.gg/tokinu"
Footer.TextColor3 = Color3.fromRGB(100, 100, 100)
Footer.TextSize = 12
Footer.Font = Enum.Font.SourceSans
Footer.Parent = Main

--// MANTIK VE ETKİLEŞİM //--

local function updateCounter()
    CounterLbl.Text = _currentWords .. "/" .. _targetWords
end

wordPlus.MouseButton1Click:Connect(function()
    _targetWords = _targetWords + 1
    wordVal.Text = tostring(_targetWords)
    updateCounter()
end)

wordMinus.MouseButton1Click:Connect(function()
    if _targetWords > 1 then
        _targetWords = _targetWords - 1
        wordVal.Text = tostring(_targetWords)
        updateCounter()
    end
end)

delayPlus.MouseButton1Click:Connect(function()
    _delayMs = _delayMs + 50
    delayVal.Text = _delayMs .. "ms"
end)

delayMinus.MouseButton1Click:Connect(function()
    if _delayMs > 0 then
        _delayMs = _delayMs - 50
        delayVal.Text = _delayMs .. "ms"
    end
end)

StartBtn.MouseButton1Click:Connect(function()
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
end)

-- Otomatik Buton Tıklama Fonksiyonu
local function autoRedeem(fullCode)
    task.wait(_delayMs / 1000)
    
    local codeBox = nil
    local redeemBtn = nil

    -- Yaygın TextBox ve Buton isimlerini arar
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextBox") and v.Visible and (v.Name:lower():find("code") or v.PlaceholderText:lower():find("code")) then
            codeBox = v
        end
    end

    if codeBox then
        codeBox.Text = fullCode
        -- Kod girildikten sonra yanındaki butonu bulmaya çalış
        local p = codeBox.Parent
        for _, b in ipairs(p:GetChildren()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                local txt = (b:IsA("TextButton") and b.Text:lower() or b.Name:lower())
                if txt:find("redeem") or txt:find("claim") or txt:find("enter") or txt:find("submit") then
                    redeemBtn = b
                    break
                end
            end
        end
        
        if redeemBtn then
            -- Butona tıkla
            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
            for _, event in ipairs(events) do
                if redeemBtn[event] then
                    for _, connection in ipairs(getconnections(redeemBtn[event])) do
                        connection:Fire()
                    end
                end
            end
            print("Kod Gönderildi: " .. fullCode)
        end
    end
    
    -- Sıfırla
    _currentWords = 0
    _collectedWords = {}
    updateCounter()
end

local function processText(txt)
    if not _enabled or #txt < 2 or _seen[txt] then return end
    
    -- Sadece harf ve sayı içeren kelimeleri ayıkla
    local clean = txt:gsub("[^A-Za-z0-9]", "")
    if #clean < 2 then return end

    _seen[txt] = true
    task.delay(10, function() _seen[txt] = nil end)

    table.insert(_collectedWords, clean)
    _currentWords = _currentWords + 1
    updateCounter()

    if _currentWords >= _targetWords then
        local fullCode = table.concat(_collectedWords, "")
        autoRedeem(fullCode)
    end
end

-- Ekranı Dinle
playerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") then
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            processText(obj.Text)
        end)
        processText(obj.Text)
    end
end)

for _, v in ipairs(playerGui:GetDescendants()) do
    if v:IsA("TextLabel") then
        v:GetPropertyChangedSignal("Text"):Connect(function()
            processText(v.Text)
        end)
    end
end

-- Chat'i Dinle
pcall(function()
    local tcs = game:GetService("TextChatService")
    if tcs and tcs.MessageReceived then
        tcs.MessageReceived:Connect(function(msg)
            processText(msg.Text)
        end)
    end
end)

print("Tokinu Code Redeemer Loaded!")
