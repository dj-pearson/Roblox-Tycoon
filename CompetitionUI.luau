-- CompetitionUI.lua
-- LocalScript for the competition management UI
-- Place in StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local updateInterval = 5 -- Update competition list every 5 seconds

-- Configuration
local CONFIG = {
	-- UI Placement
	buttonPosition = UDim2.new(0, 20, 0.7, 0),
	buttonSize = UDim2.new(0, 150, 0, 40),

	menuSize = UDim2.new(0, 400, 0, 450),
	menuPosition = UDim2.new(0.5, -200, 0.5, -225),

	-- Colors
	buttonColor = Color3.fromRGB(220, 50, 50),
	buttonHoverColor = Color3.fromRGB(240, 70, 70),
	menuBackgroundColor = Color3.fromRGB(30, 30, 30),
	menuHeaderColor = Color3.fromRGB(20, 20, 20),
	textColor = Color3.fromRGB(255, 255, 255),
	accentColor = Color3.fromRGB(220, 50, 50),
	availableColor = Color3.fromRGB(50, 200, 50),
	unavailableColor = Color3.fromRGB(150, 150, 150),

	-- Animation
	tweenDuration = 0.3
}

-- Format time from seconds to MM:SS
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- Format duration from seconds to minutes
local function formatDuration(seconds)
	local minutes = math.floor(seconds / 60)
	if minutes == 1 then
		return "1 minute"
	else
		return minutes .. " minutes"
	end
end

-- Create the competition button
local function createCompetitionButton()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CompetitionGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui

	-- Create button
	local button = Instance.new("TextButton")
	button.Name = "CompetitionButton"
	button.Size = CONFIG.buttonSize
	button.Position = CONFIG.buttonPosition
	button.BackgroundColor3 = CONFIG.buttonColor
	button.Text = "Competitions"
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
	menu.Name = "CompetitionMenu"
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
	headerText.Text = "Gym Competitions"
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
	container.ZIndex = 11
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
	statusText.Font = Enum.Font.Gotham
	statusText.TextColor3 = CONFIG.textColor
	statusText.TextSize = 14
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Text = "Select a competition to boost your gym's memberships!"
	statusText.ZIndex = 11
	statusText.Parent = menu

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
		menu.Visible = not menu.Visible

		if menu.Visible then
			-- Refresh data when opening
			updateCompetitionList(container, statusText)
		end
	end)

	-- Close menu on close button click
	closeButton.MouseButton1Click:Connect(function()
		menu.Visible = false
	end)

	return {
		button = button,
		menu = menu,
		container = container,
		statusText = statusText
	}
end

-- Create a competition card
local function createCompetitionCard(container, competition)
	-- Create card frame
	local card = Instance.new("Frame")
	card.Name = competition.id .. "Card"
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	card.BorderSizePixel = 0
	card.ZIndex = 12

	-- Card corner
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Competition title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = competition.name
	title.ZIndex = 13
	title.Parent = card

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -20, 0, 35)
	description.Position = UDim2.new(0, 10, 0, 35)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	description.TextSize = 14
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.Text = competition.description
	description.ZIndex = 13
	description.Parent = card

	-- Details container
	local detailsContainer = Instance.new("Frame")
	detailsContainer.Name = "Details"
	detailsContainer.Size = UDim2.new(1, -140, 0, 30)
	detailsContainer.Position = UDim2.new(0, 10, 0, 80)
	detailsContainer.BackgroundTransparency = 1
	detailsContainer.ZIndex = 13
	detailsContainer.Parent = card

	-- Duration icon
	local durationIcon = Instance.new("ImageLabel")
	durationIcon.Name = "DurationIcon"
	durationIcon.Size = UDim2.new(0, 16, 0, 16)
	durationIcon.Position = UDim2.new(0, 0, 0, 0)
	durationIcon.BackgroundTransparency = 1
	durationIcon.Image = "rbxassetid://6031280882" -- Clock icon
	durationIcon.ImageColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	durationIcon.ZIndex = 13
	durationIcon.Parent = detailsContainer

	-- Duration text
	local durationText = Instance.new("TextLabel")
	durationText.Name = "DurationText"
	durationText.Size = UDim2.new(0, 100, 0, 16)
	durationText.Position = UDim2.new(0, 22, 0, 0)
	durationText.BackgroundTransparency = 1
	durationText.Font = Enum.Font.Gotham
	durationText.TextColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	durationText.TextSize = 14
	durationText.TextXAlignment = Enum.TextXAlignment.Left
	durationText.Text = formatDuration(competition.duration)
	durationText.ZIndex = 13
	durationText.Parent = detailsContainer

	-- Cost icon
	local costIcon = Instance.new("ImageLabel")
	costIcon.Name = "CostIcon"
	costIcon.Size = UDim2.new(0, 16, 0, 16)
	costIcon.Position = UDim2.new(0, 0, 0, 20)
	costIcon.BackgroundTransparency = 1
	costIcon.Image = "rbxassetid://6034684949" -- Money icon
	costIcon.ImageColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	costIcon.ZIndex = 13
	costIcon.Parent = detailsContainer

	-- Cost text
	local costText = Instance.new("TextLabel")
	costText.Name = "CostText"
	costText.Size = UDim2.new(0, 100, 0, 16)
	costText.Position = UDim2.new(0, 22, 0, 20)
	costText.BackgroundTransparency = 1
	costText.Font = Enum.Font.Gotham
	costText.TextColor3 = competition.available and CONFIG.textColor or CONFIG.unavailableColor
	costText.TextSize = 14
	costText.TextXAlignment = Enum.TextXAlignment.Left
	costText.Text = "$" .. competition.cost
	costText.ZIndex = 13
	costText.Parent = detailsContainer

	-- Start button or status
	if competition.available then
		local startButton = Instance.new("TextButton")
		startButton.Name = "StartButton"
		startButton.Size = UDim2.new(0, 100, 0, 30)
		startButton.Position = UDim2.new(1, -110, 0, 80)
		startButton.BackgroundColor3 = CONFIG.availableColor
		startButton.Text = "Start"
		startButton.TextColor3 = CONFIG.textColor
		startButton.Font = Enum.Font.GothamBold
		startButton.TextSize = 16
		startButton.ZIndex = 13
		startButton.Parent = card

		-- Start button corner
		local startCorner = Instance.new("UICorner")
		startCorner.CornerRadius = UDim.new(0, 6)
		startCorner.Parent = startButton

		-- Handle start button click
		startButton.MouseButton1Click:Connect(function()
			-- Check if player has enough money
			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats or not leaderstats:FindFirstChild("Cash") then
				return
			end

			if leaderstats.Cash.Value < competition.cost then
				-- Update status text
				local statusText = container.Parent:FindFirstChild("StatusText")
				if statusText then
					statusText.Text = "Not enough money to start this competition!"
					statusText.TextColor3 = Color3.fromRGB(255, 100, 100)

					-- Reset after 3 seconds
					delay(3, function()
						statusText.Text = "Select a competition to boost your gym's memberships!"
						statusText.TextColor3 = CONFIG.textColor
					end)
				end
				return
			end

			-- Start competition via remote function
			local startCompetitionFunction = ReplicatedStorage:FindFirstChild("StartCompetitionFunction")
			if startCompetitionFunction then
				local success, result = pcall(function()
					return startCompetitionFunction:InvokeServer(competition.id)
				end)

				if success and result then
					-- Update status text
					local statusText = container.Parent:FindFirstChild("StatusText")
					if statusText then
						statusText.Text = "Competition started successfully!"
						statusText.TextColor3 = Color3.fromRGB(100, 255, 100)

						-- Reset after 3 seconds
						delay(3, function()
							statusText.Text = "Your competition is now attracting new members!"
							statusText.TextColor3 = CONFIG.textColor
						end)
					end

					-- Close menu
					local menu = container.Parent.Parent
					if menu then
						-- Delay closing to show success message
						delay(1.5, function()
							menu.Visible = false
						end)
					end

					-- Play a sound effect
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6042583773" -- success sound
					sound.Volume = 0.5
					sound.Parent = player.PlayerGui
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 2)
				else
					-- Show error
					local statusText = container.Parent:FindFirstChild("StatusText")
					if statusText then
						statusText.Text = "Error: " .. tostring(result)
						statusText.TextColor3 = Color3.fromRGB(255, 100, 100)

						-- Reset after 3 seconds
						delay(3, function()
							statusText.Text = "Select a competition to boost your gym's memberships!"
							statusText.TextColor3 = CONFIG.textColor
						end)
					end
				end
			end
		end)
	else
		-- Show reason why it's unavailable
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(0, 100, 0, 30)
		statusLabel.Position = UDim2.new(1, -110, 0, 80)
		statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		statusLabel.TextColor3 = CONFIG.unavailableColor
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.TextSize = 13
		statusLabel.Text = "Unavailable"
		statusLabel.ZIndex = 13
		statusLabel.Parent = card

		-- Status corner
		local statusCorner = Instance.new("UICorner")
		statusCorner.CornerRadius = UDim.new(0, 6)
		statusCorner.Parent = statusLabel

		-- Show reason on hover
		if competition.reason then
			local reasonTip = Instance.new("TextLabel")
			reasonTip.Name = "ReasonTip"
			reasonTip.Size = UDim2.new(0, 200, 0, 40)
			reasonTip.Position = UDim2.new(0.5, -100, 0, -45)
			reasonTip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			reasonTip.TextColor3 = CONFIG.textColor
			reasonTip.Font = Enum.Font.Gotham
			reasonTip.TextSize = 12
			reasonTip.Text = competition.reason
			reasonTip.TextWrapped = true
			reasonTip.Visible = false
			reasonTip.ZIndex = 15
			reasonTip.Parent = statusLabel

			-- Tip corner
			local tipCorner = Instance.new("UICorner")
			tipCorner.CornerRadius = UDim.new(0, 6)
			tipCorner.Parent = reasonTip

			-- Show on hover
			statusLabel.MouseEnter:Connect(function()
				reasonTip.Visible = true
			end)

			statusLabel.MouseLeave:Connect(function()
				reasonTip.Visible = false
			end)

			-- If there's a time remaining, show it
			if competition.timeRemaining then
				reasonTip.Text = competition.reason .. "\nAvailable in: " .. formatTime(competition.timeRemaining)
			end
		end
	end

	-- Add card to container
	card.Parent = container

	return card
end

-- Update the competition list
local function updateCompetitionList(container, statusText)
	-- Clear existing cards
	container:ClearAllChildren()

	-- Add list layout back
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 15)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	-- Get competitions from server
	local getCompetitionsFunction = ReplicatedStorage:FindFirstChild("GetCompetitionsFunction")
	if not getCompetitionsFunction then
		statusText.Text = "Error: Competitions unavailable"
		statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	local success, competitions = pcall(function()
		return getCompetitionsFunction:InvokeServer()
	end)

	if not success or not competitions then
		statusText.Text = "Error loading competitions"
		statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	-- Sort competitions: available first, then by cost
	table.sort(competitions, function(a, b)
		if a.available ~= b.available then
			return a.available
		end
		return a.cost < b.cost
	end)

	-- Create cards for each competition
	for i, competition in ipairs(competitions) do
		local card = createCompetitionCard(container, competition)
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

	-- Reset status text
	statusText.Text = "Select a competition to boost your gym's memberships!"
	statusText.TextColor3 = CONFIG.textColor
end

-- Initialize
local guiElements = createCompetitionButton()

-- Update periodically when menu is open
spawn(function()
	while true do
		wait(updateInterval)

		if guiElements.menu.Visible then
			updateCompetitionList(guiElements.container, guiElements.statusText)
		end
	end
end)