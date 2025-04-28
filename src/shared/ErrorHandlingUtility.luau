--[[
    ErrorHandlingUtility.luau
    
    A shared module for consistent error handling, logging, and reporting throughout
    the codebase. Provides standard error types, formatting, and recovery strategies.
    
    Created to support fixes for issues identified in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    errorLevels = {
        DEBUG = 0,
        INFO = 1,
        WARNING = 2,
        ERROR = 3,
        CRITICAL = 4
    },
    minReportLevel = 2, -- WARNING and above
    errorTypes = {
        DATA_ERROR = "DataError",
        MODULE_ERROR = "ModuleError",
        TYPE_ERROR = "TypeError",
        VALUE_ERROR = "ValueError",
        TIMEOUT_ERROR = "TimeoutError",
        REGISTRY_ERROR = "RegistryError",
        TYCOON_ERROR = "TycoonError",
        SYSTEM_ERROR = "SystemError"
    },
    maxErrorHistory = 100
}

-- Error history
local errorHistory = {}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorHandling]", ...)
    end
end

-- Format an error with contextual information
local function formatError(errorType, message, source, additionalInfo)
    local formattedError = {
        type = errorType or "UnknownError",
        message = message or "Unknown error",
        source = source or "Unknown",
        timestamp = os.time(),
        additional = additionalInfo or {},
        traceback = debug.traceback(nil, 2)
    }
    
    return formattedError
end

-- Report an error
local function reportError(level, errorInfo)
    -- Add to history
    table.insert(errorHistory, 1, errorInfo)
    
    -- Trim history if needed
    if #errorHistory > CONFIG.maxErrorHistory then
        table.remove(errorHistory)
    end
    
    -- Get level name
    local levelName = "UNKNOWN"
    for name, lvl in pairs(CONFIG.errorLevels) do
        if lvl == level then
            levelName = name
            break
        end
    end
    
    -- Print based on level
    if level >= CONFIG.minReportLevel then
        if level >= CONFIG.errorLevels.ERROR then
            warn(string.format("[%s] %s: %s (%s)", 
                levelName,
                errorInfo.type,
                errorInfo.message,
                errorInfo.source
            ))
        else
            print(string.format("[%s] %s: %s (%s)", 
                levelName,
                errorInfo.type,
                errorInfo.message,
                errorInfo.source
            ))
        end
    end
      -- Send to remote receivers if available
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    if errorBridge and errorBridge:FindFirstChild("ReportError") and level >= CONFIG.errorLevels.ERROR then
        -- Create a simplified version for remote sending
        local simplifiedError = {
            type = errorInfo.type,
            message = errorInfo.message,
            source = errorInfo.source,
            timestamp = errorInfo.timestamp,
            level = level
        }
        
        -- Send over appropriate event based on environment
        if RunService:IsServer() and errorBridge:FindFirstChild("ReportError"):IsA("BindableEvent") then
            -- Server-side reporting
            errorBridge.ReportError:Fire(simplifiedError)
        elseif RunService:IsClient() and errorBridge:FindFirstChild("ReportErrorToServer") and 
               errorBridge.ReportErrorToServer:IsA("RemoteEvent") then
            -- Client-side reporting to server
            errorBridge.ReportErrorToServer:FireServer(simplifiedError)
        end
    end
    
    return errorInfo
end

-- Create specific error reporting functions
local function generateErrorFunction(level, errorType)
    return function(message, source, additionalInfo)
        local errorInfo = formatError(errorType, message, source, additionalInfo)
        return reportError(level, errorInfo)
    end
end

-- Create error report system
local errorReporter = {}

-- Generate standard error reporting functions
for typeName, errorType in pairs(CONFIG.errorTypes) do
    errorReporter["report" .. errorType] = generateErrorFunction(CONFIG.errorLevels.ERROR, errorType)
    errorReporter["reportCritical" .. errorType] = generateErrorFunction(CONFIG.errorLevels.CRITICAL, errorType)
    errorReporter["warn" .. errorType] = generateErrorFunction(CONFIG.errorLevels.WARNING, errorType)
end

-- Create error bridge if it doesn't exist
local function setupErrorBridge()
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    
    if not errorBridge then
        errorBridge = Instance.new("Folder")
        errorBridge.Name = "ErrorBridge"
        errorBridge.Parent = ReplicatedStorage
    end
    
    -- Create report event (server-side)
    local reportEvent = errorBridge:FindFirstChild("ReportError") or Instance.new("BindableEvent")
    reportEvent.Name = "ReportError"
    reportEvent.Parent = errorBridge
    
    -- Create client-to-server report event
    local clientReportEvent = errorBridge:FindFirstChild("ReportErrorToServer") or Instance.new("RemoteEvent")
    clientReportEvent.Name = "ReportErrorToServer"
    clientReportEvent.Parent = errorBridge
    
    -- Create error history object
    local historyValue = errorBridge:FindFirstChild("ErrorHistory") or Instance.new("StringValue")
    historyValue.Name = "ErrorHistory"
    historyValue.Value = "[]" -- Empty JSON array
    historyValue.Parent = errorBridge
    
    -- Create client error history object
    local clientHistoryValue = errorBridge:FindFirstChild("ClientErrorHistory") or Instance.new("StringValue")
    clientHistoryValue.Name = "ClientErrorHistory"
    clientHistoryValue.Value = "[]" -- Empty JSON array
    clientHistoryValue.Parent = errorBridge
    
    -- Connect report event to history
    reportEvent.Event:Connect(function(errorInfo)
        -- Update history string (limits to last 10 errors for size)
        local history = {}
        for i = 1, math.min(10, #errorHistory) do
            table.insert(history, {
                type = errorHistory[i].type,
                message = errorHistory[i].message,
                source = errorHistory[i].source,
                timestamp = errorHistory[i].timestamp
            })
        end
        
        -- Try to encode as JSON
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONEncode(history)
        end)
        
        if success then
            historyValue.Value = result
        end
    end)
end

-- Safe error handling with recovery options
local function safeCall(func, ...)
    if type(func) ~= "function" then
        return false, errorReporter.reportTypeError("Expected a function", "safeCall", {
            provided = type(func)
        })
    end
    
    local success, result = pcall(func, ...)
    
    if not success then
        return false, errorReporter.reportSystemError(result, "safeCall")
    end
    
    return true, result
end

-- Safe requiring of modules
local function safeRequire(moduleScript)
    if not moduleScript then
        return false, errorReporter.reportValueError("Module is nil", "safeRequire")
    end
    
    if not moduleScript:IsA("ModuleScript") then
        return false, errorReporter.reportTypeError("Expected ModuleScript", "safeRequire", {
            provided = moduleScript.ClassName
        })
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        return false, errorReporter.reportModuleError("Failed to require module: " .. result, moduleScript:GetFullName())
    end
    
    return true, result
end

-- Initialize the module
setupErrorBridge()
log("ErrorHandlingUtility initialized")

-- Public API
return {
    -- Error reporting
    error = errorReporter,
    
    -- Error types
    errorTypes = CONFIG.errorTypes,
    
    -- Safe execution
    safeCall = safeCall,
    safeRequire = safeRequire,
    
    -- Error history
    getErrorHistory = function()
        return errorHistory
    end,
    
    -- Format errors
    formatError = formatError,
    
    -- Utility functions
    getErrorSummary = function()
        local counts = {}
        
        for _, err in ipairs(errorHistory) do
            counts[err.type] = (counts[err.type] or 0) + 1
        end
        
        return {
            total = #errorHistory,
            byType = counts,
            recent = errorHistory[1]
        }
    end,
    
    -- Clear history
    clearHistory = function()
        errorHistory = {}
    end
}
