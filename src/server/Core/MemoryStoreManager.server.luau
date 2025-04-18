-- MemoryStoreManager.server.luau
-- Manages temporary data using Roblox's MemoryStore service
-- Part of the Performance Optimization Framework

local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    enabled = true,
    
    -- MemoryStore settings
    defaultExpiration = 86400,      -- Default expiration time in seconds (1 day)
    cleanupInterval = 300,          -- How often to clean up local cache (5 minutes)
    retryCount = 3,                 -- How many times to retry a MemoryStore operation
    retryDelay = 1,                 -- Delay between retries in seconds
    
    -- Fallback settings
    useFallback = true,             -- Whether to use local cache when MemoryStore fails
    cacheTTL = 600,                 -- How long to keep items in local cache (10 minutes)
    
    -- Quota management
    quotaThreshold = 0.8,           -- Threshold for quota warning (80% of limit)
    
    -- Data categories with custom expiration times (in seconds)
    expirationTimes = {
        player_session = 3600,      -- Player session data (1 hour)
        system_state = 7200,        -- System state data (2 hours)
        game_metrics = 86400,       -- Game metrics data (24 hours)
        temp_effects = 300,         -- Temporary visual effects (5 minutes)
        cooldowns = 1800            -- Cooldown timers (30 minutes)
    }
}

-- Module table
local MemoryStoreManager = {
    Name = "MemoryStoreManager",
    Dependencies = {
        "CoreRegistry"
    },
    
    -- Internal state
    _maps = {},                     -- MemoryStore maps by name
    _queues = {},                   -- MemoryStore queues by name
    _localCache = {},               -- Local cache for fallback
    _initialized = false,           -- Whether the system is initialized
    _operationCount = {             -- Track operation counts for quota management
        get = 0,
        set = 0,
        remove = 0,
        update = 0,
        readQueue = 0,
        writeQueue = 0
    },
    _lastReset = os.time()          -- When operation counts were last reset
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[MemoryStoreManager]", ...)
    end
end

--[[ Helper Functions ]]--

-- Generate a unique key for a category/id combination
local function generateKey(category, id)
    return category .. ":" .. tostring(id)
end

-- Get expiration time for a category
local function getExpirationTime(category)
    return CONFIG.expirationTimes[category] or CONFIG.defaultExpiration
end

-- Get a MemoryStoreSortedMap for a category
function MemoryStoreManager:getMap(category)
    if not CONFIG.enabled then return nil end
    
    -- Create map if it doesn't exist
    if not self._maps[category] then
        self._maps[category] = MemoryStoreService:GetSortedMap(category)
        debugPrint("Created SortedMap for category:", category)
    end
    
    return self._maps[category]
end

-- Get a MemoryStoreQueue for a category
function MemoryStoreManager:getQueue(category)
    if not CONFIG.enabled then return nil end
    
    -- Create queue if it doesn't exist
    if not self._queues[category] then
        self._queues[category] = MemoryStoreService:GetQueue(category)
        debugPrint("Created Queue for category:", category)
    end
    
    return self._queues[category]
end

-- Track an operation for quota management
function MemoryStoreManager:trackOperation(operationType)
    self._operationCount[operationType] = (self._operationCount[operationType] or 0) + 1
    
    -- Reset counts every hour
    if os.time() - self._lastReset > 3600 then
        for op, _ in pairs(self._operationCount) do
            self._operationCount[op] = 0
        end
        self._lastReset = os.time()
    end
    
    -- Check if approaching quota
    local totalOps = 0
    for _, count in pairs(self._operationCount) do
        totalOps = totalOps + count
    end
    
    -- Warning threshold (assuming ~60,000 operations per hour quota)
    if totalOps > 60000 * CONFIG.quotaThreshold then
        warn("[MemoryStoreManager] Approaching MemoryStore quota! Operations this hour:", totalOps)
    end
end

--[[ MemoryStore Map Operations ]]--

-- Set a value in MemoryStore
function MemoryStoreManager:setValue(category, id, value, expiration)
    if not CONFIG.enabled then return false end
    
    -- Generate key and get map
    local key = generateKey(category, id)
    local map = self:getMap(category)
    if not map then return false end
    
    -- Set expiration time
    local expirationTime = expiration or getExpirationTime(category)
    
    -- Try to set value with retries
    local success = false
    local errorMessage
    
    -- Serialize table values to JSON
    local serializedValue = value
    if type(value) == "table" then
        serializedValue = HttpService:JSONEncode(value)
    end
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            map:SetAsync(key, serializedValue, expirationTime)
            self:trackOperation("set")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to set value (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- Update local cache for fallback
    if CONFIG.useFallback then
        self._localCache[key] = {
            value = value,
            expires = os.time() + expirationTime
        }
    end
    
    return success
end

-- Get a value from MemoryStore
function MemoryStoreManager:getValue(category, id)
    if not CONFIG.enabled then return nil end
    
    -- Generate key and get map
    local key = generateKey(category, id)
    local map = self:getMap(category)
    if not map then
        -- Try fallback
        if CONFIG.useFallback and self._localCache[key] then
            if os.time() < self._localCache[key].expires then
                return self._localCache[key].value
            else
                self._localCache[key] = nil
            end
        end
        return nil
    end
    
    -- Try to get value with retries
    local value = nil
    local success = false
    local errorMessage
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            value = map:GetAsync(key)
            self:trackOperation("get")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to get value (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- If successful and value exists, try to deserialize
    if success and value ~= nil then
        -- Try to deserialize JSON if it's a string and looks like JSON
        if type(value) == "string" and string.sub(value, 1, 1) == "{" then
            local deserializeSuccess, deserializedValue = pcall(function()
                return HttpService:JSONDecode(value)
            end)
            
            if deserializeSuccess then
                -- Update local cache
                if CONFIG.useFallback then
                    self._localCache[key] = {
                        value = deserializedValue,
                        expires = os.time() + getExpirationTime(category)
                    }
                end
                
                return deserializedValue
            end
        end
        
        -- Update local cache with original value
        if CONFIG.useFallback then
            self._localCache[key] = {
                value = value,
                expires = os.time() + getExpirationTime(category)
            }
        end
        
        return value
    end
    
    -- Try fallback if MemoryStore failed
    if CONFIG.useFallback and self._localCache[key] then
        if os.time() < self._localCache[key].expires then
            return self._localCache[key].value
        else
            self._localCache[key] = nil
        end
    end
    
    return nil
end

-- Remove a value from MemoryStore
function MemoryStoreManager:removeValue(category, id)
    if not CONFIG.enabled then return false end
    
    -- Generate key and get map
    local key = generateKey(category, id)
    local map = self:getMap(category)
    if not map then return false end
    
    -- Try to remove value with retries
    local success = false
    local errorMessage
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            map:RemoveAsync(key)
            self:trackOperation("remove")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to remove value (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- Remove from local cache
    if CONFIG.useFallback and self._localCache[key] then
        self._localCache[key] = nil
    end
    
    return success
end

-- Update a value in MemoryStore (atomic operation)
function MemoryStoreManager:updateValue(category, id, updateFunc)
    if not CONFIG.enabled or not updateFunc then return false end
    
    -- Generate key and get map
    local key = generateKey(category, id)
    local map = self:getMap(category)
    if not map then return false end
    
    -- Try to update value with retries
    local success = false
    local errorMessage
    local newValue
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            local value = map:GetAsync(key)
            
            -- Try to deserialize if it's a string and looks like JSON
            if type(value) == "string" and string.sub(value, 1, 1) == "{" then
                local deserializeSuccess, deserializedValue = pcall(function()
                    return HttpService:JSONDecode(value)
                end)
                
                if deserializeSuccess then
                    value = deserializedValue
                end
            end
            
            -- Apply the update function
            newValue = updateFunc(value)
            
            -- Serialize table values to JSON
            local serializedValue = newValue
            if type(newValue) == "table" then
                serializedValue = HttpService:JSONEncode(newValue)
            end
            
            -- Set the new value
            map:SetAsync(key, serializedValue, getExpirationTime(category))
            self:trackOperation("update")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to update value (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- Update local cache
    if success and CONFIG.useFallback then
        self._localCache[key] = {
            value = newValue,
            expires = os.time() + getExpirationTime(category)
        }
    end
    
    return success, newValue
end

--[[ MemoryStore Queue Operations ]]--

-- Add an item to a queue
function MemoryStoreManager:addToQueue(category, item, priority, expiration)
    if not CONFIG.enabled then return false end
    
    -- Get queue
    local queue = self:getQueue(category)
    if not queue then return false end
    
    -- Set defaults
    priority = priority or 0
    expiration = expiration or getExpirationTime(category)
    
    -- Serialize table items to JSON
    local serializedItem = item
    if type(item) == "table" then
        serializedItem = HttpService:JSONEncode(item)
    end
    
    -- Try to add item with retries
    local success = false
    local errorMessage
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            queue:AddAsync(serializedItem, priority, expiration)
            self:trackOperation("writeQueue")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to add to queue (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return success
end

-- Read an item from a queue
function MemoryStoreManager:readFromQueue(category, timeoutSeconds)
    if not CONFIG.enabled then return nil end
    
    -- Get queue
    local queue = self:getQueue(category)
    if not queue then return nil end
    
    -- Set defaults
    timeoutSeconds = timeoutSeconds or 30
    
    -- Try to read item with retries
    local item = nil
    local success = false
    local errorMessage
    
    for i = 1, CONFIG.retryCount do
        success, errorMessage = pcall(function()
            item = queue:ReadAsync(timeoutSeconds)
            self:trackOperation("readQueue")
        end)
        
        if success then
            break
        else
            debugPrint("Failed to read from queue (attempt " .. i .. "):", errorMessage)
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- If successful and item exists, try to deserialize
    if success and item then
        -- Try to deserialize JSON if it's a string and looks like JSON
        if type(item) == "string" and string.sub(item, 1, 1) == "{" then
            local deserializeSuccess, deserializedItem = pcall(function()
                return HttpService:JSONDecode(item)
            end)
            
            if deserializeSuccess then
                return deserializedItem
            end
        end
        
        return item
    end
    
    return nil
end

--[[ Cache Management ]]--

-- Clean expired items from local cache
function MemoryStoreManager:cleanLocalCache()
    local currentTime = os.time()
    local count = 0
    
    for key, data in pairs(self._localCache) do
        if currentTime > data.expires then
            self._localCache[key] = nil
            count = count + 1
        end
    end
    
    if count > 0 then
        debugPrint("Cleaned " .. count .. " expired items from local cache")
    end
    
    return count
end

-- Get cache statistics
function MemoryStoreManager:getCacheStats()
    local count = 0
    local byCategory = {}
    
    for key, _ in pairs(self._localCache) do
        count = count + 1
        
        -- Extract category from key
        local category = string.match(key, "^([^:]+):")
        if category then
            byCategory[category] = (byCategory[category] or 0) + 1
        end
    end
    
    return {
        totalItems = count,
        byCategory = byCategory,
        operations = self._operationCount
    }
end

--[[ Initialization and Core Functions ]]--

-- Initialize the MemoryStoreManager
function MemoryStoreManager:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing MemoryStoreManager...")
    
    -- Set up cache cleanup
    task.spawn(function()
        while true do
            task.wait(CONFIG.cleanupInterval)
            self:cleanLocalCache()
        end
    end)
    
    self._initialized = true
    debugPrint("MemoryStoreManager initialized")
    return true
end

-- Stop the MemoryStoreManager
function MemoryStoreManager:shutdown()
    -- Nothing to disconnect or clean up for now
    self._initialized = false
    debugPrint("MemoryStoreManager shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- MemoryStore Map operations
    setValue = function(category, id, value, expiration)
        return MemoryStoreManager:setValue(category, id, value, expiration)
    end,
    
    getValue = function(category, id)
        return MemoryStoreManager:getValue(category, id)
    end,
    
    removeValue = function(category, id)
        return MemoryStoreManager:removeValue(category, id)
    end,
    
    updateValue = function(category, id, updateFunc)
        return MemoryStoreManager:updateValue(category, id, updateFunc)
    end,
    
    -- MemoryStore Queue operations
    addToQueue = function(category, item, priority, expiration)
        return MemoryStoreManager:addToQueue(category, item, priority, expiration)
    end,
    
    readFromQueue = function(category, timeoutSeconds)
        return MemoryStoreManager:readFromQueue(category, timeoutSeconds)
    end,
    
    -- Cache management
    cleanLocalCache = function()
        return MemoryStoreManager:cleanLocalCache()
    end,
    
    getCacheStats = function()
        return MemoryStoreManager:getCacheStats()
    end,
}

-- Initialize the system
MemoryStoreManager:initialize()

-- Register with CoreRegistry
if CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("MemoryStoreManager", PublicAPI)
end

return PublicAPI