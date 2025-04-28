--[[
    SoundSystemManager.luau
    
    This module handles sound management in the game, including playback, validation, and 
    mechanisms to address asset loading failures. This module adds validation and 
    fallback mechanisms for all sound assets used in the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local isServer = RunService:IsServer()

-- Find a module
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    if isServer then
        local ServerScriptService = game:GetService("ServerScriptService")
        table.insert(searchPaths, 1, ServerScriptService:FindFirstChild("Core"))
        table.insert(searchPaths, 2, ServerScriptService)
    else
        local player = game:GetService("Players").LocalPlayer
        if player then
            local playerScripts = player:FindFirstChild("PlayerScripts")
            if playerScripts then
                table.insert(searchPaths, 1, playerScripts:FindFirstChild("Client"))
                table.insert(searchPaths, 2, playerScripts)
            end
        end
    end
    
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

-- Safe require function
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("SoundSystemManager: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Try to load dependencies
local SoundAssetValidatorModule = findModule("SoundAssetValidator")
local SoundAssetValidator = safeRequire(SoundAssetValidatorModule)

local EventBridgeModule = findModule("EventBridge")
local EventBridge = safeRequire(EventBridgeModule)

-- Register events if EventBridge is available
if EventBridge and EventBridge.registerEvent then
    EventBridge.registerEvent("SoundSystem_SoundPlayed")
    EventBridge.registerEvent("SoundSystem_SoundFailed")
    EventBridge.registerEvent("SoundSystem_VolumeChanged")
end

-- Create the module
local SoundSystemManager = {}

-- Version information
SoundSystemManager.VERSION = "1.0.0"

-- Sound configuration
local soundConfig = {
    masterVolume = 1,
    sfxVolume = 1,
    musicVolume = 0.5,
    uiVolume = 0.8,
    soundEnabled = true,
    musicEnabled = true,
    sfxEnabled = true,
    uiEnabled = true
}

-- Sound categories
local soundCategories = {
    sfx = SoundService:FindFirstChild("SFX") or Instance.new("SoundGroup", SoundService),
    music = SoundService:FindFirstChild("Music") or Instance.new("SoundGroup", SoundService),
    ui = SoundService:FindFirstChild("UI") or Instance.new("SoundGroup", SoundService),
    ambient = SoundService:FindFirstChild("Ambient") or Instance.new("SoundGroup", SoundService)
}

-- Ensure sound groups are named correctly
soundCategories.sfx.Name = "SFX"
soundCategories.music.Name = "Music"
soundCategories.ui.Name = "UI"
soundCategories.ambient.Name = "Ambient"

-- Sound asset registry 
local soundAssets = {
    -- UI Sounds
    ui = {
        click = 4612338705,
        hover = 4612347302,
        success = 4612339685,
        error = 4612361922
    },
    -- Game Sounds
    game = {
        purchase = 4612385339,
        achievement = 4612394965,
        levelUp = 4612383033
    },
    -- Music
    music = {
        menu = 4612416484,
        gameplay = 4612421162
    },
    -- Ambient
    ambient = {
        gym = 4612426648
    }
}

-- Sound cache for commonly used sounds
local soundCache = {}

-- Error tracking
local errorCount = 0
local lastError = ""

-- Sound IDs that are known to be problematic
local knownProblematicIds = {
    [9048378264] = true,  -- Mentioned in RobloxIssues.txt
    [9125601193] = true   -- Mentioned in RobloxIssues.txt
}

-- Initialize sound groups
local function initializeSoundGroups()
    -- Set initial volumes
    soundCategories.sfx.Volume = soundConfig.sfxVolume
    soundCategories.music.Volume = soundConfig.musicVolume
    soundCategories.ui.Volume = soundConfig.uiVolume
    soundCategories.ambient.Volume = soundConfig.masterVolume
end

-- Initialize the SoundSystemManager
function SoundSystemManager.initialize()
    initializeSoundGroups()
    
    -- Check for SoundAssetValidator
    if not SoundAssetValidator then
        warn("SoundSystemManager: SoundAssetValidator not found, sound validation disabled")
    else
        print("SoundSystemManager: SoundAssetValidator loaded successfully")
        
        -- Register fallback sounds
        for category, sounds in pairs(soundAssets) do
            for name, id in pairs(sounds) do
                SoundAssetValidator.registerFallback(category, name, id)
            end
        end
    end
    
    -- Report success
    print("✅ SoundSystemManager initialized successfully")
    return true
end

-- Create a sound with validation
function SoundSystemManager.createSound(soundId, properties)
    properties = properties or {}
    
    local category = properties.category or "sfx"
    local soundGroup = soundCategories[category] or soundCategories.sfx
    
    -- Create properties for the sound
    local soundProperties = {
        Volume = properties.Volume or 1,
        PlaybackSpeed = properties.PlaybackSpeed or 1,
        Looped = properties.Looped or false
    }
    
    -- Create sound with validation if available
    local sound
    if SoundAssetValidator then
        sound = SoundAssetValidator.createValidatedSound(soundId, soundProperties)
    else
        sound = Instance.new("Sound")
        sound.SoundId = typeof(soundId) == "number" and "rbxassetid://" .. soundId or soundId
        
        -- Apply properties
        for prop, value in pairs(soundProperties) do
            sound[prop] = value
        end
    end
    
    -- Set sound group
    sound.SoundGroup = soundGroup
    
    -- Set parent
    if properties.Parent then
        sound.Parent = properties.Parent
    else
        sound.Parent = SoundService
    end
    
    return sound
end

-- Play a sound once
function SoundSystemManager.playSound(soundId, properties)
    -- Check if sound is enabled for this category
    local category = properties and properties.category or "sfx"
    local enabled = true
    
    if category == "sfx" and not soundConfig.sfxEnabled then
        enabled = false
    elseif category == "music" and not soundConfig.musicEnabled then
        enabled = false
    elseif category == "ui" and not soundConfig.uiEnabled then
        enabled = false
    end
    
    -- If category is disabled, don't play
    if not enabled or not soundConfig.soundEnabled then
        return nil
    end
    
    -- Check for known problematic IDs
    if knownProblematicIds[soundId] then
        -- Replace with a known good fallback
        local fallbacks = {
            sfx = 4612338705,
            music = 4612416484,
            ui = 4612347302,
            ambient = 4612426648
        }
        
        soundId = fallbacks[category] or 4612338705
        
        -- Log the replacement
        warn("SoundSystemManager: Replaced known problematic sound ID with fallback")
        errorCount += 1
    end
    
    -- Try to create and play the sound
    local success, result = pcall(function()
        local sound = SoundSystemManager.createSound(soundId, properties)
        sound:Play()
        
        -- Auto cleanup for non-looped sounds
        if not sound.Looped then
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
        end
        
        return sound
    end)
    
    if success then
        -- Fire event
        if EventBridge and EventBridge.fireEvent then
            EventBridge.fireEvent("SoundSystem_SoundPlayed", {
                soundId = soundId,
                category = category
            })
        end
        
        return result
    else
        errorCount += 1
        lastError = tostring(result)
        
        -- Fire event
        if EventBridge and EventBridge.fireEvent then
            EventBridge.fireEvent("SoundSystem_SoundFailed", {
                soundId = soundId,
                error = lastError
            })
        end
        
        warn("SoundSystemManager: Failed to play sound - " .. lastError)
        return nil
    end
end

-- Play UI sound
function SoundSystemManager.playUISound(soundName)
    if not soundAssets.ui[soundName] then
        warn("SoundSystemManager: Unknown UI sound - " .. soundName)
        return nil
    end
    
    return SoundSystemManager.playSound(soundAssets.ui[soundName], {
        category = "ui",
        Volume = 0.8
    })
end

-- Play game sound
function SoundSystemManager.playGameSound(soundName)
    if not soundAssets.game[soundName] then
        warn("SoundSystemManager: Unknown game sound - " .. soundName)
        return nil
    end
    
    return SoundSystemManager.playSound(soundAssets.game[soundName], {
        category = "sfx",
        Volume = 1
    })
end

-- Play music
function SoundSystemManager.playMusic(musicName, fadeIn)
    if not soundAssets.music[musicName] then
        warn("SoundSystemManager: Unknown music - " .. musicName)
        return nil
    end
    
    -- Stop currently playing music
    SoundSystemManager.stopMusic()
    
    -- Create and play new music
    local music = SoundSystemManager.createSound(soundAssets.music[musicName], {
        category = "music",
        Volume = fadeIn and 0 or soundConfig.musicVolume,
        Looped = true
    })
    
    -- Cache the music
    soundCache.currentMusic = music
    
    -- Start playing
    music:Play()
    
    -- Fade in if needed
    if fadeIn then
        local targetVolume = soundConfig.musicVolume
        local duration = typeof(fadeIn) == "number" and fadeIn or 2
        
        -- Fade in over time
        local startTime = os.clock()
        local connection
        
        connection = RunService.Heartbeat:Connect(function()
            local elapsed = os.clock() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            music.Volume = targetVolume * alpha
            
            if alpha >= 1 or not music.Playing then
                connection:Disconnect()
            end
        end)
    end
    
    return music
end

-- Stop music with optional fade out
function SoundSystemManager.stopMusic(fadeOut)
    if not soundCache.currentMusic then
        return
    end
    
    local music = soundCache.currentMusic
    
    -- Fade out if needed
    if fadeOut and music.Playing then
        local startVolume = music.Volume
        local duration = typeof(fadeOut) == "number" and fadeOut or 2
        
        -- Fade out over time
        local startTime = os.clock()
        local connection
        
        connection = RunService.Heartbeat:Connect(function()
            local elapsed = os.clock() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            music.Volume = startVolume * (1 - alpha)
            
            if alpha >= 1 then
                music:Stop()
                music:Destroy()
                soundCache.currentMusic = nil
                connection:Disconnect()
            end
        end)
    else
        -- Stop immediately
        music:Stop()
        music:Destroy()
        soundCache.currentMusic = nil
    end
end

-- Set volume for a category
function SoundSystemManager.setVolume(category, volume)
    volume = math.clamp(volume, 0, 1)
    
    if category == "master" then
        soundConfig.masterVolume = volume
        SoundService.Volume = volume
    elseif soundCategories[category] then
        soundConfig[category .. "Volume"] = volume
        soundCategories[category].Volume = volume
        
        -- Fire event
        if EventBridge and EventBridge.fireEvent then
            EventBridge.fireEvent("SoundSystem_VolumeChanged", {
                category = category,
                volume = volume
            })
        end
    end
end

-- Get volume for a category
function SoundSystemManager.getVolume(category)
    if category == "master" then
        return soundConfig.masterVolume
    elseif soundCategories[category] then
        return soundConfig[category .. "Volume"]
    end
    
    return 0
end

-- Toggle sound for a category
function SoundSystemManager.toggleSound(category, enabled)
    if category == "master" then
        soundConfig.soundEnabled = enabled
        return true
    elseif category == "sfx" then
        soundConfig.sfxEnabled = enabled
        return true
    elseif category == "music" then
        soundConfig.musicEnabled = enabled
        
        -- Stop music if disabled
        if not enabled and soundCache.currentMusic then
            SoundSystemManager.stopMusic()
        end
        
        return true
    elseif category == "ui" then
        soundConfig.uiEnabled = enabled
        return true
    end
    
    return false
end

-- Get sound assets
function SoundSystemManager.getSoundAssets()
    return table.clone(soundAssets)
end

-- Get error statistics
function SoundSystemManager.getErrorStats()
    local validationStats = SoundAssetValidator and SoundAssetValidator.getStats() or {
        totalChecked = 0,
        validSounds = 0,
        invalidSounds = 0,
        replacements = 0,
        successRate = 0
    }
    
    return {
        errorCount = errorCount,
        lastError = lastError,
        validation = validationStats
    }
end

-- Register a custom sound
function SoundSystemManager.registerSound(category, name, soundId)
    if not category or not name then
        return false
    end
    
    -- Create category if it doesn't exist
    if not soundAssets[category] then
        soundAssets[category] = {}
    end
    
    local validId = soundId
    
    -- Validate ID if validator is available
    if SoundAssetValidator then
        validId = SoundAssetValidator.validateSoundId(soundId, category)
    end
    
    soundAssets[category][name] = validId
    return true
end

-- Check the status of the sound system
function SoundSystemManager.getStatus()
    if SoundAssetValidator then
        local stats = SoundAssetValidator.getStats()
        local errorRate = stats.invalidSounds / math.max(stats.totalChecked, 1)
          -- If more than 25% of sounds are invalid, system is in warning state
        if errorRate > 0.25 then
            return "WARNING"
        else
            return "OPERATIONAL"
        end
    end
    
    return errorCount > 0 and "WARNING" or "OPERATIONAL"
}

-- Initialize the sound system
SoundSystemManager.initialize()

-- Register with CoreRegistry if available
local CoreRegistryModule = findModule("CoreRegistry")
local CoreRegistry = safeRequire(CoreRegistryModule)

if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
    CoreRegistry.registerSystem("SoundSystemManager", SoundSystemManager)
    print("SoundSystemManager: Registered with CoreRegistry")
end

return SoundSystemManager
