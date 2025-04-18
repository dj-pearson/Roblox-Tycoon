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

-- Try to load CoreRegistry for new architecture
local CoreRegistry
pcall(function()
	CoreRegistry = require(ServerScriptService:WaitForChild("Core"):WaitForChild("CoreRegistry"))
end)

-- Try to get NPCSystem from CoreRegistry
local NPCSystem

local DailyRewardSystem = {
	-- Standard rewards
	rewards = {
		{ type = "cash", amount = 1000, description = "$1,000 Cash Bonus", rarity = "common" },
		{ type = "cash", amount = 2000, description = "$2,000 Cash Bonus", rarity = "common" },
		{ type = "cash", amount = 3000, description = "$3,000 Cash Bonus", rarity = "common" },
		{ type = "multiplier", amount = 1.5, duration = 3600, description = "1.5x Income for 1 Hour", rarity = "uncommon" },
		{ type = "cash", amount = 5000, description = "$5,000 Cash Bonus", rarity = "uncommon" },
		{ type = "vip_member", amount = 3, description = "3 Free VIP Members", rarity = "rare" },
		{ type = "cash", amount = 10000, description = "BIG $10,000 Cash Bonus!", rarity = "rare" },
	},
	
	-- Rare rewards that occasionally appear (lower chance to get)
	rareRewards = {
		{ type = "multiplier", amount = 2.5, duration = 7200, description = "2.5x Income for 2 Hours!", rarity = "epic" },
		{ type = "vip_member", amount = 5, description = "5 Free VIP Members", rarity = "epic" },
		{ type = "cash", amount = 25000, description = "HUGE $25,000 Cash Bonus!", rarity = "epic" },
		{ type = "satisfaction", amount = 15, duration = 14400, description = "+15 Member Satisfaction for 4 Hours", rarity = "epic" },
		{ type = "staff_efficiency", amount = 0.5, duration = 10800, description = "+50% Staff Efficiency for 3 Hours", rarity = "legendary" },
		{ type = "equipment_quality", amount = 25, description = "+25 Equipment Quality", rarity = "legendary" },
		{ type = "cash", amount = 50000, description = "JACKPOT $50,000 Cash Bonus!!", rarity = "legendary" },
	},
	
	-- Milestone rewards for consistent play (fixed days)
	milestoneRewards = {
		[7] = { type = "cash", amount = 20000, description = "7 Day Streak: $20,000 Bonus!" },
		[14] = { type = "multiplier", amount = 2, duration = 10800, description = "14 Day Streak: 2x Income for 3 Hours!" },
		[30] = { type = "premium_pack", description = "30 Day Streak: Ultimate Premium Pack!" },
		[60] = { type = "gym_decoration", itemId = "trophy_case", description = "60 Day Streak: Exclusive Trophy Case!" },
		[90] = { type = "special_staff", staffId = "celebrity_trainer", description = "90 Day Streak: Celebrity Trainer!" }
	},
	
	-- Streak multipliers - increase reward values for consecutive days
	streakMultipliers = {
		-- [streak days] = multiplier value
		[1] = 1.0,    -- Day 1: normal rewards
		[2] = 1.1,    -- Day 2: 10% bonus
		[3] = 1.2,    -- Day 3: 20% bonus
		[4] = 1.3,    -- Day 4: 30% bonus
		[5] = 1.5,    -- Day 5: 50% bonus
		[10] = 2.0,   -- Day 10+: double rewards
		[20] = 2.5,   -- Day 20+: 2.5x rewards
		[30] = 3.0    -- Day 30+: triple rewards
	},
	
	-- Chance to get a rare reward
	rareRewardChance = {
		base = 0.1,       -- 10% base chance for rare reward
		perStreak = 0.01  -- +1% per streak day
	},
	
	activeMultipliers = {}, -- Format: {userId = {multiplier, endTime}}
	activeSatisfactionBoosts = {}, -- Format: {userId = {amount, endTime}}
	activeEfficiencyBoosts = {}, -- Format: {userId = {amount, endTime}}
}

-- Calculate the streak multiplier for a given streak count
function DailyRewardSystem.getStreakMultiplier(streak)
	-- Find the highest threshold that's not greater than the streak
	local highestThreshold = 1
	local multiplier = 1.0
	
	for threshold, value in pairs(DailyRewardSystem.streakMultipliers) do
		if streak >= threshold and threshold > highestThreshold then
			highestThreshold = threshold
			multiplier = value
		end
	end
	
	return multiplier
end

-- Calculate chance of getting a rare reward based on streak
function DailyRewardSystem.getRareRewardChance(streak)
	local baseChance = DailyRewardSystem.rareRewardChance.base
	local streakBonus = DailyRewardSystem.rareRewardChance.perStreak * streak
	
	-- Cap at 50% max chance
	return math.min(baseChance + streakBonus, 0.5)
end

-- Initialize player data
function DailyRewardSystem.initPlayerData(player)
	if not DataStorage then return end

	local userId = player.UserId
	local data = DataStorage.loadedData[userId]

	if data and not data.dailyRewards then
		data.dailyRewards = {
			lastClaimed = 0,
			streak = 0,
			multiplierEndTime = 0,
			satisfactionBoostEndTime = 0,
			efficiencyBoostEndTime = 0,
			lifetimeStreak = 0,   -- Track highest streak ever achieved
			totalClaims = 0,      -- Track total number of daily rewards claimed
			unlockedSpecials = {} -- Track special rewards unlocked
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
	end

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

-- Get reward based on streak and rarity chance
function DailyRewardSystem.selectReward(streak)
	-- Check for milestone rewards first
	local milestoneReward = DailyRewardSystem.milestoneRewards[streak]
	if milestoneReward then
		return milestoneReward, true -- Second return value indicates this is a milestone reward
	end
	
	-- Calculate chance for rare reward
	local rareChance = DailyRewardSystem.getRareRewardChance(streak)
	
	-- Determine if player gets a rare reward
	local useRarePool = (math.random() < rareChance)
	
	local rewardPool = useRarePool and DailyRewardSystem.rareRewards or DailyRewardSystem.rewards
	local rewardIndex = math.random(1, #rewardPool)
	
	return rewardPool[rewardIndex], false -- Regular reward (not milestone)
end

-- Apply streak multiplier to reward
function DailyRewardSystem.applyStreakMultiplier(reward, streak)
	local multiplier = DailyRewardSystem.getStreakMultiplier(streak)
	local adjustedReward = table.clone(reward)
	
	-- Apply multiplier to relevant values
	if reward.type == "cash" then
		adjustedReward.amount = math.floor(reward.amount * multiplier)
		adjustedReward.description = "$" .. string.format("%s", adjustedReward.amount) .. " Cash Bonus"
		if multiplier > 1 then
			adjustedReward.description = adjustedReward.description .. " (+" .. math.floor((multiplier - 1) * 100) .. "% Streak Bonus!)"
		end
	elseif reward.type == "multiplier" then
		-- Don't multiply the multiplier, but extend duration
		adjustedReward.duration = math.floor(reward.duration * math.sqrt(multiplier))
		local hours = math.floor(adjustedReward.duration / 3600)
		adjustedReward.description = reward.amount .. "x Income for " .. hours .. " Hour" .. (hours > 1 and "s" or "")
		if multiplier > 1 then
			adjustedReward.description = adjustedReward.description .. " (+" .. math.floor((multiplier - 1) * 100) .. "% longer!)"
		end
	elseif reward.type == "vip_member" then
		-- Add more VIP members based on streak
		adjustedReward.amount = math.floor(reward.amount * math.sqrt(multiplier))
		adjustedReward.description = adjustedReward.amount .. " Free VIP Members"
		if multiplier > 1 and adjustedReward.amount > reward.amount then
			adjustedReward.description = adjustedReward.description .. " (+" .. (adjustedReward.amount - reward.amount) .. " Bonus Members!)"
		end
	end
	
	return adjustedReward
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
	end

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
	
	local streak = data.dailyRewards.streak
	
	-- Track lifetime stats
	data.dailyRewards.totalClaims = (data.dailyRewards.totalClaims or 0) + 1
	data.dailyRewards.lifetimeStreak = math.max(data.dailyRewards.lifetimeStreak or 0, streak)
	
	-- Select reward based on streak
	local reward, isMilestone = DailyRewardSystem.selectReward(streak)
	
	-- Apply streak multiplier if not a milestone reward
	if not isMilestone then
		reward = DailyRewardSystem.applyStreakMultiplier(reward, streak)
	end
	
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
		end
	elseif reward.type == "vip_member" then
		-- Add VIP members
		for i = 1, reward.amount do
			-- Spawn VIP NPCs
			task.spawn(function()
				if CoreRegistry then
					-- Try to get NPCSystem from CoreRegistry
					if not NPCSystem then
						NPCSystem = CoreRegistry:tryGetSystem("NPCSystem")
					end
					
					if NPCSystem and NPCSystem.createNPC then
						local tycoon = player:FindFirstChild("Tycoon")
						if tycoon and tycoon.Value then
							local spawnPosition = tycoon.Value:GetPivot().Position + Vector3.new(0, 5, 0)
							NPCSystem:createNPC(spawnPosition, tycoon.Value, player, true) -- true = VIP
						end
					end
				else
					-- Legacy support
					local legacyNPCSystem
					pcall(function()
						legacyNPCSystem = require(ServerScriptService:FindFirstChild("UnifiedNPCSystem"))
					end)

					if legacyNPCSystem and legacyNPCSystem.createNPC then
						local tycoon = player:FindFirstChild("Tycoon")
						if tycoon and tycoon.Value then
							local spawnPosition = tycoon.Value:GetPivot().Position + Vector3.new(0, 5, 0)
							legacyNPCSystem.createNPC(spawnPosition, tycoon.Value, player, true) -- true = VIP
						end
					end
				end

				task.wait(0.5) -- Space out spawns
			end)
		end
	elseif reward.type == "satisfaction" then
		-- Increase member satisfaction temporarily
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			local currentSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or 75
			tycoon:SetAttribute("MemberSatisfaction", math.min(100, currentSatisfaction + reward.amount))
			
			-- Set expiry time
			local endTime = os.time() + reward.duration
			data.dailyRewards.satisfactionBoostEndTime = endTime
			
			-- Track active boost
			DailyRewardSystem.activeSatisfactionBoosts[userId] = {
				amount = reward.amount,
				endTime = endTime
			}
		end
	elseif reward.type == "staff_efficiency" then
		-- Increase staff efficiency temporarily
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			tycoon:SetAttribute("StaffEfficiencyBoost", reward.amount)
			
			-- Set expiry time
			local endTime = os.time() + reward.duration
			data.dailyRewards.efficiencyBoostEndTime = endTime
			
			-- Track active boost
			DailyRewardSystem.activeEfficiencyBoosts[userId] = {
				amount = reward.amount,
				endTime = endTime
			}
		end
	elseif reward.type == "equipment_quality" then
		-- Improve equipment quality
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			local currentQuality = tycoon:GetAttribute("EquipmentQuality") or 100
			tycoon:SetAttribute("EquipmentQuality", math.min(100, currentQuality + reward.amount))
		end
	elseif reward.type == "premium_pack" then
		-- Give a premium pack with multiple bonuses
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Cash") then
			leaderstats.Cash.Value = leaderstats.Cash.Value + 50000 -- Cash bonus
		end
		
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			-- Apply multiple benefits
			tycoon:SetAttribute("IncomeMultiplier", 2.0) -- Income boost
			tycoon:SetAttribute("MembershipBonus", 0.5) -- 50% more members
			
			-- Set expiry time (24 hours)
			local endTime = os.time() + (24 * 3600)
			data.dailyRewards.multiplierEndTime = endTime
			
			-- Track boost
			DailyRewardSystem.activeMultipliers[userId] = {
				multiplier = 2.0,
				endTime = endTime
			}
		end
		
		-- Record special reward in player data
		data.dailyRewards.unlockedSpecials = data.dailyRewards.unlockedSpecials or {}
		data.dailyRewards.unlockedSpecials["premium_pack"] = true
	elseif reward.type == "gym_decoration" or reward.type == "special_staff" then
		-- Store special reward data
		data.dailyRewards.unlockedSpecials = data.dailyRewards.unlockedSpecials or {}
		data.dailyRewards.unlockedSpecials[reward.type .. "_" .. (reward.itemId or reward.staffId)] = true
		
		-- Implementation for these special rewards would connect to other systems
		if reward.type == "special_staff" and reward.staffId == "celebrity_trainer" then
			-- Find staff system
			local StaffManagementSystem
			
			if CoreRegistry then
				StaffManagementSystem = CoreRegistry:tryGetSystem("StaffManagementSystem")
			end
			
			-- Add celebrity trainer if system exists
			if StaffManagementSystem and StaffManagementSystem.addSpecialStaff then
				StaffManagementSystem:addSpecialStaff(player, "celebrity_trainer", 1)
			end
		end
	end

	-- Update claim time
	data.dailyRewards.lastClaimed = currentTime

	-- Save data
	if DataStorage.saveData then
		DataStorage.saveData(player)
	end

	-- Return the reward details and streak
	return true, reward.description, streak, reward.rarity or "common"
end

-- Create UI for a player
function DailyRewardSystem.createUI(player)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardsGui"
	screenGui.ResetOnSpawn = false

	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 420) -- Increased size for new elements
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
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
	title.TextSize = 28
	title.Text = "🎁 Daily Reward"
	title.Parent = mainFrame

	-- Streak counter
	local streakCounter = Instance.new("TextLabel")
	streakCounter.Name = "StreakCounter"
	streakCounter.Size = UDim2.new(1, 0, 0, 30)
	streakCounter.Position = UDim2.new(0, 0, 0, 40)
	streakCounter.BackgroundTransparency = 1
	streakCounter.Font = Enum.Font.Gotham
	streakCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
	streakCounter.TextSize = 18
	streakCounter.Text = "Current Streak: 0 days"
	streakCounter.Parent = mainFrame

	-- Streak multiplier indicator
	local multiplierText = Instance.new("TextLabel")
	multiplierText.Name = "MultiplierText"
	multiplierText.Size = UDim2.new(1, 0, 0, 25)
	multiplierText.Position = UDim2.new(0, 0, 0, 70)
	multiplierText.BackgroundTransparency = 1
	multiplierText.Font = Enum.Font.Gotham
	multiplierText.TextColor3 = Color3.fromRGB(255, 200, 100)
	multiplierText.TextSize = 16
	multiplierText.Text = "Streak Bonus: +0%"
	multiplierText.Parent = mainFrame

	-- Reward Icon
	local rewardIcon = Instance.new("ImageLabel")
	rewardIcon.Name = "RewardIcon"
	rewardIcon.Size = UDim2.new(0, 80, 0, 80)
	rewardIcon.Position = UDim2.new(0.5, -40, 0, 100)
	rewardIcon.BackgroundTransparency = 1
	rewardIcon.Image = "rbxassetid://6031268575" -- Gift box icon
	rewardIcon.Parent = mainFrame

	-- Reward description
	local rewardDesc = Instance.new("TextLabel")
	rewardDesc.Name = "RewardDescription"
	rewardDesc.Size = UDim2.new(1, -40, 0, 60)
	rewardDesc.Position = UDim2.new(0, 20, 0, 190)
	rewardDesc.BackgroundTransparency = 1
	rewardDesc.Font = Enum.Font.GothamBold
	rewardDesc.TextColor3 = Color3.fromRGB(0, 200, 255)
	rewardDesc.TextSize = 20
	rewardDesc.Text = "Your reward is waiting!"
	rewardDesc.TextWrapped = true
	rewardDesc.Parent = mainFrame

	-- Next milestone info
	local nextMilestone = Instance.new("TextLabel")
	nextMilestone.Name = "NextMilestone"
	nextMilestone.Size = UDim2.new(1, -40, 0, 50)
	nextMilestone.Position = UDim2.new(0, 20, 0, 250)
	nextMilestone.BackgroundTransparency = 1
	nextMilestone.Font = Enum.Font.Gotham
	nextMilestone.TextColor3 = Color3.fromRGB(150, 220, 255)
	nextMilestone.TextSize = 16
	nextMilestone.Text = "Next milestone in: 7 days"
	nextMilestone.TextWrapped = true
	nextMilestone.Parent = mainFrame

	-- Claim button
	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0, 200, 0, 50)
	claimButton.Position = UDim2.new(0.5, -100, 1, -120)
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

	-- Glow effect for button
	local buttonUIStroke = Instance.new("UIStroke")
	buttonUIStroke.Name = "ButtonGlow"
	buttonUIStroke.Color = Color3.fromRGB(0, 255, 100)
	buttonUIStroke.Thickness = 2
	buttonUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	buttonUIStroke.Parent = claimButton

	-- Animate button glow
	task.spawn(function()
		while claimButton.Parent do
			for i = 0, 1, 0.05 do
				buttonUIStroke.Transparency = i
				task.wait(0.05)
			end
			for i = 1, 0, -0.05 do
				buttonUIStroke.Transparency = i
				task.wait(0.05)
			end
		end
	end)

	-- Cooldown text
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 0, 30)
	cooldownText.Position = UDim2.new(0, 0, 1, -60)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Font = Enum.Font.Gotham
	cooldownText.TextColor3 = Color3.fromRGB(200, 200, 200)
	cooldownText.TextSize = 14
	cooldownText.Text = ""
	cooldownText.Parent = mainFrame

	-- Streak display bar (visual indicator of streak progress)
	local streakBarBackground = Instance.new("Frame")
	streakBarBackground.Name = "StreakBarBackground"
	streakBarBackground.Size = UDim2.new(0.8, 0, 0, 15)
	streakBarBackground.Position = UDim2.new(0.1, 0, 0, 320)
	streakBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	streakBarBackground.BorderSizePixel = 0
	streakBarBackground.Parent = mainFrame
	
	local streakBarBackgroundCorner = Instance.new("UICorner")
	streakBarBackgroundCorner.CornerRadius = UDim.new(0, 7)
	streakBarBackgroundCorner.Parent = streakBarBackground
	
	local streakBarFill = Instance.new("Frame")
	streakBarFill.Name = "StreakBarFill"
	streakBarFill.Size = UDim2.new(0, 0, 1, 0)
	streakBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	streakBarFill.BorderSizePixel = 0
	streakBarFill.Parent = streakBarBackground
	
	local streakBarFillCorner = Instance.new("UICorner")
	streakBarFillCorner.CornerRadius = UDim.new(0, 7)
	streakBarFillCorner.Parent = streakBarFill

	-- Connect button
	claimButton.MouseButton1Click:Connect(function()
		local success, message, streak, rarity = DailyRewardSystem.giveReward(player)

		if success then
			-- Update UI
			rewardDesc.Text = message
			streakCounter.Text = "Current Streak: " .. streak .. " days"
			
			-- Update streak multiplier text
			local multiplier = DailyRewardSystem.getStreakMultiplier(streak)
			multiplierText.Text = "Streak Bonus: +" .. math.floor((multiplier - 1) * 100) .. "%"
			
			-- Update color based on rarity
			if rarity == "common" then
				rewardDesc.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
			elseif rarity == "uncommon" then
				rewardDesc.TextColor3 = Color3.fromRGB(0, 200, 0) -- Green
			elseif rarity == "rare" then
				rewardDesc.TextColor3 = Color3.fromRGB(0, 100, 255) -- Blue
			elseif rarity == "epic" then
				rewardDesc.TextColor3 = Color3.fromRGB(150, 0, 255) -- Purple
			elseif rarity == "legendary" then
				rewardDesc.TextColor3 = Color3.fromRGB(255, 150, 0) -- Orange
			end

			-- Animate button
			claimButton.Text = "CLAIMED!"
			claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			claimButton.Enabled = false
			
			-- Show celebration effects
			DailyRewardSystem.playCelebrationEffect(mainFrame, rarity)

			-- Close UI after a delay
			task.wait(4)
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

-- Play celebration effect based on reward rarity
function DailyRewardSystem.playCelebrationEffect(mainFrame, rarity)
	-- Create confetti particles
	local numParticles = 0
	local particleColors = {}
	
	if rarity == "common" then
		numParticles = 20
		particleColors = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(200, 200, 200)
		}
	elseif rarity == "uncommon" then
		numParticles = 30
		particleColors = {
			Color3.fromRGB(100, 255, 100),
			Color3.fromRGB(255, 255, 100)
		}
	elseif rarity == "rare" then
		numParticles = 40
		particleColors = {
			Color3.fromRGB(100, 100, 255),
			Color3.fromRGB(100, 200, 255)
		}
	elseif rarity == "epic" then
		numParticles = 60
		particleColors = {
			Color3.fromRGB(150, 0, 255),
			Color3.fromRGB(200, 100, 255)
		}
	elseif rarity == "legendary" then
		numParticles = 100
		particleColors = {
			Color3.fromRGB(255, 150, 0),
			Color3.fromRGB(255, 200, 0)
		}
	end
	
	-- Create confetti particles
	for i = 1, numParticles do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
		particle.BorderSizePixel = 0
		particle.BackgroundColor3 = particleColors[math.random(1, #particleColors)]
		particle.Rotation = math.random(0, 360)
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.Parent = mainFrame
		
		-- Random movement animation
		local endPosX = math.random(-200, 200)
		local endPosY = math.random(-200, 200)
		local duration = math.random(10, 20) / 10
		
		local tween = TweenService:Create(
			particle,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(0.5, endPosX, 0.5, endPosY),
				Rotation = math.random(0, 360),
				BackgroundTransparency = 1
			}
		)
		tween:Play()
		
		task.spawn(function()
			task.wait(duration)
			particle:Destroy()
		end)
	end
	
	-- Gold burst for legendary rewards
	if rarity == "legendary" then
		-- Create gold burst
		local burst = Instance.new("Frame")
		burst.Size = UDim2.new(0, 0, 0, 0) 
		burst.Position = UDim2.new(0.5, 0, 0.5, 0)
		burst.AnchorPoint = Vector2.new(0.5, 0.5)
		burst.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		burst.BorderSizePixel = 0
		burst.Parent = mainFrame
		
		local burstCorner = Instance.new("UICorner") 
		burstCorner.CornerRadius = UDim.new(1, 0)
		burstCorner.Parent = burst
		
		-- Create glow
		local glow = Instance.new("UIGradient")
		glow.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		glow.Parent = burst
		
		-- Animate burst
		local growTween = TweenService:Create(
			burst,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(3, 0, 3, 0)}
		)
		growTween:Play()
		
		local fadeTween = TweenService:Create(
			burst,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 1}
		)
		fadeTween:Play()
		
		task.spawn(function()
			task.wait(1)
			burst:Destroy()
		end)
	end
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
	local streak = DailyRewardSystem.getStreakCount(player)
	local streakCounter = mainFrame.StreakCounter
	streakCounter.Text = "Current Streak: " .. streak .. " days"
	
	-- Update streak multiplier
	local multiplier = DailyRewardSystem.getStreakMultiplier(streak)
	local multiplierText = mainFrame.MultiplierText
	multiplierText.Text = "Streak Bonus: +" .. math.floor((multiplier - 1) * 100) .. "%"
	
	-- Find next milestone
	local nextMilestoneText = mainFrame.NextMilestone
	local nextMilestone = nil
	local daysToNextMilestone = 0
	
	for day, _ in pairs(DailyRewardSystem.milestoneRewards) do
		if day > streak then
			if nextMilestone == nil or day < nextMilestone then
				nextMilestone = day
			end
		end
	end
	
	if nextMilestone then
		daysToNextMilestone = nextMilestone - streak
		nextMilestoneText.Text = "Next milestone in " .. daysToNextMilestone .. " days: " .. 
			DailyRewardSystem.milestoneRewards[nextMilestone].description
	else
		nextMilestoneText.Text = "You've reached all milestones! Keep your streak for bonuses!"
	end
	
	-- Update streak bar
	local targetMilestone = nextMilestone or (streak > 90 and 100 or 7)
	if streak > 90 then targetMilestone = 100 end
	
	local progress = streak / targetMilestone
	local streakBarFill = mainFrame.StreakBarBackground.StreakBarFill
	
	-- Tween the fill to match the current progress
	TweenService:Create(
		streakBarFill,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(math.min(1, progress), 0, 1, 0)}
	):Play()

	-- Update reward description
	local rewardDesc = mainFrame.RewardDescription
	
	-- Check for milestone reward first
	if DailyRewardSystem.milestoneRewards[streak + 1] then
		-- Show upcoming milestone reward
		local upcomingMilestone = DailyRewardSystem.milestoneRewards[streak + 1]
		rewardDesc.Text = "Tomorrow's Special Milestone: " .. upcomingMilestone.description
		rewardDesc.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	else
		-- Show standard reward options
		rewardDesc.Text = "Come back tomorrow for another reward!"
		rewardDesc.TextColor3 = Color3.fromRGB(0, 200, 255)
		
		-- Show the chance for rare rewards
		local rareChance = DailyRewardSystem.getRareRewardChance(streak + 1)
		local chanceText = math.floor(rareChance * 100) .. "% chance for rare rewards!"
		
		rewardDesc.Text = rewardDesc.Text .. "\n" .. chanceText
	end

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
	mainFrame.Position = UDim2.new(0.5, -250, 0, -400)
	mainFrame.Visible = true

	local showTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -250, 0.5, -210)}
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
		{Position = UDim2.new(0.5, -250, 0, -400)}
	)
	hideTween:Play()

	hideTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

-- Create a rewards notification with animated button
function DailyRewardSystem.createRewardNotification(player)
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
	
	-- Add streak indicator if player has a streak
	local streak = DailyRewardSystem.getStreakCount(player)
	if streak > 0 then
		local streakLabel = Instance.new("TextLabel")
		streakLabel.Size = UDim2.new(0, 60, 0, 25)
		streakLabel.Position = UDim2.new(1, 10, 0.5, 0)
		streakLabel.AnchorPoint = Vector2.new(0, 0.5)
		streakLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		streakLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		streakLabel.Font = Enum.Font.GothamBold
		streakLabel.TextSize = 14
		streakLabel.Text = streak .. " 🔥"
		streakLabel.Parent = button
		
		local streakCorner = Instance.new("UICorner")
		streakCorner.CornerRadius = UDim.new(0, 12)
		streakCorner.Parent = streakLabel
	end

	-- Add animation
	task.spawn(function()
		while button.Parent do
			local original = button.Position
			local tween = TweenService:Create(
				button,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Position = original + UDim2.new(0, 0, 0, 10)}
			)
			tween:Play()
			task.wait(2)
		end
	end)

	-- Connect button
	button.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		DailyRewardSystem.showUI(player)
	end)

	screenGui.Parent = player.PlayerGui
	return screenGui
end

-- Initialize the system
function DailyRewardSystem.initialize()
	-- Look for CoreRegistry and NPCSystem first
	task.spawn(function()
		if CoreRegistry then
			NPCSystem = CoreRegistry:tryGetSystem("NPCSystem")
		end
	end)

	-- Update active boosts
	task.spawn(function()
		while task.wait(10) do
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
					if DataStorage and DataStorage.loadedData[userId] then
						DataStorage.loadedData[userId].dailyRewards.multiplierEndTime = 0
					end
				end
			end
			
			-- Check all active satisfaction boosts
			for userId, data in pairs(DailyRewardSystem.activeSatisfactionBoosts) do
				if data.endTime <= currentTime then
					-- Satisfaction boost expired
					local player = Players:GetPlayerByUserId(userId)
					if player then
						local tycoon = player:FindFirstChild("Tycoon")
						if tycoon then
							local currentSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or 75
							tycoon:SetAttribute("MemberSatisfaction", math.max(50, currentSatisfaction - data.amount))
						end
					end

					-- Remove from active boosts
					DailyRewardSystem.activeSatisfactionBoosts[userId] = nil

					-- Update data storage
					if DataStorage and DataStorage.loadedData[userId] then
						DataStorage.loadedData[userId].dailyRewards.satisfactionBoostEndTime = 0
					end
				end
			end
			
			-- Check all active efficiency boosts
			for userId, data in pairs(DailyRewardSystem.activeEfficiencyBoosts) do
				if data.endTime <= currentTime then
					-- Efficiency boost expired
					local player = Players:GetPlayerByUserId(userId)
					if player then
						local tycoon = player:FindFirstChild("Tycoon")
						if tycoon then
							tycoon:SetAttribute("StaffEfficiencyBoost", 0)
						end
					end

					-- Remove from active boosts
					DailyRewardSystem.activeEfficiencyBoosts[userId] = nil

					-- Update data storage
					if DataStorage and DataStorage.loadedData[userId] then
						DataStorage.loadedData[userId].dailyRewards.efficiencyBoostEndTime = 0
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
		task.wait(5)

		-- Check if player can claim reward
		if DailyRewardSystem.canClaimReward(player) then
			-- Show notification
			local notification = Instance.new("Message")
			notification.Text = "Your daily reward is ready to claim!"
			notification.Parent = player
			game:GetService("Debris"):AddItem(notification, 5)

			-- Add button to claim
			DailyRewardSystem.createRewardNotification(player)
		end

		-- Check for active boosts
		local userId = player.UserId
		if DataStorage and DataStorage.loadedData[userId] and DataStorage.loadedData[userId].dailyRewards then
			-- Restore income multiplier
			local multiplierEndTime = DataStorage.loadedData[userId].dailyRewards.multiplierEndTime or 0
			if multiplierEndTime > os.time() then
				-- Restore multiplier
				local multiplier = 1.5 -- Default
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					tycoon:SetAttribute("IncomeMultiplier", multiplier)
				end

				-- Track active multiplier
				DailyRewardSystem.activeMultipliers[userId] = {
					multiplier = multiplier,
					endTime = multiplierEndTime
				}

				-- Notify player
				local notification = Instance.new("Message")
				notification.Text = "Income Multiplier active: " .. multiplier .. "x"
				notification.Parent = player
				game:GetService("Debris"):AddItem(notification, 5)
			end
			
			-- Restore satisfaction boost
			local satBoostEndTime = DataStorage.loadedData[userId].dailyRewards.satisfactionBoostEndTime or 0
			if satBoostEndTime > os.time() then
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					-- Just restore the attribute, the exact amount might vary
					local boostAmount = 15 -- Default
					DailyRewardSystem.activeSatisfactionBoosts[userId] = {
						amount = boostAmount,
						endTime = satBoostEndTime
					}
				end
			end
			
			-- Restore efficiency boost
			local effBoostEndTime = DataStorage.loadedData[userId].dailyRewards.efficiencyBoostEndTime or 0
			if effBoostEndTime > os.time() then
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					local boostAmount = 0.5 -- Default
					tycoon:SetAttribute("StaffEfficiencyBoost", boostAmount)
					
					DailyRewardSystem.activeEfficiencyBoosts[userId] = {
						amount = boostAmount,
						endTime = effBoostEndTime
					}
				end
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

	print("Daily Reward System initialized with streak multipliers and rare rewards")
	return true
end

DailyRewardSystem.initialize()

return DailyRewardSystem
