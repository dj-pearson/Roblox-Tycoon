-- src/client/TutorialClient.client.luau

local TutorialClient = {}
TutorialClient.__index = TutorialClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedEvents = ReplicatedStorage:WaitForChild("ReplicatedEvents")
local TutorialEvent = ReplicatedEvents:WaitForChild("TutorialEvent")

local TutorialUI = require(game.ReplicatedStorage.src.shared.TutorialUI)

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