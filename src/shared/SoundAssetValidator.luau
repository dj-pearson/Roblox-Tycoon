--!strict
-- SoundAssetValidator.luau
-- Specialized validator for sound assets with preloading and fallback mechanisms
-- Created on April 29, 2025 to fix sound asset loading failures

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to get AssetValidator for common functionality
local AssetValidator = nil
local function tryGetAssetValidator()
    local success, result = pcall(function()
        local paths = {
            ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"),
            ReplicatedStorage:FindFirstChild("shared"),
            script.Parent
        }
        
        for _, path in ipairs(paths) do
            if path and path:FindFirstChild("AssetValidator") then
                return require(path:FindFirstChild("AssetValidator"))
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Default sound assets to use as fallbacks
local DEFAULT_SOUNDS = {
    ["ambient"] = "rbxassetid://9113028916", -- Soft ambient sound
    ["ui"] = "rbxassetid://6026984224", -- UI click
    ["success"] = "rbxassetid://6895079853", -- Success notification
    ["error"] = "rbxassetid://6895079094", -- Error notification
    ["purchase"] = "rbxassetid://6289084960", -- Purchase sound
    ["achievement"] = "rbxassetid://6895079853", -- Achievement unlock
    ["background"] = "rbxassetid://1843475671", -- Background music
    ["default"] = "rbxassetid://6026984224" -- Default empty sound
}

-- Sound asset cache to avoid repeated validation
local validatedSounds = {}
local preloadedSounds = {}

-- Stats tracking
local stats = {
    totalChecks = 0,
    validSounds = 0,
    invalidSounds = 0,
    fallbacksUsed = 0,
    preloadAttempts = 0,
    successfulPreloads = 0
}

-- Forward declaration
local SoundAssetValidator = {}

-- Initialize the module by searching for AssetValidator
AssetValidator = tryGetAssetValidator()
if AssetValidator then
    print("[SoundAssetValidator] Found AssetValidator module")
else
    print("[SoundAssetValidator] AssetValidator module not found, using standalone functionality")
end

-- Helper function to validate a sound asset ID format
local function isValidSoundAssetFormat(assetId)
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

-- Test if a sound can be successfully loaded
local function testSoundLoad(assetId)
    -- If we've already validated this sound, return the cached result
    if validatedSounds[assetId] ~= nil then
        return validatedSounds[assetId]
    end
    
    -- Create a temporary Sound object for testing
    local testSound = Instance.new("Sound")
    testSound.SoundId = assetId
    testSound.Volume = 0 -- Ensure it's silent for testing
    
    -- Try to preload the sound
    local success = pcall(function()
        ContentProvider:PreloadAsync({testSound})
    end)
    
    -- Clean up the test sound
    testSound:Destroy()
    
    -- Cache and return the result
    validatedSounds[assetId] = success
    return success
end

-- Validate a sound asset
function SoundAssetValidator.validateSound(assetId, category)
    stats.totalChecks += 1
    
    -- Safety checks
    if not assetId or assetId == "" then
        stats.invalidSounds += 1
        stats.fallbacksUsed += 1
        return false, DEFAULT_SOUNDS[category or "default"] or DEFAULT_SOUNDS.default
    end
    
    -- Check format
    if not isValidSoundAssetFormat(assetId) then
        stats.invalidSounds += 1
        stats.fallbacksUsed += 1
        return false, DEFAULT_SOUNDS[category or "default"] or DEFAULT_SOUNDS.default
    end
    
    -- Test loading the sound
    local isValid = testSoundLoad(assetId)
    
    if isValid then
        stats.validSounds += 1
        return true, assetId
    else
        stats.invalidSounds += 1
        stats.fallbacksUsed += 1
        print(string.format("[SoundAssetValidator] Invalid sound asset: %s, using %s fallback", 
            assetId, category or "default"))
        return false, DEFAULT_SOUNDS[category or "default"] or DEFAULT_SOUNDS.default
    end
end

-- Preload a sound asset
function SoundAssetValidator.preloadSound(assetId, category)
    stats.preloadAttempts += 1
    
    -- Validate first
    local isValid, validatedId = SoundAssetValidator.validateSound(assetId, category)
    
    -- Don't try to preload if invalid
    if not isValid then
        return false
    end
    
    -- Skip if already preloaded
    if preloadedSounds[validatedId] then
        return true
    end
    
    -- Create a sound instance for preloading
    local sound = Instance.new("Sound")
    sound.SoundId = validatedId
    
    -- Try to preload
    local success = pcall(function()
        ContentProvider:PreloadAsync({sound})
    end)
    
    sound:Destroy()
    
    -- Update cache and stats
    if success then
        preloadedSounds[validatedId] = true
        stats.successfulPreloads += 1
    end
    
    return success
end

-- Batch validate multiple sounds
function SoundAssetValidator.validateSoundBatch(soundsTable)
    local results = {}
    local validCount = 0
    local totalCount = 0
    
    for key, info in pairs(soundsTable) do
        totalCount += 1
        
        -- Handle different input formats
        local assetId, category
        
        if typeof(info) == "string" then
            assetId = info
            category = "default"
        elseif typeof(info) == "table" then
            assetId = info.id or info.assetId or info.soundId
            category = info.category or info.type or "default"
        end
        
        -- Validate
        local isValid, validatedId = SoundAssetValidator.validateSound(assetId, category)
        results[key] = {
            valid = isValid,
            id = validatedId,
            originalId = assetId,
            category = category
        }
        
        if isValid then
            validCount += 1
        end
    end
    
    return results, validCount, totalCount
end

-- Create a Sound instance with proper validation
function SoundAssetValidator.createSound(assetId, category, properties)
    -- Validate the sound asset
    local isValid, validatedId = SoundAssetValidator.validateSound(assetId, category)
    
    -- Create the sound instance
    local sound = Instance.new("Sound")
    sound.SoundId = validatedId
    
    -- Apply any additional properties
    if properties and typeof(properties) == "table" then
        for propName, propValue in pairs(properties) do
            if propName ~= "SoundId" then -- Skip SoundId as we've already set it
                pcall(function()
                    sound[propName] = propValue
                end)
            end
        end
    end
    
    return sound, isValid
end

-- Fix specific known problematic sound assets
function SoundAssetValidator.fixKnownProblemSounds()
    -- Replace known problematic sound assets with working alternatives
    local knownBadSounds = {
        ["rbxassetid://9048378264"] = "rbxassetid://9113028916", -- Replace with working alternative
        ["rbxassetid://9125601193"] = "rbxassetid://6289084960"  -- Replace with working alternative
    }
    
    local fixCount = 0
    
    -- Log the fixes
    for badId, goodId in pairs(knownBadSounds) do
        print(string.format("[SoundAssetValidator] Registered fix for problematic sound: %s -> %s", badId, goodId))
        validatedSounds[badId] = false
        fixCount += 1
    end
    
    return knownBadSounds, fixCount
end

-- Get a fallback sound for a specific category
function SoundAssetValidator.getFallbackSound(category)
    return DEFAULT_SOUNDS[category or "default"] or DEFAULT_SOUNDS.default
end

-- Get stats about sound validation
function SoundAssetValidator.getStats()
    return {
        totalChecks = stats.totalChecks,
        validSounds = stats.validSounds,
        invalidSounds = stats.invalidSounds,
        fallbacksUsed = stats.fallbacksUsed,
        preloadAttempts = stats.preloadAttempts,
        successfulPreloads = stats.successfulPreloads,
        cacheSize = #validatedSounds,
        preloadedSize = #preloadedSounds,
        passRate = stats.totalChecks > 0 and (stats.validSounds / stats.totalChecks * 100) or 0
    }
end

-- Initialize with default sounds
local function init()
    -- Prevalidate default sounds
    print("[SoundAssetValidator] Validating default sounds")
    local validDefaultCount = 0
    
    for category, soundId in pairs(DEFAULT_SOUNDS) do
        local isValid = testSoundLoad(soundId)
        if isValid then
            validDefaultCount += 1
        else
            warn(string.format("[SoundAssetValidator] Default sound for %s category is invalid: %s", 
                category, soundId))
            
            -- Attempt to find a working fallback
            if category ~= "default" then
                DEFAULT_SOUNDS[category] = DEFAULT_SOUNDS.default
            end
        end
    end
    
    print(string.format("[SoundAssetValidator] Validated %d/%d default sounds", 
        validDefaultCount, #DEFAULT_SOUNDS))
    
    -- Fix known problem sounds
    SoundAssetValidator.fixKnownProblemSounds()
end

-- Run initialization
init()

return SoundAssetValidator
