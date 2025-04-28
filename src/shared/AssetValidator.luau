--[[
    AssetValidator.luau
    
    A utility module for validating and loading assets properly, ensuring UI and 
    other game assets are correctly loaded and available before use.
    
    Created to address the "AssetValidator not found" issues identified in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Try to get ErrorHandlingUtility
local ErrorHandling
local errorTypes = {
    ASSET_ERROR = "AssetError",
    VALIDATION_ERROR = "ValidationError"
}

local function tryGetErrorHandling()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then return nil end
    
    local errorModule = shared:FindFirstChild("ErrorHandlingUtility")
    if not errorModule or not errorModule:IsA("ModuleScript") then return nil end
    
    local success, result = pcall(function()
        return require(errorModule)
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

-- Configuration
local CONFIG = {
    debug = true,
    assetTypes = {
        IMAGE = "Image",
        MESH = "Mesh",
        SOUND = "Sound",
        ANIMATION = "Animation",
        UI = "UI",
        OTHER = "Other"
    },
    defaultAssetFolders = {
        Images = "rbxassetid://0", -- Default blank image
        Meshes = nil,
        Sounds = nil,
        Animations = nil,
        UI = nil
    },
    preloadCommonAssets = true,
    validateTimeoutSeconds = 10
}

-- Local variables
local validatedAssets = {}
local failedAssets = {}
local loadingPromises = {}
local preloadedAssets = {}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[AssetValidator]", ...)
    end
end

-- Report an error
local function reportError(errorType, message, source, additionalInfo)
    -- If ErrorHandling module is available, use it
    if ErrorHandling then
        return ErrorHandling.error["report" .. errorType](message, source, additionalInfo)
    else
        -- Basic error reporting
        warn("[AssetValidator]", errorType, ":", message, "(", source or "", ")")
        return {
            type = errorType,
            message = message,
            source = source or "AssetValidator",
            timestamp = os.time(),
            additional = additionalInfo or {}
        }
    end
end

-- Get asset type based on asset instance
local function getAssetType(asset)
    if not asset then
        return CONFIG.assetTypes.OTHER
    end
    
    -- Check by ClassName
    if asset:IsA("ImageLabel") or asset:IsA("ImageButton") or asset:IsA("Decal") or asset:IsA("Texture") then
        return CONFIG.assetTypes.IMAGE
    elseif asset:IsA("SpecialMesh") or asset:IsA("MeshPart") or asset:IsA("FileMesh") then
        return CONFIG.assetTypes.MESH
    elseif asset:IsA("Sound") or asset:IsA("SoundGroup") then
        return CONFIG.assetTypes.SOUND
    elseif asset:IsA("Animation") or asset:IsA("AnimationTrack") then
        return CONFIG.assetTypes.ANIMATION
    elseif asset:IsA("UIComponent") or asset:IsA("GuiObject") then
        return CONFIG.assetTypes.UI
    else
        return CONFIG.assetTypes.OTHER
    end
end

-- Get asset ID from an asset
local function getAssetId(asset)
    if not asset then return nil end
    
    -- Get asset ID based on type
    local assetType = getAssetType(asset)
    
    if assetType == CONFIG.assetTypes.IMAGE then
        if asset:IsA("ImageLabel") or asset:IsA("ImageButton") then
            return asset.Image
        elseif asset:IsA("Decal") or asset:IsA("Texture") then
            return asset.Texture
        end
    elseif assetType == CONFIG.assetTypes.MESH then
        if asset:IsA("SpecialMesh") or asset:IsA("FileMesh") then
            return asset.MeshId
        elseif asset:IsA("MeshPart") then
            return asset.MeshID
        end
    elseif assetType == CONFIG.assetTypes.SOUND then
        if asset:IsA("Sound") then
            return asset.SoundId
        end
    elseif assetType == CONFIG.assetTypes.ANIMATION then
        if asset:IsA("Animation") then
            return asset.AnimationId
        end
    end
    
    -- Check common asset ID properties
    local commonProperties = {"AssetId", "ID", "Id", "TextureID", "TextureId"}
    for _, prop in ipairs(commonProperties) do
        if asset[prop] and typeof(asset[prop]) == "string" then
            return asset[prop]
        end
    end
    
    return nil
end

-- Wait with timeout
local function waitWithTimeout(seconds)
    local endTime = os.clock() + (seconds or CONFIG.validateTimeoutSeconds)
    
    return function()
        if os.clock() >= endTime then
            return true
        end
        RunService.Heartbeat:Wait()
        return false
    end
end

-- Validate a single asset
local function validateAsset(asset, options)
    options = options or {}
    local assetId = options.assetId or getAssetId(asset)
    local assetType = options.assetType or getAssetType(asset)
    local source = options.source or "Unknown"
    
    -- If no asset ID, automatically pass validation
    if not assetId or assetId == "" then
        return true
    end
    
    -- Check if already validated
    if validatedAssets[assetId] then
        return true
    end
    
    -- Check if already failed
    if failedAssets[assetId] then
        if options.suppressErrors ~= true then
            reportError(errorTypes.ASSET_ERROR, "Asset previously failed validation", source, {
                assetId = assetId,
                assetType = assetType
            })
        end
        return false
    end
    
    -- Normalize rbxassetid format
    if assetId:find("rbxassetid://") then
        -- Already in correct format
    elseif assetId:find("rbxasset://") then
        -- Local asset, assume it's valid
        validatedAssets[assetId] = true
        return true
    elseif tonumber(assetId) then
        -- Convert number to rbxassetid format
        assetId = "rbxassetid://" .. assetId
    end
    
    -- Special case for empty/zero asset IDs
    if assetId == "rbxassetid://0" or assetId == "0" or assetId == "" then
        validatedAssets[assetId] = true
        return true
    end
    
    -- Check if already loading this asset
    if loadingPromises[assetId] then
        -- Wait for existing load to finish
        log("Waiting for existing load of asset:", assetId)
        
        -- If it's a UI workflow, we don't want to block
        if options.noWait then
            return true
        end
        
        -- Set up timeout checker
        local timedOut = waitWithTimeout()
        
        while loadingPromises[assetId] do
            if timedOut() then
                reportError(errorTypes.VALIDATION_ERROR, "Asset validation timed out", source, {
                    assetId = assetId,
                    assetType = assetType
                })
                return false
            end
            RunService.Heartbeat:Wait()
        end
        
        -- Check if successfully loaded
        if validatedAssets[assetId] then
            return true
        else
            if options.suppressErrors ~= true then
                reportError(errorTypes.ASSET_ERROR, "Asset failed previous validation", source, {
                    assetId = assetId,
                    assetType = assetType
                })
            end
            return false
        end
    end
    
    -- Start loading
    loadingPromises[assetId] = true
    
    -- Different validation strategies based on asset type
    local validationSuccess = false
    
    -- Use ContentProvider to preload
    if assetType == CONFIG.assetTypes.IMAGE or assetType == CONFIG.assetTypes.MESH then
        log("Validating asset:", assetId)
        
        local success, result = pcall(function()
            ContentProvider:PreloadAsync({assetId})
            return true
        end)
        
        validationSuccess = success
        
        if not success and options.suppressErrors ~= true then
            reportError(errorTypes.ASSET_ERROR, "Failed to preload asset: " .. tostring(result), source, {
                assetId = assetId,
                assetType = assetType
            })
        end
    elseif assetType == CONFIG.assetTypes.SOUND then
        -- Create temporary sound object to validate
        local tempSound = Instance.new("Sound")
        tempSound.Volume = 0
        tempSound.SoundId = assetId
        
        local connection
        local loaded = false
        
        connection = tempSound.Loaded:Connect(function()
            loaded = true
            validationSuccess = true
            if connection then connection:Disconnect() end
        end)
        
        -- Use timeout
        local timedOut = waitWithTimeout()
        
        while not loaded do
            if timedOut() then
                if options.suppressErrors ~= true then
                    reportError(errorTypes.VALIDATION_ERROR, "Sound validation timed out", source, {
                        assetId = assetId
                    })
                end
                break
            end
            RunService.Heartbeat:Wait()
        end
        
        tempSound:Destroy()
    else
        -- For other asset types, just assume they're valid
        validationSuccess = true
    end
    
    -- Update tracking
    if validationSuccess then
        validatedAssets[assetId] = true
    else
        failedAssets[assetId] = true
    end
    
    -- Clear loading promise
    loadingPromises[assetId] = nil
    
    return validationSuccess
end

-- Validate multiple assets
local function validateAssets(assets, options)
    options = options or {}
    
    -- Handle array of assets
    if typeof(assets) == "table" and #assets > 0 then
        local allValid = true
        local results = {}
        
        for index, asset in ipairs(assets) do
            local valid = validateAsset(asset, options)
            results[index] = valid
            
            if not valid then
                allValid = false
            end
        end
        
        return allValid, results
    -- Handle a single asset
    elseif typeof(assets) == "Instance" then
        return validateAsset(assets, options)
    -- Handle a single asset ID
    elseif typeof(assets) == "string" then
        return validateAsset(nil, {
            assetId = assets,
            assetType = options.assetType or CONFIG.assetTypes.OTHER,
            source = options.source
        })
    end
    
    return false
end

-- Preload common assets
local function preloadCommonAssets()
    if not CONFIG.preloadCommonAssets then
        return
    end
    
    log("Preloading common assets")
    
    -- Find asset folders
    local assetFolder = ReplicatedStorage:FindFirstChild("Assets")
    
    -- If no asset folder exists, use defaults
    if not assetFolder then
        for folderName, defaultAsset in pairs(CONFIG.defaultAssetFolders) do
            if defaultAsset then
                validateAsset(nil, {
                    assetId = defaultAsset,
                    assetType = folderName:sub(1, -2), -- Remove 's' to get type
                    source = "PreloadCommonAssets",
                    suppressErrors = true
                })
            end
        end
        return
    end
    
    -- Preload assets from folders
    for _, folder in ipairs(assetFolder:GetChildren()) do
        if folder:IsA("Folder") then
            log("Preloading assets from folder:", folder.Name)
            
            -- Limit to 10 assets per folder to avoid long load times
            local count = 0
            
            for _, asset in ipairs(folder:GetChildren()) do
                if count >= 10 then break end
                
                local assetId = getAssetId(asset)
                if assetId then
                    validateAsset(asset, {
                        source = "PreloadCommonAssets",
                        suppressErrors = true
                    })
                    preloadedAssets[assetId] = true
                    count = count + 1
                end
            end
        end
    end
    
    log("Common asset preloading complete")
end

-- Get fallback asset for type
local function getFallbackAsset(assetType)
    assetType = assetType or CONFIG.assetTypes.OTHER
    
    -- Check type and return appropriate fallback
    if assetType == CONFIG.assetTypes.IMAGE then
        return "rbxassetid://0" -- Blank image
    elseif assetType == CONFIG.assetTypes.SOUND then
        return "rbxassetid://0" -- Silent sound
    end
    
    -- For types without fallbacks, return nil
    return nil
end

-- Initialize the module
local function initialize()
    log("Initializing AssetValidator")
    
    -- Try to get ErrorHandling utility
    ErrorHandling = tryGetErrorHandling()
    
    -- Preload common assets after a short delay
    task.delay(1, function()
        preloadCommonAssets()
    end)
    
    log("AssetValidator initialized")
end

-- Initialize
initialize()

-- Public API
return {
    -- Core validation functions
    validateAsset = validateAsset,
    validateAssets = validateAssets,
    
    -- Asset information
    getAssetType = getAssetType,
    getAssetId = getAssetId,
    
    -- Fallbacks 
    getFallbackAsset = getFallbackAsset,
    
    -- Status information
    getValidatedAssets = function()
        return validatedAssets
    end,
    
    getFailedAssets = function()
        return failedAssets
    end,
    
    isAssetValid = function(assetId)
        return validatedAssets[assetId] == true
    end,
    
    -- Utility functions
    preloadAssets = function(assets, options)
        return validateAssets(assets, options)
    end,
    
    clearCache = function()
        -- Only clear failed assets, keep validated ones
        failedAssets = {}
        log("Failed asset cache cleared")
    end,
    
    -- Constants
    assetTypes = CONFIG.assetTypes
}
