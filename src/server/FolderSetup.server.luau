--!strict
--[[
    FolderSetup.server.luau
    Creates all necessary folders at game startup to prevent infinite yield warnings
    Priority: 1 (runs before all other scripts)
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Function to ensure a path exists
local function ensurePath(parent, path)
    local current = parent
    for _, folderName in ipairs(path) do
        local folder = current:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = current
            print("FolderSetup: Created missing folder " .. folderName .. " in " .. current:GetFullName())
        end
        current = folder
    end
    return current
end

-- Ensure all paths from the warnings exist
ensurePath(ServerScriptService, {"src", "server"})
ensurePath(ReplicatedStorage, {"ReputationEvents"})
ensurePath(ReplicatedStorage, {"shared", "CompetitionUI"})
ensurePath(ReplicatedStorage, {"JoinAllianceEvent"})
ensurePath(ReplicatedStorage, {"ReplicatedEvents", "TutorialEvent"})
ensurePath(ReplicatedStorage, {"shared", "UIStyle"})

-- Create RemoteEvents for the missing events
local function createRemoteEventIfNeeded(parent, name)
    if not parent:FindFirstChild(name) then
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = parent
        print("FolderSetup: Created missing RemoteEvent " .. name .. " in " .. parent:GetFullName())
    end
end

-- Create the remote events
createRemoteEventIfNeeded(ReplicatedStorage:FindFirstChild("ReputationEvents"), "ReputationChanged")
createRemoteEventIfNeeded(ReplicatedStorage, "JoinAllianceEvent")
createRemoteEventIfNeeded(ReplicatedStorage:FindFirstChild("ReplicatedEvents"), "TutorialEvent")

print("FolderSetup: All required folders and events have been created")
