--[[
    DataThrottler.server.luau
    
    Manages DataStore request throttling to prevent queue overload warnings
    Coordinates between multiple systems trying to save data simultaneously
    
    Author: April 23, 2025
]]

local DataStoreService = game:GetService("DataStoreService")

-- Get the CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    maxRequestsPerMinute = 50,       -- Max requests to send per minute (limit is 60)
    maxConcurrentRequests = 5,       -- Max concurrent requests
    requestDelay = 6,                -- Base delay between requests (seconds)
    priorityLevels = {
        critical = 1,                -- Critical data (immediate save)
        high = 2,                    -- High priority (player leaving)
        normal = 3,                  -- Normal priority (periodic save)
        low = 4                      -- Low priority (background save)
    },
    debugLogging = true              -- Enable debug logging
}

-- DataThrottler singleton
local DataThrottler = {
    requestQueue = {},               -- Queue of pending requests
    activeRequests = 0,              -- Count of currently active requests
    requestsThisMinute = 0,          -- Count of requests in the current minute
    lastRequestTime = 0,             -- Time of the last request
    systems = {},                    -- Registered DataStore systems
    requestsInQueue = {}             -- Track if a system has requests in queue already
}

-- Debug logging
local function log(...)
    if CONFIG.debugLogging then
        print("[DataThrottler]", ...)
    end
end

-- Queue a DataStore request with priority
function DataThrottler:queueRequest(system, key, requestType, callback, priority, data)
    priority = priority or CONFIG.priorityLevels.normal
    
    -- Create request object
    local request = {
        system = system,             -- System that made the request
        key = key,                   -- Key being accessed
        requestType = requestType,   -- "get", "set", or "update"
        callback = callback,         -- Function to run when request is processed
        priority = priority,         -- Priority level
        data = data,                 -- Data for set/update operations
        queueTime = os.clock(),      -- Time when request was queued
        attempts = 0                 -- Number of attempts made
    }
    
    -- Add to queue
    table.insert(self.requestQueue, request)
    
    -- Mark this system as having a request in queue for this key
    if not self.requestsInQueue[system] then
        self.requestsInQueue[system] = {}
    end
    self.requestsInQueue[system][key] = true
    
    -- Sort queue by priority
    table.sort(self.requestQueue, function(a, b)
        return a.priority < b.priority
    end)
    
    log(system .. ": Queued " .. requestType .. " request for key " .. key .. " (Priority: " .. priority .. ")")
    
    -- Process queue
    self:processQueue()
    
    return true
end

-- Process the request queue
function DataThrottler:processQueue()
    -- Check if we're already at max concurrent requests
    if self.activeRequests >= CONFIG.maxConcurrentRequests then
        return
    end
    
    -- Check if we've hit the rate limit
    if self.requestsThisMinute >= CONFIG.maxRequestsPerMinute then
        log("Rate limit reached, waiting for next minute")
        return
    end
    
    -- Check if queue is empty
    if #self.requestQueue == 0 then
        return
    end
    
    -- Calculate delay based on recent activity
    local now = os.clock()
    local timeSinceLastRequest = now - self.lastRequestTime
    local delay = math.max(0, CONFIG.requestDelay - timeSinceLastRequest)
    
    -- Get next request
    local request = table.remove(self.requestQueue, 1)
    
    -- Remove from tracking
    if self.requestsInQueue[request.system] then
        self.requestsInQueue[request.system][request.key] = nil
    end
    
    -- Increment active requests
    self.activeRequests = self.activeRequests + 1
    
    -- Update metrics
    self.lastRequestTime = now
    self.requestsThisMinute = self.requestsThisMinute + 1
    
    -- Reset request counter after a minute
    task.delay(60, function()
        self.requestsThisMinute = math.max(0, self.requestsThisMinute - 1)
    end)
    
    -- Process request after delay
    task.delay(delay, function()
        self:executeRequest(request)
    end)
    
    -- Try to process more from queue if available
    task.delay(delay + 0.1, function()
        self:processQueue()
    end)
end

-- Execute a DataStore request
function DataThrottler:executeRequest(request)
    local dataStore
    
    -- Get the appropriate DataStore
    if request.system == "EnhancedDataStorageSystem" then
        dataStore = DataStoreService:GetDataStore("EnhancedPlayerData")
    elseif request.system == "GymTycoonDataManager" then
        dataStore = DataStoreService:GetDataStore("GymTycoonData")
    else
        -- Try to get DataStore from system name
        local success, result = pcall(function()
            return DataStoreService:GetDataStore(request.system)
        end)
        
        if success then
            dataStore = result
        else
            log("Failed to get DataStore for " .. request.system)
            dataStore = nil
        end
    end
    
    -- Execute request
    if dataStore then
        local success, result
        
        if request.requestType == "get" then
            success, result = pcall(function()
                return dataStore:GetAsync(request.key)
            end)
        elseif request.requestType == "set" then
            success, result = pcall(function()
                return dataStore:SetAsync(request.key, request.data)
            end)
        elseif request.requestType == "update" then
            success, result = pcall(function()
                return dataStore:UpdateAsync(request.key, function(oldData)
                    return request.data(oldData)
                end)
            end)
        else
            success = false
            result = "Unknown request type"
        end
        
        -- Handle result
        request.attempts = request.attempts + 1
        
        if success then
            log(request.system .. ": Successful " .. request.requestType .. " for key " .. request.key)
            
            -- Call callback with result
            if request.callback then
                task.spawn(function()
                    request.callback(true, result)
                end)
            end
        else
            log(request.system .. ": Failed " .. request.requestType .. " for key " .. request.key .. ": " .. tostring(result))
            
            -- Retry if needed
            if request.attempts < 3 then
                log("Retrying request (Attempt " .. request.attempts .. "/3)")
                table.insert(self.requestQueue, request)
                
                -- Re-add to tracking
                if not self.requestsInQueue[request.system] then
                    self.requestsInQueue[request.system] = {}
                end
                self.requestsInQueue[request.system][request.key] = true
            else
                -- Call callback with failure
                if request.callback then
                    task.spawn(function()
                        request.callback(false, result)
                    end)
                end
            end
        end
    else
        -- Call callback with failure
        if request.callback then
            task.spawn(function()
                request.callback(false, "DataStore not found")
            end)
        end
    end
    
    -- Decrement active requests
    self.activeRequests = self.activeRequests - 1
    
    -- Process more from queue
    self:processQueue()
end

-- Check if a system already has a request for this key
function DataThrottler:hasExistingRequest(system, key)
    return self.requestsInQueue[system] and self.requestsInQueue[system][key] == true
end

-- Register a DataStore system
function DataThrottler:registerSystem(systemName)
    if not table.find(self.systems, systemName) then
        table.insert(self.systems, systemName)
        log("Registered system: " .. systemName)
    end
    
    return true
end

-- Initialize the DataThrottler
function DataThrottler:initialize()
    log("Initializing DataThrottler...")
    
    -- Reset any state
    self.requestQueue = {}
    self.activeRequests = 0
    self.requestsThisMinute = 0
    self.lastRequestTime = 0
    self.systems = {}
    self.requestsInQueue = {}
    
    -- Auto-register known systems
    self:registerSystem("EnhancedDataStorageSystem")
    self:registerSystem("GymTycoonDataManager")
    self:registerSystem("DataManager")
    
    -- Set up minute counter reset
    task.spawn(function()
        while true do
            task.wait(60)
            self.requestsThisMinute = 0
        end
    end)
    
    log("DataThrottler initialized successfully")
    return true
end

-- Public API for other systems
local DataThrottlerAPI = {
    initialize = function()
        return DataThrottler:initialize()
    end,
    
    queueSaveRequest = function(system, key, data, priority, callback)
        return DataThrottler:queueRequest(
            system,
            key,
            "set",
            callback,
            priority or CONFIG.priorityLevels.normal,
            data
        )
    end,
    
    queueLoadRequest = function(system, key, priority, callback)
        return DataThrottler:queueRequest(
            system,
            key,
            "get",
            callback,
            priority or CONFIG.priorityLevels.high
        )
    end,
    
    queueUpdateRequest = function(system, key, updateFunc, priority, callback)
        return DataThrottler:queueRequest(
            system,
            key,
            "update",
            callback,
            priority or CONFIG.priorityLevels.normal,
            updateFunc
        )
    end,
    
    registerSystem = function(systemName)
        return DataThrottler:registerSystem(systemName)
    end,
    
    hasExistingRequest = function(system, key)
        return DataThrottler:hasExistingRequest(system, key)
    end,
    
    getPriorities = function()
        return CONFIG.priorityLevels
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("DataThrottler", DataThrottlerAPI, {"CoreRegistry"})