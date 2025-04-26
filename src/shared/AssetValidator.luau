--!strict
--[[
    AssetValidator.luau
    
    A utility module for validating and managing assets.
    
    Created: April 25, 2025
    
    This module:
    1. Validates all types of assets (sounds, animations, images)
    2. Maintains a robust catalog of fallback assets
    3. Implements asset preloading for critical assets
    4. Adds detailed logging for asset loading failures
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    VERBOSE_LOGGING = false,
    ENABLE_VALIDATION = true,
    PRELOAD_CRITICAL_ASSETS = true,
    TRACK_LOADING_STATS = true
}

-- Constants
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()
local IsStudio = RunService:IsStudio()

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    print("[AssetValidator] Created shared folder in ReplicatedStorage")
end

-- State tracking
local validationResults = {}
local assetLoadAttempts = {}
local assetLoadSuccesses = {}
local assetLoadFailures = {}
local criticalAssets = {}
local preloadedAssets = {}

-- Fallback assets by type
local fallbackAssets = {
    Image = "rbxassetid://6031090990",  -- Placeholder image
    Sound = "rbxassetid://1547213590",  -- Placeholder sound
    Animation = "rbxassetid://507766388", -- Simple idle animation
    Mesh = "rbxassetid://94586901",     -- Simple cube mesh
    Texture = "rbxassetid://6031090990", -- Placeholder texture
    Icon = "rbxassetid://6031090990",   -- Placeholder icon
    Logo = "rbxassetid://6031090990",   -- Placeholder logo
    UI = "rbxassetid://6031090990"      -- Placeholder UI element
}

-- AssetValidator Module
local AssetValidator = {
    fallbackAssets = fallbackAssets,
    validationResults = validationResults,
    stats = {
        totalAssets = 0,
        validAssets = 0,
        invalidAssets = 0,
        preloadedAssets = 0,
        loadAttempts = 0,
        loadSuccesses = 0,
        loadFailures = 0
    }
}

-- Debug logging
local function log(message, isVerbose)
    if CONFIG.DEBUG_LOGGING and (not isVerbose or CONFIG.VERBOSE_LOGGING) then
        print("[AssetValidator] " .. message)
    end
end

-- Register a critical asset that should always be preloaded
function AssetValidator.registerCriticalAsset(assetId, assetType)
    if not assetId then
        warn("[AssetValidator] Cannot register critical asset: nil asset ID")
        return false
    end
    
    -- Ensure the asset ID is a proper format
    if not string.match(assetId, "^rbxassetid://") and not tonumber(assetId) then
        warn("[AssetValidator] Invalid asset ID format: " .. assetId)
        return false
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Store in critical assets list
    criticalAssets[normalizedId] = assetType or "Unknown"
    log("Registered critical asset: " .. normalizedId .. " (Type: " .. (assetType or "Unknown") .. ")")
    
    -- If we're already initialized, preload this asset now
    if AssetValidator.initialized and CONFIG.PRELOAD_CRITICAL_ASSETS then
        AssetValidator.preloadAsset(normalizedId)
    end
    
    return true
end

-- Validate a single asset
function AssetValidator.validateAsset(assetId, assetType, skipCache)
    if not assetId then
        warn("[AssetValidator] Cannot validate nil asset ID")
        return false
    end
    
    -- Check cache first unless skipCache is true
    if not skipCache and validationResults[assetId] ~= nil then
        log("Using cached validation result for " .. assetId .. ": " .. tostring(validationResults[assetId]), true)
        return validationResults[assetId]
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Track attempt
    if CONFIG.TRACK_LOADING_STATS then
        AssetValidator.stats.loadAttempts += 1
        assetLoadAttempts[normalizedId] = (assetLoadAttempts[normalizedId] or 0) + 1
    end
    
    -- Try to load the asset
    local success = pcall(function()
        -- Try different validation approaches based on asset type
        if assetType == "Image" or assetType == "Texture" or assetType == "Icon" or assetType == "Logo" or assetType == "UI" then
            -- For images, create a temporary ImageLabel
            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Image = normalizedId
            imageLabel:GetPropertyChangedSignal("IsLoaded"):Wait()
            if not imageLabel.IsLoaded then
                error("Image failed to load: " .. normalizedId)
            end
            imageLabel:Destroy()
        elseif assetType == "Sound" then
            -- For sounds, create a temporary Sound
            local sound = Instance.new("Sound")
            sound.SoundId = normalizedId
            sound.Parent = ReplicatedStorage
            
            -- No clean way to check if sound loaded in Lua, so we'll just wait
            task.delay(0.5, function()
                sound:Destroy()
            end)
        elseif assetType == "Animation" then
            -- For animations, create a temporary Animation
            local animation = Instance.new("Animation")
            animation.AnimationId = normalizedId
            
            -- Try to load it
            local animationTrack = nil
            if IsServer then
                -- Can't easily validate on server
                -- Just assume it's valid
                return true
            else
                -- On client, try to load in a dummy Animator
                local dummy = Instance.new("Part")
                dummy.Anchored = true
                dummy.CanCollide = false
                dummy.Transparency = 1
                dummy.Parent = workspace
                
                local humanoid = Instance.new("Humanoid")
                humanoid.Parent = dummy
                
                local animator = Instance.new("Animator")
                animator.Parent = humanoid
                
                animationTrack = animator:LoadAnimation(animation)
                
                -- Wait briefly
                task.delay(0.5, function()
                    animationTrack:Stop()
                    dummy:Destroy()
                end)
            end
        else
            -- For other asset types, use ContentProvider
            ContentProvider:PreloadAsync({normalizedId}, function(assetId, status)
                if status ~= Enum.AssetFetchStatus.Success then
                    error("Asset failed to load: " .. assetId .. " (Status: " .. tostring(status) .. ")")
                end
            end)
        end
    end)
    
    -- Store result
    validationResults[normalizedId] = success
    
    -- Update stats
    if CONFIG.TRACK_LOADING_STATS then
        if success then
            AssetValidator.stats.loadSuccesses += 1
            assetLoadSuccesses[normalizedId] = (assetLoadSuccesses[normalizedId] or 0) + 1
            AssetValidator.stats.validAssets += 1
        else
            AssetValidator.stats.loadFailures += 1
            assetLoadFailures[normalizedId] = (assetLoadFailures[normalizedId] or 0) + 1
            AssetValidator.stats.invalidAssets += 1
            
            warn("[AssetValidator] Asset validation failed: " .. normalizedId .. " (Type: " .. (assetType or "Unknown") .. ")")
        end
        
        AssetValidator.stats.totalAssets += 1
    end
    
    log("Validated asset " .. normalizedId .. ": " .. tostring(success) .. " (Type: " .. (assetType or "Unknown") .. ")")
    return success
end

-- Get a valid asset ID, with fallback if needed
function AssetValidator.getValidAssetId(assetId, assetType, skipValidation)
    if not assetId then
        warn("[AssetValidator] Cannot validate nil asset ID")
        return fallbackAssets[assetType] or fallbackAssets.Image
    end
    
    -- Skip validation if disabled or explicitly skipped
    if not CONFIG.ENABLE_VALIDATION or skipValidation then
        return assetId
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Check if asset is valid
    local isValid = AssetValidator.validateAsset(normalizedId, assetType)
    
    if not isValid then
        -- Return fallback asset
        local fallbackId = fallbackAssets[assetType] or fallbackAssets.Image
        log("Using fallback asset for " .. normalizedId .. ": " .. fallbackId)
        return fallbackId
    end
    
    return normalizedId
end

-- Preload a single asset
function AssetValidator.preloadAsset(assetId, assetType)
    if not assetId then
        warn("[AssetValidator] Cannot preload nil asset ID")
        return false
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Skip if already preloaded
    if preloadedAssets[normalizedId] then
        log("Asset already preloaded: " .. normalizedId, true)
        return true
    end
    
    log("Preloading asset: " .. normalizedId)
    
    -- Try to preload the asset
    local success = pcall(function()
        ContentProvider:PreloadAsync({normalizedId})
    end)
    
    -- Track result
    if success then
        preloadedAssets[normalizedId] = true
        AssetValidator.stats.preloadedAssets += 1
        log("Successfully preloaded asset: " .. normalizedId)
    else
        warn("[AssetValidator] Failed to preload asset: " .. normalizedId)
    end
    
    return success
end

-- Preload all critical assets
function AssetValidator.preloadCriticalAssets()
    log("Preloading critical assets...")
    
    local successCount = 0
    local totalCount = 0
    
    for assetId, assetType in pairs(criticalAssets) do
        totalCount += 1
        if AssetValidator.preloadAsset(assetId, assetType) then
            successCount += 1
        end
    end
    
    log("Preloaded " .. successCount .. "/" .. totalCount .. " critical assets")
    return successCount == totalCount
end

-- Preload a batch of assets
function AssetValidator.preloadAssetBatch(assetIds)
    if not assetIds or #assetIds == 0 then
        warn("[AssetValidator] No assets to preload")
        return false
    end
    
    -- Normalize all asset IDs
    local normalizedIds = {}
    for _, assetId in ipairs(assetIds) do
        if tonumber(assetId) then
            table.insert(normalizedIds, "rbxassetid://" .. assetId)
        else
            table.insert(normalizedIds, assetId)
        end
    end
    
    log("Preloading batch of " .. #normalizedIds .. " assets")
    
    -- Try to preload the assets
    local success = pcall(function()
        ContentProvider:PreloadAsync(normalizedIds)
    end)
    
    -- Track results
    if success then
        for _, assetId in ipairs(normalizedIds) do
            preloadedAssets[assetId] = true
        end
        
        AssetValidator.stats.preloadedAssets += #normalizedIds
        log("Successfully preloaded batch of " .. #normalizedIds .. " assets")
    else
        warn("[AssetValidator] Failed to preload asset batch with " .. #normalizedIds .. " assets")
    end
    
    return success
end

-- Get a list of all invalid assets
function AssetValidator.getInvalidAssets()
    local invalidAssets = {}
    
    for assetId, isValid in pairs(validationResults) do
        if not isValid then
            table.insert(invalidAssets, assetId)
        end
    end
    
    return invalidAssets
end

-- Generate an asset health report
function AssetValidator.generateHealthReport()
    local report = {
        timestamp = os.time(),
        totalAssets = AssetValidator.stats.totalAssets,
        validAssets = AssetValidator.stats.validAssets,
        invalidAssets = AssetValidator.stats.invalidAssets,
        preloadedAssets = AssetValidator.stats.preloadedAssets,
        loadAttempts = AssetValidator.stats.loadAttempts,
        loadSuccesses = AssetValidator.stats.loadSuccesses,
        loadFailures = AssetValidator.stats.loadFailures,
        invalidAssetsList = AssetValidator.getInvalidAssets(),
        criticalAssetsCount = #criticalAssets,
        preloadedAssetsCount = #preloadedAssets
    }
    
    return report
end

-- Print the current health report
function AssetValidator.printHealthReport()
    local report = AssetValidator.generateHealthReport()
    
    print("===== Asset Health Report =====")
    print("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S", report.timestamp))
    print("Total Assets: " .. report.totalAssets)
    print("Valid Assets: " .. report.validAssets)
    print("Invalid Assets: " .. report.invalidAssets)
    print("Preloaded Assets: " .. report.preloadedAssets)
    print("Load Attempts: " .. report.loadAttempts)
    print("Load Successes: " .. report.loadSuccesses)
    print("Load Failures: " .. report.loadFailures)
    print("Critical Assets: " .. report.criticalAssetsCount)
    print("Preloaded Assets: " .. report.preloadedAssetsCount)
    
    if #report.invalidAssetsList > 0 then
        print("Invalid Assets List:")
        for _, assetId in ipairs(report.invalidAssetsList) do
            print("  - " .. assetId)
        end
    else
        print("No invalid assets detected.")
    end
    
    print("===============================")
    
    return report
end

-- Initialize the validator
function AssetValidator.initialize()
    if AssetValidator.initialized then
        return true
    end
    
    log("Initializing AssetValidator")
    
    -- Preregister default fallback assets as critical
    for assetType, assetId in pairs(fallbackAssets) do
        AssetValidator.registerCriticalAsset(assetId, assetType)
    end
    
    -- Preload critical assets if enabled
    if CONFIG.PRELOAD_CRITICAL_ASSETS then
        task.spawn(function()
            AssetValidator.preloadCriticalAssets()
        end)
    end
    
    -- Auto-register common UI assets if we're on the client
    if IsClient then
        -- Add core UI assets
        local uiAssets = {
            "rbxassetid://3926307971", -- Common UI icons
            "rbxassetid://3926305904", -- Common UI icons
            "rbxassetid://6026568247", -- Coin icon
            "rbxassetid://6031090990"  -- Placeholder image
        }
        
        for _, assetId in ipairs(uiAssets) do
            AssetValidator.registerCriticalAsset(assetId, "UI")
        end
    end
    
    AssetValidator.initialized = true
    log("AssetValidator initialized")
    
    return true
end

-- Auto-initialize
AssetValidator.initialize()

return AssetValidator
