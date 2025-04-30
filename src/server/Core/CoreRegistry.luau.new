-- filepath: c:\Users\dpearson\OneDrive\Documents\RobloxProject\src\server\Core\CoreRegistry.luau
--[[
    CoreRegistry.luau
    
    Registry for critical core systems in the game.
    This module provides central access to critical systems and manages system interdependencies.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed initialization and critical system handling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CoreRegistry = {}
CoreRegistry.initialized = false

-- Registry status enum
local RegistryStatus = {
    Initializing = "Initializing",
    Ready = "Ready",
    Degraded = "Degraded",
    Error = "Error"
}

-- Current registry status
local status = RegistryStatus.Initializing

-- Debug settings
CoreRegistry.DEBUG = true

-- Critical system names
local CRITICAL_SYSTEMS = {
    "ModuleLoader",
    "DataManager",
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem",
    "TycoonSystem",
    "EventBridge"
}

-- The systems registry - stores system objects with metadata
local systems = {}

-- Log a message to the output
local function log(message)
    if CoreRegistry.DEBUG then
        print("[CoreRegistry] " .. message)
    end
end

-- Function to check if all critical systems are registered
function CoreRegistry.checkCriticalSystems()
    local criticalCount = 0
    local missingCritical = {}
    
    for _, systemName in ipairs(CRITICAL_SYSTEMS) do
        if systems[systemName] then
            criticalCount += 1
        else
            table.insert(missingCritical, systemName)
        end
    end
    
    -- Calculate total critical systems
    local totalCritical = #CRITICAL_SYSTEMS
    
    -- Update status based on critical systems
    if criticalCount == 0 then
        status = RegistryStatus.Error
        log("Registry status set to: Error")
    elseif criticalCount < totalCritical then
        status = RegistryStatus.Degraded
        log("Registry status set to: Degraded")
    else
        status = RegistryStatus.Ready
        log("Registry status set to: Ready")
    end
    
    -- Output missing systems
    for _, systemName in ipairs(missingCritical) do
        log("Critical system missing: " .. systemName)
    end
    
    return criticalCount, totalCritical
end

-- Function to register a system
function CoreRegistry.registerSystem(systemName, systemInstance)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to registerSystem")
        return false
    end
    
    if not systemInstance then
        warn("[CoreRegistry] Invalid system object for " .. systemName)
        return false
    end
    
    log("Registering system: " .. systemName)
    
    systems[systemName] = {
        instance = systemInstance,
        timestamp = os.time()
    }
    
    -- Update registry status if this was a critical system
    if table.find(CRITICAL_SYSTEMS, systemName) then
        CoreRegistry.checkCriticalSystems()
    end
    
    return true
end

-- Function to get a system by name
function CoreRegistry.getSystem(systemName)
    if not systemName or typeof(systemName) ~= "string" then
        warn("[CoreRegistry] Invalid system name provided to getSystem")
        return nil
    end
    
    if not systems[systemName] then
        log("System not found: " .. systemName)
        return nil
    end
    
    return systems[systemName].instance
end

-- Alias for getSystem for backward compatibility
CoreRegistry.GetSystem = CoreRegistry.getSystem

-- Function to get registry status
function CoreRegistry.getStatus()
    return status
end

-- Function to run a health check
function CoreRegistry.runHealthCheck()
    log("Running health check...")
    return CoreRegistry.checkCriticalSystems()
end

-- Initialize the registry
function CoreRegistry.initialize()
    if CoreRegistry.initialized then
        return
    end
    
    log("Initializing CoreRegistry...")
    
    -- Self-register
    CoreRegistry.registerSystem("CoreRegistry", CoreRegistry)
    
    -- Try to find and load critical systems from various locations
    for _, systemName in ipairs(CRITICAL_SYSTEMS) do
        if systemName == "CoreRegistry" then
            -- Already registered
            continue
        end
        
        local found = false
        
        -- List of common paths to check for the module
        local searchPaths = {
            -- ServerScriptService paths
            {ServerScriptService, "Core", systemName},
            {ServerScriptService, "Server", "Core", systemName},
            {ServerScriptService, "src", "server", "Core", systemName},
            {ServerScriptService, "Systems", systemName},
            {ServerScriptService, systemName},
            
            -- ReplicatedStorage paths
            {ReplicatedStorage, "shared", systemName},
            {ReplicatedStorage, "src", "shared", systemName},
            {ReplicatedStorage, "Core", systemName},
            {ReplicatedStorage, systemName},
            
            -- ServerStorage paths
            {ServerStorage, "Systems", systemName},
            {ServerStorage, "Core", systemName},
            {ServerStorage, systemName}
        }
        
        -- Try each path
        for _, pathComponents in ipairs(searchPaths) do
            local currentPath = pathComponents[1]
            
            -- Navigate through the path components
            local valid = true
            for i = 2, #pathComponents do
                if not currentPath:FindFirstChild(pathComponents[i]) then
                    valid = false
                    break
                end
                currentPath = currentPath:FindFirstChild(pathComponents[i])
            end
            
            -- If path is valid and a ModuleScript, try loading it
            if valid and currentPath:IsA("ModuleScript") then
                local success, system = pcall(function()
                    return require(currentPath)
                end)
                
                if success and system then
                    CoreRegistry.registerSystem(systemName, system)
                    found = true
                    log("Found and registered " .. systemName)
                    break
                end
            end
        end
        
        if not found then
            log("Critical system missing: " .. systemName)
        end
    end
    
    -- Create shared registry remotes
    local remotes = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "CoreRegistryRemotes"
        remotes.Parent = ReplicatedStorage
        
        -- Create GetSystem remote
        local getSystemRemote = Instance.new("RemoteFunction")
        getSystemRemote.Name = "GetSystem"
        getSystemRemote.Parent = remotes
        
        -- Handle GetSystem calls
        getSystemRemote.OnServerInvoke = function(_, systemName)
            -- Security check - only return certain systems to clients
            local clientAllowedSystems = {
                "UIComponents",
                "AssetValidator",
                "EventBridge"
                -- Add other client-accessible systems here
            }
            
            if table.find(clientAllowedSystems, systemName) then
                local system = CoreRegistry.getSystem(systemName)
                if system and typeof(system.getClientInterface) == "function" then
                    -- Only return client-safe interface if available
                    return system:getClientInterface()
                end
            end
            
            return nil
        end
    end
    
    -- Set initial status based on loaded systems
    CoreRegistry.checkCriticalSystems()
    
    CoreRegistry.initialized = true
    log("CoreRegistry initialization complete")
    
    return true
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(systemName)
    return systems[systemName] ~= nil
end

-- Get all registered system names
function CoreRegistry.getSystemNames()
    local names = {}
    for name, _ in pairs(systems) do
        table.insert(names, name)
    end
    return names
end

-- Get a list of missing critical systems
function CoreRegistry.getMissingCriticalSystems()
    local missing = {}
    for _, name in ipairs(CRITICAL_SYSTEMS) do
        if not systems[name] then
            table.insert(missing, name)
        end
    end
    return missing
end

-- Get system info (excluding the actual system instance)
function CoreRegistry.getSystemInfo(name)
    if not systems[name] then
        return nil
    end
    
    return {
        name = name,
        registered = systems[name].timestamp,
        isCritical = table.find(CRITICAL_SYSTEMS, name) ~= nil
    }
end

-- Get all registered systems and their info
function CoreRegistry.getSystemsInfo()
    local info = {}
    for name, _ in pairs(systems) do
        info[name] = CoreRegistry.getSystemInfo(name)
    end
    return info
end

-- Initialize the registry
CoreRegistry.initialize()

return CoreRegistry
