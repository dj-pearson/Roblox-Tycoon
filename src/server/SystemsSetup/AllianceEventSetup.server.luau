--!strict
--[[
    AllianceEventSetup.server.luau
    
    This script ensures all Alliance-related RemoteEvents are properly set up at server startup,
    preventing any "WaitForChild" issues on the client.
    
    Author: Pearson
    Date: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a helper function to create or find RemoteEvents
local function ensureRemoteEventExists(name)
    local event = ReplicatedStorage:FindFirstChild(name)
    
    if not event then
        print("AllianceEventSetup: Creating missing event: " .. name)
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = ReplicatedStorage
    else
        print("AllianceEventSetup: Found existing event: " .. name)
    end
    
    return event
end

-- Create a ServerToClientEvents folder for consolidated server-to-client events
local serverToClientEvents = ReplicatedStorage:FindFirstChild("ServerToClientEvents")
if not serverToClientEvents then
    serverToClientEvents = Instance.new("RemoteEvent")
    serverToClientEvents.Name = "ServerToClientEvents" 
    serverToClientEvents.Parent = ReplicatedStorage
    print("AllianceEventSetup: Created ServerToClientEvents")
else
    print("AllianceEventSetup: Found existing ServerToClientEvents")
end

-- Define all needed alliance events
local allianceEvents = {
    "AllianceCreatedEvent",
    "PlayerJoinedAllianceEvent",
    "PlayerLeftAllianceEvent", 
    "PlayerRemovedFromAllianceEvent",
    "PlayerInvitedToAllianceEvent",
    "AllianceDisbandedEvent",
    "JoinAllianceEvent",
    "CreateAllianceEvent",
    "LeaveAllianceEvent",
    "DisbandAllianceEvent",
    "ErrorEvent"
}

-- Create all required events
for _, eventName in ipairs(allianceEvents) do
    ensureRemoteEventExists(eventName)
end

print("AllianceEventSetup: All alliance events are ready")

-- Return a boolean to indicate successful setup
return true
