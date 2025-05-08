--[[
    InitializeCoreRegistry.server.luau
    
    Initializes the CoreRegistry and CoreRegistryMonitor systems.
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
        print("[InitializeCoreRegistry]", ...)
    end
end

-- Initialize CoreRegistry
local function initializeCoreRegistry()
    log("Initializing CoreRegistry...")
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("CoreRegistry") then
        local success, result = pcall(function()
            local registry = require(core.CoreRegistry)
            if registry.initialize() then
                -- Store in global for easy access
                _G.CoreRegistry = registry
                return registry
            end
        end)
        
        if success and result then
            log("CoreRegistry initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize CoreRegistry")
    return nil
end

-- Initialize CoreRegistryMonitor
local function initializeCoreRegistryMonitor()
    log("Initializing CoreRegistryMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("CoreRegistryMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("CoreRegistryMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("CoreRegistryMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.CoreRegistryMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("CoreRegistryMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("CoreRegistryMonitor initialized from ServerScriptService")
            return result
        end
    end
    
    log("Failed to initialize CoreRegistryMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize CoreRegistry with retries
    local registry = nil
    for i = 1, CONFIG.maxRetries do
        registry = initializeCoreRegistry()
        if registry then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying CoreRegistry initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not registry then
        log("Failed to initialize CoreRegistry after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize CoreRegistryMonitor
    local monitor = initializeCoreRegistryMonitor()
    if not monitor then
        log("Failed to initialize CoreRegistryMonitor")
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