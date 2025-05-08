--[[
    AssetManager.server.luau
    
    Manages asset loading and permissions, providing fallback mechanisms
    for inaccessible assets and proper error handling.
    
    Features:
    - Asset permission validation
    - Fallback asset management
    - Asset caching
    - Error tracking and reporting
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds,
    fallbackAssets = {
        -- Equipment
        [8093763464] = 1234567890, -- Example fallback ID
        -- Add more fallback mappings as needed
    },
    assetTypes = {
        Model = true,
        Decal = true,
        MeshPart = true,
        Texture = true
    }
}

-- Module state
local AssetManager = {
    initialized = false,
    loadedAssets = {}, -- Cache of loaded assets
    errors = {},      -- Error history
    lastCheck = 0     -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[AssetManager]", ...)
    end
end

-- Get ModuleResolver
local function getModuleResolver()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local resolver = coreRegistry:getSystem("ModuleResolver")
        if resolver then
            return resolver
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolver") then
        local success, result = pcall(function()
            return require(core.ModuleResolver)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Check asset permissions
local function checkAssetPermissions(assetId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(assetId)
    end)
    
    if not success then
        return false, "Failed to get product info: " .. tostring(result)
    end
    
    -- Check if the asset is owned by the game
    if not result.IsOwned then
        return false, "Asset not owned by the game"
    end
    
    return true, "Accessible"
end

-- Get fallback asset
local function getFallbackAsset(assetId)
    return CONFIG.fallbackAssets[assetId]
end

-- Load asset
local function loadAsset(assetId)
    -- Check cache first
    if AssetManager.loadedAssets[assetId] then
        return AssetManager.loadedAssets[assetId]
    end
    
    -- Check permissions
    local hasAccess, message = checkAssetPermissions(assetId)
    if not hasAccess then
        -- Try fallback asset
        local fallbackId = getFallbackAsset(assetId)
        if fallbackId then
            log("Using fallback asset for " .. assetId .. ": " .. fallbackId)
            assetId = fallbackId
        else
            AssetManager.recordError("No access to asset " .. assetId .. ": " .. message)
            return nil
        end
    end
    
    -- Load the asset
    local success, asset = pcall(function()
        return game:GetService("InsertService"):LoadAsset(assetId)
    end)
    
    if not success then
        AssetManager.recordError("Failed to load asset " .. assetId .. ": " .. tostring(asset))
        return nil
    end
    
    -- Cache the asset
    AssetManager.loadedAssets[assetId] = asset
    return asset
end

-- Initialize AssetManager
function AssetManager.initialize()
    if AssetManager.initialized then return true end
    
    log("Initializing AssetManager...")
    
    -- Get ModuleResolver
    local resolver = getModuleResolver()
    if not resolver then
        log("ModuleResolver not found, asset loading may be limited", true)
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            AssetManager.checkHealth()
        end
    end)
    
    AssetManager.initialized = true
    log("AssetManager initialized")
    return true
end

-- Get asset
function AssetManager.getAsset(assetId)
    if not AssetManager.initialized then
        AssetManager.initialize()
    end
    
    return loadAsset(assetId)
end

-- Preload assets
function AssetManager.preloadAssets(assetIds)
    if not AssetManager.initialized then
        AssetManager.initialize()
    end
    
    for _, assetId in ipairs(assetIds) do
        loadAsset(assetId)
    end
end

-- Clear asset cache
function AssetManager.clearCache()
    for _, asset in pairs(AssetManager.loadedAssets) do
        if typeof(asset) == "Instance" then
            asset:Destroy()
        end
    end
    AssetManager.loadedAssets = {}
end

-- Check system health
function AssetManager.checkHealth()
    local now = os.time()
    AssetManager.lastCheck = now
    
    -- Check loaded assets count
    local assetCount = 0
    for _ in pairs(AssetManager.loadedAssets) do
        assetCount = assetCount + 1
    end
    
    if assetCount > 100 then
        AssetManager.recordError("Too many loaded assets: " .. assetCount)
    end
    
    -- Check error count
    if #AssetManager.errors > 50 then
        AssetManager.recordError("Too many errors: " .. #AssetManager.errors)
    end
    
    return true
end

-- Record an error
function AssetManager.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(AssetManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #AssetManager.errors > 50 do
        table.remove(AssetManager.errors, 1)
    end
    
    log("Error recorded: " .. message)
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
    return AssetManager.checkHealth()
end

return AssetManager 