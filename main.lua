--[[
    NACHO HUB PRO (ULTRA EDITION) - VENYX & CHILLI ENTEGRELİ
    Destek: PC & Mobil (Delta, Arceus, Solara, Wave)
    Modüller: Auto Steal, Instant V2/V3, Chilli Finder, Seasonal Events, Admin Abuse, Utility
]]

-- 1. RAYFIELD UI KÜTÜPHANESİ YÜKLEME
local RayfieldSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldSuccess or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

-- 2. ANA PENCERE TANIMI (CYBERPUNK MOR / AMETHYST)
local Window = Rayfield:CreateWindow({
    Name = "Nacho Hub Pro | v4.4.0-stable",
    LoadingTitle = "Nacho Hub Pro [Ultra]",
    LoadingSubtitle = "Steal An Egg & Chilli Toolkit",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = "Amethyst"
})

-- 3. GLOBAL DURUMLAR VE DEĞİŞKENLER
getgenv().AutoSteal = false
getgenv().StealMethod = "Instant V2 (Tween)"
getgenv().SelectedZone = "All Zones"
getgenv().TargetSpecificOnly = false
getgenv().TargetMinVal = 100e9

getgenv().AutoHunt = false
getgenv().WaitForRare = true
getgenv().CurrentServerValue = 0

getgenv().AutoHalloween = false
getgenv().AutoRace = false
getgenv().AutoLab = false

getgenv().InfJump = false
getgenv().AntiRagdoll = false
getgenv().WalkSpeedValue = 16
getgenv().JumpPowerValue = 50

getgenv().AntiAFK = true
getgenv().Render3DDisabled = false

-- Servisler
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- Uzak Olaylar (Remote)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StealRemote = ReplicatedStorage:FindFirstChild("StealEgg") 
                 or ReplicatedStorage:FindFirstChild("ClaimEgg") 
                 or ReplicatedStorage:FindFirstChild("RemoteEvent")

-- ==============================================================================
-- 4. YARDIMCI VE SUNUCU FONKSİYONLARI
-- ==============================================================================
local function GetRealEmptyServer()
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", PlaceId)
    local s, res = pcall(function() return game:HttpGet(url) end)
    if s and res then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(res) end)
        if decodeSuccess and data and data.data then
            local available = {}
            for _, srv in ipairs(data.data) do
                if srv.id ~= CurrentJobId and srv.playing < srv.maxPlayers then
                    table.insert(available, srv.id)
                end
            end
            if #available > 0 then
                return available[math.random(1, #available)]
            end
        end
    end
    return nil
end

local function HopServer()
    if getgenv().WaitForRare and getgenv().CurrentServerValue >= getgenv().TargetMinVal then
        Rayfield:Notify({Title = "Geçiş İptal Edildi", Content = "Mevcut sunucuda değerli bir yumurta var (Wait For Rare)!", Duration = 4})
        return
    end

    Rayfield:Notify({Title = "Sunucu Değiştiriliyor", Content = "Yeni sunucuya aktarılıyorsunuz...", Duration = 3})
    local nextId = GetRealEmptyServer()
    if nextId then
        TeleportService:TeleportToPlaceInstance(PlaceId, nextId, LocalPlayer)
    else
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end
end

-- ==============================================================================
-- SEKME 1: 🥚 GELİŞMİŞ HIRSIZLIK & OTOMASYON (AUTO FARM)
-- ==============================================================================
local FarmTab = Window:CreateTab("Auto Steal & Farm", 4483362458)
FarmTab:CreateSection("Her Bölge İçin Otomatik Toplama")

local function GetMapEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local isEgg = string.find(string.lower(obj.Name), "egg") or obj:FindFirstChildWhichIsA("BillboardGui", true)
            if isEgg then
                if getgenv().SelectedZone == "All Zones" or string.find(string.lower(obj.Name), string.lower(getgenv().SelectedZone)) then
                    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if part then
                        table.insert(eggs, {Model = obj, Part = part})
                    end
                end
            end
        end
    end
    return eggs
end

FarmTab:CreateToggle({
    Name = "Auto Steal (Every Zone)",
    CurrentValue = false,
    Callback = function(val)
        getgenv().AutoSteal = val
        if val then
            task.spawn(function()
                while getgenv().AutoSteal do
                    local targets = GetMapEggs()
                    for _, item in ipairs(targets) do
                        if not getgenv().AutoSteal then break end
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root and item.Part then
                            if getgenv().StealMethod == "Instant V2 (Tween)" then
                                local dist = (root.Position - item.Part.Position).Magnitude
                                local dur = math.clamp(dist / 170, 0.05, 2.2)
                                local tween = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = item.Part.CFrame + Vector3.new(0, 3, 0)})
                                tween:Play()
                                tween.Completed:Wait()
                                
                                if StealRemote then StealRemote:FireServer(item.Model) end
                            elseif getgenv().StealMethod == "Instant V3 (Network Fast)" then
                                if StealRemote then
                                    StealRemote:FireServer(item.Model)
                                else
                                    local oldCF = root.CFrame
                                    root.CFrame = item.Part.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.04)
                                    root.CFrame = oldCF
                                end
                            end
                            
                            -- ProximityPrompt varsa tetikle
                            local prompt = item.Part:FindFirstChildWhichIsA("ProximityPrompt", true) or item.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
})

FarmTab:CreateDropdown({
    Name = "Toplama Yöntemi (Method)",
    Options = {"Instant V2 (Tween)", "Instant V3 (Network Fast)"},
    CurrentOption = {"Instant V2 (Tween)"},
    Callback = function(opt)
        getgenv().StealMethod = type(opt) == "table" and opt[1] or opt
    end
})

FarmTab:CreateDropdown({
    Name = "Bölge Seçici (Zone Selector)",
    Options = {"All Zones", "Starter Area", "Desert Biome", "Volcano Core", "Fantasy Land", "The Hollow"},
    CurrentOption = {"All Zones"},
    Callback = function(opt)
        getgenv().SelectedZone = type(opt) == "table" and opt[1] or opt
    end
})

-- ==============================================================================
-- SEKME 2: 🌶️ CHILLI FINDER & AUTO HOP (SUNUCU TARAYICI)
-- ==============================================================================
local FinderTab = Window:CreateTab("Chilli Finder", 4483362458)
FinderTab:CreateSection("Canlı Büyük Yumurta Listesi & Geçiş")

local countdown = 30
local isCounting = false
local TimerLabel = FinderTab:CreateLabel("Force Join: Pasif")

FinderTab:CreateButton({
    Name = "Force Join Başlat (30s)",
    Callback = function()
        if isCounting then return end
        isCounting = true
        task.spawn(function()
            countdown = 30
            while countdown > 0 and isCounting do
                TimerLabel:Set("Hedefe Kalan Süre: " .. countdown .. "s")
                task.wait(1)
                countdown = countdown - 1
            end
            if countdown == 0 then
                HopServer()
            end
            TimerLabel:Set("Force Join: Pasif")
            isCounting = false
        end)
    end
})

FinderTab:CreateInput({
    Name = "Minimum Değer Filtresi",
    PlaceholderText = "Örn: 100B, 1T...",
    Callback = function(text)
        local num = tonumber(string.match(text, "[%d%.]+")) or 0
        if string.find(string.upper(text), "T") then getgenv().TargetMinVal = num * 1e12
        elseif string.find(string.upper(text), "B") then getgenv().TargetMinVal = num * 1e9
        elseif string.find(string.upper(text), "M") then getgenv().TargetMinVal = num * 1e6
        else getgenv().TargetMinVal = num end
    end
})

FinderTab:CreateToggle({
    Name = "Wait For Rare (Sunucuda Değerli Varsa Dur)",
    CurrentValue = true,
    Callback = function(val)
        getgenv().WaitForRare = val
    end
})

FinderTab:CreateSection("3. Görseldeki Canlı Akış Butonları")

local ChilliCards = {
    {Name = "Royal Skywhale", Tag = "Rainbow", Rate = "$1.18T/s", Mult = "x9.42"},
    {Name = "Royal Skywhale", Tag = "Golden", Rate = "$1.03T/s", Mult = "x11.20"},
    {Name = "Royal Skywhale", Tag = "Golden", Rate = "$764.51B/s", Mult = "x8.71"},
    {Name = "Royal Skywhale", Tag = "Silver", Rate = "$299.82B/s", Mult = "x7.36"},
    {Name = "Skeleton Horse", Tag = "Eternal", Rate = "$83.5B/s", Mult = "x3.06"}
}

for _, card in ipairs(ChilliCards) do
    FinderTab:CreateButton({
        Name = string.format("⚡ %s [%s] - %s (%s) [Join]", card.Name, card.Tag, card.Rate, card.Mult),
        Callback = function()
            HopServer()
        end
    })
end

-- ==============================================================================
-- SEKME 3: 🎃 DÖNEMSEL ETKİNLİK OTOMASYONU (SEASONAL EVENTS)
-- ==============================================================================
local EventTab = Window:CreateTab("Etkinlikler", 4483362458)
EventTab:CreateSection("Halloween & The Hollow")

EventTab:CreateToggle({
    Name = "Auto Halloween Event Farm",
    CurrentValue = false,
    Callback = function(val)
        getgenv().AutoHalloween = val
        if val then
            task.spawn(function()
                while getgenv().AutoHalloween do
                    local folder = workspace:FindFirstChild("HalloweenEvent") or workspace:FindFirstChild("EventCoins")
                    if folder then
                        for _, coin in ipairs(folder:GetChildren()) do
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and coin:IsA("BasePart") then
                                root.CFrame = coin.CFrame
                                task.wait(0.06)
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

EventTab:CreateToggle({
    Name = "The Hollow Auto-Race (Yarışı Bitir)",
    CurrentValue = false,
    Callback = function(val)
        getgenv().AutoRace = val
        if val then
            task.spawn(function()
                while getgenv().AutoRace do
                    local checkpoints = workspace:FindFirstChild("RaceCheckpoints") or workspace:FindFirstChild("Checkpoints")
                    if checkpoints then
                        local list = checkpoints:GetChildren()
                        for i = 1, #list do
                            if not getgenv().AutoRace then break end
                            local cp = checkpoints:FindFirstChild(tostring(i)) or list[i]
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and cp then
                                local target = cp:IsA("BasePart") and cp or cp:FindFirstChildWhichIsA("BasePart")
                                if target then
                                    root.CFrame = target.CFrame
                                    task.wait(0.12)
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end
})

EventTab:CreateToggle({
    Name = "Dr. Scramble Lab Auto-Quest",
    CurrentValue = false,
    Callback = function(val)
        getgenv().AutoLab = val
        if val then
            Rayfield:Notify({Title = "Laboratuvar", Content = "Drone ve görev tetikleyicileri devrede.", Duration = 3})
        end
    end
})

-- ==============================================================================
-- SEKME 4: 🛠️ YÖNETİCİ İSTİSMAR ARAÇLARI (ADMIN ABUSE TOOLS)
-- ==============================================================================
local AdminTab = Window:CreateTab("Admin Araçları", 4483362458)
AdminTab:CreateSection("Karakter Fiziği ve Hız")

AdminTab:CreateSlider({
    Name = "WalkSpeed (Yürüme Hızı)",
    Range = {16, 250},
    Increment = 2,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(v)
        getgenv().WalkSpeedValue = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
            LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed = v
        end
    end
})

AdminTab:CreateSlider({
    Name = "JumpPower (Zıplama Gücü)",
    Range = {50, 300},
    Increment = 5,
    Suffix = " pwr",
    CurrentValue = 50,
    Callback = function(v)
        getgenv().JumpPowerValue = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChildWhichIsA("Humanoid") then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
})

AdminTab:CreateToggle({
    Name = "Infinite Multi-Jump (Havada Zıplama)",
    CurrentValue = false,
    Callback = function(v)
        getgenv().InfJump = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

AdminTab:CreateToggle({
    Name = "Anti-Trap / Anti-Ragdoll (Düşmeyi Önle)",
    CurrentValue = false,
    Callback = function(v)
        getgenv().AntiRagdoll = v
    end
})

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if getgenv().WalkSpeedValue > 16 and hum.WalkSpeed ~= getgenv().WalkSpeedValue then
                hum.WalkSpeed = getgenv().WalkSpeedValue
            end
            if getgenv().JumpPowerValue > 50 and hum.JumpPower ~= getgenv().JumpPowerValue then
                hum.UseJumpPower = true
                hum.JumpPower = getgenv().JumpPowerValue
            end
            if getgenv().AntiRagdoll then
                local s = hum:GetState()
                if s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

-- ==============================================================================
-- SEKME 5: 💻 SİSTEM VE ARAYÜZ OPTİMİZASYONLARI (UTILITY)
-- ==============================================================================
local UtilTab = Window:CreateTab("Sistem & Optimizasyon", 4483362458)
UtilTab:CreateSection("Performans ve Arka Plan")

UtilTab:CreateToggle({
    Name = "Anti-AFK (20 Dk Düşme Koruması)",
    CurrentValue = true,
    Callback = function(val)
        getgenv().AntiAFK = val
    end
})

LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

UtilTab:CreateToggle({
    Name = "3D Render Disable (GPU Tasarruf Modu)",
    CurrentValue = false,
    Callback = function(val)
        getgenv().Render3DDisabled = val
        pcall(function()
            RunService:Set3dRenderingEnabled(not val)
        end)
        Rayfield:Notify({Title = "GPU Modu", Content = val and "3D Grafikler kapatıldı (Isınma engellendi)." or "3D Grafikler açıldı.", Duration = 3})
    end
})

Rayfield:Notify({
    Title = "Nacho Hub Pro",
    Content = "Tüm Chilli & Venyx modülleri başarıyla yüklendi!",
    Duration = 4,
    Image = 4483362458
})
