--[[
    InitializeUISystem.client.luau
    
    Initializes the UISystem and UISystemMonitor systems.
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
        print("[InitializeUISystem]", ...)
    end
end

-- Initialize UISystem
local function initializeUISystem()
    log("Initializing UISystem...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("UISystem") then
        local success, result = pcall(function()
            local system = require(core.UISystem)
            if system.initialize() then
                -- Store in global for easy access
                _G.UISystem = system
                return system
            end
        end)
        
        if success and result then
            log("UISystem initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize UISystem")
    return nil
end

-- Initialize UISystemMonitor
local function initializeUISystemMonitor()
    log("Initializing UISystemMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("UISystemMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("UISystemMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("UISystemMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.UISystemMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("UISystemMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("UISystemMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize UISystemMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize UISystem with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeUISystem()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying UISystem initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize UISystem after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize UISystemMonitor
    local monitor = initializeUISystemMonitor()
    if not monitor then
        log("Failed to initialize UISystemMonitor")
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