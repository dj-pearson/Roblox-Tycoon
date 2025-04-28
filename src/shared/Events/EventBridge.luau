--!strict
--[[
    EventBridge.luau
    
    A unified cross-context event communication system that bridges events between
    client and server. The EventBridge optimizes network usage while maintaining
    event semantics across contexts.
    
    Features:
    - Bidirectional event synchronization
    - Automatic event filtering for security
    - Bandwidth optimization with batching
    - Remote event transformation
    - Automatic client-server connection management
    
    Author: Created April 28, 2025
]]

-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Determine execution context
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Import dependencies
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local EventsModules = SharedModules:WaitForChild("Events")

local EventTypes = require(EventsModules:WaitForChild("EventTypes"))

-- Import context-specific event systems
local ServerEvents, ClientEvents

if isServer then
    local ServerScriptService = game:GetService("ServerScriptService")
    local ServerModules = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Events")
    ServerEvents = require(ServerModules:WaitForChild("ServerEvents")).get()
end

if isClient then
    local ClientModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core"):WaitForChild("Events")
    ClientEvents = require(ClientModules:WaitForChild("ClientEvents")).get()
end

-- Type imports
type Event = EventTypes.Event
type EventData = EventTypes.EventData
type EventHandler = EventTypes.EventHandler
type EventHandlerInfo = EventTypes.EventHandlerInfo
type EventPriority = EventTypes.EventPriority
type EventCategory = EventTypes.EventCategory
type EventFilter = EventTypes.EventFilter
type EventTransform = EventTypes.EventTransform
type EventResult = EventTypes.EventResult
type EventBusConfig = EventTypes.EventBusConfig
type EventSubscription = EventTypes.EventSubscription

-- EventBridge configuration type
type EventBridgeConfig = {
    debug: boolean?,                  -- Enable debug logging
    batchEvents: boolean?,            -- Batch events to reduce network calls
    batchInterval: number?,           -- Time between batches (seconds)
    allowedClientEvents: {string}?,   -- Event types clients can emit to server
    allowedServerEvents: {string}?,   -- Event types server can emit to clients
    eventFilters: {EventFilter}?,     -- Additional filters for events
    maxBatchSize: number?,            -- Maximum events in a batch
    compressionThreshold: number?,    -- Size threshold for compression (bytes)
    playerSpecificEvents: boolean?,   -- Whether to support player-specific events
}

-- Module implementation
local EventBridge = {}
EventBridge.__index = EventBridge

-- Create a new event bridge
function EventBridge.new(config: EventBridgeConfig?)
    config = config or {}
    
    local self = setmetatable({
        debug = config.debug == true,
        batchEvents = config.batchEvents ~= false,
        batchInterval = config.batchInterval or 0.1, -- 100ms default
        maxBatchSize = config.maxBatchSize or 100,   -- Maximum 100 events per batch
        compressionThreshold = config.compressionThreshold or 1024, -- 1KB default
        playerSpecificEvents = config.playerSpecificEvents ~= false,
        
        -- Event allowlists (default to empty - must be explicitly allowed)
        allowedClientEvents = {},
        allowedServerEvents = {},
        
        -- Remote objects
        remotes = {
            clientToServer = nil,
            serverToClient = nil,
            serverToPlayer = nil
        },
        
        -- Event queues for batching
        eventBatches = {
            clientToServer = {},
            serverToClient = {},
            serverToPlayer = {} -- Player UserId -> event batch
        },
        
        -- Batch timers
        batchTimers = {
            clientToServer = nil,
            serverToClient = nil,
            -- Server-to-player timers are created as needed
        },
        
        -- Subscriptions
        subscriptions = {},
        
        -- Statistics
        stats = {
            eventsSent = 0,
            eventsReceived = 0,
            bytesSent = 0,
            bytesReceived = 0,
            batchesSent = 0,
            batchesReceived = 0
        }
    }, EventBridge)
    
    -- Set up allowlists
    if config.allowedClientEvents then
        for _, eventId in ipairs(config.allowedClientEvents) do
            self.allowedClientEvents[eventId] = true
        end
    end
    
    if config.allowedServerEvents then
        for _, eventId in ipairs(config.allowedServerEvents) do
            self.allowedServerEvents[eventId] = true
        end
    end
    
    -- Set up remote objects
    self:_setupRemotes()
    
    -- Connect to existing events as needed
    self:_connectEvents()
    
    return self
end

-- Get singleton instance
local eventBridgeInstance
function EventBridge.get()
    if not eventBridgeInstance then
        eventBridgeInstance = EventBridge.new()
    end
    return eventBridgeInstance
end

--[[ Private implementation ]]--

-- Log debug message
function EventBridge:_debug(...)
    if self.debug then
        print("[EventBridge]", ...)
    end
end

-- Set up remote objects
function EventBridge:_setupRemotes()
    local folder = ReplicatedStorage:FindFirstChild("EventBridgeRemotes")
    
    if not folder then
        -- Only create the folder on the server
        if isServer then
            folder = Instance.new("Folder")
            folder.Name = "EventBridgeRemotes"
            
            -- Create the remote objects
            local clientToServer = Instance.new("RemoteEvent")
            clientToServer.Name = "ClientToServer"
            clientToServer.Parent = folder
            
            local serverToClient = Instance.new("RemoteEvent")
            serverToClient.Name = "ServerToClient"
            serverToClient.Parent = folder
            
            local serverToPlayer = Instance.new("RemoteEvent")
            serverToPlayer.Name = "ServerToPlayer"
            serverToPlayer.Parent = folder
            
            folder.Parent = ReplicatedStorage
        else
            -- Client should wait for the folder
            folder = ReplicatedStorage:WaitForChild("EventBridgeRemotes", 10)
            if not folder then
                warn("[EventBridge] Failed to find remote objects")
                return
            end
        end
    end
    
    -- Get the remote objects
    self.remotes.clientToServer = folder:WaitForChild("ClientToServer")
    self.remotes.serverToClient = folder:WaitForChild("ServerToClient")
    self.remotes.serverToPlayer = folder:WaitForChild("ServerToPlayer")
    
    -- Set up event handlers
    if isServer then
        -- Listen for client events
        self.remotes.clientToServer.OnServerEvent:Connect(function(player, eventBatch)
            self:_handleClientBatch(player, eventBatch)
        end)
    end
    
    if isClient then
        -- Listen for server events
        self.remotes.serverToClient.OnClientEvent:Connect(function(eventBatch)
            self:_handleServerBatch(eventBatch)
        end)
        
        -- Listen for player-specific events
        self.remotes.serverToPlayer.OnClientEvent:Connect(function(eventBatch)
            self:_handleServerBatch(eventBatch, true) -- true = player-specific
        end)
    end
end

-- Connect to existing events
function EventBridge:_connectEvents()
    if isServer and ServerEvents then
        -- Subscribe to allowed server events
        local serverEvents = {}
        for eventId in pairs(self.allowedServerEvents) do
            table.insert(serverEvents, eventId)
        end
        
        if #serverEvents > 0 then
            local subscription = ServerEvents:subscribeMultiple(serverEvents, function(event)
                self:_bridgeServerEvent(event)
                return true
            end)
            
            table.insert(self.subscriptions, subscription)
        end
    end
    
    if isClient and ClientEvents then
        -- Subscribe to allowed client events
        local clientEvents = {}
        for eventId in pairs(self.allowedClientEvents) do
            table.insert(clientEvents, eventId)
        end
        
        if #clientEvents > 0 then
            local subscription = ClientEvents:subscribeMultiple(clientEvents, function(event)
                self:_bridgeClientEvent(event)
                return true
            end)
            
            table.insert(self.subscriptions, subscription)
        end
    end
end

-- Bridge a server event to clients
function EventBridge:_bridgeServerEvent(event: Event)
    -- Check if this event should be shared
    if not self.allowedServerEvents[event.id] then
        return
    end
    
    -- Prepare the event for transmission
    local transmitEvent = {
        id = event.id,
        category = event.category,
        data = event.data, -- Deep copy might be needed in some cases
        timestamp = event.timestamp
    }
    
    -- Check if this is a player-specific event
    if self.playerSpecificEvents and event.data and event.data.player and typeof(event.data.player) == "Instance" then
        local player = event.data.player
        
        -- Don't include the full player instance in the data
        transmitEvent.data = table.clone(event.data)
        transmitEvent.data.player = nil
        transmitEvent.data.playerId = player.UserId
        
        -- Add to player-specific batch
        if self.batchEvents then
            if not self.eventBatches.serverToPlayer[player.UserId] then
                self.eventBatches.serverToPlayer[player.UserId] = {}
            end
            
            table.insert(self.eventBatches.serverToPlayer[player.UserId], transmitEvent)
            
            -- Schedule a batch send if we haven't already
            if not self.batchTimers[player.UserId] then
                self.batchTimers[player.UserId] = true
                task.delay(self.batchInterval, function()
                    self:_sendPlayerBatch(player)
                end)
            end
        else
            -- Send immediately
            self.remotes.serverToPlayer:FireClient(player, {transmitEvent})
            self.stats.eventsSent += 1
            self.stats.batchesSent += 1
        end
    else
        -- Broadcast event to all clients
        if self.batchEvents then
            table.insert(self.eventBatches.serverToClient, transmitEvent)
            
            -- Schedule a batch send if we haven't already
            if not self.batchTimers.serverToClient then
                self.batchTimers.serverToClient = true
                task.delay(self.batchInterval, function()
                    self:_sendServerBatch()
                end)
            end
        else
            -- Send immediately
            self.remotes.serverToClient:FireAllClients({transmitEvent})
            self.stats.eventsSent += 1
            self.stats.batchesSent += 1
        end
    end
end

-- Bridge a client event to the server
function EventBridge:_bridgeClientEvent(event: Event)
    -- Check if this event should be shared
    if not self.allowedClientEvents[event.id] then
        return
    end
    
    -- Prepare the event for transmission
    local transmitEvent = {
        id = event.id,
        category = event.category,
        data = event.data, -- Deep copy might be needed in some cases
        timestamp = event.timestamp
    }
    
    -- Add to batch
    if self.batchEvents then
        table.insert(self.eventBatches.clientToServer, transmitEvent)
        
        -- Schedule a batch send if we haven't already
        if not self.batchTimers.clientToServer then
            self.batchTimers.clientToServer = true
            task.delay(self.batchInterval, function()
                self:_sendClientBatch()
            end)
        end
    else
        -- Send immediately
        self.remotes.clientToServer:FireServer({transmitEvent})
        self.stats.eventsSent += 1
        self.stats.batchesSent += 1
    end
end

-- Send a client event batch to the server
function EventBridge:_sendClientBatch()
    -- Reset the timer
    self.batchTimers.clientToServer = nil
    
    -- Check if we have any events to send
    if #self.eventBatches.clientToServer == 0 then
        return
    end
    
    -- Get the batch
    local batch = self.eventBatches.clientToServer
    self.eventBatches.clientToServer = {}
    
    -- Send the batch
    self.remotes.clientToServer:FireServer(batch)
    
    -- Update stats
    self.stats.eventsSent += #batch
    self.stats.batchesSent += 1
    
    self:_debug("Sent client batch with", #batch, "events")
end

-- Send a server event batch to all clients
function EventBridge:_sendServerBatch()
    -- Reset the timer
    self.batchTimers.serverToClient = nil
    
    -- Check if we have any events to send
    if #self.eventBatches.serverToClient == 0 then
        return
    end
    
    -- Get the batch
    local batch = self.eventBatches.serverToClient
    self.eventBatches.serverToClient = {}
    
    -- Send the batch
    self.remotes.serverToClient:FireAllClients(batch)
    
    -- Update stats
    self.stats.eventsSent += #batch
    self.stats.batchesSent += 1
    
    self:_debug("Sent server batch with", #batch, "events to all clients")
end

-- Send a player-specific event batch
function EventBridge:_sendPlayerBatch(player: Player)
    -- Reset the timer
    self.batchTimers[player.UserId] = nil
    
    -- Check if we have any events to send
    if not self.eventBatches.serverToPlayer[player.UserId] or 
       #self.eventBatches.serverToPlayer[player.UserId] == 0 then
        return
    end
    
    -- Get the batch
    local batch = self.eventBatches.serverToPlayer[player.UserId]
    self.eventBatches.serverToPlayer[player.UserId] = {}
    
    -- Send the batch
    self.remotes.serverToPlayer:FireClient(player, batch)
    
    -- Update stats
    self.stats.eventsSent += #batch
    self.stats.batchesSent += 1
    
    self:_debug("Sent player batch with", #batch, "events to", player.Name)
end

-- Handle a batch from client to server
function EventBridge:_handleClientBatch(player: Player, eventBatch: {any})
    -- Update stats
    self.stats.eventsReceived += #eventBatch
    self.stats.batchesReceived += 1
    
    -- Process each event
    for _, transmitEvent in ipairs(eventBatch) do
        -- Validate the event
        if not transmitEvent.id or not transmitEvent.category then
            self:_debug("Received invalid event:", transmitEvent)
            continue
        end
        
        -- Check if this event is allowed from clients
        if not self.allowedClientEvents[transmitEvent.id] then
            self:_debug("Received disallowed event from client:", transmitEvent.id)
            continue
        end
        
        -- Add player info
        local eventData = transmitEvent.data or {}
        eventData.player = player
        eventData.playerId = player.UserId
        
        -- Emit the event on the server
        ServerEvents:emit(transmitEvent.id, eventData, {
            category = transmitEvent.category,
            source = "EventBridge"
        })
        
        self:_debug("Bridged client event:", transmitEvent.id, "from player", player.Name)
    end
end

-- Handle a batch from server to client
function EventBridge:_handleServerBatch(eventBatch: {any}, isPlayerSpecific: boolean?)
    -- Update stats
    self.stats.eventsReceived += #eventBatch
    self.stats.batchesReceived += 1
    
    local localPlayer = Players.LocalPlayer
    
    -- Process each event
    for _, transmitEvent in ipairs(eventBatch) do
        -- Validate the event
        if not transmitEvent.id or not transmitEvent.category then
            self:_debug("Received invalid event:", transmitEvent)
            continue
        end
        
        -- Check if this event is allowed from server
        if not self.allowedServerEvents[transmitEvent.id] then
            self:_debug("Received disallowed event from server:", transmitEvent.id)
            continue
        end
        
        -- Reconstruct player references if needed
        local eventData = transmitEvent.data or {}
        if eventData.playerId then
            -- Try to find the player
            local player = Players:GetPlayerByUserId(eventData.playerId)
            if player then
                eventData.player = player
            end
        end
        
        -- Add local player reference for player-specific events
        if isPlayerSpecific then
            eventData.player = localPlayer
            eventData.isLocalPlayerEvent = true
        end
        
        -- Emit the event on the client
        ClientEvents:emit(transmitEvent.id, eventData, {
            category = transmitEvent.category,
            source = "EventBridge"
        })
        
        self:_debug("Bridged server event:", transmitEvent.id)
    end
end

--[[ Public API ]]--

-- Allow a client event to be sent to server
function EventBridge:allowClientEvent(eventId: string)
    self.allowedClientEvents[eventId] = true
    self:_debug("Allowing client event:", eventId)
    
    -- If we're on the client, we need to connect to this event
    if isClient and ClientEvents then
        local subscription = ClientEvents:subscribe(eventId, function(event)
            self:_bridgeClientEvent(event)
            return true
        end)
        
        table.insert(self.subscriptions, subscription)
    end
end

-- Allow multiple client events
function EventBridge:allowClientEvents(eventIds: {string})
    for _, eventId in ipairs(eventIds) do
        self:allowClientEvent(eventId)
    end
end

-- Allow a server event to be sent to clients
function EventBridge:allowServerEvent(eventId: string)
    self.allowedServerEvents[eventId] = true
    self:_debug("Allowing server event:", eventId)
    
    -- If we're on the server, we need to connect to this event
    if isServer and ServerEvents then
        local subscription = ServerEvents:subscribe(eventId, function(event)
            self:_bridgeServerEvent(event)
            return true
        end)
        
        table.insert(self.subscriptions, subscription)
    end
end

-- Allow multiple server events
function EventBridge:allowServerEvents(eventIds: {string})
    for _, eventId in ipairs(eventIds) do
        self:allowServerEvent(eventId)
    end
end

-- Disallow a client event
function EventBridge:disallowClientEvent(eventId: string)
    self.allowedClientEvents[eventId] = nil
    self:_debug("Disallowing client event:", eventId)
end

-- Disallow a server event
function EventBridge:disallowServerEvent(eventId: string)
    self.allowedServerEvents[eventId] = nil
    self:_debug("Disallowing server event:", eventId)
end

-- Set batch configuration
function EventBridge:configureBatching(enabled: boolean, interval: number?)
    self.batchEvents = enabled
    if interval then
        self.batchInterval = interval
    end
end

-- Get event bridge statistics
function EventBridge:getStats()
    return table.clone(self.stats)
end

-- Return the module
return EventBridge
