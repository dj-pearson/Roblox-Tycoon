-- StatsPanel.lua
-- Place in StarterGui/StatsGui (create a ScreenGui named StatsGui first)
-- Creates a stats panel that shows all gym statistics in a clean table layout

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local statsGui = script.Parent

-- Configuration
local CONFIG = {
	buttonPosition = UDim2.new(0, 10, 0.5, 0),
	panelSize = UDim2.new(0, 350, 0, 400),
	updateInterval = 2,
	animationDuration = 0.3
}

-- Format numbers with commas
local function formatNumber(number)
	local formatted = tostring(number)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Create toggle button if it doesn't exist
local function createToggleButton()
	local button = statsGui:FindFirstChild("StatsButton")
	if not button then
		button = Instance.new("TextButton")
		button.Name = "StatsButton"
		button.Size = UDim2.new(0, 120, 0, 40)
		button.Position = CONFIG.buttonPosition
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.BackgroundColor3 = Color3.fromRGB(0, 100, 70)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 18
		button.Text = "GYM STATS"
		button.BorderSizePixel = 0
		button.ZIndex = 10
		button.Parent = statsGui

		-- Add corner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = button
	end

	return button
end

-- Create the stats panel
local function createStatsPanel()
	local panel = statsGui:FindFirstChild("StatsPanel")
	if not panel then
		panel = Instance.new("Frame")
		panel.Name = "StatsPanel"
		panel.Size = CONFIG.panelSize
		panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		panel.BackgroundTransparency = 0.1
		panel.BorderSizePixel = 0
		panel.Visible = false
		panel.ZIndex = 10
		panel.Parent = statsGui

		-- Add corner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = panel

		-- Add title
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 50)
		title.BackgroundColor3 = Color3.fromRGB(0, 80, 50)
		title.BackgroundTransparency = 0
		title.BorderSizePixel = 0
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 22
		title.Text = "Fitness Center Statistics"
		title.ZIndex = 11
		title.Parent = panel

		-- Add title corner
		local titleCorner = Instance.new("UICorner")
		titleCorner.CornerRadius = UDim.new(0, 10)
		titleCorner.Parent = title

		-- Add close button
		local closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.Size = UDim2.new(0, 30, 0, 30)
		closeButton.Position = UDim2.new(1, -10, 0, 10)
		closeButton.AnchorPoint = Vector2.new(1, 0)
		closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeButton.Font = Enum.Font.GothamBold
		closeButton.TextSize = 18
		closeButton.Text = "X"
		closeButton.ZIndex = 12
		closeButton.Parent = title

		-- Add close button corner
		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0.5, 0)
		closeCorner.Parent = closeButton

		-- Close button handler
		closeButton.MouseButton1Click:Connect(function()
			panel.Visible = false
		end)

		-- Create scroll frame for the stats
		local statsContainer = Instance.new("ScrollingFrame")
		statsContainer.Name = "StatsContainer"
		statsContainer.Position = UDim2.new(0, 10, 0, 60)
		statsContainer.Size = UDim2.new(1, -20, 1, -70)
		statsContainer.BackgroundTransparency = 1
		statsContainer.ScrollBarThickness = 6
		statsContainer.ZIndex = 11
		statsContainer.Parent = panel

		-- Create layout for the stats
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = statsContainer
	end

	return panel
end

-- Update membership stats display
local function updateStats()
	local statsPanel = statsGui:FindFirstChild("StatsPanel")
	if not statsPanel or not statsPanel.Visible then return end

	local statsContainer = statsPanel:FindFirstChild("StatsContainer")
	if not statsContainer then return end

	-- Get tycoon data
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return end

	-- Define the stats to display
	local stats = {
		{name = "Gym Level", value = tycoon:GetAttribute("GymLevel") or 1, icon = "⭐", color = Color3.fromRGB(255, 215, 0)},
		{name = "Equipment Count", value = tycoon:GetAttribute("EquipmentCount") or 0, icon = "🏋️", color = Color3.fromRGB(100, 100, 255)},
		{name = "Total Members", value = tycoon:GetAttribute("MembershipCount") or 0, icon = "👥", color = Color3.fromRGB(0, 200, 100)},
		{name = "VIP Members", value = tycoon:GetAttribute("VIPMemberCount") or 0, icon = "👑", color = Color3.fromRGB(255, 150, 0)},
		{name = "Hourly Revenue", value = "$" .. formatNumber(tycoon:GetAttribute("HourlyRevenue") or 0), icon = "💰", color = Color3.fromRGB(0, 255, 127)},
		{name = "Membership Tier", value = tycoon:GetAttribute("MembershipTier") or 0, icon = "📊", color = Color3.fromRGB(150, 75, 255)},
		{name = "Staff Count", value = tycoon:GetAttribute("StaffCount") or 0, icon = "👨‍💼", color = Color3.fromRGB(255, 100, 100)},
		{name = "Accrued Dues", value = "$" .. formatNumber(tycoon:GetAttribute("AccruedDues") or 0), icon = "💵", color = Color3.fromRGB(0, 175, 175)}
	}

	-- Clear existing stats
	for _, child in pairs(statsContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Create stat cards
	for i, stat in ipairs(stats) do
		local card = Instance.new("Frame")
		card.Name = "StatCard_" .. stat.name
		card.Size = UDim2.new(1, -20, 0, 60)
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.ZIndex = 11

		-- Add corner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = card

		-- Add icon
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.Position = UDim2.new(0, 10, 0, 10)
		icon.BackgroundColor3 = stat.color
		icon.TextColor3 = Color3.fromRGB(255, 255, 255)
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 20
		icon.Text = stat.icon
		icon.ZIndex = 12
		icon.Parent = card

		-- Add icon corner
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0.5, 0)
		iconCorner.Parent = icon

		-- Add stat name
		local name = Instance.new("TextLabel")
		name.Name = "StatName"
		name.Size = UDim2.new(0.6, 0, 0.5, 0)
		name.Position = UDim2.new(0.15, 0, 0, 0)
		name.BackgroundTransparency = 1
		name.TextColor3 = Color3.fromRGB(200, 200, 200)
		name.Font = Enum.Font.Gotham
		name.TextSize = 16
		name.Text = stat.name
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 12
		name.Parent = card

		-- Add stat value
		local value = Instance.new("TextLabel")
		value.Name = "StatValue"
		value.Size = UDim2.new(0.6, 0, 0.5, 0)
		value.Position = UDim2.new(0.15, 0, 0.5, 0)
		value.BackgroundTransparency = 1
		value.TextColor3 = Color3.fromRGB(255, 255, 255)
		value.Font = Enum.Font.GothamBold
		value.TextSize = 18
		value.Text = tostring(stat.value)
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.ZIndex = 12
		value.Parent = card

		card.Parent = statsContainer
	end

	-- Update scroll frame canvas size
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, (#stats * 70))
end

-- Initialize
local function initialize()
	-- Create UI elements
	local button = createToggleButton()
	local panel = createStatsPanel()

	-- Set up button click
	button.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible

		if panel.Visible then
			-- Update stats immediately when opened
			updateStats()

			-- Animate panel opening
			panel.Position = UDim2.new(0.5, 0, 0.6, 0)
			panel.BackgroundTransparency = 0.5

			TweenService:Create(
				panel,
				TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.1}
			):Play()
		end
	end)

	-- Set up stats update loop
	task.spawn(function()
		while wait(CONFIG.updateInterval) do
			if panel.Visible then
				updateStats()
			end
		end
	end)

	-- Listen for membership updates
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if eventBridge then
		local membershipUpdated = eventBridge:FindFirstChild("MembershipUpdated") 
		if membershipUpdated then
			membershipUpdated.OnClientEvent:Connect(function()
				if panel.Visible then
					updateStats()
				end
			end)
		end
	end
end

-- Start initialization
initialize()