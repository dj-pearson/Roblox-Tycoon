-- CompetitionUI.luau
-- UI Module for competition management
-- Updated as part of UI refinements (April 2025)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- Configuration
local CONFIG = {
	-- UI Placement
	menuSize = UDim2.new(0, 500, 0, 450),
	menuPosition = UDim2.new(0.5, 0, 0.5, 0),

	-- Animation
	tweenDuration = 0.3
}

-- Module table
local CompetitionUI = {}

-- Private variables
local uiElements = {}
local callbacks = {}
local isInitialized = false

-- Format functions
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatDuration(seconds)
	local minutes = math.floor(seconds / 60)
	if minutes == 1 then
		return "1 minute"
	else
		return minutes .. " minutes"
	end
end

-- Initialize the UI module
function CompetitionUI:Initialize(UIManager)
	if isInitialized then return end
	
	-- Store reference to UIManager for use in callbacks
	self.UIManager = UIManager
	
	isInitialized = true
	return true
end

-- Create the competition UI components
function CompetitionUI:CreateUI()
	-- Create main frame
	local menu = UIStyle.createShadowFrame({
		name = "CompetitionMenu",
		size = CONFIG.menuSize,
		position = CONFIG.menuPosition,
		anchorPoint = Vector2.new(0.5, 0.5),
		color = UIStyle.colors.background,
		cornerRadius = UIStyle.cornerRadius.large
	})
	
	-- Create header
	local header = UIStyle.createHeader({
		name = "Header",
		text = "Gym Competitions",
		color = UIStyle.colors.headerBackground,
		fixBottomCorners = true,
		parent = menu
	})
	
	-- Competition container
	local container = Instance.new("ScrollingFrame")
	container.Name = "CompetitionContainer"
	container.Size = UDim2.new(1, -40, 1, -70)
	container.Position = UDim2.new(0, 20, 0, 60)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 6
	container.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
	container.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	container.ZIndex = UIStyle.zIndex.content
	container.Parent = menu

	-- Competition list layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 15)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	-- Status text at bottom
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, -40, 0, 20)
	statusText.Position = UDim2.new(0, 20, 1, -30)
	statusText.BackgroundTransparency = 1
	statusText.Font = UIStyle.fonts.body
	statusText.TextColor3 = UIStyle.colors.textPrimary
	statusText.TextSize = UIStyle.textSizes.body
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Text = "Select a competition to boost your gym's memberships!"
	statusText.ZIndex = UIStyle.zIndex.content
	statusText.Parent = menu

	-- Connect close button
	header.CloseButton.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Store UI elements for future reference
	uiElements = {
		menu = menu,
		container = container,
		statusText = statusText,
		closeButton = header.CloseButton,
		layout = layout
	}
	
	return menu
end

-- Open the UI
function CompetitionUI:Open(data)
	if not uiElements.menu then
		self:CreateUI()
	end
	
	if callbacks.onOpen then
		callbacks.onOpen()
	end
	
	return uiElements.menu
end

-- Close the UI
function CompetitionUI:Close()
	if self.UIManager then
		self.UIManager.closeUI("CompetitionUI")
	end
end

-- Set status message
function CompetitionUI:SetStatus(message, color)
	local statusText = uiElements.statusText
	if not statusText then return end
	
	statusText.Text = message or "Select a competition to boost your gym's memberships!"
	statusText.TextColor3 = color or UIStyle.colors.textPrimary
end

-- Reset status after delay
function CompetitionUI:ResetStatus(delay)
	delay = delay or 3
	
	task.delay(delay, function()
		self:SetStatus()
	end)
end

-- Create a competition card
function CompetitionUI:CreateCompetitionCard(competition)
	local container = uiElements.container
	if not container then return end
	
	-- Create card frame with shadow
	local card = UIStyle.createShadowFrame({
		name = competition.id .. "Card",
		size = UDim2.new(1, 0, 0, 120),
		position = UDim2.new(0, 0, 0, 0),
		color = UIStyle.colors.cardBackground,
		cornerRadius = UIStyle.cornerRadius.medium
	})
	
	card.ZIndex = UIStyle.zIndex.content
	
	-- Competition title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = UIStyle.fonts.subheader
	title.TextColor3 = competition.available and UIStyle.colors.textPrimary or UIStyle.colors.textDisabled
	title.TextSize = UIStyle.textSizes.subheader
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = competition.name
	title.ZIndex = UIStyle.zIndex.content + 1
	title.Parent = card

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -20, 0, 35)
	description.Position = UDim2.new(0, 10, 0, 35)
	description.BackgroundTransparency = 1
	description.Font = UIStyle.fonts.body
	description.TextColor3 = competition.available and UIStyle.colors.textSecondary or UIStyle.colors.textDisabled
	description.TextSize = UIStyle.textSizes.body
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.Text = competition.description
	description.ZIndex = UIStyle.zIndex.content + 1
	description.Parent = card

	-- Details container
	local detailsContainer = Instance.new("Frame")
	detailsContainer.Name = "Details"
	detailsContainer.Size = UDim2.new(1, -140, 0, 30)
	detailsContainer.Position = UDim2.new(0, 10, 0, 80)
	detailsContainer.BackgroundTransparency = 1
	detailsContainer.ZIndex = UIStyle.zIndex.content + 1
	detailsContainer.Parent = card

	-- Duration icon
	local durationIcon = Instance.new("ImageLabel")
	durationIcon.Name = "DurationIcon"
	durationIcon.Size = UDim2.new(0, 16, 0, 16)
	durationIcon.Position = UDim2.new(0, 0, 0, 0)
	durationIcon.BackgroundTransparency = 1
	durationIcon.Image = UIStyle.icons.refresh -- Clock icon
	durationIcon.ImageColor3 = competition.available and UIStyle.colors.textSecondary or UIStyle.colors.textDisabled
	durationIcon.ZIndex = UIStyle.zIndex.content + 1
	durationIcon.Parent = detailsContainer

	-- Duration text
	local durationText = Instance.new("TextLabel")
	durationText.Name = "DurationText"
	durationText.Size = UDim2.new(0, 100, 0, 16)
	durationText.Position = UDim2.new(0, 22, 0, 0)
	durationText.BackgroundTransparency = 1
	durationText.Font = UIStyle.fonts.body
	durationText.TextColor3 = competition.available and UIStyle.colors.textSecondary or UIStyle.colors.textDisabled
	durationText.TextSize = UIStyle.textSizes.body
	durationText.TextXAlignment = Enum.TextXAlignment.Left
	durationText.Text = formatDuration(competition.duration)
	durationText.ZIndex = UIStyle.zIndex.content + 1
	durationText.Parent = detailsContainer

	-- Cost icon
	local costIcon = Instance.new("ImageLabel")
	costIcon.Name = "CostIcon"
	costIcon.Size = UDim2.new(0, 16, 0, 16)
	costIcon.Position = UDim2.new(0, 0, 0, 20)
	costIcon.BackgroundTransparency = 1
	costIcon.Image = "rbxassetid://6034684949" -- Money icon
	costIcon.ImageColor3 = competition.available and UIStyle.colors.textSecondary or UIStyle.colors.textDisabled
	costIcon.ZIndex = UIStyle.zIndex.content + 1
	costIcon.Parent = detailsContainer

	-- Cost text
	local costText = Instance.new("TextLabel")
	costText.Name = "CostText"
	costText.Size = UDim2.new(0, 100, 0, 16)
	costText.Position = UDim2.new(0, 22, 0, 20)
	costText.BackgroundTransparency = 1
	costText.Font = UIStyle.fonts.body
	costText.TextColor3 = competition.available and UIStyle.colors.textSecondary or UIStyle.colors.textDisabled
	costText.TextSize = UIStyle.textSizes.body
	costText.TextXAlignment = Enum.TextXAlignment.Left
	costText.Text = "$" .. competition.cost
	costText.ZIndex = UIStyle.zIndex.content + 1
	costText.Parent = detailsContainer

	-- Start button or status
	if competition.available then
		local startButton = UIStyle.createButton({
			name = "StartButton",
			size = UDim2.new(0, 100, 0, 30),
			position = UDim2.new(1, -110, 0, 80),
			text = "Start",
			color = UIStyle.colors.success,
			parent = card
		})
		
		startButton.ZIndex = UIStyle.zIndex.content + 1
		
		-- Handle start button click
		startButton.MouseButton1Click:Connect(function()
			if callbacks.onStartCompetition then
				callbacks.onStartCompetition(competition.id)
			end
		end)
	else
		-- Show reason why it's unavailable
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(0, 100, 0, 30)
		statusLabel.Position = UDim2.new(1, -110, 0, 80)
		statusLabel.BackgroundColor3 = UIStyle.colors.buttonDisabled
		statusLabel.TextColor3 = UIStyle.colors.textDisabled
		statusLabel.Font = UIStyle.fonts.subheader
		statusLabel.TextSize = UIStyle.textSizes.small
		statusLabel.Text = "Unavailable"
		statusLabel.ZIndex = UIStyle.zIndex.content + 1
		statusLabel.Parent = card
		
		-- Add rounded corners
		local statusCorner = Instance.new("UICorner")
		statusCorner.CornerRadius = UIStyle.cornerRadius.small
		statusCorner.Parent = statusLabel

		-- Show reason on hover
		if competition.reason then
			local reasonTip = UIStyle.createShadowFrame({
				name = "ReasonTip",
				size = UDim2.new(0, 200, 0, 40),
				position = UDim2.new(0.5, 0, 0, -45),
				anchorPoint = Vector2.new(0.5, 0),
				color = UIStyle.colors.cardBackground,
				cornerRadius = UIStyle.cornerRadius.small
			})
			
			reasonTip.Visible = false
			reasonTip.ZIndex = UIStyle.zIndex.tooltip
			
			-- Tooltip text
			local tipText = Instance.new("TextLabel")
			tipText.Name = "TipText"
			tipText.Size = UDim2.new(1, -16, 1, -8)
			tipText.Position = UDim2.new(0, 8, 0, 4)
			tipText.BackgroundTransparency = 1
			tipText.Font = UIStyle.fonts.body
			tipText.TextColor3 = UIStyle.colors.textPrimary
			tipText.TextSize = UIStyle.textSizes.small
			tipText.TextWrapped = true
			tipText.Text = competition.reason
			tipText.ZIndex = UIStyle.zIndex.tooltip + 1
			tipText.Parent = reasonTip
			
			reasonTip.Parent = statusLabel

			-- Show on hover
			statusLabel.MouseEnter:Connect(function()
				reasonTip.Visible = true
			end)

			statusLabel.MouseLeave:Connect(function()
				reasonTip.Visible = false
			end)

			-- If there's a time remaining, show it
			if competition.timeRemaining then
				tipText.Text = competition.reason .. "\nAvailable in: " .. formatTime(competition.timeRemaining)
			end
		end
	end

	-- Add card to container
	card.Parent = container

	return card
end

-- Update the UI with competition data
function CompetitionUI:UpdateCompetitions(competitions)
	local container = uiElements.container
	if not container then return end
	
	local layout = uiElements.layout
	
	-- Clear existing cards
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Ensure layout is in place
	if not container:FindFirstChild("UIListLayout") then
		local newLayout = layout:Clone()
		newLayout.Parent = container
	end
	
	-- Create cards for each competition
	for i, competition in ipairs(competitions) do
		local card = self:CreateCompetitionCard(competition)
		card.LayoutOrder = i
	end
	
	-- Update canvas size
	local totalHeight = 0
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			totalHeight = totalHeight + child.Size.Y.Offset + layout.Padding.Offset
		end
	end
	
	container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Set callbacks for UI interaction
function CompetitionUI:SetCallbacks(callbackTable)
	callbacks = callbackTable or {}
end

-- For module API pattern compatibility
function CompetitionUI.create(data)
	if not isInitialized then
		CompetitionUI:Initialize()
	end
	
	local menu = CompetitionUI:CreateUI()
	
	-- Update if data is provided
	if data and data.competitions then
		CompetitionUI:UpdateCompetitions(data.competitions)
	end
	
	return menu
end

function CompetitionUI.open(ui, data)
	-- Update if data is provided
	if data and data.competitions then
		CompetitionUI:UpdateCompetitions(data.competitions)
	end
	
	return ui
end

function CompetitionUI.close(ui)
	if ui and ui.Parent then
		ui:Destroy()
	end
	
	uiElements = {}
end

return CompetitionUI