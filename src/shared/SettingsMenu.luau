-- SettingsMenu.luau
-- Settings configuration UI using the new UIComponent base class
-- Part of UI refinements initiative (April 2025)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local UIComponent = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIComponent"))
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- Settings module
local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu
setmetatable(SettingsMenu, UIComponent)

-- Default settings categories and options
local DEFAULT_SETTINGS = {
    gameplay = {
        title = "Gameplay",
        icon = UIStyle.icons.settings,
        options = {
            autoCollect = {
                type = "toggle",
                title = "Auto-Collect Revenue",
                description = "Automatically collect revenue when available",
                default = true
            },
            notifications = {
                type = "toggle",
                title = "Notifications",
                description = "Show in-game notifications",
                default = true
            },
            confirmPurchases = {
                type = "toggle",
                title = "Confirm Purchases",
                description = "Ask for confirmation before making purchases",
                default = true
            },
            tutorialHints = {
                type = "toggle",
                title = "Tutorial Hints",
                description = "Show tutorial hints during gameplay",
                default = true
            }
        }
    },
    audio = {
        title = "Audio",
        icon = UIStyle.icons.audio,
        options = {
            masterVolume = {
                type = "slider",
                title = "Master Volume",
                description = "Control the overall game volume",
                min = 0,
                max = 100,
                default = 80
            },
            musicVolume = {
                type = "slider",
                title = "Music Volume",
                description = "Control the game music volume",
                min = 0,
                max = 100,
                default = 60
            },
            sfxVolume = {
                type = "slider",
                title = "SFX Volume",
                description = "Control the sound effects volume",
                min = 0,
                max = 100,
                default = 90
            },
            muteMusic = {
                type = "toggle",
                title = "Mute Music",
                description = "Turn off all music",
                default = false
            }
        }
    },
    visual = {
        title = "Visual",
        icon = UIStyle.icons.visual,
        options = {
            quality = {
                type = "dropdown",
                title = "Graphics Quality",
                description = "Choose your preferred graphics quality",
                options = {"Low", "Medium", "High", "Auto"},
                default = "High"
            },
            showFPS = {
                type = "toggle",
                title = "Show FPS",
                description = "Display frames per second counter",
                default = false
            },
            gymMemberVisibility = {
                type = "dropdown",
                title = "Gym Member Visibility",
                description = "Control how many members are visible at once",
                options = {"Minimal", "Balanced", "Maximum"},
                default = "Balanced"
            },
            particleEffects = {
                type = "toggle",
                title = "Particle Effects",
                description = "Show special effects during workouts and achievements",
                default = true
            }
        }
    },
    gym = {
        title = "Gym Settings",
        icon = UIStyle.icons.gym,
        options = {
            memberAI = {
                type = "dropdown",
                title = "Member AI Behavior",
                description = "How gym members behave in your facility",
                options = {"Realistic", "Performance", "Balanced"},
                default = "Balanced"
            },
            staffBehavior = {
                type = "dropdown",
                title = "Staff Behavior",
                description = "How staff members interact with the gym",
                options = {"Proactive", "Reactive", "Balanced"},
                default = "Balanced"
            },
            cleanlinessImpact = {
                type = "slider",
                title = "Cleanliness Impact",
                description = "How much cleanliness affects member satisfaction",
                min = 1,
                max = 10,
                default = 5
            },
            temperatureEffect = {
                type = "slider",
                title = "Temperature Effect",
                description = "How much temperature affects member comfort",
                min = 1,
                max = 10,
                default = 5
            }
        }
    }
}

-- Create a new SettingsMenu instance
function SettingsMenu.new(customConfig)
    local config = {
        size = UDim2.new(0, 700, 0, 500),
        title = "Settings",
        backgroundColor = UIStyle.colors.background,
        headerColor = UIStyle.colors.headerBackground
    }
    
    -- Merge with custom config if provided
    if customConfig then
        for key, value in pairs(customConfig) do
            config[key] = value
        end
    end
    
    -- Create base UIComponent
    local self = UIComponent.new("SettingsMenu", config)
    setmetatable(self, SettingsMenu)
    
    -- Initialize settings state
    self.currentCategory = "gameplay"
    self.settings = {}
    self.userSettings = {}
    self.settingControls = {}
    
    -- Load default settings
    for category, categoryData in pairs(DEFAULT_SETTINGS) do
        self.settings[category] = categoryData
        self.userSettings[category] = {}
        self.settingControls[category] = {}
        
        -- Load default values
        for setting, settingData in pairs(categoryData.options) do
            self.userSettings[category][setting] = self:loadSetting(category, setting, settingData.default)
        end
    end
    
    return self
end

-- Create UI elements
function SettingsMenu:createUI()
    -- Create base container from parent class
    local container = UIComponent.createUI(self)
    
    -- Create two-panel layout: category sidebar and settings content
    self:createCategorySidebar()
    self:createSettingsPanel()
    
    -- Add save/cancel buttons at bottom
    self:createActionButtons()
    
    -- Populate with initial category
    self:showCategory(self.currentCategory)
    
    return container
end

-- Create the category sidebar
function SettingsMenu:createCategorySidebar()
    local contentArea = self.uiElements.contentArea
    
    -- Create sidebar container
    local sidebar = Instance.new("Frame")
    sidebar.Name = "CategorySidebar"
    sidebar.Size = UDim2.new(0, 200, 1, -60) -- Leave space for bottom buttons
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = UIStyle.colors.cardBackground
    sidebar.BackgroundTransparency = 0.2
    sidebar.BorderSizePixel = 0
    sidebar.Parent = contentArea
    
    -- Add padding and layout
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingBottom = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingLeft = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingRight = UDim.new(0, UIStyle.padding.medium)
    padding.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, UIStyle.padding.medium)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = sidebar
    
    -- Create category buttons
    local categoryButtons = {}
    local index = 0
    
    for categoryId, categoryData in pairs(self.settings) do
        local button = self:createCategoryButton(categoryId, categoryData, index)
        button.Parent = sidebar
        categoryButtons[categoryId] = button
        index = index + 1
    end
    
    -- Store references
    self.uiElements.sidebar = sidebar
    self.uiElements.categoryButtons = categoryButtons
end

-- Create a category button
function SettingsMenu:createCategoryButton(categoryId, categoryData, index)
    local isSelected = categoryId == self.currentCategory
    
    local button = Instance.new("TextButton")
    button.Name = categoryId .. "Button"
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = isSelected and UIStyle.colors.primary or UIStyle.colors.buttonDefault
    button.BackgroundTransparency = 0.1
    button.Text = ""
    button.LayoutOrder = index
    button.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.cornerRadius.medium
    corner.Parent = button
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = categoryData.icon or UIStyle.icons.settings
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = button
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = UIStyle.fonts.button
    label.TextSize = UIStyle.textSizes.button
    label.TextColor3 = UIStyle.colors.textPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = categoryData.title
    label.Parent = button
    
    -- Add hover and click effects
    button.MouseEnter:Connect(function()
        if categoryId ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonHover}
            ):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if categoryId ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        self:showCategory(categoryId)
    end)
    
    return button
end

-- Create the settings panel
function SettingsMenu:createSettingsPanel()
    local contentArea = self.uiElements.contentArea
    
    -- Create settings panel container
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "SettingsPanel"
    panel.Size = UDim2.new(1, -220, 1, -60) -- Space for sidebar and buttons
    panel.Position = UDim2.new(0, 210, 0, 0)
    panel.BackgroundTransparency = 1
    panel.ScrollBarThickness = 6
    panel.ScrollingDirection = Enum.ScrollingDirection.Y
    panel.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    panel.Parent = contentArea
    
    -- Add padding and layout
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingBottom = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingLeft = UDim.new(0, UIStyle.padding.medium)
    padding.PaddingRight = UDim.new(0, UIStyle.padding.medium)
    padding.Parent = panel
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, UIStyle.padding.large)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    
    -- Store reference
    self.uiElements.settingsPanel = panel
end

-- Create save/cancel buttons
function SettingsMenu:createActionButtons()
    local contentArea = self.uiElements.contentArea
    
    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 50)
    buttonContainer.Position = UDim2.new(0, 0, 1, -50)
    buttonContainer.BackgroundColor3 = UIStyle.colors.headerBackground
    buttonContainer.BackgroundTransparency = 0.1
    buttonContainer.BorderSizePixel = 0
    buttonContainer.Parent = contentArea
    
    -- Add save button
    local saveButton = UIStyle.createButton({
        name = "SaveButton",
        size = UDim2.new(0, 120, 0, 36),
        position = UDim2.new(1, -140, 0.5, 0),
        anchorPoint = Vector2.new(0, 0.5),
        text = "Save",
        color = UIStyle.colors.success,
        parent = buttonContainer
    })
    
    -- Add cancel button
    local cancelButton = UIStyle.createButton({
        name = "CancelButton",
        size = UDim2.new(0, 120, 0, 36),
        position = UDim2.new(1, -270, 0.5, 0),
        anchorPoint = Vector2.new(0, 0.5),
        text = "Cancel",
        color = UIStyle.colors.buttonDefault,
        parent = buttonContainer
    })
    
    -- Add reset to default button
    local resetButton = UIStyle.createButton({
        name = "ResetButton",
        size = UDim2.new(0, 120, 0, 36),
        position = UDim2.new(0, 20, 0.5, 0),
        anchorPoint = Vector2.new(0, 0.5),
        text = "Defaults",
        color = UIStyle.colors.buttonDefault,
        parent = buttonContainer
    })
    
    -- Connect buttons
    saveButton.MouseButton1Click:Connect(function()
        self:saveSettings()
        self:close()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        self:close()
    end)
    
    resetButton.MouseButton1Click:Connect(function()
        self:resetToDefaults()
    end)
    
    -- Store references
    self.uiElements.buttonContainer = buttonContainer
    self.uiElements.saveButton = saveButton
    self.uiElements.cancelButton = cancelButton
    self.uiElements.resetButton = resetButton
end

-- Show a category's settings
function SettingsMenu:showCategory(categoryId)
    if not self.settings[categoryId] then return end
    
    -- Update selected category
    local oldCategory = self.currentCategory
    self.currentCategory = categoryId
    
    -- Update button visuals
    if self.uiElements.categoryButtons then
        -- Deselect old category
        if oldCategory and self.uiElements.categoryButtons[oldCategory] then
            TweenService:Create(
                self.uiElements.categoryButtons[oldCategory],
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
        
        -- Select new category
        if self.uiElements.categoryButtons[categoryId] then
            TweenService:Create(
                self.uiElements.categoryButtons[categoryId],
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.primary}
            ):Play()
        end
    end
    
    -- Clear current settings
    local panel = self.uiElements.settingsPanel
    if panel then
        for _, child in pairs(panel:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    else
        return -- Panel not created yet
    end
    
    -- Get category data
    local categoryData = self.settings[categoryId]
    if not categoryData then return end
    
    -- Create header for category
    local header = Instance.new("Frame")
    header.Name = "CategoryHeader"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    header.Parent = panel
    
    local headerText = Instance.new("TextLabel")
    headerText.Name = "HeaderText"
    headerText.Size = UDim2.new(1, 0, 1, 0)
    headerText.BackgroundTransparency = 1
    headerText.Font = UIStyle.fonts.header
    headerText.TextSize = UIStyle.textSizes.header
    headerText.TextColor3 = UIStyle.colors.textPrimary
    headerText.TextXAlignment = Enum.TextXAlignment.Left
    headerText.Text = categoryData.title
    headerText.Parent = header
    
    -- Create settings options
    local index = 1
    for settingId, settingData in pairs(categoryData.options) do
        local settingControl = self:createSettingControl(categoryId, settingId, settingData, index)
        settingControl.Parent = panel
        
        -- Store reference for updating
        self.settingControls[categoryId][settingId] = settingControl
        index = index + 1
    end
    
    -- Update canvas size
    local totalHeight = 0
    for _, child in pairs(panel:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            totalHeight = totalHeight + child.Size.Y.Offset + panel:FindFirstChildOfClass("UIListLayout").Padding.Offset
        end
    end
    
    panel.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Create a control for a setting
function SettingsMenu:createSettingControl(categoryId, settingId, settingData, index)
    local currentValue = self.userSettings[categoryId][settingId]
    
    -- Create frame for setting
    local control = Instance.new("Frame")
    control.Name = settingId .. "Control"
    control.Size = UDim2.new(1, 0, 0, settingData.type == "slider" and 80 or 60)
    control.BackgroundColor3 = UIStyle.colors.cardBackground
    control.BackgroundTransparency = 0.1
    control.LayoutOrder = index
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.cornerRadius.small
    corner.Parent = control
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = UIStyle.fonts.subheader
    title.TextSize = UIStyle.textSizes.subheader
    title.TextColor3 = UIStyle.colors.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = settingData.title
    title.Parent = control
    
    -- Add description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(0.7, -20, 0, 20)
    description.Position = UDim2.new(0, 10, 0, 30)
    description.BackgroundTransparency = 1
    description.Font = UIStyle.fonts.body
    description.TextSize = UIStyle.textSizes.body
    description.TextColor3 = UIStyle.colors.textSecondary
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.Text = settingData.description
    description.TextWrapped = true
    description.Parent = control
    
    -- Create control based on type
    if settingData.type == "toggle" then
        -- Create toggle switch
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0, 50, 0, 24)
        toggleButton.Position = UDim2.new(1, -60, 0, 30)
        toggleButton.BackgroundColor3 = currentValue and UIStyle.colors.success or UIStyle.colors.buttonDisabled
        toggleButton.Text = ""
        toggleButton.Parent = control
        
        -- Add corner radius
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0.5, 0)
        toggleCorner.Parent = toggleButton
        
        -- Add indicator
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 18, 0, 18)
        indicator.Position = currentValue and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        indicator.AnchorPoint = Vector2.new(0, 0.5)
        indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        indicator.Parent = toggleButton
        
        -- Add corner radius to indicator
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0.5, 0)
        indicatorCorner.Parent = indicator
        
        -- Handle clicks
        toggleButton.MouseButton1Click:Connect(function()
            currentValue = not currentValue
            self.userSettings[categoryId][settingId] = currentValue
            
            -- Animate change
            TweenService:Create(
                toggleButton,
                UIStyle.animations.fast,
                {BackgroundColor3 = currentValue and UIStyle.colors.success or UIStyle.colors.buttonDisabled}
            ):Play()
            
            TweenService:Create(
                indicator,
                UIStyle.animations.fast,
                {Position = currentValue and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}
            ):Play()
        end)
        
    elseif settingData.type == "slider" then
        -- Create slider track
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "SliderTrack"
        sliderTrack.Size = UDim2.new(0.7, 0, 0, 6)
        sliderTrack.Position = UDim2.new(0.15, 0, 0, 60)
        sliderTrack.BackgroundColor3 = UIStyle.colors.buttonDefault
        sliderTrack.Parent = control
        
        -- Add corner radius to track
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0.5, 0)
        trackCorner.Parent = sliderTrack
        
        -- Create fill track
        local fillTrack = Instance.new("Frame")
        fillTrack.Name = "FillTrack"
        fillTrack.Size = UDim2.new((currentValue - settingData.min) / (settingData.max - settingData.min), 0, 1, 0)
        fillTrack.BackgroundColor3 = UIStyle.colors.primary
        fillTrack.Parent = sliderTrack
        
        -- Add corner radius to fill track
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0.5, 0)
        fillCorner.Parent = fillTrack
        
        -- Create slider knob
        local sliderKnob = Instance.new("TextButton")
        sliderKnob.Name = "SliderKnob"
        sliderKnob.Size = UDim2.new(0, 16, 0, 16)
        sliderKnob.Position = UDim2.new((currentValue - settingData.min) / (settingData.max - settingData.min), 0, 0.5, 0)
        sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderKnob.Text = ""
        sliderKnob.Parent = sliderTrack
        
        -- Add corner radius to knob
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0.5, 0)
        knobCorner.Parent = sliderKnob
        
        -- Create value label
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0, 50, 0, 20)
        valueLabel.Position = UDim2.new(1, -60, 0, 30)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = UIStyle.fonts.body
        valueLabel.TextSize = UIStyle.textSizes.body
        valueLabel.TextColor3 = UIStyle.colors.textPrimary
        valueLabel.Text = tostring(currentValue)
        valueLabel.Parent = control
        
        -- Slider functionality
        local dragging = false
        
        local function updateSlider(relativeX)
            -- Clamp to valid range
            relativeX = math.clamp(relativeX, 0, 1)
            
            -- Update components
            fillTrack.Size = UDim2.new(relativeX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
            
            -- Calculate value
            local newValue = math.floor(settingData.min + relativeX * (settingData.max - settingData.min))
            currentValue = newValue
            self.userSettings[categoryId][settingId] = currentValue
            
            -- Update label
            valueLabel.Text = tostring(newValue)
        end
        
        sliderKnob.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        sliderTrack.MouseButton1Down:Connect(function(x, y)
            -- Calculate relative position in track
            local relativeX = (x - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            updateSlider(relativeX)
        end)
        
        sliderKnob.MouseMoved:Connect(function(x, y)
            if dragging then
                -- Calculate relative position in track
                local relativeX = (x - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
                updateSlider(relativeX)
            end
        end)
        
        sliderKnob.MouseButton1Up:Connect(function()
            dragging = false
        end)
        
        -- Also catch mouse release outside the button
        local connection = game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        -- Store connection for cleanup
        table.insert(self.eventConnections, connection)
    end
    
    return control
end

-- Load a setting from player data
function SettingsMenu:loadSetting(category, setting, defaultValue)
    local settingKey = "Setting_" .. category .. "_" .. setting
    local value = Player:GetAttribute(settingKey)
    
    -- Return stored value or default
    if value ~= nil then
        -- Convert string back to bool if needed
        if defaultValue == true or defaultValue == false then
            return value == "true"
        end
        
        -- Convert string to number if default is number
        if type(defaultValue) == "number" then
            return tonumber(value) or defaultValue
        end
        
        return value
    end
    
    return defaultValue
end

-- Save all settings
function SettingsMenu:saveSettings()
    -- Save each setting to player attributes
    for category, settings in pairs(self.userSettings) do
        for setting, value in pairs(settings) do
            local settingKey = "Setting_" .. category .. "_" .. setting
            
            -- Convert value to string for storage
            local storedValue = type(value) == "boolean" and tostring(value) or value
            Player:SetAttribute(settingKey, storedValue)
        end
    end
    
    -- Fire callback if registered
    if self.callbacks.onSettingsSaved then
        self.callbacks.onSettingsSaved(self.userSettings)
    end
    
    -- Show saved notification
    if self.UIManager then
        self.UIManager.showNotification({
            title = "Settings Saved",
            message = "Your settings have been saved and applied.",
            duration = 3,
            type = "success"
        })
    end
    
    -- Apply settings immediately
    self:applySettings()
end

-- Apply current settings
function SettingsMenu:applySettings()
    -- Apply settings that need immediate effect
    
    -- UI Hub setting
    if self.userSettings.interface and self.userSettings.interface.useUIHub ~= nil then
        -- Set config on UIManager
        if self.UIManager and self.UIManager.getConfig then
            local config = self.UIManager.getConfig()
            if config then
                config.useUIHub = self.userSettings.interface.useUIHub
            end
        end
    end
    
    -- Audio settings
    if self.userSettings.audio then
        local soundService = game:GetService("SoundService")
        
        if self.userSettings.audio.muteAll ~= nil then
            soundService.RespectFilteringEnabled = not self.userSettings.audio.muteAll
            soundService.VolumeOverride = self.userSettings.audio.muteAll and 0 or 1
        end
        
        -- Other audio settings can be applied here
    end
    
    -- Accessibility settings
    if self.userSettings.accessibility then
        -- Apply high contrast mode
        if self.userSettings.accessibility.highContrast then
            -- Implementation for high contrast mode
        end
        
        -- Apply large text mode
        if self.userSettings.accessibility.largeText then
            -- Implementation for large text
        end
    end
    
    -- Fire callback if registered
    if self.callbacks.onSettingsApplied then
        self.callbacks.onSettingsApplied(self.userSettings)
    end
end

-- Reset settings to default
function SettingsMenu:resetToDefaults()
    -- Reset all settings in current category to default
    local categoryId = self.currentCategory
    local categoryData = self.settings[categoryId]
    
    if not categoryData then return end
    
    for settingId, settingData in pairs(categoryData.options) do
        -- Reset to default value
        self.userSettings[categoryId][settingId] = settingData.default
        
        -- Update UI control
        local control = self.settingControls[categoryId][settingId]
        if control then
            if settingData.type == "toggle" then
                local toggleButton = control:FindFirstChild("ToggleButton")
                local indicator = toggleButton and toggleButton:FindFirstChild("Indicator")
                
                if toggleButton and indicator then
                    -- Update visuals
                    toggleButton.BackgroundColor3 = settingData.default and UIStyle.colors.success or UIStyle.colors.buttonDisabled
                    indicator.Position = settingData.default and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                end
                
            elseif settingData.type == "slider" then
                local sliderTrack = control:FindFirstChild("SliderTrack")
                local fillTrack = sliderTrack and sliderTrack:FindFirstChild("FillTrack")
                local sliderKnob = sliderTrack and sliderTrack:FindFirstChild("SliderKnob")
                local valueLabel = control:FindFirstChild("ValueLabel")
                
                if sliderTrack and fillTrack and sliderKnob and valueLabel then
                    -- Calculate relative position
                    local relativeX = (settingData.default - settingData.min) / (settingData.max - settingData.min)
                    
                    -- Update visuals
                    fillTrack.Size = UDim2.new(relativeX, 0, 1, 0)
                    sliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
                    valueLabel.Text = tostring(settingData.default)
                end
            end
        end
    end
end

-- Get all settings
function SettingsMenu:getSettings()
    return self.userSettings
end

-- Set specific setting
function SettingsMenu:setSetting(category, setting, value)
    if not self.userSettings[category] or self.userSettings[category][setting] == nil then
        return false
    end
    
    self.userSettings[category][setting] = value
    
    -- Update UI if visible
    if self.isVisible and self.currentCategory == category then
        local control = self.settingControls[category][setting]
        local settingData = self.settings[category].options[setting]
        
        if control and settingData then
            if settingData.type == "toggle" then
                local toggleButton = control:FindFirstChild("ToggleButton")
                local indicator = toggleButton and toggleButton:FindFirstChild("Indicator")
                
                if toggleButton and indicator then
                    -- Update visuals
                    toggleButton.BackgroundColor3 = value and UIStyle.colors.success or UIStyle.colors.buttonDisabled
                    indicator.Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                end
                
            elseif settingData.type == "slider" then
                local sliderTrack = control:FindFirstChild("SliderTrack")
                local fillTrack = sliderTrack and sliderTrack:FindFirstChild("FillTrack")
                local sliderKnob = sliderTrack and sliderTrack:FindFirstChild("SliderKnob")
                local valueLabel = control:FindFirstChild("ValueLabel")
                
                if sliderTrack and fillTrack and sliderKnob and valueLabel then
                    -- Calculate relative position
                    local relativeX = (value - settingData.min) / (settingData.max - settingData.min)
                    
                    -- Update visuals
                    fillTrack.Size = UDim2.new(relativeX, 0, 1, 0)
                    sliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
                    valueLabel.Text = tostring(value)
                end
            end
        end
    end
    
    return true
end

-- For compatibility with UIManager
function SettingsMenu.create(data)
    local instance = SettingsMenu.new(data)
    local container = instance:createUI()
    
    -- Store instance in container for reference
    container._UIInstance = instance
    
    return container
end

function SettingsMenu.open(ui, data)
    local instance = ui._UIInstance
    if instance then
        instance:open(data)
    end
    
    return ui
end

function SettingsMenu.close(ui)
    local instance = ui._UIInstance
    if instance then
        instance:cleanup()
    elseif ui and ui:IsA("Instance") then
        ui:Destroy()
    end
end

return SettingsMenu