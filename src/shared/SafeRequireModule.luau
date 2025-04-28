-- SafeRequireModule.luau
-- Utility for safely requiring modules while avoiding circular dependencies
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local DEFAULT_TIMEOUT = 5 -- seconds

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[SafeRequireModule][%s] %s", level, message))
end

-- Local helper variables
local _requiringModules = {}
local _loadedModules = {}
local _deferredCallbacks = {}

-- Safe Require Module object
local SafeRequireModule = {
	_version = VERSION
}

-- Try to get ModuleLoader
local function getModuleLoader()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild("ModuleLoader") then
		local success, result = pcall(function()
			return require(shared.ModuleLoader)
		end)
		
		if success then
			return result
		end
	end
	
	return nil
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

-- Find a module by name or path
local function findModule(moduleNameOrPath)
	-- Check if it's a direct instance reference
	if typeof(moduleNameOrPath) == "Instance" and moduleNameOrPath:IsA("ModuleScript") then
		return moduleNameOrPath
	end
	
	-- Try using ModuleLoader if available
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		local resolved = moduleLoader:ResolveModulePath(moduleNameOrPath)
		if resolved and resolved:IsA("ModuleScript") then
			return resolved
		end
	end
	
	-- Try direct path
	if type(moduleNameOrPath) == "string" then
		local parts = string.split(moduleNameOrPath, ".")
		local current = game
		
		for i, part in ipairs(parts) do
			current = safeWaitForChild(current, part)
			if not current then
				return nil
			end
		end
		
		if current:IsA("ModuleScript") then
			return current
		end
	end
	
	return nil
end

-- Check if we're in a circular require
local function isCircularRequire(moduleScript)
	local name = moduleScript:GetFullName()
	return _requiringModules[name] ~= nil
end

-- Safe require with circular dependency handling
function SafeRequireModule:Require(moduleNameOrPath)
	-- Handle nil input
	if moduleNameOrPath == nil then
		log("Module name or path is nil", "Error")
		return nil
	end
	
	-- Find the module
	local moduleScript = findModule(moduleNameOrPath)
	if not moduleScript then
		log("Module not found: " .. tostring(moduleNameOrPath), "Error")
		return nil
	end
	
	-- Get module name for tracking
	local name = moduleScript:GetFullName()
	
	-- Check if already loaded
	if _loadedModules[name] then
		return _loadedModules[name]
	end
	
	-- Check for circular dependency
	if isCircularRequire(moduleScript) then
		log("Circular dependency detected for: " .. name, "Warning")
		
		-- Return a proxy object that will be filled when the module is actually loaded
		local proxy = {}
		
		-- Add to deferred callbacks
		_deferredCallbacks[name] = _deferredCallbacks[name] or {}
		table.insert(_deferredCallbacks[name], function(actualModule)
			-- Copy all properties from the actual module to the proxy
			for key, value in pairs(actualModule) do
				proxy[key] = value
			end
		end)
		
		return proxy
	end
	
	-- Mark as requiring
	_requiringModules[name] = true
	
	-- Require the module
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	-- Unmark as requiring
	_requiringModules[name] = nil
	
	-- Handle result
	if success then
		-- Store in loaded modules
		_loadedModules[name] = result
		
		-- Run deferred callbacks
		if _deferredCallbacks[name] then
			for _, callback in ipairs(_deferredCallbacks[name]) do
				pcall(callback, result)
			end
			_deferredCallbacks[name] = nil
		end
		
		return result
	else
		log("Error requiring module: " .. name .. " - " .. tostring(result), "Error")
		return nil
	end
end

-- Require with timeout to prevent infinite yield
function SafeRequireModule:RequireWithTimeout(moduleNameOrPath, timeout)
	timeout = timeout or DEFAULT_TIMEOUT
	
	-- Try to require within the timeout
	local result = nil
	local completed = false
	
	-- Spawn a thread to require the module
	local thread = coroutine.create(function()
		result = self:Require(moduleNameOrPath)
		completed = true
	end)
	
	-- Start the thread
	coroutine.resume(thread)
	
	-- Wait for completion or timeout
	local startTime = os.clock()
	while not completed and os.clock() - startTime < timeout do
		wait(0.1)
	end
	
	if not completed then
		log("Require timed out after " .. timeout .. " seconds: " .. tostring(moduleNameOrPath), "Warning")
		return nil
	end
	
	return result
end

-- Get list of loaded modules
function SafeRequireModule:GetLoadedModules()
	local modules = {}
	for name, _ in pairs(_loadedModules) do
		table.insert(modules, name)
	end
	return modules
end

-- Clear cache for a specific module
function SafeRequireModule:ClearCache(moduleNameOrPath)
	local moduleScript = findModule(moduleNameOrPath)
	if not moduleScript then
		return false
	end
	
	local name = moduleScript:GetFullName()
	if _loadedModules[name] then
		_loadedModules[name] = nil
		log("Cleared cache for module: " .. name)
		return true
	end
	
	return false
end

-- Clear all cached modules
function SafeRequireModule:ClearAllCache()
	_loadedModules = {}
	log("Cleared all module cache")
	return true
end

-- Check if module is available without requiring it
function SafeRequireModule:IsModuleAvailable(moduleNameOrPath)
	local moduleScript = findModule(moduleNameOrPath)
	return moduleScript ~= nil
end

-- Wait for a module to be available
function SafeRequireModule:WaitForModule(moduleNameOrPath, timeout)
	timeout = timeout or DEFAULT_TIMEOUT
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		if self:IsModuleAvailable(moduleNameOrPath) then
			return true
		end
		wait(0.1)
	end
	
	log("Timed out waiting for module: " .. tostring(moduleNameOrPath), "Warning")
	return false
end

-- Pre-load modules in background
function SafeRequireModule:PreloadModules(moduleList)
	if type(moduleList) ~= "table" then
		log("Module list must be a table", "Error")
		return false
	end
	
	log("Preloading " .. #moduleList .. " modules")
	
	-- Spawn a thread to preload the modules
	spawn(function()
		for _, moduleNameOrPath in ipairs(moduleList) do
			self:Require(moduleNameOrPath)
			wait() -- Yield to prevent freezing
		end
		log("Finished preloading modules")
	end)
	
	return true
end

-- Get the SafeRequireModule version
function SafeRequireModule:GetVersion()
	return self._version
end

-- Register with ModuleLoader if available
do
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		moduleLoader:RegisterPath("SafeRequireModule", "ReplicatedStorage.shared.SafeRequireModule")
		log("Registered with ModuleLoader")
	end
end

return SafeRequireModule
