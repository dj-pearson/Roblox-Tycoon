--!strict
--[[
    DataSystemInitializer.server.luau
    
    Handles the initial setup and configuration of data systems, ensuring proper
    initialization order and dependency management.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Initial implementation
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import CoreRegistry
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Import DataAccessLayer
local DataAccessLayer = require(script.Parent.DataAccessLayer)

-- Import DataSystemIntegration
local DataSystemIntegration = require(script.Parent.DataSystemIntegration)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    initializationTimeout = 30, -- seconds
    systems = {
        -- Core data systems
        core = {
            "DataAccessLayer",
            "DataSystemIntegration"
        },
        -- Data-dependent systems
        dataDependent = {
            "BuyTileSystem",
            "TycoonSystem",
            "UIComponents",
            "AssetValidator"
        }
    }
}

-- DataSystemInitializer module
local DataSystemInitializer = {
    Version = "1.0.0",
    initialized = false,
    initializationStatus = {},
    initializationErrors = {}
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[DataSystemInitializer]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Initialize the DataSystemInitializer
function DataSystemInitializer:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataSystemInitializer v" .. self.Version)
    
    -- Initialize core systems first
    for _, systemName in ipairs(CONFIG.systems.core) do
        local success = self:InitializeSystem(systemName)
        if not success then
            log("Failed to initialize core system: " .. systemName, "error")
            return false
        end
    end
    
    -- Initialize data-dependent systems
    for _, systemName in ipairs(CONFIG.systems.dataDependent) do
        local success = self:InitializeSystem(systemName)
        if not success then
            log("Failed to initialize data-dependent system: " .. systemName, "warn")
            -- Continue with other systems even if one fails
        end
    end
    
    -- Verify initialization
    local allInitialized = self:VerifyInitialization()
    if not allInitialized then
        log("Some systems failed to initialize properly", "warn")
        -- Attempt recovery
        self:AttemptRecovery()
    end
    
    self.initialized = true
    log("DataSystemInitializer initialized successfully")
    return true
end

-- Initialize a specific system
function DataSystemInitializer:InitializeSystem(systemName)
    if self.initializationStatus[systemName] then
        return true
    end
    
    log("Initializing system: " .. systemName)
    
    -- Get system module
    local systemModule = self:GetSystemModule(systemName)
    if not systemModule then
        log("System module not found: " .. systemName, "error")
        self.initializationErrors[systemName] = "Module not found"
        return false
    end
    
    -- Initialize system with timeout
    local success, result = self:InitializeWithTimeout(systemModule)
    
    if not success then
        log("Failed to initialize system: " .. systemName, "error")
        self.initializationErrors[systemName] = result
        return false
    end
    
    -- Register system with CoreRegistry if not already registered
    if CoreRegistry and not CoreRegistry.isSystemRegistered(systemName) then
        CoreRegistry.registerSystem(systemName, systemModule)
    end
    
    -- Update initialization status
    self.initializationStatus[systemName] = true
    log("System initialized: " .. systemName)
    return true
end

-- Initialize a system with timeout
function DataSystemInitializer:InitializeWithTimeout(systemModule)
    local startTime = os.time()
    local success, result
    
    -- Create a thread for initialization
    local initThread = task.spawn(function()
        if systemModule.Initialize then
            return systemModule:Initialize()
        end
        return true
    end)
    
    -- Wait for initialization with timeout
    while os.time() - startTime < CONFIG.initializationTimeout do
        if coroutine.status(initThread) == "dead" then
            success, result = coroutine.resume(initThread)
            break
        end
        task.wait(0.1)
    end
    
    -- Check if initialization timed out
    if coroutine.status(initThread) ~= "dead" then
        task.cancel(initThread)
        return false, "Initialization timed out"
    end
    
    return success, result
end

-- Get a system module
function DataSystemInitializer:GetSystemModule(systemName)
    -- Try to get from CoreRegistry first
    if CoreRegistry then
        local system = CoreRegistry.getSystem(systemName)
        if system then
            return system
        end
    end
    
    -- Try to require from various locations
    local locations = {
        ServerScriptService.Core,
        ServerScriptService,
        ReplicatedStorage
    }
    
    for _, location in ipairs(locations) do
        local module = location:FindFirstChild(systemName)
        if module and module:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(module)
            end)
            
            if success then
                return result
            end
        end
    end
    
    return nil
end

-- Verify initialization
function DataSystemInitializer:VerifyInitialization()
    local allInitialized = true
    
    -- Check core systems
    for _, systemName in ipairs(CONFIG.systems.core) do
        if not self.initializationStatus[systemName] then
            log("Core system not initialized: " .. systemName, "error")
            allInitialized = false
        end
    end
    
    -- Check data-dependent systems
    for _, systemName in ipairs(CONFIG.systems.dataDependent) do
        if not self.initializationStatus[systemName] then
            log("Data-dependent system not initialized: " .. systemName, "warn")
            allInitialized = false
        end
    end
    
    return allInitialized
end

-- Attempt recovery
function DataSystemInitializer:AttemptRecovery()
    log("Attempting to recover failed systems")
    
    -- Try to recover core systems first
    for _, systemName in ipairs(CONFIG.systems.core) do
        if not self.initializationStatus[systemName] then
            local success = self:RecoverSystem(systemName)
            if success then
                log("Recovered core system: " .. systemName)
            else
                log("Failed to recover core system: " .. systemName, "error")
            end
        end
    end
    
    -- Try to recover data-dependent systems
    for _, systemName in ipairs(CONFIG.systems.dataDependent) do
        if not self.initializationStatus[systemName] then
            local success = self:RecoverSystem(systemName)
            if success then
                log("Recovered data-dependent system: " .. systemName)
            else
                log("Failed to recover data-dependent system: " .. systemName, "warn")
            end
        end
    end
end

-- Recover a system
function DataSystemInitializer:RecoverSystem(systemName)
    log("Attempting to recover system: " .. systemName)
    
    -- Get system module
    local system = self:GetSystemModule(systemName)
    if not system then
        log("Cannot recover system - module not found: " .. systemName, "error")
        return false
    end
    
    -- Attempt recovery
    local success = pcall(function()
        if system.Recover then
            return system:Recover()
        end
        return false
    end)
    
    if success then
        -- Re-initialize if recovery was successful
        return self:InitializeSystem(systemName)
    else
        log("Failed to recover system: " .. systemName, "error")
        return false
    end
end

-- Get initialization status
function DataSystemInitializer:GetInitializationStatus()
    return self.initializationStatus
end

-- Get initialization errors
function DataSystemInitializer:GetInitializationErrors()
    return self.initializationErrors
end

-- Initialize the DataSystemInitializer
DataSystemInitializer:Initialize()

return DataSystemInitializer
