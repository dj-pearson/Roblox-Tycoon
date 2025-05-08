--[[
    InitializeDataManager.server.luau
    
    Initializes the DataManager and DataManagerMonitor systems.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes both systems
    - Handles initialization failures
    - Provides detailed logging
    - Integrates with CoreRegistry
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

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
        print("[InitializeDataManager]", ...)
    end
end

-- Initialize DataManager
local function initializeDataManager()
    log("Initializing DataManager...")
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("DataManager") then
        local success, result = pcall(function()
            local manager = require(core.DataManager)
            if manager.initialize() then
                -- Store in global for easy access
                _G.DataManager = manager
                return manager
            end
        end)
        
        if success and result then
            log("DataManager initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize DataManager")
    return nil
end

-- Initialize DataManagerMonitor
local function initializeDataManagerMonitor()
    log("Initializing DataManagerMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("DataManagerMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("DataManagerMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("DataManagerMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.DataManagerMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("DataManagerMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("DataManagerMonitor initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize DataManagerMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize DataManager with retries
    local manager = nil
    for i = 1, CONFIG.maxRetries do
        manager = initializeDataManager()
        if manager then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying DataManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not manager then
        log("Failed to initialize DataManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize DataManagerMonitor
    local monitor = initializeDataManagerMonitor()
    if not monitor then
        log("Failed to initialize DataManagerMonitor")
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