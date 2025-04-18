-- SeasonalSpecializationSystem.lua
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Try to load dependencies
local SpecializationSystem
pcall(function()
	SpecializationSystem = require(ServerScriptService:FindFirstChild("GymSpecializationSystem"))
end)

local GymRevenue
pcall(function()
	GymRevenue = require(ServerScriptService:FindFirstChild("GymRevenueSystem"))
end)

local SeasonalSystem = {
	-- Currently active seasonal event
	currentSeason = nil,

	-- Players with active seasonal bonuses
	playerSeasonalBoosts = {},

	-- Definitions of seasonal events
	seasons = {
		summerBeachBody = {
			name = "Summer Beach Body Program",
			description = "Attract more members with summer-focused training programs",
			duration = 14, -- Days (use minutes for testing)
			icon = "rbxassetid://12345678", -- Replace with actual ID
			benefits = {
				membership_boost = 1.4, -- 40% more members
				specific_equipment_boost = {"outdoor", "cardio"}, -- Boost for specific equipment
				member_satisfaction = 1.2
			},
			requirements = {
				gym_level = 2 -- Minimum gym level to participate
			}
		},

		newYearResolution = {
			name = "New Year's Resolution Program",
			description = "Capitalize on New Year's fitness resolutions with beginner-friendly programs",
			duration = 21,
			icon = "rbxassetid://12345679",
			benefits = {
				membership_boost = 1.5, -- 50% more members
				retention_penalty = 0.7, -- But members leave faster
				dues_boost = 1.2 -- 20% more membership fees
			},
			requirements = {
				gym_level = 3
			}
		},

		summerSlim = {
			name = "Summer Slim Down Challenge",
			description = "Help members get beach-ready with intensive cardio programs",
			duration = 14,
			icon = "rbxassetid://12345680",
			benefits = {
				cardio_equipment_boost = 1.5, -- Cardio equipment efficiency boost
				membership_boost = 1.3,
				vip_chance = 0.15
			},
			requirements = {
				gym_level = 2,
				min_cardio_equipment = 3 -- Requires at least 3 cardio machines
			}
		},

		fallFitness = {
			name = "Fall Fitness Challenge",
			description = "Keep members engaged with seasonal challenges",
			duration = 18,
			icon = "rbxassetid://12345681",
			benefits = {
				retention_boost = 1.3, -- Better retention
				dues_boost = 1.15,
				competition_boost = 1.2
			},
			requirements = {
				gym_level = 4
			}
		},

		winterBulk = {
			name = "Winter Bulk Program",
			description = "Focused strength training during winter months",
			duration = 28,
			icon = "rbxassetid://12345682",
			benefits = {
				membership_boost = 1.2,
				strength_equipment_boost = 1.4,
				vip_chance = 0.18
			},
			requirements = {
				gym_level = 3,
				min_strength_equipment = 4
			}
		}
	}
}

-- Check if player meets requirements for a seasonal event
function SeasonalSystem.checkRequirements(player, seasonId)
	if not player or not seasonId then return false end

	local season = SeasonalSystem.seasons[seasonId]
	if not season then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Check gym level
	local gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
	if gymLevel < season.requirements.gym_level then
		return false, "Your gym needs to be level " .. season.requirements.gym_level
	end

	-- Check equipment requirements if any
	if season.requirements.min_cardio_equipment then
		-- Count cardio equipment (this would need to be implemented based on your equipment system)
		local cardioCount = 0
		-- Example implementation - replace with your actual equipment counting logic
		-- This would likely use CollectionService tags or equipment attributes
		if cardioCount < season.requirements.min_cardio_equipment then
			return false, "You need at least " .. season.requirements.min_cardio_equipment .. " cardio machines"
		end
	end

	if season.requirements.min_strength_equipment then
		-- Count strength equipment (similar implementation needed)
		local strengthCount = 0
		-- Example implementation
		if strengthCount < season.requirements.min_strength_equipment then
			return false, "You need at least " .. season.requirements.min_strength_equipment .. " strength equipment pieces"
		end
	end

	return true
end

-- Get available seasonal events for a player
function SeasonalSystem.getAvailableSeasons(player)
	if not player then return {} end

	local available = {}

	for id, season in pairs(SeasonalSystem.seasons) do
		local meetsRequirements, reason = SeasonalSystem.checkRequirements(player, id)

		table.insert(available, {
			id = id,
			name = season.name,
			description = season.description,
			duration = season.duration,
			icon = season.icon,
			available = meetsRequirements,
			reason = not meetsRequirements and reason or nil
		})
	end

	return available
end

-- Apply seasonal bonuses to a player
function SeasonalSystem.applySeasonalBonuses(player, seasonId)
	if not player or not seasonId then return false end

	local season = SeasonalSystem.seasons[seasonId]
	if not season then return false, "Invalid seasonal event" end

	-- Check requirements
	local meetsRequirements, reason = SeasonalSystem.checkRequirements(player, seasonId)
	if not meetsRequirements then
		return false, reason
	end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false, "Tycoon not found" end

	-- Apply bonuses
	if season.benefits.membership_boost then
		tycoon:SetAttribute("SeasonalMembershipBoost", season.benefits.membership_boost)
	end

	if season.benefits.dues_boost then
		tycoon:SetAttribute("SeasonalDuesBoost", season.benefits.dues_boost)
	end

	if season.benefits.vip_chance then
		tycoon:SetAttribute("SeasonalVIPChance", season.benefits.vip_chance)
	end

	if season.benefits.retention_boost then
		tycoon:SetAttribute("SeasonalRetentionBoost", season.benefits.retention_boost)
	end

	if season.benefits.retention_penalty then
		tycoon:SetAttribute("SeasonalRetentionPenalty", season.benefits.retention_penalty)
	end

	if season.benefits.competition_boost then
		tycoon:SetAttribute("SeasonalCompetitionBoost", season.benefits.competition_boost)
	end

	-- Calculate end time
	local durationInSeconds = season.duration * 24 * 60 * 60 -- Convert days to seconds
	local endTime = os.time() + durationInSeconds

	-- Store in player data
	tycoon:SetAttribute("ActiveSeason", seasonId)
	tycoon:SetAttribute("SeasonEndTime", endTime)

	-- Store in module data for tracking
	SeasonalSystem.playerSeasonalBoosts[player.UserId] = {
		seasonId = seasonId,
		endTime = endTime
	}

	-- Create notification
	local message = Instance.new("Message")
	message.Text = "Seasonal Event Started: " .. season.name .. "\nActive for " .. season.duration .. " days!"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)

	-- Update any relevant systems
	if GymRevenue and GymRevenue.updatePlayerConfig then
		GymRevenue.updatePlayerConfig(player)
	end

	return true, "Seasonal event started successfully"
end

-- Remove seasonal bonuses from a player
function SeasonalSystem.removeSeasonalBonuses(player)
	if not player then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Remove all seasonal attributes
	tycoon:SetAttribute("SeasonalMembershipBoost", nil)
	tycoon:SetAttribute("SeasonalDuesBoost", nil)
	tycoon:SetAttribute("SeasonalVIPChance", nil)
	tycoon:SetAttribute("SeasonalRetentionBoost", nil)
	tycoon:SetAttribute("SeasonalRetentionPenalty", nil)
	tycoon:SetAttribute("SeasonalCompetitionBoost", nil)
	tycoon:SetAttribute("ActiveSeason", nil)
	tycoon:SetAttribute("SeasonEndTime", nil)

	-- Remove from tracking
	SeasonalSystem.playerSeasonalBoosts[player.UserId] = nil

	-- Update any relevant systems
	if GymRevenue and GymRevenue.updatePlayerConfig then
		GymRevenue.updatePlayerConfig(player)
	end

	return true
end

-- Check for expired seasonal events
function SeasonalSystem.checkExpiredEvents()
	local currentTime = os.time()

	for userId, data in pairs(SeasonalSystem.playerSeasonalBoosts) do
		if currentTime >= data.endTime then
			-- Find player
			local player = game:GetService("Players"):GetPlayerByUserId(userId)
			if player then
				-- Create notification
				local message = Instance.new("Message")
				local seasonName = SeasonalSystem.seasons[data.seasonId] and SeasonalSystem.seasons[data.seasonId].name or "Seasonal Event"
				message.Text = seasonName .. " has ended!\nYour gym has returned to normal operations."
				message.Parent = player
				game:GetService("Debris"):AddItem(message, 5)

				-- Remove bonuses
				SeasonalSystem.removeSeasonalBonuses(player)
			else
				-- Player not found, just remove from tracking
				SeasonalSystem.playerSeasonalBoosts[userId] = nil
			end
		end
	end
end

-- Get current season info
function SeasonalSystem.getCurrentSeason()
	return SeasonalSystem.currentSeason
end

-- Start a global seasonal event
function SeasonalSystem.startGlobalSeason(seasonId)
	if not seasonId or not SeasonalSystem.seasons[seasonId] then
		return false, "Invalid seasonal event"
	end

	-- Set current global season
	SeasonalSystem.currentSeason = {
		id = seasonId,
		name = SeasonalSystem.seasons[seasonId].name,
		startTime = os.time(),
		endTime = os.time() + (SeasonalSystem.seasons[seasonId].duration * 24 * 60 * 60)
	}

	-- Notify all players
	for _, player in pairs(Players:GetPlayers()) do
		local message = Instance.new("Message")
		message.Text = "Seasonal Event Available: " .. SeasonalSystem.seasons[seasonId].name .. "\nCheck the Seasonal Events menu to participate!"
		message.Parent = player
		game:GetService("Debris"):AddItem(message, 5)
	end

	-- Create remote event to notify clients
	local seasonEvent = ReplicatedStorage:FindFirstChild("SeasonalEventStarted")
	if not seasonEvent then
		seasonEvent = Instance.new("RemoteEvent")
		seasonEvent.Name = "SeasonalEventStarted"
		seasonEvent.Parent = ReplicatedStorage
	end

	-- Fire the event
	seasonEvent:FireAllClients(seasonId, SeasonalSystem.seasons[seasonId].name)

	return true
end

-- End global seasonal event
function SeasonalSystem.endGlobalSeason()
	if not SeasonalSystem.currentSeason then
		return false, "No active seasonal event"
	end

	local oldSeason = SeasonalSystem.currentSeason
	SeasonalSystem.currentSeason = nil

	-- Notify all players
	for _, player in pairs(Players:GetPlayers()) do
		local message = Instance.new("Message")
		message.Text = "Seasonal Event Ended: " .. oldSeason.name
		message.Parent = player
		game:GetService("Debris"):AddItem(message, 5)
	end

	-- Create remote event to notify clients
	local seasonEvent = ReplicatedStorage:FindFirstChild("SeasonalEventEnded")
	if not seasonEvent then
		seasonEvent = Instance.new("RemoteEvent")
		seasonEvent.Name = "SeasonalEventEnded"
		seasonEvent.Parent = ReplicatedStorage
	end

	-- Fire the event
	seasonEvent:FireAllClients()

	return true
end

-- Initialize the system
function SeasonalSystem.initialize()
	print("Initializing Seasonal Specialization System...")

	-- Create remote functions/events
	local joinSeasonFunc = Instance.new("RemoteFunction")
	joinSeasonFunc.Name = "JoinSeasonalEvent"
	joinSeasonFunc.Parent = ReplicatedStorage

	local getAvailableSeasonsFunc = Instance.new("RemoteFunction")
	getAvailableSeasonsFunc.Name = "GetAvailableSeasons"
	getAvailableSeasonsFunc.Parent = ReplicatedStorage

	-- Handle join season requests
	joinSeasonFunc.OnServerInvoke = function(player, seasonId)
		return SeasonalSystem.applySeasonalBonuses(player, seasonId)
	end

	-- Handle get available seasons requests
	getAvailableSeasonsFunc.OnServerInvoke = function(player)
		return SeasonalSystem.getAvailableSeasons(player)
	end

	-- Set up event checking loop
	spawn(function()
		while wait(60) do -- Check every minute
			SeasonalSystem.checkExpiredEvents()
		end
	end)

	-- Test code - start with a seasonal event
	-- SeasonalSystem.startGlobalSeason("summerBeachBody")

	print("Seasonal Specialization System initialized")
	return true
end

-- Run initialization
SeasonalSystem.initialize()

return SeasonalSystem