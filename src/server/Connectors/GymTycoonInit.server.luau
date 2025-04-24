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
	-- Try multiple possible paths for DataManager
	DataManager = require(ServerScriptService.Data.GymTycoonDataManager) -- Preferred path
	print("Loaded GymTycoonDataManager from Data folder")
end)

if not DataManager then
	pcall(function()
		DataManager = require(ServerScriptService.Core.DataManager)
		print("Loaded DataManager from Core folder")
	end)
end

if not DataManager then
	pcall(function()
		DataManager = require(ServerScriptService:FindFirstChild("GymTycoonDataManager"))
		print("Loaded GymTycoonDataManager from ServerScriptService")
	end)
end

if not DataManager then
	-- Last resort, use EnhancedDataStorageSystem as fallback
	pcall(function()
		DataManager = require(ServerScriptService.Data.EnhancedDataStorageSystem)
		print("Using EnhancedDataStorageSystem as fallback")
	end)
end

if not DataManager then
	warn("Failed to load GymTycoonDataManager - data persistence will not work!")
end

-- Step 2.5: Load DataSystemBridge to help with integration issues
local DataSystemBridge
pcall(function()
    DataSystemBridge = require(ServerScriptService.Core.DataSystemBridge)
    print("Loaded and initialized DataSystemBridge - resolving integration issues")
end)

if not DataSystemBridge then
    warn("Failed to load DataSystemBridge - will attempt to continue without it")
end

-- Step 3: Load systems in the correct order
local SystemManager = {}
SystemManager.systems = {}

-- Define system dependencies and load order with multiple possible locations
local systemDefinitions = {
	{name = "GymRevenueSystem", paths = {
		ServerScriptService.Core.RevenueSystem,
		ServerScriptService.Essentials.GymRevenueSystem,
		ServerScriptService:FindFirstChild("GymRevenueSystem"),
		ServerScriptService:FindFirstChild("RevenueSystem")
	}},
	{name = "UnifiedTycoonSystem", paths = {
		ServerScriptService.Core.TycoonSystem,
		ServerScriptService.Essentials.UnifiedTycoonSystem,
		ServerScriptService:FindFirstChild("UnifiedTycoonSystem")
	}, dependencies = {"GymRevenueSystem"}},
	{name = "BuyTile", paths = {
		ServerScriptService.Core.BuyTileSystem,
		ServerScriptService.Essentials.BuyTile,
		ServerScriptService:FindFirstChild("BuyTile"),
		ServerScriptService:FindFirstChild("BuyTileSystem")
	}, dependencies = {"GymRevenueSystem", "UnifiedTycoonSystem"}},
	{name = "UnifiedNPCSystem", paths = {
		ServerScriptService.Core.NPCSystem,
		ServerScriptService.Enhancements.UnifiedNPCSystem,
		ServerScriptService:FindFirstChild("UnifiedNPCSystem"),
		ServerScriptService:FindFirstChild("NPCSystem")
	}, dependencies = {"GymRevenueSystem", "UnifiedTycoonSystem"}},
	{name = "UnifiedFrontDeskSystem", paths = {
		ServerScriptService.Core.FrontDeskSystem,
		ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem"),
		ServerScriptService:FindFirstChild("FrontDeskSystem")
	}, dependencies = {"GymRevenueSystem"}}
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

			-- Handle missing dependency by trying to load it manually
			if not depDef then
				print("Warning: Missing definition for dependency " .. depName .. ", trying to load directly")
				
				-- Try to load from Core folder first
				local success, result = pcall(function()
					local systemModule = require(ServerScriptService.Core:FindFirstChild(depName))
					SystemManager.systems[depName] = systemModule
					return systemModule ~= nil
				end)
				
				-- If that fails, try Essentials folder
				if not success or not result then
					success, result = pcall(function()
						local systemModule = require(ServerScriptService.Essentials:FindFirstChild(depName))
						SystemManager.systems[depName] = systemModule
						return systemModule ~= nil
					end)
				end
				
				-- If that still fails, try direct child
				if not success or not result then
					success, result = pcall(function()
						local systemModule = require(ServerScriptService:FindFirstChild(depName))
						SystemManager.systems[depName] = systemModule
						return systemModule ~= nil
					end)
				end
				
				if not success or not result then
					warn("Failed to load dependency: " .. depName)
					return false
				end
			-- Normal case - load dependency through recursive call
			elseif not loadSystem(depDef) then
				warn("Failed to load dependency: " .. depName)
				return false
			end
		end
	end
	-- Load the system using multiple possible paths
	if definition.paths then
		for _, path in ipairs(definition.paths) do
			local success, system = pcall(function()
				if path then
					return require(path)
				end
				return nil
			end)
			
			if success and system then
				SystemManager.systems[definition.name] = system
				print("Loaded system: " .. definition.name)
				return true
			end
		end
		
		warn("Failed to load system: " .. definition.name)
		return false
	else
		-- Legacy path-based loading (for backwards compatibility)
		local success = pcall(function()
			local system = require(ServerScriptService:FindFirstChild(definition.path))
			SystemManager.systems[definition.name] = system
			print("Loaded system: " .. definition.name)
		end)
		
		return success
	end
end

-- Load all systems
for _, definition in ipairs(systemDefinitions) do
	loadSystem(definition)
end

-- Step 4.5: Initialize Gym Structure Integration
local GymStructureIntegration
pcall(function()
    GymStructureIntegration = require(ServerScriptService:FindFirstChild("GymStructureIntegration"))
    GymStructureIntegration.initialize() -- Ensure the structure is initialized
    print("Initialized Gym Structure Integration")
end)

if not GymStructureIntegration then
    warn("Failed to load GymStructureIntegration - Gym structure information will not be available!")
end


-- Step 4: Load the connector last (integrates all systems)
local GymTycoonConnector
pcall(function()
	GymTycoonConnector = require(ServerScriptService.Core.GymTycoonConnector)
	print("Loaded GymTycoonConnector from Core folder")
end)

if not GymTycoonConnector then
	pcall(function()
		GymTycoonConnector = require(ServerScriptService.Connectors.GymTycoonConnector)
		print("Loaded GymTycoonConnector from Connectors folder")
	end)
end

if not GymTycoonConnector then
	pcall(function()
		GymTycoonConnector = require(ServerScriptService:FindFirstChild("GymTycoonConnector"))
		print("Loaded GymTycoonConnector from ServerScriptService")
	end)
end

if not GymTycoonConnector then
	pcall(function()
		GymTycoonConnector = require(script.Parent.GymTycoonConnector)
		print("Loaded GymTycoonConnector from script.Parent")
	end)
end

if not GymTycoonConnector then
	warn("Failed to load GymTycoonConnector - system integration may not work properly!")
end

-- Initialize connector if found
if GymTycoonConnector then
	if typeof(GymTycoonConnector) == "table" and typeof(GymTycoonConnector.initialize) == "function" then
		pcall(function()
			GymTycoonConnector:initialize()
			print("Initialized GymTycoonConnector")
		end)
	elseif typeof(GymTycoonConnector.Initialize) == "function" then
		pcall(function()
			GymTycoonConnector.Initialize()
			print("Initialized GymTycoonConnector")
		end)
	end
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