-- SpecializationClient.lua
-- Place this in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local openSpecMenuEvent = ReplicatedStorage:WaitForChild("OpenSpecializationMenu")
local showSpecMenuFunc = ReplicatedStorage:WaitForChild("ShowSpecializationsMenu")

-- Configuration
local CONFIG = {
	buttonPosition = UDim2.new(1, -160, 0, 100),
	buttonSize = UDim2.new(0, 150, 0, 40),
	buttonColor = Color3.fromRGB(0, 120, 180),
	buttonHoverColor = Color3.fromRGB(0, 150, 220),
	textColor = Color3.fromRGB(255, 255, 255),

	tweenDuration = 0.3,
	notificationDuration = 5
}

-- Create a button to access specializations
local function createSpecButton()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpecializationButtonGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Create button
	local button = Instance.new("TextButton")
	button.Name = "SpecializationButton"
	button.Size = CONFIG.buttonSize
	button.Position = CONFIG.buttonPosition
	button.BackgroundColor3 = CONFIG.buttonColor
	button.Text = "Specializations"
	button.TextColor3 = CONFIG.textColor
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AnchorPoint = Vector2.new(0, 0)
	button.Parent = screenGui

	-- Add rounded corners
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button

	-- Add button effects
	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(CONFIG.tweenDuration, Enum.EasingStyle.Quad),
			{BackgroundColor3 = CONFIG.buttonHoverColor}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(CONFIG.tweenDuration, Enum.EasingStyle.Quad),
			{BackgroundColor3 = CONFIG.buttonColor}
		):Play()
	end)

	-- Connect click
	button.MouseButton1Click:Connect(function()
		openSpecMenuEvent:FireServer()
	end)

	return button
end

-- Create a function to show benefits notification when player changes specializations
local function createBenefitsNotification(specialization)
	-- Create notification GUI
	local notification = Instance.new("ScreenGui")
	notification.Name = "SpecializationNotification"
	notification.ResetOnSpawn = false
	notification.Parent = player.PlayerGui

	-- Create frame
	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrame"
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0, -160)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = notification

	-- Add rounded corners
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = frame

	-- Add title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Text = specialization.name .. " Specialization"
	title.Parent = frame

	-- Add benefits list
	local benefits = Instance.new("TextLabel")
	benefits.Name = "Benefits"
	benefits.Size = UDim2.new(1, -40, 1, -50)
	benefits.Position = UDim2.new(0, 20, 0, 40)
	benefits.BackgroundTransparency = 1
	benefits.Font = Enum.Font.Gotham
	benefits.TextColor3 = Color3.fromRGB(220, 220, 220)
	benefits.TextSize = 14
	benefits.TextWrapped = true
	benefits.TextXAlignment = Enum.TextXAlignment.Left
	benefits.TextYAlignment = Enum.TextYAlignment.Top

	-- Create benefits text
	local benefitsText = "Active Benefits:\n\n"

	if specialization.benefits.membership_boost then
		local percent = math.floor((specialization.benefits.membership_boost - 1) * 100)
		if percent > 0 then
			benefitsText = benefitsText .. "• " .. percent .. "% more members\n"
		elseif percent < 0 then
			benefitsText = benefitsText .. "• " .. math.abs(percent) .. "% fewer members (higher quality)\n"
		end
	end

	if specialization.benefits.dues_boost then
		local percent = math.floor((specialization.benefits.dues_boost - 1) * 100)
		if percent > 0 then
			benefitsText = benefitsText .. "• " .. percent .. "% higher membership fees\n"
		end
	end

	if specialization.benefits.vip_chance then
		local percent = math.floor(specialization.benefits.vip_chance * 100)
		benefitsText = benefitsText .. "• " .. percent .. "% chance for VIP members\n"
	end

	if specialization.benefits.vip_multiplier and specialization.benefits.vip_multiplier > 1 then
		local percent = math.floor((specialization.benefits.vip_multiplier - 1) * 100)
		benefitsText = benefitsText .. "• VIP members pay " .. percent .. "% more\n"
	end

	if specialization.benefits.competition_boost and specialization.benefits.competition_boost > 1 then
		local percent = math.floor((specialization.benefits.competition_boost - 1) * 100)
		benefitsText = benefitsText .. "• " .. percent .. "% better competition results\n"
	end

	if specialization.benefits.equipment_discounts then
		benefitsText = benefitsText .. "• Discounts on specialty equipment\n"
	end

	benefits.Text = benefitsText
	benefits.Parent = frame

	-- Animate the notification in
	frame:TweenPosition(
		UDim2.new(0.5, -150, 0, 20),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5
	)

	-- Auto-remove after duration
	delay(CONFIG.notificationDuration, function()
		frame:TweenPosition(
			UDim2.new(0.5, -150, 0, -160),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.5
		)

		delay(0.5, function()
			notification:Destroy()
		end)
	end)

	return notification
end

-- Check for specialization changes
local function checkSpecializationChanges()
	local currentSpecs

	-- Function to get current specializations
	local function getCurrentSpecs()
		local success, result = pcall(function()
			return showSpecMenuFunc:InvokeServer()
		end)

		if success and result and result.current then
			return result.current
		end

		return {primary = nil, secondary = nil}
	end

	-- Get initial specializations
	currentSpecs = getCurrentSpecs()

	-- Poll for changes (a better approach would be to use a RemoteEvent)
	spawn(function()
		while wait(5) do -- Check every 5 seconds
			local newSpecs = getCurrentSpecs()

			-- Check for primary specialization change
			if newSpecs.primary ~= currentSpecs.primary and newSpecs.primary then
				-- Get specialization data
				local specData
				local success, result = pcall(function()
					return showSpecMenuFunc:InvokeServer()
				end)

				if success and result and result.available then
					for _, spec in ipairs(result.available) do
						if spec.id == newSpecs.primary then
							specData = spec
							break
						end
					end
				end

				-- Show notification with benefits
				if specData then
					createBenefitsNotification(specData)
				end
			end

			-- Update current specs
			currentSpecs = newSpecs
		end
	end)
end

-- Initialize
local function initialize()
	createSpecButton()
	checkSpecializationChanges()

	print("Specialization client initialized")
end

initialize()