# Event System

## Overview

The Event System provides a unified way to handle events across both client and server environments. It features a flexible architecture with type safety, priority-based event processing, and extensive subscription management capabilities.

## Core Components

- **EventTypes**: Type definitions and constants for events
- **EventBase**: Foundational event processing functionality
- **ClientEvents**: Client-specific event handling with UI and input integration
- **ServerEvents**: Server-specific event handling with persistence and security
- **EventBridge**: (Coming soon) Cross-context event communication

## Key Features

- **Type Safety**: Strong typing for event data
- **Priority System**: Handlers execute in priority order
- **Event Categories**: Logical organization of events
- **Filtering & Transformation**: Process events before handling
- **Subscription Management**: Easy subscription, pausing, and unsubscribing
- **Performance Optimizations**: Efficient event dispatch
- **Debug Visualization**: Visual representation of events (client-only)

## Usage Examples

### Basic Event Handling

```lua
-- Server-side
local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()

-- Subscribe to an event
local subscription = ServerEvents:subscribe("player.levelUp", function(event)
    print(event.data.player.Name .. " leveled up to " .. event.data.newLevel)
    -- Return false to cancel the event (if it's cancelable)
    return true
end)

-- Emit an event
ServerEvents:emit("player.levelUp", {
    player = player,
    oldLevel = oldLevel,
    newLevel = newLevel,
    timestamp = os.time()
})

-- Later, unsubscribe
subscription:unsubscribe()
```

### Client-Side Input Binding

```lua
local ClientEvents = require(ReplicatedStorage.src.client.Core.Events.ClientEvents).get()

-- Bind keyboard input to events
ClientEvents:bindInput(Enum.KeyCode.Space, "input.jump", "both")

-- Subscribe to the event
ClientEvents:subscribe("input.jump", function(event)
    local keyCode = event.data.keyCode
    local player = event.data.player
    print(player.Name .. " pressed " .. keyCode.Name)
end)
```

### UI Event Integration

```lua
local ClientEvents = require(ReplicatedStorage.src.client.Core.Events.ClientEvents).get()

-- Bind UI element events
local button = script.Parent.Button
ClientEvents:bindUIElement(button, "mouseButton1Click", "ui.buttonClicked")

-- Subscribe to UI events
ClientEvents:subscribe("ui.buttonClicked", function(event)
    local element = event.data.element
    print("Button clicked: " .. element.Name)
end)
```

### Category-Based Subscription

```lua
local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()

-- Subscribe to all events in a category
ServerEvents:subscribeToCategory("economy", function(event)
    print("Economy event: " .. event.id)
    -- Log all economy events
    print(game:GetService("HttpService"):JSONEncode(event.data))
end)
```

### Priority-Based Handling

```lua
local ClientEvents = require(ReplicatedStorage.src.client.Core.Events.ClientEvents).get()

-- High priority handler (runs first)
ClientEvents:subscribe("ui.windowClosed", function(event)
    print("High priority handler")
end, {
    priority = 100 -- Higher runs first
})

-- Lower priority handler (runs after)
ClientEvents:subscribe("ui.windowClosed", function(event)
    print("Lower priority handler")
end, {
    priority = 50 -- Default priority
})
```

### One-Time Events

```lua
local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()

-- Subscribe to an event that only fires once
ServerEvents:subscribe("game.roundStarted", function(event)
    print("Round started!")
end, {
    once = true -- Auto-unsubscribes after first trigger
})
```

## Integration with Other Systems

The Event System is designed to integrate seamlessly with other core systems:

- **Registry System**: Components can subscribe to events in their initialization phase
- **Data Management**: Data changes can trigger events
- **UI System**: UI components can both emit and handle events

## Advanced Features

### Server-Side Event Persistence

```lua
local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()

-- Configure event persistence
ServerEvents:configurePersistence({
    ["player.purchased"] = true,
    ["player.achievementUnlocked"] = true
})

-- Fire a persistent event (automatically logged)
ServerEvents:firePersistentEvent("player.purchased", {
    player = player,
    itemId = "premium_pass",
    price = 100,
    currency = "robux"
}, {
    category = "economy",
    save = true -- Will be persisted
})

-- Later, retrieve logs
local purchaseLogs = ServerEvents:getEventLogs({
    eventIds = {"player.purchased"},
    startTime = os.time() - 86400 -- Last 24 hours
})
```

### Client-Side Debug Visualization

```lua
local ClientEvents = require(ReplicatedStorage.src.client.Core.Events.ClientEvents).get()

-- Enable visual representation of events
ClientEvents:enableDebugVisualization(true)
```

## Best Practices

1. **Use Descriptive Event Names**: Use namespaced event names like `category.action`
2. **Handle Events Efficiently**: Keep handlers quick and focused
3. **Clean Up Subscriptions**: Always unsubscribe when no longer needed
4. **Use Event Categories**: Categorize events for easier management
5. **Set Appropriate Priorities**: Only use high/low priorities when order matters
6. **Include Relevant Data**: Make events self-contained with all needed info
7. **Consider Cancellation**: Decide if events should be cancelable

## Migration from Legacy Systems

See the `Documentation/EventSystemMigration.md` file for detailed guidelines on migrating from existing event systems to the new Event System.
