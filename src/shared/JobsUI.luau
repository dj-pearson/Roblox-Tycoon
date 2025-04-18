-- JobsUI.luau
-- UI Module for job management
-- Part of the UI module pattern

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	-- UI Placement
	buttonPosition = UDim2.new(0, 20, 0.8, 0),
	buttonSize = UDim2.new(0, 150, 0, 40),
	
	menuSize = UDim2.new(0, 600, 0, 450),
	menuPosition = UDim2.new(0.5, -300, 0.5, -225),
	
	-- UI Colors
	buttonColor = Color3.fromRGB(70, 100, 200), -- Blue
	buttonHoverColor = Color3.fromRGB(90, 120, 220),
	menuBackgroundColor = Color3.fromRGB(30, 30, 30),
	menuHeaderColor = Color3.fromRGB(20, 20, 20),
	textColor = Color3.fromRGB(255, 255, 255),
	accentColor = Color3.fromRGB(70, 100, 200),
	availableColor = Color3.fromRGB(50, 200, 50), -- Green
	unavailableColor = Color3.fromRGB(150, 150, 150), -- Gray
	deleteColor = Color3.fromRGB(200, 60, 60), -- Red
	
	-- Job colors (for visual identification)
	jobColors = {
		trainer = Color3.fromRGB(255, 100, 0), -- Orange
		receptionist = Color3.fromRGB(0, 100, 255), -- Blue
		maintenance = Color3.fromRGB(100, 100, 100), -- Gray
		nutritionist = Color3.fromRGB(0, 200, 100), -- Green
		manager = Color3.fromRGB(150, 0, 150) -- Purple
	},
	
	-- Animation
	tweenDuration = 0.3
}

-- Module table
local JobsUI = {}

-- Private variables
local uiElements = {}
local callbacks = {}
local isInitialized = false

local selectedJob = nil
local selectedNPC = nil
local currentTab = "hire"

-- Format number as currency
local function formatCurrency(amount)
	return "$" .. tostring(amount)
end

-- Initialize the UI module
function JobsUI:Initialize(UIManager)
	if isInitialized then return end
	
	-- Store reference to UIManager for use in callbacks
	self.UIManager = UIManager
	
	-- Create UI components
	self:CreateUI()
	
	-- Register handlers
	self:RegisterHandlers()
	
	isInitialized = true
	return true
end

-- Create the Jobs UI components
function JobsUI:CreateUI()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JobsGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui
	
	-- Create button
	local button = Instance.new("TextButton")
	button.Name = "JobsButton"
	button.Size = CONFIG.buttonSize
	button.Position = CONFIG.buttonPosition
	button.BackgroundColor3 = CONFIG.buttonColor
	button.Text = "Staff"
	button.TextColor3 = CONFIG.textColor
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
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
	
	-- Create the menu (hidden by default)
	local menu = Instance.new("Frame")
	menu.Name = "JobsMenu"
	menu.Size = CONFIG.menuSize
	menu.Position = CONFIG.menuPosition
	menu.BackgroundColor3 = CONFIG.menuBackgroundColor
	menu.BackgroundTransparency = 0.1
	menu.BorderSizePixel = 0
	menu.Visible = false
	menu.ZIndex = 10
	menu.Parent = screenGui
	
	-- Add rounded corners to menu
	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 12)
	menuCorner.Parent = menu
	
	-- Add menu shadow
	local menuShadow = Instance.new("ImageLabel")
	menuShadow.Name = "Shadow"
	menuShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	menuShadow.BackgroundTransparency = 1
	menuShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuShadow.Size = UDim2.new(1, 40, 1, 40)
	menuShadow.ZIndex = 9
	menuShadow.Image = "rbxassetid://6014254928" -- Shadow image
	menuShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	menuShadow.ImageTransparency = 0.5
	menuShadow.Parent = menu
	
	-- Menu header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = CONFIG.menuHeaderColor
	header.BorderSizePixel = 0
	header.ZIndex = 11
	header.Parent = menu
	
	-- Header corner
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header
	
	-- Fix bottom corners of header
	local headerFix = Instance.new("Frame")
	headerFix.Name = "HeaderFix"
	headerFix.Size = UDim2.new(1, 0, 0, 12)
	headerFix.Position = UDim2.new(0, 0, 1, -12)
	headerFix.BackgroundColor3 = CONFIG.menuHeaderColor
	headerFix.BorderSizePixel = 0
	headerFix.ZIndex = 11
	headerFix.Parent = header
	
	-- Header text
	local headerText = Instance.new("TextLabel")
	headerText.Name = "HeaderText"
	headerText.Size = UDim2.new(1, -50, 1, 0)
	headerText.Position = UDim2.new(0, 20, 0, 0)
	headerText.BackgroundTransparency = 1
	headerText.Font = Enum.Font.GothamBold
	headerText.TextColor3 = CONFIG.textColor
	headerText.TextSize = 22
	headerText.TextXAlignment = Enum.TextXAlignment.Left
	headerText.Text = "Gym Staff Management"
	headerText.ZIndex = 12
	headerText.Parent = header
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.Text = "X"
	closeButton.TextColor3 = CONFIG.textColor
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.ZIndex = 12
	closeButton.Parent = header
	
	-- Close button corner
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	-- Tab buttons
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Name = "TabsContainer"
	tabsContainer.Size = UDim2.new(1, -40, 0, 40)
	tabsContainer.Position = UDim2.new(0, 20, 0, 60)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.ZIndex = 11
	tabsContainer.Parent = menu
	
	-- Hire tab
	local hireTab = Instance.new("TextButton")
	hireTab.Name = "HireTab"
	hireTab.Size = UDim2.new(0.5, -5, 1, 0)
	hireTab.Position = UDim2.new(0, 0, 0, 0)
	hireTab.BackgroundColor3 = CONFIG.accentColor
	hireTab.Text = "Hire Staff"
	hireTab.TextColor3 = CONFIG.textColor
	hireTab.Font = Enum.Font.GothamBold
	hireTab.TextSize = 16
	hireTab.ZIndex = 12
	hireTab.Parent = tabsContainer
	
	local hireCorner = Instance.new("UICorner")
	hireCorner.CornerRadius = UDim.new(0, 8)
	hireCorner.Parent = hireTab
	
	-- Manage tab
	local manageTab = Instance.new("TextButton")
	manageTab.Name = "ManageTab"
	manageTab.Size = UDim2.new(0.5, -5, 1, 0)
	manageTab.Position = UDim2.new(0.5, 5, 0, 0)
	manageTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	manageTab.Text = "Manage Staff"
	manageTab.TextColor3 = CONFIG.textColor
	manageTab.Font = Enum.Font.GothamBold
	manageTab.TextSize = 16
	manageTab.ZIndex = 12
	manageTab.Parent = tabsContainer
	
	local manageCorner = Instance.new("UICorner")
	manageCorner.CornerRadius = UDim.new(0, 8)
	manageCorner.Parent = manageTab
	
	-- Content container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -40, 1, -160)
	contentContainer.Position = UDim2.new(0, 20, 0, 110)
	contentContainer.BackgroundTransparency = 1
	contentContainer.ZIndex = 11
	contentContainer.Parent = menu
	
	-- Create Hire Staff tab content
	local hireContent = Instance.new("Frame")
	hireContent.Name = "HireContent"
	hireContent.Size = UDim2.new(1, 0, 1, 0)
	hireContent.BackgroundTransparency = 1
	hireContent.Visible = true
	hireContent.ZIndex = 11
	hireContent.Parent = contentContainer
	
	-- Create job list container (left side)
	local jobListContainer = Instance.new("ScrollingFrame")
	jobListContainer.Name = "JobListContainer"
	jobListContainer.Size = UDim2.new(0.5, -10, 1, 0)
	jobListContainer.Position = UDim2.new(0, 0, 0, 0)
	jobListContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	jobListContainer.BorderSizePixel = 0
	jobListContainer.ScrollBarThickness = 6
	jobListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	jobListContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	jobListContainer.ZIndex = 12
	jobListContainer.Parent = hireContent
	
	local jobsCorner = Instance.new("UICorner")
	jobsCorner.CornerRadius = UDim.new(0, 8)
	jobsCorner.Parent = jobListContainer
	
	local jobListLayout = Instance.new("UIListLayout")
	jobListLayout.Padding = UDim.new(0, 10)
	jobListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	jobListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	jobListLayout.Parent = jobListContainer
	
	local jobListPadding = Instance.new("UIPadding")
	jobListPadding.PaddingTop = UDim.new(0, 10)
	jobListPadding.PaddingBottom = UDim.new(0, 10)
	jobListPadding.PaddingLeft = UDim.new(0, 10)
	jobListPadding.PaddingRight = UDim.new(0, 10)
	jobListPadding.Parent = jobListContainer
	
	-- Create NPC list container (right side)
	local npcListContainer = Instance.new("ScrollingFrame")
	npcListContainer.Name = "NPCListContainer"
	npcListContainer.Size = UDim2.new(0.5, -10, 1, -60)
	npcListContainer.Position = UDim2.new(0.5, 10, 0, 0)
	npcListContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	npcListContainer.BorderSizePixel = 0
	npcListContainer.ScrollBarThickness = 6
	npcListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	npcListContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	npcListContainer.ZIndex = 12
	npcListContainer.Parent = hireContent
	
	local npcsCorner = Instance.new("UICorner")
	npcsCorner.CornerRadius = UDim.new(0, 8)
	npcsCorner.Parent = npcListContainer
	
	local npcListLayout = Instance.new("UIListLayout")
	npcListLayout.Padding = UDim.new(0, 10)
	npcListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	npcListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	npcListLayout.Parent = npcListContainer
	
	local npcListPadding = Instance.new("UIPadding")
	npcListPadding.PaddingTop = UDim.new(0, 10)
	npcListPadding.PaddingBottom = UDim.new(0, 10)
	npcListPadding.PaddingLeft = UDim.new(0, 10)
	npcListPadding.PaddingRight = UDim.new(0, 10)
	npcListPadding.Parent = npcListContainer
	
	-- Create hire button (below NPC list)
	local hireButton = Instance.new("TextButton")
	hireButton.Name = "HireButton"
	hireButton.Size = UDim2.new(0.5, -10, 0, 50)
	hireButton.Position = UDim2.new(0.5, 10, 1, -50)
	hireButton.BackgroundColor3 = CONFIG.availableColor
	hireButton.Text = "Hire Staff Member"
	hireButton.TextColor3 = CONFIG.textColor
	hireButton.Font = Enum.Font.GothamBold
	hireButton.TextSize = 16
	hireButton.AutoButtonColor = false
	hireButton.ZIndex = 12
	hireButton.Enabled = false -- Disabled by default until selection
	hireButton.Parent = hireContent
	
	local hireButtonCorner = Instance.new("UICorner")
	hireButtonCorner.CornerRadius = UDim.new(0, 8)
	hireButtonCorner.Parent = hireButton
	
	-- Create Manage Staff tab content
	local manageContent = Instance.new("Frame")
	manageContent.Name = "ManageContent"
	manageContent.Size = UDim2.new(1, 0, 1, 0)
	manageContent.BackgroundTransparency = 1
	manageContent.Visible = false
	manageContent.ZIndex = 11
	manageContent.Parent = contentContainer
	
	-- Staff list
	local staffListContainer = Instance.new("ScrollingFrame")
	staffListContainer.Name = "StaffListContainer"
	staffListContainer.Size = UDim2.new(1, 0, 1, 0)
	staffListContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	staffListContainer.BorderSizePixel = 0
	staffListContainer.ScrollBarThickness = 6
	staffListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	staffListContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	staffListContainer.ZIndex = 12
	staffListContainer.Parent = manageContent
	
	local staffCorner = Instance.new("UICorner")
	staffCorner.CornerRadius = UDim.new(0, 8)
	staffCorner.Parent = staffListContainer
	
	local staffListLayout = Instance.new("UIListLayout")
	staffListLayout.Padding = UDim.new(0, 10)
	staffListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	staffListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	staffListLayout.Parent = staffListContainer
	
	local staffListPadding = Instance.new("UIPadding")
	staffListPadding.PaddingTop = UDim.new(0, 10)
	staffListPadding.PaddingBottom = UDim.new(0, 10)
	staffListPadding.PaddingLeft = UDim.new(0, 10)
	staffListPadding.PaddingRight = UDim.new(0, 10)
	staffListPadding.Parent = staffListContainer
	
	-- Status text at bottom
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, -40, 0, 20)
	statusText.Position = UDim2.new(0, 20, 1, -30)
	statusText.BackgroundTransparency = 1
	statusText.Font = Enum.Font.Gotham
	statusText.TextColor3 = CONFIG.textColor
	statusText.TextSize = 14
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Text = "Hire staff to boost your gym's performance!"
	statusText.ZIndex = 11
	statusText.Parent = menu
	
	-- Store UI elements for future reference
	uiElements = {
		screenGui = screenGui,
		button = button,
		menu = menu,
		header = header,
		closeButton = closeButton,
		hireTab = hireTab,
		manageTab = manageTab,
		hireContent = hireContent,
		manageContent = manageContent,
		jobListContainer = jobListContainer,
		jobListLayout = jobListLayout,
		npcListContainer = npcListContainer,
		npcListLayout = npcListLayout,
		hireButton = hireButton,
		staffListContainer = staffListContainer,
		staffListLayout = staffListLayout,
		statusText = statusText
	}
end

-- Register handlers for UI interactions
function JobsUI:RegisterHandlers()
	local button = uiElements.button
	local menu = uiElements.menu
	local closeButton = uiElements.closeButton
	local hireTab = uiElements.hireTab
	local manageTab = uiElements.manageTab
	local hireButton = uiElements.hireButton
	
	-- Button hover effects
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
	
	-- Toggle menu visibility on button click
	button.MouseButton1Click:Connect(function()
		self:Toggle()
	end)
	
	-- Close menu on close button click
	closeButton.MouseButton1Click:Connect(function()
		self:Toggle(false)
	end)
	
	-- Tab switching
	hireTab.MouseButton1Click:Connect(function()
		self:SwitchTab("hire")
	end)
	
	manageTab.MouseButton1Click:Connect(function()
		self:SwitchTab("manage")
	end)
	
	-- Hire button click
	hireButton.MouseButton1Click:Connect(function()
		if selectedJob and selectedNPC then
			if callbacks.onHireStaff then
				callbacks.onHireStaff(selectedJob, selectedNPC)
			end
		end
	end)
end

-- Switch between tabs
function JobsUI:SwitchTab(tabName)
	local hireTab = uiElements.hireTab
	local manageTab = uiElements.manageTab
	local hireContent = uiElements.hireContent
	local manageContent = uiElements.manageContent
	
	currentTab = tabName
	
	if tabName == "hire" then
		-- Update tab appearance
		hireTab.BackgroundColor3 = CONFIG.accentColor
		manageTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		
		-- Show/hide content
		hireContent.Visible = true
		manageContent.Visible = false
		
		-- Update status text
		self:SetStatus("Hire staff to boost your gym's performance!")
	else -- manage
		-- Update tab appearance
		hireTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		manageTab.BackgroundColor3 = CONFIG.accentColor
		
		-- Show/hide content
		hireContent.Visible = false
		manageContent.Visible = true
		
		-- Update status text
		self:SetStatus("Manage your current staff members")
	end
	
	-- Call tab change callback if exists
	if callbacks.onTabChanged then
		callbacks.onTabChanged(tabName)
	end
end

-- Toggle the menu visibility
function JobsUI:Toggle(state)
	local menu = uiElements.menu
	
	if state ~= nil then
		menu.Visible = state
	else
		menu.Visible = not menu.Visible
	end
	
	if menu.Visible then
		-- Reset selections
		selectedJob = nil
		selectedNPC = nil
		uiElements.hireButton.Enabled = false
		uiElements.hireButton.BackgroundColor3 = CONFIG.unavailableColor
		
		-- Switch to default tab
		self:SwitchTab("hire")
		
		-- Call open callback if exists
		if callbacks.onOpen then
			callbacks.onOpen()
		end
	end
	
	return menu.Visible
end

-- Set status message
function JobsUI:SetStatus(message, color)
	local statusText = uiElements.statusText
	
	statusText.Text = message or "Hire staff to boost your gym's performance!"
	statusText.TextColor3 = color or CONFIG.textColor
end

-- Create a job card
function JobsUI:CreateJobCard(jobData)
	local jobListContainer = uiElements.jobListContainer
	
	-- Create card frame
	local card = Instance.new("Frame")
	card.Name = jobData.id .. "JobCard"
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.ZIndex = 13
	
	-- Add selection behavior
	local selectable = Instance.new("TextButton")
	selectable.Name = "Selectable"
	selectable.Size = UDim2.new(1, 0, 1, 0)
	selectable.BackgroundTransparency = 1
	selectable.Text = ""
	selectable.ZIndex = 14
	selectable.Parent = card
	
	selectable.MouseButton1Click:Connect(function()
		self:SelectJob(jobData.id)
	end)
	
	-- Card corner
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Color indicator
	local colorIndicator = Instance.new("Frame")
	colorIndicator.Name = "ColorIndicator"
	colorIndicator.Size = UDim2.new(0, 8, 1, -20)
	colorIndicator.Position = UDim2.new(0, 10, 0, 10)
	colorIndicator.BackgroundColor3 = CONFIG.jobColors[jobData.id] or Color3.fromRGB(200, 200, 200)
	colorIndicator.ZIndex = 14
	colorIndicator.Parent = card
	
	-- Indicator corner
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 4)
	indicatorCorner.Parent = colorIndicator
	
	-- Job title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -38, 0, 25)
	title.Position = UDim2.new(0, 28, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = jobData.available and CONFIG.textColor or CONFIG.unavailableColor
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = jobData.name
	title.ZIndex = 14
	title.Parent = card
	
	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -38, 0, 20)
	description.Position = UDim2.new(0, 28, 0, 35)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = jobData.available and CONFIG.textColor or CONFIG.unavailableColor
	description.TextSize = 14
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.Text = jobData.description
	description.ZIndex = 14
	description.Parent = card
	
	-- Benefits
	local benefits = Instance.new("TextLabel")
	benefits.Name = "Benefits"
	benefits.Size = UDim2.new(1, -38, 0, 20)
	benefits.Position = UDim2.new(0, 28, 0, 55)
	benefits.BackgroundTransparency = 1
	benefits.Font = Enum.Font.GothamMedium
	benefits.TextColor3 = jobData.available and Color3.fromRGB(100, 200, 255) or CONFIG.unavailableColor
	benefits.TextSize = 14
	benefits.TextXAlignment = Enum.TextXAlignment.Left
	benefits.TextYAlignment = Enum.TextYAlignment.Top
	benefits.TextWrapped = true
	benefits.Text = jobData.benefits
	benefits.ZIndex = 14
	benefits.Parent = card
	
	-- Salary
	local salary = Instance.new("TextLabel")
	salary.Name = "Salary"
	salary.Size = UDim2.new(0, 100, 0, 20)
	salary.Position = UDim2.new(0, 28, 0, 85)
	salary.BackgroundTransparency = 1
	salary.Font = Enum.Font.GothamBold
	salary.TextColor3 = jobData.available and CONFIG.textColor or CONFIG.unavailableColor
	salary.TextSize = 14
	salary.TextXAlignment = Enum.TextXAlignment.Left
	salary.Text = formatCurrency(jobData.salary) .. "/hr"
	salary.ZIndex = 14
	salary.Parent = card
	
	-- Availability count
	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.new(0.5, 0, 0, 20)
	count.Position = UDim2.new(0.5, 0, 0, 85)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.Gotham
	count.TextColor3 = jobData.available and CONFIG.textColor or CONFIG.unavailableColor
	count.TextSize = 14
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.Text = jobData.currentCount .. "/" .. jobData.maxCount
	count.ZIndex = 14
	count.Parent = card
	
	-- Unavailable reason
	if not jobData.available and jobData.reason then
		local reasonLabel = Instance.new("TextLabel")
		reasonLabel.Name = "ReasonLabel"
		reasonLabel.Size = UDim2.new(1, -20, 0, 20)
		reasonLabel.Position = UDim2.new(0, 10, 1, -25)
		reasonLabel.BackgroundTransparency = 1
		reasonLabel.Font = Enum.Font.GothamMedium
		reasonLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		reasonLabel.TextSize = 12
		reasonLabel.TextXAlignment = Enum.TextXAlignment.Center
		reasonLabel.Text = jobData.reason
		reasonLabel.ZIndex = 14
		reasonLabel.Parent = card
	end
	
	-- Add card to container
	card.Parent = jobListContainer
	
	return card
end

-- Create an NPC card
function JobsUI:CreateNPCCard(npcData)
	local npcListContainer = uiElements.npcListContainer
	
	-- Create card frame
	local card = Instance.new("Frame")
	card.Name = npcData.id .. "NPCCard"
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.ZIndex = 13
	
	-- Add selection behavior
	local selectable = Instance.new("TextButton")
	selectable.Name = "Selectable"
	selectable.Size = UDim2.new(1, 0, 1, 0)
	selectable.BackgroundTransparency = 1
	selectable.Text = ""
	selectable.ZIndex = 14
	selectable.Parent = card
	
	selectable.MouseButton1Click:Connect(function()
		self:SelectNPC(npcData.id)
	end)
	
	-- Card corner
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- NPC icon
	local npcIcon = Instance.new("ImageLabel")
	npcIcon.Name = "NPCIcon"
	npcIcon.Size = UDim2.new(0, 40, 0, 40)
	npcIcon.Position = UDim2.new(0, 20, 0.5, -20)
	npcIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	npcIcon.Image = "rbxassetid://6034275503" -- Person icon
	npcIcon.ZIndex = 14
	npcIcon.Parent = card
	
	-- Icon corner
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0) -- Circular
	iconCorner.Parent = npcIcon
	
	-- NPC name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, -80, 0, 25)
	name.Position = UDim2.new(0, 70, 0, 15)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = CONFIG.textColor
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = npcData.name
	name.ZIndex = 14
	name.Parent = card
	
	-- NPC type
	local npcType = Instance.new("TextLabel")
	npcType.Name = "Type"
	npcType.Size = UDim2.new(1, -80, 0, 20)
	npcType.Position = UDim2.new(0, 70, 0, 40)
	npcType.BackgroundTransparency = 1
	npcType.Font = Enum.Font.Gotham
	npcType.TextColor3 = CONFIG.textColor
	npcType.TextSize = 14
	npcType.TextXAlignment = Enum.TextXAlignment.Left
	npcType.Text = npcData.type
	npcType.ZIndex = 14
	npcType.Parent = card
	
	-- Add card to container
	card.Parent = npcListContainer
	
	return card
end

-- Create a staff card for the manage tab
function JobsUI:CreateStaffCard(staffData)
	local staffListContainer = uiElements.staffListContainer
	
	-- Create card frame
	local card = Instance.new("Frame")
	card.Name = staffData.npcId .. "StaffCard"
	card.Size = UDim2.new(1, 0, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.ZIndex = 13
	
	-- Card corner
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Color indicator based on job type
	local colorIndicator = Instance.new("Frame")
	colorIndicator.Name = "ColorIndicator"
	colorIndicator.Size = UDim2.new(0, 8, 1, -20)
	colorIndicator.Position = UDim2.new(0, 10, 0, 10)
	colorIndicator.BackgroundColor3 = CONFIG.jobColors[staffData.jobId] or Color3.fromRGB(200, 200, 200)
	colorIndicator.ZIndex = 14
	colorIndicator.Parent = card
	
	-- Indicator corner
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 4)
	indicatorCorner.Parent = colorIndicator
	
	-- NPC icon
	local npcIcon = Instance.new("ImageLabel")
	npcIcon.Name = "NPCIcon"
	npcIcon.Size = UDim2.new(0, 40, 0, 40)
	npcIcon.Position = UDim2.new(0, 30, 0, 10)
	npcIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	npcIcon.Image = "rbxassetid://6034275503" -- Person icon
	npcIcon.ZIndex = 14
	npcIcon.Parent = card
	
	-- Icon corner
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0) -- Circular
	iconCorner.Parent = npcIcon
	
	-- Staff name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(0, 150, 0, 25)
	name.Position = UDim2.new(0, 80, 0, 10)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = CONFIG.textColor
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = staffData.name
	name.ZIndex = 14
	name.Parent = card
	
	-- Job title
	local jobTitle = Instance.new("TextLabel")
	jobTitle.Name = "JobTitle"
	jobTitle.Size = UDim2.new(0, 150, 0, 20)
	jobTitle.Position = UDim2.new(0, 80, 0, 35)
	jobTitle.BackgroundTransparency = 1
	jobTitle.Font = Enum.Font.Gotham
	jobTitle.TextColor3 = CONFIG.textColor
	jobTitle.TextSize = 14
	jobTitle.TextXAlignment = Enum.TextXAlignment.Left
	jobTitle.Text = staffData.jobName
	jobTitle.ZIndex = 14
	jobTitle.Parent = card
	
	-- Salary
	local salary = Instance.new("TextLabel")
	salary.Name = "Salary"
	salary.Size = UDim2.new(0, 100, 0, 20)
	salary.Position = UDim2.new(0, 80, 0, 60)
	salary.BackgroundTransparency = 1
	salary.Font = Enum.Font.Gotham
	salary.TextColor3 = CONFIG.textColor
	salary.TextSize = 14
	salary.TextXAlignment = Enum.TextXAlignment.Left
	salary.Text = "Salary: " .. formatCurrency(staffData.salary) .. "/hr"
	salary.ZIndex = 14
	salary.Parent = card
	
	-- Fire button
	local fireButton = Instance.new("TextButton")
	fireButton.Name = "FireButton"
	fireButton.Size = UDim2.new(0, 100, 0, 35)
	fireButton.Position = UDim2.new(1, -120, 0.5, -17.5)
	fireButton.BackgroundColor3 = CONFIG.deleteColor
	fireButton.Text = "Fire"
	fireButton.TextColor3 = CONFIG.textColor
	fireButton.Font = Enum.Font.GothamBold
	fireButton.TextSize = 16
	fireButton.ZIndex = 14
	fireButton.Parent = card
	
	-- Fire button corner
	local fireCorner = Instance.new("UICorner")
	fireCorner.CornerRadius = UDim.new(0, 8)
	fireCorner.Parent = fireButton
	
	-- Fire button handler
	fireButton.MouseButton1Click:Connect(function()
		if callbacks.onFireStaff then
			callbacks.onFireStaff(staffData.npcId)
		end
	end)
	
	-- Add card to container
	card.Parent = staffListContainer
	
	return card
end

-- Select a job
function JobsUI:SelectJob(jobId)
	selectedJob = jobId
	
	-- Update job card visuals
	local jobListContainer = uiElements.jobListContainer
	for _, child in pairs(jobListContainer:GetChildren()) do
		if child:IsA("Frame") then
			if child.Name == jobId .. "JobCard" then
				child.BackgroundColor3 = CONFIG.accentColor
			else
				child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			end
		end
	end
	
	-- Enable hire button if both selections made
	self:UpdateHireButton()
end

-- Select an NPC
function JobsUI:SelectNPC(npcId)
	selectedNPC = npcId
	
	-- Update NPC card visuals
	local npcListContainer = uiElements.npcListContainer
	for _, child in pairs(npcListContainer:GetChildren()) do
		if child:IsA("Frame") then
			if child.Name == npcId .. "NPCCard" then
				child.BackgroundColor3 = CONFIG.accentColor
			else
				child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			end
		end
	end
	
	-- Enable hire button if both selections made
	self:UpdateHireButton()
end

-- Update hire button state
function JobsUI:UpdateHireButton()
	local hireButton = uiElements.hireButton
	
	if selectedJob and selectedNPC then
		hireButton.Enabled = true
		hireButton.BackgroundColor3 = CONFIG.availableColor
	else
		hireButton.Enabled = false
		hireButton.BackgroundColor3 = CONFIG.unavailableColor
	end
end

-- Update the jobs display
function JobsUI:UpdateJobs(jobsData)
	local jobListContainer = uiElements.jobListContainer
	local jobListLayout = uiElements.jobListLayout
	
	-- Clear existing cards
	for _, child in pairs(jobListContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Ensure layout is in place
	if not jobListContainer:FindFirstChild("UIListLayout") then
		local newLayout = jobListLayout:Clone()
		newLayout.Parent = jobListContainer
	end
	
	-- Create cards for each job
	for i, jobData in ipairs(jobsData) do
		local card = self:CreateJobCard(jobData)
		card.LayoutOrder = i
		
		-- If this was previously selected, highlight it
		if selectedJob == jobData.id then
			card.BackgroundColor3 = CONFIG.accentColor
		end
	end
	
	-- Update canvas size
	local totalHeight = 0
	for _, child in pairs(jobListContainer:GetChildren()) do
		if child:IsA("Frame") then
			totalHeight = totalHeight + child.Size.Y.Offset + jobListLayout.Padding.Offset
		end
	end
	
	jobListContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Update the NPCs display
function JobsUI:UpdateNPCs(npcsData)
	local npcListContainer = uiElements.npcListContainer
	local npcListLayout = uiElements.npcListLayout
	
	-- Clear existing cards
	for _, child in pairs(npcListContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Ensure layout is in place
	if not npcListContainer:FindFirstChild("UIListLayout") then
		local newLayout = npcListLayout:Clone()
		newLayout.Parent = npcListContainer
	end
	
	-- Create cards for each NPC
	for i, npcData in ipairs(npcsData) do
		local card = self:CreateNPCCard(npcData)
		card.LayoutOrder = i
		
		-- If this was previously selected, highlight it
		if selectedNPC == npcData.id then
			card.BackgroundColor3 = CONFIG.accentColor
		end
	end
	
	-- Update canvas size
	local totalHeight = 0
	for _, child in pairs(npcListContainer:GetChildren()) do
		if child:IsA("Frame") then
			totalHeight = totalHeight + child.Size.Y.Offset + npcListLayout.Padding.Offset
		end
	end
	
	npcListContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	
	-- Update hire button state
	self:UpdateHireButton()
end

-- Update the staff display
function JobsUI:UpdateStaff(staffData)
	local staffListContainer = uiElements.staffListContainer
	local staffListLayout = uiElements.staffListLayout
	
	-- Clear existing cards
	for _, child in pairs(staffListContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Ensure layout is in place
	if not staffListContainer:FindFirstChild("UIListLayout") then
		local newLayout = staffListLayout:Clone()
		newLayout.Parent = staffListContainer
	end
	
	-- Create cards for each staff member
	for i, staff in ipairs(staffData) do
		local card = self:CreateStaffCard(staff)
		card.LayoutOrder = i
	end
	
	-- Update canvas size
	local totalHeight = 0
	for _, child in pairs(staffListContainer:GetChildren()) do
		if child:IsA("Frame") then
			totalHeight = totalHeight + child.Size.Y.Offset + staffListLayout.Padding.Offset
		end
	end
	
	staffListContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	
	-- Update tab status text
	if #staffData == 0 then
		self:SetStatus("You don't have any staff members yet")
	else
		local totalSalary = 0
		for _, staff in ipairs(staffData) do
			totalSalary = totalSalary + staff.salary
		end
		
		self:SetStatus("Total staff: " .. #staffData .. " - Total hourly cost: " .. formatCurrency(totalSalary))
	end
end

-- Update all job UI data at once
function JobsUI:UpdateData(data)
	if data.jobs then
		self:UpdateJobs(data.jobs)
	end
	
	if data.npcs then
		self:UpdateNPCs(data.npcs)
	end
	
	if data.staff then
		self:UpdateStaff(data.staff)
	end
end

-- Set callbacks for UI interaction
function JobsUI:SetCallbacks(callbackTable)
	callbacks = callbackTable or {}
end

-- Public methods
function JobsUI:IsVisible()
	return uiElements.menu and uiElements.menu.Visible or false
end

function JobsUI:GetCurrentTab()
	return currentTab
end

function JobsUI:Destroy()
	if uiElements.screenGui then
		uiElements.screenGui:Destroy()
	end
	
	uiElements = {}
	callbacks = {}
	selectedJob = nil
	selectedNPC = nil
	isInitialized = false
end

-- For UI module pattern
function JobsUI:GetUI()
	return uiElements.screenGui
end

return JobsUI