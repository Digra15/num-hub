--[[
    
    Cara menambah game baru:
    1. Buka game di browser: roblox.com/games/XXXXXXX/Game-Name
    2. Ambil angka setelah /games/ itu adalah Place ID
    3. Tambahkan: [PlaceID] = "URL script raw GitHub kamu"

    GitHub Repository: https://github.com/Digra15/num-hub
]]

-- ============================================================
--  GAME LIST - Daftar semua game yang didukung
-- ============================================================

local Games = {

    -- ---------------------------------------------------------
    --  FIGHTING / BATTLE
    -- ---------------------------------------------------------

    [994732206]  = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Blox%20Fruits.lua",        -- Blox Fruits
    [3808081382] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/The%20Strongest%20Battlegrounds.lua", -- The Strongest Battlegrounds

    -- ---------------------------------------------------------
    --  PET / SIMULATOR
    -- ---------------------------------------------------------

    [8737899170] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Pet%20Simulator%2099.lua", -- Pet Simulator 99
    [6401952734] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Pet%20GO.lua",             -- Pet GO

    -- ---------------------------------------------------------
    --  ANIME
    -- ---------------------------------------------------------

    [12688139157] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Anime%20Adventures.lua", -- Anime Adventures

    -- ---------------------------------------------------------
    --  HORROR / MURDER
    -- ---------------------------------------------------------

    [142823291]  = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Murder%20Mystery%202.lua", -- Murder Mystery 2

    -- ---------------------------------------------------------
    --  ROLEPLAY / SOCIAL
    -- ---------------------------------------------------------

    [2788229376] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Da%20Hood.lua",           -- Da Hood
    [4924922222] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Brookhaven.lua",          -- Brookhaven RP

    -- ---------------------------------------------------------
    --  FARMING / IDLE
    -- ---------------------------------------------------------

    -- CATATAN: Verifikasi Place ID Grow a Garden & Grow a Garden 2
    -- di browser: roblox.com/games/XXXXX/Grow-a-Garden ambil angkanya.
    [126884695634] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Grow%20a%20Garden.lua",   -- Grow a Garden
    [97598239454123] = "https://raw.githubusercontent.com/Digra15/num-hub/main/Scripts/Grow%20a%20Garden%202.lua", -- Grow a Garden 2

}

-- ============================================================
--  LOADER - Jangan ubah bagian ini
-- ============================================================

local PlaceId = game.PlaceId

if Games[PlaceId] then
    print("[Speed Hub X] Game ditemukan: " .. tostring(PlaceId))
    print("[Speed Hub X] Memuat script...")

    local success, err = pcall(function()
        loadstring(game:HttpGet(Games[PlaceId]))()
    end)

    if not success then
        warn("[Speed Hub X] Gagal memuat script: " .. tostring(err))
    end
else
    warn("[Speed Hub X] Game dengan Place ID [" .. tostring(PlaceId) .. "] belum didukung.")
    warn("[Speed Hub X] Kunjungi repo kami untuk request game baru!")
end

return Games
