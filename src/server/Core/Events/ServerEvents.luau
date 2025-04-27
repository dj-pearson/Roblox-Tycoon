--!strict
--[[
    ServerEvents.luau
    
    Server-specific implementation of the Event System. Extends EventBase with
    functionality specific to the server context, including player-specific events,
    system coordination, and persistence capabilities.
    
    Features:
    - Player-specific event management
    - System event coordination
    - Event persistence and logging
    - Performance optimizations for server context
    - Security filtering
    
    Author: Created April 28, 2025
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Import dependencies
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local EventsModules = SharedModules:WaitForChild("Events")

local EventBase = require(EventsModules:WaitForChild("EventBase"))
local EventTypes = require(EventsModules:WaitForChild("EventTypes"))

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

-- Server-specific event categories
local ServerEventCategories = {
    SYSTEM = "system",           -- System events 
    PLAYER = "player",           -- Player events
    GAME = "game",               -- Game state events
    DATA = "data",               -- Data events
    ECONOMY = "economy",         -- Economy events
    ADMIN = "admin",             -- Admin events
    ANALYTICS = "analytics",     -- Analytics events
    SECURITY = "security"        -- Security events
}

-- Module implementation
local ServerEvents = setmetatable({}, {__index = EventBase})
ServerEvents.__index = ServerEvents

-- Constructor
function ServerEvents.new(config: EventBusConfig?)
    -- Prepare configuration with server defaults
    config = config or {}
    if not config.name then
        config.name = "ServerEvents"
    end
    
    -- Create new event bus with EventBase constructor
    local self = setmetatable(EventBase.new(config), ServerEvents)
    
    -- Add server-specific properties
    self.playerEvents = {}       -- Player-specific event handlers
    self.persistentEvents = {}   -- Events that are persisted
    self.eventLog = {}           -- Log of critical events
    self.maxEventLogSize = config.maxEventLogSize or 1000
    self.persistEventTypes = config.persistEventTypes or {}
    
    -- Set up player management
    self:_setupPlayerManagement()
    
    -- Add server-specific filters (security, etc.)
    table.insert(self.filters, function(event: Event)
        -- Security filter: Check for protected events
        if event.category == ServerEventCategories.ADMIN then
            -- Check if the source is authorized 
            -- (would integrate with an admin system in a real implementation)
            if event.data.player and not self:_isPlayerAuthorized(event.data.player, "admin") then
                warn("[ServerEvents] Unauthorized admin event from " .. tostring(event.data.player))
                return false
            end
        end
        
        -- Let the event through
        return true
    end)
    
    return self
end

-- Get the singleton instance
local serverEventsInstance
function ServerEvents.get()
    if not serverEventsInstance then
        serverEventsInstance = ServerEvents.new()
    end
    return serverEventsInstance
end

--[[ Private Server-specific implementations ]]--

-- Set up player management
function ServerEvents:_setupPlayerManagement()
    -- Initialize player events for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:_initializePlayerEvents(player)
    end
    
    -- Connect to PlayerAdded
    Players.PlayerAdded:Connect(function(player)
        self:_initializePlayerEvents(player)
        
        -- Fire player joined event
        self:emit("player.joined", {
            player = player,
            userId = player.UserId,
            displayName = player.DisplayName,
            name = player.Name,
            joinTime = os.time()
        }, {
            category = ServerEventCategories.PLAYER,
            source = "PlayerService"
        })
    end)
    
    -- Connect to PlayerRemoving
    Players.PlayerRemoving:Connect(function(player)
        -- Fire player leaving event
        self:emit("player.leaving", {
            player = player,
            userId = player.UserId,
            displayName = player.DisplayName,
            name = player.Name,
            leaveTime = os.time()
        }, {
            category = ServerEventCategories.PLAYER,
            source = "PlayerService"
        })
        
        -- Clean up player events
        self:_cleanupPlayerEvents(player)
    end)
end

-- Initialize events for a specific player
function ServerEvents:_initializePlayerEvents(player: Player)
    -- Create player event container if needed
    if not self.playerEvents[player.UserId] then
        self.playerEvents[player.UserId] = {
            subscriptions = {},
            lastActivityTime = os.time()
        }
    end
    
    -- Set up character events
    player.CharacterAdded:Connect(function(character)
        self:emit("player.characterSpawned", {
            player = player,
            character = character,
            spawnTime = os.time()
        }, {
            category = ServerEventCategories.PLAYER,
            source = "CharacterService"
        })
        
        -- Set up humanoid events
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            -- Connect to humanoid events
            humanoid.Died:Connect(function()
                self:emit("player.died", {
                    player = player,
                    character = character,
                    deathTime = os.time()
                }, {
                    category = ServerEventCategories.PLAYER,
                    source = "CharacterService"
                })
            end)
        end
    end)
}

-- Clean up events for a specific player
function ServerEvents:_cleanupPlayerEvents(player: Player)
    -- Check if we have events for this player
    if not self.playerEvents[player.UserId] then
        return
    end
    
    -- Unsubscribe from all player-specific events
    for _, subscription in pairs(self.playerEvents[player.UserId].subscriptions) do
        if type(subscription.unsubscribe) == "function" then
            subscription:unsubscribe()
        end
    end
    
    -- Remove the player events entry
    self.playerEvents[player.UserId] = nil
}

-- Check if a player is authorized for an action
function ServerEvents:_isPlayerAuthorized(player: Player, permission: string): boolean
    -- This would integrate with your admin/permissions system
    -- For simplicity, we'll just check if the player is the owner
    if player.UserId == game.CreatorId then
        return true
    end
    
    -- Check for admin attribute on the player
    if player:GetAttribute("IsAdmin") == true then
        return true
    end
    
    -- Could check a permissions table, group membership, etc.
    return false
end

-- Log an event
function ServerEvents:_logEvent(event: Event)
    -- Add to event log
    table.insert(self.eventLog, {
        id = event.id,
        category = event.category,
        timestamp = event.timestamp,
        data = event.data,
        source = event.source
    })
    
    -- Trim log if too large
    while #self.eventLog > self.maxEventLogSize do
        table.remove(self.eventLog, 1)
    end
}

--[[ Public Server-specific API ]]--

-- Subscribe to player-specific events
function ServerEvents:subscribeToPlayer(
    player: Player,
    eventId: string,
    handler: EventHandler,
    options: {
        priority: EventPriority?,
        once: boolean?,
        id: string?
    }?
): EventSubscription
    options = options or {}
    
    -- Create a wrapper handler that filters for the specific player
    local wrappedHandler = function(event: Event)
        if event.data and event.data.player == player then
            return handler(event)
        end
        return true
    end
    
    -- Subscribe with the wrapped handler
    local subscription = self:subscribe(eventId, wrappedHandler, options)
    
    -- Store the subscription in player events
    if not self.playerEvents[player.UserId] then
        self.playerEvents[player.UserId] = {
            subscriptions = {},
            lastActivityTime = os.time()
        }
    end
    
    self.playerEvents[player.UserId].subscriptions[subscription.id] = subscription
    
    return subscription
end

-- Fire a player-specific event
function ServerEvents:firePlayerEvent(
    player: Player,
    eventId: string,
    data: EventData?
): EventResult
    local eventData = data or {}
    eventData.player = player
    
    return self:emit(eventId, eventData, {
        category = ServerEventCategories.PLAYER,
        source = "PlayerEvent"
    })
end

-- Fire a game event
function ServerEvents:fireGameEvent(
    eventId: string,
    data: EventData?
): EventResult
    return self:emit(eventId, data or {}, {
        category = ServerEventCategories.GAME,
        source = "GameEvent"
    })
end

-- Fire a system event
function ServerEvents:fireSystemEvent(
    eventId: string,
    data: EventData?
): EventResult
    return self:emit(eventId, data or {}, {
        category = ServerEventCategories.SYSTEM,
        source = "SystemEvent"
    })
end

-- Fire a persistent event (logged and optionally saved)
function ServerEvents:firePersistentEvent(
    eventId: string,
    data: EventData?,
    options: {
        category: EventCategory?,
        save: boolean?
    }?
): EventResult
    options = options or {}
    
    -- Create event data
    local eventData = data or {}
    
    -- Add timestamp if not present
    if not eventData.timestamp then
        eventData.timestamp = os.time()
    end
    
    -- Emit the event
    local result = self:emit(eventId, eventData, {
        category = options.category or ServerEventCategories.SYSTEM,
        source = "PersistentEvent"
    })
    
    -- Log the event
    self:_logEvent({
        id = eventId,
        category = options.category or ServerEventCategories.SYSTEM,
        timestamp = eventData.timestamp,
        data = eventData,
        source = "PersistentEvent",
        cancelable = true,
        canceled = result.canceled,
        propagating = false
    })
    
    -- If save is explicitly true or this event type is in persistEventTypes, save it
    local shouldSave = options.save == true or self.persistEventTypes[eventId] == true
    
    if shouldSave then
        -- In a real implementation, this would save to a data store
        -- For this example, we'll just add it to our persistentEvents array
        table.insert(self.persistentEvents, {
            id = eventId,
            category = options.category or ServerEventCategories.SYSTEM,
            timestamp = eventData.timestamp,
            data = eventData,
            source = "PersistentEvent"
        })
    end
    
    return result
end

-- Get event logs (filtered by criteria if provided)
function ServerEvents:getEventLogs(
    options: {
        startTime: number?,
        endTime: number?,
        categories: {string}?,
        eventIds: {string}?,
        limit: number?
    }?
): {any}
    options = options or {}
    
    local filteredLogs = {}
    local count = 0
    local limit = options.limit or self.maxEventLogSize
    
    for i = #self.eventLog, 1, -1 do
        local logEntry = self.eventLog[i]
        
        -- Apply time filters
        if options.startTime and logEntry.timestamp < options.startTime then
            continue
        end
        
        if options.endTime and logEntry.timestamp > options.endTime then
            continue
        end
        
        -- Apply category filter
        if options.categories then
            local categoryMatch = false
            for _, category in ipairs(options.categories) do
                if logEntry.category == category then
                    categoryMatch = true
                    break
                end
            end
            if not categoryMatch then
                continue
            end
        end
        
        -- Apply event ID filter
        if options.eventIds then
            local eventIdMatch = false
            for _, eventId in ipairs(options.eventIds) do
                if logEntry.id == eventId then
                    eventIdMatch = true
                    break
                end
            end
            if not eventIdMatch then
                continue
            end
        end
        
        -- Add to filtered logs
        table.insert(filteredLogs, logEntry)
        count += 1
        
        -- Check limit
        if count >= limit then
            break
        end
    end
    
    return filteredLogs
end

-- Configure event persistence
function ServerEvents:configurePersistence(
    eventTypes: {[string]: boolean},
    maxLogSize: number?
)
    self.persistEventTypes = eventTypes
    if maxLogSize then
        self.maxEventLogSize = maxLogSize
    end
end

-- Return module (with get function for singleton access)
return ServerEvents
