-- JobSystem.luau
-- Migrated to new architecture pattern
-- Part of Core Systems

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- System Configuration
local CONFIG = {
	-- Job types and their details
	jobs = {
		{
			id = "trainer",
			name = "Trainer",
			description = "Help gym members with their workouts",
			benefits = "Increases NPC satisfaction by 25%",
			salary = 50, -- per hour
			requiredLevel = 2, -- Min gym level to hire
			maxPerGym = 3 -- Maximum number per gym
		},
		{
			id = "receptionist",
			name = "Receptionist",
			description = "Process new memberships and handle inquiries",
			benefits = "Increases membership processing speed by 30%",
			salary = 40,
			requiredLevel = 1,
			maxPerGym = 2
		},
		{
			id = "maintenance",
			name = "Maintenance Staff",
			description = "Keep gym equipment clean and functioning",
			benefits = "Reduces equipment downtime by 40%",
			salary = 35,
			requiredLevel = 3,
			maxPerGym = 2
		},
		{
			id = "nutritionist",
			name = "Nutritionist",
			description = "Provide nutrition advice to gym members",
			benefits = "Increases revenue per member by 15%",
			salary = 60,
			requiredLevel = 5,
			maxPerGym = 1
		},
		{
			id = "manager",
			name = "Gym Manager",
			description = "Oversee all gym operations",
			benefits = "Increases all gym efficiency by 20%",
			salary = 100,
			requiredLevel = 8,
			maxPerGym = 1
		}
	},
	
	-- Payment configuration
	paymentInterval = 3600, -- Pay staff every hour (in seconds)
	
	-- NPC assignment settings
	jobUniformColors = {
		trainer = Color3.fromRGB(255, 100, 0), -- Orange
		receptionist = Color3.fromRGB(0, 100, 255), -- Blue
		maintenance = Color3.fromRGB(100, 100, 100), -- Gray
		nutritionist = Color3.fromRGB(0, 200, 100), -- Green
		manager = Color3.fromRGB(150, 0, 150) -- Purple
	},
	
	-- Miscellaneous
	debug = true,
	enableSalaries = true
}

-- Private variables
local CoreRegistry
local DataManager
local EventBridge
local NPCSystem
local RevenueSystem

-- State tracking
local activeJobs = {} -- Format: [playerId][npcId] = jobInfo
local lastPaymentTime = {}

-- Module table
local JobSystem = {
	Name = "JobSystem",
	Dependencies = {
		"CoreRegistry",
		"DataManager",
		"EventBridge",
		"NPCSystem",
		"RevenueSystem"
	}
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[JobSystem]", ...)
	end
end

-- Initialize the job system
function JobSystem:Initialize(registry)
	debugPrint("Initializing Job System...")
	
	-- Get dependencies
	CoreRegistry = registry
	DataManager = CoreRegistry:GetSystem("DataManager")
	EventBridge = CoreRegistry:GetSystem("EventBridge")
	NPCSystem = CoreRegistry:GetSystem("NPCSystem")
	RevenueSystem = CoreRegistry:GetSystem("RevenueSystem")
	
	-- Check dependencies
	if not DataManager or not EventBridge or not NPCSystem or not RevenueSystem then
		warn("[JobSystem] Missing dependencies, system may not function correctly")
		return false
	end
	
	-- Load state from DataManager
	self:LoadState()
	
	-- Register remote functions using EventBridge
	EventBridge:RegisterRemoteFunction("GetAvailableJobs", function(player)
		return self:GetAvailableJobs(player)
	end)
	
	EventBridge:RegisterRemoteFunction("HireStaff", function(player, jobId, npcId)
		return self:HireStaff(player, jobId, npcId)
	end)
	
	EventBridge:RegisterRemoteFunction("FireStaff", function(player, npcId)
		return self:FireStaff(player, npcId)
	end)
	
	-- Subscribe to relevant events
	EventBridge:Subscribe("PlayerRemoved", function(player)
		self:CleanupPlayerJobs(player)
	end)
	
	EventBridge:Subscribe("NPCRemoved", function(npcId, playerId)
		if playerId and npcId then
			self:HandleNPCRemoved(playerId, npcId)
		end
	end)
	
	-- Start salary payment system
	self:StartSalarySystem()
	
	-- Apply job benefits to existing NPCs
	self:ApplyAllJobBenefits()
	
	debugPrint("Job System initialized successfully")
	return true
end

-- Load state from DataManager
function JobSystem:LoadState()
	-- Try to load job data
	local success, data = DataManager:GetGlobalData("JobSystem")
	
	if success and data then
		if data.activeJobs then
			activeJobs = data.activeJobs
		end
		
		if data.lastPaymentTime then
			lastPaymentTime = data.lastPaymentTime
		end
		
		debugPrint("Loaded job state from DataManager")
	else
		debugPrint("No saved job state found, using defaults")
	end
end

-- Save state to DataManager
function JobSystem:SaveState()
	local data = {
		activeJobs = activeJobs,
		lastPaymentTime = lastPaymentTime
	}
	
	DataManager:SetGlobalData("JobSystem", data)
	debugPrint("Job state saved to DataManager")
end

-- Get available jobs for a player
function JobSystem:GetAvailableJobs(player)
	if not player then return {} end
	
	local availableJobs = {}
	
	-- Get player gym level from RevenueSystem
	local gymLevel = RevenueSystem:CalculateGymLevel(player)
	
	-- Get current job counts for this player
	local playerJobs = activeJobs[player.UserId] or {}
	local jobCounts = {}
	
	for _, jobInfo in pairs(playerJobs) do
		local jobId = jobInfo.jobId
		jobCounts[jobId] = (jobCounts[jobId] or 0) + 1
	end
	
	-- Check each job type
	for _, jobConfig in ipairs(CONFIG.jobs) do
		-- Check level requirement
		local meetsLevelRequirement = gymLevel >= jobConfig.requiredLevel
		
		-- Check maximum per gym
		local belowMaxCount = (jobCounts[jobConfig.id] or 0) < jobConfig.maxPerGym
		
		-- Add to available list with status
		table.insert(availableJobs, {
			id = jobConfig.id,
			name = jobConfig.name,
			description = jobConfig.description,
			benefits = jobConfig.benefits,
			salary = jobConfig.salary,
			available = meetsLevelRequirement and belowMaxCount,
			reason = not meetsLevelRequirement and "Level requirement not met" or
			         not belowMaxCount and "Maximum staff limit reached" or nil,
			currentCount = jobCounts[jobConfig.id] or 0,
			maxCount = jobConfig.maxPerGym
		})
	end
	
	return availableJobs
end

-- Get available NPCs that can be assigned jobs
function JobSystem:GetAvailableNPCs(player)
	if not player or not NPCSystem then return {} end
	
	local availableNPCs = {}
	local assignedNPCs = {}
	
	-- Get currently assigned NPCs
	if activeJobs[player.UserId] then
		for npcId, _ in pairs(activeJobs[player.UserId]) do
			assignedNPCs[npcId] = true
		end
	end
	
	-- Get all NPCs owned by this player
	local playerNPCs = NPCSystem:GetPlayerNPCs(player)
	
	for _, npcData in pairs(playerNPCs) do
		if not assignedNPCs[npcData.id] then
			table.insert(availableNPCs, {
				id = npcData.id,
				name = npcData.name or "Staff Member",
				type = npcData.type or "Generic"
			})
		end
	end
	
	return availableNPCs
end

-- Get staff members for a player
function JobSystem:GetPlayerStaff(player)
	if not player then return {} end
	
	local playerStaff = {}
	local playerJobs = activeJobs[player.UserId] or {}
	
	for npcId, jobInfo in pairs(playerJobs) do
		-- Try to get NPC data from NPCSystem
		local npcData = NPCSystem:GetNPCById(npcId)
		
		local staffInfo = {
			npcId = npcId,
			jobId = jobInfo.jobId,
			jobName = jobInfo.jobName,
			salary = jobInfo.salary,
			hireTime = jobInfo.hireTime,
			name = npcData and npcData.name or "Staff Member"
		}
		
		table.insert(playerStaff, staffInfo)
	end
	
	return playerStaff
end

-- Hire staff for a player
function JobSystem:HireStaff(player, jobId, npcId)
	if not player or not jobId or not npcId then
		return false, "Missing required information"
	end
	
	-- Check if job exists
	local jobConfig
	for _, job in ipairs(CONFIG.jobs) do
		if job.id == jobId then
			jobConfig = job
			break
		end
	end
	
	if not jobConfig then
		return false, "Invalid job type"
	end
	
	-- Check if player can hire this job type
	local availableJobs = self:GetAvailableJobs(player)
	local canHire = false
	
	for _, job in ipairs(availableJobs) do
		if job.id == jobId and job.available then
			canHire = true
			break
		end
	end
	
	if not canHire then
		return false, "Job not available for hiring"
	end
	
	-- Check if NPC exists and is available
	local availableNPCs = self:GetAvailableNPCs(player)
	local npcAvailable = false
	
	for _, npc in ipairs(availableNPCs) do
		if npc.id == npcId then
			npcAvailable = true
			break
		end
	end
	
	if not npcAvailable then
		return false, "NPC not available for this job"
	end
	
	-- Initialize player's job table if needed
	if not activeJobs[player.UserId] then
		activeJobs[player.UserId] = {}
	end
	
	-- Assign the job
	activeJobs[player.UserId][npcId] = {
		jobId = jobId,
		jobName = jobConfig.name,
		salary = jobConfig.salary,
		hireTime = os.time()
	}
	
	-- Update NPC appearance and behavior
	NPCSystem:UpdateNPC(npcId, {
		job = jobId,
		uniformColor = CONFIG.jobUniformColors[jobId] or Color3.fromRGB(200, 200, 200)
	})
	
	-- Apply job benefits
	self:ApplyJobBenefits(player, jobId)
	
	-- Save updated state
	self:SaveState()
	
	-- Fire event for job assignment
	EventBridge:Fire("StaffHired", player, {
		npcId = npcId,
		jobId = jobId,
		jobName = jobConfig.name
	})
	
	-- Notify client
	EventBridge:FireClient(player, "StaffHired", {
		npcId = npcId,
		jobName = jobConfig.name
	})
	
	debugPrint(player.Name .. " hired a " .. jobConfig.name)
	return true, "Staff hired successfully"
end

-- Fire staff for a player
function JobSystem:FireStaff(player, npcId)
	if not player or not npcId then
		return false, "Missing required information"
	end
	
	-- Check if this NPC is employed by the player
	if not activeJobs[player.UserId] or not activeJobs[player.UserId][npcId] then
		return false, "NPC is not currently employed"
	end
	
	local jobInfo = activeJobs[player.UserId][npcId]
	
	-- Update NPC appearance and behavior
	NPCSystem:UpdateNPC(npcId, {
		job = nil,
		uniformColor = nil
	})
	
	-- Remove job benefits
	self:RemoveJobBenefits(player, jobInfo.jobId)
	
	-- Remove job assignment
	activeJobs[player.UserId][npcId] = nil
	
	-- Check if player has no more jobs
	local hasJobs = false
	for _ in pairs(activeJobs[player.UserId]) do
		hasJobs = true
		break
	end
	
	if not hasJobs then
		activeJobs[player.UserId] = nil
	end
	
	-- Save updated state
	self:SaveState()
	
	-- Fire event for job removal
	EventBridge:Fire("StaffFired", player, {
		npcId = npcId,
		jobId = jobInfo.jobId,
		jobName = jobInfo.jobName
	})
	
	-- Notify client
	EventBridge:FireClient(player, "StaffFired", {
		npcId = npcId,
		jobName = jobInfo.jobName
	})
	
	debugPrint(player.Name .. " fired a " .. jobInfo.jobName)
	return true, "Staff fired successfully"
end

-- Apply job benefits based on job type
function JobSystem:ApplyJobBenefits(player, jobId)
	if not RevenueSystem or not player or not jobId then return end
	
	-- Count how many of this job type the player has
	local jobCount = 0
	if activeJobs[player.UserId] then
		for _, jobInfo in pairs(activeJobs[player.UserId]) do
			if jobInfo.jobId == jobId then
				jobCount = jobCount + 1
			end
		end
	end
	
	-- Apply benefits based on job type
	if jobId == "trainer" then
		-- Trainers increase NPC satisfaction
		RevenueSystem:ApplyJobBoost(player, "satisfaction", 0.25 * jobCount)
	elseif jobId == "receptionist" then
		-- Receptionists increase membership processing speed
		RevenueSystem:ApplyJobBoost(player, "processing", 0.3 * jobCount)
	elseif jobId == "maintenance" then
		-- Maintenance staff reduce equipment downtime
		RevenueSystem:ApplyJobBoost(player, "equipment", 0.4 * jobCount)
	elseif jobId == "nutritionist" then
		-- Nutritionists increase revenue per member
		RevenueSystem:ApplyJobBoost(player, "revenue", 0.15 * jobCount)
	elseif jobId == "manager" then
		-- Managers increase overall efficiency
		RevenueSystem:ApplyJobBoost(player, "efficiency", 0.2 * jobCount)
	end
end

-- Remove job benefits when a staff member is fired
function JobSystem:RemoveJobBenefits(player, jobId)
	if not RevenueSystem or not player or not jobId then return end
	
	-- Count how many of this job type the player has left after removal
	local jobCount = 0
	if activeJobs[player.UserId] then
		for _, jobInfo in pairs(activeJobs[player.UserId]) do
			if jobInfo.jobId == jobId then
				jobCount = jobCount + 1
			end
		end
	end
	
	-- Update benefits based on new count
	if jobId == "trainer" then
		RevenueSystem:ApplyJobBoost(player, "satisfaction", 0.25 * jobCount)
	elseif jobId == "receptionist" then
		RevenueSystem:ApplyJobBoost(player, "processing", 0.3 * jobCount)
	elseif jobId == "maintenance" then
		RevenueSystem:ApplyJobBoost(player, "equipment", 0.4 * jobCount)
	elseif jobId == "nutritionist" then
		RevenueSystem:ApplyJobBoost(player, "revenue", 0.15 * jobCount)
	elseif jobId == "manager" then
		RevenueSystem:ApplyJobBoost(player, "efficiency", 0.2 * jobCount)
	end
end

-- Apply all job benefits (called at initialization)
function JobSystem:ApplyAllJobBenefits()
	for playerId, playerJobs in pairs(activeJobs) do
		local player = Players:GetPlayerByUserId(playerId)
		if player then
			-- Track jobs by type to apply correct multiplier
			local jobCounts = {}
			
			for _, jobInfo in pairs(playerJobs) do
				local jobId = jobInfo.jobId
				jobCounts[jobId] = (jobCounts[jobId] or 0) + 1
			end
			
			-- Apply benefits for each job type
			for jobId, count in pairs(jobCounts) do
				if jobId == "trainer" then
					RevenueSystem:ApplyJobBoost(player, "satisfaction", 0.25 * count)
				elseif jobId == "receptionist" then
					RevenueSystem:ApplyJobBoost(player, "processing", 0.3 * count)
				elseif jobId == "maintenance" then
					RevenueSystem:ApplyJobBoost(player, "equipment", 0.4 * count)
				elseif jobId == "nutritionist" then
					RevenueSystem:ApplyJobBoost(player, "revenue", 0.15 * count)
				elseif jobId == "manager" then
					RevenueSystem:ApplyJobBoost(player, "efficiency", 0.2 * count)
				end
			end
		end
	end
end

-- Start salary payment system
function JobSystem:StartSalarySystem()
	if not CONFIG.enableSalaries then return end
	
	spawn(function()
		while true do
			wait(60) -- Check every minute
			
			local currentTime = os.time()
			
			for playerId, playerJobs in pairs(activeJobs) do
				-- Get player from ID
				local player = Players:GetPlayerByUserId(playerId)
				if player then
					-- Check if it's time to pay salaries
					local lastPaid = lastPaymentTime[playerId] or 0
					if (currentTime - lastPaid) >= CONFIG.paymentInterval then
						-- Calculate total salary
						local totalSalary = 0
						for _, jobInfo in pairs(playerJobs) do
							totalSalary = totalSalary + jobInfo.salary
						end
						
						if totalSalary > 0 then
							-- Deduct from player's balance
							local deductionSuccess = RevenueSystem:DeductMoney(player, totalSalary, "Staff Salaries")
							
							if deductionSuccess then
								-- Update last payment time
								lastPaymentTime[playerId] = currentTime
								
								-- Notify player
								EventBridge:FireClient(player, "SalariesPaid", {
									amount = totalSalary,
									staffCount = table.getn(playerJobs)
								})
								
								debugPrint("Paid " .. totalSalary .. " in salaries for " .. player.Name)
							else
								-- Handle insufficient funds
								debugPrint(player.Name .. " couldn't afford to pay staff salaries")
								
								-- Notify player of insufficient funds
								EventBridge:FireClient(player, "InsufficientFunds", {
									amount = totalSalary,
									staffCount = table.getn(playerJobs)
								})
							end
						end
					end
				end
			end
			
			-- Save payment time state
			self:SaveState()
		end
	end)
end

-- Clean up jobs when a player leaves
function JobSystem:CleanupPlayerJobs(player)
	if not player then return end
	
	-- Check if player has any jobs
	if not activeJobs[player.UserId] then return end
	
	-- Reset NPCs with jobs
	for npcId, jobInfo in pairs(activeJobs[player.UserId]) do
		NPCSystem:UpdateNPC(npcId, {
			job = nil,
			uniformColor = nil
		})
	end
	
	-- Clear job assignments
	activeJobs[player.UserId] = nil
	
	-- Clear payment time
	lastPaymentTime[player.UserId] = nil
	
	-- Save updated state
	self:SaveState()
	
	debugPrint("Cleaned up jobs for " .. player.Name)
end

-- Handle when an NPC is removed
function JobSystem:HandleNPCRemoved(playerId, npcId)
	if not playerId or not npcId then return end
	
	-- Check if this NPC had a job
	if activeJobs[playerId] and activeJobs[playerId][npcId] then
		local jobInfo = activeJobs[playerId][npcId]
		
		-- Remove job benefits
		local player = Players:GetPlayerByUserId(playerId)
		if player then
			self:RemoveJobBenefits(player, jobInfo.jobId)
		end
		
		-- Remove job assignment
		activeJobs[playerId][npcId] = nil
		
		-- Check if player has no more jobs
		local hasJobs = false
		for _ in pairs(activeJobs[playerId]) do
			hasJobs = true
			break
		end
		
		if not hasJobs then
			activeJobs[playerId] = nil
		end
		
		-- Save updated state
		self:SaveState()
		
		debugPrint("Removed job for NPC: " .. npcId)
	end
end

-- Get job configuration
function JobSystem:GetJobConfig(jobId)
	for _, job in ipairs(CONFIG.jobs) do
		if job.id == jobId then
			return job
		end
	end
	return nil
end

-- Get all job configurations
function JobSystem:GetAllJobs()
	return CONFIG.jobs
end

-- Get system config
function JobSystem:GetConfig()
	return CONFIG
end

return JobSystem