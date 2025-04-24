# Gym Automation System Migration Guide

## Important Notice
**The old gym automation scripts will be removed on June 30, 2025.**

This document provides detailed instructions on how to migrate from the old gym automation scripts to the new consolidated module system.

## Why Are We Consolidating?
The new consolidated module system offers several benefits:
- **Reduced code duplication** - Common functionality is now in shared modules
- **Improved performance** - More efficient and optimized code
- **Enhanced maintainability** - Better organized code structure
- **More robust error handling** - Comprehensive validation and error states
- **Better extensibility** - Easier to add new features

## Migration Timeline
- **Phase 1-4**: System development and testing (Completed)
- **Phase 5**: Deprecation period (Current phase)
- **June 30, 2025**: Old scripts will be removed

## Old Scripts and Their Replacements

| Old Script | Replacement Module | Notes |
|------------|-------------------|-------|
| `EquipmentSetup.server.luau` | `EquipmentManager.server.luau` | Equipment initialization and attributes |
| `EquipmentUpgradeSystem.server.luau` | `EquipmentManager.server.luau` | Equipment upgrade functionality |
| `BoundingBoxGenerator.server.luau` | `BoundingBoxManager.server.luau` | Hitbox generation for tiles |
| `EquipmentBoundingBox.luau` | `BoundingBoxManager.server.luau` | Equipment interaction zones |

## How to Migrate

### Step 1: Access the New Modules
The new consolidated modules are available through the CoreRegistry system:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local coreFolder = ServerScriptService:FindFirstChild("Core")
local CoreRegistry = require(coreFolder:FindFirstChild("CoreRegistry"))

-- Get the new modules
local EquipmentManager = CoreRegistry:GetSystem("EquipmentManager")
local BoundingBoxManager = CoreRegistry:GetSystem("BoundingBoxManager")
local BuyTileProgressionManager = CoreRegistry:GetSystem("BuyTileProgressionManager")
local TileDataGenerator = CoreRegistry:GetSystem("TileDataGenerator")
```

### Step 2: Replace Function Calls

#### From EquipmentSetup to EquipmentManager

| Old Function | New Function | Example |
|------------|-------------------|-------|
| `EquipmentSetup.SetupEquipment(model)` | `EquipmentManager:ProcessEquipment(model)` | `local attrs = EquipmentManager:ProcessEquipment(treadmill)` |
| `EquipmentSetup.ProcessGymEquipment(folder)` | `EquipmentManager:ProcessAllEquipment(folder)` | `EquipmentManager:ProcessAllEquipment(workspace.Tycoon)` |
| `EquipmentSetup.GetEquipmentCategory(model)` | `EquipmentManager:DetectEquipmentCategory(model)` | `local category = EquipmentManager:DetectEquipmentCategory(model)` |

#### From EquipmentUpgradeSystem to EquipmentManager

| Old Function | New Function | Example |
|------------|-------------------|-------|
| `EquipmentUpgradeSystem.UpgradeEquipment(model)` | `EquipmentManager:UpgradeEquipment(model)` | `local success = EquipmentManager:UpgradeEquipment(treadmill)` |
| `EquipmentUpgradeSystem.GetUpgradeInfo(model)` | `EquipmentManager:GetNextUpgradeInfo(model)` | `local info = EquipmentManager:GetNextUpgradeInfo(treadmill)` |
| `EquipmentUpgradeSystem.GetUpgradePrice(model)` | `local info = EquipmentManager:GetNextUpgradeInfo(model); local price = info and info.price or 0` | See example |

#### From BoundingBoxGenerator to BoundingBoxManager

| Old Function | New Function | Example |
|------------|-------------------|-------|
| `BoundingBoxGenerator.CalculateBoundingBox(model)` | `BoundingBoxManager:CalculateBoundingBox(model)` | `local bbox = BoundingBoxManager:CalculateBoundingBox(model)` |
| `BoundingBoxGenerator.CreateBuyHitbox(tile)` | `BoundingBoxManager:CreateHitbox(tile)` | `local hitbox = BoundingBoxManager:CreateHitbox(tile)` |
| `BoundingBoxGenerator.ShowHitboxes()` | `BoundingBoxManager:SetHitboxesVisible(true)` | `BoundingBoxManager:SetHitboxesVisible(true)` |
| `BoundingBoxGenerator.HideHitboxes()` | `BoundingBoxManager:SetHitboxesVisible(false)` | `BoundingBoxManager:SetHitboxesVisible(false)` |

## New Features Available

### Build Order and Progression
The new `BuyTileProgressionManager` provides tools to manage tycoon progression:

```lua
-- Generate build order for a tycoon
local buildOrder = BuyTileProgressionManager:GetBuildOrder(tycoon)

-- Check prerequisites for a tile
local prerequisites = BuyTileProgressionManager:GetTilePrerequisites(tile)

-- Check if a tile is unlockable
local isUnlockable = BuyTileProgressionManager:IsTileUnlockable(tile)

-- Get prerequisites for unlocking a floor
local floorPrereqs = BuyTileProgressionManager:GetFloorPrerequisites(floor)
```

### Generating Tile Data
The new `TileDataGenerator` helps with generating consistent tile data:

```lua
-- Generate data for a tile
local tileData = TileDataGenerator:GenerateTileData(model)

-- Extract attributes from a model
local attributes = TileDataGenerator:ExtractModelAttributes(model)

-- Apply a template to a model
TileDataGenerator:ApplyTemplateToModel(model, "treadmill")
```

## Testing and Validation

You can use these global Studio functions for testing:

```lua
-- Run test suite to verify all modules
_G.RunTestSuite()

-- Validate your tycoons
_G.ValidateTycoons()

-- Visualize build order progression
_G.ShowBuildOrder()

-- Test migrated data
_G.RunMigrationTests()
```

## Handling Migration Issues

If you encounter issues during migration:

1. Check the output warnings for details
2. Use `_G.GetDeprecationTelemetry()` to identify which deprecated functions are still being used
3. Run `_G.ValidateTycoons()` to find any configuration issues
4. For data migration issues, check the validation functions in `MigrationUtils.server.luau`

## Need More Help?

- Check the API documentation in the developer hub
- Use the test tools to validate your implementation
- Look at the example implementations in the documentation

## Common Migration Patterns

### Example 1: Setting up gym equipment

**Old code:**
```lua
local EquipmentSetup = require(ServerScriptService.EquipmentSetup)
local EquipmentUpgradeSystem = require(ServerScriptService.EquipmentUpgradeSystem)

-- Process equipment
for _, equipment in ipairs(workspace.Tycoon:GetDescendants()) do
    if equipment:IsA("Model") and equipment:GetAttribute("Category") == "CARDIO" then
        EquipmentSetup.SetupEquipment(equipment)
        
        -- Check for upgrades
        local upgradeInfo = EquipmentUpgradeSystem.GetUpgradeInfo(equipment)
        if upgradeInfo then
            print("Next upgrade: " .. upgradeInfo.level)
        end
    end
end
```

**New code:**
```lua
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
local EquipmentManager = CoreRegistry:GetSystem("EquipmentManager")

-- Process equipment (more efficiently)
EquipmentManager:ProcessAllEquipment(workspace.Tycoon)

-- Or process individual equipment if needed
for _, equipment in ipairs(workspace.Tycoon:GetDescendants()) do
    if equipment:IsA("Model") and equipment:GetAttribute("Category") == "CARDIO" then
        -- Get upgrade info
        local upgradeInfo = EquipmentManager:GetNextUpgradeInfo(equipment)
        if upgradeInfo then
            print("Next upgrade: " .. upgradeInfo.level)
        end
    end
end
```

### Example 2: Creating hitboxes

**Old code:**
```lua
local BoundingBoxGenerator = require(ServerScriptService.BoundingBoxGenerator)
local EquipmentBoundingBox = require(ServerScriptService.EquipmentBoundingBox)

-- Create buy hitbox
local hitbox = BoundingBoxGenerator.CreateBuyHitbox(tile)

-- Create equipment interaction
local interactionZone = EquipmentBoundingBox.CreateInteractionBox(equipment)
```

**New code:**
```lua
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
local BoundingBoxManager = CoreRegistry:GetSystem("BoundingBoxManager")

-- Create buy hitbox
local hitbox = BoundingBoxManager:CreateHitbox(tile)

-- Create equipment interaction
local interactionZone = BoundingBoxManager:CreateEquipmentInteractionBox(equipment)
```

## Migration Checklist

- [ ] Replace `EquipmentSetup` calls with `EquipmentManager` equivalents
- [ ] Replace `EquipmentUpgradeSystem` calls with `EquipmentManager` equivalents
- [ ] Replace `BoundingBoxGenerator` calls with `BoundingBoxManager` equivalents
- [ ] Replace `EquipmentBoundingBox` calls with `BoundingBoxManager` equivalents
- [ ] Test your implementation with `_G.RunTestSuite()`
- [ ] Validate your tycoons with `_G.ValidateTycoons()`
- [ ] Remove any direct references to deprecated modules
