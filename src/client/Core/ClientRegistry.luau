-- ClientRegistry.luau
-- Client-side registry for UI components and client systems
-- Created: April 28, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a single ClientRegistry object
local ClientRegistry = {
	_registered = {},
	_version = "1.0.0",
	_loaded = os.clock(),
	_health = "OPERATIONAL",
	_systems = {},
	_components = {},
}

-- Register a module or system with the ClientRegistry
function ClientRegistry:Register(name, module)
	if self._registered[name] then
		warn("ClientRegistry: Overwriting existing registration for " .. name)
	end
	self._registered[name] = module
	print("ClientRegistry: Registered " .. name)
	return true
end

-- Register a UI component
function ClientRegistry:RegisterComponent(name, component)
	self._components[name] = component
	self:Register("UI_" .. name, component) -- Also add to general registry
	return true
end

-- Register a client system
function ClientRegistry:RegisterSystem(name, system)
	self._systems[name] = system
	self:Register("System_" .. name, system) -- Also add to general registry
	return true
end

-- Get a registered module or system
function ClientRegistry:Get(name)
	return self._registered[name]
end

-- Get a UI component
function ClientRegistry:GetComponent(name)
	return self._components[name]
end

-- Get a client system
function ClientRegistry:GetSystem(name)
	return self._systems[name]
end

-- Check if a module or system is registered
function ClientRegistry:HasComponent(name)
	return self._components[name] ~= nil
end

-- Check if a client system is registered
function ClientRegistry:HasSystem(name)
	return self._systems[name] ~= nil
end

-- Get all registered modules and systems
function ClientRegistry:GetAll()
	return self._registered
end

-- Get all registered UI components
function ClientRegistry:GetAllComponents()
	return self._components
end

-- Get all registered client systems
function ClientRegistry:GetAllSystems()
	return self._systems
end

-- Get registry version
function ClientRegistry:GetVersion()
	return self._version
end

-- Health check
function ClientRegistry:HealthCheck()
	return {
		status = self._health,
		version = self._version,
		uptime = os.clock() - self._loaded,
		registeredCount = #self:GetRegisteredNames(),
		componentsCount = #self:GetComponentNames(),
		systemsCount = #self:GetSystemNames(),
	}
end

-- Get list of registered names
function ClientRegistry:GetRegisteredNames()
	local names = {}
	for name, _ in pairs(self._registered) do
		table.insert(names, name)
	end
	return names
end

-- Get list of registered component names
function ClientRegistry:GetComponentNames()
	local names = {}
	for name, _ in pairs(self._components) do
		table.insert(names, name)
	end
	return names
end

-- Get list of registered system names
function ClientRegistry:GetSystemNames()
	local names = {}
	for name, _ in pairs(self._systems) do
		table.insert(names, name)
	end
	return names
end

-- For diagnostics and debugging
function ClientRegistry:__tostring()
	return "ClientRegistry (v" .. self._version .. ")" .. 
		" | Status: " .. self._health .. 
		" | Systems: " .. #self:GetSystemNames() ..
		" | Components: " .. #self:GetComponentNames()
end

-- Make the registry accessible for debugging
if _G then
	_G.__ClientRegistry = ClientRegistry
end

-- This line is crucial - return ONLY the ClientRegistry object
return ClientRegistry
