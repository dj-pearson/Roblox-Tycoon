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

-- Load CoreRegistry if available
local CoreRegistry
pcall(function()
	local coreRegistryPath = ServerScriptService:FindFirstChild("Core") and 
							ServerScriptService.Core:FindFirstChild("CoreRegistry")
	if coreRegistryPath then
		CoreRegistry = require(coreRegistryPath)
	end
end)

-- Load required systems with multiple fallback paths
local DataAccessLayer, BuyTileSystem, TycoonSystem

-- Try to load DataAccessLayer (new standardized data layer)
pcall(function()
	local dataLayerPath = ServerScriptService:FindFirstChild("Core") and 
						 ServerScriptService.Core:FindFirstChild("DataAccessLayer")
	if dataLayerPath then
		DataAccessLayer = require(dataLayerPath)
		debugPrint("Loaded DataAccessLayer")
	end
end)

-- Try to load systems through CoreRegistry first
if CoreRegistry then
	if not DataAccessLayer then
		DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
		if DataAccessLayer then
			debugPrint("Loaded DataAccessLayer from CoreRegistry")
		end
	end
	
	BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem")
	if BuyTileSystem then
		debugPrint("Loaded BuyTileSystem from CoreRegistry")
	end
	
	TycoonSystem = CoreRegistry:GetSystem("TycoonSystem")
	if TycoonSystem then
		debugPrint("Loaded TycoonSystem from CoreRegistry")
	end
end

-- Fallbacks for direct requires if not found in CoreRegistry
if not BuyTileSystem then
	pcall(function() 
		BuyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile")) 
		debugPrint("Loaded BuyTile system directly")
	end)
end

if not TycoonSystem then
	pcall(function() 
		TycoonSystem = require(ServerScriptService:FindFirstChild("UnifiedTycoonSystem")) 
		debugPrint("Loaded UnifiedTycoonSystem directly")
	end)
end

-- Legacy fallback for data storage if DataAccessLayer not available
local DataStorage
if not DataAccessLayer then
	pcall(function() 
		DataStorage = require(ServerScriptService:FindFirstChild("Data"):FindFirstChild("EnhancedDataStorageSystem")) 
		if not DataStorage then
			DataStorage = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"))
		end
		debugPrint("Loaded EnhancedDataStorageSystem as fallback")
	end)
end

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

-- Get player data with proper layering
function ProgressRestoration.getPlayerData(player)
	if not player then return nil end

	local data = nil

	-- Try DataAccessLayer first (preferred method)
	if DataAccessLayer then
		local success, result = pcall(function()
			return DataAccessLayer:GetAllPlayerData(player)
		end)
		
		if success and result then
			data = result
		end
	end
	
	-- Try EnhancedDataStorageSystem as fallback
	if not data and DataStorage and DataStorage.loadData then
		local success, result = pcall(function()
			return DataStorage.loadData(player)
		end)
		
		if success and result then
			data = result
		end
	end

	-- Check DataStore2 as secondary fallback
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

	-- Try any GymTycoonConnector from CoreRegistry as last resort
	if not data and CoreRegistry then
		local connector = CoreRegistry:GetSystem("GymTycoonConnector")
		if connector and connector.getPlayerData then
			local success, result = pcall(function()
				return connector.getPlayerData(player)
			end)
			
			if success and result then
				data = result
			end
		end
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
	
	-- Ensure player has a tycoon
	local tycoon = ProgressRestoration.ensurePlayerTycoon(player)
	if not tycoon then
		debugPrint("No tycoon to restore equipment to for " .. player.Name)
		return false
	end
	
	-- Get the player data
	local data = ProgressRestoration.getPlayerData(player)
	if not data then
		debugPrint("No data to restore for " .. player.Name)
		return false
	end
	
	-- Extract equipment data based on available format
	local equipment = {}
	if data.equipmentPurchased then
		-- Format: {tileId = true, ...}
		for tileId, _ in pairs(data.equipmentPurchased) do
			table.insert(equipment, tonumber(tileId))
		end
	elseif data.equipment then
		-- Format: {1, 2, 3, ...}
		equipment = data.equipment
	end
	
	if #equipment == 0 then
		debugPrint("No equipment to restore for " .. player.Name)
		return false
	end
	
	debugPrint("Attempting to restore " .. #equipment .. " pieces of equipment for " .. player.Name)
	
	-- Try to use DataAccessLayer first (preferred method)
	if DataAccessLayer then
		local success, result = pcall(function()
			return DataAccessLayer:RestorePlayerEquipment(player)
		end)
		
		if success and result then
			debugPrint("Successfully restored equipment using DataAccessLayer")
			return true
		end
	end
	
	-- Try using BuyTileSystem directly
	if BuyTileSystem then
		local success = false
		
		-- Handle different BuyTileSystem interfaces
		if typeof(BuyTileSystem.restoreEquipment) == "function" then
			success = BuyTileSystem.restoreEquipment(player, equipment)
		elseif typeof(BuyTileSystem.restorePurchasedEquipment) == "function" then
			success = BuyTileSystem.restorePurchasedEquipment(player, equipment)
		else
			-- Manual restore as last resort
			for _, tileId in ipairs(equipment) do
				task.spawn(function()
					if typeof(BuyTileSystem.spawnGymPart) == "function" then
						local part = BuyTileSystem.spawnGymPart(tileId)
						if part then
							debugPrint("Restored tile " .. tileId .. " for " .. player.Name)
						end
					elseif typeof(BuyTileSystem.handleBuyTileRequest) == "function" then
						BuyTileSystem.handleBuyTileRequest(player, tileId, true) -- Force restoration
					end
					task.wait(0.1) -- Prevent server lag from mass spawning
				end)
			end
			success = true
		end
		
		return success
	end
	
	return false
end

-- Handle player joining
function ProgressRestoration.onPlayerJoin(player)
	if not player then return end
	
	-- Wait a bit for other systems to initialize
	task.wait(3)
	
	-- Ensure tycoon exists
	local tycoon = ProgressRestoration.ensurePlayerTycoon(player)
	
	-- Restore equipment 
	task.spawn(function()
		ProgressRestoration.restorePurchasedEquipment(player)
	end)
end

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		ProgressRestoration.onPlayerJoin(player)
	end)
end)

-- Restore for existing players (in case of script reloading)
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		ProgressRestoration.onPlayerJoin(player)
	end)
end

-- Register with CoreRegistry if available
if CoreRegistry and CoreRegistry.registerSystem then
	CoreRegistry:RegisterSystem("PlayerProgressRestoration", ProgressRestoration)
	debugPrint("Registered with CoreRegistry")
end

return ProgressRestoration