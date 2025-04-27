--[[
	ConfigurationIntegration.server.luau
	
	This module integrates the new TycoonConfigurationManager with the existing consolidated modules.
	It acts as a bridge to ensure that configurations are properly applied to all systems.
	
	Part of Phase 6: System Enhancement & Expansion (Task 1)
]]

local ConfigurationIntegration = {}

-- Services
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Module dependencies
local success, TycoonConfigurationManager = pcall(function()
	return require(script.Parent.TycoonConfigurationManager)
end)

if not success then
	warn("Failed to load TycoonConfigurationManager:", TycoonConfigurationManager)
	return {}
end

-- Ensure configuration manager is initialized
TycoonConfigurationManager.init()

-- Module references (will be populated during initialization)
local moduleRefs = {
	BoundingBoxManager = nil,
	EquipmentManager = nil,
	BuyTileProgressionManager = nil,
	TileDataGenerator = nil
}

-- Configuration caches by tycoon
local tycoonConfigs = {}
local defaultConfigName = "DefaultGym"

--[[
	Initialize the integration module and connect it to other modules
	@param modules - Table of module references to integrate with
	@return void
]]
function ConfigurationIntegration.init(modules)
	if modules then
		for name, module in pairs(modules) do
			if moduleRefs[name] ~= nil then
				moduleRefs[name] = module
			end
		end
	end
	
	-- Try to find modules in parent
	for name, _ in pairs(moduleRefs) do
		if not moduleRefs[name] then
			success, moduleRefs[name] = pcall(function()
				return require(script.Parent[name])
			end)
			
			if not success then
				moduleRefs[name] = nil
				warn("Could not find module:", name)
			end
		end
	end
	
	print("ConfigurationIntegration initialized with modules:", table.concat(getLoadedModuleNames(), ", "))
end

--[[
	Apply configuration to a specific tycoon
	@param tycoonInstance - The tycoon instance to configure
	@param configName - Optional name of configuration to apply, otherwise uses tycoon name or default
	@return boolean - Whether configuration was successfully applied
]]
function ConfigurationIntegration.applyConfiguration(tycoonInstance, configName)
	if not tycoonInstance then
		warn("Cannot apply configuration: tycoonInstance is nil")
		return false
	end
	
	-- Determine which configuration to use
	configName = configName or tycoonInstance.Name or defaultConfigName
	
	-- Get or create configuration for this tycoon
	local config = getOrCreateTycoonConfig(tycoonInstance, configName)
	if not config then
		warn("Failed to get or create configuration for tycoon:", tycoonInstance.Name)
		return false
	end
	
	-- Apply configuration to each module
	local success = true
	
	-- Apply to BoundingBoxManager if available
	if moduleRefs.BoundingBoxManager then
		success = success and applyConfigToBoundingBoxManager(tycoonInstance, config)
	end
	
	-- Apply to EquipmentManager if available
	if moduleRefs.EquipmentManager then
		success = success and applyConfigToEquipmentManager(tycoonInstance, config)
	end
	
	-- Apply to BuyTileProgressionManager if available
	if moduleRefs.BuyTileProgressionManager then
		success = success and applyConfigToProgressionManager(tycoonInstance, config)
	end
	
	-- Apply to TileDataGenerator if available
	if moduleRefs.TileDataGenerator then
		success = success and applyConfigToTileDataGenerator(tycoonInstance, config)
	end
	
	if success then
		print("Successfully applied configuration to tycoon:", tycoonInstance.Name)
	else
		warn("Errors occurred while applying configuration to tycoon:", tycoonInstance.Name)
	end
	
	return success
end

--[[
	Get the configuration for a specific tycoon
	@param tycoonInstance - The tycoon instance
	@return TycoonConfigurationManager instance
]]
function ConfigurationIntegration.getConfiguration(tycoonInstance)
	if not tycoonInstance then return nil end
	
	local tycoonId = getTycoonId(tycoonInstance)
	return tycoonConfigs[tycoonId]
end

--[[
	Update a specific setting for a tycoon
	@param tycoonInstance - The tycoon instance
	@param path - The dot-notation path to the setting
	@param value - The new value
	@return boolean - Whether the update was successful
]]
function ConfigurationIntegration.updateSetting(tycoonInstance, path, value)
	if not tycoonInstance or not path then return false end
	
	local config = ConfigurationIntegration.getConfiguration(tycoonInstance)
	if not config then
		warn("No configuration found for tycoon:", tycoonInstance.Name)
		return false
	end
	
	local success = config:SetSetting(path, value)
	if success then
		-- Reapply the configuration
		ConfigurationIntegration.applyConfiguration(tycoonInstance)
	end
	
	return success
end

--[[
	Save all current tycoon configurations
	@return boolean - Whether all saves were successful
]]
function ConfigurationIntegration.saveAllConfigurations()
	local allSuccess = true
	
	for _, config in pairs(tycoonConfigs) do
		local success = config:SaveConfig()
		allSuccess = allSuccess and success
	end
	
	return allSuccess
end

--[[
	Register Studio commands for configuration management
	@return void
]]
function ConfigurationIntegration.registerStudioCommands()
	if not RunService:IsStudio() then return end
	
	-- Register global functions for Studio use
	_G.ApplyTycoonConfiguration = function(tycoonName, configName)
		local tycoon = getTycoonByName(tycoonName)
		if tycoon then
			return ConfigurationIntegration.applyConfiguration(tycoon, configName)
		else
			warn("Tycoon not found:", tycoonName)
			return false
		end
	end
	
	_G.SaveTycoonConfiguration = function(tycoonName)
		local tycoon = getTycoonByName(tycoonName)
		if tycoon then
			local config = ConfigurationIntegration.getConfiguration(tycoon)
			if config then
				return config:SaveConfig()
			end
		end
		return false
	end
	
	_G.ListTycoonConfigurations = function()
		local configFolder = ServerStorage:FindFirstChild("TycoonConfigurations")
		if not configFolder then
			print("No TycoonConfigurations folder found")
			return
		end
		
		print("Available configurations:")
		for _, item in ipairs(configFolder:GetChildren()) do
			if item:IsA("StringValue") then
				print("- " .. item.Name)
			end
		end
	end
	
	print("Registered studio commands: _G.ApplyTycoonConfiguration, _G.SaveTycoonConfiguration, _G.ListTycoonConfigurations")
end

-- Private helper functions

--[[
	Get or create a configuration for a tycoon
	@param tycoonInstance - The tycoon instance
	@param configName - Name of configuration to use
	@return TycoonConfigurationManager instance
]]
function getOrCreateTycoonConfig(tycoonInstance, configName)
	local tycoonId = getTycoonId(tycoonInstance)
	
	-- Return existing config if we have one
	if tycoonConfigs[tycoonId] then
		return tycoonConfigs[tycoonId]
	end
	
	-- Create new configuration
	local config = TycoonConfigurationManager.new(configName)
	
	-- Cache the configuration
	tycoonConfigs[tycoonId] = config
	
	return config
end

--[[
	Apply configuration to BoundingBoxManager
	@param tycoonInstance - The tycoon instance
	@param config - TycoonConfigurationManager instance
	@return boolean - Whether configuration was successfully applied
]]
function applyConfigToBoundingBoxManager(tycoonInstance, config)
	local manager = moduleRefs.BoundingBoxManager
	if not manager then return false end
	
	-- Apply relevant configuration options
	local options = {
		visualizeHitboxes = config:GetSetting("settings.customizationEnabled", false),
		useSimplifiedBounds = config:IsFeatureEnabled("settings.enabledFeatures.simplifiedBounds"),
		debugMode = RunService:IsStudio()
	}
	
	-- Call the configuration method if it exists
	if typeof(manager.ConfigureTycoon) == "function" then
		return pcall(function()
			manager:ConfigureTycoon(tycoonInstance, options)
		end)
	end
	
	return false
end

--[[
	Apply configuration to EquipmentManager
	@param tycoonInstance - The tycoon instance
	@param config - TycoonConfigurationManager instance
	@return boolean - Whether configuration was successfully applied
]]
function applyConfigToEquipmentManager(tycoonInstance, config)
	local manager = moduleRefs.EquipmentManager
	if not manager then return false end
	
	-- Apply relevant configuration options
	local options = {
		upgradesEnabled = config:IsFeatureEnabled("settings.enabledFeatures.equipmentUpgrades"),
		economyMultiplier = config:GetSetting("settings.economyMultiplier", 1.0),
		equipmentCategories = config:GetSetting("equipmentCategories", {})
	}
	
	-- Call the configuration method if it exists
	if typeof(manager.ConfigureTycoon) == "function" then
		return pcall(function()
			manager:ConfigureTycoon(tycoonInstance, options)
		end)
	end
	
	return false
end

--[[
	Apply configuration to BuyTileProgressionManager
	@param tycoonInstance - The tycoon instance
	@param config - TycoonConfigurationManager instance
	@return boolean - Whether configuration was successfully applied
]]
function applyConfigToProgressionManager(tycoonInstance, config)
	local manager = moduleRefs.BuyTileProgressionManager
	if not manager then return false end
	
	-- Apply relevant configuration options
	local options = {
		progressionSpeed = config:GetSetting("settings.progressionSpeed", 1.0),
		maxFloors = config:GetSetting("settings.maxFloors", 3),
		prerequisites = config:GetSetting("prerequisites", {})
	}
	
	-- Call the configuration method if it exists
	if typeof(manager.ConfigureTycoon) == "function" then
		return pcall(function()
			manager:ConfigureTycoon(tycoonInstance, options)
		end)
	end
	
	return false
end

--[[
	Apply configuration to TileDataGenerator
	@param tycoonInstance - The tycoon instance
	@param config - TycoonConfigurationManager instance
	@return boolean - Whether configuration was successfully applied
]]
function applyConfigToTileDataGenerator(tycoonInstance, config)
	local generator = moduleRefs.TileDataGenerator
	if not generator then return false end
	
	-- Apply relevant configuration options
	local options = {
		roomTypes = config:GetSetting("roomTypes", {}),
		economyMultiplier = config:GetSetting("settings.economyMultiplier", 1.0)
	}
	
	-- Call the configuration method if it exists
	if typeof(generator.ConfigureTycoon) == "function" then
		return pcall(function()
			generator:ConfigureTycoon(tycoonInstance, options)
		end)
	end
	
	return false
end

--[[
	Get a unique identifier for a tycoon instance
	@param tycoonInstance - The tycoon instance
	@return string - Unique identifier
]]
function getTycoonId(tycoonInstance)
	if not tycoonInstance then return "unknown" end
	return tycoonInstance.Name .. "_" .. tostring(tycoonInstance:GetDebugId())
end

--[[
	Find a tycoon by name in the workspace
	@param tycoonName - The name of the tycoon
	@return Instance - The tycoon instance or nil if not found
]]
function getTycoonByName(tycoonName)
	if not tycoonName then return nil end
	
	-- Look in workspace for tycoon with this name
	return workspace:FindFirstChild(tycoonName)
end

--[[
	Get the names of loaded modules
	@return table - Array of loaded module names
]]
function getLoadedModuleNames()
	local names = {}
	for name, module in pairs(moduleRefs) do
		if module then
			table.insert(names, name)
		end
	end
	return names
end

return ConfigurationIntegration
