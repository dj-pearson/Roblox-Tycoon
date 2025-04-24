local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import SafeWait utility
local SafeWait
pcall(function()
    SafeWait = require(ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("SafeWait"))
end)

-- If SafeWait isn't available, create a simple version
if not SafeWait then
    SafeWait = {
        waitForChild = function(parent, name, timeout)
            -- First check if child already exists
            local child = parent:FindFirstChild(name)
            if child then
                return child
            end
            
            -- Use timeout to prevent infinite yield
            return parent:WaitForChild(name, timeout or 5)
        end
    }
end

-- Safely wait for required objects with timeouts
local Events = SafeWait.waitForChild(ReplicatedStorage, "Events", 10)
local ReputationEvents = SafeWait.waitForChild(ReplicatedStorage, "ReputationEvents", 10)
local ReputationBenefitsUpdated = Events and SafeWait.waitForChild(Events, "ReputationBenefitsUpdated", 5)

-- Use SafeWait instead of direct WaitForChild to prevent infinite yield
local ReputationUpdated = ReputationEvents and SafeWait.waitForChild(ReputationEvents, "ReputationUpdated", 5)

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