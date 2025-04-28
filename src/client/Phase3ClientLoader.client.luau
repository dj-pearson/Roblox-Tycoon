--[[
    Phase3ClientLoader.client.luau
    
    Client-side initialization for Phase 3 fixes addressing:
    1. Asset loading failures
    2. Sound playback issues
    
    This script ensures that client-side components of Phase 3 fixes are 
    properly loaded and initialized.
    
    Created: April 27, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    AUTO_INITIALIZE = true,
    INITIALIZATION_DELAY = 2, -- seconds to wait before initializing
    PRELOAD_SOUNDS = true
}

-- Local player
local player = Players.LocalPlayer

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[Phase3ClientLoader] " .. message)
    end
end

-- The Phase 3 client loader module
local Phase3ClientLoader = {}

-- Check if module exists without yielding
local function safeRequire(moduleParent, moduleName, timeout)
    timeout = timeout or 5 -- 5 seconds default timeout
    
    if not moduleParent then return nil end
    
    -- Check if module exists immediately
    if moduleParent:FindFirstChild(moduleName) then
        local success, result = pcall(function()
            return require(moduleParent[moduleName])
        end)
        
        if success then
            return result
        end
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    local module
    
    while os.clock() - startTime < timeout do
        module = moduleParent:FindFirstChild(moduleName)
        if module then
            local success, result = pcall(function()
                return require(module)
            end)
            
            if success then
                return result
            end
            
            -- If require failed, no point waiting more
            return nil
        end
        
        task.wait(0.1)
    end
    
    return nil
end

-- Ensure we have shared folder
local function ensureSharedFolder()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
        log("Created missing shared folder")
    end
    
    return shared
end

-- Initialize sound system fixes
function Phase3ClientLoader:InitializeSoundSystem()
    log("Initializing sound system fixes...")
    
    -- Ensure we have shared folder
    local shared = ensureSharedFolder()
    
    -- Try to load sound system modules
    local soundSystem = safeRequire(shared, "SoundSystemManager")
    local soundValidator = safeRequire(shared, "SoundAssetValidator")
    
    if not soundSystem then
        log("SoundSystemManager not found or failed to load")
    else
        log("SoundSystemManager loaded successfully")
    end
    
    if not soundValidator then
        log("SoundAssetValidator not found or failed to load")
    else
        log("SoundAssetValidator loaded successfully")
    end
    
    -- Ensure PlaySoundEvent exists
    local playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
    if not playSoundEvent then
        log("PlaySoundEvent missing! Creating a local fallback...")
        
        -- Create a local bindable instead
        local localEvent = Instance.new("BindableEvent")
        localEvent.Name = "LocalPlaySoundEvent"
        localEvent.Parent = player:FindFirstChild("PlayerGui") or player
        
        log("Created local sound event fallback")
    else
        log("PlaySoundEvent found")
    end
    
    -- Try to load the enhanced sound client
    local soundClient = safeRequire(player:FindFirstChild("PlayerScripts"), "SoundClient.client")
    
    if not soundClient then
        log("SoundClient.client not found or failed to load")
    else
        log("SoundClient.client loaded successfully")
    end
    
    -- Preload common sounds if sound validator is available
    if soundValidator and CONFIG.PRELOAD_SOUNDS then
        task.spawn(function()
            log("Preloading common sounds...")
            soundValidator.createSoundRegistry()
        end)
    end
    
    log("Sound system initialization complete")
    return soundSystem ~= nil or soundValidator ~= nil or soundClient ~= nil
end

-- Initialize all client-side fixes
function Phase3ClientLoader:Initialize()
    -- Add a small delay to allow other systems to load first
    task.wait(CONFIG.INITIALIZATION_DELAY)
    
    log("Initializing Phase 3 client fixes...")
    
    local soundSystemResult = self:InitializeSoundSystem()
    
    log("Phase 3 client initialization complete:")
    log("- Sound System: " .. (soundSystemResult and "SUCCESS" or "FAILED"))
    
    return soundSystemResult
end

-- Auto-initialize if enabled
if CONFIG.AUTO_INITIALIZE then
    task.spawn(function()
        Phase3ClientLoader:Initialize()
    end)
end

return Phase3ClientLoader
