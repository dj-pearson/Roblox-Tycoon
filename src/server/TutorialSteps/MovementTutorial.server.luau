-- src/server/TutorialSteps/MovementTutorial.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Fix path to TutorialManager - direct Core reference
local TutorialManager = require(ServerScriptService:WaitForChild("Core"):WaitForChild("TutorialManager"))

local MovementTutorial = {}

MovementTutorial.Name = "MovementTutorial"

local tutorialStep = {
	Step = MovementTutorial.Name,
	Text = "Welcome to the Gym! Use WASD to move around, and the mouse to look.",
}

function MovementTutorial.triggerTutorial(player)
	TutorialManager.triggerTutorialStep(player, tutorialStep)
end

return MovementTutorial