--[[
    TutorialClient.client.luau
    
    Client-side implementation for the Gym Tycoon tutorial system.
    Handles UI display and user interaction for tutorials.
]]

local TutorialClient = {}
TutorialClient._version = "1.0.0"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Local references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local EventBridge
local tutorialUI

-- UI configuration
local CONFIG = {
    frameBackgroundColor = Color3.fromRGB(40, 40, 40),
    frameBorderColor = Color3.fromRGB(80, 80, 80),
    titleTextColor = Color3.fromRGB(255, 255, 255),
    descTextColor = Color3.fromRGB(220, 220, 220),
    buttonBackgroundColor = Color3.fromRGB(60, 60, 60),
    buttonHoverColor = Color3.fromRGB(80, 80, 80),
    buttonTextColor = Color3.fromRGB(255, 255, 255),
    highlightColor = Color3.fromRGB(255, 235, 0),
    tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    cornerRadius = UDim.new(0, 8),
}

-- Debug logging
local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then
        print("[TutorialClient]", ...)
    end
end

-- Track active tutorials and highlights
local activeTutorials = {}
local activeHighlights = {}
local tutorialQueue = {}
local isTutorialPlaying = false

--[[ UI Creation ]]--

-- Create the main tutorial UI
local function createTutorialUI()
    if tutorialUI then return tutorialUI end
    
    debugPrint("Creating Tutorial UI")
    
    -- Main ScreenGui
    tutorialUI = Instance.new("ScreenGui")
    tutorialUI.Name = "TutorialUI"
    tutorialUI.ResetOnSpawn = false
    tutorialUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    tutorialUI.Parent = playerGui
    
    -- Tutorial container (for positioning)
    local tutorialContainer = Instance.new("Frame")
    tutorialContainer.Name = "TutorialContainer"
    tutorialContainer.AnchorPoint = Vector2.new(0.5, 0)
    tutorialContainer.Position = UDim2.new(0.5, 0, 0.15, 0)
    tutorialContainer.Size = UDim2.new(0, 400, 0, 0) -- Height will be determined by content
    tutorialContainer.BackgroundTransparency = 1
    tutorialContainer.Parent = tutorialUI
    
    -- Settings button
    local settingsButton = Instance.new("ImageButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.AnchorPoint = Vector2.new(1, 0)
    settingsButton.Position = UDim2.new(0.98, 0, 0.02, 0)
    settingsButton.Size = UDim2.new(0, 40, 0, 40)
    settingsButton.Image = "rbxassetid://3926307971" -- Settings icon
    settingsButton.ImageRectOffset = Vector2.new(324, 124)
    settingsButton.ImageRectSize = Vector2.new(36, 36)
    settingsButton.BackgroundTransparency = 0.5
    settingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    settingsButton.Parent = tutorialUI
    
    -- Add corner to settings button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONFIG.cornerRadius
    corner.Parent = settingsButton
    
    -- Tutorial menu (hidden by default)
    local tutorialMenu = Instance.new("Frame")
    tutorialMenu.Name = "TutorialMenu"
    tutorialMenu.AnchorPoint = Vector2.new(0.5, 0.5)
    tutorialMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
    tutorialMenu.Size = UDim2.new(0, 500, 0, 400)
    tutorialMenu.BackgroundColor3 = CONFIG.frameBackgroundColor
    tutorialMenu.BorderSizePixel = 0
    tutorialMenu.Visible = false
    tutorialMenu.Parent = tutorialUI
    
    -- Add corner to menu
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = CONFIG.cornerRadius
    menuCorner.Parent = tutorialMenu
    
    -- Menu title
    local menuTitle = Instance.new("TextLabel")
    menuTitle.Name = "Title"
    menuTitle.Position = UDim2.new(0, 20, 0, 10)
    menuTitle.Size = UDim2.new(1, -40, 0, 40)
    menuTitle.BackgroundTransparency = 1
    menuTitle.Text = "Tutorial Menu"
    menuTitle.TextColor3 = CONFIG.titleTextColor
    menuTitle.Font = Enum.Font.GothamBold
    menuTitle.TextSize = 24
    menuTitle.TextXAlignment = Enum.TextXAlignment.Left
    menuTitle.Parent = tutorialMenu
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = tutorialMenu
    
    -- Add corner to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = CONFIG.cornerRadius
    closeCorner.Parent = closeButton
    
    -- Tabs (Basic, Advanced, Settings)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "Tabs"
    tabContainer.Position = UDim2.new(0, 20, 0, 60)
    tabContainer.Size = UDim2.new(1, -40, 0, 30)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = tutorialMenu
    
    -- Tab buttons
    local function createTab(name, index)
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Position = UDim2.new((index - 1) * 0.33, 0, 0, 0)
        tab.Size = UDim2.new(0.33, -5, 1, 0)
        tab.BackgroundColor3 = index == 1 and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
        tab.Text = name
        tab.TextColor3 = Color3.new(1, 1, 1)
        tab.Font = Enum.Font.GothamSemibold
        tab.TextSize = 16
        tab.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = CONFIG.cornerRadius
        tabCorner.Parent = tab
        
        return tab
    end
    
    local basicTab = createTab("Basic", 1)
    local advancedTab = createTab("Advanced", 2)
    local settingsTab = createTab("Settings", 3)
    
    -- Content container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Position = UDim2.new(0, 20, 0, 100)
    contentContainer.Size = UDim2.new(1, -40, 1, -120)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 6
    contentContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    contentContainer.Parent = tutorialMenu
    
    -- Layout for content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.Parent = contentContainer
    
    -- Settings content (hidden by default)
    local settingsContent = Instance.new("Frame")
    settingsContent.Name = "SettingsContent"
    settingsContent.Size = UDim2.new(1, -40, 1, -120)
    settingsContent.Position = UDim2.new(0, 20, 0, 100)
    settingsContent.BackgroundTransparency = 1
    settingsContent.Visible = false
    settingsContent.Parent = tutorialMenu
    
    -- Settings options
    local function createSettingToggle(name, description, yPos)
        local container = Instance.new("Frame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 0, 50)
        container.Position = UDim2.new(0, 0, 0, yPos)
        container.BackgroundTransparency = 1
        container.Parent = settingsContent
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = description
        label.TextColor3 = CONFIG.descTextColor
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = container
        
        local toggle = Instance.new("Frame")
        toggle.Name = "Toggle"
        toggle.Size = UDim2.new(0, 50, 0, 25)
        toggle.Position = UDim2.new(1, -50, 0.5, -12.5)
        toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggle.Parent = container
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggle
        
        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, 21, 0, 21)
        knob.Position = UDim2.new(0, 2, 0.5, -10.5)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = toggle
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        
        toggle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local isOn = toggle.Knob.Position.X.Offset > 25
                
                local targetPos = isOn and UDim2.new(0, 2, 0.5, -10.5) or UDim2.new(0, 27, 0.5, -10.5)
                local targetColor = isOn and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(0, 170, 255)
                
                TweenService:Create(knob, CONFIG.tweenInfo, {Position = targetPos}):Play()
                TweenService:Create(toggle, CONFIG.tweenInfo, {BackgroundColor3 = targetColor}):Play()
                
                -- Update tutorial settings
                local updateEvent = EventBridge:FindFirstChild("UpdateTutorialSettings")
                if updateEvent then
                    local settings = {}
                    settings[name] = not isOn
                    updateEvent:FireServer(settings)
                end
            end
        end)
        
        return {toggle = toggle, knob = knob}
    end
    
    local enabledToggle = createSettingToggle("enabled", "Enable Tutorials", 0)
    local highlightsToggle = createSettingToggle("showHighlights", "Show UI Highlights", 60)
    local popupsToggle = createSettingToggle("showPopups", "Show Tutorial Popups", 120)
    local autoStartToggle = createSettingToggle("autoStart", "Auto-start Tutorials", 180)
    
    -- Button to reset tutorial progress
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Size = UDim2.new(0.6, 0, 0, 40)
    resetButton.Position = UDim2.new(0.2, 0, 0, 250)
    resetButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    resetButton.Text = "Reset Tutorial Progress"
    resetButton.TextColor3 = Color3.new(1, 1, 1)
    resetButton.Font = Enum.Font.GothamBold
    resetButton.TextSize = 18
    resetButton.Parent = settingsContent
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = CONFIG.cornerRadius
    resetCorner.Parent = resetButton
    
    -- Advanced tab content (hidden by default)
    local advancedContent = Instance.new("Frame")
    advancedContent.Name = "AdvancedContent"
    advancedContent.Size = UDim2.new(1, -40, 1, -120)
    advancedContent.Position = UDim2.new(0, 20, 0, 100)
    advancedContent.BackgroundTransparency = 1
    advancedContent.Visible = false
    advancedContent.Parent = tutorialMenu
    
    -- Create event handlers for menu
    closeButton.MouseButton1Click:Connect(function()
        tutorialMenu.Visible = false
    end)
    
    settingsButton.MouseButton1Click:Connect(function()
        tutorialMenu.Visible = not tutorialMenu.Visible
    end)
    
    local function switchTab(tabName)
        -- Update tab buttons
        basicTab.BackgroundColor3 = tabName == "Basic" and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
        advancedTab.BackgroundColor3 = tabName == "Advanced" and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
        settingsTab.BackgroundColor3 = tabName == "Settings" and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
        
        -- Show correct content
        contentContainer.Visible = tabName == "Basic"
        advancedContent.Visible = tabName == "Advanced"
        settingsContent.Visible = tabName == "Settings"
    end
    
    basicTab.MouseButton1Click:Connect(function()
        switchTab("Basic")
    end)
    
    advancedTab.MouseButton1Click:Connect(function()
        switchTab("Advanced")
    end)
    
    settingsTab.MouseButton1Click:Connect(function()
        switchTab("Settings")
    end)
    
    -- Update settings toggles when settings are loaded
    local function updateSettingsUI(settings)
        if not settings then return end
        
        -- Update enabled toggle
        local enabledPos = settings.enabled and UDim2.new(0, 27, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        local enabledColor = settings.enabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        enabledToggle.knob.Position = enabledPos
        enabledToggle.toggle.BackgroundColor3 = enabledColor
        
        -- Update highlights toggle
        local highlightsPos = settings.showHighlights and UDim2.new(0, 27, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        local highlightsColor = settings.showHighlights and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        highlightsToggle.knob.Position = highlightsPos
        highlightsToggle.toggle.BackgroundColor3 = highlightsColor
        
        -- Update popups toggle
        local popupsPos = settings.showPopups and UDim2.new(0, 27, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        local popupsColor = settings.showPopups and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        popupsToggle.knob.Position = popupsPos
        popupsToggle.toggle.BackgroundColor3 = popupsColor
        
        -- Update auto-start toggle
        local autoStartPos = settings.autoStart and UDim2.new(0, 27, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        local autoStartColor = settings.autoStart and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        autoStartToggle.knob.Position = autoStartPos
        autoStartToggle.toggle.BackgroundColor3 = autoStartColor
    end
    
    -- Handle reset button
    resetButton.MouseButton1Click:Connect(function()
        -- Create a confirmation dialog
        local confirmDialog = Instance.new("Frame")
        confirmDialog.Name = "ConfirmDialog"
        confirmDialog.Size = UDim2.new(0, 300, 0, 150)
        confirmDialog.Position = UDim2.new(0.5, -150, 0.5, -75)
        confirmDialog.BackgroundColor3 = CONFIG.frameBackgroundColor
        confirmDialog.BorderSizePixel = 0
        confirmDialog.ZIndex = 10
        confirmDialog.Parent = tutorialUI
        
        local confirmCorner = Instance.new("UICorner")
        confirmCorner.CornerRadius = CONFIG.cornerRadius
        confirmCorner.Parent = confirmDialog
        
        local confirmText = Instance.new("TextLabel")
        confirmText.Size = UDim2.new(1, -20, 0, 80)
        confirmText.Position = UDim2.new(0, 10, 0, 10)
        confirmText.BackgroundTransparency = 1
        confirmText.Text = "Are you sure you want to reset all tutorial progress? This cannot be undone."
        confirmText.TextColor3 = CONFIG.titleTextColor
        confirmText.Font = Enum.Font.Gotham
        confirmText.TextSize = 16
        confirmText.TextWrapped = true
        confirmText.ZIndex = 10
        confirmText.Parent = confirmDialog
        
        local confirmButton = Instance.new("TextButton")
        confirmButton.Size = UDim2.new(0.45, 0, 0, 40)
        confirmButton.Position = UDim2.new(0.025, 0, 1, -50)
        confirmButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        confirmButton.Text = "Reset"
        confirmButton.TextColor3 = Color3.new(1, 1, 1)
        confirmButton.Font = Enum.Font.GothamBold
        confirmButton.TextSize = 16
        confirmButton.ZIndex = 10
        confirmButton.Parent = confirmDialog
        
        local confirmButtonCorner = Instance.new("UICorner")
        confirmButtonCorner.CornerRadius = CONFIG.cornerRadius
        confirmButtonCorner.Parent = confirmButton
        
        local cancelButton = Instance.new("TextButton")
        cancelButton.Size = UDim2.new(0.45, 0, 0, 40)
        cancelButton.Position = UDim2.new(0.525, 0, 1, -50)
        cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        cancelButton.Text = "Cancel"
        cancelButton.TextColor3 = Color3.new(1, 1, 1)
        cancelButton.Font = Enum.Font.GothamBold
        cancelButton.TextSize = 16
        cancelButton.ZIndex = 10
        cancelButton.Parent = confirmDialog
        
        local cancelButtonCorner = Instance.new("UICorner")
        cancelButtonCorner.CornerRadius = CONFIG.cornerRadius
        cancelButtonCorner.Parent = cancelButton
        
        -- Add event handlers
        confirmButton.MouseButton1Click:Connect(function()
            -- Request tutorial reset
            local updateEvent = EventBridge:FindFirstChild("UpdateTutorialSettings")
            if updateEvent then
                updateEvent:FireServer({
                    completedTutorials = {}
                })
            end
            
            confirmDialog:Destroy()
        end)
        
        cancelButton.MouseButton1Click:Connect(function()
            confirmDialog:Destroy()
        end)
    end)
    
    -- Return the UI and functions
    return {
        ui = tutorialUI,
        container = tutorialContainer,
        menu = tutorialMenu,
        updateSettingsUI = updateSettingsUI,
        contentContainer = contentContainer,
        contentLayout = contentLayout
    }
end

-- Create a tutorial card for the tutorial menu
local function createTutorialCard(tutorialData)
    local uiTutorial = tutorialUI or createTutorialUI()
    local container = uiTutorial.contentContainer
    
    -- Main card frame
    local card = Instance.new("Frame")
    card.Name = "TutorialCard_" .. tutorialData.name
    card.Size = UDim2.new(1, -20, 0, 80)
    card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    card.BorderSizePixel = 0
    card.Parent = container
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONFIG.cornerRadius
    corner.Parent = card
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.7, 0, 0, 30)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = tutorialData.description or tutorialData.name
    title.TextColor3 = CONFIG.titleTextColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextWrapped = true
    title.Parent = card
    
    -- Status (completed/available)
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(0, 100, 0, 20)
    status.Position = UDim2.new(1, -115, 0, 10)
    status.BackgroundColor3 = tutorialData.completed and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 120, 255)
    status.Text = tutorialData.completed and "COMPLETED" or "AVAILABLE"
    status.TextColor3 = Color3.new(1, 1, 1)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.Parent = card
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = status
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -30, 0, 30)
    description.Position = UDim2.new(0, 15, 0, 35)
    description.BackgroundTransparency = 1
    description.Text = tutorialData.longDescription or "Click to start this tutorial"
    description.TextColor3 = CONFIG.descTextColor
    description.Font = Enum.Font.Gotham
    description.TextSize = 14
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = card
    
    -- Make card clickable
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Request tutorial
            local requestEvent = EventBridge:FindFirstChild("RequestTutorial")
            if requestEvent then
                tutorialUI.TutorialMenu.Visible = false
                requestEvent:FireServer(tutorialData.name)
            end
        end
    end)
    
    -- Update container canvas size
    container.CanvasSize = UDim2.new(0, 0, 0, container.UIListLayout.AbsoluteContentSize.Y + 20)
    
    return card
end

-- Create a tutorial popup
local function createTutorialPopup(tutorialData)
    -- If popup already exists for this tutorial, destroy it
    if activeTutorials[tutorialData.name] then
        activeTutorials[tutorialData.name]:Destroy()
        activeTutorials[tutorialData.name] = nil
    end
    
    local uiTutorial = tutorialUI or createTutorialUI()
    local container = uiTutorial.TutorialContainer
    
    -- Main frame
    local popup = Instance.new("Frame")
    popup.Name = "TutorialPopup_" .. tutorialData.name
    popup.Size = UDim2.new(1, 0, 0, tutorialData.image and 320 or 160)
    popup.BackgroundColor3 = CONFIG.frameBackgroundColor
    popup.BorderColor3 = CONFIG.frameBorderColor
    popup.BorderSizePixel = 2
    popup.Parent = container
    
    -- Store reference to popup
    activeTutorials[tutorialData.name] = popup
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONFIG.cornerRadius
    corner.Parent = popup
    
    -- Add a subtle drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = popup
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 10)
    shadowCorner.Parent = shadow
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = tutorialData.title or "Tutorial"
    title.TextColor3 = CONFIG.titleTextColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = popup
    
    -- Image (if provided)
    if tutorialData.image then
        local image = Instance.new("ImageLabel")
        image.Name = "Image"
        image.Size = UDim2.new(1, -40, 0, 140)
        image.Position = UDim2.new(0, 20, 0, 55)
        image.BackgroundColor3 = Color3.new(0, 0, 0)
        image.BackgroundTransparency = 0.5
        image.BorderSizePixel = 0
        image.Image = tutorialData.image
        image.ScaleType = Enum.ScaleType.Fit
        image.Parent = popup
        
        local imageCorner = Instance.new("UICorner")
        imageCorner.CornerRadius = UDim.new(0, 6)
        imageCorner.Parent = image
    end
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -40, 0, 80)
    description.Position = UDim2.new(0, 20, 0, tutorialData.image and 205 or 55)
    description.BackgroundTransparency = 1
    description.Text = tutorialData.description or ""
    description.TextColor3 = CONFIG.descTextColor
    description.Font = Enum.Font.Gotham
    description.TextSize = 18
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = popup
    
    -- Skip button
    local skipButton = Instance.new("TextButton")
    skipButton.Name = "SkipButton"
    skipButton.Size = UDim2.new(0, 80, 0, 30)
    skipButton.Position = UDim2.new(1, -100, 0, 15)
    skipButton.BackgroundColor3 = CONFIG.buttonBackgroundColor
    skipButton.Text = "Skip"
    skipButton.TextColor3 = CONFIG.buttonTextColor
    skipButton.Font = Enum.Font.GothamBold
    skipButton.TextSize = 16
    skipButton.Parent = popup
    
    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = CONFIG.cornerRadius
    skipCorner.Parent = skipButton
    
    -- Hover effects for skip button
    skipButton.MouseEnter:Connect(function()
        TweenService:Create(skipButton, CONFIG.tweenInfo, {
            BackgroundColor3 = CONFIG.buttonHoverColor
        }):Play()
    end)
    
    skipButton.MouseLeave:Connect(function()
        TweenService:Create(skipButton, CONFIG.tweenInfo, {
            BackgroundColor3 = CONFIG.buttonBackgroundColor
        }):Play()
    end)
    
    -- Skip button functionality
    skipButton.MouseButton1Click:Connect(function()
        TutorialClient.skipTutorial(tutorialData.name)
    end)
    
    -- Animate popup appearing
    popup.Position = UDim2.new(0, 0, -1, 0)
    popup.Size = UDim2.new(1, 0, 0, tutorialData.image and 320 or 160)
    
    TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Show appropriate UI highlights if needed
    if tutorialData.highlightSelector then
        TutorialClient.createHighlight(tutorialData.highlightSelector)
    end
    
    return popup
end

-- Create UI highlights for tutorial targets
function TutorialClient.createHighlight(selector)
    -- Get settings
    local getTutorialSettingsFunc = EventBridge:FindFirstChild("GetTutorialSettings")
    local settings = getTutorialSettingsFunc and getTutorialSettingsFunc:InvokeServer()
    
    if settings and not settings.showHighlights then
        return nil
    end
    
    -- Find all matching UI elements
    local uiElements = {}
    
    -- Handle special cases for common UI elements
    if selector == ".BuyPrompt" then
        -- Find all BuyPrompt objects in workspace
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Name:match("BuyPrompt") then
                table.insert(uiElements, prompt)
            end
        end
    elseif selector == ".StaffButton" then
        -- Find Staff button in UI
        for _, gui in pairs(playerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and 
               (gui.Name == "StaffButton" or gui.Name:match("Staff")) then
                table.insert(uiElements, gui)
            end
        end
    elseif selector == ".AllianceButton" then
        -- Find Alliance button in UI
        for _, gui in pairs(playerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and 
               (gui.Name == "AllianceButton" or gui.Name:match("Alliance")) then
                table.insert(uiElements, gui)
            end
        end
    elseif selector == ".SpecializationButton" then
        -- Find Specialization button in UI
        for _, gui in pairs(playerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and 
               (gui.Name == "SpecializationButton" or gui.Name:match("Specialization")) then
                table.insert(uiElements, gui)
            end
        end
    elseif selector == ".RebirthButton" then
        -- Find Rebirth button in UI
        for _, gui in pairs(playerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and 
               (gui.Name == "RebirthButton" or gui.Name:match("Rebirth")) then
                table.insert(uiElements, gui)
            end
        end
    end
    
    -- Create highlight for each matching element
    for _, element in ipairs(uiElements) do
        -- Check if highlight already exists
        local existingHighlight = activeHighlights[element]
        if existingHighlight and existingHighlight.Parent then
            continue
        end
        
        -- Create the highlight
        local highlight
        
        if element:IsA("GuiObject") then
            -- For UI elements
            highlight = Instance.new("UIStroke")
            highlight.Name = "TutorialHighlight"
            highlight.Color = CONFIG.highlightColor
            highlight.Thickness = 3
            highlight.Parent = element
            
            -- Add animation
            local originalThickness = highlight.Thickness
            
            -- Pulse animation
            spawn(function()
                local startTime = tick()
                local connection
                
                connection = RunService.Heartbeat:Connect(function()
                    if not highlight or not highlight.Parent then
                        connection:Disconnect()
                        return
                    end
                    
                    local elapsed = tick() - startTime
                    highlight.Thickness = originalThickness + math.sin(elapsed * 3) * 1.5
                end)
                
                -- Store for cleanup
                activeHighlights[element] = {
                    highlight = highlight,
                    connection = connection
                }
            end)
        else
            -- For 3D objects (like proximity prompts)
            highlight = Instance.new("Highlight")
            highlight.Name = "TutorialHighlight"
            highlight.FillColor = CONFIG.highlightColor
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = element.Parent
            highlight.Adornee = element.Parent
            
            -- Add animation
            local connection
            
            connection = RunService.Heartbeat:Connect(function()
                if not highlight or not highlight.Parent then
                    connection:Disconnect()
                    return
                end
                
                local elapsed = tick()
                highlight.FillTransparency = 0.3 + math.sin(elapsed * 3) * 0.2
            end)
            
            -- Store for cleanup
            activeHighlights[element] = {
                highlight = highlight,
                connection = connection
            }
        end
    end
end

-- Remove all UI highlights
function TutorialClient.clearHighlights()
    for element, highlight in pairs(activeHighlights) do
        if highlight.connection then
            highlight.connection:Disconnect()
        end
        
        if highlight.highlight and highlight.highlight.Parent then
            highlight.highlight:Destroy()
        end
    end
    
    activeHighlights = {}
end

--[[ Tutorial Handling ]]--

-- Show a tutorial
function TutorialClient.showTutorial(tutorialData)
    -- Check if tutorials are enabled
    local getTutorialSettingsFunc = EventBridge:FindFirstChild("GetTutorialSettings")
    local settings = getTutorialSettingsFunc and getTutorialSettingsFunc:InvokeServer()
    
    if settings and not settings.showPopups then
        return
    end
    
    -- If we're already showing a tutorial and this one requires interaction,
    -- queue it instead of showing immediately
    if isTutorialPlaying and tutorialData.requiresInteraction then
        table.insert(tutorialQueue, tutorialData)
        debugPrint("Queued tutorial:", tutorialData.name)
        return
    end
    
    -- Create and show the tutorial popup
    local popup = createTutorialPopup(tutorialData)
    if popup then
        isTutorialPlaying = true
        debugPrint("Showing tutorial:", tutorialData.name)
    end
end

-- Skip a tutorial
function TutorialClient.skipTutorial(tutorialName)
    -- Hide the popup
    if activeTutorials[tutorialName] then
        local popup = activeTutorials[tutorialName]
        
        TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0, 0, -1, 0)
        }):Play()
        
        task.delay(0.3, function()
            popup:Destroy()
            activeTutorials[tutorialName] = nil
            
            -- Clear any associated highlights
            TutorialClient.clearHighlights()
            
            -- Mark tutorial as no longer playing
            isTutorialPlaying = false
            
            -- Show next tutorial in queue if any
            if #tutorialQueue > 0 then
                local nextTutorial = table.remove(tutorialQueue, 1)
                TutorialClient.showTutorial(nextTutorial)
            end
        end)
    end
    
    -- Tell server to skip this tutorial
    local skipEvent = EventBridge:FindFirstChild("SkipTutorial") 
    if skipEvent then
        skipEvent:FireServer(tutorialName)
    end
end

-- Complete a tutorial
function TutorialClient.completeTutorial(tutorialName)
    -- Similar animation to skip, but might have different behavior
    TutorialClient.skipTutorial(tutorialName)
}

-- Populate tutorial menu with available tutorials
function TutorialClient.populateTutorialMenu(tutorialList, completedTutorials)
    local uiTutorial = tutorialUI or createTutorialUI()
    local container = uiTutorial.contentContainer
    
    -- Clear existing cards
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("TutorialCard_") then
            child:Destroy()
        end
    end
    
    -- Add tutorial cards for each tutorial
    for _, tutorial in ipairs(tutorialList) do
        local isCompleted = table.find(completedTutorials, tutorial.name) ~= nil
        
        createTutorialCard({
            name = tutorial.name,
            description = tutorial.description,
            longDescription = tutorial.longDescription,
            completed = isCompleted,
            category = tutorial.category
        })
    end
}

--[[ Event Handling ]]--

-- Set up event handlers
function TutorialClient.setupEventHandlers()
    if not EventBridge then return end
    
    -- Listen for tutorial step started
    local tutorialStepStarted = EventBridge:FindFirstChild("TutorialStepStarted")
    if tutorialStepStarted then
        tutorialStepStarted.OnClientEvent:Connect(function(tutorialData)
            TutorialClient.showTutorial(tutorialData)
        end)
    end
    
    -- Listen for tutorial step completed
    local tutorialStepCompleted = EventBridge:FindFirstChild("TutorialStepCompleted")
    if tutorialStepCompleted then
        tutorialStepCompleted.OnClientEvent:Connect(function(tutorialData)
            TutorialClient.completeTutorial(tutorialData.name)
        end)
    end
    
    -- Listen for tutorial step skipped
    local tutorialStepSkipped = EventBridge:FindFirstChild("TutorialStepSkipped")
    if tutorialStepSkipped then
        tutorialStepSkipped.OnClientEvent:Connect(function(tutorialData)
            -- Redundant as skip is initiated from client, but included for completeness
        end)
    end
    
    -- Listen for direct UI commands
    local showTutorialUI = EventBridge:FindFirstChild("ShowTutorialUI")
    if showTutorialUI then
        showTutorialUI.OnClientEvent:Connect(function(tutorialData)
            TutorialClient.showTutorial(tutorialData)
        end)
    end
}

--[[ Initialization ]]--

-- Initialize the tutorial client
function TutorialClient.init()
    debugPrint("Initializing Tutorial Client")
    
    -- Wait for EventBridge to be available
    local startTime = tick()
    while not EventBridge and tick() - startTime < 10 do
        EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
        if not EventBridge then
            task.wait(0.5)
        end
    end
    
    if not EventBridge then
        warn("EventBridge not found after 10 seconds, tutorial system may not function correctly")
        return false
    end
    
    -- Create main UI
    tutorialUI = createTutorialUI()
    
    -- Set up event handlers
    TutorialClient.setupEventHandlers()
    
    -- Request tutorial settings
    local getTutorialSettingsFunc = EventBridge:FindFirstChild("GetTutorialSettings")
    if getTutorialSettingsFunc then
        local settings = getTutorialSettingsFunc:InvokeServer()
        if settings then
            tutorialUI.updateSettingsUI(settings)
        end
    end
    
    -- Request available tutorials for menu
    local getTutorialsFunc = EventBridge:FindFirstChild("GetTutorials")
    if getTutorialsFunc then
        local tutorialData = getTutorialsFunc:InvokeServer()
        if tutorialData then
            TutorialClient.populateTutorialMenu(
                tutorialData.available, 
                tutorialData.completed
            )
        end
    end
    
    debugPrint("Tutorial Client initialized")
    return true
end

-- Start initialization when the script runs
task.spawn(TutorialClient.init)

return TutorialClient
