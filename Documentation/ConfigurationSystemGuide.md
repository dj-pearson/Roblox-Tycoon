# Configuration System Documentation

## Overview
The new configuration system provides a comprehensive way to manage tycoon settings, styles, and behavior. It enables developers to create and apply different configurations for various tycoon types, enhancing reusability and flexibility.

## Components

### TycoonConfigurationManager
The core module responsible for managing configurations.

**Key Features:**
- JSON-based configuration loading and saving
- Schema validation for type safety
- Configuration inheritance
- Default value handling
- Dot notation access to nested properties
- Import/export functionality

### ConfigurationSchema
Defines the structure, validation rules, and default values for configurations.

**Key Features:**
- Type validation (string, number, boolean, Color3, etc.)
- Range validation for numerical values
- Default value application
- Required field checking

### ConfigurationIntegration
Bridges the configuration system with other consolidated modules.

**Key Features:**
- Applies configurations to various subsystems
- Handles configuration dependencies
- Provides unified configuration API
- Studio integration tools

### ConfigurationEditorPlugin
A Studio plugin for visually editing configurations.

**Key Features:**
- User-friendly UI for editing all configuration properties
- Real-time validation
- Template management
- Import/export functionality

## Using the Configuration System

### Creating and Loading Configurations

```lua
-- Initialize the manager
local TycoonConfigurationManager = require(path.to.TycoonConfigurationManager)
TycoonConfigurationManager.init()

-- Create or load a configuration
local configManager = TycoonConfigurationManager.new("MyGymConfig")

-- Set configuration values
configManager:SetSetting("tycoonType", "Gym")
configManager:SetSetting("settings.economyMultiplier", 1.5)
configManager:SetSetting("settings.maxFloors", 4)

-- Save the configuration
configManager:SaveConfig()
```

### Reading Configuration Values

```lua
-- Get a configuration value
local economyMultiplier = configManager:GetSetting("settings.economyMultiplier")

-- Get a value with default fallback
local maxFloors = configManager:GetSetting("settings.maxFloors", 3)

-- Check if a feature is enabled
if configManager:IsFeatureEnabled("settings.enabledFeatures.staffHiring") then
    -- Staff hiring is enabled
end
```

### Applying Configurations to Tycoons

```lua
-- Through ConfigurationIntegration
local ConfigurationIntegration = require(path.to.ConfigurationIntegration)
ConfigurationIntegration.init()

-- Apply configuration to a tycoon
local tycoon = workspace.GymTycoon
ConfigurationIntegration.applyConfiguration(tycoon, "LuxuryGymConfig")

-- Update a specific setting
ConfigurationIntegration.updateSetting(tycoon, "settings.economyMultiplier", 2.0)
```

### Using with GymAutomation

```lua
-- Automate a tycoon with a specific configuration
local GymAutomation = require(path.to.GymAutomation)
GymAutomation:AutomateGym(workspace.GymTycoon, "LuxuryGymConfig")

-- Automate all tycoons with a default configuration
GymAutomation:AutomateAllGyms("DefaultGymConfig")
```

### Studio Commands

In Studio, the following commands are available:

```lua
-- List available configurations
_G.ListTycoonConfigurations()

-- Apply a configuration to a tycoon
_G.ApplyTycoonConfiguration("GymTycoon", "LuxuryGymConfig")

-- Save a tycoon's current configuration
_G.SaveTycoonConfiguration("GymTycoon")
```

### Configuration Editor Plugin

1. Open the plugin from the Plugins menu
2. Select or create a configuration
3. Edit values using the intuitive UI
4. Save changes
5. Apply to tycoons in your game

## Configuration Schema

### Basic Structure
```json
{
  "tycoonType": "Gym",
  "version": "1.0.0",
  "settings": {
    "economyMultiplier": 1.2,
    "progressionSpeed": 1.5,
    "maxFloors": 4,
    "customizationEnabled": true,
    "enabledFeatures": {
      "staffHiring": true,
      "equipmentUpgrades": true,
      "membershipTiers": true,
      "specialEvents": true
    }
  },
  "roomTypes": [
    {"name": "Cardio", "color": {"r": 1, "g": 0.78, "b": 0.78}},
    {"name": "Weights", "color": {"r": 0.78, "g": 0.78, "b": 1}},
    {"name": "Specialized", "color": {"r": 0.78, "g": 1, "b": 0.78}}
  ],
  "equipmentCategories": [
    {"name": "Cardio", "upgradePathPrefix": "Cardio_"},
    {"name": "Strength", "upgradePathPrefix": "Strength_"},
    {"name": "Functional", "upgradePathPrefix": "Func_"}
  ],
  "prerequisites": {
    "floor2": ["receptionArea", "basicCardio"],
    "floor3": ["floor2", "advancedCardio"]
  }
}
```

### Configuration Fields

#### tycoonType
Type: string  
Description: The type of tycoon this configuration is for.  
Allowed values: "Gym", "Restaurant", "Retail", "Office", "Custom"

#### version
Type: string  
Description: Semantic version of the configuration.  
Format: "MAJOR.MINOR.PATCH"

#### settings
Type: table  
Description: General settings for the tycoon.

##### settings.economyMultiplier
Type: number  
Description: Multiplier for all economic values (prices, income, etc.).  
Range: 0.1 to 10.0

##### settings.progressionSpeed
Type: number  
Description: Controls how quickly players can progress through the tycoon.  
Range: 0.1 to 10.0

##### settings.maxFloors
Type: number (integer)  
Description: Maximum number of floors the tycoon can have.  
Range: 1 to 10

##### settings.customizationEnabled
Type: boolean  
Description: Whether players can customize the tycoon.

##### settings.enabledFeatures
Type: table  
Description: Toggle features on or off.

#### roomTypes
Type: array  
Description: Types of rooms available in the tycoon.

##### roomTypes[].name
Type: string  
Description: Name of the room type.

##### roomTypes[].color
Type: Color3  
Description: Color used to visualize this room type.

#### equipmentCategories
Type: array  
Description: Categories of equipment in the tycoon.

##### equipmentCategories[].name
Type: string  
Description: Name of the equipment category.

##### equipmentCategories[].upgradePathPrefix
Type: string  
Description: Prefix used for upgrade paths within this category.

#### prerequisites
Type: table  
Description: Defines what items must be purchased before others become available.

## Best Practices

1. **Use descriptive configuration names** that reflect their purpose.
2. **Create base configurations** for common tycoon types, then extend them for specific variations.
3. **Validate configurations** against the schema to ensure they're properly formed.
4. **Separate game-specific logic** from configuration data.
5. **Use templates** for common configuration patterns.
6. **Document custom configuration fields** that aren't part of the standard schema.
7. **Version your configurations** to track changes.

## Example Workflow

1. Create base configuration for "GymTycoon"
2. Create variations like "LuxuryGym", "BudgetGym"
3. Apply configurations to tycoons in workspace
4. Configure individual elements as needed
5. Save configurations for reuse

## Integration with Existing Systems

The configuration system integrates with:
- BoundingBoxManager
- EquipmentManager
- BuyTileProgressionManager
- TileDataGenerator

When a configuration is applied, each system receives the relevant settings:

- **BoundingBoxManager**: Receives visualization and boundary settings
- **EquipmentManager**: Receives equipment categories and economy settings
- **BuyTileProgressionManager**: Receives progression speed and prerequisites
- **TileDataGenerator**: Receives room types and economy settings

## Troubleshooting

### Common Issues

1. **Configuration not loading**: Check that the configuration exists in ServerStorage/TycoonConfigurations
2. **Changes not taking effect**: Ensure you're saving the configuration after making changes
3. **Invalid configuration**: Validate against the schema to identify issues
4. **System not responding**: Verify that all dependent modules are loaded

### Debugging Tips

- Use `TycoonConfigurationManager.new(configName)` to inspect a configuration
- Check if a configuration exists with `ServerStorage:FindFirstChild("TycoonConfigurations"):FindFirstChild(configName)`
- Set `debug = true` when applying configurations to see detailed logs

## Advanced Topics

### Creating Custom Configuration Fields

You can extend the configuration schema with custom fields:

1. Add fields to your configuration
2. Update the ConfigurationSchema module to include validation for your fields
3. Update ConfigurationIntegration to pass your fields to the appropriate systems

### Creating Configuration Templates

Templates provide starting points for different tycoon types:

1. Create a base configuration
2. Save it with a template name (e.g., "TemplateGym")
3. Apply the template: `configManager:ApplyTemplate("TemplateGym")`
4. Customize as needed

### Configuration Inheritance

Inherit settings from another configuration:

```lua
-- Create configuration based on template
local configManager = TycoonConfigurationManager.new("MyGym")
configManager:ApplyTemplate("LuxuryGymTemplate")

-- Override specific settings
configManager:SetSetting("settings.economyMultiplier", 2.0)
configManager:SaveConfig()
```
