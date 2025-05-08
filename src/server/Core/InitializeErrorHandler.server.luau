--[[
    InitializeErrorHandler.server.luau
    
    Initializes the ErrorHandler and ErrorMonitor systems.
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
        print("[InitializeErrorHandler]", ...)
    end
end

-- Initialize ErrorHandler
local function initializeErrorHandler()
    log("Initializing ErrorHandler...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            local success = handler.initialize()
            if success then
                log("ErrorHandler initialized from CoreRegistry")
                return handler
            end
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            local handler = require(core.ErrorHandler)
            if handler.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("ErrorHandler", handler)
                end
                return handler
            end
        end)
        
        if success and result then
            log("ErrorHandler initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize ErrorHandler")
    return nil
end

-- Initialize ErrorMonitor
local function initializeErrorMonitor()
    log("Initializing ErrorMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("ErrorMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("ErrorMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.ErrorMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("ErrorMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("ErrorMonitor initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize ErrorMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize ErrorHandler with retries
    local handler = nil
    for i = 1, CONFIG.maxRetries do
        handler = initializeErrorHandler()
        if handler then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying ErrorHandler initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not handler then
        log("Failed to initialize ErrorHandler after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize ErrorMonitor
    local monitor = initializeErrorMonitor()
    if not monitor then
        log("Failed to initialize ErrorMonitor")
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