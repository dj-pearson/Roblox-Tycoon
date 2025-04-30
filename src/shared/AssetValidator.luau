-- AssetValidator.luau
-- Validates UI assets and resources to ensure they exist and are appropriate
-- Created: May 2, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

-- Cache common services
local ModuleLoader

-- Try to load ModuleLoader
local function tryRequireModuleLoader()
    local success, result = pcall(function()
        -- Try different paths for ModuleLoader
        for _, path in ipairs({
            ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoader"),
            ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("ModuleLoader"),
            ReplicatedStorage:FindFirstChild("ModuleLoader"),
        }) do
            if path and path:IsA("ModuleScript") then
                return require(path)
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    else
        warn("[AssetValidator] Could not load ModuleLoader, using built-in fallbacks")
        return nil
    end
end

-- Simple module loader fallback in case ModuleLoader isn't available
local function findModule(moduleName)
    -- Search paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    -- Look in each path
    for _, path in ipairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
        end
    end
    
    return nil
end

-- Create the validator module
local AssetValidator = {
    Version = "1.0.0",
    IsLoaded = true,
    ValidatedAssets = {}, -- Cache of validated assets
}

-- Asset types and validation methods
local AssetTypes = {
    Image = "rbxassetid://",
    Sound = "rbxassetid://",
    Animation = "rbxassetid://",
    MeshPart = "rbxassetid://",
    Font = Enum.Font,
    Color = Color3
}

-- Initialize the module
function AssetValidator.Initialize()
    print("[AssetValidator] Initializing...")
    
    -- Try to get ModuleLoader
    ModuleLoader = tryRequireModuleLoader()
    
    -- Register with ClientRegistry if available
    if ModuleLoader then
        local clientRegistry = ModuleLoader.tryRequire("ClientRegistry")
        if clientRegistry and typeof(clientRegistry.Register) == "function" then
            clientRegistry:Register("AssetValidator", AssetValidator)
            print("[AssetValidator] Registered with ClientRegistry")
        end
    end
    
    print("[AssetValidator] Initialization complete")
    return true
end

-- Validate an asset ID or reference
function AssetValidator.ValidateAsset(assetId, assetType)
    -- If we've already validated this asset, return from cache
    if AssetValidator.ValidatedAssets[assetId] then
        return AssetValidator.ValidatedAssets[assetId]
    end
    
    -- If no asset type specified, try to detect it
    if not assetType then
        if typeof(assetId) == "string" and string.find(assetId, "rbxassetid://") then
            assetType = "Image" -- Default to image for asset IDs
        elseif typeof(assetId) == "EnumItem" then
            assetType = "Enum"
        elseif typeof(assetId) == "Color3" then
            assetType = "Color"
        end
    end
    
    -- Default result
    local validationResult = {
        isValid = false,
        assetType = assetType or "Unknown",
        assetId = assetId,
        errorMessage = nil
    }
    
    -- Validate based on type
    if assetType == "Image" or assetType == "Sound" or assetType == "Animation" or assetType == "MeshPart" then
        -- Check if it's a valid asset ID format
        if typeof(assetId) ~= "string" then
            validationResult.errorMessage = "Asset ID must be a string"
        elseif not string.find(assetId, "rbxassetid://") then
            validationResult.errorMessage = "Asset ID must start with rbxassetid://"
        else
            -- Try to preload the asset to verify it exists
            local success, message = pcall(function()
                ContentProvider:PreloadAsync({assetId})
            end)
            
            if success then
                validationResult.isValid = true
            else
                validationResult.errorMessage = "Failed to load asset: " .. tostring(message)
            end
        end
    elseif assetType == "Font" then
        -- Validate font
        if typeof(assetId) == "EnumItem" and assetId.EnumType == Enum.Font then
            validationResult.isValid = true
        else
            validationResult.errorMessage = "Not a valid Font enum"
        end
    elseif assetType == "Color" then
        -- Validate color
        if typeof(assetId) == "Color3" then
            validationResult.isValid = true
        else
            validationResult.errorMessage = "Not a valid Color3 value"
        end
    else
        validationResult.errorMessage = "Unknown asset type"
    end
    
    -- Cache the result
    AssetValidator.ValidatedAssets[assetId] = validationResult
    
    return validationResult
end

-- Validate and return a fallback if invalid
function AssetValidator.ValidateOrDefault(assetId, assetType, defaultAsset)
    local result = AssetValidator.ValidateAsset(assetId, assetType)
    
    if result.isValid then
        return assetId
    else
        return defaultAsset
    end
end

-- Get fallback assets for different types
function AssetValidator.GetDefaultAsset(assetType)
    local defaults = {
        Image = "rbxassetid://9823548700",  -- A generic placeholder image
        Sound = "rbxassetid://9042996635",  -- A generic sound effect
        Font = Enum.Font.Gotham,
        Color = Color3.fromRGB(255, 255, 255)
    }
    
    return defaults[assetType] or defaults.Image
end

-- Preload a set of assets
function AssetValidator.PreloadAssets(assetIds)
    if typeof(assetIds) ~= "table" or #assetIds == 0 then
        return false, "No assets to preload"
    end
    
    local success, message = pcall(function()
        ContentProvider:PreloadAsync(assetIds)
    end)
    
    return success, message
end

-- Auto-initialize on load
task.spawn(function()
    AssetValidator.Initialize()
end)

return AssetValidator
