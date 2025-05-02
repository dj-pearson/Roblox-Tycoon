--!strict
--[[
    RegistryTelemetry.luau
    
    A module that collects usage telemetry from the Registry System to help
    track migration progress and identify systems still using legacy APIs.
    
    This telemetry helps guide the final stages of consolidation by providing
    data on which systems are actively using which registry implementations.
    
    Created: May 2, 2025
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configure telemetry settings
local TELEMETRY_CONFIG = {
    enabled = true,
    storeTelemetry = true,
    printDebug = false,
    sampleRate = 0.1, -- Only log 10% of events to avoid spam
    maxEventsPerMinute = 60,
    storagePeriod = 1800 -- Store telemetry for 30 minutes
}

-- Telemetry storage
local telemetryData = {
    legacyRegistryUsage = {},
    newRegistryUsage = {},
    migrationEvents = {},
    errors = {},
    startTime = os.time(),
    eventCount = 0
}

-- Rate limiting
local lastMinute = 0
local eventsThisMinute = 0

-- The module
local RegistryTelemetry = {}

-- Internal utility functions
local function shouldLogEvent()
    if not TELEMETRY_CONFIG.enabled then
        return false
    end
    
    -- Rate limiting
    local currentMinute = math.floor(os.time() / 60)
    if currentMinute > lastMinute then
        lastMinute = currentMinute
        eventsThisMinute = 0
    end
    
    eventsThisMinute += 1
    if eventsThisMinute > TELEMETRY_CONFIG.maxEventsPerMinute then
        return false
    end
    
    -- Random sampling to reduce volume
    return math.random() <= TELEMETRY_CONFIG.sampleRate
end

local function createEventId()
    return HttpService:GenerateGUID(false)
end

local function getCallerInfo()
    -- Get the script that called the registry function
    local callerScript = "Unknown"
    local callerLine = 0
    
    -- Try to get call stack info
    local success, result = pcall(function()
        -- This will error, giving us the stack trace
        error("Stack trace", 3)
    end)
    
    if not success and typeof(result) == "string" then
        -- Parse stack trace
        local stackInfo = result
        local pattern = "([^/]+%.%w+):(%d+)"
        
        for scriptName, lineNumber in string.gmatch(stackInfo, pattern) do
            callerScript = scriptName
            callerLine = tonumber(lineNumber) or 0
            break
        end
    end
    
    return {
        script = callerScript,
        line = callerLine,
        timestamp = os.time()
    }
end

-- Public API
function RegistryTelemetry:LogLegacyUsage(registryName, methodName, componentName)
    if not shouldLogEvent() then
        return
    end
    
    local eventId = createEventId()
    local callerInfo = getCallerInfo()
    
    local event = {
        id = eventId,
        registry = registryName,
        method = methodName,
        component = componentName,
        caller = callerInfo
    }
    
    -- Store the event
    if TELEMETRY_CONFIG.storeTelemetry then
        table.insert(telemetryData.legacyRegistryUsage, event)
        telemetryData.eventCount += 1
    end
    
    -- Print debug info if enabled
    if TELEMETRY_CONFIG.printDebug then
        print("[RegistryTelemetry] Legacy usage: " .. registryName .. ":" .. methodName .. " for " .. (componentName or "unknown"))
    end
    
    return eventId
end

function RegistryTelemetry:LogNewUsage(registryName, methodName, componentName)
    if not shouldLogEvent() then
        return
    end
    
    local eventId = createEventId()
    local callerInfo = getCallerInfo()
    
    local event = {
        id = eventId,
        registry = registryName,
        method = methodName,
        component = componentName,
        caller = callerInfo
    }
    
    -- Store the event
    if TELEMETRY_CONFIG.storeTelemetry then
        table.insert(telemetryData.newRegistryUsage, event)
        telemetryData.eventCount += 1
    end
    
    return eventId
end

function RegistryTelemetry:LogMigrationEvent(eventType, details)
    local eventId = createEventId()
    
    local event = {
        id = eventId,
        type = eventType,
        details = details,
        timestamp = os.time()
    }
    
    -- Store the event
    if TELEMETRY_CONFIG.storeTelemetry then
        table.insert(telemetryData.migrationEvents, event)
        telemetryData.eventCount += 1
    end
    
    -- Print debug info if enabled
    if TELEMETRY_CONFIG.printDebug then
        print("[RegistryTelemetry] Migration event: " .. eventType)
    end
    
    return eventId
end

function RegistryTelemetry:LogError(source, errorMessage, componentName)
    local eventId = createEventId()
    local callerInfo = getCallerInfo()
    
    local event = {
        id = eventId,
        source = source,
        error = errorMessage,
        component = componentName,
        caller = callerInfo,
        timestamp = os.time()
    }
    
    -- Store the event
    if TELEMETRY_CONFIG.storeTelemetry then
        table.insert(telemetryData.errors, event)
        telemetryData.eventCount += 1
    end
    
    -- Always print errors
    warn("[RegistryTelemetry] Error in " .. source .. ": " .. errorMessage)
    
    return eventId
end

-- Reporting
function RegistryTelemetry:GetLegacyUsageSummary()
    local summary = {
        totalCalls = #telemetryData.legacyRegistryUsage,
        byRegistry = {},
        byComponent = {},
        byMethod = {},
        byCaller = {}
    }
    
    -- Process events
    for _, event in ipairs(telemetryData.legacyRegistryUsage) do
        -- By registry
        summary.byRegistry[event.registry] = (summary.byRegistry[event.registry] or 0) + 1
        
        -- By component
        if event.component then
            summary.byComponent[event.component] = (summary.byComponent[event.component] or 0) + 1
        end
        
        -- By method
        summary.byMethod[event.method] = (summary.byMethod[event.method] or 0) + 1
        
        -- By caller
        local callerKey = event.caller.script .. ":" .. event.caller.line
        summary.byCaller[callerKey] = (summary.byCaller[callerKey] or 0) + 1
    end
    
    return summary
end

function RegistryTelemetry:GetMigrationStatus()
    -- Calculate ratio of new vs legacy usage
    local legacyCount = #telemetryData.legacyRegistryUsage
    local newCount = #telemetryData.newRegistryUsage
    local totalCount = legacyCount + newCount
    
    local migrationRatio = 0
    if totalCount > 0 then
        migrationRatio = newCount / totalCount
    end
    
    -- Get top components still using legacy registry
    local legacyComponents = {}
    for _, event in ipairs(telemetryData.legacyRegistryUsage) do
        if event.component then
            legacyComponents[event.component] = (legacyComponents[event.component] or 0) + 1
        end
    end
    
    -- Sort components by usage count
    local topLegacyComponents = {}
    for component, count in pairs(legacyComponents) do
        table.insert(topLegacyComponents, {name = component, count = count})
    end
    
    table.sort(topLegacyComponents, function(a, b)
        return a.count > b.count
    end)
    
    -- Take top 10
    while #topLegacyComponents > 10 do
        table.remove(topLegacyComponents)
    end
    
    return {
        migrationRatio = migrationRatio,
        legacyUsageCount = legacyCount,
        newUsageCount = newCount,
        topLegacyComponents = topLegacyComponents,
        migrationEvents = #telemetryData.migrationEvents,
        errors = #telemetryData.errors,
        telemetryStartTime = telemetryData.startTime,
        telemetryDuration = os.time() - telemetryData.startTime
    }
end

-- Cleanup old data periodically
RunService.Heartbeat:Connect(function()
    -- Skip most frames to reduce overhead
    if math.random() > 0.001 then -- ~0.1% chance to run per frame
        return
    end
    
    local currentTime = os.time()
    local cutoffTime = currentTime - TELEMETRY_CONFIG.storagePeriod
    
    -- Clean up old events
    for _, category in pairs({"legacyRegistryUsage", "newRegistryUsage", "migrationEvents", "errors"}) do
        local i = 1
        while i <= #telemetryData[category] do
            local event = telemetryData[category][i]
            local eventTime = event.timestamp or event.caller.timestamp or 0
            
            if eventTime < cutoffTime then
                table.remove(telemetryData[category], i)
            else
                i += 1
            end
        end
    end
end)

return RegistryTelemetry
