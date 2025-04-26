--!strict
--[[
    UniversalSystemFinder.luau
    
    A utility module for finding systems and modules across different locations,
    with fallback mechanisms for when CoreRegistry or ModuleLoader are not available.
    
    Created: April 26, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug settings
local DEBUG_ENABLED = true

-- Print debug messages
local function log(message)
    if DEBUG_ENABLED then
        print("[UniversalSystemFinder] " .. message)
    end
end

local function warn_log(message)
    warn("[UniversalSystemFinder] " .. message)
end

-- Main module
local UniversalSystemFinder = {
    cachedSystems = {}, -- Cache to avoid repeated lookups
    nameAliases = {}    -- Alternative names for systems
}

-- Add common aliases for systems
function UniversalSystemFinder:InitializeAliases()
    self.nameAliases = {
        ["DataSystem"] = {"DataManager", "EnhancedDataStorageSystem", "DataStorageSystem"},
        ["EventSystem"] = {"EventBridge", "EventManager"},
        ["UISystem"] = {"UIManager", "UIRegistry"},
        ["TycoonSystem"] = {"TycoonManager", "GymTycoonSystem"}
    }
end

-- Find a system by name, checking multiple locations
function UniversalSystemFinder:FindSystem(systemName)
    -- Check cache first
    if self.cachedSystems[systemName] then
        return self.cachedSystems[systemName]
    end
    
    -- Try CoreRegistryAccess first (most reliable)
    local CoreRegistryAccess = self:FindModule("CoreRegistryAccess", "shared")
    if CoreRegistryAccess then
        local system = CoreRegistryAccess:GetSystem(systemName)
        if system then
            self.cachedSystems[systemName] = system
            return system
        end
    end
    
    -- Try direct CoreRegistry access
    local CoreRegistry = self:GetCoreRegistry()
    if CoreRegistry and CoreRegistry.getSystem then
        local system = CoreRegistry:getSystem(systemName)
        if system then
            self.cachedSystems[systemName] = system
            return system
        end
    end
    
    -- Try to find the module directly
    local module = self:FindModule(systemName)
    if module then
        self.cachedSystems[systemName] = module
        return module
    end
    
    -- Try aliases
    local aliases = self.nameAliases[systemName]
    if aliases then
        for _, alias in ipairs(aliases) do
            local system = self:FindSystem(alias)
            if system then
                self.cachedSystems[systemName] = system  -- Cache under original name
                return system
            end
        end
    end
    
    return nil
end

-- Get CoreRegistry by any means necessary
function UniversalSystemFinder:GetCoreRegistry()
    -- Check cache first
    if self.cachedSystems["CoreRegistry"] then
        return self.cachedSystems["CoreRegistry"]
    end
    
    local registry = nil
    
    -- Try shared table first
    if shared and shared.CoreRegistry then
        registry = shared.CoreRegistry
    end
    
    -- Try global scope
    if not registry and _G and _G.CoreRegistry then
        registry = _G.CoreRegistry
    end
    
    -- Try requiring module
    if not registry then
        if RunService:IsServer() then
            -- Server-side loading
            local success, result = pcall(function()
                return require(ServerScriptService.Core.CoreRegistry)
            end)
            
            if success then
                registry = result
            end
        else
            -- Client-side loading
            local success, result = pcall(function()
                return require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("CoreRegistry"))
            end)
            
            if success then
                registry = result
            end
        end
    end
    
    -- Cache and return
    if registry then
        self.cachedSystems["CoreRegistry"] = registry
    end
    
    return registry
end

-- Find a module in common locations
function UniversalSystemFinder:FindModule(moduleName, context)
    -- Skip missing names
    if not moduleName or moduleName == "" then
        return nil
    end
    
    context = context or "any"
    
    -- Common locations to check based on context
    local locations = {}
    
    if context == "any" or context == "core" then
        if RunService:IsServer() then
            table.insert(locations, ServerScriptService:FindFirstChild("Core"))
        end
        table.insert(locations, ReplicatedStorage:FindFirstChild("Core"))
    end
    
    if context == "any" or context == "shared" then
        table.insert(locations, ReplicatedStorage:FindFirstChild("shared"))
    end
    
    if context == "any" or context == "client" then
        table.insert(locations, ReplicatedStorage:FindFirstChild("client"))
    end
    
    if context == "any" or context == "server" then
        if RunService:IsServer() then
            table.insert(locations, ServerScriptService)
            table.insert(locations, ServerScriptService:FindFirstChild("Systems"))
            table.insert(locations, ServerScriptService:FindFirstChild("Data"))
        end
    end
    
    -- Check each location
    for _, location in ipairs(locations) do
        if location then
            local module = location:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                -- Found module, try to require it
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                end
            end
        end
    end
    
    -- Also check src structure
    local srcLocations = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client")
    }
    
    for _, location in ipairs(srcLocations) do
        if location then
            local module = location:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                -- Found module, try to require it
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                end
            end
        end
    end
    
    return nil
end

-- Find a service (using Roblox GetService)
function UniversalSystemFinder:FindService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    
    if success then
        return service
    end
    
    return nil
end

-- Find an event in ReplicatedStorage.Events
function UniversalSystemFinder:FindEvent(eventName)
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        return nil
    end
    
    local event = eventsFolder:FindFirstChild(eventName)
    if event and (event:IsA("RemoteEvent") or event:IsA("RemoteFunction") or event:IsA("BindableEvent")) then
        return event
    end
    
    return nil
end

-- Get all registered systems (for diagnostics)
function UniversalSystemFinder:ListAllSystems()
    -- Try CoreRegistry first
    local registry = self:GetCoreRegistry()
    if registry and registry.systems then
        local systemNames = {}
        for name, _ in pairs(registry.systems) do
            table.insert(systemNames, name)
        end
        return systemNames
    end
    
    -- Fallback: Try to gather from modules in Core folder
    local systemNames = {}
    
    if RunService:IsServer() then
        local core = ServerScriptService:FindFirstChild("Core")
        if core then
            for _, child in pairs(core:GetChildren()) do
                if child:IsA("ModuleScript") then
                    table.insert(systemNames, child.Name)
                end
            end
        end
    end
    
    return systemNames
end

-- Initialize aliases
UniversalSystemFinder:InitializeAliases()

return UniversalSystemFinder
