--!strict
--[[
    Settings.luau
    
    Settings screen implementation.
    Allows users to configure game settings like volume, graphics, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Get the base UI component
local UIComponent = require(script.Parent.Parent.Core.UIComponent)

-- Create Settings class
local Settings = setmetatable({}, {__index = UIComponent})
Settings.__index = Settings

-- Default settings
local DEFAULT_SETTINGS = {
    masterVolume = 1,
    musicVolume = 0.8,
    sfxVolume = 0.8,
    graphicsQuality = "High",
    fullscreen = true,
    showFPS = false
}

-- Constructor
function Settings.new()
    local self = setmetatable(UIComponent.new("Settings"), Settings)
    self.settings = table.clone(DEFAULT_SETTINGS)
    return self
end

-- Override create method
function Settings:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create UI elements
    self:createBackground()
    self:createTitle()
    self:createSettingsPanel()
    self:createButtons()
    
    return self.instance
end

-- Create background
function Settings:createBackground()
    local background = self:createFrame({
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0
    })
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35))
    })
    gradient.Rotation = 45
    gradient.Parent = background
end

-- Create title
function Settings:createTitle()
    local titleContainer = self:createFrame({
        Name = "TitleContainer",
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0.05, 0),
        BackgroundTransparency = 1
    })
    
    local title = self:createLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Settings",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 36
    })
end

-- Create settings panel
function Settings:createSettingsPanel()
    local panel = self:createScrollingFrame({
        Name = "SettingsPanel",
        Size = UDim2.new(0.8, 0, 0.7, 0),
        Position = UDim2.new(0.1, 0, 0.2, 0),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        CanvasSize = UDim2.new(0, 0, 0, 600)
    })
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    -- Create settings sections
    self:createAudioSettings(panel)
    self:createGraphicsSettings(panel)
    self:createGameplaySettings(panel)
end

-- Create audio settings section
function Settings:createAudioSettings(parent)
    local section = self:createFrame({
        Name = "AudioSection",
        Size = UDim2.new(1, -40, 0, 150),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 0.8,
        BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    })
    section.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section
    
    -- Section title
    local title = self:createLabel({
        Name = "AudioTitle",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Audio Settings",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20
    })
    title.Parent = section
    
    -- Master volume slider
    local masterVolume = self:createVolumeSlider(section, "Master Volume", 40, self.settings.masterVolume)
    masterVolume.Parent = section
    
    -- Music volume slider
    local musicVolume = self:createVolumeSlider(section, "Music Volume", 80, self.settings.musicVolume)
    musicVolume.Parent = section
end

-- Create graphics settings section
function Settings:createGraphicsSettings(parent)
    local section = self:createFrame({
        Name = "GraphicsSection",
        Size = UDim2.new(1, -40, 0, 150),
        Position = UDim2.new(0, 20, 0, 190),
        BackgroundTransparency = 0.8,
        BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    })
    section.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section
    
    -- Section title
    local title = self:createLabel({
        Name = "GraphicsTitle",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Graphics Settings",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20
    })
    title.Parent = section
    
    -- Graphics quality dropdown
    local qualityLabel = self:createLabel({
        Name = "QualityLabel",
        Size = UDim2.new(0.4, 0, 0, 30),
        Position = UDim2.new(0, 10, 0, 40),
        Text = "Graphics Quality:",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    qualityLabel.Parent = section
    
    -- Fullscreen toggle
    local fullscreenLabel = self:createLabel({
        Name = "FullscreenLabel",
        Size = UDim2.new(0.4, 0, 0, 30),
        Position = UDim2.new(0, 10, 0, 80),
        Text = "Fullscreen:",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    fullscreenLabel.Parent = section
end

-- Create gameplay settings section
function Settings:createGameplaySettings(parent)
    local section = self:createFrame({
        Name = "GameplaySection",
        Size = UDim2.new(1, -40, 0, 150),
        Position = UDim2.new(0, 20, 0, 360),
        BackgroundTransparency = 0.8,
        BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    })
    section.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section
    
    -- Section title
    local title = self:createLabel({
        Name = "GameplayTitle",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Gameplay Settings",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20
    })
    title.Parent = section
    
    -- Show FPS toggle
    local fpsLabel = self:createLabel({
        Name = "FPSLabel",
        Size = UDim2.new(0.4, 0, 0, 30),
        Position = UDim2.new(0, 10, 0, 40),
        Text = "Show FPS:",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    fpsLabel.Parent = section
end

-- Create volume slider
function Settings:createVolumeSlider(parent, label, yOffset, initialValue)
    local container = Instance.new("Frame")
    container.Name = label .. "Container"
    container.Size = UDim2.new(1, -20, 0, 30)
    container.Position = UDim2.new(0, 10, 0, yOffset)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Label
    local label = self:createLabel({
        Name = label .. "Label",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = label,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    label.Parent = container
    
    -- Slider
    local slider = Instance.new("Frame")
    slider.Name = label .. "Slider"
    slider.Size = UDim2.new(0.5, 0, 0, 4)
    slider.Position = UDim2.new(0.45, 0, 0.5, -2)
    slider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    slider.BorderSizePixel = 0
    slider.Parent = container
    
    -- Slider fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(initialValue, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    -- Slider handle
    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new(initialValue, -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = slider
    
    -- Add corner radius to handle
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = handle
    
    -- Value label
    local valueLabel = self:createLabel({
        Name = label .. "Value",
        Size = UDim2.new(0.1, 0, 1, 0),
        Position = UDim2.new(0.95, 0, 0, 0),
        Text = tostring(math.floor(initialValue * 100)) .. "%",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    valueLabel.Parent = container
    
    return container
end

-- Create buttons
function Settings:createButtons()
    local buttonContainer = self:createFrame({
        Name = "ButtonContainer",
        Size = UDim2.new(0.8, 0, 0, 50),
        Position = UDim2.new(0.1, 0, 0.92, 0),
        BackgroundTransparency = 1
    })
    
    -- Create save button
    local saveButton = self:createButton({
        Name = "SaveButton",
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.35, 0, 0, 0),
        Text = "Save",
        BackgroundColor3 = Color3.fromRGB(114, 137, 218),
        TextSize = 20
    })
    
    -- Create back button
    local backButton = self:createButton({
        Name = "BackButton",
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.65, 0, 0, 0),
        Text = "Back",
        BackgroundColor3 = Color3.fromRGB(50, 53, 59),
        TextSize = 20
    })
    
    -- Add button hover effects
    local function setupButtonHover(button, hoverColor)
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor:Lerp(Color3.new(1, 1, 1), 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
    end
    
    setupButtonHover(saveButton, Color3.fromRGB(114, 137, 218))
    setupButtonHover(backButton, Color3.fromRGB(50, 53, 59))
    
    -- Add button click handlers
    saveButton.MouseButton1Click:Connect(function()
        self:saveSettings()
    end)
    
    backButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
end

-- Save settings
function Settings:saveSettings()
    -- TODO: Implement settings save functionality
    print("Settings saved")
    self:hide()
end

-- Override update method
function Settings:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    -- Update UI elements based on state
    -- TODO: Implement state-based updates
    
    return true
end

return Settings 