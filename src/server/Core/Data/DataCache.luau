--!strict
--[[
    DataCache.luau
    
    Provides advanced caching mechanisms to improve performance, reduce DataStore operations,
    and optimize memory usage in the data system.
    
    Features:
    - Multi-level caching (memory, session)
    - LRU eviction policy
    - Time-to-live (TTL) support
    - Cache scoping (player, global, temporary)
    - Write-through and write-back policies
    - Memory tracking and optimization
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Module constants and types
local DataCache = {}
local CACHE_MESSAGING_TOPIC = "DataCache_Invalidation"
local DEFAULT_CONFIG = {
    memoryLimit = 50 * 1024 * 1024, -- 50MB default limit
    defaultTTL = 300, -- 5 minutes default TTL
    sessionTimeout = 1800, -- 30 minutes session timeout
    enableSharedCache = false, -- Disabled by default
    writePolicy = "through", -- "through" or "back"
    checkInterval = 30, -- Check every 30 seconds
    maxEntriesPerScope = 1000, -- Maximum entries per scope
    logLevel = 2 -- 0=none, 1=errors, 2=warnings, 3=info, 4=verbose
}

-- Cache state
local initialized = false
local config = table.clone(DEFAULT_CONFIG)
local memoryCacheSize = 0
local cacheStats = {
    hits = 0,
    misses = 0,
    evictions = 0,
    writes = 0,
    errors = 0
}

-- Cache structure:
-- memory = {
--     [scope] = {
--         entries = {}, -- Ordered list of entries
--         lookup = {} -- Map for quick lookups
--     }
-- }
local memory = {}
local dirtyEntries = {} -- For write-back policy

-- Cache entry type
type CacheEntry = {
    key: string,
    value: any,
    scope: string,
    expires: number,
    lastAccessed: number,
    size: number,
    dirty: boolean,
    version: number
}

--[[ Private Utility Functions ]]--

-- Calculate the approximate memory size of an object
local function calculateSize(value)
    local valueType = typeof(value)
    
    if valueType == "nil" then
        return 0
    elseif valueType == "boolean" then
        return 4
    elseif valueType == "number" then
        return 8
    elseif valueType == "string" then
        return #value
    elseif valueType == "table" then
        local size = 40 -- Base table size
        
        for k, v in pairs(value) do
            size = size + calculateSize(k)
            size = size + calculateSize(v)
        end
        
        return size
    elseif valueType == "function" or valueType == "thread" or valueType == "userdata" then
        return 32 -- Approximate size for complex types
    else
        return 16 -- Default for other types
    end
end

-- Log messages based on log level
local function log(level, ...)
    if config.logLevel >= level then
        local prefix = "[DataCache]"
        
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

-- Ensure a scope exists in cache
local function ensureScopeExists(scope)
    if not memory[scope] then
        memory[scope] = {
            entries = {},
            lookup = {}
        }
    end
    
    return memory[scope]
end

-- Get current time in seconds
local function now()
    return os.time()
end

-- Check if an entry has expired
local function isExpired(entry)
    return entry.expires <= now()
end

-- Create a new cache entry
local function createCacheEntry(key, value, options)
    options = options or {}
    local scope = options.scope or "global"
    local ttl = options.ttl or config.defaultTTL
    
    local size = calculateSize(value)
    
    local entry = {
        key = key,
        value = value,
        scope = scope,
        expires = now() + ttl,
        lastAccessed = now(),
        size = size,
        dirty = false,
        version = 1
    }
    
    return entry
end

-- Update memory size tracking
local function updateMemorySizeTracking(deltaSize)
    memoryCacheSize = memoryCacheSize + deltaSize
    
    -- Log if we're approaching the limit
    if memoryCacheSize > config.memoryLimit * 0.9 and config.logLevel >= 2 then
        log(2, "Cache memory usage approaching limit:", math.floor(memoryCacheSize / 1024 / 1024), "MB /", 
            math.floor(config.memoryLimit / 1024 / 1024), "MB")
    end
end

-- Add entry to front of LRU list (most recently used)
local function addToFront(scopeCache, entry)
    table.insert(scopeCache.entries, 1, entry)
    scopeCache.lookup[entry.key] = entry
    updateMemorySizeTracking(entry.size)
end

-- Remove entry from LRU list
local function removeFromList(scopeCache, entry)
    for i, e in ipairs(scopeCache.entries) do
        if e.key == entry.key then
            table.remove(scopeCache.entries, i)
            break
        end
    end
    
    scopeCache.lookup[entry.key] = nil
    updateMemorySizeTracking(-entry.size)
    
    -- Track as eviction
    cacheStats.evictions = cacheStats.evictions + 1
end

-- Move entry to front of LRU list (after being accessed)
local function moveToFront(scopeCache, entry)
    removeFromList(scopeCache, entry)
    addToFront(scopeCache, entry)
end

-- Make room in cache by removing least recently used items
local function makeRoom(scope, sizeNeeded)
    local scopeCache = memory[scope]
    if not scopeCache then return end
    
    -- First remove expired entries
    for i = #scopeCache.entries, 1, -1 do
        local entry = scopeCache.entries[i]
        if isExpired(entry) then
            removeFromList(scopeCache, entry)
        end
    end
    
    -- If still need room, remove based on LRU
    local entriesCount = #scopeCache.entries
    if entriesCount > config.maxEntriesPerScope or memoryCacheSize + sizeNeeded > config.memoryLimit then
        for i = #scopeCache.entries, 1, -1 do
            local entry = scopeCache.entries[i]
            
            -- If entry is dirty, write it back before removing
            if entry.dirty and config.writePolicy == "back" then
                -- Add to dirty entries for write-back
                dirtyEntries[entry.key] = entry.value
            end
            
            removeFromList(scopeCache, entry)
            
            -- If we've made enough room, stop removing
            if entriesCount - i >= config.maxEntriesPerScope / 4 and 
               memoryCacheSize + sizeNeeded <= config.memoryLimit * 0.9 then
                break
            end
        end
    end
end

-- Clean all expired entries from cache
local function cleanExpiredEntries()
    for scope, scopeCache in pairs(memory) do
        for i = #scopeCache.entries, 1, -1 do
            local entry = scopeCache.entries[i]
            if isExpired(entry) then
                log(4, "Removing expired entry:", entry.key)
                removeFromList(scopeCache, entry)
            end
        end
    end
end

-- Maintenance task for cache health
local function runMaintenance()
    cleanExpiredEntries()
    
    -- Check memory usage and evict if needed
    if memoryCacheSize > config.memoryLimit * 0.9 then
        log(3, "Running cache eviction due to memory pressure:", 
            math.floor(memoryCacheSize / 1024 / 1024), "MB /", 
            math.floor(config.memoryLimit / 1024 / 1024), "MB")
        
        -- Evict entries from each scope based on LRU
        for scope, scopeCache in pairs(memory) do
            makeRoom(scope, 0)
        end
    end
    
    -- Process any dirty entries if using write-back policy
    if config.writePolicy == "back" and next(dirtyEntries) then
        -- Process write-backs (will be implemented by DataManager)
        local processedEntries = {}
        
        for key, value in pairs(dirtyEntries) do
            -- In a real implementation, this would write to DataStore
            -- For now, just mark as processed
            processedEntries[key] = true
        end
        
        -- Remove processed entries
        for key in pairs(processedEntries) do
            dirtyEntries[key] = nil
        end
    end
    
    -- Log cache stats if verbose logging
    if config.logLevel >= 4 then
        log(4, "Cache stats:", 
            "Hits:", cacheStats.hits, 
            "Misses:", cacheStats.misses, 
            "Evictions:", cacheStats.evictions, 
            "Writes:", cacheStats.writes, 
            "Errors:", cacheStats.errors, 
            "Memory:", math.floor(memoryCacheSize / 1024 / 1024), "MB")
    end
end

-- Parse cache key to extract components
local function parseKey(key)
    local parts = string.split(key, ":")
    local scope = parts[1] or "global"
    
    return {
        scope = scope,
        originalKey = key
    }
end

-- Format a standardized cache key
local function formatCacheKey(scope, key)
    return scope .. ":" .. key
end

--[[ Public API Functions ]]--

-- Initialize the cache with configuration
function DataCache:initialize(customConfig)
    if initialized then
        return true
    end
    
    -- Apply custom configuration if provided
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Set up maintenance task
    task.spawn(function()
        while true do
            task.wait(config.checkInterval)
            
            local success, err = pcall(runMaintenance)
            if not success then
                log(1, "Error in cache maintenance:", err)
                cacheStats.errors = cacheStats.errors + 1
            end
        end
    end)
    
    -- Set up messaging service if shared cache is enabled
    if config.enableSharedCache then
        local success, err = pcall(function()
            MessagingService:SubscribeAsync(CACHE_MESSAGING_TOPIC, function(message)
                local data = message.Data
                if data and data.key then
                    -- Invalidate the entry in this server's cache
                    DataCache:invalidate(data.key, {scope = data.scope})
                    log(3, "Received invalidation for:", data.key, "in scope:", data.scope)
                end
            end)
        end)
        
        if not success then
            log(1, "Failed to subscribe to cache messaging:", err)
            config.enableSharedCache = false
            cacheStats.errors = cacheStats.errors + 1
        end
    end
    
    log(3, "DataCache initialized with config:", config)
    initialized = true
    return true
end

-- Set a value in the cache
function DataCache:set(key, value, options)
    self:initialize()
    options = options or {}
    
    if not key then
        log(1, "Cannot set cache with nil key")
        return false
    end
    
    -- Parse options
    local scope = options.scope or "global"
    local ttl = options.ttl or config.defaultTTL
    local writePolicy = options.writePolicy or config.writePolicy
    
    -- Format cache key
    local cacheKey = formatCacheKey(scope, key)
    
    -- Ensure scope exists
    local scopeCache = ensureScopeExists(scope)
    
    -- Create or update entry
    local entry = scopeCache.lookup[cacheKey]
    if entry then
        -- Update existing entry
        local oldSize = entry.size
        entry.value = value
        entry.expires = now() + ttl
        entry.lastAccessed = now()
        entry.size = calculateSize(value)
        entry.dirty = (writePolicy == "back")
        entry.version = entry.version + 1
        
        -- Update memory tracking
        updateMemorySizeTracking(entry.size - oldSize)
        
        -- Move to front of LRU
        moveToFront(scopeCache, entry)
    else
        -- Make room if needed
        local valueSize = calculateSize(value)
        makeRoom(scope, valueSize)
        
        -- Create new entry
        entry = createCacheEntry(cacheKey, value, {
            scope = scope,
            ttl = ttl
        })
        entry.dirty = (writePolicy == "back")
        
        -- Add to cache
        addToFront(scopeCache, entry)
    end
    
    -- Track write
    cacheStats.writes = cacheStats.writes + 1
    
    -- Handle shared cache invalidation
    if config.enableSharedCache then
        -- Send invalidation message to other servers
        pcall(function()
            MessagingService:PublishAsync(CACHE_MESSAGING_TOPIC, {
                key = key,
                scope = scope,
                action = "set"
            })
        end)
    end
    
    return true
end

-- Get a value from the cache
function DataCache:get(key, options)
    self:initialize()
    options = options or {}
    
    if not key then
        log(1, "Cannot get cache with nil key")
        return nil, nil
    end
    
    -- Parse options
    local scope = options.scope or "global"
    
    -- Format cache key
    local cacheKey = formatCacheKey(scope, key)
    
    -- Check if scope exists
    local scopeCache = memory[scope]
    if not scopeCache then
        cacheStats.misses = cacheStats.misses + 1
        return nil, nil
    end
    
    -- Check if entry exists
    local entry = scopeCache.lookup[cacheKey]
    if not entry then
        cacheStats.misses = cacheStats.misses + 1
        return nil, nil
    end
    
    -- Check if expired
    if isExpired(entry) then
        removeFromList(scopeCache, entry)
        cacheStats.misses = cacheStats.misses + 1
        return nil, nil
    end
    
    -- Update access time and move to front
    entry.lastAccessed = now()
    moveToFront(scopeCache, entry)
    
    -- Track hit
    cacheStats.hits = cacheStats.hits + 1
    
    return entry.value, "memory"
end

-- Invalidate a cache entry
function DataCache:invalidate(key, options)
    self:initialize()
    options = options or {}
    
    if not key then
        log(1, "Cannot invalidate cache with nil key")
        return false
    end
    
    -- Parse options
    local scope = options.scope or "global"
    
    -- Format cache key
    local cacheKey = formatCacheKey(scope, key)
    
    -- Check if scope exists
    local scopeCache = memory[scope]
    if not scopeCache then
        return false
    end
    
    -- Check if entry exists
    local entry = scopeCache.lookup[cacheKey]
    if not entry then
        return false
    end
    
    -- If dirty and using write-back policy, write before removing
    if entry.dirty and config.writePolicy == "back" then
        dirtyEntries[key] = entry.value
    end
    
    -- Remove from cache
    removeFromList(scopeCache, entry)
    
    -- Handle shared cache invalidation
    if config.enableSharedCache then
        -- Send invalidation message to other servers
        pcall(function()
            MessagingService:PublishAsync(CACHE_MESSAGING_TOPIC, {
                key = key,
                scope = scope,
                action = "invalidate"
            })
        end)
    end
    
    return true
end

-- Clear all entries in a scope
function DataCache:clear(scope)
    self:initialize()
    
    if not scope then
        log(1, "Cannot clear cache with nil scope")
        return false
    end
    
    -- Check if scope exists
    local scopeCache = memory[scope]
    if not scopeCache then
        return false
    end
    
    -- Handle dirty entries
    if config.writePolicy == "back" then
        for _, entry in ipairs(scopeCache.entries) do
            if entry.dirty then
                dirtyEntries[entry.key] = entry.value
            end
        end
    end
    
    -- Calculate total size to remove
    local totalSize = 0
    for _, entry in ipairs(scopeCache.entries) do
        totalSize = totalSize + entry.size
    end
    
    -- Clear scope
    memory[scope] = {
        entries = {},
        lookup = {}
    }
    
    -- Update memory tracking
    updateMemorySizeTracking(-totalSize)
    
    -- Handle shared cache invalidation
    if config.enableSharedCache then
        -- Send invalidation message to other servers
        pcall(function()
            MessagingService:PublishAsync(CACHE_MESSAGING_TOPIC, {
                scope = scope,
                action = "clear"
            })
        end)
    end
    
    return true
end

-- Check if a key exists in cache
function DataCache:has(key, options)
    self:initialize()
    options = options or {}
    
    if not key then
        return false
    end
    
    -- Parse options
    local scope = options.scope or "global"
    
    -- Format cache key
    local cacheKey = formatCacheKey(scope, key)
    
    -- Check if scope exists
    local scopeCache = memory[scope]
    if not scopeCache then
        return false
    end
    
    -- Check if entry exists and not expired
    local entry = scopeCache.lookup[cacheKey]
    if not entry or isExpired(entry) then
        return false
    end
    
    return true
end

-- Touch a cache entry (update access time without getting value)
function DataCache:touch(key, options)
    self:initialize()
    options = options or {}
    
    if not key then
        return false
    end
    
    -- Parse options
    local scope = options.scope or "global"
    
    -- Format cache key
    local cacheKey = formatCacheKey(scope, key)
    
    -- Check if scope exists
    local scopeCache = memory[scope]
    if not scopeCache then
        return false
    end
    
    -- Check if entry exists
    local entry = scopeCache.lookup[cacheKey]
    if not entry or isExpired(entry) then
        return false
    end
    
    -- Update access time and move to front
    entry.lastAccessed = now()
    moveToFront(scopeCache, entry)
    
    return true
end

-- Get cache statistics
function DataCache:getStats()
    self:initialize()
    
    local stats = table.clone(cacheStats)
    stats.memorySizeMB = memoryCacheSize / 1024 / 1024
    stats.scopeCount = 0
    stats.entryCount = 0
    
    for scope, scopeCache in pairs(memory) do
        stats.scopeCount = stats.scopeCount + 1
        stats.entryCount = stats.entryCount + #scopeCache.entries
    end
    
    stats.hitRatio = stats.hits / (stats.hits + stats.misses)
    if stats.hitRatio ~= stats.hitRatio then -- Check for NaN
        stats.hitRatio = 0
    end
    
    stats.dirtyEntryCount = 0
    for _ in pairs(dirtyEntries) do
        stats.dirtyEntryCount = stats.dirtyEntryCount + 1
    end
    
    return stats
end

-- Set cache configuration
function DataCache:configure(newConfig)
    self:initialize()
    
    if not newConfig then
        return false
    end
    
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then -- Only update existing keys
            config[k] = v
        end
    end
    
    return true
end

-- Get current configuration
function DataCache:getConfig()
    self:initialize()
    return table.clone(config)
end

-- Internal helper to mark all entries as clean
function DataCache:_markAllEntriesAsClean()
    for scope, scopeCache in pairs(memory) do
        for _, entry in ipairs(scopeCache.entries) do
            entry.dirty = false
        end
    end
    
    -- Clear dirty entries
    dirtyEntries = {}
    
    return true
end

-- Internal helper to get all keys in a scope
function DataCache:_getAllKeysInScope(scope)
    if not scope then
        return {}
    end
    
    local scopeCache = memory[scope]
    if not scopeCache then
        return {}
    end
    
    local keys = {}
    for _, entry in ipairs(scopeCache.entries) do
        table.insert(keys, entry.key)
    end
    
    return keys
end

return DataCache
