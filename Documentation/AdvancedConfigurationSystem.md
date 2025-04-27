# Advanced Configuration System Implementation Plan

## Overview
This document provides a detailed implementation plan for the Advanced Configuration System, which is Task 1 of Phase 6 in our consolidation plan. This system will allow for flexible configuration of tycoon properties across different styles and use cases.

## Components

### 1. TycoonConfigurationManager

#### File: `TycoonConfigurationManager.server.luau`

```lua
--[[ 
	TycoonConfigurationManager.server.luau
	Handles loading, validation, and access to tycoon configuration
]]

local TycoonConfigurationManager = {}
TycoonConfigurationManager.__index = TycoonConfigurationManager

-- Dependencies
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

-- Constants
local CONFIG_FOLDER = ServerStorage:FindFirstChild("TycoonConfigurations") or Instance.new("Folder")
CONFIG_FOLDER.Name = "TycoonConfigurations"
CONFIG_FOLDER.Parent = ServerStorage

local DEFAULT_CONFIG = {
	tycoonType = "Gym",
	version = "1.0.0",
	settings = {
		economyMultiplier = 1.0,
		progressionSpeed = 1.0,
		maxFloors = 3,
		customizationEnabled = true
	},
	roomTypes = {
		{name = "Cardio", color = Color3.fromRGB(255, 200, 200)},
		{name = "Weights", color = Color3.fromRGB(200, 200, 255)},
		{name = "Specialized", color = Color3.fromRGB(200, 255, 200)}
	},
	equipmentCategories = {
		{name = "Cardio", upgradePathPrefix = "Cardio_"},
		{name = "Strength", upgradePathPrefix = "Strength_"},
		{name = "Functional", upgradePathPrefix = "Func_"}
	},
	prerequisites = {
		-- Default prerequisites go here
	}
}

-- Private Methods
local function validateConfig(config)
	-- Validate the configuration against the schema
	-- Return corrected config with any missing values filled in with defaults
	local validated = {}
	
	-- Implementation details...
	
	return validated
end

local function loadConfigFile(configName)
	local configInstance = CONFIG_FOLDER:FindFirstChild(configName)
	if not configInstance or not configInstance:IsA("StringValue") then
		return nil
	end
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(configInstance.Value)
	end)
	
	if not success then
		warn("Failed to parse config file:", configName, result)
		return nil
	end
	
	return result
end

-- Public Methods
function TycoonConfigurationManager.new(configName)
	local self = setmetatable({}, TycoonConfigurationManager)
	
	-- Load or create configuration
	local config = loadConfigFile(configName)
	if not config then
		config = table.clone(DEFAULT_CONFIG)
		print("Created default configuration for:", configName)
	end
	
	self.configName = configName
	self.config = validateConfig(config)
	self.modifiedSinceLastSave = false
	
	return self
end

function TycoonConfigurationManager:GetSetting(path)
	-- Navigate the config table using dot notation path and return the value
	-- Example: manager:GetSetting("settings.economyMultiplier")
	
	local pathParts = string.split(path, ".")
	local currentTable = self.config
	
	for _, part in ipairs(pathParts) do
		if type(currentTable) ~= "table" then
			return nil
		end
		currentTable = currentTable[part]
	end
	
	return currentTable
end

function TycoonConfigurationManager:SetSetting(path, value)
	-- Navigate the config table using dot notation path and set the value
	-- Example: manager:SetSetting("settings.economyMultiplier", 1.5)
	
	local pathParts = string.split(path, ".")
	local currentTable = self.config
	local lastIndex = #pathParts
	
	for i = 1, lastIndex - 1 do
		local part = pathParts[i]
		if type(currentTable[part]) ~= "table" then
			currentTable[part] = {}
		end
		currentTable = currentTable[part]
	end
	
	currentTable[pathParts[lastIndex]] = value
	self.modifiedSinceLastSave = true
	
	return true
end

function TycoonConfigurationManager:SaveConfig()
	-- Save the configuration to a StringValue in the CONFIG_FOLDER
	
	local configInstance = CONFIG_FOLDER:FindFirstChild(self.configName) or Instance.new("StringValue")
	configInstance.Name = self.configName
	configInstance.Parent = CONFIG_FOLDER
	
	local success, result = pcall(function()
		return HttpService:JSONEncode(self.config)
	end)
	
	if not success then
		warn("Failed to encode config for saving:", self.configName, result)
		return false
	end
	
	configInstance.Value = result
	self.modifiedSinceLastSave = false
	
	return true
end

function TycoonConfigurationManager:ExportConfig()
	-- Return a JSON string of the current configuration
	
	local success, result = pcall(function()
		return HttpService:JSONEncode(self.config)
	end)
	
	if not success then
		warn("Failed to export config:", self.configName, result)
		return nil
	end
	
	return result
end

function TycoonConfigurationManager:ImportConfig(jsonString)
	-- Import a configuration from a JSON string
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success then
		warn("Failed to import config:", result)
		return false
	end
	
	self.config = validateConfig(result)
	self.modifiedSinceLastSave = true
	
	return true
end

return TycoonConfigurationManager
```

### 2. Configuration Schema

#### File: `ConfigurationSchema.lua`

```lua
--[[ 
	ConfigurationSchema.lua
	Defines the schema for tycoon configuration validation
]]

local ConfigurationSchema = {
	tycoonType = {
		type = "string",
		required = true,
		default = "Gym",
		enum = {"Gym", "Restaurant", "Retail", "Office", "Custom"}
	},
	version = {
		type = "string", 
		required = true,
		pattern = "^%d+%.%d+%.%d+$" -- Semantic versioning pattern
	},
	settings = {
		type = "table",
		required = true,
		properties = {
			economyMultiplier = {
				type = "number",
				required = true,
				default = 1.0,
				min = 0.1,
				max = 10.0
			},
			progressionSpeed = {
				type = "number",
				required = true,
				default = 1.0,
				min = 0.1,
				max = 10.0
			},
			maxFloors = {
				type = "number",
				required = true,
				default = 3,
				min = 1,
				max = 10
			},
			customizationEnabled = {
				type = "boolean",
				required = true,
				default = true
			}
		}
	},
	roomTypes = {
		type = "array",
		required = true,
		itemSchema = {
			type = "table",
			properties = {
				name = {
					type = "string",
					required = true
				},
				color = {
					type = "Color3",
					required = true
				}
			}
		}
	},
	equipmentCategories = {
		type = "array",
		required = true,
		itemSchema = {
			type = "table",
			properties = {
				name = {
					type = "string",
					required = true
				},
				upgradePathPrefix = {
					type = "string",
					required = true
				}
			}
		}
	},
	prerequisites = {
		type = "table",
		required = false,
		default = {}
	}
}

return ConfigurationSchema
```

### 3. Configuration Editor Plugin

#### File: `ConfigurationEditorPlugin.server.lua`

```lua
--[[ 
	ConfigurationEditorPlugin.server.lua
	Studio plugin for editing tycoon configurations visually
]]

-- Only run in Studio
if not game:GetService("RunService"):IsStudio() then
	return
end

local Plugin = plugin
local PluginName = "Tycoon Configuration Editor"

-- Services
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Dependencies
local TycoonConfigurationManager = require(script.Parent:WaitForChild("TycoonConfigurationManager"))
local ConfigurationSchema = require(script.Parent:WaitForChild("ConfigurationSchema"))

-- UI Setup
local toolbar = Plugin:CreateToolbar(PluginName)
local openEditorButton = toolbar:CreateButton(
	"Open Editor", 
	"Open the Tycoon Configuration Editor", 
	"rbxassetid://4458901886"
)

local editorWidget = Plugin:CreateDockWidgetPluginGui(
	"TycoonConfigurationEditorWidget",
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		700,
		500,
		500,
		300
	)
)
editorWidget.Title = PluginName

-- UI Elements will be created here

-- Functionality
local function buildEditorUI()
	-- Implementation for building the editor UI
end

local function loadConfigurations()
	-- Load all configurations from the CONFIG_FOLDER
end

local function saveCurrentConfiguration()
	-- Save the current configuration
	ChangeHistoryService:SetWaypoint("Saved Tycoon Configuration")
end

-- Event Connections
openEditorButton.Click:Connect(function()
	editorWidget.Enabled = not editorWidget.Enabled
	
	if editorWidget.Enabled then
		buildEditorUI()
		loadConfigurations()
	end
end)

-- Initialize
print(PluginName .. " plugin loaded")
```

## Implementation Steps

### Step 1: Core Configuration Manager
1. Create the TycoonConfigurationManager.server.luau file
2. Implement basic loading and saving of JSON configuration
3. Set up configuration schema and validation
4. Create methods for accessing and modifying configuration data
5. Add documentation for all methods

### Step 2: Configuration UI (Studio Plugin)
1. Create the ConfigurationEditorPlugin.server.lua file
2. Build the UI for configuration editing
3. Add tabs for different configuration categories
4. Implement live validation and feedback
5. Create import/export functionality

### Step 3: Integration with Existing Systems
1. Update EquipmentManager to use configuration data
2. Update BoundingBoxManager to incorporate configuration options
3. Update BuyTileProgressionManager to use prerequisites from configuration
4. Add configuration hooks in GymAutomation.server.luau

### Step 4: Documentation and Examples
1. Create comprehensive documentation with examples
2. Add configuration templates for different tycoon styles
3. Create tutorial for building custom configurations

## Testing Plan
- Create test configurations for different tycoon styles
- Verify that all systems correctly use configuration values
- Test edge cases with invalid configuration data
- Verify performance impact with large configurations
- Test import/export functionality

## Dependencies
- HttpService for JSON encoding/decoding
- ServerStorage for configuration storage
- Studio plugin API for configuration editor

## Timeline
- Days 1-3: Implementation of TycoonConfigurationManager
- Days 4-7: Development of Studio plugin for configuration editing
- Days 8-9: Integration with existing systems
- Day 10: Documentation and testing

## Success Criteria
- Configurations can be easily created and edited in Studio
- All systems correctly read and apply configuration values
- JSON import/export works correctly
- Different tycoon styles can be quickly set up using configurations
