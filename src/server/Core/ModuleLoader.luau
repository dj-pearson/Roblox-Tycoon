--[[
    ModuleLoader.luau
    
    Core system for dynamic module loading and dependency management.
    This module handles loading, caching, and resolving dependencies for modules.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false

-- Debug settings
ModuleLoader.DEBUG = true

-- Log a message to the output
local function log(message)
    if ModuleLoader.DEBUG then
        print("[ModuleLoader] " .. message)
    end
end

-- Cache of loaded modules
local moduleCache = {}

-- Dependency graph for circular dependency detection
local dependencyGraph = {}

-- Module loading in progress tracker (for circular dependency detection)
local loadingModules = {}

-- Get the CoreRegistry if available
local function getCoreRegistry()
    -- Try standard paths
    local standardPaths = {
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
    
    return nil
end

-- Initialize the ModuleLoader
function ModuleLoader.initialize()
    if ModuleLoader.initialized then
        return true
    end
    
    log("Initializing ModuleLoader...")
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
        log("Registered with CoreRegistry")
    else
        log("CoreRegistry not found, but ModuleLoader will still function")
    end
    
    ModuleLoader.initialized = true
    log("ModuleLoader initialized")
    
    return true
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

-- Find a module by name in the standard paths
function ModuleLoader.findModule(moduleName)
    -- Check cache first
    if moduleCache[moduleName] and moduleCache[moduleName].instance then
        return moduleCache[moduleName].instance
    end
    
    local searchPaths = ModuleLoader.getSearchPaths()
    
    for _, path in ipairs(searchPaths) do
        -- Direct match
        local module = path:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            log("Found module " .. moduleName .. " at: " .. module:GetFullName())
            
            -- Cache the module instance
            moduleCache[moduleName] = {
                instance = module,
                loaded = false,
                exports = nil
            }
            
            return module
        end
        
        -- With .luau extension
        module = path:FindFirstChild(moduleName .. ".luau")
        if module and module:IsA("ModuleScript") then
            log("Found module " .. moduleName .. ".luau at: " .. module:GetFullName())
            
            moduleCache[moduleName] = {
                instance = module,
                loaded = false,
                exports = nil
            }
            
            return module
        end
        
        -- With .server.luau extension (server-side only)
        if RunService:IsServer() then
            module = path:FindFirstChild(moduleName .. ".server.luau")
            if module and module:IsA("ModuleScript") then
                log("Found module " .. moduleName .. ".server.luau at: " .. module:GetFullName())
                
                moduleCache[moduleName] = {
                    instance = module,
                    loaded = false,
                    exports = nil
                }
                
                return module
            end
        end
        
        -- With .client.luau extension (client-side only)
        if not RunService:IsServer() then
            module = path:FindFirstChild(moduleName .. ".client.luau")
            if module and module:IsA("ModuleScript") then
                log("Found module " .. moduleName .. ".client.luau at: " .. module:GetFullName())
                
                moduleCache[moduleName] = {
                    instance = module,
                    loaded = false,
                    exports = nil
                }
                
                return module
            end
        end
    end
    
    log("Could not find module: " .. moduleName)
    return nil
end

-- Check for circular dependencies
local function detectCircularDependency(moduleName, dependencyChain)
    dependencyChain = dependencyChain or {}
    
    if table.find(dependencyChain, moduleName) then
        local circularPath = ""
        local startIndex = table.find(dependencyChain, moduleName)
        for i = startIndex, #dependencyChain do
            circularPath = circularPath .. dependencyChain[i] .. " -> "
        end
        circularPath = circularPath .. moduleName
        
        return true, circularPath
    end
    
    return false, nil
end

-- Load a module with dependency management
function ModuleLoader.requireModule(moduleName, parent)
    if not ModuleLoader.initialized then
        ModuleLoader.initialize()
    end
    
    -- Check cache first
    if moduleCache[moduleName] and moduleCache[moduleName].loaded then
        return moduleCache[moduleName].exports
    end
    
    -- Record dependency
    if parent then
        if not dependencyGraph[parent] then
            dependencyGraph[parent] = {}
        end
        table.insert(dependencyGraph[parent], moduleName)
        
        -- Check for circular dependencies
        local isCircular, path = detectCircularDependency(moduleName, loadingModules)
        if isCircular then
            warn("[ModuleLoader] Circular dependency detected: " .. path)
            -- Return a stub or throw an error based on your preference
            return {}
        end
    end
    
    -- Mark as loading
    table.insert(loadingModules, moduleName)
    
    -- Find the module
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        table.remove(loadingModules, table.find(loadingModules, moduleName))
        return nil
    end
    
    -- Check if already in cache but not loaded (partially loaded)
    if moduleCache[moduleName] and not moduleCache[moduleName].loaded then
        log("Module " .. moduleName .. " is currently loading, possible circular dependency")
        table.remove(loadingModules, table.find(loadingModules, moduleName))
        return {}
    end
    
    -- Require the module
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    -- Un-mark as loading
    table.remove(loadingModules, table.find(loadingModules, moduleName))
    
    if success then
        -- Cache the result
        if moduleCache[moduleName] then
            moduleCache[moduleName].loaded = true
            moduleCache[moduleName].exports = result
        else
            moduleCache[moduleName] = {
                instance = moduleScript,
                loaded = true,
                exports = result
            }
        end
        
        return result
    else
        warn("[ModuleLoader] Failed to require " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Get a module from CoreRegistry or load it if not found
function ModuleLoader.getModule(moduleName)
    -- Try CoreRegistry first
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.getSystem) == "function" then
        local system = CoreRegistry.getSystem(moduleName)
        if system then
            return system
        end
    end
    
    -- Fall back to direct require
    return ModuleLoader.requireModule(moduleName)
end

-- Clear the module cache
function ModuleLoader.clearCache(moduleName)
    if moduleName then
        moduleCache[moduleName] = nil
        log("Cleared cache for module: " .. moduleName)
    else
        moduleCache = {}
        log("Cleared entire module cache")
    end
end

-- Get dependency graph for a module
function ModuleLoader.getDependencies(moduleName)
    return dependencyGraph[moduleName] or {}
end

-- Initialize the ModuleLoader
ModuleLoader.initialize()

return ModuleLoader
