-- TowelSystemInitializer.server.lua
-- Initialize the Towel System and create necessary RemoteEvents

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create Events folder if it doesn't exist
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

-- Create necessary RemoteEvents
local remoteEvents = {
    "InventoryUpdate",
    "InventoryAction",
    "Notification"
}

for _, eventName in ipairs(remoteEvents) do
    if not eventsFolder:FindFirstChild(eventName) then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = eventsFolder
    end
end

-- Initialize TowelSystem
local TowelSystem = require(ServerScriptService:WaitForChild("Towels"))
TowelSystem.init()

print("TowelSystem initialized successfully!")
