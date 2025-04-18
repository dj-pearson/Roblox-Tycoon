--[[
    TemperatureDisplay.client.luau
    Client-side UI module for displaying sauna temperature
    Part of the UI modules architecture
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Client references
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Module dependencies
local ClientRegistry
local UIManager

-- Configuration
local CONFIG = {
    -- UI sizing and positioning
    uiSize = UDim2.new(0, 200, 0, 100),
    uiPosition = UDim2.new(1, -220, 0, 20),
    backgroundTransparency = 0.3,
    cornerRadius = UDim.new(0, 10),

    -- Text settings
    titleFont = Enum.Font.GothamBold,
    valueFont = Enum.Font.GothamBold,
    titleTextSize = 16,
    valueTextSize = 24,

    -- Colors
    backgroundColor = Color3.fromRGB(30, 30, 30),
    titleColor = Color3.fromRGB(255, 255, 255),

    -- Temperature colors (gradient from cool to hot)
    temperatureColors = {
        {temp = 20, color = Color3.fromRGB(0, 162, 255)},   -- Cool blue
        {temp = 40, color = Color3.fromRGB(0, 255, 126)},   -- Teal
        {temp = 60, color = Color3.fromRGB(255, 217, 0)},   -- Yellow
        {temp = 80, color = Color3.fromRGB(255, 115, 0)},   -- Orange
        {temp = 100, color = Color3.fromRGB(255, 0, 0)}     -- Red
    },

    -- Animation
    animationDuration = 0.5,

    -- Effects
    showThermometer = true,
    showHeatEffects = true,
    
    -- Debug
    debug = false
}

-- Module table
local TemperatureDisplay = {
    _name = "TemperatureDisplay",
    _version = "1.0.0",
    _dependencies = {"ClientRegistry", "UIManager"},
    
    -- Internal state
    _gui = nil,
    _temperatureValue = nil,
    _thermometerBar = nil,
    _heatOverlay = nil,
    _currentTemperature = 0,
    _visible = false
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Temperature Display]", ...)
    end
end

--[[ Helper Functions ]]--

-- Get appropriate color for a temperature
function TemperatureDisplay:_getTemperatureColor(temp)
    local colors = CONFIG.temperatureColors

    -- If below minimum temperature
    if temp <= colors[1].temp then
        return colors[1].color
    end

    -- If above maximum temperature
    if temp >= colors[#colors].temp then
        return colors[#colors].color
    end

    -- Find the two colors to lerp between
    for i = 1, #colors - 1 do
        local current = colors[i]
        local next = colors[i + 1]

        if temp >= current.temp and temp <= next.temp then
            -- Calculate interpolation factor
            local factor = (temp - current.temp) / (next.temp - current.temp)

            -- Lerp between colors
            return Color3.new(
                current.color.R + (next.color.R - current.color.R) * factor,
                current.color.G + (next.color.G - current.color.G) * factor,
                current.color.B + (next.color.B - current.color.B) * factor
            )
        end
    end

    -- Fallback
    return colors[1].color
end

--[[ Core Functions ]]--

-- Create the temperature UI
function TemperatureDisplay:_createUI()
    -- Check if UI already exists
    if self._gui then 
        self._gui:Destroy()
    end

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SaunaTemperatureUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "TemperatureFrame"
    mainFrame.Size = CONFIG.uiSize
    mainFrame.Position = CONFIG.uiPosition
    mainFrame.BackgroundColor3 = CONFIG.backgroundColor
    mainFrame.BackgroundTransparency = CONFIG.backgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    -- Round corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = CONFIG.cornerRadius
    uiCorner.Parent = mainFrame

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SAUNA TEMPERATURE"
    titleLabel.TextColor3 = CONFIG.titleColor
    titleLabel.TextSize = CONFIG.titleTextSize
    titleLabel.Font = CONFIG.titleFont
    titleLabel.Parent = mainFrame

    -- Temperature value label
    local tempLabel = Instance.new("TextLabel")
    tempLabel.Name = "TemperatureLabel"
    tempLabel.Size = UDim2.new(1, 0, 0, 40)
    tempLabel.Position = UDim2.new(0, 0, 0, 45)
    tempLabel.BackgroundTransparency = 1
    tempLabel.Text = "0°C"
    tempLabel.TextSize = CONFIG.valueTextSize
    tempLabel.Font = CONFIG.valueFont
    tempLabel.TextColor3 = CONFIG.temperatureColors[1].color
    tempLabel.Parent = mainFrame

    self._temperatureValue = tempLabel

    -- Thermometer (if enabled)
    if CONFIG.showThermometer then
        -- Container
        local thermometerContainer = Instance.new("Frame")
        thermometerContainer.Name = "ThermometerContainer"
        thermometerContainer.Size = UDim2.new(0.8, 0, 0, 10)
        thermometerContainer.Position = UDim2.new(0.1, 0, 1, -20)
        thermometerContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        thermometerContainer.BorderSizePixel = 0
        thermometerContainer.Parent = mainFrame

        -- UICorner for container
        local thermoCorner = Instance.new("UICorner")
        thermoCorner.CornerRadius = UDim.new(0, 5)
        thermoCorner.Parent = thermometerContainer

        -- Fill bar
        local fillBar = Instance.new("Frame")
        fillBar.Name = "FillBar"
        fillBar.Size = UDim2.new(0, 0, 1, 0)
        fillBar.BackgroundColor3 = CONFIG.temperatureColors[1].color
        fillBar.BorderSizePixel = 0
        fillBar.Parent = thermometerContainer

        -- UICorner for fill bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 5)
        fillCorner.Parent = fillBar

        self._thermometerBar = fillBar
    end

    -- Create heat overlay if enabled
    if CONFIG.showHeatEffects then
        local overlay = Instance.new("Frame")
        overlay.Name = "HeatOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(255, 60, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 10
        overlay.Parent = screenGui

        self._heatOverlay = overlay
    end

    self._gui = screenGui
    return screenGui
end

--[[ Public API ]]--

-- Show the temperature display
function TemperatureDisplay:show(initialTemperature)
    -- Create UI if it doesn't exist
    if not self._gui then
        self:_createUI()
    end
    
    -- Initialize with temperature if provided
    if initialTemperature then
        self:updateTemperature(initialTemperature)
    end
    
    -- Show the frame
    self._gui.TemperatureFrame.Visible = true
    self._visible = true
    
    -- Animate entry
    local frame = self._gui.TemperatureFrame
    frame.Position = UDim2.new(1, 0, 0, 20) -- Start off screen
    
    local entryTween = TweenService:Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = CONFIG.uiPosition}
    )
    entryTween:Play()
    
    debugPrint("Showing temperature display")
end

-- Hide the temperature display
function TemperatureDisplay:hide()
    if not self._gui or not self._visible then return end
    
    -- Animate exit
    local frame = self._gui.TemperatureFrame
    
    local exitTween = TweenService:Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 20)} -- Move off screen
    )
    
    exitTween.Completed:Connect(function()
        frame.Visible = false
        self._visible = false
    end)
    
    exitTween:Play()
    
    -- Reset heat overlay effect
    if self._heatOverlay then
        local overlayTween = TweenService:Create(
            self._heatOverlay,
            TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
            {BackgroundTransparency = 1}
        )
        overlayTween:Play()
    end
    
    debugPrint("Hiding temperature display")
end

-- Update the temperature display
function TemperatureDisplay:updateTemperature(temperature)
    if not self._gui or not self._temperatureValue then return end
    
    self._currentTemperature = temperature

    -- Update the text
    self._temperatureValue.Text = string.format("%.1f°C", temperature)

    -- Update the color
    local color = self:_getTemperatureColor(temperature)

    -- Tween to new color
    local colorTween = TweenService:Create(
        self._temperatureValue,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
        {TextColor3 = color}
    )
    colorTween:Play()

    -- Update thermometer if it exists
    if self._thermometerBar then
        -- Calculate fill amount (0-1)
        local minTemp = CONFIG.temperatureColors[1].temp
        local maxTemp = CONFIG.temperatureColors[#CONFIG.temperatureColors].temp
        local fillAmount = math.clamp((temperature - minTemp) / (maxTemp - minTemp), 0, 1)

        -- Tween size and color
        local barTween = TweenService:Create(
            self._thermometerBar,
            TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
            {Size = UDim2.new(fillAmount, 0, 1, 0), BackgroundColor3 = color}
        )
        barTween:Play()
    end

    -- Update heat overlay if it exists
    if self._heatOverlay and CONFIG.showHeatEffects then
        -- Only show heat effect at higher temperatures
        local heatEffect = math.clamp(
            (temperature - 50) / 50, -- Start at 50°C, max at 100°C
            0, 
            0.3 -- Maximum transparency
        )

        local overlayTween = TweenService:Create(
            self._heatOverlay,
            TweenInfo.new(CONFIG.animationDuration * 2, Enum.EasingStyle.Sine),
            {BackgroundTransparency = 1 - heatEffect}
        )
        overlayTween:Play()
    end
    
    debugPrint("Updated temperature:", temperature)
end

-- Toggle temperature display visibility
function TemperatureDisplay:toggle()
    if self._visible then
        self:hide()
    else
        self:show(self._currentTemperature)
    end
    
    return self._visible
end

-- Get current temperature
function TemperatureDisplay:GetCurrentTemperature()
    return self._currentTemperature
end

-- Update UI configuration
function TemperatureDisplay:UpdateConfig(newConfig)
    -- Merge new config with existing
    for key, value in pairs(newConfig) do
        CONFIG[key] = value
    end
    
    -- Recreate UI if it exists
    if self._gui then
        local wasVisible = self._visible
        local temp = self._currentTemperature
        
        self:_createUI()
        
        if wasVisible then
            self:show(temp)
        end
    end
end

--[[ Initialization and Cleanup ]]--

-- Initialize the module
function TemperatureDisplay:init()
    debugPrint("Initializing TemperatureDisplay v" .. self._version)
    
    -- Get dependencies
    ClientRegistry = self.ClientRegistry
    if ClientRegistry then
        UIManager = ClientRegistry:getSystem("UIManager")
    end
    
    return true
end

-- Start the module
function TemperatureDisplay:start()
    debugPrint("TemperatureDisplay started")
    
    -- Pre-create UI
    self:_createUI()
    
    return true
end

-- Stop the module
function TemperatureDisplay:stop()
    debugPrint("TemperatureDisplay stopped")
    
    -- Clean up resources
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
    
    self._temperatureValue = nil
    self._thermometerBar = nil
    self._heatOverlay = nil
    self._visible = false
    
    return true
end

return TemperatureDisplay