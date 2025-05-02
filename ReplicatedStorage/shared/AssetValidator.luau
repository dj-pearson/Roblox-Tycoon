--[[
    AssetValidator.luau
    
    A module for validating and loading assets for UI and other systems.
    Provides caching and error handling for asset loading.
    
    Created: May 1, 2025
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG = true,
    PRELOAD_ASSETS = true,
    CACHE_SIZE_LIMIT = 100,
    RETRIES = 3,
    RETRY_DELAY = 1
}

-- Asset cache to prevent duplicate loading
local assetCache = {}
local cacheSize = 0

-- Statistics
local stats = {
    totalRequests = 0,
    cacheHits = 0,
    cacheMisses = 0,
    loadErrors = 0,
    validationErrors = 0
}

local AssetValidator = {}

-- Helper function for logging
local function log(message, level)
    if not CONFIG.DEBUG and level ~= "Error" then return end
    
    local prefix = "[AssetValidator]"
    if level == "Error" then
        warn(prefix, message)
    elseif level == "Success" then
        print(prefix, "✓", message)
    else
        print(prefix, message)
    end
end

-- Function to clear the cache
function AssetValidator.clearCache()
    assetCache = {}
    cacheSize = 0
    log("Cache cleared", "Info")
end

-- Function to validate and load an asset
function AssetValidator.validateAsset(assetId, assetType)
    stats.totalRequests += 1
    
    -- Check cache first
    if assetCache[assetId] then
        stats.cacheHits += 1
        return assetCache[assetId]
    end
    
    stats.cacheMisses += 1
    
    -- Handle different asset types
    local asset = nil
    local success = false
    
    -- Determine asset class based on type
    local assetClass = nil
    if assetType == "Image" or assetType == "Decal" or assetType == "Texture" then
        assetClass = "ImageLabel"
    elseif assetType == "Sound" or assetType == "Music" then
        assetClass = "Sound"
    elseif assetType == "Animation" then
        assetClass = "Animation"
    elseif assetType == "Model" then
        assetClass = "Model"
    else
        assetClass = assetType -- Use the provided type directly
    end
    
    -- Create the asset
    local retries = 0
    while retries < CONFIG.RETRIES and not success do
        local success, result = pcall(function()
            local instance = Instance.new(assetClass)
            
            -- Set appropriate property based on asset type
            if assetClass == "ImageLabel" then
                instance.Image = assetId
            elseif assetClass == "Sound" then
                instance.SoundId = assetId
            elseif assetClass == "Animation" then
                instance.AnimationId = assetId
            end
            
            -- Try to preload
            if CONFIG.PRELOAD_ASSETS then
                ContentProvider:PreloadAsync({instance})
            end
            
            return instance
        end)
        
        if success then
            asset = result
            break
        else
            retries += 1
            log("Error loading asset " .. assetId .. ": " .. tostring(result) .. " (Retry " .. retries .. "/" .. CONFIG.RETRIES .. ")", "Error")
            task.wait(CONFIG.RETRY_DELAY)
        end
    end
    
    if not asset then
        stats.loadErrors += 1
        return nil
    end
    
    -- Cache the asset if we have room
    if cacheSize < CONFIG.CACHE_SIZE_LIMIT then
        assetCache[assetId] = asset
        cacheSize += 1
    end
    
    return asset
end

-- Alias for backward compatibility
AssetValidator.ValidateAsset = AssetValidator.validateAsset

-- Get the current statistics
function AssetValidator.getStats()
    return stats
end

-- Register with ClientRegistry if available
if RunService:IsClient() then
    task.spawn(function()
        -- Try to get ClientRegistry from ReplicatedStorage/shared
        local ClientRegistry = nil
        local success, result = pcall(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local sharedFolder = ReplicatedStorage:WaitForChild("shared", 5)
            if sharedFolder then
                local SafeRequire = require(sharedFolder:WaitForChild("SafeRequire", 2))
                if SafeRequire then
                    return SafeRequire.requireFromPath("ClientRegistry")
                end
            end
            return nil
        end)
        
        if success and result then
            ClientRegistry = result
            ClientRegistry:Register("AssetValidator", AssetValidator)
            log("Registered with ClientRegistry", "Success")
        end
    end)
end

return AssetValidator
