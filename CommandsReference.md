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
8. [Model Validation Commands](#model-validation-commands)
9. [Configuration Generation Commands](#configuration-generation-commands)
10. [Developer Utility Commands](#developer-utility-commands)

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

## Model Validation Commands

Commands for validating models in the gym tycoon and identifying potential issues.

### `_G.ValidateGymModels(tycoonName)`

Validates all models in a tycoon for common issues including missing PrimaryPart, unanchored parts, excessive part counts, naming convention violations, and missing required attributes.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to validate. If not provided, uses the first tycoon found.

**Example:**
```lua
_G.ValidateGymModels("GymParts")
```

**Returns:** A results table with validation statistics and detailed issues for each problematic model. Also tags models with issues using CollectionService.

### `_G.GenerateModelReport(tycoonName)`

Generates a comprehensive validation report for all models in a tycoon, formatted for easy reading.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to validate. If not provided, uses the first tycoon found.

**Example:**
```lua
_G.GenerateModelReport("GymParts")
```

**Returns:** A formatted string report of all model validation issues. Also prints the report to output.

### `_G.FixModelIssues(tycoonName, autoFix)`

Attempts to fix common model issues automatically.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to fix. If not provided, uses the first tycoon found.
- `autoFix` (boolean): Whether to automatically fix issues without prompting (default: false).

**Example:**
```lua
_G.FixModelIssues("GymParts", true)
```

**Returns:** Report of issues fixed and issues that require manual intervention.

**Implementation details:** This command uses the ModelValidator module to identify issues and then attempts to fix common problems like:
- Setting PrimaryPart for models without one
- Anchoring unanchored parts in structures
- Adding missing required attributes with default values
- Fixing naming convention violations by renaming models

## Configuration Generation Commands

Commands for automatically generating configuration tables from placed models.

### `_G.GenerateEquipmentConfig(tycoonName, options)`

Extracts attributes from equipment models and generates a configuration table for runtime systems.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to process. If not provided, uses the first tycoon found.
- `options` (table, optional): Configuration options including:
  - `categoryFilter` (string): Filter to a specific equipment category.
  - `strict` (boolean): Whether to enforce required attributes (default: true).
  - `output` (string): Output format - "table", "module", or "json" (default: "table").
  - `moduleName` (string): Name of the generated module script (default: "EquipmentConfig").

**Example:**
```lua
_G.GenerateEquipmentConfig("GymParts", {
    categoryFilter = "CARDIO",
    output = "module",
    moduleName = "CardioEquipmentConfig"
})
```

**Returns:** Configuration table or path to created module/file.

**Implementation details:** Uses the ConfigGenerator module to extract attributes from models and transform them into a structured data format. The generated configuration can be used by runtime systems instead of manually maintained data tables.

### `_G.DetectUpgradePaths(tycoonName, options)`

Automatically detects upgrade paths between related equipment based on attributes or naming conventions.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to process. If not provided, uses the first tycoon found.
- `options` (table, optional): Configuration options including:
  - `detectFromNames` (boolean): Whether to detect upgrade paths from naming patterns (default: true).
  - `applyAttributes` (boolean): Whether to add missing UpgradesTo/UpgradesFrom attributes (default: false).
  - `applyTags` (boolean): Whether to apply CollectionService tags for upgrade relationships (default: false).
  - `debug` (boolean): Whether to print detailed information about detected paths (default: true).
  - `generateModule` (boolean): Whether to create a ModuleScript with upgrade data (default: false).
  - `moduleName` (string): Name for the generated module (default: "UpgradePathsData").

**Example:**
```lua
_G.DetectUpgradePaths("GymParts", {
    detectFromNames = true,
    applyAttributes = true,
    applyTags = true,
    generateModule = true
})
```

**Returns:** Table with detected upgrade paths and statistics on paths found.

**Implementation details:** Uses the UpgradePathDetector module to identify related equipment by analyzing naming patterns (e.g., Treadmill_1, Treadmill_2) or existing upgrade attributes. The system supports multiple naming schemes including numeric suffixes (_1, _2), mark variants (_Mk1, _Mk2), version variants (_V1, _V2), and tier-based names (_Basic, _Premium).

### `_G.ApplyCollectionTags(tycoonName, options)`

Automatically applies CollectionService tags to models based on their attributes and characteristics.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to process. If not provided, uses the first tycoon found.
- `options` (table, optional): Configuration options including:
  - `tagCategories` (boolean): Whether to tag by category (default: true).
  - `tagFloors` (boolean): Whether to tag by floor (default: true).
  - `tagRooms` (boolean): Whether to tag by room (default: false).
  - `tagProperties` (boolean): Whether to tag based on special properties (default: true).
  - `tagInteractions` (boolean): Whether to tag interactive elements (default: true).
  - `tagFunctional` (boolean): Whether to tag functional elements like hitboxes (default: true).
  - `debug` (boolean): Whether to print tag summary (default: true).
  - `customTags` (table): Table of custom tag rules.

**Example:**
```lua
_G.ApplyCollectionTags("GymParts", {
    tagCategories = true,
    tagFloors = true,
    tagRooms = true,
    customTags = {
        {attribute = "Price", value = 1000, compare = function(a, b) return a > b end, tag = "ExpensiveEquipment"},
        {attribute = "IncomeBoost", value = 50, compare = function(a, b) return a > b end, tag = "HighIncomeEquipment"}
    }
})
```

**Returns:** Table with statistics on tags applied.

**Implementation details:** Uses the TaggingSystem module to apply CollectionService tags based on model attributes. The system automatically creates tags for categories (e.g., CardioEquipment, StrengthEquipment), floors (Floor_1, Floor_2), and special properties (GeneratesRevenue, AffectsSatisfaction). These tags can be used at runtime to efficiently query for specific types of objects without expensive hierarchy searches.

## Developer Utility Commands

Advanced utility functions for development workflows, analysis, and troubleshooting.

### `_G.BatchProcessModels(tycoonName, processingFunction, options)`

Applies a custom processing function to all models in a tycoon.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to process. If not provided, uses the first tycoon found.
- `processingFunction` (function): Function to apply to each model. Receives `(model, options)` as parameters.
- `options` (table, optional): Options to pass to the processing function.

**Example:**
```lua
_G.BatchProcessModels("GymParts", function(model, options)
    -- Apply custom logic to each model
    if model:GetAttribute("Category") == "CARDIO" then
        model:SetAttribute("MaintenanceCost", model:GetAttribute("Price") * 0.05)
        return true -- Return value is collected in results table
    end
    return false
end)
```

**Returns:** Table of results indexed by model name.

### `_G.GenerateModelStats(tycoonName, options)`

Generates detailed statistics about models in a tycoon including part counts, memory usage, and other performance metrics.

**Parameters:**
- `tycoonName` (string, optional): Name of the tycoon to analyze.
- `options` (table, optional):
  - `detailed` (boolean): Whether to include detailed per-model stats
  - `categoryBreakdown` (boolean): Whether to break down stats by category
  - `export` (string): Export format - "print", "table", or "file"

**Example:**
```lua
_G.GenerateModelStats("GymParts", {
    detailed = true,
    categoryBreakdown = true,
    export = "print"
})
```

**Returns:** Table of statistics and prints a formatted report.

### `_G.CompareConfigWithModels(configModule, tycoonName, options)`

Compares an existing configuration module against the actual models in the workspace, detecting inconsistencies.

**Parameters:**
- `configModule` (string or ModuleScript): Name of config module or the module itself.
- `tycoonName` (string, optional): Name of the tycoon to compare with.
- `options` (table, optional):
  - `strict` (boolean): Whether to enforce strict matching (default: false)
  - `autoFix` (boolean): Whether to automatically fix minor issues (default: false)

**Example:**
```lua
_G.CompareConfigWithModels("EquipmentConfig", "GymParts", {
    strict = false,
    autoFix = true
})
```

**Returns:** Table of inconsistencies found including missing models, extra models, and attribute mismatches.

### `_G.ExportCollectionServiceTags(outputFormat, containerName)`

Exports a list of all CollectionService tags used in the game, with usage statistics.

**Parameters:**
- `outputFormat` (string, optional): Format to output the tags
  - "table" (default), "print", "module", or "json"
- `containerName` (string, optional): Name of container to export tags from
  - If not provided, exports all tags in the workspace

**Example:**
```lua
_G.ExportCollectionServiceTags("module", "GymParts")
```

**Returns:** Table of tags or path to output file/module.

### `_G.SetupTargetHardware(profile, customSettings)`

Sets up performance test parameters based on target hardware profiles for development and testing.

**Parameters:**
- `profile` (string): Target hardware profile
  - "low", "medium", "high", or "custom"
- `customSettings` (table, optional): Custom settings to apply when using "custom" profile

**Example:**
```lua
_G.SetupTargetHardware("low")

-- Or with custom settings:
_G.SetupTargetHardware("custom", {
    maxParts = 3000,
    maxTriangles = 150000,
    renderDistance = 750,
    maxLights = 6
})
```

**Returns:** Table of applied settings.

### `_G.GenerateUIConfig(uiContainer, options)`

Extracts properties from UI elements to create a configuration module for runtime use.

**Parameters:**
- `uiContainer` (Instance or string): UI container to analyze
  - If not provided, will look in StarterGui
- `options` (table, optional):
  - `output` (string): Output format - "module" (default) or "table"
  - `moduleName` (string): Name for the generated module

**Example:**
```lua
_G.GenerateUIConfig("MainUI", {
    output = "module",
    moduleName = "MainUIConfig"
})
```

**Returns:** UI configuration data or module.

### `_G.InitializeDevelopmentEnvironment(options)`

Sets up all required systems and tools for development. Particularly useful when onboarding new team members to the project.

**Parameters:**
- `options` (table, optional):
  - `cleanStart` (boolean): Whether to clean existing settings first
  - `setupPlugins` (boolean): Whether to install recommended plugins
  - `loadTestData` (boolean): Whether to load test data

**Example:**
```lua
_G.InitializeDevelopmentEnvironment({
    cleanStart = true,
    setupPlugins = true,
    loadTestData = true
})
```

**Returns:** Status of initialization with success/failure information.

**Implementation details:** This command creates a consistent development environment by initializing core systems, setting up debug configurations, and configuring recommended plugins. It also runs initial validation on models if a tycoon is present in the workspace.

## Recommended Workflow

For a typical development workflow, here is a recommended sequence of commands:

1. **Process the tycoon structure**: `_G.ProcessTycoon()`
2. **Review room information**: `_G.ShowRoomInfo()`
3. **Set proper room types**: `_G.SetRoomType()` for each room that needs adjustment
4. **Process equipment**: `_G.ProcessEquipment()`
5. **Validate models**: `_G.ValidateGymModels()` and review the report
6. **Fix model issues**: Address any issues identified in the validation report
7. **Generate equipment configuration**: `_G.GenerateEquipmentConfig()`
8. **Detect upgrade paths**: `_G.DetectUpgradePaths()`
9. **Apply Collection Tags**: `_G.ApplyCollectionTags()`
10. **Generate build order**: `_G.GenerateBuildOrder()`
11. **Generate hitboxes**: `_G.GenerateHitboxes()`
12. **Show hitboxes to verify**: `_G.ShowHitboxes()`
13. **Review final tycoon info**: `_G.ShowTycoonInfo()`

Alternatively, use the all-in-one automation: `_G.AutomateGym()` or `_G.AutomateGymTycoon()`

## Notes

- Most commands will work with either a specific tycoon name provided or will default to looking for "GymParts" or "Tycoon" in the workspace.
- All functions are designed to work in Studio mode only.
- When customizing room types, refer to the allowed room types defined in the `CONFIG.ROOM_TYPES` table in the FloorAttributeSetup module.