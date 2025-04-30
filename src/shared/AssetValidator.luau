--[[
    AssetValidator.luau
    
    Validates and preloads game assets to ensure they're available when needed.
    This module handles asset verification, preloading, and management.
    
    Created: April 30, 2025
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetValidator = {}
AssetValidator.initialized = false

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    PRELOAD_ENABLED = true,
    MAX_PARALLEL_PRELOADS = 10,
    PRELOAD_BATCH_SIZE = 20,
    VALIDATION_ENABLED = true
}

-- Asset tracking
local assetCache = {}
local preloadQueue = {}
local validatedAssets = {}
local failedAssets = {}
local preloadingActive = false

-- Log function
local function log(message, forceLog)
    if CONFIG.DEBUG_MODE or forceLog then
        print("[AssetValidator] " .. message)
    end
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[AssetValidator] Failed to require module:", result)
        return nil
    end
end

-- Get ModuleScriptAccessor if available
local function getModuleScriptAccessor()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        return safeRequire(shared.ModuleScriptAccessor)
    end
    return nil
end

-- Register with CoreRegistry if available
local function registerWithCoreRegistry()
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
        if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("AssetValidator", AssetValidator)
            log("Registered with CoreRegistry")
            return true
        end
    end
    
    log("CoreRegistry not available, working in standalone mode")
    return false
end

-- Check if an asset ID or instance is valid
function AssetValidator.validateAsset(asset)
    if not CONFIG.VALIDATION_ENABLED then
        return true
    end
    
    -- Skip if already validated
    local assetId = typeof(asset) == "string" and asset or asset:GetFullName()
    if validatedAssets[assetId] ~= nil then
        return validatedAssets[assetId]
    end
    
    -- Perform validation
    local success = pcall(function()
        if typeof(asset) == "string" then
            -- Check if it's an asset ID (rbxassetid://)
            if string.match(asset, "^rbxassetid://") then
                ContentProvider:PreloadAsync({asset})
            else
                -- Assume it's a path and try to find it
                local instance = game
                for part in string.gmatch(asset, "[^%.]+") do
                    instance = instance:FindFirstChild(part)
                    if not instance then
                        error("Path not found: " .. asset)
                    end
                end
            end
        else
            -- Instance validation
            if not asset:IsDescendantOf(game) then
                error("Instance not in game: " .. asset:GetFullName())
            end
        end
    end)
    
    -- Record validation result
    validatedAssets[assetId] = success
    if not success then
        failedAssets[assetId] = true
        warn("[AssetValidator] Asset validation failed for: " .. assetId)
    end
    
    return success
end

-- Preload an asset or list of assets
function AssetValidator.preloadAsset(asset, callback)
    if not CONFIG.PRELOAD_ENABLED then
        if callback then
            callback(true)
        end
        return true
    end
    
    if type(asset) == "table" then
        -- Handle array of assets
        for _, singleAsset in ipairs(asset) do
            AssetValidator.preloadAsset(singleAsset)
        end
        
        if callback then
            callback(true)
        end
        return true
    end
    
    -- Skip if already in cache
    local assetId = typeof(asset) == "string" and asset or asset:GetFullName()
    if assetCache[assetId] then
        if callback then
            callback(true)
        end
        return true
    end
    
    -- Add to preload queue
    table.insert(preloadQueue, {
        asset = asset,
        callback = callback
    })
    
    -- Start preload process if not already running
    if not preloadingActive then
        AssetValidator.processPreloadQueue()
    end
    
    return true
end

-- Process the preload queue
function AssetValidator.processPreloadQueue()
    if #preloadQueue == 0 or preloadingActive then
        return
    end
    
    preloadingActive = true
    
    -- Process in batches
    local function processBatch()
        if #preloadQueue == 0 then
            preloadingActive = false
            return
        end
        
        local batch = {}
        local callbacks = {}
        local batchSize = math.min(CONFIG.PRELOAD_BATCH_SIZE, #preloadQueue)
        
        for i = 1, batchSize do
            local item = table.remove(preloadQueue, 1)
            table.insert(batch, item.asset)
            if item.callback then
                table.insert(callbacks, item.callback)
            end
        end
        
        log("Preloading batch of " .. #batch .. " assets")
        
        ContentProvider:PreloadAsync(batch, function(assetId, status)
            local success = (status == Enum.AssetFetchStatus.Success)
            if success then
                assetCache[assetId] = true
            else
                warn("[AssetValidator] Failed to preload asset: " .. assetId)
                failedAssets[assetId] = true
            end
        end)
        
        -- Call callbacks
        for _, callback in ipairs(callbacks) do
            task.spawn(callback, true)
        end
        
        -- Schedule next batch
        task.delay(0.1, processBatch)
    end
    
    -- Start processing
    processBatch()
end

-- Check if an asset is preloaded
function AssetValidator.isAssetPreloaded(asset)
    local assetId = typeof(asset) == "string" and asset or asset:GetFullName()
    return assetCache[assetId] == true
end

-- Get validation statistics
function AssetValidator.getValidationStats()
    local validCount = 0
    local invalidCount = 0
    
    for _, valid in pairs(validatedAssets) do
        if valid then
            validCount += 1
        else
            invalidCount += 1
        end
    end
    
    return {
        validated = validCount,
        failed = invalidCount,
        total = validCount + invalidCount,
        preloaded = table.getn(assetCache)
    }
end

-- Debug utility: Show all failed assets
function AssetValidator.debugShowFailedAssets()
    local failedList = {}
    for assetId, _ in pairs(failedAssets) do
        table.insert(failedList, assetId)
    end
    
    log("Failed assets: " .. table.concat(failedList, ", "), true)
    return failedList
end

-- Initialize the module
function AssetValidator.initialize()
    if AssetValidator.initialized then
        return true
    end
    
    log("Initializing AssetValidator...")
    
    -- Register with CoreRegistry
    registerWithCoreRegistry()
    
    -- Set up automatic validation for critical assets
    if CONFIG.VALIDATION_ENABLED then
        -- Example: Validate critical assets here
    end
    
    AssetValidator.initialized = true
    log("AssetValidator initialized")
    
    return true
end

-- Initialize on load
AssetValidator.initialize()

return AssetValidator
