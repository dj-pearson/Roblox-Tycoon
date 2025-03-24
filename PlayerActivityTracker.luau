-- PlayerActivityTracker.lua
-- LocalScript to track player activity and prevent AFK abuse
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Ensure the remote event exists
local activityEvent = ReplicatedStorage:FindFirstChild("PlayerActivityEvent")
if not activityEvent then
	activityEvent = Instance.new("RemoteEvent")
	activityEvent.Name = "PlayerActivityEvent"
	activityEvent.Parent = ReplicatedStorage
end

-- Variables
local lastActivity = tick()
local reportInterval = 30 -- Report activity every 30 seconds

-- Functions to track activity
local function onInputDetected()
	lastActivity = tick()
	-- Report immediately
	activityEvent:FireServer()
end

-- Connect to input events
UserInputService.InputBegan:Connect(onInputDetected)
UserInputService.InputChanged:Connect(onInputDetected)
UserInputService.InputEnded:Connect(onInputDetected)

-- Character movement also counts as activity
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.MoveToFinished:Connect(onInputDetected)
	humanoid.Jumping:Connect(onInputDetected)

	-- Also track when player moves their character
	RunService.Heartbeat:Connect(function()
		if humanoid.MoveDirection.Magnitude > 0 then
			onInputDetected()
		end
	end)
end)

-- Periodically report activity
spawn(function()
	while wait(reportInterval) do
		-- Only report if there's been activity in the last report interval
		if tick() - lastActivity < reportInterval then
			activityEvent:FireServer()
		end
	end
end)