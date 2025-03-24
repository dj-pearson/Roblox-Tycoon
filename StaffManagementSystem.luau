-- StaffManagementSystem.lua
-- Allows players to hire staff for revenue bonuses
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
	-- Staff positions
	staffPositions = {
		{
			id = "trainer",
			name = "Personal Trainer",
			description = "Increases member satisfaction and retention",
			cost = 5000,
			revenueBonusPercent = 10,
			membershipBonusPercent = 5
		},
		{
			id = "receptionist",
			name = "Receptionist",
			description = "Processes new memberships faster",
			cost = 3000,
			revenueBonusPercent = 5,
			membershipBonusPercent = 10
		},
		{
			id = "manager",
			name = "Gym Manager",
			description = "Improves overall gym efficiency",
			cost = 8000,
			revenueBonusPercent = 15,
			membershipBonusPercent = 15
		},
		{
			id = "maintenance",
			name = "Maintenance Staff",
			description = "Keeps equipment in top condition",
			cost = 4000,
			revenueBonusPercent = 7,
			membershipBonusPercent = 3
		},
		{
			id = "nutritionist",
			name = "Nutritionist",
			description = "Provides specialized plans for VIP members",
			cost = 6000,
			revenueBonusPercent = 12,
			membershipBonusPercent = 7,
			vipBonusPercent = 20
		}
	},

	-- Staff limits
	maxTotalStaff = 15,
	maxPerPosition = 3,

	-- Staff scaling
	staffRevenueBonusPerTier = 0.1, -- +10% bonus per tier

	-- Debug
	debug = true
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Staff System]", ...)
	end
end

-- Module table
local StaffSystem = {
	CONFIG = CONFIG -- Export config for other systems
}

-- Try to load dependencies
local MembershipSystem
pcall(function()
	MembershipSystem = require(ServerScriptService:FindFirstChild("GymMembershipSystem"))
	if MembershipSystem then
		debugPrint("Successfully loaded GymMembershipSystem")
	end
end)

-- Get EventBridge
local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
if not EventBridge then
	EventBridge = Instance.new("Folder")
	EventBridge.Name = "EventBridge"
	EventBridge.Parent = ReplicatedStorage
	debugPrint("Created EventBridge in ReplicatedStorage")
end

-- Find position by ID
function StaffSystem.findPositionInfo(positionId)
	for _, position in ipairs(CONFIG.staffPositions) do
		if position.id == positionId then
			return position
		end
	end
	return nil
end

-- Get total staff count
function StaffSystem.getTotalStaffCount(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local totalCount = 0
	for _, position in ipairs(CONFIG.staffPositions) do
		local count = tycoon:GetAttribute("Staff_" .. position.id) or 0
		totalCount = totalCount + count
	end

	return totalCount
end

-- Get staff count for specific position
function StaffSystem.getStaffCountForPosition(player, positionId)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	return tycoon:GetAttribute("Staff_" .. positionId) or 0
end

-- Calculate revenue bonus from staff
function StaffSystem.calculateRevenueBonus(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local totalBonus = 0
	local currentTier = 1

	-- Get current tier if available
	if MembershipSystem then
		currentTier = MembershipSystem.calculateMembershipTier(player) + 1
	else
		currentTier = tycoon:GetAttribute("MembershipTier") or 0
		currentTier = currentTier + 1 -- Add 1 to avoid multiplying by 0
	end

	-- Calculate bonus from each staff type
	for _, position in ipairs(CONFIG.staffPositions) do
		local count = tycoon:GetAttribute("Staff_" .. position.id) or 0

		-- Base bonus plus tier scaling
		local positionBonus = position.revenueBonusPercent / 100
		local scaledBonus = positionBonus * (1 + ((currentTier - 1) * CONFIG.staffRevenueBonusPerTier))

		totalBonus = totalBonus + (count * scaledBonus)
	end

	-- Store for other systems
	tycoon:SetAttribute("StaffRevenueBonus", totalBonus)

	return totalBonus
end

-- Calculate membership bonus from staff
function StaffSystem.calculateMembershipBonus(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local totalBonus = 0

	-- Calculate bonus from each staff type
	for _, position in ipairs(CONFIG.staffPositions) do
		local count = tycoon:GetAttribute("Staff_" .. position.id) or 0
		local positionBonus = position.membershipBonusPercent / 100

		totalBonus = totalBonus + (count * positionBonus)
	end

	-- Store for other systems
	tycoon:SetAttribute("StaffMembershipBonus", totalBonus)

	return totalBonus
end

-- Calculate VIP bonus from staff
function StaffSystem.calculateVIPBonus(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return 0 end

	local totalBonus = 0

	-- Calculate bonus from each staff type that has vipBonusPercent
	for _, position in ipairs(CONFIG.staffPositions) do
		if position.vipBonusPercent then
			local count = tycoon:GetAttribute("Staff_" .. position.id) or 0
			local positionBonus = position.vipBonusPercent / 100

			totalBonus = totalBonus + (count * positionBonus)
		end
	end

	-- Store for other systems
	tycoon:SetAttribute("StaffVIPBonus", totalBonus)

	return totalBonus
end

-- Hire staff
function StaffSystem.hireStaff(player, positionId)
	if not player then return false, "Invalid player" end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end

	-- Check if player has started tycoon
	if not tycoon:GetAttribute("TycoonStarted") then
		return false, "You need to start your gym first"
	end

	-- Find position information
	local position = StaffSystem.findPositionInfo(positionId)
	if not position then
		return false, "Invalid staff position"
	end

	-- Check if player has reached maximum total staff
	local totalStaff = StaffSystem.getTotalStaffCount(player)
	if totalStaff >= CONFIG.maxTotalStaff then
		return false, "Maximum staff limit reached"
	end

	-- Check if player has reached maximum for this position
	local positionCount = StaffSystem.getStaffCountForPosition(player, positionId)
	if positionCount >= CONFIG.maxPerPosition then
		return false, "Maximum " .. position.name .. " limit reached"
	end

	-- Check if player has enough cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then
		return false, "Cash not found"
	end

	if leaderstats.Cash.Value < position.cost then
		return false, "Not enough cash"
	end

	-- Deduct cost
	leaderstats.Cash.Value = leaderstats.Cash.Value - position.cost

	-- Update staff count
	local newCount = positionCount + 1
	tycoon:SetAttribute("Staff_" .. positionId, newCount)

	-- Update total count attribute
	tycoon:SetAttribute("StaffCount", totalStaff + 1)

	-- Recalculate bonuses
	StaffSystem.calculateRevenueBonus(player)
	StaffSystem.calculateMembershipBonus(player)
	StaffSystem.calculateVIPBonus(player)

	-- Fire event
	local staffHiredEvent = EventBridge:FindFirstChild("StaffHired")
	if not staffHiredEvent then
		staffHiredEvent = Instance.new("RemoteEvent")
		staffHiredEvent.Name = "StaffHired"
		staffHiredEvent.Parent = EventBridge
	end

	staffHiredEvent:FireClient(player, {
		positionId = positionId,
		name = position.name,
		count = newCount,
		totalStaff = totalStaff + 1
	})

	-- Notify player
	local message = Instance.new("Message")
	message.Text = "Hired " .. position.name .. "!\nYou now have " .. newCount .. " in this position."
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 3)

	debugPrint(player.Name .. " hired " .. position.name .. " (now has " .. newCount .. ")")

	return true, "Successfully hired " .. position.name
end

-- Initialize player
function StaffSystem.initializePlayer(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
	end

	-- Initialize attributes for tracking staff
	for _, position in ipairs(CONFIG.staffPositions) do
		if not tycoon:GetAttribute("Staff_" .. position.id) then
			tycoon:SetAttribute("Staff_" .. position.id, 0)
		end
	end

	-- Initialize total count if needed
	if not tycoon:GetAttribute("StaffCount") then
		tycoon:SetAttribute("StaffCount", StaffSystem.getTotalStaffCount(player))
	end

	-- Initialize bonus attributes
	if not tycoon:GetAttribute("StaffRevenueBonus") then
		tycoon:SetAttribute("StaffRevenueBonus", 0)
	end

	if not tycoon:GetAttribute("StaffMembershipBonus") then
		tycoon:SetAttribute("StaffMembershipBonus", 0)
	end

	if not tycoon:GetAttribute("StaffVIPBonus") then
		tycoon:SetAttribute("StaffVIPBonus", 0)
	end

	debugPrint("Initialized staff data for " .. player.Name)

	return true
end

-- Initialize the system
function StaffSystem.initialize()
	debugPrint("Initializing Staff System")

	-- Create remote functions and events
	local hireStaffFunction = ReplicatedStorage:FindFirstChild("HireStaffFunction")
	if not hireStaffFunction then
		hireStaffFunction = Instance.new("RemoteFunction")
		hireStaffFunction.Name = "HireStaffFunction"
		hireStaffFunction.Parent = ReplicatedStorage
	end

	-- Set function handler
	hireStaffFunction.OnServerInvoke = function(player, positionId)
		local success, message = StaffSystem.hireStaff(player, positionId)
		return success, message
	end

	-- Create event for other systems
	if not EventBridge:FindFirstChild("StaffHired") then
		local staffHiredEvent = Instance.new("RemoteEvent")
		staffHiredEvent.Name = "StaffHired"
		staffHiredEvent.Parent = EventBridge
	end

	-- Create function to get available positions
	local getStaffPositionsFunction = ReplicatedStorage:FindFirstChild("GetStaffPositionsFunction")
	if not getStaffPositionsFunction then
		getStaffPositionsFunction = Instance.new("RemoteFunction")
		getStaffPositionsFunction.Name = "GetStaffPositionsFunction"
		getStaffPositionsFunction.Parent = ReplicatedStorage
	end

	-- Set function handler for position info
	getStaffPositionsFunction.OnServerInvoke = function(player)
		-- Return deep copy of positions to prevent modification
		local positionsCopy = {}

		for i, position in ipairs(CONFIG.staffPositions) do
			positionsCopy[i] = table.clone(position)
			positionsCopy[i].currentCount = StaffSystem.getStaffCountForPosition(player, position.id)
		end

		return positionsCopy, StaffSystem.getTotalStaffCount(player), CONFIG.maxTotalStaff
	end

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			StaffSystem.initializePlayer(player)
		end)
	end

	-- Connect to player events
	Players.PlayerAdded:Connect(function(player)
		task.delay(5, function()
			StaffSystem.initializePlayer(player)
		end)
	end)

	-- Periodic updates
	task.spawn(function()
		while true do
			task.wait(10) -- Update every 10 seconds

			for _, player in pairs(Players:GetPlayers()) do
				task.spawn(function()
					StaffSystem.calculateRevenueBonus(player)
					StaffSystem.calculateMembershipBonus(player)
					StaffSystem.calculateVIPBonus(player)
				end)
			end
		end
	end)

	-- Connect to MembershipSystem if available
	if MembershipSystem then
		-- Hook into MembershipSystem to apply staff bonuses
		if MembershipSystem.calculateHourlyRevenue then
			local originalRevenue = MembershipSystem.calculateHourlyRevenue

			MembershipSystem.calculateHourlyRevenue = function(player)
				local baseRevenue = originalRevenue(player)

				-- Apply staff bonus
				local staffBonus = StaffSystem.calculateRevenueBonus(player)
				return math.floor(baseRevenue * (1 + staffBonus))
			end

			debugPrint("Hooked into MembershipSystem revenue calculation")
		end
	end

	debugPrint("Staff System initialized")
	return true
end

-- Initialize the system
StaffSystem.initialize()

-- Return the module
return StaffSystem