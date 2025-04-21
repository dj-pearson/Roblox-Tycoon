# Roblox Gym Tycoon - Command Reference Guide

This document provides a comprehensive guide to all available global commands (`_G` functions) in the Gym Tycoon project. These commands can be executed in the Command Bar in Roblox Studio to assist with development, debugging, and testing.

## Table of Contents

1. [Floor and Room Structure Commands](#floor-and-room-structure-commands)
2. [Tycoon Automation Commands](#tycoon-automation-commands)
3. [BoundingBox and Hitbox Commands](#boundingbox-and-hitbox-commands)
4. [Equipment Management Commands](#equipment-management-commands)
5. [Visualization Commands](#visualization-commands)
6. [Buy Tile System Commands](#buy-tile-system-commands)
7. [Debugging and Information Commands](#debugging-and-information-commands)

## Floor and Room Structure Commands

Commands related to floor detection, room structure, and attributes.

### `_G.ProcessTycoon(tycoonName)`

Analyzes a tycoon structure to identify floors, walls, and rooms, then applies appropriate attributes.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to process. If not provided, will look for "GymParts" or "Tycoon" in the workspace.

**Example:**
```lua
_G.ProcessTycoon("GymParts")
```

**Returns:** Prints the number of floors detected in the tycoon.

### `_G.ShowRoomInfo(tycoonName)`

Displays detailed information about all rooms in a tycoon.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to analyze. If not provided, will look for "GymParts" or "Tycoon" in the workspace.

**Example:**
```lua
_G.ShowRoomInfo("GymParts")
```

**Returns:** Prints detailed information about each room, including its type, dimensions, and part counts.

### `_G.SetRoomType(tycoonName, floorNumber, roomName, roomType)`

Sets the type of a specific room in the tycoon.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon. If not provided, will look for "GymParts" or "Tycoon".
- `floorNumber` (number): The floor number where the room is located.
- `roomName` (string): The name of the room to modify.
- `roomType` (string): The new room type (e.g., "Entrance", "Reception", "Cardio", "Weights", etc.)

**Example:**
```lua
_G.SetRoomType("GymParts", 1, "Floor1_Room1", "Reception")
```

**Returns:** Confirmation message that the room type has been set.

### `_G.HighlightRoom(tycoonName, floorNumber, roomName, duration)`

Temporarily highlights a specific room in the tycoon for easier visualization.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon. If not provided, will look for "GymParts" or "Tycoon".
- `floorNumber` (number): The floor number where the room is located.
- `roomName` (string): The name of the room to highlight.
- `duration` (number, optional): Duration in seconds for the highlight to remain visible (default: 5).

**Example:**
```lua
_G.HighlightRoom("GymParts", 1, "Floor1_Room1", 10)
```

**Returns:** Confirmation message and visual highlight in the 3D view.

## Tycoon Automation Commands

Commands for automating the setup of gym tycoons.

### `_G.AutomateGym(tycoonName)`

Completely automates the setup of a specific gym tycoon by applying floor attributes, detecting rooms, generating tile data, setting up equipment, creating hitboxes, and generating build order.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to automate. If not provided, uses the first tycoon found.

**Example:**
```lua
_G.AutomateGym("GymParts")
```

**Returns:** Summary of the automation process, including counts of floors, equipment, and hitboxes.

### `_G.AutomateAllGyms()`

Automates all gym tycoons found in the workspace.

**Example:**
```lua
_G.AutomateAllGyms()
```

**Returns:** Summary of the automation process for all detected gyms.

### `_G.AutomateGymTycoon(config)`

Advanced automation with configuration options. Uses the consolidated modular system.

**Parameters:**
- `config` (table, optional): Table with configuration options like `generateConfig`, `setupAttributes`, `generateHitboxes`, etc.

**Example:**
```lua
_G.AutomateGymTycoon({
    generateConfig = true,
    setupAttributes = true,
    generateHitboxes = true,
    analyzeStructure = true,
    overrideExisting = false,
    showDebug = true
})
```

**Returns:** Summary of the automation process with detailed status of each step.

### `_G.AnalyzeGymStructure(verbose)`

Analyzes the gym structure without applying changes.

**Parameters:**
- `verbose` (boolean): Whether to show detailed information.

**Example:**
```lua
_G.AnalyzeGymStructure(true)
```

**Returns:** Analysis of the gym structure.

## BoundingBox and Hitbox Commands

Commands related to hitbox and bounding box generation for equipment placement.

### `_G.GenerateHitboxes()`

Creates hitboxes for BuyTile interaction.

**Example:**
```lua
_G.GenerateHitboxes()
```

**Returns:** Number of hitboxes created.

### `_G.ShowHitboxes()`

Makes all hitboxes visible in the workspace.

**Example:**
```lua
_G.ShowHitboxes()
```

**Returns:** Confirmation message and visible hitboxes in the 3D view.

### `_G.HideHitboxes()`

Makes all hitboxes invisible in the workspace.

**Example:**
```lua
_G.HideHitboxes()
```

**Returns:** Confirmation message and hides hitboxes in the 3D view.

### `_G.GenerateBoundingBoxes(tileType, tycoon)`

Generates bounding boxes for equipment placement, either for a specific tile type or all types.

**Parameters:**
- `tileType` (string, optional): The specific tile type to generate boxes for. If not provided, generates for all types.
- `tycoon` (Instance, optional): The tycoon to generate boxes for. If not provided, looks for "Tycoon" or "GymParts".

**Example:**
```lua
_G.GenerateBoundingBoxes("Treadmill")
```

**Returns:** Confirmation message with the number of bounding boxes generated.

### `_G.ShowNextTiles(tycoon)`

Shows bounding boxes for the next purchasable tiles based on progression.

**Parameters:**
- `tycoon` (Instance, optional): The tycoon to show next tiles for. If not provided, looks for "Tycoon" or "GymParts".

**Example:**
```lua
_G.ShowNextTiles()
```

**Returns:** Confirmation message with the number of next purchasable tiles shown.

### `_G.ClearBoundingBoxes(tycoon)`

Clears all bounding boxes for a specific tycoon or all tycoons.

**Parameters:**
- `tycoon` (Instance, optional): The tycoon to clear boxes for. If not provided, clears for all tycoons.

**Example:**
```lua
_G.ClearBoundingBoxes()
```

**Returns:** Confirmation message.

## Equipment Management Commands

Commands for managing gym equipment.

### `_G.ProcessEquipment(options)`

Processes all equipment in the workspace, setting up attributes and interactions.

**Parameters:**
- `options` (table, optional): Configuration options for equipment processing.

**Example:**
```lua
_G.ProcessEquipment({
    setupAttributes = true,
    generateInteractions = true
})
```

**Returns:** Summary of processed equipment.

### `_G.UpgradeEquipment(model)`

Upgrades a specific piece of equipment.

**Parameters:**
- `model` (string or Instance): The model to upgrade, either as a string name or an Instance.

**Example:**
```lua
_G.UpgradeEquipment("Treadmill_Basic")
```

**Returns:** Confirmation of the upgrade.

## Buy Tile System Commands

Commands for managing the BuyTile system and progression.

### `_G.GenerateBuildOrder()`

Generates a logical build order progression for tiles based on floors, prices, and other factors.

**Example:**
```lua
_G.GenerateBuildOrder()
```

**Returns:** Confirmation and displays the first 10 items in the build order.

### `_G.GenerateBuyTileConfig()`

Generates configuration for the BuyTile system.

**Example:**
```lua
_G.GenerateBuyTileConfig()
```

**Returns:** Confirmation of config generation.

### `_G.AutoSetupBuyTiles()`

Automatically sets up all buy tiles in all tycoons.

**Example:**
```lua
_G.AutoSetupBuyTiles()
```

**Returns:** Confirmation with statistics.

### `_G.SetAutomationConfig(config)`

Sets configuration options for the automation system.

**Parameters:**
- `config` (table): Configuration options.

**Example:**
```lua
_G.SetAutomationConfig({
    generateConfig = true,
    setupAttributes = true
})
```

**Returns:** Updated configuration.

## Debugging and Information Commands

Commands for debugging and retrieving information.

### `_G.ShowTycoonInfo(tycoonName)`

Displays detailed information about a tycoon's structure, including floors, rooms, equipment, tiles, and hitboxes.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to show info for. If not provided, uses the first tycoon found.

**Example:**
```lua
_G.ShowTycoonInfo("GymParts")
```

**Returns:** Detailed information about the tycoon's structure and components.

### `_G.SyncGymStructure(verbose)`

Synchronizes gym structure data across systems.

**Parameters:**
- `verbose` (boolean): Whether to show detailed information.

**Example:**
```lua
_G.SyncGymStructure(true)
```

**Returns:** Status of the sync operation.

## Recommended Workflow

For a typical development workflow, here is a recommended sequence of commands:

1. **Process the tycoon structure**: `_G.ProcessTycoon()`
2. **Review room information**: `_G.ShowRoomInfo()`
3. **Set proper room types**: `_G.SetRoomType()` for each room that needs adjustment
4. **Process equipment**: `_G.ProcessEquipment()`
5. **Generate build order**: `_G.GenerateBuildOrder()`
6. **Generate hitboxes**: `_G.GenerateHitboxes()`
7. **Show hitboxes to verify**: `_G.ShowHitboxes()`
8. **Review final tycoon info**: `_G.ShowTycoonInfo()`

Alternatively, use the all-in-one automation: `_G.AutomateGym()` or `_G.AutomateGymTycoon()`

## Notes

- Most commands will work with either a specific tycoon name provided or will default to looking for "GymParts" or "Tycoon" in the workspace.
- All functions are designed to work in Studio mode only.
- When customizing room types, refer to the allowed room types defined in the `CONFIG.ROOM_TYPES` table in the FloorAttributeSetup module.