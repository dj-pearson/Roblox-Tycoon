# TileValidator Module Documentation

## Overview

The `TileValidator` module provides a comprehensive validation system for tycoon tiles and gym parts. It ensures tiles are correctly positioned, sized, and attached to the appropriate parts of the tycoon. The module was created to fix the "Tile Building Issues" and related problems reported in the game.

## Features

- **Tile Validation**: Validates tile properties and positioning
- **Gym Part Validation**: Verifies gym parts are properly placed on tiles
- **Automatic Fixing**: Attempts to fix common issues automatically
- **Validation Reporting**: Generates reports of validation failures
- **Event System Integration**: Fires events on validation success and failure
- **Debugging Tools**: Provides debugging visualization for invalid tiles
- **Performance Optimization**: Efficient validation methods for high tile counts

## API Reference

### Initialization

#### `TileValidator.initialize()`
Initializes the TileValidator module. Sets up event handlers and internal state.

**Returns:**
- `boolean`: `true` if initialization was successful

**Example:**
```lua
TileValidator.initialize()
```

### Tile Validation

#### `TileValidator.validateTile(tile, options)`
Validates a specific tile against requirements.

**Parameters:**
- `tile` (Instance): The tile to validate
- `options` (table, optional): Validation options
  - `autoFix` (boolean): Whether to attempt to fix issues automatically
  - `debug` (boolean): Whether to show debug visualization
  - `strict` (boolean): Whether to use strict validation rules
  - `validateGymParts` (boolean): Whether to validate gym parts on the tile

**Returns:**
- `boolean, table`: Success status and table of issues found

**Example:**
```lua
local success, issues = TileValidator.validateTile(tile, {
    autoFix = true,
    validateGymParts = true
})

if not success then
    for _, issue in ipairs(issues) do
        print(issue.message)
    end
end
```

#### `TileValidator.validateAllTiles(player, options)`
Validates all tiles in a player's tycoon.

**Parameters:**
- `player` (Player): The player whose tycoon to validate
- `options` (table, optional): Same options as validateTile

**Returns:**
- `boolean, table`: Success status and table of issues found grouped by tile

**Example:**
```lua
local success, allIssues = TileValidator.validateAllTiles(player, {
    autoFix = true
})

print("Validation " .. (success and "passed" or "failed") .. 
      " with " .. #allIssues .. " tiles having issues")
```

### Gym Part Validation

#### `TileValidator.validateGymPart(gymPart, tile)`
Validates a gym part's placement on a tile.

**Parameters:**
- `gymPart` (Instance): The gym part to validate
- `tile` (Instance): The tile the gym part should be attached to

**Returns:**
- `boolean, table`: Success status and table of issues found

**Example:**
```lua
local success, issues = TileValidator.validateGymPart(gymPart, tile)
```

#### `TileValidator.validateGymPartById(gymPartId, player)`
Validates a gym part by its ID across a player's tycoon.

**Parameters:**
- `gymPartId` (string): ID of the gym part to validate
- `player` (Player): The player whose tycoon to check

**Returns:**
- `boolean, table`: Success status and table of issues found

**Example:**
```lua
local success, issues = TileValidator.validateGymPartById("TreadmillPro", player)
```

### Automatic Fixing

#### `TileValidator.fixTile(tile)`
Attempts to fix common issues with a tile.

**Parameters:**
- `tile` (Instance): The tile to fix

**Returns:**
- `boolean, table`: Success status and list of fixes applied

**Example:**
```lua
local success, fixes = TileValidator.fixTile(tile)
if success then
    for _, fix in ipairs(fixes) do
        print("Applied fix: " .. fix)
    end
end
```

#### `TileValidator.fixGymPart(gymPart, tile)`
Attempts to fix common issues with a gym part's placement.

**Parameters:**
- `gymPart` (Instance): The gym part to fix
- `tile` (Instance): The tile the gym part should be attached to

**Returns:**
- `boolean, table`: Success status and list of fixes applied

**Example:**
```lua
local success, fixes = TileValidator.fixGymPart(gymPart, tile)
```

### Utility Functions

#### `TileValidator.getRequiredTileSize(tileId)`
Gets the required size for a specific tile type.

**Parameters:**
- `tileId` (string): ID of the tile type

**Returns:**
- `Vector3`: The required size for the tile

**Example:**
```lua
local requiredSize = TileValidator.getRequiredTileSize("GymFloor")
```

#### `TileValidator.getTileRequirements(tileId)`
Gets all validation requirements for a specific tile type.

**Parameters:**
- `tileId` (string): ID of the tile type

**Returns:**
- `table`: Table of requirements for the tile

**Example:**
```lua
local requirements = TileValidator.getTileRequirements("EntranceTile")
```

#### `TileValidator.markTile(tile, status, duration)`
Temporarily marks a tile with a colored highlight for debugging.

**Parameters:**
- `tile` (Instance): The tile to mark
- `status` (string): Status color ("valid", "invalid", "warning")
- `duration` (number): How long to show the mark (in seconds)

**Example:**
```lua
TileValidator.markTile(tile, "warning", 5)
```

### Validation Reports

#### `TileValidator.generateValidationReport(player)`
Generates a detailed validation report for a player's tycoon.

**Parameters:**
- `player` (Player): The player whose tycoon to validate

**Returns:**
- `table`: A comprehensive validation report

**Example:**
```lua
local report = TileValidator.generateValidationReport(player)
print("Tiles checked: " .. report.tilesChecked)
print("Issues found: " .. report.issueCount)
```

## Events

When integrated with EventBridge, the TileValidator fires the following events:

- **TileValidator_ValidationError**: Fired when a tile fails validation
- **TileValidator_ValidationPassed**: Fired when a tile passes validation
- **TileValidator_TileFixed**: Fired when a tile is automatically fixed
- **TileValidator_GymPartError**: Fired when a gym part fails validation

## Configuration

The TileValidator uses the following configuration parameters, which can be adjusted:

### Tile Requirements

```lua
TileValidator.TILE_REQUIREMENTS = {
    DEFAULT = {
        minSize = Vector3.new(4, 1, 4),
        maxSize = Vector3.new(16, 2, 16),
        allowedMaterials = { 
            Enum.Material.Concrete, 
            Enum.Material.Plastic,
            Enum.Material.SmoothPlastic
        },
        mustBeAnchored = true,
        maxTiltAngle = 5, -- degrees
    },
    
    -- Specific tile types can override defaults
    EntranceTile = {
        minSize = Vector3.new(8, 1, 8),
        requiredMaterial = Enum.Material.Marble
    }
}
```

### Gym Part Requirements

```lua
TileValidator.GYM_PART_REQUIREMENTS = {
    DEFAULT = {
        mustBeCentered = true,
        maxOffsetFromCenter = 2,
        maxCollisionOverhang = 0.2,
    }
}
```

## Integration with Other Systems

### CoreRegistry Integration

The TileValidator automatically registers with the CoreRegistry:

```lua
local CoreRegistry = safeRequire(findModule("CoreRegistry"))
if CoreRegistry and CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("TileValidator", TileValidator)
end
```

### EventBridge Integration

The TileValidator integrates with the EventBridge:

```lua
if EventBridge.registerEvent then
    EventBridge.registerEvent("TileValidator_ValidationError")
    EventBridge.registerEvent("TileValidator_ValidationPassed")
    EventBridge.registerEvent("TileValidator_TileFixed")
    EventBridge.registerEvent("TileValidator_GymPartError")
end
```

## Best Practices

1. **Validate Early and Often**: Run validation when tiles are created or modified
2. **Use Autofix for Minor Issues**: Enable autoFix for non-critical validation
3. **Create Detailed Error Logs**: Use the validation results for debugging
4. **Perform Batch Validations**: For efficiency, validate multiple tiles at once
5. **Listen for Validation Events**: Respond appropriately to validation failures
6. **Use Strict Mode During Development**: Enable strict mode to catch all issues

## Performance Considerations

- Validation can be performance-intensive with many tiles
- Use `validateAllTiles` sparingly, especially with many players
- Consider validating in batches or on a schedule instead of all at once
- Disable debug visualization in production environments

## Common Issues and Solutions

### Issue: Tiles Failing Validation

**Possible causes:**
- Incorrect tile sizing
- Improper tile materials
- Excessive tile rotation
- Overlapping tiles

**Solutions:**
- Use `getRequiredTileSize` to get correct sizing
- Consult `TILE_REQUIREMENTS` for allowed materials
- Use `fixTile` to automatically correct minor issues
- Check for overlapping tiles in the validator report

### Issue: Gym Parts Misplaced

**Possible causes:**
- Gym parts not centered on tiles
- Gym parts floating above tiles
- Gym parts overlapping tile boundaries

**Solutions:**
- Use `validateGymPart` to specifically check gym parts
- Enable autoFix to automatically center parts
- Ensure the primary part of gym part models is properly set
- Use `markTile` to visualize issues during development

### Issue: Performance Impact from Validation

**Possible causes:**
- Too many tiles being validated simultaneously
- Debug visualization enabled in production
- Excessive automatic fixing attempts

**Solutions:**
- Validate only when necessary
- Disable debug options in production
- Implement throttling or batching for validation
- Optimize the game's overall tile structure

## Version History

- **1.0.0**: Initial release with core functionality
