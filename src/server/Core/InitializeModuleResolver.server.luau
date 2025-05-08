--[[
    InitializeModuleResolver.server.luau
    
    Initializes the ModuleResolver and ModuleResolverMonitor systems.
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
        print("[InitializeModuleResolver]", ...)
    end
end

-- Initialize ModuleResolver
local function initializeModuleResolver()
    log("Initializing ModuleResolver...")
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolver") then
        local success, result = pcall(function()
            local system = require(core.ModuleResolver)
            if system.initialize() then
                -- Store in global for easy access
                _G.ModuleResolver = system
                return system
            end
        end)
        
        if success and result then
            log("ModuleResolver initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize ModuleResolver")
    return nil
end

-- Initialize ModuleResolverMonitor
local function initializeModuleResolverMonitor()
    log("Initializing ModuleResolverMonitor...")
    
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local monitor = coreRegistry:getSystem("ModuleResolverMonitor")
        if monitor then
            local success = monitor.initialize()
            if success then
                log("ModuleResolverMonitor initialized from CoreRegistry")
                return monitor
            end
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolverMonitor") then
        local success, result = pcall(function()
            local monitor = require(core.ModuleResolverMonitor)
            if monitor.initialize() then
                -- Register with CoreRegistry if available
                if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
                    coreRegistry:registerSystem("ModuleResolverMonitor", monitor)
                end
                return monitor
            end
        end)
        
        if success and result then
            log("ModuleResolverMonitor initialized from ReplicatedStorage")
            return result
        end
    end
    
    log("Failed to initialize ModuleResolverMonitor")
    return nil
end

-- Main initialization function
local function initialize()
    log("Starting initialization...")
    
    -- Initialize ModuleResolver with retries
    local system = nil
    for i = 1, CONFIG.maxRetries do
        system = initializeModuleResolver()
        if system then break end
        
        if i < CONFIG.maxRetries then
            log("Retrying ModuleResolver initialization in " .. CONFIG.retryDelay .. " seconds...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not system then
        log("Failed to initialize ModuleResolver after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize ModuleResolverMonitor
    local monitor = initializeModuleResolverMonitor()
    if not monitor then
        log("Failed to initialize ModuleResolverMonitor")
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