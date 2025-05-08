--[[
    InitializeMenuButtons.client.luau
    
    Initializes the MenuButtonManager and MenuButtonMonitor systems.
    This script ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes MenuButtonManager and MenuButtonMonitor
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
        print("[InitializeMenuButtons]", ...)
    end
end

-- Initialize MenuButtonManager
local function initializeMenuButtonManager()
    log("Initializing MenuButtonManager...")
    
    -- Try to require MenuButtonManager
    local success, manager = pcall(function()
        local core = ReplicatedStorage:FindFirstChild("Core")
        if not core then
            error("Core folder not found")
        end
        
        local module = core:FindFirstChild("MenuButtonManager")
        if not module then
            error("MenuButtonManager not found")
        end
        
        return require(module)
    end)
    
    if not success then
        log("Failed to require MenuButtonManager:", manager)
        return false
    end
    
    -- Initialize MenuButtonManager
    success, manager = pcall(function()
        return manager.initialize()
    end)
    
    if not success then
        log("Failed to initialize MenuButtonManager:", manager)
        return false
    end
    
    -- Register with CoreRegistry if available
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        success = pcall(function()
            coreRegistry:registerSystem("MenuButtonManager", manager)
        end)
        
        if not success then
            log("Failed to register MenuButtonManager with CoreRegistry")
            return false
        end
    end
    
    log("MenuButtonManager initialized successfully")
    return true
end

-- Initialize MenuButtonMonitor
local function initializeMenuButtonMonitor()
    log("Initializing MenuButtonMonitor...")
    
    -- Try to require MenuButtonMonitor
    local success, monitor = pcall(function()
        local core = ReplicatedStorage:FindFirstChild("Core")
        if not core then
            error("Core folder not found")
        end
        
        local module = core:FindFirstChild("MenuButtonMonitor")
        if not module then
            error("MenuButtonMonitor not found")
        end
        
        return require(module)
    end)
    
    if not success then
        log("Failed to require MenuButtonMonitor:", monitor)
        return false
    end
    
    -- Initialize MenuButtonMonitor
    success, monitor = pcall(function()
        return monitor.initialize()
    end)
    
    if not success then
        log("Failed to initialize MenuButtonMonitor:", monitor)
        return false
    end
    
    -- Register with CoreRegistry if available
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        success = pcall(function()
            coreRegistry:registerSystem("MenuButtonMonitor", monitor)
        end)
        
        if not success then
            log("Failed to register MenuButtonMonitor with CoreRegistry")
            return false
        end
    end
    
    log("MenuButtonMonitor initialized successfully")
    return true
end

-- Main initialization
local function initialize()
    log("Starting initialization...")
    
    -- Initialize MenuButtonManager with retries
    local managerInitialized = false
    for i = 1, CONFIG.maxRetries do
        if initializeMenuButtonManager() then
            managerInitialized = true
            break
        end
        
        if i < CONFIG.maxRetries then
            log("Retrying MenuButtonManager initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not managerInitialized then
        log("Failed to initialize MenuButtonManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize MenuButtonMonitor
    if not initializeMenuButtonMonitor() then
        log("Failed to initialize MenuButtonMonitor")
        return false
    end
    
    log("Initialization completed successfully")
    return true
end

-- Run initialization
local success, result = pcall(initialize)
if not success then
    warn("[InitializeMenuButtons] Initialization failed:", result)
end 