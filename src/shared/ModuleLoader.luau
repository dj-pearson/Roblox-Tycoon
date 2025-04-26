--!strict
--[[
    ModuleLoader.luau
    
    A utility module for loading modules with robust path resolution.
    
    Created: April 25, 2025
    
    Features:
    - Multiple search paths for modules
    - Path resolution independent of exact hierarchy
    - Verbose logging for module loading issues
    - Support for lazy-loading optional dependencies
    - Caching of successfully loaded modules
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()
local IsStudio = RunService:IsStudio()

-- Configuration
local DEBUG_LOGGING = true 
local VERBOSE_LOGGING = false

-- Module cache
local loadedModules = {}
local moduleLoadAttempts = {}

-- Default search paths
local defaultSearchPaths = {
    ReplicatedStorage,
    ReplicatedStorage:FindFirstChild("shared"),
    game:GetService("ServerScriptService"),
    game:GetService("ServerStorage")
}

if IsClient then
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    if LocalPlayer then
        table.insert(defaultSearchPaths, 3, LocalPlayer.PlayerScripts)
        
        if LocalPlayer.PlayerScripts:FindFirstChild("client") then
            table.insert(defaultSearchPaths, 4, LocalPlayer.PlayerScripts.client)
        end
        
        if LocalPlayer.PlayerScripts:FindFirstChild("Client") then
            table.insert(defaultSearchPaths, 5, LocalPlayer.PlayerScripts.Client)
        end
    end
end

-- Utility functions
local ModuleLoader = {
    loadedModules = loadedModules,
    searchPaths = defaultSearchPaths,
}

-- Logging function
function ModuleLoader.log(message, isVerbose)
    if DEBUG_LOGGING and (not isVerbose or VERBOSE_LOGGING) then
        print("[ModuleLoader] " .. message)
    end
end

-- Add a search path
function ModuleLoader.addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(ModuleLoader.searchPaths, 1, path)
        ModuleLoader.log("Added search path: " .. path:GetFullName())
        return true
    else
        warn("[ModuleLoader] Invalid search path: " .. tostring(path))
        return false
    end
end

-- Clear the module cache
function ModuleLoader.clearCache()
    loadedModules = {}
    moduleLoadAttempts = {}
    ModuleLoader.log("Module cache cleared")
end

-- Find a module by name in any of the search paths
function ModuleLoader.findModule(moduleName)
    -- If already cached, return from cache
    if moduleLoadAttempts[moduleName] then
        return moduleLoadAttempts[moduleName]
    end
    
    ModuleLoader.log("Searching for module: " .. moduleName, true)
    
    -- First look for exact matches
    for _, searchPath in ipairs(ModuleLoader.searchPaths) do
        -- Direct child
        local directChild = searchPath:FindFirstChild(moduleName)
        if directChild and directChild:IsA("ModuleScript") then
            ModuleLoader.log("Found module (direct): " .. directChild:GetFullName(), true)
            moduleLoadAttempts[moduleName] = directChild
            return directChild
        end
    end
    
    -- Then look for path segments (moduleName = "folder/module")
    local pathSegments = string.split(moduleName, "/")
    if #pathSegments > 1 then
        for _, searchPath in ipairs(ModuleLoader.searchPaths) do
            local current = searchPath
            for i, segment in ipairs(pathSegments) do
                if current then
                    current = current:FindFirstChild(segment)
                    if not current and i < #pathSegments then
                        break
                    end
                end
            end
            
            if current and current:IsA("ModuleScript") then
                ModuleLoader.log("Found module (path): " .. current:GetFullName(), true)
                moduleLoadAttempts[moduleName] = current
                return current
            end
        end
    end
    
    -- If still not found, do a deep search in each path
    for _, searchPath in ipairs(ModuleLoader.searchPaths) do
        local found = ModuleLoader.deepSearchModule(searchPath, moduleName)
        if found then
            ModuleLoader.log("Found module (deep): " .. found:GetFullName(), true)
            moduleLoadAttempts[moduleName] = found
            return found
        end
    end
    
    -- Module not found
    ModuleLoader.log("Module not found: " .. moduleName, true)
    moduleLoadAttempts[moduleName] = nil
    return nil
end

-- Recursively search for a module in a path
function ModuleLoader.deepSearchModule(parent, moduleName)
    if not parent then return nil end
    
    -- Check if this is the module we're looking for
    if parent:IsA("ModuleScript") and parent.Name == moduleName then
        return parent
    end
    
    -- Search children
    for _, child in pairs(parent:GetChildren()) do
        local found = ModuleLoader.deepSearchModule(child, moduleName)
        if found then
            return found
        end
    end
    
    return nil
end

-- Require a module by name
function ModuleLoader.requireModule(moduleName, isOptional)
    -- If already loaded, return from cache
    if loadedModules[moduleName] then
        ModuleLoader.log("Loading module from cache: " .. moduleName, true)
        return loadedModules[moduleName]
    end
    
    ModuleLoader.log("Requiring module: " .. moduleName)
    
    -- Find the module
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        if isOptional then
            ModuleLoader.log("Optional module not found: " .. moduleName)
            return nil
        else
            warn("[ModuleLoader] Cannot require module (not found): " .. moduleName)
            return nil
        end
    end
    
    -- Require the module
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        ModuleLoader.log("Successfully loaded module: " .. moduleName)
        loadedModules[moduleName] = result
        return result
    else
        if isOptional then
            ModuleLoader.log("Failed to load optional module: " .. moduleName .. " - " .. tostring(result))
            return nil
        else
            warn("[ModuleLoader] Failed to require module: " .. moduleName .. " - " .. tostring(result))
            return nil
        end
    end
end

-- Get a module instance without requiring it
function ModuleLoader.getModuleInstance(moduleName)
    return ModuleLoader.findModule(moduleName)
end

-- Try to require a module, but don't throw an error if it fails
function ModuleLoader.tryRequire(moduleName)
    return ModuleLoader.requireModule(moduleName, true)
end

-- Preload a set of modules
function ModuleLoader.preloadModules(moduleNames)
    for _, moduleName in ipairs(moduleNames) do
        ModuleLoader.requireModule(moduleName, true)
    end
    
    ModuleLoader.log("Preloaded " .. #moduleNames .. " modules")
end

-- Add the core paths that should always be available
function ModuleLoader.addCorePaths()
    -- Add shared folders with different casing
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then ModuleLoader.addSearchPath(shared) end
    
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    if Shared and Shared ~= shared then ModuleLoader.addSearchPath(Shared) end
    
    -- Add client folders (if client)
    if IsClient then
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        if LocalPlayer then
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") then
                ModuleLoader.addSearchPath(LocalPlayer.PlayerScripts.Client)
            end
            
            if LocalPlayer.PlayerScripts:FindFirstChild("client") then
                ModuleLoader.addSearchPath(LocalPlayer.PlayerScripts.client)
            end
        end
    end
    
    -- Add server folders (if server)
    if IsServer then
        local ServerScriptService = game:GetService("ServerScriptService")
        
        if ServerScriptService:FindFirstChild("Server") then
            ModuleLoader.addSearchPath(ServerScriptService.Server)
        end
        
        if ServerScriptService:FindFirstChild("server") then
            ModuleLoader.addSearchPath(ServerScriptService.server)
        end
        
        -- Also add ServerStorage paths
        local ServerStorage = game:GetService("ServerStorage")
        
        if ServerStorage:FindFirstChild("Server") then
            ModuleLoader.addSearchPath(ServerStorage.Server)
        end
        
        if ServerStorage:FindFirstChild("server") then
            ModuleLoader.addSearchPath(ServerStorage.server)
        end
    end
end

-- Initialize the module loader
function ModuleLoader.initialize()
    ModuleLoader.log("Initializing ModuleLoader")
    ModuleLoader.addCorePaths()
    return ModuleLoader
end

return ModuleLoader
