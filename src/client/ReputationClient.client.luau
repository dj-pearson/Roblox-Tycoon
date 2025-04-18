local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage:WaitForChild("Events")
local ReputationEvents = ReplicatedStorage:WaitForChild("ReputationEvents")
local ReputationBenefitsUpdated = Events:WaitForChild("ReputationBenefitsUpdated")

local ReputationUpdated = ReputationEvents:WaitForChild("ReputationUpdated")

local ReputationUI = require(script.Parent.Parent.Shared.ReputationUI)

local ReputationClient = {}

ReputationClient.CurrentReputation = 0

local function UpdateReputation(reputation)
	ReputationClient.CurrentReputation = reputation
	ReputationUI.UpdateReputationDisplay(reputation)
end

local function UpdateBenefits(benefits)
	ReputationUI.UpdateBenefits(benefits)
end

function ReputationClient.UpdateUI()
	ReputationUI.UpdateUI(ReputationClient.CurrentReputation)
end

function ReputationClient.Initialize()
	if not RunService:IsClient() then return end

	ReputationUpdated.OnClientEvent:Connect(function(player, newReputation)
		if player == Players.LocalPlayer then
			UpdateReputation(newReputation)
		end
	end)
	
	ReputationBenefitsUpdated.OnClientEvent:Connect(function(benefits)
		if benefits then
			UpdateBenefits(benefits)
		end
	end)

	print("Reputation Client Initialized")
end

return ReputationClient