-- Setup remote objects for data system client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the remote folder structure if it doesn't exist
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local dataSystemFolder = remotesFolder:FindFirstChild("DataSystem")
if not dataSystemFolder then
    dataSystemFolder = Instance.new("Folder")
    dataSystemFolder.Name = "DataSystem"
    dataSystemFolder.Parent = remotesFolder
end

-- Create the remote functions
local getDataRemote = dataSystemFolder:FindFirstChild("GetData")
if not getDataRemote then
    getDataRemote = Instance.new("RemoteFunction")
    getDataRemote.Name = "GetData"
    getDataRemote.Parent = dataSystemFolder
end

local setDataRemote = dataSystemFolder:FindFirstChild("SetData")
if not setDataRemote then
    setDataRemote = Instance.new("RemoteFunction")
    setDataRemote.Name = "SetData"
    setDataRemote.Parent = dataSystemFolder
end

local incrementDataRemote = dataSystemFolder:FindFirstChild("IncrementData")
if not incrementDataRemote then
    incrementDataRemote = Instance.new("RemoteFunction")
    incrementDataRemote.Name = "IncrementData"
    incrementDataRemote.Parent = dataSystemFolder
end

-- Create remote events for notifications
local dataChangedEvent = dataSystemFolder:FindFirstChild("DataChanged")
if not dataChangedEvent then
    dataChangedEvent = Instance.new("RemoteEvent")
    dataChangedEvent.Name = "DataChanged"
    dataChangedEvent.Parent = dataSystemFolder
end

print("Data system remote objects setup complete")
