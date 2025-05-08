--!strict
--[[
    CoreRegistry.server.luau
    
    Core system registry that manages all system modules and their dependencies.
    This system ensures proper initialization order and system availability.
    
    Features:
    - System registration and discovery
    - Dependency management
    - Initialization sequence control
    - Health monitoring
    - Error recovery
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    initTimeout = 10, -- seconds
    retryDelay = 1, -- seconds
    maxRetries = 3,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600 -- 1 hour
}

-- Module state
local CoreRegistry = {
    systems = {},           -- Registered systems
    dependencies = {},      -- System dependencies
    initialized = false,    -- Initialization status
    errors = {},           -- Error history
    lastCheck = 0,         -- Last health check time
    initQueue = {},        -- Initialization queue
    initStatus = {}        -- System initialization status
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistry]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    if CoreRegistry.systems.ErrorHandler then
        return CoreRegistry.systems.ErrorHandler
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            return require(core.ErrorHandler)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check system dependencies
local function checkDependencies(systemName)
    local deps = CoreRegistry.dependencies[systemName]
    if not deps then return true end
    
    for _, dep in ipairs(deps) do
        if not CoreRegistry.systems[dep] then
            return false, "Missing dependency: " .. dep
        end
        if not CoreRegistry.initStatus[dep] then
            return false, "Dependency not initialized: " .. dep
        end
    end
    
    return true
end

-- Initialize a system
local function initializeSystem(systemName)
    if CoreRegistry.initStatus[systemName] then
        return true
    end
    
    local system = CoreRegistry.systems[systemName]
    if not system then
        return false, "System not found: " .. systemName
    end
    
    -- Check dependencies
    local depsOk, depsError = checkDependencies(systemName)
    if not depsOk then
        return false, depsError
    end
    
    -- Initialize system
    local success, result = pcall(function()
        if typeof(system.initialize) == "function" then
            return system.initialize()
        end
        return true
    end)
    
    if not success then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Failed to initialize system: " .. systemName, "init_failure", {
                error = result,
                system = systemName
            })
        end
        return false, result
    end
    
    CoreRegistry.initStatus[systemName] = true
    log("System initialized: " .. systemName)
    return true
end

-- Process initialization queue
local function processInitQueue()
    local queue = CoreRegistry.initQueue
    local maxAttempts = #queue * CONFIG.maxRetries
    local attempts = 0
    
    while #queue > 0 and attempts < maxAttempts do
        local systemName = queue[1]
        local success, error = initializeSystem(systemName)
        
        if success then
            table.remove(queue, 1)
        else
            -- Move to end of queue for retry
            table.remove(queue, 1)
            table.insert(queue, systemName)
            task.wait(CONFIG.retryDelay)
        end
        
        attempts = attempts + 1
    end
    
    if #queue > 0 then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Failed to initialize all systems", "init_failure", {
                remaining = queue
            })
        end
        return false
    end
    
    return true
end

-- Register a system
function CoreRegistry.registerSystem(systemName, system, dependencies)
    if CoreRegistry.systems[systemName] then
        log("System already registered: " .. systemName)
        return false
    end
    
    CoreRegistry.systems[systemName] = system
    CoreRegistry.dependencies[systemName] = dependencies or {}
    CoreRegistry.initStatus[systemName] = false
    
    -- Add to initialization queue
    table.insert(CoreRegistry.initQueue, systemName)
    
    log("System registered: " .. systemName)
    return true
end

-- Get a system
function CoreRegistry.getSystem(systemName)
    return CoreRegistry.systems[systemName]
end

-- Initialize CoreRegistry
function CoreRegistry.initialize()
    if CoreRegistry.initialized then return true end
    
    log("Initializing CoreRegistry...")
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            CoreRegistry.checkHealth()
        end
    end)
    
    -- Process initialization queue
    local success = processInitQueue()
    if not success then
        log("Failed to initialize all systems")
        return false
    end
    
    CoreRegistry.initialized = true
    log("CoreRegistry initialized")
    return true
end

-- Check system health
function CoreRegistry.checkHealth()
    local now = os.time()
    CoreRegistry.lastCheck = now
    
    -- Check initialization status
    for systemName, system in pairs(CoreRegistry.systems) do
        if not CoreRegistry.initStatus[systemName] then
            local errorHandler = getErrorHandler()
            if errorHandler then
                errorHandler.recordError("System not initialized: " .. systemName, "health_check", {
                    system = systemName
                })
            end
        end
    end
    
    -- Check error count
    if #CoreRegistry.errors > CONFIG.maxErrors then
        local errorHandler = getErrorHandler()
        if errorHandler then
            errorHandler.recordError("Too many errors: " .. #CoreRegistry.errors, "health_check")
        end
    end
    
    return true
end

-- Record an error
function CoreRegistry.recordError(message, errorType, context)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(CoreRegistry.errors, {
        message = message,
        type = errorType,
        context = context,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #CoreRegistry.errors > CONFIG.maxErrors do
        table.remove(CoreRegistry.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #CoreRegistry.errors, 1, -1 do
        if CoreRegistry.errors[i].timestamp < cutoff then
            table.remove(CoreRegistry.errors, i)
        end
    end
    
    log("Error recorded: " .. message)
end

-- Get error count
function CoreRegistry.getErrorCount()
    return #CoreRegistry.errors
end

-- Get recent errors
function CoreRegistry.getRecentErrors()
    return CoreRegistry.errors
end

-- Force a health check
function CoreRegistry.forceCheck()
    return CoreRegistry.checkHealth()
end

-- Get initialization status
function CoreRegistry.getInitStatus()
    return CoreRegistry.initStatus
end

-- Get system list
function CoreRegistry.getSystemList()
    return CoreRegistry.systems
end

return CoreRegistry
