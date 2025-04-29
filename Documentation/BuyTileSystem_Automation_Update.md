# BuyTile System Automation Update - April 28, 2025

## Overview

This update enhances the BuyTile system with automated configuration based on the GymParts folder structure. The new automation system scans the physical folder hierarchy in ServerStorage.GymParts and automatically generates the appropriate tile data, tags, attributes, and progression logic.

## Key Components Added

### 1. GymPartsScanner.server.luau

A new script that automatically scans the GymParts folder structure and generates BuyTile configuration based on:

- Floor folders (`Floor 1`, `Floor 2`, etc.)
- Room subfolders (`Cardio`, `Strength`, etc.)
- Equipment organization within rooms (`Treadmills`, `Bikes`, etc.)

The scanner applies appropriate tags and attributes to all gym parts for easy identification and filtering, generates cost values based on floor and room type, and creates logical prerequisites between items.

### 2. BuyTileSystemIntegration.server.luau

A new integration script that connects the GymPartsScanner with the existing BuyTileSystem, providing:

- Automatic initialization on server start
- Commands for managing the integration
- Event handling for system coordination
- Validation and repair of the BuyTile system

### 3. GymPartsScanner_Test.server.luau

A test script that creates a sample GymParts structure and verifies the scanner is working correctly.

## Folder Structure Requirements

The automation system expects the GymParts folder to be organized as follows:

```
GymParts/
  FrontDesk/            (Special folder, processed first)
  Floor 1/
    Walls/              (Processed first in each floor)
    Rooms/
      Cardio/
        Treadmills/     (Equipment subfolders)
        Bikes/
      Strength/
        Weights/
        Machines/
    Ceiling/            (Processed after rooms)
    Stairs/             (Processed last, unlocks next floor)
  Floor 2/
    ...etc
```

## New Features

### 1. Automated Tile Data Generation

The system now automatically generates tile data from the folder structure, including:

- Cost values based on floor level and room type
- Prerequisites based on logical progression
- Build order that follows the physical structure
- Room-based grouping for related equipment

### 2. Tagging System

All gym parts are now tagged for easy filtering:

- `GymPart` tag for all gym parts
- `BuyTile` tag for all buyable tiles
- Floor, room, and equipment type tags
- Special tags for specific roles (e.g., `FrontDesk`)

### 3. Attribute System

Gym parts now have attributes that provide detailed information:

- `BuyTileId`: Unique ID for the tile
- `TileFloor`: Floor number
- `TileRoom`: Room type
- `TileEquipment`: Equipment type
- `TileCost`: Cost to purchase
- `TilePriority`: Purchase priority
- `TileIdAttribute`: ID for ordering
- `TileName`: Display name
- `TilePath`: Path in folder structure

### 4. Command and Admin UI Integration

New commands available in the command bar:

- `_G.SetupBuyTileSystem()`: Sets up the system
- `_G.ScanGymPartsStructure()`: Returns structure data
- `_G.TestGymPartsScanner()`: Runs the test script

Admin commands:

- `/setupBuyTiles`: Sets up the BuyTile system
- `/integrateBuyTile`: Integrates the system
- `/generateTileData source`: Generates tile data

Admin Dashboard UI:

- **Admin Dashboard > Game Settings tab**: Contains a "Setup BuyTile System" button
- Provides visual feedback and confirmation dialog
- Logs results to the command output in the Admin Dashboard

### 5. Event System Integration

New events fired by the system:

- `GymPartsScanner_SetupComplete`
- `BuyTileSystem_Integrated`
- `BuyTileSystem_SetupFromGymParts`

## Usage Guide

### Adding New Equipment

1. Add your model to the appropriate subfolder in GymParts
2. Run `_G.SetupBuyTileSystem()`

### Reorganizing Progression

1. Move folders/models in the GymParts structure
2. Run `_G.SetupBuyTileSystem()`

### Adding a New Floor

1. Create a new "Floor X" folder with appropriate subfolders
2. Run `_G.SetupBuyTileSystem()`

## Benefits

This automation system provides several benefits:

1. **Maintainability**: Changes to the progression flow are as simple as reorganizing folders
2. **Consistency**: Enforces a consistent progression structure
3. **Efficiency**: Eliminates the need for manual configuration
4. **Flexibility**: Easily adapt to new floor layouts and equipment
5. **Integration**: Connects with existing systems through CoreRegistry and EventBridge

## Integration with Previous Updates

This update builds on the BuyTile system revamp from earlier today, enhancing it with automated configuration capabilities while preserving all the previously implemented features:

- Room-based progression logic
- "Front Desk first" approach
- Floor-by-floor progression
- Enhanced prerequisites system
- Improved error handling

## Documentation

For detailed information, see the new documentation file:
`Documentation/GymParts_Automation_Documentation.md`
