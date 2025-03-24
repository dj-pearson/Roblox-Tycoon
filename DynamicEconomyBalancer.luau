-- DynamicEconomyBalancer.lua
-- Place this in ServerScriptService
-- This script scans all BuyTiles, adjusts pricing and income scaling
-- to make progression more challenging based on completion percentage

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Helper function to ensure values are numbers
local function ensureNumber(value)
	if type(value) == "string" then
		return tonumber(value) or 0
	end
	return value
end

-- Try to load EconomySystem
local EconomySystem
pcall(function()
	EconomySystem = require(ServerScriptService:FindFirstChild("UnifiedGymEconomySystem"))
end)

-- Configuration
local CONFIG = {
	-- Tile pricing curve
	initial_price = 100,           -- First tile price
	final_price = 100000,          -- Last tile price
	curve_steepness = 1.15,        -- Higher = steeper exponential growth

	-- Income factors
	base_income_initial = 15,      -- Starting base income
	base_income_final = 25,        -- Max base income
	income_scaling_factor = 0.8,   -- Lower = slower income growth (0-1)

	-- NPC membership fee scaling
	npc_fee_min = 15,              -- Minimum NPC membership fee
	npc_fee_max = 45,              -- Maximum NPC membership fee
	vip_multiplier = 3,            -- VIP members pay this much more

	-- Thresholds
	early_game_threshold = 0.2,    -- % of completion considered "early game"
	mid_game_threshold = 0.6,      -- % of completion considered "mid game"

	-- Difficulty scaling
	early_game_multiplier = 1.0,   -- Early game income multiplier
	mid_game_multiplier = 0.8,     -- Mid game income multiplier
	late_game_multiplier = 0.6,    -- Late game income multiplier

	-- Price jumps
	price_jump_thresholds = {      -- Add price spikes at these completion %
		[0.25] = 1.5,              -- 25% completion = 1.5x price multiplier
		[0.5] = 2.0,               -- 50% completion = 2.0x price multiplier
		[0.75] = 3.0,              -- 75% completion = 3.0x price multiplier
	},

	-- Misc settings
	debug = true,                  -- Print debug information
	update_interval = 60,          -- Run analysis every 60 seconds
	apply_changes = true           -- Actually apply the calculated values
}

-- Module
local DynamicEconomyBalancer = {}

-- Variables
local totalBuyTileCount = 0           -- Total number of BuyTiles in the game
local analyzedBuyTiles = {}           -- Table of analyzed BuyTiles with their calculated prices
local gameCompletionStats = {         -- Game completion statistics
	totalTileCount = 0,
	maxTileId = 0,
	completionPercentageByTileCount = 0,
	completionPercentageByTileId = 0,
	currentPhase = "early_game",      -- "early_game", "mid_game", or "late_game"
}

-- Debug print function
local function debugPrint(...)
	if CONFIG.debug then
		print("[EconomyBalancer]", ...)
	end
end

-- Find all BuyTiles in ServerStorage
local function findAllBuyTiles()
	local buyTiles = {}
	local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")

	if not buyTilesFolder then
		debugPrint("BuyTiles folder not found in ServerStorage!")
		return buyTiles
	end

	-- Recursive function to find all buy tiles
	local function findBuyTilesInFolder(folder)
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Model") and item:GetAttribute("ID") then
				table.insert(buyTiles, item)
			elseif item:IsA("Folder") then
				findBuyTilesInFolder(item)
			end
		end
	end

	findBuyTilesInFolder(buyTilesFolder)

	-- Sort by ID - FIX: Ensure IDs are treated as numbers during comparison
	table.sort(buyTiles, function(a, b)
		local idA = ensureNumber(a:GetAttribute("ID"))
		local idB = ensureNumber(b:GetAttribute("ID"))
		return idA < idB
	end)

	return buyTiles
end

-- Calculate prices and completion stats
local function analyzeBuyTiles()
	local buyTiles = findAllBuyTiles()
	totalBuyTileCount = #buyTiles

	if totalBuyTileCount == 0 then
		debugPrint("No BuyTiles found! Cannot calculate economy.")
		return
	end

	debugPrint("Found " .. totalBuyTileCount .. " BuyTiles for economy calculation")

	-- Reset analyzed tiles
	analyzedBuyTiles = {}

	-- Find the highest tile ID
	local maxId = 0
	for _, tile in ipairs(buyTiles) do
		local id = ensureNumber(tile:GetAttribute("ID"))
		maxId = math.max(maxId, id)
	end

	-- Update completion stats
	gameCompletionStats.totalTileCount = totalBuyTileCount
	gameCompletionStats.maxTileId = maxId

	-- Analyze each BuyTile and calculate its price
	for _, tile in ipairs(buyTiles) do
		local id = ensureNumber(tile:GetAttribute("ID"))
		local completionPercentage = id / maxId

		-- Calculate base price using exponential curve
		local priceRange = CONFIG.final_price - CONFIG.initial_price
		local basePrice = CONFIG.initial_price + priceRange * (CONFIG.curve_steepness ^ (completionPercentage * 10) - 1) / (CONFIG.curve_steepness ^ 10 - 1)

		-- Apply price jumps at thresholds
		local priceMultiplier = 1
		for threshold, multiplier in pairs(CONFIG.price_jump_thresholds) do
			if completionPercentage >= threshold and completionPercentage < threshold + 0.05 then
				priceMultiplier = multiplier
				break
			end
		end

		-- Final price calculation
		local finalPrice = math.floor(basePrice * priceMultiplier)

		-- Store the analysis
		analyzedBuyTiles[id] = {
			model = tile,
			id = id,
			completionPercentage = completionPercentage,
			basePrice = basePrice,
			priceMultiplier = priceMultiplier,
			finalPrice = finalPrice
		}
	end

	-- Debug output of price curve
	if CONFIG.debug then
		debugPrint("Buy Tile Price Curve:")
		debugPrint("---------------------")
		for i = 1, maxId do
			if analyzedBuyTiles[i] then
				local tile = analyzedBuyTiles[i]
				debugPrint(string.format("Tile ID %2d: $%s (%.1f%% completion, x%.1f multiplier)", 
					i, 
					tostring(tile.finalPrice),
					tile.completionPercentage * 100,
					tile.priceMultiplier))
			end
		end
	end

	return analyzedBuyTiles
end

-- Apply calculated prices to BuyTiles
local function applyPrices()
	if not CONFIG.apply_changes then
		debugPrint("Price application disabled in configuration.")
		return
	end

	local appliedCount = 0

	for id, tileInfo in pairs(analyzedBuyTiles) do
		local tile = tileInfo.model

		-- Set the price attribute
		tile:SetAttribute("Price", tileInfo.finalPrice)

		-- Calculate income bonus
		local progressionPhase = "early_game"
		if tileInfo.completionPercentage > CONFIG.mid_game_threshold then
			progressionPhase = "late_game"
		elseif tileInfo.completionPercentage > CONFIG.early_game_threshold then
			progressionPhase = "mid_game"
		end

		-- Calculate income bonus based on progression phase
		local baseIncomeRange = CONFIG.base_income_final - CONFIG.base_income_initial
		local baseIncome = CONFIG.base_income_initial + (baseIncomeRange * tileInfo.completionPercentage)

		-- Apply phase-based scaling
		local phaseMultiplier = CONFIG.early_game_multiplier
		if progressionPhase == "mid_game" then
			phaseMultiplier = CONFIG.mid_game_multiplier
		elseif progressionPhase == "late_game" then
			phaseMultiplier = CONFIG.late_game_multiplier
		end

		-- Calculate final income bonus using non-linear scaling
		local incomeBonus = math.floor(baseIncome * phaseMultiplier * (CONFIG.income_scaling_factor ^ id))

		-- Set income bonus attribute
		tile:SetAttribute("IncomeBonus", incomeBonus)

		appliedCount = appliedCount + 1
	end

	debugPrint("Applied calculated prices to " .. appliedCount .. " BuyTiles")
end

-- Calculate game completion statistics
local function updateCompletionStats()
	-- Get the average completion percentage across all players
	local totalCompletion = 0
	local playerCount = 0

	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			local equipmentCount = ensureNumber(tycoon:GetAttribute("EquipmentCount"))
			if gameCompletionStats.totalTileCount > 0 then
				local playerCompletion = equipmentCount / gameCompletionStats.totalTileCount
				totalCompletion = totalCompletion + playerCompletion
				playerCount = playerCount + 1
			end
		end
	end

	if playerCount > 0 then
		gameCompletionStats.completionPercentageByTileCount = totalCompletion / playerCount
	else
		gameCompletionStats.completionPercentageByTileCount = 0
	end

	-- Determine game phase
	if gameCompletionStats.completionPercentageByTileCount >= CONFIG.mid_game_threshold then
		gameCompletionStats.currentPhase = "late_game"
	elseif gameCompletionStats.completionPercentageByTileCount >= CONFIG.early_game_threshold then
		gameCompletionStats.currentPhase = "mid_game"
	else
		gameCompletionStats.currentPhase = "early_game"
	end

	debugPrint("Game Statistics:")
	debugPrint("- Average Completion: " .. string.format("%.1f%%", gameCompletionStats.completionPercentageByTileCount * 100))
	debugPrint("- Current Phase: " .. gameCompletionStats.currentPhase)

	return gameCompletionStats
end

-- Update Economy System configuration if available
local function patchEconomySystem()
	if not EconomySystem then
		debugPrint("EconomySystem not found, cannot patch configuration.")
		return
	end

	if not EconomySystem.CONFIG then
		debugPrint("EconomySystem does not have CONFIG table, cannot patch.")
		return
	end

	if not CONFIG.apply_changes then
		debugPrint("Economy patching disabled in configuration.")
		return
	end

	-- Copy original config for reference
	local originalConfig = {}
	for key, value in pairs(EconomySystem.CONFIG) do
		originalConfig[key] = value
	end

	-- Calculate new values based on game progression
	local completion = gameCompletionStats.completionPercentageByTileCount
	local phase = gameCompletionStats.currentPhase

	-- Patch NPC income values
	if phase == "early_game" then
		EconomySystem.CONFIG.baseIncomeAmount = CONFIG.base_income_initial
		EconomySystem.CONFIG.npcBaseIncome = CONFIG.npc_fee_min
	elseif phase == "mid_game" then
		-- Scale between min and max based on completion
		local scaleFactor = (completion - CONFIG.early_game_threshold) / 
			(CONFIG.mid_game_threshold - CONFIG.early_game_threshold)

		local baseIncome = CONFIG.base_income_initial + 
			(CONFIG.base_income_final - CONFIG.base_income_initial) * scaleFactor * 0.5

		local npcFee = CONFIG.npc_fee_min + 
			(CONFIG.npc_fee_max - CONFIG.npc_fee_min) * scaleFactor * 0.5

		EconomySystem.CONFIG.baseIncomeAmount = math.floor(baseIncome)
		EconomySystem.CONFIG.npcBaseIncome = math.floor(npcFee)
	else -- late_game
		local scaleFactor = (completion - CONFIG.mid_game_threshold) / 
			(1 - CONFIG.mid_game_threshold)

		local baseIncome = CONFIG.base_income_initial + 
			(CONFIG.base_income_final - CONFIG.base_income_initial) * 
			(0.5 + scaleFactor * 0.5)

		local npcFee = CONFIG.npc_fee_min + 
			(CONFIG.npc_fee_max - CONFIG.npc_fee_min) * 
			(0.5 + scaleFactor * 0.5)

		EconomySystem.CONFIG.baseIncomeAmount = math.floor(baseIncome)
		EconomySystem.CONFIG.npcBaseIncome = math.floor(npcFee)
	end

	-- Adjust difficulty based on phase
	if phase == "early_game" then
		EconomySystem.CONFIG.equipmentIncomeMultiplier = 1.5 * CONFIG.early_game_multiplier
		EconomySystem.CONFIG.tierMultiplier = 1.2 * CONFIG.early_game_multiplier
	elseif phase == "mid_game" then 
		EconomySystem.CONFIG.equipmentIncomeMultiplier = 1.5 * CONFIG.mid_game_multiplier
		EconomySystem.CONFIG.tierMultiplier = 1.2 * CONFIG.mid_game_multiplier
	else -- late_game
		EconomySystem.CONFIG.equipmentIncomeMultiplier = 1.5 * CONFIG.late_game_multiplier
		EconomySystem.CONFIG.tierMultiplier = 1.2 * CONFIG.late_game_multiplier
	end

	-- Ensure VIP multiplier is consistent
	EconomySystem.CONFIG.vipNpcMultiplier = CONFIG.vip_multiplier

	-- Log changes
	debugPrint("Patched EconomySystem configuration based on game progression:")
	for key, newValue in pairs(EconomySystem.CONFIG) do
		if originalConfig[key] ~= newValue then
			debugPrint("- " .. key .. ": " .. tostring(originalConfig[key]) .. " -> " .. tostring(newValue))
		end
	end
end

-- Create startup indicator value
local function createStartupIndicator()
	local indicator = ReplicatedStorage:FindFirstChild("DynamicEconomyActive")
	if not indicator then
		indicator = Instance.new("BoolValue")
		indicator.Name = "DynamicEconomyActive"
		indicator.Value = true
		indicator.Parent = ReplicatedStorage
	end
end

-- Main update function
function DynamicEconomyBalancer.update()
	-- Use pcall to prevent errors from breaking the script
	local success, result = pcall(function()
		debugPrint("Running economy analysis and update...")

		-- Find and analyze buy tiles
		analyzeBuyTiles()

		-- Update game completion statistics
		updateCompletionStats()

		-- Apply calculated prices to buy tiles
		applyPrices()

		-- Patch economy system if available
		patchEconomySystem()

		debugPrint("Economy update complete!")
	end)

	if not success then
		warn("[EconomyBalancer] Error during update: " .. tostring(result))
	end
end

-- Initialize the balancer
function DynamicEconomyBalancer.initialize()
	debugPrint("Initializing Dynamic Economy Balancer...")

	-- Create startup indicator
	createStartupIndicator()

	-- Run initial update
	DynamicEconomyBalancer.update()

	-- Set up periodic updates
	task.spawn(function()
		while true do
			task.wait(CONFIG.update_interval)
			DynamicEconomyBalancer.update()
		end
	end)

	-- Set up player events
	Players.PlayerAdded:Connect(function(player)
		task.wait(10) -- Wait for player to be fully loaded
		updateCompletionStats() -- Update stats when a new player joins
	end)

	debugPrint("Dynamic Economy Balancer initialized!")
	return true
end

-- Initialize immediately
DynamicEconomyBalancer.initialize()

-- Return the module
return DynamicEconomyBalancer