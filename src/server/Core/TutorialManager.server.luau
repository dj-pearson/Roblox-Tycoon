local TutorialManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialSteps = require(ReplicatedStorage.src.TutorialSteps)

local PlayerTutorialProgress = {}
local RegisteredTutorialSteps = {}

type TutorialStep = {
	Name: string,
	Description: string,
	TriggerCondition: (Player: Player) -> boolean,
	Action: (Player: Player) -> (),
}

function TutorialManager.addTutorialStep(step: TutorialStep)
	if RegisteredTutorialSteps[step.Name] then
		warn("Tutorial step already registered: " .. step.Name)
		return
	end
	RegisteredTutorialSteps[step.Name] = step
end

function TutorialManager.checkPlayerProgress(player: Player): {string}
	local playerProgress = PlayerTutorialProgress[player.UserId]
	if playerProgress then
		return playerProgress
	else
		return {}
	end
end

function TutorialManager.triggerTutorialStep(player: Player, stepName: string)
	local step = RegisteredTutorialSteps[stepName]
	if step then
		if step.TriggerCondition(player) then
			step.Action(player)
			if PlayerTutorialProgress[player.UserId] then
				table.insert(PlayerTutorialProgress[player.UserId], stepName)
			else
				PlayerTutorialProgress[player.UserId] = {stepName}
			end
		end
	else
		warn("Tutorial step not found: " .. stepName)
	end
end

function TutorialManager.playerJoined(player: Player)
	if not PlayerTutorialProgress[player.UserId] then
		PlayerTutorialProgress[player.UserId] = {}
		TutorialManager.triggerTutorialStep(player, "MovementTutorial")
	end
end

function TutorialManager.initialize()
	TutorialManager.addTutorialStep(TutorialSteps.MovementTutorial)
end
return TutorialManager
