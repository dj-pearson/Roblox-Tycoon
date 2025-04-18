-- CompetitionSystem.lua
-- Server script for managing gym competitions
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Try to load GymRevenueSystem
local GymRevenueSystem
pcall(function()
	GymRevenueSystem = require(ServerScriptService:FindFirstChild("GymRevenueSystem"))
end)

if not GymRevenueSystem then
	warn("GymRevenueSystem not found! CompetitionSystem will not function properly.")
	return
end

-- Configuration
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

-- Module table
local CompetitionSystem = {
	CONFIG = CONFIG
}

-- State tracking
local activeCompetitions = {}
local competitionCooldowns = {}
local lastGlobalCompetition = 0

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Competition]", ...)
	end
end

-- Get available competitions for a player
function CompetitionSystem.getAvailableCompetitions(player)
	local availableCompetitions = {}
	local currentTime = os.time()

	-- Get player gym level
	local gymLevel = 1
	if GymRevenueSystem then
		gymLevel = GymRevenueSystem.calculateGymLevel(player)
	end

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
			if activeComp.competitionId == competition.id and activeComp.player == player then
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
function CompetitionSystem.startCompetition(player, competitionId)
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
	local availableCompetitions = CompetitionSystem.getAvailableCompetitions(player)
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
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then
		return false, "Leaderstats not found"
	end

	if leaderstats.Cash.Value < competitionConfig.cost then
		return false, "Not enough money"
	end

	-- Deduct cost
	leaderstats.Cash.Value = leaderstats.Cash.Value - competitionConfig.cost

	-- Start competition using GymRevenueSystem
	if GymRevenueSystem and GymRevenueSystem.startCompetition then
		local competitionKey = GymRevenueSystem.startCompetition(player, competitionConfig.name)
		if not competitionKey then
			return false, "Failed to start competition"
		end

		-- Track competition
		table.insert(activeCompetitions, {
			player = player,
			competitionId = competitionId,
			startTime = os.time(),
			endTime = os.time() + competitionConfig.duration,
			key = competitionKey
		})

		-- Update cooldowns
		lastGlobalCompetition = os.time()

		if not competitionCooldowns[player.UserId] then
			competitionCooldowns[player.UserId] = {}
		end

		competitionCooldowns[player.UserId][competitionId] = os.time()

		-- Notify all players about the competition
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				local message = Instance.new("Message")
				message.Text = player.Name .. " has started a " .. competitionConfig.name .. "!"
				message.Parent = otherPlayer
				game:GetService("Debris"):AddItem(message, 5)
			end
		end

		debugPrint(player.Name .. " started competition: " .. competitionConfig.name)
		return true, "Competition started successfully"
	else
		-- Return money since we couldn't start
		leaderstats.Cash.Value = leaderstats.Cash.Value + competitionConfig.cost
		return false, "Revenue system not available"
	end
end

-- End a competition (called automatically when duration expires)
function CompetitionSystem.endCompetition(competitionData)
	if not competitionData then return false end

	local player = competitionData.player
	if not player then return false end

	-- End competition in GymRevenueSystem
	if GymRevenueSystem and GymRevenueSystem.endCompetition then
		GymRevenueSystem.endCompetition(player, competitionData.key)
	end

	-- Remove from active competitions
	for i, comp in ipairs(activeCompetitions) do
		if comp.player == player and comp.competitionId == competitionData.competitionId then
			table.remove(activeCompetitions, i)
			break
		end
	end

	debugPrint("Competition ended for " .. player.Name .. ": " .. competitionData.competitionId)
	return true
end

-- Initialize the competition system
function CompetitionSystem.initialize()
	debugPrint("Initializing Competition System...")

	-- Set up remote functions
	local getCompetitionsFunction = ReplicatedStorage:FindFirstChild("GetCompetitionsFunction")
	if not getCompetitionsFunction then
		getCompetitionsFunction = Instance.new("RemoteFunction")
		getCompetitionsFunction.Name = "GetCompetitionsFunction"
		getCompetitionsFunction.Parent = ReplicatedStorage
	end

	-- Handle competition data requests
	getCompetitionsFunction.OnServerInvoke = function(player)
		return CompetitionSystem.getAvailableCompetitions(player)
	end

	-- Competition start function
	local startCompetitionFunction = ReplicatedStorage:FindFirstChild("StartCompetitionFunction")
	if not startCompetitionFunction then
		startCompetitionFunction = Instance.new("RemoteFunction")
		startCompetitionFunction.Name = "StartCompetitionFunction"
		startCompetitionFunction.Parent = ReplicatedStorage
	end

	-- Handle competition start requests
	startCompetitionFunction.OnServerInvoke = function(player, competitionId)
		return CompetitionSystem.startCompetition(player, competitionId)
	end

	-- Start a loop to check for expired competitions
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
				CompetitionSystem.endCompetition(comp)
			end
		end
	end)

	-- Handle player removal
	Players.PlayerRemoving:Connect(function(player)
		-- End any active competitions for this player
		for i = #activeCompetitions, 1, -1 do
			if activeCompetitions[i].player == player then
				CompetitionSystem.endCompetition(activeCompetitions[i])
			end
		end

		-- Clear cooldowns
		competitionCooldowns[player.UserId] = nil
	end)

	debugPrint("Competition System initialized")
	return true
end

-- Initialize the system
CompetitionSystem.initialize()

-- Return the module
return CompetitionSystem