--[[
    AssetValidator.luau
    
    Core system for validating and managing game assets.
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
    PRELOAD_ON_INIT = true,
    CRITICAL_ASSETS_ONLY = false,
    REPORT_MISSING = true,
    VERIFY_MODEL_PROPERTIES = true
}

-- Asset categories
AssetValidator.CATEGORIES = {
    CRITICAL = "critical",
    STANDARD = "standard",
    OPTIONAL = "optional"
}

-- Debug settings
AssetValidator.DEBUG = true

-- Asset registry
local assetRegistry = {
    models = {},
    images = {},
    sounds = {},
    animations = {},
    other = {}
}

-- Log a message to the output
local function log(message)
    if AssetValidator.DEBUG then
        print("[AssetValidator] " .. message)
    end
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try in ReplicatedStorage
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("replicatedStorage") then
        -- Try CoreRegistryShared for clients
        if RunService:IsClient() and shared.replicatedStorage:FindFirstChild("CoreRegistryShared") then
            local success, result = pcall(function()
                return require(shared.replicatedStorage.CoreRegistryShared)
            end)
            
            if success and result then
                return result
            end
        end
        
        -- Try ModuleScriptAccessor
        if shared.replicatedStorage:FindFirstChild("ModuleScriptAccessor") then
            local success, result = pcall(function()
                return require(shared.replicatedStorage.ModuleScriptAccessor)
            end)
            
            if success and result and typeof(result.getCoreRegistry) == "function" then
                return result.getCoreRegistry()
            end
        end
    end
    
    return nil
end

-- Initialize the asset validator
function AssetValidator.initialize()
    if AssetValidator.initialized then
        return true
    end
    
    log("Initializing AssetValidator...")
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("AssetValidator", AssetValidator)
        log("Registered with CoreRegistry")
    else
        log("CoreRegistry not found, but AssetValidator will still function")
    end
    
    -- Create asset container if it doesn't exist
    local assetContainer = ReplicatedStorage:FindFirstChild("GameAssets")
    if not assetContainer then
        assetContainer = Instance.new("Folder")
        assetContainer.Name = "GameAssets"
        assetContainer.Parent = ReplicatedStorage
        log("Created GameAssets folder in ReplicatedStorage")
    end
    
    -- Preload critical assets if configured
    if CONFIG.PRELOAD_ON_INIT then
        log("Preloading critical assets...")
        AssetValidator.preloadAssets(AssetValidator.CATEGORIES.CRITICAL)
    end
    
    AssetValidator.initialized = true
    log("AssetValidator initialized")
    
    return true
end

-- Register an asset to be managed
function AssetValidator.registerAsset(assetInfo)
    if not assetInfo or type(assetInfo) ~= "table" then
        warn("[AssetValidator] Invalid asset info provided")
        return false
    end
    
    -- Required properties
    if not assetInfo.id then
        warn("[AssetValidator] Asset missing required id property")
        return false
    end
    
    -- Set default values
    assetInfo.category = assetInfo.category or AssetValidator.CATEGORIES.STANDARD
    assetInfo.type = assetInfo.type or "other"
    assetInfo.preloaded = assetInfo.preloaded or false
    
    -- Store in appropriate category
    local category = assetInfo.type
    if not assetRegistry[category] then
        assetRegistry[category] = {}
    end
    
    assetRegistry[category][assetInfo.id] = assetInfo
    log("Registered " .. category .. " asset: " .. assetInfo.id)
    
    return true
end

-- Register multiple assets at once
function AssetValidator.registerAssets(assets)
    if not assets or type(assets) ~= "table" then
        warn("[AssetValidator] Invalid assets table provided")
        return 0
    end
    
    local count = 0
    for _, assetInfo in ipairs(assets) do
        if AssetValidator.registerAsset(assetInfo) then
            count = count + 1
        end
    end
    
    log("Registered " .. count .. " assets")
    return count
end

-- Preload assets by category
function AssetValidator.preloadAssets(category)
    -- Collect assets to preload
    local assetsToPreload = {}
    
    -- Function to collect assets of specified category
    local function collectCategoryAssets(assetType, cat)
        if assetRegistry[assetType] then
            for id, info in pairs(assetRegistry[assetType]) do
                if info.category == cat and not info.preloaded then
                    if string.sub(id, 1, 11) == "rbxassetid:" then
                        table.insert(assetsToPreload, id)
                    end
                end
            end
        end
    end
    
    -- If no category specified, preload all
    if not category then
        for cat, _ in pairs(AssetValidator.CATEGORIES) do
            for assetType, _ in pairs(assetRegistry) do
                collectCategoryAssets(assetType, cat)
            end
        end
    else
        -- Preload specific category
        for assetType, _ in pairs(assetRegistry) do
            collectCategoryAssets(assetType, category)
        end
    end
    
    -- If no assets to preload, return early
    if #assetsToPreload == 0 then
        log("No assets to preload for category: " .. (category or "all"))
        return true
    end
    
    -- Preload the collected assets
    log("Preloading " .. #assetsToPreload .. " assets")
    local success, errorMessage = pcall(function()
        ContentProvider:PreloadAsync(assetsToPreload)
    end)
    
    if success then
        log("Successfully preloaded all assets")
        
        -- Mark assets as preloaded
        for _, assetId in ipairs(assetsToPreload) do
            for assetType, assets in pairs(assetRegistry) do
                if assets[assetId] then
                    assets[assetId].preloaded = true
                end
            end
        end
        
        return true
    else
        warn("[AssetValidator] Failed to preload assets: " .. tostring(errorMessage))
        return false
    end
end

-- Verify if a model contains all required components
function AssetValidator.verifyModel(model, requirements)
    if not model or typeof(model) ~= "Instance" then
        warn("[AssetValidator] Invalid model provided for verification")
        return false
    end
    
    requirements = requirements or {}
    
    -- Check for required children
    if requirements.requiredChildren then
        for _, childName in ipairs(requirements.requiredChildren) do
            if not model:FindFirstChild(childName) then
                warn("[AssetValidator] Model " .. model.Name .. " missing required child: " .. childName)
                return false
            end
        end
    end
    
    -- Check for required properties
    if requirements.requiredProperties and CONFIG.VERIFY_MODEL_PROPERTIES then
        for propName, expectedValue in pairs(requirements.requiredProperties) do
            -- Skip if property doesn't exist
            if not model[propName] then
                warn("[AssetValidator] Model " .. model.Name .. " missing required property: " .. propName)
                return false
            end
            
            -- Check if value matches expected
            if model[propName] ~= expectedValue then
                warn("[AssetValidator] Model " .. model.Name .. " property mismatch - " .. propName .. ": expected " .. tostring(expectedValue) .. ", got " .. tostring(model[propName]))
                return false
            end
        end
    end
    
    -- All checks passed
    return true
end

-- Get all registered assets of a specific type
function AssetValidator.getAssetsByType(assetType)
    assetType = assetType or "all"
    
    if assetType == "all" then
        local allAssets = {}
        for type, assets in pairs(assetRegistry) do
            for id, info in pairs(assets) do
                allAssets[id] = info
            end
        end
        
        return allAssets
    else
        return assetRegistry[assetType] or {}
    end
end

-- Get an asset by its ID
function AssetValidator.getAssetById(assetId)
    for _, assets in pairs(assetRegistry) do
        if assets[assetId] then
            return assets[assetId]
        end
    end
    
    return nil
end

-- Check if an asset is registered
function AssetValidator.isAssetRegistered(assetId)
    return AssetValidator.getAssetById(assetId) ~= nil
end

-- Client interface that's safe to expose to clients
function AssetValidator:getClientInterface()
    local clientInterface = {
        isAssetRegistered = self.isAssetRegistered,
        preloadAssets = self.preloadAssets,
        CATEGORIES = self.CATEGORIES
    }
    
    return clientInterface
end

-- Initialize AssetValidator
AssetValidator.initialize()

return AssetValidator
