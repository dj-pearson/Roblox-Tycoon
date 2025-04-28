--[[
    SoundAssetValidator.luau
    
    A utility module for validating, managing, and fixing sound assets.
    Helps address the asset loading failures identified in the RobloxIssues document.
    
    Created: April 27, 2025
]]

-- Services
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    VALIDATION_TIMEOUT = 2, -- seconds per asset
    BATCH_SIZE = 10, -- assets per batch for validation
    CACHE_VALIDATION_RESULTS = true,
    ALLOW_SOUND_REPLACEMENTS = true
}

-- Repository of known working sound IDs by category
local SOUND_REPOSITORY = {
    UI = {
        "rbxassetid://12222253",  -- Click 
        "rbxassetid://134012322", -- UI Toggle
        "rbxassetid://172347967", -- Achievement
    },
    Gameplay = {
        "rbxassetid://9125601194", -- Jump
        "rbxassetid://169486406",  -- Collect
        "rbxassetid://17245419579" -- Coin
    },
    Ambient = {
        "rbxassetid://169380495", -- Wind
        "rbxassetid://169380526", -- Water
        "rbxassetid://169380617"  -- Forest
    },
    Music = {
        "rbxassetid://1848354536", -- Happy music
        "rbxassetid://1842006186", -- Adventure music
        "rbxassetid://1837829571"  -- Calm music
    }
}

-- Cache of validated sound assets
local validatedSounds = {}
local invalidSounds = {}

-- Shared cache folder for storing sound replacements
local CACHE_FOLDER_NAME = "SoundAssetCache"
local soundCacheFolder

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[SoundAssetValidator] " .. message)
    end
end

-- Get or create sound cache folder
local function getSoundCacheFolder()
    if soundCacheFolder then
        return soundCacheFolder
    end
    
    soundCacheFolder = ReplicatedStorage:FindFirstChild(CACHE_FOLDER_NAME)
    if not soundCacheFolder then
        soundCacheFolder = Instance.new("Folder")
        soundCacheFolder.Name = CACHE_FOLDER_NAME
        soundCacheFolder.Parent = ReplicatedStorage
    end
    
    return soundCacheFolder
end

-- Clean asset ID (remove prefixes, etc.)
local function cleanAssetId(assetId)
    if not assetId then return nil end
    
    -- Convert to string if number
    assetId = tostring(assetId)
    
    -- Remove rbxassetid:// prefix if present
    return assetId:gsub("rbxassetid://", "")
end

-- Format asset ID with proper prefix
local function formatAssetId(assetId)
    if not assetId then return nil end
    
    -- Convert to string if number
    assetId = tostring(assetId)
    
    -- Remove existing prefix if any
    assetId = cleanAssetId(assetId)
    
    -- Add prefix
    return "rbxassetid://" .. assetId
end

-- Cache validation result
local function cacheValidationResult(assetId, isValid)
    assetId = cleanAssetId(assetId)
    
    if not CONFIG.CACHE_VALIDATION_RESULTS then
        return
    end
    
    if isValid then
        validatedSounds[assetId] = true
        
        -- Remove from invalid if it was there
        invalidSounds[assetId] = nil
    else
        invalidSounds[assetId] = true
        
        -- Remove from valid if it was there
        validatedSounds[assetId] = nil
    end
end

-- Check if a sound asset is valid
local function validateSoundAsset(assetId)
    assetId = cleanAssetId(assetId)
    
    -- Check cache first
    if validatedSounds[assetId] then
        return true
    elseif invalidSounds[assetId] then
        return false
    end
    
    local isValid = false
    
    -- Try to create and preload the sound
    local sound = Instance.new("Sound")
    sound.SoundId = formatAssetId(assetId)
    
    -- Use content provider to validate
    local preloadSuccess = false
    local startTime = os.clock()
    
    -- Set up a preload handler
    ContentProvider:PreloadAsync({sound}, function(contentId, status)
        if status == Enum.AssetFetchStatus.Success then
            preloadSuccess = true
        end
    end)
    
    -- Wait until preload succeeds or times out
    while os.clock() - startTime < CONFIG.VALIDATION_TIMEOUT and not preloadSuccess do
        task.wait(0.1)
    end
    
    -- Check if sound has a valid length
    if preloadSuccess and sound.TimeLength > 0 then
        isValid = true
    end
    
    -- Clean up
    sound:Destroy()
    
    -- Cache the result
    cacheValidationResult(assetId, isValid)
    
    return isValid
end

-- Validate a batch of sound assets
local function validateSoundBatch(assetIds, callback)
    if not assetIds or #assetIds == 0 then
        if callback then
            callback({})
        end
        return
    end
    
    local results = {}
    local processedCount = 0
    
    -- Process in smaller batches
    for i = 1, #assetIds, CONFIG.BATCH_SIZE do
        local batchEnd = math.min(i + CONFIG.BATCH_SIZE - 1, #assetIds)
        local batch = {}
        
        for j = i, batchEnd do
            table.insert(batch, assetIds[j])
        end
        
        -- Process this mini-batch
        log("Processing batch " .. i .. "-" .. batchEnd .. " of " .. #assetIds .. " assets")
        
        for _, assetId in ipairs(batch) do
            local cleanId = cleanAssetId(assetId)
            results[cleanId] = validateSoundAsset(cleanId)
            processedCount = processedCount + 1
        end
        
        -- Allow a frame to process other things
        task.wait()
    end
    
    log("Validation complete: " .. processedCount .. " sound assets processed")
    
    if callback then
        callback(results)
    end
    
    return results
end

-- Get a replacement for an invalid sound
local function getReplacementSound(category)
    category = category or "Gameplay"
    
    -- Get random sound from the repository
    local categorySounds = SOUND_REPOSITORY[category]
    if not categorySounds or #categorySounds == 0 then
        -- Fall back to gameplay category
        categorySounds = SOUND_REPOSITORY["Gameplay"]
    end
    
    -- Select a random sound from the category
    local randomIndex = math.random(1, #categorySounds)
    return categorySounds[randomIndex]
end

-- Create or get a preloaded sound asset
local function getPreloadedSound(assetId, category)
    assetId = cleanAssetId(assetId)
    
    -- Check if valid
    local isValid = validateSoundAsset(assetId)
    
    -- If not valid and replacements are allowed, get replacement
    if not isValid and CONFIG.ALLOW_SOUND_REPLACEMENTS then
        local replacementId = getReplacementSound(category)
        log("Replacing invalid sound " .. assetId .. " with " .. replacementId)
        assetId = cleanAssetId(replacementId)
    end
    
    -- Try to find in cache
    local cacheFolder = getSoundCacheFolder()
    local cachedSound = cacheFolder:FindFirstChild("Sound_" .. assetId)
    
    if cachedSound then
        return cachedSound:Clone()
    end
    
    -- Create new sound
    local sound = Instance.new("Sound")
    sound.SoundId = formatAssetId(assetId)
    sound.Name = "Sound_" .. assetId
    
    -- Store in cache
    local cachedCopy = sound:Clone()
    cachedCopy.Parent = cacheFolder
    
    return sound
end

-- Create a sound asset registry
local function createSoundRegistry()
    -- Create sounds folder if it doesn't exist
    local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
    if not soundsFolder then
        soundsFolder = Instance.new("Folder")
        soundsFolder.Name = "Sounds"
        soundsFolder.Parent = ReplicatedStorage
    end

    -- Create categories
    for category, sounds in pairs(SOUND_REPOSITORY) do
        local categoryFolder = soundsFolder:FindFirstChild(category)
        if not categoryFolder then
            categoryFolder = Instance.new("Folder")
            categoryFolder.Name = category
            categoryFolder.Parent = soundsFolder
        end
        
        -- Preload each sound in category
        for _, soundId in ipairs(sounds) do
            local cleanId = cleanAssetId(soundId)
            local sound = Instance.new("Sound") 
            sound.SoundId = formatAssetId(cleanId)
            sound.Name = "Sound_" .. cleanId
            sound.Parent = categoryFolder
            
            -- Validate
            validateSoundAsset(cleanId)
        end
        
        log("Created sound registry for category: " .. category)
    end
    
    log("Sound registry created successfully")
    return soundsFolder
end

-- Scan and automatically fix common sound asset issues
local function scanAndFixSoundAssets()
    log("Starting sound asset scan")
    
    -- Look for Sound objects throughout the game
    local soundsToCheck = {}
    
    -- Collect sounds from workspace
    for _, sound in ipairs(game.Workspace:GetDescendants()) do
        if sound:IsA("Sound") and sound.SoundId and sound.SoundId ~= "" then
            table.insert(soundsToCheck, {
                instance = sound,
                id = cleanAssetId(sound.SoundId)
            })
        end
    end
    
    -- Collect sounds from ReplicatedStorage
    for _, sound in ipairs(ReplicatedStorage:GetDescendants()) do
        if sound:IsA("Sound") and sound.SoundId and sound.SoundId ~= "" then
            table.insert(soundsToCheck, {
                instance = sound,
                id = cleanAssetId(sound.SoundId)
            })
        end
    end
    
    log("Found " .. #soundsToCheck .. " sounds to validate")
    
    -- Validate in smaller batches
    local invalidCount = 0
    local fixedCount = 0
    
    for i = 1, #soundsToCheck, CONFIG.BATCH_SIZE do
        local batchEnd = math.min(i + CONFIG.BATCH_SIZE - 1, #soundsToCheck)
        
        for j = i, batchEnd do
            local soundData = soundsToCheck[j]
            
            -- Check if valid
            local isValid = validateSoundAsset(soundData.id)
            
            -- Fix if invalid and replacements are allowed
            if not isValid and CONFIG.ALLOW_SOUND_REPLACEMENTS then
                invalidCount = invalidCount + 1
                
                -- Get category based on instance name or parent
                local category = "Gameplay"
                local instanceName = string.lower(soundData.instance.Name)
                
                if string.find(instanceName, "ui") or string.find(instanceName, "click") or string.find(instanceName, "button") then
                    category = "UI"
                elseif string.find(instanceName, "music") or string.find(instanceName, "theme") then
                    category = "Music"
                elseif string.find(instanceName, "ambient") or string.find(instanceName, "wind") or string.find(instanceName, "environment") then
                    category = "Ambient"
                end
                
                -- Replace with valid sound
                local replacement = getReplacementSound(category)
                soundData.instance.SoundId = replacement
                fixedCount = fixedCount + 1
                
                log("Fixed invalid sound ID " .. soundData.id .. " -> " .. cleanAssetId(replacement) .. " [" .. soundData.instance:GetFullName() .. "]")
            end
        end
        
        -- Wait a bit between batches
        task.wait()
    end
    
    log("Sound asset scan complete. Found " .. invalidCount .. " invalid sounds, fixed " .. fixedCount)
    return fixedCount
end

-- Initialize the module
local function initialize()
    log("Initializing Sound Asset Validator")
    
    -- Create cache folder
    getSoundCacheFolder()
    
    -- Create the sound registry
    createSoundRegistry() 
    
    log("Sound Asset Validator initialized")
end

-- Initialize automatically
task.spawn(initialize)

-- Return API
return {
    validateSoundAsset = validateSoundAsset,
    validateSoundBatch = validateSoundBatch,
    getReplacementSound = getReplacementSound,
    getPreloadedSound = getPreloadedSound,
    createSoundRegistry = createSoundRegistry,
    scanAndFixSoundAssets = scanAndFixSoundAssets,
    cleanAssetId = cleanAssetId,
    formatAssetId = formatAssetId
}
