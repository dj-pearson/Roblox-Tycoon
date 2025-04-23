-- FolderSetup.server.luau
-- Creates necessary folders to prevent infinite yield warnings
-- Should run before other scripts that rely on these folders

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug function
local function log(...)
    print("[FolderSetup]", ...)
end

log("Setting up necessary folders...")

-- Create folders in ReplicatedStorage
local function ensureFolderExists(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder: " .. parent.Name .. "/" .. name)
    end
    return folder
end

-- Create standard folders in ReplicatedStorage
local replicatedFolders = {
    "shared",
    "Events",
    "ReplicatedEvents",
    "MembershipBoostEvent",
    "CreateAllianceEvent"
}

for _, folderName in ipairs(replicatedFolders) do
    ensureFolderExists(ReplicatedStorage, folderName)
end

-- Create standard folders in ServerStorage
local serverStorageFolders = {
    "MemberSatisfactionSystem"
}

for _, folderName in ipairs(serverStorageFolders) do
    ensureFolderExists(ServerStorage, folderName)
end

-- Create standard folders in ServerScriptService
local serverScriptFolders = {
    "src"
}

for _, folderName in ipairs(serverScriptFolders) do
    ensureFolderExists(ServerScriptService, folderName)
end

-- Create event instances in Events folder
local eventNames = {
    "MembershipUpdated",
    "EquipmentPurchased",
    "RevenueCollected",
    "MemberJoined",
    "MemberLeft",
    "TycoonCreated",
    "MembershipTierChanged"
}

local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if eventsFolder then
    for _, eventName in ipairs(eventNames) do
        if not eventsFolder:FindFirstChild(eventName) then
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = eventsFolder
            log("Created RemoteEvent: Events/" .. eventName)
        end
    end
end

log("Folder setup complete!")

-- Mark setup as complete for other scripts to check
local setupComplete = Instance.new("BoolValue")
setupComplete.Name = "FolderSetupComplete"
setupComplete.Value = true
setupComplete.Parent = ReplicatedStorage

return true