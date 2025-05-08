--[[
    ModuleResolver.server.luau
    
    Core system for managing module loading and resolution.
    This system ensures proper module initialization, caching,
    and error recovery.
    
    Features:
    - Module loading and resolution
    - Module caching
    - Error tracking and reporting
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    maxRetries = 3,
    retryDelay = 2, -- seconds
    cacheTimeout = 300, -- 5 minutes
    searchPaths = {
        ServerScriptService,
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    }
}

-- Module state
local ModuleResolver = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    moduleCache = {},
    moduleTimestamps = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ModuleResolver]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            return handler
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            return require(core.ErrorHandler)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Find module in paths
local function findModuleInPaths(moduleName)
    for _, path in ipairs(CONFIG.searchPaths) do
        if path then
            -- Try exact name
            local module = path:FindFirstChild(moduleName)
            if module then
                return module
            end
            
            -- Try with .server.luau extension
            module = path:FindFirstChild(moduleName .. ".server.luau")
            if module then
                return module
            end
            
            -- Try with .client.luau extension
            module = path:FindFirstChild(moduleName .. ".client.luau")
            if module then
                return module
            end
            
            -- Try with .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module then
                return module
            end
        end
    end
    
    return nil
end

-- Load module with retries
local function loadModuleWithRetries(module, retries)
    retries = retries or CONFIG.maxRetries
    local success, result
    
    for i = 1, retries do
        success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            return result
        end
        
        if i < retries then
            log("Failed to require module, retrying... (" .. i .. "/" .. retries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return nil
end

-- Resolve module
local function resolveModule(moduleName)
    if not moduleName then
        return nil, "No module name provided"
    end
    
    -- Check cache first
    local cachedModule = ModuleResolver.moduleCache[moduleName]
    local timestamp = ModuleResolver.moduleTimestamps[moduleName]
    
    if cachedModule and timestamp then
        -- Check if cache is still valid
        if os.time() - timestamp < CONFIG.cacheTimeout then
            return cachedModule
        end
    end
    
    -- Find module in paths
    local module = findModuleInPaths(moduleName)
    if not module then
        return nil, "Module not found: " .. moduleName
    end
    
    -- Load module
    local result = loadModuleWithRetries(module)
    if not result then
        return nil, "Failed to load module: " .. moduleName
    end
    
    -- Cache module
    ModuleResolver.moduleCache[moduleName] = result
    ModuleResolver.moduleTimestamps[moduleName] = os.time()
    
    return result
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(ModuleResolver.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #ModuleResolver.errors > CONFIG.maxErrors do
        table.remove(ModuleResolver.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #ModuleResolver.errors, 1, -1 do
        if ModuleResolver.errors[i].timestamp < cutoff then
            table.remove(ModuleResolver.errors, i)
        end
    end
    
    -- Report to ErrorHandler
    local errorHandler = getErrorHandler()
    if errorHandler then
        errorHandler:recordError(message, "module_resolver", {
            timestamp = timestamp
        })
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    ModuleResolver.lastCheck = now
    
    -- Check cache validity
    for moduleName, timestamp in pairs(ModuleResolver.moduleTimestamps) do
        if now - timestamp >= CONFIG.cacheTimeout then
            -- Remove expired cache
            ModuleResolver.moduleCache[moduleName] = nil
            ModuleResolver.moduleTimestamps[moduleName] = nil
        end
    end
    
    return true
end

-- Initialize ModuleResolver
function ModuleResolver.initialize()
    if ModuleResolver.initialized then return true end
    
    log("Initializing ModuleResolver...")
    
    -- Get required systems
    local errorHandler = getErrorHandler()
    if not errorHandler then
        log("ErrorHandler not found, error reporting may be limited")
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    ModuleResolver.initialized = true
    log("ModuleResolver initialized")
    return true
end

-- Resolve module
function ModuleResolver.resolve(moduleName)
    local module, error = resolveModule(moduleName)
    if not module then
        recordError(error)
    end
    return module
end

-- Clear module cache
function ModuleResolver.clearCache(moduleName)
    if moduleName then
        ModuleResolver.moduleCache[moduleName] = nil
        ModuleResolver.moduleTimestamps[moduleName] = nil
    else
        ModuleResolver.moduleCache = {}
        ModuleResolver.moduleTimestamps = {}
    end
end

-- Get error count
function ModuleResolver.getErrorCount()
    return #ModuleResolver.errors
end

-- Get recent errors
function ModuleResolver.getRecentErrors()
    return ModuleResolver.errors
end

-- Force a health check
function ModuleResolver.forceCheck()
    return checkHealth()
end

return ModuleResolver 