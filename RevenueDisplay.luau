-- Optimized Revenue Display System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Configuration
local CONFIG = {
	-- Display settings
	mainSize = UDim2.new(0, 250, 0, 120),
	mainOffset = Vector3.new(0, 5, 0),

	-- Colors
	backgroundColor = Color3.fromRGB(30, 30, 30),
	borderColor = Color3.fromRGB(0, 100, 200),
	textColor = Color3.fromRGB(255, 255, 255),
	revenueColor = Color3.fromRGB(255, 215, 0), -- Gold

	-- Transparency
	backgroundTransparency = 0.2,

	-- Animation
	animationDuration = 0.5,
	updateEffectDuration = 1,

	-- Design
	cornerRadius = UDim.new(0, 10),
	borderSize = 2,

	-- Update frequency
	updateInterval = 5, -- Update every 5 seconds

	-- Debug
	debug = true
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Revenue Display]", ...)
	end
end

-- Module table
local RevenueDisplay = {}

-- Format large numbers with commas
local function formatWithCommas(number)
	local formatted = tostring(number)
	local formattedWithCommas = ""

	for i = #formatted, 1, -1 do
		if (#formatted - i) % 3 == 0 and i ~= #formatted then
			formattedWithCommas = "," .. formattedWithCommas
		end
		formattedWithCommas = string.sub(formatted, i, i) .. formattedWithCommas
	end

	return formattedWithCommas
end

-- Calculate monthly revenue (scaling hourly revenue)
local function calculateMonthlyRevenue(hourlyRevenue)
	-- Assuming 16 hours of operation per day, 30 days per month
	return hourlyRevenue * 16 * 30
end

-- Calculate player income safely using the connector
local function calculatePlayerIncome(player)
	-- Default values
	local incomePerInterval = 0
	local intervalSeconds = 60

	-- Try to get income from connector
	if _G.GymTycoonConnector and _G.GymTycoonConnector.EconomySystem and 
		typeof(_G.GymTycoonConnector.EconomySystem.calculatePlayerIncome) == "function" then

		incomePerInterval = _G.GymTycoonConnector.EconomySystem.calculatePlayerIncome(player)
		intervalSeconds = _G.GymTycoonConnector.EconomySystem.CONFIG and
			_G.GymTycoonConnector.EconomySystem.CONFIG.incomeInterval or 60
	else
		-- Fallback to direct calculation
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
			local gymTier = tycoon:GetAttribute("GymTier") or 1

			-- Base income calculation
			incomePerInterval = 15 * (1.2 ^ (gymTier - 1)) + equipmentCount * 3

			-- Add NPC income if possible
			if tycoon.Value then
				local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
				if npcsFolder then
					for _, npc in pairs(npcsFolder:GetChildren()) do
						local membershipFee = npc:GetAttribute("MembershipFee") or 15
						incomePerInterval = incomePerInterval + membershipFee
					end
				end
			end

			intervalSeconds = 60 -- Default interval
		end
	end

	-- Calculate hourly revenue
	local hourlyRevenue = math.floor(incomePerInterval * (3600 / intervalSeconds))

	return hourlyRevenue
end

-- Create a revenue display for a front desk
function RevenueDisplay.createRevenueDisplay(frontDesk, player)
	if not frontDesk or not player then
		debugPrint("Invalid frontDesk or player provided")
		return nil
	end

	-- Check if front desk already has a revenue display
	local existingDisplay = frontDesk:FindFirstChild("RevenueDisplay")
	if existingDisplay then
		existingDisplay:Destroy() -- Remove existing to refresh
	end

	-- Create BillboardGui
	local display = Instance.new("BillboardGui")
	display.Name = "RevenueDisplay"
	display.Size = CONFIG.mainSize
	display.StudsOffset = CONFIG.mainOffset
	display.Adornee = frontDesk
	display.AlwaysOnTop = true

	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = CONFIG.backgroundColor
	mainFrame.BackgroundTransparency = CONFIG.backgroundTransparency
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = display

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CONFIG.cornerRadius
	corner.Parent = mainFrame

	-- Add border
	local border = Instance.new("UIStroke")
	border.Color = CONFIG.borderColor
	border.Thickness = CONFIG.borderSize
	border.Parent = mainFrame

	-- Add gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
	})
	gradient.Rotation = 45
	gradient.Parent = mainFrame

	-- Create header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.25, 0)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.TextColor3 = CONFIG.textColor
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.Text = "GYM REVENUE"
	header.Parent = mainFrame

	-- Create hourly revenue display
	local hourlyRevenue = Instance.new("TextLabel")
	hourlyRevenue.Name = "HourlyRevenue"
	hourlyRevenue.Size = UDim2.new(1, 0, 0.3, 0)
	hourlyRevenue.Position = UDim2.new(0, 0, 0.25, 0)
	hourlyRevenue.BackgroundTransparency = 1
	hourlyRevenue.TextColor3 = CONFIG.revenueColor
	hourlyRevenue.Font = Enum.Font.GothamBold
	hourlyRevenue.TextSize = 18
	hourlyRevenue.Text = "$0/hr"
	hourlyRevenue.Parent = mainFrame

	-- Create monthly revenue display
	local monthlyRevenue = Instance.new("TextLabel")
	monthlyRevenue.Name = "MonthlyRevenue"
	monthlyRevenue.Size = UDim2.new(1, 0, 0.25, 0)
	monthlyRevenue.Position = UDim2.new(0, 0, 0.55, 0)
	monthlyRevenue.BackgroundTransparency = 1
	monthlyRevenue.TextColor3 = CONFIG.revenueColor
	monthlyRevenue.Font = Enum.Font.Gotham
	monthlyRevenue.TextSize = 14
	monthlyRevenue.Text = "$0/month"
	monthlyRevenue.Parent = mainFrame

	-- Create income sources display
	local sources = Instance.new("TextLabel")
	sources.Name = "Sources"
	sources.Size = UDim2.new(1, 0, 0.2, 0)
	sources.Position = UDim2.new(0, 0, 0.8, 0)
	sources.BackgroundTransparency = 1
	sources.TextColor3 = CONFIG.textColor
	sources.Font = Enum.Font.Gotham
	sources.TextSize = 12
	sources.Text = "0 Equipment | 0 NPCs"
	sources.Parent = mainFrame

	-- Parent to front desk
	display.Parent = frontDesk

	-- Set up update animation
	local lastRevenue = 0

	-- Function to update display with animation
	local function updateDisplay()
		-- Calculate revenue
		local hourlyIncome = calculatePlayerIncome(player)
		local monthlyIncome = calculateMonthlyRevenue(hourlyIncome)

		-- Format values with commas
		local formattedHourly = formatWithCommas(hourlyIncome)
		local formattedMonthly = formatWithCommas(monthlyIncome)

		-- Update text
		hourlyRevenue.Text = "$" .. formattedHourly .. "/hr"
		monthlyRevenue.Text = "$" .. formattedMonthly .. "/month"

		-- Update income sources
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
			local npcCount = 0

			if tycoon.Value then
				local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
				if npcsFolder then
					npcCount = #npcsFolder:GetChildren()
				end
			end

			sources.Text = equipmentCount .. " Equipment | " .. npcCount .. " NPCs"
		end

		-- Animate if revenue has changed
		if hourlyIncome ~= lastRevenue then
			-- Scale effect
			local originalScale = hourlyRevenue.TextSize
			hourlyRevenue.TextSize = originalScale * 1.2

			-- Color effect
			local originalColor = hourlyRevenue.TextColor3
			hourlyRevenue.TextColor3 = hourlyIncome > lastRevenue 
				and Color3.fromRGB(0, 255, 0)  -- Green if increased
				or Color3.fromRGB(255, 0, 0)   -- Red if decreased

			-- Tween back to normal
			task.spawn(function()
				task.wait(0.2) -- Short delay for emphasis

				local tweenInfo = TweenInfo.new(
					CONFIG.updateEffectDuration,
					Enum.EasingStyle.Elastic,
					Enum.EasingDirection.Out
				)

				local tween1 = TweenService:Create(
					hourlyRevenue, 
					tweenInfo, 
					{TextSize = originalScale, TextColor3 = originalColor}
				)

				tween1:Play()
			end)

			lastRevenue = hourlyIncome
		end
	end

	-- Initial update
	updateDisplay()

	-- Setup periodic updates
	task.spawn(function()
		while display and display.Parent do
			task.wait(CONFIG.updateInterval)

			-- Use pcall to prevent errors from breaking the loop
			pcall(function()
				updateDisplay()
			end)
		end
	end)

	debugPrint("Created revenue display for " .. player.Name)
	return display
end

-- Find and update all front desks
function RevenueDisplay.updateAllDisplays()
	debugPrint("Updating all revenue displays")

	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon.Value then
				local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
				if frontDesk then
					RevenueDisplay.createRevenueDisplay(frontDesk, player)
				end
			end
		end)
	end
end

-- Initialize the system
function RevenueDisplay.initialize()
	debugPrint("Initializing Revenue Display System")

	-- Run initial update
	RevenueDisplay.updateAllDisplays()

	-- Set up periodic updates
	task.spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds for new front desks
			RevenueDisplay.updateAllDisplays()
		end
	end)

	-- Watch for new front desks
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "Front Desk" and descendant:IsA("Model") then
			-- Wait a bit for everything to set up
			task.wait(1)

			-- Find which player this front desk belongs to
			for _, player in pairs(Players:GetPlayers()) do
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon and tycoon.Value then
					if descendant:IsDescendantOf(tycoon.Value) then
						RevenueDisplay.createRevenueDisplay(descendant, player)
						break
					end
				end
			end
		end
	end)

	debugPrint("Revenue Display System initialized")
	return true
end

-- Run initialization automatically
RevenueDisplay.initialize()

-- Return public API
return RevenueDisplay