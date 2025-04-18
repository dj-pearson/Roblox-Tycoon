-- PerformanceProfiler.server.luau
-- System for monitoring and analyzing performance metrics
-- Part of the Performance Optimization Framework

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local ConfigManager
local MemoryStoreManager

-- Module table
local PerformanceProfiler = {
    Name = "PerformanceProfiler",
    Dependencies = {
        "CoreRegistry",
        "ConfigManager",
        "MemoryStoreManager"
    },
    
    -- Internal state
    _tracking = {},                 -- Currently tracked metrics
    _metricsHistory = {},           -- Historical metrics
    _activeProfiles = {},           -- Active profiling sessions
    _systemPerformance = {},        -- Performance metrics by system
    _initialized = false            -- Whether the system is initialized
}

-- Debug function
local function debugPrint(...)
    if CoreRegistry.getSystem and CoreRegistry:getSystem("ConfigManager") then
        local debug = CoreRegistry:getSystem("ConfigManager"):getValue("core.debug", false)
        if debug then
            print("[PerformanceProfiler]", ...)
        end
    end
end

--[[ Performance Metric Tracking ]]--

-- Start tracking a performance metric
function PerformanceProfiler:startTracking(name, category)
    category = category or "general"
    
    -- Initialize category if needed
    if not self._tracking[category] then
        self._tracking[category] = {}
    end
    
    -- Record start time
    self._tracking[category][name] = {
        startTime = os.clock(),
        lastLapTime = os.clock()
    }
    
    return true
end

-- End tracking a performance metric and record the result
function PerformanceProfiler:endTracking(name, category, additionalData)
    category = category or "general"
    
    -- Check if metric is being tracked
    if not self._tracking[category] or not self._tracking[category][name] then
        return false
    end
    
    -- Calculate duration
    local startData = self._tracking[category][name]
    local endTime = os.clock()
    local duration = endTime - startData.startTime
    
    -- Create metric result
    local result = {
        name = name,
        category = category,
        duration = duration,
        timestamp = os.time(),
        additionalData = additionalData or {}
    }
    
    -- Add to history
    if not self._metricsHistory[category] then
        self._metricsHistory[category] = {}
    end
    
    if not self._metricsHistory[category][name] then
        self._metricsHistory[category][name] = {}
    end
    
    table.insert(self._metricsHistory[category][name], result)
    
    -- Limit history size
    local maxHistory = 100 -- Could be made configurable
    if #self._metricsHistory[category][name] > maxHistory then
        table.remove(self._metricsHistory[category][name], 1)
    end
    
    -- Stop tracking
    self._tracking[category][name] = nil
    
    -- Persist important metrics to MemoryStore if available
    if MemoryStoreManager and category == "critical" then
        MemoryStoreManager:setValue("metrics." .. name, result, 86400) -- 24 hour retention
    end
    
    return result
end

-- Record a lap time without stopping tracking
function PerformanceProfiler:recordLap(name, category, lapName)
    category = category or "general"
    
    -- Check if metric is being tracked
    if not self._tracking[category] or not self._tracking[category][name] then
        return false
    end
    
    -- Calculate lap duration
    local trackingData = self._tracking[category][name]
    local currentTime = os.clock()
    local lapDuration = currentTime - trackingData.lastLapTime
    
    -- Add lap to tracking data
    if not trackingData.laps then
        trackingData.laps = {}
    end
    
    table.insert(trackingData.laps, {
        name = lapName or ("Lap " .. (#trackingData.laps + 1)),
        duration = lapDuration,
        timestamp = currentTime
    })
    
    -- Update last lap time
    trackingData.lastLapTime = currentTime
    
    return lapDuration
end

-- Get historical metrics for a specific metric
function PerformanceProfiler:getMetricHistory(name, category)
    category = category or "general"
    
    if not self._metricsHistory[category] or not self._metricsHistory[category][name] then
        return {}
    end
    
    return self._metricsHistory[category][name]
end

-- Get statistics for a specific metric
function PerformanceProfiler:getMetricStats(name, category)
    category = category or "general"
    
    local history = self:getMetricHistory(name, category)
    if #history == 0 then
        return nil
    end
    
    -- Calculate statistics
    local sum = 0
    local min = math.huge
    local max = -math.huge
    
    for _, metric in ipairs(history) do
        sum = sum + metric.duration
        min = math.min(min, metric.duration)
        max = math.max(max, metric.duration)
    end
    
    local avg = sum / #history
    
    -- Calculate standard deviation
    local sumSquaredDiff = 0
    for _, metric in ipairs(history) do
        local diff = metric.duration - avg
        sumSquaredDiff = sumSquaredDiff + (diff * diff)
    end
    
    local stdDev = math.sqrt(sumSquaredDiff / #history)
    
    return {
        count = #history,
        average = avg,
        min = min,
        max = max,
        stdDev = stdDev,
        total = sum
    }
end

-- Clear all tracking data
function PerformanceProfiler:clearTracking()
    self._tracking = {}
    return true
end

-- Clear historical metrics
function PerformanceProfiler:clearHistory(category, name)
    if category and name then
        -- Clear specific metric
        if self._metricsHistory[category] then
            self._metricsHistory[category][name] = {}
        end
    elseif category then
        -- Clear category
        self._metricsHistory[category] = {}
    else
        -- Clear all
        self._metricsHistory = {}
    end
    
    return true
end

--[[ Performance Profiling ]]--

-- Start profiling a function or code block
function PerformanceProfiler:startProfiling(name, category)
    category = category or "profiling"
    
    local profileId = HttpService:GenerateGUID(false)
    
    self._activeProfiles[profileId] = {
        name = name,
        category = category,
        startTime = os.clock(),
        calls = 0
    }
    
    return profileId
end

-- End profiling and record results
function PerformanceProfiler:endProfiling(profileId)
    local profile = self._activeProfiles[profileId]
    if not profile then
        return false
    end
    
    local endTime = os.clock()
    local duration = endTime - profile.startTime
    
    -- Record as a metric
    local result = {
        name = profile.name,
        category = profile.category,
        duration = duration,
        calls = profile.calls,
        timestamp = os.time()
    }
    
    -- Add to history
    if not self._metricsHistory[profile.category] then
        self._metricsHistory[profile.category] = {}
    end
    
    if not self._metricsHistory[profile.category][profile.name] then
        self._metricsHistory[profile.category][profile.name] = {}
    end
    
    table.insert(self._metricsHistory[profile.category][profile.name], result)
    
    -- Limit history size
    local maxHistory = 100
    if #self._metricsHistory[profile.category][profile.name] > maxHistory then
        table.remove(self._metricsHistory[profile.category][profile.name], 1)
    end
    
    -- Remove active profile
    self._activeProfiles[profileId] = nil
    
    return result
end

-- Record a function call in a profiling session
function PerformanceProfiler:recordCall(profileId)
    local profile = self._activeProfiles[profileId]
    if not profile then
        return false
    end
    
    profile.calls = profile.calls + 1
    return profile.calls
end

-- Create a profiling wrapper for a function
function PerformanceProfiler:profileFunction(func, name, category)
    local self = self
    
    return function(...)
        local profileId = self:startProfiling(name, category)
        local results = {pcall(func, ...)}
        local success = table.remove(results, 1)
        self:endProfiling(profileId)
        
        if success then
            return unpack(results)
        else
            error(results[1])
        end
    end
end

--[[ System Performance Tracking ]]--

-- Record system performance
function PerformanceProfiler:recordSystemPerformance(systemName, functionName, duration, additionalData)
    -- Initialize system entry if needed
    if not self._systemPerformance[systemName] then
        self._systemPerformance[systemName] = {
            functions = {},
            totalCalls = 0,
            totalDuration = 0
        }
    end
    
    local system = self._systemPerformance[systemName]
    
    -- Initialize function entry if needed
    if not system.functions[functionName] then
        system.functions[functionName] = {
            calls = 0,
            totalDuration = 0,
            minDuration = math.huge,
            maxDuration = 0,
            samples = {}
        }
    end
    
    local func = system.functions[functionName]
    
    -- Update function metrics
    func.calls = func.calls + 1
    func.totalDuration = func.totalDuration + duration
    func.minDuration = math.min(func.minDuration, duration)
    func.maxDuration = math.max(func.maxDuration, duration)
    
    -- Add sample with recent data
    table.insert(func.samples, {
        duration = duration,
        timestamp = os.time(),
        data = additionalData
    })
    
    -- Limit sample size
    local maxSamples = 50
    if #func.samples > maxSamples then
        table.remove(func.samples, 1)
    end
    
    -- Update system totals
    system.totalCalls = system.totalCalls + 1
    system.totalDuration = system.totalDuration + duration
    
    return true
end

-- Get system performance stats
function PerformanceProfiler:getSystemPerformance(systemName)
    if systemName then
        return self._systemPerformance[systemName]
    else
        return self._systemPerformance
    end
end

-- Clear system performance data
function PerformanceProfiler:clearSystemPerformance(systemName)
    if systemName then
        self._systemPerformance[systemName] = nil
    else
        self._systemPerformance = {}
    end
    
    return true
end

--[[ Server Performance Monitoring ]]--

-- Get current server performance metrics
function PerformanceProfiler:getServerPerformance()
    local metrics = {}
    
    -- Memory metrics
    metrics.memoryUsageMB = Stats:GetTotalMemoryUsageMb()
    metrics.dataReceiveKBPS = Stats.DataReceiveKbps
    metrics.dataSendKBPS = Stats.DataSendKbps
    metrics.physicsStepTimeMs = Stats.PhysicsStepTimeMs
    metrics.heartbeatTimeMs = Stats.HeartbeatTimeMs
    
    -- Active client count
    metrics.playerCount = #game.Players:GetPlayers()
    
    -- Last frame time (approximate)
    metrics.timestamp = os.time()
    
    return metrics
end

-- Start monitoring server performance
function PerformanceProfiler:startServerMonitoring(interval, historySize)
    interval = interval or 10 -- Default to 10 seconds
    historySize = historySize or 60 -- Keep last 60 samples (10 minutes at default interval)
    
    -- Initialize server metrics history if not already
    if not self._metricsHistory.server then
        self._metricsHistory.server = {
            metrics = {},
            lastSample = 0
        }
    end
    
    -- Start monitoring task
    task.spawn(function()
        while true do
            task.wait(interval)
            
            local metrics = self:getServerPerformance()
            table.insert(self._metricsHistory.server.metrics, metrics)
            self._metricsHistory.server.lastSample = os.time()
            
            -- Limit history size
            if #self._metricsHistory.server.metrics > historySize then
                table.remove(self._metricsHistory.server.metrics, 1)
            end
            
            -- Store metrics summary in MemoryStore if available
            if MemoryStoreManager then
                local averageMemory = 0
                local averageCPU = 0
                local count = math.min(6, #self._metricsHistory.server.metrics) -- Last 6 samples
                
                for i = #self._metricsHistory.server.metrics - count + 1, #self._metricsHistory.server.metrics do
                    local sample = self._metricsHistory.server.metrics[i]
                    averageMemory = averageMemory + sample.memoryUsageMB
                    averageCPU = averageCPU + sample.heartbeatTimeMs
                end
                
                averageMemory = averageMemory / count
                averageCPU = averageCPU / count
                
                MemoryStoreManager:setValue("server_metrics", {
                    averageMemoryMB = averageMemory,
                    averageCPUMs = averageCPU,
                    playerCount = metrics.playerCount,
                    timestamp = os.time()
                }, 3600) -- 1 hour retention
            end
        end
    end)
    
    return true
end

-- Get server performance history
function PerformanceProfiler:getServerHistory()
    if not self._metricsHistory.server then
        return {
            metrics = {},
            lastSample = 0
        }
    end
    
    return self._metricsHistory.server
end

--[[ Initialization and Core Functions ]]--

-- Initialize the PerformanceProfiler
function PerformanceProfiler:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing PerformanceProfiler...")
    
    -- Get dependencies
    ConfigManager = CoreRegistry:getSystem("ConfigManager")
    if not ConfigManager then
        warn("ConfigManager not found, some functionality may be limited")
    end
    
    MemoryStoreManager = CoreRegistry:getSystem("MemoryStoreManager")
    if not MemoryStoreManager then
        warn("MemoryStoreManager not found, metrics persistence will be disabled")
    end
    
    -- Start server monitoring
    if ConfigManager then
        local monitoringEnabled = ConfigManager:getValue("performance.monitorServerMetrics", true)
        local monitorInterval = ConfigManager:getValue("performance.serverMonitorInterval", 10)
        
        if monitoringEnabled then
            self:startServerMonitoring(monitorInterval)
        end
    else
        -- Default to enabled with default settings
        self:startServerMonitoring()
    end
    
    self._initialized = true
    debugPrint("PerformanceProfiler initialized")
    return true
end

-- Stop the PerformanceProfiler
function PerformanceProfiler:shutdown()
    -- Nothing to clean up for now
    self._initialized = false
    debugPrint("PerformanceProfiler shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- Metric tracking
    startTracking = function(name, category)
        return PerformanceProfiler:startTracking(name, category)
    end,
    
    endTracking = function(name, category, additionalData)
        return PerformanceProfiler:endTracking(name, category, additionalData)
    end,
    
    recordLap = function(name, category, lapName)
        return PerformanceProfiler:recordLap(name, category, lapName)
    end,
    
    getMetricHistory = function(name, category)
        return PerformanceProfiler:getMetricHistory(name, category)
    end,
    
    getMetricStats = function(name, category)
        return PerformanceProfiler:getMetricStats(name, category)
    end,
    
    clearTracking = function()
        return PerformanceProfiler:clearTracking()
    end,
    
    clearHistory = function(category, name)
        return PerformanceProfiler:clearHistory(category, name)
    end,
    
    -- Function profiling
    startProfiling = function(name, category)
        return PerformanceProfiler:startProfiling(name, category)
    end,
    
    endProfiling = function(profileId)
        return PerformanceProfiler:endProfiling(profileId)
    end,
    
    recordCall = function(profileId)
        return PerformanceProfiler:recordCall(profileId)
    end,
    
    profileFunction = function(func, name, category)
        return PerformanceProfiler:profileFunction(func, name, category)
    end,
    
    -- System performance
    recordSystemPerformance = function(systemName, functionName, duration, additionalData)
        return PerformanceProfiler:recordSystemPerformance(systemName, functionName, duration, additionalData)
    end,
    
    getSystemPerformance = function(systemName)
        return PerformanceProfiler:getSystemPerformance(systemName)
    end,
    
    clearSystemPerformance = function(systemName)
        return PerformanceProfiler:clearSystemPerformance(systemName)
    end,
    
    -- Server monitoring
    getServerPerformance = function()
        return PerformanceProfiler:getServerPerformance()
    end,
    
    startServerMonitoring = function(interval, historySize)
        return PerformanceProfiler:startServerMonitoring(interval, historySize)
    end,
    
    getServerHistory = function()
        return PerformanceProfiler:getServerHistory()
    end,
}

-- Initialize the system
PerformanceProfiler:initialize()

-- Register with CoreRegistry
if CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("PerformanceProfiler", PublicAPI)
end

return PublicAPI