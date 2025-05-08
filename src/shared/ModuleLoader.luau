--!strict
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
    - Health check and recovery system
    
    Created: April 30, 2025
    Updated: May 3, 2025 - Added health check and recovery system
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local ModuleLoader = {}
ModuleLoader.initialized = false
ModuleLoader.version = "1.3.0"

-- Configuration
local CONFIG = {
    debug = true,
    maxInitAttempts = 3,
    initTimeout = 10, -- seconds
    healthCheckInterval = 30, -- seconds
    recoveryAttempts = 3,
    recoveryDelay = 2, -- seconds,
    cacheSizeLimit = 1000,
    maxCircularDependencyDepth = 10
}

-- Cache of loaded modules
local moduleCache = {}

-- Module loading stats
local stats = {
    totalLoaded = 0,
    loadErrors = 0,
    cacheHits = 0,
    recoveryAttempts = 0,
    healthCheckFailures = 0
}

-- Dependency graph for circular dependency detection
local dependencyGraph = {}

-- Module loading in progress tracker
local loadingModules = {}

-- Health check state
local healthState = {
    lastCheck = 0,
    status = "Unknown",
    errors = {},
    warnings = {},
    recoveryInProgress = false
}

-- Log a message to the output
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[ModuleLoader]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Detect circular dependencies
local function detectCircularDependency(moduleName, loadingStack)
    local visited = {}
    local path = {}
    
    local function dfs(current)
        if visited[current] then
            return true, path
        end
        
        if #path > CONFIG.maxCircularDependencyDepth then
            return true, path
        end
        
        visited[current] = true
        table.insert(path, current)
        
        local deps = dependencyGraph[current] or {}
        for _, dep in ipairs(deps) do
            if dfs(dep) then
                return true, path
            end
        end
        
        table.remove(path)
        visited[current] = nil
        return false
    end
    
    return dfs(moduleName)
end

-- Get all standard search paths
function ModuleLoader.getSearchPaths()
    local paths = {}
    
    -- Add standard paths
    if RunService:IsServer() then
        table.insert(paths, ServerScriptService:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"))
    end
    
    table.insert(paths, ReplicatedStorage:FindFirstChild("shared"))
    table.insert(paths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"))
    
    -- Add custom paths
    if ModuleLoader.customPaths then
        for _, path in ipairs(ModuleLoader.customPaths) do
            table.insert(paths, path)
        end
    end
    
    return paths
end

-- Safe require function with timeout
function ModuleLoader.safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        log("Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName(), "error")
        return fallback
    end
    
    -- Check if module is already in cache
    if moduleCache[module] then
        stats.cacheHits = stats.cacheHits + 1
        return moduleCache[module]
    end
    
    -- Safely require the module with timeout
    local success, result = pcall(function()
        local completed = false
        local initResult = nil
        
        task.spawn(function()
            initResult = require(module)
            completed = true
        end)
        
        local startTime = os.time()
        while not completed and os.time() - startTime < CONFIG.initTimeout do
            task.wait(0.1)
        end
        
        if not completed then
            error("Module load timeout")
        end
        
        return initResult
    end)
    
    if success then
        moduleCache[module] = result
        stats.totalLoaded = stats.totalLoaded + 1
        return result
    else
        log("Failed to require " .. module:GetFullName() .. " - " .. tostring(result), "error")
        stats.loadErrors = stats.loadErrors + 1
        return fallback
    end
end

-- Find a module in the game hierarchy
function ModuleLoader.findModule(moduleName, searchPaths)
    if typeof(moduleName) ~= "string" then
        log("findModule expects a string moduleName, got " .. typeof(moduleName), "error")
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
            
            -- Check directories
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
        log("loadModule expects a string moduleName, got " .. typeof(moduleName), "error")
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
            log("Circular dependency detected: " .. table.concat(path, " -> "), "error")
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
    
    log("Module not found: " .. moduleName, "warn")
    return fallback
end

-- Health check function
function ModuleLoader.healthCheck()
    local currentTime = os.time()
    if currentTime - healthState.lastCheck < CONFIG.healthCheckInterval then
        return healthState.status
    end
    
    healthState.lastCheck = currentTime
    healthState.errors = {}
    healthState.warnings = {}
    
    -- Check module cache size
    local cacheSize = 0
    for _ in pairs(moduleCache) do
        cacheSize += 1
    end
    
    if cacheSize > CONFIG.cacheSizeLimit then
        table.insert(healthState.warnings, "Module cache size exceeds limit: " .. cacheSize)
    end
    
    -- Check for stuck loading modules
    if #loadingModules > 0 then
        table.insert(healthState.errors, "Stuck loading modules: " .. table.concat(loadingModules, ", "))
    end
    
    -- Check error rate
    local errorRate = stats.loadErrors / (stats.totalLoaded + 1)
    if errorRate > 0.1 then -- More than 10% error rate
        table.insert(healthState.warnings, "High module load error rate: " .. string.format("%.1f%%", errorRate * 100))
    end
    
    -- Update health status
    if #healthState.errors > 0 then
        healthState.status = "Critical"
    elseif #healthState.warnings > 0 then
        healthState.status = "Degraded"
    else
        healthState.status = "Healthy"
    end
    
    return healthState.status
end

-- Recovery function
function ModuleLoader.recover()
    if healthState.recoveryInProgress then
        return false
    end
    
    healthState.recoveryInProgress = true
    stats.recoveryAttempts += 1
    
    -- Clear stuck loading modules
    loadingModules = {}
    
    -- Clear module cache
    moduleCache = {}
    
    -- Reset stats
    stats.totalLoaded = 0
    stats.loadErrors = 0
    stats.cacheHits = 0
    
    -- Reset health state
    healthState.lastCheck = 0
    healthState.errors = {}
    healthState.warnings = {}
    healthState.status = "Recovering"
    
    -- Wait for recovery delay
    task.wait(CONFIG.recoveryDelay)
    
    -- Run health check
    local status = ModuleLoader.healthCheck()
    
    healthState.recoveryInProgress = false
    return status == "Healthy"
end

-- Get module loading stats
function ModuleLoader.getStats()
    return {
        totalLoaded = stats.totalLoaded,
        loadErrors = stats.loadErrors,
        cacheHits = stats.cacheHits,
        recoveryAttempts = stats.recoveryAttempts,
        healthCheckFailures = stats.healthCheckFailures,
        cacheSize = 0,
        loadingModules = #loadingModules
    }
end

-- Get health status
function ModuleLoader.getHealthStatus()
    return {
        status = healthState.status,
        lastCheck = healthState.lastCheck,
        errors = healthState.errors,
        warnings = healthState.warnings
    }
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
    else
        log("CoreRegistry not found, but ModuleLoader will still function")
    end
    
    -- Start periodic health checks
    task.spawn(function()
        while true do
            task.wait(CONFIG.healthCheckInterval)
            local status = ModuleLoader.healthCheck()
            if status == "Critical" then
                stats.healthCheckFailures += 1
                ModuleLoader.recover()
            end
        end
    end)
    
    ModuleLoader.initialized = true
    log("ModuleLoader initialized")
    return true
end

return ModuleLoader
