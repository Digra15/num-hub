--[[
    â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
    â•‘                  NUM HUB - UI Library                    â•‘
    â•‘              Beautiful Dark Purple/Blue Theme            â•‘
    â•‘                    Version: 1.0.0                        â•‘
    â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    USAGE:
        local UI = loadstring(game:HttpGet("URL/UI/Library.lua"))()
        local Window = UI:CreateWindow("NUM HUB", "Grow A Garden 2")
        local Tab = Window:AddTab("Auto Farm", "ðŸŒ±")
        Tab:AddToggle("Auto Collect Fruit", false, function(state)
            Settings["Auto Collect Fruit"] = state
        end)
]]

local Library = {}
Library.__index = Library

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
-- THEME / COLOR PALETTE
-- ============================================================
local Theme = {
    -- Background
    Background      = Color3.fromRGB(12, 12, 18),       -- Sangat gelap
    BackgroundAlt   = Color3.fromRGB(18, 18, 28),       -- Sedikit lebih terang
    Surface         = Color3.fromRGB(22, 22, 36),       -- Card surface
    SurfaceAlt      = Color3.fromRGB(28, 28, 45),       -- Hover surface

    -- Accent
    Accent          = Color3.fromRGB(110, 60, 220),     -- Ungu utama
    AccentAlt       = Color3.fromRGB(80, 120, 255),     -- Biru aksen
    AccentGlow      = Color3.fromRGB(130, 80, 255),     -- Glow ungu
    AccentDark      = Color3.fromRGB(60, 30, 140),      -- Ungu gelap

    -- Text
    TextPrimary     = Color3.fromRGB(240, 240, 255),    -- Putih kebiruan
    TextSecondary   = Color3.fromRGB(160, 160, 200),    -- Abu kebiruan
    TextMuted       = Color3.fromRGB(90, 90, 130),      -- Muted

    -- Status
    Success         = Color3.fromRGB(80, 220, 120),     -- Hijau
    Warning         = Color3.fromRGB(255, 180, 50),     -- Kuning
    Danger          = Color3.fromRGB(220, 80, 80),      -- Merah
    Info            = Color3.fromRGB(80, 160, 255),     -- Biru

    -- Misc
    Border          = Color3.fromRGB(50, 50, 80),
    Divider         = Color3.fromRGB(35, 35, 55),
    Shadow          = Color3.fromRGB(0, 0, 0),
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function Tween(obj, props, duration, easingStyle, easingDir)
    local info = TweenInfo.new(
        duration or 0.25,
        easingStyle or Enum.EasingStyle.Quart,
        easingDir or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function NewInstance(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function AddUICorner(parent, radius)
    return NewInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function AddUIStroke(parent, color, thickness)
    return NewInstance("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function AddPadding(parent, top, bottom, left, right)
    return NewInstance("UIPadding", {
        PaddingTop    = UDim.new(0, top or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left or 8),
        PaddingRight  = UDim.new(0, right or 8),
        Parent = parent
    })
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotifContainer

local function CreateNotifContainer(screenGui)
    NotifContainer = NewInstance("Frame", {
        Name             = "NotifContainer",
        BackgroundTransparency = 1,
        Position         = UDim2.new(1, -20, 1, -20),
        Size             = UDim2.new(0, 300, 0, 0),
        AnchorPoint      = Vector2.new(1, 1),
        Parent           = screenGui,
    })
    NewInstance("UIListLayout", {
        SortOrder        = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding          = UDim.new(0, 8),
        Parent           = NotifContainer,
    })
end

function Library:Notify(title, message, notifType, duration)
    notifType = notifType or "info"
    duration  = duration or 3

    local colors = {
        info    = Theme.Info,
        success = Theme.Success,
        warning = Theme.Warning,
        error   = Theme.Danger,
    }
    local icons = {
        info    = "â„¹ï¸",
        success = "âœ…",
        warning = "âš ï¸",
        error   = "âŒ",
    }

    local color = colors[notifType] or Theme.Info
    local icon  = icons[notifType] or "â„¹ï¸"

    -- Card
    local card = NewInstance("Frame", {
        Name                 = "Notification",
        BackgroundColor3     = Theme.Surface,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 0.1,
        Parent               = NotifContainer,
    })
    AddUICorner(card, 10)

    -- Accent bar kiri
    NewInstance("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 4, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        Parent           = card,
    }, {NewInstance("UICorner", {CornerRadius = UDim.new(0, 4)})})

    -- Content
    local content = NewInstance("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size     = UDim2.new(1, -20, 1, 0),
        Parent   = card,
    })

    NewInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 8),
        Size                   = UDim2.new(1, 0, 0, 20),
        TextColor3             = Theme.TextPrimary,
        TextSize               = 14,
        Font                   = Enum.Font.GothamBold,
        Text                   = icon .. "  " .. title,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = content,
    })

    NewInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 32),
        Size                   = UDim2.new(1, 0, 0, 28),
        TextColor3             = Theme.TextSecondary,
        TextSize               = 12,
        Font                   = Enum.Font.Gotham,
        Text                   = message,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        Parent                 = content,
    })

    -- Slide in
    card.Position = UDim2.new(1.2, 0, 0, 0)
    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)

    -- Auto dismiss
    task.delay(duration, function()
        Tween(card, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        card:Destroy()
    end)
end

-- ============================================================
-- CREATE WINDOW
-- ============================================================
function Library:CreateWindow(hubName, gameName)
    hubName  = hubName or "NUM HUB"
    gameName = gameName or "Unknown Game"

    -- Buat ScreenGui
    local ScreenGui = NewInstance("ScreenGui", {
        Name            = "NUMHUB_" .. hubName:gsub(" ", "_"),
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset  = true,
        Parent          = LocalPlayer:WaitForChild("PlayerGui"),
    })

    CreateNotifContainer(ScreenGui)

    -- â”€â”€ MAIN WINDOW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local MainFrame = NewInstance("Frame", {
        Name             = "MainFrame",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, -300, 0.5, -200),
        Size             = UDim2.new(0, 600, 0, 420),
        AnchorPoint      = Vector2.new(0, 0),
        Parent           = ScreenGui,
    })
    AddUICorner(MainFrame, 12)
    AddUIStroke(MainFrame, Theme.Border, 1.5)

    -- Shadow
    local Shadow = NewInstance("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size     = UDim2.new(1, 30, 1, 30),
        Image    = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex   = 0,
        Parent   = MainFrame,
    })

    -- â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local Header = NewInstance("Frame", {
        Name             = "Header",
        BackgroundColor3 = Theme.BackgroundAlt,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 55),
        Parent           = MainFrame,
    })
    AddUICorner(Header, 12)

    -- Fix bottom corners header
    NewInstance("Frame", {
        BackgroundColor3 = Theme.BackgroundAlt,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        Parent           = Header,
    })

    -- Logo / Icon area
    local LogoFrame = NewInstance("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 12, 0.5, -15),
        Size             = UDim2.new(0, 30, 0, 30),
        Parent           = Header,
    })
    AddUICorner(LogoFrame, 8)

    NewInstance("TextLabel", {
        BackgroundTransparency = 1,
        Size       = UDim2.fromScale(1, 1),
        Text       = "N",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize   = 18,
        Font       = Enum.Font.GothamBlack,
        Parent     = LogoFrame,
    })

    -- Hub Name
    NewInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 52, 0, 8),
        Size           = UDim2.new(0, 200, 0, 22),
        Text           = hubName,
        TextColor3     = Theme.TextPrimary,
        TextSize       = 16,
        Font           = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent         = Header,
    })

    -- Game Name
    NewInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 52, 0, 30),
        Size           = UDim2.new(0, 250, 0, 16),
        Text           = "â–¸ " .. gameName,
        TextColor3     = Theme.TextMuted,
        TextSize       = 11,
        Font           = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent         = Header,
    })

    -- Close Button
    local CloseBtn = NewInstance("TextButton", {
        BackgroundColor3 = Color3.fromRGB(220, 60, 60),
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -44, 0.5, -11),
        Size             = UDim2.new(0, 22, 0, 22),
        Text             = "Ã—",
        TextColor3       = Color3.new(1, 1, 1),
        TextSize         = 16,
        Font             = Enum.Font.GothamBold,
        Parent           = Header,
    })
    AddUICorner(CloseBtn, 6)

    -- Minimize Button
    local MinBtn = NewInstance("TextButton", {
        BackgroundColor3 = Color3.fromRGB(200, 150, 30),
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -70, 0.5, -11),
        Size             = UDim2.new(0, 22, 0, 22),
        Text             = "âˆ’",
        TextColor3       = Color3.new(1, 1, 1),
        TextSize         = 16,
        Font             = Enum.Font.GothamBold,
        Parent           = Header,
    })
    AddUICorner(MinBtn, 6)

    -- â”€â”€ TAB BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local TabBar = NewInstance("Frame", {
        Name             = "TabBar",
        BackgroundColor3 = Theme.BackgroundAlt,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 55),
        Size             = UDim2.new(0, 150, 1, -55),
        Parent           = MainFrame,
    })

    NewInstance("UIListLayout", {
        SortOrder  = Enum.SortOrder.LayoutOrder,
        Padding    = UDim.new(0, 4),
        Parent     = TabBar,
    })
    AddPadding(TabBar, 8, 8, 8, 8)

    -- â”€â”€ CONTENT AREA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local ContentArea = NewInstance("Frame", {
        Name             = "ContentArea",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 155, 0, 60),
        Size             = UDim2.new(1, -160, 1, -65),
        Parent           = MainFrame,
    })

    -- Divider vertikal
    NewInstance("Frame", {
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 150, 0, 58),
        Size             = UDim2.new(0, 1, 1, -60),
        Parent           = MainFrame,
    })

    -- â”€â”€ DRAG â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    MakeDraggable(MainFrame, Header)

    -- â”€â”€ CLOSE & MINIMIZE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local isMinimized = false
    local originalSize = MainFrame.Size

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 55)}, 0.3)
        else
            Tween(MainFrame, {Size = originalSize}, 0.3)
        end
    end)

    -- Hover effects
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}, 0.15)
    end)

    -- Animate in
    MainFrame.Size = UDim2.new(0, 600, 0, 0)
    MainFrame.BackgroundTransparency = 1
    Tween(MainFrame, {Size = originalSize, BackgroundTransparency = 0}, 0.4)

    -- â”€â”€ WINDOW OBJECT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local Window = {}
    Window._tabs     = {}
    Window._tabBtns  = {}
    Window._active   = nil
    Window._gui      = ScreenGui
    Window._lib      = self

    function Window:Notify(...)
        Library.Notify(self._lib, ...)
    end

    -- â”€â”€ ADD TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function Window:AddTab(name, icon)
        icon = icon or "â¬¡"

        -- Tab Button
        local TabBtn = NewInstance("TextButton", {
            BackgroundColor3     = Theme.Surface,
            BorderSizePixel      = 0,
            Size                 = UDim2.new(1, 0, 0, 38),
            Text                 = "",
            AutoButtonColor      = false,
            Parent               = TabBar,
        })
        AddUICorner(TabBtn, 8)

        -- Tab icon + label
        NewInstance("TextLabel", {
            BackgroundTransparency = 1,
            Position  = UDim2.new(0, 10, 0, 0),
            Size      = UDim2.new(0, 24, 1, 0),
            Text      = icon,
            TextSize  = 14,
            Font      = Enum.Font.Gotham,
            TextColor3 = Theme.TextSecondary,
            Parent    = TabBtn,
        })

        local TabLabel = NewInstance("TextLabel", {
            BackgroundTransparency = 1,
            Position  = UDim2.new(0, 38, 0, 0),
            Size      = UDim2.new(1, -42, 1, 0),
            Text      = name,
            TextSize  = 13,
            Font      = Enum.Font.GothamSemibold,
            TextColor3 = Theme.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent    = TabBtn,
        })

        -- Active indicator
        local ActiveBar = NewInstance("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 0, 0.2, 0),
            Size             = UDim2.new(0, 3, 0.6, 0),
            Parent           = TabBtn,
        })
        AddUICorner(ActiveBar, 4)
        ActiveBar.Visible = false

        -- Tab content frame
        local TabContent = NewInstance("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.fromScale(0, 0),
            Size                   = UDim2.fromScale(1, 1),
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.Accent,
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = false,
            Parent                 = ContentArea,
        })

        NewInstance("UIListLayout", {
            SortOrder    = Enum.SortOrder.LayoutOrder,
            Padding      = UDim.new(0, 6),
            Parent       = TabContent,
        })
        AddPadding(TabContent, 4, 8, 2, 6)

        -- Tab object
        local Tab = {}
        Tab._content = TabContent
        Tab._window  = self

        -- Switch tab function
        local function ActivateTab()
            -- Deactivate all
            for _, t in ipairs(Window._tabs) do
                t._content.Visible = false
            end
            for _, btn in ipairs(Window._tabBtns) do
                Tween(btn.frame, {BackgroundColor3 = Theme.Surface}, 0.2)
                Tween(btn.label, {TextColor3 = Theme.TextSecondary}, 0.2)
                btn.bar.Visible = false
            end
            -- Activate this tab
            TabContent.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Theme.SurfaceAlt}, 0.2)
            Tween(TabLabel, {TextColor3 = Theme.TextPrimary}, 0.2)
            ActiveBar.Visible = true
        end

        TabBtn.MouseButton1Click:Connect(ActivateTab)

        -- Hover
        TabBtn.MouseEnter:Connect(function()
            if TabContent.Visible then return end
            Tween(TabBtn, {BackgroundColor3 = Theme.SurfaceAlt}, 0.15)
        end)
        TabBtn.MouseLeave:Connect(function()
            if TabContent.Visible then return end
            Tween(TabBtn, {BackgroundColor3 = Theme.Surface}, 0.15)
        end)

        table.insert(Window._tabs, Tab)
        table.insert(Window._tabBtns, {frame = TabBtn, label = TabLabel, bar = ActiveBar})

        -- Activate first tab automatically
        if #Window._tabs == 1 then
            ActivateTab()
        end

        -- â”€â”€ SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddSection(title)
            local SectionFrame = NewInstance("Frame", {
                BackgroundTransparency = 1,
                Size   = UDim2.new(1, 0, 0, 28),
                Parent = TabContent,
            })

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Size           = UDim2.new(1, -10, 1, 0),
                Position       = UDim2.new(0, 5, 0, 0),
                Text           = title:upper(),
                TextColor3     = Theme.Accent,
                TextSize       = 10,
                Font           = Enum.Font.GothamBlack,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent         = SectionFrame,
            })

            NewInstance("Frame", {
                BackgroundColor3 = Theme.Divider,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 5, 1, -1),
                Size             = UDim2.new(1, -10, 0, 1),
                Parent           = SectionFrame,
            })
        end

        -- â”€â”€ TOGGLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddToggle(name, default, callback)
            local state = default or false

            local Row = NewInstance("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 44),
                Parent           = TabContent,
            })
            AddUICorner(Row, 8)
            AddUIStroke(Row, Theme.Border, 1)

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0, 12, 0, 0),
                Size      = UDim2.new(1, -70, 1, 0),
                Text      = name,
                TextColor3 = Theme.TextPrimary,
                TextSize  = 13,
                Font      = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent    = Row,
            })

            -- Toggle switch
            local SwitchBg = NewInstance("Frame", {
                BackgroundColor3 = state and Theme.Accent or Theme.BackgroundAlt,
                BorderSizePixel  = 0,
                Position         = UDim2.new(1, -52, 0.5, -12),
                Size             = UDim2.new(0, 42, 0, 24),
                Parent           = Row,
            })
            AddUICorner(SwitchBg, 12)
            AddUIStroke(SwitchBg, state and Theme.AccentGlow or Theme.Border, 1)

            local Knob = NewInstance("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                Position         = state and UDim2.new(0, 20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                Size             = UDim2.new(0, 18, 0, 18),
                Parent           = SwitchBg,
            })
            AddUICorner(Knob, 9)

            -- Click handler
            local function Toggle()
                state = not state
                callback(state)

                Tween(SwitchBg, {
                    BackgroundColor3 = state and Theme.Accent or Theme.BackgroundAlt
                }, 0.2)
                Tween(Knob, {
                    Position = state
                        and UDim2.new(0, 20, 0.5, -9)
                        or  UDim2.new(0, 3, 0.5, -9)
                }, 0.2)

                local stroke = SwitchBg:FindFirstChildWhichIsA("UIStroke")
                if stroke then
                    Tween(stroke, {Color = state and Theme.AccentGlow or Theme.Border}, 0.2)
                end
            end

            Row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    Toggle()
                end
            end)
            SwitchBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    Toggle()
                end
            end)

            -- Hover
            Row.MouseEnter:Connect(function()
                Tween(Row, {BackgroundColor3 = Theme.SurfaceAlt}, 0.15)
            end)
            Row.MouseLeave:Connect(function()
                Tween(Row, {BackgroundColor3 = Theme.Surface}, 0.15)
            end)

            local ToggleObj = {}
            function ToggleObj:Set(val)
                if val ~= state then Toggle() end
            end
            function ToggleObj:Get() return state end
            return ToggleObj
        end

        -- â”€â”€ SLIDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddSlider(name, min, max, default, callback)
            min     = min or 0
            max     = max or 1
            default = math.clamp(default or min, min, max)
            local value = default

            local Row = NewInstance("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 54),
                Parent           = TabContent,
            })
            AddUICorner(Row, 8)
            AddUIStroke(Row, Theme.Border, 1)

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0, 12, 0, 6),
                Size      = UDim2.new(0.7, 0, 0, 18),
                Text      = name,
                TextColor3 = Theme.TextPrimary,
                TextSize  = 13,
                Font      = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent    = Row,
            })

            local ValueLabel = NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0.7, 0, 0, 6),
                Size      = UDim2.new(0.3, -10, 0, 18),
                Text      = tostring(default),
                TextColor3 = Theme.Accent,
                TextSize  = 13,
                Font      = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent    = Row,
            })

            -- Track
            local Track = NewInstance("Frame", {
                BackgroundColor3 = Theme.BackgroundAlt,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 12, 0, 34),
                Size             = UDim2.new(1, -24, 0, 6),
                Parent           = Row,
            })
            AddUICorner(Track, 3)

            local Fill = NewInstance("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new((default - min) / (max - min), 0, 1, 0),
                Parent           = Track,
            })
            AddUICorner(Fill, 3)

            -- Knob
            local SliderKnob = NewInstance("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 14),
                Parent           = Track,
            })
            AddUICorner(SliderKnob, 7)

            -- Drag slider
            local sliding = false
            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    local trackPos   = Track.AbsolutePosition.X
                    local trackWidth = Track.AbsoluteSize.X
                    local rel = math.clamp((input.Position.X - trackPos) / trackWidth, 0, 1)
                    value = math.floor(min + rel * (max - min))
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    SliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end
            end)

            local SliderObj = {}
            function SliderObj:Set(val)
                val = math.clamp(val, min, max)
                value = val
                local rel = (val - min) / (max - min)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                SliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
                ValueLabel.Text = tostring(val)
                callback(val)
            end
            function SliderObj:Get() return value end
            return SliderObj
        end

        -- â”€â”€ DROPDOWN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddDropdown(name, options, default, callback)
            local selected = default or options[1] or "None"
            local isOpen   = false

            local Wrapper = NewInstance("Frame", {
                BackgroundTransparency = 1,
                Size   = UDim2.new(1, 0, 0, 44),
                ClipsDescendants = false,
                Parent = TabContent,
            })

            local Row = NewInstance("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 44),
                Parent           = Wrapper,
            })
            AddUICorner(Row, 8)
            AddUIStroke(Row, Theme.Border, 1)

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0, 12, 0, 0),
                Size      = UDim2.new(0.5, 0, 1, 0),
                Text      = name,
                TextColor3 = Theme.TextPrimary,
                TextSize  = 13,
                Font      = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent    = Row,
            })

            local SelectedLabel = NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0.5, 0, 0, 0),
                Size      = UDim2.new(0.4, 0, 1, 0),
                Text      = selected,
                TextColor3 = Theme.Accent,
                TextSize  = 12,
                Font      = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent    = Row,
            })

            local Arrow = NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(1, -28, 0, 0),
                Size      = UDim2.new(0, 20, 1, 0),
                Text      = "â–¾",
                TextColor3 = Theme.TextMuted,
                TextSize  = 14,
                Font      = Enum.Font.GothamBold,
                Parent    = Row,
            })

            -- Dropdown list
            local DropList = NewInstance("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 0, 1, 4),
                Size             = UDim2.new(1, 0, 0, #options * 32 + 8),
                Visible          = false,
                ZIndex           = 10,
                Parent           = Wrapper,
            })
            AddUICorner(DropList, 8)
            AddUIStroke(DropList, Theme.Border, 1)

            NewInstance("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 2),
                Parent    = DropList,
            })
            AddPadding(DropList, 4, 4, 4, 4)

            -- Option items
            for _, opt in ipairs(options) do
                local OptBtn = NewInstance("TextButton", {
                    BackgroundColor3 = Theme.SurfaceAlt,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1, 0, 0, 28),
                    Text             = opt,
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 12,
                    Font             = Enum.Font.Gotham,
                    ZIndex           = 11,
                    AutoButtonColor  = false,
                    Parent           = DropList,
                })
                AddUICorner(OptBtn, 6)

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelectedLabel.Text = opt
                    callback(opt)
                    isOpen = false
                    DropList.Visible = false
                    Wrapper.Size = UDim2.new(1, 0, 0, 44)
                    Tween(Arrow, {Rotation = 0}, 0.2)
                end)
                OptBtn.MouseEnter:Connect(function()
                    Tween(OptBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextPrimary}, 0.15)
                end)
                OptBtn.MouseLeave:Connect(function()
                    Tween(OptBtn, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextSecondary}, 0.15)
                end)
            end

            Row.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                DropList.Visible = isOpen
                Wrapper.Size = isOpen
                    and UDim2.new(1, 0, 0, 44 + #options * 32 + 12)
                    or UDim2.new(1, 0, 0, 44)
                Tween(Arrow, {Rotation = isOpen and 180 or 0}, 0.2)
            end)

            local DropObj = {}
            function DropObj:Set(val) selected = val; SelectedLabel.Text = val; callback(val) end
            function DropObj:Get() return selected end
            return DropObj
        end

        -- â”€â”€ BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddButton(name, description, callback)
            local Row = NewInstance("TextButton", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 44),
                Text             = "",
                AutoButtonColor  = false,
                Parent           = TabContent,
            })
            AddUICorner(Row, 8)
            AddUIStroke(Row, Theme.Border, 1)

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0, 12, 0, description and 6 or 0),
                Size      = UDim2.new(0.8, 0, 0, 18),
                Text      = name,
                TextColor3 = Theme.TextPrimary,
                TextSize  = 13,
                Font      = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent    = Row,
            })

            if description then
                NewInstance("TextLabel", {
                    BackgroundTransparency = 1,
                    Position  = UDim2.new(0, 12, 0, 26),
                    Size      = UDim2.new(0.8, 0, 0, 14),
                    Text      = description,
                    TextColor3 = Theme.TextMuted,
                    TextSize  = 10,
                    Font      = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent    = Row,
                })
            end

            -- Arrow icon
            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(1, -30, 0, 0),
                Size      = UDim2.new(0, 20, 1, 0),
                Text      = "â€º",
                TextColor3 = Theme.Accent,
                TextSize  = 20,
                Font      = Enum.Font.GothamBold,
                Parent    = Row,
            })

            Row.MouseButton1Click:Connect(function()
                Tween(Row, {BackgroundColor3 = Theme.AccentDark}, 0.1)
                task.delay(0.1, function()
                    Tween(Row, {BackgroundColor3 = Theme.SurfaceAlt}, 0.15)
                end)
                callback()
            end)
            Row.MouseEnter:Connect(function()
                Tween(Row, {BackgroundColor3 = Theme.SurfaceAlt}, 0.15)
            end)
            Row.MouseLeave:Connect(function()
                Tween(Row, {BackgroundColor3 = Theme.Surface}, 0.15)
            end)
        end

        -- â”€â”€ LABEL / INFO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddLabel(text, labelType)
            labelType = labelType or "normal"
            local colors = {
                normal  = Theme.TextSecondary,
                success = Theme.Success,
                warning = Theme.Warning,
                danger  = Theme.Danger,
                info    = Theme.Info,
            }

            local lbl = NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Size      = UDim2.new(1, 0, 0, 22),
                Text      = text,
                TextColor3 = colors[labelType] or Theme.TextSecondary,
                TextSize  = 12,
                Font      = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent    = TabContent,
            })

            local LblObj = {}
            function LblObj:Set(newText) lbl.Text = newText end
            return LblObj
        end

        -- â”€â”€ INPUT BOX â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        function Tab:AddInput(name, placeholder, callback)
            local Row = NewInstance("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 54),
                Parent           = TabContent,
            })
            AddUICorner(Row, 8)
            AddUIStroke(Row, Theme.Border, 1)

            NewInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position  = UDim2.new(0, 12, 0, 6),
                Size      = UDim2.new(1, -24, 0, 16),
                Text      = name,
                TextColor3 = Theme.TextSecondary,
                TextSize  = 11,
                Font      = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent    = Row,
            })

            local InputBox = NewInstance("TextBox", {
                BackgroundColor3 = Theme.BackgroundAlt,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 10, 0, 26),
                Size             = UDim2.new(1, -20, 0, 22),
                Text             = "",
                PlaceholderText  = placeholder or "...",
                TextColor3       = Theme.TextPrimary,
                PlaceholderColor3 = Theme.TextMuted,
                TextSize         = 13,
                Font             = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                Parent           = Row,
            })
            AddUICorner(InputBox, 6)
            AddPadding(InputBox, 2, 2, 8, 8)

            InputBox.FocusLost:Connect(function(enter)
                if enter then callback(InputBox.Text) end
            end)
        end

        return Tab
    end

    return Window
end

return Library
