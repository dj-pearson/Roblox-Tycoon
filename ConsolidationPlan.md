# Automation Scripts Consolidation Plan

## Overview
This document outlines the plan to consolidate all gym automation scripts into a more modular and maintainable structure. The goal is to eliminate code duplication, improve maintainability, and create a more robust system.

## Scripts Being Consolidated

### Standalone Scripts
- `FloorAttributeSetup.server.luau` - Floor detection and room structure
- `GymAutomation.server.luau` - Main automation controller

### Core Scripts
- `AnalyzeGymStructure.server.luau` - Analysis of gym layout
- `BoundingBoxGenerator.server.luau` - Hitbox generation for interactable tiles
- `BuyTileSystem.server.luau` - Core system for tile purchases
- `EquipmentBoundingBox.luau` - Equipment-specific hitboxes
- `EquipmentSetup.server.luau` - Equipment configuration and setup
- `EquipmentUpgradeSystem.luau` / `EquipmentUpgradeSystem.server.luau` - Equipment upgrade logic
- `FloorAttributeSetup.server.luau` (Core version) - Floor attribute assignment
- `GymStructureIntegration.server.luau` - Integration with gym structure systems

## New Modular System

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

### Phase 3: Data Migration (Completed)
- [x] Create migration functions in `MigrationUtils.server.luau` to help transition data:
  - [x] `MigrateEquipmentData(oldFormat, newFormat)` - Convert equipment data between formats
  - [x] `MigrateTileData(oldFormat, newFormat)` - Convert tile purchase data between formats
  - [x] `MigrateProgressionData(oldFormat, newFormat)` - Convert progression state data
- [x] Add backward compatibility layer in each consolidated module:
  - [x] `EquipmentManager:LegacySupport()` - Support old equipment API calls
  - [x] `BoundingBoxManager:LegacySupport()` - Support old hitbox generation methods
- [x] Create data validation functions to ensure integrity during migration
- [x] Implement rollback capability if migration issues are detected
- [x] Create comprehensive test suite to verify migration functionality (MigrationTest.server.luau)

### Phase 4: Testing & Validation (Completed)
- [x] Create automated test suite for module functionality:
  - [x] Unit tests for each consolidated module (TestSuite.server.luau)
  - [x] Integration tests for module interactions
  - [x] Edge case handling tests
- [x] Test automation on sample gym tycoon to ensure all functions work:
  - [x] Verify correct tile purchase functionality (TycoonValidationTool.server.luau)
  - [x] Test equipment interaction and upgrades
  - [x] Confirm floor progression and room recognition
- [x] Verify that all equipment is properly detected and set up:
  - [x] Check attribute application
  - [x] Verify upgrade paths work correctly
  - [x] Test equipment interaction zones
- [x] Confirm build order progression works as expected:
  - [x] Test prerequisite system
  - [x] Verify floor unlocking conditions
  - [x] Test progression visualization (BuildOrderVisualizer.server.luau)

### Phase 5: Deprecate Old Scripts (Completed)
- [x] Add deprecation notices to old scripts:
  - [x] Include clear migration instructions
  - [x] Set deprecation date (June 30, 2025)
  - [x] Add links to new module documentation
- [x] Create wrappers for old script interfaces that redirect to new modules:
  - [x] Preserve API signatures for backward compatibility
  - [x] Add warning outputs when deprecated methods are used
  - [x] Log usage of deprecated functions for monitoring (DeprecationHelper.luau)
- [x] Document new system for developer reference:
  - [x] Create detailed API documentation (APIReference.md)
  - [x] Provide migration guides (MigrationGuide.md)
  - [x] Create examples for common use cases

### Phase 6: System Enhancement & Expansion (In Progress)
- [ ] Create advanced configuration system:
  - [ ] `TycoonConfigurationManager.server.luau` - Configuration management for different tycoon styles
  - [ ] JSON-based configuration files
  - [ ] In-game configuration editor for Studio
- [ ] Enhance room detection capabilities:
  - [ ] Semantic room identification based on equipment types
  - [ ] Zone-based room boundaries
  - [ ] Floor plan optimization suggestions
- [ ] Improve build order visualization:
  - [ ] Interactive build path visualization
  - [ ] Color-coded progression paths
  - [ ] Prerequisite relationship maps
- [ ] Expand automated testing framework:
  - [ ] Enhanced unit and integration test coverage
  - [ ] Performance benchmarks
  - [ ] Stress testing for large tycoons
- [ ] Implement performance optimizations:
  - [ ] Batched processing for equipment setup
  - [ ] Optimized bounding box calculations
  - [ ] Tiered loading system for large tycoons
- [ ] Create developer tools:
  - [ ] Debugging console for real-time system monitoring
  - [ ] Visual indicators for system states
  - [ ] Advanced logging capabilities

For detailed implementation schedule and tasks, see [ConsolidationPhase6.md](Documentation/ConsolidationPhase6.md)

## Core Module Responsibilities

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

## Core Module Responsibilities

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

## Achievement Milestones
- ✅ **Phase 1:** Created consolidated modules (April 1, 2025)
- ✅ **Phase 2:** Updated main automation script (April 5, 2025)
- ✅ **Phase 3:** Completed data migration (April 12, 2025)
- ✅ **Phase 4:** Finished testing & validation (April 18, 2025)
- ✅ **Phase 5:** Deprecated old scripts (April 25, 2025)
- 🔄 **Phase 6:** System enhancement & expansion (In Progress, due July 9, 2025)

## Next Steps
- Complete all tasks in Phase 6 (see [ConsolidationPhase6.md](Documentation/ConsolidationPhase6.md))
- Plan for integration with other systems (UI, Analytics, etc.)
- Consider supporting third-party extensions
- Evaluate potential framework extraction for reuse in other tycoon games