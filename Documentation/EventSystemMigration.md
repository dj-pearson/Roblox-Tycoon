# Event System Migration Guide

**Last Updated: May 2, 2025**

This guide provides a step-by-step approach to migrating from the legacy event system to the new unified Event System. The new system offers better type safety, performance, and flexibility, while maintaining compatibility with existing code through migration utilities.

## Migration Overview

The migration strategy follows these principles:

1. **Gradual Migration**: You don't need to update all code at once. Legacy code continues to function.
2. **Parallel Operation**: Both old and new event systems operate simultaneously during migration.
3. **Compatibility Layer**: The `EventMigration` utility bridges the gap between systems.
4. **Forward Compatibility**: Events fired through the old system automatically trigger handlers in the new system.

## Why Migrate?

The new Event System provides significant advantages:

- **Type Safety**: Improves code reliability with runtime type checking
- **Priority System**: Control the order of event handler execution
- **Middleware Support**: Transform and filter events before they reach handlers
- **Performance Optimizations**: More efficient event dispatch patterns
- **Improved Debugging**: Better tools for tracking event flow and issues
- **Organized Categories**: Logical grouping of related events

## Migration Steps

### Step 1: Update Module References

Replace references to legacy event modules with the new ones:

```lua
-- OLD (Legacy)
local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")

-- NEW (Server)
local ServerEvents = require(ServerScriptService.src.server.Core.Events.ServerEvents).get()

-- NEW (Client)
local ClientEvents = require(game:GetService("Players").LocalPlayer.PlayerScripts.src.client.Core.Events.ClientEvents).get()

-- Migration Utility (both contexts)
local EventMigration = require(ReplicatedStorage.src.shared.Events.EventMigration)
```

### Step 2: Migrate Event Connections

#### Legacy Approach:
```lua
-- OLD: Server receiving events
local purchaseEvent = ReplicatedStorage.RemoteEvents.EquipmentPurchase
purchaseEvent.OnServerEvent:Connect(function(player, equipmentId, amount)
    -- Handle purchase
end)

-- OLD: Client receiving events
local resourceEvent = ReplicatedStorage.RemoteEvents.ResourceUpdate
resourceEvent.OnClientEvent:Connect(function(resourceType, newAmount)
    -- Update UI
end)
```

#### Migration Approach:
```lua
-- MIGRATION: Use EventMigration to handle legacy events
EventMigration:ConnectLegacyEvent("EquipmentPurchase", function(player, equipmentId, amount)
    -- Legacy handling remains the same
end)

-- NEW: Also connect using the new API for future code
ServerEvents:subscribe("tycoon.equipment.purchase", function(event)
    local player = event.data.player
    local equipmentId = event.data.equipmentId
    local amount = event.data.amount
    
    -- Handle purchase with new structure
end)
```

### Step 3: Migrate Event Firing

#### Legacy Approach:
```lua
-- OLD: Server firing events to clients
local purchaseEvent = ReplicatedStorage.RemoteEvents.EquipmentPurchase
purchaseEvent:FireClient(player, equipmentId, amount)

-- OLD: Client firing events to server
local event = ReplicatedStorage.RemoteEvents.PurchaseRequest
event:FireServer(itemId, quantity)
```

#### Migration Approach:
```lua
-- MIGRATION: Fire both systems in parallel
EventMigration:FireLegacyEvent("EquipmentPurchase", player, equipmentId, amount)

-- NEW: Start using the new API for future code
ServerEvents:emit("tycoon.equipment.purchase", {
    player = player,
    equipmentId = equipmentId,
    amount = amount,
    timestamp = os.time()
})
```

### Step 4: Adopt New Event Patterns

As you migrate, take advantage of the new features:

#### Priority-based Handlers:
```lua
-- High priority handler (runs first)
ServerEvents:subscribe("player.joined", function(event)
    print("FIRST: " .. event.data.player.Name .. " joined")
    return true
end, ServerEvents.PRIORITIES.HIGH)

-- Normal priority handler (runs second)
ServerEvents:subscribe("player.joined", function(event)
    print("SECOND: " .. event.data.player.Name .. " joined")
    return true
end)
```

#### Middleware for Event Processing:
```lua
-- Add logging middleware to specific event
ServerEvents:addEventMiddleware("player.purchase", function(eventData, next)
    print("Purchase attempt: " .. eventData.data.itemId)
    
    -- You can transform the data
    eventData.data.timestamp = os.time()
    
    -- Continue processing
    next(eventData)
end)
```

#### Subscription Management:
```lua
-- Store subscription for later management
local subscription = ClientEvents:subscribe("ui.button.clicked", handleButtonClick)

-- Temporarily pause/resume handling
subscription:pause()   -- Stop receiving events
subscription:resume()  -- Start receiving again

-- Unsubscribe when no longer needed
subscription:unsubscribe()
```

## Event Name Mapping

The following table maps legacy event names to their equivalents in the new system:

| Legacy Event Name | New Event Name |
|-------------------|----------------|
| UINotification | ui.notification |
| OpenMenu | ui.menu.open |
| CloseMenu | ui.menu.close |
| TransactionComplete | economy.transaction.complete |
| ResourceUpdate | economy.resource.update |
| TycoonUpdate | tycoon.update |
| EquipmentPurchase | tycoon.equipment.purchase |
| StaffHire | tycoon.staff.hire |
| GymEquipmentInteraction | gym.equipment.interaction |
| WorkoutComplete | gym.workout.complete |
| MemberSatisfactionChange | gym.member.satisfaction.change |
| PlayerDataUpdate | player.data.update |
| SystemStatus | system.status |
| ErrorReport | system.error |
| DebugCommand | system.debug.command |

## Recommended Migration Order

1. **Start with new features**: Use the new Event System for any new code.
2. **Add parallel handlers**: Set up new event handlers alongside existing ones.
3. **Use the migration utility**: Replace direct event connections with `EventMigration`.
4. **Update event firing code**: Use both systems during transition.
5. **Gradually remove legacy code**: Once confirmed working, remove legacy code.

## Debugging Tips

- Check `EventMigration:GenerateReport()` for statistics on event usage.
- Use `ServerEvents:getSubscriberCount("event.name")` to verify handler connections.
- Events in the new system have built-in logging when in debug mode.

## Complete Examples

For detailed examples of both legacy and new event patterns, see the `EventSystemExamples.luau` file in the `src/shared/Events/Examples` directory.

See the `Documentation/EventSystemMigration.md` file for detailed guidelines on migrating from existing event systems to the new Event System.
