-- SpecializationsUI.luau
-- Client-side UI module for the Gym Specialization System

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventBridge

-- Module
local SpecializationsUI = {
	Name = "SpecializationsUI",
	Dependencies = {
		"EventBridge"
	},
	screenGui = nil,
	isVisible = false
}

-- Constants
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HIDE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local UI_COLORS = {
	background = Color3.fromRGB(30, 30, 30),
	title = Color3.fromRGB(255, 255, 255),
	description = Color3.fromRGB(200, 200, 200),
	cardBackground = Color3.fromRGB(40, 40, 40),
	primarySelection = Color3.fromRGB(0, 100, 180),
	secondarySelection = Color3.fromRGB(0, 80, 140),
	primaryButton = Color3.fromRGB(0, 120, 180),
	secondaryButton = Color3.fromRGB(0, 100, 160),
	activeButton = Color3.fromRGB(0, 180, 0),
	disabledButton = Color3.fromRGB(100, 100, 100),
	closeButton = Color3.fromRGB(200, 50, 50)
}

-- Current player specialization data
local playerSpecializations = {
	primary = nil,
	secondary = nil,
	available = {}
}

-- Initialize the UI module
function SpecializationsUI:Initialize(registry)
	-- Get dependencies
	EventBridge = registry:GetSystem("EventBridge")
	
	if not EventBridge then
		warn("[SpecializationsUI] Missing EventBridge dependency!")
		return false
	end
	
	-- Register event handlers
	EventBridge:HandleEvent("OpenSpecializationsMenu", function()
		self:ShowUI()
	end)
	
	EventBridge:HandleEvent("SpecializationUpdated", function(data)
		self:UpdatePlayerSpecializations(data)
	end)
	
	-- Create command button
	self:CreateCommandButton()
	
	print("[SpecializationsUI] Initialized")
	return true
end

-- Create the specializations button in command bar
function SpecializationsUI:CreateCommandButton()
	-- Check if CommandBar exists, create if not
	local player = Players.LocalPlayer
	local commandBar = player.PlayerGui:FindFirstChild("GymCommandBar")
	
	if not commandBar then
		commandBar = Instance.new("ScreenGui")
		commandBar.Name = "GymCommandBar"
		commandBar.ResetOnSpawn = false
		commandBar.Parent = player.PlayerGui
	end
	
	-- Check if button already exists
	local existingButton = commandBar:FindFirstChild("SpecializationButton")
	if existingButton then
		existingButton:Destroy()
	end
	
	-- Create a button for specializations
	local specButton = Instance.new("TextButton")
	specButton.Name = "SpecializationButton"
	specButton.Size = UDim2.new(0, 150, 0, 40)
	specButton.Position = UDim2.new(1, -160, 0, 100)
	specButton.AnchorPoint = Vector2.new(0, 0)
	specButton.BackgroundColor3 = UI_COLORS.primaryButton
	specButton.Font = Enum.Font.GothamBold
	specButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	specButton.TextSize = 14
	specButton.Text = "Specializations"
	specButton.ZIndex = 10
	
	-- Add rounded corners
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = specButton
	
	-- Add shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.ZIndex = 9
	shadow.Image = "rbxassetid://6015897843" -- Shadow image asset
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = specButton
	
	-- Connect button
	specButton.MouseButton1Click:Connect(function()
		EventBridge:FireServer("OpenSpecializationsMenu")
	end)
	
	specButton.Parent = commandBar
end

-- Create the specializations UI
function SpecializationsUI:CreateUI()
	local player = Players.LocalPlayer
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpecializationGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0, -400) -- Start off screen
	mainFrame.BackgroundColor3 = UI_COLORS.background
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = mainFrame
	
	-- Add shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.ZIndex = 0
	shadow.Image = "rbxassetid://6015897843" -- Shadow image asset
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = UI_COLORS.title
	title.TextSize = 24
	title.Text = "Gym Specialization"
	title.Parent = mainFrame

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -40, 0, 40)
	description.Position = UDim2.new(0, 20, 0, 40)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = UI_COLORS.description
	description.TextSize = 16
	description.TextWrapped = true
	description.Text = "Choose a specialization to focus your gym and receive unique bonuses."
	description.Parent = mainFrame

	-- Specialization container
	local container = Instance.new("ScrollingFrame")
	container.Name = "SpecContainer"
	container.Size = UDim2.new(1, -40, 1, -140)
	container.Position = UDim2.new(0, 20, 0, 90)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 6
	container.ScrollingDirection = Enum.ScrollingDirection.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
	container.Parent = mainFrame

	-- Add list layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	-- Current specialization label
	local currentLabel = Instance.new("TextLabel")
	currentLabel.Name = "CurrentSpecLabel"
	currentLabel.Size = UDim2.new(1, -40, 0, 30)
	currentLabel.Position = UDim2.new(0, 20, 1, -40)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.GothamSemibold
	currentLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	currentLabel.TextSize = 16
	currentLabel.TextWrapped = true
	currentLabel.Text = "Current Primary: None | Secondary: None"
	currentLabel.Parent = mainFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = UI_COLORS.closeButton
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Text = "X"
	closeButton.Parent = mainFrame

	-- Add rounded corners to close button
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 15)
	closeCorner.Parent = closeButton

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		self:HideUI()
	end)

	screenGui.Parent = player.PlayerGui
	self.screenGui = screenGui
	
	return screenGui
end

-- Create a specialization card
function SpecializationsUI:CreateSpecCard(container, specId, specData, isPrimary, isSecondary, isAvailable)
	local card = Instance.new("Frame")
	card.Name = specId .. "Card"
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = UI_COLORS.cardBackground

	-- Change background color based on selection
	if isPrimary then
		card.BackgroundColor3 = UI_COLORS.primarySelection
	elseif isSecondary then
		card.BackgroundColor3 = UI_COLORS.secondarySelection
	end

	card.BorderSizePixel = 0

	-- Add rounded corners
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Add card shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
	shadow.Size = UDim2.new(1, 8, 1, 8)
	shadow.ZIndex = 0
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -130, 0, 30)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = specData.name
	title.Parent = card

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -130, 0, 50)
	description.Position = UDim2.new(0, 15, 0, 40)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = Color3.fromRGB(220, 220, 220)
	description.TextSize = 14
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.Text = specData.description
	description.Parent = card

	-- Level requirement
	local levelReq = Instance.new("TextLabel")
	levelReq.Name = "LevelReq"
	levelReq.Size = UDim2.new(1, -130, 0, 20)
	levelReq.Position = UDim2.new(0, 15, 0, 90)
	levelReq.BackgroundTransparency = 1
	levelReq.Font = Enum.Font.Gotham
	levelReq.TextColor3 = Color3.fromRGB(180, 180, 180)
	levelReq.TextSize = 12
	levelReq.TextXAlignment = Enum.TextXAlignment.Left
	levelReq.Text = "Requires Level " .. specData.level_requirement
	levelReq.Parent = card

	-- Primary button
	local primaryButton = Instance.new("TextButton")
	primaryButton.Name = "PrimaryButton"
	primaryButton.Size = UDim2.new(0, 100, 0, 30)
	primaryButton.Position = UDim2.new(1, -115, 0, 25)
	primaryButton.BackgroundColor3 = isPrimary and UI_COLORS.activeButton or UI_COLORS.primaryButton
	primaryButton.Font = Enum.Font.GothamBold
	primaryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	primaryButton.TextSize = 14
	primaryButton.Text = isPrimary and "PRIMARY" or "Set Primary"
	primaryButton.Parent = card

	-- Add rounded corners to button
	local primaryCorner = Instance.new("UICorner")
	primaryCorner.CornerRadius = UDim.new(0, 6)
	primaryCorner.Parent = primaryButton

	-- Secondary button
	local secondaryButton = Instance.new("TextButton")
	secondaryButton.Name = "SecondaryButton"
	secondaryButton.Size = UDim2.new(0, 100, 0, 30)
	secondaryButton.Position = UDim2.new(1, -115, 0, 65)
	secondaryButton.BackgroundColor3 = isSecondary and UI_COLORS.activeButton or UI_COLORS.secondaryButton
	secondaryButton.Font = Enum.Font.GothamBold
	secondaryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	secondaryButton.TextSize = 14
	secondaryButton.Text = isSecondary and "SECONDARY" or "Set Secondary"
	secondaryButton.Parent = card

	-- Add rounded corners to button
	local secondaryCorner = Instance.new("UICorner")
	secondaryCorner.CornerRadius = UDim.new(0, 6)
	secondaryCorner.Parent = secondaryButton
	
	-- Add button shadows
	local primaryShadow = Instance.new("ImageLabel")
	primaryShadow.Name = "Shadow"
	primaryShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	primaryShadow.BackgroundTransparency = 1
	primaryShadow.Position = UDim2.new(0.5, 0, 0.5, 2)
	primaryShadow.Size = UDim2.new(1, 6, 1, 6)
	primaryShadow.ZIndex = 0
	primaryShadow.Image = "rbxassetid://6015897843"
	primaryShadow.ImageColor3 = Color3.new(0, 0, 0)
	primaryShadow.ImageTransparency = 0.7
	primaryShadow.ScaleType = Enum.ScaleType.Slice
	primaryShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	primaryShadow.Parent = primaryButton
	
	local secondaryShadow = primaryShadow:Clone()
	secondaryShadow.Parent = secondaryButton

	-- Disable if not available
	if not isAvailable then
		primaryButton.BackgroundColor3 = UI_COLORS.disabledButton
		secondaryButton.BackgroundColor3 = UI_COLORS.disabledButton
		primaryButton.Text = "Locked"
		secondaryButton.Text = "Locked"
		primaryButton.Enabled = false
		secondaryButton.Enabled = false
		
		-- Add tooltip for unavailable reason if provided
		if specData.unavailable_reason then
			local lockedTooltip = Instance.new("TextLabel")
			lockedTooltip.Name = "LockedTooltip"
			lockedTooltip.Size = UDim2.new(0, 120, 0, 30)
			lockedTooltip.Position = UDim2.new(1, -125, 0, -35)
			lockedTooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			lockedTooltip.BackgroundTransparency = 0.2
			lockedTooltip.BorderSizePixel = 0
			lockedTooltip.Font = Enum.Font.Gotham
			lockedTooltip.TextColor3 = Color3.fromRGB(255, 100, 100)
			lockedTooltip.TextSize = 12
			lockedTooltip.TextWrapped = true
			lockedTooltip.Text = specData.unavailable_reason
			lockedTooltip.Visible = false
			
			local tooltipCorner = Instance.new("UICorner")
			tooltipCorner.CornerRadius = UDim.new(0, 6)
			tooltipCorner.Parent = lockedTooltip
			
			lockedTooltip.Parent = card
			
			-- Show tooltip on hover
			primaryButton.MouseEnter:Connect(function()
				lockedTooltip.Visible = true
			end)
			
			primaryButton.MouseLeave:Connect(function()
				lockedTooltip.Visible = false
			end)
			
			secondaryButton.MouseEnter:Connect(function()
				lockedTooltip.Visible = true
			end)
			
			secondaryButton.MouseLeave:Connect(function()
				lockedTooltip.Visible = false
			end)
		end
	end

	card.Parent = container
	
	-- Connect buttons if available
	if isAvailable then
		primaryButton.MouseButton1Click:Connect(function()
			if not isPrimary then
				self:SetSpecialization(specId, false)
			end
		end)
		
		secondaryButton.MouseButton1Click:Connect(function()
			if not isSecondary then
				self:SetSpecialization(specId, true)
			end
		end)
	end
	
	return card
end

-- Show specialization UI and populate data
function SpecializationsUI:ShowUI()
	-- Don't show if already visible
	if self.isVisible then
		return
	end
	
	-- Get or create the UI
	local screenGui = self.screenGui
	if not screenGui then
		screenGui = self:CreateUI()
	end
	
	local mainFrame = screenGui.MainFrame
	
	-- Get specialization data from server
	local success, specData = EventBridge:InvokeServer("GetSpecializations")
	
	if not success or not specData then
		warn("[SpecializationsUI] Failed to get specialization data from server")
		return
	end
	
	-- Update available specializations
	playerSpecializations.available = specData.available
	playerSpecializations.primary = specData.current.primary
	playerSpecializations.secondary = specData.current.secondary
	
	-- Show and update the UI
	self:RefreshUI()
	
	-- Make UI visible with animation
	mainFrame.Visible = true
	self.isVisible = true
	
	local showTween = TweenService:Create(
		mainFrame,
		TWEEN_INFO,
		{Position = UDim2.new(0.5, -300, 0.5, -200)}
	)
	showTween:Play()
end

-- Hide the UI with animation
function SpecializationsUI:HideUI()
	if not self.isVisible or not self.screenGui then
		return
	end
	
	local mainFrame = self.screenGui.MainFrame
	
	local hideTween = TweenService:Create(
		mainFrame,
		HIDE_TWEEN_INFO,
		{Position = UDim2.new(0.5, -300, 0, -400)}
	)
	hideTween:Play()
	
	hideTween.Completed:Connect(function()
		mainFrame.Visible = false
		self.isVisible = false
	end)
end

-- Update player specializations when received from server
function SpecializationsUI:UpdatePlayerSpecializations(data)
	if not data then return end
	
	playerSpecializations.primary = data.primary
	playerSpecializations.secondary = data.secondary
	
	-- Refresh UI if visible
	if self.isVisible then
		self:RefreshUI()
	end
end

-- Refresh the UI with current specialization data
function SpecializationsUI:RefreshUI()
	if not self.screenGui then return end
	
	local mainFrame = self.screenGui.MainFrame
	local container = mainFrame.SpecContainer
	local currentLabel = mainFrame.CurrentSpecLabel
	
	-- Update current specializations label
	local primaryName = "None"
	local secondaryName = "None"
	
	-- Clear container
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Get name for current specializations
	for _, spec in ipairs(playerSpecializations.available) do
		if spec.id == playerSpecializations.primary then
			primaryName = spec.name
		end
		if spec.id == playerSpecializations.secondary then
			secondaryName = spec.name
		end
	end
	
	currentLabel.Text = "Current Primary: " .. primaryName .. " | Secondary: " .. secondaryName
	
	-- Create cards for all specializations
	for i, spec in ipairs(playerSpecializations.available) do
		local isPrimary = spec.id == playerSpecializations.primary
		local isSecondary = spec.id == playerSpecializations.secondary
		
		local card = self:CreateSpecCard(
			container, 
			spec.id, 
			spec, 
			isPrimary, 
			isSecondary, 
			spec.available
		)
		
		-- Set layout order
		card.LayoutOrder = i
	end
	
	-- Update canvas size
	local listLayout = container:FindFirstChild("UIListLayout")
	if listLayout then
		container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end
end

-- Set a specialization from UI
function SpecializationsUI:SetSpecialization(specializationId, isSecondary)
	if not specializationId then return end
	
	-- Call server to set specialization
	local success, message = EventBridge:InvokeServer("SetSpecialization", specializationId, isSecondary)
	
	if success then
		-- Update local cache immediately for smooth UI transition
		if isSecondary then
			playerSpecializations.secondary = specializationId
		else
			playerSpecializations.primary = specializationId
		end
		
		-- Refresh UI
		self:RefreshUI()
		
		-- Show notification
		self:ShowNotification(message, Color3.fromRGB(0, 200, 0))
	else
		-- Show error message
		self:ShowNotification(message or "Failed to set specialization", Color3.fromRGB(255, 50, 50))
	end
end

-- Show a temporary notification
function SpecializationsUI:ShowNotification(message, color)
	if not message then return end
	
	local player = Players.LocalPlayer
	local notificationGui = player.PlayerGui:FindFirstChild("NotificationGui")
	
	if not notificationGui then
		notificationGui = Instance.new("ScreenGui")
		notificationGui.Name = "NotificationGui"
		notificationGui.ResetOnSpawn = false
		notificationGui.Parent = player.PlayerGui
	end
	
	-- Create notification frame
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 300, 0, 60)
	notification.Position = UDim2.new(0.5, -150, 0, -70)
	notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	notification.BorderSizePixel = 0
	
	-- Add rounded corners
	local cornerRadius = Instance.new("UICorner")
	cornerRadius.CornerRadius = UDim.new(0, 8)
	cornerRadius.Parent = notification
	
	-- Add message text
	local text = Instance.new("TextLabel")
	text.Name = "Message"
	text.Size = UDim2.new(1, -20, 1, 0)
	text.Position = UDim2.new(0, 10, 0, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamSemibold
	text.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	text.TextSize = 16
	text.TextWrapped = true
	text.Text = message
	text.Parent = notification
	
	-- Add color bar on the left
	local colorBar = Instance.new("Frame")
	colorBar.Name = "ColorBar"
	colorBar.Size = UDim2.new(0, 5, 1, 0)
	colorBar.BackgroundColor3 = color or Color3.fromRGB(0, 120, 255)
	colorBar.BorderSizePixel = 0
	colorBar.Parent = notification
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = colorBar
	
	-- Add shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.ZIndex = 0
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Parent = notification
	
	notification.Parent = notificationGui
	
	-- Animate notification
	local showTween = TweenService:Create(
		notification,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -150, 0, 20)}
	)
	showTween:Play()
	
	-- Hide after delay
	task.delay(3, function()
		local hideTween = TweenService:Create(
			notification,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, -150, 0, -70)}
		)
		hideTween:Play()
		
		hideTween.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

return SpecializationsUI