-- PlayerActivityReceiver.lua
-- Server script to receive activity events from clients
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Get the data storage system
local DataStorage
pcall(function()
	DataStorage = require(ServerScriptService:FindFirstChild("DataStorageSystem"))
end)

-- Ensure the remote event exists
local activityEvent = ReplicatedStorage:FindFirstChild("PlayerActivityEvent")
if not activityEvent then
	activityEvent = Instance.new("RemoteEvent")
	activityEvent.Name = "PlayerActivityEvent"
	activityEvent.Parent = ReplicatedStorage
end

-- Connect to the remote event
activityEvent.OnServerEvent:Connect(function(player)
	-- Update player activity timestamp
	if DataStorage and DataStorage.updatePlayerActivity then
		DataStorage.updatePlayerActivity(player)
	end
end)

print("Player activity receiver initialized")