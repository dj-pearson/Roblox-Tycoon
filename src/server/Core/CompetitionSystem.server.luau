-- CompetitionSystem.luau
-- Migrated to new architecture pattern
-- Part of Core Systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- System Configuration 
local CONFIG = {
	-- Competition types and their details
	competitions = {
		{
			id = "fitness_challenge",
			name = "Fitness Challenge",
			description = "Challenge members to beat their personal records!",
			duration = 1800, -- 30 minutes
			boostMultiplier = 1.5, -- 50% more members
			cost = 500,
			minLevel = 1 -- Min gym level to start this competition
		},
		{
			id = "bodybuilding_contest",
			name = "Bodybuilding Contest",
			description = "Show off muscles and attract new members!",
			duration = 2700, -- 45 minutes
			boostMultiplier = 1.75, -- 75% more members
			cost = 1000,
			minLevel = 3
		},
		{
			id = "marathon_training",
			name = "Marathon Training",
			description = "Help members train for upcoming marathons!",
			duration = 3600, -- 60 minutes
			boostMultiplier = 2.0, -- 100% more members
			cost = 2000,
			minLevel = 5
		},
		{
			id = "celebrity_visit",
			name = "Celebrity Trainer Visit",
			description = "A famous trainer is visiting your gym!",
			duration = 1800, -- 30 minutes
			boostMultiplier = 2.5, -- 150% more members
			cost = 5000,
			minLevel = 8
		},
		{
			id = "championship",
			name = "Fitness Championship",
			description = "Host the ultimate fitness competition!",
			duration = 3600, -- 60 minutes
			boostMultiplier = 3.0, -- 200% more members
			cost = 10000,
			minLevel = 12
		}
	},

	-- Cooldowns
	globalCooldown = 300, -- 5 minutes between any competitions
	typeCooldown = 7200,  -- 2 hours between same competition type

	-- Unlock system
	unlockByLevel = true, -- Whether competitions unlock by gym level

	-- Miscellaneous
	maxSimultaneousCompetitions = 1, -- How many competitions can run at once
	debug = true
}

-- Private variables
local CoreRegistry
local DataManager
local EventBridge
local RevenueSystem

-- State tracking
local activeCompetitions = {}
local competitionCooldowns = {}
local lastGlobalCompetition = 0

-- Module table
local CompetitionSystem = {
	Name = "CompetitionSystem",
	Dependencies = {
		"CoreRegistry",
		"DataManager",
		"EventBridge",
		"RevenueSystem"
	}
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Competition]", ...)
	end
end

-- Initialize the competition system
function CompetitionSystem:Initialize(registry)
	debugPrint("Initializing Competition System...")
	
	-- Get dependencies
	CoreRegistry = registry
	DataManager = CoreRegistry:GetSystem("DataManager")
	EventBridge = CoreRegistry:GetSystem("EventBridge")
	RevenueSystem = CoreRegistry:GetSystem("RevenueSystem")
	
	-- Check dependencies
	if not DataManager or not EventBridge or not RevenueSystem then
		warn("[CompetitionSystem] Missing dependencies, system may not function correctly")
		return false
	end
	
	-- Load state from DataManager
	self:LoadState()
	
	-- Register remote functions using EventBridge
	EventBridge:RegisterRemoteFunction("GetCompetitions", function(player)
		return self:GetAvailableCompetitions(player)
	end)
	
	EventBridge:RegisterRemoteFunction("StartCompetition", function(player, competitionId)
		return self:StartCompetition(player, competitionId)
	end)
	
	-- Subscribe to relevant events
	EventBridge:Subscribe("PlayerRemoved", function(player)
		self:CleanupPlayerCompetitions(player)
	end)
	
	-- Start competition expiration checker
	self:StartExpirationChecker()
	
	debugPrint("Competition System initialized successfully")
	return true
end

-- Load state from DataManager
function CompetitionSystem:LoadState()
	-- Try to load competition data
	local success, data = DataManager:GetGlobalData("CompetitionSystem")
	
	if success and data then
		if data.activeCompetitions then
			-- Filter out expired competitions
			local currentTime = os.time()
			for _, comp in pairs(data.activeCompetitions) do
				if comp.endTime and comp.endTime > currentTime then
					table.insert(activeCompetitions, comp)
				end
			end
		end
		
		if data.competitionCooldowns then
			competitionCooldowns = data.competitionCooldowns
		end
		
		if data.lastGlobalCompetition then
			lastGlobalCompetition = data.lastGlobalCompetition
		end
		
		debugPrint("Loaded competition state from DataManager")
	else
		debugPrint("No saved competition state found, using defaults")
	end
end

-- Save state to DataManager
function CompetitionSystem:SaveState()
	local data = {
		activeCompetitions = activeCompetitions,
		competitionCooldowns = competitionCooldowns,
		lastGlobalCompetition = lastGlobalCompetition
	}
	
	DataManager:SetGlobalData("CompetitionSystem", data)
	debugPrint("Competition state saved to DataManager")
end

-- Get available competitions for a player
function CompetitionSystem:GetAvailableCompetitions(player)
	if not player then return {} end
	
	local availableCompetitions = {}
	local currentTime = os.time()

	-- Get player gym level from RevenueSystem
	local gymLevel = RevenueSystem:CalculateGymLevel(player)

	-- Check each competition type
	for _, competition in ipairs(CONFIG.competitions) do
		-- Check if player meets level requirement
		local meetsLevelRequirement = gymLevel >= competition.minLevel

		-- Check cooldowns
		local onGlobalCooldown = (currentTime - lastGlobalCompetition) < CONFIG.globalCooldown
		local onTypeCooldown = competitionCooldowns[player.UserId] and 
			competitionCooldowns[player.UserId][competition.id] and
			(currentTime - competitionCooldowns[player.UserId][competition.id]) < CONFIG.typeCooldown

		-- Check if too many active competitions
		local tooManyActive = #activeCompetitions >= CONFIG.maxSimultaneousCompetitions

		-- Check if this specific competition is already active
		local isActive = false
		for _, activeComp in pairs(activeCompetitions) do
			if activeComp.competitionId == competition.id and activeComp.playerId == player.UserId then
				isActive = true
				break
			end
		end

		local isAvailable = meetsLevelRequirement and not onGlobalCooldown and not onTypeCooldown and not tooManyActive and not isActive

		-- Add to available list with status
		table.insert(availableCompetitions, {
			id = competition.id,
			name = competition.name,
			description = competition.description,
			duration = competition.duration,
			cost = competition.cost,
			available = isAvailable,
			reason = not isAvailable and (
				not meetsLevelRequirement and "Level requirement not met" or
					onGlobalCooldown and "Global cooldown active" or
					onTypeCooldown and "Type cooldown active" or
					tooManyActive and "Maximum competitions running" or
					isActive and "Competition already active" or
					"Unknown reason"
			) or nil,
			timeRemaining = onTypeCooldown and 
				(CONFIG.typeCooldown - (currentTime - competitionCooldowns[player.UserId][competition.id])) or nil
		})
	end

	return availableCompetitions
end

-- Start a competition
function CompetitionSystem:StartCompetition(player, competitionId)
	if not player then return false, "Invalid player" end

	-- Find competition config
	local competitionConfig
	for _, comp in ipairs(CONFIG.competitions) do
		if comp.id == competitionId then
			competitionConfig = comp
			break
		end
	end

	if not competitionConfig then
		return false, "Invalid competition type"
	end

	-- Check if player can start this competition
	local availableCompetitions = self:GetAvailableCompetitions(player)
	local canStart = false

	for _, comp in ipairs(availableCompetitions) do
		if comp.id == competitionId and comp.available then
			canStart = true
			break
		end
	end

	if not canStart then
		return false, "Competition not available"
	end

	-- Check if player has enough money
	local playerData = DataManager:GetPlayerData(player, "Currency")
	if not playerData or not playerData.cash then
		return false, "Player data not found"
	end

	if playerData.cash < competitionConfig.cost then
		return false, "Not enough money"
	end

	-- Deduct cost from player
	DataManager:UpdatePlayerData(player, "Currency", function(data)
		data.cash = data.cash - competitionConfig.cost
		return data
	end)

	-- Apply competition boost through RevenueSystem
	local competitionKey = RevenueSystem:ApplyCompetitionBoost(player, competitionConfig.boostMultiplier, competitionConfig.duration)
	
	-- Track competition
	local competitionData = {
		playerId = player.UserId,
		playerName = player.Name,
		competitionId = competitionId,
		competitionName = competitionConfig.name,
		startTime = os.time(),
		endTime = os.time() + competitionConfig.duration,
		boostMultiplier = competitionConfig.boostMultiplier,
		key = competitionKey
	}
	
	table.insert(activeCompetitions, competitionData)

	-- Update cooldowns
	lastGlobalCompetition = os.time()

	if not competitionCooldowns[player.UserId] then
		competitionCooldowns[player.UserId] = {}
	end

	competitionCooldowns[player.UserId][competitionId] = os.time()
	
	-- Save updated state
	self:SaveState()

	-- Send notification event to all players
	EventBridge:FireAllClients("CompetitionStarted", {
		playerName = player.Name,
		competitionName = competitionConfig.name
	})
	
	-- Fire server-side event for other systems
	EventBridge:Fire("CompetitionStarted", player, competitionData)

	debugPrint(player.Name .. " started competition: " .. competitionConfig.name)
	return true, "Competition started successfully"
end

-- End a competition
function CompetitionSystem:EndCompetition(competitionData)
	if not competitionData then return false end

	-- Remove competition boost through RevenueSystem
	RevenueSystem:RemoveCompetitionBoost(competitionData.playerId, competitionData.key)

	-- Remove from active competitions
	for i, comp in ipairs(activeCompetitions) do
		if comp.playerId == competitionData.playerId and comp.competitionId == competitionData.competitionId then
			table.remove(activeCompetitions, i)
			break
		end
	end
	
	-- Save updated state
	self:SaveState()
	
	-- Fire event for competition end
	EventBridge:Fire("CompetitionEnded", competitionData)
	
	-- Find player by ID and send notification
	local player = Players:GetPlayerByUserId(competitionData.playerId)
	if player then
		EventBridge:FireClient(player, "CompetitionEnded", competitionData)
	end
	
	debugPrint("Competition ended: " .. competitionData.competitionName .. " for " .. competitionData.playerName)
	return true
end

-- Start the expiration checker loop
function CompetitionSystem:StartExpirationChecker()
	spawn(function()
		while true do
			wait(1)

			local currentTime = os.time()
			local competitionsToEnd = {}

			-- Find expired competitions
			for _, comp in ipairs(activeCompetitions) do
				if currentTime >= comp.endTime then
					table.insert(competitionsToEnd, comp)
				end
			end

			-- End expired competitions
			for _, comp in ipairs(competitionsToEnd) do
				self:EndCompetition(comp)
			end
		end
	end)
end

-- Clean up competitions when a player leaves
function CompetitionSystem:CleanupPlayerCompetitions(player)
	if not player then return end
	
	-- Find and end all competitions for this player
	local playerCompetitions = {}
	for _, comp in ipairs(activeCompetitions) do
		if comp.playerId == player.UserId then
			table.insert(playerCompetitions, comp)
		end
	end
	
	-- End each competition
	for _, comp in ipairs(playerCompetitions) do
		self:EndCompetition(comp)
	end
	
	-- Clean up cooldowns
	competitionCooldowns[player.UserId] = nil
	
	-- Save updated state
	self:SaveState()
end

-- Get competition info by ID
function CompetitionSystem:GetCompetitionConfig(competitionId)
	for _, competition in ipairs(CONFIG.competitions) do
		if competition.id == competitionId then
			return competition
		end
	end
	return nil
end

-- Get all active competitions
function CompetitionSystem:GetActiveCompetitions()
	return activeCompetitions
end

-- Get competition config
function CompetitionSystem:GetConfig()
	return CONFIG
end

return CompetitionSystem