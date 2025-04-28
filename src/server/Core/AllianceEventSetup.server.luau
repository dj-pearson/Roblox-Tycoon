-- AllianceEventSetup.server.luau
-- Creates alliance-specific events early to prevent infinite yield errors
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local DEBUG = true
local EVENT_FOLDER_NAME = "AllianceEvents"

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[AllianceEventSetup][%s] %s", level, message))
end

-- Create remote events for alliances
local function createAllianceEvents()
	log("Setting up alliance events...")
	
	-- Create the events folder in ReplicatedStorage if it doesn't exist
	local eventsFolder = ReplicatedStorage:FindFirstChild(EVENT_FOLDER_NAME)
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = EVENT_FOLDER_NAME
		eventsFolder.Parent = ReplicatedStorage
		log("Created events folder: " .. EVENT_FOLDER_NAME)
	end
	
	-- Define all the alliance events that need to be created
	local allianceEvents = {
		"AllianceCreated",
		"AllianceInvite",
		"AllianceJoined",
		"AllianceLeft",
		"AllianceDisbanded",
		"AllianceMessageSent",
		"AllianceRoleChanged",
		"AllianceMemberKicked",
		"AllianceCompetitionStarted",
		"AllianceCompetitionEnded",
		"AllianceCompetitionScoreUpdated"
	}
	
	-- Create each event if it doesn't exist already
	for _, eventName in ipairs(allianceEvents) do
		if not eventsFolder:FindFirstChild(eventName) then
			local remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = eventsFolder
			log("Created remote event: " .. eventName)
		end
	end
	
	-- Create a signal to indicate that all alliance events are ready
	local signal = Instance.new("BoolValue")
	signal.Name = "AllianceEventsReady"
	signal.Value = true
	signal.Parent = eventsFolder
	
	log("Alliance events setup complete")
	return eventsFolder
end

-- Create additional alliance value objects
local function createAllianceValues()
	log("Setting up alliance values...")
	
	-- Get the events folder
	local eventsFolder = ReplicatedStorage:FindFirstChild(EVENT_FOLDER_NAME)
	if not eventsFolder then
		log("Events folder not found, creating it")
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = EVENT_FOLDER_NAME
		eventsFolder.Parent = ReplicatedStorage
	end
	
	-- Create alliance configuration values
	local configValues = {
		-- Alliance limits
		{ name = "MaxAllianceMembers", type = "IntValue", value = 50 },
		{ name = "MaxAlliancesPerPlayer", type = "IntValue", value = 1 },
		{ name = "MinAllianceNameLength", type = "IntValue", value = 3 },
		{ name = "MaxAllianceNameLength", type = "IntValue", value = 20 },
		
		-- Alliance features
		{ name = "AllianceChatEnabled", type = "BoolValue", value = true },
		{ name = "AllianceCompetitionsEnabled", type = "BoolValue", value = true },
		{ name = "AllianceBonusesEnabled", type = "BoolValue", value = true },
		
		-- Alliance costs
		{ name = "AllianceCreationCost", type = "IntValue", value = 10000 }
	}
	
	-- Create a config folder if it doesn't exist
	local configFolder = eventsFolder:FindFirstChild("Config")
	if not configFolder then
		configFolder = Instance.new("Folder")
		configFolder.Name = "Config"
		configFolder.Parent = eventsFolder
		log("Created alliance config folder")
	end
	
	-- Create each value if it doesn't exist
	for _, valueInfo in ipairs(configValues) do
		if not configFolder:FindFirstChild(valueInfo.name) then
			local valueObj = Instance.new(valueInfo.type)
			valueObj.Name = valueInfo.name
			valueObj.Value = valueInfo.value
			valueObj.Parent = configFolder
			log("Created alliance config value: " .. valueInfo.name)
		end
	end
	
	log("Alliance values setup complete")
	return configFolder
end

-- Initialize event and value setup
local allianceEvents = createAllianceEvents()
local allianceValues = createAllianceValues()

log("Alliance system initialization complete")

-- Return the events folder
return allianceEvents
