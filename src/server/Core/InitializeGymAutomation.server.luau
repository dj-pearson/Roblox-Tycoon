--[[
    InitializeGymAutomation.server.luau
    
    Initializes the GymAutomation and GymAutomationMonitor systems.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes both systems
    - Handles initialization failures
    - Provides detailed logging
    - Integrates with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    initTimeout = 10, -- seconds
    retryDelay = 1, -- seconds
    maxRetries = 3
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[InitializeGymAutomation]", ...)
    end
end

-- Initialize GymAutomation
local function initializeGymAutomation()
    log("Initializing GymAutomation...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("GymAutomation") then
        local success, result = pcall(function()
            local system = require(core.GymAutomation)
            if system.initialize() then
                -- Store in global for easy access
                _G.GymAutomation = system
                return system
            end
        end)
        
        if success and result then
            log("GymAutomation initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize GymAutomation")
    return nil
end

-- Initialize GymAutomationMonitor
local function initializeGymAutomationMonitor()
    log("Initializing GymAutomationMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("GymAutomationMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("GymAutomationMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("GymAutomationMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.GymAutomationMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("GymAutomationMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("GymAutomationMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize GymAutomationMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize GymAutomation with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeGymAutomation()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying GymAutomation initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize GymAutomation after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize GymAutomationMonitor
    local monitor = initializeGymAutomationMonitor()
    if not monitor then
        log("Failed to initialize GymAutomationMonitor")
        return false
    end
    
    log("Initialization complete")
    return true
end

-- Run initialization
local success, result = pcall(initialize)
if not success then
    log("Initialization failed with error: " .. tostring(result))
end 