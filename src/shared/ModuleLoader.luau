-- ModuleLoader.luau
-- Utility for loading and managing modules across the game
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true 
local MAX_REQUIRE_DEPTH = 10
local DEFAULT_TIMEOUT = 5 -- seconds

-- ModuleLoader object
local ModuleLoader = {
	_loadedModules = {}, -- Cache of loaded modules
	_loadAttempts = {}, -- Track how many times we've tried to load a module
	_version = VERSION,
	_nameToPaths = {}, -- Mapping from module names to possible paths
	_dependencies = {}, -- Track dependencies between modules
	_loadErrors = {}, -- Track errors during module loading
	_stats = {
		hits = 0, -- Cache hits
		misses = 0, -- Cache misses
		errors = 0 -- Error count
	}
}

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[ModuleLoader][%s] %s", level, message))
end

-- Safe require function that won't throw errors
local function safeRequire(moduleScript)
	if not moduleScript then
		return nil, "Module is nil"
	end
	
	if not moduleScript:IsA("ModuleScript") then
		return nil, "Instance is not a ModuleScript, but " .. moduleScript.ClassName
	end
	
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	if success then
		return result, nil
	else
		return nil, result
	end
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or DEFAULT_TIMEOUT
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

-- Resolve a path string to a ModuleScript instance
function ModuleLoader:ResolveModulePath(pathString)
	if not pathString then
		return nil, "Path string is nil"
	end
	
	-- Check if we've already resolved this path
	if self._resolvedPaths then
		local cached = self._resolvedPaths[pathString]
		if cached then
			return cached
		end
	else
		self._resolvedPaths = {}
	end
	
	local pathParts = string.split(pathString, ".")
	local current = game
	
	for i, part in ipairs(pathParts) do
		current = safeWaitForChild(current, part, DEFAULT_TIMEOUT)
		
		if not current then
			log("Failed to resolve path at part " .. i .. ": " .. part, "Warning")
			return nil, "Failed to find part: " .. part
		end
	end
	
	-- Cache the resolved path
	self._resolvedPaths[pathString] = current
	
	return current
end

-- Load a module by path string
function ModuleLoader:LoadModule(pathString)
	if not pathString then
		return nil, "Path string is nil"
	end
	
	-- Check if we've already loaded this module
	if self._loadedModules[pathString] then
		self._stats.hits += 1
		return self._loadedModules[pathString]
	end
	
	self._stats.misses += 1
	
	-- Track loading attempts
	self._loadAttempts[pathString] = (self._loadAttempts[pathString] or 0) + 1
	
	-- Check if we're trying to load this module too many times
	if self._loadAttempts[pathString] > MAX_REQUIRE_DEPTH then
		log("Circular dependency detected for: " .. pathString, "Error")
		self._stats.errors += 1
		self._loadErrors[pathString] = "Circular dependency"
		return nil, "Circular dependency"
	end
	
	-- Resolve the path to a ModuleScript instance
	local moduleScript, errorMsg = self:ResolveModulePath(pathString)
	if not moduleScript then
		log("Failed to resolve module path: " .. pathString .. " - " .. errorMsg, "Warning")
		self._stats.errors += 1
		self._loadErrors[pathString] = errorMsg
		return nil, errorMsg
	end
	
	-- Require the module
	local module, requireError = safeRequire(moduleScript)
	if not module then
		log("Failed to require module: " .. pathString .. " - " .. requireError, "Warning")
		self._stats.errors += 1
		self._loadErrors[pathString] = requireError
		return nil, requireError
	end
	
	-- Cache the loaded module
	self._loadedModules[pathString] = module
	
	-- Reset loading attempts
	self._loadAttempts[pathString] = 0
	
	return module
end

-- Load a module by name using registered paths
function ModuleLoader:LoadModuleByName(moduleName)
	if not moduleName then
		return nil, "Module name is nil"
	end
	
	-- Check if we have registered paths for this module
	local paths = self._nameToPaths[moduleName]
	if not paths or #paths == 0 then
		log("No paths registered for module: " .. moduleName, "Warning")
		return nil, "No paths registered"
	end
	
	-- Try each path until we find one that works
	for _, path in ipairs(paths) do
		local module, error = self:LoadModule(path)
		if module then
			return module
		end
	end
	
	log("Failed to load module by name: " .. moduleName .. " - No valid paths found", "Warning")
	return nil, "No valid paths found"
end

-- Register a path for a module name
function ModuleLoader:RegisterPath(moduleName, pathString)
	if not moduleName or not pathString then
		return false
	end
	
	-- Initialize the paths array if it doesn't exist
	if not self._nameToPaths[moduleName] then
		self._nameToPaths[moduleName] = {}
	end
	
	-- Add the path if it's not already registered
	local paths = self._nameToPaths[moduleName]
	for _, path in ipairs(paths) do
		if path == pathString then
			return true -- Already registered
		end
	end
	
	table.insert(paths, pathString)
	log("Registered path for " .. moduleName .. ": " .. pathString)
	
	return true
end

-- Get a loaded module
function ModuleLoader:GetModule(pathStringOrName)
	if not pathStringOrName then
		return nil, "Path string or name is nil"
	end
	
	-- Check if we've already loaded this module by path
	if self._loadedModules[pathStringOrName] then
		return self._loadedModules[pathStringOrName]
	end
	
	-- Check if we have registered paths for this module name
	if self._nameToPaths[pathStringOrName] then
		return self:LoadModuleByName(pathStringOrName)
	end
	
	-- Try to load the module by path
	return self:LoadModule(pathStringOrName)
end

-- Clear the module cache
function ModuleLoader:ClearCache(modulePath)
	if modulePath then
		-- Clear a specific module
		self._loadedModules[modulePath] = nil
		log("Cleared cache for module: " .. modulePath)
	else
		-- Clear all modules
		self._loadedModules = {}
		log("Cleared entire module cache")
	end
end

-- Get the loader version
function ModuleLoader:GetVersion()
	return self._version
end

-- Register common module paths
function ModuleLoader:RegisterCommonPaths()
	-- Core modules
	self:RegisterPath("CoreRegistry", "ServerScriptService.Core.CoreRegistry")
	self:RegisterPath("ClientRegistry", "ReplicatedStorage.shared.ClientRegistry")
	self:RegisterPath("ClientRegistry", "ReplicatedStorage.src.client.Core.ClientRegistry")
	
	-- UI modules
	self:RegisterPath("UIComponents", "ReplicatedStorage.shared.UIComponents")
	self:RegisterPath("UIComponents", "ReplicatedStorage.UIModules.UIComponent")
	self:RegisterPath("UIComponents", "ReplicatedStorage.src.shared.UI.UIComponents")
	
	-- Utility modules
	self:RegisterPath("SafeWaitForChild", "ReplicatedStorage.shared.SafeWaitForChild")
	self:RegisterPath("SafeWaitForChild", "ReplicatedStorage.src.shared.Utils.SafeWaitForChild")
	
	-- System modules
	self:RegisterPath("GymAutomationManager", "ServerStorage.GymAutomationManager")
	self:RegisterPath("GymAutomationManager", "ServerScriptService.GymAutomation.GymAutomationManager")
	self:RegisterPath("GymAutomationManager", "ServerScriptService.server.GymAutomation.GymAutomationManager")
	
	log("Registered common module paths")
end

-- Register a dependency between modules
function ModuleLoader:RegisterDependency(moduleName, dependencyName)
	if not moduleName or not dependencyName then return false end
	
	if not self._dependencies[moduleName] then
		self._dependencies[moduleName] = {}
	end
	
	-- Add the dependency if it's not already registered
	local deps = self._dependencies[moduleName]
	for _, dep in ipairs(deps) do
		if dep == dependencyName then
			return true -- Already registered
		end
	end
	
	table.insert(deps, dependencyName)
	log("Registered dependency: " .. moduleName .. " depends on " .. dependencyName)
	return true
end

-- Get all dependencies for a module
function ModuleLoader:GetDependencies(moduleName)
	return self._dependencies[moduleName] or {}
end

-- Check if loading a module would create a circular dependency
function ModuleLoader:WouldCreateCircularDependency(moduleName, dependencyChain)
	dependencyChain = dependencyChain or {}
	
	-- If the module is already in the dependency chain, it would create a circular dependency
	for _, mod in ipairs(dependencyChain) do
		if mod == moduleName then
			return true, dependencyChain
		end
	end
	
	-- Add this module to the dependency chain
	local newChain = table.clone(dependencyChain)
	table.insert(newChain, moduleName)
	
	-- Check all dependencies of this module
	local dependencies = self:GetDependencies(moduleName)
	for _, depName in ipairs(dependencies) do
		local wouldCreateCircular, chain = self:WouldCreateCircularDependency(depName, newChain)
		if wouldCreateCircular then
			return true, chain
		end
	end
	
	return false, nil
end

-- Get diagnostics about the ModuleLoader state
function ModuleLoader:GetDiagnostics()
	local loadedModuleCount = 0
	for _ in pairs(self._loadedModules) do
		loadedModuleCount += 1
	end
	
	local registeredPathCount = 0
	for _, paths in pairs(self._nameToPaths) do
		registeredPathCount += #paths
	end
	
	local dependencyCount = 0
	for _, deps in pairs(self._dependencies) do
		dependencyCount += #deps
	end
	
	local errorCount = 0
	for _ in pairs(self._loadErrors) do
		errorCount += 1
	end
	
	return {
		version = self._version,
		loadedModules = loadedModuleCount,
		registeredPaths = registeredPathCount,
		dependencies = dependencyCount,
		errors = errorCount,
		stats = self._stats
	}
end

-- Get all loaded modules
function ModuleLoader:GetLoadedModules()
	local modules = {}
	for path, module in pairs(self._loadedModules) do
		modules[path] = module
	end
	return modules
end

-- Get all loading errors
function ModuleLoader:GetLoadErrors()
	return self._loadErrors
end

-- Attempt to reload a failed module
function ModuleLoader:RetryFailedModule(pathStringOrName)
	if not pathStringOrName then return nil, "Path string or name is nil" end
	
	-- Clear any cached errors for this module
	self._loadErrors[pathStringOrName] = nil
	
	-- Clear any cached instances of this module
	self._loadedModules[pathStringOrName] = nil
	
	-- Try loading the module again
	return self:GetModule(pathStringOrName)
end

-- Initialize the ModuleLoader
do
	log("Initializing ModuleLoader v" .. VERSION)
	ModuleLoader:RegisterCommonPaths()
	-- Register new paths for newly created modules
	ModuleLoader:RegisterPath("UIComponents", "ReplicatedStorage.shared.UIComponents")
	ModuleLoader:RegisterPath("AssetValidator", "ReplicatedStorage.shared.AssetValidator")
	ModuleLoader:RegisterPath("UIRegistry", "ReplicatedStorage.shared.UIRegistry")
	ModuleLoader:RegisterPath("SystemDiagnostics", "ReplicatedStorage.shared.SystemDiagnostics")
	ModuleLoader:RegisterPath("SafeRequireModule", "ReplicatedStorage.shared.SafeRequireModule")
	
	-- Log initialization success
	log("ModuleLoader successfully initialized")
end

-- Return the ModuleLoader instance
return ModuleLoader
