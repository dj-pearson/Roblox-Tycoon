--[[
    AssetValidator.luau
    This module handles validation and loading of assets in the game.
    It provides fallback mechanisms for common asset types and caching for performance.
    
    Created to fix critical "Asset Loading Failures" reported in RobloxIssues.txt
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Determine if we're on the server or client
local RunService = game:GetService("RunService")
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe require helper
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("AssetValidator: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

-- Try to load dependencies
local EventBridge = safeRequire(findModule("EventBridge")) or {
    fireEvent = function() end,
    registerEvent = function() end
}

-- Create the module
local AssetValidator = {}

-- Version information
AssetValidator.VERSION = "1.0.0"
AssetValidator.isLoaded = true

-- Cache of validated assets
local validatedAssets = {}
local preloadQueue = {}
local preloadInProgress = false
local registeredFallbacks = {}

-- Constants
local ASSET_TYPES = {
    IMAGE = "Image",
    SOUND = "Sound",
    ANIMATION = "Animation",
    MESH = "MeshPart",
    TEXTURE = "Texture",
    FONT = "Font",
    PACKAGE = "Package",
    PLUGIN = "Plugin",
    UNKNOWN = "Unknown"
}

-- Default fallbacks for common asset types
local DEFAULT_FALLBACKS = {
    [ASSET_TYPES.IMAGE] = "rbxassetid://8388158292", -- Generic placeholder image
    [ASSET_TYPES.SOUND] = "rbxassetid://170765130", -- Silent sound file (0.1s)
    [ASSET_TYPES.ANIMATION] = nil, -- No default fallback for animations
    [ASSET_TYPES.FONT] = Enum.Font.Gotham -- Default font
}

-- Initialize the AssetValidator
function AssetValidator.initialize()
    print("AssetValidator: Initializing...")
    
    -- Register events with EventBridge if available
    if EventBridge.registerEvent then
        EventBridge.registerEvent("AssetValidator_AssetValidated")
        EventBridge.registerEvent("AssetValidator_AssetFailed")
        EventBridge.registerEvent("AssetValidator_AssetPreloaded")
    end
    
    -- Set up the preload processor
    if isClient then
        task.spawn(AssetValidator.processPreloadQueue)
    end
    
    print("AssetValidator: Initialized successfully")
    return true
end

-- Process the preload queue
function AssetValidator.processPreloadQueue()
    -- Only run on the client
    if not isClient then return end
    
    -- Don't run multiple instances
    if preloadInProgress then return end
    
    preloadInProgress = true
    
    -- Process the queue in the background
    task.spawn(function()
        while true do
            -- Get next batch of assets to preload (up to 10 at a time)
            local batch = {}
            for i = 1, 10 do
                if #preloadQueue == 0 then break end
                table.insert(batch, table.remove(preloadQueue, 1))
            end
            
            -- If no assets to preload, wait and check again
            if #batch == 0 then
                task.wait(1)
                continue
            end
            
            -- Preload the batch
            local success, result = pcall(function()
                ContentProvider:PreloadAsync(batch)
            end)
            
            if not success then
                warn("AssetValidator: Failed to preload batch - " .. tostring(result))
            end
            
            -- Give the game a chance to breathe
            task.wait(0.1)
        end
    end)
end

-- Validate an asset ID
function AssetValidator.validateAssetId(assetId, options)
    options = options or {}
    local assetType = options.assetType or ASSET_TYPES.UNKNOWN
    local fallbackId = options.fallback
    local mustValidate = options.mustValidate or false
    
    -- Clean up the asset ID format
    if typeof(assetId) == "string" then
        -- Extract only the ID number if it's a full rbxassetid
        local idNumber = string.match(assetId, "^rbxassetid://(%d+)$")
        if idNumber then
            assetId = idNumber
        end
        
        -- Convert string ID to number
        assetId = tonumber(assetId)
    end
    
    -- Check for invalid IDs
    if not assetId or assetId <= 0 then
        warn("AssetValidator: Invalid asset ID: " .. tostring(assetId))
        return AssetValidator.getFallback(assetType, fallbackId)
    end
    
    -- Format as rbxassetid
    local formattedId = "rbxassetid://" .. tostring(assetId)
    
    -- Check cache first
    if validatedAssets[formattedId] ~= nil then
        if validatedAssets[formattedId] == false then
            -- Asset previously failed validation
            return AssetValidator.getFallback(assetType, fallbackId)
        else
            -- Asset previously passed validation
            return formattedId
        end
    end
    
    -- For server, we can't validate content, so always return the ID
    if isServer and not mustValidate then
        -- But we should still queue it for later validation on client
        validatedAssets[formattedId] = true
        return formattedId
    end
    
    -- For client, actually validate the asset
    if isClient then
        local success = false
        
        -- For images and sounds, we can check if they exist
        if assetType == ASSET_TYPES.IMAGE then
            local testImage = Instance.new("ImageLabel")
            testImage.BackgroundTransparency = 1
            testImage.Image = formattedId
            testImage.Size = UDim2.new(0, 1, 0, 1)
            
            -- Check if image loads correctly
            success = pcall(function()
                testImage.Parent = StarterGui
                task.wait(0.1)
                testImage:Destroy()
            end)
            
            -- Preload the image if it's valid
            if success then
                table.insert(preloadQueue, formattedId)
            end
            
        elseif assetType == ASSET_TYPES.SOUND then
            local testSound = Instance.new("Sound")
            testSound.Volume = 0
            testSound.SoundId = formattedId
            
            -- Check if sound loads correctly
            success = pcall(function()
                testSound.Parent = workspace
                task.wait(0.1)
                testSound:Destroy()
            end)
            
            -- Preload the sound if it's valid
            if success then
                table.insert(preloadQueue, formattedId)
            end
            
        else
            -- For other asset types, we can't easily validate, so assume success
            success = true
        end
        
        -- Cache the result
        validatedAssets[formattedId] = success
        
        -- Fire event for tracking
        if EventBridge.fireEvent then
            if success then
                EventBridge.fireEvent("AssetValidator_AssetValidated", {
                    assetId = formattedId,
                    assetType = assetType
                })
            else
                EventBridge.fireEvent("AssetValidator_AssetFailed", {
                    assetId = formattedId,
                    assetType = assetType,
                    fallbackUsed = AssetValidator.getFallback(assetType, fallbackId)
                })
            end
        end
        
        -- Return the appropriate ID
        if success then
            return formattedId
        else
            return AssetValidator.getFallback(assetType, fallbackId)
        end
    end
    
    -- Default behavior (server-side or fallback)
    return formattedId
end

-- Get a fallback asset for a given type
function AssetValidator.getFallback(assetType, customFallback)
    -- If a custom fallback is provided, use it
    if customFallback then
        return customFallback
    end
    
    -- Check for registered fallbacks first
    if registeredFallbacks[assetType] then
        return registeredFallbacks[assetType]
    end
    
    -- Fallback to defaults
    return DEFAULT_FALLBACKS[assetType]
end

-- Register a fallback asset for a given type
function AssetValidator.registerFallback(assetType, fallbackId)
    if not assetType or not fallbackId then
        warn("AssetValidator: Invalid parameters for registerFallback")
        return false
    end
    
    -- Validate the fallback ID first
    local formattedId = AssetValidator.validateAssetId(fallbackId, {
        assetType = assetType,
        mustValidate = true
    })
    
    -- Don't register if validation failed
    if not formattedId then
        warn("AssetValidator: Fallback asset failed validation: " .. tostring(fallbackId))
        return false
    end
    
    registeredFallbacks[assetType] = formattedId
    return true
end

-- Clear cached validations
function AssetValidator.clearCache()
    validatedAssets = {}
end

-- Preload a list of assets
function AssetValidator.preloadAssets(assets)
    if typeof(assets) ~= "table" then
        warn("AssetValidator: Invalid assets list for preloading")
        return false
    end
    
    local validAssets = {}
    
    for _, asset in ipairs(assets) do
        local assetId = asset.id or asset
        local assetType = asset.type or ASSET_TYPES.UNKNOWN
        
        local validatedId = AssetValidator.validateAssetId(assetId, {
            assetType = assetType
        })
        
        if validatedId then
            table.insert(validAssets, validatedId)
        end
    end
    
    -- Add valid assets to preload queue
    for _, asset in ipairs(validAssets) do
        table.insert(preloadQueue, asset)
    end
    
    -- Start the preload processor if it's not already running
    if isClient and not preloadInProgress then
        task.spawn(AssetValidator.processPreloadQueue)
    end
    
    return true
end

-- Validate a sound asset specifically
function AssetValidator.validateSoundId(soundId, fallback)
    return AssetValidator.validateAssetId(soundId, {
        assetType = ASSET_TYPES.SOUND,
        fallback = fallback
    })
end

-- Validate an image asset specifically
function AssetValidator.validateImageId(imageId, fallback)
    return AssetValidator.validateAssetId(imageId, {
        assetType = ASSET_TYPES.IMAGE,
        fallback = fallback
    })
end

-- Create a validated ImageLabel
function AssetValidator.createImageLabel(imageId, properties)
    properties = properties or {}
    
    -- Validate the image ID
    local validatedId = AssetValidator.validateImageId(imageId, properties.fallback)
    
    -- Create the ImageLabel
    local imageLabel = Instance.new("ImageLabel")
    
    -- Set basic properties
    imageLabel.BackgroundTransparency = properties.BackgroundTransparency or 1
    imageLabel.Image = validatedId
    imageLabel.Size = properties.Size or UDim2.new(0, 100, 0, 100)
    
    -- Apply other properties if provided
    for property, value in pairs(properties) do
        -- Skip properties we've already set and those that aren't valid
        if property == "BackgroundTransparency" or property == "Image" or 
           property == "Size" or property == "fallback" or property == "Parent" then
            continue
        end
        
        -- Set the property
        pcall(function()
            imageLabel[property] = value
        end)
    end
    
    -- Set parent if provided
    if properties.Parent then
        imageLabel.Parent = properties.Parent
    end
    
    return imageLabel
end

-- Create a validated Sound
function AssetValidator.createSound(soundId, properties)
    properties = properties or {}
    
    -- Validate the sound ID
    local validatedId = AssetValidator.validateSoundId(soundId, properties.fallback)
    
    -- Create the Sound
    local sound = Instance.new("Sound")
    
    -- Set basic properties
    sound.SoundId = validatedId
    sound.Volume = properties.Volume or 0.5
    
    -- Apply other properties if provided
    for property, value in pairs(properties) do
        -- Skip properties we've already set and those that aren't valid
        if property == "SoundId" or property == "Volume" or 
           property == "fallback" or property == "Parent" then
            continue
        end
        
        -- Set the property
        pcall(function()
            sound[property] = value
        end)
    end
    
    -- Set parent if provided
    if properties.Parent then
        sound.Parent = properties.Parent
    end
    
    return sound
end

-- Get asset type by extension
function AssetValidator.getAssetTypeByExtension(extension)
    extension = string.lower(extension)
    
    if extension == "png" or extension == "jpg" or extension == "jpeg" then
        return ASSET_TYPES.IMAGE
    elseif extension == "mp3" or extension == "wav" or extension == "ogg" then
        return ASSET_TYPES.SOUND
    elseif extension == "fbx" then
        return ASSET_TYPES.ANIMATION
    elseif extension == "mesh" then
        return ASSET_TYPES.MESH
    else
        return ASSET_TYPES.UNKNOWN
    end
end

-- Constants export
AssetValidator.ASSET_TYPES = ASSET_TYPES

-- Initialize the module
AssetValidator.initialize()

-- Register with ClientRegistry if available
if isClient then
    local ClientRegistry = safeRequire(findModule("ClientRegistry"))
    if ClientRegistry and ClientRegistry.registerSystem then
        ClientRegistry.registerSystem("AssetValidator", AssetValidator)
        print("AssetValidator: Registered with ClientRegistry")
    end
end

-- Register with CoreRegistry if available
if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("AssetValidator", AssetValidator)
        print("AssetValidator: Registered with CoreRegistry")
    end
end

return AssetValidator
