# EventBridge Module Documentation

## Overview

The `EventBridge` module provides a centralized event system for the game, enabling reliable communication between different systems and across client-server boundaries. It was created to fix issues with event handling and cross-boundary communication, ensuring that events are properly fired and received throughout the game.

## Features

- **Centralized Event Registration**: Maintain a registry of all events used in the game
- **Cross-Boundary Communication**: Seamlessly handle events between client and server
- **Event History**: Track recent event firings for debugging purposes
- **Error Handling**: Robust error handling for event callbacks
- **Custom Event Scoping**: Control whether events are local, remote, or both
- **Event Filtering**: Filter events based on various criteria
- **Debugging Utilities**: Built-in tools for tracking and troubleshooting events
- **Performance Monitoring**: Track event performance and frequency

## API Reference

### Event Registration

#### `EventBridge.registerEvent(eventName, options)`
Registers an event with the EventBridge system.

**Parameters:**
- `eventName` (string): The name of the event to register
- `options` (table, optional): Configuration options
  - `scope` (string): The event scope ("local", "remote", "all") (default: "all")
  - `throttle` (number): Minimum time between event fires in seconds
  - `debug` (boolean): Whether to enable extra debugging for this event
  - `description` (string): Description of the event's purpose
  - `validation` (function): Callback to validate event data

**Returns:**
- `boolean`: `true` if the event was registered successfully, `false` otherwise

**Example:**
```lua
EventBridge.registerEvent("PlayerCollectedCoin", {
    scope = "all",
    description = "Fired when a player collects a coin",
    validation = function(data)
        return typeof(data) == "table" and 
               data.player and 
               typeof(data.amount) == "number"
    end
})
```

#### `EventBridge.isEventRegistered(eventName)`
Checks if an event is registered with the EventBridge system.

**Parameters:**
- `eventName` (string): The name of the event to check

**Returns:**
- `boolean`: `true` if the event is registered, `false` otherwise

**Example:**
```lua
if EventBridge.isEventRegistered("PlayerCollectedCoin") then
    print("PlayerCollectedCoin event is registered")
end
```

#### `EventBridge.unregisterEvent(eventName)`
Unregisters an event from the EventBridge system.

**Parameters:**
- `eventName` (string): The name of the event to unregister

**Returns:**
- `boolean`: `true` if the event was unregistered successfully, `false` otherwise

**Example:**
```lua
EventBridge.unregisterEvent("TemporaryEvent")
```

### Event Firing and Handling

#### `EventBridge.fireEvent(eventName, data)`
Fires an event with the specified data.

**Parameters:**
- `eventName` (string): The name of the event to fire
- `data` (any): The data to pass with the event

**Returns:**
- `boolean`: `true` if the event was fired successfully, `false` otherwise

**Example:**
```lua
EventBridge.fireEvent("PlayerCollectedCoin", {
    player = player,
    amount = 50,
    position = player.Character.HumanoidRootPart.Position
})
```

#### `EventBridge.listenToEvent(eventName, callback)`
Subscribes a callback function to an event.

**Parameters:**
- `eventName` (string): The name of the event to listen to
- `callback` (function): The function to call when the event is fired

**Returns:**
- `RBXScriptConnection`: The connection object, or `nil` if unsuccessful

**Example:**
```lua
local connection = EventBridge.listenToEvent("PlayerCollectedCoin", function(data)
    print(data.player.Name .. " collected " .. data.amount .. " coins!")
    updatePlayerCoins(data.player, data.amount)
end)
```

#### `EventBridge.listenToEventOnce(eventName, callback)`
Subscribes a callback to an event, but disconnects after the first firing.

**Parameters:**
- `eventName` (string): The name of the event to listen to
- `callback` (function): The function to call when the event is fired

**Returns:**
- `RBXScriptConnection`: The connection object, or `nil` if unsuccessful

**Example:**
```lua
EventBridge.listenToEventOnce("PlayerCompletedTutorial", function(data)
    awardTutorialCompletion(data.player)
end)
```

### Remote Events

#### `EventBridge.fireRemoteEvent(eventName, data)`
Fires a remote event from server to client or client to server.

**Parameters:**
- `eventName` (string): The name of the event to fire
- `data` (any): The data to pass with the event
- `filter` (table/Player, optional): Player(s) to send to (server only)

**Returns:**
- `boolean`: `true` if the event was fired successfully, `false` otherwise

**Example:**
```lua
-- On server:
EventBridge.fireRemoteEvent("UpdateCoins", { coins = 100 }, player)

-- On client:
EventBridge.fireRemoteEvent("PurchaseRequest", { itemId = "sword" })
```

### Event History and Debugging

#### `EventBridge.getEventHistory(eventName)`
Gets the recent history of an event's firings.

**Parameters:**
- `eventName` (string): The name of the event to get history for

**Returns:**
- `table`: Array of event firing entries with timestamp, data, and source

**Example:**
```lua
local history = EventBridge.getEventHistory("PlayerCollectedCoin")
for _, entry in ipairs(history) do
    print(entry.timestamp .. ": " .. entry.source)
end
```

#### `EventBridge.enableDebugMode()`
Enables detailed debugging for all events.

**Example:**
```lua
EventBridge.enableDebugMode()
```

#### `EventBridge.disableDebugMode()`
Disables detailed debugging.

**Example:**
```lua
EventBridge.disableDebugMode()
```

### System Information

#### `EventBridge.getRegisteredEvents()`
Gets a list of all registered events.

**Returns:**
- `table`: Array of event names and their configurations

**Example:**
```lua
local events = EventBridge.getRegisteredEvents()
for eventName, config in pairs(events) do
    print(eventName .. " - " .. (config.description or "No description"))
end
```

## Event Scope

The EventBridge supports three scopes for events:

1. **"local"**: Events that only fire within the same context (client or server)
2. **"remote"**: Events that only fire across the boundary (client to server or server to client)
3. **"all"**: Events that fire both locally and remotely (default)

## Integration with Other Systems

### Server-Side Integration

The EventBridge automatically registers with the CoreRegistry on server startup:

```lua
local CoreRegistry = safeRequire(findModule("CoreRegistry"))
if CoreRegistry and CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("EventBridge", EventBridge)
end
```

### Client-Side Integration

On the client, the EventBridge registers with the ClientRegistry:

```lua
local ClientRegistry = safeRequire(findModule("ClientRegistry"))
if ClientRegistry and ClientRegistry.registerSystem then
    ClientRegistry.registerSystem("EventBridge", EventBridge)
end
```

## Best Practices

1. **Register All Events**: Always register events before using them to ensure proper documentation and tracking
2. **Use Descriptive Event Names**: Name events clearly based on what happened (e.g., "PlayerCollectedCoin" not "CoinEvent")
3. **Validate Event Data**: Add validation functions to ensure event data is properly formatted
4. **Handle Connection Cleanup**: Store and disconnect connections when they're no longer needed
5. **Use Event Namespacing**: Prefix event names with a system name to avoid collisions (e.g., "Inventory_ItemAdded")
6. **Be Mindful of Remote Events**: Remote events have network overhead, so use them judiciously

## Performance Considerations

- Local events have minimal overhead and can be used generously
- Remote events involve network traffic, so be mindful of their frequency and data size
- Throttling high-frequency events can improve performance
- The EventBridge has internal optimizations for high-volume events

## Debugging Tips

1. **Enable Debug Mode**: Use `enableDebugMode()` to see detailed event information
2. **Check Event History**: Use `getEventHistory()` to trace recent event firings
3. **Verify Event Registration**: Use `isEventRegistered()` to confirm events exist
4. **Add Event Descriptions**: Include clear descriptions when registering events
5. **Use Validation Functions**: Add validation to catch malformed event data early

## Common Issues and Solutions

### Issue: Events Not Firing

**Possible causes:**
- Event not properly registered
- Typos in event names
- Wrong event scope
- Client/server boundary issues

**Solutions:**
- Check that the event is registered with `isEventRegistered()`
- Verify exact spelling of event names
- Ensure the event scope is appropriate
- Use debug mode to track event firing attempts

### Issue: Event Handlers Not Executing

**Possible causes:**
- Error in callback function
- Connection disconnected
- Event throttled
- Data validation failing

**Solutions:**
- Add error handling in callbacks
- Check connection return values
- Verify throttle settings
- Use the debug mode to see validation failures

### Issue: Performance Problems

**Possible causes:**
- Too many remote events
- Large data payloads
- High-frequency events without throttling

**Solutions:**
- Batch updates instead of firing multiple events
- Minimize data sent in events
- Add appropriate throttling
- Use local-only events when possible

## Version History

- **1.0.0**: Initial release with core functionality
