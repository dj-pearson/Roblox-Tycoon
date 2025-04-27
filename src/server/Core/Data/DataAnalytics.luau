--!strict
--[[
    DataAnalytics.luau
    
    Provides monitoring, telemetry, and analytics for the data system.
    Tracks usage patterns, performance metrics, and errors to help optimize 
    the data system and identify issues.
    
    Features:
    - Performance monitoring
    - Usage analytics
    - Error tracking
    - System health metrics
    - Reporting tools
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Import required modules
local ServerScripts = script.Parent.Parent
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")

local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Module and state variables
local DataAnalytics = {}
local initialized = false

-- Analytics configuration
local config = {
    enabled = true,
    debugMode = false,
    logLevel = 2, -- 0=none, 1=errors, 2=warnings, 3=info, 4=verbose
    sampleRate = 0.1, -- Sample 10% of operations for detailed metrics
    sessionDuration = 900, -- 15 minutes before considering a new session
    maxErrorsStored = 100,
    maxEventsStored = 1000,
    autoFlushInterval = 300, -- 5 minutes
    remoteAnalyticsEnabled = false, -- Set to true to enable remote analytics
    remoteAnalyticsUrl = "", -- URL for remote analytics API
}

-- Analytics storage
local metrics = {
    operations = {
        reads = 0,
        writes = 0,
        deletes = 0,
        errors = 0,
        totalTime = 0,
        count = 0,
        lastOperation = 0
    },
    cache = {
        hits = 0,
        misses = 0,
        evictions = 0,
        size = 0
    },
    dataStore = {
        requests = 0,
        budgetWarnings = 0,
        throttles = 0,
        failures = 0,
        retries = 0
    },
    performance = {
        averageReadTime = 0,
        averageWriteTime = 0,
        slowestOperation = 0,
        fastestOperation = 0,
        operationTimes = {} -- Circular buffer for recent operations
    },
    sessions = {
        active = 0,
        total = 0,
        averageDuration = 0,
        totalDuration = 0
    },
    errors = {},
    events = {}
}

-- Session tracking
local sessions = {}
local nextSampleOperation = 1

--[[ Private Utility Functions ]]--

-- Log messages based on log level
local function log(level, ...)
    if config.logLevel >= level then
        local prefix = "[DataAnalytics]"
        
        if level == 1 then
            prefix = prefix .. " [ERROR]"
            warn(prefix, ...)
        elseif level == 2 then
            prefix = prefix .. " [WARNING]"
            warn(prefix, ...)
        elseif level == 3 then
            prefix = prefix .. " [INFO]"
            print(prefix, ...)
        elseif level == 4 then
            prefix = prefix .. " [DEBUG]"
            print(prefix, ...)
        end
    end
end

-- Get current time in seconds
local function now()
    return os.time()
end

-- Generate a unique ID for events
local function generateId()
    return HttpService:GenerateGUID(false):lower():gsub("-", "")
end

-- Determine if an operation should be sampled for detailed metrics
local function shouldSample()
    if config.sampleRate <= 0 then
        return false
    elseif config.sampleRate >= 1 then
        return true
    else
        return math.random() < config.sampleRate
    end
end

-- Add an event to the events log
local function addEvent(eventType, data)
    if not config.enabled then
        return
    end
    
    local event = {
        id = generateId(),
        type = eventType,
        timestamp = now(),
        data = data or {}
    }
    
    -- Add to events circular buffer
    table.insert(metrics.events, 1, event)
    
    -- Maintain maximum size
    if #metrics.events > config.maxEventsStored then
        table.remove(metrics.events)
    end
    
    -- Log if in debug mode
    if config.debugMode and config.logLevel >= 4 then
        log(4, "Event:", eventType, data and HttpService:JSONEncode(data) or "")
    end
    
    return event.id
end

-- Add an error to the error log
local function addError(errorType, message, source, details)
    if not config.enabled then
        return
    end
    
    local error = {
        id = generateId(),
        type = errorType,
        message = message,
        source = source,
        timestamp = now(),
        details = details or {}
    }
    
    -- Add to errors circular buffer
    table.insert(metrics.errors, 1, error)
    
    -- Maintain maximum size
    if #metrics.errors > config.maxErrorsStored then
        table.remove(metrics.errors)
    end
    
    -- Log the error
    if config.logLevel >= 1 then
        log(1, "Error:", errorType, message, "Source:", source)
    end
    
    -- Add as event too
    addEvent("error", {
        errorId = error.id,
        type = errorType, 
        message = message,
        source = source
    })
    
    -- Update error count
    metrics.operations.errors += 1
    
    return error.id
end

-- Start a session for a player
local function startSession(userId)
    if sessions[userId] then
        -- If existing session is recent, continue it
        local lastSeen = sessions[userId].lastSeen
        if now() - lastSeen < config.sessionDuration then
            sessions[userId].lastSeen = now()
            return sessions[userId].id
        else
            -- End previous session
            endSession(userId)
        }
    end
    
    -- Create new session
    local sessionId = generateId()
    sessions[userId] = {
        id = sessionId,
        userId = userId,
        startTime = now(),
        lastSeen = now(),
        operations = {
            reads = 0,
            writes = 0,
            deletes = 0,
            errors = 0
        },
        events = {}
    }
    
    -- Update metrics
    metrics.sessions.active += 1
    metrics.sessions.total += 1
    
    -- Add event
    addEvent("session_start", {
        userId = userId,
        sessionId = sessionId
    })
    
    return sessionId
end

-- Update a session's activity
local function updateSession(userId, operation)
    if not sessions[userId] then
        return startSession(userId)
    end
    
    -- Update last seen time
    sessions[userId].lastSeen = now()
    
    -- Update operation counts
    if operation then
        sessions[userId].operations[operation] = (sessions[userId].operations[operation] or 0) + 1
    end
    
    return sessions[userId].id
end

-- End a session for a player
local function endSession(userId)
    if not sessions[userId] then
        return
    end
    
    local session = sessions[userId]
    local duration = now() - session.startTime
    
    -- Update session metrics
    metrics.sessions.active -= 1
    metrics.sessions.totalDuration += duration
    
    if metrics.sessions.total > 0 then
        metrics.sessions.averageDuration = metrics.sessions.totalDuration / metrics.sessions.total
    end
    
    -- Add event
    addEvent("session_end", {
        userId = userId,
        sessionId = session.id,
        duration = duration,
        operations = session.operations
    })
    
    -- Clean up session
    sessions[userId] = nil
end

-- Auto-flush metrics
local function setupAutoFlush()
    if not config.enabled or config.autoFlushInterval <= 0 then
        return
    end
    
    task.spawn(function()
        while config.enabled do
            task.wait(config.autoFlushInterval)
            DataAnalytics:flush()
        end
    end)
end

-- Send metrics to a remote analytics service
local function sendToRemote(metricsData)
    if not config.remoteAnalyticsEnabled or not config.remoteAnalyticsUrl or config.remoteAnalyticsUrl == "" then
        return false
    end
    
    -- This would normally use HttpService to send data to a remote endpoint
    -- For this implementation, we'll just log that it would happen
    log(3, "Would send metrics to remote service:", config.remoteAnalyticsUrl)
    
    return true
end

-- Connect player events
local function connectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        local userId = player.UserId
        startSession(userId)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        endSession(userId)
    end)
    
    -- Handle game shutdown
    game:BindToClose(function()
        DataAnalytics:flush()
        
        -- End all sessions
        for userId in pairs(sessions) do
            endSession(userId)
        end
    end)
end

--[[ Public API Functions ]]--

-- Initialize the analytics system
function DataAnalytics:initialize(customConfig)
    if initialized then
        return true
    end
    
    -- Apply custom configuration if provided
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    if not config.enabled then
        log(3, "Analytics disabled")
        return true
    end
    
    -- Setup systems
    setupAutoFlush()
    connectPlayerEvents()
    
    -- Set initialized flag
    initialized = true
    log(3, "DataAnalytics initialized")
    
    -- Record initialization event
    addEvent("system_initialize", {
        config = {
            sampleRate = config.sampleRate,
            logLevel = config.logLevel,
            remoteEnabled = config.remoteAnalyticsEnabled
        }
    })
    
    return true
end

-- Track an operation
function DataAnalytics:trackOperation(operationType, details)
    self:initialize()
    
    if not config.enabled then
        return
    end
    
    operationType = operationType or "unknown"
    details = details or {}
    
    -- Update basic counts
    metrics.operations.count += 1
    metrics.operations.lastOperation = now()
    
    if operationType == "read" then
        metrics.operations.reads += 1
    elseif operationType == "write" then
        metrics.operations.writes += 1
    elseif operationType == "delete" then
        metrics.operations.deletes += 1
    end
    
    -- Track operation time
    if details.duration then
        metrics.operations.totalTime += details.duration
        
        -- Update performance metrics
        if details.duration > metrics.performance.slowestOperation then
            metrics.performance.slowestOperation = details.duration
        end
        
        if metrics.performance.fastestOperation == 0 or details.duration < metrics.performance.fastestOperation then
            metrics.performance.fastestOperation = details.duration
        end
        
        -- Calculate averages
        if operationType == "read" then
            metrics.performance.averageReadTime = 
                (metrics.performance.averageReadTime * (metrics.operations.reads - 1) + details.duration) 
                / metrics.operations.reads
        elseif operationType == "write" then
            metrics.performance.averageWriteTime = 
                (metrics.performance.averageWriteTime * (metrics.operations.writes - 1) + details.duration) 
                / metrics.operations.writes
        end
        
        -- Sample detailed metrics for some percentage of operations
        if #metrics.performance.operationTimes < 100 or shouldSample() then
            table.insert(metrics.performance.operationTimes, {
                type = operationType,
                duration = details.duration,
                timestamp = now(),
                details = {
                    scope = details.scope,
                    result = details.result,
                    userId = details.userId
                }
            })
            
            -- Maintain maximum size
            if #metrics.performance.operationTimes > 100 then
                table.remove(metrics.performance.operationTimes, 1)
            end
        end
    end
    
    -- Track in player's session if available
    if details.userId then
        updateSession(details.userId, operationType)
    end
    
    -- Add detailed event if sampling
    if shouldSample() then
        addEvent("operation", {
            type = operationType,
            duration = details.duration,
            result = details.result,
            scope = details.scope,
            userId = details.userId
        })
    end
end

-- Track cache usage
function DataAnalytics:trackCacheUsage(cacheEvent, details)
    self:initialize()
    
    if not config.enabled then
        return
    end
    
    cacheEvent = cacheEvent or "unknown"
    details = details or {}
    
    -- Update cache metrics
    if cacheEvent == "hit" then
        metrics.cache.hits += 1
    elseif cacheEvent == "miss" then
        metrics.cache.misses += 1
    elseif cacheEvent == "eviction" then
        metrics.cache.evictions += 1
    end
    
    -- Update cache size
    if details.size then
        metrics.cache.size = details.size
    end
    
    -- Add detailed event if sampling
    if shouldSample() then
        addEvent("cache", {
            event = cacheEvent,
            key = details.key,
            scope = details.scope,
            size = details.size,
            ttl = details.ttl
        })
    end
end

-- Track DataStore usage
function DataAnalytics:trackDataStoreUsage(storeEvent, details)
    self:initialize()
    
    if not config.enabled then
        return
    end
    
    storeEvent = storeEvent or "unknown"
    details = details or {}
    
    -- Update DataStore metrics
    if storeEvent == "request" then
        metrics.dataStore.requests += 1
    elseif storeEvent == "throttle" then
        metrics.dataStore.throttles += 1
    elseif storeEvent == "budget_warning" then
        metrics.dataStore.budgetWarnings += 1
    elseif storeEvent == "failure" then
        metrics.dataStore.failures += 1
    elseif storeEvent == "retry" then
        metrics.dataStore.retries += 1
    end
    
    -- Add detailed event if it's an issue or if sampling
    if storeEvent == "throttle" or storeEvent == "failure" or storeEvent == "budget_warning" or shouldSample() then
        addEvent("datastore", {
            event = storeEvent,
            storeName = details.storeName,
            key = details.key,
            errorCode = details.errorCode,
            retryCount = details.retryCount
        })
    end
    
    -- Track error if failure
    if storeEvent == "failure" then
        addError("datastore_error", details.errorMessage or "DataStore operation failed", 
            details.storeName, {
                key = details.key,
                errorCode = details.errorCode,
                retryCount = details.retryCount
            })
    end
end

-- Record a custom event
function DataAnalytics:recordEvent(eventName, eventData)
    self:initialize()
    
    if not config.enabled then
        return nil
    end
    
    return addEvent(eventName, eventData)
end

-- Record an error
function DataAnalytics:recordError(errorType, message, source, details)
    self:initialize()
    
    if not config.enabled then
        return nil
    end
    
    return addError(errorType, message, source, details)
end

-- Get metrics
function DataAnalytics:getMetrics(metricType)
    self:initialize()
    
    if metricType then
        return metrics[metricType]
    else
        return metrics
    end
end

-- Get recent errors
function DataAnalytics:getErrors(count)
    self:initialize()
    
    count = count or 10
    
    local recentErrors = {}
    for i = 1, math.min(count, #metrics.errors) do
        table.insert(recentErrors, metrics.errors[i])
    end
    
    return recentErrors
end

-- Get recent events
function DataAnalytics:getEvents(count, eventType)
    self:initialize()
    
    count = count or 10
    
    local recentEvents = {}
    local added = 0
    
    for i = 1, #metrics.events do
        if added >= count then
            break
        end
        
        if not eventType or metrics.events[i].type == eventType then
            table.insert(recentEvents, metrics.events[i])
            added += 1
        end
    end
    
    return recentEvents
end

-- Get active sessions
function DataAnalytics:getActiveSessions()
    self:initialize()
    
    local activeSessions = {}
    for userId, session in pairs(sessions) do
        -- Check if session has expired but hasn't been cleaned up
        if now() - session.lastSeen >= config.sessionDuration then
            endSession(userId)
        else
            table.insert(activeSessions, session)
        end
    end
    
    return activeSessions
end

-- Clear metrics
function DataAnalytics:clearMetrics()
    self:initialize()
    
    -- Reset operation metrics
    metrics.operations = {
        reads = 0,
        writes = 0,
        deletes = 0,
        errors = 0,
        totalTime = 0,
        count = 0,
        lastOperation = metrics.operations.lastOperation
    }
    
    -- Reset cache metrics
    metrics.cache = {
        hits = 0,
        misses = 0,
        evictions = 0,
        size = metrics.cache.size
    }
    
    -- Reset DataStore metrics
    metrics.dataStore = {
        requests = 0,
        budgetWarnings = 0,
        throttles = 0,
        failures = 0,
        retries = 0
    }
    
    -- Reset performance metrics
    metrics.performance = {
        averageReadTime = 0,
        averageWriteTime = 0,
        slowestOperation = 0,
        fastestOperation = 0,
        operationTimes = {}
    }
    
    -- Keep session metrics and active session info
    
    -- Clear errors and events
    metrics.errors = {}
    metrics.events = {}
    
    -- Add reset event
    addEvent("metrics_reset", {timestamp = now()})
    
    return true
end

-- Flush metrics to remote service or local storage
function DataAnalytics:flush()
    self:initialize()
    
    if not config.enabled then
        return false
    end
    
    -- Clone metrics for sending
    local metricsSnapshot = {
        timestamp = now(),
        operations = {
            reads = metrics.operations.reads,
            writes = metrics.operations.writes,
            deletes = metrics.operations.deletes,
            errors = metrics.operations.errors,
            totalTime = metrics.operations.totalTime,
            count = metrics.operations.count
        },
        cache = {
            hits = metrics.cache.hits,
            misses = metrics.cache.misses,
            evictions = metrics.cache.evictions,
            size = metrics.cache.size,
            hitRate = metrics.cache.hits / (metrics.cache.hits + metrics.cache.misses + 0.001)
        },
        dataStore = {
            requests = metrics.dataStore.requests,
            failures = metrics.dataStore.failures,
            throttles = metrics.dataStore.throttles,
            retries = metrics.dataStore.retries
        },
        performance = {
            averageReadTime = metrics.performance.averageReadTime,
            averageWriteTime = metrics.performance.averageWriteTime,
            slowestOperation = metrics.performance.slowestOperation,
            fastestOperation = metrics.performance.fastestOperation
        },
        sessions = {
            active = metrics.sessions.active,
            total = metrics.sessions.total,
            averageDuration = metrics.sessions.averageDuration
        }
    }
    
    -- Add flush event
    addEvent("metrics_flush", {timestamp = now()})
    
    -- Send to remote service
    local success = false
    if config.remoteAnalyticsEnabled then
        success = sendToRemote(metricsSnapshot)
    end
    
    return success
end

-- Set configuration option
function DataAnalytics:setConfig(option, value)
    if config[option] ~= nil then
        config[option] = value
        
        -- Add configuration change event
        addEvent("config_change", {option = option, value = value})
        
        return true
    end
    return false
end

-- Get configuration value
function DataAnalytics:getConfig(option)
    if option then
        return config[option]
    else
        local configCopy = {}
        for k, v in pairs(config) do
            configCopy[k] = v
        end
        return configCopy
    end
end

-- Generate a report of analytics data
function DataAnalytics:generateReport(reportType)
    self:initialize()
    
    local report = {
        timestamp = now(),
        reportType = reportType or "full",
        metrics = {}
    }
    
    if reportType == "performance" then
        report.metrics = {
            operations = metrics.operations,
            performance = metrics.performance
        }
    elseif reportType == "usage" then
        report.metrics = {
            operations = metrics.operations,
            dataStore = metrics.dataStore,
            cache = metrics.cache
        }
    elseif reportType == "errors" then
        report.metrics = {
            errors = metrics.errors,
            totalErrors = metrics.operations.errors
        }
    elseif reportType == "sessions" then
        report.metrics = {
            sessions = metrics.sessions,
            activeSessions = self:getActiveSessions()
        }
    else -- "full"
        report.metrics = metrics
    end
    
    -- Add report generation event
    addEvent("report_generated", {reportType = reportType})
    
    return report
end

return DataAnalytics
