# Shared Module Consolidation Guide

## Overview

As part of our ongoing efforts to standardize the codebase structure, we are consolidating the shared modules from two locations:

1. `ReplicatedStorage\shared` (the older implementation)
2. `src\shared` (the new standardized implementation mapped via default.project.json)

This guide explains how to safely migrate to using only the standardized implementation.

## Current Setup

In the default.project.json file, we've configured:

```json
"ReplicatedStorage": {
  "Shared": {
    "$path": "src/shared"
  },
  "shared": {
    "$path": "src/shared"
  }
}
```

This means both `ReplicatedStorage.Shared` (capital S) and `ReplicatedStorage.shared` (lowercase s) point to the same folder in the file system: `src/shared`.

## Why Consolidate?

1. **Code duplication**: Having modules in two places leads to confusion about which version to use
2. **Maintenance burden**: Updates need to be made in multiple places
3. **Inconsistent file access**: Some code uses `ReplicatedStorage.shared` while others use `ReplicatedStorage.Shared`
4. **Potential sync issues**: The actual files in `ReplicatedStorage\shared` might be out of sync with those in `src\shared`

## Addressing Compatibility Issues

The verification script has identified several compatibility issues between modules in `ReplicatedStorage\shared` and `src\shared`:

1. **Different return types**: Some modules in `src\shared` return different types or have different interfaces than their counterparts in `ReplicatedStorage\shared`.

2. **Missing modules**: The SafeRequire module reference is causing errors during validation.

To address these issues, we've created:

1. **ModuleAdapterWrapper**: A utility that wraps modules to ensure compatibility between old and new versions
2. **Module Compatibility Reference**: Documentation detailing interface differences between module versions

## Migration Process

### Step 1: Use the ModuleAdapterWrapper for Transitional Code

For scripts that need to work with both versions during the transition period:

```lua
local ModuleAdapterWrapper = require(ReplicatedStorage.Shared.ModuleAdapterWrapper)

-- Get a compatible version of any module
local UIComponents = ModuleAdapterWrapper.requireCompatible("UIComponents")

-- Now use it with the old interface
local button = UIComponents.CreateButton("Click Me")
```

### Step 2: Run the Verification Script (Updated)

Run the updated verification script to ensure all modules are properly compatible:

```lua
-- In Roblox Studio Command Bar
loadfile("tools/verify_shared_modules.luau")()
```

### Step 3: Run the Migration Helper

The migration helper will:
- Create a backup of the `ReplicatedStorage\shared` folder
- Verify all required modules exist in the new location
- Generate a report with findings and recommendations

```lua
-- In Roblox Studio Command Bar
loadfile("tools/shared_folder_migration.luau")()
```

### Step 4: Update Direct References

If any scripts are directly referencing files in `ReplicatedStorage\shared` using paths like:

```lua
local module = require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleName"))
```

Update them to use:

```lua
local module = require(ReplicatedStorage.shared.ModuleName)
```

### Step 5: Remove the Redundant Folder

Once verification is complete and the report indicates it's safe, you can remove the `ReplicatedStorage\shared` folder.

### Step 6: Standardize Module Interfaces (Long-term)

As a future task, consider standardizing all module interfaces to eliminate the need for the ModuleAdapterWrapper.

## Restoring from Backup

If issues occur after removing the `ReplicatedStorage\shared` folder, the backup can be found in `ServerStorage` with the name format: `backup_shared_YYYYMMDD_HHMMSS`.

## Reference Documents

- [Module Compatibility Reference](ModuleCompatibilityReference.md): Details on interface differences between module versions

## Questions?

Refer to the generated migration report or contact the development team for assistance.
