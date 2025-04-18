-- ClientEventBridge.luau
-- Handles communication between client systems and with the server
-- Place in StarterPlayer/StarterPlayerScripts/Core

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Import the ClientRegistry
local ClientRegistry = require(script.Parent.ClientRegistry)

-- Configuration
local CONFIG = {
    debugEnabled = true,
    eventsBranch = "GymTycoonEvents",
    remoteEventsFolder = "RemoteEvents",
    remoteFunctionsFolder = "RemoteFunctions"
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[ClientEventBridge]", ...)
    end
end

-- The ClientEventBridge system
local ClientEventBridge = {
    -- Event handling
    events = {},             -- Local event handlers
    eventConnections = {},   -- Connections to events
    
    -- Remote event handling
    remoteEvents = {},       -- RemoteEvent references
    remoteFunctions = {},    -- RemoteFunction references
    
    -- State tracking
    isInitialized = false,
    eventCounter = 0
}

-- Initialize the event bridge
function ClientEventBridge:initialize()
    log("Initializing ClientEventBridge...")
    
    -- Wait for remote events and functions folders
    self:setupRemoteConnections()
    
    -- Set up core events
    self:setupCoreEvents()
    
    self.isInitialized = true
    log("ClientEventBridge initialized")
    return true
end

-- Set up core events
function ClientEventBridge:setupCoreEvents()
    -- Player-specific local events
    local coreEvents = {
        "PlayerDataUpdated",      -- When player data changes
        "InventoryUpdated",       -- When player inventory changes
        "TycoonUpdated",          -- When tycoon state changes
        "SpecializationChanged",  -- When player unlocks/changes specialization
        "UIRequested",            -- Request to show/hide UI
    }
    
    -- Create core events
    for _, eventName in ipairs(coreEvents) do
        self:createEvent(eventName)
    end
    
    log("Core events set up")
end

-- Set up remote connections
function ClientEventBridge:setupRemoteConnections()
    -- Get or create the events folder
    local eventsFolder = ReplicatedStorage:FindFirstChild(CONFIG.eventsBranch)
    if not eventsFolder then
        log("Events folder not found in ReplicatedStorage")
        return
    end
    
    -- Get remote events folder
    local remoteEventsFolder = eventsFolder:FindFirstChild(CONFIG.remoteEventsFolder)
    if not remoteEventsFolder then
        log("Remote events folder not found")
        return
    end
    
    -- Get remote functions folder
    local remoteFunctionsFolder = eventsFolder:FindFirstChild(CONFIG.remoteFunctionsFolder)
    if not remoteFunctionsFolder then
        log("Remote functions folder not found")
        return
    end
    
    -- Store references to remote events
    for _, remoteEvent in ipairs(remoteEventsFolder:GetChildren()) do
        if remoteEvent:IsA("RemoteEvent") then
            self.remoteEvents[remoteEvent.Name] = remoteEvent
            
            -- Connect remote event to client event system
            remoteEvent.OnClientEvent:Connect(function(...)
                self:fireEvent(remoteEvent.Name, ...)
            end)
        end
    end
    
    -- Store references to remote functions
    for _, remoteFunction in ipairs(remoteFunctionsFolder:GetChildren()) do
        if remoteFunction:IsA("RemoteFunction") then
            self.remoteFunctions[remoteFunction.Name] = remoteFunction
        end
    end
    
    log("Remote connections set up")
end

-- Create a new client-side event
function ClientEventBridge:createEvent(eventName)
    if self.events[eventName] then
        return self.events[eventName]
    end
    
    self.events[eventName] = {
        name = eventName,
        handlers = {},
        handlerCount = 0
    }
    
    log("Created event:", eventName)
    return self.events[eventName]
end

-- Connect a handler to an event
function ClientEventBridge:connectEvent(eventName, handler)
    if not eventName or type(handler) ~= "function" then
        log("Invalid event connection attempt")
        return nil
    end
    
    -- Create event if it doesn't exist
    if not self.events[eventName] then
        self:createEvent(eventName)
    end
    
    -- Generate a unique connection ID
    self.eventCounter = self.eventCounter + 1
    local connectionId = eventName .. "_" .. self.eventCounter
    
    -- Store the handler
    self.events[eventName].handlers[connectionId] = handler
    self.events[eventName].handlerCount = self.events[eventName].handlerCount + 1
    
    -- Create connection object
    local connection = {
        disconnect = function()
            self:disconnectEvent(eventName, connectionId)
        end,
        id = connectionId
    }
    
    self.eventConnections[connectionId] = {
        eventName = eventName,
        handler = handler
    }
    
    log("Connected handler to event:", eventName, connectionId)
    return connection
end

-- Disconnect a handler from an event
function ClientEventBridge:disconnectEvent(eventName, connectionId)
    if not self.events[eventName] or not self.events[eventName].handlers[connectionId] then
        return false
    end
    
    -- Remove the handler
    self.events[eventName].handlers[connectionId] = nil
    self.events[eventName].handlerCount = self.events[eventName].handlerCount - 1
    self.eventConnections[connectionId] = nil
    
    log("Disconnected handler from event:", eventName, connectionId)
    return true
end

-- Fire an event
function ClientEventBridge:fireEvent(eventName, ...)
    if not self.events[eventName] then
        -- Create event if it doesn't exist to support future connections
        self:createEvent(eventName)
        return
    end
    
    local event = self.events[eventName]
    
    -- Call all handlers
    for connectionId, handler in pairs(event.handlers) do
        local success, err = pcall(handler, ...)
        if not success then
            log("Error in event handler for", eventName, ":", err)
        end
    end
    
    return event.handlerCount > 0
end

-- Fire an event to the server
function ClientEventBridge:fireServerEvent(eventName, ...)
    local remoteEvent = self.remoteEvents[eventName]
    if not remoteEvent then
        log("Remote event not found:", eventName)
        return false
    end
    
    -- Send event to server
    local success, err = pcall(function()
        remoteEvent:FireServer()
    end)
    
    if not success then
        log("Error firing server event", eventName, ":", err)
        return false
    end
    
    return true
end

-- Call a server function
function ClientEventBridge:callServerFunction(functionName, ...)
    local remoteFunction = self.remoteFunctions[functionName]
    if not remoteFunction then
        log("Remote function not found:", functionName)
        return nil
    end
    
    -- Call server function
    local success, result = pcall(function()
        return remoteFunction:InvokeServer()
    end)
    
    if not success then
        log("Error calling server function", functionName, ":", result)
        return nil
    end
    
    return result
end

-- Remove all connections for a specific event
function ClientEventBridge:clearEvent(eventName)
    if not self.events[eventName] then
        return false
    end
    
    -- Remove all handlers
    for connectionId in pairs(self.events[eventName].handlers) do
        self:disconnectEvent(eventName, connectionId)
    end
    
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return ClientEventBridge:initialize()
    end,
    
    connectEvent = function(eventName, handler)
        return ClientEventBridge:connectEvent(eventName, handler)
    end,
    
    disconnectEvent = function(eventName, connectionId)
        return ClientEventBridge:disconnectEvent(eventName, connectionId)
    end,
    
    fireEvent = function(eventName, ...)
        return ClientEventBridge:fireEvent(eventName, ...)
    end,
    
    fireServerEvent = function(eventName, ...)
        return ClientEventBridge:fireServerEvent(eventName, ...)
    end,
    
    callServerFunction = function(functionName, ...)
        return ClientEventBridge:callServerFunction(functionName, ...)
    end,
    
    createEvent = function(eventName)
        return ClientEventBridge:createEvent(eventName)
    end,
    
    clearEvent = function(eventName)
        return ClientEventBridge:clearEvent(eventName)
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("ClientEventBridge", PublicAPI)