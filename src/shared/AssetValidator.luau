--[[
    AssetValidator.luau
    
    A module to validate and provide fallbacks for problematic assets.
    Helps resolve "Asset type does not match requested type" errors and other asset loading issues.
    
    Created: April 25, 2025
]]

local AssetValidator = {}

-- Constants
local DEBUG_ENABLED = true

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[AssetValidator] " .. message)
    end
end

local function warn_log(message)
    warn("[AssetValidator] " .. message)
end

-- Default fallback assets by type
local fallbackAssets = {
    Sound = "rbxassetid://6042633456", -- Generic notification sound
    Image = "rbxassetid://6031068426", -- Question mark icon
    Animation = "rbxassetid://507771019", -- Idle animation
    MeshPart = "rbxassetid://4923941319" -- Simple cube
}

-- Cache to store previously validated assets
local validatedAssetCache = {}

-- Map of known bad assets and their replacements
local knownBadAssets = {
    -- Sound assets
    ["rbxassetid://9125601193"] = "rbxassetid://6042633456",
    ["rbxassetid://9048378264"] = "rbxassetid://6042633456",
    
    -- Animation assets
    ["rbxassetid://4479935848"] = "rbxassetid://507771019",
    
    -- Add more problematic assets here
}

-- Function to validate a sound asset
function AssetValidator:validateSound(assetId)
    -- Check if we've already validated this asset
    if validatedAssetCache[assetId] then
        return validatedAssetCache[assetId]
    end
    
    -- Check if this is a known bad asset
    if knownBadAssets[assetId] then
        log("Known bad sound asset: " .. assetId .. ", using replacement")
        validatedAssetCache[assetId] = knownBadAssets[assetId]
        return knownBadAssets[assetId]
    end
    
    -- Test if the sound can be loaded
    local success = pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = assetId
    end)
    
    if success then
        validatedAssetCache[assetId] = assetId
        return assetId
    else
        warn_log("Failed to validate sound: " .. assetId .. ", using fallback")
        validatedAssetCache[assetId] = fallbackAssets.Sound
        return fallbackAssets.Sound
    end
end

-- Function to validate an image asset
function AssetValidator:validateImage(assetId)
    -- Check if we've already validated this asset
    if validatedAssetCache[assetId] then
        return validatedAssetCache[assetId]
    end
    
    -- Check if this is a known bad asset
    if knownBadAssets[assetId] then
        log("Known bad image asset: " .. assetId .. ", using replacement")
        validatedAssetCache[assetId] = knownBadAssets[assetId]
        return knownBadAssets[assetId]
    end
    
    -- Test if the image can be loaded
    local success = pcall(function()
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Image = assetId
    end)
    
    if success then
        validatedAssetCache[assetId] = assetId
        return assetId
    else
        warn_log("Failed to validate image: " .. assetId .. ", using fallback")
        validatedAssetCache[assetId] = fallbackAssets.Image
        return fallbackAssets.Image
    end
end

-- Function to validate an animation asset
function AssetValidator:validateAnimation(assetId)
    -- Check if we've already validated this asset
    if validatedAssetCache[assetId] then
        return validatedAssetCache[assetId]
    end
    
    -- Check if this is a known bad asset
    if knownBadAssets[assetId] then
        log("Known bad animation asset: " .. assetId .. ", using replacement")
        validatedAssetCache[assetId] = knownBadAssets[assetId]
        return knownBadAssets[assetId]
    end
    
    -- Animation validation requires actual loading, so we'll have to
    -- rely on known bad assets and fallbacks
    
    -- For now, just return the assetId and let the game handle errors
    validatedAssetCache[assetId] = assetId
    return assetId
end

-- Function to validate any asset ID based on expected type
function AssetValidator:validateAsset(assetId, assetType)
    if not assetId then
        warn_log("Nil asset ID provided, returning fallback")
        return fallbackAssets[assetType] or fallbackAssets.Image
    end
    
    -- Normalize assetId format
    if typeof(assetId) == "number" then
        assetId = "rbxassetid://" .. tostring(assetId)
    end
    
    -- Handle different asset types
    if assetType == "Sound" then
        return self:validateSound(assetId)
    elseif assetType == "Image" then
        return self:validateImage(assetId)
    elseif assetType == "Animation" then
        return self:validateAnimation(assetId)
    else
        -- Default to image validation for unknown types
        return self:validateImage(assetId)
    end
end

-- Function to create a validated asset instance
function AssetValidator:createInstance(instanceType, assetIdProperty, assetId)
    local instance = Instance.new(instanceType)
    
    -- Validate and set the asset ID
    local validatedId = self:validateAsset(assetId, instanceType)
    instance[assetIdProperty] = validatedId
    
    return instance
end

-- Create a validated Sound instance
function AssetValidator:createSound(soundId, properties)
    properties = properties or {}
    
    local validatedId = self:validateAsset(soundId, "Sound")
    local sound = Instance.new("Sound")
    sound.SoundId = validatedId
    
    -- Apply properties if provided
    for property, value in pairs(properties) do
        sound[property] = value
    end
    
    return sound
end

-- Create a validated ImageLabel instance
function AssetValidator:createImageLabel(imageId, properties)
    properties = properties or {}
    
    local validatedId = self:validateAsset(imageId, "Image")
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Image = validatedId
    
    -- Apply properties if provided
    for property, value in pairs(properties) do
        if property ~= "Image" then
            imageLabel[property] = value
        end
    end
    
    return imageLabel
end

-- Create a validated ImageButton instance
function AssetValidator:createImageButton(imageId, properties)
    properties = properties or {}
    
    local validatedId = self:validateAsset(imageId, "Image")
    local imageButton = Instance.new("ImageButton")
    imageButton.Image = validatedId
    
    -- Apply properties if provided
    for property, value in pairs(properties) do
        if property ~= "Image" then
            imageButton[property] = value
        end
    end
    
    return imageButton
end

-- Function to register a known bad asset and its replacement
function AssetValidator:registerBadAsset(assetId, replacementId)
    knownBadAssets[assetId] = replacementId
    validatedAssetCache[assetId] = replacementId
    log("Registered bad asset: " .. assetId .. " → " .. replacementId)
end

-- Function to set a fallback asset for a specific type
function AssetValidator:setFallbackAsset(assetType, assetId)
    fallbackAssets[assetType] = assetId
    log("Set fallback " .. assetType .. " asset: " .. assetId)
end

-- Function to clear the validation cache
function AssetValidator:clearCache()
    validatedAssetCache = {}
    log("Cleared asset validation cache")
end

-- Function to get the list of known bad assets
function AssetValidator:getKnownBadAssets()
    return knownBadAssets
end

-- Function to play a sound safely
function AssetValidator:playSound(soundId, parent, properties)
    properties = properties or {}
    parent = parent or workspace
    
    local sound = self:createSound(soundId, properties)
    sound.Parent = parent
    
    -- Try to play the sound
    local success = pcall(function()
        sound:Play()
    end)
    
    if not success then
        warn_log("Failed to play sound: " .. sound.SoundId)
        
        -- Try the fallback sound
        sound.SoundId = fallbackAssets.Sound
        pcall(function()
            sound:Play()
        end)
    end
    
    -- Clean up after playing
    if properties.AutoCleanup ~= false then
        local duration = sound.TimeLength
        if duration == 0 then
            duration = 5 -- Default duration if TimeLength is not available
        end
        
        task.delay(duration + 0.5, function()
            sound:Destroy()
        end)
    end
    
    return sound
end

-- Register common problematic assets
AssetValidator:registerBadAsset("rbxassetid://9125601193", "rbxassetid://6042633456")
AssetValidator:registerBadAsset("rbxassetid://9048378264", "rbxassetid://6042633456")
AssetValidator:registerBadAsset("rbxassetid://4479935848", "rbxassetid://507771019")

return AssetValidator
