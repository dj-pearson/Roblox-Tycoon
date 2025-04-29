--!strict
--[[
    EventTypes.luau
    
    Type definitions and constants for the Event System. This module defines
    the foundational types used throughout the Event System, providing strong
    typing and consistent interfaces.
    
    Features:
    - Type definitions for events and handlers
    - Event priority constants
    - Event category definitions
    - Utility types for event system internals
    
    Author: Created April 28, 2025
]]

-- Event priority constants
export type EventPriority = number

-- Event priorities
local EventPriorities = {
    MONITOR = -100,     -- Monitor events only, should not modify
    LOWEST = 0,         -- Lowest priority, runs last
    LOW = 25,           -- Low priority
    NORMAL = 50,        -- Normal priority (default)
    HIGH = 75,          -- High priority
    HIGHEST = 100,      -- Highest priority, runs first
    CRITICAL = 1000     -- Critical priority, reserved for system use
}

-- Event category constants
export type EventCategory = string

-- Event categories
local EventCategories = {
    SYSTEM = "system",      -- System events (internal)
    GAMEPLAY = "gameplay",  -- Gameplay events
    UI = "ui",              -- UI events
    PLAYER = "player",      -- Player events
    NETWORK = "network",    -- Network events
    DATA = "data",          -- Data events
    DEBUG = "debug"         -- Debug events
}

-- Event data must be serializable for network events
export type EventData = {[string]: any}

-- Base event type
export type Event = {
    id: string,             -- Unique event identifier
    priority: EventPriority, -- Event priority
    category: EventCategory, -- Event category
    data: EventData,        -- Event data
    source: string?,        -- Source of the event
    cancelable: boolean,    -- Whether the event can be cancelled
    canceled: boolean,      -- Whether the event is cancelled
    timestamp: number,      -- When the event was created
    propagating: boolean,   -- Whether the event is still propagating
}

-- Event handler function type
export type EventHandler = (event: Event) -> boolean?

-- Event handler info
export type EventHandlerInfo = {
    id: string,                    -- Unique handler ID
    handler: EventHandler,         -- Handler function
    priority: EventPriority,       -- Handler priority
    categories: {[EventCategory]: boolean}?, -- Categories this handler responds to
    eventTypes: {[string]: boolean}?,        -- Event types this handler responds to
    once: boolean,                 -- Whether this handler should only fire once
    fired: boolean,                -- Whether this handler has fired (for 'once' handlers)
    source: string?,               -- Source module/system creating the handler
}

-- Event filter for checking if an event should be processed
export type EventFilter = (event: Event) -> boolean

-- Event transform for modifying events
export type EventTransform = (event: Event) -> Event

-- Event result returned after processing
export type EventResult = {
    completed: boolean,     -- Whether all handlers completed
    canceled: boolean,      -- Whether the event was canceled
    handlerCount: number,   -- Number of handlers that processed the event
    stoppedBy: string?,     -- ID of the handler that stopped propagation
    canceledBy: string?,    -- ID of the handler that canceled the event
    error: string?          -- Error message if processing failed
}

-- Event bus configuration
export type EventBusConfig = {
    name: string?,          -- Name of the event bus
    debug: boolean?,        -- Whether to enable debug logging
    strict: boolean?,       -- Whether to use strict mode (more validation)
    maxQueueSize: number?,  -- Maximum number of events in the queue
    allowCancelation: boolean?, -- Whether events can be canceled
    errorHandler: (error: string, event: Event?) -> ()?,  -- Custom error handler
    defaultPriority: EventPriority?, -- Default priority for events and handlers
    filters: {EventFilter}?, -- Global filters for all events
    transforms: {EventTransform}? -- Global transforms for all events
}

-- Event subscription info
export type EventSubscription = {
    id: string,          -- Subscription ID (same as handler ID)
    unsubscribe: () -> (), -- Function to unsubscribe
    isPaused: () -> boolean, -- Check if subscription is paused
    pause: () -> (),     -- Pause the subscription
    resume: () -> (),    -- Resume the subscription
}

-- Create a new event
local function createEvent(
    id: string, 
    data: EventData, 
    category: EventCategory?,
    priority: EventPriority?,
    cancelable: boolean?
): Event
    return {
        id = id,
        data = data or {},
        priority = priority or EventPriorities.NORMAL,
        category = category or EventCategories.GAMEPLAY,
        cancelable = cancelable ~= false,
        canceled = false,
        timestamp = os.time(),
        propagating = true,
        source = nil
    }
end

-- Create a new handler info
local function createHandlerInfo(
    id: string,
    handler: EventHandler,
    priority: EventPriority?,
    eventTypes: {string}?,
    categories: {EventCategory}?,
    once: boolean?
): EventHandlerInfo
    local eventTypeMap: {[string]: boolean}? = nil
    if eventTypes then
        eventTypeMap = {}
        for _, eventType in ipairs(eventTypes) do
            eventTypeMap[eventType] = true
        end
    end
    
    local categoryMap: {[EventCategory]: boolean}? = nil
    if categories then
        categoryMap = {}
        for _, category in ipairs(categories) do
            categoryMap[category] = true
        end
    end
    
    return {
        id = id,
        handler = handler,
        priority = priority or EventPriorities.NORMAL,
        eventTypes = eventTypeMap,
        categories = categoryMap,
        once = once == true,
        fired = false,
        source = nil
    }
end

return {
    -- Constants
    Priorities = EventPriorities,
    Categories = EventCategories,
    
    -- Factory functions
    createEvent = createEvent,
    createHandlerInfo = createHandlerInfo,
    
    -- For type checking
    EventPriorities = EventPriorities,
    EventCategories = EventCategories
}
