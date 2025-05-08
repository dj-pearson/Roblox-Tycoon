--!strict
--[[
    DataAccessLayer.server.luau
    
    Enhanced data access layer that provides a standardized interface for
    data operations with improved error reporting and handling.
    
    Features:
    - Detailed error reporting
    - Error categorization
    - Error recovery strategies
    - Operation tracking
    - Performance monitoring
    - Automatic recovery
    - Data validation
    - Cache management
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Import required modules
local CoreRegistry = require(script.Parent:WaitForChild("CoreRegistry_enhanced"))

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    operationTimeout = 30, -- seconds
    errorReporting = {
        enabled = true,
        logLevel = "Detailed", -- Basic, Detailed, Verbose
        trackStackTraces = true,
        maxStoredErrors = 100
    },
    performance = {
        trackOperations = true,
        maxStoredOperations = 1000,
        slowOperationThreshold = 1 -- seconds
    }
}

-- Error categories
local ERROR_CATEGORIES = {
    CONNECTION = "Connection",
    TIMEOUT = "Timeout",
    THROTTLE = "Throttle",
    VALIDATION = "Validation",
    PERMISSION = "Permission",
    DATA = "Data",
    SYSTEM = "System",
    UNKNOWN = "Unknown"
}

-- Recovery strategies
local RECOVERY_STRATEGIES = {
    -- Retry with exponential backoff
    RETRY = function(operation, maxRetries, initialDelay)
        local delay = initialDelay or 1
        for attempt = 1, maxRetries do
            local success, result = pcall(operation)
            if success then
                return true, result
            end
            task.wait(delay)
            delay = delay * 2
        end
        return false
    end,
    
    -- Fallback to backup data
    FALLBACK = function(primaryOperation, backupOperation)
        local success, result = pcall(primaryOperation)
        if success then
            return true, result
        end
        
        return pcall(backupOperation)
    end,
    
    -- Data repair
    REPAIR = function(data, repairRules)
        local repaired = table.clone(data)
        for field, rule in pairs(repairRules) do
            if repaired[field] == nil or not rule.validate(repaired[field]) then
                repaired[field] = rule.repair(repaired[field])
            end
        end
        return repaired
    end,
    
    -- Cache invalidation
    INVALIDATE_CACHE = function(cache, key)
        if cache[key] then
            cache[key] = nil
            return true
        end
        return false
    end
}

-- Data access layer state
local dataAccess = {
    initialized = false,
    version = "1.0.0",
    dataStores = {},
    errorLog = {},
    operationLog = {},
    cache = {},
    recoveryAttempts = {},
    stats = {
        totalOperations = 0,
        successfulOperations = 0,
        failedOperations = 0,
        retryAttempts = 0,
        recoveryAttempts = 0,
        successfulRecoveries = 0,
        cacheHits = 0,
        cacheMisses = 0
    }
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[DataAccessLayer][%s] %s", level, message))
end

-- Categorize error
local function categorizeError(error)
    local errorString = tostring(error):lower()
    
    if errorString:match("connection") or errorString:match("network") then
        return ERROR_CATEGORIES.CONNECTION
    elseif errorString:match("timeout") or errorString:match("timed out") then
        return ERROR_CATEGORIES.TIMEOUT
    elseif errorString:match("throttle") or errorString:match("too many requests") then
        return ERROR_CATEGORIES.THROTTLE
    elseif errorString:match("validation") or errorString:match("invalid") then
        return ERROR_CATEGORIES.VALIDATION
    elseif errorString:match("permission") or errorString:match("not allowed") then
        return ERROR_CATEGORIES.PERMISSION
    elseif errorString:match("data") or errorString:match("format") then
        return ERROR_CATEGORIES.DATA
    elseif errorString:match("system") or errorString:match("internal") then
        return ERROR_CATEGORIES.SYSTEM
    end
    
    return ERROR_CATEGORIES.UNKNOWN
end

-- Log error
local function logError(operation, error, context)
    if not CONFIG.errorReporting.enabled then
        return
    end
    
    local errorEntry = {
        timestamp = os.time(),
        operation = operation,
        error = tostring(error),
        category = categorizeError(error),
        context = context or {},
        stackTrace = CONFIG.errorReporting.trackStackTraces and debug.traceback() or nil
    }
    
    table.insert(dataAccess.errorLog, 1, errorEntry)
    
    -- Trim error log if needed
    if #dataAccess.errorLog > CONFIG.errorReporting.maxStoredErrors then
        table.remove(dataAccess.errorLog)
    end
    
    -- Log based on level
    if CONFIG.errorReporting.logLevel == "Basic" then
        log(string.format("Error in %s: %s", operation, errorEntry.error), "Error")
    elseif CONFIG.errorReporting.logLevel == "Detailed" then
        log(string.format("Error in %s (%s): %s", operation, errorEntry.category, errorEntry.error), "Error")
    else -- Verbose
        log(string.format("Error in %s (%s): %s\nContext: %s\nStack: %s", 
            operation, errorEntry.category, errorEntry.error,
            HttpService:JSONEncode(errorEntry.context),
            errorEntry.stackTrace or "Not tracked"), "Error")
    end
end

-- Log operation
local function logOperation(operation, startTime, success, context)
    if not CONFIG.performance.trackOperations then
        return
    end
    
    local duration = os.clock() - startTime
    local operationEntry = {
        timestamp = os.time(),
        operation = operation,
        duration = duration,
        success = success,
        context = context or {}
    }
    
    table.insert(dataAccess.operationLog, 1, operationEntry)
    
    -- Trim operation log if needed
    if #dataAccess.operationLog > CONFIG.performance.maxStoredOperations then
        table.remove(dataAccess.operationLog)
    end
    
    -- Log slow operations
    if duration > CONFIG.performance.slowOperationThreshold then
        log(string.format("Slow operation: %s took %.2f seconds", operation, duration), "Warning")
    end
end

-- Get data store
local function getDataStore(name)
    if not dataAccess.dataStores[name] then
        dataAccess.dataStores[name] = DataStoreService:GetDataStore(name)
    end
    return dataAccess.dataStores[name]
end

-- Attempt recovery
local function attemptRecovery(operation, error, context)
    dataAccess.stats.recoveryAttempts += 1
    
    -- Get recovery strategy based on error category
    local category = categorizeError(error)
    local strategy = nil
    
    if category == ERROR_CATEGORIES.CONNECTION then
        strategy = RECOVERY_STRATEGIES.RETRY
    elseif category == ERROR_CATEGORIES.DATA then
        strategy = RECOVERY_STRATEGIES.REPAIR
    elseif category == ERROR_CATEGORIES.TIMEOUT then
        strategy = RECOVERY_STRATEGIES.RETRY
    elseif category == ERROR_CATEGORIES.THROTTLE then
        strategy = RECOVERY_STRATEGIES.RETRY
    end
    
    if not strategy then
        return false, "No recovery strategy available for error category: " .. category
    end
    
    -- Apply recovery strategy
    local success, result = pcall(function()
        return strategy(operation, context)
    end)
    
    if success then
        dataAccess.stats.successfulRecoveries += 1
        log("Recovery successful for operation: " .. context.operation)
        return true, result
    else
        log("Recovery failed: " .. tostring(result), "Error")
        return false, result
    end
end

-- Safe data store operation with recovery
local function safeDataStoreOperation(operation, dataStore, key, value)
    local startTime = os.clock()
    local success, result
    
    for attempt = 1, CONFIG.maxRetries do
        success, result = pcall(function()
            if operation == "Get" then
                -- Check cache first
                if dataAccess.cache[key] then
                    dataAccess.stats.cacheHits += 1
                    return dataAccess.cache[key]
                end
                dataAccess.stats.cacheMisses += 1
                return dataStore:GetAsync(key)
            elseif operation == "Set" then
                local result = dataStore:SetAsync(key, value)
                -- Update cache
                dataAccess.cache[key] = value
                return result
            elseif operation == "Update" then
                local result = dataStore:UpdateAsync(key, value)
                -- Update cache
                dataAccess.cache[key] = result
                return result
            end
        end)
        
        if success then
            dataAccess.stats.successfulOperations += 1
            logOperation(operation, startTime, true, {key = key})
            return result
        end
        
        dataAccess.stats.retryAttempts += 1
        logError(operation, result, {
            attempt = attempt,
            key = key,
            dataStore = dataStore.Name
        })
        
        -- Attempt recovery
        local recovered, recoveryResult = attemptRecovery(
            function() return dataStore[operation .. "Async"](dataStore, key, value) end,
            result,
            {
                operation = operation,
                key = key,
                attempt = attempt
            }
        )
        
        if recovered then
            dataAccess.stats.successfulOperations += 1
            logOperation(operation, startTime, true, {key = key, recovered = true})
            return recoveryResult
        end
        
        if attempt < CONFIG.maxRetries then
            task.wait(CONFIG.retryDelay)
        end
    end
    
    dataAccess.stats.failedOperations += 1
    logOperation(operation, startTime, false, {key = key})
    return nil
end

-- Load data
function dataAccess:loadData(dataStoreName, key)
    dataAccess.stats.totalOperations += 1
    
    local dataStore = getDataStore(dataStoreName)
    if not dataStore then
        logError("LoadData", "DataStore not found: " .. dataStoreName)
        return nil
    end
    
    return safeDataStoreOperation("Get", dataStore, key)
end

-- Save data
function dataAccess:saveData(dataStoreName, key, value)
    dataAccess.stats.totalOperations += 1
    
    local dataStore = getDataStore(dataStoreName)
    if not dataStore then
        logError("SaveData", "DataStore not found: " .. dataStoreName)
        return false
    end
    
    local success = safeDataStoreOperation("Set", dataStore, key, value) ~= nil
    return success
end

-- Update data
function dataAccess:updateData(dataStoreName, key, updateFunction)
    dataAccess.stats.totalOperations += 1
    
    local dataStore = getDataStore(dataStoreName)
    if not dataStore then
        logError("UpdateData", "DataStore not found: " .. dataStoreName)
        return nil
    end
    
    return safeDataStoreOperation("Update", dataStore, key, updateFunction)
end

-- Get error log
function dataAccess:getErrorLog(filter)
    if not filter then
        return dataAccess.errorLog
    end
    
    local filteredLog = {}
    for _, error in ipairs(dataAccess.errorLog) do
        if (not filter.category or error.category == filter.category) and
           (not filter.operation or error.operation == filter.operation) and
           (not filter.startTime or error.timestamp >= filter.startTime) and
           (not filter.endTime or error.timestamp <= filter.endTime) then
            table.insert(filteredLog, error)
        end
    end
    
    return filteredLog
end

-- Get operation log
function dataAccess:getOperationLog(filter)
    if not filter then
        return dataAccess.operationLog
    end
    
    local filteredLog = {}
    for _, operation in ipairs(dataAccess.operationLog) do
        if (not filter.operation or operation.operation == filter.operation) and
           (not filter.success or operation.success == filter.success) and
           (not filter.startTime or operation.timestamp >= filter.startTime) and
           (not filter.endTime or operation.timestamp <= filter.endTime) then
            table.insert(filteredLog, operation)
        end
    end
    
    return filteredLog
end

-- Get statistics
function dataAccess:getStats()
    return {
        totalOperations = dataAccess.stats.totalOperations,
        successfulOperations = dataAccess.stats.successfulOperations,
        failedOperations = dataAccess.stats.failedOperations,
        retryAttempts = dataAccess.stats.retryAttempts,
        errorCount = #dataAccess.errorLog,
        operationCount = #dataAccess.operationLog
    }
end

-- Clear cache
function dataAccess:clearCache(key)
    if key then
        return RECOVERY_STRATEGIES.INVALIDATE_CACHE(self.cache, key)
    else
        self.cache = {}
        return true
    end
end

-- Get cache statistics
function dataAccess:getCacheStats()
    return {
        hits = self.stats.cacheHits,
        misses = self.stats.cacheMisses,
        hitRate = self.stats.cacheHits / (self.stats.cacheHits + self.stats.cacheMisses),
        size = #self.cache
    }
end

-- Get recovery statistics
function dataAccess:getRecoveryStats()
    return {
        attempts = self.stats.recoveryAttempts,
        successful = self.stats.successfulRecoveries,
        successRate = self.stats.successfulRecoveries / self.stats.recoveryAttempts
    }
end

-- Initialize data access layer
function dataAccess:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataAccessLayer v" .. self.version)
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:registerSystem("DataAccessLayer", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up periodic cache cleanup
    task.spawn(function()
        while true do
            task.wait(300) -- 5 minutes
            local now = os.time()
            for key, entry in pairs(self.cache) do
                if entry.timestamp and now - entry.timestamp > 3600 then -- 1 hour
                    self.cache[key] = nil
                end
            end
        end
    end)
    
    self.initialized = true
    log("DataAccessLayer initialized successfully")
    return true
end

-- Initialize the data access layer
dataAccess:initialize()

return dataAccess
