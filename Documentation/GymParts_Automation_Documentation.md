# GymParts Folder Structure Automation

## Overview

This document describes the new automation system for the BuyTile progression based on the folder structure in the GymParts folder. The system automatically scans the physical structure of the GymParts folder and generates the appropriate tags, attributes, and BuyTile configuration data based on the folder hierarchy.

## Folder Structure

The expected folder structure for the GymParts folder is:

```
GymParts/
  FrontDesk/
    (front desk models)
  Floor 1/
    Walls/
      (wall models)
    Rooms/
      Cardio/
        Treadmills/
          (treadmill models)
        Bikes/
          (bike models)
      Strength/
        Weights/
          (weight models)
        Machines/
          (machine models)
    Ceiling/
      (ceiling models)
    Stairs/
      (stair models to Floor 2)
  Floor 2/
    ...etc
```

## Key Systems

### 1. GymPartsScanner.server.luau

The main automation script that handles:
- Scanning the GymParts folder structure
- Applying tags and attributes to gym parts
- Generating BuyTile configuration data
- Setting up prerequisites based on progression rules

### 2. BuyTileSystemIntegration.server.luau

Integration script that connects the GymPartsScanner with the BuyTileSystem:
- Handles the initialization sequence
- Provides commands for managing the integration
- Validates and repairs the system if needed
- Listens for relevant events

### 3. GymPartsScanner_Test.server.luau

Test script that creates a sample GymParts structure and tests the scanner.

## Progression Rules

The automation system follows these progression rules:

1. **Front Desk First**: Items in the FrontDesk folder are always first (ID attribute 1)
2. **Floor-by-Floor Progression**: Players must complete a floor before moving to the next
3. **Room-Based Ordering**: Within each floor, progression follows the physical room structure:
   - Walls first
   - Room equipment (following subfolder hierarchy)
   - Ceiling
   - Stairs (to unlock the next floor)
4. **Equipment Hierarchy**: Equipment follows the subfolder structure within each room
   (e.g., Cardio/Treadmills before Cardio/Bikes)

## Tags and Attributes

The system applies the following tags to gym parts:

- `GymPart`: Applied to all gym parts
- `BuyTile`: Applied to all buyable tiles
- `Floor_X`: Indicates the floor number (e.g., `Floor_1`)
- `Room_X`: Indicates the room type (e.g., `Room_Cardio`)
- `Equipment_X`: Indicates equipment type (e.g., `Equipment_Treadmill`)
- `FrontDesk`: Special tag for the front desk

And these attributes:

- `BuyTileId`: Unique ID for the tile
- `TileFloor`: Floor number
- `TileRoom`: Room type
- `TileEquipment`: Equipment type
- `TileCost`: Cost to purchase
- `TilePriority`: Purchase priority
- `TileIdAttribute`: ID attribute (used for ordering)
- `TileName`: Display name
- `TilePath`: Path in folder structure

## Costs and Progression

The system automatically calculates costs based on:

- Floor number (higher floors cost more)
- Room type (specialized rooms cost more)
- Equipment size (larger equipment costs more)

## Commands

The system provides the following commands (available in the command bar):

- `_G.SetupBuyTileSystem()`: Sets up the BuyTile system from the GymParts folder
- `_G.ScanGymPartsStructure()`: Returns the structure data without applying it
- `_G.TestGymPartsScanner()`: Runs the test script with a sample structure
- `_G.IntegrateBuyTileSystem()`: Initializes the integration system
- `_G.GenerateBuyTileDataFrom(source)`: Generates tile data from a specific source

And these admin commands:

- `/setupBuyTiles`: Sets up the BuyTile system
- `/integrateBuyTile`: Integrates the BuyTile system
- `/generateTileData source`: Generates tile data from a specified source

## Admin Dashboard Integration

The system is integrated with the Admin Dashboard UI through a dedicated button:

1. Open the Admin Dashboard by clicking the "Admin" button in the main menu
2. Navigate to the "Game Settings" tab
3. Scroll down to find the "Setup BuyTile System" button
4. Click the button and confirm the action
5. The system will run the setup process and display the results

## Events

The system fires these events:

- `GymPartsScanner_SetupComplete`: Fired when setup is complete
- `BuyTileSystem_Integrated`: Fired when integration is complete
- `BuyTileSystem_SetupFromGymParts`: Fired when setup from GymParts is complete

## How to Use

### Adding New Equipment

1. Add your new equipment model to the appropriate subfolder in the GymParts structure
2. Run `_G.SetupBuyTileSystem()` in the command bar
3. The system will automatically update the BuyTile configuration

### Reorganizing the Progression

1. Move folders/models in the GymParts structure to reflect desired progression
2. Run `_G.SetupBuyTileSystem()` in the command bar
3. The system will regenerate the progression based on the new structure

### Adding a New Floor

1. Create a new folder named "Floor X" in GymParts
2. Add appropriate subfolders (Walls, Rooms, Ceiling, Stairs)
3. Run `_G.SetupBuyTileSystem()` in the command bar
4. The new floor will be added to the progression automatically

### Testing the System

Run `_G.TestGymPartsScanner()` to create a sample structure and test the system.

## Integration with Other Systems

The GymParts automation system integrates with:

- **BuyTileSystem**: Provides tile data and progression logic
- **CoreRegistry**: Registers systems and facilitates communication
- **EventBridge**: Fires events for other systems to respond to
- **CommandService**: Provides admin commands
- **DataManager**: Handles saving and loading purchased tiles

## Troubleshooting

If the system isn't working as expected:

1. Check the folder structure follows the expected format
2. Run `_G.TestGymPartsScanner()` to verify the scanner works
3. Run diagnostics using `/diagnostics` command
4. Check for errors in the output window
5. Try regenerating tile data with `_G.GenerateBuyTileDataFrom("gymparts")`

## Conclusion

This automation system provides a flexible and maintainable way to manage the BuyTile progression based on the physical folder structure of your gym. By simply organizing your models in the appropriate folder hierarchy, you can control the progression flow without writing any code.
