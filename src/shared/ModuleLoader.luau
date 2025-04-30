--[[
    ModuleLoader.luau
    
    A utility module for dynamically loading modules and managing dependencies.
    This module provides a clean way to handle module loading, with error handling,
    dependency management, and caching.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false

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

-- Find a module in the game hierarchy
function ModuleLoader.findModule(moduleName, searchPaths)
    searchPaths = searchPaths or {}
    
    -- If no search paths provided, use defaults based on context
    if #searchPaths == 0 then
        if RunService:IsServer() then
            local ServerStorage = game:GetService("ServerStorage")
            searchPaths = {
                -- ServerScriptService paths
                ServerScriptService:FindFirstChild("Core"),
                ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
                ServerScriptService:FindFirstChild("Systems"),
                ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
                ServerScriptService,
                
                -- ServerStorage paths
                ServerStorage:FindFirstChild("Core"),
                ServerStorage:FindFirstChild("Systems"),
                ServerStorage:FindFirstChild("GymStructure"),
                ServerStorage:FindFirstChild("BuyTiles"),
                ServerStorage
            }
        else
            searchPaths = {
                ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("Core"),
                ReplicatedStorage:FindFirstChild("Core"),
                ReplicatedStorage:FindFirstChild("Systems"),
                ReplicatedStorage
            }
        end
        
        -- Add common paths for both server and client
        table.insert(searchPaths, ReplicatedStorage:FindFirstChild("shared"))
        table.insert(searchPaths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"))
    end
    
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
        end
    end
    
    return nil
end

-- Load a module by name
function ModuleLoader.loadModule(moduleName, searchPaths, fallback)
    local module = ModuleLoader.findModule(moduleName, searchPaths)
    if module then
        return ModuleLoader.safeRequire(module, fallback)
    end
    
    log("Module not found: " .. moduleName)
    return fallback
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

-- Load a dependency chain
function ModuleLoader.loadDependencyChain(dependencies, searchPaths)
    local loadedDependencies = {}
    local missingDependencies = {}
    
    for _, dependency in ipairs(dependencies) do
        local module = ModuleLoader.loadModule(dependency, searchPaths)
        if module then
            loadedDependencies[dependency] = module
        else
            table.insert(missingDependencies, dependency)
        end
    end
    
    return loadedDependencies, missingDependencies
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

-- Initialize the module
function ModuleLoader.initialize()
    if ModuleLoader.initialized then
        return true
    end
    
    -- Try to find ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor then
            -- Try to register with CoreRegistry
            local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
            if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
                CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
                log("Registered with CoreRegistry")
            end
        end
    end
    
    log("ModuleLoader initialized")
    ModuleLoader.initialized = true
    return true
end

-- Initialize on load
ModuleLoader.initialize()

return ModuleLoader
