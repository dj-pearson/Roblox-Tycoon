-- Temperature Display UI Script
-- Place this in a LocalScript in StarterGui or StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote events
local remotes = {
	updateTemperature = ReplicatedStorage:WaitForChild("updateTemperature"),
	enterSauna = ReplicatedStorage:WaitForChild("enterSauna"),
	exitSauna = ReplicatedStorage:WaitForChild("exitSauna")
}

-- Configuration
local CONFIG = {
	-- UI
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

-- Variables
local temperatureUI
local temperatureValue
local thermometerBar
local inSauna = false
local currentTemperature = 0
local heatOverlay

-- Function to create the temperature UI
local function createTemperatureUI()
	-- Check if UI already exists
	if temperatureUI then temperatureUI:Destroy() end

	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SaunaTemperatureUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

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

	temperatureValue = tempLabel

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

		thermometerBar = fillBar
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

		heatOverlay = overlay
	end

	temperatureUI = screenGui
	return screenGui
end

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

-- Function to update the temperature display
local function updateTemperatureDisplay(temperature)
	if not temperatureUI or not temperatureValue then return end

	currentTemperature = temperature

	-- Update the text
	temperatureValue.Text = string.format("%.1f°C", temperature)

	-- Update the color
	local color = getTemperatureColor(temperature)

	-- Tween to new color
	local colorTween = TweenService:Create(
		temperatureValue,
		TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
		{TextColor3 = color}
	)
	colorTween:Play()

	-- Update thermometer if it exists
	if thermometerBar then
		-- Calculate fill amount (0-1)
		local minTemp = CONFIG.temperatureColors[1].temp
		local maxTemp = CONFIG.temperatureColors[#CONFIG.temperatureColors].temp
		local fillAmount = math.clamp((temperature - minTemp) / (maxTemp - minTemp), 0, 1)

		-- Tween size and color
		local barTween = TweenService:Create(
			thermometerBar,
			TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Sine),
			{Size = UDim2.new(fillAmount, 0, 1, 0), BackgroundColor3 = color}
		)
		barTween:Play()
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
end

-- Handle entering sauna
local function onEnterSauna(temperature)
	inSauna = true

	-- Create UI if it doesn't exist
	if not temperatureUI then
		createTemperatureUI()
	end

	-- Show UI
	temperatureUI.TemperatureFrame.Visible = true

	-- Update temperature display
	updateTemperatureDisplay(temperature)

	-- Add heat wavering effect to camera
	if CONFIG.showHeatEffects and temperature > 60 then
		local camera = workspace.CurrentCamera
		if camera then
			-- Apply subtle camera shake/waver based on temperature
			-- This would be implemented here
		end
	end
end

-- Handle exiting sauna
local function onExitSauna()
	inSauna = false

	-- Hide UI
	if temperatureUI and temperatureUI.TemperatureFrame then
		temperatureUI.TemperatureFrame.Visible = false
	end

	-- Reset heat overlay
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
	if camera then
		-- Remove camera effects here
	end
end

-- Connect to remote events
remotes.enterSauna.OnClientEvent:Connect(onEnterSauna)
remotes.exitSauna.OnClientEvent:Connect(onExitSauna)
remotes.updateTemperature.OnClientEvent:Connect(updateTemperatureDisplay)

-- Create the UI
createTemperatureUI()

print("Temperature display UI initialized")