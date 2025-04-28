--[[
    ErrorCollector.server.luau
    
    Server-side script that collects and processes errors from both server and client.
    Aggregates error data, provides analytics, and handles persistence of critical errors.
    
    Created as part of the critical fixes for issues identified in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
    debug = true,
    maxErrorsStored = 500,      -- Maximum number of errors to store
    persistErrorsToDataStore = false,  -- Whether to save errors to DataStore
    errorCategories = {          -- Categories for error classification
        CRITICAL = "Critical",   -- Game-breaking issues
        HIGH = "High",           -- Significant impact but game functions
        MEDIUM = "Medium",       -- Minor impact, annoying but not game-breaking
        LOW = "Low"              -- Minimal impact, might not be noticed
    },
    batchReporting = {           -- Settings for batch error reporting
        enabled = true,
        interval = 60,           -- Report errors in batches every 60 seconds
        threshold = 10           -- Minimum errors before sending a batch report
    }
}

-- Local variables
local errorCollection = {}
local errorCount = {
    total = 0,
    byType = {},
    byPlayer = {},
    bySource = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[ErrorCollector]", ...)
    end
end

-- Add an error to the collection
local function addError(errorInfo)
    -- Ensure error has required fields
    errorInfo = errorInfo or {}
    errorInfo.type = errorInfo.type or "UnknownError"
    errorInfo.message = errorInfo.message or "Unknown error"
    errorInfo.source = errorInfo.source or "Unknown"
    errorInfo.timestamp = errorInfo.timestamp or os.time()
    
    -- Add server ID for easier tracking
    errorInfo.serverId = game.JobId or "Unknown"
    
    -- Determine severity if not specified
    if not errorInfo.severity then
        -- Simple severity determination based on type
        if string.find(errorInfo.type, "Critical") then
            errorInfo.severity = CONFIG.errorCategories.CRITICAL
        elseif string.find(errorInfo.type, "Data") or string.find(errorInfo.type, "Core") then
            errorInfo.severity = CONFIG.errorCategories.HIGH
        elseif string.find(errorInfo.type, "UI") or string.find(errorInfo.type, "Asset") then
            errorInfo.severity = CONFIG.errorCategories.MEDIUM
        else
            errorInfo.severity = CONFIG.errorCategories.LOW
        end
    end
    
    -- Add to collection
    table.insert(errorCollection, 1, errorInfo)
    
    -- Trim collection if needed
    if #errorCollection > CONFIG.maxErrorsStored then
        table.remove(errorCollection, #errorCollection)
    end
    
    -- Update counts
    errorCount.total = errorCount.total + 1
    
    -- Count by type
    errorCount.byType[errorInfo.type] = (errorCount.byType[errorInfo.type] or 0) + 1
    
    -- Count by player if specified
    if errorInfo.playerName then
        errorCount.byPlayer[errorInfo.playerName] = (errorCount.byPlayer[errorInfo.playerName] or 0) + 1
    end
    
    -- Count by source
    errorCount.bySource[errorInfo.source] = (errorCount.bySource[errorInfo.source] or 0) + 1
    
    -- Log if critical or high severity
    if errorInfo.severity == CONFIG.errorCategories.CRITICAL then
        warn("[CRITICAL ERROR]", errorInfo.type, ":", errorInfo.message, "(", errorInfo.source, ")")
    elseif errorInfo.severity == CONFIG.errorCategories.HIGH then
        warn("[HIGH ERROR]", errorInfo.type, ":", errorInfo.message, "(", errorInfo.source, ")")
    end
    
    return errorInfo
}

-- Process client error report
local function processClientError(player, errorInfo)
    -- Add player info if not provided
    errorInfo = errorInfo or {}
    errorInfo.playerName = errorInfo.playerName or player.Name
    errorInfo.userId = errorInfo.userId or player.UserId
    errorInfo.source = errorInfo.source or ("Client:" .. player.Name)
    
    -- Add to collection
    return addError(errorInfo)
}

-- Set up client error reporting
local function setupClientErrorReporting()
    log("Setting up client error reporting")
    
    -- Ensure ErrorBridge exists
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    if not errorBridge then
        errorBridge = Instance.new("Folder")
        errorBridge.Name = "ErrorBridge"
        errorBridge.Parent = ReplicatedStorage
    end
    
    -- Set up client-to-server reporting
    local reportEvent = errorBridge:FindFirstChild("ReportErrorToServer")
    if not reportEvent then
        reportEvent = Instance.new("RemoteEvent")
        reportEvent.Name = "ReportErrorToServer"
        reportEvent.Parent = errorBridge
    end
    
    -- Connect to the report event
    reportEvent.OnServerEvent:Connect(function(player, errorInfo)
        log("Received error report from", player.Name)
        processClientError(player, errorInfo)
    end)
    
    log("Client error reporting set up successfully")
}

-- Generate error report
local function generateErrorReport()
    local report = {
        timestamp = os.time(),
        totalErrors = errorCount.total,
        serverUptime = os.time() - (game:GetService("Stats"):GetTotalMemoryUsageMb() and 0 or 0), -- placeholder
        activePlayers = #Players:GetPlayers(),
        topErrorTypes = {},
        topErrorSources = {},
        criticalErrors = {},
        recentErrors = {}
    }
    
    -- Get top error types
    local topTypes = {}
    for errorType, count in pairs(errorCount.byType) do
        table.insert(topTypes, {type = errorType, count = count})
    end
    table.sort(topTypes, function(a, b) return a.count > b.count end)
    
    -- Add top 5 error types
    for i = 1, math.min(5, #topTypes) do
        table.insert(report.topErrorTypes, topTypes[i])
    end
    
    -- Get top error sources
    local topSources = {}
    for source, count in pairs(errorCount.bySource) do
        table.insert(topSources, {source = source, count = count})
    end
    table.sort(topSources, function(a, b) return a.count > b.count end)
    
    -- Add top 5 error sources
    for i = 1, math.min(5, #topSources) do
        table.insert(report.topErrorSources, topSources[i])
    end
    
    -- Add critical errors
    for _, error in ipairs(errorCollection) do
        if error.severity == CONFIG.errorCategories.CRITICAL then
            table.insert(report.criticalErrors, {
                type = error.type,
                message = error.message,
                source = error.source,
                timestamp = error.timestamp
            })
            
            -- Limit to 10 critical errors
            if #report.criticalErrors >= 10 then
                break
            end
        end
    end
    
    -- Add 10 most recent errors
    for i = 1, math.min(10, #errorCollection) do
        table.insert(report.recentErrors, {
            type = errorCollection[i].type,
            message = errorCollection[i].message,
            source = errorCollection[i].source,
            timestamp = errorCollection[i].timestamp,
            severity = errorCollection[i].severity
        })
    end
    
    return report
}

-- Update error statistics in ReplicatedStorage
local function updateErrorStats()
    -- Ensure ErrorBridge exists
    local errorBridge = ReplicatedStorage:FindFirstChild("ErrorBridge")
    if not errorBridge then return end
    
    -- Create or update ErrorStats
    local errorStats = errorBridge:FindFirstChild("ErrorStats") or Instance.new("StringValue")
    errorStats.Name = "ErrorStats"
    
    -- Generate a simplified stats object
    local stats = {
        total = errorCount.total,
        byType = {},
        bySource = {},
        lastUpdate = os.time(),
        criticalCount = 0
    }
    
    -- Add top error types (limited to 10)
    local topTypes = {}
    for errorType, count in pairs(errorCount.byType) do
        table.insert(topTypes, {type = errorType, count = count})
    end
    table.sort(topTypes, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(10, #topTypes) do
        stats.byType[topTypes[i].type] = topTypes[i].count
    end
    
    -- Count critical errors
    for _, error in ipairs(errorCollection) do
        if error.severity == CONFIG.errorCategories.CRITICAL then
            stats.criticalCount = stats.criticalCount + 1
        end
    end
    
    -- Try to encode as JSON
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(stats)
    end)
    
    if success then
        errorStats.Value = jsonString
    else
        warn("[ErrorCollector] Failed to encode error stats to JSON")
    end
    
    errorStats.Parent = errorBridge
}

-- Set up periodic tasks
local function setupPeriodicTasks()
    -- Update error stats every 30 seconds
    task.spawn(function()
        while true do
            task.wait(30)
            updateErrorStats()
        end
    end)
    
    -- Generate and log full report every 5 minutes
    task.spawn(function()
        while true do
            task.wait(300)  -- 5 minutes
            local report = generateErrorReport()
            log("Error report generated with", report.totalErrors, "total errors")
        end
    end)
}

-- Initialize the error collector
local function initialize()
    log("Initializing ErrorCollector")
    
    -- Set up client error reporting
    setupClientErrorReporting()
    
    -- Set up periodic tasks
    setupPeriodicTasks()
    
    log("ErrorCollector initialized successfully")
}

-- Run initialization
initialize()

-- Return public API
return {
    addError = addError,
    processClientError = processClientError,
    generateReport = generateErrorReport,
    getErrorCounts = function()
        return errorCount
    end,
    getErrorCollection = function()
        return errorCollection
    end,
    clearErrors = function()
        errorCollection = {}
        errorCount = {
            total = 0,
            byType = {},
            byPlayer = {},
            bySource = {}
        }
        log("Error collection cleared")
    end
}
