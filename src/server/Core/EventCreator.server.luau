--[[
    EventCreator.server.luau
    
    Creates all the remote events that the game needs at startup to prevent
    "Infinite yield possible on WaitForChild" errors.
    
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
end

-- Fallback if SafeWaitForChild is not available
local function ensureFolderExists(parent, name)
    if SafeWaitForChild then
        return SafeWaitForChild.ensureFolder(parent, name)
    end
    
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("[EventCreator] Created folder: " .. name .. " in " .. parent:GetFullName())
    end
    return folder
end

local function createRemoteEvent(parent, name)
    local event = parent:FindFirstChild(name)
    if event and event:IsA("RemoteEvent") then
        return event
    end
    
    event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = parent
    print("[EventCreator] Created RemoteEvent: " .. name)
    return event
end

-- Create a folder to store all remote events
local eventsFolder = ensureFolderExists(ReplicatedStorage, "Events")

-- List of events we need to create ahead of time
local commonEvents = {
    -- Core system events
    "PlaySoundEvent",
    "ShowNotification",
    "RequestDataUpdate",
    "DataUpdated",
    
    -- Alliance system events
    "PlayerAddedToAllianceEvent",
    "PlayerRemovedFromAllianceEvent",
    "AllianceInviteEvent",
    "AllianceResponseEvent",
    "AllianceCreatedEvent",
    "AllianceDeletedEvent",
    
    -- Buy tile system events
    "PurchaseTileEvent",
    "TileStateChangedEvent",
    "RequestTileInfoEvent",
    "TileInfoResponseEvent",
    
    -- UI events
    "UIActionEvent",
    "UIStateChanged",
    "MenuToggleEvent",
    "CloseAllMenusEvent"
}

-- Create them all
for _, eventName in ipairs(commonEvents) do
    createRemoteEvent(eventsFolder, eventName)
end

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
    print("[EventCreator] Found CoreRegistry, registering events")
    
    -- Try to get EventBridge
    local EventBridge = CoreRegistry:GetSystem("EventBridge")
    if EventBridge then
        -- Register all events with EventBridge
        for _, eventName in ipairs(commonEvents) do
            if typeof(EventBridge.registerRemoteEvent) == "function" then
                EventBridge:registerRemoteEvent(eventName, eventsFolder[eventName])
                print("[EventCreator] Registered event with EventBridge: " .. eventName)
            end
        end
    end
end

print("[EventCreator] All events created successfully")

return {
    eventsList = commonEvents,
    eventsFolder = eventsFolder
}
