-- EventBridge.luau
-- Central event management system for cross-system communication
-- Place in ServerScriptService/Core

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventBridge = {
    events = {},
    remoteEvents = {}
}

-- Debug function
local function log(...)
    print("[EventBridge]", ...)
end

-- Initialize the module
function EventBridge:initialize()
    -- Create EventBridge folder in ReplicatedStorage if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("EventBridge") then
        local eventFolder = Instance.new("Folder")
        eventFolder.Name = "EventBridge"
        eventFolder.Parent = ReplicatedStorage
        log("Created EventBridge folder in ReplicatedStorage")
    end
    
    -- Create or get core events
    self:getOrCreateEvent("TilePurchased")
    self:getOrCreateEvent("DuesCollected")
    self:getOrCreateEvent("NPCSpawned")
    self:getOrCreateEvent("GymLevelUp")
    self:getOrCreateEvent("MilestoneReached")
    self:getOrCreateEvent("SpecializationChanged")
    self:getOrCreateEvent("SeasonalEventStarted")
    self:getOrCreateEvent("SeasonalEventEnded")
    
    log("EventBridge initialized")
    return true
end

-- Get or create an event
function EventBridge:getOrCreateEvent(eventName)
    -- Check if we already have this event cached
    if self.events[eventName] then
        return self.events[eventName]
    end
    
    local eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventFolder then
        log("EventBridge folder not found!")
        return nil
    end
    
    -- Check if event already exists
    local existingEvent = eventFolder:FindFirstChild(eventName)
    if existingEvent then
        self.events[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new event
    local newEvent = Instance.new("BindableEvent")
    newEvent.Name = eventName
    newEvent.Parent = eventFolder
    
    self.events[eventName] = newEvent
    log("Created event: " .. eventName)
    
    return newEvent
end

-- Create a remote event (for client-server communication)
function EventBridge:getOrCreateRemoteEvent(eventName)
    -- Check if we already have this remote event cached
    if self.remoteEvents[eventName] then
        return self.remoteEvents[eventName]
    end
    
    local eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventFolder then
        log("EventBridge folder not found!")
        return nil
    end
    
    -- Check if remote event already exists
    local existingEvent = eventFolder:FindFirstChild(eventName .. "Remote")
    if existingEvent then
        self.remoteEvents[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new remote event
    local newEvent = Instance.new("RemoteEvent")
    newEvent.Name = eventName .. "Remote"
    newEvent.Parent = eventFolder
    
    self.remoteEvents[eventName] = newEvent
    log("Created remote event: " .. eventName .. "Remote")
    
    return newEvent
end

-- Fire an event
function EventBridge:fireEvent(eventName, ...)
    local event = self:getOrCreateEvent(eventName)
    if event then
        event:Fire(...)
    else
        log("Failed to fire event: " .. eventName)
    end
end

-- Connect to an event
function EventBridge:connectEvent(eventName, callback)
    local event = self:getOrCreateEvent(eventName)
    if event then
        return event.Event:Connect(callback)
    else
        log("Failed to connect to event: " .. eventName)
        return nil
    end
end

-- Fire a remote event to clients
function EventBridge:fireClientEvent(eventName, player, ...)
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        if player then
            -- Fire to specific player
            event:FireClient(player, ...)
        else
            -- Fire to all players
            event:FireAllClients(...)
        end
    else
        log("Failed to fire remote event: " .. eventName)
    end
end

-- Connect a server handler to a remote event
function EventBridge:connectRemoteEvent(eventName, callback)
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        return event.OnServerEvent:Connect(callback)
    else
        log("Failed to connect to remote event: " .. eventName)
        return nil
    end
end

-- Register with CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)
return CoreRegistry.registerSystem("EventBridge", EventBridge, {})