-- Buy Tile Pricing Tool
-- Run this script in Command Bar or as a Server Script (once)
-- This will price all your buy tiles with an incremental scale

local ServerStorage = game:GetService("ServerStorage")
local function ensureNumber(value)
	if type(value) == "string" then
		return tonumber(value) or 0
	end
	return value
end
-- Configuration settings
local PRICE_SETTINGS = {
	initial_price = 1,          -- Price of first tile

	-- Pricing curve options (choose one)
	pricing_curve = "exponential", -- "linear", "exponential", "stepped"

	-- Linear settings
	linear_increment = 10,        -- How much to add for each tile in linear mode

	-- Exponential settings
	exp_base = 1.05,               -- Base for exponential growth (higher = steeper curve)
	exp_multiplier = 10,         -- Multiplier for exponential growth

	-- Stepped settings
	step_tiers = {                -- Price tiers for stepped pricing
		{max_id = 5, price = 100},    -- Tiles 1-5: $100
		{max_id = 10, price = 250},   -- Tiles 6-10: $250
		{max_id = 15, price = 500},   -- Tiles 11-15: $500
		{max_id = 20, price = 1000},  -- Tiles 16-20: $1000
		{max_id = 25, price = 2500},  -- Tiles 21-25: $2500
		{max_id = 999, price = 5000}, -- Tiles 26+: $5000
	}
}

-- Income settings for tiles
local INCOME_SETTINGS = {
	base_income = 5,             -- Base income per tile
	income_multiplier = 1,    -- How much each tile increases income (multiplier)
	tile_group_size = 3          -- How many tiles before a significant income jump
}

-- Function to calculate price for a specific tile
local function calculatePrice(id)
	if id == 1 then
		return PRICE_SETTINGS.initial_price
	end

	if PRICE_SETTINGS.pricing_curve == "linear" then
		-- Linear pricing: initial + (id-1) * increment
		return PRICE_SETTINGS.initial_price + (id - 1) * PRICE_SETTINGS.linear_increment

	elseif PRICE_SETTINGS.pricing_curve == "exponential" then
		-- Exponential pricing: initial + multiplier * (base ^ (id-1))
		return math.floor(PRICE_SETTINGS.initial_price + 
			PRICE_SETTINGS.exp_multiplier * 
			(PRICE_SETTINGS.exp_base ^ (id - 1)))

	elseif PRICE_SETTINGS.pricing_curve == "stepped" then
		-- Stepped pricing based on tiers
		for _, tier in ipairs(PRICE_SETTINGS.step_tiers) do
			if id <= tier.max_id then
				return tier.price
			end
		end
		-- Fallback to last tier
		return PRICE_SETTINGS.step_tiers[#PRICE_SETTINGS.step_tiers].price
	end

	-- Default fallback
	return id * 100
end

-- Function to calculate membership income increase for a specific tile
local function calculateIncomeBonus(id)
	local baseBonus = INCOME_SETTINGS.base_income

	-- Add a bigger jump every few tiles
	local groupMultiplier = math.floor((id - 1) / INCOME_SETTINGS.tile_group_size)

	-- Calculate the final income value
	local finalBonus = baseBonus * (INCOME_SETTINGS.income_multiplier ^ groupMultiplier)

	return math.floor(finalBonus)
end

-- Main function to update all buy tiles
local function updateBuyTilePrices()
	-- Check if Buy Tiles folder exists
	local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
	if not buyTilesFolder then
		warn("BuyTiles folder not found in ServerStorage!")
		return
	end

	-- Collect all buy tiles
	local buyTiles = {}

	-- Recursive function to find all buy tiles
	local function findBuyTiles(folder)
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Model") and item:GetAttribute("ID") then
				table.insert(buyTiles, item)
			elseif item:IsA("Folder") then
				findBuyTiles(item)
			end
		end
	end

	findBuyTiles(buyTilesFolder)

	-- Sort buy tiles by ID
	-- Sort buy tiles by ID with type conversion
	table.sort(buyTiles, function(a, b)
		local idA = a:GetAttribute("ID")
		local idB = b:GetAttribute("ID")

		-- Convert to numbers to ensure consistent comparison
		local numA = tonumber(idA) or 0
		local numB = tonumber(idB) or 0

		return numA < numB
	end)

	print("Found " .. #buyTiles .. " buy tiles to update")

	-- Track total tiles and verify sequential IDs
	local maxId = 0
	local missingIds = {}

	-- Check for missing IDs
	for i, tile in ipairs(buyTiles) do
		local id = tile:GetAttribute("ID")
		maxId = math.max(maxId, id)

		-- Print current tile info
		print("Tile ID " .. id .. ": " .. tile.Name .. " - Current price: $" .. (tile:GetAttribute("Price") or "N/A"))
	end

	for i = 1, maxId do
		local found = false
		for _, tile in ipairs(buyTiles) do
			if tile:GetAttribute("ID") == i then
				found = true
				break
			end
		end

		if not found then
			table.insert(missingIds, i)
		end
	end

	if #missingIds > 0 then
		warn("WARNING: Missing IDs detected: " .. table.concat(missingIds, ", "))
	end

	-- Update each buy tile's price
	for _, tile in ipairs(buyTiles) do
		local id = tile:GetAttribute("ID")
		local newPrice = calculatePrice(id)
		local incomeBonus = calculateIncomeBonus(id)

		-- Set the price attribute
		tile:SetAttribute("Price", newPrice)

		-- Set the income bonus attribute if it doesn't exist
		if not tile:GetAttribute("IncomeBonus") then
			tile:SetAttribute("IncomeBonus", incomeBonus)
		end

		print("Updated Tile ID " .. id .. ": " .. tile.Name .. " - New Price: $" .. newPrice .. " - Income Bonus: $" .. incomeBonus)
	end

	print("Finished updating " .. #buyTiles .. " buy tiles!")

	-- Print final pricing table for reference
	print("\nPricing Reference Table:")
	print("-------------------------")
	print("ID | Price | Income Bonus")
	print("-------------------------")

	for id = 1, maxId do
		local price = calculatePrice(id)
		local income = calculateIncomeBonus(id)
		print(string.format("%2d | $%5d | $%d per interval", id, price, income))
	end

	-- Print expected gameplay progression times
	print("\nEstimated Progression (assuming 30-second income intervals):")
	print("----------------------------------------------------------")

	local cumulativeTime = 0
	local cumulativeIncome = 0
	local timeFormatted = ""

	for id = 1, maxId do
		local price = calculatePrice(id)
		local prevIncomeRate = cumulativeIncome
		cumulativeIncome = cumulativeIncome + calculateIncomeBonus(id)

		-- Skip the first one since it's immediate
		if id > 1 then
			local timeToEarn
			if prevIncomeRate > 0 then
				timeToEarn = price / prevIncomeRate
				cumulativeTime = cumulativeTime + timeToEarn

				-- Format time
				local minutes = math.floor(timeToEarn / 2) -- 30-second intervals = 2 per minute
				local hours = math.floor(minutes / 60)
				minutes = minutes % 60

				if hours > 0 then
					timeFormatted = string.format("%dh %dm", hours, minutes)
				else
					timeFormatted = string.format("%dm", minutes)
				end
			else
				timeFormatted = "immediate"
			end
		else
			timeFormatted = "start"
		end

		print(string.format("Tile %2d | Price: $%5d | Income: $%d | Time to earn: %s", 
			id, price, cumulativeIncome, timeFormatted))
	end
end

-- Run the update function
updateBuyTilePrices()