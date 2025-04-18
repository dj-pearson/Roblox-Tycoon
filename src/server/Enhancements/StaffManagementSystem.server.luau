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
			membershipBonusPercent = 5,
			specializations = {
				"strength", "cardio", "functional", "wellness"
			},
			specializationBonus = {
				strength = {
					description = "Strength-focused training",
					bonusType = "revenue",
					bonusValue = 0.08
				},
				cardio = {
					description = "Cardio-focused training",
					bonusType = "membership",
					bonusValue = 0.12
				},
				functional = {
					description = "Functional fitness training",
					bonusType = "satisfaction",
					bonusValue = 0.15
				},
				wellness = {
					description = "Mind-body wellness",
					bonusType = "retention",
					bonusValue = 0.10
				}
			}
		},
		{
			id = "receptionist",
			name = "Receptionist",
			description = "Processes new memberships faster",
			cost = 3000,
			revenueBonusPercent = 5,
			membershipBonusPercent = 10,
			specializations = {
				"sales", "hospitality", "organization"
			},
			specializationBonus = {
				sales = {
					description = "Sales-focused approach",
					bonusType = "vip_chance",
					bonusValue = 0.07
				},
				hospitality = {
					description = "Hospitality-focused service",
					bonusType = "satisfaction",
					bonusValue = 0.10
				},
				organization = {
					description = "Organizational expertise",
					bonusType = "efficiency",
					bonusValue = 0.08
				}
			}
		},
		{
			id = "manager",
			name = "Gym Manager",
			description = "Improves overall gym efficiency",
			cost = 8000,
			revenueBonusPercent = 15,
			membershipBonusPercent = 15,
			specializations = {
				"operations", "marketing", "leadership"
			},
			specializationBonus = {
				operations = {
					description = "Operations management",
					bonusType = "efficiency",
					bonusValue = 0.15
				},
				marketing = {
					description = "Marketing expertise",
					bonusType = "membership",
					bonusValue = 0.20
				},
				leadership = {
					description = "Leadership development",
					bonusType = "staff_xp",
					bonusValue = 0.25
				}
			}
		},
		{
			id = "maintenance",
			name = "Maintenance Staff",
			description = "Keeps equipment in top condition",
			cost = 4000,
			revenueBonusPercent = 7,
			membershipBonusPercent = 3,
			specializations = {
				"repair", "cleaning", "technical"
			},
			specializationBonus = {
				repair = {
					description = "Equipment repair",
					bonusType = "equipment_lifespan",
					bonusValue = 0.20
				},
				cleaning = {
					description = "Facility cleaning",
					bonusType = "satisfaction",
					bonusValue = 0.10
				},
				technical = {
					description = "Technical maintenance",
					bonusType = "equipment_quality",
					bonusValue = 0.15
				}
			}
		},
		{
			id = "nutritionist",
			name = "Nutritionist",
			description = "Provides specialized plans for VIP members",
			cost = 6000,
			revenueBonusPercent = 12,
			membershipBonusPercent = 7,
			vipBonusPercent = 20,
			specializations = {
				"weightloss", "muscle", "wellness", "sports"
			},
			specializationBonus = {
				weightloss = {
					description = "Weight loss programs",
					bonusType = "vip_conversion",
					bonusValue = 0.15
				},
				muscle = {
					description = "Muscle building nutrition",
					bonusType = "vip_revenue",
					bonusValue = 0.20
				},
				wellness = {
					description = "Holistic wellness",
					bonusType = "retention",
					bonusValue = 0.10
				},
				sports = {
					description = "Sports nutrition",
					bonusType = "vip_chance",
					bonusValue = 0.12
				}
			}
		}
	},

	-- Staff limits
	maxTotalStaff = 15,
	maxPerPosition = 3,

	-- Staff scaling
	staffRevenueBonusPerTier = 0.1, -- +10% bonus per tier
	
	-- Skill system
	skillLevels = {
		{ -- Level 1 (Initial level)
			name = "Beginner",
			multiplier = 1.0,
			xpRequired = 0
		},
		{ -- Level 2
			name = "Trained",
			multiplier = 1.25,
			xpRequired = 1000
		},
		{ -- Level 3
			name = "Professional",
			multiplier = 1.5,
			xpRequired = 3000
		},
		{ -- Level 4
			name = "Expert",
			multiplier = 1.75,
			xpRequired = 7500
		},
		{ -- Level 5
			name = "Master",
			multiplier = 2.0,
			xpRequired = 15000
		}
	},
	
	-- Training settings
	trainingFacilityBuildCost = 25000,
	trainingSessionCost = {
		-- Cost per staff level
		[1] = 500,
		[2] = 1000,
		[3] = 2500,
		[4] = 5000,
		[5] = 0 -- Max level
	},
	trainingSessionDuration = 3600, -- 1 hour in seconds
	trainingSessionXP = {
		-- XP gained per session by level
		[1] = 250,
		[2] = 400,
		[3] = 750,
		[4] = 1200
	},
	trainingBonusPerFacilityLevel = 0.25, -- Each facility level adds 25% XP
	maxTrainingFacilityLevel = 3,
	
	-- Specialization settings
	specializationUnlockLevel = 3, -- Staff must be level 3 to select specialization
	specializationChangeCost = 2500, -- Cost to change specialization
	
	-- Staff passive XP gain
	passiveXpInterval = 1800, -- 30 minutes
	passiveXpAmount = {
		-- Base XP earned passively per level
		[1] = 25,
		[2] = 20,
		[3] = 15, 
		[4] = 10
	},
	
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
	CONFIG = CONFIG, -- Export config for other systems
	staffData = {}, -- Format: {userId = {positionId = {staffMembers = {{}}}}}
	activeTrainingSessions = {} -- Track active training sessions
}

-- Try to load dependencies
local MembershipSystem
pcall(function()
	MembershipSystem = require(ServerScriptService:FindFirstChild("GymMembershipSystem"))
	if MembershipSystem then
		debugPrint("Successfully loaded GymMembershipSystem")
	end
end)

-- Load DataManager for data persistence if available
local DataManager
pcall(function()
	DataManager = require(ServerScriptService:FindFirstChild("GymTycoonDataManager")) or
		require(ServerScriptService:FindFirstChild("DataManager"))
	if DataManager then
		debugPrint("Successfully loaded DataManager")
	end
end)

-- Get CoreRegistry if available
local CoreRegistry
pcall(function()
	CoreRegistry = require(ServerScriptService:FindFirstChild("CoreRegistry"))
	if CoreRegistry then
		debugPrint("Successfully loaded CoreRegistry")
	end
end)

-- Try to load EventBridge properly
local EventBridge
if CoreRegistry then
	EventBridge = CoreRegistry.getSystem("EventBridge")
else
	EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not EventBridge then
		EventBridge = Instance.new("Folder")
		EventBridge.Name = "EventBridge"
		EventBridge.Parent = ReplicatedStorage
		debugPrint("Created EventBridge in ReplicatedStorage")
	end
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

	-- Create new staff member
	StaffSystem:createStaffMember(player, positionId)

	return true, "Successfully hired " .. position.name
end

-- Create a new staff member when hired
function StaffSystem:createStaffMember(player, positionId)
	if not player or not positionId then return nil end
	
	local userId = player.UserId
	
	-- Initialize player data structure if needed
	if not self.staffData[userId] then
		self.staffData[userId] = {}
	end
	
	-- Initialize position data structure if needed
	if not self.staffData[userId][positionId] then
		self.staffData[userId][positionId] = {
			staffMembers = {}
		}
	end
	
	-- Create new staff member
	local staffMember = {
		id = os.time() .. "_" .. #self.staffData[userId][positionId].staffMembers + 1, -- Unique ID
		name = self:generateStaffName(positionId),
		level = 1, -- Start at level 1
		xp = 0, -- Start with 0 XP
		skillMultiplier = CONFIG.skillLevels[1].multiplier, -- Initial multiplier
		specialization = nil, -- No specialization initially
		hireTime = os.time(), -- Track when hired
		lastXpGain = os.time(), -- For passive XP
		inTraining = false -- Training status
	}
	
	-- Add to staff collection
	table.insert(self.staffData[userId][positionId].staffMembers, staffMember)
	
	-- Save the data
	self:saveStaffData(player)
	
	debugPrint("Created new " .. positionId .. " for " .. player.Name .. " with ID " .. staffMember.id)
	
	return staffMember
end

-- Generate a random staff name based on position
function StaffSystem:generateStaffName(positionId)
	local firstNames = {"James", "John", "Alex", "Sarah", "Emma", "Michael", "David", "Lisa", "Jessica", "Mark", "Olivia", "Daniel", "Ryan", "Karen", "Carlos", "Maria", "Sofia", "Luis", "Tom", "Ava"}
	local lastNames = {"Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson", "Clark"}
	
	-- Add some position-specific names
	if positionId == "trainer" then
		table.insert(firstNames, "Max")
		table.insert(firstNames, "Chad")
		table.insert(firstNames, "Steve")
		table.insert(firstNames, "Brooke")
	elseif positionId == "nutritionist" then
		table.insert(firstNames, "Kale")
		table.insert(firstNames, "Quinoa")
		table.insert(lastNames, "Greens")
	elseif positionId == "manager" then
		table.insert(firstNames, "Morgan")
		table.insert(lastNames, "Powers")
	end
	
	local firstName = firstNames[math.random(1, #firstNames)]
	local lastName = lastNames[math.random(1, #lastNames)]
	
	return firstName .. " " .. lastName
end

-- Get staff members for a specific position
function StaffSystem:getStaffMembers(player, positionId)
	if not player or not positionId then return {} end
	
	local userId = player.UserId
	
	if not self.staffData[userId] or not self.staffData[userId][positionId] then
		return {}
	end
	
	return self.staffData[userId][positionId].staffMembers
end

-- Get all staff members for a player
function StaffSystem:getAllStaffMembers(player)
	if not player then return {} end
	
	local userId = player.UserId
	local allStaff = {}
	
	if not self.staffData[userId] then
		return {}
	end
	
	for positionId, positionData in pairs(self.staffData[userId]) do
		for _, staffMember in ipairs(positionData.staffMembers) do
			table.insert(allStaff, {
				positionId = positionId,
				staffMember = staffMember
			})
		end
	end
	
	return allStaff
end

-- Add XP to a staff member
function StaffSystem:addStaffXP(player, positionId, staffId, xpAmount)
	if not player or not positionId or not staffId or not xpAmount then return false end
	
	local userId = player.UserId
	
	if not self.staffData[userId] or 
	   not self.staffData[userId][positionId] then
		return false
	end
	
	-- Find the staff member
	local staffMembers = self.staffData[userId][positionId].staffMembers
	local staffMember = nil
	local staffIndex = nil
	
	for i, staff in ipairs(staffMembers) do
		if staff.id == staffId then
			staffMember = staff
			staffIndex = i
			break
		end
	end
	
	if not staffMember then
		return false
	end
	
	-- Add XP
	staffMember.xp = staffMember.xp + xpAmount
	staffMember.lastXpGain = os.time()
	
	-- Check for level up
	if staffMember.level < #CONFIG.skillLevels then
		local nextLevel = staffMember.level + 1
		local requiredXP = CONFIG.skillLevels[nextLevel].xpRequired
		
		if staffMember.xp >= requiredXP then
			-- Level up!
			staffMember.level = nextLevel
			staffMember.skillMultiplier = CONFIG.skillLevels[nextLevel].multiplier
			
			-- Show notification to player
			local message = Instance.new("Message")
			local position = self:findPositionInfo(positionId)
			message.Text = "LEVEL UP: " .. staffMember.name .. " (" .. position.name .. ")" ..
				"\nNow level " .. nextLevel .. " - " .. CONFIG.skillLevels[nextLevel].name
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)
			
			-- Fire level up event
			if EventBridge then
				local levelUpEvent = EventBridge:FindFirstChild("StaffLevelUp")
				if not levelUpEvent then
					if typeof(EventBridge.fireEvent) == "function" then
						EventBridge:fireEvent("StaffLevelUp", player, {
							staffName = staffMember.name,
							positionId = positionId,
							newLevel = nextLevel,
							levelName = CONFIG.skillLevels[nextLevel].name
						})
					end
				else
					levelUpEvent:FireClient(player, {
						staffName = staffMember.name,
						positionId = positionId,
						newLevel = nextLevel,
						levelName = CONFIG.skillLevels[nextLevel].name
					})
				end
			end
			
			debugPrint(staffMember.name .. " leveled up to level " .. nextLevel)
		end
	end
	
	-- Update data
	self.staffData[userId][positionId].staffMembers[staffIndex] = staffMember
	
	-- Save data
	self:saveStaffData(player)
	
	return true
end

-- Save staff data to DataManager or player attributes
function StaffSystem:saveStaffData(player)
	if not player then return false end
	
	local userId = player.UserId
	
	-- Skip if no data
	if not self.staffData[userId] then
		return false
	end
	
	-- Use DataManager if available
	if DataManager then
		if DataManager.updatePlayerData then
			DataManager.updatePlayerData(player, "staffData", self.staffData[userId])
			debugPrint("Saved staff data to DataManager for " .. player.Name)
			return true
		elseif DataManager.updateData then
			DataManager.updateData(player, "staffData", self.staffData[userId])
			debugPrint("Saved staff data to DataManager for " .. player.Name)
			return true
		end
	end
	
	-- Fallback to player attributes
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end
	
	-- Convert to JSON string since attributes can't store complex tables
	local success, encodedData = pcall(function()
		return game:GetService("HttpService"):JSONEncode(self.staffData[userId])
	end)
	
	if success then
		tycoon:SetAttribute("StaffData", encodedData)
		debugPrint("Saved staff data to player attributes for " .. player.Name)
		return true
	else
		warn("Failed to encode staff data for " .. player.Name)
		return false
	end
end

-- Load staff data from DataManager or player attributes
function StaffSystem:loadStaffData(player)
	if not player then return false end
	
	local userId = player.UserId
	local staffData = nil
	
	-- Try DataManager first
	if DataManager then
		if DataManager.getPlayerData then
			staffData = DataManager.getPlayerData(player, "staffData")
		elseif DataManager.getData then
			staffData = DataManager.getData(player, "staffData")
		end
		
		if staffData then
			self.staffData[userId] = staffData
			debugPrint("Loaded staff data from DataManager for " .. player.Name)
			return true
		end
	end
	
	-- Fallback to player attributes
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end
	
	local encodedData = tycoon:GetAttribute("StaffData")
	if not encodedData then return false end
	
	local success, decodedData = pcall(function()
		return game:GetService("HttpService"):JSONDecode(encodedData)
	end)
	
	if success then
		self.staffData[userId] = decodedData
		debugPrint("Loaded staff data from player attributes for " .. player.Name)
		return true
	else
		warn("Failed to decode staff data for " .. player.Name)
		return false
	end
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
	
	-- Initialize training facility attributes
	if not tycoon:GetAttribute("HasTrainingFacility") then
		tycoon:SetAttribute("HasTrainingFacility", false)
	end
	
	if not tycoon:GetAttribute("TrainingFacilityLevel") then
		tycoon:SetAttribute("TrainingFacilityLevel", 0)
	end
	
	-- Initialize specialization bonus attributes
	tycoon:SetAttribute("StaffSpecRevenue", 0)
	tycoon:SetAttribute("StaffSpecMembership", 0)
	tycoon:SetAttribute("StaffSpecSatisfaction", 0)
	tycoon:SetAttribute("StaffSpecRetention", 0)
	tycoon:SetAttribute("StaffSpecVIPChance", 0)
	tycoon:SetAttribute("StaffSpecEfficiency", 0)
	tycoon:SetAttribute("StaffSpecXP", 0)
	tycoon:SetAttribute("StaffSpecEquipmentLifespan", 0)
	tycoon:SetAttribute("StaffSpecEquipmentQuality", 0)
	tycoon:SetAttribute("StaffSpecVIPConversion", 0)
	tycoon:SetAttribute("StaffSpecVIPRevenue", 0)

	-- Load staff data
	StaffSystem:loadStaffData(player)

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
	
	-- Create remote functions for training & specialization systems
	local createTrainingFacilityFunction = ReplicatedStorage:FindFirstChild("CreateTrainingFacilityFunction")
	if not createTrainingFacilityFunction then
		createTrainingFacilityFunction = Instance.new("RemoteFunction")
		createTrainingFacilityFunction.Name = "CreateTrainingFacilityFunction"
		createTrainingFacilityFunction.Parent = ReplicatedStorage
	end
	
	createTrainingFacilityFunction.OnServerInvoke = function(player)
		return StaffSystem:buildTrainingFacility(player)
	end
	
	local upgradeTrainingFacilityFunction = ReplicatedStorage:FindFirstChild("UpgradeTrainingFacilityFunction")
	if not upgradeTrainingFacilityFunction then
		upgradeTrainingFacilityFunction = Instance.new("RemoteFunction")
		upgradeTrainingFacilityFunction.Name = "UpgradeTrainingFacilityFunction"
		upgradeTrainingFacilityFunction.Parent = ReplicatedStorage
	end
	
	upgradeTrainingFacilityFunction.OnServerInvoke = function(player)
		return StaffSystem:upgradeTrainingFacility(player)
	end
	
	local startTrainingSessionFunction = ReplicatedStorage:FindFirstChild("StartTrainingSessionFunction")
	if not startTrainingSessionFunction then
		startTrainingSessionFunction = Instance.new("RemoteFunction")
		startTrainingSessionFunction.Name = "StartTrainingSessionFunction"
		startTrainingSessionFunction.Parent = ReplicatedStorage
	end
	
	startTrainingSessionFunction.OnServerInvoke = function(player, positionId, staffId)
		return StaffSystem:startTrainingSession(player, positionId, staffId)
	end
	
	local setStaffSpecializationFunction = ReplicatedStorage:FindFirstChild("SetStaffSpecializationFunction")
	if not setStaffSpecializationFunction then
		setStaffSpecializationFunction = Instance.new("RemoteFunction")
		setStaffSpecializationFunction.Name = "SetStaffSpecializationFunction"
		setStaffSpecializationFunction.Parent = ReplicatedStorage
	end
	
	setStaffSpecializationFunction.OnServerInvoke = function(player, positionId, staffId, specializationId)
		return StaffSystem:setStaffSpecialization(player, positionId, staffId, specializationId)
	end
	
	local getStaffDetailsFunction = ReplicatedStorage:FindFirstChild("GetStaffDetailsFunction")
	if not getStaffDetailsFunction then
		getStaffDetailsFunction = Instance.new("RemoteFunction")
		getStaffDetailsFunction.Name = "GetStaffDetailsFunction"
		getStaffDetailsFunction.Parent = ReplicatedStorage
	end
	
	getStaffDetailsFunction.OnServerInvoke = function(player, positionId)
		return StaffSystem:getStaffMembers(player, positionId)
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
					-- Apply specialization bonuses
					StaffSystem:applySpecializationBonuses(player)
				end)
			end
		end
	end)
	
	-- Passive XP gain loop
	task.spawn(function()
		while true do
			task.wait(60) -- Check every minute
			
			for _, player in pairs(Players:GetPlayers()) do
				task.spawn(function()
					StaffSystem:awardPassiveXP(player)
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
				
				-- Apply specialization bonus if available
				local tycoon = player:FindFirstChild("Tycoon")
				local specBonus = 0
				if tycoon then
					specBonus = tycoon:GetAttribute("StaffSpecRevenue") or 0
				end
				
				return math.floor(baseRevenue * (1 + staffBonus + specBonus))
			end

			debugPrint("Hooked into MembershipSystem revenue calculation")
		end
	end
	
	-- Register with CoreRegistry if available
	if CoreRegistry and CoreRegistry.registerSystem then
		CoreRegistry.registerSystem("StaffSystem", StaffSystem)
		debugPrint("Registered StaffSystem with CoreRegistry")
	end

	debugPrint("Staff System initialized")
	return true
end

-- Training facility functions
-- Check if player has a training facility
function StaffSystem:hasTrainingFacility(player)
	if not player then return false, 0 end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, 0 end
	
	local hasTraining = tycoon:GetAttribute("HasTrainingFacility") or false
	local trainingLevel = tycoon:GetAttribute("TrainingFacilityLevel") or 0
	
	return hasTraining, trainingLevel
end

-- Build a training facility
function StaffSystem:buildTrainingFacility(player)
	if not player then return false, "Invalid player" end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end
	
	-- Check if player already has a training facility
	if tycoon:GetAttribute("HasTrainingFacility") then
		return false, "You already have a training facility"
	end
	
	-- Check if player has enough cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then
		return false, "Cash not found"
	end
	
	if leaderstats.Cash.Value < CONFIG.trainingFacilityBuildCost then
		return false, "Not enough cash to build a training facility"
	end
	
	-- Deduct cost
	leaderstats.Cash.Value = leaderstats.Cash.Value - CONFIG.trainingFacilityBuildCost
	
	-- Set attributes
	tycoon:SetAttribute("HasTrainingFacility", true)
	tycoon:SetAttribute("TrainingFacilityLevel", 1)
	
	-- Create a simple training facility model in the tycoon
	local tycoonModel = tycoon.Value
	if tycoonModel then
		task.spawn(function()
			-- Find a good spot for the training facility
			local position = Vector3.new(0, 0, 0)
			local foundSpot = false
			
			-- Try to find empty space near the center of the tycoon
			if tycoonModel:FindFirstChild("FrontDesk") then
				local frontDesk = tycoonModel:FindFirstChild("FrontDesk")
				position = frontDesk:GetPivot().Position + Vector3.new(10, 0, 10)
				foundSpot = true
			else
				-- Fallback to the tycoon's primary part if available
				if tycoonModel.PrimaryPart then
					position = tycoonModel.PrimaryPart.Position + Vector3.new(10, 0, 10)
					foundSpot = true
				else
					-- Last resort: find any part and position relative to it
					for _, part in ipairs(tycoonModel:GetDescendants()) do
						if part:IsA("BasePart") then
							position = part.Position + Vector3.new(5, 0, 5)
							foundSpot = true
							break
						end
					end
				end
			end
			
			if foundSpot then
				-- Create training facility model
				local trainingFacility = Instance.new("Model")
				trainingFacility.Name = "TrainingFacility"
				
				-- Create base platform
				local platform = Instance.new("Part")
				platform.Name = "Platform"
				platform.Size = Vector3.new(10, 1, 10)
				platform.Position = position
				platform.Anchored = true
				platform.TopSurface = Enum.SurfaceType.Smooth
				platform.BottomSurface = Enum.SurfaceType.Smooth
				platform.Material = Enum.Material.SmoothPlastic
				platform.BrickColor = BrickColor.new("Institutional white")
				platform.Parent = trainingFacility
				
				-- Create sign
				local sign = Instance.new("Part")
				sign.Name = "Sign"
				sign.Size = Vector3.new(7, 3, 0.5)
				sign.Position = position + Vector3.new(0, 3, -4.5)
				sign.Anchored = true
				sign.Material = Enum.Material.Neon
				sign.BrickColor = BrickColor.new("Bright blue")
				sign.Parent = trainingFacility
				
				-- Add label
				local signLabel = Instance.new("BillboardGui")
				signLabel.Name = "SignLabel"
				signLabel.Size = UDim2.new(10, 0, 2, 0)
				signLabel.StudsOffset = Vector3.new(0, 0, 0.3)
				signLabel.AlwaysOnTop = true
				signLabel.Parent = sign
				
				local textLabel = Instance.new("TextLabel")
				textLabel.Name = "Title"
				textLabel.Size = UDim2.new(1, 0, 0.5, 0)
				textLabel.Position = UDim2.new(0, 0, 0, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.TextScaled = true
				textLabel.TextColor3 = Color3.new(1, 1, 1)
				textLabel.Text = "STAFF TRAINING CENTER"
				textLabel.Font = Enum.Font.GothamBold
				textLabel.Parent = signLabel
				
				local levelLabel = Instance.new("TextLabel")
				levelLabel.Name = "Level"
				levelLabel.Size = UDim2.new(1, 0, 0.3, 0)
				levelLabel.Position = UDim2.new(0, 0, 0.5, 0)
				levelLabel.BackgroundTransparency = 1
				levelLabel.TextScaled = true
				levelLabel.TextColor3 = Color3.new(1, 1, 0)
				levelLabel.Text = "Level 1"
				levelLabel.Font = Enum.Font.GothamSemibold
				levelLabel.Parent = signLabel
				
				-- Add a proximity prompt for training
				local trainingPrompt = Instance.new("ProximityPrompt")
				trainingPrompt.Name = "TrainingPrompt"
				trainingPrompt.ActionText = "Train Staff"
				trainingPrompt.ObjectText = "Staff Training Facility"
				trainingPrompt.KeyboardKeyCode = Enum.KeyCode.E
				trainingPrompt.HoldDuration = 0.5
				trainingPrompt.MaxActivationDistance = 10
				trainingPrompt.Parent = platform
				
				-- Add equipment
				local addEquipment = function(name, size, position, color)
					local equipment = Instance.new("Part")
					equipment.Name = name
					equipment.Size = size
					equipment.Position = position
					equipment.Anchored = true
					equipment.Material = Enum.Material.SmoothPlastic
					equipment.BrickColor = BrickColor.new(color)
					equipment.Parent = trainingFacility
				end
				
				-- Add some training equipment
				addEquipment("Desk", Vector3.new(4, 1, 2), position + Vector3.new(-2, 1, 0), "Bright blue")
				addEquipment("Computer", Vector3.new(1, 1, 1), position + Vector3.new(-2, 2, 0), "Black")
				addEquipment("Whiteboard", Vector3.new(4, 3, 0.2), position + Vector3.new(3, 2.5, -4), "White")
				addEquipment("TrainingMat", Vector3.new(4, 0.1, 4), position + Vector3.new(2, 1, 2), "Really red")
				
				-- Connect prompt to training function
				trainingPrompt.Triggered:Connect(function(playerWhoTriggered)
					if playerWhoTriggered == player then
						-- Show training UI
						local showTrainingUI = EventBridge:FindFirstChild("ShowTrainingUI")
						if showTrainingUI then
							showTrainingUI:FireClient(player)
						end
					end
				end)
				
				-- Parent to tycoon
				trainingFacility.Parent = tycoonModel
				
				-- Save the fact that we have a training facility
				self:saveStaffData(player)
			end
		end)
	end
	
	-- Notify player
	local message = Instance.new("Message")
	message.Text = "Training Facility Built!\nYou can now train your staff to improve their skills"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	
	-- Fire event
	if EventBridge then
		local facilityBuiltEvent = EventBridge:FindFirstChild("TrainingFacilityBuilt")
		if not facilityBuiltEvent then
			facilityBuiltEvent = Instance.new("RemoteEvent")
			facilityBuiltEvent.Name = "TrainingFacilityBuilt"
			facilityBuiltEvent.Parent = EventBridge
		end
		facilityBuiltEvent:FireClient(player, {
			level = 1
		})
	end
	
	debugPrint(player.Name .. " built a training facility")
	
	return true, "Successfully built a training facility"
end

-- Upgrade training facility
function StaffSystem:upgradeTrainingFacility(player)
	if not player then return false, "Invalid player" end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end
	
	-- Check if player has a training facility
	local hasFacility, currentLevel = self:hasTrainingFacility(player)
	if not hasFacility then
		return false, "You don't have a training facility"
	end
	
	-- Check if already at max level
	if currentLevel >= CONFIG.maxTrainingFacilityLevel then
		return false, "Training facility already at maximum level"
	end
	
	-- Calculate upgrade cost (double the initial cost per level)
	local upgradeCost = CONFIG.trainingFacilityBuildCost * (currentLevel + 1)
	
	-- Check if player has enough cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then
		return false, "Cash not found"
	end
	
	if leaderstats.Cash.Value < upgradeCost then
		return false, "Not enough cash to upgrade training facility"
	end
	
	-- Deduct cost
	leaderstats.Cash.Value = leaderstats.Cash.Value - upgradeCost
	
	-- Set new level
	local newLevel = currentLevel + 1
	tycoon:SetAttribute("TrainingFacilityLevel", newLevel)
	
	-- Update facility model
	local tycoonModel = tycoon.Value
	if tycoonModel then
		local trainingFacility = tycoonModel:FindFirstChild("TrainingFacility")
		if trainingFacility then
			-- Update sign
			local sign = trainingFacility:FindFirstChild("Sign")
			if sign and sign:FindFirstChild("SignLabel") then
				local levelLabel = sign.SignLabel:FindFirstChild("Level")
				if levelLabel then
					levelLabel.Text = "Level " .. newLevel
				end
			end
			
			-- Change colors based on level
			if newLevel == 2 then
				if sign then
					sign.BrickColor = BrickColor.new("Bright violet")
				end
			elseif newLevel == 3 then
				if sign then
					sign.BrickColor = BrickColor.new("New Yeller")
					sign.Material = Enum.Material.Neon
				end
			end
			
			-- Add more equipment for higher levels
			if newLevel == 2 then
				-- Add level 2 equipment
				local addEquipment = function(name, size, position, color)
					local equipment = Instance.new("Part")
					equipment.Name = name
					equipment.Size = size
					equipment.Position = position
					equipment.Anchored = true
					equipment.Material = Enum.Material.SmoothPlastic
					equipment.BrickColor = BrickColor.new(color)
					equipment.Parent = trainingFacility
				end
				
				local position = trainingFacility:FindFirstChild("Platform").Position
				addEquipment("TreadmillL2", Vector3.new(1, 1, 3), position + Vector3.new(-3, 1, 3), "Really black")
				addEquipment("ProjectorL2", Vector3.new(1, 0.5, 1), position + Vector3.new(3, 3, -3), "Dark stone grey")
			elseif newLevel == 3 then
				-- Add level 3 equipment
				local addEquipment = function(name, size, position, color)
					local equipment = Instance.new("Part")
					equipment.Name = name
					equipment.Size = size
					equipment.Position = position
					equipment.Anchored = true
					equipment.Material = Enum.Material.SmoothPlastic
					equipment.BrickColor = BrickColor.new(color)
					equipment.Parent = trainingFacility
				end
				
				local position = trainingFacility:FindFirstChild("Platform").Position
				addEquipment("VRStationL3", Vector3.new(1.5, 1.5, 1.5), position + Vector3.new(0, 2, 2), "Royal purple")
				addEquipment("TrainingDummyL3", Vector3.new(1, 3, 1), position + Vector3.new(3, 2.5, 3), "Bright orange")
			end
		end
	end
	
	-- Notify player
	local message = Instance.new("Message")
	message.Text = "Training Facility Upgraded to Level " .. newLevel .. "!\nTraining sessions now provide " .. math.floor(newLevel * CONFIG.trainingBonusPerFacilityLevel * 100) .. "% more XP"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	
	-- Fire event
	if EventBridge then
		local facilityUpgradedEvent = EventBridge:FindFirstChild("TrainingFacilityUpgraded")
		if not facilityUpgradedEvent then
			facilityUpgradedEvent = Instance.new("RemoteEvent")
			facilityUpgradedEvent.Name = "TrainingFacilityUpgraded"
			facilityUpgradedEvent.Parent = EventBridge
		end
		facilityUpgradedEvent:FireClient(player, {
			level = newLevel
		})
	end
	
	debugPrint(player.Name .. " upgraded training facility to level " .. newLevel)
	
	return true, "Successfully upgraded training facility to level " .. newLevel
end

-- Start a training session for a staff member
function StaffSystem:startTrainingSession(player, positionId, staffId)
	if not player or not positionId or not staffId then
		return false, "Invalid parameters"
	end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end
	
	-- Check if player has a training facility
	local hasFacility, facilityLevel = self:hasTrainingFacility(player)
	if not hasFacility then
		return false, "You need a training facility to train staff"
	end
	
	local userId = player.UserId
	
	-- Check if we have this staff member
	if not self.staffData[userId] or 
	   not self.staffData[userId][positionId] or
	   not self.staffData[userId][positionId].staffMembers then
		return false, "Staff member not found"
	end
	
	-- Find the staff member
	local staffMembers = self.staffData[userId][positionId].staffMembers
	local staffMember = nil
	local staffIndex = nil
	
	for i, staff in ipairs(staffMembers) do
		if staff.id == staffId then
			staffMember = staff
			staffIndex = i
			break
		end
	end
	
	if not staffMember then
		return false, "Staff member not found"
	end
	
	-- Check if already in training
	if staffMember.inTraining then
		return false, staffMember.name .. " is already in training"
	end
	
	-- Check if already at max level
	if staffMember.level >= #CONFIG.skillLevels then
		return false, staffMember.name .. " is already at maximum level"
	end
	
	-- Calculate training cost based on current level
	local trainingCost = CONFIG.trainingSessionCost[staffMember.level] or 0
	
	-- Check if player has enough cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then
		return false, "Cash not found"
	end
	
	if leaderstats.Cash.Value < trainingCost then
		return false, "Not enough cash for training session"
	end
	
	-- Deduct cost
	leaderstats.Cash.Value = leaderstats.Cash.Value - trainingCost
	
	-- Mark staff as in training
	staffMember.inTraining = true
	self.staffData[userId][positionId].staffMembers[staffIndex] = staffMember
	
	-- Save updated state
	self:saveStaffData(player)
	
	-- Setup training session
	local trainingEndTime = os.time() + CONFIG.trainingSessionDuration
	
	-- Create session data
	local sessionId = userId .. "_" .. staffId
	self.activeTrainingSessions[sessionId] = {
		playerId = userId,
		positionId = positionId,
		staffId = staffId,
		staffName = staffMember.name,
		startTime = os.time(),
		endTime = trainingEndTime,
		level = staffMember.level,
		facilityLevel = facilityLevel
	}
	
	-- Schedule end of training
	task.delay(CONFIG.trainingSessionDuration, function()
		self:completeTrainingSession(player, positionId, staffId)
	end)
	
	-- Notify player
	local position = self:findPositionInfo(positionId)
	local message = Instance.new("Message")
	message.Text = staffMember.name .. " (" .. position.name .. ") is now in training\nTraining will be completed in " .. (CONFIG.trainingSessionDuration / 60) .. " minutes"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	
	-- Fire event
	if EventBridge then
		local trainingStartedEvent = EventBridge:FindFirstChild("StaffTrainingStarted")
		if not trainingStartedEvent then
			trainingStartedEvent = Instance.new("RemoteEvent")
			trainingStartedEvent.Name = "StaffTrainingStarted"
			trainingStartedEvent.Parent = EventBridge
		end
		trainingStartedEvent:FireClient(player, {
			staffId = staffId,
			staffName = staffMember.name,
			positionId = positionId,
			positionName = position.name,
			endTime = trainingEndTime
		})
	end
	
	debugPrint(staffMember.name .. " started training session for " .. player.Name)
	
	return true, staffMember.name .. " has started training"
end

-- Complete a training session
function StaffSystem:completeTrainingSession(player, positionId, staffId)
	if not player or not positionId or not staffId then return false end
	
	local userId = player.UserId
	local sessionId = userId .. "_" .. staffId
	
	-- Check if session exists
	local sessionData = self.activeTrainingSessions[sessionId]
	if not sessionData then return false end
	
	-- Clear session
	self.activeTrainingSessions[sessionId] = nil
	
	-- Check if player still in game
	if not player or not player.Parent then return false end
	
	-- Find staff member
	if not self.staffData[userId] or 
	   not self.staffData[userId][positionId] or
	   not self.staffData[userId][positionId].staffMembers then
		return false
	end
	
	-- Find the staff member
	local staffMembers = self.staffData[userId][positionId].staffMembers
	local staffMember = nil
	local staffIndex = nil
	
	for i, staff in ipairs(staffMembers) do
		if staff.id == staffId then
			staffMember = staff
			staffIndex = i
			break
		end
	end
	
	if not staffMember then return false end
	
	-- Calculate XP gain
	local baseXp = CONFIG.trainingSessionXP[staffMember.level] or 0
	local facilityBonus = 1 + (sessionData.facilityLevel * CONFIG.trainingBonusPerFacilityLevel)
	local totalXp = math.floor(baseXp * facilityBonus)
	
	-- Mark as not in training
	staffMember.inTraining = false
	self.staffData[userId][positionId].staffMembers[staffIndex] = staffMember
	
	-- Add XP
	self:addStaffXP(player, positionId, staffId, totalXp)
	
	-- Notify player
	local position = self:findPositionInfo(positionId)
	local message = Instance.new("Message")
	message.Text = staffMember.name .. " (" .. position.name .. ") completed training\nGained " .. totalXp .. " XP!"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	
	-- Fire event
	if EventBridge then
		local trainingCompletedEvent = EventBridge:FindFirstChild("StaffTrainingCompleted")
		if not trainingCompletedEvent then
			trainingCompletedEvent = Instance.new("RemoteEvent")
			trainingCompletedEvent.Name = "StaffTrainingCompleted"
			trainingCompletedEvent.Parent = EventBridge
		end
		trainingCompletedEvent:FireClient(player, {
			staffId = staffId,
			staffName = staffMember.name,
			positionId = positionId,
			positionName = position.name,
			xpGained = totalXp
		})
	end
	
	debugPrint(staffMember.name .. " completed training session for " .. player.Name)
	
	return true
end

-- Set staff specialization
function StaffSystem:setStaffSpecialization(player, positionId, staffId, specializationId)
	if not player or not positionId or not staffId or not specializationId then
		return false, "Invalid parameters"
	end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end
	
	local userId = player.UserId
	
	-- Check if we have this staff member
	if not self.staffData[userId] or 
	   not self.staffData[userId][positionId] or
	   not self.staffData[userId][positionId].staffMembers then
		return false, "Staff member not found"
	end
	
	-- Find the staff member
	local staffMembers = self.staffData[userId][positionId].staffMembers
	local staffMember = nil
	local staffIndex = nil
	
	for i, staff in ipairs(staffMembers) do
		if staff.id == staffId then
			staffMember = staff
			staffIndex = i
			break
		end
	end
	
	if not staffMember then
		return false, "Staff member not found"
	end
	
	-- Check if level meets requirements
	if staffMember.level < CONFIG.specializationUnlockLevel then
		return false, "Staff must be at least level " .. CONFIG.specializationUnlockLevel .. " to specialize"
	end
	
	-- Get position info to check if specialization is valid
	local position = self:findPositionInfo(positionId)
	if not position then
		return false, "Invalid position"
	end
	
	-- Check if specialization is valid for position
	local validSpecialization = false
	for _, spec in ipairs(position.specializations or {}) do
		if spec == specializationId then
			validSpecialization = true
			break
		end
	end
	
	if not validSpecialization then
		return false, "Invalid specialization for this position"
	end
	
	-- Check cost for changing specialization if already specialized
	if staffMember.specialization and staffMember.specialization ~= specializationId then
		-- Need to pay to change specialization
		local changeCost = CONFIG.specializationChangeCost
		
		-- Check if player has enough cash
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats or not leaderstats:FindFirstChild("Cash") then
			return false, "Cash not found"
		end
		
		if leaderstats.Cash.Value < changeCost then
			return false, "Not enough cash to change specialization"
		end
		
		-- Deduct cost
		leaderstats.Cash.Value = leaderstats.Cash.Value - changeCost
	end
	
	-- Set specialization
	staffMember.specialization = specializationId
	self.staffData[userId][positionId].staffMembers[staffIndex] = staffMember
	
	-- Save staff data
	self:saveStaffData(player)
	
	-- Get specialization info for notification
	local specBonus = position.specializationBonus and position.specializationBonus[specializationId]
	local bonusDesc = specBonus and specBonus.description or "specialized training"
	
	-- Notify player
	local message = Instance.new("Message")
	message.Text = staffMember.name .. " is now specialized in " .. specializationId .. "!\n" .. bonusDesc
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	
	-- Fire event
	if EventBridge then
		local specializationEvent = EventBridge:FindFirstChild("StaffSpecialized")
		if not specializationEvent then
			specializationEvent = Instance.new("RemoteEvent")
			specializationEvent.Name = "StaffSpecialized"
			specializationEvent.Parent = EventBridge
		end
		specializationEvent:FireClient(player, {
			staffId = staffId,
			staffName = staffMember.name,
			positionId = positionId,
			positionName = position.name,
			specialization = specializationId,
			description = bonusDesc
		})
	end
	
	debugPrint(staffMember.name .. " specialized in " .. specializationId .. " for " .. player.Name)
	
	return true, staffMember.name .. " is now specialized in " .. specializationId
end

-- Apply staff member bonuses based on specialization
function StaffSystem:applySpecializationBonuses(player)
	if not player then return end
	
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return end
	
	local userId = player.UserId
	
	-- Skip if no staff data
	if not self.staffData[userId] then
		return
	end
	
	-- Reset all specialization bonuses
	tycoon:SetAttribute("StaffSpecRevenue", 0)
	tycoon:SetAttribute("StaffSpecMembership", 0)
	tycoon:SetAttribute("StaffSpecSatisfaction", 0)
	tycoon:SetAttribute("StaffSpecRetention", 0)
	tycoon:SetAttribute("StaffSpecVIPChance", 0)
	tycoon:SetAttribute("StaffSpecEfficiency", 0)
	tycoon:SetAttribute("StaffSpecXP", 0)
	tycoon:SetAttribute("StaffSpecEquipmentLifespan", 0)
	tycoon:SetAttribute("StaffSpecEquipmentQuality", 0)
	tycoon:SetAttribute("StaffSpecVIPConversion", 0)
	tycoon:SetAttribute("StaffSpecVIPRevenue", 0)
	
	-- Calculate bonuses from all specialized staff
	for positionId, positionData in pairs(self.staffData[userId]) do
		local position = self:findPositionInfo(positionId)
		if position then
			for _, staff in ipairs(positionData.staffMembers or {}) do
				-- Skip if not specialized
				if not staff.specialization then
					continue
				end
				
				-- Get specialization bonus info
				local specBonus = position.specializationBonus and 
					position.specializationBonus[staff.specialization]
				
				if specBonus then
					-- Apply bonus based on type, scaled by skill multiplier
					local bonusValue = specBonus.bonusValue * staff.skillMultiplier
					
					if specBonus.bonusType == "revenue" then
						local currentBonus = tycoon:GetAttribute("StaffSpecRevenue") or 0
						tycoon:SetAttribute("StaffSpecRevenue", currentBonus + bonusValue)
					elseif specBonus.bonusType == "membership" then
						local currentBonus = tycoon:GetAttribute("StaffSpecMembership") or 0
						tycoon:SetAttribute("StaffSpecMembership", currentBonus + bonusValue)
					elseif specBonus.bonusType == "satisfaction" then
						local currentBonus = tycoon:GetAttribute("StaffSpecSatisfaction") or 0
						tycoon:SetAttribute("StaffSpecSatisfaction", currentBonus + bonusValue)
					elseif specBonus.bonusType == "retention" then
						local currentBonus = tycoon:GetAttribute("StaffSpecRetention") or 0
						tycoon:SetAttribute("StaffSpecRetention", currentBonus + bonusValue)
					elseif specBonus.bonusType == "vip_chance" then
						local currentBonus = tycoon:GetAttribute("StaffSpecVIPChance") or 0
						tycoon:SetAttribute("StaffSpecVIPChance", currentBonus + bonusValue)
					elseif specBonus.bonusType == "efficiency" then
						local currentBonus = tycoon:GetAttribute("StaffSpecEfficiency") or 0
						tycoon:SetAttribute("StaffSpecEfficiency", currentBonus + bonusValue)
					elseif specBonus.bonusType == "staff_xp" then
						local currentBonus = tycoon:GetAttribute("StaffSpecXP") or 0
						tycoon:SetAttribute("StaffSpecXP", currentBonus + bonusValue)
					elseif specBonus.bonusType == "equipment_lifespan" then
						local currentBonus = tycoon:GetAttribute("StaffSpecEquipmentLifespan") or 0
						tycoon:SetAttribute("StaffSpecEquipmentLifespan", currentBonus + bonusValue)
					elseif specBonus.bonusType == "equipment_quality" then
						local currentBonus = tycoon:GetAttribute("StaffSpecEquipmentQuality") or 0
						tycoon:SetAttribute("StaffSpecEquipmentQuality", currentBonus + bonusValue)
					elseif specBonus.bonusType == "vip_conversion" then
						local currentBonus = tycoon:GetAttribute("StaffSpecVIPConversion") or 0
						tycoon:SetAttribute("StaffSpecVIPConversion", currentBonus + bonusValue)
					elseif specBonus.bonusType == "vip_revenue" then
						local currentBonus = tycoon:GetAttribute("StaffSpecVIPRevenue") or 0
						tycoon:SetAttribute("StaffSpecVIPRevenue", currentBonus + bonusValue)
					end
				end
			end
		end
	end
end

-- Award passive XP to staff
function StaffSystem:awardPassiveXP(player)
	if not player then return end
	
	local userId = player.UserId
	
	-- Skip if no staff data
	if not self.staffData[userId] then
		return
	end
	
	-- Get training facility level for bonus
	local _, facilityLevel = self:hasTrainingFacility(player)
	local facilityMultiplier = 1 + (facilityLevel * 0.1) -- 10% bonus per level
	
	-- Get staff XP specialization bonus
	local tycoon = player:FindFirstChild("Tycoon")
	local xpSpecBonus = 0
	if tycoon then
		xpSpecBonus = tycoon:GetAttribute("StaffSpecXP") or 0
	end
	
	-- Award XP to all staff
	for positionId, positionData in pairs(self.staffData[userId]) do
		for i, staff in ipairs(positionData.staffMembers or {}) do
			-- Skip if max level or in training
			if staff.level >= #CONFIG.skillLevels or staff.inTraining then
				continue
			end
			
			-- Calculate time since last XP gain
			local timeSinceLastXP = os.time() - staff.lastXpGain
			
			-- Check if enough time has passed
			if timeSinceLastXP >= CONFIG.passiveXpInterval then
				-- Calculate XP amount
				local baseXP = CONFIG.passiveXpAmount[staff.level] or 0
				local totalXP = math.floor(baseXP * facilityMultiplier * (1 + xpSpecBonus))
				
				-- Add XP
				if totalXP > 0 then
					self:addStaffXP(player, positionId, staff.id, totalXP)
				end
			end
		end
	end
end

-- Initialize the system
StaffSystem.initialize()

-- Return the module
return StaffSystem