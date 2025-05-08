--[[
    InitializeTycoonFolderManager.server.luau
    
    Initializes the TycoonFolderManager and TycoonFolderManagerMonitor systems.
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
        print("[InitializeTycoonFolderManager]", ...)
    end
end

-- Initialize TycoonFolderManager
local function initializeTycoonFolderManager()
    log("Initializing TycoonFolderManager...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("TycoonFolderManager") then
        local success, result = pcall(function()
            local system = require(core.TycoonFolderManager)
            if system.initialize() then
                -- Store in global for easy access
                _G.TycoonFolderManager = system
                return system
            end
        end)
        
        if success and result then
            log("TycoonFolderManager initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize TycoonFolderManager")
    return nil
end

-- Initialize TycoonFolderManagerMonitor
local function initializeTycoonFolderManagerMonitor()
    log("Initializing TycoonFolderManagerMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("TycoonFolderManagerMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("TycoonFolderManagerMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("TycoonFolderManagerMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.TycoonFolderManagerMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("TycoonFolderManagerMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("TycoonFolderManagerMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize TycoonFolderManagerMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize TycoonFolderManager with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeTycoonFolderManager()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying TycoonFolderManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize TycoonFolderManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize TycoonFolderManagerMonitor
    local monitor = initializeTycoonFolderManagerMonitor()
    if not monitor then
        log("Failed to initialize TycoonFolderManagerMonitor")
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