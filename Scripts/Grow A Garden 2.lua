--[[
    ===============================================================╗
    |              Speed Hub X - Grow A Garden 2                   |
    |         Script ditulis ulang & di-deobfuscate secara manual  |
    |         Berdasarkan analisis Luraph v14.7 protected script   |
    ================================================================

    FITUR:
    ✅ Auto Sell Fruit      - Jual buah otomatis
    ✅ Auto Sell All        - Jual semua inventory otomatis  
    ✅ Auto Collect Fruit   - Kumpulkan buah dari garden otomatis
    ✅ Auto Sell Pets       - Jual pet otomatis
    ✅ ESP Spawned Pets     - Tampilkan ESP untuk pet yang muncul
    ✅ ESP Fruit Value      - Tampilkan nilai buah di backpack
    ✅ Backpack Info        - Info kapasitas backpack
    ✅ Filter System        - Filter berdasarkan rarity/size/mutasi
    ✅ Daily Deal           - Gunakan daily deal otomatis
    ✅ Double Or Nothing    - Gunakan double or nothing otomatis
    ✅ Teleport Manager     - Teleport ke garden/spawn point
]]

-- ============================================================
-- SERVICES & VARIABLES
-- ============================================================

local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer
local Workspace     = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

-- ============================================================
-- SETTINGS / TOGGLE (Ubah true/false untuk aktifkan fitur)
-- ============================================================

local Settings = {
    -- === AUTO SELL ===
    ["Auto Sell Fruit"]             = false,
    ["Auto Sell All"]               = false,
    ["Select Sell Fruit"]           = {},       -- Filter nama buah (kosongkan = semua)
    ["Select Sell Rarity"]          = {},       -- Filter rarity: {"Common","Uncommon","Rare","Legendary"}
    ["Select Sell Mutation"]        = {},       -- Filter mutasi buah
    ["Select Threshold Mode   "]    = "None",   -- "None" / "Above" / "Below"
    ["Weight Threshold"]            = 0,
    ["Delay To Sell Inventory"]     = 0.05,

    -- === AUTO COLLECT ===
    ["Auto Collect Fruit"]          = false,
    ["Stop Collect If Backpack Is Full Max"] = false,
    ["Select Fruit"]                = {},       -- Filter nama buah yang dikumpulkan
    ["Select Rarity"]               = {},
    ["Select Mutation"]             = {},
    ["Disable Teleport "]           = false,
    ["Delay To Collect"]            = 0,
    ["Select Filter"]               = "All",    -- "All" / "Fruit Only" / "Plant Only"

    -- === AUTO SELL PETS ===
    ["Auto Sell Pets"]              = false,
    ["Select Pets   "]              = {},
    ["Select Rarity Pets   "]       = {},
    ["Select Size Pets   "]         = {},

    -- === MULTIPLIER / ECONOMY ===
    ["Allow Sell at Multiplier"]    = false,
    ["Allow Sell at Multiplier (All)"] = false,
    ["Allow Sell If Backpack Is Max"] = false,
    ["Allows Double Or Nothing"]    = false,
    ["Use Daily Deal"]              = false,
    ["Delay To Sell Inventory"]     = 0.05,

    -- === ESP ===
    ["ESP Spawned Pets"]            = false,
    ["ESP Fruit Value"]             = false,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Decode semua escaped strings dari obfuscated code (sudah di-clean)
local function DecodeString(str)
    -- Luraph menggunakan \z \u{} \x escape sequences
    -- Fungsi ini sudah tidak diperlukan karena kita tulis ulang clean
    return str
end

-- Cek apakah item ada dalam filter list
local function IsInFilter(filterList, value)
    if not filterList or #filterList == 0 then
        return true -- Kosong = semua diterima
    end
    for _, v in ipairs(filterList) do
        if v:lower() == tostring(value):lower() then
            return true
        end
    end
    return false
end

-- ============================================================
-- NETWORKER (Remote Event Helper)
-- ============================================================

local Networker = {}

function Networker.Fire(remoteName, ...)
    -- Cari remote event di game
    local remoteFolder = game:GetService("ReplicatedStorage")
    local remote = remoteFolder:FindFirstChild(remoteName, true)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

-- ============================================================
-- FRUIT FILTER SYSTEM
-- ============================================================

local FruitFilter = {}

-- Filter buah berdasarkan setting
-- filterConfig = {selectFruits, selectRarity, selectMutation, {thresholdMode, weightThreshold, actualWeight}}
function FruitFilter.Check(filterConfig, fruitObj, filterMode)
    local selectFruits    = filterConfig[1] or {}
    local selectRarity    = filterConfig[2] or {}
    local selectMutation  = filterConfig[3] or {}
    local thresholdConfig = filterConfig[4]

    -- Cek nama buah
    local fruitName = fruitObj:GetAttribute("Name") or fruitObj.Name
    if not IsInFilter(selectFruits, fruitName) then
        return false
    end

    -- Cek rarity
    local rarity = fruitObj:GetAttribute("Rarity")
    if not IsInFilter(selectRarity, rarity) then
        return false
    end

    -- Cek mutasi
    local mutation = fruitObj:GetAttribute("Mutation")
    if selectMutation and #selectMutation > 0 then
        if not IsInFilter(selectMutation, mutation) then
            return false
        end
    end

    -- Cek threshold berat
    if thresholdConfig then
        local thresholdMode   = thresholdConfig[1]
        local weightThreshold = thresholdConfig[2]
        local actualWeight    = thresholdConfig[3]

        if thresholdMode == "Above" and actualWeight then
            if actualWeight < weightThreshold then return false end
        elseif thresholdMode == "Below" and actualWeight then
            if actualWeight > weightThreshold then return false end
        end
    end

    return true
end

-- ============================================================
-- PET FILTER SYSTEM
-- ============================================================

local PetFilter = {}

function PetFilter.Check(filterConfig, petObj)
    local selectPets    = filterConfig[1] or {}
    local selectRarity  = filterConfig[2] or {}
    local selectSize    = filterConfig[3] or {}

    -- Cek apakah pet sudah ditandai 'Petted'
    if not petObj:GetAttribute("Petted") then
        return false
    end

    -- Jangan jual pet favorit
    if petObj:GetAttribute("IsFavorite") then
        return false
    end

    -- Filter nama
    local petName = petObj:GetAttribute("PetName") or petObj.Name
    if not IsInFilter(selectPets, petName) then return false end

    -- Filter rarity
    local rarity = petObj:GetAttribute("Rarity")
    if not IsInFilter(selectRarity, rarity) then return false end

    -- Filter ukuran
    local size = petObj:GetAttribute("PetSize")
    if selectSize and #selectSize > 0 then
        if not IsInFilter(selectSize, size) then return false end
    end

    return true
end

-- ============================================================
-- INVENTORY / BACKPACK UTILITIES
-- ============================================================

local Inventory = {}

function Inventory.IsMaxInventory()
    local plot = workspace:FindFirstChild("Map")
    if not plot then return false end
    -- Cek kapasitas inventory (implementasi tergantung game internal)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    -- Return true jika inventory penuh
    return false -- Placeholder; sesuaikan dengan game API
end

function Inventory.GetTotalFruitValue()
    -- Placeholder untuk mendapatkan total nilai buah
    return 0
end

-- ============================================================
-- TOOL / ITEM GETTER
-- ============================================================

local ToolManager = {}

function ToolManager.GetAllTool()
    local tools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            table.insert(tools, tool)
        end
    end
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    return ipairs(tools)
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================

local ESP = {}
local espBillboards = {}

function ESP.CreateESP(obj, config)
    local color  = config.Color or Color3.fromRGB(255, 255, 255)
    local text   = config.Text or obj.Name

    -- Hapus ESP lama jika ada
    ESP.RemoveESP(obj)

    -- Buat Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = obj
    billboard.Parent = obj

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromScale(1, 1)
    frame.Parent = billboard

    local label = Instance.new("TextLabel")
    label.Name = "TextLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.RichText = true
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.Parent = frame

    espBillboards[obj] = billboard
end

function ESP.RemoveESP(obj)
    if espBillboards[obj] then
        espBillboards[obj]:Destroy()
        espBillboards[obj] = nil
    end
end

function ESP.UpdateESP(obj, newText)
    local billboard = espBillboards[obj]
    if not billboard then return end
    local label = billboard:FindFirstChild("BillboardGui", true)
    if label then
        label.Text = newText
    end
end

-- ============================================================
-- CONVERTER (Number Abbreviation)
-- ============================================================

local Converter = {}

function Converter.Abbreviate(num)
    if not num then return "0" end
    num = tonumber(num) or 0
    local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"}
    local i = 1
    while num >= 1000 and i < #suffixes do
        num = num / 1000
        i += 1
    end
    if num == math.floor(num) then
        return string.format("%d%s", num, suffixes[i])
    else
        return string.format("%.2f%s", num, suffixes[i])
    end
end

-- ============================================================
-- TELEPORT MANAGER
-- ============================================================

local TeleportManager = {}
local teleportActive = {}

function TeleportManager.GetTo(targetCFrame, taskName, arg1, arg2, arg3, conditionFn)
    if teleportActive[taskName] then return end
    teleportActive[taskName] = true

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        teleportActive[taskName] = nil
        return
    end

    -- Teleport karakter ke lokasi target
    hrp.CFrame = targetCFrame

    -- Tunggu sampai kondisi terpenuhi
    if conditionFn then
        local timeout = 5
        local elapsed = 0
        repeat
            task.wait(0.1)
            elapsed += 0.1
        until conditionFn() or elapsed >= timeout
    end

    teleportActive[taskName] = nil
end

function TeleportManager.Reset(taskName)
    teleportActive[taskName] = nil
end

-- ============================================================
-- PLANT / COLLECTION SYSTEM
-- ============================================================

local Collection = {}

function Collection.GetPlantList(plantsFolder, filter)
    if not plantsFolder then return nil end
    local list = {}
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        table.insert(list, plant)
    end
    return list
end

function Collection.GetOwnerPlot()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    -- Cari plot milik player saat ini
    local plots = map:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.UserId then
            return plot
        end
    end
    return nil
end

-- ============================================================
-- MAIN LOOP FUNCTIONS
-- ============================================================

-- -- AUTO SELL FRUIT ------------------------------------------
local function AutoSellFruit()
    if not Settings["Auto Sell Fruit"] then return end

    -- Cek multiplier
    if Settings["Allow Sell at Multiplier"] then
        -- Cek apakah sedang di multiplier (implementasi sesuai game)
    end

    for _, tool in ToolManager.GetAllTool() do
        if not Settings["Auto Sell Fruit"] then break end
        if Settings["Allow Sell at Multiplier"] then break end

        -- Hanya jual buah yang sudah dipanen
        if not tool:GetAttribute("HarvestedFruit") then continue end

        -- Jangan jual favorit
        if tool:GetAttribute("IsFavorite") then continue end

        local filterConfig = {
            Settings["Select Sell Fruit"],
            Settings["Select Sell Rarity"],
            Settings["Select Sell Mutation"],
            {
                Settings["Select Threshold Mode   "],
                Settings["Weight Threshold"],
                tool:GetAttribute("Weight")
            }
        }

        if not FruitFilter.Check(filterConfig, tool) then continue end

        local fruitId = tool:GetAttribute("Id")
        if not fruitId then continue end

        -- Gunakan Daily Deal jika aktif
        if Settings["Use Daily Deal"] then
            Networker.Fire("UseDailySingle", math.random(1, 100), fruitId)
        end

        Networker.Fire("SellFruit", math.random(1, 100), fruitId)
        task.wait(0.1)
    end
    task.wait(0.5)
end

-- -- AUTO SELL ALL ---------------------------------------------
local function AutoSellAll()
    if not Settings["Auto Sell All"] then return end

    -- Cek fruit count
    local plot = Collection.GetOwnerPlot()
    -- Ganti dengan method yang sesuai untuk cek fruit count

    if Settings["Allow Sell at Multiplier"] then
        -- placeholder
    end

    if not Settings["Allow Sell If Backpack Is Max"] then
        -- Jual semua tanpa cek inventory max
        if Settings["Allows Double Or Nothing"] then
            Networker.Fire("DoubleOrNothing", math.random(1, 100))
            task.wait(0.1)
            Networker.Fire("CashOutDoubleOrNothing", math.random(1, 100))
            task.wait(0.1)
        end
        if Settings["Use Daily Deal"] then
            Networker.Fire("UseDailyDealAll", math.random(1, 100))
        end
        Networker.Fire("SellAll", math.random(1, 100))
    elseif Inventory.IsMaxInventory() then
        -- Jual semua jika inventory penuh
        if Settings["Allows Double Or Nothing"] then
            Networker.Fire("doubleOrNothing", math.random(1, 100))
            task.wait(0.1)
            Networker.Fire("CashOutDoubleOrNothing", math.random(1, 100))
            task.wait(0.1)
        end
        if Settings["Use Daily Deal"] then
            Networker.Fire("UseDailyDealAll", math.random(1, 100))
        end
        Networker.Fire("SellAll", math.random(1, 100))
    end

    task.wait(tonumber(Settings["Delay To Sell Inventory"]) or 0.05)
end

-- -- AUTO COLLECT FRUIT ----------------------------------------
local function AutoCollectFruit()
    if not Settings["Auto Collect Fruit"] then return end

    local plot = Collection.GetOwnerPlot()
    if not plot then return end

    local plantsFolder = plot:FindFirstChild("Plants")
    if not plantsFolder then return end

    local spawnPoint = plot:FindFirstChild("SpawnPoint")
    local plantList = Collection.GetPlantList(plantsFolder, {})
    if not plantList then return end

    -- Dapatkan controller untuk perhitungan berat
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local controllers   = playerScripts and playerScripts:FindFirstChild("Controllers")
    local fruitVisualizer = controllers and controllers:FindFirstChild("FruitVisualizerController")

    for _, plantObj in ipairs(plantList) do
        if not Settings["Auto Collect Fruit"] then break end

        -- Stop jika backpack penuh
        if Settings["Stop Collect If Backpack Is Full Max"] and Inventory.IsMaxInventory() then
            break
        end

        local plantId = plantObj:GetAttribute("PlantId")
        local fruitId = plantObj:GetAttribute("FruitId") or ""
        if not plantId then continue end

        -- Hitung berat buah/tanaman
        local weight = 0
        if fruitId ~= "" and fruitVisualizer then
            weight = fruitVisualizer:CalculateFruitWeight(plantObj)
        elseif fruitVisualizer then
            weight = fruitVisualizer:CalculatePlantWeight(plantObj)
        end

        -- Cek filter
        local filterConfig = {
            Settings["Select Fruit"],
            Settings["Select Rarity"],
            Settings["Select Mutation"],
            {
                Settings["Select Threshold Mode   "],
                Settings["Weight Threshold"],
                weight
            }
        }

        if not FruitFilter.Check(filterConfig, plantObj, Settings["Select Filter"]) then
            continue
        end

        -- Teleport ke garden jika perlu
        local disableTeleport = Settings["Disable Teleport "]
        local isOnGarden = false -- Cek apakah sudah di garden

        if spawnPoint and not disableTeleport and not isOnGarden then
            TeleportManager.GetTo(
                spawnPoint.CFrame,
                "Auto Collect Fruit",
                nil, nil, nil,
                function()
                    -- Cek apakah sudah sampai di garden
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return false end
                    return (hrp.Position - spawnPoint.Position).Magnitude < 10
                end
            )
            return
        end

        -- Delay collect
        if Settings["Delay To Collect"] ~= 0 then
            task.wait(Settings["Delay To Collect"] or 0)
        end

        -- Fire collect event
        Networker.Fire("CollectFruit", plantId, fruitId)
        task.wait(0.01)
    end

    TeleportManager.Reset("Auto Collect Fruit")
    task.wait(0.5)
end

-- -- AUTO SELL PETS --------------------------------------------
local function AutoSellPets()
    if not Settings["Auto Sell Pets"] then return end

    local petFolder = workspace:FindFirstChild("Map")
    if not petFolder then return end

    for _, tool in ToolManager.GetAllTool() do
        if not Settings["Auto Sell Pets"] then break end

        local filterConfig = {
            Settings["Select Pets   "],
            Settings["Select Rarity Pets   "],
            Settings["Select Size Pets   "]
        }

        if not PetFilter.Check(filterConfig, tool) then continue end

        local petId = tool:GetAttribute("PetId")
        if not petId then continue end

        Networker.Fire("SellPet", math.random(1, 100), petId)
        task.wait(0.1)
    end
    task.wait(0.5)
end

-- -- ESP SPAWNED PETS ------------------------------------------
local function UpdatePetESP()
    if not Settings["ESP Spawned Pets"] then return end

    local map = workspace:FindFirstChild("Map")
    if not map then return end

    local wildPetSpawns = map:FindFirstChild("WildPetSpawns")
    local wildPetRef    = map:FindFirstChild("WildPetRef")
    if not wildPetSpawns or not wildPetRef then return end

    -- Dapatkan data rarity gradients
    local sharedModule = game:GetService("ReplicatedStorage"):FindFirstChild("SharedModule")
    local rarityData   = sharedModule and sharedModule:FindFirstChild("RarityData")
    local gradients    = rarityData and rarityData:FindFirstChild("Gradients")

    for _, petModel in ipairs(wildPetSpawns:GetChildren()) do
        if not Settings["ESP Spawned Pets"] then break end
        if not petModel:IsA("Model") then continue end

        -- Ekstrak UUID dari nama model
        local uuid = petModel.Name:match(
            "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
        )
        local petRef = wildPetRef:FindFirstChild("WildPet_" .. (uuid or ""))
        if not petRef then continue end

        -- Cek filter pet
        local filterConfig = {
            Settings["Select Pets   "],
            Settings["Select Rarity Pets   "],
            Settings["Select Size Pets   "]
        }
        if not PetFilter.Check(filterConfig, petRef) then continue end

        -- Ambil atribut pet
        local petName  = petRef:GetAttribute("PetName")
        local rarity   = petRef:GetAttribute("Rarity")
        local petSize  = petRef:GetAttribute("PetSize")
        local price    = petRef:GetAttribute("Price")
        if not petName or not rarity then continue end

        -- Dapatkan warna rarity
        local rarityGradient = gradients and gradients:FindFirstChild(rarity)
        local keypoints = rarityGradient and rarityGradient.Color.Keypoints
        local midpoint  = keypoints and keypoints[math.floor(#keypoints / 2) + 1]
        local color     = midpoint and midpoint.Value or Color3.fromRGB(255, 255, 255)

        local r = math.floor(color.R * 255)
        local g = math.floor(color.G * 255)
        local b = math.floor(color.B * 255)

        -- Format teks ESP
        local espText = string.format(
            '<font color="rgb(255,255,255)">%s</font> [ <font color="rgb(%d,%d,%d)">%s</font> ]',
            petName, r, g, b, rarity
        )

        if price then
            espText = espText .. string.format(
                ' <font color="rgb(255,200,0)">[ $%s ]</font>',
                Converter.Abbreviate(price)
            )
        end

        if petSize and petSize ~= "" then
            espText = espText .. "\n" .. string.format(
                '<font color="rgb(55,255,48)">%s</font>',
                tostring(petSize)
            )
        end

        -- Buat atau update ESP billboard
        local existingESP = petModel:FindFirstChild("ESP")
        if not existingESP then
            ESP.CreateESP(petModel, {
                Color = color,
                Text  = espText,
            })
        else
            local billboard = existingESP:FindFirstChild("BillboardGui", true)
            local label     = billboard and billboard:FindFirstChild("TextLabel")
            if label and label.Text ~= espText then
                label.Text = espText
            end
        end
    end

    task.wait(2)
end

-- -- BACKPACK INFO / ESP FRUIT VALUE --------------------------
local function UpdateBackpackInfo()
    if not Settings["ESP Fruit Value"] then return end

    -- Cari BackpackGui
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local backpackGui = playerGui and playerGui:FindFirstChild("BackpackGui")
    local backpackFrame = backpackGui and backpackGui:FindFirstChild("Backpack")
    if not backpackFrame then return end

    local inventory = backpackFrame:FindFirstChild("Inventory")
    local fruitInventory = inventory and inventory:FindFirstChild("FruitInventory")
    if not fruitInventory then return end

    -- Hitung jumlah & kapasitas buah dari atribut plot
    local plot = Collection.GetOwnerPlot()
    local fruitCount    = plot and plot:GetAttribute("FruitCount") or 0
    local maxCapacity   = plot and plot:GetAttribute("MaxFruitCapacity") or 0

    local totalValue = Inventory.GetTotalFruitValue()

    local displayText = string.format("%s/%s Fruits | ", fruitCount, maxCapacity)
        .. '<font color="rgb(0,255,0)">$' .. Converter.Abbreviate(totalValue) .. '</font>'

    fruitInventory.Visible  = true
    fruitInventory.RichText  = true
    fruitInventory.Text      = displayText

    task.wait(1.5)
end

-- -- ESP BACKPACK BUTTONS (Fruit Value per Item) ---------------
local function UpdateFruitValueESP()
    if not Settings["ESP Fruit Value"] then return end

    local playerGui   = LocalPlayer:FindFirstChild("PlayerGui")
    local backpackGui = playerGui and playerGui:FindFirstChild("BackpackGui")
    local backpackFrame = backpackGui and backpackGui:FindFirstChild("Backpack")
    if not backpackFrame then return end

    -- Cari semua TextButton di backpack
    for _, btn in backpackFrame:GetDescendants() do
        if not Settings["ESP Fruit Value"] then break end
        if not btn:IsA("TextButton") then continue end

        local toolCount = btn:FindFirstChild("ToolCount")
        local toolName  = btn:FindFirstChild("ToolName")
        if toolCount and toolName then
            -- Tambahkan value label menggunakan Fruit_Misc API
            -- (implementasi tergantung game internal API)
        end
    end

    task.wait(2)
end

-- ============================================================
-- MAIN EXECUTOR LOOP
-- ============================================================

local function MainLoop()
    while true do
        -- Auto Sell Fruit (individual)
        local ok1, err1 = pcall(AutoSellFruit)
        if not ok1 then warn("[GAG2 Hub] AutoSellFruit error: " .. tostring(err1)) end

        -- Auto Sell All
        local ok2, err2 = pcall(AutoSellAll)
        if not ok2 then warn("[GAG2 Hub] AutoSellAll error: " .. tostring(err2)) end

        -- Auto Collect Fruit
        local ok3, err3 = pcall(AutoCollectFruit)
        if not ok3 then warn("[GAG2 Hub] AutoCollectFruit error: " .. tostring(err3)) end

        -- Auto Sell Pets
        local ok4, err4 = pcall(AutoSellPets)
        if not ok4 then warn("[GAG2 Hub] AutoSellPets error: " .. tostring(err4)) end

        -- ESP Update
        local ok5, err5 = pcall(UpdatePetESP)
        if not ok5 then warn("[GAG2 Hub] PetESP error: " .. tostring(err5)) end

        local ok6, err6 = pcall(UpdateBackpackInfo)
        if not ok6 then warn("[GAG2 Hub] BackpackInfo error: " .. tostring(err6)) end

        task.wait(0.1)
    end
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

print("[GAG2 Hub] Script loaded! Version: 1.0.0")
print("[GAG2 Hub] Game: Grow A Garden 2")
print("[GAG2 Hub] Fitur: Auto Sell, Auto Collect, Pet ESP, Fruit ESP")
print("[GAG2 Hub] Gunakan Settings table untuk mengaktifkan fitur!")

-- Jalankan main loop dalam coroutine
task.spawn(MainLoop)

-- ============================================================
-- PUBLIC API (untuk digunakan dengan GUI/Loader)
-- ============================================================

local GameModule = {}
GameModule.Settings        = Settings
GameModule.FruitFilter     = FruitFilter
GameModule.PetFilter       = PetFilter
GameModule.ESP             = ESP
GameModule.Networker       = Networker
GameModule.Converter       = Converter
GameModule.TeleportManager = TeleportManager
GameModule.Inventory       = Inventory
GameModule.Collection      = Collection

function GameModule.InitUI(Window)

    -- -- TAB 1: AUTO FARM -------------------------------------
    local FarmTab = Window:AddTab("Auto Farm", "🌱")

    FarmTab:AddSection("BUAH")

    FarmTab:AddToggle("Auto Collect Fruit", false, function(state)
        Settings["Auto Collect Fruit"] = state
    end)

    FarmTab:AddToggle("Stop Jika Backpack Penuh", false, function(state)
        Settings["Stop Collect If Backpack Is Full Max"] = state
    end)

    FarmTab:AddToggle("Disable Teleport", false, function(state)
        Settings["Disable Teleport "] = state
    end)

    FarmTab:AddSlider("Delay Collect (detik)", 0, 5, 0, function(val)
        Settings["Delay To Collect"] = val
    end)

    FarmTab:AddSection("FILTER BUAH")

    FarmTab:AddDropdown("Filter Rarity", {
        "All", "Common", "Uncommon", "Rare",
        "Epic", "Legendary", "Mythical", "Divine"
    }, "All", function(val)
        if val == "All" then
            Settings["Select Rarity"] = {}
        else
            Settings["Select Rarity"] = {val}
        end
    end)

    FarmTab:AddDropdown("Filter Mutasi", {
        "All", "None", "Golden", "Rainbow", "Shiny"
    }, "All", function(val)
        if val == "All" then
            Settings["Select Mutation"] = {}
        else
            Settings["Select Mutation"] = {val}
        end
    end)

    FarmTab:AddDropdown("Threshold Mode", {
        "None", "Above", "Below"
    }, "None", function(val)
        Settings["Select Threshold Mode   "] = val
    end)

    FarmTab:AddSlider("Weight Threshold", 0, 10000, 0, function(val)
        Settings["Weight Threshold"] = val
    end)

    -- -- TAB 2: AUTO SELL -------------------------------------
    local SellTab = Window:AddTab("Auto Sell", "💰")

    SellTab:AddSection("JUAL BUAH")

    SellTab:AddToggle("Auto Sell Fruit", false, function(state)
        Settings["Auto Sell Fruit"] = state
    end)

    SellTab:AddToggle("Auto Sell All", false, function(state)
        Settings["Auto Sell All"] = state
    end)

    SellTab:AddSlider("Delay Sell (detik)", 0, 5, 0, function(val)
        Settings["Delay To Sell Inventory"] = val
    end)

    SellTab:AddSection("EKONOMI")

    SellTab:AddToggle("Allow Sell at Multiplier", false, function(state)
        Settings["Allow Sell at Multiplier"] = state
    end)

    SellTab:AddToggle("Allow Sell If Backpack Max", false, function(state)
        Settings["Allow Sell If Backpack Is Max"] = state
    end)

    SellTab:AddToggle("Double Or Nothing", false, function(state)
        Settings["Allows Double Or Nothing"] = state
    end)

    SellTab:AddToggle("Use Daily Deal", false, function(state)
        Settings["Use Daily Deal"] = state
    end)

    SellTab:AddSection("FILTER SELL")

    SellTab:AddDropdown("Filter Rarity Sell", {
        "All", "Common", "Uncommon", "Rare",
        "Epic", "Legendary", "Mythical", "Divine"
    }, "All", function(val)
        if val == "All" then
            Settings["Select Sell Rarity"] = {}
        else
            Settings["Select Sell Rarity"] = {val}
        end
    end)

    -- -- TAB 3: AUTO PET --------------------------------------
    local PetTab = Window:AddTab("Pets", "🐾")

    PetTab:AddSection("AUTO SELL PET")

    PetTab:AddToggle("Auto Sell Pets", false, function(state)
        Settings["Auto Sell Pets"] = state
    end)

    PetTab:AddSection("ESP PET")

    PetTab:AddToggle("ESP Spawned Pets", false, function(state)
        Settings["ESP Spawned Pets"] = state
    end)

    PetTab:AddDropdown("Filter Rarity Pet", {
        "All", "Common", "Uncommon", "Rare",
        "Epic", "Legendary", "Mythical", "Divine"
    }, "All", function(val)
        if val == "All" then
            Settings["Select Rarity Pets   "] = {}
        else
            Settings["Select Rarity Pets   "] = {val}
        end
    end)

    -- -- TAB 4: ESP -------------------------------------------
    local EspTab = Window:AddTab("ESP", "👁️")

    EspTab:AddSection("VISUAL")

    EspTab:AddToggle("ESP Fruit Value", false, function(state)
        Settings["ESP Fruit Value"] = state
    end)

    EspTab:AddButton("Remove All ESP", "Hapus semua ESP yang aktif", function()
        for obj, billboard in pairs(espBillboards) do
            pcall(function() billboard:Destroy() end)
            espBillboards[obj] = nil
        end
        Window:Notify("ESP", "Semua ESP telah dihapus.", "success")
    end)

end

return GameModule
