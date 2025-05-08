--[[
    InitializeData.server.luau
    
    Initializes the DataManager and DataManagerMonitor systems.
    Ensures proper setup and integration with CoreRegistry.
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    debug = true,
    initTimeout = 10, -- seconds
    retryDelay = 2, -- seconds
    maxRetries = 3
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[InitializeData]", ...)
    end
end

-- Initialize DataManager
local function initializeDataManager()
    log("Initializing DataManager...")
    
    -- Get DataManager module
    local dataManager = require(script.Parent.DataManager)
    if not dataManager then
        warn("Failed to get DataManager module")
        return false
    end
    
    -- Initialize DataManager
    local success = dataManager.initialize()
    if not success then
        warn("Failed to initialize DataManager")
        return false
    end
    
    -- Register with CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if coreRegistry then
        success = coreRegistry.registerSystem("DataManager", dataManager)
        if not success then
            warn("Failed to register DataManager with CoreRegistry")
            return false
        end
    end
    
    log("DataManager initialized successfully")
    return true
end

-- Initialize DataManagerMonitor
local function initializeDataManagerMonitor()
    log("Initializing DataManagerMonitor...")
    
    -- Get DataManagerMonitor module
    local dataManagerMonitor = require(script.Parent.DataManagerMonitor)
    if not dataManagerMonitor then
        warn("Failed to get DataManagerMonitor module")
        return false
    end
    
    -- Start monitoring
    dataManagerMonitor.monitorHealth()
    
    -- Register with CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if coreRegistry then
        local success = coreRegistry.registerSystem("DataManagerMonitor", dataManagerMonitor)
        if not success then
            warn("Failed to register DataManagerMonitor with CoreRegistry")
            return false
        end
    end
    
    log("DataManagerMonitor initialized successfully")
    return true
end

-- Main initialization function
local function initialize()
    log("Starting data system initialization...")
    
    -- Initialize DataManager with retries
    local dataManagerInitialized = false
    for i = 1, CONFIG.maxRetries do
        if initializeDataManager() then
            dataManagerInitialized = true
            break
        end
        
        if i < CONFIG.maxRetries then
            log("Retrying DataManager initialization... (" .. i .. "/" .. CONFIG.maxRetries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not dataManagerInitialized then
        warn("Failed to initialize DataManager after " .. CONFIG.maxRetries .. " attempts")
        return false
    end
    
    -- Initialize DataManagerMonitor
    if not initializeDataManagerMonitor() then
        warn("Failed to initialize DataManagerMonitor")
        return false
    end
    
    log("Data system initialization completed successfully")
    return true
end

-- Run initialization
local success = initialize()
if not success then
    warn("Data system initialization failed")
end 