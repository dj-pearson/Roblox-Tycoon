# UI Module System

## Overview

This UI Module system is designed to provide a robust, fault-tolerant framework for creating and managing UI elements in our Roblox game. It handles module loading issues, asset validation, and provides consistent UI styling across the game.

## Core Components

### 1. ModuleLoader

Located in `src/shared/ModuleLoader.luau`, this utility handles loading modules with robust error handling and fallbacks.

**Key Features:**
- Multiple module search paths
- Caching for performance
- Detailed error reporting
- Dependency resolution

**Usage:**
```lua
local ModuleLoader = require(game.ReplicatedStorage.shared.ModuleLoader)
local MyModule = ModuleLoader.require("MyModule") -- Throws error if not found
local OptionalModule = ModuleLoader.tryRequire("OptionalModule") -- Returns nil if not found
```

### 2. ClientRegistry

Located in `src/client/Core/ClientRegistry.luau`, this is the central registry for client-side systems.

**Key Features:**
- System registration and discovery
- UI component management
- Cross-system communication

**Usage:**
```lua
local ClientRegistry = require(game.ReplicatedStorage.shared.ClientRegistry)

-- Register a system
ClientRegistry:registerSystem("MySystem", mySystemInstance)

-- Get a system
local otherSystem = ClientRegistry:getSystem("OtherSystem")

-- Register/get UI components
ClientRegistry:registerUIComponent("MyStyle", myStyleInstance)
local style = ClientRegistry:getUIComponent("MyStyle")
```

### 3. UIComponents

Located in `src/shared/UIComponents.luau`, this bundle provides consistent styling and UI elements.

**Key Features:**
- Consistent color schemes and styles
- Icon management
- Button and dialog creation
- Fallback styles when assets fail to load

**Usage:**
```lua
local UIComponents = require(game.ReplicatedStorage.shared.UIComponents)

-- Create a styled button
local button = UIComponents.ButtonFactory.createButton("Click Me")
button.Parent = someFrame

-- Create a dialog
local dialog = UIComponents.DialogFactory.createConfirmDialog(
    "Confirm Action",
    "Are you sure you want to proceed?",
    function() print("Confirmed") end,
    function() print("Cancelled") end
)
```

### 4. AssetValidator

Located in `src/shared/AssetValidator.luau`, this utility ensures assets load correctly.

**Key Features:**
- Validates all types of assets (sounds, animations, images)
- Maintains fallback assets for when loading fails
- Preloads critical assets
- Detailed logging of asset loading failures

**Usage:**
```lua
local AssetValidator = require(game.ReplicatedStorage.shared.AssetValidator)

-- Register critical assets for preloading
AssetValidator.registerCriticalAsset("rbxassetid://1234567890", "Image")

-- Validate an asset ID
local isValid = AssetValidator.validateAsset("rbxassetid://1234567890", "Sound")

-- Get a valid asset ID with automatic fallback
local assetId = AssetValidator.getValidAssetId(someAssetId, "Image")
```

### 5. AssetHealthDashboard

Located in `src/client/UI/AssetHealthDashboard.client.luau`, this provides a UI for diagnosing asset issues.

**Key Features:**
- Visual display of asset loading stats
- Tools to validate and fix problematic assets
- Asset previewing

**Usage:**
```lua
local AssetHealthDashboard = require(game.Players.LocalPlayer.PlayerScripts.Client.UI.AssetHealthDashboard)

-- Open the dashboard
AssetHealthDashboard.open()

-- Register a custom asset fixer
AssetHealthDashboard.registerAssetFixer("Image", function(assetId)
    return myCustomFallbackAsset
end)
```

## Integration

### System Initialization Order

1. `ClientBootstrap.client.luau` initializes first and loads:
   - ModuleLoader
   - ClientRegistryFixer (ensures ClientRegistry exists)
   - ClientRegistry
   - UIComponents
   - AssetValidator
   - UIRegistry
   - AssetHealthDashboard

2. These core systems are available to all other scripts and systems.

### Adding to Existing Scripts

To use these systems in your existing scripts, add the following to the top of your scripts:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.shared.ModuleLoader)

-- Get the components you need
local ClientRegistry = ModuleLoader.tryRequire("ClientRegistry")
local UIComponents = ModuleLoader.tryRequire("UIComponents")
local AssetValidator = ModuleLoader.tryRequire("AssetValidator")

-- Fallback methods if ModuleLoader fails
if not ClientRegistry then
    ClientRegistry = require(ReplicatedStorage.shared.ClientRegistry)
end
```

### Creating UI Elements

For consistent UI styling, always use the UIComponents system:

```lua
-- Create a screen GUI with proper styling
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = UIComponents.UIStyle.Colors.Background
mainFrame.Parent = screenGui

-- Add a styled button
local button = UIComponents.ButtonFactory.createButton("Click Me")
button.Position = UDim2.new(0.5, -50, 0.5, -20)
button.Parent = mainFrame
```

### Testing System Health

Use the `UISystemTester` to check if all components are working correctly:

```lua
local UISystemTester = require(game.Players.LocalPlayer.PlayerScripts.Client.UI.UISystemTester)

-- Run all tests
UISystemTester.testModuleLoader()
UISystemTester.testClientRegistry()
UISystemTester.testUIRegistry()
UISystemTester.testUIComponents()
UISystemTester.testAssetValidator()

-- Generate a report
local report = UISystemTester.generateReport()

-- Create a test UI
UISystemTester.createTestUI()
```

## Troubleshooting

### Common Issues

1. **Modules not loading**
   - Check for module name typos
   - Ensure modules are in the correct folders
   - Use `ModuleLoader.tryRequire()` instead of direct require

2. **UI styling inconsistencies**
   - Always use UIComponents for UI element creation
   - Check if UIStyle is correctly loaded via ClientRegistry

3. **Asset loading failures**
   - Register critical assets early using AssetValidator
   - Open AssetHealthDashboard (Ctrl+Shift+A) to diagnose issues
   - Check console for warnings from AssetValidator

### Accessing the Dashboard

Press `Ctrl+Shift+A` in game to open the Asset Health Dashboard, which provides tools to diagnose and fix asset loading issues.

## Further Development

To extend this system:

1. Add new UI components by registering them with UIRegistry
2. Create specialized UI factories for game-specific interfaces
3. Extend AssetValidator for additional asset types
4. Create additional diagnostic tools based on UISystemTester

## Contact

For issues or suggestions regarding this UI Module system, contact the development team.

Last Updated: April 25, 2025
