--[[
    InitializeAssets.server.luau
    
    Initializes the AssetManager and AssetMonitor.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes AssetManager and AssetMonitor
    - Handles initialization failures
    - Provides detailed logging
    - Integrates with CoreRegistry
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
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
        print("[InitializeAssets]", ...)
    end
end

-- Initialize AssetManager
local function initializeAssetManager()
    log("Initializing AssetManager...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("AssetManager")
        if manager then
            log("Found AssetManager in CoreRegistry")
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        log("Core folder not found in ServerScriptService")
        return nil
    end
    
    local managerModule = core:FindFirstChild("AssetManager")
    if not managerModule then
        log("AssetManager module not found")
        return nil
    end
    
    -- Require the module
    local success, manager = pcall(function()
        return require(managerModule)
    end)
    
    if not success then
        log("Failed to require AssetManager:", manager)
        return nil
    end
    
    -- Initialize the manager
    success = manager.initialize()
    if not success then
        log("Failed to initialize AssetManager")
        return nil
    end
    
    -- Register with CoreRegistry if available
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        coreRegistry:registerSystem("AssetManager", manager)
        log("Registered AssetManager with CoreRegistry")
    end
    
    log("AssetManager initialized successfully")
    return manager
end

-- Initialize AssetMonitor
local function initializeAssetMonitor()
    log("Initializing AssetMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("AssetMonitor")
        if monitor then
            log("Found AssetMonitor in CoreRegistry")
            return monitor
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        log("Core folder not found in ServerScriptService")
        return nil
    end
    
    local monitorModule = core:FindFirstChild("AssetMonitor")
    if not monitorModule then
        log("AssetMonitor module not found")
        return nil
    end
    
    -- Require the module
    local success, monitor = pcall(function()
        return require(monitorModule)
    end)
    
    if not success then
        log("Failed to require AssetMonitor:", monitor)
        return nil
    end
    
    -- Initialize the monitor
    success = monitor.initialize()
    if not success then
        log("Failed to initialize AssetMonitor")
        return nil
    end
    
    -- Register with CoreRegistry if available
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        coreRegistry:registerSystem("AssetMonitor", monitor)
        log("Registered AssetMonitor with CoreRegistry")
    end
    
    log("AssetMonitor initialized successfully")
    return monitor
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize AssetManager with retries
    local manager
    for i = 1, CONFIG.maxRetries do
        manager = initializeAssetManager()
        if manager then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying AssetManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not manager then
        log("Failed to initialize AssetManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize AssetMonitor
    local monitor = initializeAssetMonitor()
    if not monitor then
        log("Failed to initialize AssetMonitor")
        return false
    end
    
    log("Initialization completed successfully")
    return true
end

-- Run initialization
local success, result = pcall(initialize)
if not success then
    log("Initialization failed with error:", result)
end

return success 