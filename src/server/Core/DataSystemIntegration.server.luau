--!strict
--[[
    DataSystemIntegration.server.luau
    
    Coordinates between DataAccessLayer and other game systems.
    Ensures proper initialization order and data flow between systems.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Major overhaul for improved reliability
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    initializationOrder = {
        "DataAccessLayer",
        "DataManager",
        "DataPersistenceManager",
        "VersionedDataStore",
        "DataMigrationUtility"
    }
}

-- DataSystemIntegration module
local DataSystemIntegration = {
    Version = "2.0.0",
    initialized = false,
    systems = {},
    systemStatus = {},
    healthCheckInterval = 30 -- seconds
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[DataSystemIntegration]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Initialize a system
local function initializeSystem(systemName, system)
    if not system then
        log("System not found: " .. systemName, "error")
        return false
    end
    
    -- Check if already initialized
    if DataSystemIntegration.systemStatus[systemName] == "initialized" then
        return true
    end
    
    -- Mark as initializing
    DataSystemIntegration.systemStatus[systemName] = "initializing"
    
    -- Initialize the system
    local success, result = pcall(function()
        if type(system.initialize) == "function" then
            return system:initialize()
        elseif type(system.Initialize) == "function" then
            return system:Initialize()
        end
        return true
    end)
    
    if not success then
        log("Failed to initialize system: " .. systemName .. " - " .. tostring(result), "error")
        DataSystemIntegration.systemStatus[systemName] = "failed"
        return false
    end
    
    -- Mark as initialized
    DataSystemIntegration.systemStatus[systemName] = "initialized"
    log("Initialized system: " .. systemName)
    return true
end

-- Get a system module
local function getSystemModule(systemName)
    -- Try to get from CoreRegistry first
    local system = CoreRegistry:getSystem(systemName)
    if system then
        return system
    end
    
    -- Try to load from Core folder
    local success, result = pcall(function()
        return require(ServerScriptService.Core[systemName])
    end)
    
    if success and result then
        return result
    end
    
    -- Try to load from Data folder
    success, result = pcall(function()
        return require(ServerScriptService.Data[systemName])
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

-- Set up health monitoring
local function setupHealthMonitoring()
    task.spawn(function()
        while true do
            task.wait(DataSystemIntegration.healthCheckInterval)
            
            for systemName, system in pairs(DataSystemIntegration.systems) do
                -- Check system health
                local isHealthy = true
                if type(system.isHealthy) == "function" then
                    isHealthy = system:isHealthy()
                elseif type(system.IsHealthy) == "function" then
                    isHealthy = system:IsHealthy()
                end
                
                -- Update status
                if not isHealthy then
                    log("System unhealthy: " .. systemName, "warn")
                    DataSystemIntegration.systemStatus[systemName] = "unhealthy"
                    
                    -- Attempt recovery
                    if type(system.recover) == "function" then
                        local success = system:recover()
                        if success then
                            log("Recovered system: " .. systemName)
                            DataSystemIntegration.systemStatus[systemName] = "initialized"
                        end
                    elseif type(system.Recover) == "function" then
                        local success = system:Recover()
                        if success then
                            log("Recovered system: " .. systemName)
                            DataSystemIntegration.systemStatus[systemName] = "initialized"
                        end
                    end
                end
            end
        end
    end)
end

-- Initialize DataSystemIntegration
function DataSystemIntegration:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataSystemIntegration v" .. self.Version)
    
    -- Initialize systems in order
    for _, systemName in ipairs(CONFIG.initializationOrder) do
        local system = getSystemModule(systemName)
        if system then
            self.systems[systemName] = system
            if not initializeSystem(systemName, system) then
                log("Failed to initialize system: " .. systemName, "error")
            end
        else
            log("Could not find system: " .. systemName, "warn")
        end
    end
    
    -- Set up health monitoring
    setupHealthMonitoring()
    
    self.initialized = true
    log("DataSystemIntegration initialized successfully")
    return true
end

-- Get system status
function DataSystemIntegration:GetSystemStatus(systemName)
    return self.systemStatus[systemName]
end

-- Get all system statuses
function DataSystemIntegration:GetAllSystemStatuses()
    return deepCopy(self.systemStatus)
end

-- Check if initialized
function DataSystemIntegration:IsInitialized()
    return self.initialized
end

-- Check if healthy
function DataSystemIntegration:IsHealthy()
    if not self.initialized then
        return false
    end
    
    -- Check if all critical systems are healthy
    for systemName, status in pairs(self.systemStatus) do
        if status ~= "initialized" then
            return false
        end
    end
    
    return true
end

-- Recover from failure
function DataSystemIntegration:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    
    log("Attempting recovery")
    
    -- Reinitialize all systems
    for systemName, system in pairs(self.systems) do
        if self.systemStatus[systemName] ~= "initialized" then
            if initializeSystem(systemName, system) then
                log("Recovered system: " .. systemName)
            else
                log("Failed to recover system: " .. systemName, "error")
            end
        end
    end
    
    return self:IsHealthy()
end

-- Register with CoreRegistry
if CoreRegistry then
    CoreRegistry.registerSystem("DataSystemIntegration", DataSystemIntegration)
end

return DataSystemIntegration 