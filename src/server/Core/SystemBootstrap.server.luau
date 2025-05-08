--!strict
--[[
    SystemBootstrap.server.luau
    
    Handles the initialization of all game systems in the correct order.
    Works with CoreRegistry to ensure proper system initialization and dependency management.
    
    Created: April 26, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- System dependencies
local SYSTEM_DEPENDENCIES = {
    -- Core Systems
    EventBridge = {},
    DataPersistence = {},
    DataAccessLayer = {"DataPersistence"},
    DataManager = {"DataAccessLayer", "EventBridge"},
    
    -- UI Systems
    UIComponents = {"EventBridge"},
    
    -- Game Systems
    AssetValidator = {"DataManager"},
    BuyTileSystem = {"DataManager", "EventBridge"},
    TycoonSystem = {"DataManager", "BuyTileSystem", "EventBridge"}
}

-- System initialization order
local INITIALIZATION_ORDER = {
    "EventBridge",
    "DataPersistence",
    "DataAccessLayer",
    "DataManager",
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem",
    "TycoonSystem"
}

-- Debug logging
local function log(message)
    print("[SystemBootstrap] " .. message)
end

-- Load a system module
local function loadSystem(systemName)
    local systemPath = ServerScriptService:FindFirstChild("Systems")
    if not systemPath then
        warn("Systems folder not found")
        return nil
    end
    
    local systemModule = systemPath:FindFirstChild(systemName)
    if not systemModule then
        warn("System module not found: " .. systemName)
        return nil
    end
    
    local success, system = pcall(require, systemModule)
    if not success then
        warn("Failed to require system module: " .. systemName)
        return nil
    end
    
    return system
end

-- Register a system with CoreRegistry
local function registerSystem(systemName, system)
    if not system then
        warn("Cannot register nil system: " .. systemName)
        return false
    end
    
    local dependencies = SYSTEM_DEPENDENCIES[systemName] or {}
    return CoreRegistry.registerSystem(systemName, system, dependencies)
end

-- Initialize all systems
local function initializeSystems()
    log("Starting system initialization...")
    
    -- Register all systems first
    for _, systemName in ipairs(INITIALIZATION_ORDER) do
        local system = loadSystem(systemName)
        if system then
            if not registerSystem(systemName, system) then
                warn("Failed to register system: " .. systemName)
            end
        end
    end
    
    -- Initialize all systems through CoreRegistry
    local success = CoreRegistry.initializeAll()
    
    -- Get initialization status
    local status = CoreRegistry.getInitStatus()
    
    -- Log results
    log("Initialization complete")
    log("Status: " .. CoreRegistry.getStatus())
    log("Initialized systems: " .. #status.initialized)
    log("Failed systems: " .. #status.failed)
    log("Pending systems: " .. #status.pending)
    
    if #status.failed > 0 then
        log("Failed systems:")
        for _, systemName in ipairs(status.failed) do
            log("  - " .. systemName)
        end
    end
    
    return success
end

-- Run initialization
local success = initializeSystems()

-- Export initialization status
return {
    success = success,
    status = CoreRegistry.getStatus(),
    getInitStatus = CoreRegistry.getInitStatus
}
