--[[ 
	TycoonConfigurationManager.server.luau
	A comprehensive system for loading, storing, and managing tycoon configurations.
	Part of Phase 6: System Enhancement & Expansion
	
	This module provides:
	- JSON-based configuration loading/saving
	- Schema validation for configurations
	- Default value handling
	- Configuration inheritance
	- API for accessing configuration values
]]

local TycoonConfigurationManager = {}
TycoonConfigurationManager.__index = TycoonConfigurationManager

-- Services
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Dependencies
local ConfigurationSchema = nil
-- Will load schema during initialization

-- Constants
local CONFIG_FOLDER_NAME = "TycoonConfigurations"
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
	prerequisites = {}
}

-- Private Variables
local initialized = false
local configCache = {}
local configFolder = nil

-- Forward declarations
local validateConfig, loadConfigFile, ensureConfigFolder
local deepCopy, mergeConfigs, isValidType, logWarning
local convertColorToTable, convertTableToColor

--[[
	Initialize the configuration system
	@param schemaModule - Optional custom schema module
	@return void
]]
function TycoonConfigurationManager.init(schemaModule)
	if initialized then
		return
	end
	
	-- Set up the configuration schema
	if schemaModule then
		ConfigurationSchema = schemaModule
	else
		-- If no schema module provided, load from sibling module
		local success
		success, ConfigurationSchema = pcall(function()
			return require(script.Parent:WaitForChild("ConfigurationSchema"))
		end)
		
		if not success then
			-- Create default schema module
			ConfigurationSchema = {
				validate = function(config)
					-- Simple validation implementation
					return config
				end,
				getDefault = function()
					return deepCopy(DEFAULT_CONFIG)
				end
			}
			
			logWarning("ConfigurationSchema module not found. Using default schema implementation.")
		end
	end
	
	-- Ensure the configuration folder exists
	configFolder = ensureConfigFolder()
	
	-- Initialize cache
	configCache = {}
	
	initialized = true
	print("TycoonConfigurationManager initialized")
end

--[[
	Create a new configuration manager for a specific tycoon
	@param configName - The name of the configuration to load or create
	@return TycoonConfigurationManager instance
]]
function TycoonConfigurationManager.new(configName)
	if not initialized then
		TycoonConfigurationManager.init()
	end
	
	local self = setmetatable({}, TycoonConfigurationManager)
	
	-- Set up instance variables
	self.configName = configName
	self.modifiedSinceLastSave = false
	
	-- Try to load existing configuration from cache
	if configCache[configName] then
		self.config = deepCopy(configCache[configName])
		return self
	end
	
	-- Load or create configuration
	local config = loadConfigFile(configName)
	if not config then
		-- Create new configuration using defaults
		config = deepCopy(DEFAULT_CONFIG)
		print("Created default configuration for:", configName)
	end
	
	-- Validate the configuration
	self.config = validateConfig(config)
	
	-- Cache the configuration
	configCache[configName] = deepCopy(self.config)
	
	return self
end

--[[
	Get a setting from the configuration using dot notation path
	@param path - The dot notation path to the setting (e.g. "settings.economyMultiplier")
	@param defaultValue - Optional default value if setting is not found
	@return The setting value or defaultValue if not found
]]
function TycoonConfigurationManager:GetSetting(path, defaultValue)
	if not path then
		return defaultValue
	end
	
	local pathParts = string.split(path, ".")
	local currentTable = self.config
	
	for _, part in ipairs(pathParts) do
		if type(currentTable) ~= "table" then
			return defaultValue
		end
		currentTable = currentTable[part]
		if currentTable == nil then
			return defaultValue
		end
	end
	
	return currentTable
end

--[[
	Set a setting in the configuration using dot notation path
	@param path - The dot notation path to the setting (e.g. "settings.economyMultiplier")
	@param value - The value to set
	@return boolean - true if successful, false otherwise
]]
function TycoonConfigurationManager:SetSetting(path, value)
	if not path then
		return false
	end
	
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

--[[
	Save the configuration to ServerStorage
	@return boolean - true if successful, false otherwise
]]
function TycoonConfigurationManager:SaveConfig()
	if not configFolder then
		configFolder = ensureConfigFolder()
	end
	
	local configInstance = configFolder:FindFirstChild(self.configName)
	if not configInstance then
		configInstance = Instance.new("StringValue")
		configInstance.Name = self.configName
		configInstance.Parent = configFolder
	end
	
	local success, result = pcall(function()
		return HttpService:JSONEncode(prepareConfigForSerialization(self.config))
	end)
	
	if not success then
		logWarning("Failed to encode config for saving: " .. self.configName .. " - " .. tostring(result))
		return false
	end
	
	configInstance.Value = result
	self.modifiedSinceLastSave = false
	
	-- Update cache
	configCache[self.configName] = deepCopy(self.config)
	
	return true
end

--[[
	Export the configuration as a JSON string
	@return string - JSON representation of the configuration or nil if failed
]]
function TycoonConfigurationManager:ExportConfig()
	local success, result = pcall(function()
		return HttpService:JSONEncode(prepareConfigForSerialization(self.config))
	end)
	
	if not success then
		logWarning("Failed to export config: " .. self.configName .. " - " .. tostring(result))
		return nil
	end
	
	return result
end

--[[
	Import a configuration from a JSON string
	@param jsonString - The JSON string to import
	@return boolean - true if successful, false otherwise
]]
function TycoonConfigurationManager:ImportConfig(jsonString)
	if not jsonString then
		return false
	end
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success then
		logWarning("Failed to import config: " .. tostring(result))
		return false
	end
	
	-- Process special types like Color3
	result = processImportedConfig(result)
	
	-- Validate the imported configuration
	self.config = validateConfig(result)
	self.modifiedSinceLastSave = true
	
	return true
end

--[[
	Apply a configuration template, merging it with the current configuration
	@param templateName - The name of the template to apply
	@return boolean - true if successful, false otherwise
]]
function TycoonConfigurationManager:ApplyTemplate(templateName)
	local templateConfig = loadConfigFile(templateName)
	if not templateConfig then
		logWarning("Template not found: " .. templateName)
		return false
	end
	
	-- Merge the template with the current configuration
	self.config = mergeConfigs(self.config, templateConfig)
	self.modifiedSinceLastSave = true
	
	return true
end

--[[
	Reset the configuration to defaults
	@return void
]]
function TycoonConfigurationManager:ResetToDefaults()
	self.config = deepCopy(DEFAULT_CONFIG)
	self.modifiedSinceLastSave = true
end

--[[
	Check if a specific feature is enabled in the configuration
	@param featurePath - The path to the feature setting
	@return boolean - true if enabled, false otherwise
]]
function TycoonConfigurationManager:IsFeatureEnabled(featurePath)
	return self:GetSetting(featurePath, false) == true
end

-- Private Functions

--[[
	Validate a configuration against the schema
	@param config - The configuration to validate
	@return validated configuration with defaults applied where needed
]]
function validateConfig(config)
	if not config then
		return deepCopy(DEFAULT_CONFIG)
	end
	
	if ConfigurationSchema and ConfigurationSchema.validate then
		return ConfigurationSchema.validate(config)
	end
	
	-- Simple validation if no schema module
	return mergeConfigs(deepCopy(DEFAULT_CONFIG), config)
end

--[[
	Load a configuration from ServerStorage
	@param configName - The name of the configuration to load
	@return The loaded configuration or nil if not found
]]
function loadConfigFile(configName)
	if not configFolder then
		configFolder = ensureConfigFolder()
	end
	
	local configInstance = configFolder:FindFirstChild(configName)
	if not configInstance or not configInstance:IsA("StringValue") then
		return nil
	end
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(configInstance.Value)
	end)
	
	if not success then
		logWarning("Failed to parse config file: " .. configName .. " - " .. tostring(result))
		return nil
	end
	
	-- Process special types like Color3
	result = processImportedConfig(result)
	
	return result
end

--[[
	Prepare a configuration for serialization (convert objects to serializable form)
	@param config - The configuration to prepare
	@return The prepared configuration
]]
function prepareConfigForSerialization(config)
	local prepared = deepCopy(config)
	
	-- Convert Color3 objects to tables for serialization
	local function processTable(tbl)
		for key, value in pairs(tbl) do
			if typeof(value) == "Color3" then
				tbl[key] = convertColorToTable(value)
			elseif type(value) == "table" then
				processTable(value)
			end
		end
	end
	
	processTable(prepared)
	
	return prepared
end

--[[
	Process an imported configuration (convert serialized forms back to objects)
	@param config - The configuration to process
	@return The processed configuration
]]
function processImportedConfig(config)
	local processed = deepCopy(config)
	
	-- Convert color tables back to Color3 objects
	local function processTable(tbl)
		for key, value in pairs(tbl) do
			if type(value) == "table" and value.r and value.g and value.b then
				tbl[key] = convertTableToColor(value)
			elseif type(value) == "table" then
				processTable(value)
			end
		end
	end
	
	processTable(processed)
	
	return processed
end

--[[
	Ensure the configuration folder exists
	@return The configuration folder
]]
function ensureConfigFolder()
	local folder = ServerStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CONFIG_FOLDER_NAME
		folder.Parent = ServerStorage
	end
	return folder
end

--[[
	Create a deep copy of a table
	@param original - The table to copy
	@return A deep copy of the original table
]]
function deepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	
	return copy
end

--[[
	Merge two configurations recursively, with the second taking precedence
	@param target - The base configuration
	@param source - The configuration to merge in
	@return The merged configuration
]]
function mergeConfigs(target, source)
	local result = deepCopy(target)
	
	for key, value in pairs(source) do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = mergeConfigs(result[key], value)
		else
			result[key] = deepCopy(value)
		end
	end
	
	return result
end

--[[
	Check if a value is of the expected type
	@param value - The value to check
	@param expectedType - The expected type or table of types
	@return boolean - true if valid, false otherwise
]]
function isValidType(value, expectedType)
	if type(expectedType) == "table" then
		for _, eType in ipairs(expectedType) do
			if typeof(value) == eType then
				return true
			end
		end
		return false
	else
		return typeof(value) == expectedType
	end
end

--[[
	Log a warning message
	@param message - The message to log
	@return void
]]
function logWarning(message)
	warn("[TycoonConfigurationManager] " .. message)
end

--[[
	Convert a Color3 to a serializable table
	@param color - The Color3 to convert
	@return table with r, g, b keys
]]
function convertColorToTable(color)
	return {
		r = color.R,
		g = color.G,
		b = color.B
	}
end

--[[
	Convert a table to a Color3
	@param table - The table with r, g, b keys
	@return Color3
]]
function convertTableToColor(tbl)
	return Color3.new(tbl.r or 0, tbl.g or 0, tbl.b or 0)
end

return TycoonConfigurationManager
