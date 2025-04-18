-- SaunaTemperatureUI.luau
-- UI Module for Sauna Temperature Display
-- Place in ReplicatedStorage/UIModules

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Import client systems
local ClientRegistry = require(LocalPlayer.PlayerScripts.Core.ClientRegistry)
local UIManager = ClientRegistry.getSystem("UIManager")
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    uiSize = UDim2.new(0, 200, 0, 100),
    uiPosition = UDim2.new(1, -220, 0, 20),
    backgroundTransparency = 0.3,
    cornerRadius = UDim.new(0, 10),

    -- Text
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
    showTemperatureRays = true,
    showThermometer = true,
    showHeatEffects = true
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SaunaTemperatureUI]", ...)
    end
end

-- Module table
local SaunaTemperatureUI = {}

-- Internal module state
local inSauna = false
local currentTemperature = 0

-- Function to get color for a temperature
local function getTemperatureColor(temp)
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

-- Create the sauna temperature UI
function SaunaTemperatureUI.create(data)
    log("Creating sauna temperature UI")

    -- Apply custom settings if provided
    if data and data.config then
        for key, value in pairs(data.config) do
            CONFIG[key] = value
        end
    end

    -- Set initial temperature if provided
    if data and data.temperature then
        currentTemperature = data.temperature
    end

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SaunaTemperatureUI"
    screenGui.ResetOnSpawn = false

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "TemperatureFrame"
    mainFrame.Size = CONFIG.uiSize
    mainFrame.Position = CONFIG.uiPosition
    mainFrame.BackgroundColor3 = CONFIG.backgroundColor
    mainFrame.BackgroundTransparency = CONFIG.backgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = inSauna -- Only visible when in sauna
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
    tempLabel.Text = string.format("%.1f°C", currentTemperature)
    tempLabel.TextSize = CONFIG.valueTextSize
    tempLabel.Font = CONFIG.valueFont
    tempLabel.TextColor3 = getTemperatureColor(currentTemperature)
    tempLabel.Parent = mainFrame

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
        
        -- Calculate initial fill amount
        local minTemp = CONFIG.temperatureColors[1].temp
        local maxTemp = CONFIG.temperatureColors[#CONFIG.temperatureColors].temp
        local fillAmount = math.clamp((currentTemperature - minTemp) / (maxTemp - minTemp), 0, 1)
        
        fillBar.Size = UDim2.new(fillAmount, 0, 1, 0)
        fillBar.BackgroundColor3 = getTemperatureColor(currentTemperature)
        fillBar.BorderSizePixel = 0
        fillBar.Parent = thermometerContainer

        -- UICorner for fill bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 5)
        fillCorner.Parent = fillBar
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
    end

    return screenGui
end

-- Function to update the temperature display
function SaunaTemperatureUI:updateTemperature(ui, temperature)
    if not ui or not ui:FindFirstChild("TemperatureFrame") then return end

    log("Updating temperature to " .. temperature)
    currentTemperature = temperature

    local temperatureFrame = ui.TemperatureFrame
    local temperatureLabel = temperatureFrame:FindFirstChild("TemperatureLabel")
    local thermometerContainer = temperatureFrame:FindFirstChild("ThermometerContainer")
    local heatOverlay = ui:FindFirstChild("HeatOverlay")

    -- Update the text
    if temperatureLabel then
        temperatureLabel.Text = string.format("%.1f°C", temperature)

        -- Update the color
        local color = getTemperatureColor(temperature)

        -- Tween to new color
        local colorTween = TweenService:Create(
            temperatureLabel,
            TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
            {TextColor3 = color}
        )
        colorTween:Play()
    end

    -- Update thermometer if it exists
    if thermometerContainer then
        local fillBar = thermometerContainer:FindFirstChild("FillBar")
        
        if fillBar then
            -- Calculate fill amount (0-1)
            local minTemp = CONFIG.temperatureColors[1].temp
            local maxTemp = CONFIG.temperatureColors[#CONFIG.temperatureColors].temp
            local fillAmount = math.clamp((temperature - minTemp) / (maxTemp - minTemp), 0, 1)

            -- Tween size and color
            local barTween = TweenService:Create(
                fillBar,
                TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
                {Size = UDim2.new(fillAmount, 0, 1, 0), BackgroundColor3 = getTemperatureColor(temperature)}
            )
            barTween:Play()
        end
    end

    -- Update heat overlay if it exists
    if heatOverlay and CONFIG.showHeatEffects then
        -- Only show heat effect at higher temperatures
        local heatEffect = math.clamp(
            (temperature - 50) / 50, -- Start at 50°C, max at 100°C
            0, 
            0.3 -- Maximum transparency
        )

        local overlayTween = TweenService:Create(
            heatOverlay,
            TweenInfo.new(CONFIG.animationDuration * 2, Enum.EasingStyle.Sine),
            {BackgroundTransparency = 1 - heatEffect}
        )
        overlayTween:Play()
    end
    
    -- Apply camera effects at high temperatures
    if temperature > 60 and inSauna and CONFIG.showHeatEffects then
        -- This would be implemented here or through another system
    end
end

-- Handle entering sauna
function SaunaTemperatureUI:enterSauna(ui, temperature)
    if not ui or not ui:FindFirstChild("TemperatureFrame") then return end
    
    log("Entering sauna with temperature " .. temperature)
    inSauna = true
    currentTemperature = temperature

    -- Show UI
    ui.TemperatureFrame.Visible = true

    -- Update temperature display
    self:updateTemperature(ui, temperature)
    
    return true
end

-- Handle exiting sauna
function SaunaTemperatureUI:exitSauna(ui)
    if not ui or not ui:FindFirstChild("TemperatureFrame") then return end
    
    log("Exiting sauna")
    inSauna = false

    -- Hide UI
    ui.TemperatureFrame.Visible = false

    -- Reset heat overlay
    local heatOverlay = ui:FindFirstChild("HeatOverlay")
    if heatOverlay then
        local overlayTween = TweenService:Create(
            heatOverlay,
            TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
            {BackgroundTransparency = 1}
        )
        overlayTween:Play()
    end

    -- Remove any camera effects
    local camera = workspace.CurrentCamera
    if camera and CONFIG.showHeatEffects then
        -- Remove camera effects here if needed
    end
    
    return true
end

-- Handle when the UI opens
function SaunaTemperatureUI.open(ui, data)
    log("Opening sauna temperature UI")
    
    -- Connect to events
    if not SaunaTemperatureUI.eventConnected then
        ClientEventBridge.connectEvent("SaunaTemperatureUpdate", function(temperature)
            if ui and ui.Parent then
                SaunaTemperatureUI:updateTemperature(ui, temperature)
            end
        end)
        
        ClientEventBridge.connectEvent("PlayerEnterSauna", function(temperature)
            if ui and ui.Parent then
                SaunaTemperatureUI:enterSauna(ui, temperature)
            end
        end)
        
        ClientEventBridge.connectEvent("PlayerExitSauna", function()
            if ui and ui.Parent then
                SaunaTemperatureUI:exitSauna(ui)
            end
        end)
        
        SaunaTemperatureUI.eventConnected = true
    end
    
    -- If player is already in sauna, show the UI
    if data and data.inSauna then
        SaunaTemperatureUI:enterSauna(ui, data.temperature or 20)
    end
    
    return true
end

-- Handle when the UI closes
function SaunaTemperatureUI.close(ui)
    log("Closing sauna temperature UI")
    
    -- Clean up any camera effects
    local camera = workspace.CurrentCamera
    if camera and CONFIG.showHeatEffects then
        -- Remove camera effects here if needed
    end
    
    -- Hide heat overlay
    local heatOverlay = ui:FindFirstChild("HeatOverlay")
    if heatOverlay then
        heatOverlay.BackgroundTransparency = 1
    end
    
    -- Destroy the UI
    if ui and ui.Parent then
        ui:Destroy()
    end
    
    return true
end

return SaunaTemperatureUI