# Module Compatibility Reference

## Overview

This document outlines the interface differences between the modules in `ReplicatedStorage\shared` and `src\shared`. It serves as a reference for developers during the migration process to ensure all functionality is preserved.

## Module Interface Differences

### AssetValidator

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `validateAsset` | ✅ | ✅ | Different parameter order in new version |
| `preloadAsset` | ✅ | ✅ | Enhanced with better error handling in new version |
| `getAsset` | ✅ | ✅ | New version includes caching system |
| | | `validateMultipleAssets` | New function in new version |
| | | `preloadMultipleAssets` | New function in new version |

### ModuleLoader

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `loadModule` | ✅ | ✅ | Enhanced error handling in new version |
| `getModule` | ✅ | ✅ | Added caching in new version |
| | | `invalidateCache` | New function in new version |
| | | `registerDependency` | New function in new version |
| | | `resolveModulePath` | New function in new version |

### SafeRequire

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `require` | ✅ | ❓ | New version may expose as direct function |
| | | `requireFromPath` | New function in new version |
| | | `requireMultiple` | New function in new version |

### SafeWaitForChild

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `waitForChild` | ✅ | ❓ | New version may expose as direct function |
| | | `waitForDescendant` | New function in new version |
| | | `waitForChildOfClass` | New function in new version |

### UIComponents

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `CreateButton` | ✅ | ✅ | Enhanced styling options in new version |
| `CreateFrame` | ✅ | ✅ | Enhanced styling options in new version |
| `CreateLabel` | ✅ | ✅ | Enhanced styling options in new version |
| | | Multiple new component creators | New version has many additional components |

### UIRegistry

| Function | Old Module | New Module | Notes |
|----------|------------|------------|-------|
| `RegisterComponent` | ✅ | ✅ | Additional metadata options in new version |
| `RegisterScreen` | ✅ | ✅ | Additional transition options in new version |
| `OpenScreen` | ✅ | ✅ | Enhanced with animation options in new version |
| `CloseScreen` | ✅ | ✅ | Enhanced with animation options in new version |
| | | `GetRegisteredComponents` | New function in new version |
| | | `GetActiveScreens` | New function in new version |

## Using the ModuleAdapterWrapper

To ensure compatibility during migration, we've created a `ModuleAdapterWrapper` utility that standardizes interfaces:

```lua
local ModuleAdapterWrapper = require(ReplicatedStorage.Shared.ModuleAdapterWrapper)

-- Get a compatible version of any module
local UIComponents = ModuleAdapterWrapper.requireCompatible("UIComponents")

-- Now use it with the old interface
local button = UIComponents.CreateButton("Click Me")
```

This adapter will handle the interface differences automatically, allowing for a smoother transition while using a single codebase.
