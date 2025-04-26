--!strict
--[[
    EventCreator.server.luau
    
    Creates all the remote events that the game needs at startup to prevent
    "Infinite yield possible on WaitForChild" errors.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug settings
local DEBUG_ENABLED = true

-- Print debug messages
local function log(message)
    if DEBUG_ENABLED then
        print("[EventCreator] " .. message)
    end
end

local function warn_log(message)
    warn("[EventCreator] " .. message)
end

-- Try to load CoreRegistryAccess
local CoreRegistryAccess
local success, result = pcall(function()
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder and sharedFolder:FindFirstChild("CoreRegistryAccess") then
        return require(sharedFolder.CoreRegistryAccess)
    end
    return nil
end)

if success and result then
    CoreRegistryAccess = result
    log("Loaded CoreRegistryAccess")
else
    log("CoreRegistryAccess not found, using fallback methods")
end

-- Find folder with fallbacks
local function ensureFolderExists(parent, name)
    if not parent then
        return nil
    end
    
    local folder = parent:FindFirstChild(name)
    if folder and folder:IsA("Folder") then
        return folder
    end
    
    folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    log("Created folder: " .. name .. " in " .. parent:GetFullName())
    
    return folder
end

local function createRemoteEvent(parent, name)
    if not parent then
        warn_log("Cannot create RemoteEvent '" .. name .. "' - parent is nil")
        return nil
    end
    
    local event = parent:FindFirstChild(name)
    if event and event:IsA("RemoteEvent") then
        return event
    end
    
    event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = parent
    log("Created RemoteEvent: " .. name)
    return event
end

-- Create a folder to store all remote events
local eventsFolder = ensureFolderExists(ReplicatedStorage, "Events")
if not eventsFolder then
    warn_log("Failed to create or find Events folder in ReplicatedStorage")
    return
end

-- List of events we need to create ahead of time
local COMMON_EVENTS = {
    -- Core system events
    "PlaySoundEvent",
    "ShowNotification",
    "RequestDataUpdate",
    "DataUpdated",
    "UIActionEvent",
    "UIStateChanged",
    "CloseAllMenusEvent",
    
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
    "EquipmentPurchasedEvent",
    
    -- Admin system events
    "AdminCommandEvent",
    "AdminResponseEvent",
    
    -- Menu events
    "MenuToggleEvent",
    "MenuActionEvent",
    
    -- Tutorial system events
    "TutorialStartEvent",
    "TutorialStepEvent",
    "TutorialCompleteEvent"
}

-- Create all common events
local createdEvents = {}
for _, eventName in ipairs(COMMON_EVENTS) do
    local event = createRemoteEvent(eventsFolder, eventName)
    if event then
        createdEvents[eventName] = event
    end
end

log("Created " .. #COMMON_EVENTS .. " remote events")

-- Try to register events with EventBridge if CoreRegistry is available
if CoreRegistryAccess then
    log("Attempting to register events with EventBridge")
    
    -- Get the EventBridge system
    local eventBridge = CoreRegistryAccess:GetSystem("EventBridge")
    if eventBridge then
        log("Found EventBridge, registering events")
        
        -- Register remote events with EventBridge
        local registeredCount = 0
        for eventName, event in pairs(createdEvents) do
            if eventBridge.remoteEvents then
                eventBridge.remoteEvents[eventName] = event
                registeredCount = registeredCount + 1
            end
        end
        
        log("Registered " .. registeredCount .. " events with EventBridge")
    else
        log("EventBridge not found in CoreRegistry")
    end
else
    -- Try to find CoreRegistry directly
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
        log("Found CoreRegistry directly")
        
        local eventBridge = CoreRegistry.getSystem and CoreRegistry:getSystem("EventBridge")
        if eventBridge and eventBridge.remoteEvents then
            -- Register events with EventBridge
            local registeredCount = 0
            for eventName, event in pairs(createdEvents) do
                eventBridge.remoteEvents[eventName] = event
                registeredCount = registeredCount + 1
            end
            
            log("Registered " .. registeredCount .. " events with EventBridge")
        end
    end
end

return {
    ensureFolderExists = ensureFolderExists,
    createRemoteEvent = createRemoteEvent,
    events = createdEvents
}
