-- DailyRewardsSystem.lua
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Try to load dependencies
local DataStorage
pcall(function()
	DataStorage = require(ServerScriptService:FindFirstChild("DataStorageSystem"))
end)

local DailyRewardSystem = {
	rewards = {
		{ type = "cash", amount = 1000, description = "$1,000 Cash Bonus" },
		{ type = "cash", amount = 2000, description = "$2,000 Cash Bonus" },
		{ type = "cash", amount = 3000, description = "$3,000 Cash Bonus" },
		{ type = "multiplier", amount = 1.5, duration = 3600, description = "1.5x Income for 1 Hour" },
		{ type = "cash", amount = 5000, description = "$5,000 Cash Bonus" },
		{ type = "vip_member", amount = 3, description = "3 Free VIP Members" },
		{ type = "cash", amount = 10000, description = "BIG $10,000 Cash Bonus!" }
	},
	activeMultipliers = {} -- Format: {userId = {multiplier, endTime}}
}

-- Initialize player data
function DailyRewardSystem.initPlayerData(player)
	if not DataStorage then return end

	local userId = player.UserId
	local data = DataStorage.loadedData[userId]

	if data and not data.dailyRewards then
		data.dailyRewards = {
			lastClaimed = 0,
			streak = 0,
			multiplierEndTime = 0
		}
	end
end

-- Check if player can claim daily reward
function DailyRewardSystem.canClaimReward(player)
	if not DataStorage then return false end

	local userId = player.UserId
	local data = DataStorage.loadedData[userId]

	if not data or not data.dailyRewards then
		DailyRewardSystem.initPlayerData(player)
		data = DataStorage.loadedData[userId]
	end

	if not data then return false end

	-- Calculate time since last claim
	local currentTime = os.time()
	local lastClaimed = data.dailyRewards.lastClaimed
	local timeSince = currentTime - lastClaimed

	-- Can claim after 20 hours (allows for some timezone flexibility)
	return timeSince >= 20 * 3600
end

-- Get current streak count
function DailyRewardSystem.getStreakCount(player)
	if not DataStorage then return 0 end

	local userId = player.UserId
	local data = DataStorage.loadedData[userId]

	if not data or not data.dailyRewards then
		DailyRewardSystem.initPlayerData(player)
		data = DataStorage.loadedData[userId]
		

		if not data then return 0 end

-- Check if streak is still valid (36 hours to maintain streak)
local currentTime = os.time()
local lastClaimed = data.dailyRewards.lastClaimed
local timeSince = currentTime - lastClaimed

if timeSince > 36 * 3600 then
	-- Streak expired
	data.dailyRewards.streak = 0
end

return data.dailyRewards.streak
end

-- Give reward to player
function DailyRewardSystem.giveReward(player)
	if not player then return false end

	local userId = player.UserId
	if not DataStorage then return false end

	local data = DataStorage.loadedData[userId]
	if not data or not data.dailyRewards then
		DailyRewardSystem.initPlayerData(player)
		data = DataStorage.loadedData[userId]
		

		if not data then return false end

-- Check if can claim
if not DailyRewardSystem.canClaimReward(player) then
	return false, "You've already claimed your daily reward. Come back tomorrow!"
end

-- Calculate streak
local currentTime = os.time()
local lastClaimed = data.dailyRewards.lastClaimed
local timeSince = currentTime - lastClaimed

-- If first claim or streak expired, set to 1, otherwise increment
if lastClaimed == 0 or timeSince > 36 * 3600 then
	data.dailyRewards.streak = 1
else
	data.dailyRewards.streak = data.dailyRewards.streak + 1
end

-- Cap streak at rewards table length
local streak = math.min(data.dailyRewards.streak, #DailyRewardSystem.rewards)

-- Get reward for current streak
local rewardIndex = ((streak - 1) % #DailyRewardSystem.rewards) + 1
local reward = DailyRewardSystem.rewards[rewardIndex]

-- Apply reward
if reward.type == "cash" then
	-- Add cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + reward.amount
	end

	-- Update data storage
	data.cash = (data.cash or 0) + reward.amount

elseif reward.type == "multiplier" then
	-- Set income multiplier
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		tycoon:SetAttribute("IncomeMultiplier", reward.amount)

		-- Set expiry time
		local endTime = os.time() + reward.duration
		data.dailyRewards.multiplierEndTime = endTime

		-- Track active multiplier
		DailyRewardSystem.activeMultipliers[userId] = {
			multiplier = reward.amount,
			endTime = endTime
		}
		

		elseif reward.type == "vip_member" then
	-- Add VIP members
	for i = 1, reward.amount do
		-- Spawn VIP NPCs
		task.spawn(function()
			local NPCSystem
			pcall(function()
				NPCSystem = require(ServerScriptService:FindFirstChild("UnifiedNPCSystem"))
			end)

			if NPCSystem and NPCSystem.trySpawnNPC then
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon and tycoon.Value then
					local spawnPosition = tycoon.Value:GetPivot().Position + Vector3.new(0, 5, 0)
					NPCSystem.createNPC(spawnPosition, tycoon.Value, player, true) -- true = VIP
				end
			end

			wait(0.5) -- Space out spawns
		end)
	end
end

-- Update claim time
data.dailyRewards.lastClaimed = currentTime

-- Save data
if DataStorage.saveData then
	DataStorage.saveData(player)
end

return true, reward.description, streak
end

-- Create UI for a player
function DailyRewardSystem.createUI(player)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardsGui"
	screenGui.ResetOnSpawn = false

	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	title.TextSize = 24
	title.Text = "Daily Reward"
	title.Parent = mainFrame

	-- Streak counter
	local streakCounter = Instance.new("TextLabel")
	streakCounter.Name = "StreakCounter"
	streakCounter.Size = UDim2.new(1, 0, 0, 30)
	streakCounter.Position = UDim2.new(0, 0, 0, 40)
	streakCounter.BackgroundTransparency = 1
	streakCounter.Font = Enum.Font.Gotham
	streakCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
	streakCounter.TextSize = 16
	streakCounter.Text = "Current Streak: 0 days"
	streakCounter.Parent = mainFrame

	-- Reward description
	local rewardDesc = Instance.new("TextLabel")
	rewardDesc.Name = "RewardDescription"
	rewardDesc.Size = UDim2.new(1, -40, 0, 60)
	rewardDesc.Position = UDim2.new(0, 20, 0, 80)
	rewardDesc.BackgroundTransparency = 1
	rewardDesc.Font = Enum.Font.GothamBold
	rewardDesc.TextColor3 = Color3.fromRGB(0, 200, 255)
	rewardDesc.TextSize = 20
	rewardDesc.Text = "Your reward is waiting!"
	rewardDesc.TextWrapped = true
	rewardDesc.Parent = mainFrame

	-- Claim button
	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0, 200, 0, 50)
	claimButton.Position = UDim2.new(0.5, -100, 1, -80)
	claimButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	claimButton.Font = Enum.Font.GothamBold
	claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimButton.TextSize = 18
	claimButton.Text = "CLAIM REWARD"
	claimButton.Parent = mainFrame

	-- Add rounded corners to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = claimButton

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 0, 30)
	cooldownText.Position = UDim2.new(0, 0, 1, -30)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Font = Enum.Font.Gotham
	cooldownText.TextColor3 = Color3.fromRGB(200, 200, 200)
	cooldownText.TextSize = 14
	cooldownText.Text = ""
	cooldownText.Parent = mainFrame

	-- Connect button
	claimButton.MouseButton1Click:Connect(function()
		local success, message, streak = DailyRewardSystem.giveReward(player)

		if success then
			-- Update UI
			rewardDesc.Text = message
			streakCounter.Text = "Current Streak: " .. streak .. " days"

			-- Animate button
			claimButton.Text = "CLAIMED!"
			claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			claimButton.Enabled = false

			-- Show confetti effect
			-- Implementation depends on your preferred visual style

			-- Close UI after a delay
			wait(3)
			DailyRewardSystem.hideUI(player)
		else
			-- Show error message
			rewardDesc.Text = message
			rewardDesc.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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
		DailyRewardSystem.hideUI(player)
	end)

	screenGui.Parent = player.PlayerGui
	return screenGui
end

-- Show the daily rewards UI
function DailyRewardSystem.showUI(player)
	local userId = player.UserId

	-- Find existing GUI or create new one
	local gui = player.PlayerGui:FindFirstChild("DailyRewardsGui")
	if not gui then
		gui = DailyRewardSystem.createUI(player)
	end

	local mainFrame = gui.MainFrame

	-- Update streak count
	local streakCounter = mainFrame.StreakCounter
	local streak = DailyRewardSystem.getStreakCount(player)
	streakCounter.Text = "Current Streak: " .. streak .. " days"

	-- Update reward description
	local rewardDesc = mainFrame.RewardDescription
	local nextIndex = ((streak % #DailyRewardSystem.rewards) + 1)
	local nextReward = DailyRewardSystem.rewards[nextIndex]
	rewardDesc.Text = "Today's Reward: " .. nextReward.description
	rewardDesc.TextColor3 = Color3.fromRGB(0, 200, 255)

	-- Update claim button state
	local claimButton = mainFrame.ClaimButton
	local canClaim = DailyRewardSystem.canClaimReward(player)

	if canClaim then
		claimButton.Text = "CLAIM REWARD"
		claimButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
		claimButton.Enabled = true
	else
		claimButton.Text = "ALREADY CLAIMED"
		claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		claimButton.Enabled = false

		-- Update cooldown text
		local cooldownText = mainFrame.CooldownText

		-- Calculate time until next claim
		local data = DataStorage.loadedData[userId]
		if data and data.dailyRewards then
			local nextClaimTime = data.dailyRewards.lastClaimed + (20 * 3600)
			local timeLeft = nextClaimTime - os.time()

			if timeLeft > 0 then
				local hoursLeft = math.floor(timeLeft / 3600)
				local minutesLeft = math.floor((timeLeft % 3600) / 60)
				cooldownText.Text = "Next reward in: " .. hoursLeft .. "h " .. minutesLeft .. "m"
			else
				cooldownText.Text = "You can claim your reward now!"
			end
		end
	end

	-- Show the frame with animation
	mainFrame.Position = UDim2.new(0.5, -200, 0, -300)
	mainFrame.Visible = true

	local showTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0.5, -150)}
	)
	showTween:Play()
end

-- Hide the daily rewards UI
function DailyRewardSystem.hideUI(player)
	local gui = player.PlayerGui:FindFirstChild("DailyRewardsGui")
	if not gui then return end

	local mainFrame = gui.MainFrame

	local hideTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -200, 0, -300)}
	)
	hideTween:Play()

	hideTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

-- Initialize the system
function DailyRewardSystem.initialize()
	-- Update active multipliers
	spawn(function()
		while wait(10) do
			local currentTime = os.time()

			-- Check all active multipliers
			for userId, data in pairs(DailyRewardSystem.activeMultipliers) do
				if data.endTime <= currentTime then
					-- Multiplier expired
					local player = Players:GetPlayerByUserId(userId)
					if player then
						local tycoon = player:FindFirstChild("Tycoon")
						if tycoon then
							tycoon:SetAttribute("IncomeMultiplier", 1)
						end
					end

					-- Remove from active multipliers
					DailyRewardSystem.activeMultipliers[userId] = nil

					-- Update data storage
					-- Update data storage
					if DataStorage and DataStorage.loadedData[userId] then
						DataStorage.loadedData[userId].dailyRewards.multiplierEndTime = 0
					end
				end
			end
		end
	end)

	-- Daily login check
	Players.PlayerAdded:Connect(function(player)
		-- Initialize player data
		DailyRewardSystem.initPlayerData(player)

		-- Wait for everything to load
		wait(5)

		-- Check if player can claim reward
		if DailyRewardSystem.canClaimReward(player) then
			-- Show notification
			local notification = Instance.new("Message")
			notification.Text = "Your daily reward is ready to claim!"
			notification.Parent = player
			game:GetService("Debris"):AddItem(notification, 5)

			-- Add button to claim
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "RewardNotification"
			screenGui.ResetOnSpawn = false

			local button = Instance.new("TextButton")
			button.Size = UDim2.new(0, 200, 0, 50)
			button.Position = UDim2.new(1, -220, 0, 20)
			button.AnchorPoint = Vector2.new(0, 0)
			button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			button.BorderSizePixel = 0
			button.Text = "🎁 CLAIM DAILY REWARD"
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Font = Enum.Font.GothamBold
			button.TextSize = 16
			button.Parent = screenGui

			-- Add rounded corners
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 8)
			uiCorner.Parent = button

			-- Add glow effect
			local uiGradient = Instance.new("UIGradient")
			uiGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200))
			})
			uiGradient.Parent = button

			-- Add animation
			spawn(function()
				while button.Parent do
					local original = button.Position
					local tween = TweenService:Create(
						button,
						TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
						{Position = original + UDim2.new(0, 0, 0, 10)}
					)
					tween:Play()
					wait(2)
				end
			end)

			-- Connect button
			button.MouseButton1Click:Connect(function()
				screenGui:Destroy()
				DailyRewardSystem.showUI(player)
			end)

			screenGui.Parent = player.PlayerGui
		end

		-- Check for active multiplier
		local userId = player.UserId
		if DataStorage and DataStorage.loadedData[userId] and DataStorage.loadedData[userId].dailyRewards then
			local endTime = DataStorage.loadedData[userId].dailyRewards.multiplierEndTime

			if endTime > os.time() then
				-- Restore multiplier
				local multiplier = 1.5 -- Default
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					tycoon:SetAttribute("IncomeMultiplier", multiplier)
				end

				-- Track active multiplier
				DailyRewardSystem.activeMultipliers[userId] = {
					multiplier = multiplier,
					endTime = endTime
				}

				-- Notify player
				local notification = Instance.new("Message")
				notification.Text = "Income Multiplier active: " .. multiplier .. "x"
				notification.Parent = player
				game:GetService("Debris"):AddItem(notification, 5)
			end
		end
	end)

	-- Add command to show UI
	local function onPlayerChatted(player, message)
		if message:lower() == "/daily" then
			DailyRewardSystem.showUI(player)
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			onPlayerChatted(player, message)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			onPlayerChatted(player, message)
		end)
	end)

	print("Daily Reward System initialized")
	return true
end

DailyRewardSystem.initialize()

return DailyRewardSystem
	end
end
end
