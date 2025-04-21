# BuyTile System Consolidation Plan

This document outlines the strategy for consolidating all equipment and structure automation scripts into the new modular BuyTile system.

## Current Script Inventory

### Legacy/Standalone Scripts
- `FloorAttributeSetup.server.luau` (standalone in root)
- `GymAutomation.server.luau` (standalone in root)

### Core Equipment & Structure Scripts
- `AnalyzeGymStructure.server.luau` - Analyzes gym layout
- `BoundingBoxGenerator.server.luau` - Creates visualization boxes for equipment
- `BuyTileSystem.server.luau` - Core BuyTile functionality 
- `EquipmentBoundingBox.luau` - Equipment-specific bounding boxes
- `EquipmentSetup.server.luau` - Sets up equipment attributes
- `EquipmentUpgradeSystem.luau` - Equipment upgrade functionality
- `FloorAttributeSetup.server.luau` - Sets up floor attributes
- `GymStructureIntegration.server.luau` - Integrates structure data with other systems

### New Modular System
- `FloorAttributeSetup.server.luau` (enhanced version)
- `BuyTileProgressionManager.server.luau`
- `TileDataGenerator.server.luau`
- `MigrationUtils.server.luau`

## Consolidation Strategy

### 1. Core System Components

#### `BuyTileSystem.server.luau`
- Keep as the primary system module
- Refactor to use the new modular components
- Move implementation details to specialized modules

#### `FloorAttributeSetup.server.luau`
- Consolidate standalone and core versions
- Move all floor/room detection logic here
- Integrate structure analysis from AnalyzeGymStructure

#### `BuyTileProgressionManager.server.luau`
- Keep as the progression logic handler
- Integrate buildOrder generation from all other scripts
- Handle prerequisites and dependencies

#### `TileDataGenerator.server.luau`
- Consolidate all tile data generation functionality
- Integrate price calculation and income boost logic
- Handle model scanning and attribute extraction

#### `MigrationUtils.server.luau`
- Keep for transitioning from legacy systems
- Add specific handling for each legacy script

### 2. Equipment & Bounding Box Consolidation

Create a new integrated module:

#### `EquipmentManager.server.luau`
- Consolidate EquipmentSetup and EquipmentUpgradeSystem
- Handle equipment attributes, upgrades, and progression
- Integrate with BuyTileSystem

#### `BoundingBoxManager.server.luau`
- Consolidate BoundingBoxGenerator and EquipmentBoundingBox
- Unified interface for hitbox generation
- Support for both visualization and interaction

### 3. Migration Steps

1. **Analyze & Catalog Functions**
   - Document all public functions across scripts
   - Identify overlapping functionality
   - Map dependencies between scripts

2. **Move Functions to Appropriate Modules**
   - Relocate functions to their logical modules
   - Update references and maintain backward compatibility
   - Document changes in each module header

3. **Create Adapter Layer**
   - Implement adapter functions for backward compatibility
   - Redirect legacy function calls to new implementations
   - Use LegacyBridge.server.luau for legacy support

4. **Update External References**
   - Identify all places where scripts are required
   - Update require statements to use new modules
   - Test all integration points

5. **Archive Legacy Scripts**
   - Move legacy scripts to Unused/ folder
   - Rename with .backup extension
   - Add deprecation notices

## Implementation Order

1. ✅ First consolidate `FloorAttributeSetup` scripts
2. ✅ Create `BoundingBoxManager` to replace bounding box scripts
3. ✅ Create `EquipmentManager` to consolidate equipment scripts
4. ✅ Update `GymAutomation.server.luau` to use all new modules

## Core Module Responsibilities

- **Manage Equipment**: Handle the setup, attributes, and upgrades of all gym equipment, consolidating the functionality previously found in `EquipmentSetup.server.luau` and `EquipmentUpgradeSystem.server.luau`.
- **Handle Bounding Boxes**: Generate and manage bounding boxes for equipment and other interactive elements, consolidating functionality from `BoundingBoxGenerator.server.luau` and `EquipmentBoundingBox.luau`.
- **Manage Buy Tile Placement**: Automate the placement of buy tiles and ensure the placement is efficient, reliable, and effective. Consolidate scripts related to model attribute automation and buy tile placement.
- **Manage Floor Attributes**: Detect and manage floor attributes, consolidating floor/room detection logic from `FloorAttributeSetup.server.luau`.
- **Progression Management**: Handle progression logic, including build order generation and managing prerequisites and dependencies.
- **Data Generation**: Generate tile data, calculate prices, and handle income boost logic.
- **Migration Utilities**: Provide utilities for transitioning from legacy systems to the consolidated system.
- **Core Automation**: Provide core functions for automating gym setup, generating hitboxes, and setting up attributes on models.

## Implementation Order


## Migration Steps

1. ⏳ Run migration utilities to transition data


6. ⏳ Update any GUI or command bar references
7. ⏳ Archive legacy scripts after thorough testing

## Current Progress (April 21, 2025)

### Completed
- Created `BoundingBoxManager.server.luau` that consolidates all bounding box and hitbox functionality
- Created `EquipmentManager.server.luau` that consolidates equipment handling and upgrades
- Updated `GymAutomation.server.luau` to use our new consolidated modules
- Verified `MigrationUtils.server.luau` is fully implemented with data migration capabilities
- Created detailed documentation in ConsolidationPlan.md

### In Progress
- Testing the migration process and consolidated system on sample gym tycoons
- Verifying conflicts are properly detected and resolved

### To Do
- Create additional tests to ensure all functionality works as expected
- Add deprecation notices to old scripts
- Update documentation for all new systems

## Testing Plan

1. Use `_G.AutomateGym()` to validate consolidation
2. Test BuyTile visualization with `_G.ShowHitboxes()`
3. Verify progression with `_G.GenerateBuildOrder()`
4. Test migration with `_G.MigrateBuyTileSystem()`
5. Run full build process on test tycoon

## Command Line Functions

```lua
-- Core automation
_G.AutomateGym()         -- Main automation function
_G.GenerateHitboxes()    -- Create hitboxes for visualization
_G.SetupAttributes()     -- Set up attributes on models

-- Visibility
_G.ShowHitboxes()        -- Make hitboxes visible
_G.HideHitboxes()        -- Make hitboxes invisible

-- Advanced
_G.ProcessGymParts()     -- Process gym structure with FloorAttributeSetup
_G.GenerateTileData()    -- Generate tile data with TileDataGenerator
_G.GenerateBuildOrder()  -- Generate progression data with BuyTileProgressionManager
_G.MigrateBuyTileSystem() -- Migrate legacy data to new system
_G.ShowMigrationInfo()   -- Show migration info and conflicts
```