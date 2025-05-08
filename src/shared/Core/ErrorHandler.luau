--[[
    ErrorHandler.luau
    
    Core system for handling script errors and providing recovery mechanisms.
    This system ensures proper error tracking, recovery, and reporting.
    
    Features:
    - Error tracking and categorization
    - Automatic error recovery
    - Error reporting and logging
    - Health monitoring
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    maxRetries = 3,
    retryDelay = 1, -- seconds
    errorTypes = {
        NIL_INDEX = "attempt to index nil",
        NIL_CALL = "attempt to call a nil value",
        INFINITE_YIELD = "Infinite yield possible",
        INVALID_MEMBER = "is not a valid member of",
        INVALID_PROPERTY = "is not a valid property of",
        INVALID_METHOD = "is not a valid method of",
        INVALID_ARGUMENT = "invalid argument",
        INVALID_OPERATION = "invalid operation",
        INVALID_TYPE = "invalid type",
        INVALID_VALUE = "invalid value"
    },
    recoveryStrategies = {
        NIL_INDEX = function(context)
            -- Try to find the object in a different location
            if context.objectPath then
                local parts = string.split(context.objectPath, ".")
                local current = game
                for _, part in ipairs(parts) do
                    if current then
                        current = current:FindFirstChild(part)
                    end
                end
                if current then
                    return current
                end
            end
            return nil
        end,
        NIL_CALL = function(context)
            -- Try to find the function in a different location
            if context.functionPath then
                local parts = string.split(context.functionPath, ".")
                local current = game
                for _, part in ipairs(parts) do
                    if current then
                        current = current:FindFirstChild(part)
                    end
                end
                if current and typeof(current) == "function" then
                    return current
                end
            end
            return nil
        end,
        INFINITE_YIELD = function(context)
            -- Add timeout to WaitForChild
            if context.instance and context.childName then
                local child = context.instance:FindFirstChild(context.childName)
                if child then
                    return child
                end
                -- Try to create the child if it's a common type
                if context.childType then
                    local newChild = Instance.new(context.childType)
                    newChild.Name = context.childName
                    newChild.Parent = context.instance
                    return newChild
                end
            end
            return nil
        end
    }
}

-- Module state
local ErrorHandler = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    recoveryAttempts = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorHandler]", ...)
    end
end

-- Get error type
local function getErrorType(message)
    for type, pattern in pairs(CONFIG.errorTypes) do
        if string.find(message, pattern) then
            return type
        end
    end
    return "UNKNOWN"
end

-- Extract context from error
local function extractContext(message, stackTrace)
    local context = {
        message = message,
        stackTrace = stackTrace,
        timestamp = os.time()
    }
    
    -- Try to extract object path
    local objectPath = string.match(message, "attempt to index nil with '([^']+)'")
    if objectPath then
        context.objectPath = objectPath
    end
    
    -- Try to extract function path
    local functionPath = string.match(message, "attempt to call a nil value '([^']+)'")
    if functionPath then
        context.functionPath = functionPath
    end
    
    -- Try to extract instance and child name
    local instanceName, childName = string.match(message, "Infinite yield possible on '([^']+)' for '([^']+)'")
    if instanceName and childName then
        context.instance = game:FindFirstChild(instanceName)
        context.childName = childName
    end
    
    return context
end

-- Attempt error recovery
local function attemptRecovery(errorType, context)
    local strategy = CONFIG.recoveryStrategies[errorType]
    if not strategy then
        return nil
    end
    
    -- Check if we've tried too many times
    local key = errorType .. ":" .. (context.objectPath or context.functionPath or context.childName or "")
    ErrorHandler.recoveryAttempts[key] = (ErrorHandler.recoveryAttempts[key] or 0) + 1
    
    if ErrorHandler.recoveryAttempts[key] > CONFIG.maxRetries then
        return nil
    end
    
    -- Try recovery
    return strategy(context)
end

-- Record an error
local function recordError(message, source, context)
    local timestamp = os.time()
    local errorType = getErrorType(message)
    local errorContext = context or {}
    
    -- Add stack trace if not provided
    if not errorContext.stackTrace then
        errorContext.stackTrace = debug.traceback()
    end
    
    -- Add source if not provided
    if not errorContext.source then
        errorContext.source = source or "unknown"
    end
    
    -- Add timestamp
    errorContext.timestamp = timestamp
    
    -- Add new error
    table.insert(ErrorHandler.errors, {
        type = errorType,
        message = message,
        context = errorContext
    })
    
    -- Remove old errors
    while #ErrorHandler.errors > CONFIG.maxErrors do
        table.remove(ErrorHandler.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #ErrorHandler.errors, 1, -1 do
        if ErrorHandler.errors[i].context.timestamp < cutoff then
            table.remove(ErrorHandler.errors, i)
        end
    end
    
    -- Try recovery
    local recovered = attemptRecovery(errorType, errorContext)
    if recovered then
        log("Recovered from error: " .. message)
        return recovered
    end
    
    log("Error recorded: " .. message)
    return nil
end

-- Check system health
local function checkHealth()
    local now = os.time()
    ErrorHandler.lastCheck = now
    
    -- Check error count
    if #ErrorHandler.errors > CONFIG.maxErrors then
        log("Too many errors: " .. #ErrorHandler.errors)
    end
    
    -- Check recovery attempts
    for key, attempts in pairs(ErrorHandler.recoveryAttempts) do
        if attempts > CONFIG.maxRetries then
            log("Too many recovery attempts for: " .. key)
        end
    end
    
    return true
end

-- Initialize ErrorHandler
function ErrorHandler.initialize()
    if ErrorHandler.initialized then return true end
    
    log("Initializing ErrorHandler...")
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    -- Set up error handling
    local function handleError(message, stackTrace)
        return recordError(message, "runtime", {
            stackTrace = stackTrace
        })
    end
    
    -- Override error handling
    local oldError = error
    error = function(message, level)
        local stackTrace = debug.traceback()
        local recovered = handleError(message, stackTrace)
        if recovered then
            return recovered
        end
        return oldError(message, level)
    end
    
    ErrorHandler.initialized = true
    log("ErrorHandler initialized")
    return true
end

-- Record an error
function ErrorHandler.recordError(message, source, context)
    return recordError(message, source, context)
end

-- Get error count
function ErrorHandler.getErrorCount()
    return #ErrorHandler.errors
end

-- Get recent errors
function ErrorHandler.getRecentErrors()
    return ErrorHandler.errors
end

-- Get error type
function ErrorHandler.getErrorType(message)
    return getErrorType(message)
end

-- Force a health check
function ErrorHandler.forceCheck()
    return checkHealth()
end

return ErrorHandler 