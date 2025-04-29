# BuyTile System Revamp - April 28, 2025

## Overview

The BuyTile system has been completely revamped to implement a new logical progression sequence based on physical gym structure. The new system organizes the purchase flow according to the following rules:

1. **Front Desk First** (ID attribute 1) - This starts the membership desk
2. **Walls** - Wall sections are purchased next for structural integrity
3. **Room Content** - Equipment and amenities within rooms, following folder structure
4. **Ceiling** - Ceiling elements are purchased after room contents
5. **Stairs** - Stairs to the next floor are purchased last

Each floor follows this progression pattern, with floors unlocking sequentially after the previous floor is completed.

## Key Components

The BuyTile system revamp involves these key components:

### 1. BuyTileSystem.server.luau

Core system handling tile purchasing, prerequisites, and gym part spawning. Key enhancements:

- New structure build order constants
- Improved gym part placement logic
- Automatic tile ordering based on structure type
- Enhanced folder hierarchy support
- Better error handling and fallbacks

### 2. TileDataInitializer.server.luau

New module that scans the physical gym structure and generates appropriate tile data:

- Analyzes GymStructure folder hierarchy
- Follows room folder structure for equipment ordering
- Automatically sets up prerequisites between elements
- Enforces floor-by-floor progression
- Creates appropriate cost scaling by floor

### 3. BuyTileProgressionManager.server.luau

Enhanced to work with the new folder structure:

- Updated progression constants for Front Desk first approach
- Improved room priority ordering
- Better prerequisite generation between floors
- Enhanced integration with CoreRegistry

### 4. SystemDiagnostics.server.luau

New diagnostic utility to verify system integrity:

- Checks folder structure against expectations
- Validates BuyTile system configuration
- Automatically repairs common issues
- Provides detailed logs and commandline diagnostics

## Tile Progression Rules

The new progression system follows these rules:

1. **Floor Progression**: Players must complete a floor before unlocking the next
2. **Room-Based Ordering**: Equipment follows the room folder structure (Cardio, Strength, etc.)
3. **Front Desk Priority**: The front desk (ID attribute 1) is always the first unlocked item
4. **Structural Dependency**: Equipment requires walls, ceilings require completed rooms
5. **Stair Gateway**: Stairs act as gateways to the next floor and require the current floor to be complete

## Commands

The following commands are available to administrators:

- `/generateTileData` - Regenerates tile data from gym structure
- `/showTileProgression` - Shows the current progression order of tiles
- `/diagnostics` - Runs system diagnostics and shows results
- `/checkProgression` - Shows available tiles for a player

## Implementation Details

### Folder Structure

The expected folder structure in ServerStorage is:

```
GymStructure/
  FrontDesk/
  1st_Floor/
    Walls/
    Rooms/
      Cardio/
        Treadmill
        Elliptical
      Strength/
        BenchPress
        Dumbbells
    Ceiling/
    Stairs/
  2nd_Floor/
    ...
```

### Prerequisites Logic

Prerequisites are generated based on:

1. **Spatial Relationship**: Items in the same room have dependencies
2. **Structural Requirements**: Equipment requires walls to be built first
3. **Floor Dependencies**: Upper floors require stairs from lower floors
4. **Room Completion**: Ceilings require room equipment to be purchased
5. **ID Attributes**: Lower ID attributes generally come before higher ones

## Technical Implementation

The implementation uses CoreRegistry to coordinate between systems and provides events for major milestones:

- `TileData_Initialized` - Fired when tile data is fully initialized
- `BuyTile_TilePurchased` - Fired when a player purchases a tile
- `BuyTile_GymPartSpawned` - Fired when a gym part is spawned
- `FloorUnlocked` - Fired when a player unlocks a new floor

## Integration with Other Systems

The BuyTile system integrates with:

- **DataManager**: For saving player purchases and progression
- **EventBridge**: For firing events on major actions
- **CoreRegistry**: For system registration and coordination
- **CommandService**: For administrative commands

## Automation Capabilities

The system includes automation scripts:

- `_G.GenerateBuyTileConfig()` - Generates tile configuration from physical structure
- `_G.AutoSetupBuyTiles()` - Sets up the entire buy tile system automatically

## Troubleshooting

If the BuyTile system is not working correctly:

1. Run `/diagnostics` to check system health
2. Verify the folder structure follows the expected pattern
3. Try running `_G.GenerateBuyTileConfig()` to regenerate tile data
4. Check for error messages related to prerequisites or gym parts

## Conclusion

This revamp creates a more intuitive and maintainable progression system that follows the physical structure of the gym. The tile purchase order now makes logical sense to players while still maintaining proper progression gates and requirements.
