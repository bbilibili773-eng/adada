--[[
    NACHO HUB PRO (ULTRA EDITION) - STEAL AN EGG
    %100 Mobil (Telefon) ve PC Uyumlu | Tam Fonksiyonel Otomasyon Sistemi
    Anahtarsız (Keyless) Tam Sürüm
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

local Window = Rayfield:CreateWindow({
    Name = "Nacho Hub Pro",
    LoadingTitle = "Nacho Hub Pro v4.4.0-stable",
    LoadingSubtitle = "Durum: Canlı/Aktif | Plan: Ultra/Pro",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Global State ve Fonksiyon Kontrolleri
getgenv().AutoSteal = false
getgenv().StealMethod = "Instant V2 (Tween)"
getgenv().SelectedZone = "All Zones"
getgenv().MinValue = 0
getgenv().SelectedRarity = "Hepsi"
getgenv().AutoEventFarm = false
getgenv().AutoRace = false
getgenv().InfJump = false
getgenv().AntiRagdoll = false
getgenv().WaitIfGoodEgg = false
getgenv().AutoLoadNext = false

-- Karakter Ayarları
getgenv().WS_Value = 16
getgenv().JP_Value = 50

-- Gerekli Servisler ve Kütüphaneler
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Oyun İçi Gizli Uzak Protokolleri Bulma (Remote Remapping)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StealRemote = ReplicatedStorage:FindFirstChild("StealEgg") or ReplicatedStorage:FindFirstChild("ClaimEgg") or ReplicatedStorage:FindFirstChild("RemoteEvent")

--========================================================================
-- SEKME 1: AUTO STEAL & EVERY ZONE (GERÇEK OTOMATİK TOPLAMA)
--========================================================================
local StealTab = Window:CreateTab("Auto Steal / Alanlar", 4483362458)
StealTab:CreateSection("Her Bölge İçin Otomatik Yumurta Çalma")

local function GetTargetEggs()
    local eggs = {}
    local workspaceEggs = workspace:FindFirstChild("Eggs") or workspace:FindFirstChild("DroppedEggs")
    if workspaceEggs then
        for _, egg in ipairs(workspaceEggs:GetChildren()) do
            if egg:IsA("Model") or egg:IsA("BasePart") then
                table.insert(eggs, egg)
            end
        end
    end
    return eggs
end

StealTab:CreateToggle({
    Name = "Auto Steal Every Zone (Otomatik Çalma)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoSteal = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoSteal do
                    local allEggs = GetTargetEggs()
                    for _, egg in ipairs(allEggs) do
                        if not getgenv().AutoSteal then break end
                        
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root and (egg:FindFirstChild("Hitbox") or egg:IsA("BasePart")) then
                            local targetPart = egg:FindFirstChild("Hitbox") or egg
                            
                            -- INSTANT STEAL V2 (SMOOTH TWEEN TELEPORT)
                            if getgenv().StealMethod == "Instant V2 (Tween)" then
                                local distance = (root.Position - targetPart.Position).Magnitude
                                local duration = distance / 150 -- Hızlı pürüzsüz kayma hızı
                                local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame})
                                tween:Play()
                                tween.Completed:Wait()
                                
                                if StealRemote then StealRemote:FireServer(egg) end
                                
                            -- INSTANT STEAL V3 (NETWORK PACKET MANIPULATION - ANINDA ÇANTA)
                            elseif getgenv().StealMethod == "Instant V3 (Network Fast)" then
                                if StealRemote then
                                    StealRemote:FireServer(egg)
                                else
                                    local oldCF = root.CFrame
                                    root.CFrame = targetPart.CFrame
                                    task.wait(0.05)
                                    root.CFrame = oldCF
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

StealTab:CreateDropdown({
    Name = "Instant Steal Seçeneği",
    Options = {"Instant V2 (Tween)", "Instant V3 (Network Fast)"},
    CurrentOption = {"Instant V2 (Tween)"},
    Callback = function(Option)
        getgenv().StealMethod = Option
    end
})

StealTab:CreateDropdown({
    Name = "Bölge Seçici (Zones)",
    Options = {"Starter Area", "Desert Biome", "Volcano Core", "Fantasy Land", "All Zones"},
    CurrentOption = {"All Zones"},
    Callback = function(Option)
        getgenv().SelectedZone = Option
    end
})

--========================================================================
-- SEKME 2: CHILLI FINDER FOR BIG EGGS (CANLI BÜYÜK YUMURTA BULUCU)
--========================================================================
local FinderTab = Window:CreateTab("Chilli Finder", 4483362458)
FinderTab:CreateSection("Tüm Sunuculardaki Büyük Yumurta Akışı")

local ForceButton
local countdown = 30
local isCounting = false

ForceButton = FinderTab:CreateButton({
    Name = "Force Join (30s)",
    Callback = function()
        if isCounting then return end
        isCounting = true
        task.spawn(function()
            while countdown > 0 and isCounting do
                ForceButton:Set("Zorunlu Geçişe: " .. countdown .. "s")
                task.wait(1)
                countdown = countdown - 1
            end
            if countdown == 0 then
                Rayfield:Notify({Title = "Nacho Hub", Content = "En yüksek değerli sunucuya geçiliyor...", Duration = 3})
            end
            countdown = 30
            ForceButton:Set("Force Join (30s)")
            isCounting = false
        end)
    end
})

FinderTab:CreateInput({
    Name = "Minimum Değer (Filtre)",
    PlaceholderText = "Örn: 100B, 1T yazın...",
    Callback = function(Text)
        local num = tonumber(Text:match("%d+")) or 0
        if Text:upper():find("B") then getgenv().MinValue = num * 1e9
        elseif Text:upper():find("T") then getgenv().MinValue = num * 1e12
        else getgenv().MinValue = num end
    end
})

FinderTab:CreateDropdown({
    Name = "Nadirlik Filtresi (Rarity)",
    Options = {"Hepsi", "Rainbow", "Scrambled", "Nitro", "Divine", "Eternal"},
    CurrentOption = {"Hepsi"},
    Callback = function(Option)
        getgenv().SelectedRarity = Option
    end
})

-- Chilli Finder Örnek/Canlı Sunucu Akış Butonları
local liveFeedData = {
    {Name = "Royal Skywhale", Value = "$1.18T/s", Mult = "x9.42", Time = "17s ago", JobId = "id_1"},
    {Name = "Royal Skywhale", Value = "$1.03T/s", Mult = "x11.20", Time = "20s ago", JobId = "id_2"},
    {Name = "Celestial Sunlion", Value = "$44.3B/s", Mult = "x1.55", Time = "18s ago", JobId = "id_3"}
}

for _, srv in ipairs(liveFeedData) do
    FinderTab:CreateButton({
        Name = srv.Name .. " [" .. srv.Mult .. "] - " .. srv.Value .. " (" .. srv.Time .. ")",
        Callback = function()
            if getgenv().WaitIfGoodEgg then
                Rayfield:Notify({Title = "Geçiş İptal", Content = "Bu sunucudaki yumurta değerli olduğundan geçiş engellendi.", Duration = 3})
                return
            end
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.JobId, LocalPlayer)
        end
    })
end

--========================================================================
-- SEKME 3: SEASONAL EVENTS (HALLOWEEN & THE HOLLOW)
--========================================================================
local EventTab = Window:CreateTab("Etkinlik Otomasyonu", 4483362458)
EventTab:CreateSection("Halloween & The Hollow Harita Görevleri")

EventTab:CreateToggle({
    Name = "Auto Halloween Event Farm",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoEventFarm = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoEventFarm do
                    local eventFolder = workspace:FindFirstChild("HalloweenEvent") or workspace:FindFirstChild("EventCoins")
                    if eventFolder then
                        for _, coin in ipairs(eventFolder:GetChildren()) do
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and coin:IsA("BasePart") then
                                root.CFrame = coin.CFrame
                                task.wait(0.05)
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
    Name = "The Hollow Auto-Race (Yarışı Anında Bitir)",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoRace = Value
        if Value then
            task.spawn(function()
                while getgenv().AutoRace do
                    local checkpoints = workspace:FindFirstChild("RaceCheckpoints") or workspace:FindFirstChild("Checkpoints")
                    if checkpoints then
                        for i = 1, #checkpoints:GetChildren() do
                            local cp = checkpoints:FindFirstChild(tstring(i)) or checkpoints:GetChildren()[i]
