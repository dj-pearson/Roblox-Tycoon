--[[
    EventBridge.luau
    This module provides a centralized event system for the game.
    It handles event registration, firing, and cross-boundary communication.
    
    Created to fix "Event System Issues" reported in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Determine if we're on server or client
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe require helper
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("EventBridge: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

-- Create the module
local EventBridge = {}

-- Version information
EventBridge.VERSION = "1.0.0"
EventBridge.isLoaded = true

-- Internal state
local registeredEvents = {}
local eventConnections = {}
local remoteEvents = {}
local eventHistory = {}
local debugMode = false
local maxHistoryLength = 100

-- Event Namespace constants
EventBridge.SCOPE = {
    LOCAL = "LOCAL",    -- Events that stay within the current context (server or client)
    REMOTE = "REMOTE",  -- Events that are replicated between server and client
    BOTH = "BOTH"       -- Events that work both locally and remotely
}

-- Initialize the EventBridge
function EventBridge.initialize()
    print("EventBridge: Initializing...")
    
    -- Set up default event folder in ReplicatedStorage
    local eventFolder = ReplicatedStorage:FindFirstChild("EventBridge")
    if not eventFolder then
        eventFolder = Instance.new("Folder")
        eventFolder.Name = "EventBridge"
        eventFolder.Parent = ReplicatedStorage
    end
    
    -- Create server-to-client RemoteEvent if on server
    if isServer then
        local serverToClient = eventFolder:FindFirstChild("ServerToClient")
        if not serverToClient then
            serverToClient = Instance.new("RemoteEvent")
            serverToClient.Name = "ServerToClient"
            serverToClient.Parent = eventFolder
        end
        
        remoteEvents.ServerToClient = serverToClient
    end
    
    -- Create client-to-server RemoteEvent if on client
    if isClient then
        local clientToServer = eventFolder:FindFirstChild("ClientToServer")
        if not clientToServer then
            clientToServer = Instance.new("RemoteEvent")
            clientToServer.Name = "ClientToServer"
            clientToServer.Parent = eventFolder
        end
        
        remoteEvents.ClientToServer = clientToServer
        
        -- Connect to server events
        local serverToClient = eventFolder:FindFirstChild("ServerToClient")
        if serverToClient then
            remoteEvents.ServerToClient = serverToClient
            
            serverToClient.OnClientEvent:Connect(function(eventName, data)
                -- Handle remote event from server
                EventBridge.handleRemoteEvent(eventName, data)
            end)
        end
    end
    
    -- Connect to client events if on server
    if isServer then
        local clientToServer = eventFolder:FindFirstChild("ClientToServer")
        if clientToServer then
            remoteEvents.ClientToServer = clientToServer
            
            clientToServer.OnServerEvent:Connect(function(player, eventName, data)
                -- Handle remote event from client, including player info
                if typeof(data) == "table" then
                    data.player = player
                else
                    data = { player = player, data = data }
                end
                
                EventBridge.handleRemoteEvent(eventName, data)
            end)
        end
    end
    
    print("EventBridge: Initialized successfully")
    return true
end

-- Enable or disable debug mode
function EventBridge.setDebugMode(enabled)
    debugMode = enabled == true
    
    if debugMode then
        print("EventBridge: Debug mode enabled")
    else
        print("EventBridge: Debug mode disabled")
    end
    
    return debugMode
end

-- Set the maximum history length
function EventBridge.setMaxHistoryLength(length)
    if typeof(length) == "number" and length >= 0 then
        maxHistoryLength = length
        
        -- Trim history if needed
        while #eventHistory > maxHistoryLength do
            table.remove(eventHistory, 1)
        end
        
        return true
    end
    
    return false
end

-- Register an event
function EventBridge.registerEvent(eventName, options)
    if not eventName or typeof(eventName) ~= "string" then
        warn("EventBridge: Invalid event name")
        return false
    end
    
    options = options or {}
    local scope = options.scope or EventBridge.SCOPE.LOCAL
    
    -- Check if already registered
    if registeredEvents[eventName] then
        if debugMode then
            warn("EventBridge: Event already registered - " .. eventName)
        end
        return false
    end
    
    -- Register the event
    registeredEvents[eventName] = {
        name = eventName,
        scope = scope,
        connections = {}
    }
    
    if debugMode then
        print("EventBridge: Registered event - " .. eventName .. " with scope " .. scope)
    end
    
    return true
end

-- Check if an event is registered
function EventBridge.isEventRegistered(eventName)
    return registeredEvents[eventName] ~= nil
end

-- Fire an event
function EventBridge.fireEvent(eventName, data)
    -- Make sure the event is registered
    local eventInfo = registeredEvents[eventName]
    if not eventInfo then
        if debugMode then
            warn("EventBridge: Attempted to fire unregistered event - " .. eventName)
        end
        return false
    end
    
    -- Add to history if enabled
    if maxHistoryLength > 0 then
        table.insert(eventHistory, {
            timestamp = os.time(),
            name = eventName,
            data = data,
            source = isServer and "Server" or "Client"
        })
        
        -- Trim history if needed
        while #eventHistory > maxHistoryLength do
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire the event locally
    local connections = eventInfo.connections
    if connections then
        for _, connection in ipairs(connections) do
            task.spawn(function()
                local success, err = pcall(function()
                    connection(data)
                end)
                
                if not success and debugMode then
                    warn("EventBridge: Error in event handler for " .. eventName .. " - " .. tostring(err))
                end
            end)
        end
    end
    
    -- Fire remotely if needed
    if (eventInfo.scope == EventBridge.SCOPE.REMOTE or eventInfo.scope == EventBridge.SCOPE.BOTH) then
        if isServer and remoteEvents.ServerToClient then
            -- Server to all clients
            remoteEvents.ServerToClient:FireAllClients(eventName, data)
        elseif isClient and remoteEvents.ClientToServer then
            -- Client to server
            remoteEvents.ClientToServer:FireServer(eventName, data)
        end
    end
    
    if debugMode then
        print("EventBridge: Fired event - " .. eventName .. " with data: " .. tostring(data))
    end
    
    return true
end

-- Fire an event to a specific player (server only)
function EventBridge.firePlayerEvent(player, eventName, data)
    -- Only works on server
    if not isServer then
        if debugMode then
            warn("EventBridge: Attempted to fire player event from client - " .. eventName)
        end
        return false
    end
    
    -- Make sure the event is registered
    local eventInfo = registeredEvents[eventName]
    if not eventInfo then
        if debugMode then
            warn("EventBridge: Attempted to fire unregistered player event - " .. eventName)
        end
        return false
    end
    
    -- Fire the event to the player
    if remoteEvents.ServerToClient and player and player:IsA("Player") then
        remoteEvents.ServerToClient:FireClient(player, eventName, data)
        
        if debugMode then
            print("EventBridge: Fired player event - " .. eventName .. " to " .. player.Name)
        end
        
        return true
    end
    
    return false
end

-- Connect to an event
function EventBridge.connect(eventName, callback)
    if not eventName or typeof(callback) ~= "function" then
        warn("EventBridge: Invalid parameters for connect")
        return nil
    end
    
    -- Make sure the event is registered
    local eventInfo = registeredEvents[eventName]
    if not eventInfo then
        if debugMode then
            warn("EventBridge: Attempted to connect to unregistered event - " .. eventName)
        end
        return nil
    end
    
    -- Add the connection
    table.insert(eventInfo.connections, callback)
    
    -- Create a connection object
    local connectionObject = {
        disconnect = function()
            -- Find and remove the callback
            for i, conn in ipairs(eventInfo.connections) do
                if conn == callback then
                    table.remove(eventInfo.connections, i)
                    break
                end
            end
        end
    }
    
    return connectionObject
end

-- Handle remote events
function EventBridge.handleRemoteEvent(eventName, data)
    -- Make sure the event is registered
    local eventInfo = registeredEvents[eventName]
    if not eventInfo then
        if debugMode then
            warn("EventBridge: Received unregistered remote event - " .. eventName)
        end
        return false
    end
    
    -- Add to history if enabled
    if maxHistoryLength > 0 then
        table.insert(eventHistory, {
            timestamp = os.time(),
            name = eventName,
            data = data,
            source = isServer and "Client" or "Server" -- Source is opposite of receiver
        })
        
        -- Trim history if needed
        while #eventHistory > maxHistoryLength do
            table.remove(eventHistory, 1)
        end
    end
    
    -- Fire the event locally
    local connections = eventInfo.connections
    if connections then
        for _, connection in ipairs(connections) do
            task.spawn(function()
                local success, err = pcall(function()
                    connection(data)
                end)
                
                if not success and debugMode then
                    warn("EventBridge: Error in remote event handler for " .. eventName .. " - " .. tostring(err))
                end
            end)
        end
    end
    
    if debugMode then
        print("EventBridge: Handled remote event - " .. eventName)
    end
    
    return true
end

-- Get event history
function EventBridge.getHistory()
    return table.clone(eventHistory)
end

-- Clear event history
function EventBridge.clearHistory()
    eventHistory = {}
    return true
end

-- Get all registered events
function EventBridge.getRegisteredEvents()
    local events = {}
    
    for name, info in pairs(registeredEvents) do
        table.insert(events, {
            name = name,
            scope = info.scope,
            connections = #info.connections
        })
    end
    
    return events
end

-- Initialize the module
EventBridge.initialize()

-- Register with registry system if available
if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry then
        if typeof(CoreRegistry.Register) == "function" then
            CoreRegistry:Register("EventBridge", EventBridge)
            print("EventBridge: Registered with CoreRegistry using Register")
        elseif typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("EventBridge", EventBridge)
            print("EventBridge: Registered with CoreRegistry using registerSystem")
        end
    else
        -- Try to find CoreRegistry in server scripts
        local ServerScriptService = game:GetService("ServerScriptService")
        local success, registry = pcall(function()
            return require(ServerScriptService:FindFirstChild("Core", true) and 
                           ServerScriptService:FindFirstChild("Core", true):FindFirstChild("CoreRegistry"))
        end)
        
        if success and registry then
            if typeof(registry.Register) == "function" then
                registry:Register("EventBridge", EventBridge)
                print("EventBridge: Registered with CoreRegistry using alternative path")
            elseif typeof(registry.registerSystem) == "function" then
                registry.registerSystem("EventBridge", EventBridge)
                print("EventBridge: Registered with CoreRegistry using alternative path")
            end
        end
    end
else
    local ClientRegistry = safeRequire(findModule("ClientRegistry"))
    if ClientRegistry then
        if typeof(ClientRegistry.Register) == "function" then
            ClientRegistry:Register("EventBridge", EventBridge)
            print("EventBridge: Registered with ClientRegistry using Register")
        elseif typeof(ClientRegistry.registerSystem) == "function" then
            ClientRegistry.registerSystem("EventBridge", EventBridge)
            print("EventBridge: Registered with ClientRegistry using registerSystem")
        end
    else
        -- Try to find ClientRegistry in player scripts
        local Players = game:GetService("Players")
        if isClient and Players.LocalPlayer then
            local playerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
            if playerScripts then
                local success, registry = pcall(function()
                    return require(playerScripts:FindFirstChild("ClientRegistry"))
                end)
                
                if success and registry then
                    if typeof(registry.Register) == "function" then
                        registry:Register("EventBridge", EventBridge)
                        print("EventBridge: Registered with ClientRegistry using alternative path")
                    elseif typeof(registry.registerSystem) == "function" then
                        registry.registerSystem("EventBridge", EventBridge)
                        print("EventBridge: Registered with ClientRegistry using alternative path")
                    end
                end
            end
        end
    end
end

return EventBridge
