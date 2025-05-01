--[[
    EventBridge.luau
    A cross-server event system for Roblox games.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Check if we're running on the server
local isServer = RunService:IsServer()

-- Configuration
local CONFIG = {
    -- Whether to log all event traffic
    LOG_TRAFFIC = true,
    
    -- Maximum number of events to keep in history
    MAX_EVENT_HISTORY = 500,
    
    -- Whether to validate event data
    VALIDATE_EVENT_DATA = true,
    
    -- Maximum rate of events per second per player
    MAX_RATE_PER_PLAYER = 20,
    
    -- Time window for rate limiting (in seconds)
    RATE_LIMIT_WINDOW = 5
}

-- Private variables
local events = {}
local functions = {}
local eventHandlers = {}
local functionHandlers = {}
local securityRules = {}
local initialized = false
local lastEventTimes = {}
local eventHistory = {}
local pendingReplication = {}
local coreRegistry

-- Helper functions
local function log(message)
    if CONFIG.LOG_TRAFFIC then
        print("[EventBridge] " .. message)
    end
end

-- Try to find the CoreRegistry module
local function getCoreRegistry()
    if coreRegistry then
        return coreRegistry
    end
    
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
    
    -- Try in ServerScriptService
    if isServer then
        local standardPaths = {
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
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

-- Rate limiting
local function checkRateLimit(player, eventName)
    if not CONFIG.VALIDATE_EVENT_DATA then
        return true
    end
    
    -- Initialize player data if needed
    if not lastEventTimes[player.UserId] then
        lastEventTimes[player.UserId] = {}
    end
    
    -- Get current timestamp
    local now = tick()
    
    -- Get recent event times
    local playerEvents = lastEventTimes[player.UserId]
    local recentEvents = {}
    
    -- Filter to recent events within the window
    for i, eventData in ipairs(playerEvents) do
        if now - eventData.time < CONFIG.RATE_LIMIT_WINDOW then
            table.insert(recentEvents, eventData)
        end
    end
    
    -- Check if too many events
    if #recentEvents >= CONFIG.MAX_RATE_PER_PLAYER * CONFIG.RATE_LIMIT_WINDOW then
        warn("[EventBridge] Rate limit exceeded for player " .. player.Name)
        return false
    end
    
    -- Record this event
    table.insert(playerEvents, {
        time = now,
        event = eventName
    })
    
    -- Trim history
    if #playerEvents > CONFIG.MAX_RATE_PER_PLAYER * CONFIG.RATE_LIMIT_WINDOW * 2 then
        table.remove(playerEvents, 1)
    end
    
    return true
end

-- Data validation
local function validateEventData(player, eventName, ...)
    if not CONFIG.VALIDATE_EVENT_DATA then
        return true
    end
    
    -- Check if there's a validation rule for this event
    local rule = securityRules[eventName]
    if not rule then
        return true
    end
    
    -- Validate based on rule type
    if rule.type == "whitelist" then
        return rule.playerIds[player.UserId] ~= nil
    elseif rule.type == "validate" and typeof(rule.validate) == "function" then
        return rule.validate(player, ...)
    end
    
    return true
end

-- EventBridge API
local EventBridge = {
    initialized = false
}

-- Initialize the event bridge
function EventBridge.initialize()
    if EventBridge.initialized then
        return
    end
    
    -- Create folder for remotes if it doesn't exist
    local remoteFolder = ReplicatedStorage:FindFirstChild("EventBridgeRemotes")
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "EventBridgeRemotes"
        remoteFolder.Parent = ReplicatedStorage
    end
    
    -- Set up player cleanup on leave
    if isServer then
        Players.PlayerRemoving:Connect(function(player)
            lastEventTimes[player.UserId] = nil
        end)
    end
    
    EventBridge.initialized = true
    log("EventBridge initialized")
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
        local args = table.pack(...) -- Capture varargs locally
        for _, handler in ipairs(handlers) do
            task.spawn(function()
                local success, result = pcall(function()
                    return handler(table.unpack(args, 1, args.n))
                end)
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
    
    -- Get the remote folder
    local remoteFolder = ReplicatedStorage:FindFirstChild("EventBridgeRemotes")
    if not remoteFolder then
        warn("[EventBridge] Remote folder not found. Did you initialize?")
        return nil
    end
    
    -- Check if remote already exists
    local remote = remoteFolder:FindFirstChild("Event_" .. eventName)
    if not remote then
        -- Create new remote
        remote = Instance.new("RemoteEvent")
        remote.Name = "Event_" .. eventName
        remote.Parent = remoteFolder
    end
    
    -- Set up event handling on the client
    if not isServer then
        remote.OnClientEvent:Connect(function(...)
            EventBridge.handleEventFromServer(eventName, ...)
        end)
    end
    
    -- Cache and return
    events[eventName] = remote
    return remote
end

-- Create or get a remote function
function EventBridge.getRemoteFunction(functionName)
    if not EventBridge.initialized then
        EventBridge.initialize()
    end
    
    -- Check if already exists
    if functions[functionName] then
        return functions[functionName]
    end
    
    -- Get the remote folder
    local remoteFolder = ReplicatedStorage:FindFirstChild("EventBridgeRemotes")
    if not remoteFolder then
        warn("[EventBridge] Remote folder not found. Did you initialize?")
        return nil
    end
    
    -- Check if remote already exists
    local remote = remoteFolder:FindFirstChild("Function_" .. functionName)
    if not remote then
        -- Create new remote
        remote = Instance.new("RemoteFunction")
        remote.Name = "Function_" .. functionName
        remote.Parent = remoteFolder
    end
    
    -- Cache and return
    functions[functionName] = remote
    return remote
end

-- Send an event from server to all clients
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
    
    -- Fire event
    remote:FireAllClients(...)
    return true
end

-- Send an event from server to a specific client
function EventBridge.fireClient(client, eventName, ...)
    if not isServer then
        warn("[EventBridge] fireClient can only be called from server")
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
            target = client.Name,
            event = eventName,
            args = {...}
        })
        
        -- Trim history if needed
        if #eventHistory > CONFIG.MAX_EVENT_HISTORY then
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire event
    remote:FireClient(client, ...)
    return true
end

-- Send an event from client to server
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
    
    -- Fire event
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
        local args = table.pack(...) -- Capture varargs locally
        task.spawn(function()
            local success, result = pcall(function()
                return callback(player, table.unpack(args, 1, args.n))
            end)
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
    
    -- Initialize the event handlers array if needed
    if not eventHandlers[eventName] then
        eventHandlers[eventName] = {}
    end
    
    -- Add the handler
    table.insert(eventHandlers[eventName], callback)
    
    -- Make sure we have a remote event and are connected
    EventBridge.getRemoteEvent(eventName)
    
    log("Added client handler for event: " .. eventName)
    return true
end

-- Register a server function handler
function EventBridge.onServerInvoke(functionName, callback)
    if not isServer then
        warn("[EventBridge] onServerInvoke can only be called from server")
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
    
    -- Set up the callback
    remote.OnServerInvoke = function(player, ...)
        -- Check security rules
        if not checkRateLimit(player, functionName) then
            log("Rate limit exceeded for " .. functionName .. " by " .. player.Name)
            return nil, "Rate limit exceeded"
        end
        
        if not validateEventData(player, functionName, ...) then
            log("Validation failed for " .. functionName .. " by " .. player.Name)
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
    
    log("Registered server function handler: " .. functionName)
    return true
end

-- Register a client function handler
function EventBridge.onClientInvoke(functionName, callback)
    if isServer then
        warn("[EventBridge] onClientInvoke can only be called from client")
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
    
    -- Set up the callback
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
    
    log("Registered client function handler: " .. functionName)
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
    local args = table.pack(...) -- Capture varargs locally
    local success, result = pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
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
    local args = table.pack(...) -- Capture varargs locally
    local success, result = pcall(function()
        return remote:InvokeClient(client, table.unpack(args, 1, args.n))
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
    
    securityRules[name] = rule
    log("Set security rule for: " .. name)
    return true
end

-- Get event history
function EventBridge.getEventHistory()
    return eventHistory
end

-- Example security rules
if isServer then
    -- Chat filter rule example
    EventBridge.setSecurityRule("sendChatMessage", {
        type = "validate",
        validate = function(player, message)
            -- Basic length check
            return type(message) == "string" and #message < 200
        end
    })
    
    -- Inventory rule example
    EventBridge.setSecurityRule("purchaseItem", {
        type = "validate",
        validate = function(player, itemId)
            -- Would check if player has enough currency and item exists
            return type(itemId) == "string" or type(itemId) == "number"
        end
    })
    
    -- Admin-only rule example
    EventBridge.setSecurityRule("adminCommand", {
        type = "whitelist",
        playerIds = {
            [1234567890] = true, -- Example admin
            [2345678901] = true  -- Another admin
        }
    })
end

-- Setup connection with CoreRegistry if available
local function setupCoreRegistry()
    local CR = getCoreRegistry()
    if CR and typeof(CR.RegisterPublicModule) == "function" then
        CR.RegisterPublicModule("EventBridge", EventBridge)
        log("Registered with CoreRegistry")
    end
end

-- Try to register with CoreRegistry
task.spawn(setupCoreRegistry)

-- Initialize on load
EventBridge.initialize()

return EventBridge
