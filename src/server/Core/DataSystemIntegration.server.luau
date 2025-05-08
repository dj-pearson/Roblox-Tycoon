--!strict
--[[
    DataSystemIntegration.server.luau
    
    Unified data system integration module that ensures proper connection
    between all data-related systems and provides a robust interface for
    data operations.
    
    Features:
    - System integration and coordination
    - Data persistence management
    - Migration handling
    - Error recovery
    - Health monitoring
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Import required modules
local CoreRegistry = require(script.Parent:WaitForChild("CoreRegistry_enhanced"))
local DataAccessLayer = require(script.Parent:WaitForChild("DataAccessLayer"))
local DataManager = require(script.Parent:WaitForChild("DataManager_enhanced"))

-- Configuration
local CONFIG = {
    debug = true,
    integrationTimeout = 10, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds
    healthCheckInterval = 30, -- seconds
    criticalSystems = {
        "DataAccessLayer",
        "DataManager",
        "VersionedDataStore",
        "DataMigrationUtility"
    }
}

-- Integration state
local integration = {
    initialized = false,
    version = "1.0.0",
    systems = {},
    health = {
        status = "Unknown",
        lastCheck = 0,
        errors = {},
        warnings = {}
    },
    stats = {
        integrationAttempts = 0,
        successfulIntegrations = 0,
        failedIntegrations = 0,
        recoveryAttempts = 0
    }
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[DataSystemIntegration][%s] %s", level, message))
end

-- Initialize a system
local function initializeSystem(systemName, system)
    if not system then
        log("System not found: " .. systemName, "Error")
        return false
    end
    
    -- Check if system has initialize method
    if typeof(system.initialize) ~= "function" then
        log("System has no initialize method: " .. systemName, "Warning")
        return true
    end
    
    -- Initialize system
    local success, result = pcall(function()
        return system:initialize()
    end)
    
    if not success then
        log("Failed to initialize " .. systemName .. ": " .. tostring(result), "Error")
        return false
    end
    
    log("Initialized system: " .. systemName)
    return true
end

-- Check system health
local function checkSystemHealth(systemName, system)
    if not system then
        return {
            status = "Critical",
            error = "System not found"
        }
    end
    
    -- Check if system has health check method
    if typeof(system.healthCheck) ~= "function" then
        return {
            status = "Unknown",
            warning = "No health check method"
        }
    end
    
    -- Run health check
    local success, result = pcall(function()
        return system:healthCheck()
    end)
    
    if not success then
        return {
            status = "Critical",
            error = "Health check failed: " .. tostring(result)
        }
    end
    
    return {
        status = result,
        lastCheck = os.time()
    }
end

-- Recover a system
local function recoverSystem(systemName, system)
    if not system then
        log("Cannot recover missing system: " .. systemName, "Error")
        return false
    end
    
    -- Check if system has recovery method
    if typeof(system.recover) ~= "function" then
        log("System has no recovery method: " .. systemName, "Warning")
        return false
    end
    
    -- Attempt recovery
    local success, result = pcall(function()
        return system:recover()
    end)
    
    if not success then
        log("Recovery failed for " .. systemName .. ": " .. tostring(result), "Error")
        return false
    end
    
    log("Recovered system: " .. systemName)
    return true
end

-- Run health check
function integration:healthCheck()
    local currentTime = os.time()
    if currentTime - self.health.lastCheck < CONFIG.healthCheckInterval then
        return self.health.status
    end
    
    self.health.lastCheck = currentTime
    self.health.errors = {}
    self.health.warnings = {}
    
    -- Check each system
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local system = self.systems[systemName]
        local health = checkSystemHealth(systemName, system)
        
        if health.status == "Critical" then
            table.insert(self.health.errors, {
                system = systemName,
                error = health.error
            })
        elseif health.status == "Degraded" then
            table.insert(self.health.warnings, {
                system = systemName,
                warning = health.warning
            })
        end
    end
    
    -- Update overall health status
    if #self.health.errors > 0 then
        self.health.status = "Critical"
    elseif #self.health.warnings > 0 then
        self.health.status = "Degraded"
    else
        self.health.status = "Healthy"
    end
    
    return self.health.status
end

-- Attempt recovery
function integration:recover()
    if self.health.status == "Healthy" then
        return true
    end
    
    self.stats.recoveryAttempts += 1
    log("Attempting recovery (Attempt " .. self.stats.recoveryAttempts .. ")")
    
    -- Try to recover each failed system
    for _, error in ipairs(self.health.errors) do
        local system = self.systems[error.system]
        if system then
            local success = recoverSystem(error.system, system)
            if not success then
                log("Failed to recover " .. error.system, "Error")
            end
        end
    end
    
    -- Run health check after recovery
    local status = self:healthCheck()
    return status == "Healthy"
end

-- Initialize integration
function integration:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataSystemIntegration v" .. self.version)
    self.stats.integrationAttempts += 1
    
    -- Get systems from CoreRegistry
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local system = CoreRegistry:getSystem(systemName)
        if system then
            self.systems[systemName] = system
            log("Found system: " .. systemName)
        else
            log("System not found in CoreRegistry: " .. systemName, "Warning")
        end
    end
    
    -- Initialize each system
    local allInitialized = true
    for systemName, system in pairs(self.systems) do
        if not initializeSystem(systemName, system) then
            allInitialized = false
            log("Failed to initialize " .. systemName, "Error")
        end
    end
    
    -- Set up health check loop
    task.spawn(function()
        while true do
            task.wait(CONFIG.healthCheckInterval)
            local status = self:healthCheck()
            if status == "Critical" then
                self:recover()
            end
        end
    end)
    
    -- Initial health check
    self:healthCheck()
    
    if allInitialized then
        self.stats.successfulIntegrations += 1
        self.initialized = true
        log("DataSystemIntegration initialized successfully")
        return true
    else
        self.stats.failedIntegrations += 1
        log("DataSystemIntegration initialization failed", "Error")
        return false
    end
end

-- Get system
function integration:getSystem(systemName)
    return self.systems[systemName]
end

-- Get health status
function integration:getHealthStatus()
    return {
        status = self.health.status,
        lastCheck = self.health.lastCheck,
        errors = self.health.errors,
        warnings = self.health.warnings
    }
end

-- Get statistics
function integration:getStats()
    return {
        integrationAttempts = self.stats.integrationAttempts,
        successfulIntegrations = self.stats.successfulIntegrations,
        failedIntegrations = self.stats.failedIntegrations,
        recoveryAttempts = self.stats.recoveryAttempts
    }
end

-- Initialize the integration
integration:initialize()

return integration 