--!strict
--[[
    DataThrottler.lua
    
    A utility module to manage and throttle DataStore requests to prevent hitting rate limits.
    This module implements request queuing, prioritization, and retry mechanisms.
    
    Author: Pearson
    Date: April 25, 2025
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataThrottler = {
    systems = {},           -- Registered systems using the throttler
    requestQueue = {},       -- Queue of requests by priority
    activeRequests = 0,      -- Currently active requests
    rateMetrics = {          -- Metrics for rate limiting
        requests = {},       -- Recent requests with timestamps
        writesThisMinute = 0,
        readsThisMinute = 0,
        lastCleanup = os.time()
    }
}

-- Configuration
local CONFIG = {
    -- Request limits (based on DataStore limits)
    maxConcurrentRequests = 5,      -- Maximum concurrent requests
    maxRequestsPerMinute = 60,      -- Maximum requests per minute
    maxWritesPerMinute = 60,        -- Maximum write operations per minute
    maxReadsPerMinute = 100,        -- Maximum read operations per minute
    
    -- Retry configuration
    maxRetries = 5,                 -- Maximum retry attempts
    baseRetryDelay = 1,             -- Base delay between retries (seconds)
    
    -- Priority levels
    priorities = {
        CRITICAL = 1,   -- Player leaving, game shutdown
        HIGH = 2,       -- Immediate saves requested by game
        NORMAL = 3,     -- Regular auto-saves
        LOW = 4,        -- Backups, non-essential writes
        BACKGROUND = 5  -- Analytics, logs
    },
    
    -- Performance
    processingInterval = 0.1,       -- How often to process queue (seconds)
    cleanupInterval = 60,           -- How often to clean up metrics (seconds)
    
    -- Debug
    debug = true
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[DataThrottler]", ...)
    end
end

-- Register a system to use the throttler
function DataThrottler.registerSystem(systemName)
    if not DataThrottler.systems[systemName] then
        DataThrottler.systems[systemName] = {
            name = systemName,
            requestsMade = 0,
            requestsSucceeded = 0,
            requestsFailed = 0,
            lastRequest = 0
        }
        debugPrint("Registered system:", systemName)
    end
    return DataThrottler.systems[systemName]
end

-- Clean up old metrics
function DataThrottler.cleanupMetrics()
    local currentTime = os.time()
    
    -- Only clean up once per minute
    if currentTime - DataThrottler.rateMetrics.lastCleanup < CONFIG.cleanupInterval then
        return
    end
    
    -- Remove metrics older than 1 minute
    local cutoffTime = currentTime - 60
    local newRequests = {}
    
    for _, request in ipairs(DataThrottler.rateMetrics.requests) do
        if request.time > cutoffTime then
            table.insert(newRequests, request)
        end
    end
    
    DataThrottler.rateMetrics.requests = newRequests
    DataThrottler.rateMetrics.writesThisMinute = 0
    DataThrottler.rateMetrics.readsThisMinute = 0
    DataThrottler.rateMetrics.lastCleanup = currentTime
    
    debugPrint("Cleaned up metrics. Current queue length:", #DataThrottler.requestQueue)
end

-- Check if we can make another request
function DataThrottler.canMakeRequest(isWrite)
    -- Too many concurrent requests
    if DataThrottler.activeRequests >= CONFIG.maxConcurrentRequests then
        return false, "Too many concurrent requests"
    end
    
    -- Count requests in the last minute
    local currentTime = os.time()
    local requestsLastMinute = 0
    local writesLastMinute = 0
    local readsLastMinute = 0
    
    for _, request in ipairs(DataThrottler.rateMetrics.requests) do
        if currentTime - request.time <= 60 then
            requestsLastMinute = requestsLastMinute + 1
            if request.isWrite then
                writesLastMinute = writesLastMinute + 1
            else
                readsLastMinute = readsLastMinute + 1
            end
        end
    end
    
    -- Check if we're at the rate limit
    if requestsLastMinute >= CONFIG.maxRequestsPerMinute then
        return false, "Rate limit reached for total requests"
    end
    
    if isWrite and writesLastMinute >= CONFIG.maxWritesPerMinute then
        return false, "Rate limit reached for write operations"
    end
    
    if not isWrite and readsLastMinute >= CONFIG.maxReadsPerMinute then
        return false, "Rate limit reached for read operations"
    end
    
    return true, nil
end

-- Add a request to the queue with specified priority
function DataThrottler.queueRequestWithPriority(systemName, priority, callback, isWrite)
    -- Default to normal priority if not specified
    priority = priority or CONFIG.priorities.NORMAL
    
    -- Register system if not already registered
    if not DataThrottler.systems[systemName] then
        DataThrottler.registerSystem(systemName)
    end
    
    -- Create request object
    local request = {
        system = systemName,
        callback = callback,
        priority = priority,
        isWrite = isWrite == nil and true or isWrite, -- Default to write operation
        retries = 0,
        created = os.time(),
        id = tostring(systemName) .. "_" .. os.time() .. "_" .. math.random(10000, 99999)
    }
    
    -- Add to queue based on priority
    table.insert(DataThrottler.requestQueue, request)
    
    -- Sort queue by priority (lower number = higher priority)
    table.sort(DataThrottler.requestQueue, function(a, b)
        return a.priority < b.priority
    end)
    
    debugPrint("Queued " .. (isWrite and "write" or "read") .. " request for system:", systemName, "Priority:", priority)
    
    -- Create a thread to wait for the result
    local thread = coroutine.running()
    
    -- Store thread to resume when the request completes
    request.thread = thread
    
    -- Yield until the request is processed
    return coroutine.yield()
end

-- Regular priority request wrapper
function DataThrottler.queueRequest(systemName, callback, isWrite)
    return DataThrottler.queueRequestWithPriority(systemName, CONFIG.priorities.NORMAL, callback, isWrite)
end

-- Critical priority request wrapper
function DataThrottler.queueCriticalRequest(systemName, callback, isWrite)
    return DataThrottler.queueRequestWithPriority(systemName, CONFIG.priorities.CRITICAL, callback, isWrite)
end

-- Process a single request
function DataThrottler.processRequest(request)
    if not request then return false end
    
    -- Check if we can make this request
    local canRequest, reason = DataThrottler.canMakeRequest(request.isWrite)
    
    if not canRequest then
        debugPrint("Cannot process request:", reason, "Will retry later.")
        return false
    end
    
    -- Mark as active
    DataThrottler.activeRequests = DataThrottler.activeRequests + 1
    
    -- Record metrics
    table.insert(DataThrottler.rateMetrics.requests, {
        time = os.time(),
        isWrite = request.isWrite
    })
    
    -- Update system stats
    local system = DataThrottler.systems[request.system]
    if system then
        system.requestsMade = system.requestsMade + 1
        system.lastRequest = os.time()
    end
    
    -- Execute the request
    task.spawn(function()
        local success, result
        
        -- Try to execute with retry logic
        for attempt = 1, CONFIG.maxRetries do
            success, result = pcall(request.callback)
            
            if success then
                break
            else
                -- Failed, retry with exponential backoff
                request.retries = request.retries + 1
                
                local delay = CONFIG.baseRetryDelay * (2 ^ (request.retries - 1))
                debugPrint("Request failed, retry " .. request.retries .. "/" .. CONFIG.maxRetries .. 
                           " in " .. delay .. " seconds. Error: " .. tostring(result))
                
                task.wait(delay)
            end
        end
        
        -- Update stats
        DataThrottler.activeRequests = DataThrottler.activeRequests - 1
        
        if system then
            if success then
                system.requestsSucceeded = system.requestsSucceeded + 1
            else
                system.requestsFailed = system.requestsFailed + 1
            end
        end
        
        -- Resume the thread that made the request
        if request.thread then
            task.spawn(function()
                coroutine.resume(request.thread, success, result)
            end)
        end
    end)
    
    return true
end

-- Process the queue
function DataThrottler.processQueue()
    -- Clean up metrics periodically
    DataThrottler.cleanupMetrics()
    
    -- No requests to process
    if #DataThrottler.requestQueue == 0 then
        return
    end
    
    -- Process requests in priority order
    local i = 1
    while i <= #DataThrottler.requestQueue do
        local request = DataThrottler.requestQueue[i]
        
        if DataThrottler.processRequest(request) then
            -- Request was processed, remove from queue
            table.remove(DataThrottler.requestQueue, i)
        else
            -- Request couldn't be processed yet, try the next one
            i = i + 1
        end
        
        -- Don't process too many at once
        if DataThrottler.activeRequests >= CONFIG.maxConcurrentRequests then
            break
        end
    end
end

-- Get statistics for all systems
function DataThrottler.getStats()
    local stats = {
        activeRequests = DataThrottler.activeRequests,
        queueLength = #DataThrottler.requestQueue,
        systems = {}
    }
    
    for name, system in pairs(DataThrottler.systems) do
        stats.systems[name] = {
            requestsMade = system.requestsMade,
            requestsSucceeded = system.requestsSucceeded,
            requestsFailed = system.requestsFailed,
            lastRequest = system.lastRequest
        }
    end
    
    return stats
end

-- Start the queue processor
task.spawn(function()
    while true do
        task.wait(CONFIG.processingInterval)
        
        -- Process the queue
        pcall(function()
            DataThrottler.processQueue()
        end)
    end
end)

debugPrint("DataThrottler initialized")
return DataThrottler
