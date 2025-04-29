--[[
    CoreRegistry.luau
    
    A centralized registry for core game systems and modules.
    Handles registration, dependency management, and access to critical systems.
    
    Created as part of critical fixes on April 28, 2025.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Registry status constants
local STATUS = {
    UNAVAILABLE = "Unavailable", -- Registry not initialized yet
    AVAILABLE = "Available",     -- Registry is fully functional
    DEGRADED = "Degraded",       -- Registry is functional but missing critical systems
    ERROR = "Error"              -- Registry encountered a critical error
}

-- Core system definitions (these MUST be registered for proper operation)
local CRITICAL_SYSTEMS = {
    "ModuleLoader",
    "DataManager", 
    "TycoonSystem",
    "EventBridge",
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem"
}

-- Module
local CoreRegistry = {
    VERSION = "1.1.0",
    STATUS = STATUS,
}

-- Private state
local initialized = false
local systems = {}
local systemVersions = {}
local dependencies = {}
local status = STATUS.UNAVAILABLE
local isServer = RunService:IsServer()

-- Private functions
local function verifyInitialization()
    if not initialized then
        warn("[CoreRegistry] Attempting to use CoreRegistry before initialization")
        return false
    end
    return true
end

-- Check health of the registry
local function checkHealth()
    if not initialized then
        return STATUS.UNAVAILABLE
    end
    
    -- Count missing critical systems
    local missingCriticalSystems = {}
    for _, systemName in ipairs(CRITICAL_SYSTEMS) do
        if not systems[systemName] then
            table.insert(missingCriticalSystems, systemName)
        end
    end
    
    -- Determine status
    if #missingCriticalSystems == 0 then
        return STATUS.AVAILABLE
    elseif #missingCriticalSystems <= 2 then
        return STATUS.DEGRADED
    else
        return STATUS.ERROR
    end
end

-- Public methods
-- Initialize the CoreRegistry
function CoreRegistry.initialize()
    if initialized then
        return true
    end
    
    print("[CoreRegistry] Initializing CoreRegistry...")
    systems = {}
    systemVersions = {}
    dependencies = {}
    status = STATUS.UNAVAILABLE
    
    -- Create the registry object
    initialized = true
    status = checkHealth()
    
    -- Set up periodic health checks
    if isServer then
        task.spawn(function()
            while true do
                task.wait(30) -- Check every 30 seconds
                print("[CoreRegistry] Running health check...")
                local currentStatus = checkHealth()
                
                -- Log missing critical systems
                for _, systemName in ipairs(CRITICAL_SYSTEMS) do
                    if not systems[systemName] then
                        warn("[CoreRegistry] Critical system missing: " .. systemName)
                    end
                end
                
                -- Update status if changed
                if currentStatus ~= status then
                    print("[CoreRegistry] Registry status changed from " .. status .. " to " .. currentStatus)
                    status = currentStatus
                end
                
                print("[CoreRegistry] Registry status set to: " .. status)
            end
        end)
    end
    
    print("✅ [CoreRegistry] Initialized successfully!")
    return true
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, version)
    if not verifyInitialization() then
        return false
    end
    
    if not name or typeof(name) ~= "string" then
        warn("[CoreRegistry] Invalid system name")
        return false
    end
    
    if not system then
        warn("[CoreRegistry] Invalid system object for " .. name)
        return false
    end
    
    print("[CoreRegistry] Registering system: " .. name)
    systems[name] = system
    
    if version then
        systemVersions[name] = tostring(version)
    end
    
    -- Update status after registration
    status = checkHealth()
    
    return true
end

-- Get a system from the registry
function CoreRegistry.getSystem(name)
    if not verifyInitialization() then
        return nil
    end
    
    return systems[name]
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(name)
    if not verifyInitialization() then
        return false
    end
    
    return systems[name] ~= nil
end

-- Get the version of a system
function CoreRegistry.getSystemVersion(name)
    if not verifyInitialization() then
        return nil
    end
    
    return systemVersions[name]
end

-- Register a dependency
function CoreRegistry.registerDependency(system, dependsOn)
    if not verifyInitialization() then
        return false
    end
    
    if not dependencies[system] then
        dependencies[system] = {}
    end
    
    table.insert(dependencies[system], dependsOn)
    return true
end

-- Get all dependencies for a system
function CoreRegistry.getDependencies(system)
    if not verifyInitialization() then
        return {}
    end
    
    return dependencies[system] or {}
end

-- Get all registered systems
function CoreRegistry.getAllSystems()
    if not verifyInitialization() then
        return {}
    end
    
    return table.clone(systems)
end

-- Get the current status of the registry
function CoreRegistry.getStatus()
    return status
end

-- For testing: forcibly set a status (debug only)
function CoreRegistry.setStatus(newStatus)
    if table.find({STATUS.AVAILABLE, STATUS.DEGRADED, STATUS.ERROR, STATUS.UNAVAILABLE}, newStatus) then
        status = newStatus
        return true
    end
    return false
end

-- Create a global reference for easy access
_G.CoreRegistry = CoreRegistry

-- Initialize on load
CoreRegistry.initialize()

return CoreRegistry
