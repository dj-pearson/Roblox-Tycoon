-- CoreRegistryInitializer.server.luau
-- Early-loading script to ensure CoreRegistry is available
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local CORE_REGISTRY_PATH = ServerScriptService:WaitForChild("Core", 5)
local TIMEOUT = 5 -- seconds to wait before creating fallback
local VERSION = "1.0.0"
local DEBUG = true -- Set to true for verbose logging

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[CoreRegistryInitializer][%s] %s", level, message))
end

-- Create folders if they don't exist
local function ensureFolderExists(parent, name)
	if not parent:FindFirstChild(name) then
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		log("Created folder: " .. parent.Name .. "/" .. name, "Warning")
	end
	return parent:FindFirstChild(name)
end

-- Initialize required folders
log("Starting CoreRegistry initialization")
local Core = ensureFolderExists(ServerScriptService, "Core")

-- Create a CoreRegistry if one doesn't exist
local function createCoreRegistry()
	log("Creating CoreRegistry module", "Warning")
	
	local coreRegistry = Instance.new("ModuleScript")
	coreRegistry.Name = "CoreRegistry"
	coreRegistry.Parent = Core
	
	-- Basic implementation of CoreRegistry
	coreRegistry.Source = [[
		-- CoreRegistry Module
		-- Auto-generated fallback implementation
		-- Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
		
		local CoreRegistry = {
			_registered = {},
			_version = "]] .. VERSION .. [[",
			_isFallback = true,
			_loaded = os.clock(),
			_health = "OPERATIONAL",
		}
		
		-- Register a module or system with the CoreRegistry
		function CoreRegistry:Register(name, module)
			if self._registered[name] then
				warn("CoreRegistry: Overwriting existing registration for " .. name)
			end
			self._registered[name] = module
			print("CoreRegistry: Registered " .. name)
			return true
		end
		
		-- Get a registered module or system
		function CoreRegistry:Get(name)
			return self._registered[name]
		end
		
		-- Check if a module or system is registered
		function CoreRegistry:HasSystem(name)
			return self._registered[name] ~= nil
		end
		
		-- Get all registered modules and systems
		function CoreRegistry:GetAll()
			return self._registered
		end
		
		-- Get registry version
		function CoreRegistry:GetVersion()
			return self._version
		end
		
		-- Health check
		function CoreRegistry:HealthCheck()
			return {
				status = self._health,
				version = self._version,
				isFallback = self._isFallback,
				uptime = os.clock() - self._loaded,
				registeredCount = #self:GetRegisteredNames(),
			}
		end
		
		-- Get list of registered names
		function CoreRegistry:GetRegisteredNames()
			local names = {}
			for name, _ in pairs(self._registered) do
				table.insert(names, name)
			end
			return names
		end
		
		-- For diagnostics and debugging
		function CoreRegistry:__tostring()
			return "CoreRegistry (v" .. self._version .. ")" .. 
				" | Status: " .. self._health .. 
				" | Systems: " .. #self:GetRegisteredNames()
		end
		
		return CoreRegistry
	]]
	
	return coreRegistry
end

-- Try to find the existing CoreRegistry, or create a fallback
local function initializeCoreRegistry()
	local coreRegistry
	
	-- Try to find existing CoreRegistry
	if Core:FindFirstChild("CoreRegistry") then
		coreRegistry = Core:FindFirstChild("CoreRegistry")
		log("Found existing CoreRegistry module")
	else
		-- Create a new CoreRegistry module
		coreRegistry = createCoreRegistry()
		log("Created fallback CoreRegistry module", "Warning")
	end
	
	-- Make sure we have a valid module
	local success, registry = pcall(function()
		return require(coreRegistry)
	end)
	
	if success then
		-- CoreRegistry loaded successfully
		log("CoreRegistry loaded successfully: v" .. registry:GetVersion())
		
		-- Global access for debugging
		_G.__CoreRegistry = registry
		_G.CoreRegistry = registry
		
		-- Create a health check feedback system
		spawn(function()
			while wait(5) do
				local health = registry:HealthCheck()
				log("CoreRegistry health: " .. health.status .. " | Systems: " .. health.registeredCount)
			end
		end)
		
		return registry
	else
		-- Failed to load CoreRegistry
		warn("Failed to load CoreRegistry: " .. registry)
		return nil
	end
end

-- Initialize CoreRegistry
local CoreRegistry = initializeCoreRegistry()

-- Create a shared variable to signal that CoreRegistry is ready
local signal = Instance.new("BoolValue")
signal.Name = "CoreRegistryAvailable"
signal.Value = CoreRegistry ~= nil
signal.Parent = ReplicatedStorage

-- Add a changed event to the signal
signal.Changed:Connect(function(newValue)
	if newValue then
		log("CoreRegistry is now available", "Info")
	else
		log("CoreRegistry is now unavailable", "Error")
	end
end)

log("CoreRegistry initialization complete. Status: " .. (signal.Value and "AVAILABLE" or "UNAVAILABLE"))

return CoreRegistry
