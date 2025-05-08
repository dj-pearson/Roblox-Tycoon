-- filepath: c:\Users\dpearson\OneDrive\Documents\RobloxProject\src\server\Core\CoreRegistry.luau
--[[
    CoreRegistry.luau
    
    Registry for critical core systems in the game.
    This module provides central access to critical systems and manages system interdependencies.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed initialization and critical system handling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CoreRegistry = {}
CoreRegistry.initialized = false

-- Registry status enum
local RegistryStatus = {
    Initializing = "Initializing",
    Ready = "Ready",
    Degraded = "Degraded",
    Error = "Error"
}

-- Current registry status
local status = RegistryStatus.Initializing

-- Debug settings
CoreRegistry.DEBUG = true

-- Critical system names
local CRITICAL_SYSTEMS = {
    "ModuleLoader",
    "DataManager",
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem",
    "TycoonSystem",
    "EventBridge"
}

-- The systems registry - stores system objects with metadata
local systems = {}
local systemStatus = {} -- Tracks initialization status of each system

-- Log a message to the output
local function log(message)
    if CoreRegistry.DEBUG then
        print("[CoreRegistry] " .. message)
    end
end

-- Function to check if all critical systems are registered
function CoreRegistry.checkCriticalSystems()
    local criticalCount = 0
    local missingCritical = {}
    local failedCritical = {}
    
    for _, systemName in ipairs(CRITICAL_SYSTEMS) do
        if systems[systemName] then
            if systemStatus[systemName] == "Initialized" then
                criticalCount += 1
            else
                table.insert(failedCritical, systemName)
            end
        else
            table.insert(missingCritical, systemName)
        end
    end
    
    -- Calculate total critical systems
    local totalCritical = #CRITICAL_SYSTEMS
    
    -- Update status based on critical systems
    if criticalCount == 0 then
        status = RegistryStatus.Error
        log("Registry status set to: Error")
    elseif criticalCount < totalCritical then
        status = RegistryStatus.Degraded
        log("Registry status set to: Degraded")
    else
        status = RegistryStatus.Ready
        log("Registry status set to: Ready")
    end
    
    -- Output missing systems
    for _, systemName in ipairs(missingCritical) do
        log("Critical system missing: " .. systemName)
    end
    
    -- Output failed systems
    for _, systemName in ipairs(failedCritical) do
        log("Critical system failed to initialize: " .. systemName)
    end
    
    return criticalCount, totalCritical
end

-- Function to register a system
function CoreRegistry.registerSystem(systemName, systemInstance, dependencies)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to registerSystem")
        return false
    end
    
    if not systemInstance then
        warn("[CoreRegistry] Invalid system object for " .. systemName)
        return false
    end
    
    log("Registering system: " .. systemName)
    
    -- Check dependencies if provided
    if dependencies and type(dependencies) == "table" then
        for _, depName in ipairs(dependencies) do
            if not systems[depName] then
                warn("[CoreRegistry] Dependency not found: " .. depName .. " for system: " .. systemName)
                return false
            end
        end
    end
    
    systems[systemName] = {
        instance = systemInstance,
        timestamp = os.time(),
        dependencies = dependencies or {}
    }
    
    -- Set initial status
    systemStatus[systemName] = "Registered"
    
    -- Update registry status if this was a critical system
    if table.find(CRITICAL_SYSTEMS, systemName) then
        CoreRegistry.checkCriticalSystems()
    end
    
    return true
end

-- Function to get a system by name
function CoreRegistry.getSystem(systemName)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to getSystem")
        return nil
    end
    
    if not systems[systemName] then
        log("System not found: " .. systemName)
        return nil
    end
    
    return systems[systemName].instance
end

-- Alias for getSystem for backward compatibility
CoreRegistry.GetSystem = CoreRegistry.getSystem

-- Function to get registry status
function CoreRegistry.getStatus()
    return status
end

-- Function to mark a system as initialized
function CoreRegistry.markInitialized(systemName)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to markInitialized")
        return false
    end
    
    if not systems[systemName] then
        warn("[CoreRegistry] System not found: " .. systemName)
        return false
    end
    
    log("Marking system as initialized: " .. systemName)
    systemStatus[systemName] = "Initialized"
    
    -- Update registry status if this was a critical system
    if table.find(CRITICAL_SYSTEMS, systemName) then
        CoreRegistry.checkCriticalSystems()
    end
    
    return true
end

-- Function to get system status
function CoreRegistry.getSystemStatus(systemName)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to getSystemStatus")
        return nil
    end
    
    return systemStatus[systemName]
end

-- Function to get all system statuses
function CoreRegistry.getAllSystemStatuses()
    local statuses = {}
    for name, _ in pairs(systems) do
        statuses[name] = systemStatus[name]
    end
    return statuses
end

-- Function to run a health check
function CoreRegistry.runHealthCheck()
    log("Running health check...")
    local criticalCount, totalCritical = CoreRegistry.checkCriticalSystems()
    
    -- Print detailed status
    log("Registry Status: " .. status)
    log("Critical Systems: " .. criticalCount .. "/" .. totalCritical)
    
    -- Print system statuses
    log("System Statuses:")
    for name, status in pairs(systemStatus) do
        log("  - " .. name .. ": " .. status)
    end
    
    return criticalCount, totalCritical
end

-- Initialize the registry
function CoreRegistry.initialize()
    if CoreRegistry.initialized then
        return
    end
    
    log("Initializing CoreRegistry...")
    
    -- Self-register
    CoreRegistry.registerSystem("CoreRegistry", CoreRegistry)
    CoreRegistry.markInitialized("CoreRegistry")
    
    CoreRegistry.initialized = true
    log("CoreRegistry initialized")
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(systemName)
    return systems[systemName] ~= nil
end

-- Get all registered system names
function CoreRegistry.getSystemNames()
    local names = {}
    for name, _ in pairs(systems) do
        table.insert(names, name)
    end
    return names
end

-- Get a list of missing critical systems
function CoreRegistry.getMissingCriticalSystems()
    local missing = {}
    for _, name in ipairs(CRITICAL_SYSTEMS) do
        if not systems[name] then
            table.insert(missing, name)
        end
    end
    return missing
end

-- Get system info (excluding the actual system instance)
function CoreRegistry.getSystemInfo(name)
    if not systems[name] then
        return nil
    end
    
    return {
        name = name,
        registered = systems[name].timestamp,
        isCritical = table.find(CRITICAL_SYSTEMS, name) ~= nil
    }
end

-- Get all registered systems and their info
function CoreRegistry.getSystemsInfo()
    local info = {}
    for name, _ in pairs(systems) do
        info[name] = CoreRegistry.getSystemInfo(name)
    end
    return info
end

return CoreRegistry
