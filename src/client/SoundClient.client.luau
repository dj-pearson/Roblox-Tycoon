--[[
    SoundClient.client.luau
    
    Client-side script that manages sound playback using the SoundSystemManager.
    Handles PlaySoundEvent safely, with fallbacks for when the event is not available.
    
    Created: April 27, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get local player
local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    EVENT_TIMEOUT = 5, -- seconds to wait for PlaySoundEvent
    USE_LOCAL_FALLBACK = true -- whether to create a local fallback when event not found
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[SoundClient] " .. message)
    end
end

-- Main functionality
local SoundClient = {
    initialized = false,
    playSoundEvent = nil,
    soundSystemManager = nil
}

-- Initialize the sound client system
function SoundClient:Initialize()
    log("Initializing sound client system")
    
    -- Try to load SoundSystemManager
    local success, soundManager = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SoundSystemManager"))
    end)
    
    if success and soundManager then
        self.soundSystemManager = soundManager
        log("Successfully loaded SoundSystemManager")
    else
        warn("[SoundClient] Failed to load SoundSystemManager, using fallback")
    end
    
    -- Try to get PlaySoundEvent with timeout
    local startTime = os.clock()
    
    -- Try to find the event immediately first
    self.playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
    
    -- If not found, wait with timeout
    if not self.playSoundEvent then
        log("PlaySoundEvent not found immediately, waiting...")
        
        -- Start a loop to wait with timeout
        while os.clock() - startTime < CONFIG.EVENT_TIMEOUT do
            self.playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
            if self.playSoundEvent then
                log("Found PlaySoundEvent after waiting")
                break
            end
            task.wait(0.1)
        end
    end
    
    -- If still not found, create a local fallback
    if not self.playSoundEvent and CONFIG.USE_LOCAL_FALLBACK then
        log("PlaySoundEvent not found after timeout, creating local fallback")
        
        -- Create a local event (won't sync with server, but won't yield either)
        self.playSoundEvent = Instance.new("BindableEvent")
        self.playSoundEvent.Name = "LocalPlaySoundEvent"
        self.playSoundEvent.Parent = player:WaitForChild("PlayerGui")
    end
    
    -- Set up event handler if event was found or created
    if self.playSoundEvent then
        -- Connect to the appropriate event based on the instance type
        if self.playSoundEvent:IsA("RemoteEvent") then
            self.playSoundEvent.OnClientEvent:Connect(function(...)
                self:HandleSoundPlayback(...)
            end)
            log("Connected to RemoteEvent PlaySoundEvent")
        elseif self.playSoundEvent:IsA("BindableEvent") then
            self.playSoundEvent.Event:Connect(function(...)
                self:HandleSoundPlayback(...)
            end)
            log("Connected to local fallback BindableEvent")
        end
    else
        warn("[SoundClient] Failed to find or create PlaySoundEvent")
        return false
    end
    
    self.initialized = true
    log("Sound client system initialized")
    return true
end

-- Handle sound playback (from any event source)
function SoundClient:HandleSoundPlayback(soundId, properties)
    if not soundId then return end
    
    properties = properties or {}
    log("Playing sound: " .. tostring(soundId))
    
    -- Use SoundSystemManager if available
    if self.soundSystemManager then
        self.soundSystemManager:PlaySound(soundId, properties)
        return
    end
    
    -- Fallback implementation
    local sound = Instance.new("Sound")
    sound.Name = "ClientSound"
    
    -- Handle potential asset ID issues
    if type(soundId) == "string" and not string.match(soundId, "^rbxassetid://") then
        soundId = "rbxassetid://" .. soundId
    end
    
    sound.SoundId = soundId
    
    -- Apply properties
    for prop, value in pairs(properties) do
        if prop ~= "Parent" and sound[prop] ~= nil then
            sound[prop] = value
        end
    end
    
    -- Set default properties if not specified
    sound.Volume = properties.Volume or 1
    sound.Parent = properties.Parent or player.Character or workspace
    
    -- Play the sound with error handling
    local success = pcall(function()
        sound:Play()
    end)
    
    if not success then
        warn("[SoundClient] Failed to play sound: " .. tostring(soundId))
        sound:Destroy()
        
        -- Try with a known working sound as fallback
        local fallbackSound = Instance.new("Sound")
        fallbackSound.SoundId = "rbxassetid://12222253" -- Known working simple beep
        fallbackSound.Volume = properties.Volume or 0.5
        fallbackSound.Parent = properties.Parent or player.Character or workspace
        fallbackSound:Play()
        
        -- Auto cleanup
        task.delay(2, function()
            fallbackSound:Destroy()
        end)
    else
        -- Auto cleanup for successful sounds
        task.delay(sound.TimeLength + 1, function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
    end
end

-- Play a sound locally
function SoundClient:PlayLocalSound(soundId, properties)
    self:HandleSoundPlayback(soundId, properties)
end

-- Initialize the system
SoundClient:Initialize()

-- Make functions available through a shared table for testing
local sharedFunctions = ReplicatedStorage:FindFirstChild("SharedFunctions")
if not sharedFunctions then
    sharedFunctions = Instance.new("Folder")
    sharedFunctions.Name = "SharedFunctions"
    sharedFunctions.Parent = ReplicatedStorage
end

-- Create a bindable function for testing
local playLocalSoundFunction = Instance.new("BindableFunction")
playLocalSoundFunction.Name = "PlayLocalSound"
playLocalSoundFunction.OnInvoke = function(soundId, properties)
    SoundClient:PlayLocalSound(soundId, properties)
end
playLocalSoundFunction.Parent = sharedFunctions

-- Return the module
return SoundClient
