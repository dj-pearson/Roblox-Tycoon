# DataManager Module Documentation

## Overview

The `DataManager` module provides a centralized and robust data management system for the game. It handles all aspects of player data including loading, saving, validation, and restoration. The module was created to fix critical "Data Saving Failures on Player Leave" and related data issues reported in the game.

## Features

- **Robust Data Persistence**: Securely saves and loads player data using DataStoreService
- **Automatic Data Validation**: Checks and fixes corrupted or incomplete player data
- **Retry Mechanism**: Automatically retries failed operations to mitigate transient network issues
- **Tycoon Restoration**: Fully restores player tycoons from saved data
- **Automatic Backup**: Performs regular automated saves to prevent data loss
- **Event System Integration**: Fires events on important data operations for system integration
- **Error Handling**: Comprehensive error handling with fallback mechanisms

## API Reference

### Initialization

#### `DataManager.initialize()`
Initializes the DataManager module. Sets up event connections and DataStore access.

**Returns:**
- `boolean`: `true` if initialization was successful, `false` otherwise

**Example:**
```lua
local success = DataManager.initialize()
if success then
    print("DataManager initialized successfully")
else
    warn("DataManager failed to initialize")
end
```

### Data Operations

#### `DataManager.loadPlayerData(player)`
Loads data for a specified player from the DataStore.

**Parameters:**
- `player` (Player): The player to load data for

**Returns:**
- `boolean`: `true` if loading was successful, `false` otherwise

**Example:**
```lua
local success = DataManager.loadPlayerData(player)
if success then
    print("Data loaded for " .. player.Name)
end
```

#### `DataManager.savePlayerData(player)`
Saves data for a specified player to the DataStore.

**Parameters:**
- `player` (Player): The player to save data for

**Returns:**
- `boolean`: `true` if saving was successful, `false` otherwise

**Example:**
```lua
local success = DataManager.savePlayerData(player)
if success then
    print("Data saved for " .. player.Name)
end
```

#### `DataManager.saveAllPlayers()`
Saves data for all currently connected players.

**Returns:**
- `boolean`: `true` if the operation started successfully, `false` otherwise

**Example:**
```lua
DataManager.saveAllPlayers()
```

#### `DataManager.getPlayerData(player)`
Gets a copy of the current data for a player.

**Parameters:**
- `player` (Player/number): The player or player UserId to get data for

**Returns:**
- `table`: A copy of the player's data, or `nil` if no data exists

**Example:**
```lua
local data = DataManager.getPlayerData(player)
if data then
    print("Player " .. player.Name .. " has " .. data.coins .. " coins")
end
```

#### `DataManager.updatePlayerData(player, newData)`
Updates specific fields in a player's data.

**Parameters:**
- `player` (Player/number): The player or player UserId to update data for
- `newData` (table): Table containing the fields to update

**Returns:**
- `boolean`: `true` if update was successful, `false` otherwise

**Example:**
```lua
local newData = {
    coins = 500,
    level = 3
}
local success = DataManager.updatePlayerData(player, newData)
```

### Tycoon Management

#### `DataManager.restorePlayerTycoon(player)`
Restores a player's tycoon from stored data.

**Parameters:**
- `player` (Player): The player whose tycoon should be restored

**Returns:**
- `boolean`: `true` if restoration was successful, `false` otherwise

**Example:**
```lua
local success = DataManager.restorePlayerTycoon(player)
if success then
    print("Tycoon restored for " .. player.Name)
end
```

#### `DataManager.restoreTile(player, tileId, tileData)`
Restores a specific tile in a player's tycoon.

**Parameters:**
- `player` (Player): The player who owns the tile
- `tileId` (string): The ID of the tile to restore
- `tileData` (table): The data for the tile

**Returns:**
- `boolean`: `true` if restoration was successful, `false` otherwise

**Example:**
```lua
local tileData = {
    properties = {
        Position = Vector3.new(0, 0, 0),
        Size = Vector3.new(10, 1, 10)
    },
    purchased = true,
    gymPartId = "TreadmillPro"
}
local success = DataManager.restoreTile(player, "Tile1", tileData)
```

#### `DataManager.spawnGymPart(player, tile, gymPartId)`
Spawns a gym part on a tile.

**Parameters:**
- `player` (Player): The player who owns the tile
- `tile` (BasePart): The tile to spawn the gym part on
- `gymPartId` (string): The ID of the gym part to spawn

**Returns:**
- `boolean`: `true` if spawning was successful, `false` otherwise

**Example:**
```lua
local tile = player.Tycoon:FindFirstChild("Tile1")
if tile then
    local success = DataManager.spawnGymPart(player, tile, "TreadmillPro")
end
```

#### `DataManager.setFallbackGymPartHandler(handler)`
Sets a custom fallback handler for gym part spawning when the default mechanism fails.

**Parameters:**
- `handler` (function): A function that takes (player, tile, gymPartId) and returns a boolean

**Returns:**
- `boolean`: `true` if the handler was set successfully, `false` otherwise

**Example:**
```lua
local function customGymPartHandler(player, tile, gymPartId)
    -- Custom gym part spawning logic
    return true
end

DataManager.setFallbackGymPartHandler(customGymPartHandler)
```

### Data Validation

#### `DataManager.validateData(data)`
Validates the structure of player data.

**Parameters:**
- `data` (table): The data to validate

**Returns:**
- `boolean`: `true` if the data is valid, `false` otherwise

**Example:**
```lua
local isValid = DataManager.validateData(someData)
if not isValid then
    print("Data is invalid and needs fixing")
end
```

#### `DataManager.fixPlayerData(data)`
Fixes invalid or incomplete player data.

**Parameters:**
- `data` (table): The data to fix

**Returns:**
- `table`: The fixed data

**Example:**
```lua
local fixedData = DataManager.fixPlayerData(corruptedData)
```

## Events

When integrated with EventBridge, the DataManager fires the following events:

- **DataManager_PlayerDataLoaded**: Fired when a player's data is loaded
- **DataManager_PlayerDataSaved**: Fired when a player's data is saved
- **DataManager_PlayerDataError**: Fired when there's an error with player data
- **DataManager_TileRestored**: Fired when a tile is restored
- **DataManager_DataMigrated**: Fired when data is migrated from one version to another

## Default Data Structure

The default player data structure is as follows:

```lua
{
    coins = 0,
    level = 1,
    experience = 0,
    statistics = {
        totalVisitors = 0,
        totalRevenue = 0,
        playtime = 0,
        tilesUnlocked = 0
    },
    tiles = {},
    purchases = {},
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.5,
        notifications = true
    },
    achievements = {},
    lastLogin = 0,
    version = 2
}
```

## Error Handling

The DataManager implements comprehensive error handling:

1. **DataStore Access Failures**: Retries operations up to MAX_RETRIES times
2. **Corrupt Data**: Automatically repairs and validates data structures
3. **Missing Modules**: Uses fallback implementations when dependencies cannot be found
4. **Network Issues**: Implements retry mechanisms with exponential backoff
5. **Missing Game Objects**: Creates required folders and objects if they don't exist

## Integration with Other Systems

### CoreRegistry Integration

The DataManager automatically registers with the CoreRegistry if available:

```lua
if coreRegistry and coreRegistry.registerSystem then
    coreRegistry.registerSystem("DataManager", DataManager)
end
```

### EventBridge Integration

The DataManager integrates with the EventBridge to fire events on important operations:

```lua
if EventBridge.registerEvent then
    EventBridge.registerEvent("DataManager_PlayerDataLoaded")
    -- Other event registrations...
end
```

## Best Practices

1. **Always validate data before use**: Call `DataManager.validateData()` on any external data
2. **Save important changes immediately**: Call `DataManager.savePlayerData()` after important changes
3. **Handle errors gracefully**: Check return values of DataManager functions and handle errors
4. **Don't modify returned data directly**: Use `DataManager.updatePlayerData()` to update fields
5. **Listen to DataManager events**: Subscribe to events to respond to data changes

## Performance Considerations

- The DataManager uses caching to reduce DataStore API calls
- Auto-save runs every 60 seconds to balance between data security and API usage
- Saving operations for multiple players are run in separate threads to prevent blocking
- Data validation and fixing is performed only when needed

## Common Issues and Solutions

### Issue: Data Not Saving

**Possible causes:**
- DataStoreService is not available (Studio mode)
- Player left before save completed
- Exceeded DataStore limits

**Solutions:**
- Ensure game is published for DataStoreService to work
- Implement pre-exit save mechanism (already in DataManager)
- Monitor and limit DataStore usage

### Issue: Corrupted Player Data

**Possible causes:**
- Interrupted save operation
- Bug in data structure manipulation
- Unexpected data type

**Solutions:**
- Use `DataManager.validateData()` and `DataManager.fixPlayerData()`
- Implement data versioning (already in DataManager)
- Add additional validation for critical fields

### Issue: Tycoon Not Restoring Properly

**Possible causes:**
- Missing tile data
- Invalid gym part IDs
- Race condition in object creation

**Solutions:**
- Ensure all required folders exist before restoration
- Use the fallback gym part handler for missing gym parts
- Implement sufficient wait times between restoration steps

## Version History

- **1.0.0**: Initial release with core functionality
