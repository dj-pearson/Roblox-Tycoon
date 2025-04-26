--!strict
--[[
    SettingsUI.luau
    
    Consolidated settings interface for managing all game preferences.
    Provides options for audio, graphics, controls, and gameplay settings.
    
    Features:
    - Category-based settings organization
    - Automatic settings persistence
    - Real-time preview of setting changes
    - Reset to defaults functionality
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    error("Source folder not found")
    return
end

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local clientCoreFolder = clientFolder and clientFolder:FindFirstChild("Core")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local ClientRegistry = requireSafely(clientCoreFolder and clientCoreFolder:FindFirstChild("ClientRegistry"))

-- Create fallbacks for critical modules
if not UIStyle then
    warn("UIStyle module not found, using fallback implementation")
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Secondary = Color3.fromRGB(45, 45, 45),
            Background = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            TextDisabled = Color3.fromRGB(150, 150, 150),
            Success = Color3.fromRGB(46, 204, 113),
            Warning = Color3.fromRGB(230, 126, 34),
            Error = Color3.fromRGB(231, 76, 60)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            Light = Enum.Font.GothamMedium
        },
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

if not ButtonFactory then
    warn("ButtonFactory module not found, using fallback implementation")
    ButtonFactory = {
        createButton = function(properties)
            local button = Instance.new("TextButton")
            button.Size = properties.size or UDim2.new(0, 200, 0, 50)
            button.Position = properties.position or UDim2.new(0, 0, 0, 0)
            button.BackgroundColor3 = properties.backgroundColor or UIStyle.Colors.Primary
            button.BorderSizePixel = 0
            button.Text = properties.text or "Button"
            button.TextColor3 = properties.textColor or UIStyle.Colors.Text
            button.Font = properties.font or UIStyle.Fonts.Regular
            button.TextSize = properties.textSize or 16
            button.Parent = properties.parent
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button
            
            if properties.callback then
                button.Activated:Connect(properties.callback)
            end
            
            return button
        end
    }
end

-- Module and state variables
local SettingsUI = {}
local uiElements = {
    mainFrame = nil,
    tabs = {},
    activeTab = nil,
    sliders = {},
    toggles = {}
}

-- Settings data store
local settings = {
    audio = {
        musicVolume = 50,
        sfxVolume = 70,
        ambientVolume = 60,
        muteAll = false
    },
    graphics = {
        quality = 7, -- 1-10
        shadows = true,
        effects = true,
        vSync = true
    },
    gameplay = {
        hintsEnabled = true,
        tutorialEnabled = true,
        camShake = true,
        autoSave = true,
        saveInterval = 300 -- Seconds
    },
    interface = {
        alwaysShowStats = true,
        hudSize = 5, -- 1-10
        textSize = 5, -- 1-10
        notifications = true,
        chatEnabled = true
    }
}

-- Configuration
local CONFIG = {
    mainFrameSize = UDim2.new(0, 700, 0, 500),
    tabCount = 4, -- Audio, Graphics, Gameplay, Interface
    tabButtonSize = UDim2.new(0.25, -5, 0, 40),
    tabContentSize = UDim2.new(1, -40, 1, -100),
    sliderHeight = 35,
    toggleHeight = 40,
    animationDuration = 0.3
}

--[[ UI Creation Functions ]]--

-- Create the main UI
local function createMainUI()
    -- Create or find the ScreenGui
    local screenGui = PlayerGui:FindFirstChild("SettingsUI")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SettingsUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = PlayerGui
    end
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = CONFIG.mainFrameSize
    mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2)
    mainFrame.BackgroundColor3 = UIStyle.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false -- Start hidden
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = UIStyle.Colors.Primary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    -- Add corner radius to header (top corners only)
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Create header bottom to remove rounded corners on bottom
    local headerBottom = Instance.new("Frame")
    headerBottom.Name = "HeaderBottom"
    headerBottom.Size = UDim2.new(1, 0, 0, 12)
    headerBottom.Position = UDim2.new(0, 0, 1, -12)
    headerBottom.BackgroundColor3 = UIStyle.Colors.Primary
    headerBottom.BorderSizePixel = 0
    headerBottom.ZIndex = header.ZIndex
    headerBottom.Parent = header
    
    -- Add header title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.Font = UIStyle.Fonts.Bold
    title.TextSize = 24
    title.TextColor3 = UIStyle.Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Add close button
    local closeButton = ButtonFactory.createButton({
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0.5, -20),
        backgroundColor = Color3.fromRGB(231, 76, 60),
        text = "X",
        textSize = 18,
        font = UIStyle.Fonts.Bold,
        parent = header,
        callback = function()
            SettingsUI:hide()
            
            -- Save settings when closing
            saveSettings()
        end
    })
    
    -- Create tab buttons container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -40, 0, 40)
    tabContainer.Position = UDim2.new(0, 20, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = CONFIG.tabContentSize
    contentContainer.Position = UDim2.new(0, 20, 0, 110)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Create footer with buttons
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, -40, 0, 50)
    footer.Position = UDim2.new(0, 20, 1, -60)
    footer.BackgroundTransparency = 1
    footer.Parent = mainFrame
    
    -- Add reset to defaults button
    local resetButton = ButtonFactory.createButton({
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        backgroundColor = UIStyle.Colors.Warning,
        text = "Reset to Defaults",
        textSize = 16,
        parent = footer,
        callback = function()
            SettingsUI:resetToDefaults()
        end
    })
    
    -- Add save and close button
    local saveButton = ButtonFactory.createButton({
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(1, -150, 0, 0),
        backgroundColor = UIStyle.Colors.Success,
        text = "Save & Close",
        textSize = 16,
        parent = footer,
        callback = function()
            saveSettings()
            SettingsUI:hide()
            
            if UIManager then
                UIManager:createNotification({
                    message = "Settings saved successfully",
                    type = "success"
                })
            end
        end
    })
    
    -- Store references
    uiElements.mainFrame = mainFrame
    uiElements.tabContainer = tabContainer
    uiElements.contentContainer = contentContainer
    uiElements.screenGui = screenGui
    uiElements.footer = footer
    
    return mainFrame
end

-- Create the tabs
local function createTabs()
    local tabNames = {"Audio", "Graphics", "Gameplay", "Interface"}
    local tabButtons = {}
    local tabContents = {}
    
    -- Create tab buttons
    for i, tabName in ipairs(tabNames) do
        local button = ButtonFactory.createButton({
            size = CONFIG.tabButtonSize,
            position = UDim2.new((i - 1) * 0.25, (i - 1) * 5, 0, 0),
            backgroundColor = i == 1 and UIStyle.Colors.Primary or UIStyle.Colors.Secondary,
            text = tabName,
            textSize = 16,
            parent = uiElements.tabContainer,
            callback = function()
                SettingsUI:switchTab(tabName)
            end
        })
        
        tabButtons[tabName] = button
        
        -- Create content frame for this tab
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Name = tabName .. "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 6
        contentFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
        contentFrame.Visible = i == 1 -- Only first tab visible by default
        contentFrame.Parent = uiElements.contentContainer
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = contentFrame
        
        -- Add layout
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 15)
        layout.Parent = contentFrame
        
        tabContents[tabName] = contentFrame
    end
    
    -- Store references
    uiElements.tabs = {
        buttons = tabButtons,
        contents = tabContents
    }
    uiElements.activeTab = "Audio"
    
    -- Now populate each tab's content
    populateAudioSettings(tabContents["Audio"])
    populateGraphicsSettings(tabContents["Graphics"])
    populateGameplaySettings(tabContents["Gameplay"])
    populateInterfaceSettings(tabContents["Interface"])
    
    -- Update canvas sizes after population
    for _, contentFrame in pairs(tabContents) do
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentFrame.UIListLayout.AbsoluteContentSize.Y + 20)
    end
end

-- Create a slider control
local function createSlider(parent, label, value, min, max, onChange)
    local container = Instance.new("Frame")
    container.Name = label .. "Container"
    container.Size = UDim2.new(1, 0, 0, CONFIG.sliderHeight)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(0.3, 0, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = UIStyle.Fonts.Regular
    labelText.TextSize = 16
    labelText.TextColor3 = UIStyle.Colors.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container
    
    -- Slider background
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "SliderBackground"
    sliderBg.Size = UDim2.new(0.5, 0, 0, 10)
    sliderBg.Position = UDim2.new(0.3, 0, 0.5, -5)
    sliderBg.BackgroundColor3 = UIStyle.Colors.Secondary
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    
    -- Add corner radius
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 5)
    cornerBg.Parent = sliderBg
    
    -- Slider fill
    local fillAmt = ((value - min) / (max - min))
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.new(fillAmt, 0, 1, 0)
    sliderFill.BackgroundColor3 = UIStyle.Colors.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    -- Add corner radius to fill
    local cornerFill = Instance.new("UICorner")
    cornerFill.CornerRadius = UDim.new(0, 5)
    cornerFill.Parent = sliderFill
    
    -- Slider thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.Position = UDim2.new(fillAmt, -8, 0.5, -8)
    thumb.BackgroundColor3 = UIStyle.Colors.Text
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = sliderBg
    
    -- Add corner radius to thumb
    local cornerThumb = Instance.new("UICorner")
    cornerThumb.CornerRadius = UDim.new(0, 8)
    cornerThumb.Parent = thumb
    
    -- Value display
    local valueText = Instance.new("TextLabel")
    valueText.Name = "Value"
    valueText.Size = UDim2.new(0.1, 0, 1, 0)
    valueText.Position = UDim2.new(0.85, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.Font = UIStyle.Fonts.Bold
    valueText.TextSize = 16
    valueText.TextColor3 = UIStyle.Colors.Text
    valueText.Parent = container
    
    -- Slider interaction
    local isDragging = false
    
    local function updateSlider(position)
        local xOffset = math.clamp(position - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
        local percent = xOffset / sliderBg.AbsoluteSize.X
        
        -- Update visual elements
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        thumb.Position = UDim2.new(percent, -8, 0.5, -8)
        
        -- Calculate value based on range
        local newValue = math.floor(min + (percent * (max - min)))
        valueText.Text = tostring(newValue)
        
        -- Call onChange callback
        if onChange then
            onChange(newValue)
        end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateSlider(input.Position.X)
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)
    
    thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    
    -- Store reference
    uiElements.sliders[label] = {
        container = container,
        fill = sliderFill,
        thumb = thumb,
        valueText = valueText,
        updateValue = function(newValue)
            local percent = (newValue - min) / (max - min)
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            thumb.Position = UDim2.new(percent, -8, 0.5, -8)
            valueText.Text = tostring(newValue)
        end
    }
    
    return container
end

-- Create a toggle control
local function createToggle(parent, label, value, onChange)
    local container = Instance.new("Frame")
    container.Name = label .. "Container"
    container.Size = UDim2.new(1, 0, 0, CONFIG.toggleHeight)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(0.7, 0, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = UIStyle.Fonts.Regular
    labelText.TextSize = 16
    labelText.TextColor3 = UIStyle.Colors.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = container
    
    -- Toggle background
    local toggleBg = Instance.new("Frame")
    toggleBg.Name = "ToggleBackground"
    toggleBg.Size = UDim2.new(0, 50, 0, 26)
    toggleBg.Position = UDim2.new(0.8, 0, 0.5, -13)
    toggleBg.BackgroundColor3 = value and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    
    -- Add corner radius
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 13)
    cornerBg.Parent = toggleBg
    
    -- Toggle indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(value and 1 or 0, value and -23 or 3, 0.5, -10)
    indicator.BackgroundColor3 = UIStyle.Colors.Text
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleBg
    
    -- Add corner radius to indicator
    local cornerIndicator = Instance.new("UICorner")
    cornerIndicator.CornerRadius = UDim.new(0, 10)
    cornerIndicator.Parent = indicator
    
    -- Make toggle interactive
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    button.Activated:Connect(function()
        value = not value
        
        -- Update visual state
        toggleBg.BackgroundColor3 = value and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
        
        -- Animate indicator
        TweenService:Create(
            indicator,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(value and 1 or 0, value and -23 or 3, 0.5, -10) }
        ):Play()
        
        -- Call onChange callback
        if onChange then
            onChange(value)
        end
    end)
    
    -- Store reference
    uiElements.toggles[label] = {
        container = container,
        background = toggleBg,
        indicator = indicator,
        updateValue = function(newValue)
            value = newValue
            toggleBg.BackgroundColor3 = value and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
            indicator.Position = UDim2.new(value and 1 or 0, value and -23 or 3, 0.5, -10)
        end
    }
    
    return container
end

-- Create category label
local function createCategoryLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Name = text .. "Label"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = UIStyle.Fonts.Bold
    label.TextSize = 18
    label.TextColor3 = UIStyle.Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    -- Add separator line
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.Position = UDim2.new(0, 0, 1, 0)
    separator.BackgroundColor3 = UIStyle.Colors.TextDisabled
    separator.BorderSizePixel = 0
    separator.Parent = label
    
    return label
end

--[[ Tab Content Creation Functions ]]--

-- Populate Audio settings tab
local function populateAudioSettings(frame)
    -- Create category: Music
    createCategoryLabel(frame, "Music")
    
    -- Music volume slider
    createSlider(frame, "Music Volume", settings.audio.musicVolume, 0, 100, function(value)
        settings.audio.musicVolume = value
        -- Apply setting immediately
        if ClientRegistry then
            local audioSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("AudioSystem")
            if audioSystem and audioSystem.setMusicVolume then
                audioSystem.setMusicVolume(value / 100)
            end
        end
    end)
    
    -- Create category: Sound Effects
    createCategoryLabel(frame, "Sound Effects")
    
    -- SFX volume slider
    createSlider(frame, "SFX Volume", settings.audio.sfxVolume, 0, 100, function(value)
        settings.audio.sfxVolume = value
        -- Apply setting immediately
        if ClientRegistry then
            local audioSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("AudioSystem")
            if audioSystem and audioSystem.setSFXVolume then
                audioSystem.setSFXVolume(value / 100)
            end
        end
    end)
    
    -- Create category: Ambient
    createCategoryLabel(frame, "Ambient")
    
    -- Ambient volume slider
    createSlider(frame, "Ambient Volume", settings.audio.ambientVolume, 0, 100, function(value)
        settings.audio.ambientVolume = value
        -- Apply setting immediately
        if ClientRegistry then
            local audioSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("AudioSystem")
            if audioSystem and audioSystem.setAmbientVolume then
                audioSystem.setAmbientVolume(value / 100)
            end
        end
    end)
    
    -- Create category: General
    createCategoryLabel(frame, "General")
    
    -- Mute all toggle
    createToggle(frame, "Mute All Audio", settings.audio.muteAll, function(value)
        settings.audio.muteAll = value
        -- Apply setting immediately
        if ClientRegistry then
            local audioSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("AudioSystem")
            if audioSystem and audioSystem.setMasterMute then
                audioSystem.setMasterMute(value)
            end
        end
    end)
end

-- Populate Graphics settings tab
local function populateGraphicsSettings(frame)
    -- Create category: Quality
    createCategoryLabel(frame, "Quality")
    
    -- Graphics quality slider
    createSlider(frame, "Graphics Quality", settings.graphics.quality, 1, 10, function(value)
        settings.graphics.quality = value
        -- Apply setting immediately
        UserGameSettings.SavedQualityLevel = value
    end)
    
    -- Create category: Features
    createCategoryLabel(frame, "Features")
    
    -- Shadows toggle
    createToggle(frame, "Shadows", settings.graphics.shadows, function(value)
        settings.graphics.shadows = value
        -- Apply setting immediately
        if ClientRegistry then
            local graphicsSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("GraphicsSystem")
            if graphicsSystem and graphicsSystem.setShadowsEnabled then
                graphicsSystem.setShadowsEnabled(value)
            end
        end
    end)
    
    -- Effects toggle
    createToggle(frame, "Special Effects", settings.graphics.effects, function(value)
        settings.graphics.effects = value
        -- Apply setting immediately
        if ClientRegistry then
            local graphicsSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("GraphicsSystem")
            if graphicsSystem and graphicsSystem.setEffectsEnabled then
                graphicsSystem.setEffectsEnabled(value)
            end
        end
    end)
    
    -- VSync toggle
    createToggle(frame, "Vertical Sync", settings.graphics.vSync, function(value)
        settings.graphics.vSync = value
        -- Apply setting immediately
        UserGameSettings.VSync = value
    end)
end

-- Populate Gameplay settings tab
local function populateGameplaySettings(frame)
    -- Create category: Tutorial
    createCategoryLabel(frame, "Tutorial")
    
    -- Hints toggle
    createToggle(frame, "Show Hints", settings.gameplay.hintsEnabled, function(value)
        settings.gameplay.hintsEnabled = value
        -- Apply setting immediately
        if ClientRegistry then
            local tutorialSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("TutorialSystem")
            if tutorialSystem and tutorialSystem.setHintsEnabled then
                tutorialSystem.setHintsEnabled(value)
            end
        end
    end)
    
    -- Tutorial toggle
    createToggle(frame, "Tutorial Mode", settings.gameplay.tutorialEnabled, function(value)
        settings.gameplay.tutorialEnabled = value
        -- Apply setting immediately
        if ClientRegistry then
            local tutorialSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("TutorialSystem")
            if tutorialSystem and tutorialSystem.setTutorialEnabled then
                tutorialSystem.setTutorialEnabled(value)
            end
        end
    end)
    
    -- Create category: Camera
    createCategoryLabel(frame, "Camera")
    
    -- Camera shake toggle
    createToggle(frame, "Camera Shake", settings.gameplay.camShake, function(value)
        settings.gameplay.camShake = value
        -- Apply setting immediately
        if ClientRegistry then
            local cameraSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("CameraSystem")
            if cameraSystem and cameraSystem.setCameraShakeEnabled then
                cameraSystem.setCameraShakeEnabled(value)
            end
        end
    end)
    
    -- Create category: Save
    createCategoryLabel(frame, "Save")
    
    -- Auto save toggle
    createToggle(frame, "Auto Save", settings.gameplay.autoSave, function(value)
        settings.gameplay.autoSave = value
        -- Apply setting immediately
        if ClientRegistry then
            local dataSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("DataSystem")
            if dataSystem and dataSystem.setAutoSaveEnabled then
                dataSystem.setAutoSaveEnabled(value)
            end
        end
    end)
    
    -- Save interval slider
    createSlider(frame, "Save Interval (seconds)", settings.gameplay.saveInterval, 60, 600, function(value)
        settings.gameplay.saveInterval = value
        -- Apply setting immediately
        if ClientRegistry then
            local dataSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("DataSystem")
            if dataSystem and dataSystem.setSaveInterval then
                dataSystem.setSaveInterval(value)
            end
        end
    end)
end

-- Populate Interface settings tab
local function populateInterfaceSettings(frame)
    -- Create category: Heads-Up Display
    createCategoryLabel(frame, "Heads-Up Display")
    
    -- Always show stats toggle
    createToggle(frame, "Always Show Stats", settings.interface.alwaysShowStats, function(value)
        settings.interface.alwaysShowStats = value
        -- Apply setting immediately
        if ClientRegistry then
            local uiSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("UISystem")
            if uiSystem and uiSystem.setAlwaysShowStats then
                uiSystem.setAlwaysShowStats(value)
            end
        end
    end)
    
    -- HUD size slider
    createSlider(frame, "HUD Size", settings.interface.hudSize, 1, 10, function(value)
        settings.interface.hudSize = value
        -- Apply setting immediately
        if ClientRegistry then
            local uiSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("UISystem")
            if uiSystem and uiSystem.setHUDSize then
                uiSystem.setHUDSize(value / 10) -- Normalize to 0-1
            end
        end
    end)
    
    -- Text size slider
    createSlider(frame, "Text Size", settings.interface.textSize, 1, 10, function(value)
        settings.interface.textSize = value
        -- Apply setting immediately
        if ClientRegistry then
            local uiSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("UISystem")
            if uiSystem and uiSystem.setTextSize then
                uiSystem.setTextSize(value / 10) -- Normalize to 0-1
            end
        end
    end)
    
    -- Create category: Communication
    createCategoryLabel(frame, "Communication")
    
    -- Notifications toggle
    createToggle(frame, "Show Notifications", settings.interface.notifications, function(value)
        settings.interface.notifications = value
        -- Apply setting immediately
        if ClientRegistry then
            local uiSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("UISystem")
            if uiSystem and uiSystem.setNotificationsEnabled then
                uiSystem.setNotificationsEnabled(value)
            end
        end
    end)
    
    -- Chat toggle
    createToggle(frame, "Enable Chat", settings.interface.chatEnabled, function(value)
        settings.interface.chatEnabled = value
        -- Apply setting immediately
        if ClientRegistry then
            local chatSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("ChatSystem")
            if chatSystem and chatSystem.setChatEnabled then
                chatSystem.setChatEnabled(value)
            end
        end
    end)
end

--[[ Helper Functions ]]--

-- Save settings to player data
local function saveSettings()
    if not ClientRegistry then
        return
    end
    
    local dataSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("DataSystem")
    if dataSystem and dataSystem.saveSettings then
        dataSystem.saveSettings("userSettings", settings)
    else
        -- Fallback to storing in local storage
        local success, err = pcall(function()
            local settingsJson = game:GetService("HttpService"):JSONEncode(settings)
            LocalPlayer:SetAttribute("userSettings", settingsJson)
        end)
        
        if not success then
            warn("Failed to save settings:", err)
        end
    end
end

-- Load settings from player data
local function loadSettings()
    if not ClientRegistry then
        return
    end
    
    local dataSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("DataSystem")
    
    if dataSystem and dataSystem.loadSettings then
        local savedSettings = dataSystem.loadSettings("userSettings")
        if savedSettings then
            -- Merge saved settings into current settings
            for category, values in pairs(savedSettings) do
                if settings[category] then
                    for key, value in pairs(values) do
                        if settings[category][key] ~= nil then
                            settings[category][key] = value
                        end
                    end
                end
            end
        end
    else
        -- Fallback to loading from local storage
        local settingsJson = LocalPlayer:GetAttribute("userSettings")
        if settingsJson then
            local success, savedSettings = pcall(function()
                return game:GetService("HttpService"):JSONDecode(settingsJson)
            end)
            
            if success and savedSettings then
                -- Merge saved settings into current settings
                for category, values in pairs(savedSettings) do
                    if settings[category] then
                        for key, value in pairs(values) do
                            if settings[category][key] ~= nil then
                                settings[category][key] = value
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Update UI elements with loaded settings
    updateUIFromSettings()
end

-- Update UI elements to reflect current settings
local function updateUIFromSettings()
    -- Update audio sliders
    if uiElements.sliders["Music Volume"] then
        uiElements.sliders["Music Volume"].updateValue(settings.audio.musicVolume)
    end
    
    if uiElements.sliders["SFX Volume"] then
        uiElements.sliders["SFX Volume"].updateValue(settings.audio.sfxVolume)
    end
    
    if uiElements.sliders["Ambient Volume"] then
        uiElements.sliders["Ambient Volume"].updateValue(settings.audio.ambientVolume)
    end
    
    -- Update audio toggles
    if uiElements.toggles["Mute All Audio"] then
        uiElements.toggles["Mute All Audio"].updateValue(settings.audio.muteAll)
    end
    
    -- Update graphics sliders
    if uiElements.sliders["Graphics Quality"] then
        uiElements.sliders["Graphics Quality"].updateValue(settings.graphics.quality)
    end
    
    -- Update graphics toggles
    if uiElements.toggles["Shadows"] then
        uiElements.toggles["Shadows"].updateValue(settings.graphics.shadows)
    end
    
    if uiElements.toggles["Special Effects"] then
        uiElements.toggles["Special Effects"].updateValue(settings.graphics.effects)
    end
    
    if uiElements.toggles["Vertical Sync"] then
        uiElements.toggles["Vertical Sync"].updateValue(settings.graphics.vSync)
    end
    
    -- Update gameplay toggles and sliders
    if uiElements.toggles["Show Hints"] then
        uiElements.toggles["Show Hints"].updateValue(settings.gameplay.hintsEnabled)
    end
    
    if uiElements.toggles["Tutorial Mode"] then
        uiElements.toggles["Tutorial Mode"].updateValue(settings.gameplay.tutorialEnabled)
    end
    
    if uiElements.toggles["Camera Shake"] then
        uiElements.toggles["Camera Shake"].updateValue(settings.gameplay.camShake)
    end
    
    if uiElements.toggles["Auto Save"] then
        uiElements.toggles["Auto Save"].updateValue(settings.gameplay.autoSave)
    end
    
    if uiElements.sliders["Save Interval (seconds)"] then
        uiElements.sliders["Save Interval (seconds)"].updateValue(settings.gameplay.saveInterval)
    end
    
    -- Update interface toggles and sliders
    if uiElements.toggles["Always Show Stats"] then
        uiElements.toggles["Always Show Stats"].updateValue(settings.interface.alwaysShowStats)
    end
    
    if uiElements.sliders["HUD Size"] then
        uiElements.sliders["HUD Size"].updateValue(settings.interface.hudSize)
    end
    
    if uiElements.sliders["Text Size"] then
        uiElements.sliders["Text Size"].updateValue(settings.interface.textSize)
    end
    
    if uiElements.toggles["Show Notifications"] then
        uiElements.toggles["Show Notifications"].updateValue(settings.interface.notifications)
    end
    
    if uiElements.toggles["Enable Chat"] then
        uiElements.toggles["Enable Chat"].updateValue(settings.interface.chatEnabled)
    end
}

--[[ Public API Functions ]]--

-- Switch active tab
function SettingsUI:switchTab(tabName)
    if not uiElements.tabs or not uiElements.tabs.buttons[tabName] or not uiElements.tabs.contents[tabName] then
        return
    end
    
    -- Update tab button colors
    for name, button in pairs(uiElements.tabs.buttons) do
        button.BackgroundColor3 = name == tabName and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
    end
    
    -- Show/hide tab contents
    for name, content in pairs(uiElements.tabs.contents) do
        content.Visible = name == tabName
    end
    
    uiElements.activeTab = tabName
end

-- Reset settings to defaults
function SettingsUI:resetToDefaults()
    -- Default values
    local defaultSettings = {
        audio = {
            musicVolume = 50,
            sfxVolume = 70,
            ambientVolume = 60,
            muteAll = false
        },
        graphics = {
            quality = 7,
            shadows = true,
            effects = true,
            vSync = true
        },
        gameplay = {
            hintsEnabled = true,
            tutorialEnabled = true,
            camShake = true,
            autoSave = true,
            saveInterval = 300
        },
        interface = {
            alwaysShowStats = true,
            hudSize = 5,
            textSize = 5,
            notifications = true,
            chatEnabled = true
        }
    }
    
    -- Show confirmation dialog
    if UIManager then
        UIManager:createModal({
            title = "Reset Settings",
            message = "Are you sure you want to reset all settings to default values?",
            buttons = {
                {
                    text = "Yes",
                    color = UIStyle.Colors.Primary,
                    callback = function()
                        -- Copy default settings
                        settings = {
                            audio = table.clone(defaultSettings.audio),
                            graphics = table.clone(defaultSettings.graphics),
                            gameplay = table.clone(defaultSettings.gameplay),
                            interface = table.clone(defaultSettings.interface)
                        }
                        
                        -- Update UI
                        updateUIFromSettings()
                        
                        -- Apply settings
                        applyAllSettings()
                        
                        -- Show confirmation
                        UIManager:createNotification({
                            message = "Settings reset to defaults",
                            type = "success"
                        })
                    end
                },
                {
                    text = "Cancel",
                    color = UIStyle.Colors.Secondary
                }
            }
        })
    else
        -- Fallback if no UIManager
        settings = {
            audio = table.clone(defaultSettings.audio),
            graphics = table.clone(defaultSettings.graphics),
            gameplay = table.clone(defaultSettings.gameplay),
            interface = table.clone(defaultSettings.interface)
        }
        
        -- Update UI
        updateUIFromSettings()
        
        -- Apply settings
        applyAllSettings()
    end
end

-- Apply all current settings
function SettingsUI:applyAllSettings()
    if not ClientRegistry then
        return
    end
    
    -- Apply audio settings
    local audioSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("AudioSystem")
    if audioSystem then
        if audioSystem.setMusicVolume then
            audioSystem.setMusicVolume(settings.audio.musicVolume / 100)
        end
        
        if audioSystem.setSFXVolume then
            audioSystem.setSFXVolume(settings.audio.sfxVolume / 100)
        end
        
        if audioSystem.setAmbientVolume then
            audioSystem.setAmbientVolume(settings.audio.ambientVolume / 100)
        end
        
        if audioSystem.setMasterMute then
            audioSystem.setMasterMute(settings.audio.muteAll)
        end
    end
    
    -- Apply graphics settings
    UserGameSettings.SavedQualityLevel = settings.graphics.quality
    UserGameSettings.VSync = settings.graphics.vSync
    
    local graphicsSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("GraphicsSystem")
    if graphicsSystem then
        if graphicsSystem.setShadowsEnabled then
            graphicsSystem.setShadowsEnabled(settings.graphics.shadows)
        end
        
        if graphicsSystem.setEffectsEnabled then
            graphicsSystem.setEffectsEnabled(settings.graphics.effects)
        end
    end
    
    -- Apply gameplay settings
    local tutorialSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("TutorialSystem")
    if tutorialSystem then
        if tutorialSystem.setHintsEnabled then
            tutorialSystem.setHintsEnabled(settings.gameplay.hintsEnabled)
        end
        
        if tutorialSystem.setTutorialEnabled then
            tutorialSystem.setTutorialEnabled(settings.gameplay.tutorialEnabled)
        end
    end
    
    local cameraSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("CameraSystem")
    if cameraSystem and cameraSystem.setCameraShakeEnabled then
        cameraSystem.setCameraShakeEnabled(settings.gameplay.camShake)
    end
    
    local dataSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("DataSystem")
    if dataSystem then
        if dataSystem.setAutoSaveEnabled then
            dataSystem.setAutoSaveEnabled(settings.gameplay.autoSave)
        end
        
        if dataSystem.setSaveInterval then
            dataSystem.setSaveInterval(settings.gameplay.saveInterval)
        end
    end
    
    -- Apply interface settings
    local uiSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("UISystem")
    if uiSystem then
        if uiSystem.setAlwaysShowStats then
            uiSystem.setAlwaysShowStats(settings.interface.alwaysShowStats)
        end
        
        if uiSystem.setHUDSize then
            uiSystem.setHUDSize(settings.interface.hudSize / 10)
        end
        
        if uiSystem.setTextSize then
            uiSystem.setTextSize(settings.interface.textSize / 10)
        end
        
        if uiSystem.setNotificationsEnabled then
            uiSystem.setNotificationsEnabled(settings.interface.notifications)
        end
    end
    
    local chatSystem = ClientRegistry.getSystem and ClientRegistry.getSystem("ChatSystem")
    if chatSystem and chatSystem.setChatEnabled then
        chatSystem.setChatEnabled(settings.interface.chatEnabled)
    end
}

-- Initialize the UI
function SettingsUI:initialize()
    -- Create base UI if not already created
    if not uiElements.mainFrame then
        createMainUI()
    end
    
    if not uiElements.tabs or not next(uiElements.tabs) then
        createTabs()
    end
    
    -- Load saved settings
    loadSettings()
    
    -- Apply settings
    self:applyAllSettings()
    
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("SettingsUI", self)
    end
    
    -- Register with UIManager if available
    if UIManager and UIManager.registerUI then
        UIManager:registerUI("SettingsUI", self)
    end
    
    return self
end

-- Show the UI
function SettingsUI:show()
    if not uiElements.mainFrame then
        self:initialize()
    end
    
    -- Show the main frame with animation
    uiElements.mainFrame.Visible = true
    uiElements.mainFrame.BackgroundTransparency = 1
    uiElements.mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.55, -CONFIG.mainFrameSize.Y.Offset / 2)
    
    -- Create and play entrance animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    positionTween:Play()
    transparencyTween:Play()
    
    -- Load latest settings
    loadSettings()
    
    return true
end

-- Hide the UI
function SettingsUI:hide()
    if not uiElements.mainFrame then
        return false
    end
    
    -- Create and play exit animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.55, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    
    -- Hide after animation completes
    transparencyTween.Completed:Connect(function()
        uiElements.mainFrame.Visible = false
    end)
    
    positionTween:Play()
    transparencyTween:Play()
    
    -- Save settings when hiding
    saveSettings()
    
    return true
end

-- Initialize on module load
SettingsUI:initialize()

-- Return the module
return SettingsUI
