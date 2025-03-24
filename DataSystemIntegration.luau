-- DataSystemIntegration.lua
-- This script integrates the enhanced data storage system with your existing systems
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the enhanced data storage system
local EnhancedDataStorage
pcall(function()
	EnhancedDataStorage = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"))
end)

-- Load the existing BuyTile system
local BuyTileSystem
pcall(function()
	BuyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
end)

-- Check if EventBridge exists, create if needed
local function ensureEventBridge()
	if not ReplicatedStorage:FindFirstChild("EventBridge") then
		local eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
		print("[DataSystemIntegration] Created EventBridge in ReplicatedStorage")
	end

	-- Ensure TilePurchased event exists
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not eventBridge:FindFirstChild("TilePurchased") then
		local event = Instance.new("BindableEvent")
		event.Name = "TilePurchased"
		event.Parent = eventBridge
		print("[DataSystemIntegration] Created TilePurchased event in EventBridge")
	end

	return ReplicatedStorage:FindFirstChild("EventBridge")
end

-- Connect BuyTile system to enhanced data storage
local function connectBuyTileSystem()
	if not BuyTileSystem then
		warn("[DataSystemIntegration] BuyTile system not found, cannot connect to data storage")
		return false
	end

	-- Check if the original handleTilePurchase function exists
	if not BuyTileSystem.handleTilePurchase then
		warn("[DataSystemIntegration] BuyTile.handleTilePurchase function not found")
		return false
	end

	-- Create a wrapper for the tile purchase handler that adds data storage
	local originalHandleTilePurchase = BuyTileSystem.handleTilePurchase

	BuyTileSystem.handleTilePurchase = function(buyTile)
		-- Call the original function first
		originalHandleTilePurchase(buyTile)

		-- Get the tile ID and price
		local id = buyTile:GetAttribute("ID")
		if not id then return end

		-- Set up a touched event that also records the purchase in data storage
		local buyTilePart = buyTile:FindFirstChild("BuyTilePart")
		if not buyTilePart then return end

		-- Make a copy of the original touched connection with data storage
		buyTilePart.Touched:Connect(function(hit)
			-- Find the player who touched the part
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end

			-- Check if player has leaderstats and Cash stat
			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats or not leaderstats:FindFirstChild("Cash") then return end

			local cashStat = leaderstats.Cash
			local price = buyTile:GetAttribute("Price") or 0

			-- Check if player has enough cash and purchased the tile
			if cashStat.Value >= price then
				-- This means the purchase went through
				-- Record in data storage
				if EnhancedDataStorage then
					EnhancedDataStorage.recordEquipmentPurchase(player, id)
					print("[DataSystemIntegration] Recorded purchase of tile " .. id .. " for " .. player.Name)

					-- Trigger save soon after purchase
					task.delay(5, function()
						if player and player.Parent then
							EnhancedDataStorage.saveData(player, false)
						end
					end)
				end

				-- Fire event
				local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
				if EventBridge then
					local tileEvent = EventBridge:FindFirstChild("TilePurchased")
					if tileEvent then
						tileEvent:Fire(player, id)
					end
				end
			end
		end)
	end

	print("[DataSystemIntegration] Successfully connected BuyTile system to enhanced data storage")
	return true
end


	-- Main initialization function
local function initialize()
	print("[DataSystemIntegration] Initializing data system integration...")

	-- Check if enhanced data storage was loaded
	if not EnhancedDataStorage then
		warn("[DataSystemIntegration] Enhanced data storage system not found!")
		return false
	end

	-- Ensure EventBridge exists
	ensureEventBridge()

	-- Connect BuyTile system to enhanced data storage
	connectBuyTileSystem()

	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			-- Make sure player data is loaded
			if EnhancedDataStorage.loadedData[player.UserId] == nil then
				local data = EnhancedDataStorage.loadData(player)
				if data then
					EnhancedDataStorage.applyDataToPlayer(player)

					-- Wait for tycoon to be fully set up
					task.wait(5)

					-- Restore purchased equipment
					EnhancedDataStorage.restorePurchasedEquipment(player)
				end
			end
		end)
	end

	print("[DataSystemIntegration] Data system integration complete!")
	return true
end


	-- Initialize the system
initialize()