--!strict
--[[
    RegistryBridge.luau
    
    A compatibility layer that bridges legacy registry code with the new unified Registry System.
    This module automatically forwards registry operations to the appropriate context-aware registry.
    
    Usage:
    - For legacy code dependent on CoreRegistry: require this module instead
    - For new code: use the appropriate context-specific registry directly
    
    Created: May 2, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Determine execution context
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Import new registry systems
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local RegistryBase = require(RegistryModules:WaitForChild("RegistryBase"))
local SharedRegistry = require(RegistryModules:WaitForChild("SharedRegistry"))
local RegistryTelemetry = require(RegistryModules:WaitForChild("RegistryTelemetry"))

-- Context-specific registry
local ContextRegistry
if isServer then
    local ServerModules = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Registry")
    ContextRegistry = require(ServerModules:WaitForChild("ServerRegistry"))
elseif isClient then
    local ClientModules = script.Parent:FindFirstChild("Registry")
    if ClientModules then
        ContextRegistry = require(ClientModules:WaitForChild("ClientRegistry"))
    else
        -- Try alternative paths
        local alternativePath = ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core"):WaitForChild("Registry")
        ContextRegistry = require(alternativePath:WaitForChild("ClientRegistry"))
    end
end

-- Legacy CoreRegistry API
local RegistryBridge = {}

-- Tracking for wrapped objects
local wrappedComponents = {}

-- Forward registration to the appropriate registry
function RegistryBridge:RegisterSystem(systemName, systemComponent)
    -- Log telemetry for legacy API usage
    RegistryTelemetry:LogLegacyUsage("RegistryBridge", "RegisterSystem", systemName)
    
    -- Add warning for legacy API usage
    if SharedRegistry.Config.debugMode then
        warn("[RegistryBridge] Legacy RegisterSystem call for: " .. systemName .. ". Consider migrating to the new registry API.")
    end
    
    -- Create wrapper with metadata
    local wrappedComponent = {
        _original = systemComponent,
        _legacyName = systemName,
        _registrationTime = os.time(),
        _migrationStatus = "pending"
    }
    
    -- Store for future reference
    wrappedComponents[systemName] = wrappedComponent
    
    -- Register with context-appropriate registry
    if ContextRegistry then
        ContextRegistry:RegisterComponent(systemName, systemComponent, {
            legacy = true,
            autoInit = true,
            version = "legacy-" .. os.time(),
            source = "legacy-bridge"
        })
    end
    
    -- Also register with shared registry for cross-context discovery
    SharedRegistry:RegisterComponent(systemName, systemComponent, {
        legacy = true,
        autoInit = false, -- Let the context registry handle initialization
        version = "legacy-" .. os.time(),
        source = "legacy-bridge"
    })
    
    -- Log successful migration event
    RegistryTelemetry:LogMigrationEvent("legacy_registration_bridged", {
        name = systemName,
        context = isServer and "server" or "client"
    })
    
    return true
end

-- Forward component retrieval
function RegistryBridge:GetSystem(systemName)
    -- Log telemetry for legacy API usage
    RegistryTelemetry:LogLegacyUsage("RegistryBridge", "GetSystem", systemName)
    
    -- Try context registry first
    if ContextRegistry then
        local success, component = pcall(function()
            return ContextRegistry:GetComponent(systemName)
        end)
        
        if success and component then
            return component
        end
    end
    
    -- Fall back to shared registry
    local success, component = pcall(function()
        return SharedRegistry:GetComponent(systemName)
    end)
    
    if success and component then
        return component
    end
    
    -- Final fallback to legacy wrapped components
    local component = wrappedComponents[systemName] and wrappedComponents[systemName]._original
    
    -- Log error if component not found
    if not component then
        RegistryTelemetry:LogError("RegistryBridge", "Component not found", systemName)
    end
    
    return component
end

-- Legacy initialization API
function RegistryBridge:InitializeSystem(systemName)
    if ContextRegistry then
        local success, result = pcall(function()
            return ContextRegistry:InitializeComponent(systemName)
        end)
        
        if success then
            return result
        end
    end
    
    return false
end

-- Legacy dependency API
function RegistryBridge:AddDependency(systemName, dependencyName)
    if ContextRegistry then
        ContextRegistry:AddDependency(systemName, dependencyName)
    end
    
    return true
end

-- Legacy health check API
function RegistryBridge:IsSystemAvailable(systemName)
    if ContextRegistry then
        return ContextRegistry:IsComponentAvailable(systemName)
    end
    
    return false
end

-- Legacy system status API
function RegistryBridge:GetSystemStatus(systemName)
    if ContextRegistry then
        local status = ContextRegistry:GetComponentStatus(systemName)
        return status or "Unknown"
    end
    
    return "Unknown"
end

-- Migration helpers
function RegistryBridge:MigrateToNewRegistry(systemName, newRegistry)
    local component = wrappedComponents[systemName]
    if component then
        component._migrationStatus = "completed"
        
        if newRegistry then
            newRegistry:RegisterComponent(systemName, component._original, {
                legacy = false,
                migrated = true,
                version = "migrated-" .. os.time()
            })
        end
        
        return true
    end
    
    return false
end

-- Legacy events forwarding
function RegistryBridge:FireEvent(eventName, ...)
    if ContextRegistry then
        ContextRegistry:FireEvent(eventName, ...)
    end
end

function RegistryBridge:ConnectEvent(eventName, callback)
    if ContextRegistry then
        return ContextRegistry:ConnectEvent(eventName, callback)
    end
    
    -- Return dummy connection for compatibility
    return {
        Disconnect = function() end
    }
end

-- Add CoreRegistry-style API aliases for maximum compatibility
RegistryBridge.registerSystem = RegistryBridge.RegisterSystem
RegistryBridge.getSystem = RegistryBridge.GetSystem
RegistryBridge.initializeSystem = RegistryBridge.InitializeSystem
RegistryBridge.addDependency = RegistryBridge.AddDependency
RegistryBridge.isSystemAvailable = RegistryBridge.IsSystemAvailable
RegistryBridge.getSystemStatus = RegistryBridge.GetSystemStatus
RegistryBridge.fireEvent = RegistryBridge.FireEvent
RegistryBridge.connectEvent = RegistryBridge.ConnectEvent

return RegistryBridge
