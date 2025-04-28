# Critical Fix Modules Integration Guide

## Introduction

This guide explains how to properly integrate the newly implemented critical fix modules into your game code. The modules work together to provide a comprehensive solution for data management, asset loading, system communication, and tycoon operations. Following these integration patterns will help ensure your game benefits from all the stability and performance improvements.

## Overview of Modules

Before diving into integration, it's important to understand how the modules relate to each other:

- **DataManager**: Central data persistence system
- **AssetValidator**: Asset verification and fallback system
- **EventBridge**: Cross-system communication backbone
- **TycoonHelper**: Tycoon creation and management utilities
- **TileValidator**: Validation and fixing for tiles and gym parts

These modules have intentional dependencies:

```
EventBridge ← DataManager ← TycoonHelper ← TileValidator
      ↑
AssetValidator
```

All modules depend on EventBridge for communication, and TileValidator depends on TycoonHelper, which depends on DataManager. AssetValidator is more independent but still uses EventBridge.

## Integration Steps

### 1. Module Loading Sequence

To ensure proper initialization, load the modules in the following order:

#### Server-Side

```lua
-- 1. First load EventBridge as a dependency for other modules
local EventBridge = require(ServerScriptService.Core.EventBridge)

-- 2. Then load DataManager which depends on EventBridge
local DataManager = require(ServerScriptService.Core.DataManager)

-- 3. Load AssetValidator which has minimal dependencies
local AssetValidator = require(ServerScriptService.Core.AssetValidator)

-- 4. Load TycoonHelper which depends on both EventBridge and DataManager
local TycoonHelper = require(ServerScriptService.Core.TycoonHelper)

-- 5. Finally load TileValidator which depends on TycoonHelper
local TileValidator = require(ServerScriptService.Core.TileValidator)
```

#### Client-Side

```lua
-- 1. First load EventBridge as a dependency for other modules
local EventBridge = require(ReplicatedStorage.Core.EventBridge)

-- 2. Load AssetValidator for client-side asset validation
local AssetValidator = require(ReplicatedStorage.Core.AssetValidator)
```

### 2. Initialization Sequence

Call initialize() on each module in the proper sequence:

```lua
-- Server-side initialization
EventBridge.initialize()
DataManager.initialize()
AssetValidator.initialize()
TycoonHelper.initialize()
TileValidator.initialize()
```

### 3. Core Registry Integration

If using CoreRegistry, modules will automatically register themselves. To access them:

```lua
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)

-- Get references to registered modules
local DataManager = CoreRegistry.getSystem("DataManager")
local EventBridge = CoreRegistry.getSystem("EventBridge")
local AssetValidator = CoreRegistry.getSystem("AssetValidator")
local TycoonHelper = CoreRegistry.getSystem("TycoonHelper")
local TileValidator = CoreRegistry.getSystem("TileValidator")
```

## Module Integration Patterns

### DataManager Integration

#### Setting Up Player Data

```lua
-- Automatic loading happens on PlayerAdded
-- But you can manually load if needed
local function onPlayerJoin(player)
    -- DataManager will automatically load data
    -- You can access it after it's loaded
    EventBridge.listenToEvent("DataManager_PlayerDataLoaded", function(data)
        if data.player == player then
            print("Data loaded for " .. player.Name)
            -- Now you can use the data
            local playerData = DataManager.getPlayerData(player)
        end
    end)
end
```

#### Updating Player Data

```lua
-- Update specific data fields
local function awardCoins(player, amount)
    local data = DataManager.getPlayerData(player)
    if data then
        local updatedData = {
            coins = data.coins + amount
        }
        DataManager.updatePlayerData(player, updatedData)
        
        -- For important changes, consider saving immediately
        DataManager.savePlayerData(player)
    end
end
```

### AssetValidator Integration

#### Validating Assets Before Use

```lua
-- Create UI elements with validated images
local function createShopItem(itemId, imageId)
    local frame = Instance.new("Frame")
    
    -- Use AssetValidator to create the ImageLabel with validation
    local icon = AssetValidator.createImageLabel(imageId, {
        Size = UDim2.new(0, 100, 0, 100),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = frame
    })
    
    return frame
end
```

#### Preloading Assets

```lua
-- Preload assets for improved performance
local function preloadShopAssets(shopData)
    local assetIds = {}
    
    for _, item in pairs(shopData.items) do
        table.insert(assetIds, item.imageId)
        table.insert(assetIds, item.soundId)
    end
    
    AssetValidator.preloadAssets(assetIds)
end
```

### EventBridge Integration

#### Setting Up Event System

```lua
-- Register game events
local function setupGameEvents()
    EventBridge.registerEvent("Player_PurchasedItem", {
        description = "Fired when a player purchases an item",
        validation = function(data)
            return typeof(data) == "table" and 
                   data.player and 
                   data.itemId and
                   typeof(data.cost) == "number"
        end
    })
    
    EventBridge.registerEvent("Tycoon_TileUpdated", {
        description = "Fired when a tycoon tile is updated"
    })
end
```

#### Using Events for Communication

```lua
-- Fire an event when a purchase happens
local function processPurchase(player, itemId, cost)
    -- Handle purchase logic
    local success = handleTransaction(player, cost)
    
    if success then
        -- Notify other systems about the purchase
        EventBridge.fireEvent("Player_PurchasedItem", {
            player = player,
            itemId = itemId,
            cost = cost,
            timestamp = os.time()
        })
    end
    
    return success
end

-- Listen for purchase events
local function setupPurchaseListener()
    EventBridge.listenToEvent("Player_PurchasedItem", function(data)
        -- Update shop inventory
        updateInventory(data.player, data.itemId)
        
        -- Play purchase sound
        playPurchaseSound(data.player)
    end)
end
```

### TycoonHelper Integration

#### Managing Player Tycoons

```lua
-- Create and set up a player's tycoon
local function setupPlayerTycoon(player)
    local success = TycoonHelper.createTycoonForPlayer(player)
    
    if success then
        -- Get the tycoon instance
        local tycoon = TycoonHelper.getTycoon(player)
        
        -- Create initial tiles
        TycoonHelper.createTile(player, "EntranceTile", {
            Size = Vector3.new(10, 1, 10),
            Position = Vector3.new(0, 0, 0),
            BrickColor = BrickColor.new("Medium stone grey"),
            Material = Enum.Material.Concrete
        })
    end
end

-- Handle purchases of new tiles
local function purchaseTile(player, tileId, position)
    -- Check if player can afford the tile
    local playerData = DataManager.getPlayerData(player)
    
    if canAffordTile(playerData, tileId) then
        -- Create the tile
        local success, tile = TycoonHelper.createTile(player, tileId, {
            Size = Vector3.new(8, 1, 8),
            Position = position,
            BrickColor = BrickColor.new("Bright green"),
            Material = Enum.Material.Grass
        })
        
        if success then
            -- Update player data
            deductCoins(player, getTileCost(tileId))
            
            -- Notify systems
            EventBridge.fireEvent("Tycoon_TileUpdated", {
                player = player,
                tileId = tileId,
                action = "purchase"
            })
            
            return true
        end
    end
    
    return false
end
```

### TileValidator Integration

#### Validating Tycoon Tiles

```lua
-- Validate all tiles in a player's tycoon
local function validatePlayerTycoon(player)
    local success, issues = TileValidator.validateAllTiles(player, {
        autoFix = true,
        validateGymParts = true
    })
    
    if not success then
        -- Log validation issues
        for tileId, tileIssues in pairs(issues) do
            for _, issue in ipairs(tileIssues) do
                print("Tile " .. tileId .. " issue: " .. issue.message)
            end
        end
    end
    
    return success
end

-- Validate a specific tile after creation or modification
local function validateNewTile(player, tileId)
    local tile = TycoonHelper.getTile(player, tileId)
    
    if tile then
        local success, issues = TileValidator.validateTile(tile, {
            autoFix = true
        })
        
        if not success then
            -- Notify player of issues
            for _, issue in ipairs(issues) do
                notifyPlayer(player, "Tile issue: " .. issue.message)
            end
        end
        
        return success
    end
    
    return false
end
```

## Combined Usage Examples

### Complete Player Onboarding Flow

This example demonstrates how all modules work together during player onboarding:

```lua
local function onPlayerJoin(player)
    -- Load player data
    local dataLoaded = DataManager.loadPlayerData(player)
    
    -- Listen for the data loaded event
    EventBridge.listenToEventOnce("DataManager_PlayerDataLoaded", function(data)
        if data.player == player then
            -- Create or restore tycoon
            if data.data.hasTycoon then
                print("Restoring existing tycoon")
                DataManager.restorePlayerTycoon(player)
            else
                print("Creating new tycoon")
                TycoonHelper.createTycoonForPlayer(player)
                
                -- Mark that player now has a tycoon
                DataManager.updatePlayerData(player, {
                    hasTycoon = true
                })
            end
            
            -- Validate the tycoon
            task.spawn(function()
                -- Give time for tycoon to fully load
                task.wait(1)
                
                local valid, issues = TileValidator.validateAllTiles(player, {
                    autoFix = true
                })
                
                if not valid then
                    print("Fixed " .. #issues .. " issues with player tycoon")
                end
                
                -- Preload assets for this player's tycoon
                preloadTycoonAssets(player)
            end)
        end
    end)
}
```

### Complete Purchase Flow

This example shows how the modules work together during an item purchase:

```lua
local function purchaseGymEquipment(player, tileId, gymEquipmentId)
    -- Get player data
    local playerData = DataManager.getPlayerData(player)
    
    -- Check if player can afford the equipment
    if playerData.coins < getEquipmentCost(gymEquipmentId) then
        return false, "Not enough coins"
    end
    
    -- Get the tile
    local tile = TycoonHelper.getTile(player, tileId)
    if not tile then
        return false, "Tile not found"
    end
    
    -- Check if tile is purchased
    if not TycoonHelper.isTilePurchased(player, tileId) then
        return false, "Tile not purchased"
    end
    
    -- Validate the equipment ID
    local validatedId = AssetValidator.validateAssetId(gymEquipmentId, {
        assetType = "GymEquipment"
    })
    
    -- Spawn the gym part
    local success = TycoonHelper.spawnGymPart(player, tile, validatedId)
    
    if success then
        -- Deduct coins
        local newCoins = playerData.coins - getEquipmentCost(gymEquipmentId)
        DataManager.updatePlayerData(player, {
            coins = newCoins
        })
        
        -- Update tile data
        local tileData = playerData.tiles[tileId] or {}
        tileData.gymPartId = validatedId
        tileData.purchaseTimestamp = os.time()
        
        local updatedTileData = {
            tiles = playerData.tiles
        }
        updatedTileData.tiles[tileId] = tileData
        
        DataManager.updatePlayerData(player, updatedTileData)
        
        -- Validate the placement
        task.spawn(function()
            task.wait(0.2)  -- Allow time for the part to settle
            
            local gymPart = tile:FindFirstChild(validatedId)
            if gymPart then
                TileValidator.validateGymPart(gymPart, tile)
            end
        end)
        
        -- Fire purchase event
        EventBridge.fireEvent("Player_PurchasedEquipment", {
            player = player,
            tileId = tileId,
            equipmentId = validatedId,
            cost = getEquipmentCost(gymEquipmentId)
        })
        
        return true
    end
    
    return false, "Failed to spawn equipment"
end
```

## Troubleshooting Integration

### Common Integration Issues

#### Issue: Events Not Firing

**Problem:** Events registered in EventBridge aren't being received by listeners.

**Solution:**
1. Ensure EventBridge is initialized before registering or listening for events
2. Check that event names match exactly (case-sensitive)
3. Verify that event scope is appropriate (local, remote, or all)
4. Enable debug mode to trace event flow: `EventBridge.enableDebugMode()`

#### Issue: Player Data Not Saving

**Problem:** Player data changes aren't persisting after the player leaves.

**Solution:**
1. Check that DataManager is properly initialized
2. Use `DataManager.updatePlayerData()` instead of modifying data directly
3. Call `DataManager.savePlayerData(player)` after important changes
4. Listen for the `DataManager_PlayerDataSaved` event to confirm saves

#### Issue: Tycoon Not Restoring Properly

**Problem:** Player tycoons aren't restoring correctly when players rejoin.

**Solution:**
1. Ensure proper dependency order: EventBridge → DataManager → TycoonHelper
2. Allow sufficient time for the DataManager to load data before restoration
3. Use event listeners to coordinate tycoon restoration after data is loaded
4. Run TileValidator on restored tycoons to fix any issues

#### Issue: Assets Not Loading

**Problem:** Game assets aren't appearing or are showing errors.

**Solution:**
1. Always use AssetValidator to validate asset IDs before use
2. Register fallback assets for critical asset types
3. Use the factory methods (`createImageLabel`, `createSound`) for automatic validation
4. Check asset validation events for specific failure information

## Best Practices for Integration

1. **Follow Initialization Order**: Initialize modules in the correct dependency order
2. **Use Event-Based Communication**: Communicate between systems via EventBridge
3. **Validate Early and Often**: Use TileValidator to check tiles after creation/modification
4. **Handle Errors Gracefully**: Always check return values and handle errors
5. **Save After Important Changes**: Call save methods after significant data changes
6. **Validate Assets Before Use**: Always run assets through AssetValidator
7. **Use Factory Methods**: Use provided factory methods over direct instance creation
8. **Listen for System Events**: Set up listeners for key system events
9. **Implement Graceful Recovery**: Build systems that can recover from partial failures
10. **Document System Dependencies**: Keep track of which systems depend on others

## Conclusion

By following this integration guide, you can effectively combine all the critical fix modules into a cohesive system that addresses data management, asset loading, communication, and tycoon operations. These modules work together to provide a robust foundation for your game, eliminating common sources of errors and providing fallback mechanisms when things go wrong.

Each module has detailed documentation available for more specific usage information:

- [DataManager Documentation](./DataManager_Documentation.md)
- [AssetValidator Documentation](./AssetValidator_Documentation.md)
- [EventBridge Documentation](./EventBridge_Documentation.md)
- [TycoonHelper Documentation](./TycoonHelper_Documentation.md)
- [TileValidator Documentation](./TileValidator_Documentation.md)

For a comprehensive overview of all the issues these modules address, see the [Comprehensive Implementation Summary](./ComprehensiveImplementationSummary.md).
