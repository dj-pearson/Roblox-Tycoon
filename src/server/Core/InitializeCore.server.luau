--[[
    InitializeCore.server.luau
    
    Initializes the core systems of the game, starting with CoreRegistry.
    This script should be the first thing to run when the game starts.
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    initTimeout = 30, -- seconds
    retryDelay = 2,   -- seconds
    maxRetries = 3
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[InitializeCore]", ...)
    end
end

-- Initialize CoreRegistry
local function initializeCoreRegistry()
    log("Initializing CoreRegistry...")
    
    -- Get CoreRegistry module
    local coreRegistryModule = ServerScriptService.Core:FindFirstChild("CoreRegistry")
    if not coreRegistryModule then
        warn("CoreRegistry module not found!")
        return false
    end
    
    -- Require CoreRegistry
    local success, CoreRegistry = pcall(function()
        return require(coreRegistryModule)
    end)
    
    if not success or not CoreRegistry then
        warn("Failed to require CoreRegistry:", CoreRegistry)
        return false
    end
    
    -- Initialize CoreRegistry
    success = pcall(function()
        return CoreRegistry.initialize()
    end)
    
    if not success then
        warn("Failed to initialize CoreRegistry")
        return false
    end
    
    -- Store in _G for global access
    _G.CoreRegistry = CoreRegistry
    
    log("CoreRegistry initialized successfully")
    return true
end

-- Initialize CoreRegistryMonitor
local function initializeMonitor()
    log("Initializing CoreRegistryMonitor...")
    
    -- Get monitor module
    local monitorModule = ServerScriptService.Core:FindFirstChild("CoreRegistryMonitor")
    if not monitorModule then
        warn("CoreRegistryMonitor module not found!")
        return false
    end
    
    -- Require monitor
    local success, monitor = pcall(function()
        return require(monitorModule)
    end)
    
    if not success or not monitor then
        warn("Failed to require CoreRegistryMonitor:", monitor)
        return false
    end
    
    -- Store in _G for global access
    _G.CoreRegistryMonitor = monitor
    
    log("CoreRegistryMonitor initialized successfully")
    return true
end

-- Main initialization function
local function initialize()
    log("Starting core initialization...")
    
    -- Initialize CoreRegistry
    local retries = 0
    while retries < CONFIG.maxRetries do
        if initializeCoreRegistry() then
            break
        end
        
        retries += 1
        if retries < CONFIG.maxRetries then
            log("Retrying CoreRegistry initialization...")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if retries >= CONFIG.maxRetries then
        warn("Failed to initialize CoreRegistry after", CONFIG.maxRetries, "attempts")
        return false
    end
    
    -- Initialize monitor
    if not initializeMonitor() then
        warn("Failed to initialize CoreRegistryMonitor")
        return false
    end
    
    log("Core initialization completed successfully")
    return true
end

-- Run initialization
local success = initialize()
if not success then
    warn("Core initialization failed!")
end

return success