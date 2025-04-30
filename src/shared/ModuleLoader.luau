--[[
    ModuleLoader.luau
    
    Advanced module loading system with dependency management.
    This module provides tools for safe module loading, dependency resolution,
    and circular dependency detection.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    CACHE_ENABLED = true,
    DETECT_CIRCULAR_DEPENDENCIES = true,
    MAX_REQUIRE_DEPTH = 50,
    CACHE_STATS_ENABLED = true
}

-- Module cache and tracking
local moduleCache = {}
local requireCount = {}
local loadTimes = {}
local requireStack = {}
local currentDepth = 0

-- Log function with configurable debug mode
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[ModuleLoader] " .. message)
    end
end

-- Try to get CoreRegistry if available
local function getCoreRegistry()
    -- Try shared.ModuleScriptAccessor first
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor then
            local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
            if CoreRegistry then
                return CoreRegistry
            end
        end
    end
    
    -- Try direct paths
    local paths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(paths) do
        if path then
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

-- Find a module in the workspace
function ModuleLoader.findModule(moduleName)
    -- Define search paths based on context
    local searchPaths = {}
    
    if RunService:IsServer() then
        -- Server-side search paths
        table.insert(searchPaths, ServerScriptService:FindFirstChild("Core"))
        table.insert(searchPaths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"))
        table.insert(searchPaths, ServerScriptService:FindFirstChild("Systems"))
        table.insert(searchPaths, ServerScriptService)
    end
    
    -- Common search paths for both server and client
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("shared"))
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"))
    table.insert(searchPaths, ReplicatedStorage)
    
    -- Try to find the module
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

-- Safe require with circular dependency detection and caching
function ModuleLoader.safeRequire(moduleScript, ignoreCache)
    if not moduleScript then
        return nil
    end
    
    local moduleName = moduleScript:GetFullName()
    
    -- Check for circular dependencies
    if CONFIG.DETECT_CIRCULAR_DEPENDENCIES then
        for _, module in ipairs(requireStack) do
            if module == moduleName then
                warn("[ModuleLoader] Circular dependency detected for module: " .. moduleName)
                warn("[ModuleLoader] Require stack: " .. table.concat(requireStack, " -> ") .. " -> " .. moduleName)
                return {}
            end
        end
    end
    
    -- Check cache if enabled
    if CONFIG.CACHE_ENABLED and not ignoreCache and moduleCache[moduleName] then
        if CONFIG.CACHE_STATS_ENABLED then
            requireCount[moduleName] = (requireCount[moduleName] or 0) + 1
        end
        return moduleCache[moduleName]
    end
    
    -- Check for max depth
    if currentDepth >= CONFIG.MAX_REQUIRE_DEPTH then
        warn("[ModuleLoader] Maximum require depth reached for module: " .. moduleName)
        return {}
    end
    
    -- Track require stack
    currentDepth += 1
    table.insert(requireStack, moduleName)
    
    -- Measure load time
    local startTime = os.clock()
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    local endTime = os.clock()
    local loadTime = endTime - startTime
    
    -- Update stats if enabled
    if CONFIG.CACHE_STATS_ENABLED then
        loadTimes[moduleName] = loadTime
        requireCount[moduleName] = (requireCount[moduleName] or 0) + 1
    end
    
    -- Clean up stack
    table.remove(requireStack)
    currentDepth -= 1
    
    -- Handle result
    if success then
        -- Cache the result if caching is enabled
        if CONFIG.CACHE_ENABLED and not ignoreCache then
            moduleCache[moduleName] = result
        end
        return result
    else
        warn("[ModuleLoader] Failed to require module " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Require a module by name
function ModuleLoader.requireByName(moduleName, ignoreCache)
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        warn("[ModuleLoader] Module not found: " .. moduleName)
        return nil
    end
    
    return ModuleLoader.safeRequire(moduleScript, ignoreCache)
end

-- Clear the module cache entirely or for a specific module
function ModuleLoader.clearCache(moduleName)
    if moduleName then
        moduleCache[moduleName] = nil
        log("Cache cleared for module: " .. moduleName)
    else
        moduleCache = {}
        log("Entire module cache cleared")
    end
end

-- Get cache statistics
function ModuleLoader.getCacheStats()
    if not CONFIG.CACHE_STATS_ENABLED then
        return {
            cacheEnabled = CONFIG.CACHE_ENABLED,
            statsEnabled = false,
            cacheSize = 0,
            modules = {}
        }
    end
    
    local modules = {}
    local totalRequireCount = 0
    
    for name, count in pairs(requireCount) do
        totalRequireCount += count
        table.insert(modules, {
            name = name,
            requireCount = count,
            loadTime = loadTimes[name] or 0,
            cached = moduleCache[name] ~= nil
        })
    end
    
    -- Sort by require count
    table.sort(modules, function(a, b)
        return a.requireCount > b.requireCount
    end)
      -- Count number of items in moduleCache
    local cacheSize = 0
    for _ in pairs(moduleCache) do
        cacheSize += 1
    end
    
    return {
        cacheEnabled = CONFIG.CACHE_ENABLED,
        statsEnabled = true,
        cacheSize = cacheSize,
        totalRequireCount = totalRequireCount,
        modules = modules
    }
end

-- Initialize the module
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
        log("CoreRegistry not available, working in standalone mode")
    end
    
    ModuleLoader.initialized = true
    log("ModuleLoader initialized")
    
    return true
end

-- Initialize on load
ModuleLoader.initialize()

return ModuleLoader
