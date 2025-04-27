# Registry Migration Guide

## Overview

This guide outlines the process for migrating components from legacy registry systems to our new unified Registry System. The migration tools provide both automated and manual migration options to simplify the transition while maintaining compatibility with existing code.

## Migration Tools

We've created two key tools to assist with registry migration:

1. **RegistryMigration**: A utility module that provides the core migration functionality
2. **MigrateRegistryComponents**: A script that automates migration of registered components

### RegistryMigration Utility

The `RegistryMigration` utility (`src/shared/Registry/RegistryMigration.luau`) provides functions for:

- Transforming legacy IDs to the new format
- Mapping dependencies between old and new systems
- Determining appropriate component versions
- Creating compatibility wrappers for legacy code

### Migration Script

The `MigrateRegistryComponents` script (`src/shared/Registry/MigrateRegistryComponents.luau`) automatically:

- Locates legacy registry modules
- Extracts registered components
- Migrates them to the appropriate new registry
- Creates compatibility wrappers in the global scope

## Migration Process

### Automated Migration

The easiest way to migrate is to run the automated migration script:

1. Require the migration script on both client and server:

```lua
-- From a server script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("Registry")
require(SharedModules:WaitForChild("MigrateRegistryComponents"))
```

```lua
-- From a client script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("Registry")
require(SharedModules:WaitForChild("MigrateRegistryComponents"))
```

2. The script will:
   - Find legacy registry modules
   - Migrate components to the new registry system
   - Create compatibility wrappers in the global scope:
     - `_G.LegacyClientRegistry` for client
     - `_G.LegacyCoreRegistry` for server

### Manual Migration

For components that aren't automatically detected, you can use the global migration helper:

```lua
-- Migrate a component manually
_G.MigrateComponent("MyComponent", myComponentModule, "client") -- For client components
_G.MigrateComponent("MyService", myServiceModule, "server") -- For server components 
_G.MigrateComponent("MyUtility", myUtilityModule, "shared") -- For shared components
```

## Component Type Detection

The migration tools automatically detect component types:

### Client Components

- UI components are detected by the presence of `mount` and `unmount` methods
- Regular components are registered with the client registry

### Server Components

- Services are detected by the presence of `start` and `stop` methods
- Systems are detected by the presence of a `run` method
- Regular components are registered with the server registry

### Shared Components

- Components are registered with context based on explicit `CONTEXT` property or configuration

## Configuration Options

The migration tools support various configuration options:

- **legacyNamespace**: The old namespace (e.g., "ClientSystem") 
- **targetRegistry**: Which registry to use ("client", "server", "shared")
- **idTransformer**: Function to transform component IDs
- **versionMap**: Explicit versions for specific components
- **dependencyMap**: Dependency mappings for components
- **contextMap**: Context mappings for shared components

## Compatibility Wrappers

The migration tools create compatibility wrappers to support legacy code:

### Client Registry Wrapper

```lua
-- Legacy code using old client registry
local ClientRegistry = _G.LegacyClientRegistry
local mySystem = ClientRegistry.getSystem("MySystem")
```

### Server Registry Wrapper

```lua
-- Legacy code using old server registry
local CoreRegistry = _G.LegacyCoreRegistry
local mySystem = CoreRegistry.getInitializedSystem("MySystem")
```

## Best Practices

1. **Staged Migration**: Migrate one system at a time, starting with core systems
2. **Testing**: Test thoroughly after each migration to ensure functionality
3. **Update References**: Gradually update references to use the new registry API
4. **Component Adaptation**: Adapt components to use new lifecycle methods
5. **Dependency Updates**: Update dependencies to use the new registry format

## Example Workflow

Here's a recommended workflow for migrating a specific system:

1. Run the automated migration script
2. Verify the system was migrated correctly
3. Update the system to use new registry features:

```lua
-- Before migration
local ClientRegistry = require(path.to.ClientRegistry)
ClientRegistry.registerSystem("MySystem", MySystemModule)

-- After migration
local ClientRegistry = require(path.to.Registry.ClientRegistry).get()
ClientRegistry:register("MySystem", MySystemModule, "1.0.0")
```

4. Update dependencies to use the new registry format
5. Test functionality thoroughly
6. Repeat for other systems

## Troubleshooting

### Common Issues

1. **Component Not Found**: Ensure ID transformation is correct
2. **Dependency Issues**: Check that all dependencies are migrated
3. **Type Mismatch**: Verify that the component is migrated to the correct registry
4. **Initialization Failures**: Ensure component lifecycle methods are compatible

### Debugging

The migration tools provide detailed logging to help diagnose issues:

```lua
-- Enable detailed logging
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RegistryBase = require(ReplicatedStorage.src.shared.Registry.RegistryBase)
local registry = RegistryBase.new("DebugRegistry", {logLevel = 4})
```

## Conclusion

The Registry Migration tools provide a smooth path from legacy registry systems to our new unified Registry System. By using these tools, we can maintain compatibility with existing code while gradually adopting the improved architecture and features of the new system.

For specific questions or assistance with complex migrations, consult with the development team.
