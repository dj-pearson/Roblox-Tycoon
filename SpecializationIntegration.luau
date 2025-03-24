-- SpecializationIntegration.lua
-- This script integrates the specialization system with GymRevenueSystem
-- Place in ServerScriptService

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load required systems
local SpecializationSystem, GymRevenueSystem, EquipmentTagSystem

pcall(function()
	SpecializationSystem = require(ServerScriptService:FindFirstChild("GymSpecializationSystem"))
end)

pcall(function()
	GymRevenueSystem = require(ServerScriptService:FindFirstChild("GymRevenueSystem"))
end)

pcall(function()
	EquipmentTagSystem = require(ServerScriptService:FindFirstChild("EquipmentTagSystem"))
end)

-- Check if the necessary systems are loaded
if not SpecializationSystem then
	warn("SpecializationIntegration: Failed to load GymSpecializationSystem")
	return
end

print("Starting Specialization Integration...")

-- Patch GymRevenueSystem to use specialization bonuses
if GymRevenueSystem then
	print("Patching GymRevenueSystem for specializations...")

	-- Add specialization-aware configuration updater
	GymRevenueSystem.updatePlayerConfig = function(player)
		if not player then return end

		local tycoon = player:FindFirstChild("Tycoon")
		if not tycoon then return end

		-- Get specialization modifiers
		local membershipBoost = tycoon:GetAttribute("SpecMembershipBoost") or 1.0
		local duesBoost = tycoon:GetAttribute("SpecDuesBoost") or 1.0
		local vipChance = tycoon:GetAttribute("SpecVIPChance") or 0.1
		local vipMultiplier = tycoon:GetAttribute("SpecVIPMultiplier") or 1.0

		-- Update config for this player
		local playerConfig = {
			membershipBoost = membershipBoost,
			duesBoost = duesBoost,
			vipChance = vipChance,
			vipMultiplier = vipMultiplier
		}

		-- Store in player data
		tycoon:SetAttribute("ConfigModified", true)

		print("Updated revenue configuration for " .. player.Name .. " based on specializations")
		return playerConfig
	end

	-- Patch the membership count calculation
	local originalCalculateMembershipCount = GymRevenueSystem.calculateMembershipCount
	if originalCalculateMembershipCount then
		GymRevenueSystem.calculateMembershipCount = function(player)
			-- Get base membership count
			local baseCount = originalCalculateMembershipCount(player)

			-- Apply specialization bonus
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon:GetAttribute("ConfigModified") then
				local membershipBoost = tycoon:GetAttribute("SpecMembershipBoost") or 1.0
				baseCount = math.floor(baseCount * membershipBoost)
			end

			return baseCount
		end

		print("Patched membership count calculation")
	end

	-- Patch the VIP calculation
	local originalCalculateVIPCount = GymRevenueSystem.calculateVIPMembershipCount
	if originalCalculateVIPCount then
		GymRevenueSystem.calculateVIPMembershipCount = function(player)
			-- Get base VIP count
			local baseCount = originalCalculateVIPCount(player)

			-- Apply specialization bonus
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon:GetAttribute("ConfigModified") then
				local vipChance = tycoon:GetAttribute("SpecVIPChance") or 0.1
				local memberCount = GymRevenueSystem.calculateMembershipCount(player)
				return math.floor(memberCount * vipChance)
			end

			return baseCount
		end

		print("Patched VIP membership calculation")
	end

	-- Patch hourly revenue calculation for dues boost
	local originalCalculateHourlyRevenue = GymRevenueSystem.calculateHourlyRevenue
	if originalCalculateHourlyRevenue then
		GymRevenueSystem.calculateHourlyRevenue = function(player)
			-- Get base hourly revenue
			local baseRevenue = originalCalculateHourlyRevenue(player)

			-- Apply specialization bonus
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon:GetAttribute("ConfigModified") then
				local duesBoost = tycoon:GetAttribute("SpecDuesBoost") or 1.0
				baseRevenue = math.floor(baseRevenue * duesBoost)
			end

			return baseRevenue
		end

		print("Patched hourly revenue calculation")
	end

	print("GymRevenueSystem patched successfully")
end

-- Patch BuyTile system for equipment discounts
if _G.GymTycoonConnector and EquipmentTagSystem then
	print("Patching BuyTile system for equipment discounts...")

	-- Store original onTilePurchased function
	local originalOnTilePurchased = _G.GymTycoonConnector.onTilePurchased

	-- Replace with specialized version
	_G.GymTycoonConnector.onTilePurchased = function(player, tileId)
		-- First apply any specialization discounts
		local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
		if buyTilesFolder then
			-- Find the buy tile by ID
			local function findBuyTileById(id, folder)
				for _, item in pairs(folder:GetChildren()) do
					if item:IsA("Model") and item:GetAttribute("ID") == id then
						return item
					elseif item:IsA("Folder") then
						local result = findBuyTileById(id, item)
						if result then return result end
					end
				end
				return nil
			end

			local buyTile = findBuyTileById(tileId, buyTilesFolder)
			if buyTile then
				-- Get equipment type
				local equipmentType = EquipmentTagSystem.getEquipmentType(buyTile)

				-- Get original price
				local originalPrice = buyTile:GetAttribute("Price") or 0

				if equipmentType and originalPrice > 0 and SpecializationSystem then
					-- Apply any specialization discounts
					local discountedPrice = SpecializationSystem.applyEquipmentDiscount(player, equipmentType, originalPrice)

					-- If price changed, set it temporarily
					if discountedPrice < originalPrice then
						-- Store original price
						buyTile:SetAttribute("OriginalPrice", originalPrice)

						-- Apply discount
						buyTile:SetAttribute("Price", discountedPrice)

						-- Show discount notification to player
						local discount = math.floor((1 - (discountedPrice / originalPrice)) * 100)

						-- Create a message to show the player
						local message = Instance.new("Message")
						message.Text = "Specialization Discount: " .. discount .. "% off " .. buyTile.Name .. "!"
						message.Parent = player

						-- Remove message after 3 seconds
						game:GetService("Debris"):AddItem(message, 3)

						print("Applied " .. discount .. "% specialization discount for " .. player.Name)

						-- Schedule restoration of original price
						delay(5, function()
							if buyTile and buyTile:GetAttribute("OriginalPrice") then
								buyTile:SetAttribute("Price", buyTile:GetAttribute("OriginalPrice"))
								buyTile:SetAttribute("OriginalPrice", nil)
							end
						end)
					end
				end
			end
		end

		-- Call original function
		return originalOnTilePurchased(player, tileId)
	end

	print("BuyTile system patched successfully")
end

-- Patch Competition System if available
local CompetitionSystem
pcall(function()
	CompetitionSystem = require(ServerScriptService:FindFirstChild("CompetitionSystem"))
end)

if CompetitionSystem then
	print("Patching CompetitionSystem for specializations...")

	-- Store original startCompetition function
	local originalStartCompetition = CompetitionSystem.startCompetition

	-- Replace with specialized version
	CompetitionSystem.startCompetition = function(player, competitionId)
		-- Call original function first
		local result, competitionKey = originalStartCompetition(player, competitionId)

		-- Apply specialization bonus if successful
		if result and competitionKey then
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon:GetAttribute("ConfigModified") then
				local competitionBoost = tycoon:GetAttribute("SpecCompetitionBoost") or 1.0

				-- Apply the boost to the competition results
				-- This depends on how your competition system works

				print("Applied specialization competition boost for " .. player.Name)
			end
		end

		return result, competitionKey
	end

	print("CompetitionSystem patched successfully")
end

-- Create a command system for specializations
local function createSpecializationCommands()
	-- Create a RemoteFunction for commands
	local specCommandFunc = Instance.new("RemoteFunction")
	specCommandFunc.Name = "SpecializationCommands"
	specCommandFunc.Parent = ReplicatedStorage

	-- Handle command requests
	specCommandFunc.OnServerInvoke = function(player, command, ...)
		if command == "getSpecializations" then
			return SpecializationSystem.getPlayerSpecializations(player)
		elseif command == "getAvailable" then
			return SpecializationSystem.getAvailableSpecializations(player)
		elseif command == "createDecor" then
			return SpecializationSystem.createSpecializationDecor(player)
		elseif command == "applyBenefits" then
			return SpecializationSystem.applySpecializationBenefits(player)
		end

		return nil, "Unknown command"
	end

	print("Specialization commands created")
	return specCommandFunc
end

-- Initialize the integration
local function initialize()
	-- Create commands
	createSpecializationCommands()

	-- Apply specialization benefits to all players
	if SpecializationSystem then
		for _, player in pairs(game:GetService("Players"):GetPlayers()) do
			SpecializationSystem.applySpecializationBenefits(player)

			-- Create decor for players with specializations
			local specs = SpecializationSystem.getPlayerSpecializations(player)
			if specs and specs.primary then
				SpecializationSystem.createSpecializationDecor(player)
			end
		end
	end

	print("Specialization Integration initialized successfully")
	return true
end

-- Run initialization
initialize()

return {
	initialize = initialize,
	createSpecializationCommands = createSpecializationCommands
}