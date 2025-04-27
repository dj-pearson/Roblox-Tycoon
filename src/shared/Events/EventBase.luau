--!strict
--[[
    EventBase.luau
    
    Core implementation of the Event System with foundational functionality
    for managing events, handlers, and event dispatching. This serves as the
    base for both client and server event systems.
    
    Features:
    - Type-safe event registration and dispatch
    - Priority-based event processing
    - Event filtering and transformation
    - Event cancellation
    - Subscription management
    
    Author: Created April 28, 2025
]]

-- Import dependencies
local EventTypes = require(script.Parent:WaitForChild("EventTypes"))

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

-- Module implementation
local EventBase = {}
EventBase.__index = EventBase

-- Create a new event bus
function EventBase.new(config: EventBusConfig?)
    config = config or {}
    
    local self = setmetatable({
        name = config.name or "EventBus",
        debug = config.debug == true,
        strict = config.strict ~= false,
        maxQueueSize = config.maxQueueSize or 1000,
        allowCancellation = config.allowCancelation ~= false,
        errorHandler = config.errorHandler or function(err, event) warn("[" .. (config.name or "EventBus") .. "] Error: ", err, event and event.id) end,
        defaultPriority = config.defaultPriority or EventTypes.Priorities.NORMAL,
        
        -- Event handlers
        handlers = {} :: {[string]: {EventHandlerInfo}},
        
        -- Global handlers
        globalHandlers = {} :: {EventHandlerInfo},
        
        -- Handler lookup for quick unsubscribing
        handlerLookup = {} :: {[string]: EventHandlerInfo},
        
        -- Event queues
        eventQueue = {} :: {Event},
        processedEvents = {} :: {[string]: number},
        
        -- Filters and transforms
        filters = config.filters or {} :: {EventFilter},
        transforms = config.transforms or {} :: {EventTransform},
        
        -- State
        processing = false,
        paused = false,
        nextHandlerId = 1,
    }, EventBase)
    
    return self
end

--[[ Private Utility Functions ]]--

-- Generate a unique handler ID
function EventBase:_generateHandlerId(): string
    local id = "handler_" .. self.nextHandlerId
    self.nextHandlerId += 1
    return id
end

-- Log a debug message
function EventBase:_debug(...)
    if self.debug then
        print("[" .. self.name .. "]", ...)
    end
end

-- Check if a handler should process an event
function EventBase:_shouldHandleEvent(handler: EventHandlerInfo, event: Event): boolean
    -- Skip handler if it's for specific event types and this event doesn't match
    if handler.eventTypes and not handler.eventTypes[event.id] then
        return false
    end
    
    -- Skip handler if it's for specific categories and this event doesn't match
    if handler.categories and not handler.categories[event.category] then
        return false
    end
    
    -- Skip "once" handlers that have already fired
    if handler.once and handler.fired then
        return false
    end
    
    return true
end

-- Apply all filters to an event
function EventBase:_applyFilters(event: Event): boolean
    for _, filter in ipairs(self.filters) do
        -- Skip event if any filter returns false
        if not filter(event) then
            return false
        end
    end
    
    return true
end

-- Apply all transforms to an event
function EventBase:_applyTransforms(event: Event): Event
    local transformedEvent = event
    
    for _, transform in ipairs(self.transforms) do
        transformedEvent = transform(transformedEvent)
    end
    
    return transformedEvent
end

-- Sort handlers by priority (highest first)
local function sortHandlersByPriority(a: EventHandlerInfo, b: EventHandlerInfo): boolean
    return a.priority > b.priority
end

--[[ Public API ]]--

-- Subscribe to an event
function EventBase:subscribe(
    eventId: string,
    handler: EventHandler,
    options: {
        priority: EventPriority?,
        once: boolean?,
        id: string?,
        source: string?
    }?
): EventSubscription
    options = options or {}
    
    -- Generate or use provided handler ID
    local handlerId = options.id or self:_generateHandlerId()
    
    -- Create handler info
    local handlerInfo = EventTypes.createHandlerInfo(
        handlerId,
        handler,
        options.priority or self.defaultPriority,
        {eventId}, -- This handler only responds to the specified event
        nil,       -- No category filtering
        options.once
    )
    
    -- Set source if provided
    if options.source then
        handlerInfo.source = options.source
    end
    
    -- Initialize handlers table for this event if needed
    if not self.handlers[eventId] then
        self.handlers[eventId] = {}
    end
    
    -- Add handler to event handlers
    table.insert(self.handlers[eventId], handlerInfo)
    
    -- Sort handlers by priority
    table.sort(self.handlers[eventId], sortHandlersByPriority)
    
    -- Store in lookup for quick access
    self.handlerLookup[handlerId] = handlerInfo
    
    self:_debug("Subscribed to event:", eventId, "with handler:", handlerId)
    
    -- Create subscription object
    local subscription: EventSubscription = {
        id = handlerId,
        
        unsubscribe = function()
            self:unsubscribe(handlerId)
        end,
        
        isPaused = function()
            return self.handlerLookup[handlerId] == nil
        end,
        
        pause = function()
            -- Implementation will store the handler temporarily
            self:pauseSubscription(handlerId)
        end,
        
        resume = function()
            -- Implementation will restore the handler
            self:resumeSubscription(handlerId)
        end
    }
    
    return subscription
end

-- Subscribe to multiple events
function EventBase:subscribeMultiple(
    eventIds: {string},
    handler: EventHandler,
    options: {
        priority: EventPriority?,
        once: boolean?,
        id: string?,
        source: string?
    }?
): EventSubscription
    options = options or {}
    
    -- Generate or use provided handler ID
    local handlerId = options.id or self:_generateHandlerId()
    
    -- Create handler info
    local handlerInfo = EventTypes.createHandlerInfo(
        handlerId,
        handler,
        options.priority or self.defaultPriority,
        eventIds,  -- This handler responds to all specified events
        nil,       -- No category filtering
        options.once
    )
    
    -- Set source if provided
    if options.source then
        handlerInfo.source = options.source
    end
    
    -- Add handler to each event's handlers
    for _, eventId in ipairs(eventIds) do
        -- Initialize handlers table for this event if needed
        if not self.handlers[eventId] then
            self.handlers[eventId] = {}
        end
        
        -- Add handler to event handlers
        table.insert(self.handlers[eventId], handlerInfo)
        
        -- Sort handlers by priority
        table.sort(self.handlers[eventId], sortHandlersByPriority)
    end
    
    -- Store in lookup for quick access
    self.handlerLookup[handlerId] = handlerInfo
    
    self:_debug("Subscribed to multiple events:", table.concat(eventIds, ", "), "with handler:", handlerId)
    
    -- Create subscription object
    local subscription: EventSubscription = {
        id = handlerId,
        
        unsubscribe = function()
            self:unsubscribe(handlerId)
        end,
        
        isPaused = function()
            return self.handlerLookup[handlerId] == nil
        end,
        
        pause = function()
            -- Implementation will store the handler temporarily
            self:pauseSubscription(handlerId)
        end,
        
        resume = function()
            -- Implementation will restore the handler
            self:resumeSubscription(handlerId)
        end
    }
    
    return subscription
end

-- Subscribe to events by category
function EventBase:subscribeToCategory(
    category: EventCategory,
    handler: EventHandler,
    options: {
        priority: EventPriority?,
        once: boolean?,
        id: string?,
        source: string?
    }?
): EventSubscription
    options = options or {}
    
    -- Generate or use provided handler ID
    local handlerId = options.id or self:_generateHandlerId()
    
    -- Create handler info
    local handlerInfo = EventTypes.createHandlerInfo(
        handlerId,
        handler,
        options.priority or self.defaultPriority,
        nil,       -- No event type filtering
        {category}, -- This handler only responds to the specified category
        options.once
    )
    
    -- Set source if provided
    if options.source then
        handlerInfo.source = options.source
    end
    
    -- Add to global handlers
    table.insert(self.globalHandlers, handlerInfo)
    
    -- Sort global handlers by priority
    table.sort(self.globalHandlers, sortHandlersByPriority)
    
    -- Store in lookup for quick access
    self.handlerLookup[handlerId] = handlerInfo
    
    self:_debug("Subscribed to category:", category, "with handler:", handlerId)
    
    -- Create subscription object
    local subscription: EventSubscription = {
        id = handlerId,
        
        unsubscribe = function()
            self:unsubscribe(handlerId)
        end,
        
        isPaused = function()
            return self.handlerLookup[handlerId] == nil
        end,
        
        pause = function()
            -- Implementation will store the handler temporarily
            self:pauseSubscription(handlerId)
        end,
        
        resume = function()
            -- Implementation will restore the handler
            self:resumeSubscription(handlerId)
        end
    }
    
    return subscription
end

-- Subscribe to all events
function EventBase:subscribeToAll(
    handler: EventHandler,
    options: {
        priority: EventPriority?,
        once: boolean?,
        id: string?,
        source: string?
    }?
): EventSubscription
    options = options or {}
    
    -- Generate or use provided handler ID
    local handlerId = options.id or self:_generateHandlerId()
    
    -- Create handler info
    local handlerInfo = EventTypes.createHandlerInfo(
        handlerId,
        handler,
        options.priority or self.defaultPriority,
        nil,    -- No event type filtering
        nil,    -- No category filtering
        options.once
    )
    
    -- Set source if provided
    if options.source then
        handlerInfo.source = options.source
    end
    
    -- Add to global handlers
    table.insert(self.globalHandlers, handlerInfo)
    
    -- Sort global handlers by priority
    table.sort(self.globalHandlers, sortHandlersByPriority)
    
    -- Store in lookup for quick access
    self.handlerLookup[handlerId] = handlerInfo
    
    self:_debug("Subscribed to all events with handler:", handlerId)
    
    -- Create subscription object
    local subscription: EventSubscription = {
        id = handlerId,
        
        unsubscribe = function()
            self:unsubscribe(handlerId)
        end,
        
        isPaused = function()
            return self.handlerLookup[handlerId] == nil
        end,
        
        pause = function()
            -- Implementation will store the handler temporarily
            self:pauseSubscription(handlerId)
        end,
        
        resume = function()
            -- Implementation will restore the handler
            self:resumeSubscription(handlerId)
        end
    }
    
    return subscription
end

-- Unsubscribe from events
function EventBase:unsubscribe(handlerId: string): boolean
    -- Find the handler info
    local handlerInfo = self.handlerLookup[handlerId]
    if not handlerInfo then
        self:_debug("Handler not found for unsubscribe:", handlerId)
        return false
    end
    
    -- Remove from lookup
    self.handlerLookup[handlerId] = nil
    
    -- Remove from specific event handlers
    if handlerInfo.eventTypes then
        for eventId, _ in pairs(handlerInfo.eventTypes) do
            if self.handlers[eventId] then
                for i = #self.handlers[eventId], 1, -1 do
                    if self.handlers[eventId][i].id == handlerId then
                        table.remove(self.handlers[eventId], i)
                        break
                    end
                end
            end
        end
    else
        -- Remove from global handlers
        for i = #self.globalHandlers, 1, -1 do
            if self.globalHandlers[i].id == handlerId then
                table.remove(self.globalHandlers, i)
                break
            end
        end
    end
    
    self:_debug("Unsubscribed handler:", handlerId)
    return true
end

-- Pause a subscription
function EventBase:pauseSubscription(handlerId: string): boolean
    -- Implementation would temporarily store the handler
    local handlerInfo = self.handlerLookup[handlerId]
    if not handlerInfo then
        return false
    end
    
    -- We'll just mark it as fired if it's a "once" handler
    -- For regular handlers, we'd need to implement a paused state
    if handlerInfo.once then
        handlerInfo.fired = true
        return true
    end
    
    -- For now, just unsubscribe (this would be improved)
    return self:unsubscribe(handlerId)
end

-- Resume a subscription
function EventBase:resumeSubscription(handlerId: string): boolean
    -- Implementation would restore the handler
    -- This would be implemented based on how pauseSubscription works
    return false
end

-- Emit an event
function EventBase:emit(
    eventId: string, 
    eventData: EventData,
    options: {
        priority: EventPriority?,
        category: EventCategory?,
        cancelable: boolean?,
        source: string?
    }?
): EventResult
    options = options or {}
    
    -- Create the event
    local event = EventTypes.createEvent(
        eventId,
        eventData,
        options.category,
        options.priority or self.defaultPriority,
        options.cancelable
    )
    
    -- Set source if provided
    if options.source then
        event.source = options.source
    end
    
    -- Process the event
    return self:processEvent(event)
end

-- Process an event through the system
function EventBase:processEvent(event: Event): EventResult
    self:_debug("Processing event:", event.id)
    
    -- Create result object
    local result: EventResult = {
        completed = false,
        canceled = false,
        handlerCount = 0,
        stoppedBy = nil,
        canceledBy = nil,
        error = nil
    }
    
    -- Apply filters
    if not self:_applyFilters(event) then
        self:_debug("Event filtered out:", event.id)
        return result
    end
    
    -- Apply transforms
    event = self:_applyTransforms(event)
    
    -- Track that we've processed this event
    if not self.processedEvents[event.id] then
        self.processedEvents[event.id] = 0
    end
    self.processedEvents[event.id] += 1
    
    -- Process event handlers
    local success, err = pcall(function()
        -- Process specific event handlers
        local eventHandlers = self.handlers[event.id] or {}
        
        -- Start with specific event handlers, sorted by priority
        for _, handlerInfo in ipairs(eventHandlers) do
            -- Skip if handler shouldn't process this event
            if not self:_shouldHandleEvent(handlerInfo, event) then
                continue
            end
            
            -- Call the handler
            local handlerSuccess, handlerResult = pcall(function()
                return handlerInfo.handler(event)
            end)
            
            result.handlerCount += 1
            
            -- Mark "once" handlers as fired
            if handlerInfo.once then
                handlerInfo.fired = true
            end
            
            -- Check for handler errors
            if not handlerSuccess then
                self.errorHandler("Error in event handler: " .. tostring(handlerResult), event)
                continue
            end
            
            -- Check for cancellation
            if handlerResult == false and event.cancelable and self.allowCancellation then
                event.canceled = true
                result.canceled = true
                result.canceledBy = handlerInfo.id
                break
            end
            
            -- Check for propagation stop
            if not event.propagating then
                result.stoppedBy = handlerInfo.id
                break
            end
        end
        
        -- If event is still propagating, process global handlers
        if event.propagating and not event.canceled then
            for _, handlerInfo in ipairs(self.globalHandlers) do
                -- Skip if handler shouldn't process this event
                if not self:_shouldHandleEvent(handlerInfo, event) then
                    continue
                end
                
                -- Call the handler
                local handlerSuccess, handlerResult = pcall(function()
                    return handlerInfo.handler(event)
                end)
                
                result.handlerCount += 1
                
                -- Mark "once" handlers as fired
                if handlerInfo.once then
                    handlerInfo.fired = true
                end
                
                -- Check for handler errors
                if not handlerSuccess then
                    self.errorHandler("Error in global event handler: " .. tostring(handlerResult), event)
                    continue
                end
                
                -- Check for cancellation
                if handlerResult == false and event.cancelable and self.allowCancellation then
                    event.canceled = true
                    result.canceled = true
                    result.canceledBy = handlerInfo.id
                    break
                end
                
                -- Check for propagation stop
                if not event.propagating then
                    result.stoppedBy = handlerInfo.id
                    break
                end
            end
        end
    end)
    
    -- Handle errors in the event processing
    if not success then
        result.error = err
        self.errorHandler("Error processing event: " .. tostring(err), event)
    else
        result.completed = true
    end
    
    return result
end

-- Add a filter
function EventBase:addFilter(filter: EventFilter)
    table.insert(self.filters, filter)
end

-- Add a transform
function EventBase:addTransform(transform: EventTransform)
    table.insert(self.transforms, transform)
end

-- Get event statistics
function EventBase:getStats()
    local stats = {
        eventCounts = {},
        totalEvents = 0,
        handlerCounts = {},
        totalHandlers = 0,
        globalHandlers = #self.globalHandlers
    }
    
    -- Count processed events
    for eventId, count in pairs(self.processedEvents) do
        stats.eventCounts[eventId] = count
        stats.totalEvents += count
    end
    
    -- Count handlers
    for eventId, handlers in pairs(self.handlers) do
        stats.handlerCounts[eventId] = #handlers
        stats.totalHandlers += #handlers
    end
    
    return stats
end

-- Reset the event bus
function EventBase:reset()
    -- Clear all handlers
    self.handlers = {}
    self.globalHandlers = {}
    self.handlerLookup = {}
    
    -- Clear event state
    self.eventQueue = {}
    self.processedEvents = {}
    
    -- Reset state
    self.processing = false
    self.paused = false
    self.nextHandlerId = 1
    
    -- Keep filters and transforms (they might be important for system function)
    
    self:_debug("Event bus reset")
end

-- Return the module
return EventBase
