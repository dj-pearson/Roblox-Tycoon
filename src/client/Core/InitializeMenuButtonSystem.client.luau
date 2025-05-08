--[[
    InitializeMenuButtonSystem.client.luau
    
    Initializes the MenuButtonSystem and MenuButtonSystemMonitor systems.
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
        print("[InitializeMenuButtonSystem]", ...)
    end
end

-- Initialize MenuButtonSystem
local function initializeMenuButtonSystem()
    log("Initializing MenuButtonSystem...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("MenuButtonSystem") then
        local success, result = pcall(function()
            local system = require(core.MenuButtonSystem)
            if system.initialize() then
                -- Store in global for easy access
                _G.MenuButtonSystem = system
                return system
            end
        end)
        
        if success and result then
            log("MenuButtonSystem initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize MenuButtonSystem")
    return nil
end

-- Initialize MenuButtonSystemMonitor
local function initializeMenuButtonSystemMonitor()
    log("Initializing MenuButtonSystemMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("MenuButtonSystemMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("MenuButtonSystemMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("MenuButtonSystemMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.MenuButtonSystemMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("MenuButtonSystemMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("MenuButtonSystemMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize MenuButtonSystemMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize MenuButtonSystem with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeMenuButtonSystem()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying MenuButtonSystem initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize MenuButtonSystem after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize MenuButtonSystemMonitor
    local monitor = initializeMenuButtonSystemMonitor()
    if not monitor then
        log("Failed to initialize MenuButtonSystemMonitor")
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