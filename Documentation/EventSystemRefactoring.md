# Event System Refactoring Plan

## Current Issues

Based on the analysis of the existing structure, we've identified several issues with the current Event Systems:

1. **Fragmentation**: Multiple event systems exist across different directories:
   - `src/client/Core/ClientEvents.client.luau`: Client event system
   - `src/client/Core/ClientEventBridge.client.luau`: Client-server communication
   - `src/server/Core/EventBridge.server.luau`: Server event handling
   - `src/server/Core/EventCreator.server.luau`: Event creation system
   - `src/server/Essentials/EventBridge.server.luau`: Essential events communication

2. **Redundancy**: Likely duplicate functionality exists between the multiple event bridges.

3. **Inconsistent Naming**: Similar functionality with different names (EventBridge vs EventCreator).

4. **Unclear Responsibilities**: The separation between different event systems is not clearly defined.

## Proposed Solution

We propose a unified Event System with clear separation of concerns:

### 1. Core Event Modules

- **`src/shared/Events/EventTypes.luau`**: Definitions of event types and type checking
- **`src/shared/Events/EventBase.luau`**: Base class for events with common functionality
- **`src/client/Core/Events/ClientEvents.luau`**: Client-side events management
- **`src/server/Core/Events/ServerEvents.luau`**: Server-side events management
- **`src/shared/Events/EventBridge.luau`**: Unified client-server communication

### 2. Key Features

- **Type Safety**: Runtime type checking for event parameters
- **Event Categories**: Organizing events into logical categories
- **Middleware Support**: Add processing steps between event dispatch and handling
- **Debugging Tools**: Built-in logging and tracing of event flow
- **Performance Metrics**: Track event frequency and handling time
- **Documentation**: Auto-generated event documentation

### 3. Implementation Strategy

#### Phase 1: Create Core Event Infrastructure

1. Implement `EventTypes.luau` to define standardized event types:
   - Define basic event types (string, number, boolean, etc.)
   - Support for complex types (tables, arrays, etc.)
   - Type validation functions

2. Implement `EventBase.luau` with core functionality:
   - Event creation
   - Event subscription
   - Event firing
   - Type validation
   - Middleware support

#### Phase 2: Implement Client and Server Events

1. Create `ClientEvents.luau` for client-side event management:
   - Local client events
   - UI event handling
   - Client-to-server event forwarding

2. Create `ServerEvents.luau` for server-side event management:
   - Local server events
   - Game mechanic events
   - Server-to-client event broadcasting

#### Phase 3: Implement Event Bridge

1. Create unified `EventBridge.luau`:
   - Client-to-server communication
   - Server-to-client communication
   - Server-to-clients (broadcast) communication
   - Type validation across network boundary
   - Rate limiting and security checks

#### Phase 4: Documentation and Examples

1. Create comprehensive documentation:
   - Usage guidelines
   - API reference
   - Best practices

2. Develop example implementations:
   - Common event patterns
   - Integration with game systems
   - Error handling examples

## Migration Strategy

1. **Map Existing Events**: Document all current events in the system
2. **Create Equivalent Events**: Recreate existing events in the new system
3. **Adapter Layer**: Create adapters for legacy code during transition
4. **Gradual Migration**: Replace event handlers one at a time

## Example Usage

### Shared Events

```lua
-- Define an event type
local PlayerJoinedEvent = EventTypes.defineEvent("PlayerJoined", {
    player = EventTypes.Instance("Player"),
    joinTime = EventTypes.Number,
    isNewPlayer = EventTypes.Boolean
})

-- Register the event
SharedEvents:registerEvent(PlayerJoinedEvent)
```

### Client Events

```lua
-- Subscribe to an event
ClientEvents:subscribe("ButtonClicked", function(buttonId, playerInput)
    -- Handle button click
    print("Button clicked:", buttonId)
end)

-- Fire an event
ClientEvents:fire("ButtonClicked", "playButton", { x = 100, y = 200 })
```

### Server Events

```lua
-- Subscribe to an event
ServerEvents:subscribe("PlayerJoined", function(player, joinTime, isNewPlayer)
    -- Handle player joining
    print("Player joined:", player.Name, "at", joinTime)
    
    if isNewPlayer then
        -- Handle new player
    end
end)

-- Fire an event
ServerEvents:fire("PlayerJoined", player, os.time(), isNew)
```

### Event Bridge

```lua
-- Client to server
EventBridge:fireServer("PurchaseItem", itemId, quantity)

-- Server to client
EventBridge:fireClient(player, "ItemPurchased", itemId, quantity, success)

-- Server to all clients
EventBridge:fireAllClients("GlobalAnnouncement", message, duration)
```

## Timeline

- **Week 1**: Define event types and base infrastructure
- **Week 2**: Implement client and server event systems
- **Week 3**: Implement event bridge and test communication
- **Week 4**: Create documentation and begin migration

## Benefits

1. **Consistency**: Single coherent system for all event operations
2. **Type Safety**: Runtime validation of event parameters
3. **Debugging**: Improved tools for tracking and debugging events
4. **Performance**: Better monitoring and optimization of event handling
5. **Maintainability**: Clearer structure and better documentation

By implementing this refactoring plan, we can create a more reliable and maintainable event system that will improve code quality and reduce bugs related to event handling throughout the codebase.
