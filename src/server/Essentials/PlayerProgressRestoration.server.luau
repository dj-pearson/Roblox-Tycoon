-- PlayerProgressRestoration.lua
-- This script ensures player progress is properly restored between game sessions
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DEBUG_MODE = true -- Set to false for production

-- Debug function
local function debugPrint(...)
	if DEBUG_MODE then
		print("[ProgressRestoration]", ...)
	end
end

-- Load required systems
local DataStorage
local BuyTileSystem
local TycoonSystem

-- Attempt to load each dependency
pcall(function() 
	DataStorage = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem")) 
	debugPrint("Loaded EnhancedDataStorageSystem")
end)

pcall(function() 
	BuyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile")) 
	debugPrint("Loaded BuyTile system")
end)

pcall(function() 
	TycoonSystem = require(ServerScriptService:FindFirstChild("UnifiedTycoonSystem")) 
	debugPrint("Loaded UnifiedTycoonSystem")
end)

-- Create failsafe module
local ProgressRestoration = {}

-- Fix the player's tycoon reference
function ProgressRestoration.ensurePlayerTycoon(player)
	if not player then return nil end

	-- Check if player has Tycoon value
	local tycoonValue = player:FindFirstChild("Tycoon")
	if not tycoonValue then
		tycoonValue = Instance.new("ObjectValue")
		tycoonValue.Name = "Tycoon"
		tycoonValue.Parent = player
		debugPrint("Created Tycoon value for " .. player.Name)
	end

	-- Check if the Tycoon value is valid
	if not tycoonValue.Value or not tycoonValue.Value:IsA("Model") then
		-- Try to find the player's tycoon in the workspace
		local tycoonName = player.Name .. "'s Gym"
		local tycoon = nil

		-- Check in Tycoons folder if it exists
		local tycoonsFolder = Workspace:FindFirstChild("Tycoons")
		if tycoonsFolder then
			tycoon = tycoonsFolder:FindFirstChild(tycoonName)
		end

		-- Check in workspace if not found
		if not tycoon then
			tycoon = Workspace:FindFirstChild(tycoonName)
		end

		-- If tycoon not found, check for any model with player as the owner
		if not tycoon then
			for _, model in pairs(Workspace:GetChildren()) do
				if model:IsA("Model") and model:GetAttribute("Owner") == player.UserId then
					tycoon = model
					break
				end
			end
		end

		-- Set the value if found
		if tycoon then
			tycoonValue.Value = tycoon
			debugPrint("Found and set existing tycoon for " .. player.Name)
		else
			debugPrint("Could not find existing tycoon for " .. player.Name)
			-- Create new tycoon if needed
			if TycoonSystem and TycoonSystem.createNewTycoon then
				local newTycoon = TycoonSystem.createNewTycoon(player)
				if newTycoon then 
					tycoonValue.Value = newTycoon
					debugPrint("Created new tycoon for " .. player.Name)
				end
			end
		end
	end

	return tycoonValue.Value
end

-- Get player data with fallback for different data stores
function ProgressRestoration.getPlayerData(player)
	if not player then return nil end

	local data = nil

	-- Try EnhancedDataStorageSystem first
	if DataStorage and DataStorage.loadData then
		pcall(function()
			data = DataStorage.loadData(player)
		end)
	end

	-- Check DataStore2 as fallback
	if not data then
		local DataStore2
		pcall(function()
			DataStore2 = require(ServerScriptService:FindFirstChild("DataStore2"))
		end)

		if DataStore2 then
			pcall(function()
				local equipmentStore = DataStore2("Equipment", player)
				local equipment = equipmentStore:Get({})
				data = {
					equipmentPurchased = equipment
				}
			end)
		end
	end

	-- Try _G.GymTycoonConnector as a last resort
	if not data and _G.GymTycoonConnector and _G.GymTycoonConnector.getPlayerData then
		pcall(function()
			data = _G.GymTycoonConnector.getPlayerData(player)
		end)
	end

	if not data then
		debugPrint("Could not retrieve data for " .. player.Name)
		return nil
	end

	debugPrint("Retrieved data for " .. player.Name)
	return data
end

-- Improved equipment restoration function
function ProgressRestoration.restorePurchasedEquipment(player)
	if not player then return false end

	-- Ensure player has a tycoon first
	local tycoon = ProgressRestoration.ensurePlayerTycoon(player)
	if not tycoon then
		debugPrint("Failed to ensure tycoon for " .. player.Name)
		return false
	end

	-- Get player data
	local data = ProgressRestoration.getPlayerData(player)
	if not data then
		debugPrint("No data to restore for " .. player.Name)
		return false
	end

	-- Check for equipment data
	if not data.equipmentPurchased or type(data.equipmentPurchased) ~= "table" then
		debugPrint("No equipment data to restore for " .. player.Name)
		return false
	end

	-- Get the BuyTile system
	if not BuyTileSystem or not BuyTileSystem.spawnGymPart then
		debugPrint("BuyTile system not available or missing spawnGymPart function")
		-- Try to get the global function as fallback
		if _G.spawnGymPart then
			BuyTileSystem = {
				spawnGymPart = _G.spawnGymPart,
				spawnBuyTile = _G.spawnBuyTile or function() end
			}
		else
			return false
		end
	end

	-- Get purchased tile IDs
	local purchasedTiles = {}
	for tileId, _ in pairs(data.equipmentPurchased) do
		local id = tonumber(tileId) or tonumber(string.match(tileId, "%d+"))
		if id then
			table.insert(purchasedTiles, id)
		end
	end

	-- Sort IDs to purchase in order
	table.sort(purchasedTiles)

	debugPrint("Restoring " .. #purchasedTiles .. " equipment pieces for " .. player.Name)

	-- Track successful spawns
	local spawnCount = 0

	-- Make sure front desk exists first (tile ID 1)
	local frontDeskSpawned = false

	-- Check if front desk already exists
	if tycoon:FindFirstChild("Front Desk") then
		frontDeskSpawned = true
		spawnCount = spawnCount + 1
		debugPrint("Front desk already exists for " .. player.Name)
	else
		-- Try to spawn front desk (usually tile ID 1)
		if BuyTileSystem.spawnGymPart then
			local frontDesk = BuyTileSystem.spawnGymPart(1)
			if frontDesk then
				frontDeskSpawned = true
				spawnCount = spawnCount + 1
				debugPrint("Spawned front desk for " .. player.Name)

				-- Ensure it's properly parented to tycoon
				if frontDesk.Parent ~= tycoon then
					frontDesk.Parent = tycoon
				end
			end
		end
	end

	-- Spawn each remaining tile with a delay between
	for _, tileId in ipairs(purchasedTiles) do
		-- Skip ID 1 if already processed
		if tileId == 1 and frontDeskSpawned then
			continue
		end

		task.wait(0.1) -- Slight delay to prevent issues

		-- Check if the part already exists in the tycoon
		local exists = false
		for _, part in pairs(tycoon:GetDescendants()) do
			if part:GetAttribute("ID") == tileId then
				exists = true
				spawnCount = spawnCount + 1
				debugPrint("Equipment ID " .. tileId .. " already exists for " .. player.Name)
				break
			end
		end

		if not exists then
			-- Try to spawn gym part
			local part = BuyTileSystem.spawnGymPart(tileId)
			if part then
				-- Ensure it's properly parented to tycoon
				if part.Parent ~= tycoon then
					part.Parent = tycoon
				end

				spawnCount = spawnCount + 1
				debugPrint("Restored gym part " .. tileId .. " for " .. player.Name)
			else
				debugPrint("Failed to restore gym part " .. tileId .. " for " .. player.Name)
			end
		end
	end

	-- Update equipment count on tycoon
	player:FindFirstChild("Tycoon"):SetAttribute("EquipmentCount", spawnCount)

	debugPrint("Successfully restored " .. spawnCount .. "/" .. #purchasedTiles .. " equipment pieces for " .. player.Name)

	-- Make sure the front desk is set up properly
	pcall(function()
		local FrontDeskSystem = require(ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem"))
		if FrontDeskSystem and FrontDeskSystem.updateFrontDeskDisplay then
			task.spawn(function()
				task.wait(1) -- Wait for tycoon to be fully set up
				FrontDeskSystem.updateFrontDeskDisplay(player)
			end)
		end
	end)

	return true
end

-- Additional function to set up everything a player needs
function ProgressRestoration.setupPlayer(player)
	if not player then return false end

	-- Ensure leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Value = 1000 -- Default starting cash
		cashValue.Parent = leaderstats
	end

	-- Ensure tycoon
	local tycoon = ProgressRestoration.ensurePlayerTycoon(player)

	-- Restore equipment with delay
	task.spawn(function()
		task.wait(3) -- Wait for everything to initialize
		ProgressRestoration.restorePurchasedEquipment(player)
	end)

	return true
end

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for player to fully load
	ProgressRestoration.setupPlayer(player)
end)

-- Check existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2) -- Wait to avoid conflicts with other initializing scripts
		ProgressRestoration.setupPlayer(player)
	end)
end

-- Export the module
return ProgressRestoration