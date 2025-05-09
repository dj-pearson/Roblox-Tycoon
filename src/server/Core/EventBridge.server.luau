-- EventBridge.luau
-- Central event management system for cross-system communication
-- Place in ServerScriptService/Core

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventBridge = {
    events = {},
    remoteEvents = {},
    status = "Initializing",
    eventFolder = nil
}

-- Debug function with enhanced logging
local function log(level, ...)
    local prefix = "[EventBridge]"
    if level == "ERROR" then
        warn(prefix, "ERROR:", ...)
    elseif level == "WARNING" then
        warn(prefix, "WARNING:", ...)
    else
        print(prefix, ...)
    end
end

-- Validate event name
local function validateEventName(eventName)
    if type(eventName) ~= "string" then
        log("ERROR", "Invalid event name type: " .. type(eventName))
        return false
    end
    
    if eventName == "" then
        log("ERROR", "Empty event name")
        return false
    end
    
    return true
end

-- Initialize the module
function EventBridge:initialize()
    log("INFO", "Initializing EventBridge...")
    
    -- Create EventBridge folder in ReplicatedStorage if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("EventBridge") then
        local success, result = pcall(function()
            local eventFolder = Instance.new("Folder")
            eventFolder.Name = "EventBridge"
            eventFolder.Parent = ReplicatedStorage
            self.eventFolder = eventFolder
            log("INFO", "Created EventBridge folder in ReplicatedStorage")
        end)
        
        if not success then
            log("ERROR", "Failed to create EventBridge folder: " .. tostring(result))
            self.status = "Error"
            return false
        end
    else
        self.eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    end
    
    -- Create or get core events
    local coreEvents = {
        "TilePurchased",
        "DuesCollected",
        "NPCSpawned",
        "GymLevelUp",
        "MilestoneReached",
        "SpecializationChanged",
        "SeasonalEventStarted",
        "SeasonalEventEnded",
        "DataLoaded",
        "DataSaved",
        "PlayerJoined",
        "PlayerLeft",
        "ErrorOccurred"
    }
    
    local success = true
    for _, eventName in ipairs(coreEvents) do
        if not self:getOrCreateEvent(eventName) then
            success = false
            log("ERROR", "Failed to create core event: " .. eventName)
        end
    end
    
    if success then
        self.status = "Ready"
        log("INFO", "EventBridge initialized successfully")
    else
        self.status = "Degraded"
        log("WARNING", "EventBridge initialized with some errors")
    end
    
    return success
end

-- Get or create an event
function EventBridge:getOrCreateEvent(eventName)
    if not validateEventName(eventName) then
        return nil
    end
    
    -- Check if we already have this event cached
    if self.events[eventName] then
        return self.events[eventName]
    end
    
    if not self.eventFolder then
        log("ERROR", "EventBridge folder not found!")
        return nil
    end
    
    -- Check if event already exists
    local existingEvent = self.eventFolder:FindFirstChild(eventName)
    if existingEvent then
        self.events[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new event
    local success, newEvent = pcall(function()
        local event = Instance.new("BindableEvent")
        event.Name = eventName
        event.Parent = self.eventFolder
        return event
    end)
    
    if success and newEvent then
        self.events[eventName] = newEvent
        log("INFO", "Created event: " .. eventName)
        return newEvent
    else
        log("ERROR", "Failed to create event: " .. eventName)
        return nil
    end
end

-- Create a remote event (for client-server communication)
function EventBridge:getOrCreateRemoteEvent(eventName)
    if not validateEventName(eventName) then
        return nil
    end
    
    -- Check if we already have this remote event cached
    if self.remoteEvents[eventName] then
        return self.remoteEvents[eventName]
    end
    
    if not self.eventFolder then
        log("ERROR", "EventBridge folder not found!")
        return nil
    end
    
    -- Check if remote event already exists
    local existingEvent = self.eventFolder:FindFirstChild(eventName .. "Remote")
    if existingEvent then
        self.remoteEvents[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new remote event
    local success, newEvent = pcall(function()
        local event = Instance.new("RemoteEvent")
        event.Name = eventName .. "Remote"
        event.Parent = self.eventFolder
        return event
    end)
    
    if success and newEvent then
        self.remoteEvents[eventName] = newEvent
        log("INFO", "Created remote event: " .. eventName .. "Remote")
        return newEvent
    else
        log("ERROR", "Failed to create remote event: " .. eventName)
        return nil
    end
end

-- Fire an event
function EventBridge:fireEvent(eventName, ...)
    local args = {...}
    if not validateEventName(eventName) then
        return false
    end
    
    local event = self:getOrCreateEvent(eventName)
    if event then
        local success, err = pcall(function()
            event:Fire(unpack(args))
        end)
        
        if success then
            return true
        else
            log("ERROR", "Failed to fire event " .. eventName .. ": " .. tostring(err))
            return false
        end
    else
        log("ERROR", "Failed to get/create event: " .. eventName)
        return false
    end
end

-- Connect to an event
function EventBridge:connectEvent(eventName, callback)
    if not validateEventName(eventName) then
        return nil
    end
    
    if type(callback) ~= "function" then
        log("ERROR", "Invalid callback type for event " .. eventName)
        return nil
    end
    
    local event = self:getOrCreateEvent(eventName)
    if event then
        local success, connection = pcall(function()
            return event.Event:Connect(callback)
        end)
        
        if success then
            return connection
        else
            log("ERROR", "Failed to connect to event " .. eventName .. ": " .. tostring(connection))
            return nil
        end
    else
        log("ERROR", "Failed to get/create event: " .. eventName)
        return nil
    end
end

-- Fire a remote event to clients
function EventBridge:fireClientEvent(eventName, player, ...)
    local args = {...}
    if not validateEventName(eventName) then
        return false
    end
    
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        local success, err = pcall(function()
            if player then
                -- Fire to specific player
                event:FireClient(player, unpack(args))
            else
                -- Fire to all players
                event:FireAllClients(unpack(args))
            end
        end)
        
        if success then
            return true
        else
            log("ERROR", "Failed to fire remote event " .. eventName .. ": " .. tostring(err))
            return false
        end
    else
        log("ERROR", "Failed to get/create remote event: " .. eventName)
        return false
    end
end

-- Connect a server handler to a remote event
function EventBridge:connectRemoteEvent(eventName, callback)
    if not validateEventName(eventName) then
        return nil
    end
    
    if type(callback) ~= "function" then
        log("ERROR", "Invalid callback type for remote event " .. eventName)
        return nil
    end
    
    local event = self:getOrCreateRemoteEvent(eventName)
    if event then
        local success, connection = pcall(function()
            return event.OnServerEvent:Connect(callback)
        end)
        
        if success then
            return connection
        else
            log("ERROR", "Failed to connect to remote event " .. eventName .. ": " .. tostring(connection))
            return nil
        end
    else
        log("ERROR", "Failed to get/create remote event: " .. eventName)
        return nil
    end
end

-- Get bridge status
function EventBridge:getStatus()
    return self.status
end

-- Register with CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)
return CoreRegistry.registerSystem("EventBridge", EventBridge, {})