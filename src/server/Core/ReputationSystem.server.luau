--[[
    Reputation System - Server Implementation
]]
-- Types
export type ReputationFactorType = "Helpful" | "Harmful" | "Generous" | "Selfish"

export type ReputationFactor = {
	Name: string,
	FactorType: ReputationFactorType,
	Impact: number, -- Impact on reputation per point
}

-- Modules
local ReputationSystem = {}
ReputationSystem.__index = ReputationSystem

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Placeholder modules (replace with actual implementations)
local MemberSatisfactionSystem = require(ServerStorage:WaitForChild("MemberSatisfactionSystem")) -- Replace with actual path
local NPCSystem = require(ServerStorage:WaitForChild("NPCSystem")) -- Replace with actual path
local RevenueSystem = require(ServerStorage:WaitForChild("RevenueSystem")) -- Replace with actual path

-- Reputation System Components

-- FactorManager
local FactorManager = {}
FactorManager.__index = FactorManager

function FactorManager.new()
	local self = setmetatable({}, FactorManager)
	self.Factors = {}
	return self
end

function FactorManager:AddFactor(factor: ReputationFactor)
	self.Factors[factor.Name] = factor
end

function FactorManager:GetFactor(name: string)
	return self.Factors[name]
end

function FactorManager:GetFactors()
	return self.Factors
end
-- ReputationCalculator

function FactorManager:AddPointsToFactor(factorName: string, amount: number)
	if self.Factors[factorName] then
		self.Factors[factorName].Points = (self.Factors[factorName].Points or 0) + amount
	end
end

function FactorManager:RemovePointsFromFactor(factorName: string, amount: number)
	if self.Factors[factorName] then
		self.Factors[factorName].Points = math.max(0, (self.Factors[factorName].Points or 0) - amount)
	end
end
local ReputationCalculator = {}
ReputationCalculator.__index = ReputationCalculator

function ReputationCalculator.new()
	local self = setmetatable({}, ReputationCalculator)
	return self
end

function ReputationCalculator:Calculate(factors: {[string]: {Points: number, Impact: number}})
	local reputation = 50 -- Base reputation
	for _, factor in pairs(factors) do
		local impact = math.clamp(factor.Points * factor.Impact, -25, 25) -- Each factor can add/remove max 25 points
		reputation += impact
	end

	return math.clamp(reputation, 0, 100) -- Reputation range 0-100
end

-- BenefitController
local BenefitController = {}
BenefitController.__index = BenefitController

export type ReputationLevel = "Notorious" | "Neutral" | "Respected"

local ReputationLevels: {[ReputationLevel]: {Min: number, Max: number, Benefits: {}}} = {
	Notorious = {Min = 0, Max = 25, Benefits = {}}, -- Add benefits here
	Neutral = {Min = 26, Max = 75, Benefits = {}}, -- Add benefits here
	Respected = {Min = 76, Max = 100, Benefits = {}}, -- Add benefits here
} 

local function GetReputationLevel(reputation: number): ReputationLevel
	for level, range in pairs(ReputationLevels) do
		if reputation >= range.Min and reputation <= range.Max then
function BenefitController.new()
	local self = setmetatable({}, BenefitController)
	return self
end
end


function BenefitController:ApplyBenefits(player: Player, reputation: number)
	-- Example benefits based on reputation tiers
			return level
		end
	end
	return "Neutral" -- Default level
end

function BenefitController:GetBenefits(reputation: number)
	local level = GetReputationLevel(reputation)
	if level then
		return ReputationLevels[level].Benefits
	end
	return {}
end

-- HistoryTracker
local HistoryTracker = {}
HistoryTracker.__index = HistoryTracker

function HistoryTracker.new()
	local self = setmetatable({}, HistoryTracker)
	self.playerHistory = {} -- Store player history
	return self
end

function HistoryTracker:AddAction(player: Player, action: string, details: {})
	local history = self.playerHistory[player.UserId]
	if not history then
		history = {}
		self.playerHistory[player.UserId] = history
	end
	table.insert(history, {Timestamp = os.time(), Action = action, Details = details})
end

function HistoryTracker:GetPlayerHistory(player: Player)
	return self.playerHistory[player.UserId] or {}
end

function HistoryTracker:PlayerJoined(player: Player)
	self.playerHistory[player.UserId] = {} -- Initialize empty history
end

-- Reputation System Instance
function ReputationSystem.new()
	local self = setmetatable({}, ReputationSystem)
	self.FactorManager = FactorManager.new()
	self.ReputationCalculator = ReputationCalculator.new()
	self.BenefitController = BenefitController.new()
	self.HistoryTracker = HistoryTracker.new()
	self.playerData = {} -- Store player-specific data
	return self
end

function ReputationSystem:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:PlayerJoined(player)
	end)
end

function ReputationSystem:AddFactor(factor: ReputationFactor)
	self.FactorManager:AddFactor(factor)
end
function ReputationSystem:AddPointsToFactor(player: Player, factorName: string, points: number, actionDescription: string, actionDetails: {})
	local playerData = self.playerData[player.UserId]
	if not playerData then
		warn("Player data not found for", player.Name)
		return
	end

	self.FactorManager:AddPointsToFactor(factorName, points)

	local factors = self.FactorManager:GetFactors()
	playerData.reputation = self.ReputationCalculator:Calculate(factors)

	self.HistoryTracker:AddAction(player, actionDescription, actionDetails)
	local reputation = playerData.reputation
	self.BenefitController:ApplyBenefits(player,reputation)

	-- Send reputation update to the client
	local remoteEvent = ReplicatedStorage:WaitForChild("ReputationUpdated")
	if remoteEvent then
		remoteEvent:FireClient(player, playerData.reputation)
	end
end

function ReputationSystem:RemovePointsFromFactor(player: Player, factorName: string, points: number, actionDescription: string, actionDetails: {})
	local playerData = self.playerData[player.UserId]
	if not playerData then
		warn("Player data not found for", player.Name)
		return
	end
	self.FactorManager:RemovePointsFromFactor(factorName, points)

	local factors = self.FactorManager:GetFactors()
	playerData.reputation = self.ReputationCalculator:Calculate(factors)

	self.HistoryTracker:AddAction(player, actionDescription, actionDetails)
	local reputation = playerData.reputation
	self.BenefitController:ApplyBenefits(player,reputation)
	-- Send reputation update to the client
	local remoteEvent = ReplicatedStorage:WaitForChild("ReputationUpdated")
	if remoteEvent then
		remoteEvent:FireClient(player, playerData.reputation)
	end
end
function ReputationSystem:GetReputation(player: Player)
	local playerData = self.playerData[player.UserId]
	if playerData then
		return playerData.reputation
	end
	return 50 -- Default reputation
end

function ReputationSystem:GetHistory(player: Player)
	return self.HistoryTracker:GetPlayerHistory(player)
end

function ReputationSystem:PlayerJoined(player: Player)
	self.playerData[player.UserId] = {
		reputation = 50, -- Initial reputation
		factors = {}, -- Initialize factor points
	}
	self.HistoryTracker:PlayerJoined(player)
end


return ReputationSystem