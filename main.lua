--[[
    NACHO HUB PRO v6.0 - AUTO HUNT SNIPER (CHILLI PRO ALTERNATİFİ)
    Özellikler: 
    1. Otomatik Avcı (Sunucu sunucu gezip hedef yumurtayı bulur, durur ve çalar)
    2. Mevcut Sunucudaki Gerçek Yumurta Listesi (Steal Panel)
    3. Admin Araçları (Hız, Zıplama, Anti-Ragdoll)
]]

-- 1. RAYFIELD UI KÜTÜPHANESİ
local RayfieldSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldSuccess or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

-- 2. ANA PENCERE
local Window = Rayfield:CreateWindow({
    Name = "Nacho Hub Pro",
    LoadingTitle = "Nacho Auto-Hunt Sniper",
    LoadingSubtitle = "Otomatik Sunucu Avcısı",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = "Amethyst"
})

-- 3. GLOBAL DURUMLAR VE DEĞİŞKENLER
getgenv().AutoHunt = false
getgenv().HuntMinValue = 50e6 -- Varsayılan 50M/s
getgenv().HuntTargetName = "Hepsi"
getgenv().AutoSteal = false
getgenv().InfJump = false
getgenv().AntiRagdoll = false
getgenv().WalkSpeedValue = 16
getgenv().JumpPowerValue = 50

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- YENİ SUNUCUDA OTOMATİK BAŞLAMA KUYRUĞU
local function QueueScriptForNextServer()
    local queue = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    if queue then
        local code = string.format([[
            task.wait(2)
            getgenv().AutoHunt = %s
            getgenv().HuntMinValue = %f
            getgenv().HuntTargetName = %q
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bbilibili773-eng/adada/main/main.lua"))()
        ]], tostring(getgenv().AutoHunt), getgenv().HuntMinValue, getgenv().HuntTargetName)
        queue(code)
    end
end

-- BOŞ SUNUCUYA GEÇİŞ (SERVER HOP)
local function HopToNextServer()
    QueueScriptForNextServer()
    
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
                local targetJob = available[math.random(1, #available)]
                TeleportService:TeleportToPlaceInstance(PlaceId, targetJob, LocalPlayer)
                return
            end
        end
    end
    
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

-- ==============================================================================
-- 4. GERÇEK HARİTA TARAMA MOTORU
-- ==============================================================================
local function ScanCurrentServerRealEggs()
    local detectedEggs = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local billboard = obj:FindFirstChildWhichIsA("BillboardGui", true)
            if billboard then
                local eggName = nil
                local eggRate = nil
                local eggMult = nil
                local eggTag = ""

                for _, lbl in ipairs(billboard:GetDescendants()) do
                    if lbl:IsA("TextLabel") then
                        local txt = lbl.Text
                        if string.find(txt, "%$") and string.find(txt, "/s") then
                            eggRate = txt
                        elseif string.find(txt, "^x%d") or string.find(txt, "x%d+%.%d+") then
                            eggMult = txt
                        elseif string.find(string.lower(txt), "halloween") or string.find(string.lower(txt), "rainbow") or string.find(string.lower(txt), "golden") then
                            eggTag = txt
                        elseif #txt > 2 and not string.find(txt, "%$") and not string.find(txt, "x") and not string.find(txt, "Hold") then
                            eggName = txt
                        end
                    end
                end

                if eggRate or eggName then
                    local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if rootPart then
                        local cleanNum = tonumber(string.match(eggRate or "0", "[%d%.]+")) or 0
                        if string.find(eggRate or "", "B") then cleanNum = cleanNum * 1e9
                        elseif string.find(eggRate or "", "M") then cleanNum = cleanNum * 1e6
                        elseif string.find(eggRate or "", "T") then cleanNum = cleanNum * 1e12 end

                        table.insert(detectedEggs, {
                            Instance = rootPart,
                            Name = eggName or obj.Name,
                            Rate = eggRate or "$0/s",
                            Mult = eggMult or "x1.0",
                            Tag = eggTag,
                            NumericValue = cleanNum
                        })
                    end
                end
            end
        end
    end

    table.sort(detectedEggs, function(a, b)
        return a.NumericValue > b.NumericValue
    end)

    return detectedEggs
end

-- IŞINLANMA VE ÇALMA
local function StealTargetEgg(targetPart)
    if not targetPart then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.15)
        
        local prompt = targetPart:FindFirstChildWhichIsA("ProximityPrompt", true) 
                    or targetPart.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                end)
            end
        end
    end
end

-- ==============================================================================
-- SEKME 1: AUTO HUNT SNIPER (CHILLI PRO YERİNE GEÇEN SİSTEM)
-- ==============================================================================
local HuntTab = Window:CreateTab("Auto Hunt Sniper", 4483362458)
HuntTab:CreateSection("Otomatik Sunucu Gezici ve Değerli Yumurta Avcısı")

local HuntStatusLabel = HuntTab:CreateLabel("Avcı Durumu: Beklemede")

HuntTab:CreateToggle({
    Name = "⚡ Auto Hunt Sniper (Otomatik Avı Başlat)",
    CurrentValue = getgenv().AutoHunt or false,
    Callback = function(val)
        getgenv().AutoHunt = val
        if val then
            HuntStatusLabel:Set("Durum: Avcı Aktif! Sunucular taranıyor...")
            Rayfield:Notify({Title = "Avcı Başlatıldı", Content = "Değerli yumurta bulunana kadar sunucular taranacak!", Duration = 3})
            
            task.spawn(function()
                task.wait(1.5)
                local eggs = ScanCurrentServerRealEggs()
                local found = nil
                
                for _, egg in ipairs(eggs) do
                    local nameMatch = (getgenv().HuntTargetName == "Hepsi") or string.find(string.lower(egg.Name), string.lower(getgenv().HuntTargetName))
                    local valMatch = (egg.NumericValue >= getgenv().HuntMinValue)
                    
                    if nameMatch and valMatch then
                        found = egg
                        break
                    end
                end
                
                if found then
                    HuntStatusLabel:Set("HEDEF BULUNDU: " .. found.Name .. " (" .. found.Rate .. ")")
                    Rayfield:Notify({Title = "HEDEF BULUNDU!", Content = found.Name .. " tespit edildi, çalınıyor!", Duration = 5})
                    getgenv().AutoHunt = false -- Hedef bulunduğu için gezmeyi durdur
                    StealTargetEgg(found.Instance)
                else
                    HuntStatusLabel:Set("Değerli yumurta yok. Sıradaki sunucuya geçiliyor...")
                    task.wait(1)
                    HopToNextServer()
                end
            end)
        else
            HuntStatusLabel:Set("Avcı Durumu: Durduruldu.")
        end
    end
})

HuntTab:CreateInput({
    Name = "Aranacak Minimum Değer Eşiği",
    PlaceholderText = "Örn: 50M, 100M, 1B...",
    Callback = function(text)
        local num = tonumber(string.match(text, "[%d%.]+")) or 0
        if string.find(string.upper(text), "B") then getgenv().HuntMinValue = num * 1e9
        elseif string.find(string.upper(text), "M") then getgenv().HuntMinValue = num * 1e6
        elseif string.find(string.upper(text), "T") then getgenv().HuntMinValue = num * 1e12
        else getgenv().HuntMinValue = num end
        
        Rayfield:Notify({Title = "Hedef Güncellendi", Content = "Alt Limit: " .. text, Duration = 2})
    end
})

HuntTab:CreateDropdown({
    Name = "Özel İsim Filtresi",
    Options = {"Hepsi", "Hexed Pumpkin", "Patchwork Imp", "Astral Jackalope", "Stag"},
    CurrentOption = {"Hepsi"},
    Callback = function(opt)
        getgenv().HuntTargetName = type(opt) == "table" and opt[1] or opt
    end
})

-- ==============================================================================
-- SEKME 2: STEAL PANEL (MEVCUT SUNUCUDAKİ YUMURTALAR)
-- ==============================================================================
local StealTab = Window:CreateTab("Mevcut Sunucu", 4483362458)
StealTab:CreateSection("Bu Sunucudaki Gerçek Yumurtalar")

local CurrentServerLabel = StealTab:CreateLabel("Harita taranıyor...")

local EggButtons = {}
for i = 1, 5 do
    EggButtons[i] = StealTab:CreateButton({
        Name = "[" .. i .. "] Taranıyor...",
        Callback = function()
            local list = ScanCurrentServerRealEggs()
            local target = list[i]
            if target and target.Instance then
                StealTargetEgg(target.Instance)
                Rayfield:Notify({Title = "Işınlanıldı", Content = target.Name .. " çalınıyor!", Duration = 2})
            end
        end
    })
end

local function RefreshCurrentUI()
    local eggs = ScanCurrentServerRealEggs()
    CurrentServerLabel:Set("Sunucudaki Yumurta Sayısı: " .. tostring(#eggs))
    for i = 1, 5 do
        local egg = eggs[i]
        local btn = EggButtons[i]
        if egg then
            btn:Set(string.format("STEAL: %s - %s (%s)", egg.Name, egg.Rate, egg.Mult))
        else
            btn:Set("[" .. i .. "] - Boş")
        end
    end
end

StealTab:CreateButton({
    Name = "🔄 Bu Sunucudaki Yumurtaları Yenile",
    Callback = function()
        RefreshCurrentUI()
    end
})

-- ==============================================================================
-- SEKME 3: ADMIN ARAÇLARI
-- ==============================================================================
local AdminTab = Window:CreateTab("Admin Araçları", 4483362458)
AdminTab:CreateSection("Karakter Ayarları")

AdminTab:CreateSlider({
    Name = "WalkSpeed",
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

AdminTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) getgenv().InfJump = v end
})

UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- BAŞLANGIÇTA ÇALIŞAN OTOMATİK KONTROL
task.spawn(function()
    task.wait(2)
    RefreshCurrentUI()
    
    -- Eğer önceki sunucudan AutoHunt açık geldiyse aramaya devam et
    if getgenv().AutoHunt then
        HuntStatusLabel:Set("Yeni sunucu taranıyor...")
        local eggs = ScanCurrentServerRealEggs()
        local found = nil
        
        for _, egg in ipairs(eggs) do
            local nameMatch = (getgenv().HuntTargetName == "Hepsi") or string.find(string.lower(egg.Name), string.lower(getgenv().HuntTargetName))
            local valMatch = (egg.NumericValue >= getgenv().HuntMinValue)
            if nameMatch and valMatch then
                found = egg
                break
            end
        end
        
        if found then
            HuntStatusLabel:Set("HEDEF BULUNDU: " .. found.Name)
            Rayfield:Notify({Title = "HEDEF BULUNDU!", Content = found.Name .. " çalınıyor!", Duration = 5})
            getgenv().AutoHunt = false
            StealTargetEgg(found.Instance)
        else
            HuntStatusLabel:Set("Hedef yok, sıradaki sunucuya geçiliyor...")
            task.wait(1)
            HopToNextServer()
        end
    end
end)
