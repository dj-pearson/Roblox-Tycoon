--!strict
--[[
    SystemInitializationCoordinator.server.luau
    
    Coordinates the initialization of core systems and ensures proper
    startup order and dependency management.
    
    Features:
    - System dependency management
    - Initialization order control
    - Health monitoring
    - Automatic recovery
    - Initialization retry logic
    - System status tracking
    - Detailed error reporting
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local CoreRegistry = require(script.Parent:WaitForChild("CoreRegistry_enhanced"))

-- Configuration
local CONFIG = {
    debug = true,
    maxInitAttempts = 3,
    retryDelay = 2, -- seconds
    healthCheckInterval = 30, -- seconds
    criticalSystems = {
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge"
    },
    systemDependencies = {
        DataManager = {},
        UIComponents = {"DataManager"},
        AssetValidator = {"DataManager"},
        BuyTileSystem = {"DataManager", "AssetValidator"},
        TycoonSystem = {"DataManager", "BuyTileSystem"},
        EventBridge = {"DataManager", "TycoonSystem"}
    },
    initializationTimeout = 30, -- seconds
    recoveryStrategies = {
        DataManager = "RESTART",
        UIComponents = "RELOAD",
        AssetValidator = "RESTART",
        BuyTileSystem = "RELOAD",
        TycoonSystem = "RESTART",
        EventBridge = "RELOAD"
    }
}

-- System status
local SYSTEM_STATUS = {
    PENDING = "Pending",
    INITIALIZING = "Initializing",
    RUNNING = "Running",
    DEGRADED = "Degraded",
    FAILED = "Failed",
    RECOVERING = "Recovering"
}

-- Coordinator state
local coordinator = {
    initialized = false,
    version = "1.0.0",
    systems = {},
    status = {},
    health = {},
    stats = {
        totalInitializations = 0,
        successfulInitializations = 0,
        failedInitializations = 0,
        recoveryAttempts = 0,
        successfulRecoveries = 0
    }
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[SystemInitializationCoordinator][%s] %s", level, message))
end

-- Check system dependencies
local function checkDependencies(systemName)
    local dependencies = CONFIG.systemDependencies[systemName]
    if not dependencies then
        return true
    end
    
    for _, depName in ipairs(dependencies) do
        if coordinator.status[depName] ~= SYSTEM_STATUS.RUNNING then
            return false, "Dependency not ready: " .. depName
        end
    end
    
    return true
end

-- Initialize system
local function initializeSystem(systemName)
    coordinator.stats.totalInitializations += 1
    coordinator.status[systemName] = SYSTEM_STATUS.INITIALIZING
    
    -- Check dependencies
    local depsReady, depError = checkDependencies(systemName)
    if not depsReady then
        coordinator.status[systemName] = SYSTEM_STATUS.FAILED
        coordinator.stats.failedInitializations += 1
        log("Failed to initialize " .. systemName .. ": " .. depError, "Error")
        return false
    end
    
    -- Get system module
    local system = coordinator.systems[systemName]
    if not system then
        coordinator.status[systemName] = SYSTEM_STATUS.FAILED
        coordinator.stats.failedInitializations += 1
        log("System not found: " .. systemName, "Error")
        return false
    end
    
    -- Initialize system
    local startTime = os.clock()
    local success, error = pcall(function()
        return system:initialize()
    end)
    
    if success then
        coordinator.status[systemName] = SYSTEM_STATUS.RUNNING
        coordinator.stats.successfulInitializations += 1
        coordinator.health[systemName] = {
            lastCheck = os.time(),
            status = "Healthy",
            errors = {}
        }
        log("Successfully initialized " .. systemName)
        return true
    else
        coordinator.status[systemName] = SYSTEM_STATUS.FAILED
        coordinator.stats.failedInitializations += 1
        log("Failed to initialize " .. systemName .. ": " .. tostring(error), "Error")
        return false
    end
end

-- Attempt system recovery
local function attemptRecovery(systemName)
    coordinator.stats.recoveryAttempts += 1
    local strategy = CONFIG.recoveryStrategies[systemName]
    
    if strategy == "RESTART" then
        -- Full system restart
        coordinator.status[systemName] = SYSTEM_STATUS.RECOVERING
        local success = initializeSystem(systemName)
        if success then
            coordinator.stats.successfulRecoveries += 1
            log("Successfully recovered " .. systemName)
            return true
        end
    elseif strategy == "RELOAD" then
        -- Reload system module
        local system = coordinator.systems[systemName]
        if system and system.reload then
            coordinator.status[systemName] = SYSTEM_STATUS.RECOVERING
            local success = pcall(function()
                return system:reload()
            end)
            if success then
                coordinator.stats.successfulRecoveries += 1
                log("Successfully reloaded " .. systemName)
                return true
            end
        end
    end
    
    log("Failed to recover " .. systemName, "Error")
    return false
end

-- Check system health
local function checkSystemHealth(systemName)
    local system = coordinator.systems[systemName]
    if not system or not system.checkHealth then
        return false
    end
    
    local success, health = pcall(function()
        return system:checkHealth()
    end)
    
    if success and health then
        coordinator.health[systemName] = {
            lastCheck = os.time(),
            status = health.status or "Unknown",
            errors = health.errors or {}
        }
        return true
    end
    
    return false
end

-- Run health checks
local function runHealthChecks()
    for systemName, _ in pairs(coordinator.systems) do
        if coordinator.status[systemName] == SYSTEM_STATUS.RUNNING then
            local healthy = checkSystemHealth(systemName)
            if not healthy then
                coordinator.status[systemName] = SYSTEM_STATUS.DEGRADED
                log("System health check failed: " .. systemName, "Warning")
                
                -- Attempt recovery
                if attemptRecovery(systemName) then
                    coordinator.status[systemName] = SYSTEM_STATUS.RUNNING
                else
                    coordinator.status[systemName] = SYSTEM_STATUS.FAILED
                end
            end
        end
    end
end

-- Register system
function coordinator:registerSystem(systemName, system)
    if not systemName or not system then
        log("Invalid system registration", "Error")
        return false
    end
    
    self.systems[systemName] = system
    self.status[systemName] = SYSTEM_STATUS.PENDING
    log("Registered system: " .. systemName)
    return true
end

-- Initialize all systems
function coordinator:initializeAll()
    if self.initialized then
        return true
    end
    
    log("Starting system initialization")
    
    -- Initialize critical systems in order
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local attempts = 0
        local success = false
        
        while attempts < CONFIG.maxInitAttempts and not success do
            success = initializeSystem(systemName)
            if not success then
                attempts += 1
                if attempts < CONFIG.maxInitAttempts then
                    task.wait(CONFIG.retryDelay)
                end
            end
        end
        
        if not success then
            log("Failed to initialize critical system: " .. systemName, "Error")
            return false
        end
    end
    
    -- Start health check loop
    task.spawn(function()
        while true do
            task.wait(CONFIG.healthCheckInterval)
            runHealthChecks()
        end
    end)
    
    self.initialized = true
    log("All systems initialized successfully")
    return true
end

-- Get system status
function coordinator:getSystemStatus(systemName)
    if systemName then
        return {
            status = self.status[systemName],
            health = self.health[systemName]
        }
    end
    
    local status = {}
    for name, _ in pairs(self.systems) do
        status[name] = {
            status = self.status[name],
            health = self.health[name]
        }
    end
    return status
end

-- Get initialization statistics
function coordinator:getStats()
    return {
        totalInitializations = self.stats.totalInitializations,
        successfulInitializations = self.stats.successfulInitializations,
        failedInitializations = self.stats.failedInitializations,
        recoveryAttempts = self.stats.recoveryAttempts,
        successfulRecoveries = self.stats.successfulRecoveries
    }
end

-- Initialize the coordinator
coordinator:initializeAll()

return coordinator 