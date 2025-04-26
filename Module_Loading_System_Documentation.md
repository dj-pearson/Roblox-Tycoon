# Module Loading System Documentation

## Overview

The Module Loading System provides a unified approach to loading modules in the Gym Tycoon codebase, ensuring consistent behavior and graceful error handling across both server and client contexts.

## Key Components

1. **ModuleLoader** (`src/shared/ModuleLoader.luau`)
   - Core utility for finding and loading modules
   - Smart path resolution with multiple search strategies
   - Module caching for performance
   - Error handling with optional module support

2. **ModuleLoaderHelper** (`src/shared/ModuleLoaderHelper.luau`) 
   - Higher-level abstraction for common module loading patterns
   - Context-aware (knows if running on server or client)
   - Registry integration (CoreRegistry/ClientRegistry)
   - Support for alternative paths and fallback loading

3. **ModuleLoaderExample** (`src/shared/ModuleLoaderExample.luau`)
   - Template demonstrating best practices for using the module loading system
   - Copy this pattern when creating new modules

## Using the Module Loading System

### Basic Usage

```lua
-- Import ModuleLoaderHelper first
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoaderHelper = require(ReplicatedStorage.shared.ModuleLoaderHelper)

-- Load common systems
local Registry = ModuleLoaderHelper:GetCoreRegistry()
local EventBridge = ModuleLoaderHelper:GetSystem("EventBridge")
local DataManager = ModuleLoaderHelper:GetSystem("DataManager")

-- Your module code here...
```

### Module Template Pattern

1. **Load ModuleLoaderHelper** - Always start by loading ModuleLoaderHelper with fallback support
2. **Load Dependencies** - Use ModuleLoaderHelper to get your dependencies
3. **Define Module** - Create your module with proper initialization and API
4. **Register with Registry** - Register your module with CoreRegistry/ClientRegistry if available

### Advantages

- **Consistent Interface**: Same code works on both server and client sides
- **Error Resilience**: Gracefully handles missing modules without crashing
- **Path Independence**: Doesn't rely on exact folder hierarchy
- **Performance**: Caches modules for efficient repeated access
- **Debugging**: Detailed logging helps track down loading issues

## Common Patterns

### Loading Optional Dependencies

```lua
local OptionalSystem = ModuleLoaderHelper:GetSystem("OptionalSystem")
if OptionalSystem then
    -- Use OptionalSystem
else
    -- Fallback behavior when OptionalSystem isn't available
end
```

### Registering with Registry

```lua
if Registry and typeof(Registry.registerSystem) == "function" then
    Registry:registerSystem("YourModule", YourModule, {
        "DataManager", "EventBridge"  -- Dependencies
    })
end
```

### Event Handling

```lua
-- Connect to an event
ModuleLoaderHelper:ConnectToEvent("ExampleEvent", function(...)
    -- Handle event
end)

-- Fire an event
ModuleLoaderHelper:FireEvent("ExampleEvent", arg1, arg2)
```

## Troubleshooting

If you encounter module loading errors:

1. **Check Path**: Ensure the module exists in one of the search paths
2. **Check Syntax**: Verify your module doesn't have syntax errors
3. **Check Dependencies**: Make sure all required dependencies are loaded first
4. **Check Registry**: Verify the module is registered with CoreRegistry/ClientRegistry if needed
5. **Enable Logging**: Set `DEBUG_LOGGING = true` in ModuleLoader for verbose output

## Best Practices

1. **Always use ModuleLoaderHelper** instead of direct `require()` calls
2. **Check if dependencies exist** before using them
3. **Provide fallbacks** for missing dependencies
4. **Explicitly initialize** your modules
5. **Register with Registry** to make your module available to other systems
6. **Use the ModuleTemplate pattern** for consistent module structure

## Integration with Existing Systems

The Module Loading System works with both the previously fixed CoreRegistry and ClientBootstrap systems to provide a comprehensive solution for module management in the Gym Tycoon codebase.
