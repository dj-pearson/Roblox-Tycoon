-- Enhanced GymMembershipSystem.lua
-- More dynamic membership system with randomized growth
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
	-- Base membership calculations
	minMembersPerEquipment = 1,   -- Minimum members gained per equipment
	maxMembersPerEquipment = 10,  -- Maximum members gained per equipment
	membershipFeeBase = 15,       -- Revenue per regular member per interval
	vipMembershipFeeBase = 50,    -- Revenue per VIP member per interval

	-- Tiered scaling (affects member cap and acquisition rate)
	tierThresholds = {
		[1] = 25,   -- First membership tier threshold (equipment count)
		[2] = 50,   -- Second threshold
		[3] = 100,  -- Third threshold
		[4] = 200,  -- Fourth threshold
		[5] = 300   -- Fifth threshold
	},

	tierMultipliers = {
		[0] = 1.0,  -- Base tier multiplier
		[1] = 1.2,  -- Tier 1 multiplier
		[2] = 1.5,  -- Tier 2 multiplier
		[3] = 1.8,  -- Tier 3 multiplier
		[4] = 2.2,  -- Tier 4 multiplier
		[5] = 3.0   -- Tier 5 multiplier
	},

	-- VIP members
	vipPercentBase = 0.05,        -- Base percentage of VIP members (5%)
	vipPercentIncreasePerTier = 0.02, -- How much VIP percentage increases per tier

	-- Revenue calculation
	revenueInterval = 60,         -- Generate revenue every 60 seconds
	incomeDisplayUpdateInterval = 10, -- Update income displays every 10 seconds

	-- Special events
	specialEventBoostMultiplier = 1.5, -- Membership boost during special events
	specialEventDuration = 300,    -- Duration of special events (5 min)
	specialEventCooldown = 1800,   -- Cooldown between events (30 min)

	-- Debug
	debug = true                  -- Show debug messages
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Membership System]", ...)
	end
end

-- Module table
local MembershipSystem = {
	CONFIG = CONFIG, -- Export config for other systems
	memberCache = {}, -- Cache for stored membership data
}

-- Calculate current membership tier based on equipment count
function MembershipSystem.calculateMembershipTier(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0

	-- Determine tier based on equipment thresholds
	for tier = 5, 1, -1 do
		if equipmentCount >= CONFIG.tierThresholds[tier] then
			return tier
		end
	end

	return 0 -- Base tier
end

-- Calculate total membership count with randomization
function MembershipSystem.calculateMembershipCount(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local userId = player.UserId

	-- Initialize membership cache if needed
	if not MembershipSystem.memberCache[userId] then
		MembershipSystem.memberCache[userId] = {
			equipmentCount = 0,
			memberCount = 0,
			lastEquipmentCount = 0
		}
	end

	local cache = MembershipSystem.memberCache[userId]
	local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0

	-- If equipment count has changed, add new members
	if equipmentCount > cache.lastEquipmentCount then
		local newEquipmentCount = equipmentCount - cache.lastEquipmentCount
		local currentTier = MembershipSystem.calculateMembershipTier(player)
		local tierMultiplier = CONFIG.tierMultipliers[currentTier]

		-- Add random number of members for each new equipment piece
		for i = 1, newEquipmentCount do
			local baseMembers = math.random(
				CONFIG.minMembersPerEquipment, 
				CONFIG.maxMembersPerEquipment
			)

			-- Apply tier multiplier
			local adjustedMembers = math.floor(baseMembers * tierMultiplier)
			cache.memberCount = cache.memberCount + adjustedMembers

			debugPrint(player.Name .. " gained " .. adjustedMembers .. " new members from equipment")
		end

		cache.lastEquipmentCount = equipmentCount
	end

	-- Apply any special modifiers from other systems
	local specialBonus = tycoon:GetAttribute("MembershipBonus") or 0
	local memberCount = math.floor(cache.memberCount * (1 + specialBonus))

	-- Store the value for other systems to use
	tycoon:SetAttribute("MembershipCount", memberCount)

	return memberCount
end

-- Calculate VIP membership count
function MembershipSystem.calculateVIPMemberCount(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local totalMembers = MembershipSystem.calculateMembershipCount(player)
	local currentTier = MembershipSystem.calculateMembershipTier(player)

	-- VIP percentage increases with tier
	local vipPercentage = CONFIG.vipPercentBase + (currentTier * CONFIG.vipPercentIncreasePerTier)

	local vipCount = math.floor(totalMembers * vipPercentage)

	-- Store for other systems
	tycoon:SetAttribute("VIPMemberCount", vipCount)

	return vipCount
end

-- Calculate hourly revenue from memberships
function MembershipSystem.calculateHourlyRevenue(player)
	local totalMembers = MembershipSystem.calculateMembershipCount(player)
	local vipMembers = MembershipSystem.calculateVIPMemberCount(player)
	local regularMembers = totalMembers - vipMembers

	-- Calculate individual revenue components
	local regularRevenue = regularMembers * CONFIG.membershipFeeBase
	local vipRevenue = vipMembers * CONFIG.vipMembershipFeeBase

	local hourlyRevenue = regularRevenue + vipRevenue

	-- Apply special event multiplier if active
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon and tycoon:GetAttribute("SpecialEventActive") then
		hourlyRevenue = hourlyRevenue * CONFIG.specialEventBoostMultiplier
	end

	-- Store for other systems
	if tycoon then
		tycoon:SetAttribute("HourlyRevenue", math.floor(hourlyRevenue))
	end

	return math.floor(hourlyRevenue)
end

-- Calculate revenue per interval
function MembershipSystem.calculateIntervalRevenue(player)
	local hourlyRevenue = MembershipSystem.calculateHourlyRevenue(player)
	local intervalRevenue = hourlyRevenue * (CONFIG.revenueInterval / 3600)
	return math.floor(intervalRevenue)
end

-- Generate income for a player
function MembershipSystem.generateIncome(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	-- Only generate income if player has started their tycoon
	if not tycoon:GetAttribute("TycoonStarted") then return 0 end

	-- Calculate income for this interval
	local income = MembershipSystem.calculateIntervalRevenue(player)

	-- Add to accrued dues
	local currentDues = tycoon:GetAttribute("AccruedDues") or 0
	tycoon:SetAttribute("AccruedDues", currentDues + income)

	-- Update displays if FrontDeskSystem is available
	local FrontDeskSystem = nil
	pcall(function()
		FrontDeskSystem = require(ServerScriptService:FindFirstChild("FrontDeskSystem"))
	end)

	if FrontDeskSystem and FrontDeskSystem.updateFrontDeskDisplay then
		FrontDeskSystem.updateFrontDeskDisplay(player)
	end

	-- Fire event for other systems
	local event = ReplicatedStorage:FindFirstChild("EventBridge")
	if event then
		local incomeEvent = event:FindFirstChild("IncomeGenerated")
		if incomeEvent then
			incomeEvent:FireClient(player, income)
		end
	end

	return income
end

-- Start a special event for a player
function MembershipSystem.startSpecialEvent(player, eventType)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Set special event flag
	tycoon:SetAttribute("SpecialEventActive", true)
	tycoon:SetAttribute("SpecialEventType", eventType or "Membership Drive")
	tycoon:SetAttribute("SpecialEventEndTime", os.time() + CONFIG.specialEventDuration)

	-- Notify player
	local message = Instance.new("Message")
	message.Text = "SPECIAL EVENT: " .. (eventType or "Membership Drive") .. 
		"\nMembership income boosted by " .. 
		math.floor((CONFIG.specialEventBoostMultiplier - 1) * 100) .. "% for " .. 
		(CONFIG.specialEventDuration / 60) .. " minutes!"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)

	-- Schedule event end
	task.delay(CONFIG.specialEventDuration, function()
		if player and player.Parent then
			MembershipSystem.endSpecialEvent(player)
		end
	end)

	debugPrint("Started special event for " .. player.Name .. ": " .. (eventType or "Membership Drive"))
	return true
end

-- End a special event
function MembershipSystem.endSpecialEvent(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Event already ended
	if not tycoon:GetAttribute("SpecialEventActive") then return false end

	-- Reset event flags
	tycoon:SetAttribute("SpecialEventActive", false)
	tycoon:SetAttribute("SpecialEventType", nil)
	tycoon:SetAttribute("SpecialEventEndTime", nil)

	-- Set cooldown
	tycoon:SetAttribute("SpecialEventCooldown", os.time() + CONFIG.specialEventCooldown)

	-- Notify player
	local message = Instance.new("Message")
	message.Text = "Special event has ended. Regular income rates have resumed."
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)

	debugPrint("Ended special event for " .. player.Name)
	return true
end

-- Update membership displays
function MembershipSystem.updateMembershipDisplays(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return end

	-- Calculate current values
	local memberCount = MembershipSystem.calculateMembershipCount(player)
	local vipCount = MembershipSystem.calculateVIPMemberCount(player)
	local hourlyRevenue = MembershipSystem.calculateHourlyRevenue(player)
	local currentTier = MembershipSystem.calculateMembershipTier(player)

	-- Update attributes for UI and other systems
	tycoon:SetAttribute("MembershipCount", memberCount)
	tycoon:SetAttribute("VIPMemberCount", vipCount)
	tycoon:SetAttribute("HourlyRevenue", hourlyRevenue)
	tycoon:SetAttribute("MembershipTier", currentTier)

	-- Calculate and store next tier threshold if not at max
	if currentTier < 5 then
		local nextThreshold = CONFIG.tierThresholds[currentTier + 1]
		tycoon:SetAttribute("NextTierThreshold", nextThreshold)
	else
		tycoon:SetAttribute("NextTierThreshold", nil)
	end

	-- Send update to client if there's a remote event for this
	local event = ReplicatedStorage:FindFirstChild("EventBridge")
	if event then
		local updateEvent = event:FindFirstChild("MembershipUpdated")
		if updateEvent then
			updateEvent:FireClient(player, {
				memberCount = memberCount,
				vipCount = vipCount,
				hourlyRevenue = hourlyRevenue,
				currentTier = currentTier
			})
		end
	end
end

-- Initialize a player's membership data
function MembershipSystem.initializePlayer(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		-- Create tycoon value if it doesn't exist
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
	end

	-- Set default attributes if they don't exist
	if not tycoon:GetAttribute("MembershipCount") then
		tycoon:SetAttribute("MembershipCount", 0)
	end

	if not tycoon:GetAttribute("VIPMemberCount") then
		tycoon:SetAttribute("VIPMemberCount", 0)
	end

	if not tycoon:GetAttribute("HourlyRevenue") then
		tycoon:SetAttribute("HourlyRevenue", 0)
	end

	if not tycoon:GetAttribute("MembershipTier") then
		tycoon:SetAttribute("MembershipTier", 0)
	end

	if not tycoon:GetAttribute("AccruedDues") then
		tycoon:SetAttribute("AccruedDues", 0)
	end

	-- Initialize member cache
	local userId = player.UserId
	MembershipSystem.memberCache[userId] = {
		memberCount = tycoon:GetAttribute("MembershipCount") or 0,
		lastEquipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
	}

	-- Update displays with initial values
	MembershipSystem.updateMembershipDisplays(player)

	debugPrint("Initialized membership data for " .. player.Name)

	return true
end

-- Handle tile purchase
function MembershipSystem.onTilePurchased(player, tileId)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Mark tycoon as started if this is the first purchase
	if not tycoon:GetAttribute("TycoonStarted") then
		tycoon:SetAttribute("TycoonStarted", true)
	end

	-- Check if membership tier changed
	local oldTier = tycoon:GetAttribute("MembershipTier") or 0
	MembershipSystem.updateMembershipDisplays(player)
	local newTier = tycoon:GetAttribute("MembershipTier") or 0

	-- Notify player if tier increased
	if newTier > oldTier then
		-- Create notification
		local message = Instance.new("Message")
		message.Text = "MEMBERSHIP TIER UP!\nYour gym is now Tier " .. newTier .. 
			"\nNew membership multiplier: x" .. CONFIG.tierMultipliers[newTier]
		message.Parent = player

		game:GetService("Debris"):AddItem(message, 5)

		-- Fire event for other systems
		local event = ReplicatedStorage:FindFirstChild("EventBridge")
		if event then
			local tierEvent = event:FindFirstChild("MembershipTierUp")
			if tierEvent then
				tierEvent:FireClient(player, newTier)
			end
		end

		debugPrint(player.Name .. " increased to membership tier " .. newTier)
	end

	return true
end

-- Start income generation
function MembershipSystem.startIncomeGeneration()
	-- Generate income loop
	task.spawn(function()
		while true do
			task.wait(CONFIG.revenueInterval)

			for _, player in pairs(Players:GetPlayers()) do
				task.spawn(function()
					local income = MembershipSystem.generateIncome(player)
					if income > 0 then
						debugPrint(player.Name .. " earned $" .. income .. " from memberships")
					end
				end)
			end
		end
	end)

	-- Update displays loop (more frequent than income generation)
	task.spawn(function()
		while true do
			task.wait(CONFIG.incomeDisplayUpdateInterval)

			for _, player in pairs(Players:GetPlayers()) do
				task.spawn(function()
					MembershipSystem.updateMembershipDisplays(player)
				end)
			end
		end
	end)

	-- Special event manager
	task.spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds

			for _, player in pairs(Players:GetPlayers()) do
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon and tycoon:GetAttribute("TycoonStarted") then

					-- Check if event is active and update if needed
					if tycoon:GetAttribute("SpecialEventActive") then
						local endTime = tycoon:GetAttribute("SpecialEventEndTime") or 0
						if os.time() >= endTime then
							MembershipSystem.endSpecialEvent(player)
						end
					end

					-- Random chance to start special event if not on cooldown
					if not tycoon:GetAttribute("SpecialEventActive") then
						local cooldownTime = tycoon:GetAttribute("SpecialEventCooldown") or 0
						if os.time() >= cooldownTime then
							-- 1% chance every 30 seconds
							if math.random(1, 100) <= 1 then
								MembershipSystem.startSpecialEvent(player)
							end
						end
					end
				end
			end
		end
	end)

	debugPrint("Started income generation")
	return true
end

-- Initialize the system
function MembershipSystem.initialize()
	debugPrint("Initializing Membership System")

	-- Create required events in EventBridge
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not eventBridge then
		eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
	end

	local events = {
		"IncomeGenerated",
		"MembershipUpdated",
		"MembershipTierUp"
	}

	for _, eventName in ipairs(events) do
		if not eventBridge:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = eventBridge
		end
	end

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			MembershipSystem.initializePlayer(player)
		end)
	end

	-- Setup player added/removed events
	Players.PlayerAdded:Connect(function(player)
		task.wait(3) -- Wait for character to load
		MembershipSystem.initializePlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Clear cache for player
		MembershipSystem.memberCache[player.UserId] = nil
	end)

	-- Start income generation
	MembershipSystem.startIncomeGeneration()

	debugPrint("Membership System initialized")
	return true
end

-- Connect to buy tile events via GymTycoonConnector
if _G.GymTycoonConnector then
	local originalTilePurchased = _G.GymTycoonConnector.onTilePurchased

	_G.GymTycoonConnector.onTilePurchased = function(player, tileId)
		-- Call original function if it exists
		if originalTilePurchased then
			originalTilePurchased(player, tileId)
		end

		-- Then handle membership updates
		MembershipSystem.onTilePurchased(player, tileId)
	end

	debugPrint("Connected to GymTycoonConnector")
end

-- Initialize the system
MembershipSystem.initialize()

-- Return the public API
return MembershipSystem