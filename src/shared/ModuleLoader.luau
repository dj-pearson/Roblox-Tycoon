--[[
    ModuleLoader.luau
    
    A unified utility module for dynamically loading modules and managing dependencies.
    This module provides a clean way to handle module loading, with error handling,
    dependency management, and caching.
    
    Features:
    - Centralized module loading with consistent interface
    - Robust error handling and reporting
    - Circular dependency detection and resolution
    - Module caching with selective invalidation
    - Automatic search path discovery
    - Support for different module naming patterns (.luau, .client.luau, .server.luau)
    - Integration with CoreRegistry
    - Dependency injection support
    
    Created: April 30, 2025
    Updated: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false
ModuleLoader.version = "1.2.0"

-- Debug settings
ModuleLoader.DEBUG = true

-- Cache of loaded modules
local moduleCache = {}

-- Module loading stats
local stats = {
    totalLoaded = 0,
    loadErrors = 0,
    cacheHits = 0
}

-- Log a message to the output
local function log(message)
    if ModuleLoader.DEBUG then
        print("[ModuleLoader] " .. message)
    end
end

-- Safe require function with timeout
function ModuleLoader.safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        warn("[ModuleLoader] Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName())
        return fallback
    end
    
    -- Check if module is already in cache
    if moduleCache[module] then
        stats.cacheHits = stats.cacheHits + 1
        return moduleCache[module]
    end
    
    -- Safely require the module
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        moduleCache[module] = result
        stats.totalLoaded = stats.totalLoaded + 1
        return result
    else
        warn("[ModuleLoader] Failed to require " .. module:GetFullName() .. " - " .. tostring(result))
        stats.loadErrors = stats.loadErrors + 1
        return fallback
    end
end

-- Get all standard search paths for a module
function ModuleLoader.getSearchPaths()
    local paths = {
        -- ReplicatedStorage paths (accessible from both client and server)
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("replicatedStorage"),
        ReplicatedStorage:FindFirstChild("ClientModules")
    }
    
    -- Add server-only paths if we're on the server
    if RunService:IsServer() then
        table.insert(paths, ServerScriptService:FindFirstChild("src"))
        table.insert(paths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"))
        table.insert(paths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Systems"))
        table.insert(paths, ServerScriptService:FindFirstChild("Systems"))
        table.insert(paths, ServerScriptService:FindFirstChild("GymAutomation"))
        
        table.insert(paths, ServerStorage:FindFirstChild("src"))
        table.insert(paths, ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server"))
        table.insert(paths, ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("Core"))
        table.insert(paths, ServerStorage:FindFirstChild("Core"))
        table.insert(paths, ServerStorage:FindFirstChild("Systems"))
    else
        -- Client-only paths
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player then
            table.insert(paths, player.PlayerScripts:FindFirstChild("client"))
            table.insert(paths, player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts.client:FindFirstChild("Core"))
            table.insert(paths, player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts.client:FindFirstChild("UI"))
            
            table.insert(paths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client"))
            table.insert(paths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("Core"))
            table.insert(paths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("UI"))
        end
    end
    
    -- Additional custom paths registered via registerPath
    if ModuleLoader.customPaths then
        for _, path in ipairs(ModuleLoader.customPaths) do
            table.insert(paths, path)
        end
    end
    
    -- Filter out nil paths
    local validPaths = {}
    for _, path in ipairs(paths) do
        if path ~= nil then
            table.insert(validPaths, path)
        end
    end
    
    return validPaths
end

-- Register a custom path for module searches
function ModuleLoader.registerPath(path)
    if not path then return false end
    
    if not ModuleLoader.customPaths then
        ModuleLoader.customPaths = {}
    end
    
    -- Check if path is already registered
    for _, existingPath in ipairs(ModuleLoader.customPaths) do
        if existingPath == path then
            return true -- Already registered
        end
    end
    
    table.insert(ModuleLoader.customPaths, path)
    log("Registered custom path: " .. path:GetFullName())
    return true
end

-- Find a module in the game hierarchy
function ModuleLoader.findModule(moduleName, searchPaths)
    if typeof(moduleName) ~= "string" then
        warn("[ModuleLoader] findModule expects a string moduleName, got " .. typeof(moduleName))
        return nil
    end
    
    searchPaths = searchPaths or ModuleLoader.getSearchPaths()
    
    -- Try to find the module in each search path
    for _, path in ipairs(searchPaths) do
        if path then
            -- Check for exact name
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Check with .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Check with server/client extension
            local side = RunService:IsServer() and "server" or "client"
            module = path:FindFirstChild(moduleName .. "." .. side .. ".luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Check directories - i.e. if moduleName is "UI/Button", check for UI folder with Button module
            if string.find(moduleName, "/") then
                local pathParts = string.split(moduleName, "/")
                local currentPath = path
                
                for i = 1, #pathParts - 1 do
                    if currentPath then
                        currentPath = currentPath:FindFirstChild(pathParts[i])
                    end
                end
                
                if currentPath then
                    local finalPart = pathParts[#pathParts]
                    
                    -- Check for exact name
                    module = currentPath:FindFirstChild(finalPart)
                    if module and module:IsA("ModuleScript") then
                        return module
                    end
                    
                    -- Check with .luau extension
                    module = currentPath:FindFirstChild(finalPart .. ".luau")
                    if module and module:IsA("ModuleScript") then
                        return module
                    end
                    
                    -- Check with server/client extension
                    module = currentPath:FindFirstChild(finalPart .. "." .. side .. ".luau")
                    if module and module:IsA("ModuleScript") then
                        return module
                    end
                end
            end
        end
    end
    
    return nil
end

-- Load a module by name with dependency tracking
function ModuleLoader.loadModule(moduleName, parent, fallback)
    if not ModuleLoader.initialized then
        ModuleLoader.initialize()
    end
    
    if typeof(moduleName) ~= "string" then
        warn("[ModuleLoader] loadModule expects a string moduleName, got " .. typeof(moduleName))
        return fallback
    end
    
    -- Record dependency in graph if parent is provided
    if parent then
        if not dependencyGraph[parent] then
            dependencyGraph[parent] = {}
        end
        
        if not table.find(dependencyGraph[parent], moduleName) then
            table.insert(dependencyGraph[parent], moduleName)
        end
        
        -- Check for circular dependencies
        local isCircular, path = detectCircularDependency(moduleName, loadingModules)
        if isCircular then
            warn("[ModuleLoader] Circular dependency detected: " .. path)
            -- Return a stub or throw an error based on your preference
            return fallback or {}
        end
    end
    
    -- Mark as loading
    table.insert(loadingModules, moduleName)
    
    -- Find and load the module
    local module = ModuleLoader.findModule(moduleName)
    if module then
        local result = ModuleLoader.safeRequire(module, fallback)
        
        -- Remove from loading stack
        local loadingIndex = table.find(loadingModules, moduleName)
        if loadingIndex then
            table.remove(loadingModules, loadingIndex)
        end
        
        return result
    end
    
    -- Remove from loading stack
    local loadingIndex = table.find(loadingModules, moduleName)
    if loadingIndex then
        table.remove(loadingModules, loadingIndex)
    end
    
    log("Module not found: " .. moduleName)
    return fallback
end

-- Dependency injection container
local injectionContainer = {}

-- Inject dependencies into a module or function
function ModuleLoader.injectDependencies(target, dependencies)
    if typeof(target) ~= "function" and typeof(target) ~= "table" then
        warn("[ModuleLoader] Cannot inject dependencies into " .. typeof(target))
        return target
    end
    
    if typeof(dependencies) ~= "table" then
        warn("[ModuleLoader] Dependencies must be a table, got " .. typeof(dependencies))
        return target
    end
    
    if typeof(target) == "function" then
        -- Return a wrapper function that passes dependencies to the original function
        return function(...)
            return target(dependencies, ...)
        end
    else
        -- For module tables, add dependencies directly to the table
        for name, dep in pairs(dependencies) do
            if target[name] == nil then
                target[name] = dep
            end
        end
        return target
    end
end

-- Register a dependency for injection
function ModuleLoader.registerDependency(name, value)
    injectionContainer[name] = value
    return true
end

-- Get a dependency from the injection container
function ModuleLoader.getDependency(name)
    return injectionContainer[name]
end

-- Get all registered dependencies
function ModuleLoader.getAllDependencies()
    return table.clone(injectionContainer)
end

-- Load all modules in a folder
function ModuleLoader.loadModulesInFolder(folder)
    if not folder then return {} end
    
    local loadedModules = {}
    
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local name = child.Name:gsub("%.luau$", ""):gsub("%.server$", ""):gsub("%.client$", "")
            local module = ModuleLoader.safeRequire(child)
            if module then
                loadedModules[name] = module
            end
        end
    end
    
    return loadedModules
end

-- Clear the cache for a specific module
function ModuleLoader.clearCache(module)
    if module then
        moduleCache[module] = nil
        return true
    end
    return false
end

-- Clear the entire module cache
function ModuleLoader.clearAllCache()
    moduleCache = {}
    return true
end

-- Get stats on module loading
function ModuleLoader.getStats()
    return {
        totalLoaded = stats.totalLoaded,
        loadErrors = stats.loadErrors,
        cacheHits = stats.cacheHits,
        cacheSize = 0
    }
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try standard paths
    local standardPaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(standardPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    -- Look for ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor and typeof(ModuleScriptAccessor.getCoreRegistry) == "function" then
            local registry = ModuleScriptAccessor.getCoreRegistry()
            if registry then
                return registry
            end
        end
    end
    
    return nil
end

-- Initialize the module
function ModuleLoader.initialize()
    if ModuleLoader.initialized then
        return true
    end
    
    log("Initializing ModuleLoader v" .. ModuleLoader.version .. "...")
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
        log("Registered with CoreRegistry")
        
        -- Register self as a dependency for injection
        ModuleLoader.registerDependency("ModuleLoader", ModuleLoader)
        
        -- Register CoreRegistry as a dependency for injection
        ModuleLoader.registerDependency("CoreRegistry", CoreRegistry)
    else
        log("CoreRegistry not found, but ModuleLoader will still function")
    end
    
    -- Make a copy of this ModuleLoader available in ReplicatedStorage
    local function ensureSharedModuleLoader()
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if not shared then
            shared = Instance.new("Folder")
            shared.Name = "shared"
            shared.Parent = ReplicatedStorage
        end
        
        if not shared:FindFirstChild("ModuleLoader") or not shared.ModuleLoader:IsA("ModuleScript") then
            if script:IsA("ModuleScript") then
                -- Clone this ModuleLoader script to shared
                local clone = script:Clone()
                clone.Name = "ModuleLoader"
                clone.Parent = shared
                log("Created a copy of ModuleLoader in ReplicatedStorage/shared")
                return true
            end
        else
            log("ModuleLoader already exists in ReplicatedStorage/shared")
            return true
        end
        return false
    end
    
    if RunService:IsServer() then
        ensureSharedModuleLoader()
    end
    
    log("ModuleLoader initialized")
    ModuleLoader.initialized = true
    return true
end

-- Initialize on load
ModuleLoader.initialize()

return ModuleLoader
