--[[
    AssetValidator.luau
    
    Validates asset references and ensures they are properly loaded.
    This module helps prevent errors caused by missing or invalid assets.
    
    Created: April 30, 2025
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetValidator = {}
AssetValidator.initialized = false

-- Debug settings
AssetValidator.DEBUG = true

-- Statistics tracking
local stats = {
    validatedCount = 0,
    failedCount = 0,
    cachedAssets = {}
}

-- Log a message to the output
local function log(message)
    if AssetValidator.DEBUG then
        print("[AssetValidator] " .. message)
    end
end

-- Validate a single asset ID
function AssetValidator.validateAsset(assetId)
    if not assetId then
        return false, "No asset ID provided"
    end
    
    -- Check if in our cache
    if stats.cachedAssets[assetId] then
        return stats.cachedAssets[assetId].valid, stats.cachedAssets[assetId].message
    end
    
    -- Check format
    if not string.match(assetId, "^rbxassetid://[0-9]+$") and 
       not string.match(assetId, "^rbxthumb://[0-9]+$") then
        stats.cachedAssets[assetId] = {valid = false, message = "Invalid asset ID format"}
        stats.failedCount += 1
        return false, "Invalid asset ID format: " .. assetId
    end
    
    -- Try to preload
    local success = pcall(function()
        ContentProvider:PreloadAsync({assetId})
    end)
    
    if success then
        stats.cachedAssets[assetId] = {valid = true, message = "Asset validated"}
        stats.validatedCount += 1
        return true, "Asset validated"
    else
        stats.cachedAssets[assetId] = {valid = false, message = "Failed to preload asset"}
        stats.failedCount += 1
        return false, "Failed to preload asset: " .. assetId
    end
end

-- Validate multiple assets
function AssetValidator.validateAssets(assetIds)
    if not assetIds or type(assetIds) ~= "table" then
        return false, "Invalid asset ID table"
    end
    
    local results = {
        success = true,
        validCount = 0,
        failCount = 0,
        failedAssets = {}
    }
    
    for _, assetId in ipairs(assetIds) do
        local success, message = AssetValidator.validateAsset(assetId)
        if success then
            results.validCount += 1
        else
            results.success = false
            results.failCount += 1
            table.insert(results.failedAssets, {id = assetId, message = message})
        end
    end
    
    return results
end

-- Check if an asset ID is valid
function AssetValidator.isValidAssetId(assetId)
    local success, _ = AssetValidator.validateAsset(assetId)
    return success
end

-- Validate assets in a UI object (recursively)
function AssetValidator.validateUIAssets(uiObject)
    if not uiObject then
        return false, "No UI object provided"
    end
    
    local results = {
        success = true,
        validCount = 0,
        failCount = 0,
        failedAssets = {}
    }
    
    -- Function to check an object and its children
    local function checkObject(obj)
        -- Check image properties if present
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local image = obj.Image
            if image and image ~= "" and not string.match(image, "^rbxasset://") then
                local success, message = AssetValidator.validateAsset(image)
                if success then
                    results.validCount += 1
                else
                    results.success = false
                    results.failCount += 1
                    table.insert(results.failedAssets, {
                        id = image, 
                        object = obj:GetFullName(), 
                        message = message
                    })
                end
            end
        end
        
        -- Check background properties
        if obj:IsA("GuiObject") and obj.BackgroundColor3 ~= nil then
            -- No need to validate Color3 values
        end
        
        -- Check children recursively
        for _, child in ipairs(obj:GetChildren()) do
            checkObject(child)
        end
    end
    
    -- Start the validation
    checkObject(uiObject)
    
    return results
end

-- Get validation statistics
function AssetValidator.getStats()
    return {
        validatedCount = stats.validatedCount,
        failedCount = stats.failedCount,
        cachedAssetsCount = #stats.cachedAssets
    }
}

-- Reset the validation cache
function AssetValidator.resetCache()
    stats.cachedAssets = {}
    log("Asset validation cache reset")
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
    
    AssetValidator.initialized = true
    log("AssetValidator initialized")
    return true
end

-- Initialize on load
AssetValidator.initialize()

return AssetValidator
