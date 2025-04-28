-- SystemBootstrap.server.luau
-- Coordinates the initialization of all core systems in the correct order
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local INIT_TIMEOUT = 30 -- seconds for system initialization
local DEPENDENCY_RETRY_COUNT = 3 -- times to retry loading a system with dependencies
local DEPENDENCY_RETRY_DELAY = 1 -- seconds between dependency retries

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[SystemBootstrap][%s] %s", level, message))
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or 5
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- SystemBootstrap object
local SystemBootstrap = {
	_version = VERSION,
	_systems = {}, -- Systems to initialize
	_initialized = {}, -- Systems that have been initialized
	_failed = {}, -- Systems that failed to initialize
	_startTime = os.clock(), -- Track total initialization time
	_stats = {
		successCount = 0,
		failCount = 0,
		totalTime = 0
	}
}

-- Define systems to initialize with dependencies
local SYSTEMS = {
	{
		name = "CoreRegistry",
		path = "ServerScriptService.Core.CoreRegistry",
		required = true,
		dependencies = {}
	},
	{
		name = "ModuleLoader",
		path = "ReplicatedStorage.shared.ModuleLoader",
		required = true,
		dependencies = {}
	},
	{
		name = "SafeRequireModule",
		path = "ReplicatedStorage.shared.SafeRequireModule",
		required = true,
		dependencies = {"ModuleLoader"}
	},
	{
		name = "DataManager",
		path = "ServerScriptService.server.Data.DataManager",
		required = true,
		dependencies = {"CoreRegistry", "ModuleLoader"}
	},
	{
		name = "HealthCheckSystem",
		path = "ServerScriptService.server.Core.HealthCheckSystem",
		required = false,
		dependencies = {"CoreRegistry", "ModuleLoader"}
	},
	{
		name = "AssetValidator",
		path = "ReplicatedStorage.shared.AssetValidator",
		required = false,
		dependencies = {"ModuleLoader"}
	},
	{
		name = "UIRegistry",
		path = "ReplicatedStorage.shared.UIRegistry",
		required = false,
		dependencies = {"ModuleLoader", "AssetValidator"}
	},
	{
		name = "UIComponents",
		path = "ReplicatedStorage.shared.UIComponents",
		required = false,
		dependencies = {"UIRegistry", "AssetValidator"}
	}
	-- Additional systems can be added here
}

-- Resolve path to an instance
function SystemBootstrap:ResolvePath(path)
	if not path then
		return nil, "Path is nil"
	end
	
	local parts = string.split(path, ".")
	local current = game
	
	for i, part in ipairs(parts) do
		current = safeWaitForChild(current, part)
		
		if not current then
			return nil, "Failed to resolve path at part " .. i .. ": " .. part
		end
	end
	
	return current
end

-- Load a system by path
function SystemBootstrap:LoadSystem(systemPath)
	if not systemPath then
		return nil, "System path is nil"
	end
	
	-- Resolve the path
	local moduleScript, error = self:ResolvePath(systemPath)
	if not moduleScript then
		return nil, "Failed to resolve path: " .. systemPath .. " - " .. error
	end
	
	-- Require the module
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	if success then
		return result
	else
		return nil, "Failed to require: " .. systemPath .. " - " .. result
	end
end

-- Initialize a system and its dependencies
function SystemBootstrap:InitializeSystem(systemInfo, depth)
	depth = depth or 0
	
	-- Check for excessive recursion
	if depth > 10 then
		log("Excessive recursion detected while initializing system: " .. systemInfo.name, "Error")
		self._failed[systemInfo.name] = "Excessive recursion"
		return false, "Excessive recursion"
	end
	
	-- Check if already initialized
	if self._initialized[systemInfo.name] then
		return true, self._initialized[systemInfo.name]
	end
	
	-- Check if previously failed
	if self._failed[systemInfo.name] then
		return false, "Previously failed: " .. self._failed[systemInfo.name]
	end
	
	-- Initialize dependencies first
	for _, depName in ipairs(systemInfo.dependencies) do
		local depSystem = self:FindSystemByName(depName)
		if not depSystem then
			log("Dependency not found: " .. depName .. " for system: " .. systemInfo.name, "Error")
			self._failed[systemInfo.name] = "Dependency not found: " .. depName
			return false, "Dependency not found: " .. depName
		end
		
		-- Initialize dependency
		local depSuccess, depResult = self:InitializeSystem(depSystem, depth + 1)
		if not depSuccess then
			-- If this is a required dependency, fail
			if depSystem.required then
				log("Required dependency failed: " .. depName .. " for system: " .. systemInfo.name, "Error")
				self._failed[systemInfo.name] = "Required dependency failed: " .. depName
				return false, "Required dependency failed: " .. depName
			else
				-- If optional, just log a warning
				log("Optional dependency failed: " .. depName .. " for system: " .. systemInfo.name, "Warning")
			end
		end
	end
	
	-- Load the system
	local startTime = os.clock()
	log("Initializing system: " .. systemInfo.name)
	
	local system, error = self:LoadSystem(systemInfo.path)
	
	-- Check if system loaded successfully
	if not system then
		if systemInfo.required then
			log("Failed to initialize required system: " .. systemInfo.name .. " - " .. tostring(error), "Error")
			self._failed[systemInfo.name] = tostring(error)
			self._stats.failCount += 1
			return false, error
		else
			log("Failed to initialize optional system: " .. systemInfo.name .. " - " .. tostring(error), "Warning")
			self._failed[systemInfo.name] = tostring(error)
			return false, error
		end
	end
	
	-- Store initialized system
	self._initialized[systemInfo.name] = system
	self._stats.successCount += 1
	
	-- Log success
	local duration = os.clock() - startTime
	log("Initialized system: " .. systemInfo.name .. " in " .. string.format("%.2f", duration) .. " seconds")
	
	return true, system
end

-- Find a system definition by name
function SystemBootstrap:FindSystemByName(name)
	for _, system in ipairs(SYSTEMS) do
		if system.name == name then
			return system
		end
	end
	return nil
end

-- Initialize all systems
function SystemBootstrap:InitializeAllSystems()
	log("Starting system initialization")
	
	-- Store start time
	self._startTime = os.clock()
	
	-- Process each system
	for _, system in ipairs(SYSTEMS) do
		self:InitializeSystem(system)
	end
	
	-- Store total time
	self._stats.totalTime = os.clock() - self._startTime
	
	-- Log summary
	log("System initialization complete - " .. 
		self._stats.successCount .. " successful, " .. 
		self._stats.failCount .. " failed, total time: " .. 
		string.format("%.2f", self._stats.totalTime) .. " seconds")
	
	-- Check if any required systems failed
	local requiredFailed = false
	for _, system in ipairs(SYSTEMS) do
		if system.required and self._failed[system.name] then
			requiredFailed = true
			log("CRITICAL: Required system failed: " .. system.name, "Error")
		end
	end
	
	if requiredFailed then
		log("CRITICAL: Some required systems failed to initialize. Game may not function correctly.", "Error")
	end
	
	-- Return true if all required systems initialized
	return not requiredFailed
end

-- Get the bootstrap version
function SystemBootstrap:GetVersion()
	return self._version
end

-- Get all initialized systems
function SystemBootstrap:GetInitializedSystems()
	return self._initialized
end

-- Get all failed systems
function SystemBootstrap:GetFailedSystems()
	return self._failed
end

-- Get initialization stats
function SystemBootstrap:GetStats()
	return self._stats
end

-- Get a specific system
function SystemBootstrap:GetSystem(name)
	return self._initialized[name]
end

-- Check if a system was initialized
function SystemBootstrap:IsSystemInitialized(name)
	return self._initialized[name] ~= nil
end

-- Check if a system failed
function SystemBootstrap:DidSystemFail(name)
	return self._failed[name] ~= nil
end

-- Start the initialization process
log("SystemBootstrap v" .. VERSION .. " starting")
SystemBootstrap:InitializeAllSystems()

-- Export the SystemBootstrap
return SystemBootstrap
