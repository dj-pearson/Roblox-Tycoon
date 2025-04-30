--!strict
-- AssetValidator.luau
-- Validates asset existence and provides fallback mechanisms
-- Created on April 29, 2025 to fix UI system validation failures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

-- Default assets to use as fallbacks
local DEFAULT_ASSETS = {
    image = "rbxassetid://8587344193", -- Default blank image
    sound = "rbxassetid://6026984224", -- Default empty sound
    animation = "rbxassetid://4595066903", -- Default idle animation
    mesh = "rbxassetid://268440554", -- Default cylinder mesh
}

-- Cache of validated assets
local validatedAssets = {}

-- Cache of preloaded asset contents
local preloadedAssets = {}

-- Stats tracking
local stats = {
    totalChecks = 0,
    validAssets = 0,
    invalidAssets = 0,
    fallbacksUsed = 0,
    preloads = 0
}

-- Forward declarations
local AssetValidator = {}

-- Helper function to validate an asset ID
local function isValidAssetId(assetId)
    -- Basic format check (rbxassetid://numbers)
    if not string.match(assetId, "^rbxassetid://(%d+)$") then
        return false
    end
    
    -- Extract the numeric part
    local numericId = string.match(assetId, "(%d+)")
    if not numericId then
        return false
    end
    
    -- Check if the ID is reasonable (not 0 or negative)
    local idNumber = tonumber(numericId)
    if not idNumber or idNumber <= 0 then
        return false
    end
    
    return true
end

-- Check if we've already validated this asset
local function checkCache(assetId)
    return validatedAssets[assetId]
end

-- Primary validation function
function AssetValidator.validateAsset(assetId, assetType)
    stats.totalChecks += 1
    
    -- Safety checks
    if not assetId or assetId == "" then
        stats.invalidAssets += 1
        return false, DEFAULT_ASSETS[assetType or "image"] or DEFAULT_ASSETS.image
    end
    
    -- Check the cache first
    local cachedResult = checkCache(assetId)
    if cachedResult ~= nil then
        return cachedResult, cachedResult and assetId or DEFAULT_ASSETS[assetType or "image"] or DEFAULT_ASSETS.image
    end
    
    -- Basic format validation
    if not isValidAssetId(assetId) then
        validatedAssets[assetId] = false
        stats.invalidAssets += 1
        return false, DEFAULT_ASSETS[assetType or "image"] or DEFAULT_ASSETS.image
    end
    
    -- All checks passed, consider it valid (we'll know for sure when it's used)
    validatedAssets[assetId] = true
    stats.validAssets += 1
    return true, assetId
end

-- Preload an asset to ensure it's available when needed
function AssetValidator.preloadAsset(assetId, assetType)
    -- Validate first
    local isValid, validatedId = AssetValidator.validateAsset(assetId, assetType)
    
    -- Don't try to preload invalid assets
    if not isValid then
        return false
    end
    
    -- Skip if already preloaded
    if preloadedAssets[validatedId] then
        return true
    end
    
    -- Create appropriate instance based on asset type
    local instance
    if assetType == "image" then
        instance = Instance.new("ImageLabel")
        instance.Image = validatedId
    elseif assetType == "sound" then
        instance = Instance.new("Sound")
        instance.SoundId = validatedId
    elseif assetType == "animation" then
        instance = Instance.new("Animation")
        instance.AnimationId = validatedId
    elseif assetType == "mesh" then
        instance = Instance.new("SpecialMesh")
        instance.MeshId = validatedId
    else
        -- Default to image
        instance = Instance.new("ImageLabel")
        instance.Image = validatedId
    end
    
    -- Try to preload the asset
    local success = pcall(function()
        ContentProvider:PreloadAsync({instance})
    end)
    
    -- Clean up the temporary instance
    instance:Destroy()
    
    -- Cache the result
    if success then
        preloadedAssets[validatedId] = true
        stats.preloads += 1
    else
        -- If preload fails, mark it as invalid
        validatedAssets[assetId] = false
        stats.invalidAssets += 1
        stats.validAssets -= 1 -- Correct our previous count
    end
    
    return success
end

-- Batch validate multiple assets
function AssetValidator.validateBatch(assetTable)
    local results = {}
    local validCount = 0
    local totalCount = 0
    
    for key, info in pairs(assetTable) do
        totalCount += 1
        -- Handle different input formats
        local assetId, assetType
        
        if typeof(info) == "string" then
            assetId = info
            assetType = "image" -- Default
        elseif typeof(info) == "table" then
            assetId = info.id or info.assetId
            assetType = info.type or "image"
        end
        
        -- Validate
        local isValid, validatedId = AssetValidator.validateAsset(assetId, assetType)
        results[key] = {
            valid = isValid,
            id = validatedId,
            originalId = assetId,
            type = assetType
        }
        
        if isValid then
            validCount += 1
        end
    end
    
    return results, validCount, totalCount
end

-- Preload multiple assets in batch
function AssetValidator.preloadBatch(assetTable)
    local results = {}
    local successCount = 0
    local totalCount = 0
    
    for key, info in pairs(assetTable) do
        totalCount += 1
        -- Handle different input formats
        local assetId, assetType
        
        if typeof(info) == "string" then
            assetId = info
            assetType = "image" -- Default
        elseif typeof(info) == "table" then
            assetId = info.id or info.assetId
            assetType = info.type or "image"
        end
        
        -- Preload
        local success = AssetValidator.preloadAsset(assetId, assetType)
        results[key] = {
            success = success,
            id = success and assetId or DEFAULT_ASSETS[assetType],
            type = assetType
        }
        
        if success then
            successCount += 1
        end
    end
    
    return results, successCount, totalCount
end

-- Get the default asset for a type
function AssetValidator.getDefaultAsset(assetType)
    return DEFAULT_ASSETS[assetType] or DEFAULT_ASSETS.image
end

-- Get stats about asset validation
function AssetValidator.getStats()
    return {
        totalChecks = stats.totalChecks,
        validAssets = stats.validAssets,
        invalidAssets = stats.invalidAssets,
        fallbacksUsed = stats.fallbacksUsed,
        preloads = stats.preloads,
        cacheSize = #validatedAssets,
        preloadedSize = #preloadedAssets,
        passRate = stats.totalChecks > 0 and (stats.validAssets / stats.totalChecks * 100) or 0
    }
end

-- Reset stats (useful for testing)
function AssetValidator.resetStats()
    stats = {
        totalChecks = 0,
        validAssets = 0,
        invalidAssets = 0,
        fallbacksUsed = 0,
        preloads = 0
    }
end

-- Initialize with some common defaults
local function init()
    -- Prevalidate default assets
    for _, assetId in pairs(DEFAULT_ASSETS) do
        validatedAssets[assetId] = true
    end
    
    print("[AssetValidator] Initialized with", #DEFAULT_ASSETS, "default fallback assets")
end

init()

return AssetValidator
