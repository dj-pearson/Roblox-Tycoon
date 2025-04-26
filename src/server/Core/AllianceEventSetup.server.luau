--[[
    AllianceEventSetup.server.luau
    
    Creates all alliance-related remote events at startup to prevent
    "Infinite yield possible on WaitForChild" errors specifically for the Alliance system.
    
    Created: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Try to load SafeWaitForChild
local SafeWaitForChild
local success, result = pcall(function()
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder and sharedFolder:FindFirstChild("SafeWaitForChild") then
        return require(sharedFolder.SafeWaitForChild)
    end
    return nil
end)

if success then
    SafeWaitForChild = result
    print("[AllianceEventSetup] Loaded SafeWaitForChild module")
else
    print("[AllianceEventSetup] SafeWaitForChild not found, using fallbacks")
end

-- Helper function to ensure a folder exists
local function ensureFolderExists(parent, name)
    if SafeWaitForChild then
        return SafeWaitForChild.ensureFolder(parent, name)
    end
    
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("[AllianceEventSetup] Created folder: " .. name)
    end
    return folder
end

-- Helper function to create a remote event
local function createRemoteEvent(parent, name)
    local event = parent:FindFirstChild(name)
    if event and event:IsA("RemoteEvent") then
        print("[AllianceEventSetup] Found existing event: " .. name)
        return event
    end
    
    event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = parent
    print("[AllianceEventSetup] Created event: " .. name)
    return event
end

-- Ensure there's a folder for alliance events
local allianceFolder = ensureFolderExists(ReplicatedStorage, "AllianceEvents")

-- List of alliance-related events
local allianceEvents = {
    "CreateAlliance",
    "DeleteAlliance",
    "InviteToAlliance",
    "AcceptInvitation",
    "DeclineInvitation",
    "LeaveAlliance",
    "KickFromAlliance",
    "PromoteMember",
    "DemoteMember",
    "PlayerAddedToAlliance",
    "PlayerRemovedFromAlliance",
    "AllianceUpdated",
    "RequestAllianceData",
    "AllianceDataResponse"
}

-- Create all alliance events
for _, eventName in ipairs(allianceEvents) do
    createRemoteEvent(allianceFolder, eventName)
end

-- Create direct events in ReplicatedStorage for backward compatibility
-- These were mentioned in the issues list as causing infinite yield errors
createRemoteEvent(ReplicatedStorage, "PlayerAddedToAllianceEvent")
createRemoteEvent(ReplicatedStorage, "PlayerRemovedFromAllianceEvent")

-- Try to register with CoreRegistry if available
local CoreRegistry
success, result = pcall(function()
    if ServerScriptService:FindFirstChild("Core") and
       ServerScriptService.Core:FindFirstChild("CoreRegistry") then
        return require(ServerScriptService.Core.CoreRegistry)
    end
    return nil
end)

if success and result then
    CoreRegistry = result
    print("[AllianceEventSetup] Found CoreRegistry, registering events")
    
    -- Try to get EventBridge
    local EventBridge = CoreRegistry:GetSystem("EventBridge")
    if EventBridge then
        -- Register all events with EventBridge
        for _, eventName in ipairs(allianceEvents) do
            if typeof(EventBridge.registerRemoteEvent) == "function" then
                EventBridge:registerRemoteEvent(eventName, allianceFolder[eventName])
                print("[AllianceEventSetup] Registered event with EventBridge: " .. eventName)
            end
        end
        
        -- Register backward compatibility events
        EventBridge:registerRemoteEvent("PlayerAddedToAllianceEvent", ReplicatedStorage.PlayerAddedToAllianceEvent)
        EventBridge:registerRemoteEvent("PlayerRemovedFromAllianceEvent", ReplicatedStorage.PlayerRemovedFromAllianceEvent)
    end
end

print("[AllianceEventSetup] All alliance events created successfully")

return {
    allianceEvents = allianceEvents,
    allianceFolder = allianceFolder
}
