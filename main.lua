-- ==============================================================================
-- PROJE: NACHO CHILLI FINDER (ÖZEL SCREEN-GUI SÜRÜMÜ - SIFIR RAYFIELD)
-- DESTEK: Mobil (Telefon) & PC | %100 Akıcı ve Bağımsız
-- ==============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- Eski arayüz varsa temizle
if game:GetService("CoreGui"):FindFirstChild("NachoChilliStandalone") then
    game:GetService("CoreGui").NachoChilliStandalone:Destroy()
end

-- ANA SCREEN-GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NachoChilliStandalone"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

-- AYARLAR VE DURUMLAR
local Settings = {
    AutoHunt = false,
    MinHuntValue = 50e6, -- 50M/s alt limit
    AutoSteal = false,
    AntiAFK = true,
    SpeedBoost = false
}

-- ANTI-AFK SİSTEMİ
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==============================================================================
-- 1. SOL MENÜ "FINDER" BUTONU
-- ==============================================================================
local LeftSidebarBtn = Instance.new("TextButton")
LeftSidebarBtn.Name = "FinderSidebarBtn"
LeftSidebarBtn.Size = UDim2.new(0, 105, 0, 42)
LeftSidebarBtn.Position = UDim2.new(0, 10, 0.38, 0)
LeftSidebarBtn.BackgroundColor3 = Color3.fromRGB(245, 175, 25)
LeftSidebarBtn.BorderSizePixel = 3
LeftSidebarBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
LeftSidebarBtn.Font = Enum.Font.FredokaOne
LeftSidebarBtn.Text = "🦌 Finder"
LeftSidebarBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
LeftSidebarBtn.TextSize = 19
LeftSidebarBtn.Parent = ScreenGui

local UICornerSidebar = Instance.new("UICorner")
UICornerSidebar.CornerRadius = UDim.new(0, 8)
UICornerSidebar.Parent = LeftSidebarBtn

-- ==============================================================================
-- 2. ANA CHILLI FINDER PANELİ (FOTOĞRAFTAKİ BİREBİR TASARIM)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 490)
MainFrame.Position = UDim2.new(0.65, 0, 0.20, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 36, 42)
MainFrame.BorderSizePixel = 4
MainFrame.BorderColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.Active = true
MainFrame.Draggable = true -- Hem mobilde hem PC'de sürüklenebilir!
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- BAŞLIK ÇUBUĞU (Turuncu Chilli Başlığı)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(240, 90, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0, 190, 1, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.FredokaOne
HeaderTitle.Text = "Chilli Finder"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.TextSize = 25
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

-- AUTO OFF / ON BUTONU
local AutoHuntBtn = Instance.new("TextButton")
AutoHuntBtn.Size = UDim2.new(0, 95, 0, 32)
AutoHuntBtn.Position = UDim2.new(1, -105, 0, 9)
AutoHuntBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
AutoHuntBtn.BorderSizePixel = 2
AutoHuntBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
AutoHuntBtn.Font = Enum.Font.FredokaOne
AutoHuntBtn.Text = "AUTO OFF"
AutoHuntBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHuntBtn.TextSize = 13
AutoHuntBtn.Parent = Header

local AutoHuntCorner = Instance.new("UICorner")
AutoHuntCorner.CornerRadius = UDim.new(0, 6)
AutoHuntCorner.Parent = AutoHuntBtn

-- 4 ADET HAP BUTON (FORCE JOIN, MIN VALUE, RARITY, HOP)
local PillContainer = Instance.new("Frame")
PillContainer.Size = UDim2.new(1, -20, 0, 44)
PillContainer.Position = UDim2.new(0, 10, 0, 58)
PillContainer.BackgroundTransparency = 1
PillContainer.Parent = MainFrame

local function CreatePill(text, sub, col, posX)
    local p = Instance.new("TextButton")
    p.Size = UDim2.new(0, 80, 1, 0)
    p.Position = UDim2.new(0, posX, 0, 0)
    p.BackgroundColor3 = col
    p.BorderSizePixel = 2
    p.BorderColor3 = Color3.fromRGB(0, 0, 0)
    p.Font = Enum.Font.FredokaOne
    p.Text = text .. "\n" .. sub
    p.TextColor3 = Color3.fromRGB(0, 0, 0)
    p.TextSize = 11
    p.Parent = PillContainer
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = p
    return p
end

local ForcePill = CreatePill("FORCE JOIN", "30s", Color3.fromRGB(130, 245, 130), 0)
local MinPill = CreatePill("MIN VALUE", "50M/s", Color3.fromRGB(120, 215, 255), 87)
local RarityPill = CreatePill("RARITY", "Divine", Color3.fromRGB(160, 210, 255), 174)
local HopPill = CreatePill("SERVER", "Hop", Color3.fromRGB(255, 210, 75), 260)

-- LİSTE BAŞLIĞI
local SubHeader = Instance.new("TextLabel")
SubHeader.Size = UDim2.new(1, -20, 0, 22)
SubHeader.Position = UDim2.new(0, 10, 0, 108)
SubHeader.BackgroundTransparency = 1
SubHeader.Font = Enum.Font.FredokaOne
SubHeader.Text = "Canlı Harita Yumurtaları | Tap STEAL"
SubHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
SubHeader.TextSize = 13
SubHeader.Parent = MainFrame

-- YUMURTA KARTLARI LİSTESİ (SCROLL FRAME)
local CardList = Instance.new("ScrollingFrame")
CardList.Size = UDim2.new(1, -20, 0, 310)
CardList.Position = UDim2.new(0, 10, 0, 134)
CardList.BackgroundTransparency = 1
CardList.BorderSizePixel = 0
CardList.ScrollBarThickness = 5
CardList.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = CardList

-- ==============================================================================
-- 3. GERÇEK HARİTA TARAMA VE ÇALMA MOTORU
-- ==============================================================================
local function ScanCurrentServerRealEggs()
    local detected = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local billboard = obj:FindFirstChildWhichIsA("BillboardGui", true)
            if billboard then
                local eggName, eggRate, eggMult, eggTag = nil, nil, nil, ""
                
                for _, lbl in ipairs(billboard:GetDescendants()) do
                    if lbl:IsA("TextLabel") then
                        local txt = lbl.Text
                        if string.find(txt, "%$") and string.find(txt, "/s") then
                            eggRate = txt
                        elseif string.find(txt, "^x%d") or string.find(txt, "x%d+%.%d+") then
                            eggMult = txt
                        elseif string.find(string.lower(txt), "halloween") or string.find(string.lower(txt), "rainbow") or string.find(string.lower(txt), "golden") or string.find(string.lower(txt), "divine") then
                            eggTag = txt
                        elseif #txt > 2 and not string.find(txt, "%$") and not string.find(txt, "x") and not string.find(txt, "Hold") then
                            eggName = txt
                        end
                    end
                end
                
                if eggRate or eggName then
                    local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if root then
                        local cleanNum = tonumber(string.match(eggRate or "0", "[%d%.]+")) or 0
                        if string.find(eggRate or "", "B") then cleanNum = cleanNum * 1e9
                        elseif string.find(eggRate or "", "M") then cleanNum = cleanNum * 1e6
                        elseif string.find(eggRate or "", "T") then cleanNum = cleanNum * 1e12 end
                        
                        table.insert(detected, {
                            Instance = root,
                            Name = eggName or obj.Name,
                            Rate = eggRate or "$0/s",
                            Mult = eggMult or "x1.0",
                            Tag = eggTag,
                            Numeric = cleanNum
                        })
                    end
                end
            end
        end
    end
    
    table.sort(detected, function(a, b) return a.Numeric > b.Numeric end)
    return detected
end

-- IŞINLANIP ÇALMA
local function StealEgg(part)
    if not part then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.12)
        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true) or part.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end
end

-- SUNUCU DEĞİŞTİRME (SERVER HOP)
local function HopServer()
    local queue = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if queue then
        queue([[
            task.wait(2)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bbilibili773-eng/adada/main/main.lua"))()
        ]])
    end
    
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", PlaceId)
    local s, res = pcall(function() return game:HttpGet(url) end)
    if s and res then
        local decSuccess, data = pcall(function() return HttpService:JSONDecode(res) end)
        if decSuccess and data and data.data then
            local available = {}
            for _, srv in ipairs(data.data) do
                if srv.id ~= CurrentJobId and srv.playing < srv.maxPlayers then
                    table.insert(available, srv.id)
                end
            end
            if #available > 0 then
                TeleportService:TeleportToPlaceInstance(PlaceId, available[math.random(1, #available)], LocalPlayer)
                return
            end
        end
    end
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

-- KARTLARI ÇİZEN FONKSİYON
local function RenderCards()
    for _, child in ipairs(CardList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local realEggs = ScanCurrentServerRealEggs()
    
    if #realEggs == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 45)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Font = Enum.Font.FredokaOne
        emptyLbl.Text = "Haritada aktif yumurta taranıyor..."
        emptyLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        emptyLbl.TextSize = 14
        emptyLbl.Parent = CardList
        return
    end
    
    for i = 1, math.min(6, #realEggs) do
        local data = realEggs[i]
        
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 52)
        Card.BackgroundColor3 = Color3.fromRGB(48, 50, 56)
        Card.BorderSizePixel = 2
        Card.BorderColor3 = Color3.fromRGB(20, 20, 25)
        Card.Parent = CardList
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 6)
        CardCorner.Parent = Card
        
        local IconBox = Instance.new("TextLabel")
        IconBox.Size = UDim2.new(0, 42, 1, 0)
        IconBox.BackgroundColor3 = Color3.fromRGB(65, 68, 76)
        IconBox.Text = "🎃"
        IconBox.TextSize = 22
        IconBox.Parent = Card
        
        if data.Tag ~= "" then
            local TagBadge = Instance.new("TextLabel")
            TagBadge.Size = UDim2.new(0, 42, 0, 13)
            TagBadge.Position = UDim2.new(0, 0, 1, -13)
            TagBadge.BackgroundColor3 = Color3.fromRGB(240, 140, 20)
            TagBadge.Font = Enum.Font.FredokaOne
            TagBadge.Text = data.Tag
            TagBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            TagBadge.TextSize = 8
            TagBadge.Parent = Card
        end
        
        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(0, 190, 0, 20)
        TitleLbl.Position = UDim2.new(0, 48, 0, 5)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.FredokaOne
        TitleLbl.Text = data.Name
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextSize = 15
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Parent = Card
        
        local StatsLbl = Instance.new("TextLabel")
        StatsLbl.Size = UDim2.new(0, 190, 0, 18)
        StatsLbl.Position = UDim2.new(0, 48, 0, 26)
        StatsLbl.BackgroundTransparency = 1
        StatsLbl.Font = Enum.Font.FredokaOne
        StatsLbl.Text = string.format("<font color='#32CD32'>%s</font>  <font color='#FFA500'>%s</font>", data.Rate, data.Mult)
        StatsLbl.RichText = true
        StatsLbl.TextSize = 12
        StatsLbl.TextXAlignment = Enum.TextXAlignment.Left
        StatsLbl.Parent = Card
        
        -- YEŞİL STEAL BUTONU (3. FOTOĞRAFTAKİ GİBİ)
        local StealBtn = Instance.new("TextButton")
        StealBtn.Size = UDim2.new(0, 75, 0, 36)
        StealBtn.Position = UDim2.new(1, -82, 0, 8)
        StealBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        StealBtn.BorderSizePixel = 2
        StealBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
        StealBtn.Font = Enum.Font.FredokaOne
        StealBtn.Text = "STEAL"
        StealBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        StealBtn.TextSize = 16
        StealBtn.Parent = Card
        
        local StealCorner = Instance.new("UICorner")
        StealCorner.CornerRadius = UDim.new(0, 6)
        StealCorner.Parent = StealBtn
        
        StealBtn.MouseButton1Click:Connect(function()
            StealEgg(data.Instance)
        end)
    end
end

-- ==============================================================================
-- 4. ETKİLEŞİMLER VE DÖNGÜLER
-- ==============================================================================
-- Sol menü aç/kapa
LeftSidebarBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Server Hop Butonu
HopPill.MouseButton1Click:Connect(function()
    HopServer()
end)

-- Auto Hunt Aç/Kapa
AutoHuntBtn.MouseButton1Click:Connect(function()
    Settings.AutoHunt = not Settings.AutoHunt
    if Settings.AutoHunt then
        AutoHuntBtn.Text = "AUTO ON"
        AutoHuntBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        AutoHuntBtn.Text = "AUTO OFF"
        AutoHuntBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
    end
end)

-- İlk çizim
RenderCards()

-- Canlı Yenileme ve Otomatik Avcı Döngüsü
task.spawn(function()
    while true do
        task.wait(4)
        RenderCards()
        
        -- Eğer Auto Hunt açıksa ve sunucudaki en değerli yumurta limitin altındaysa başka sunucuya geç
        if Settings.AutoHunt then
            local currentEggs = ScanCurrentServerRealEggs()
            local bestEgg = currentEggs[1]
            
            if bestEgg and bestEgg.Numeric >= Settings.MinHuntValue then
                -- Değerli yumurta bulundu! Dur ve çal!
                StealEgg(bestEgg.Instance)
                Settings.AutoHunt = false
                AutoHuntBtn.Text = "BULUNDU!"
                AutoHuntBtn.BackgroundColor3 = Color3.fromRGB(240, 160, 20)
            else
                -- Bu sunucuda yok, sıradakine geç!
                HopServer()
                break
            end
        end
    end
end)
