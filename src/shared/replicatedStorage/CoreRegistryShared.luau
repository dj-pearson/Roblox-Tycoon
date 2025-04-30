--[[
    CoreRegistryShared.luau
    
    A shared version of CoreRegistry for client-side access.
    This module provides a client-side interface to the server's CoreRegistry.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoreRegistryShared = {}
CoreRegistryShared.initalized = false

-- Systems cache
local systems = {}

-- Debug settings
CoreRegistryShared.DEBUG = true

-- Log a message to the output
local function log(message)
    if CoreRegistryShared.DEBUG then
        print("[CoreRegistryShared] " .. message)
    end
end

-- Initialize the shared registry
function CoreRegistryShared.initialize()
    if CoreRegistryShared.initialized then
        return true
    end
    
    log("Initializing shared registry...")
    
    -- Look for remotes
    local remotes = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
    if remotes then
        log("Found CoreRegistry remotes")
    else
        log("No CoreRegistry remotes found, creating client-side system cache only")
    end
    
    -- Load any client-side extensions
    local extensions = ReplicatedStorage:FindFirstChild("CoreRegistryExtensions")
    if extensions then
        for _, module in ipairs(extensions:GetChildren()) do
            if module:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success and result then
                    log("Loaded extension: " .. module.Name)
                end
            end
        end
    end
    
    CoreRegistryShared.initialized = true
    log("CoreRegistryShared initialized")
    return true
end

-- Register a client-side system
function CoreRegistryShared.registerSystem(name, system)
    if not name or type(name) ~= "string" then
        warn("[CoreRegistryShared] Invalid system name")
        return false
    end
    
    if not system then
        warn("[CoreRegistryShared] Invalid system object for " .. name)
        return false
    end
    
    log("Registering client system: " .. name)
    systems[name] = {
        instance = system,
        timestamp = os.time()
    }
    
    return true
end

-- Get a system from the registry
function CoreRegistryShared.getSystem(name)
    -- Check local systems first
    if systems[name] then
        return systems[name].instance
    end
    
    -- Try to load from client-side modules
    local clientModules = ReplicatedStorage:FindFirstChild("ClientModules")
    if clientModules and clientModules:FindFirstChild(name) then
        local success, result = pcall(function()
            return require(clientModules[name])
        end)
        
        if success and result then
            -- Register for future use
            CoreRegistryShared.registerSystem(name, result)
            return result
        end
    end
    
    -- Try remote access if available
    local remotes = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
    if remotes and remotes:FindFirstChild("GetSystem") then
        local remote = remotes.GetSystem
        local success, result = pcall(function()
            return remote:InvokeServer(name)
        end)
        
        if success and result then
            log("Got system " .. name .. " from server")
            return result
        end
    end
    
    return nil
end

-- Check if a system is registered
function CoreRegistryShared.hasSystem(name)
    return systems[name] ~= nil
end

-- Initialize on load
CoreRegistryShared.initialize()

return CoreRegistryShared
