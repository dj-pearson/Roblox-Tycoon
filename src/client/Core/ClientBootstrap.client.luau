-- ClientBootstrap.client.luau
-- Initializes all client-side systems
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core")

-- Basic configuration
local CONFIG = {
    debugEnabled = true,
    systemInitTimeout = 5, -- Maximum time to wait for a system to initialize (seconds)
    initRetryCount = 2,    -- Number of times to retry initializing a failed system
    startupDelay = 1       -- Brief delay before initializing systems (seconds)
}

-- Get the ClientRegistry to access all systems
local ClientRegistry = require(CoreFolder:FindFirstChild("ClientRegistry"))

-- Systems to initialize in order (dependencies handled by registry)
local systemsToInitialize = {
    "ClientEventBridge",   -- Communication system (must be first)
    "ClientPerformanceManager", -- Performance optimization system (initialize early)
    "UIManager",           -- UI system 
    "NotificationSystem",  -- Notifications
    "RevenueClient",       -- Revenue and membership display system
    "CompetitionClient",   -- Competition UI and management
    "SpecializationClient", -- Specialization UI
    "TycoonClient",    
    "SaunaTemperatureClient",   -- Tycoon management client
    "AchievementClient",   -- Achievement system client
    "RebirthClient"       -- Rebirth system client
    -- Additional client-side systems can be added here
}

-- Utility functions
local function log(...)
    if CONFIG.debugEnabled then
        print("[ClientBootstrap]", ...)
    end
end

local function warn(...)
    if CONFIG.debugEnabled then
        warn("[ClientBootstrap]", ...)
    end
end

-- Handle character added
local function onCharacterAdded(character)
    log("Character added")
    
    -- Notify systems that might need to know about the character
    local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
    if ClientEventBridge then
        ClientEventBridge.fireEvent("CharacterAdded", character)
    end
end

-- Tasks to run after all systems are initialized
local function postInitialization()
    log("Running post-initialization tasks...")
    
    -- Connect character-related events
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    -- Handle if character already exists
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    
    log("Post-initialization complete")
    log("Client bootstrap complete!")
end

-- Main initialization function
local function initializeSystems()
    log("Beginning client-side system initialization...")
    
    if CONFIG.startupDelay > 0 then
        task.wait(CONFIG.startupDelay)
    end
    
    -- Track successful initializations
    local initializedCount = 0
    local failedSystems = {}
    
    for _, systemName in ipairs(systemsToInitialize) do
        local success, retryCount = false, 0
        
        -- Attempt to initialize with retries
        while not success and retryCount < CONFIG.initRetryCount do
            log("Initializing " .. systemName .. (retryCount > 0 and " (retry " .. retryCount .. ")" or ""))
            
            local system = ClientRegistry.getSystem(systemName)
            
            if not system then
                warn("System not found: " .. systemName)
                break
            end
            
            -- Check if the system has already been initialized
            if ClientRegistry.isSystemInitialized(systemName) then
                log(systemName .. " was already initialized")
                success = true
                break
            end
            
            -- Attempt initialization with timeout protection
            local initializationComplete = false
            local initSuccess = false
            
            -- Create a separate thread for initialization
            task.spawn(function()
                local result = pcall(function()
                    -- Call system's initialize function if it exists
                    if typeof(system.initialize) == "function" then
                        initSuccess = system.initialize() ~= false
                    else
                        initSuccess = true -- No initialize function means success by default
                    end
                end)
                
                if not result then
                    initSuccess = false
                end
                
                initializationComplete = true
            end)
            
            -- Wait for initialization with timeout
            local startTime = os.clock()
            while not initializationComplete do
                if os.clock() - startTime > CONFIG.systemInitTimeout then
                    warn("System initialization timed out: " .. systemName)
                    break
                end
                task.wait(0.1)
            end
            
            -- Check result
            if initSuccess then
                success = true
                ClientRegistry.markSystemInitialized(systemName)
                log("Successfully initialized: " .. systemName)
                initializedCount = initializedCount + 1
            else
                retryCount = retryCount + 1
                warn("Failed to initialize: " .. systemName .. (retryCount < CONFIG.initRetryCount and ", will retry" or ""))
                task.wait(1) -- Wait before retry
            end
        end
        
        -- Track failed systems
        if not success then
            table.insert(failedSystems, systemName)
        end
    end
    
    -- Final report
    log("Client-side systems initialization complete: " .. initializedCount .. " of " .. #systemsToInitialize .. " systems initialized")
    
    if #failedSystems > 0 then
        warn("Failed to initialize " .. #failedSystems .. " systems: " .. table.concat(failedSystems, ", "))
    end
    
    -- Begin post-initialization tasks
    postInitialization()
end

-- Start the initialization process
task.spawn(initializeSystems)