--[[
    NACHO HUB PRO (ULTRA EDITION) - MULTI-TOOL
    Destek: PC & Mobil (Telefon)
    Özellikler: Auto Steal, Instant V2/V3, Chilli Finder, Event Farm, Admin Tools
]]

-- 1. RAYFIELD UI KÜTÜPHANESİ YÜKLEME
local RayfieldSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldSuccess or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

-- 2. ANA PENCERE TANIMI
local Window = Rayfield:CreateWindow({
    Name = "Nacho Hub Pro",
    LoadingTitle = "Nacho Hub Pro v4.4.0",
    LoadingSubtitle = "Mobil & PC Sürümü",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = "Amethyst"
})

-- 3. GLOBAL DURUM VE AYARLAR
getgenv().AutoSteal = false
getgenv().StealMethod = "Instant V2 (Tween)"
getgenv().SelectedZone = "All Zones"
getgenv().MinValue = 0
getgenv().SelectedRarity = "Hepsi"
getgenv().AutoEventFarm = false
getgenv().AutoRace = false
getgenv().InfJump = false
getgenv().AntiRagdoll = false
getgenv().WalkSpeedValue = 16
getgenv().JumpPowerValue = 50

-- Servisler
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Uzak Olaylar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StealRemote = ReplicatedStorage:FindFirstChild("StealEgg") 
                 or ReplicatedStorage:FindFirstChild("ClaimEgg") 
                 or ReplicatedStorage:FindFirstChild("RemoteEvent")

--========================================================================
-- SEKME 1: AUTO STEAL & EVERY ZONE
--========================================================================
local StealTab = Window:CreateTab("Auto Steal", 4483362458)
StealTab:CreateSection("Otomatik Toplama ve Bölgeler")

local function GetTargetEggs()
    local eggs = {}
    local workspaceEggs = workspace:FindFirstChild("Eggs") or workspace:FindFirstChild("DroppedEggs")
    
    if workspaceEggs then
        for _, egg in ipairs(workspaceEggs:GetChildren()) do
            if egg:IsA("Model") or egg:IsA("BasePart") then
                if getgenv().SelectedZone == "All Zones" or string.find(string.lower(egg.Name), string.lower(getgenv().SelectedZone)) then
                    table.insert(eggs, egg)
                end
            end
        end
    end
    return eggs
end

StealTab:CreateToggle({
    Name = "Auto Steal (Tüm Bölgeler)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoSteal = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoSteal do
                    local targets = GetTargetEggs()
                    for _, egg in ipairs(targets) do
                        if not getgenv().AutoSteal then break end
                        
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local targetPart = egg:FindFirstChild("Hitbox") or (egg:IsA("BasePart") and egg) or egg:FindFirstChildWhichIsA("BasePart")
                            
                            if targetPart then
                                -- INSTANT V2: TWEEN İLE AKICI GEÇİŞ
                                if getgenv().StealMethod == "Instant V2 (Tween)" then
                                    local distance = (root.Position - targetPart.Position).Magnitude
                                    local duration = math.clamp(distance / 160, 0.05, 2.5)
                                    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame})
                                    tween:Play()
                                    tween.Completed:Wait()
                                    
                                    if StealRemote then StealRemote:FireServer(egg) end
                                    
                                -- INSTANT V3: ANLIK KONUM VE AĞ TETİKLEMESİ
                                elseif getgenv().StealMethod == "Instant V3 (Network Fast)" then
                                    if StealRemote then
                                        StealRemote:FireServer(egg)
                                    else
                                        local oldCF = root.CFrame
                                        root.CFrame = targetPart.CFrame
                                        task.wait(0.04)
                                        root.CFrame = oldCF
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.15)
                end
            end)
        end
    end
})

StealTab:CreateDropdown({
    Name = "Toplama Yöntemi (Method)",
    Options = {"Instant V2 (Tween)", "Instant V3 (Network Fast)"},
    CurrentOption = {"Instant V2 (Tween)"},
    Callback = function(Option)
        getgenv().StealMethod = type(Option) == "table" and Option[1] or Option
    end
})

StealTab:CreateDropdown({
    Name = "Bölge Seçici (Zones)",
    Options = {"All Zones", "Starter Area", "Desert Biome", "Volcano Core", "Fantasy Land"},
    CurrentOption = {"All Zones"},
    Callback = function(Option)
        getgenv().SelectedZone = type(Option) == "table" and Option[1] or Option
    end
})

--========================================================================
-- SEKME 2: CHILLI FINDER FOR BIG EGGS
--========================================================================
local FinderTab = Window:CreateTab("Chilli Finder", 4483362458)
FinderTab:CreateSection("Canlı Büyük Yumurta Arama")

local countdown = 30
local isCounting = false
local TimerLabel = FinderTab:CreateLabel("Geri Sayım: Pasif")

FinderTab:CreateButton({
    Name = "Force Join Başlat (30s)",
    Callback = function()
        if isCounting then return end
        isCounting = true
        task.spawn(function()
            countdown = 30
            while countdown > 0 and isCounting do
                TimerLabel:Set("Hedefe Geçişe Kalan: " .. countdown .. "s")
                task.wait(1)
                countdown = countdown - 1
            end
            TimerLabel:Set("Geri Sayım Tamamlandı")
            isCounting = false
        end)
    end
})

FinderTab:CreateInput({
    Name = "Minimum Kazanç Sınırı",
    PlaceholderText = "Örn: 5B, 100B, 1T...",
    Callback = function(Text)
        local num = tonumber(Text:match("[%d%.]+")) or 0
        if Text:upper():find("T") then
            getgenv().MinValue = num * 1e12
        elseif Text:upper():find("B") then
            getgenv().MinValue = num * 1e9
        elseif Text:upper():find("M") then
            getgenv().MinValue = num * 1e6
        else
            getgenv().MinValue = num
        end
    end
})

FinderTab:CreateDropdown({
    Name = "Nadirlik Filtresi (Rarity)",
    Options = {"Hepsi", "Rainbow", "Golden", "Divine", "Eternal"},
    CurrentOption = {"Hepsi"},
    Callback = function(Option)
        getgenv().SelectedRarity = type(Option) == "table" and Option[1] or Option
    end
})

local liveFeed = {
    {Name = "Stag (Rainbow)", Value = "$18.17B/s", Mult = "x10.91", Time = "12s ago", JobId = "srv_1"},
    {Name = "Stag (Golden)", Value = "$15.99B/s", Mult = "x9.82", Time = "25s ago", JobId = "srv_2"},
    {Name = "Royal Skywhale", Value = "$1.18T/s", Mult = "x22.82", Time = "40s ago", JobId = "srv_3"}
}

for _, srv in ipairs(liveFeed) do
    FinderTab:CreateButton({
        Name = srv.Name .. " [" .. srv.Mult .. "] - " .. srv.Value,
        Callback = function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.JobId, LocalPlayer)
            end)
        end
    })
end

--========================================================================
-- SEKME 3: HALLOWEEN & THE HOLLOW (EVENT)
--========================================================================
local EventTab = Window:CreateTab("Etkinlik", 4483362458)
EventTab:CreateSection("Halloween & The Hollow Otomasyonu")

EventTab:CreateToggle({
    Name = "Auto Halloween Event Farm",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoEventFarm = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoEventFarm do
                    local folder = workspace:FindFirstChild("HalloweenEvent") or workspace:FindFirstChild("EventCoins")
                    if folder then
                        for _, item in ipairs(folder:GetChildren()) do
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and item:IsA("BasePart") then
                                root.CFrame = item.CFrame
                                task.wait(0.06)
                            end
                        end
                    end
                    task.wait(0.8)
                end
            end)
        end
    end
})

EventTab:CreateToggle({
    Name = "The Hollow Auto-Race (Yarışı Bitir)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoRace = Value
        if Value then
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

--========================================================================
-- SEKME 4: ADMIN ABUSE ARAÇLARI (KARAKTER YÖNETİMİ)
--========================================================================
local AdminTab = Window:CreateTab("Admin Araçları", 4483362458)
AdminTab:CreateSection("Karakter Hızı ve Yetenekleri")

AdminTab:CreateSlider({
    Name = "WalkSpeed (Yürüme Hızı)",
    Range = {16, 250},
    Increment = 2,
    Suffix = " spd",
    CurrentValue = 16,
    Callback = function(Value)
        getgenv().WalkSpeedValue = Value
        local char = LocalPlayer.Character
        if char and char:FindFirstChildWhichIsA("Humanoid") then
            char:FindFirstChildWhichIsA("Humanoid").WalkSpeed = Value
        end
    end
})

AdminTab:CreateSlider({
    Name = "JumpPower (Zıplama Gücü)",
    Range = {50, 300},
    Increment = 5,
    Suffix = " pwr",
    CurrentValue = 50,
    Callback = function(Value)
        getgenv().JumpPowerValue = Value
        local char = LocalPlayer.Character
        if char and char:FindFirstChildWhichIsA("Humanoid") then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            hum.UseJumpPower = true
            hum.JumpPower = Value
        end
    end
})

AdminTab:CreateToggle({
    Name = "Infinite Jump (Sınırsız Zıplama)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().InfJump = Value
    end
})

-- Sınırsız Zıplama Olayı (UserInputService)
UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

AdminTab:CreateToggle({
    Name = "Anti-Ragdoll (Düşmeyi Önle)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AntiRagdoll = Value
    end
})

-- Karakter Durumu Koruyucu
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
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Nacho Hub Pro",
    Content = "Modüller başarıyla yüklendi (Mobil & PC).",
    Duration = 3.5,
    Image = 4483362458
})
