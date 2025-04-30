--[[
    CoreRegistry.luau
    
    Registry for critical core systems in the game.
    This module provides central access to critical systems and manages system interdependencies.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

-- The systems registry
local systems = {}

-- List of critical systems that must be present
local criticalSystems = {
    "ModuleLoader",
    "DataManager", 
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem",
    "TycoonSystem",
    "EventBridge"
}

-- Log a message to the output
local function log(message)
    if CoreRegistry.DEBUG then
        print("[CoreRegistry] " .. message)
    end
end

-- Initialize the registry
function CoreRegistry.initialize()
    if CoreRegistry.initialized then
        return
    end
    
    log("Initializing CoreRegistry...")
    
    -- Self-register
    CoreRegistry.registerSystem("CoreRegistry", CoreRegistry)
    
    -- Check for DataManager
    local dataManagerFound = false
    
    -- Try to find DataManager in its expected locations
    local dataManagerPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("DataManager")
    }
    
    for _, path in ipairs(dataManagerPaths) do
        if path and path:IsA("ModuleScript") then
            local success, dataManager = pcall(function()
                return require(path)
            end)
            
            if success and dataManager then
                CoreRegistry.registerSystem("DataManager", dataManager)
                dataManagerFound = true
                log("Found and registered DataManager")
                break
            end
        end
    end
    
    if not dataManagerFound then
        log("Critical system missing: DataManager")
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
    
    -- Check for critical systems
    local missingCount = 0
    for _, systemName in ipairs(criticalSystems) do
        if not systems[systemName] then
            log("Critical system missing: " .. systemName)
            missingCount = missingCount + 1
        end
    end
    
    -- Set registry status based on missing systems
    if missingCount == 0 then
        status = RegistryStatus.Ready
    elseif missingCount <= 2 then
        status = RegistryStatus.Degraded
    else
        status = RegistryStatus.Error
    end
    
    log("Registry status set to: " .. status)
      CoreRegistry.initialized = true
    log("CoreRegistry initialized with " .. (7 - missingCount) .. "/7 critical systems")
    
    -- Systems are made accessible through proper require calls
    -- Do not use global variables
    
    return true
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system)
    if not name or type(name) ~= "string" then
        warn("[CoreRegistry] Invalid system name")
        return false
    end
    
    if not system then
        warn("[CoreRegistry] Invalid system object for " .. name)
        return false
    end
    
    log("Registering system: " .. name)
    systems[name] = {
        instance = system,
        timestamp = os.time()
    }
    
    -- Update registry status if this was a critical system
    if table.find(criticalSystems, name) then
        -- Recount missing critical systems
        local missingCount = 0
        for _, systemName in ipairs(criticalSystems) do
            if not systems[systemName] then
                missingCount = missingCount + 1
            end
        end
        
        -- Update status
        if missingCount == 0 then
            status = RegistryStatus.Ready
        elseif missingCount <= 2 then
            status = RegistryStatus.Degraded
        else
            status = RegistryStatus.Error
        end
        
        log("Registry status updated to: " .. status)
    end
    
    return true
end

-- Get a system from the registry
function CoreRegistry.getSystem(name)
    if not name or not systems[name] then
        return nil
    end
    
    return systems[name].instance
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(name)
    return systems[name] ~= nil
end

-- Get the current registry status
function CoreRegistry.getStatus()
    return status
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
    for _, name in ipairs(criticalSystems) do
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
        isCritical = table.find(criticalSystems, name) ~= nil
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
