# Automation Scripts Consolidation Plan

## Overview
This document outlines the plan to consolidate all gym automation scripts into a more modular and maintainable structure. The goal is to eliminate code duplication, improve maintainability, and create a more robust system.

## Scripts Being Consolidated

### Standalone Scripts
- `FloorAttributeSetup.server.luau` - Floor detection and room structure
- `GymAutomation.server.luau` - Main automation controller

## New Modular System
### Core Module Responsibilities
- Consolidate all scripts related to the automation of model attributes and buy tile placement into one seamless script.  The current setup has several scripts with some having overlapping functionality.  The scripts should be efficient, reliable, and effective for tile placement.

### New Modules
1. `BuyTileProgressionManager.server.luau` - Manages progression and prerequisites
2. `TileDataGenerator.server.luau` - Generates tile data from equipment models
3. `MigrationUtils.server.luau` - Utilities for migrating from old systems

### Consolidated Modules
1. `BoundingBoxManager.server.luau` - Consolidates all bounding box and hitbox functionality
2. `EquipmentManager.server.luau` - Consolidates all equipment handling and upgrades

## Integration Approach

### Phase 1: Create Consolidated Modules (Completed)
- ✅ Created `BoundingBoxManager.server.luau` (Consolidates `BoundingBoxGenerator` and `EquipmentBoundingBox`)
- ✅ Created `EquipmentManager.server.luau` (Consolidates `EquipmentSetup` and `EquipmentUpgradeSystem`)

### Phase 2: Update Main Automation Script (Completed)
- ✅ Updated `GymAutomation.server.luau` to use new consolidated modules
- ✅ Enhanced with fallback behavior if modules are not available

### Phase 3: Data Migration (Pending)
- [ ] Create migration functions in `MigrationUtils.server.luau` to help transition data
- [ ] Add backward compatibility for old script behavior

### Phase 4: Testing & Validation (Pending)
- [ ] Test automation on sample gym tycoon to ensure all functions work
- [ ] Verify that all equipment is properly detected and set up
- [ ] Confirm build order progression works as expected

### Phase 5: Deprecate Old Scripts (Pending)
- [ ] Add deprecation notices to old scripts
- [ ] Redirect old script usage to new modules
- [ ] Document new system for developer reference

### BoundingBoxManager
- Generate hitboxes for buyable tiles
- Calculate optimal bounding boxes
- Visualize hitboxes for debugging
- Manage interaction zones

### EquipmentManager
- Initialize equipment models
- Apply equipment attributes
- Manage upgrade paths
- Handle equipment state changes

### BuyTileProgressionManager
- Manage build order for tiles
- Set up prerequisites for tile purchases
- Identify required tiles for progression
- Control floor unlocking

### TileDataGenerator
- Generate tile data from models
- Apply attribute templates
- Organize tiles by category and type
- Calculate prices and income values

## Global Studio Functions
Studio-only global functions have been provided for testing:
- `_G.AutomateGym(tycoonName)` - Automate a specific tycoon
- `_G.AutomateAllGyms()` - Automate all gym tycoons
- `_G.GenerateBuildOrder()` - Generate build order for tiles
- `_G.ShowTycoonInfo(tycoonName)` - Show debug info about tycoon structure
- `_G.ShowHitboxes()` - Show all hitboxes
- `_G.HideHitboxes()` - Hide all hitboxes
- `_G.ProcessEquipment()` - Process all equipment in workspace

## Future Improvements
- Add configuration options for different tycoon styles
- Implement more advanced room detection algorithms
- Create visualizations for build order progression
- Add automated testing for system integrity