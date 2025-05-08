--!strict
--[[
    SystemBootstrap.server.luau
    
    Handles the initialization of all game systems using CoreRegistry.
    Manages system dependencies and initialization order.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Updated to use improved CoreRegistry
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    initializationOrder = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge"
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[SystemBootstrap]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Load a system module
local function loadSystem(systemName)
    -- Try to find the system module
    local systemModule = nil
    
    -- Check ServerScriptService/Core
    local coreFolder = ServerScriptService:FindFirstChild("Core")
    if coreFolder then
        systemModule = coreFolder:FindFirstChild(systemName)
    end
    
    -- Check ServerScriptService
    if not systemModule then
        systemModule = ServerScriptService:FindFirstChild(systemName)
    end
    
    -- Check ReplicatedStorage
    if not systemModule then
        systemModule = ReplicatedStorage:FindFirstChild(systemName)
    end
    
    if not systemModule then
        log("Could not find system module: " .. systemName, "error")
        return nil
    end
    
    -- Require the module
    local success, system = pcall(function()
        return require(systemModule)
    end)
    
    if not success then
        log("Failed to require system module: " .. systemName .. " - " .. tostring(system), "error")
        return nil
    end
    
    return system
end

-- Register a system with CoreRegistry
local function registerSystem(systemName, system)
    if not system then
        log("Cannot register nil system: " .. systemName, "error")
        return false
    end
    
    -- Get dependencies from CoreRegistry config
    local dependencies = CoreRegistry.CONFIG.systemDependencies[systemName] or {}
    
    -- Register with CoreRegistry
    if not CoreRegistry.registerSystem(systemName, system, dependencies) then
        log("Failed to register system: " .. systemName, "error")
        return false
    end
    
    log("Registered system: " .. systemName)
    return true
end

-- Initialize all systems
local function initializeSystems()
    log("Starting system initialization...")
    
    -- Register all systems first
    for _, systemName in ipairs(CONFIG.initializationOrder) do
        local system = loadSystem(systemName)
        if system then
            if not registerSystem(systemName, system) then
                log("Failed to register system: " .. systemName, "error")
            end
        else
            log("Failed to load system: " .. systemName, "error")
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
        log("Failed systems:", "warn")
        for _, systemName in ipairs(status.failed) do
            log("  - " .. systemName, "warn")
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
    getInitStatus = CoreRegistry.getInitStatus,
    getSystemStatus = CoreRegistry.getSystemStatus,
    getAllSystemStatuses = CoreRegistry.getAllSystemStatuses
}
