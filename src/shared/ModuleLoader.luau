--[[
    ModuleLoader.luau
    
    Provides robust module loading functionality with dependency management.
    This module helps prevent circular dependencies and safely loads modules.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false

-- Debug settings
ModuleLoader.DEBUG = true

-- Module cache
local moduleCache = {}

-- Currently loading modules (to detect circular dependencies)
local loadingModules = {}

-- Log a message to the output
local function log(message)
    if ModuleLoader.DEBUG then
        print("[ModuleLoader] " .. message)
    end
end

-- Safe require function with circular dependency detection
function ModuleLoader.require(moduleScript)
    if not moduleScript then
        warn("[ModuleLoader] Cannot require nil module")
        return nil
    end
    
    if not moduleScript:IsA("ModuleScript") then
        warn("[ModuleLoader] Cannot require non-ModuleScript: " .. moduleScript:GetFullName())
        return nil
    end
    
    -- Check cache first
    local moduleId = moduleScript:GetFullName()
    if moduleCache[moduleId] then
        return moduleCache[moduleId]
    end
    
    -- Check for circular dependencies
    if loadingModules[moduleId] then
        warn("[ModuleLoader] Circular dependency detected when requiring: " .. moduleId)
        
        -- Print dependency chain
        local chain = "Dependency chain: "
        for module, _ in pairs(loadingModules) do
            chain = chain .. module .. " -> "
        end
        chain = chain .. moduleId
        warn(chain)
        
        return nil
    end
    
    -- Mark as loading
    loadingModules[moduleId] = true
    
    -- Require the module
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    -- Clear loading marker
    loadingModules[moduleId] = nil
    
    if success then
        -- Cache the result
        moduleCache[moduleId] = result
        return result
    else
        warn("[ModuleLoader] Failed to require " .. moduleId .. ": " .. tostring(result))
        return nil
    end
end

-- Find a module in various locations
function ModuleLoader.findModule(moduleName)
    -- Define search paths
    local searchPaths = {}
    
    -- Server-specific paths
    if RunService:IsServer() then
        table.insert(searchPaths, ServerScriptService:FindFirstChild("Core"))
        table.insert(searchPaths, ServerScriptService:FindFirstChild("Systems"))
        table.insert(searchPaths, ServerScriptService:FindFirstChild("src") and 
                   ServerScriptService.src:FindFirstChild("server") and 
                   ServerScriptService.src.server:FindFirstChild("Core"))
        table.insert(searchPaths, ServerScriptService)
    end
    
    -- Common paths for client and server
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("Core"))
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("Systems"))
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("src") and 
               ReplicatedStorage.src:FindFirstChild("shared"))
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("shared"))
    table.insert(searchPaths, ReplicatedStorage)
    
    -- Filter out nil paths
    local validPaths = {}
    for _, path in ipairs(searchPaths) do
        if path then
            table.insert(validPaths, path)
        end
    end
    
    -- Try to find the module
    for _, path in ipairs(validPaths) do
        -- Try exact name
        local moduleScript = path:FindFirstChild(moduleName)
        if moduleScript and moduleScript:IsA("ModuleScript") then
            return moduleScript
        end
        
        -- Try with .luau extension
        moduleScript = path:FindFirstChild(moduleName .. ".luau")
        if moduleScript and moduleScript:IsA("ModuleScript") then
            return moduleScript
        end
        
        -- Try with server/client extension
        local side = RunService:IsServer() and "server" or "client"
        moduleScript = path:FindFirstChild(moduleName .. "." .. side .. ".luau")
        if moduleScript and moduleScript:IsA("ModuleScript") then
            return moduleScript
        end
    end
    
    return nil
end

-- Require a module by name
function ModuleLoader.requireByName(moduleName)
    local moduleScript = ModuleLoader.findModule(moduleName)
    
    if not moduleScript then
        warn("[ModuleLoader] Could not find module: " .. moduleName)
        return nil
    end
    
    return ModuleLoader.require(moduleScript)
end

-- Clear the module cache
function ModuleLoader.clearCache()
    moduleCache = {}
    log("Module cache cleared")
end

-- Get cache statistics
function ModuleLoader.getCacheStats()
    local count = 0
    for _ in pairs(moduleCache) do
        count += 1
    end
    
    return {
        cachedModules = count
    }
end

-- Initialize the module loader
function ModuleLoader.initialize()
    if ModuleLoader.initialized then
        return true
    end
    
    -- Try to register with CoreRegistry
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor then
            local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
            if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
                CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
                log("Registered with CoreRegistry")
            end
        end
    end
    
    ModuleLoader.initialized = true
    log("ModuleLoader initialized")
    return true
end

-- Initialize on load
ModuleLoader.initialize()

return ModuleLoader
