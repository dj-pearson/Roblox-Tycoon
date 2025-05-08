--[[
    InitializeAssetManager.luau
    
    Initializes the AssetManager and AssetManagerMonitor systems.
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
        print("[InitializeAssetManager]", ...)
    end
end

-- Initialize AssetManager
local function initializeAssetManager()
    log("Initializing AssetManager...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("AssetManager") then
        local success, result = pcall(function()
            local system = require(core.AssetManager)
            if system.initialize() then
                -- Store in global for easy access
                _G.AssetManager = system
                return system
            end
        end)
        
        if success and result then
            log("AssetManager initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize AssetManager")
    return nil
end

-- Initialize AssetManagerMonitor
local function initializeAssetManagerMonitor()
    log("Initializing AssetManagerMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("AssetManagerMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("AssetManagerMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("AssetManagerMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.AssetManagerMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("AssetManagerMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("AssetManagerMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize AssetManagerMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize AssetManager with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeAssetManager()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying AssetManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize AssetManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize AssetManagerMonitor
    local monitor = initializeAssetManagerMonitor()
    if not monitor then
        log("Failed to initialize AssetManagerMonitor")
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