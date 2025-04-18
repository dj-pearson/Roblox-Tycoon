-- ClientBootstrap.client.luau
-- Initializes client-side systems in the correct order
-- Part of UI refinements initiative (April 2025)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Import the ClientRegistry
local ClientRegistry = require(script.Parent.Core.ClientRegistry)

-- Check if we're in a testing environment
local IS_TESTING = RunService:IsStudio() and not RunService:IsRunMode()

-- Configuration
local CONFIG = {
    debug = true,
    initDelay = IS_TESTING and 1 or 2, -- Give more time in production
    maxRetries = 5,
    retryDelay = 1,
    initializedIndicator = "ClientInitialized" -- Use this to know if client is fully initialized
}

-- System initialization order and dependencies
local SYSTEMS_TO_INITIALIZE = {
    {name = "ClientEventBridge", dependencies = {}}, -- Communication system first (no dependencies)
    {name = "UIManager", dependencies = {"ClientEventBridge"}}, -- UI system needs event bridge
    {name = "UIHub", dependencies = {"UIManager", "ClientEventBridge"}}, -- UI Hub needs UIManager
    -- Other systems can be added below with their dependencies
    {name = "PlayerActivityTracker", dependencies = {"ClientEventBridge"}},
    {name = "CompetitionClient", dependencies = {"UIManager", "ClientEventBridge"}}
}

-- Private variables
local systemStatus = {}
local initializationAttempts = {}
local debugLog = {}

-- Utility function to log debug messages
local function log(message, isWarning)
    if CONFIG.debug then
        local prefix = "[ClientBootstrap] "
        local timestamp = os.date("%H:%M:%S")
        local fullMessage = prefix .. timestamp .. " - " .. message
        
        table.insert(debugLog, fullMessage)
        
        if isWarning then
            warn(fullMessage)
        else
            print(fullMessage)
        end
    end
end

-- Check if all dependencies for a system are initialized
local function areDependenciesMet(system)
    if not system.dependencies or #system.dependencies == 0 then
        return true
    end
    
    for _, dependency in ipairs(system.dependencies) do
        if not systemStatus[dependency] then
            log("Waiting for dependency: " .. dependency .. " for system: " .. system.name, true)
            return false
        end
    end
    
    return true
end

-- Initialize a single system
local function initializeSystem(system)
    -- Skip if already initialized
    if systemStatus[system.name] then
        return true
    end
    
    -- Initialize attempt count
    if not initializationAttempts[system.name] then
        initializationAttempts[system.name] = 0
    end
    
    -- Check if we've reached max attempts
    if initializationAttempts[system.name] >= CONFIG.maxRetries then
        log("Failed to initialize " .. system.name .. " after " .. CONFIG.maxRetries .. " attempts", true)
        return false
    end
    
    -- Increment attempt counter
    initializationAttempts[system.name] = initializationAttempts[system.name] + 1
    
    -- Check dependencies
    if not areDependenciesMet(system) then
        return false
    end
    
    -- Get the system from the registry
    local systemInstance = ClientRegistry.getSystem(system.name)
    if not systemInstance then
        log("System not found in registry: " .. system.name, true)
        return false
    end
    
    -- Check if the system has an initialize method
    if not systemInstance.initialize then
        log("System lacks initialize method: " .. system.name, true)
        return false
    end
    
    -- Try to initialize the system
    log("Initializing: " .. system.name)
    local success, result = pcall(function()
        return systemInstance.initialize()
    end)
    
    -- Check result
    if success and result then
        log("Successfully initialized: " .. system.name)
        systemStatus[system.name] = true
        return true
    else
        log("Failed to initialize: " .. system.name, true)
        if not success then
            log("Error: " .. tostring(result), true)
        end
        return false
    end
end

-- Initialize all systems in order, respecting dependencies
local function initializeSystems()
    log("Starting client initialization...")
    
    -- Try to initialize each system
    local allInitialized = true
    for _, system in ipairs(SYSTEMS_TO_INITIALIZE) do
        if not initializeSystem(system) then
            allInitialized = false
        end
    end
    
    -- If not all systems initialized, retry after delay
    if not allInitialized then
        task.delay(CONFIG.retryDelay, initializeSystems)
        return
    end
    
    -- Post-initialization setup (once all systems are ready)
    log("All client systems initialized")
    
    -- Create an indicator for other scripts to know client is ready
    local indicator = Instance.new("BoolValue")
    indicator.Name = CONFIG.initializedIndicator
    indicator.Value = true
    indicator.Parent = LocalPlayer
    
    -- Trigger special UI Hub setup if it's enabled
    local UIManager = ClientRegistry.getSystem("UIManager")
    if UIManager then
        local config = UIManager.getConfig()
        if config and config.useUIHub then
            log("Setting up UI Hub integration")
            task.delay(0.5, function()
                local UIHub = ClientRegistry.getSystem("UIHub")
                if UIHub and UIHub.initialized then
                    log("UI Hub initialized, hiding legacy buttons")
                    UIHub.hideLegacyButtons()
                end
            end)
        end
    end
    
    -- Setup complete
    log("Client initialization complete!")
end

-- Start initialization after a short delay to ensure all modules are loaded
task.delay(CONFIG.initDelay, initializeSystems)

-- Export debug functionality
local PublicAPI = {
    getDebugLog = function()
        return debugLog
    end,
    
    getSystemStatus = function()
        return systemStatus
    end
}

return PublicAPI