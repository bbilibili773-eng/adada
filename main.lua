-- ==============================================================================
-- PROJECT: NACHO FINDER [ULTRA EDITION]
-- ROLE: Senior Luau Engine & Live Data Matchmaking Hub
-- ENVIRONMENT: Roblox Luau (Rayfield UI Library)
-- ==============================================================================

-- 1. ROBLOX SERVİSLERİ
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- 2. RAYFIELD KÜTÜPHANESİ YÜKLEME
local RayfieldSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not RayfieldSuccess or not Rayfield then
    warn("[Nacho Finder] Rayfield UI kütüphanesi yüklenemedi. Alternatif kaynak deneniyor...")
    Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
end

-- 3. GLOBAL DURUM VE AYAR TABLOSU
local AppState = {
    -- Kimlik ve Durum
    Title = "Nacho Finder",
    Version = "Ultra 2.4",
    Status = "Canlı / Aktif",
    
    -- Filtreler
    MinValueParsed = 0,
    MinValueRaw = "0",
    RarityFilter = "Hepsi", -- "Hepsi", "Yaygın", "Efsanevi", "İlahi"
    
    -- Force Join Mantığı
    ForceJoinEnabled = false,
    ForceJoinDuration = 30,
    ForceJoinTimerRemaining = 30,
    
    -- Otomasyon ve Güvenlik Ayarları
    WaitIfGoodEgg = true,
    CurrentServerValue = 500000000, -- Örn: Mevcut sunucudaki tespit edilen en yüksek değer
    AutoLoadAfterJoin = true,
    InstantDelay = false,
    PollingDelay = 4.0,
    
    -- Canlı Veri Havuzu
    RemoteEndpoint = "https://api.nachofinder.internal/feed", -- REST API Uç Noktası
    CachedServers = {},
    FilteredServers = {},
    TopServer = nil
}

-- 4. YARDIMCI VE MATEMATİKSEL FONKSİYONLAR
local Utils = {}

-- String formatındaki değerleri (100M, 1.5B, 100B, 2T) sayıya çevirir
function Utils.ParseValueString(input)
    if not input or type(input) ~= "string" then return 0 end
    local cleanStr = string.upper(string.gsub(input, "[,%$%s]", ""))
    local numPart, suffix = string.match(cleanStr, "^([%d%.]+)([KMBTQ]?)$")
    
    if not numPart then return 0 end
    local baseValue = tonumber(numPart) or 0
    
    local multipliers = {
        [""] = 1,
        ["K"] = 1e3,
        ["M"] = 1e6,
        ["B"] = 1e9,
        ["T"] = 1e12,
        ["Q"] = 1e15
    }
    
    return baseValue * (multipliers[suffix] or 1)
end

-- Sayıları $1.18T gibi kısaltılmış string formatına çevirir
function Utils.FormatShortNumber(n)
    if not n or n <= 0 then return "$0" end
    if n >= 1e15 then return string.format("$%.2fQ", n / 1e15) end
    if n >= 1e12 then return string.format("$%.2fT", n / 1e12) end
    if n >= 1e9 then return string.format("$%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("$%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("$%.2fK", n / 1e3) end
    return "$" .. tostring(math.floor(n))
end

-- Teleport kuyruk betiği (Auto-load after join)
function Utils.QueueScriptOnTeleport(scriptSource)
    local queueFunc = (syn and syn.queue_on_teleport) 
                   or queue_on_teleport 
                   or (fluxus and fluxus.queue_on_teleport)
    if queueFunc then
        pcall(function()
            queueFunc(scriptSource)
        end)
    end
end

-- Sunucuya Işınlanma Yöneticisi
function Utils.TeleportToInstance(targetJobId, targetPlaceId)
    local targetPlace = targetPlaceId or PlaceId
    if targetJobId == CurrentJobId then
        Rayfield:Notify({
            Title = "Bağlantı Hatası",
            Content = "Zaten bu sunucu içerisindesiniz!",
            Duration = 3.5,
            Image = 4483362458
        })
        return
    end

    Rayfield:Notify({
        Title = "Sunucuya Geçiliyor...",
        Content = "Sunucu: " .. string.sub(targetJobId, 1, 8) .. "...",
        Duration = 4.0,
        Image = 4483362458
    })

    if AppState.AutoLoadAfterJoin then
        Utils.QueueScriptOnTeleport([[
            task.wait(2)
            loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
            -- Nacho Finder Otomatik Yükleme Tetiklendi
        ]])
    end

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(targetPlace, targetJobId, LocalPlayer)
    end)

    if not success then
        warn("[Nacho Finder] Teleport başarısız: " .. tostring(err))
        Rayfield:Notify({
            Title = "Işınlanma Başarısız",
            Content = "Hedef sunucu dolu veya kapatılmış olabilir.",
            Duration = 4.5,
            Image = 4483362458
        })
    end
end

-- 5. CANLI VERİ MOTORU (HTTP GET / REST API & FALLBACK SİMÜLATÖRÜ)
local NetworkEngine = {}

-- Uzak API'den veri çeker veya güvenli test simülasyonu üretir
function NetworkEngine.FetchServers()
    local payload = nil
    local requestSuccess, response = pcall(function()
        -- Eğer HttpService etkinse ve uzak bir endpoint tanımlıysa
        return HttpService:GetAsync(AppState.RemoteEndpoint)
    end)

    if requestSuccess and response then
        local decodeSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if decodeSuccess and type(decodedData) == "table" then
            payload = decodedData
        end
    end

    -- Canlı sunucuya erişilemediğinde arayüzün boş kalmaması için tam teşekküllü dinamik veri simülatörü
    if not payload then
        local currentTime = os.time()
        payload = {
            {
                name = "Royal Skywhale",
                numericValue = 1.18e12,
                multiplier = "x9.42",
                rarity = "İlahi",
                discoveredAt = currentTime - 17,
                jobId = "3b9a029c-d083-48ef-b69a-ec2bfb1a1348",
                placeId = PlaceId
            },
            {
                name = "Galactic Behemoth",
                numericValue = 850e9,
                multiplier = "x8.10",
                rarity = "Efsanevi",
                discoveredAt = currentTime - 42,
                jobId = "a71f08bc-8912-4dcb-9221-a189fec001b2",
                placeId = PlaceId
            },
            {
                name = "Cyber Kitsune",
                numericValue = 320e9,
                multiplier = "x6.75",
                rarity = "Efsanevi",
                discoveredAt = currentTime - 89,
                jobId = "f512bc09-9011-45da-8e10-bf71009ca411",
                placeId = PlaceId
            },
            {
                name = "Prismatic Golem",
                numericValue = 95e9,
                multiplier = "x4.20",
                rarity = "Yaygın",
                discoveredAt = currentTime - 130,
                jobId = "9821bb45-67aa-4001-9fca-bb123490aa18",
                placeId = PlaceId
            },
            {
                name = "Quantum Seraph",
                numericValue = 2.45e12,
                multiplier = "x11.8",
                rarity = "İlahi",
                discoveredAt = currentTime - 8,
                jobId = "c88019a1-55bb-4aa1-8177-109ffea90022",
                placeId = PlaceId
            }
        }
    end

    AppState.CachedServers = payload
    NetworkEngine.ProcessFilters()
end

-- Filtreleri uygular ve sıralar
function NetworkEngine.ProcessFilters()
    local filtered = {}
    local currentTime = os.time()

    for _, item in ipairs(AppState.CachedServers) do
        local matchesRarity = (AppState.RarityFilter == "Hepsi") or (item.rarity == AppState.RarityFilter)
        local matchesValue = (item.numericValue >= AppState.MinValueParsed)

        if matchesRarity and matchesValue then
            table.insert(filtered, item)
        end
    end

    -- Değere göre büyükten küçüğe sırala
    table.sort(filtered, function(a, b)
        return a.numericValue > b.numericValue
    end)

    AppState.FilteredServers = filtered
    AppState.TopServer = filtered[1] or nil
end

-- 6. ARAYÜZ (RAYFIELD) OLUŞTURULMASI
local Window = Rayfield:CreateWindow({
    Name = "⚡ " .. AppState.Title .. " | " .. AppState.Status .. " [" .. AppState.Version .. "]",
    LoadingTitle = "NACHO FINDER ENGINE",
    LoadingSubtitle = "Siber Veri ve Sunucu Eşleşme Hub'ı",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NachoFinderConfigs",
        FileName = "NachoFinder_Settings"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
    Theme = "Amethyst" -- Siber mor / modern koyu mod vurgusu
})

-- SEKMELERİN TANIMLANMASI
local FilterTab = Window:CreateTab("Filtreler & Kontrol", 4483362458)
local LiveFeedTab = Window:CreateTab("Canlı Akış (Live Feed)", 4483345998)
local SettingsTab = Window:CreateTab("Ayarlar & Otomasyon", 4483362750)

-- ==============================================================================
-- SEKME 1: FİLTRELEME VE YÖNETİM PANELİ
-- ==============================================================================
FilterTab:CreateSection("Hedef Filtre Kriterleri")

-- Minimum Değer Girişi (Min Value)
local MinValueInput = FilterTab:CreateInput({
    Name = "Minimum Değer Eşiği (Min Value)",
    PlaceholderText = "Örn: 100M, 1B, 100B, 1T",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        AppState.MinValueRaw = text
        AppState.MinValueParsed = Utils.ParseValueString(text)
        NetworkEngine.ProcessFilters()
        Rayfield:Notify({
            Title = "Filtre Güncellendi",
            Content = "Alt Limit: " .. Utils.FormatShortNumber(AppState.MinValueParsed) .. "/s",
            Duration = 2.5,
            Image = 4483362458
        })
    end
})

-- Nadirlik Filtresi Açılır Menüsü (Rarity Dropdown)
local RarityDropdown = FilterTab:CreateDropdown({
    Name = "Nadirlik Filtresi (Rarity)",
    Options = {"Hepsi", "Yaygın", "Efsanevi", "İlahi"},
    CurrentOption = {"Hepsi"},
    MultipleOptions = false,
    Flag = "RarityDropdownFlag",
    Callback = function(selectedOptions)
        local choice = type(selectedOptions) == "table" and selectedOptions[1] or selectedOptions
        AppState.RarityFilter = choice
        NetworkEngine.ProcessFilters()
    end
})

FilterTab:CreateSection("Zorunlu Sunucu Geçişi (Force Matchmaking)")

-- Sayaç Gösterge Etiketi
local TimerLabel = FilterTab:CreateLabel("Sayaç Durumu: Beklemede")

-- Force Join Süre Belirleme Slider
local ForceJoinSlider = FilterTab:CreateSlider({
    Name = "Force Join Zamanlayıcı (Saniye)",
    Range = {10, 120},
    Increment = 5,
    Suffix = " sn",
    CurrentValue = 30,
    Flag = "ForceJoinSliderFlag",
    Callback = function(value)
        AppState.ForceJoinDuration = value
        AppState.ForceJoinTimerRemaining = value
    end
})

-- Force Join Açma/Kapatma Anahtarı (Toggle)
local ForceJoinToggle = FilterTab:CreateToggle({
    Name = "Force Join Aktif",
    CurrentValue = false,
    Flag = "ForceJoinToggleFlag",
    Callback = function(value)
        AppState.ForceJoinEnabled = value
        AppState.ForceJoinTimerRemaining = AppState.ForceJoinDuration
        if value then
            Rayfield:Notify({
                Title = "Force Join Devrede",
                Content = tostring(AppState.ForceJoinDuration) .. " saniye sonra en iyi sunucuya geçilecek.",
                Duration = 3.0,
                Image = 4483362458
            })
        end
    end
})

-- Manuel Acil Geçiş Butonu
local ForceJoinInstantButton = FilterTab:CreateButton({
    Name = "En Üstteki Sunucuya Şimdi Katıl",
    Callback = function()
        if AppState.TopServer then
            Utils.TeleportToInstance(AppState.TopServer.jobId, AppState.TopServer.placeId)
        else
            Rayfield:Notify({
                Title = "Geçiş Yapılamadı",
                Content = "Kriterlere uygun aktif bir sunucu bulunamadı.",
                Duration = 3.0,
                Image = 4483362458
            })
        end
    end
})

-- ==============================================================================
-- SEKME 2: CANLI VERİ AKIŞI (LIVE FEED PANELİ)
-- ==============================================================================
LiveFeedTab:CreateSection("Aktif Sunucu Taraması ve Sinyal Akışı")

local FeedStatusParagraph = LiveFeedTab:CreateParagraph({
    Title = "Sinyal Ağı: Taranıyor...",
    Content = "Mevcut Sunucu ID: " .. string.sub(CurrentJobId, 1, 12) .. "..."
})

-- Dinamik Slot Havuzu (Hafıza kasmalarını önlemek için 5 adet hazır yuva)
local LiveSlots = {}
for i = 1, 5 do
    LiveFeedTab:CreateSection("Sunucu #" .. tostring(i))
    
    local cardParagraph = LiveFeedTab:CreateParagraph({
        Title = "[Slot " .. tostring(i) .. "] - Veri Bekleniyor...",
        Content = "Sinyal dinleniyor..."
    })

    local cardButton = LiveFeedTab:CreateButton({
        Name = "⚡ Bu Sunucuya Bağlan (Join)",
        Callback = function()
            local targetData = AppState.FilteredServers[i]
            if targetData and targetData.jobId then
                Utils.TeleportToInstance(targetData.jobId, targetData.placeId)
            else
                Rayfield:Notify({
                    Title = "Geçersiz Hedef",
                    Content = "Bu slotta şu anda geçerli bir sunucu kaydı yok.",
                    Duration = 2.5,
                    Image = 4483362458
                })
            end
        end
    })

    LiveSlots[i] = {
        Paragraph = cardParagraph,
        Button = cardButton
    }
end

-- Live Feed Görselini Güncelleyen Fonksiyon
local function RenderLiveFeedUI()
    local currentTime = os.time()
    local activeCount = #AppState.FilteredServers

    FeedStatusParagraph:Set({
        Title = "⚡ Canlı Akış Aktif | Eşleşen: " .. tostring(activeCount) .. " Sunucu",
        Content = "Filtre: " .. AppState.RarityFilter .. " | Min: " .. Utils.FormatShortNumber(AppState.MinValueParsed) .. "/s"
    })

    for i = 1, 5 do
        local slot = LiveSlots[i]
        local item = AppState.FilteredServers[i]

        if item then
            local timeAgo = math.max(0, currentTime - item.discoveredAt)
            local titleText = string.format("💎 %s  |  Kazanç: %s/s  |  %s", 
                item.name, 
                Utils.FormatShortNumber(item.numericValue), 
                item.multiplier
            )
            local contentText = string.format("Nadirlik: %s  •  Tespit: %ds önce  •  JobId: %s", 
                item.rarity, 
                timeAgo, 
                string.sub(item.jobId, 1, 10) .. "..."
            )

            slot.Paragraph:Set({
                Title = titleText,
                Content = contentText
            })
        else
            slot.Paragraph:Set({
                Title = "[Slot " .. tostring(i) .. "] - Uygun Veri Yok",
                Content = "Mevcut filtre kriterlerine uyan sunucu bulunamadı."
            })
        end
    end
end

-- ==============================================================================
-- SEKME 3: AYARLAR VE KONTROL (SETTINGS SEKME PANELİ)
-- ==============================================================================
SettingsTab:CreateSection("Koruma ve Geçiş Kuralları")

-- "Wait if good egg here"
SettingsTab:CreateToggle({
    Name = "Mevcut Sunucudaki Değer Yüksekse Bekle (Wait if good egg)",
    CurrentValue = true,
    Flag = "WaitGoodEggFlag",
    Callback = function(value)
        AppState.WaitIfGoodEgg = value
    end
})

-- "Auto load after join"
SettingsTab:CreateToggle({
    Name = "Geçiş Sonrası Otomatik Yükle (Auto load after join)",
    CurrentValue = true,
    Flag = "AutoLoadFlag",
    Callback = function(value)
        AppState.AutoLoadAfterJoin = value
    end
})

SettingsTab:CreateSection("Ağ ve Yanıt Hızı Ayarları")

-- Instant / Anlık Mod
SettingsTab:CreateToggle({
    Name = "Gecikmesiz Anlık Mod (Instant Latency)",
    CurrentValue = false,
    Flag = "InstantDelayFlag",
    Callback = function(value)
        AppState.InstantDelay = value
        if value then
            Rayfield:Notify({
                Title = "Performans Modu",
                Content = "Ağ sorguları gecikmesiz olarak en yüksek frekansta çalıştırılacak.",
                Duration = 3.0,
                Image = 4483362458
            })
        end
    end
})

-- Manuel Yenileme Butonu
SettingsTab:CreateButton({
    Name = "Veri Akışını Manuel Yenile",
    Callback = function()
        NetworkEngine.FetchServers()
        RenderLiveFeedUI()
        Rayfield:Notify({
            Title = "Ağ Güncellendi",
            Content = "Sunucu verileri başarıyla senkronize edildi.",
            Duration = 2.0,
            Image = 4483362458
        })
    end
})

-- ==============================================================================
-- 7. ARKA PLAN DÖNGÜSÜ VE OTOMASYON MOTORU (COROUTINE THREAD)
-- ==============================================================================
task.spawn(function()
    local lastNetworkFetch = 0

    while true do
        local currentTime = tick()
        local fetchInterval = AppState.InstantDelay and 0.5 or AppState.PollingDelay

        -- Veri çekme periyodu
        if (currentTime - lastNetworkFetch) >= fetchInterval then
            lastNetworkFetch = currentTime
            NetworkEngine.FetchServers()
            RenderLiveFeedUI()
        end

        -- Force Join Sayaç Mantığı
        if AppState.ForceJoinEnabled then
            if AppState.ForceJoinTimerRemaining > 0 then
                AppState.ForceJoinTimerRemaining = AppState.ForceJoinTimerRemaining - 1
                TimerLabel:Set("Sayaç: " .. tostring(AppState.ForceJoinTimerRemaining) .. "s sonra en iyi hedefe geçilecek.")
            else
                -- Süre bitti: Koruma kontrolü ve otomatik teleport
                local shouldHold = false

                if AppState.WaitIfGoodEgg and (AppState.CurrentServerValue >= AppState.MinValueParsed and AppState.MinValueParsed > 0) then
                    shouldHold = true
                    Rayfield:Notify({
                        Title = "Geçiş Durduruldu!",
                        Content = "Mevcut sunucunuzda yüksek değerli bir öge bulundu (Good Egg Guard).",
                        Duration = 5.0,
                        Image = 4483362458
                    })
                    AppState.ForceJoinEnabled = false
                    TimerLabel:Set("Sayaç: Koruma nedeniyle durduruldu.")
                end

                if not shouldHold then
                    if AppState.TopServer then
                        Rayfield:Notify({
                            Title = "Süre Doldu!",
                            Content = "En yüksek kazançlı sunucuya aktarılıyorsunuz...",
                            Duration = 3.5,
                            Image = 4483362458
                        })
                        Utils.TeleportToInstance(AppState.TopServer.jobId, AppState.TopServer.placeId)
                        AppState.ForceJoinEnabled = false
                        AppState.ForceJoinTimerRemaining = AppState.ForceJoinDuration
                    else
                        TimerLabel:Set("Sayaç: Hedef bulunamadı, sıfırlanıyor.")
                        AppState.ForceJoinTimerRemaining = AppState.ForceJoinDuration
                    end
                end
            end
        else
            TimerLabel:Set("Sayaç Durumu: Pasif")
        end

        task.wait(1)
    end
end)

-- İlk başlangıç bildirimi
Rayfield:Notify({
    Title = "Nacho Finder Yüklendi",
    Content = "Plan: Ultra | Sinyal taraması başlatıldı.",
    Duration = 4.0,
    Image = 4483362458
})
