# DataStore Plugin Fix Documentation

## Overview

This document describes the fixes applied to the DataStore Plugin to prevent stack overflows and address module reference issues when running in Argon.

## Issues Fixed

1. **Module References with `.server` Extensions**
   - Files were using `.server` in require statements, which doesn't work in Roblox
   - These were converted to direct references without the extension

2. **FindFirstChild Usage**
   - Using `FindFirstChild` for module references was causing potential issues
   - These were replaced with direct property access

3. **Re-export Files**
   - The re-export files now use a simplified pattern that doesn't cause stack overflows
   - They use `return require(script.server)` instead of complex logic

## How the Fix Works

### 1. Server Script References
All server scripts now use direct references to other modules:

```lua
-- Before (problematic)
local Module = require(script.Parent.ModuleName.server)
-- or
local Module = require(script.Parent:FindFirstChild("ModuleName"))

-- After (fixed)
local Module = require(script.Parent.ModuleName)
```

### 2. Re-export Files
Non-server modules that need to reference server modules use this pattern:

```lua
-- DataStore Plugin/ModuleName.luau
-- Simple re-export to server version

return require(script.server)
```

### 3. init.server.luau
The main entry point now uses direct references:

```lua
local Module = require(script.ModuleName)
```

## Roblox Sync Behavior

When syncing to Roblox:
- `ModuleName.server.luau` becomes a ServerScript named `ModuleName`
- `ModuleName.luau` becomes a ModuleScript named `ModuleName`

Inside a ModuleScript, `script.server` will correctly reference the ServerScript with the same base name.

## Maintaining the Codebase

When adding new modules to the DataStore Plugin:

1. For server-specific modules:
   - Create a `ModuleName.server.luau` file
   - Create a simple re-export `ModuleName.luau` file using the pattern above

2. For referencing modules:
   - Always use `require(script.Parent.ModuleName)` without the `.server` suffix
   - In `init.server.luau`, use `require(script.ModuleName)`

## Testing

After applying these fixes, the DataStore Plugin should:
- Load properly in Argon without stack overflows
- Maintain all functionality
- Have consistent module access patterns

---

Created: May 7, 2025
