-- SystemBootstrap.server.luau
-- Coordinates the initialization of all core systems
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[SystemBootstrap][%s] %s", level, message))
end

-- Safe WaitForChild function with timeout
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

-- Safe require function that won't throw errors
local function safeRequire(moduleScript)
	if not moduleScript then
		return nil, "Module is nil"
	end
	
	if not moduleScript:IsA("ModuleScript") then
		return nil, "Not a ModuleScript"
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

-- Find a module script in multiple possible locations
local function findModule(moduleName, defaultParent)
	-- First check if the module is directly a child of the default parent
	if defaultParent and defaultParent:FindFirstChild(moduleName) then
		return defaultParent:FindFirstChild(moduleName)
	end
	
	-- Check in ServerScriptService.Core
	local core = ServerScriptService:FindFirstChild("Core")
	if core and core:FindFirstChild(moduleName) then
		return core:FindFirstChild(moduleName)
	end
	
	-- Check in ReplicatedStorage.shared
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild(moduleName) then
		return shared:FindFirstChild(moduleName)
	end
	
	-- Check in ReplicatedStorage.src.shared
	local src = ReplicatedStorage:FindFirstChild("src")
	if src and src:FindFirstChild("shared") and src.shared:FindFirstChild(moduleName) then
		return src.shared:FindFirstChild(moduleName)
	end
	
	-- Not found
	return nil
end

-- System bootstrap object
local SystemBootstrap = {
	_version = VERSION,
	_systems = {}, -- Loaded systems
	_initOrder = {}, -- Order of system initialization
	_dependencies = {}, -- System dependencies
	_systemsInitialized = 0,
	_systemsFailed = 0
}

-- Define the initialization order for core systems
SystemBootstrap._initOrder = {
	"FolderSetup",
	"CoreRegistry",
	"ModuleLoader",
	"EventCreator",
	"AllianceEventSetup",
	"DataManager",
	"GymTycoonConnector",
	"GymAutomationManager",
	"NPCSystem",
	"PerformanceManager",
	"RevenueSystem",
	"SatisfactionSystem",
	"JobSystem",
	"GymSpecializationSystem",
	"CompetitionSystem"
}

-- Define system dependencies
SystemBootstrap._dependencies = {
	CoreRegistry = {},
	ModuleLoader = { "CoreRegistry" },
	EventCreator = { "CoreRegistry" },
	AllianceEventSetup = { "EventCreator" },
	DataManager = { "CoreRegistry", "ModuleLoader" },
	GymTycoonConnector = { "CoreRegistry" },
	GymAutomationManager = { "CoreRegistry" },
	NPCSystem = { "CoreRegistry", "DataManager" },
	PerformanceManager = { "CoreRegistry" },
	RevenueSystem = { "CoreRegistry", "DataManager" },
	SatisfactionSystem = { "CoreRegistry", "DataManager", "NPCSystem" },
	JobSystem = { "CoreRegistry", "DataManager" },
	GymSpecializationSystem = { "CoreRegistry", "DataManager", "RevenueSystem" },
	CompetitionSystem = { "CoreRegistry", "DataManager", "GymSpecializationSystem" }
}

-- Get CoreRegistry
function SystemBootstrap:GetCoreRegistry()
	local core = ServerScriptService:FindFirstChild("Core")
	if not core then
		log("Core folder not found in ServerScriptService", "Error")
		return nil
	end
	
	local coreRegistryModule = core:FindFirstChild("CoreRegistry")
	if not coreRegistryModule then
		log("CoreRegistry not found in Core folder", "Error")
		return nil
	end
	
	local coreRegistry, errorMessage = safeRequire(coreRegistryModule)
	if not coreRegistry then
		log("Failed to require CoreRegistry: " .. tostring(errorMessage), "Error")
		return nil
	end
	
	return coreRegistry
end

-- Initialize a specific system
function SystemBootstrap:InitializeSystem(systemName)
	log("Initializing system: " .. systemName)
	
	-- Check if we've already initialized this system
	if self._systems[systemName] then
		log("System already initialized: " .. systemName)
		return true
	end
	
	-- Check if dependencies are initialized
	local dependencies = self._dependencies[systemName] or {}
	for _, depName in ipairs(dependencies) do
		if not self._systems[depName] then
			log("Dependency not initialized: " .. depName .. " for system " .. systemName, "Error")
			return false
		end
	end
	
	-- Find the system module
	local systemModule = findModule(systemName, ServerScriptService:FindFirstChild("Core"))
	if not systemModule then
		log("System module not found: " .. systemName, "Error")
		self._systemsFailed = self._systemsFailed + 1
		return false
	end
	
	-- Require the system module
	local system, errorMessage = safeRequire(systemModule)
	if not system then
		log("Failed to require system: " .. systemName .. " - " .. tostring(errorMessage), "Error")
		self._systemsFailed = self._systemsFailed + 1
		return false
	end
	
	-- Check if the system has an Initialize method
	if type(system.Initialize) == "function" then
		-- Initialize the system
		local success, initResult = pcall(function()
			return system:Initialize()
		end)
		
		if not success then
			log("Failed to initialize system: " .. systemName .. " - " .. tostring(initResult), "Error")
			self._systemsFailed = self._systemsFailed + 1
			return false
		end
	end
	
	-- Register the system with CoreRegistry if available
	local coreRegistry = self:GetCoreRegistry()
	if coreRegistry and type(coreRegistry.Register) == "function" then
		coreRegistry:Register(systemName, system)
		log("Registered system with CoreRegistry: " .. systemName)
	end
	
	-- Store the system
	self._systems[systemName] = system
	self._systemsInitialized = self._systemsInitialized + 1
	
	log("Successfully initialized system: " .. systemName)
	return true
end

-- Initialize all systems in the correct order
function SystemBootstrap:InitializeAllSystems()
	log("Starting system initialization...")
	
	-- Reset counters
	self._systemsInitialized = 0
	self._systemsFailed = 0
	
	-- Initialize each system in order
	for _, systemName in ipairs(self._initOrder) do
		self:InitializeSystem(systemName)
		wait(0.1) -- Small delay between systems
	end
	
	log("System initialization complete. Initialized: " .. self._systemsInitialized .. ", Failed: " .. self._systemsFailed)
	
	return self._systemsInitialized > 0
end

-- Get system diagnostic information
function SystemBootstrap:GetDiagnostics()
	local initializedSystems = {}
	local failedSystems = {}
	
	for _, systemName in ipairs(self._initOrder) do
		if self._systems[systemName] then
			table.insert(initializedSystems, systemName)
		else
			table.insert(failedSystems, systemName)
		end
	end
	
	return {
		version = self._version,
		systemsInitialized = self._systemsInitialized,
		systemsFailed = self._systemsFailed,
		initializedSystems = initializedSystems,
		failedSystems = failedSystems
	}
end

-- Get the bootstrap version
function SystemBootstrap:GetVersion()
	return self._version
end

-- Initialize the system bootstrap
log("SystemBootstrap v" .. VERSION .. " initialized")

-- Make globally accessible for debugging
if _G then
	_G.__SystemBootstrap = SystemBootstrap
end

-- Start system initialization
spawn(function()
	wait(1) -- Wait a bit for other scripts to load
	SystemBootstrap:InitializeAllSystems()
end)

return SystemBootstrap
