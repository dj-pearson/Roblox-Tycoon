-- SystemConnector.lua
-- Provides a compatibility layer between different systems in Gym Tycoon
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Connector module
local SystemConnector = {
	systems = {},  -- Loaded systems
	initialized = false
}

-- Debug function
local function log(...)
	print("[SystemConnector]", ...)
end

-- Try to load a system
function SystemConnector.loadSystem(name, path)
	if SystemConnector.systems[name] then
		return SystemConnector.systems[name]
	end

	local success, system = pcall(function()
		return require(ServerScriptService:FindFirstChild(path or name))
	end)

	if success and system then
		SystemConnector.systems[name] = system
		log("Loaded system:", name)
		return system
	else
		log("Failed to load system:", name)
		return nil
	end
end

-- Ensure EventBridge exists and has all needed events
function SystemConnector.ensureEventBridge()
	if not ReplicatedStorage:FindFirstChild("EventBridge") then
		local eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
		log("Created EventBridge in ReplicatedStorage")
	end

	local events = {
		"TilePurchased",   -- When player buys a new tile
		"DuesCollected",   -- When player collects membership dues
		"NPCSpawned",      -- When a new NPC is created
		"GymLevelUp",      -- When player's gym level increases
		"MilestoneReached" -- When player reaches a milestone
	}

	local eventBridge = ReplicatedStorage.EventBridge

	for _, eventName in ipairs(events) do
		if not eventBridge:FindFirstChild(eventName) then
			local event = Instance.new("BindableEvent")
			event.Name = eventName
			event.Parent = eventBridge
			log("Created event:", eventName)
		end
	end

	return eventBridge
end

-- Fix tycoon reference if it's pointing to character
function SystemConnector.fixTycoonReference(player)
	if not player then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		tycoon = Instance.new("ObjectValue")
		tycoon.Name = "Tycoon"
		tycoon.Parent = player
		log("Created Tycoon value for", player.Name)
	end

	-- Check if tycoon is incorrectly set to character
	if tycoon.Value == player.Character then
		log("Fixing incorrect tycoon reference for", player.Name)

		-- Try to find correct tycoon
		local tycoonName = player.Name .. "'s Gym"
		local playerTycoon = nil

		-- Check in Tycoons folder if it exists
		local tycoonsFolder = workspace:FindFirstChild("Tycoons")
		if tycoonsFolder then
			playerTycoon = tycoonsFolder:FindFirstChild(tycoonName)
		end

		-- Check in workspace if not found
		if not playerTycoon then
			playerTycoon = workspace:FindFirstChild(tycoonName)
		end

		-- Set the value if found
		if playerTycoon then
			tycoon.Value = playerTycoon
			log("Found existing tycoon for", player.Name)
		else
			-- Create new tycoon if needed
			local TycoonSystem = SystemConnector.loadSystem("UnifiedTycoonSystem")
			if TycoonSystem and TycoonSystem.createNewTycoon then
				local newTycoon = TycoonSystem.createNewTycoon(player)
				if newTycoon then
					tycoon.Value = newTycoon
					log("Created new tycoon for", player.Name)
				end
			else
				-- Create basic tycoon model
				playerTycoon = Instance.new("Model")
				playerTycoon.Name = player.Name .. "'s Gym"
				playerTycoon:SetAttribute("Owner", player.UserId)
				playerTycoon.Parent = workspace

				-- Create floor part
				local floor = Instance.new("Part")
				floor.Name = "Floor"
				floor.Size = Vector3.new(20, 1, 20)
				floor.Position = Vector3.new(0, 0, 0)
				floor.Anchored = true
				floor.BrickColor = BrickColor.new("Medium stone grey")
				floor.Parent = playerTycoon

				-- Set as primary part
				playerTycoon.PrimaryPart = floor

				-- Set tycoon reference
				tycoon.Value = playerTycoon
				log("Created basic tycoon model for", player.Name)
			end
		end
	end

	return tycoon.Value ~= nil
end

-- Handle buying a tile
function SystemConnector.onTilePurchased(player, tileId)
	if not player then return false end

	log("Handling tile purchase for", player.Name, "Tile ID:", tileId)

	-- Get EventBridge
	local eventBridge = SystemConnector.ensureEventBridge()

	-- Fire event
	local tilePurchasedEvent = eventBridge:FindFirstChild("TilePurchased")
	if tilePurchasedEvent then
		tilePurchasedEvent:Fire(player, tileId)
	end

	-- Update equipment count
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
		tycoon:SetAttribute("EquipmentCount", equipmentCount + 1)

		-- Check if we need to update gym tier
		local currentTier = tycoon:GetAttribute("GymTier") or 1
		local newTier = math.floor(equipmentCount / 5) + 1

		if newTier > currentTier then
			tycoon:SetAttribute("GymTier", newTier)

			-- Fire level up event
			local levelUpEvent = eventBridge:FindFirstChild("GymLevelUp")
			if levelUpEvent then
				levelUpEvent:Fire(player, newTier)
			end

			log(player.Name, "advanced to gym tier", newTier)
		end
	end

	-- Save data if DataManager is available
	local DataManager = SystemConnector.loadSystem("GymTycoonDataManager")
	if DataManager and DataManager.recordEquipmentPurchase then
		DataManager.recordEquipmentPurchase(player, tileId)
	end

	return true
end

-- Handle collecting dues
function SystemConnector.onDuesCollected(player, amount)
	if not player then return false end

	log("Handling dues collection for", player.Name, "Amount:", amount)

	-- Get EventBridge
	local eventBridge = SystemConnector.ensureEventBridge()

	-- Fire event
	local duesCollectedEvent = eventBridge:FindFirstChild("DuesCollected")
	if duesCollectedEvent then
		duesCollectedEvent:Fire(player, amount)
	end

	-- Reset accrued dues
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		tycoon:SetAttribute("AccruedDues", 0)
	end

	return true
end

-- Integration with BuyTile system
function SystemConnector.integrateBuyTileSystem()
	local BuyTileSystem = SystemConnector.loadSystem("BuyTile")
	if not BuyTileSystem then
		log("Failed to load BuyTile system, can't integrate")
		return false
	end

	-- Set the global connector if BuyTile system uses it
	if not _G.GymTycoonConnector then
		_G.GymTycoonConnector = {
			onTilePurchased = SystemConnector.onTilePurchased
		}
		log("Created global GymTycoonConnector for BuyTile compatibility")
	end

	return true
end

-- Integration with data system
function SystemConnector.integrateDataSystem()
	local DataManager = SystemConnector.loadSystem("GymTycoonDataManager")
	if not DataManager then
		-- Try loading EnhancedDataStorageSystem as fallback
		DataManager = SystemConnector.loadSystem("EnhancedDataStorageSystem")
	end

	if not DataManager then
		log("Failed to load any data manager system")
		return false
	end

	log("Integrated with data system")
	return true
end


	-- Setup player with all required components
function SystemConnector.setupPlayer(player)
	if not player then return false end

	log("Setting up", player.Name)

	-- Ensure tycoon reference is correct
	SystemConnector.fixTycoonReference(player)

	-- Load data
	local DataManager = SystemConnector.loadSystem("GymTycoonDataManager")
	if DataManager then
		DataManager.setupPlayer(player)
	else
		-- Create basic leaderstats if no data manager
		if not player:FindFirstChild("leaderstats") then
			local leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player

			local cash = Instance.new("IntValue")
			cash.Name = "Cash"
			cash.Value = 1000
			cash.Parent = leaderstats

			log("Created basic leaderstats for", player.Name)
		end


		return true
	end
	

		-- Initialize the connector
function SystemConnector.initialize()
	if SystemConnector.initialized then
		return true
	end
	

		log("Initializing system connector...")

-- Ensure EventBridge exists
SystemConnector.ensureEventBridge()

-- Load and integrate core systems
SystemConnector.integrateDataSystem()
SystemConnector.integrateBuyTileSystem()

-- Set up for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		SystemConnector.setupPlayer(player)
	end)
end


	-- Connect player events
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for player to initialize
	SystemConnector.setupPlayer(player)
end)

-- Handle character respawning (to fix tycoon references)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		SystemConnector.fixTycoonReference(player)
	end)
end)

SystemConnector.initialized = true
log("System connector initialized")
return true
end


-- Initialize the connector
SystemConnector.initialize()

-- Make connector globally accessible for legacy scripts
_G.SystemConnector = SystemConnector

return SystemConnector
end

