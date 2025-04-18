-- PerformanceManager.server.luau
-- Centralized system for managing performance optimization
-- Place in ServerScriptService/Core

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    enabled = true,
    
    -- Performance monitoring
    monitoringEnabled = true,
    monitorInterval = 10,          -- How often to check performance stats (seconds)
    maxMemoryUsageMB = 3000,       -- Warning threshold for memory usage (MB)
    minAcceptableFrameRate = 30,   -- Minimum acceptable server frame rate
    serverFramerateInterval = 5,   -- How often to measure server framerate (seconds)

    -- Object pooling
    initialPoolSizes = {
        ["NPCs"] = 20,             -- Initial pool size for NPCs
        ["Effects"] = 15,          -- Initial pool size for effects
        ["Basketballs"] = 5,       -- Initial pool size for basketballs
    },
    
    -- Task scheduling
    taskDistributionTicks = 3,     -- Distribute tasks across this many heartbeats
    heavyTaskCooldown = 0.5,       -- Seconds to wait after completing a heavy task
    
    -- Detail levels
    detailLevels = {
        "High",                    -- Full detail, all features enabled
        "Medium",                  -- Reduced particle effects, fewer ambient sounds
        "Low",                     -- Minimal visual effects, reduced update frequency
        "Minimal"                  -- Only essential systems running, bare minimum visuals
    },
    defaultDetailLevel = "High",   -- Default detail level to start with
    autoAdjustDetailLevel = true,  -- Automatically adjust detail level based on performance
    
    -- Culling distances
    cullingDistances = {
        NPCs = 150,                -- Distance beyond which NPCs are culled (studs)
        Effects = 100,             -- Distance beyond which effects are culled
        DetailProps = 75,          -- Distance beyond which decorative props are culled
        Sounds = 50                -- Distance beyond which ambient sounds are culled
    },
    
    -- Memory management
    gcCollectInterval = 300,       -- How often to suggest garbage collection (seconds)
    
    -- Player density management
    maxPlayersPerArea = 6,         -- Max players in close proximity before optimization
    playerDensityRadius = 50,      -- Radius to check for player density (studs)
    
    -- System-specific optimizations
    npcUpdateFrequency = {
        High = 1,                  -- Update every frame
        Medium = 2,                -- Update every 2 frames
        Low = 3,                   -- Update every 3 frames
        Minimal = 4                -- Update every 4 frames
    },
    
    particleDensity = {
        High = 1.0,                -- 100% particle count
        Medium = 0.7,              -- 70% particle count
        Low = 0.3,                 -- 30% particle count
        Minimal = 0.1              -- 10% particle count
    },
    
    -- Performance telemetry
    recordPerformanceStats = true, -- Record performance stats for later analysis
    maxStatsHistory = 100,         -- Maximum number of performance stats to keep
    
    -- Memory store integration
    useMemoryStoreForTemp = true,  -- Use MemoryStore for temporary data
}

-- Module table
local PerformanceManager = {
    Name = "PerformanceManager",
    Dependencies = {
        "CoreRegistry",
        "EventBridge"
    },
    
    -- Internal state
    _currentDetailLevel = CONFIG.defaultDetailLevel,
    _pools = {},                   -- Object pools
    _scheduledTasks = {},          -- Tasks scheduled for future execution
    _taskDistributionIndex = 0,    -- Current index for distributing tasks
    _performanceStats = {},        -- History of performance statistics
    _systemUpdateFrequency = {},   -- How often each system should update
    _lastGC = os.clock(),          -- When garbage collection was last suggested
    _heavyTaskRunning = false,     -- Whether a heavy task is currently running
    _serverFramerateHistory = {},  -- Track server framerate over time
    _memoryUsageHistory = {},      -- Track memory usage over time
    _systemMonitoring = {},        -- Track performance of individual systems
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[PerformanceManager]", ...)
    end
end

--[[ Object Pooling ]]--

-- Initialize object pool
function PerformanceManager:initializePool(poolName, createFunc, initialSize)
    if self._pools[poolName] then
        debugPrint("Pool already exists:", poolName)
        return
    end
    
    self._pools[poolName] = {
        available = {},
        inUse = {},
        createFunc = createFunc,
        total = 0
    }
    
    -- Pre-populate the pool
    self:growPool(poolName, initialSize or CONFIG.initialPoolSizes[poolName] or 10)
    debugPrint("Initialized pool:", poolName, "with", initialSize, "objects")
end

-- Grow a pool by adding more objects
function PerformanceManager:growPool(poolName, count)
    local pool = self._pools[poolName]
    if not pool then
        debugPrint("Cannot grow non-existent pool:", poolName)
        return
    end
    
    for _ = 1, count do
        local obj = pool.createFunc()
        if obj then
            table.insert(pool.available, obj)
            pool.total = pool.total + 1
        end
    end
    
    debugPrint("Grew pool:", poolName, "by", count, "objects (Total:", pool.total, ")")
end

-- Get an object from a pool
function PerformanceManager:getFromPool(poolName)
    local pool = self._pools[poolName]
    if not pool then
        debugPrint("Cannot get from non-existent pool:", poolName)
        return nil
    end
    
    local obj
    
    if #pool.available > 0 then
        -- Get from available objects
        obj = table.remove(pool.available)
    else
        -- Need to create a new one
        debugPrint("Pool", poolName, "ran out, creating new object")
        obj = pool.createFunc()
        pool.total = pool.total + 1
    end
    
    -- Track as in use
    if obj then
        pool.inUse[obj] = true
    end
    
    return obj
end

-- Return an object to its pool
function PerformanceManager:returnToPool(poolName, obj)
    local pool = self._pools[poolName]
    if not pool then
        debugPrint("Cannot return to non-existent pool:", poolName)
        return false
    end
    
    if not pool.inUse[obj] then
        debugPrint("Object was not in use, might be double-returned or wrong pool")
        return false
    end
    
    -- Remove from in-use tracking
    pool.inUse[obj] = nil
    
    -- Add back to available pool
    table.insert(pool.available, obj)
    
    return true
end

-- Get pool statistics
function PerformanceManager:getPoolStats(poolName)
    local pool = self._pools[poolName]
    if not pool then
        return nil
    end
    
    local inUseCount = 0
    for _ in pairs(pool.inUse) do
        inUseCount = inUseCount + 1
    end
    
    return {
        available = #pool.available,
        inUse = inUseCount,
        total = pool.total
    }
end

--[[ Task Scheduling ]]--

-- Schedule a task for distributed execution
function PerformanceManager:scheduleTask(taskFunc, priority)
    local taskId = HttpService:GenerateGUID(false)
    
    self._scheduledTasks[taskId] = {
        func = taskFunc,
        priority = priority or "normal",
        added = os.clock()
    }
    
    return taskId
end

-- Cancel a scheduled task
function PerformanceManager:cancelTask(taskId)
    if self._scheduledTasks[taskId] then
        self._scheduledTasks[taskId] = nil
        return true
    end
    return false
end

-- Distribute tasks across heartbeats (called internally)
function PerformanceManager:_processScheduledTasks()
    -- Use modulo to distribute tasks across frames
    local currentTick = self._taskDistributionIndex
    self._taskDistributionIndex = (self._taskDistributionIndex + 1) % CONFIG.taskDistributionTicks
    
    -- Process tasks scheduled for this distribution tick
    local tasksToProcess = {}
    local index = 0
    
    -- First collect tasks according to priority
    for id, taskInfo in pairs(self._scheduledTasks) do
        if index % CONFIG.taskDistributionTicks == currentTick then
            table.insert(tasksToProcess, {id = id, taskInfo = taskInfo})
        end
        index = index + 1
    end
    
    -- Sort by priority and age
    table.sort(tasksToProcess, function(a, b)
        if a.taskInfo.priority == b.taskInfo.priority then
            return a.taskInfo.added < b.taskInfo.added -- Older tasks first
        end
        
        if a.taskInfo.priority == "high" then return true end
        if b.taskInfo.priority == "high" then return false end
        if a.taskInfo.priority == "normal" then return true end
        return false
    end)
    
    -- Process tasks
    local processCount = 0
    for _, taskData in ipairs(tasksToProcess) do
        -- Execute the task
        local success, result = pcall(taskData.taskInfo.func)
        
        -- Remove from scheduled tasks
        self._scheduledTasks[taskData.id] = nil
        
        -- Track statistics
        processCount = processCount + 1
        
        if not success then
            debugPrint("Task execution failed:", result)
        end
        
        -- Limit how many tasks we process per frame
        if processCount >= 5 then
            break
        end
    end
end

-- Run a heavy task with proper yield handling
function PerformanceManager:runHeavyTask(taskFunc)
    -- If another heavy task is already running, schedule this one
    if self._heavyTaskRunning then
        return self:scheduleTask(taskFunc, "normal")
    end
    
    -- Mark as running heavy task
    self._heavyTaskRunning = true
    
    -- Create a separate thread for the heavy task
    task.spawn(function()
        local success, result = pcall(taskFunc)
        
        if not success then
            debugPrint("Heavy task execution failed:", result)
        end
        
        -- Cooldown period before allowing another heavy task
        task.wait(CONFIG.heavyTaskCooldown)
        
        -- Mark as no longer running
        self._heavyTaskRunning = false
    end)
    
    return true
end

--[[ Detail Level Management ]]--

-- Set the global detail level
function PerformanceManager:setDetailLevel(level)
    if not table.find(CONFIG.detailLevels, level) then
        debugPrint("Invalid detail level:", level)
        return false
    end
    
    self._currentDetailLevel = level
    debugPrint("Detail level set to:", level)
    
    -- Notify systems about the detail level change
    if EventBridge then
        EventBridge:fireEvent("DetailLevelChanged", level)
        
        -- Also inform clients
        EventBridge:fireAllClients("DetailLevelChanged", {
            level = level,
            particleDensity = CONFIG.particleDensity[level] or 1.0,
            cullingDistances = CONFIG.cullingDistances
        })
    end
    
    return true
end

-- Get the current detail level
function PerformanceManager:getDetailLevel()
    return self._currentDetailLevel
end

-- Get system-specific update frequency based on detail level
function PerformanceManager:getUpdateFrequency(systemName)
    local detailLevel = self._currentDetailLevel
    
    if systemName == "NPCSystem" then
        return CONFIG.npcUpdateFrequency[detailLevel] or 1
    end
    
    -- Default to 1 (update every frame) if not specified
    return 1
end

--[[ Performance Monitoring ]]--

-- Start monitoring server performance
function PerformanceManager:startPerformanceMonitoring()
    if not CONFIG.monitoringEnabled then
        return
    end
    
    debugPrint("Starting performance monitoring")
    
    -- Set up server framerate monitoring
    self._monitoringLoops = self._monitoringLoops or {}
    
    -- Monitor server framerate
    self._monitoringLoops.framerate = task.spawn(function()
        local lastTime = os.clock()
        local frameCount = 0
        
        while CONFIG.monitoringEnabled do
            -- Count frames
            frameCount = frameCount + 1
            
            -- Check if it's time to calculate framerate
            local currentTime = os.clock()
            local elapsed = currentTime - lastTime
            
            if elapsed >= CONFIG.serverFramerateInterval then
                local fps = frameCount / elapsed
                
                -- Record the framerate
                table.insert(self._serverFramerateHistory, {
                    timestamp = os.time(),
                    fps = fps
                })
                
                -- Trim history if needed
                if #self._serverFramerateHistory > CONFIG.maxStatsHistory then
                    table.remove(self._serverFramerateHistory, 1)
                end
                
                -- Check if framerate is too low
                if fps < CONFIG.minAcceptableFrameRate and self._currentDetailLevel ~= "Minimal" then
                    debugPrint("Warning: Low server framerate:", fps, "FPS")
                    
                    if CONFIG.autoAdjustDetailLevel then
                        self:decreaseDetailLevel()
                    end
                end
                
                -- Reset for next interval
                frameCount = 0
                lastTime = currentTime
            end
            
            task.wait()
        end
    end)
    
    -- Monitor memory usage
    self._monitoringLoops.memory = task.spawn(function()
        while CONFIG.monitoringEnabled do
            task.wait(CONFIG.monitorInterval)
            
            -- Record memory usage
            local stats = self:getPerformanceStats()
            
            table.insert(self._memoryUsageHistory, {
                timestamp = os.time(),
                memoryMB = stats.memoryUsageMB
            })
            
            -- Trim history if needed
            if #self._memoryUsageHistory > CONFIG.maxStatsHistory then
                table.remove(self._memoryUsageHistory, 1)
            end
            
            -- Check if memory usage is too high
            if stats.memoryUsageMB > CONFIG.maxMemoryUsageMB then
                debugPrint("Warning: High memory usage:", stats.memoryUsageMB, "MB")
                
                -- Suggest garbage collection
                if os.clock() - self._lastGC > CONFIG.gcCollectInterval then
                    self._lastGC = os.clock()
                    local _ = collectgarbage("collect")
                    debugPrint("Suggested garbage collection due to high memory usage")
                end
                
                -- If still too high after garbage collection, decrease detail level
                task.wait(1) -- Wait for GC to complete
                stats = self:getPerformanceStats()
                
                if stats.memoryUsageMB > CONFIG.maxMemoryUsageMB and CONFIG.autoAdjustDetailLevel then
                    self:decreaseDetailLevel()
                end
            end
        end
    end)
    
    return true
end

-- Stop performance monitoring
function PerformanceManager:stopPerformanceMonitoring()
    if self._monitoringLoops then
        for _, loop in pairs(self._monitoringLoops) do
            task.cancel(loop)
        end
        self._monitoringLoops = {}
    end
    
    debugPrint("Performance monitoring stopped")
    return true
end

-- Get current performance statistics
function PerformanceManager:getPerformanceStats()
    local stats = {}
    
    -- Memory usage
    stats.memoryUsageMB = math.floor(collectgarbage("count") / 1024 * 100) / 100
    
    -- Current server framerate (from history)
    stats.serverFramerate = 0
    if #self._serverFramerateHistory > 0 then
        stats.serverFramerate = self._serverFramerateHistory[#self._serverFramerateHistory].fps
    end
    
    -- Active player count
    stats.playerCount = #Players:GetPlayers()
    
    -- Object pool stats
    stats.pools = {}
    for poolName, _ in pairs(self._pools) do
        stats.pools[poolName] = self:getPoolStats(poolName)
    end
    
    -- Task queue size
    stats.scheduledTaskCount = 0
    for _ in pairs(self._scheduledTasks) do
        stats.scheduledTaskCount = stats.scheduledTaskCount + 1
    end
    
    -- Current detail level
    stats.detailLevel = self._currentDetailLevel
    
    return stats
end

-- Record system performance metrics
function PerformanceManager:recordSystemPerformance(systemName, executionTime, operationType)
    if not CONFIG.recordPerformanceStats then
        return
    end
    
    -- Initialize system entry if needed
    if not self._systemMonitoring[systemName] then
        self._systemMonitoring[systemName] = {
            operationTimes = {},
            totalOperations = 0,
            totalExecutionTime = 0,
            maxExecutionTime = 0
        }
    end
    
    local system = self._systemMonitoring[systemName]
    
    -- Track operation type if specified
    if operationType then
        if not system.operationTimes[operationType] then
            system.operationTimes[operationType] = {
                count = 0,
                totalTime = 0,
                maxTime = 0
            }
        end
        
        -- Update operation metrics
        local op = system.operationTimes[operationType]
        op.count = op.count + 1
        op.totalTime = op.totalTime + executionTime
        op.maxTime = math.max(op.maxTime, executionTime)
    end
    
    -- Update system metrics
    system.totalOperations = system.totalOperations + 1
    system.totalExecutionTime = system.totalExecutionTime + executionTime
    system.maxExecutionTime = math.max(system.maxExecutionTime, executionTime)
end

-- Get a performance timer function for measuring execution time
function PerformanceManager:getTimingFunction(systemName, operationType)
    local startTime = os.clock()
    
    return function()
        local executionTime = os.clock() - startTime
        self:recordSystemPerformance(systemName, executionTime, operationType)
        return executionTime
    end
end

-- Get performance metrics for a specific system
function PerformanceManager:getSystemPerformance(systemName)
    return self._systemMonitoring[systemName] or {
        totalOperations = 0,
        totalExecutionTime = 0,
        maxExecutionTime = 0,
        operationTimes = {}
    }
end

-- Get all system performance metrics
function PerformanceManager:getAllSystemPerformance()
    return self._systemMonitoring
end

-- Reset performance metrics
function PerformanceManager:resetPerformanceMetrics()
    self._systemMonitoring = {}
    self._serverFramerateHistory = {}
    self._memoryUsageHistory = {}
    debugPrint("Performance metrics reset")
    return true
end

--[[ Detail Level Adjustment ]]--

-- Automatically decrease detail level
function PerformanceManager:decreaseDetailLevel()
    local currentLevel = self._currentDetailLevel
    local currentIndex = table.find(CONFIG.detailLevels, currentLevel)
    
    if not currentIndex or currentIndex >= #CONFIG.detailLevels then
        debugPrint("Already at lowest detail level or invalid current level")
        return false
    end
    
    local newLevel = CONFIG.detailLevels[currentIndex + 1]
    self:setDetailLevel(newLevel)
    
    debugPrint("Decreased detail level to:", newLevel)
    return true
end

-- Automatically increase detail level
function PerformanceManager:increaseDetailLevel()
    local currentLevel = self._currentDetailLevel
    local currentIndex = table.find(CONFIG.detailLevels, currentLevel)
    
    if not currentIndex or currentIndex <= 1 then
        debugPrint("Already at highest detail level or invalid current level")
        return false
    end
    
    local newLevel = CONFIG.detailLevels[currentIndex - 1]
    self:setDetailLevel(newLevel)
    
    debugPrint("Increased detail level to:", newLevel)
    return true
end

--[[ Player Density Management ]]--

-- Check player density in an area
function PerformanceManager:checkPlayerDensity(position, radius)
    radius = radius or CONFIG.playerDensityRadius
    local playerCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - position).Magnitude
            if distance <= radius then
                playerCount = playerCount + 1
            end
        end
    end
    
    return playerCount
end

-- Get optimization suggestions based on player density
function PerformanceManager:getPlayerDensityOptimizations(position, radius)
    local playerCount = self:checkPlayerDensity(position, radius)
    
    local optimizations = {
        reduceParticles = false,
        reduceAnimations = false,
        reduceSounds = false,
        reduceNPCs = false
    }
    
    -- Apply optimizations based on player density
    if playerCount > CONFIG.maxPlayersPerArea then
        -- High player density, suggest aggressive optimizations
        optimizations.reduceParticles = true
        optimizations.reduceSounds = true
        
        if playerCount > CONFIG.maxPlayersPerArea + 2 then
            optimizations.reduceAnimations = true
        end
        
        if playerCount > CONFIG.maxPlayersPerArea + 4 then
            optimizations.reduceNPCs = true
        end
    end
    
    return optimizations, playerCount
end

--[[ Memory Store Integration ]]--

-- Helper function to generate temporary data key
local function generateTempDataKey(category, id)
    return category .. "_" .. tostring(id)
end

-- Store temporary data with optional expiration
function PerformanceManager:setTempData(category, id, data, expirationSeconds)
    if not CONFIG.useMemoryStoreForTemp then
        -- Fallback to regular storage
        if not self._tempDataStorage then
            self._tempDataStorage = {}
        end
        
        local key = generateTempDataKey(category, id)
        self._tempDataStorage[key] = {
            data = data,
            expires = expirationSeconds and (os.time() + expirationSeconds) or nil
        }
        return true
    end
    
    -- Use MemoryStore when possible
    -- Implementation depends on how you want to structure your MemoryStore usage
    -- This is a placeholder for actual MemoryStore implementation
    
    return true
end

-- Get temporary data
function PerformanceManager:getTempData(category, id)
    if not CONFIG.useMemoryStoreForTemp then
        -- Fallback to regular storage
        if not self._tempDataStorage then
            return nil
        end
        
        local key = generateTempDataKey(category, id)
        local entry = self._tempDataStorage[key]
        
        if not entry then
            return nil
        end
        
        -- Check if expired
        if entry.expires and os.time() > entry.expires then
            self._tempDataStorage[key] = nil
            return nil
        end
        
        return entry.data
    end
    
    -- Use MemoryStore when possible
    -- Implementation depends on how you want to structure your MemoryStore usage
    -- This is a placeholder for actual MemoryStore implementation
    
    return nil
end

-- Clean expired temporary data
function PerformanceManager:cleanTempData()
    if not CONFIG.useMemoryStoreForTemp and self._tempDataStorage then
        local currentTime = os.time()
        local keysToRemove = {}
        
        for key, entry in pairs(self._tempDataStorage) do
            if entry.expires and currentTime > entry.expires then
                table.insert(keysToRemove, key)
            end
        end
        
        for _, key in ipairs(keysToRemove) do
            self._tempDataStorage[key] = nil
        end
        
        return #keysToRemove
    end
    
    return 0
end

--[[ Initialization and Core Functions ]]--

-- Initialize the PerformanceManager
function PerformanceManager:initialize()
    debugPrint("Initializing PerformanceManager...")
    
    -- Get dependencies
    EventBridge = CoreRegistry:getSystem("EventBridge")
    if not EventBridge then
        warn("EventBridge system not found, some functionality may be limited")
    end
    
    -- Register event handlers
    if EventBridge then
        -- Handle detail level change requests
        EventBridge:registerEvent("RequestDetailLevelChange")
        EventBridge:listenToEvent("RequestDetailLevelChange", function(level)
            self:setDetailLevel(level)
        end)
        
        -- Register additional events
        EventBridge:registerEvent("DetailLevelChanged")
        EventBridge:registerRemoteFunction("GetPerformanceStats", function()
            return self:getPerformanceStats()
        end)
        
        -- Create remote for admin performance monitoring
        EventBridge:registerRemoteFunction("RequestSystemPerformance", function(_, systemName)
            -- Could add permission check here if needed
            return systemName and self:getSystemPerformance(systemName) or self:getAllSystemPerformance()
        end)
    end
    
    -- Start performance monitoring
    self:startPerformanceMonitoring()
    
    -- Set up task distribution
    self._taskDistribution = RunService.Heartbeat:Connect(function()
        self:_processScheduledTasks()
    end)
    
    -- Set up temp data cleaning
    task.spawn(function()
        while true do
            task.wait(60) -- Clean every minute
            self:cleanTempData()
        end
    end)
    
    -- Set initial detail level
    self:setDetailLevel(CONFIG.defaultDetailLevel)
    
    debugPrint("PerformanceManager initialized")
    return true
end

-- Stop the PerformanceManager
function PerformanceManager:shutdown()
    -- Stop monitoring
    self:stopPerformanceMonitoring()
    
    -- Disconnect task distribution
    if self._taskDistribution then
        self._taskDistribution:Disconnect()
        self._taskDistribution = nil
    end
    
    debugPrint("PerformanceManager shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- Object pooling
    initializePool = function(poolName, createFunc, initialSize)
        return PerformanceManager:initializePool(poolName, createFunc, initialSize)
    end,
    
    growPool = function(poolName, count)
        return PerformanceManager:growPool(poolName, count)
    end,
    
    getFromPool = function(poolName)
        return PerformanceManager:getFromPool(poolName)
    end,
    
    returnToPool = function(poolName, obj)
        return PerformanceManager:returnToPool(poolName, obj)
    end,
    
    getPoolStats = function(poolName)
        return PerformanceManager:getPoolStats(poolName)
    end,
    
    -- Task scheduling
    scheduleTask = function(taskFunc, priority)
        return PerformanceManager:scheduleTask(taskFunc, priority)
    end,
    
    cancelTask = function(taskId)
        return PerformanceManager:cancelTask(taskId)
    end,
    
    runHeavyTask = function(taskFunc)
        return PerformanceManager:runHeavyTask(taskFunc)
    end,
    
    -- Detail level management
    getDetailLevel = function()
        return PerformanceManager:getDetailLevel()
    end,
    
    setDetailLevel = function(level)
        return PerformanceManager:setDetailLevel(level)
    end,
    
    increaseDetailLevel = function()
        return PerformanceManager:increaseDetailLevel()
    end,
    
    decreaseDetailLevel = function()
        return PerformanceManager:decreaseDetailLevel()
    end,
    
    getUpdateFrequency = function(systemName)
        return PerformanceManager:getUpdateFrequency(systemName)
    end,
    
    -- Performance monitoring
    getPerformanceStats = function()
        return PerformanceManager:getPerformanceStats()
    end,
    
    getTimingFunction = function(systemName, operationType)
        return PerformanceManager:getTimingFunction(systemName, operationType)
    end,
    
    recordSystemPerformance = function(systemName, executionTime, operationType)
        return PerformanceManager:recordSystemPerformance(systemName, executionTime, operationType)
    end,
    
    getSystemPerformance = function(systemName)
        return PerformanceManager:getSystemPerformance(systemName)
    end,
    
    getAllSystemPerformance = function()
        return PerformanceManager:getAllSystemPerformance()
    end,
    
    resetPerformanceMetrics = function()
        return PerformanceManager:resetPerformanceMetrics()
    end,
    
    -- Player density management
    checkPlayerDensity = function(position, radius)
        return PerformanceManager:checkPlayerDensity(position, radius)
    end,
    
    getPlayerDensityOptimizations = function(position, radius)
        return PerformanceManager:getPlayerDensityOptimizations(position, radius)
    end,
    
    -- Memory store integration
    setTempData = function(category, id, data, expirationSeconds)
        return PerformanceManager:setTempData(category, id, data, expirationSeconds)
    end,
    
    getTempData = function(category, id)
        return PerformanceManager:getTempData(category, id)
    end,
    
    cleanTempData = function()
        return PerformanceManager:cleanTempData()
    end,
    
    -- Core functions
    initialize = function()
        return PerformanceManager:initialize()
    end,
    
    shutdown = function()
        return PerformanceManager:shutdown()
    end,
    
    -- Config access
    getConfig = function()
        return CONFIG
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("PerformanceManager", PublicAPI, {"EventBridge"})