--!strict
-- SoundSystemManager.luau
-- Manages sound loading, playback, and error handling
-- Created on April 29, 2025 to fix sound asset loading failures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Define the module
local SoundSystemManager = {}

-- Try to get SoundAssetValidator
local SoundAssetValidator = nil
local function getSoundValidator()
    local success, result = pcall(function()
        local paths = {
            ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"),
            ReplicatedStorage:FindFirstChild("shared"),
            script.Parent
        }
        
        for _, path in ipairs(paths) do
            if path and path:FindFirstChild("SoundAssetValidator") then
                return require(path:FindFirstChild("SoundAssetValidator"))
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Sound categories with default volumes
local SOUND_CATEGORIES = {
    ui = {
        volume = 0.5,
        group = "UI",
        parent = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") or nil,
    },
    sfx = {
        volume = 0.7,
        group = "SoundEffects",
        parent = workspace,
    },
    music = {
        volume = 0.3,
        group = "Music",
        parent = workspace,
    },
    ambient = {
        volume = 0.2,
        group = "Ambient",
        parent = workspace,
    },
    voice = {
        volume = 1.0,
        group = "Voice",
        parent = workspace,
    }
}

-- Sound category groups for volume control
local soundGroups = {}

-- Sound registry for tracking and management
local registeredSounds = {}
local activeSounds = {}
local soundQueue = {}

-- Stats tracking
local stats = {
    soundsPlayed = 0,
    soundsFailed = 0,
    queuedSounds = 0,
    fallbacksUsed = 0
}

-- Initialize sound groups
local function initializeSoundGroups()
    -- Create sound groups for each category
    for category, info in pairs(SOUND_CATEGORIES) do
        local groupName = info.group or category
        
        -- Check if group already exists
        local group = SoundService:FindFirstChild(groupName)
        if not group then
            group = Instance.new("SoundGroup")
            group.Name = groupName
            group.Volume = info.volume or 1
            group.Parent = SoundService
        end
        
        soundGroups[category] = group
    end
end

-- Initialize the module
local function initialize()
    print("[SoundSystemManager] Initializing sound system...")
    
    -- Get SoundAssetValidator
    SoundAssetValidator = getSoundValidator()
    if SoundAssetValidator then
        print("[SoundSystemManager] Found SoundAssetValidator module")
    else
        warn("[SoundSystemManager] SoundAssetValidator not found, using basic validation")
    end
    
    -- Create sound groups
    initializeSoundGroups()
    
    print("[SoundSystemManager] Sound system initialized")
    return true
end

-- Register a sound for later use
function SoundSystemManager.registerSound(id, name, category, options)
    category = category or "sfx"
    options = options or {}
    
    local validId = id
    local isValid = true
    
    -- Validate the sound if we have the validator
    if SoundAssetValidator then
        isValid, validId = SoundAssetValidator.validateSound(id, category)
        if not isValid then
            warn(string.format("[SoundSystemManager] Invalid sound asset registered: %s (%s), using fallback", 
                name, id))
            stats.fallbacksUsed += 1
        end
    end
    
    -- Register the sound
    registeredSounds[name] = {
        id = validId,
        category = category,
        volume = options.volume or SOUND_CATEGORIES[category].volume or 1,
        pitch = options.pitch or 1,
        looped = options.looped or false,
        parent = options.parent or SOUND_CATEGORIES[category].parent,
        valid = isValid,
        originalId = id
    }
    
    print(string.format("[SoundSystemManager] Registered sound: %s (%s)", name, validId))
    return isValid
end

-- Register multiple sounds at once
function SoundSystemManager.registerSounds(soundsTable)
    local validCount = 0
    local totalCount = 0
    
    for name, info in pairs(soundsTable) do
        totalCount += 1
        
        local id = info.id or info.soundId or info
        local category = info.category or "sfx"
        local options = (typeof(info) == "table") and info or {}
        
        local success = SoundSystemManager.registerSound(id, name, category, options)
        if success then
            validCount += 1
        end
    end
    
    print(string.format("[SoundSystemManager] Batch registered %d/%d sounds", validCount, totalCount))
    return validCount, totalCount
end

-- Play a registered sound
function SoundSystemManager.playSound(name, options)
    options = options or {}
    local soundInfo = registeredSounds[name]
    
    -- Check if the sound is registered
    if not soundInfo then
        warn(string.format("[SoundSystemManager] Attempted to play unregistered sound: %s", name))
        stats.soundsFailed += 1
        return nil
    end
    
    -- Create the sound instance
    local sound
    local useValidator = SoundAssetValidator ~= nil
    
    if useValidator then
        sound, _ = SoundAssetValidator.createSound(soundInfo.id, soundInfo.category, {
            Volume = options.volume or soundInfo.volume,
            Pitch = options.pitch or soundInfo.pitch,
            Looped = options.looped or soundInfo.looped,
        })
    else
        sound = Instance.new("Sound")
        sound.SoundId = soundInfo.id
        sound.Volume = options.volume or soundInfo.volume
        sound.Pitch = options.pitch or soundInfo.pitch
        sound.Looped = options.looped or soundInfo.looped
    end
    
    -- Set parent and sound group
    sound.Parent = options.parent or soundInfo.parent or workspace
    
    local category = options.category or soundInfo.category
    if soundGroups[category] then
        sound.SoundGroup = soundGroups[category]
    end
    
    -- Add to active sounds
    local soundId = name .. "_" .. tostring(math.random(1, 10000))
    activeSounds[soundId] = sound
    
    -- Connect events
    sound.Ended:Connect(function()
        if activeSounds[soundId] then
            activeSounds[soundId] = nil
        end
    end)
    
    -- Handle errors
    sound.Failed:Connect(function(err)
        warn(string.format("[SoundSystemManager] Sound failed to play: %s (%s)", name, err))
        stats.soundsFailed += 1
        
        if activeSounds[soundId] then
            activeSounds[soundId] = nil
        end
    end)
    
    -- Play the sound
    local success = pcall(function()
        sound:Play()
    end)
    
    if success then
        stats.soundsPlayed += 1
    else
        stats.soundsFailed += 1
        warn(string.format("[SoundSystemManager] Failed to play sound: %s", name))
    end
    
    return sound
end

-- Stop a sound or all sounds in a category
function SoundSystemManager.stopSound(nameOrSound, fadeTime)
    -- If a sound instance is provided
    if typeof(nameOrSound) == "Instance" and nameOrSound:IsA("Sound") then
        if fadeTime and fadeTime > 0 then
            -- Fade out
            local originalVolume = nameOrSound.Volume
            local startTime = os.clock()
            
            local connection
            connection = RunService.Heartbeat:Connect(function()
                local elapsed = os.clock() - startTime
                local ratio = math.clamp(1 - (elapsed / fadeTime), 0, 1)
                
                nameOrSound.Volume = originalVolume * ratio
                
                if ratio <= 0 then
                    nameOrSound:Stop()
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        else
            -- Stop immediately
            nameOrSound:Stop()
        end
        return true
    end
    
    -- If a sound name is provided
    if typeof(nameOrSound) == "string" then
        local soundName = nameOrSound
        
        -- Check if it's a category
        if SOUND_CATEGORIES[soundName] then
            -- Stop all sounds in the category
            local count = 0
            for id, sound in pairs(activeSounds) do
                local soundInfo = registeredSounds[string.split(id, "_")[1]]
                if soundInfo and soundInfo.category == soundName then
                    if fadeTime and fadeTime > 0 then
                        SoundSystemManager.stopSound(sound, fadeTime)
                    else
                        sound:Stop()
                    end
                    count += 1
                end
            end
            return count > 0
        end
        
        -- Find and stop all instances of the named sound
        local found = false
        for id, sound in pairs(activeSounds) do
            if string.find(id, soundName .. "_") == 1 then
                if fadeTime and fadeTime > 0 then
                    SoundSystemManager.stopSound(sound, fadeTime)
                else
                    sound:Stop()
                end
                found = true
            end
        end
        
        return found
    end
    
    return false
end

-- Set volume for a sound category
function SoundSystemManager.setVolumeForCategory(category, volume)
    if soundGroups[category] then
        soundGroups[category].Volume = math.clamp(volume, 0, 1)
        return true
    end
    return false
end

-- Set volume for all sound categories
function SoundSystemManager.setMasterVolume(volume)
    for category, group in pairs(soundGroups) do
        group.Volume = math.clamp(volume, 0, 1)
    end
end

-- Get the list of registered sounds
function SoundSystemManager.getRegisteredSounds()
    return registeredSounds
end

-- Preload a batch of sounds
function SoundSystemManager.preloadSounds(soundNames)
    local success = false
    local count = 0
    
    if SoundAssetValidator then
        local sounds = {}
        
        -- Collect sounds to preload
        for _, name in ipairs(soundNames) do
            local soundInfo = registeredSounds[name]
            if soundInfo then
                sounds[name] = {
                    id = soundInfo.id,
                    category = soundInfo.category
                }
                count += 1
            end
        end
        
        -- Batch preload
        if count > 0 then
            for name, info in pairs(sounds) do
                SoundAssetValidator.preloadSound(info.id, info.category)
            end
            success = true
        end
    else
        warn("[SoundSystemManager] SoundAssetValidator not available for preloading")
    end
    
    return success, count
end

-- Get stats about sound playback
function SoundSystemManager.getStats()
    local validatorStats = SoundAssetValidator and SoundAssetValidator.getStats() or {}
    
    return {
        soundsPlayed = stats.soundsPlayed,
        soundsFailed = stats.soundsFailed,
        queuedSounds = stats.queuedSounds,
        fallbacksUsed = stats.fallbacksUsed,
        activeSounds = #activeSounds,
        registeredSounds = #registeredSounds,
        validator = validatorStats
    }
end

-- Register the problematic sounds with fixed alternatives
function SoundSystemManager.registerProblemSoundFixes()
    -- Register fixed alternatives for the problematic sounds mentioned in the error report
    SoundSystemManager.registerSound("rbxassetid://9113028916", "ambient_fixed", "ambient", { volume = 0.3, looped = true })
    SoundSystemManager.registerSound("rbxassetid://6289084960", "purchase_fixed", "ui", { volume = 0.5 })
    
    -- Replace the problematic sound IDs with working alternatives
    local fixedSounds = {
        ["rbxassetid://9048378264"] = "rbxassetid://9113028916",
        ["rbxassetid://9125601193"] = "rbxassetid://6289084960"
    }
    
    print("[SoundSystemManager] Registered fixes for problematic sounds")
    
    return fixedSounds
end

-- Initialize the module
initialize()

return SoundSystemManager
