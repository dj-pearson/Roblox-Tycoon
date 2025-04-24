-- src/client/TutorialClient.client.luau

local TutorialClient = {}
TutorialClient.__index = TutorialClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import SafeWait utility
local SafeWait
pcall(function()
    SafeWait = require(ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("SafeWait"))
end)

-- If SafeWait isn't available, create a simple version
if not SafeWait then
    SafeWait = {
        waitForChild = function(parent, name, timeout)
            return parent:WaitForChild(name, timeout or 5)
        end
    }
end

-- Safely wait for required objects with timeouts
local ReplicatedEvents = SafeWait.waitForChild(ReplicatedStorage, "ReplicatedEvents", 5)
local TutorialEvent = ReplicatedEvents and SafeWait.waitForChild(ReplicatedEvents, "TutorialEvent", 5)

-- Add warning if events couldn't be loaded
if not TutorialEvent then
    warn("TutorialClient: Failed to load TutorialEvent")
end

-- Safely require TutorialUI
local TutorialUI
pcall(function()
    TutorialUI = require(game.ReplicatedStorage.src.shared.TutorialUI)
end)

if not TutorialUI then
    warn("TutorialClient: Failed to load TutorialUI module")
end

function TutorialClient.new()
	local self = setmetatable({}, TutorialClient)
	return self
end

function TutorialClient:initialize()
	TutorialEvent.OnClientEvent:Connect(function(tutorialStep, text)
		self:receiveTutorialStep(tutorialStep, text)
	end)
end

function TutorialClient:receiveTutorialStep(tutorialStep, text)
	print("Received tutorial step:", tutorialStep, "with text:", text) -- Added print statement
	TutorialUI:displayTutorial(text) -- Updated to use displayTutorial
end

return TutorialClient.new()