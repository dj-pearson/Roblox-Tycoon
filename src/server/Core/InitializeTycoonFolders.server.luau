--[[
    InitializeTycoonFolders.server.luau
    
    Initializes the TycoonFolderManager and TycoonFolderMonitor.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes TycoonFolderManager and TycoonFolderMonitor
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
        print("[InitializeTycoonFolders]", ...)
    end
end

-- Initialize TycoonFolderManager
local function initializeTycoonFolderManager()
    log("Initializing TycoonFolderManager...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("TycoonFolderManager")
        if manager then
            log("Found TycoonFolderManager in CoreRegistry")
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        log("Core folder not found in ServerScriptService")
        return nil
    end
    
    local managerModule = core:FindFirstChild("TycoonFolderManager")
    if not managerModule then
        log("TycoonFolderManager module not found")
        return nil
    end
    
    -- Require the module
    local success, manager = pcall(function()
        return require(managerModule)
    end)
    
    if not success then
        log("Failed to require TycoonFolderManager:", manager)
        return nil
    end
    
    -- Initialize the manager
    success = manager.initialize()
    if not success then
        log("Failed to initialize TycoonFolderManager")
        return nil
    end
    
    -- Register with CoreRegistry if available
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        coreRegistry:registerSystem("TycoonFolderManager", manager)
        log("Registered TycoonFolderManager with CoreRegistry")
    end
    
    log("TycoonFolderManager initialized successfully")
    return manager
end

-- Initialize TycoonFolderMonitor
local function initializeTycoonFolderMonitor()
    log("Initializing TycoonFolderMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("TycoonFolderMonitor")
        if monitor then
            log("Found TycoonFolderMonitor in CoreRegistry")
            return monitor
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        log("Core folder not found in ServerScriptService")
        return nil
    end
    
    local monitorModule = core:FindFirstChild("TycoonFolderMonitor")
    if not monitorModule then
        log("TycoonFolderMonitor module not found")
        return nil
    end
    
    -- Require the module
    local success, monitor = pcall(function()
        return require(monitorModule)
    end)
    
    if not success then
        log("Failed to require TycoonFolderMonitor:", monitor)
        return nil
    end
    
    -- Initialize the monitor
    success = monitor.initialize()
    if not success then
        log("Failed to initialize TycoonFolderMonitor")
        return nil
    end
    
    -- Register with CoreRegistry if available
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        coreRegistry:registerSystem("TycoonFolderMonitor", monitor)
        log("Registered TycoonFolderMonitor with CoreRegistry")
    end
    
    log("TycoonFolderMonitor initialized successfully")
    return monitor
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize TycoonFolderManager with retries
    local manager
    for i = 1, CONFIG.maxRetries do
        manager = initializeTycoonFolderManager()
        if manager then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying TycoonFolderManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not manager then
        log("Failed to initialize TycoonFolderManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize TycoonFolderMonitor
    local monitor = initializeTycoonFolderMonitor()
    if not monitor then
        log("Failed to initialize TycoonFolderMonitor")
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