--[[
    InitializePathManager.luau
    
    Initialization script for the PathManager and PathManagerMonitor systems.
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
        print("[InitializePathManager]", ...)
    end
end

-- Initialize PathManager
local function initializePathManager()
    log("Initializing PathManager...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("PathManager")
        if system then
            local success = system.initialize()
            if success then
                log("PathManager initialized via CoreRegistry")
                return system
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("PathManager") then
        local success, result = pcall(function()
            local system = require(core.PathManager)
            if system.initialize() then
                log("PathManager initialized via ReplicatedStorage")
                return system
            end
        end)
        if success and result then
            return result
        end
    end
    
    log("Failed to initialize PathManager")
    return nil
end

-- Initialize PathManagerMonitor
local function initializePathManagerMonitor()
    log("Initializing PathManagerMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("PathManagerMonitor")
        if system then
            local success = system.initialize()
            if success then
                log("PathManagerMonitor initialized via CoreRegistry")
                return system
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("PathManagerMonitor") then
        local success, result = pcall(function()
            local system = require(core.PathManagerMonitor)
            if system.initialize() then
                log("PathManagerMonitor initialized via ReplicatedStorage")
                return system
            end
        end)
        if success and result then
            return result
        end
    end
    
    log("Failed to initialize PathManagerMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize PathManager with retries
    local pathManager = nil
    for i = 1, CONFIG.maxRetries do
        pathManager = initializePathManager()
        if pathManager then
            break
        end
        log("Retry " .. i .. " of " .. CONFIG.maxRetries)
        task.wait(CONFIG.retryDelay)
    end
    
    if not pathManager then
        log("Failed to initialize PathManager after " .. CONFIG.maxRetries .. " retries")
        return false
    end
    
    -- Initialize PathManagerMonitor
    local monitor = initializePathManagerMonitor()
    if not monitor then
        log("Failed to initialize PathManagerMonitor")
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