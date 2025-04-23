local TutorialManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Fix path to TutorialSteps - try multiple paths to ensure it works
local TutorialSteps
local success, result = pcall(function()
    -- Try in shared folder which is the standard location
    return require(ReplicatedStorage.shared.TutorialSteps)
end)

if not success then
    -- Fallback to server location
    success, result = pcall(function()
        return require(ServerScriptService.Core.TutorialSteps)
    end)
    
    if not success then
        -- Create a basic version if not found
        warn("TutorialSteps module not found, creating a basic version")
        TutorialSteps = {
            MovementTutorial = {
                Name = "MovementTutorial",
                Description = "Learn how to move around your gym",
                TriggerCondition = function(player) return true end,
                Action = function(player)
                    -- Send message to player
                    local message = "Welcome to your gym! Use WASD to move around."
                    if player then
                        game.StarterGui:SetCore("SendNotification", {
                            Title = "Movement Tutorial",
                            Text = message,
                            Duration = 5
                        })
                    end
                end
            }
        }
    else
        TutorialSteps = result
    end
else
    TutorialSteps = result
end

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
