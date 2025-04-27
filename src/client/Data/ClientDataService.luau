--!strict
--[[
    ClientDataService.luau
    
    Client-side data access layer that provides a clean API for UI components
    and other client modules to interact with the data system. Handles all
    communication with the server-side data services.
    
    Features:
    - Client-side data caching
    - Simple data access API
    - Remote function and event wrappers
    - Data change notification system
    - Offline mode support
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Remote communication objects
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataSystem")
local getDataRemote = remoteFolder:WaitForChild("GetData")
local setDataRemote = remoteFolder:WaitForChild("SetData")
local incrementDataRemote = remoteFolder:WaitForChild("IncrementData")
local dataChangedEvent = remoteFolder:WaitForChild("DataChanged")

-- Module and state variables
local ClientDataService = {}
local localPlayer = Players.LocalPlayer
local initialized = false
local pendingRequests = {}
local requestIdCounter = 0
local offlineMode = false
local isDevEnvironment = RunService:IsStudio() and not game:GetService("RunService"):IsRunning()

-- Client-side cache
local dataCache = {}
local dataChangeListeners = {}
local loadedScopes = {}

-- Configuration options
local config = {
    enableClientCache = true,
    cacheTTL = 60, -- Cache data for 60 seconds
    retryDelay = 1,
    maxRetries = 3,
    offlineModeEnabled = isDevEnvironment, -- Enable offline mode in non-running Studio sessions
    debugMode = false
}

--[[ Private Utility Functions ]]--

-- Log messages in debug mode
local function log(message, ...)
    if config.debugMode then
        print("[ClientDataService] " .. message, ...)
    end
end

-- Generate a unique request ID
local function generateRequestId()
    requestIdCounter += 1
    return tostring(localPlayer.UserId) .. "_" .. tostring(requestIdCounter)
end

-- Get cached data if available and not expired
local function getCachedData(scope, key)
    if not config.enableClientCache then
        return nil, false
    end
    
    if not dataCache[scope] then
        return nil, false
    end
    
    local cached = dataCache[scope][key]
    if not cached then
        return nil, false
    end
    
    -- Check if cache has expired
    if cached.timestamp + config.cacheTTL < os.time() then
        -- Cache expired
        return nil, false
    end
    
    return DataTypes.deepCopy(cached.value), true
end

-- Set data in client-side cache
local function setCachedData(scope, key, value)
    if not config.enableClientCache then
        return
    end
    
    if not dataCache[scope] then
        dataCache[scope] = {}
    end
    
    dataCache[scope][key] = {
        value = DataTypes.deepCopy(value),
        timestamp = os.time()
    }
end

-- Clear specific data from cache
local function clearCache(scope, key)
    if not dataCache[scope] then
        return
    end
    
    if key then
        dataCache[scope][key] = nil
    else
        dataCache[scope] = {}
    end
end

-- Fire data change event for listeners
local function fireDataChanged(scope, key, newValue, oldValue)
    -- Notify scope-specific listeners
    if dataChangeListeners[scope] and dataChangeListeners[scope][key] then
        for _, callback in ipairs(dataChangeListeners[scope][key]) do
            task.spawn(function()
                local success, err = pcall(function()
                    callback(newValue, oldValue)
                end)
                
                if not success then
                    warn("Error in data change listener:", err)
                end
            end)
        end
    end
    
    -- Notify scope wildcard listeners
    if dataChangeListeners[scope] and dataChangeListeners[scope]["*"] then
        for _, callback in ipairs(dataChangeListeners[scope]["*"]) do
            task.spawn(function()
                local success, err = pcall(function()
                    callback(key, newValue, oldValue)
                end)
                
                if not success then
                    warn("Error in data change listener:", err)
                end
            end)
        end
    end
    
    -- Notify global wildcard listeners
    if dataChangeListeners["*"] and dataChangeListeners["*"]["*"] then
        for _, callback in ipairs(dataChangeListeners["*"]["*"]) do
            task.spawn(function()
                local success, err = pcall(function()
                    callback(scope, key, newValue, oldValue)
                end)
                
                if not success then
                    warn("Error in data change listener:", err)
                end
            end)
        end
    end
end

-- Set up remote event connections
local function connectRemoteEvents()
    -- Listen for data change notifications from server
    dataChangedEvent.OnClientEvent:Connect(function(scope, key, newValue)
        local oldValue = nil
        
        -- Get current cached value if available
        if dataCache[scope] and dataCache[scope][key] then
            oldValue = dataCache[scope][key].value
        end
        
        -- Update cache
        setCachedData(scope, key, newValue)
        
        -- Notify listeners
        fireDataChanged(scope, key, newValue, oldValue)
    end)
end

-- Create mock data for offline mode
local function setupOfflineMode()
    if not config.offlineModeEnabled then
        return
    end
    
    log("Running in offline mode, using mock data")
    offlineMode = true
    
    -- Set up basic mock data for core player data
    dataCache[DataConstants.PLAYER_SCOPES.CORE] = {
        ["playerInfo"] = {
            value = DataTypes.create("PlayerData", localPlayer.UserId, localPlayer.Name, localPlayer.DisplayName),
            timestamp = os.time()
        },
        ["tutorial"] = {
            value = { completed = false, step = 1 },
            timestamp = os.time()
        }
    }
    
    -- Stats
    dataCache[DataConstants.PLAYER_SCOPES.STATS] = {
        ["gymLevel"] = { value = 1, timestamp = os.time() },
        ["experience"] = { value = 0, timestamp = os.time() },
        ["memberCount"] = { value = 5, timestamp = os.time() },
        ["revenue"] = { value = 1000, timestamp = os.time() },
        ["reputation"] = { value = 50, timestamp = os.time() }
    }
    
    -- Inventory
    dataCache[DataConstants.PLAYER_SCOPES.INVENTORY] = {
        ["equipment"] = { 
            value = {
                { id = "treadmill_basic", count = 2, level = 1 },
                { id = "bench_basic", count = 1, level = 1 }
            },
            timestamp = os.time()
        },
        ["currency"] = {
            value = { coins = 5000, premium = 100 },
            timestamp = os.time()
        }
    }
    
    -- Mark all scopes as loaded in offline mode
    for _, scope in pairs(DataConstants.PLAYER_SCOPES) do
        loadedScopes[scope] = true
    end
end

--[[ Public API Functions ]]--

-- Initialize the client data service
function ClientDataService:initialize(customConfig)
    if initialized then
        return true
    end
    
    -- Apply custom configuration if provided
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Connect remote events
    connectRemoteEvents()
    
    -- Set up offline mode if needed
    if config.offlineModeEnabled then
        setupOfflineMode()
    end
    
    initialized = true
    log("ClientDataService initialized")
    return true
end

-- Get data from a specific scope
function ClientDataService:getData(scope, key)
    self:initialize()
    
    -- Validate parameters
    if not scope or not key then
        warn("Invalid parameters for getData")
        return nil
    end
    
    -- Check if we're in offline mode
    if offlineMode then
        local cached = getCachedData(scope, key)
        return cached
    end
    
    -- Check cache first
    local cached, found = getCachedData(scope, key)
    if found then
        log("Retrieved", scope, key, "from cache")
        return cached
    end
    
    -- Not in cache, request from server
    log("Requesting", scope, key, "from server")
    
    -- Generate request ID for tracking
    local requestId = generateRequestId()
    
    -- Create a promise-like object for this request
    local result = nil
    local requestCompleted = false
    
    -- Set up the request
    pendingRequests[requestId] = {
        scope = scope,
        key = key,
        attempts = 0
    }
    
    -- Make the remote request
    local success, response = pcall(function()
        return getDataRemote:InvokeServer(scope, key, requestId)
    end)
    
    -- Handle response
    if success then
        if response ~= nil then
            -- Update cache
            setCachedData(scope, key, response)
            
            -- Mark scope as loaded
            loadedScopes[scope] = true
            
            -- Store result
            result = response
        end
    else
        warn("Failed to get data for", scope, key, ":", response)
    end
    
    -- Clean up
    pendingRequests[requestId] = nil
    requestCompleted = true
    
    return result
end

-- Set data for a specific scope
function ClientDataService:setData(scope, key, value)
    self:initialize()
    
    -- Validate parameters
    if not scope or not key then
        warn("Invalid parameters for setData")
        return false
    end
    
    -- Check if we're in offline mode
    if offlineMode then
        -- In offline mode, just update local cache
        local oldValue = nil
        if dataCache[scope] and dataCache[scope][key] then
            oldValue = dataCache[scope][key].value
        end
        
        setCachedData(scope, key, value)
        fireDataChanged(scope, key, value, oldValue)
        return true
    end
    
    -- Generate request ID for tracking
    local requestId = generateRequestId()
    
    -- Set up the request
    pendingRequests[requestId] = {
        scope = scope,
        key = key,
        value = value,
        attempts = 0
    }
    
    -- Make the remote request
    local success, response = pcall(function()
        return setDataRemote:InvokeServer(scope, key, value, requestId)
    end)
    
    -- Handle response
    if success and response then
        -- Update cache optimistically
        local oldValue = nil
        if dataCache[scope] and dataCache[scope][key] then
            oldValue = dataCache[scope][key].value
        end
        
        setCachedData(scope, key, value)
        
        -- Mark scope as loaded
        loadedScopes[scope] = true
        
        -- Notify listeners of the change
        fireDataChanged(scope, key, value, oldValue)
        
        -- Clean up
        pendingRequests[requestId] = nil
        
        return true
    else
        warn("Failed to set data for", scope, key, ":", response)
        
        -- Clean up
        pendingRequests[requestId] = nil
        
        return false
    end
end

-- Increment a numeric value
function ClientDataService:incrementData(scope, key, amount)
    self:initialize()
    
    -- Default amount to 1 if not specified
    amount = amount or 1
    
    -- Validate parameters
    if not scope or not key then
        warn("Invalid parameters for incrementData")
        return false, nil
    end
    
    -- Check if we're in offline mode
    if offlineMode then
        -- In offline mode, just update local cache
        local currentValue = 0
        if dataCache[scope] and dataCache[scope][key] then
            currentValue = dataCache[scope][key].value or 0
        end
        
        local newValue = currentValue + amount
        setCachedData(scope, key, newValue)
        fireDataChanged(scope, key, newValue, currentValue)
        return true, newValue
    end
    
    -- Generate request ID for tracking
    local requestId = generateRequestId()
    
    -- Set up the request
    pendingRequests[requestId] = {
        scope = scope,
        key = key,
        amount = amount,
        attempts = 0
    }
    
    -- Make the remote request
    local success, response = pcall(function()
        return incrementDataRemote:InvokeServer(scope, key, amount, requestId)
    end)
    
    -- Handle response
    if success then
        -- The response should be the new value
        local newValue = response
        
        -- Update cache
        local oldValue = nil
        if dataCache[scope] and dataCache[scope][key] then
            oldValue = dataCache[scope][key].value
        end
        
        setCachedData(scope, key, newValue)
        
        -- Mark scope as loaded
        loadedScopes[scope] = true
        
        -- Notify listeners of the change
        fireDataChanged(scope, key, newValue, oldValue)
        
        -- Clean up
        pendingRequests[requestId] = nil
        
        return true, newValue
    else
        warn("Failed to increment data for", scope, key, ":", response)
        
        -- Clean up
        pendingRequests[requestId] = nil
        
        return false, nil
    end
end

-- Listen for changes to data
function ClientDataService:onDataChanged(scope, key, callback)
    self:initialize()
    
    -- Validate parameters
    if not scope or not key or type(callback) ~= "function" then
        warn("Invalid parameters for onDataChanged")
        return false
    end
    
    -- Initialize listener tables if needed
    if not dataChangeListeners[scope] then
        dataChangeListeners[scope] = {}
    end
    
    if not dataChangeListeners[scope][key] then
        dataChangeListeners[scope][key] = {}
    end
    
    -- Add the callback
    table.insert(dataChangeListeners[scope][key], callback)
    
    return true
end

-- Check if a data scope is loaded
function ClientDataService:isScopeLoaded(scope)
    return loadedScopes[scope] == true
end

-- Clear client-side cache for a scope
function ClientDataService:clearCache(scope, key)
    self:initialize()
    
    if not scope then
        -- Clear all cache if no scope specified
        dataCache = {}
        return true
    end
    
    clearCache(scope, key)
    return true
end

-- Set configuration option
function ClientDataService:setConfig(option, value)
    if config[option] ~= nil then
        config[option] = value
        return true
    end
    return false
end

-- Get configuration value
function ClientDataService:getConfig(option)
    return config[option]
end

-- Get all configuration values
function ClientDataService:getAllConfig()
    return DataTypes.deepCopy(config)
end

-- Force refresh data from server
function ClientDataService:refreshData(scope, key)
    self:initialize()
    
    -- Validate parameters
    if not scope then
        warn("Invalid parameters for refreshData")
        return false
    end
    
    -- Clear cache for this scope/key
    clearCache(scope, key)
    
    -- If key is specified, just refresh that key
    if key then
        return self:getData(scope, key) ~= nil
    end
    
    -- Otherwise, refresh all known keys for this scope
    local success = true
    
    -- For all loaded scopes, refresh data
    if dataCache[scope] then
        for k, _ in pairs(dataCache[scope]) do
            if not self:getData(scope, k) then
                success = false
            end
        end
    end
    
    return success
end

-- Toggle offline mode (for testing)
function ClientDataService:setOfflineMode(enabled)
    if enabled and not offlineMode then
        setupOfflineMode()
    elseif not enabled and offlineMode then
        offlineMode = false
        dataCache = {}
        loadedScopes = {}
    end
    
    return offlineMode
end

-- Helper function to wait for data to load
function ClientDataService:waitForData(scope, key, timeout)
    self:initialize()
    
    timeout = timeout or 10 -- Default 10 second timeout
    local startTime = os.clock()
    
    -- First try to get the data normally
    local data = self:getData(scope, key)
    if data ~= nil then
        return data
    end
    
    -- If not available, wait for it
    while os.clock() - startTime < timeout do
        task.wait(0.1)
        data = self:getData(scope, key)
        if data ~= nil then
            return data
        end
    end
    
    warn("Timeout waiting for data:", scope, key)
    return nil
end

return ClientDataService
