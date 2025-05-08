--!strict
--[[
    CoreRegistryBridge.server.luau
    Facilitates reliable CoreRegistry integration and system coordination
    
    Updated: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    LOG_LEVEL = "INFO" -- "DEBUG", "INFO", "WARNING", "ERROR"
}

-- State tracking
local state = {
    initialized = false,
    coreRegistry = nil,
    registeredSystems = {},
    stats = {
        totalRegistrations = 0,
        successfulRegistrations = 0,
        failedRegistrations = 0
    }
}

-- Helper functions
local function log(message, level)
    level = level or CONFIG.LOG_LEVEL
    if level == "DEBUG" and CONFIG.LOG_LEVEL ~= "DEBUG" then return end
    print("[CoreRegistryBridge]", message)
end

local function findCoreRegistry()
    -- Try direct reference first
    if ReplicatedStorage:FindFirstChild("CoreRegistry") then
        local success, registry = pcall(function()
            return require(ReplicatedStorage.CoreRegistry)
        end)
        
        if success and registry then
            log("Found CoreRegistry in ReplicatedStorage", "DEBUG")
            return registry
        end
    end
    
    -- Try path-based search
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("CoreRegistry") then
            local success, registry = pcall(function()
                return require(path.CoreRegistry)
            end)
            
            if success and registry then
                log("Found CoreRegistry at: " .. path.CoreRegistry:GetFullName(), "DEBUG")
                return registry
            end
        end
    end
    
    -- Create a new CoreRegistry if none found
    log("No CoreRegistry found, creating new one", "WARNING")
    local newRegistry = {
        systems = {},
        registerSystem = function(self, name, system)
            self.systems[name] = system
            return true
        end,
        getSystem = function(self, name)
            return self.systems[name]
        end
    }
    
    return newRegistry
end

-- Register a system with CoreRegistry
local function registerSystem(name, system)
    if not state.coreRegistry then
        log("No CoreRegistry available", "ERROR")
        return false
    end
    
    state.stats.totalRegistrations = state.stats.totalRegistrations + 1
    
    local success = pcall(function()
        state.coreRegistry:registerSystem(name, system)
    end)
    
    if success then
        state.registeredSystems[name] = system
        state.stats.successfulRegistrations = state.stats.successfulRegistrations + 1
        log("Successfully registered system: " .. name, "INFO")
        return true
    else
        state.stats.failedRegistrations = state.stats.failedRegistrations + 1
        log("Failed to register system: " .. name, "ERROR")
        return false
    end
end

-- Get a system from CoreRegistry
local function getSystem(name)
    if not state.coreRegistry then
        log("No CoreRegistry available", "ERROR")
        return nil
    end
    
    return state.coreRegistry:getSystem(name)
end

-- Initialize the bridge
local function initialize()
    if state.initialized then return true end
    
    log("Initializing CoreRegistryBridge...", "INFO")
    
    -- Find CoreRegistry
    state.coreRegistry = findCoreRegistry()
    if not state.coreRegistry then
        log("Failed to find or create CoreRegistry", "ERROR")
        return false
    end
    
    -- Register core systems
    local systemsToRegister = {
        "BuyTileSystem",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystemFixer",
        "TileBuyProgressRestorer"
    }
    
    for _, systemName in ipairs(systemsToRegister) do
        local system = getSystem(systemName)
        if system then
            registerSystem(systemName, system)
        end
    end
    
    state.initialized = true
    log("CoreRegistryBridge initialized successfully", "INFO")
    return true
end

-- Public API
return {
    initialize = initialize,
    registerSystem = registerSystem,
    getSystem = getSystem,
    getStats = function() return state.stats end
} 