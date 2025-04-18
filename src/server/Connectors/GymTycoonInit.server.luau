-- GymTycoonInit.lua
-- Main initialization script for Gym Tycoon
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Script will handle the correct load order of all systems

print("===== INITIALIZING GYM TYCOON =====")

-- Step 1: Create EventBridge if it doesn't exist
if not ReplicatedStorage:FindFirstChild("EventBridge") then
	local eventBridge = Instance.new("Folder")
	eventBridge.Name = "EventBridge"
	eventBridge.Parent = ReplicatedStorage
	print("Created EventBridge in ReplicatedStorage")

	-- Create common events
	local events = {
		"TilePurchased",
		"DuesCollected",
		"NPCSpawned",
		"GymLevelUp",
		"MilestoneReached"
	}

	for _, eventName in ipairs(events) do
		local event = Instance.new("BindableEvent")
		event.Name = eventName
		event.Parent = eventBridge
		print("Created event: " .. eventName)
	end
end

-- Step 2: Load the GymTycoonDataManager first (handles data loading/saving)
local DataManager
pcall(function()
	DataManager = require(ServerScriptService:FindFirstChild("GymTycoonDataManager"))
	print("Loaded GymTycoonDataManager")
end)

if not DataManager then
	warn("Failed to load GymTycoonDataManager - data persistence will not work!")
end

-- Step 3: Load systems in the correct order
local SystemManager = {}
SystemManager.systems = {}

-- Define system dependencies and load order
local systemDefinitions = {
	{name = "GymRevenueSystem", path = "GymRevenueSystem"},
	{name = "UnifiedTycoonSystem", path = "UnifiedTycoonSystem", dependencies = {"GymRevenueSystem"}},
	{name = "BuyTile", path = "BuyTile", dependencies = {"GymRevenueSystem", "UnifiedTycoonSystem"}},
	{name = "UnifiedNPCSystem", path = "UnifiedNPCSystem", dependencies = {"GymRevenueSystem", "UnifiedTycoonSystem"}},
	{name = "UnifiedFrontDeskSystem", path = "UnifiedFrontDeskSystem", dependencies = {"GymRevenueSystem"}}
}

-- Helper function to load a system and its dependencies
local function loadSystem(definition)
	-- Skip if already loaded
	if SystemManager.systems[definition.name] then
		return true
	end

	-- Load dependencies first
	if definition.dependencies then
		for _, depName in ipairs(definition.dependencies) do
			-- Find dependency definition
			local depDef = nil
			for _, sys in ipairs(systemDefinitions) do
				if sys.name == depName then
					depDef = sys
					break
				end
			end

			if depDef and not loadSystem(depDef) then
				warn("Failed to load dependency: " .. depName)
				return false
			end
		end
	end

	-- Load the system
	local success = pcall(function()
		local system = require(ServerScriptService:FindFirstChild(definition.path))
		SystemManager.systems[definition.name] = system
		print("Loaded system: " .. definition.name)
	end)

	return success
end

-- Load all systems
for _, definition in ipairs(systemDefinitions) do
	loadSystem(definition)
end

-- Step 4: Load the connector last (integrates all systems)
local GymTycoonConnector
pcall(function()
	GymTycoonConnector = require(ServerScriptService:FindFirstChild("GymTycoonConnector"))
	print("Loaded GymTycoonConnector")
end)

if not GymTycoonConnector then
	warn("Failed to load GymTycoonConnector - system integration may not work properly!")
end

-- Step 5: Set up for existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		if GymTycoonConnector then
			GymTycoonConnector.setupPlayer(player)
		elseif DataManager then
			-- Fallback to just loading data if connector is not available
			local data = DataManager.loadPlayerData(player)
			if data then
				DataManager.applyDataToPlayer(player)
				task.wait(3)
				DataManager.restorePurchasedEquipment(player)
			end
		end
	end)
end

print("===== GYM TYCOON INITIALIZED =====")