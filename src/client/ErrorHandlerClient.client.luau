--[[
    ErrorHandlerClient.client.luau
    
    Client-side error handling script that integrates with ErrorHandlingUtility.
    Reports client errors to the server and provides local error tracking.
    
    Created as part of the critical fixes for issues identified in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    maxLocalErrors = 50,  -- Max errors to store locally
    reportAllErrors = true,  -- Whether to report all errors to server
    initialDelay = 1  -- Delay before initializing to ensure bridges are set up
}

-- Local variables
local localPlayerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"
local clientErrors = {}
local errorHandlingUtility

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorHandlerClient]", ...)
    end
end

-- Try to require ErrorHandlingUtility
local function getErrorUtility()
    -- First check if shared folder exists
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        warn("[ErrorHandlerClient] Shared folder not found")
        return nil
    end
    
    -- Check for ErrorHandlingUtility module
    local errorModule = shared:FindFirstChild("ErrorHandlingUtility")
    if not errorModule or not errorModule:IsA("ModuleScript") then
        warn("[ErrorHandlerClient] ErrorHandlingUtility not found or not a ModuleScript")
        return nil
    end
    
    -- Try to require it
    local success, result = pcall(function()
        return require(errorModule)
    end)
    
    if success and result then
        return result
    else
        warn("[ErrorHandlerClient] Failed to require ErrorHandlingUtility:", result)
        return nil
    end
end

-- Set up error bridge if needed
local function setupErrorBridge()
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    
    if not errorBridge then
        log("Creating ErrorBridge folder")
        errorBridge = Instance.new("Folder")
        errorBridge.Name = "ErrorBridge"
        errorBridge.Parent = ReplicatedStorage
    end
    
    -- Create client-to-server event if it doesn't exist
    if not errorBridge:FindFirstChild("ReportErrorToServer") then
        log("Creating ReportErrorToServer RemoteEvent")
        local reportEvent = Instance.new("RemoteEvent")
        reportEvent.Name = "ReportErrorToServer"
        reportEvent.Parent = errorBridge
    end
    
    -- Create client error history if it doesn't exist
    if not errorBridge:FindFirstChild("ClientErrorHistory") then
        log("Creating ClientErrorHistory StringValue")
        local clientHistory = Instance.new("StringValue")
        clientHistory.Name = "ClientErrorHistory"
        clientHistory.Value = "{}"  -- Empty JSON object
        clientHistory.Parent = errorBridge
    end
    
    return errorBridge
end

-- Report an error to the server
local function reportErrorToServer(errorType, message, source, additionalInfo)
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    if not errorBridge or not errorBridge:FindFirstChild("ReportErrorToServer") then
        warn("[ErrorHandlerClient] Cannot report error: ErrorBridge not set up")
        return false
    end
    
    local reportEvent = errorBridge.ReportErrorToServer
    if not reportEvent:IsA("RemoteEvent") then
        warn("[ErrorHandlerClient] ReportErrorToServer is not a RemoteEvent")
        return false
    end
    
    -- Create error info
    local errorInfo = {
        type = errorType or "UnknownError",
        message = message or "Unknown error",
        source = source or "Unknown",
        timestamp = os.time(),
        playerName = localPlayerName,
        additional = additionalInfo or {}
    }
    
    -- Add to local history
    table.insert(clientErrors, 1, errorInfo)
    
    -- Trim local history if needed
    if #clientErrors > CONFIG.maxLocalErrors then
        table.remove(clientErrors)
    end
    
    -- Report to server
    reportEvent:FireServer(errorInfo)
    
    -- Update client history in bridge
    local clientHistory = errorBridge:FindFirstChild("ClientErrorHistory")
    if clientHistory and clientHistory:IsA("StringValue") then
        -- Try to stringify the most recent 10 errors
        local recentErrors = {}
        for i = 1, math.min(10, #clientErrors) do
            table.insert(recentErrors, {
                type = clientErrors[i].type,
                message = clientErrors[i].message,
                source = clientErrors[i].source,
                timestamp = clientErrors[i].timestamp,
                playerName = clientErrors[i].playerName
            })
        end
        
        -- Update the StringValue with JSON
        local success, jsonString = pcall(function()
            return game:GetService("HttpService"):JSONEncode(recentErrors)
        end)
        
        if success then
            clientHistory.Value = jsonString
        end
    end
    
    return true
end

-- Set up error handling for client scripts
local function setupClientErrorHandling()
    -- Global error handler
    local oldErrorHandler = _G.__ERROR_HANDLER
    _G.__ERROR_HANDLER = function(err, trace, level)
        -- Report the error
        reportErrorToServer("RuntimeError", err, "Client:" .. localPlayerName, {
            trace = trace,
            level = level
        })
        
        -- Call original handler if it exists
        if oldErrorHandler and type(oldErrorHandler) == "function" then
            return oldErrorHandler(err, trace, level)
        end
        
        return nil
    end
    
    log("Installed global error handler")
    
    -- Create debug functions
    _G.reportClientError = function(errorType, message, source, additionalInfo)
        return reportErrorToServer(errorType, message, source, additionalInfo)
    end
end

-- Initialize error handling
local function initialize()
    log("Initializing ErrorHandlerClient")
    
    -- Set up error bridge
    local errorBridge = setupErrorBridge()
    if not errorBridge then
        warn("[ErrorHandlerClient] Failed to set up error bridge")
        return
    end
    
    -- Try to get ErrorHandlingUtility
    errorHandlingUtility = getErrorUtility()
    
    -- Set up client error handling
    setupClientErrorHandling()
    
    log("ErrorHandlerClient initialized successfully")
    
    -- Report initialization success
    reportErrorToServer("Info", "ErrorHandlerClient initialized successfully", "ErrorHandlerClient", {
        timestamp = os.time()
    })
}

-- Wait for game to load before initializing
task.delay(CONFIG.initialDelay, initialize)

-- Return public API
return {
    reportError = reportErrorToServer,
    getErrorHistory = function()
        return clientErrors
    end,
    clearErrorHistory = function()
        clientErrors = {}
    end,
    isInitialized = function()
        return errorHandlingUtility ~= nil
    end
}
