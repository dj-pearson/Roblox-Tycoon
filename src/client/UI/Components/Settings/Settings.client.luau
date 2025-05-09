--!strict
--[[
    Settings.client.luau
    
    Settings UI component.
    Handles game settings, graphics options, and user preferences.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local UIComponent = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("Core"):WaitForChild("UIComponent"))
local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

-- Get client-side systems
local ClientRegistry = require(script.Parent.Parent.Parent.Parent.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

type UIComponentProps = Types.UIComponentProps
type UIEvent = Types.UIEvent

local Settings = setmetatable({}, { __index = UIComponent })
Settings.__index = Settings

-- Constructor
function Settings.new(): Settings
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.SETTINGS,
        size = UDim2.new(0.8, 0, 0.8, 0),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.SETTINGS, props), Settings)
    
    -- Create UI elements
    self:createUIElements()
    
    -- Set up event listeners
    self:setupEventListeners()
    
    return self
end

-- Create UI elements
function Settings:createUIElements()
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = "MainContainer"
    container.Size = UDim2.new(1, -40, 1, -100)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.Parent = self.instance
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.TextColor3 = Constants.STYLES.TEXT_COLOR
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = self.instance
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 20)
    closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    closeButton.Text = "X"
    closeButton.TextColor3 = Constants.STYLES.TEXT_COLOR
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = self.instance
    
    -- Add hover effect
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR:Lerp(Color3.new(1, 1, 1), 0.2)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    end)
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:dispatch({
            type = Constants.EVENTS.CLICK,
            target = self.instance,
            data = {
                action = "close"
            }
        })
    end)
    
    -- Create tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = container
    
    -- Create content container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -50)
    contentContainer.Position = UDim2.new(0, 0, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ScrollBarThickness = 6
    contentContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    contentContainer.Parent = container
    
    -- Create tabs
    local tabs = {
        { name = "Graphics", icon = "rbxassetid://72876573893033" },
        { name = "Audio", icon = "rbxassetid://72876573893033" },
        { name = "Gameplay", icon = "rbxassetid://72876573893033" },
        { name = "Controls", icon = "rbxassetid://72876573893033" }
    }
    
    local tabButtons = {}
    local tabContents = {}
    
    for i, tab in ipairs(tabs) do
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.name .. "Tab"
        tabButton.Size = UDim2.new(1 / #tabs, 0, 1, 0)
        tabButton.Position = UDim2.new((i - 1) / #tabs, 0, 0, 0)
        tabButton.BackgroundColor3 = i == 1 and Constants.STYLES.ACCENT_COLOR or Constants.STYLES.BACKGROUND_COLOR
        tabButton.Text = tab.name
        tabButton.TextColor3 = Constants.STYLES.TEXT_COLOR
        tabButton.TextSize = 16
        tabButton.Font = Enum.Font.GothamBold
        tabButton.Parent = tabsContainer
        
        -- Create tab content
        local tabContent = Instance.new("Frame")
        tabContent.Name = tab.name .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = i == 1
        tabContent.Parent = contentContainer
        
        -- Add tab content elements based on tab type
        if tab.name == "Graphics" then
            self:createGraphicsSettings(tabContent)
        elseif tab.name == "Audio" then
            self:createAudioSettings(tabContent)
        elseif tab.name == "Gameplay" then
            self:createGameplaySettings(tabContent)
        elseif tab.name == "Controls" then
            self:createControlsSettings(tabContent)
        end
        
        -- Connect tab button
        tabButton.MouseButton1Click:Connect(function()
            -- Update tab buttons
            for _, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = Constants.STYLES.BACKGROUND_COLOR
            end
            tabButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
            
            -- Update tab contents
            for _, content in ipairs(tabContents) do
                content.Visible = false
            end
            tabContent.Visible = true
        end)
        
        table.insert(tabButtons, tabButton)
        table.insert(tabContents, tabContent)
    end
    
    -- Store references
    self.contentContainer = contentContainer
end

-- Create graphics settings
function Settings:createGraphicsSettings(container)
    -- Graphics quality
    local qualityLabel = Instance.new("TextLabel")
    qualityLabel.Name = "QualityLabel"
    qualityLabel.Size = UDim2.new(1, -20, 0, 30)
    qualityLabel.Position = UDim2.new(0, 10, 0, 10)
    qualityLabel.BackgroundTransparency = 1
    qualityLabel.Text = "Graphics Quality"
    qualityLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    qualityLabel.TextSize = 16
    qualityLabel.Font = Enum.Font.GothamBold
    qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
    qualityLabel.Parent = container
    
    local qualityDropdown = Instance.new("TextButton")
    qualityDropdown.Name = "QualityDropdown"
    qualityDropdown.Size = UDim2.new(1, -20, 0, 30)
    qualityDropdown.Position = UDim2.new(0, 10, 0, 40)
    qualityDropdown.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    qualityDropdown.Text = "High"
    qualityDropdown.TextColor3 = Constants.STYLES.TEXT_COLOR
    qualityDropdown.TextSize = 14
    qualityDropdown.Font = Enum.Font.Gotham
    qualityDropdown.Parent = container
    
    -- Shadows
    local shadowsLabel = Instance.new("TextLabel")
    shadowsLabel.Name = "ShadowsLabel"
    shadowsLabel.Size = UDim2.new(1, -20, 0, 30)
    shadowsLabel.Position = UDim2.new(0, 10, 0, 80)
    shadowsLabel.BackgroundTransparency = 1
    shadowsLabel.Text = "Shadows"
    shadowsLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    shadowsLabel.TextSize = 16
    shadowsLabel.Font = Enum.Font.GothamBold
    shadowsLabel.TextXAlignment = Enum.TextXAlignment.Left
    shadowsLabel.Parent = container
    
    local shadowsToggle = Instance.new("TextButton")
    shadowsToggle.Name = "ShadowsToggle"
    shadowsToggle.Size = UDim2.new(0, 50, 0, 30)
    shadowsToggle.Position = UDim2.new(0, 10, 0, 110)
    shadowsToggle.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    shadowsToggle.Text = "On"
    shadowsToggle.TextColor3 = Constants.STYLES.TEXT_COLOR
    shadowsToggle.TextSize = 14
    shadowsToggle.Font = Enum.Font.Gotham
    shadowsToggle.Parent = container
    
    -- Anti-aliasing
    local antiAliasingLabel = Instance.new("TextLabel")
    antiAliasingLabel.Name = "AntiAliasingLabel"
    antiAliasingLabel.Size = UDim2.new(1, -20, 0, 30)
    antiAliasingLabel.Position = UDim2.new(0, 10, 0, 150)
    antiAliasingLabel.BackgroundTransparency = 1
    antiAliasingLabel.Text = "Anti-aliasing"
    antiAliasingLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    antiAliasingLabel.TextSize = 16
    antiAliasingLabel.Font = Enum.Font.GothamBold
    antiAliasingLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiAliasingLabel.Parent = container
    
    local antiAliasingToggle = Instance.new("TextButton")
    antiAliasingToggle.Name = "AntiAliasingToggle"
    antiAliasingToggle.Size = UDim2.new(0, 50, 0, 30)
    antiAliasingToggle.Position = UDim2.new(0, 10, 0, 180)
    antiAliasingToggle.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    antiAliasingToggle.Text = "On"
    antiAliasingToggle.TextColor3 = Constants.STYLES.TEXT_COLOR
    antiAliasingToggle.TextSize = 14
    antiAliasingToggle.Font = Enum.Font.Gotham
    antiAliasingToggle.Parent = container
end

-- Create audio settings
function Settings:createAudioSettings(container)
    -- Master volume
    local masterVolumeLabel = Instance.new("TextLabel")
    masterVolumeLabel.Name = "MasterVolumeLabel"
    masterVolumeLabel.Size = UDim2.new(1, -20, 0, 30)
    masterVolumeLabel.Position = UDim2.new(0, 10, 0, 10)
    masterVolumeLabel.BackgroundTransparency = 1
    masterVolumeLabel.Text = "Master Volume"
    masterVolumeLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    masterVolumeLabel.TextSize = 16
    masterVolumeLabel.Font = Enum.Font.GothamBold
    masterVolumeLabel.TextXAlignment = Enum.TextXAlignment.Left
    masterVolumeLabel.Parent = container
    
    local masterVolumeSlider = Instance.new("Frame")
    masterVolumeSlider.Name = "MasterVolumeSlider"
    masterVolumeSlider.Size = UDim2.new(1, -20, 0, 30)
    masterVolumeSlider.Position = UDim2.new(0, 10, 0, 40)
    masterVolumeSlider.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    masterVolumeSlider.Parent = container
    
    -- Music volume
    local musicVolumeLabel = Instance.new("TextLabel")
    musicVolumeLabel.Name = "MusicVolumeLabel"
    musicVolumeLabel.Size = UDim2.new(1, -20, 0, 30)
    musicVolumeLabel.Position = UDim2.new(0, 10, 0, 80)
    musicVolumeLabel.BackgroundTransparency = 1
    musicVolumeLabel.Text = "Music Volume"
    musicVolumeLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    musicVolumeLabel.TextSize = 16
    musicVolumeLabel.Font = Enum.Font.GothamBold
    musicVolumeLabel.TextXAlignment = Enum.TextXAlignment.Left
    musicVolumeLabel.Parent = container
    
    local musicVolumeSlider = Instance.new("Frame")
    musicVolumeSlider.Name = "MusicVolumeSlider"
    musicVolumeSlider.Size = UDim2.new(1, -20, 0, 30)
    musicVolumeSlider.Position = UDim2.new(0, 10, 0, 110)
    musicVolumeSlider.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    musicVolumeSlider.Parent = container
    
    -- Sound effects volume
    local sfxVolumeLabel = Instance.new("TextLabel")
    sfxVolumeLabel.Name = "SFXVolumeLabel"
    sfxVolumeLabel.Size = UDim2.new(1, -20, 0, 30)
    sfxVolumeLabel.Position = UDim2.new(0, 10, 0, 150)
    sfxVolumeLabel.BackgroundTransparency = 1
    sfxVolumeLabel.Text = "Sound Effects Volume"
    sfxVolumeLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    sfxVolumeLabel.TextSize = 16
    sfxVolumeLabel.Font = Enum.Font.GothamBold
    sfxVolumeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sfxVolumeLabel.Parent = container
    
    local sfxVolumeSlider = Instance.new("Frame")
    sfxVolumeSlider.Name = "SFXVolumeSlider"
    sfxVolumeSlider.Size = UDim2.new(1, -20, 0, 30)
    sfxVolumeSlider.Position = UDim2.new(0, 10, 0, 180)
    sfxVolumeSlider.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    sfxVolumeSlider.Parent = container
end

-- Create gameplay settings
function Settings:createGameplaySettings(container)
    -- Auto-save
    local autoSaveLabel = Instance.new("TextLabel")
    autoSaveLabel.Name = "AutoSaveLabel"
    autoSaveLabel.Size = UDim2.new(1, -20, 0, 30)
    autoSaveLabel.Position = UDim2.new(0, 10, 0, 10)
    autoSaveLabel.BackgroundTransparency = 1
    autoSaveLabel.Text = "Auto-save"
    autoSaveLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    autoSaveLabel.TextSize = 16
    autoSaveLabel.Font = Enum.Font.GothamBold
    autoSaveLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoSaveLabel.Parent = container
    
    local autoSaveToggle = Instance.new("TextButton")
    autoSaveToggle.Name = "AutoSaveToggle"
    autoSaveToggle.Size = UDim2.new(0, 50, 0, 30)
    autoSaveToggle.Position = UDim2.new(0, 10, 0, 40)
    autoSaveToggle.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    autoSaveToggle.Text = "On"
    autoSaveToggle.TextColor3 = Constants.STYLES.TEXT_COLOR
    autoSaveToggle.TextSize = 14
    autoSaveToggle.Font = Enum.Font.Gotham
    autoSaveToggle.Parent = container
    
    -- Notifications
    local notificationsLabel = Instance.new("TextLabel")
    notificationsLabel.Name = "NotificationsLabel"
    notificationsLabel.Size = UDim2.new(1, -20, 0, 30)
    notificationsLabel.Position = UDim2.new(0, 10, 0, 80)
    notificationsLabel.BackgroundTransparency = 1
    notificationsLabel.Text = "Notifications"
    notificationsLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    notificationsLabel.TextSize = 16
    notificationsLabel.Font = Enum.Font.GothamBold
    notificationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationsLabel.Parent = container
    
    local notificationsToggle = Instance.new("TextButton")
    notificationsToggle.Name = "NotificationsToggle"
    notificationsToggle.Size = UDim2.new(0, 50, 0, 30)
    notificationsToggle.Position = UDim2.new(0, 10, 0, 110)
    notificationsToggle.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    notificationsToggle.Text = "On"
    notificationsToggle.TextColor3 = Constants.STYLES.TEXT_COLOR
    notificationsToggle.TextSize = 14
    notificationsToggle.Font = Enum.Font.Gotham
    notificationsToggle.Parent = container
end

-- Create controls settings
function Settings:createControlsSettings(container)
    -- Mouse sensitivity
    local sensitivityLabel = Instance.new("TextLabel")
    sensitivityLabel.Name = "SensitivityLabel"
    sensitivityLabel.Size = UDim2.new(1, -20, 0, 30)
    sensitivityLabel.Position = UDim2.new(0, 10, 0, 10)
    sensitivityLabel.BackgroundTransparency = 1
    sensitivityLabel.Text = "Mouse Sensitivity"
    sensitivityLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    sensitivityLabel.TextSize = 16
    sensitivityLabel.Font = Enum.Font.GothamBold
    sensitivityLabel.TextXAlignment = Enum.TextXAlignment.Left
    sensitivityLabel.Parent = container
    
    local sensitivitySlider = Instance.new("Frame")
    sensitivitySlider.Name = "SensitivitySlider"
    sensitivitySlider.Size = UDim2.new(1, -20, 0, 30)
    sensitivitySlider.Position = UDim2.new(0, 10, 0, 40)
    sensitivitySlider.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    sensitivitySlider.Parent = container
    
    -- Invert Y-axis
    local invertYLabel = Instance.new("TextLabel")
    invertYLabel.Name = "InvertYLabel"
    invertYLabel.Size = UDim2.new(1, -20, 0, 30)
    invertYLabel.Position = UDim2.new(0, 10, 0, 80)
    invertYLabel.BackgroundTransparency = 1
    invertYLabel.Text = "Invert Y-axis"
    invertYLabel.TextColor3 = Constants.STYLES.TEXT_COLOR
    invertYLabel.TextSize = 16
    invertYLabel.Font = Enum.Font.GothamBold
    invertYLabel.TextXAlignment = Enum.TextXAlignment.Left
    invertYLabel.Parent = container
    
    local invertYToggle = Instance.new("TextButton")
    invertYToggle.Name = "InvertYToggle"
    invertYToggle.Size = UDim2.new(0, 50, 0, 30)
    invertYToggle.Position = UDim2.new(0, 10, 0, 110)
    invertYToggle.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    invertYToggle.Text = "Off"
    invertYToggle.TextColor3 = Constants.STYLES.TEXT_COLOR
    invertYToggle.TextSize = 14
    invertYToggle.Font = Enum.Font.Gotham
    invertYToggle.Parent = container
end

-- Set up event listeners
function Settings:setupEventListeners()
    -- Listen for settings updates
    ClientEventBridge:connectEvent("SettingsUpdated", function(data)
        self:updateSettings(data)
    end)
end

-- Update settings
function Settings:updateSettings(data)
    if not data then return end
    
    -- Update graphics settings
    if data.graphics then
        self:updateGraphicsSettings(data.graphics)
    end
    
    -- Update audio settings
    if data.audio then
        self:updateAudioSettings(data.audio)
    end
    
    -- Update gameplay settings
    if data.gameplay then
        self:updateGameplaySettings(data.gameplay)
    end
    
    -- Update controls settings
    if data.controls then
        self:updateControlsSettings(data.controls)
    end
end

-- Update graphics settings
function Settings:updateGraphicsSettings(settings)
    -- Update quality dropdown
    local qualityDropdown = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("GraphicsContent"):FindFirstChild("QualityDropdown")
    if qualityDropdown then
        qualityDropdown.Text = settings.quality or "High"
    end
    
    -- Update shadows toggle
    local shadowsToggle = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("GraphicsContent"):FindFirstChild("ShadowsToggle")
    if shadowsToggle then
        shadowsToggle.Text = settings.shadows and "On" or "Off"
        shadowsToggle.BackgroundColor3 = settings.shadows and Constants.STYLES.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)
    end
    
    -- Update anti-aliasing toggle
    local antiAliasingToggle = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("GraphicsContent"):FindFirstChild("AntiAliasingToggle")
    if antiAliasingToggle then
        antiAliasingToggle.Text = settings.antiAliasing and "On" or "Off"
        antiAliasingToggle.BackgroundColor3 = settings.antiAliasing and Constants.STYLES.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)
    end
end

-- Update audio settings
function Settings:updateAudioSettings(settings)
    -- Update master volume slider
    local masterVolumeSlider = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("AudioContent"):FindFirstChild("MasterVolumeSlider")
    if masterVolumeSlider then
        masterVolumeSlider.Size = UDim2.new(settings.masterVolume or 1, 0, 1, 0)
    end
    
    -- Update music volume slider
    local musicVolumeSlider = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("AudioContent"):FindFirstChild("MusicVolumeSlider")
    if musicVolumeSlider then
        musicVolumeSlider.Size = UDim2.new(settings.musicVolume or 1, 0, 1, 0)
    end
    
    -- Update SFX volume slider
    local sfxVolumeSlider = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("AudioContent"):FindFirstChild("SFXVolumeSlider")
    if sfxVolumeSlider then
        sfxVolumeSlider.Size = UDim2.new(settings.sfxVolume or 1, 0, 1, 0)
    end
end

-- Update gameplay settings
function Settings:updateGameplaySettings(settings)
    -- Update auto-save toggle
    local autoSaveToggle = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("GameplayContent"):FindFirstChild("AutoSaveToggle")
    if autoSaveToggle then
        autoSaveToggle.Text = settings.autoSave and "On" or "Off"
        autoSaveToggle.BackgroundColor3 = settings.autoSave and Constants.STYLES.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)
    end
    
    -- Update notifications toggle
    local notificationsToggle = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("GameplayContent"):FindFirstChild("NotificationsToggle")
    if notificationsToggle then
        notificationsToggle.Text = settings.notifications and "On" or "Off"
        notificationsToggle.BackgroundColor3 = settings.notifications and Constants.STYLES.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)
    end
end

-- Update controls settings
function Settings:updateControlsSettings(settings)
    -- Update sensitivity slider
    local sensitivitySlider = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("ControlsContent"):FindFirstChild("SensitivitySlider")
    if sensitivitySlider then
        sensitivitySlider.Size = UDim2.new(settings.sensitivity or 0.5, 0, 1, 0)
    end
    
    -- Update invert Y toggle
    local invertYToggle = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild("ControlsContent"):FindFirstChild("InvertYToggle")
    if invertYToggle then
        invertYToggle.Text = settings.invertY and "On" or "Off"
        invertYToggle.BackgroundColor3 = settings.invertY and Constants.STYLES.ACCENT_COLOR or Color3.fromRGB(100, 100, 100)
    end
end

-- Override event handler
function Settings:onEvent(event: UIEvent)
    if event.type == Constants.EVENTS.CLICK then
        if event.data.action == "close" then
            self:dispatch({
                type = Constants.EVENTS.CLOSE,
                target = self.instance
            })
        end
    end
end

-- Override destroy to clean up
function Settings:destroy()
    -- Clean up event listeners
    if self.contentContainer then
        self.contentContainer:Destroy()
    end
    
    -- Call parent destroy
    UIComponent.destroy(self)
end

return Settings 