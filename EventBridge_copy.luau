--[[
    EventBridge.luau
    
    Core system for cross-boundary event communication.
    This module provides a centralized event system for client-server communication.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EventBridge = {}
EventBridge.initialized = false

-- Configuration
local CONFIG = {
    REMOTE_EVENTS_FOLDER_NAME = "EventBridgeEvents",
    REMOTE_FUNCTIONS_FOLDER_NAME = "EventBridgeFunctions",
    MAX_EVENT_HISTORY = 100,
    SECURITY_LEVEL = 2, -- 0=None, 1=Basic, 2=Standard, 3=High
    LOG_TRAFFIC = false
}

-- Debug settings
EventBridge.DEBUG = true

-- Internal state
local events = {}
local eventHandlers = {}
local functionHandlers = {}
local eventHistory = {}
local securityRules = {}

-- Is this running on the server?
local isServer = RunService:IsServer()

-- Log a message to the output
local function log(message)
    if EventBridge.DEBUG then
        print("[EventBridge] " .. message)
    end
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try in ReplicatedStorage
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("replicatedStorage") then
        -- Try CoreRegistryShared for clients
        if not isServer and shared.replicatedStorage:FindFirstChild("CoreRegistryShared") then
            local success, result = pcall(function()
                return require(shared.replicatedStorage.CoreRegistryShared)
            end)
            
            if success and result then
                return result
            end
        end
        
        -- Try ModuleScriptAccessor
        if shared.replicatedStorage:FindFirstChild("ModuleScriptAccessor") then
            local success, result = pcall(function()
                return require(shared.replicatedStorage.ModuleScriptAccessor)
            end)
            
            if success and result and typeof(result.getCoreRegistry) == "function" then
                return result.getCoreRegistry()
            end
        end
    end
    
    -- Try server paths if on server
    if isServer then
        local standardPaths = {
            ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
        }
        
        for _, path in ipairs(standardPaths) do
            if path and path:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(path)
                end)
                
                if success and result then
                    return result
                end
            end
        end
    end
    
    return nil
end

-- Initialize the EventBridge
function EventBridge.initialize()
    if EventBridge.initialized then
        return true
    end
    
    log("Initializing EventBridge...")
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("EventBridge", EventBridge)
        log("Registered with CoreRegistry")
    else
        log("CoreRegistry not found, but EventBridge will still function")
    end
    
    -- Create remote event folders
    local eventsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_EVENTS_FOLDER_NAME)
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = CONFIG.REMOTE_EVENTS_FOLDER_NAME
        eventsFolder.Parent = ReplicatedStorage
        log("Created remote events folder")
    end
    
    local functionsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_FUNCTIONS_FOLDER_NAME)
    if not functionsFolder then
        functionsFolder = Instance.new("Folder")
        functionsFolder.Name = CONFIG.REMOTE_FUNCTIONS_FOLDER_NAME
        functionsFolder.Parent = ReplicatedStorage
        log("Created remote functions folder")
    end
    
    -- Set up security rules
    EventBridge.setupDefaultSecurityRules()
    
    -- If on the client, connect to server events
    if not isServer then
        EventBridge.connectToServerEvents()
    end
    
    EventBridge.initialized = true
    log("EventBridge initialized" .. (isServer and " (server)" or " (client)"))
    
    return true
end

-- Set up default security rules
function EventBridge.setupDefaultSecurityRules()
    if not isServer then
        return -- Only apply on server
    end
    
    -- Security rule example:
    -- securityRules["EventName"] = {
    --     rateLimit = 5,  -- Max 5 calls per second per player
    --     cooldown = 0.2, -- 0.2 seconds between calls
    --     validate = function(player, ...) return true end -- Custom validation
    -- }
    
    -- Default rules for common events
    securityRules["PlayerAction"] = {
        rateLimit = 10,  -- 10 actions per second
        cooldown = 0.05  -- 50ms cooldown between actions
    }
    
    securityRules["ChatMessage"] = {
        rateLimit = 3,    -- 3 messages per second
        cooldown = 0.3,   -- 300ms cooldown between messages
        validate = function(player, message)
            return type(message) == "string" and #message <= 200
        end
    }
    
    securityRules["PurchaseItem"] = {
        rateLimit = 2,    -- 2 purchases per second max
        cooldown = 0.5,   -- 500ms cooldown between purchases
        validate = function(player, itemId)
            return type(itemId) == "string" or type(itemId) == "number"
        end
    }
    
    log("Set up default security rules")
end

-- Connect to server events (client-side)
function EventBridge.connectToServerEvents()
    if isServer then 
        return -- Only used on client
    end
    
    -- Get all remote events
    local eventsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_EVENTS_FOLDER_NAME)
    if not eventsFolder then
        log("Events folder not found")
        return
    end
    
    for _, remote in ipairs(eventsFolder:GetChildren()) do
        if remote:IsA("RemoteEvent") then
            local eventName = remote.Name
            
            -- Connect to event if not already connected
            if not events[eventName] then
                events[eventName] = remote
                
                -- Create event connector
                remote.OnClientEvent:Connect(function(...)
                    EventBridge.handleEventFromServer(eventName, ...)
                end)
                
                log("Connected to server event: " .. eventName)
            end
        end
    end
    
    -- Get all remote functions
    local functionsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_FUNCTIONS_FOLDER_NAME)
    if not functionsFolder then
        log("Functions folder not found")
        return
    end
    
    -- We don't need to connect to RemoteFunctions in the same way,
    -- as they will be invoked directly
end

-- Handle an event from the server (client-side)
function EventBridge.handleEventFromServer(eventName, ...)
    if isServer then 
        return -- Only used on client
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "from_server",
            event = eventName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Call any registered handlers
    local handlers = eventHandlers[eventName]
    if handlers then
        for _, handler in ipairs(handlers) do
            task.spawn(function()
                local success, result = pcall(handler, ...)
                if not success then
                    warn("[EventBridge] Error in handler for " .. eventName .. ": " .. tostring(result))
                end
            end)
        end
    end
end

-- Create or get a remote event
function EventBridge.getRemoteEvent(eventName)
    if not EventBridge.initialized then
        EventBridge.initialize()
    end
    
    -- Check if already exists
    if events[eventName] then
        return events[eventName]
    end
    
    -- Create or get from folder
    local eventsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_EVENTS_FOLDER_NAME)
    if not eventsFolder then
        log("Events folder not found")
        return nil
    end
    
    -- Check if exists in folder
    local existingEvent = eventsFolder:FindFirstChild(eventName)
    if existingEvent and existingEvent:IsA("RemoteEvent") then
        events[eventName] = existingEvent
        return existingEvent
    end
    
    -- Create new event if on server
    if isServer then
        local newEvent = Instance.new("RemoteEvent")
        newEvent.Name = eventName
        newEvent.Parent = eventsFolder
        
        events[eventName] = newEvent
        log("Created remote event: " .. eventName)
        return newEvent
    else
        log("Failed to get remote event: " .. eventName)
        return nil
    end
end

-- Create or get a remote function
function EventBridge.getRemoteFunction(functionName)
    if not EventBridge.initialized then
        EventBridge.initialize()
    end
    
    -- Check if exists in folder
    local functionsFolder = ReplicatedStorage:FindFirstChild(CONFIG.REMOTE_FUNCTIONS_FOLDER_NAME)
    if not functionsFolder then
        log("Functions folder not found")
        return nil
    end
    
    local existingFunction = functionsFolder:FindFirstChild(functionName)
    if existingFunction and existingFunction:IsA("RemoteFunction") then
        return existingFunction
    end
    
    -- Create new function if on server
    if isServer then
        local newFunction = Instance.new("RemoteFunction")
        newFunction.Name = functionName
        newFunction.Parent = functionsFolder
        
        log("Created remote function: " .. functionName)
        return newFunction
    else
        log("Failed to get remote function: " .. functionName)
        return nil
    end
end

-- Track player event rates (server-side)
local playerEventRates = {}
local playerCooldowns = {}

-- Check rate limit for a player and event
local function checkRateLimit(player, eventName)
    if CONFIG.SECURITY_LEVEL <= 0 then
        return true
    end
    
    local userId = player and player.UserId
    if not userId then
        return false
    end
    
    -- Check cooldown first
    local cooldowns = playerCooldowns[userId]
    if not cooldowns then
        cooldowns = {}
        playerCooldowns[userId] = cooldowns
    end
    
    local rule = securityRules[eventName] or { cooldown = 0, rateLimit = 20 }
    local lastTime = cooldowns[eventName] or 0
    local now = os.time()
    
    if now - lastTime < rule.cooldown then
        return false
    end
    
    -- Update cooldown
    cooldowns[eventName] = now
    
    -- Check rate limit
    if CONFIG.SECURITY_LEVEL >= 2 and rule.rateLimit then
        local rates = playerEventRates[userId]
        if not rates then
            rates = {}
            playerEventRates[userId] = rates
        end
        
        local eventRate = rates[eventName]
        if not eventRate then
            eventRate = {
                count = 0,
                lastReset = now
            }
            rates[eventName] = eventRate
        end
        
        -- Reset counter if more than 1 second has passed
        if now - eventRate.lastReset >= 1 then
            eventRate.count = 0
            eventRate.lastReset = now
        end
        
        -- Check if rate limit is exceeded
        if eventRate.count >= rule.rateLimit then
            return false
        end
        
        -- Increment counter
        eventRate.count = eventRate.count + 1
    end
    
    return true
end

-- Validate event data
local function validateEventData(player, eventName, ...)
    if CONFIG.SECURITY_LEVEL <= 1 then
        return true
    end
    
    local rule = securityRules[eventName]
    if rule and rule.validate then
        return rule.validate(player, ...)
    end
    
    return true
end

-- Fire an event from server to client(s)
function EventBridge.fireClient(client, eventName, ...)
    if not isServer then
        warn("[EventBridge] fireClient can only be called from server")
        return false
    end
    
    if not client then
        warn("[EventBridge] Client is required for fireClient")
        return false
    end
    
    local remote = EventBridge.getRemoteEvent(eventName)
    if not remote then
        warn("[EventBridge] Failed to get remote event: " .. eventName)
        return false
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "to_client",
            target = typeof(client) == "Instance" and client.Name or "multiple",
            event = eventName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire the event
    remote:FireClient(client, ...)
    return true
end

-- Fire an event from server to all clients
function EventBridge.fireAllClients(eventName, ...)
    if not isServer then
        warn("[EventBridge] fireAllClients can only be called from server")
        return false
    end
    
    local remote = EventBridge.getRemoteEvent(eventName)
    if not remote then
        warn("[EventBridge] Failed to get remote event: " .. eventName)
        return false
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "to_all_clients",
            event = eventName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire the event
    remote:FireAllClients(...)
    return true
end

-- Fire an event from client to server
function EventBridge.fireServer(eventName, ...)
    if isServer then
        warn("[EventBridge] fireServer can only be called from client")
        return false
    end
    
    local remote = EventBridge.getRemoteEvent(eventName)
    if not remote then
        warn("[EventBridge] Failed to get remote event: " .. eventName)
        return false
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "to_server",
            event = eventName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire the event
    remote:FireServer(...)
    return true
end

-- Listen for events on the server
function EventBridge.onServerEvent(eventName, callback)
    if not isServer then
        warn("[EventBridge] onServerEvent can only be called from server")
        return false
    end
    
    if not callback or typeof(callback) ~= "function" then
        warn("[EventBridge] Callback must be a function")
        return false
    end
    
    local remote = EventBridge.getRemoteEvent(eventName)
    if not remote then
        warn("[EventBridge] Failed to get remote event: " .. eventName)
        return false
    end
    
    -- Connect to event
    remote.OnServerEvent:Connect(function(player, ...)
        -- Check security rules
        if not checkRateLimit(player, eventName) then
            log("Rate limit exceeded for " .. eventName .. " by " .. player.Name)
            return
        end
        
        if not validateEventData(player, eventName, ...) then
            log("Validation failed for " .. eventName .. " by " .. player.Name)
            return
        end
        
        -- Record in history
        if CONFIG.LOG_TRAFFIC then
            table.insert(eventHistory, {
                time = os.time(),
                direction = "from_client",
                source = player.Name,
                event = eventName,
                args = {...}
            })
            
            -- Trim history if needed
            if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
                table.remove(eventHistory, 1)
            end
        end
        
        -- Call the callback
        task.spawn(function()
            local success, result = pcall(callback, player, ...)
            if not success then
                warn("[EventBridge] Error in handler for " .. eventName .. ": " .. tostring(result))
            end
        end)
    end)
    
    log("Added server handler for event: " .. eventName)
    return true
end

-- Listen for events on the client
function EventBridge.onClientEvent(eventName, callback)
    if isServer then
        warn("[EventBridge] onClientEvent can only be called from client")
        return false
    end
    
    if not callback or typeof(callback) ~= "function" then
        warn("[EventBridge] Callback must be a function")
        return false
    end
    
    -- Create handlers array if needed
    if not eventHandlers[eventName] then
        eventHandlers[eventName] = {}
    end
    
    -- Add to handlers
    table.insert(eventHandlers[eventName], callback)
    
    -- Make sure we're connected to the event
    if not events[eventName] then
        local remote = EventBridge.getRemoteEvent(eventName)
        if remote then
            events[eventName] = remote
            
            -- Connect to event
            remote.OnClientEvent:Connect(function(...)
                EventBridge.handleEventFromServer(eventName, ...)
            end)
        end
    end
    
    log("Added client handler for event: " .. eventName)
    return true
end

-- Set up a server function handler
function EventBridge.setServerFunction(functionName, callback)
    if not isServer then
        warn("[EventBridge] setServerFunction can only be called from server")
        return false
    end
    
    if not callback or typeof(callback) ~= "function" then
        warn("[EventBridge] Callback must be a function")
        return false
    end
    
    local remote = EventBridge.getRemoteFunction(functionName)
    if not remote then
        warn("[EventBridge] Failed to create remote function: " .. functionName)
        return false
    end
    
    -- Set server handler
    remote.OnServerInvoke = function(player, ...)
        -- Check security rules (similar to events)
        if not checkRateLimit(player, functionName) then
            log("Rate limit exceeded for function " .. functionName .. " by " .. player.Name)
            return nil, "Rate limit exceeded"
        end
        
        if not validateEventData(player, functionName, ...) then
            log("Validation failed for function " .. functionName .. " by " .. player.Name)
            return nil, "Validation failed"
        end
        
        -- Record in history
        if CONFIG.LOG_TRAFFIC then
            table.insert(eventHistory, {
                time = os.time(),
                direction = "from_client_invoke",
                source = player.Name,
                func = functionName,
                args = {...}
            })
            
            -- Trim history if needed
            if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
                table.remove(eventHistory, 1)
            end
        end
        
        -- Call the callback
        local success, result = pcall(callback, player, ...)
        if not success then
            warn("[EventBridge] Error in handler for function " .. functionName .. ": " .. tostring(result))
            return nil, "Internal error"
        end
        
        return result
    end
    
    log("Set server function handler for: " .. functionName)
    return true
end

-- Set up a client function handler
function EventBridge.setClientFunction(functionName, callback)
    if isServer then
        warn("[EventBridge] setClientFunction can only be called from client")
        return false
    end
    
    if not callback or typeof(callback) ~= "function" then
        warn("[EventBridge] Callback must be a function")
        return false
    end
    
    local remote = EventBridge.getRemoteFunction(functionName)
    if not remote then
        warn("[EventBridge] Failed to get remote function: " .. functionName)
        return false
    end
    
    -- Set client handler
    remote.OnClientInvoke = function(...)
        -- Record in history
        if CONFIG.LOG_TRAFFIC then
            table.insert(eventHistory, {
                time = os.time(),
                direction = "from_server_invoke",
                func = functionName,
                args = {...}
            })
            
            -- Trim history if needed
            if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
                table.remove(eventHistory, 1)
            end
        end
        
        -- Call the callback
        local success, result = pcall(callback, ...)
        if not success then
            warn("[EventBridge] Error in handler for function " .. functionName .. ": " .. tostring(result))
            return nil, "Internal error"
        end
        
        return result
    end
    
    log("Set client function handler for: " .. functionName)
    return true
end

-- Call a function on the server from the client
function EventBridge.invokeServer(functionName, ...)
    if isServer then
        warn("[EventBridge] invokeServer can only be called from client")
        return nil, "Can only be called from client"
    end
    
    local remote = EventBridge.getRemoteFunction(functionName)
    if not remote then
        warn("[EventBridge] Failed to get remote function: " .. functionName)
        return nil, "Function not found"
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "to_server_invoke",
            func = functionName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Call the function
    local success, result = pcall(function()
        return remote:InvokeServer(...)
    end)
    
    if not success then
        warn("[EventBridge] Error invoking server function " .. functionName .. ": " .. tostring(result))
        return nil, "Invocation failed"
    end
    
    return result
end

-- Call a function on a specific client from the server
function EventBridge.invokeClient(client, functionName, ...)
    if not isServer then
        warn("[EventBridge] invokeClient can only be called from server")
        return nil, "Can only be called from server"
    end
    
    if not client or not client:IsA("Player") then
        warn("[EventBridge] Client must be a Player")
        return nil, "Client must be a Player"
    end
    
    local remote = EventBridge.getRemoteFunction(functionName)
    if not remote then
        warn("[EventBridge] Failed to get remote function: " .. functionName)
        return nil, "Function not found"
    end
    
    -- Record in history
    if CONFIG.LOG_TRAFFIC then
        table.insert(eventHistory, {
            time = os.time(),
            direction = "to_client_invoke",
            target = client.Name,
            func = functionName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Call the function
    local success, result = pcall(function()
        return remote:InvokeClient(client, ...)
    end)
    
    if not success then
        warn("[EventBridge] Error invoking client function " .. functionName .. ": " .. tostring(result))
        return nil, "Invocation failed"
    end
    
    return result
end

-- Set a security rule for an event/function
function EventBridge.setSecurityRule(name, rule)
    if not isServer then
        warn("[EventBridge] setSecurityRule can only be called from server")
        return false
    end
    
    if not name or type(name) ~= "string" or not rule or type(rule) ~= "table" then
        warn("[EventBridge] Invalid parameters for setSecurityRule")
        return false
    end
    
    securityRules[name] = rule
    log("Set security rule for: " .. name)
    return true
end

-- Get event traffic history
function EventBridge.getTrafficHistory()
    return eventHistory
end

-- Clear event traffic history
function EventBridge.clearTrafficHistory()
    eventHistory = {}
    log("Cleared traffic history")
    return true
end

-- Client interface that's safe to expose to clients
function EventBridge:getClientInterface()
    -- For security, we only expose a limited set of functions to clients
    local clientInterface = {
        fireServer = self.fireServer,
        onClientEvent = self.onClientEvent,
        setClientFunction = self.setClientFunction,
        invokeServer = self.invokeServer
    }
    
    return clientInterface
end

-- Initialize the EventBridge
EventBridge.initialize()

return EventBridge

