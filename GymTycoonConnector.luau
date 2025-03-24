-- GymTycoonConnector.lua
-- Central connector for all gym tycoon systems
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Debug config
local DEBUG = true

-- Debug print function
local function debugPrint(...)
	if DEBUG then
		print("[GymTycoonConnector]", ...)
	end
end

-- Import systems with robust error handling
local systems = {}

-- Function to safely require a module
local function safeRequire(path, systemName)
	local success, result = pcall(function()
		return require(path)
	end)

	if success and result then
		systems[systemName] = result
		debugPrint(systemName .. " loaded successfully")
		return result
	else
		warn("[GymTycoonConnector] Failed to load " .. systemName .. ": " .. tostring(result))
		return nil
	end
end

-- Load all required systems
local DataManager = safeRequire(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"), "DataManager")
local EconomySystem = safeRequire(ServerScriptService:FindFirstChild("GymRevenueSystem"), "EconomySystem")
local BuyTileSystem = safeRequire(ServerScriptService:FindFirstChild("BuyTile"), "BuyTileSystem")
local TycoonSystem = safeRequire(ServerScriptService:FindFirstChild("UnifiedTycoonSystem"), "TycoonSystem")
local NPCSystem = safeRequire(ServerScriptService:FindFirstChild("NPCSystemIntegration"), "NPCSystem")
local FrontDeskSystem = safeRequire(ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem"), "FrontDeskSystem")

-- Create the connector
local GymTycoonConnector = {}

-- Ensure event bridge exists
local function ensureEventBridge()
	if not ReplicatedStorage:FindFirstChild("EventBridge") then
		local eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
		debugPrint("Created EventBridge in ReplicatedStorage")
	end

	return ReplicatedStorage:FindFirstChild("EventBridge")
end

-- Create or get event
local function getOrCreateEvent(name)
	local eventBridge = ensureEventBridge()

	if not eventBridge:FindFirstChild(name) then
		local event = Instance.new("BindableEvent") 
		event.Name = name
		event.Parent = eventBridge
		debugPrint("Created " .. name .. " event in EventBridge")
	end

	return eventBridge:FindFirstChild(name)
end

-- Initialize events
local TilePurchasedEvent = getOrCreateEvent("TilePurchased")
local DuesCollectedEvent = getOrCreateEvent("DuesCollected")
local NPCSpawnedEvent = getOrCreateEvent("NPCSpawned")
local GymLevelUpEvent = getOrCreateEvent("GymLevelUp")

-- Handle tile purchase (robust implementation)
function GymTycoonConnector.onTilePurchased(player, tileId)
	if not player or not tileId then
		warn("[GymTycoonConnector] Invalid parameters for onTilePurchased")
		return false
	end

	debugPrint("Tile " .. tileId .. " purchased by " .. player.Name)

	-- Update tycoon attributes directly
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		-- Create Tycoon ObjectValue if it doesn't exist
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon" 
		tycoon.Parent = player
		debugPrint("Created missing Tycoon value for " .. player.Name)
	end

	-- Update equipment count
	local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
	tycoon:SetAttribute("EquipmentCount", equipmentCount + 1)
	debugPrint("Updated equipment count for " .. player.Name .. " to " .. (equipmentCount + 1))

	-- Handle special cases
	if tonumber(tileId) == 1 then
		-- Mark player as having started their tycoon
		tycoon:SetAttribute("TycoonStarted", true)
		debugPrint("Set TycoonStarted flag for " .. player.Name)
	end

	-- Update gym tier if needed (1 tier per 5 equipment pieces)
	local newTier = math.floor((equipmentCount + 1) / 5) + 1
	local currentTier = tycoon:GetAttribute("GymTier") or 1

	if newTier > currentTier then
		tycoon:SetAttribute("GymTier", newTier)
		debugPrint(player.Name .. " advanced to tier " .. newTier)

		-- Fire tier up event
		GymLevelUpEvent:Fire(player, newTier)
	end

	-- Record purchase in data storage
	if systems.DataManager and systems.DataManager.recordEquipmentPurchase then
		systems.DataManager.recordEquipmentPurchase(player, tileId)
		debugPrint("Recorded purchase in data storage")
	end

	-- Fire the event for other systems
	TilePurchasedEvent:Fire(player, tileId)

	return true
end

-- Handle dues collection with retry logic
function GymTycoonConnector.onDuesCollected(player)
	if not player then return false end

	-- Get tycoon reference
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Get accrued dues
	local dues = tycoon:GetAttribute("AccruedDues") or 0

	-- Skip if no dues
	if dues <= 0 then
		debugPrint("No dues to collect for " .. player.Name)
		return false
	end

	-- Reset dues
	tycoon:SetAttribute("AccruedDues", 0)

	-- Add to player's cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		-- Create leaderstats if missing
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cashValue = leaderstats:FindFirstChild("Cash")
	if not cashValue then
		-- Create Cash if missing
		cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
		cashValue.Value = 0
	end

	-- Update cash
	cashValue.Value = cashValue.Value + dues
	debugPrint(player.Name .. " collected $" .. dues .. " in dues")

	-- Fire event
	DuesCollectedEvent:Fire(player, dues)

	-- Update front desk
	if systems.FrontDeskSystem and systems.FrontDeskSystem.updateFrontDeskDisplay then
		systems.FrontDeskSystem.updateFrontDeskDisplay(player)
	end

	return true
end

-- Fix tycoon reference if it's pointing to character
function GymTycoonConnector.fixTycoonReference(player)
	if not player then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
		debugPrint("Created Tycoon value for " .. player.Name)
	end

	-- Check if tycoon is incorrectly set to character
	if tycoon.Value == player.Character then
		debugPrint("Fixing incorrect tycoon reference for " .. player.Name)

		-- Try to find correct tycoon
		local correctTycoon = nil

		-- Method 1: Check for a tycoon with player's name in Workspace.Tycoons
		local tycoonsFolder = workspace:FindFirstChild("Tycoons")
		if tycoonsFolder then
			correctTycoon = tycoonsFolder:FindFirstChild(player.Name .. "'s Gym")
		end

		-- Method 2: Check directly in workspace
		if not correctTycoon then
			correctTycoon = workspace:FindFirstChild(player.Name .. "'s Gym")
		end

		-- Method 3: Use TycoonSystem if available
		if not correctTycoon and systems.TycoonSystem and systems.TycoonSystem.findPlayerTycoon then
			correctTycoon = systems.TycoonSystem.findPlayerTycoon(player)
		end

		-- Update reference if found
		if correctTycoon then
			tycoon.Value = correctTycoon
			debugPrint("Fixed tycoon reference for " .. player.Name)
			return true
		else
			-- Create new tycoon as last resort
			if systems.TycoonSystem and systems.TycoonSystem.createNewTycoon then
				local newTycoon = systems.TycoonSystem.createNewTycoon(player)
				if newTycoon then
					tycoon.Value = newTycoon
					debugPrint("Created new tycoon for " .. player.Name)
					return true
				end
			end
		end
	end

	return tycoon.Value ~= nil
end

-- Set up player with all required components
function GymTycoonConnector.setupPlayer(player)
	if not player then return false end

	debugPrint("Setting up player: " .. player.Name)

	-- Create leaderstats if needed
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 1000 -- Default starting cash
		cash.Parent = leaderstats

		debugPrint("Created leaderstats for " .. player.Name)
	end

	-- Ensure tycoon reference is correct
	GymTycoonConnector.fixTycoonReference(player)

	-- Load data with retry logic
	if systems.DataManager then
		task.spawn(function()
			local success = false
			local attempts = 0

			while not success and attempts < 3 do
				attempts = attempts + 1

				if systems.DataManager.loadPlayerData then
					local data = systems.DataManager.loadPlayerData(player)
					if data then
						if systems.DataManager.applyDataToPlayer then
							systems.DataManager.applyDataToPlayer(player)
							success = true
							debugPrint("Successfully loaded and applied data for " .. player.Name)
						end
					end
				elseif systems.DataManager.loadData then
					local data = systems.DataManager.loadData(player)
					if data then
						if systems.DataManager.applyDataToPlayer then
							systems.DataManager.applyDataToPlayer(player)
							success = true
							debugPrint("Successfully loaded and applied data for " .. player.Name)
						end
					end
				end

				if not success then
					task.wait(1) -- Wait before retry
				end
			end

			-- Restore purchased equipment
			task.wait(3) -- Wait for tycoon to be fully set up

			if success and systems.DataManager.restorePurchasedEquipment then
				systems.DataManager.restorePurchasedEquipment(player)
				debugPrint("Restored purchased equipment for " .. player.Name)
			end
		end)
	end

	-- Check if tycoon is fully set up
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		-- Create new tycoon if needed
		if systems.TycoonSystem and systems.TycoonSystem.ensurePlayerTycoon then
			systems.TycoonSystem.ensurePlayerTycoon(player)
			debugPrint("Ensured tycoon exists for " .. player.Name)
		end
	end

	-- Update front desk
	if systems.FrontDeskSystem and systems.FrontDeskSystem.updateFrontDeskDisplay then
		task.spawn(function()
			task.wait(2) -- Wait for tycoon to be fully set up
			systems.FrontDeskSystem.updateFrontDeskDisplay(player)
			debugPrint("Updated front desk display for " .. player.Name)
		end)
	end

	return true
end

-- Connect to player events
function GymTycoonConnector.connectEvents()
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) -- Wait for player to initialize
		GymTycoonConnector.setupPlayer(player)
	end)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		if systems.DataManager then
			-- Handle different data manager APIs
			if systems.DataManager.savePlayerData then
				systems.DataManager.savePlayerData(player, true) -- Save immediately
			elseif systems.DataManager.saveData then
				systems.DataManager.saveData(player, true) -- Save immediately
			end

			debugPrint("Saved data for leaving player: " .. player.Name)
		end
	end)

	-- Handle character respawning
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(1)
			GymTycoonConnector.fixTycoonReference(player)
		end)
	end)

	debugPrint("Events connected")
end

-- Initialize the system
function GymTycoonConnector.initialize()
	debugPrint("Initializing...")

	-- Set up key events
	TilePurchasedEvent.Event:Connect(function(player, tileId)
		-- Update economy system
		if systems.EconomySystem and systems.EconomySystem.onTilePurchased then
			systems.EconomySystem.onTilePurchased(player, tileId)
		end

		-- Update front desk
		if systems.FrontDeskSystem and systems.FrontDeskSystem.updateFrontDeskDisplay then
			systems.FrontDeskSystem.updateFrontDeskDisplay(player)
		end
	end)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			GymTycoonConnector.setupPlayer(player)
		end)
	end

	debugPrint("Initialized")
	return true
end

-- Make connector globally accessible
_G.GymTycoonConnector = GymTycoonConnector

-- Initialize the connector
GymTycoonConnector.initialize()
GymTycoonConnector.connectEvents()

return GymTycoonConnector