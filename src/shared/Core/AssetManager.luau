--[[
    AssetManager.luau
    
    Core system for managing asset loading and permissions.
    This system ensures proper asset loading, fallback handling,
    and permission management.
    
    Features:
    - Asset loading and caching
    - Permission checking
    - Fallback asset management
    - Error tracking
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
    cacheTimeout = 300, -- 5 minutes
    fallbackAssets = {
        -- Define fallback assets for common types
        button = {
            enabled = "rbxassetid://8093763464",
            disabled = "rbxassetid://8093763465",
            hover = "rbxassetid://8093763466"
        },
        icon = {
            default = "rbxassetid://8093763467"
        },
        background = {
            default = "rbxassetid://8093763468"
        }
    }
}

-- Module state
local AssetManager = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    assetCache = {},
    assetTimestamps = {},
    assetPermissions = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[AssetManager]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            return handler
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
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

-- Check asset permission
local function checkAssetPermission(assetId)
    if not assetId then return false end
    
    -- Check cache first
    if AssetManager.assetPermissions[assetId] ~= nil then
        return AssetManager.assetPermissions[assetId]
    end
    
    -- Try to load asset
    local success = pcall(function()
        game:GetService("ContentProvider"):PreloadAsync({assetId})
    end)
    
    -- Cache result
    AssetManager.assetPermissions[assetId] = success
    
    return success
end

-- Get fallback asset
local function getFallbackAsset(assetType, subtype)
    if not assetType then return nil end
    
    local fallbacks = CONFIG.fallbackAssets[assetType]
    if not fallbacks then return nil end
    
    if subtype then
        return fallbacks[subtype] or fallbacks.default
    end
    
    return fallbacks.default
end

-- Load asset with retries
local function loadAssetWithRetries(assetId, retries)
    retries = retries or CONFIG.maxRetries
    local success
    
    for i = 1, retries do
        success = pcall(function()
            game:GetService("ContentProvider"):PreloadAsync({assetId})
        end)
        
        if success then
            return true
        end
        
        if i < retries then
            log("Failed to load asset, retrying... (" .. i .. "/" .. retries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return false
end

-- Load asset
local function loadAsset(assetId, assetType, subtype)
    if not assetId then
        return nil, "No asset ID provided"
    end
    
    -- Check cache first
    local cachedAsset = AssetManager.assetCache[assetId]
    local timestamp = AssetManager.assetTimestamps[assetId]
    
    if cachedAsset and timestamp then
        -- Check if cache is still valid
        if os.time() - timestamp < CONFIG.cacheTimeout then
            return cachedAsset
        end
    end
    
    -- Check permission
    if not checkAssetPermission(assetId) then
        -- Try fallback asset
        local fallbackId = getFallbackAsset(assetType, subtype)
        if fallbackId then
            log("Using fallback asset for: " .. assetId)
            return fallbackId
        end
        return nil, "No permission for asset: " .. assetId
    end
    
    -- Load asset
    local success = loadAssetWithRetries(assetId)
    if not success then
        return nil, "Failed to load asset: " .. assetId
    end
    
    -- Cache asset
    AssetManager.assetCache[assetId] = assetId
    AssetManager.assetTimestamps[assetId] = os.time()
    
    return assetId
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(AssetManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #AssetManager.errors > CONFIG.maxErrors do
        table.remove(AssetManager.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #AssetManager.errors, 1, -1 do
        if AssetManager.errors[i].timestamp < cutoff then
            table.remove(AssetManager.errors, i)
        end
    end
    
    -- Report to ErrorHandler
    local errorHandler = getErrorHandler()
    if errorHandler then
        errorHandler:recordError(message, "asset_manager", {
            timestamp = timestamp
        })
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    AssetManager.lastCheck = now
    
    -- Check cache validity
    for assetId, timestamp in pairs(AssetManager.assetTimestamps) do
        if now - timestamp >= CONFIG.cacheTimeout then
            -- Remove expired cache
            AssetManager.assetCache[assetId] = nil
            AssetManager.assetTimestamps[assetId] = nil
        end
    end
    
    return true
end

-- Initialize AssetManager
function AssetManager.initialize()
    if AssetManager.initialized then return true end
    
    log("Initializing AssetManager...")
    
    -- Get required systems
    local errorHandler = getErrorHandler()
    if not errorHandler then
        log("ErrorHandler not found, error reporting may be limited")
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    AssetManager.initialized = true
    log("AssetManager initialized")
    return true
end

-- Load asset
function AssetManager.loadAsset(assetId, assetType, subtype)
    local asset, error = loadAsset(assetId, assetType, subtype)
    if not asset then
        recordError(error)
    end
    return asset
end

-- Check asset permission
function AssetManager.checkPermission(assetId)
    return checkAssetPermission(assetId)
end

-- Get fallback asset
function AssetManager.getFallback(assetType, subtype)
    return getFallbackAsset(assetType, subtype)
end

-- Clear asset cache
function AssetManager.clearCache(assetId)
    if assetId then
        AssetManager.assetCache[assetId] = nil
        AssetManager.assetTimestamps[assetId] = nil
        AssetManager.assetPermissions[assetId] = nil
    else
        AssetManager.assetCache = {}
        AssetManager.assetTimestamps = {}
        AssetManager.assetPermissions = {}
    end
end

-- Get error count
function AssetManager.getErrorCount()
    return #AssetManager.errors
end

-- Get recent errors
function AssetManager.getRecentErrors()
    return AssetManager.errors
end

-- Force a health check
function AssetManager.forceCheck()
    return checkHealth()
end

return AssetManager 