--!strict
--[[
    AssetValidator.server.luau
    
    Core system for validating and managing game assets.
    This module handles asset validation, loading, and error handling.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed initialization and CoreRegistry integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ContentProvider = game:GetService("ContentProvider")

-- Get CoreRegistry
local CoreRegistry
local success, result = pcall(function()
    return require(script.Parent.CoreRegistry)
end)
if success then
    CoreRegistry = result
end

local AssetValidator = {}
AssetValidator.initialized = false

-- Configuration
local CONFIG = {
    DEBUG = true,
    VALIDATION_TIMEOUT = 10, -- seconds
    MAX_RETRIES = 3,
    REQUIRED_ASSETS = {
        "Meshes",
        "Animations",
        "Textures",
        "Sounds"
    }
}

-- Asset registry
local validatedAssets = {}
local failedAssets = {}
local validationInProgress = {}

-- Log a message to the output
local function log(message)
    if CONFIG.DEBUG then
        print("[AssetValidator] " .. message)
    end
end

-- Initialize the asset validator
function AssetValidator:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing AssetValidator...")
    
    -- Create asset folders in ReplicatedStorage if they don't exist
    for _, folderName in ipairs(CONFIG.REQUIRED_ASSETS) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = ReplicatedStorage
            log("Created " .. folderName .. " folder in ReplicatedStorage")
        end
    end
    
    -- Register with CoreRegistry
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry:registerSystem("AssetValidator", self)
        log("Registered with CoreRegistry")
        
        -- Mark as initialized in CoreRegistry
        if typeof(CoreRegistry.markInitialized) == "function" then
            CoreRegistry:markInitialized("AssetValidator")
            log("Marked as initialized in CoreRegistry")
        end
    else
        log("CoreRegistry not found, but AssetValidator will still function")
    end
    
    self.initialized = true
    log("AssetValidator initialized successfully")
    return true
end

-- Validate an asset
function AssetValidator:validateAsset(assetId, assetType)
    if not assetId then
        warn("[AssetValidator] Invalid asset ID")
        return false
    end
    
    -- Check if already validated
    if validatedAssets[assetId] then
        return true
    end
    
    -- Check if validation is in progress
    if validationInProgress[assetId] then
        return false
    end
    
    validationInProgress[assetId] = true
    
    -- Try to load the asset
    local success = false
    for attempt = 1, CONFIG.MAX_RETRIES do
        local loaded = false
        local errorMessage = nil
        
        -- Create a promise to handle the asset loading
        local promise = Promise.new(function(resolve, reject)
            ContentProvider:PreloadAsync({assetId}, function(assetId, status)
                if status == Enum.AssetFetchStatus.Success then
                    loaded = true
                    resolve(true)
                else
                    errorMessage = tostring(status)
                    reject(errorMessage)
                end
            end)
        end)
        
        -- Wait for the promise with timeout
        local result = promise:timeout(CONFIG.VALIDATION_TIMEOUT)
        
        if result then
            success = true
            break
        else
            log("Asset validation attempt " .. attempt .. " failed for " .. assetId)
            if attempt < CONFIG.MAX_RETRIES then
                wait(1)
            end
        end
    end
    
    validationInProgress[assetId] = nil
    
    if success then
        validatedAssets[assetId] = {
            type = assetType,
            timestamp = os.time()
        }
        log("Successfully validated asset: " .. assetId)
    else
        failedAssets[assetId] = {
            type = assetType,
            timestamp = os.time()
        }
        warn("[AssetValidator] Failed to validate asset: " .. assetId)
    end
    
    return success
end

-- Check if an asset is valid
function AssetValidator:isAssetValid(assetId)
    return validatedAssets[assetId] ~= nil
end

-- Get asset validation status
function AssetValidator:getAssetStatus(assetId)
    if validatedAssets[assetId] then
        return "Valid", validatedAssets[assetId]
    elseif failedAssets[assetId] then
        return "Failed", failedAssets[assetId]
    elseif validationInProgress[assetId] then
        return "InProgress", nil
    else
        return "NotValidated", nil
    end
end

-- Get all validated assets
function AssetValidator:getValidatedAssets()
    return validatedAssets
end

-- Get all failed assets
function AssetValidator:getFailedAssets()
    return failedAssets
end

-- Get configuration
function AssetValidator:getConfig()
    return CONFIG
end

-- Check if initialized
function AssetValidator:isInitialized()
    return self.initialized
end

return AssetValidator 