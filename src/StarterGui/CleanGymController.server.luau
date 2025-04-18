-- CleanGymController.lua
-- LocalScript for cleaning gym functionality
-- Place in StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	buttonPosition = UDim2.new(0, 20, 0.6, 0),
	buttonSize = UDim2.new(0, 150, 0, 40),
	buttonColor = Color3.fromRGB(50, 150, 220),
	buttonHoverColor = Color3.fromRGB(70, 170, 240),
	textColor = Color3.fromRGB(255, 255, 255),

	cleanPrice = 150, -- Cost to clean gym

	cooldownTime = 60, -- Seconds between cleanings

	-- Animation
	tweenDuration = 0.2
}

-- Create the cleaning button
local function createCleanButton()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CleanGymGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Create button
	local button = Instance.new("TextButton")
	button.Name = "CleanButton"
	button.Size = CONFIG.buttonSize
	button.Position = CONFIG.buttonPosition
	button.BackgroundColor3 = CONFIG.buttonColor
	button.Text = "Clean Gym ($" .. CONFIG.cleanPrice .. ")"
	button.TextColor3 = CONFIG.textColor
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AutoButtonColor = false
	button.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Add drop shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.ZIndex = -1
	shadow.Image = "rbxassetid://6014254928" -- Shadow image
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.Parent = button

	-- Add cooldown overlay
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0) -- Start with 0 height
	cooldownOverlay.Position = UDim2.new(0, 0, 1, 0) -- Start from bottom
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	cooldownOverlay.BackgroundTransparency = 0.7
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.Visible = false
	cooldownOverlay.ZIndex = 2
	cooldownOverlay.Parent = button

	-- Rounded corners for overlay
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 8)
	overlayCorner.Parent = cooldownOverlay

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.TextColor3 = CONFIG.textColor
	cooldownText.Font = Enum.Font.GothamSemibold
	cooldownText.TextSize = 14
	cooldownText.Text = ""
	cooldownText.ZIndex = 3
	cooldownText.Parent = button

	-- Button hover effects
	button.MouseEnter:Connect(function()
		if not cooldownOverlay.Visible then
			TweenService:Create(
				button,
				TweenInfo.new(CONFIG.tweenDuration, Enum.EasingStyle.Quad),
				{BackgroundColor3 = CONFIG.buttonHoverColor}
			):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(CONFIG.tweenDuration, Enum.EasingStyle.Quad),
			{BackgroundColor3 = CONFIG.buttonColor}
		):Play()
	end)

	-- Get clean gym function from server
	local cleanGymFunction = ReplicatedStorage:FindFirstChild("CleanGymFunction")
	if not cleanGymFunction then
		warn("CleanGymFunction not found in ReplicatedStorage")
		return
	end

	-- Track cooldown state
	local onCooldown = false

	-- Handle button click
	button.MouseButton1Click:Connect(function()
		if onCooldown then return end

		-- Check if player has enough money
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats or not leaderstats:FindFirstChild("Cash") then
			return
		end

		if leaderstats.Cash.Value < CONFIG.cleanPrice then
			-- Show not enough money message
			cooldownText.Text = "Not enough money!"

			-- Clear message after 2 seconds
			delay(2, function()
				cooldownText.Text = ""
			end)

			return
		end

		-- Call server function
		local success, result = pcall(function()
			return cleanGymFunction:InvokeServer()
		end)

		if success and result then
			-- Deduct money
			leaderstats.Cash.Value = leaderstats.Cash.Value - CONFIG.cleanPrice

			-- Start cooldown
			onCooldown = true
			cooldownOverlay.Visible = true

			-- Animate cooldown
			for i = CONFIG.cooldownTime, 0, -1 do
				cooldownText.Text = "Cooldown: " .. i .. "s"

				-- Update overlay height
				local progress = i / CONFIG.cooldownTime
				cooldownOverlay.Size = UDim2.new(1, 0, progress, 0)
				cooldownOverlay.Position = UDim2.new(0, 0, 1 - progress, 0)

				wait(1)
			end

			-- Reset after cooldown
			cooldownOverlay.Visible = false
			cooldownText.Text = ""
			onCooldown = false
		else
			warn("Failed to clean gym:", result)
		end
	end)

	return button
end

-- Create the button
local cleanButton = createCleanButton()

-- You might want to add additional features here such as:
-- 1. Auto-updating the price based on gym size
-- 2. Making button more prominent when cleanliness is low
-- 3. Adding visual effects when cleaning is performed