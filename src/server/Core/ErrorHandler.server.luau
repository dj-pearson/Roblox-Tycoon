--[[
    ErrorHandler.server.luau
    
    Handles common script errors and provides proper error recovery mechanisms.
    This system ensures robust error handling throughout the codebase.
    
    Features:
    - Common error pattern detection
    - Error recovery strategies
    - Error tracking and reporting
    - Integration with CoreRegistry
    - Health monitoring
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds,
    waitTimeout = 5, -- seconds
    errorPatterns = {
        ["attempt to index nil with"] = {
            type = "nil_index",
            recovery = function(context)
                -- Try to find the object in alternative locations
                if context.objectName then
                    local coreRegistry = _G.CoreRegistry
                    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
                        local system = coreRegistry:getSystem(context.objectName)
                        if system then
                            return system
                        end
                    end
                end
                return nil
            end
        },
        ["attempt to call a nil value"] = {
            type = "nil_call",
            recovery = function(context)
                -- Try to find the function in alternative locations
                if context.functionName then
                    local coreRegistry = _G.CoreRegistry
                    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
                        local system = coreRegistry:getSystem(context.systemName)
                        if system and typeof(system[context.functionName]) == "function" then
                            return system[context.functionName]
                        end
                    end
                end
                return nil
            end
        },
        ["Infinite yield possible on"] = {
            type = "infinite_yield",
            recovery = function(context)
                -- Add timeout to WaitForChild calls
                if context.instance and context.childName then
                    local startTime = os.time()
                    while not context.instance:FindFirstChild(context.childName) do
                        if os.time() - startTime > CONFIG.waitTimeout then
                            return nil
                        end
                        task.wait(0.1)
                    end
                    return context.instance:FindFirstChild(context.childName)
                end
                return nil
            end
        }
    }
}

-- Module state
local ErrorHandler = {
    initialized = false,
    errors = {},      -- Error history
    lastCheck = 0     -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorHandler]", ...)
    end
end

-- Get ModuleResolver
local function getModuleResolver()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local resolver = coreRegistry:getSystem("ModuleResolver")
        if resolver then
            return resolver
        end
    end
    
    -- Try to find in ServerScriptService
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolver") then
        local success, result = pcall(function()
            return require(core.ModuleResolver)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Parse error message
local function parseError(message)
    for pattern, handler in pairs(CONFIG.errorPatterns) do
        if string.find(message, pattern) then
            return handler.type, handler.recovery
        end
    end
    return "unknown", nil
end

-- Handle error
local function handleError(error, context)
    local errorType, recoveryFunction = parseError(error)
    
    if recoveryFunction then
        local recovered = recoveryFunction(context)
        if recovered then
            log("Recovered from " .. errorType .. " error")
            return recovered
        end
    end
    
    ErrorHandler.recordError(error, errorType, context)
    return nil
end

-- Initialize ErrorHandler
function ErrorHandler.initialize()
    if ErrorHandler.initialized then return true end
    
    log("Initializing ErrorHandler...")
    
    -- Get ModuleResolver
    local resolver = getModuleResolver()
    if not resolver then
        log("ModuleResolver not found, error handling may be limited", true)
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            ErrorHandler.checkHealth()
        end
    end)
    
    ErrorHandler.initialized = true
    log("ErrorHandler initialized")
    return true
end

-- Safe require with error handling
function ErrorHandler.safeRequire(module, context)
    if not ErrorHandler.initialized then
        ErrorHandler.initialize()
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        return handleError(result, context)
    end
    
    return result
end

-- Safe WaitForChild with timeout
function ErrorHandler.safeWaitForChild(instance, childName, timeout)
    if not ErrorHandler.initialized then
        ErrorHandler.initialize()
    end
    
    timeout = timeout or CONFIG.waitTimeout
    local startTime = os.time()
    
    while not instance:FindFirstChild(childName) do
        if os.time() - startTime > timeout then
            ErrorHandler.recordError("Timeout waiting for child: " .. childName, "timeout", {
                instance = instance,
                childName = childName
            })
            return nil
        end
        task.wait(0.1)
    end
    
    return instance:FindFirstChild(childName)
end

-- Safe function call
function ErrorHandler.safeCall(func, ...)
    if not ErrorHandler.initialized then
        ErrorHandler.initialize()
    end
    
    if typeof(func) ~= "function" then
        ErrorHandler.recordError("Attempt to call non-function", "invalid_call", {
            func = func
        })
        return nil
    end
    
    local success, result = pcall(func, ...)
    if not success then
        return handleError(result, {
            func = func
        })
    end
    
    return result
end

-- Check system health
function ErrorHandler.checkHealth()
    local now = os.time()
    ErrorHandler.lastCheck = now
    
    -- Check error count
    if #ErrorHandler.errors > 50 then
        ErrorHandler.recordError("Too many errors: " .. #ErrorHandler.errors)
    end
    
    return true
end

-- Record an error
function ErrorHandler.recordError(message, errorType, context)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(ErrorHandler.errors, {
        message = message,
        type = errorType,
        context = context,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #ErrorHandler.errors > 50 do
        table.remove(ErrorHandler.errors, 1)
    end
    
    log("Error recorded: " .. message)
end

-- Get error count
function ErrorHandler.getErrorCount()
    return #ErrorHandler.errors
end

-- Get recent errors
function ErrorHandler.getRecentErrors()
    return ErrorHandler.errors
end

-- Force a health check
function ErrorHandler.forceCheck()
    return ErrorHandler.checkHealth()
end

return ErrorHandler 