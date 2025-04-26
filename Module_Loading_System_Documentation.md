# Module Loading System Documentation

## Overview

The Module Loading System provides a standardized way to load modules throughout the game, with robust error handling and fallback mechanisms. This system is designed to prevent common issues such as:

- Missing module references
- Infinite yield on WaitForChild
- Cascading failures when modules can't be found
- Difficulty in refactoring module paths

## Key Components

### 1. ModuleLoader

The core utility for loading modules across the game. It provides a centralized way to load modules by name, with configurable search paths and fallback behavior.

```lua
-- Get access to the ModuleLoader
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)

-- Load a module
local UIStyle = ModuleLoader:LoadModule("UIStyle")
```

### 2. SafeRequire

A utility function for safely requiring modules with error handling to prevent script failures when modules can't be loaded.

```lua
local SafeRequire = require(game:GetService("ReplicatedStorage").shared.SafeRequire)

-- Safely require a module
local MyModule = SafeRequire(game.ReplicatedStorage.shared.MyModule)

-- Safely require with fallback
local ConfigModule = SafeRequire(game.ReplicatedStorage.Config, {
    defaultValue = 100,
    otherSetting = true
})
```

### 3. SafeWaitForChild

A utility for safely waiting for children with timeout handling to prevent infinite yield issues.

```lua
local SafeWaitForChild = require(game:GetService("ReplicatedStorage").shared.SafeWaitForChild)

-- Wait for a child with a 5-second timeout (default)
local child = SafeWaitForChild.waitForChild(parent, "ChildName") 

-- Wait for a child with custom timeout
local child = SafeWaitForChild.waitForChild(parent, "ChildName", 10)

-- Wait for a descendant (multilevel)
local descendant = SafeWaitForChild.waitForDescendant(parent, "Child.Grandchild.Target")
```

## Using the Module Loading System

### Basic Module Loading

```lua
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)

-- Load a module by name (searches through configured paths)
local DataStore = ModuleLoader:LoadModule("DataStore")

-- Load with a fallback if the module isn't found
local UIStyle = ModuleLoader:LoadModule("UIStyle", {
    colors = {
        background = Color3.fromRGB(40, 40, 60),
        text = Color3.fromRGB(240, 240, 240)
    }
})
```

### Registering Search Paths

```lua
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)

-- Register a new search path
ModuleLoader:RegisterPath("ServerSystems", game:GetService("ServerStorage").Systems)

-- Now you can load modules from the new path
local LeaderboardSystem = ModuleLoader:LoadModule("LeaderboardSystem")
```

### Creating Module Aliases

Aliases allow you to refer to modules by a different name, which is useful for refactoring or providing shorter names for commonly used modules.

```lua
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)

-- Create an alias
ModuleLoader:RegisterAlias("UI", "UIComponents")

-- Now you can load the module using its alias
local UI = ModuleLoader:LoadModule("UI")
```

### Handling Module Dependencies

With the ModuleLoader system, modules can easily depend on other modules:

```lua
-- Inside a module script
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)

local MyModule = {}

-- Load dependencies
local DataStore = ModuleLoader:LoadModule("DataStore")
local EventBridge = ModuleLoader:LoadModule("EventBridge")

function MyModule:Initialize()
    -- Use loaded dependencies
    DataStore:Connect()
    EventBridge:RegisterEvent("MyEvent", function() end)
end

return MyModule
```

## Best Practices

1. **Always use ModuleLoader for modules that might be moved/renamed**:
   ```lua
   local UIStyle = ModuleLoader:LoadModule("UIStyle")
   ```

2. **Provide fallbacks for optional dependencies**:
   ```lua
   local Analytics = ModuleLoader:LoadModule("Analytics", { enabled = false })
   ```

3. **Use SafeWaitForChild instead of WaitForChild**:
   ```lua
   local mainFrame = SafeWaitForChild.waitForChild(script.Parent, "MainFrame")
   ```

4. **Create folder structures with SafeWaitForChild**:
   ```lua
   local folder = SafeWaitForChild.createPath(parent, "Systems.UI.Components")
   ```

5. **Use waitForDescendant for multi-level paths**:
   ```lua
   local button = SafeWaitForChild.waitForDescendant(gui, "Frame.Container.Button")
   ```

6. **Register commonly used paths in ModuleLoader**:
   ```lua
   ModuleLoader:RegisterPath("ServerSystems", game:GetService("ServerStorage").Systems)
   ModuleLoader:RegisterPath("ClientUI", game:GetService("ReplicatedStorage").UI)
   ```

## Compatibility with Existing Code

The Module Loading System is designed to be compatible with existing code. You can gradually migrate to the new system without breaking existing modules.

### Converting Existing Code:

From:
```lua
local module = require(game:GetService("ReplicatedStorage"):WaitForChild("MyModule"))
```

To:
```lua
local ModuleLoader = require(game:GetService("ReplicatedStorage").shared.ModuleLoader)
local module = ModuleLoader:LoadModule("MyModule")
```

## Error Handling

The Module Loading System provides comprehensive error handling:

1. **Module not found**: Returns the fallback value if provided, or `nil`
2. **Error during module initialization**: Logs the error and returns the fallback value
3. **Timeout during WaitForChild**: Logs a warning and returns `nil`

Every error is logged to make debugging easier, and the system is designed to fail gracefully rather than breaking the entire game.

## Performance Considerations

The Module Loading System includes caching mechanisms to ensure modules are only loaded once, improving performance, especially for frequently used modules.

```lua
-- First call loads the module
local UIStyle1 = ModuleLoader:LoadModule("UIStyle")

-- Second call returns the cached module (fast)
local UIStyle2 = ModuleLoader:LoadModule("UIStyle")
```

## Diagnostic Tools

The Module Loading System includes diagnostic tools to help identify and fix module loading issues:

1. **ModuleLoader:GetStats()**: Returns statistics about module loading attempts
2. **SafeWaitForChild.getYieldStats()**: Returns statistics about WaitForChild calls
3. **WaitForChildFinder**: A tool to find unsafe WaitForChild calls

## Conclusion

By using the Module Loading System consistently throughout your game, you can eliminate many common issues related to module loading and reference errors, making your game more robust and easier to maintain.
