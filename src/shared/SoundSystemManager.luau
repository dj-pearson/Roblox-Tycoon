--[[
    SoundSystemManager.luau
    
    A robust sound system manager that handles sound loading, validation, and fallback
    mechanisms to address asset loading failures. This module adds validation and 
    fallbacks for sound assets.
    
    Created: April 27, 2025
]]

-- Services
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    SOUND_VALIDATION_ENABLED = true,
    USE_FALLBACKS = true,
    ASSET_PRELOADING = true,
    CACHE_SOUNDS = true,
    MAX_PRELOAD_BATCH_SIZE = 10
}

-- Constants
local SOUND_CATEGORIES = {
    UI = "UI",
    GAMEPLAY = "Gameplay",
    AMBIENT = "Ambient",
    MUSIC = "Music",
    VOICE = "Voice"
}

-- Store of valid and invalid asset IDs
local validatedSounds = {}
local invalidSounds = {}

-- Cache of preloaded sounds
local soundCache = {}

-- Store of fallback sounds by category
local fallbackSounds = {
    [SOUND_CATEGORIES.UI] = "rbxassetid://12222253", -- A valid simple UI sound
    [SOUND_CATEGORIES.GAMEPLAY] = "rbxassetid://9125601194", -- A valid gameplay sound 
    [SOUND_CATEGORIES.AMBIENT] = "rbxassetid://169736440", -- A valid ambient sound
    [SOUND_CATEGORIES.MUSIC] = "rbxassetid://17245419579", -- A valid music track
    [SOUND_CATEGORIES.VOICE] = "rbxassetid://5047375056"  -- A valid voice clip
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[SoundSystemManager] " .. message)
    end
end

-- Sound System Manager
local SoundSystemManager = {}

-- Initialize the system
function SoundSystemManager:Initialize()
    log("Initializing Sound System Manager")
    
    -- Create a sound group for better organization
    self.MainSoundGroup = SoundService:FindFirstChild("GameSounds")
    if not self.MainSoundGroup then
        self.MainSoundGroup = Instance.new("SoundGroup")
        self.MainSoundGroup.Name = "GameSounds"
        self.MainSoundGroup.Parent = SoundService
    end
    
    -- Create subgroups for different sound categories
    self.SoundGroups = {}
    
    for category, _ in pairs(SOUND_CATEGORIES) do
        local group = self.MainSoundGroup:FindFirstChild(category)
        if not group then
            group = Instance.new("SoundGroup")
            group.Name = category
            group.Parent = self.MainSoundGroup
        end
        
        self.SoundGroups[category] = group
    end
    
    -- Create or get PlaySoundEvent
    self.PlaySoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
    if not self.PlaySoundEvent then
        log("Creating PlaySoundEvent RemoteEvent")
        self.PlaySoundEvent = Instance.new("RemoteEvent")
        self.PlaySoundEvent.Name = "PlaySoundEvent"
        self.PlaySoundEvent.Parent = ReplicatedStorage
    end
    
    -- Set up event handlers
    self:SetupEventHandlers()
    
    -- Preload common sounds
    if CONFIG.ASSET_PRELOADING then
        self:PreloadCommonSounds()
    end
    
    log("Sound System Manager initialized successfully")
    return true
end

-- Set up event handlers
function SoundSystemManager:SetupEventHandlers()
    -- Server-side event handler for PlaySoundEvent
    if RunService:IsServer() then
        self.PlaySoundEvent.OnServerEvent:Connect(function(player, soundId, properties)
            -- Validate the request from the client
            if not player or not soundId then return end
            
            -- Play the sound for all clients
            self:PlaySoundForAll(soundId, properties)
        end)
        
        log("Server-side sound event handlers set up")
    end
    
    -- Client-side event handler for PlaySoundEvent
    if RunService:IsClient() then
        self.PlaySoundEvent.OnClientEvent:Connect(function(soundId, properties)
            if not soundId then return end
            
            -- Play on client
            self:PlaySound(soundId, properties)
        end)
        
        log("Client-side sound event handlers set up")
    end
end

-- Check if a sound asset is valid
function SoundSystemManager:ValidateSoundAsset(soundId)
    -- Remove "rbxassetid://" prefix if present
    local assetId = string.gsub(soundId, "rbxassetid://", "")
    
    -- Check if we've already validated this sound
    if validatedSounds[assetId] then
        return true
    elseif invalidSounds[assetId] then
        return false
    end
    
    -- Try to validate by creating a temporary sound
    local success = pcall(function()
        local tempSound = Instance.new("Sound")
        tempSound.SoundId = "rbxassetid://" .. assetId
        
        -- Try to preload it
        local preloadSuccess = false
        
        -- Use ContentProvider to check if asset loads properly
        ContentProvider:PreloadAsync({tempSound}, function(assetPath, status)
            if status == Enum.AssetFetchStatus.Success then
                preloadSuccess = true
            end
        end)
        
        -- Wait a bit for preload
        local timeout = 1
        local start = os.clock()
        while os.clock() - start < timeout do
            if preloadSuccess then break end
            task.wait(0.1)
        end
        
        -- Clean up temporary sound
        tempSound:Destroy()
        
        -- Record result
        if preloadSuccess then
            validatedSounds[assetId] = true
        else
            invalidSounds[assetId] = true
        end
        
        return preloadSuccess
    end)
    
    if not success then
        invalidSounds[assetId] = true
        return false
    end
    
    return validatedSounds[assetId] or false
end

-- Preload common sounds to speed up first play
function SoundSystemManager:PreloadCommonSounds()
    local soundsToPreload = {
        -- UI Sounds
        {id = "rbxassetid://6518811702", category = SOUND_CATEGORIES.UI}, -- Click
        {id = "rbxassetid://6518727952", category = SOUND_CATEGORIES.UI}, -- Hover
        
        -- Gameplay Sounds
        {id = "rbxassetid://17245419579", category = SOUND_CATEGORIES.GAMEPLAY}, -- Purchase
        {id = "rbxassetid://9125601194", category = SOUND_CATEGORIES.GAMEPLAY}, -- Level up
        
        -- Add your commonly used sounds here
    }
    
    log("Preloading " .. #soundsToPreload .. " common sounds")
    
    -- Split into smaller batches to avoid overloading
    for i = 1, #soundsToPreload, CONFIG.MAX_PRELOAD_BATCH_SIZE do
        local batch = {}
        for j = i, math.min(i + CONFIG.MAX_PRELOAD_BATCH_SIZE - 1, #soundsToPreload) do
            local soundData = soundsToPreload[j]
            
            -- Create temporary Sound instance
            local sound = Instance.new("Sound")
            sound.SoundId = soundData.id
            
            -- Add to cache if enabled
            if CONFIG.CACHE_SOUNDS then
                -- Create a clean ID key
                local idKey = string.gsub(soundData.id, "rbxassetid://", "")
                
                -- Store in cache
                if not soundCache[idKey] then
                    sound.Name = "CachedSound_" .. idKey
                    sound.Parent = self.SoundGroups[soundData.category] or self.MainSoundGroup
                    soundCache[idKey] = sound
                    table.insert(batch, sound)
                    
                    log("Cached sound: " .. soundData.id)
                end
            else
                table.insert(batch, sound)
            end
        end
        
        -- Preload the batch
        ContentProvider:PreloadAsync(batch, function(assetPath, status)
            if status == Enum.AssetFetchStatus.Success then
                log("Preloaded sound: " .. assetPath)
                
                -- Mark as validated
                local assetId = string.match(assetPath, "%d+")
                if assetId then
                    validatedSounds[assetId] = true
                end
            else
                warn("Failed to preload sound: " .. assetPath)
                
                -- Mark as invalid
                local assetId = string.match(assetPath, "%d+")
                if assetId then
                    invalidSounds[assetId] = true
                end
                
                -- Clean up from cache
                if assetId and soundCache[assetId] then
                    soundCache[assetId]:Destroy()
                    soundCache[assetId] = nil
                end
            end
        end)
        
        -- Short pause between batches
        task.wait(0.5)
    end
    
    log("Finished preloading common sounds")
end

-- Get a sound from the cache or create a new one
function SoundSystemManager:GetSound(soundId, category)
    category = category or SOUND_CATEGORIES.GAMEPLAY
    
    -- Remove "rbxassetid://" prefix if present
    local assetId = string.gsub(soundId, "rbxassetid://", "")
    
    -- Check if validation is required
    if CONFIG.SOUND_VALIDATION_ENABLED then
        local isValid = self:ValidateSoundAsset(assetId)
        
        if not isValid then
            warn("Invalid sound asset: " .. soundId .. ", using fallback")
            
            -- Use fallback if enabled
            if CONFIG.USE_FALLBACKS then
                return self:GetSound(fallbackSounds[category], category)
            else
                return nil
            end
        end
    end
    
    -- Try to get from cache first
    if CONFIG.CACHE_SOUNDS and soundCache[assetId] then
        -- Clone the cached sound
        local cachedSound = soundCache[assetId]:Clone()
        return cachedSound
    end
    
    -- Create new Sound instance
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. assetId
    sound.Name = "Sound_" .. assetId
    
    -- Set sound group
    sound.SoundGroup = self.SoundGroups[category] or self.MainSoundGroup
    
    return sound
}

-- Play a sound locally
function SoundSystemManager:PlaySound(soundId, properties)
    properties = properties or {}
    
    -- Create or get the sound
    local sound = self:GetSound(soundId, properties.Category)
    if not sound then return nil end
    
    -- Apply properties
    for property, value in pairs(properties) do
        if property ~= "Parent" and property ~= "Category" and sound[property] ~= nil then
            sound[property] = value
        end
    end
    
    -- Set parent
    sound.Parent = properties.Parent or workspace
    
    -- Play the sound
    sound:Play()
    
    -- Auto-cleanup when done if not looped
    if not sound.Looped then
        local soundLength = sound.TimeLength
        if soundLength > 0 then
            task.delay(soundLength + 1, function()
                if sound and sound.Parent then
                    sound:Destroy()
                end
            end)
        else
            -- Fallback for sounds with unknown length
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
        end
    end
    
    return sound
end

-- Play a sound for all players (server-side)
function SoundSystemManager:PlaySoundForAll(soundId, properties)
    if RunService:IsServer() then
        self.PlaySoundEvent:FireAllClients(soundId, properties)
    end
}

-- Play a sound for a specific player (server-side)
function SoundSystemManager:PlaySoundForPlayer(player, soundId, properties)
    if not player or not RunService:IsServer() then return end
    
    self.PlaySoundEvent:FireClient(player, soundId, properties)
}

-- Update the volume for a sound category
function SoundSystemManager:SetCategoryVolume(category, volume)
    if not self.SoundGroups[category] then
        warn("Unknown sound category: " .. category)
        return false
    end
    
    self.SoundGroups[category].Volume = math.clamp(volume, 0, 1)
    return true
}

-- Get a fallback sound for a category
function SoundSystemManager:GetFallbackSound(category)
    category = category or SOUND_CATEGORIES.GAMEPLAY
    return fallbackSounds[category]
}

-- Register a custom fallback sound
function SoundSystemManager:RegisterFallbackSound(category, soundId)
    if not SOUND_CATEGORIES[category] then
        warn("Unknown sound category: " .. category)
        return false
    end
    
    -- Validate the sound first
    local isValid = self:ValidateSoundAsset(soundId)
    if isValid then
        fallbackSounds[category] = soundId
        log("Registered new fallback sound for " .. category .. ": " .. soundId)
        return true
    else
        warn("Cannot register invalid sound as fallback: " .. soundId)
        return false
    end
}

-- Initialize the system automatically
SoundSystemManager:Initialize()

return SoundSystemManager
