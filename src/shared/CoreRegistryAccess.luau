--!strict
--[[
    CoreRegistryAccess.luau
    
    A utility module for accessing the CoreRegistry reliably across different
    situations and load orders. This serves as a bridge between different 
    systems and the CoreRegistry, handling common error cases.
    
    Created: April 26, 2025
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug settings
local DEBUG_ENABLED = true

-- Local registry reference for performance
local registryInstance = nil

-- Print debug messages
local function log(message)
    if DEBUG_ENABLED then
        print("[CoreRegistryAccess] " .. message)
    end
end

local function warn_log(message)
    warn("[CoreRegistryAccess] " .. message)
end

-- Try to find module in all common locations
local function findModuleInCommonLocations(moduleName)
    local commonLocations = {
        ServerScriptService:FindFirstChild("Core") and 
            ServerScriptService.Core:FindFirstChild(moduleName),
        
        ReplicatedStorage:FindFirstChild("shared") and 
            ReplicatedStorage.shared:FindFirstChild(moduleName),
        
        ServerScriptService:FindFirstChild("src") and 
            ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild(moduleName),
        
        ReplicatedStorage:FindFirstChild("src") and 
            ReplicatedStorage.src:FindFirstChild("shared") and 
            ReplicatedStorage.src.shared:FindFirstChild(moduleName)
    }
    
    for _, location in ipairs(commonLocations) do
        if location and location:IsA("ModuleScript") then
            return location
        end
    end
    
    return nil
end

-- Utility module for CoreRegistry access
local CoreRegistryAccess = {}

-- Get CoreRegistry with fallbacks
function CoreRegistryAccess:GetRegistry()
    -- Return cached instance if available
    if registryInstance then
        return registryInstance
    end
    
    -- Try shared storage first (set by CoreRegistryInitializer)
    if shared and shared.CoreRegistry then
        registryInstance = shared.CoreRegistry
        log("Found CoreRegistry in shared storage")
        return registryInstance
    end
    
    -- Try to find ModuleLoaderHelper first
    local moduleLoaderHelperScript = findModuleInCommonLocations("ModuleLoaderHelper")
    if moduleLoaderHelperScript then
        local success, moduleLoaderHelper = pcall(function()
            return require(moduleLoaderHelperScript)
        end)
        
        if success and moduleLoaderHelper and moduleLoaderHelper.getCoreRegistry then
            local registry = moduleLoaderHelper.getCoreRegistry()
            if registry then
                registryInstance = registry
                log("Found CoreRegistry through ModuleLoaderHelper")
                return registryInstance
            end
        end
    end
    
    -- Try direct CoreRegistry access
    local coreRegistryScript = findModuleInCommonLocations("CoreRegistry")
    if coreRegistryScript then
        local success, registry = pcall(function()
            return require(coreRegistryScript)
        end)
        
        if success and registry then
            registryInstance = registry
            log("Found CoreRegistry through direct require")
            return registryInstance
        end
    end
    
    -- Last attempt - try to use _G
    if _G and _G.CoreRegistry then
        registryInstance = _G.CoreRegistry
        log("Found CoreRegistry in _G")
        return registryInstance
    end
    
    warn_log("Failed to find CoreRegistry through all available methods")
    return nil
end

-- Register a system with CoreRegistry
function CoreRegistryAccess:RegisterSystem(name, system, dependencies)
    local registry = self:GetRegistry()
    if not registry then
        warn_log("Cannot register system - CoreRegistry not found")
        return false
    end
    
    if registry.registerSystem then
        registry.registerSystem(name, system, dependencies or {})
        log("Registered system: " .. name)
        return true
    else
        warn_log("Invalid CoreRegistry - missing registerSystem method")
        return false
    end
end

-- Get a system from CoreRegistry
function CoreRegistryAccess:GetSystem(name)
    local registry = self:GetRegistry()
    if not registry then
        warn_log("Cannot get system - CoreRegistry not found")
        return nil
    end
    
    if registry.getSystem then
        local system = registry.getSystem(name)
        return system
    else
        warn_log("Invalid CoreRegistry - missing getSystem method")
        return nil
    end
end

-- Fire an event through EventBridge
function CoreRegistryAccess:FireEvent(eventName, ...)
    local registry = self:GetRegistry()
    if not registry then
        warn_log("Cannot fire event - CoreRegistry not found")
        return false
    end
    
    local eventBridge = registry.getSystem and registry:getSystem("EventBridge")
    if eventBridge and eventBridge.fireEvent then
        eventBridge:fireEvent(eventName, ...)
        return true
    else
        warn_log("Cannot fire event - EventBridge not found")
        return false
    end
end

-- Listen for an event through EventBridge
function CoreRegistryAccess:OnEvent(eventName, callback)
    local registry = self:GetRegistry()
    if not registry then
        warn_log("Cannot listen for event - CoreRegistry not found")
        return false
    end
    
    local eventBridge = registry.getSystem and registry:getSystem("EventBridge")
    if eventBridge and eventBridge.connectEvent then
        eventBridge:connectEvent(eventName, callback)
        return true
    else
        warn_log("Cannot listen for event - EventBridge not found")
        return false
    end
end

-- Initialize a system with CoreRegistry
function CoreRegistryAccess:InitializeSystem(name, system)
    if self:RegisterSystem(name, system) then
        return true
    end
    
    -- If CoreRegistry is not available, try to initialize the system directly
    if system.initialize then
        local success, result = pcall(function()
            return system:initialize()
        end)
        
        if success then
            log("Directly initialized system: " .. name)
            return true
        else
            warn_log("Failed to initialize system: " .. name .. " - " .. tostring(result))
            return false
        end
    end
    
    return false
end

-- Get a list of all registered systems
function CoreRegistryAccess:GetAllSystems()
    local registry = self:GetRegistry()
    if not registry then
        return {}
    end
    
    local systems = {}
    
    if registry.getSystemNames then
        systems = registry.getSystemNames()
    elseif registry.systems then
        for name, _ in pairs(registry.systems) do
            table.insert(systems, name)
        end
    end
    
    return systems
end

return CoreRegistryAccess
