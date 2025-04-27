# Registry System Implementation

## Overview

The Registry System has been implemented following the design specifications outlined in our consolidation plan. This system provides a robust, centralized approach to component registration, discovery, and lifecycle management across both client and server contexts.

## Architecture

The Registry System consists of four main components:

1. **RegistryBase** - Core registry functionality shared by all implementations
2. **ClientRegistry** - Client-specific registry with UI and input handling capabilities
3. **ServerRegistry** - Server-specific registry with service and system management
4. **SharedRegistry** - Cross-context registry accessible from both client and server

### Design Principles

- **Centralization**: Single point of truth for component registration
- **Type Safety**: Strong typing for component interfaces
- **Lifecycle Management**: Consistent initialization and cleanup patterns
- **Dependency Tracking**: Automatic dependency resolution and version checking
- **Contextual Awareness**: Components understand their execution context
- **Error Handling**: Robust error detection and reporting

## Implementation Details

### RegistryBase

The base registry class provides:

- Component registration with versioning
- Dependency tracking and resolution
- Lifecycle management (initialize, shutdown)
- Error handling and logging
- Component tagging and metadata

```lua
-- Register a component
local registry = RegistryBase.new("MyRegistry")
registry:register("MyComponent", componentModule, "1.0.0")

-- Get a component with version check
local component = registry:get("MyComponent", "0.5.0") -- Will work since 1.0.0 >= 0.5.0

-- Register with dependencies
registry:registerWithDependencies("DependentComponent", module, "1.0.0", {
    ["MyComponent"] = "1.0.0"
})

-- Initialize all components in dependency order
registry:initializeAll()
```

### ClientRegistry

The client-side registry extends the base with:

- UI component registration and lifecycle management
- Input handling with priority-based processing
- Client-side service discovery
- Automatic component cleanup

```lua
-- Get the singleton instance
local clientRegistry = require(path.to.ClientRegistry).get()

-- Register a UI component
clientRegistry:registerUIComponent("MainMenu", menuComponent, parentFrame)

-- Show/hide UI components
clientRegistry:showUIComponent("MainMenu", 10) -- zIndex 10
clientRegistry:hideUIComponent("MainMenu")

-- Register input handlers
clientRegistry:registerInputHandler("JumpHandler", function(inputObject, gameProcessed)
    -- Handle jump input
    return true -- Return true to mark as handled
end, {
    priority = 10,
    keyboardKeys = {[Enum.KeyCode.Space] = true}
})
```

### ServerRegistry

The server-side registry extends the base with:

- Service registration and lifecycle management
- System registration with interval-based execution
- Remote object management
- Player-specific component tracking

```lua
-- Get the singleton instance
local serverRegistry = require(path.to.ServerRegistry).get()

-- Register a service
serverRegistry:registerService("DataService", dataService, {
    autostart = true,
    remoteObjects = {
        GetData = "function",
        DataUpdated = "event"
    }
})

-- Register a system
serverRegistry:registerSystem("CleanupSystem", cleanupSystem, {
    interval = 60, -- Run every 60 seconds
    autorun = true
})

-- Auto-discover server modules
serverRegistry:discoverAndRegister()
```

### SharedRegistry

The shared registry provides:

- Cross-context component registration
- Context-aware component access
- Utility module management
- Category-based organization

```lua
-- Get the singleton instance
local sharedRegistry = require(path.to.SharedRegistry).get()

-- Register a shared component with explicit context
sharedRegistry:registerShared("MathUtils", mathUtils, {
    context = "both",
    isUtility = true,
    category = "math"
})

-- Get a component safely based on current context
local component = sharedRegistry:getContextSafe("MathUtils")

-- Get components by category
local mathComponents = sharedRegistry:getByCategory("math")
```

## Key Features

### Component Lifecycle Management

Components can define their lifecycle through standard methods:

- `initialize()` - Called when the component is first initialized
- `start()` - For services, called when the service is started
- `shutdown()` - Called when the component is being shut down
- `mount()` - For UI components, called when first attaching to the DOM
- `unmount()` - For UI components, called when removing from the DOM

### Dependency Resolution

The registry system automatically resolves dependencies between components:

1. Components declare their dependencies with version requirements
2. When initializing, the registry checks dependency availability and versions
3. Dependencies are initialized first in the correct order
4. Circular dependencies are detected and reported

### Error Handling

Robust error handling is implemented throughout:

- All external calls are wrapped in pcall to prevent cascading failures
- Detailed error information is stored with stack traces
- Components with errors are marked and tracked
- Error reports can be generated for debugging

### Type Safety

The registry system uses strict typing to ensure type safety:

- Component interfaces are well-defined
- Registry operations have clear input/output types
- Type validation occurs during registration and access

## Migration Strategy

To migrate from the old registry systems:

1. **Identify Components**: Catalog all components in existing registry systems
2. **Determine Context**: Classify components as client, server, or shared
3. **Register Components**: Register components with the appropriate registry
4. **Update References**: Update code to use the new registry API
5. **Test**: Verify all components work correctly with the new system
6. **Remove Legacy Code**: Once all components are migrated, remove old registry code

## Usage Examples

### Basic Usage

```lua
-- Get registry instances
local clientRegistry = require(path.to.ClientRegistry).get()
local serverRegistry = require(path.to.ServerRegistry).get()
local sharedRegistry = require(path.to.SharedRegistry).get()

-- Register components
if RunService:IsClient() then
    clientRegistry:register("ClientModule", require(path.to.ClientModule))
elseif RunService:IsServer() then
    serverRegistry:register("ServerModule", require(path.to.ServerModule))
end

-- Register shared components
sharedRegistry:registerShared("SharedModule", require(path.to.SharedModule))

-- Use components
local module = clientRegistry:get("ClientModule")
if module then
    module:doSomething()
end
```

### Service Registration

```lua
-- Define a service
local MyService = {}

function MyService:initialize()
    print("Service initializing")
    return true
end

function MyService:start()
    print("Service starting")
    self.running = true
end

function MyService:stop()
    print("Service stopping")
    self.running = false
end

function MyService:setupRemotes(remotes)
    -- Handle remote calls
    remotes.GetData.OnServerInvoke = function(player, ...)
        return self:getData(player, ...)
    end
end

-- Register the service
serverRegistry:registerService("MyService", MyService, {
    autostart = true,
    remoteObjects = {
        GetData = "function",
        DataUpdated = "event"
    }
})
```

### UI Component Registration

```lua
-- Define a UI component
local MyUI = {}

function MyUI:initialize()
    self.data = {}
    return true
end

function MyUI:mount(parent)
    -- Create UI instance
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Size = UDim2.new(1, 0, 1, 0)
    self.mainFrame.Parent = parent
    
    -- Return created instances
    return {
        main = self.mainFrame
    }
end

function MyUI:update(data)
    -- Update UI with data
    self.data = data
    -- Update visual elements
end

function MyUI:unmount()
    -- Clean up
    self.mainFrame:Destroy()
end

-- Register the UI component
clientRegistry:registerUIComponent("MyUI", MyUI, playerGui)
```

## Conclusion

The Registry System provides a robust foundation for our application architecture. By centralizing component registration and management, we've created a more maintainable and scalable system. The next steps are to migrate existing components to this new system and remove the legacy registry code.
