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
		return self._loadedModules[pathString]
	end
	
	-- Track loading attempts
	self._loadAttempts[pathString] = (self._loadAttempts[pathString] or 0) + 1
	
	-- Check if we're trying to load this module too many times
	if self._loadAttempts[pathString] > MAX_REQUIRE_DEPTH then
		log("Circular dependency detected for: " .. pathString, "Error")
		return nil, "Circular dependency"
	end
	
	-- Resolve the path to a ModuleScript instance
	local moduleScript, error = self:ResolveModulePath(pathString)
	if not moduleScript then
		log("Failed to resolve module path: " .. pathString .. " - " .. error, "Warning")
		return nil, error
	end
	
	-- Require the module
	local module, error = safeRequire(moduleScript)
	if not module then
		log("Failed to require module: " .. pathString .. " - " .. error, "Warning")
		return nil, error
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

-- Initialize the ModuleLoader
do
	log("Initializing ModuleLoader v" .. VERSION)
	ModuleLoader:RegisterCommonPaths()
	
	-- Make ModuleLoader available via _G for debugging
	if _G then
		_G.__ModuleLoader = ModuleLoader
	end
end

-- Return the ModuleLoader instance
return ModuleLoader
