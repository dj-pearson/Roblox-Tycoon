--[[
    AssetValidator.luau
    
    Utility for validating and managing game assets.
    Provides functionality for verifying asset IDs, preloading assets,
    and handling asset loading failures.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local AssetValidator = {}
AssetValidator.initialized = false

-- Configuration
local Config = {
    DEBUG = true,
    PRELOAD_RETRIES = 3,
    PRELOAD_RETRY_DELAY = 1,
    PRELOAD_BATCH_SIZE = 10,
    PRELOAD_BATCH_DELAY = 0.1
}

-- Asset caches
local validatedAssets = {}
local preloadedAssets = {}
local failedAssets = {}

-- Log a message to the output
local function log(message)
    if Config.DEBUG then
        print("[AssetValidator] " .. message)
    end
end

-- Validate an asset ID
function AssetValidator.validateAssetId(assetId)
    -- Clean up assetId if it's in rbxassetid:// format
    local cleanId = tostring(assetId):gsub("rbxassetid://", "")
    
    -- Check if we've already validated this asset
    if validatedAssets[cleanId] ~= nil then
        return validatedAssets[cleanId]
    end
    
    -- Validate format (should be numeric)
    if not tonumber(cleanId) then
        validatedAssets[cleanId] = false
        failedAssets[cleanId] = "Invalid format"
        return false
    end
    
    -- For actual validation, we'd need to make a request to Roblox API
    -- But since we're in a game context, we'll just assume it's valid if it's numeric
    validatedAssets[cleanId] = true
    return true
end

-- Format an asset ID for use in game
function AssetValidator.formatAssetId(assetId)
    if not assetId then return nil end
    
    local cleanId = tostring(assetId):gsub("rbxassetid://", "")
    if not AssetValidator.validateAssetId(cleanId) then
        return nil
    end
    
    return "rbxassetid://" .. cleanId
end

-- Preload a single asset
function AssetValidator.preloadAsset(assetId, callback)
    callback = callback or function() end
    
    -- Clean up assetId if it's in rbxassetid:// format
    local cleanId = tostring(assetId):gsub("rbxassetid://", "")
    
    -- Check if already preloaded
    if preloadedAssets[cleanId] then
        callback(true, cleanId)
        return
    end
    
    -- Validate asset ID first
    if not AssetValidator.validateAssetId(cleanId) then
        callback(false, cleanId, "Invalid asset ID")
        return
    end
    
    -- Create the content to preload
    local formattedId = "rbxassetid://" .. cleanId
    local success = pcall(function()
        ContentProvider:PreloadAsync({formattedId})
    end)
    
    if success then
        preloadedAssets[cleanId] = true
        callback(true, cleanId)
    else
        failedAssets[cleanId] = "Preload failed"
        callback(false, cleanId, "Preload failed")
    end
end

-- Preload multiple assets
function AssetValidator.preloadAssets(assetIds, progressCallback, completionCallback)
    local total = #assetIds
    local processed = 0
    local successful = 0
    
    -- Process assets in batches
    local function processNextBatch(startIndex)
        local endIndex = math.min(startIndex + Config.PRELOAD_BATCH_SIZE - 1, total)
        
        for i = startIndex, endIndex do
            local assetId = assetIds[i]
            
            AssetValidator.preloadAsset(assetId, function(success)
                processed = processed + 1
                if success then
                    successful = successful + 1
                end
                
                -- Call progress callback if provided
                if progressCallback and typeof(progressCallback) == "function" then
                    progressCallback(processed, total, successful)
                end
                
                -- If all processed, call completion callback
                if processed == total and completionCallback and typeof(completionCallback) == "function" then
                    completionCallback(successful, total)
                end
            end)
        end
        
        -- Process next batch if needed
        if endIndex < total then
            task.delay(Config.PRELOAD_BATCH_DELAY, function()
                processNextBatch(endIndex + 1)
            end)
        end
    end
    
    -- Start processing the first batch
    processNextBatch(1)
end

-- Check if an asset is preloaded
function AssetValidator.isPreloaded(assetId)
    local cleanId = tostring(assetId):gsub("rbxassetid://", "")
    return preloadedAssets[cleanId] == true
end

-- Get list of failed assets
function AssetValidator.getFailedAssets()
    local result = {}
    for id, reason in pairs(failedAssets) do
        table.insert(result, {id = id, reason = reason})
    end
    return result
end

-- Get statistics
function AssetValidator.getStats()
    local validatedCount = 0
    local preloadedCount = 0
    local failedCount = 0
    
    for _ in pairs(validatedAssets) do 
        validatedCount = validatedCount + 1 
    end
    
    for _ in pairs(preloadedAssets) do 
        preloadedCount = preloadedCount + 1 
    end
    
    for _ in pairs(failedAssets) do 
        failedCount = failedCount + 1 
    end
    
    return {
        validated = validatedCount,
        preloaded = preloadedCount,
        failed = failedCount
    }
end

-- Load common assets used in the UI
function AssetValidator.preloadCommonAssets(callback)
    local commonAssets = {
        "9801447135", -- Success icon
        "9801447023", -- Error icon
        "9801447287", -- Warning icon
        "9801446906"  -- Info icon
    }
    
    AssetValidator.preloadAssets(commonAssets, nil, callback)
end

-- Initialize the module
function AssetValidator.initialize()
    if AssetValidator.initialized then
        return true
    end
    
    -- Try to find ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor then
            -- Try to register with CoreRegistry
            local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
            if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
                CoreRegistry.registerSystem("AssetValidator", AssetValidator)
                log("Registered with CoreRegistry")
            end
        end
    end
    
    -- Preload common assets
    AssetValidator.preloadCommonAssets(function(successful, total)
        log(string.format("Preloaded %d/%d common assets", successful, total))
    end)
    
    log("AssetValidator initialized")
    AssetValidator.initialized = true
    return true
end

-- Initialize on load
AssetValidator.initialize()

return AssetValidator
