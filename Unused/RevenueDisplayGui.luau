-- Revenue Display GUI
-- Place this script in StarterGui/ScreenGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- Get the screen GUI and frame
local screenGui = script.Parent
local frame = screenGui:WaitForChild("Frame")

-- Set up default frame properties
frame.Size = UDim2.new(0, 300, 0, 80)
frame.Position = UDim2.new(0.5, -150, 0, 10) -- Centered at top of screen
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0

-- Add rounded corners
local cornerRadius = Instance.new("UICorner")
cornerRadius.CornerRadius = UDim.new(0, 10)
cornerRadius.Parent = frame

-- Add content shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.ZIndex = -1
shadow.Image = "rbxassetid://6015897843" -- Shadow asset
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.Parent = frame

-- Create level display text
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, 0, 0.5, 0)
levelLabel.Position = UDim2.new(0, 0, 0, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.TextSize = 22
levelLabel.Text = "Level 1"
levelLabel.Parent = frame

-- Create revenue display text
local revenueLabel = Instance.new("TextLabel")
revenueLabel.Name = "RevenueLabel"
revenueLabel.Size = UDim2.new(1, 0, 0.5, 0)
revenueLabel.Position = UDim2.new(0, 0, 0.5, 0)
revenueLabel.BackgroundTransparency = 1
revenueLabel.Font = Enum.Font.GothamSemibold
revenueLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Light green
revenueLabel.TextSize = 20
revenueLabel.Text = "Revenue: $0/hour"
revenueLabel.Parent = frame

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

-- Function to calculate hourly revenue based on the economy system
local function calculateHourlyRevenue(player)
	-- Default values if we can't access the economy system
	local incomePerInterval = 0
	local intervalSeconds = 20 -- Default interval

	-- Try to access the player's tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	-- Get gym tier/level from tycoon attributes
	local gymTier = tycoon:GetAttribute("GymTier") or 1
	local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0

	-- Try to get income calculation from RemoteFunction if it exists
	local calculateIncomeFunction = ReplicatedStorage:FindFirstChild("CalculateIncomeFunction")
	if calculateIncomeFunction then
		-- Use the remote function to get server-calculated income
		local success, result = pcall(function()
			return calculateIncomeFunction:InvokeServer()
		end)

		if success and result then
			incomePerInterval = result.income
			intervalSeconds = result.interval
		end
	else
		-- Fallback calculation based on equipment and tier
		-- This mimics the server-side calculation in UnifiedGymEconomySystem.lua
		local baseIncome = 15
		local equipmentBonus = equipmentCount * 1.5
		local tierMultiplier = 1.2 ^ (gymTier - 1)

		incomePerInterval = math.floor((baseIncome + equipmentBonus) * tierMultiplier)

		-- Also check for NPCs if we can
		if tycoon.Value then
			local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
			if npcsFolder then
				local npcCount = #npcsFolder:GetChildren()
				local npcIncome = npcCount * 15 -- Approximate NPC income
				incomePerInterval = incomePerInterval + npcIncome
			end
		end
	end

	-- Calculate hourly revenue
	local hourlyRevenue = math.floor(incomePerInterval * (3600 / intervalSeconds))
	return hourlyRevenue, gymTier
end

-- Function to update the display
local function updateRevenueDisplay()
	local player = Players.LocalPlayer
	if not player then return end

	local hourlyRevenue, gymTier = calculateHourlyRevenue(player)

	-- Update the level display
	levelLabel.Text = "Level " .. gymTier

	-- Update the revenue display with formatted number
	revenueLabel.Text = "Revenue: $" .. formatNumber(hourlyRevenue) .. "/hour"

	-- Add a subtle animation effect
	local originalSize = frame.Size
	local expandedSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 10, 
		originalSize.Y.Scale, originalSize.Y.Offset + 5)

	local expansionTween = TweenService:Create(
		frame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = expandedSize}
	)

	local contractionTween = TweenService:Create(
		frame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = originalSize}
	)

	expansionTween:Play()
	expansionTween.Completed:Connect(function()
		contractionTween:Play()
	end)
end

-- Update the display periodically
while true do
	updateRevenueDisplay()
	wait(5) -- Update every 5 seconds
end