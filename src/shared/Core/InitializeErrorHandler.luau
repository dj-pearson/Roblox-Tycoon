--[[
    InitializeErrorHandler.luau
    
    Initialization script for the ErrorHandler and ErrorHandlerMonitor systems.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - System initialization
    - Retry logic
    - Error handling
    - CoreRegistry integration
    
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
        print("[InitializeErrorHandler]", ...)
    end
end

-- Initialize ErrorHandler
local function initializeErrorHandler()
    log("Initializing ErrorHandler...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("ErrorHandler")
        if system then
            local success = system.initialize()
            if success then
                log("ErrorHandler initialized via CoreRegistry")
                return system
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            local system = require(core.ErrorHandler)
            if system.initialize() then
                log("ErrorHandler initialized via ReplicatedStorage")
                return system
            end
        end)
        if success and result then
            return result
        end
    end
    
    log("Failed to initialize ErrorHandler")
    return nil
end

-- Initialize ErrorHandlerMonitor
local function initializeErrorHandlerMonitor()
    log("Initializing ErrorHandlerMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("ErrorHandlerMonitor")
        if system then
            local success = system.initialize()
            if success then
                log("ErrorHandlerMonitor initialized via CoreRegistry")
                return system
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandlerMonitor") then
        local success, result = pcall(function()
            local system = require(core.ErrorHandlerMonitor)
            if system.initialize() then
                log("ErrorHandlerMonitor initialized via ReplicatedStorage")
                return system
            end
        end)
        if success and result then
            return result
        end
    end
    
    log("Failed to initialize ErrorHandlerMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize ErrorHandler with retries
    local errorHandler = nil
    for i = 1, CONFIG.maxRetries do
        errorHandler = initializeErrorHandler()
        if errorHandler then
            break
        end
        log("Retry " .. i .. " of " .. CONFIG.maxRetries)
        task.wait(CONFIG.retryDelay)
    end
    
    if not errorHandler then
        log("Failed to initialize ErrorHandler after " .. CONFIG.maxRetries .. " retries")
        return false
    end
    
    -- Initialize ErrorHandlerMonitor
    local monitor = initializeErrorHandlerMonitor()
    if not monitor then
        log("Failed to initialize ErrorHandlerMonitor")
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

return success 