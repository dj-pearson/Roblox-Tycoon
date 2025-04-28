# TycoonHelper Module Documentation

## Overview

The `TycoonHelper` module provides utilities for working with tycoons in the game. It handles tycoon creation, restoration, and management, ensuring that player tycoons are properly initialized and maintained. The module was created to fix critical "Data Restoration Issues" reported in the game.

## Features

- **Tycoon Creation**: Properly creates tycoon instances for players
- **Tile Management**: Handles creation and restoration of tycoon tiles
- **Gym Part Spawning**: Places gym equipment and objects on tiles with proper positioning
- **Purchase Tracking**: Keeps track of which tiles and items have been purchased
- **Error Handling**: Robust error handling for all tycoon operations
- **Event System Integration**: Fires events for tycoon-related activities
- **Fallback Mechanisms**: Provides fallbacks when operations fail

## API Reference

### Initialization

#### `TycoonHelper.initialize()`
Initializes the TycoonHelper module. Sets up event handlers and verifies necessary assets.

**Returns:**
- `boolean`: `true` if initialization was successful

**Example:**
```lua
TycoonHelper.initialize()
```

### Tycoon Management

#### `TycoonHelper.createTycoonForPlayer(player)`
Creates a new tycoon for a specified player.

**Parameters:**
- `player` (Player): The player to create a tycoon for

**Returns:**
- `boolean`: `true` if tycoon was created successfully, `false` otherwise

**Example:**
```lua
local success = TycoonHelper.createTycoonForPlayer(player)
if success then
    print("Created tycoon for " .. player.Name)
end
```

#### `TycoonHelper.getTycoon(player)`
Gets a player's tycoon instance.

**Parameters:**
- `player` (Player): The player whose tycoon to retrieve

**Returns:**
- `Instance`: The player's tycoon instance, or `nil` if it doesn't exist

**Example:**
```lua
local tycoon = TycoonHelper.getTycoon(player)
if tycoon then
    print("Found tycoon for " .. player.Name)
end
```

### Tile Management

#### `TycoonHelper.createTile(player, tileId, properties)`
Creates a new tile in a player's tycoon.

**Parameters:**
- `player` (Player): The player who owns the tycoon
- `tileId` (string): Unique identifier for the tile
- `properties` (table, optional): Properties for the tile
  - `Size` (Vector3): Size of the tile
  - `Position` (Vector3): Position of the tile
  - `BrickColor` (BrickColor): Color of the tile
  - `Material` (Enum.Material): Material of the tile
  - Other BasePart properties

**Returns:**
- `boolean, Instance`: Success status and the created tile instance

**Example:**
```lua
local success, tile = TycoonHelper.createTile(player, "Tile1", {
    Size = Vector3.new(10, 1, 10),
    Position = Vector3.new(0, 0, 0),
    BrickColor = BrickColor.new("Medium stone grey"),
    Material = Enum.Material.Concrete
})
```

#### `TycoonHelper.restoreTile(player, tileId, tileData)`
Restores a tile from saved data.

**Parameters:**
- `player` (Player): The player who owns the tycoon
- `tileId` (string): Identifier for the tile to restore
- `tileData` (table): Data for the tile
  - `properties` (table): Physical properties of the tile
  - `purchased` (boolean): Whether the tile is purchased
  - `gymPartId` (string): ID of the gym part to spawn on the tile

**Returns:**
- `boolean`: `true` if tile was restored successfully, `false` otherwise

**Example:**
```lua
local tileData = {
    properties = {
        Size = Vector3.new(10, 1, 10),
        Position = Vector3.new(0, 0, 0)
    },
    purchased = true,
    gymPartId = "TreadmillPro"
}

local success = TycoonHelper.restoreTile(player, "Tile1", tileData)
```

#### `TycoonHelper.getTile(player, tileId)`
Gets a specific tile from a player's tycoon.

**Parameters:**
- `player` (Player): The player who owns the tycoon
- `tileId` (string): Identifier for the tile to retrieve

**Returns:**
- `Instance`: The tile instance, or `nil` if it doesn't exist

**Example:**
```lua
local tile = TycoonHelper.getTile(player, "Tile1")
if tile then
    print("Found tile " .. tileId .. " for " .. player.Name)
end
```

#### `TycoonHelper.isTilePurchased(player, tileId)`
Checks if a specific tile has been purchased.

**Parameters:**
- `player` (Player): The player who owns the tycoon
- `tileId` (string): Identifier for the tile to check

**Returns:**
- `boolean`: `true` if the tile is purchased, `false` otherwise

**Example:**
```lua
if TycoonHelper.isTilePurchased(player, "Tile1") then
    print("Tile1 is purchased by " .. player.Name)
end
```

### Gym Part Management

#### `TycoonHelper.spawnGymPart(player, tile, gymPartId)`
Spawns a gym part on a specific tile.

**Parameters:**
- `player` (Player): The player who owns the tycoon
- `tile` (Instance): The tile to place the gym part on
- `gymPartId` (string): Identifier for the gym part to spawn

**Returns:**
- `boolean`: `true` if gym part was spawned successfully, `false` otherwise

**Example:**
```lua
local tile = TycoonHelper.getTile(player, "Tile1")
if tile then
    local success = TycoonHelper.spawnGymPart(player, tile, "TreadmillPro")
end
```

## Events

When integrated with EventBridge, the TycoonHelper fires the following events:

- **TycoonHelper_TycoonCreated**: Fired when a tycoon is created for a player
- **TycoonHelper_TileRestored**: Fired when a tile is successfully restored
- **TycoonHelper_GymPartSpawned**: Fired when a gym part is spawned on a tile
- **TycoonHelper_TileCreationFailed**: Fired when tile creation fails
- **TycoonHelper_TileCreated**: Fired when a new tile is created

## Dependencies

The TycoonHelper module uses the following dependencies:

- **EventBridge**: For firing and handling events
- **SafeWaitForChild**: For safely waiting for child instances
- **DataManager**: For data-related operations (server-side only)

## Tycoon Structure

A standard tycoon created by TycoonHelper has the following structure:

```
Tycoon (Model)
├── Stats (Folder)
│   ├── Coins (IntValue)
│   ├── Level (IntValue)
│   └── ...other stats...
├── Purchases (Folder)
│   └── ...purchase records...
├── TycoonData (Folder)
│   └── ...additional data...
└── ...tiles...
    └── ...gym parts...
```

## Integration with Other Systems

### CoreRegistry Integration

The TycoonHelper automatically registers with the CoreRegistry on the server:

```lua
if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("TycoonHelper", TycoonHelper)
    end
end
```

### EventBridge Integration

The TycoonHelper integrates with the EventBridge to fire events on important operations:

```lua
if EventBridge.registerEvent then
    EventBridge.registerEvent("TycoonHelper_TycoonCreated")
    EventBridge.registerEvent("TycoonHelper_TileRestored")
    EventBridge.registerEvent("TycoonHelper_GymPartSpawned")
    EventBridge.registerEvent("TycoonHelper_TileCreationFailed")
end
```

## Best Practices

1. **Validate Players**: Always check that the player parameter is valid before operations
2. **Handle Errors**: Check return values of TycoonHelper functions and handle errors
3. **Use Event Listeners**: Listen for events to respond to tycoon changes
4. **Centralize Tycoon Management**: Use TycoonHelper for all tycoon-related operations
5. **Check Purchase Status**: Use `isTilePurchased` before allowing operations on tiles

## Error Handling

TycoonHelper implements several error handling strategies:

1. **Parameter Validation**: All functions validate their parameters
2. **Safe Module Loading**: Uses fallbacks when dependencies can't be found
3. **Isolation of Operations**: Each operation is isolated to prevent cascading failures
4. **Clear Error Messages**: Descriptive warnings when operations fail
5. **Return Values**: Functions return success/failure status for error handling

## Common Issues and Solutions

### Issue: Tycoons Not Creating

**Possible causes:**
- Missing tycoon template
- Player already has a tycoon
- ServerStorage configuration issues

**Solutions:**
- Ensure the tycoon template exists at the configured path
- Use `getTycoon` to check for existing tycoons
- Configure the correct template path in TycoonHelper

### Issue: Tiles Not Appearing

**Possible causes:**
- Invalid tile properties
- Positioning issues
- Race conditions in creation

**Solutions:**
- Validate tile properties before calling `createTile`
- Use a consistent coordinate system for positioning
- Add delay between tile creation operations

### Issue: Gym Parts Missing

**Possible causes:**
- Invalid gym part ID
- Missing gym part models
- Incorrect folder structure

**Solutions:**
- Verify gym part IDs before use
- Ensure all gym part models are in the correct folder
- Use descriptive IDs that match folder names

## Version History

- **1.0.0**: Initial release with core functionality
