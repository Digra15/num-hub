--[[
    ================================================
    |           NUM HUB - Loader                  |
    |   Paste script ini ke executor kamu!        |
    |           Version: 1.0.0                    |
    ================================================

    CARA PAKAI:
        1. Copy seluruh isi file ini
        2. Paste ke executor (Delta, Arceus X, KRNL, dll)
        3. Execute!

    GitHub: https://github.com/Digra15/num-hub
]]

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    HubName     = "NUM HUB",
    Version     = "1.0.0",
    Creator     = "Digra15",
    GitHubBase  = "https://raw.githubusercontent.com/Digra15/num-hub/main/",
    DiscordLink = "discord.gg/XXXXXXX",
}

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name = "NUMHUB_Loading"
LoadGui.ResetOnSpawn = false
LoadGui.IgnoreGuiInset = true
LoadGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local LoadFrame = Instance.new("Frame")
LoadFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
LoadFrame.BorderSizePixel = 0
LoadFrame.Size = UDim2.fromScale(1, 1)
LoadFrame.Parent = LoadGui

local LogoLabel = Instance.new("TextLabel")
LogoLabel.BackgroundTransparency = 1
LogoLabel.Position = UDim2.new(0.5, -150, 0.5, -60)
LogoLabel.Size = UDim2.new(0, 300, 0, 50)
LogoLabel.Text = Config.HubName
LogoLabel.TextColor3 = Color3.fromRGB(110, 60, 220)
LogoLabel.TextSize = 36
LogoLabel.Font = Enum.Font.GothamBlack
LogoLabel.Parent = LoadFrame

local SubLabel = Instance.new("TextLabel")
SubLabel.BackgroundTransparency = 1
SubLabel.Position = UDim2.new(0.5, -150, 0.5, -5)
SubLabel.Size = UDim2.new(0, 300, 0, 20)
SubLabel.Text = "v" .. Config.Version .. " by " .. Config.Creator
SubLabel.TextColor3 = Color3.fromRGB(100, 100, 150)
SubLabel.TextSize = 12
SubLabel.Font = Enum.Font.Gotham
SubLabel.Parent = LoadFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.5, -150, 0.5, 30)
StatusLabel.Size = UDim2.new(0, 300, 0, 20)
StatusLabel.Text = "Menginisialisasi..."
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = LoadFrame

local ProgressBg = Instance.new("Frame")
ProgressBg.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
ProgressBg.BorderSizePixel = 0
ProgressBg.Position = UDim2.new(0.5, -120, 0.5, 60)
ProgressBg.Size = UDim2.new(0, 240, 0, 4)
ProgressBg.Parent = LoadFrame
Instance.new("UICorner", ProgressBg).CornerRadius = UDim.new(1, 0)

local ProgressFill = Instance.new("Frame")
ProgressFill.BackgroundColor3 = Color3.fromRGB(110, 60, 220)
ProgressFill.BorderSizePixel = 0
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.Parent = ProgressBg
Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)

local function SetStatus(msg, progress)
    StatusLabel.Text = msg
    TweenService:Create(ProgressFill, TweenInfo.new(0.3), {
        Size = UDim2.new(progress or 0, 0, 1, 0)
    }):Play()
    task.wait(0.3)
end

-- ============================================================
-- LOAD SEQUENCE
-- ============================================================
local success, errorMsg = pcall(function()

    SetStatus("Loading GameList...", 0.2)
    local GameList = loadstring(game:HttpGet(Config.GitHubBase .. "GameList.lua"))()

    SetStatus("Detecting game...", 0.4)
    local PlaceId   = game.PlaceId
    local PlaceName = game:GetService("MarketplaceService"):GetProductInfo(PlaceId).Name
    task.wait(0.3)

    SetStatus("Loading UI...", 0.6)
    local UI = loadstring(game:HttpGet(Config.GitHubBase .. "UI/Library.lua"))()

    SetStatus("Preparing script...", 0.8)
    local scriptUrl = GameList[PlaceId]

    if not scriptUrl then
        SetStatus("Game not supported: " .. tostring(PlaceId), 1)
        task.wait(1.5)

        local Window = UI:CreateWindow(Config.HubName, PlaceName or "Game " .. PlaceId)
        local Tab = Window:AddTab("Info", "!")
        Tab:AddSection("STATUS")
        Tab:AddLabel("Game ini belum didukung NUM HUB.", "warning")
        Tab:AddLabel("Place ID: " .. tostring(PlaceId), "normal")
        Tab:AddLabel("Request di Discord kami!", "info")
        Tab:AddButton("Copy Place ID", "Salin ID game ini", function()
            setclipboard(tostring(PlaceId))
            Window:Notify("Disalin!", "Place ID " .. PlaceId .. " telah disalin.", "success")
        end)
        LoadGui:Destroy()
        return
    end

    SetStatus("Loading game script...", 0.95)
    task.wait(0.2)

    local GameModule = loadstring(game:HttpGet(scriptUrl))()

    SetStatus("Ready!", 1.0)
    task.wait(0.4)

    local Window = UI:CreateWindow(Config.HubName, PlaceName or "Unknown Game")

    if GameModule and GameModule.InitUI then
        GameModule.InitUI(Window)
    else
        local Tab = Window:AddTab("Info", "#")
        Tab:AddSection("STATUS")
        Tab:AddLabel("Script berhasil dimuat!", "success")
        Tab:AddLabel("Game: " .. (PlaceName or "Unknown"), "normal")
    end

    local SettingsTab = Window:AddTab("Settings", "*")
    SettingsTab:AddSection("TENTANG")
    SettingsTab:AddLabel("Hub: " .. Config.HubName, "normal")
    SettingsTab:AddLabel("Versi: " .. Config.Version, "normal")
    SettingsTab:AddLabel("Creator: " .. Config.Creator, "normal")
    SettingsTab:AddLabel("Game: " .. (PlaceName or tostring(PlaceId)), "info")
    SettingsTab:AddSection("LINK")
    SettingsTab:AddButton("Copy Place ID", nil, function()
        pcall(setclipboard, tostring(PlaceId))
        Window:Notify("Disalin!", "Place ID berhasil disalin.", "success")
    end)
    SettingsTab:AddButton("Discord", nil, function()
        pcall(setclipboard, Config.DiscordLink)
        Window:Notify("Discord", "Link discord telah disalin!", "info")
    end)

    LoadGui:Destroy()
    Window:Notify("NUM HUB", "Script berhasil dimuat untuk " .. (PlaceName or "game ini"), "success")

end)

if not success then
    SetStatus("Error: " .. tostring(errorMsg), 1)
    warn("[NUM HUB] Error: " .. tostring(errorMsg))
    task.wait(3)
    LoadGui:Destroy()
end
