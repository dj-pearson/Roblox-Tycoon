-- TaskScheduler.server.luau
-- Central system for distributing tasks across frames to prevent performance spikes
-- Part of the Performance Optimization Framework

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local PerformanceManager

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    enabled = true,
    
    -- Task distribution settings
    taskDistributionTicks = 4,     -- Distribute tasks across this many heartbeats
    taskBatchSize = 5,             -- Max tasks to process per frame
    
    -- Priority levels and their weights (lower number = higher priority)
    priorities = {
        critical = 1,              -- Tasks that must run as soon as possible
        high = 2,                  -- High priority tasks (player-facing)
        normal = 3,                -- Standard tasks
        low = 4,                   -- Background tasks
        idle = 5                   -- Tasks to run only when system is idle
    },
    
    -- Frequency settings for recurring tasks
    frequencies = {
        everyFrame = 1,            -- Run every frame
        frequent = 5,              -- Every 5 frames
        normal = 15,               -- Every 15 frames
        infrequent = 30,           -- Every 30 frames
        rare = 60                  -- Every 60 frames
    }
}

-- Module table
local TaskScheduler = {
    Name = "TaskScheduler",
    Dependencies = {
        "CoreRegistry",
        "PerformanceManager"
    },
    
    -- Internal state
    _taskQueue = {},               -- Tasks waiting to be processed by priority
    _recurringTasks = {},          -- Tasks that run on a schedule
    _taskDistributionIndex = 0,    -- Current distribution tick
    _frameCount = 0,               -- Counter for recurring task frequency
    _taskIdCounter = 0,            -- Counter for generating task IDs
    _initialized = false           -- Whether the system is initialized
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[TaskScheduler]", ...)
    end
end

--[[ Task Queue Management ]]--

-- Add a task to the queue
function TaskScheduler:queueTask(taskFunc, priority, data)
    if not CONFIG.enabled or not taskFunc then return nil end
    
    -- Generate a unique task ID
    self._taskIdCounter = self._taskIdCounter + 1
    local taskId = self._taskIdCounter
    
    -- Default to normal priority if not specified
    priority = priority or "normal"
    if not CONFIG.priorities[priority] then
        priority = "normal"
    end
    
    -- Prepare the task info
    local taskInfo = {
        id = taskId,
        func = taskFunc,
        priority = priority,
        priorityValue = CONFIG.priorities[priority],
        added = os.clock(),
        data = data or {}
    }
    
    -- Add to the queue by priority
    if not self._taskQueue[priority] then
        self._taskQueue[priority] = {}
    end
    
    table.insert(self._taskQueue[priority], taskInfo)
    debugPrint("Task queued:", taskId, "with priority:", priority)
    
    return taskId
end

-- Cancel a queued task by its ID
function TaskScheduler:cancelTask(taskId)
    if not CONFIG.enabled or not taskId then return false end
    
    -- Search each priority queue
    for _, queue in pairs(self._taskQueue) do
        for i, task in ipairs(queue) do
            if task.id == taskId then
                table.remove(queue, i)
                debugPrint("Task cancelled:", taskId)
                return true
            end
        end
    end
    
    -- Also check recurring tasks
    for i, task in ipairs(self._recurringTasks) do
        if task.id == taskId then
            table.remove(self._recurringTasks, i)
            debugPrint("Recurring task cancelled:", taskId)
            return true
        end
    end
    
    return false
end

-- Process the task queue
function TaskScheduler:processTasks()
    if not CONFIG.enabled then return 0 end
    
    local processCount = 0
    local startTime = os.clock()
    
    -- Process by priority (lower number = higher priority)
    for p = 1, 5 do
        for priorityName, priorityValue in pairs(CONFIG.priorities) do
            if priorityValue == p and self._taskQueue[priorityName] then
                local queue = self._taskQueue[priorityName]
                
                -- Process up to batch size tasks from this priority
                local i = 1
                while i <= #queue and processCount < CONFIG.taskBatchSize do
                    local task = queue[i]
                    
                    -- Execute task with pcall for safety
                    local success, result = pcall(function()
                        return task.func(task.data)
                    end)
                    
                    if not success then
                        debugPrint("Task execution failed:", result)
                    end
                    
                    -- Remove the task
                    table.remove(queue, i)
                    processCount = processCount + 1
                    
                    -- Don't increment i since we removed an item
                end
                
                -- If we've reached batch size, exit
                if processCount >= CONFIG.taskBatchSize then
                    break
                end
            end
        end
        
        -- If we've reached batch size, exit
        if processCount >= CONFIG.taskBatchSize then
            break
        end
    end
    
    -- Performance tracking
    if processCount > 0 and PerformanceManager then
        local elapsed = os.clock() - startTime
        PerformanceManager:recordSystemPerformance("TaskScheduler", elapsed, "processTasks")
    end
    
    return processCount
end

--[[ Recurring Task Management ]]--

-- Schedule a task to run repeatedly
function TaskScheduler:scheduleRecurringTask(taskFunc, frequency, priority, data)
    if not CONFIG.enabled or not taskFunc then return nil end
    
    -- Generate a unique task ID
    self._taskIdCounter = self._taskIdCounter + 1
    local taskId = self._taskIdCounter
    
    -- Default values if not specified
    frequency = frequency or "normal"
    priority = priority or "normal"
    
    -- Convert string frequency to number
    local frequencyValue = frequency
    if type(frequency) == "string" and CONFIG.frequencies[frequency] then
        frequencyValue = CONFIG.frequencies[frequency]
    elseif type(frequency) ~= "number" then
        frequencyValue = CONFIG.frequencies.normal
    end
    
    -- Prepare the task info
    local taskInfo = {
        id = taskId,
        func = taskFunc,
        frequency = frequencyValue,
        lastRun = 0,               -- Frame counter when last run
        priority = priority,
        priorityValue = CONFIG.priorities[priority] or CONFIG.priorities.normal,
        data = data or {}
    }
    
    -- Add to recurring tasks
    table.insert(self._recurringTasks, taskInfo)
    debugPrint("Recurring task scheduled:", taskId, "with frequency:", frequency)
    
    return taskId
end

-- Process recurring tasks
function TaskScheduler:processRecurringTasks()
    if not CONFIG.enabled then return 0 end
    
    self._frameCount = self._frameCount + 1
    local processCount = 0
    local startTime = os.clock()
    
    -- Check each recurring task
    for _, task in ipairs(self._recurringTasks) do
        -- Check if it's time to run
        if (self._frameCount - task.lastRun) >= task.frequency then
            -- Execute task with pcall for safety
            local success, result = pcall(function()
                return task.func(task.data)
            end)
            
            if not success then
                debugPrint("Recurring task execution failed:", result)
            end
            
            -- Update last run time
            task.lastRun = self._frameCount
            processCount = processCount + 1
        end
    end
    
    -- Performance tracking
    if processCount > 0 and PerformanceManager then
        local elapsed = os.clock() - startTime
        PerformanceManager:recordSystemPerformance("TaskScheduler", elapsed, "processRecurringTasks")
    end
    
    return processCount
end

-- Get task queue statistics
function TaskScheduler:getQueueStats()
    local stats = {
        queuedTasks = 0,
        recurringTasks = #self._recurringTasks,
        byPriority = {}
    }
    
    -- Count tasks by priority
    for priority, queue in pairs(self._taskQueue) do
        local count = #queue
        stats.queuedTasks = stats.queuedTasks + count
        stats.byPriority[priority] = count
    end
    
    return stats
end

--[[ Initialization and Core Functions ]]--

-- Initialize the TaskScheduler
function TaskScheduler:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing TaskScheduler...")
    
    -- Get dependencies
    PerformanceManager = CoreRegistry:getSystem("PerformanceManager")
    if not PerformanceManager then
        warn("PerformanceManager not found, will operate without performance tracking")
    end
    
    -- Initialize task queue
    self._taskQueue = {
        critical = {},
        high = {},
        normal = {},
        low = {},
        idle = {}
    }
    
    -- Set up task processing
    self._taskDistribution = RunService.Heartbeat:Connect(function()
        -- Distribute tasks across heartbeats
        self._taskDistributionIndex = (self._taskDistributionIndex + 1) % CONFIG.taskDistributionTicks
        
        -- Only process on specific ticks for better distribution
        if self._taskDistributionIndex == 0 then
            self:processTasks()
        end
        
        -- Always process recurring tasks
        self:processRecurringTasks()
    end)
    
    self._initialized = true
    debugPrint("TaskScheduler initialized")
    return true
end

-- Stop the TaskScheduler
function TaskScheduler:shutdown()
    -- Disconnect task distribution
    if self._taskDistribution then
        self._taskDistribution:Disconnect()
        self._taskDistribution = nil
    end
    
    -- Clear task queues
    self._taskQueue = {}
    self._recurringTasks = {}
    
    self._initialized = false
    debugPrint("TaskScheduler shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- Task queue operations
    queueTask = function(taskFunc, priority, data)
        return TaskScheduler:queueTask(taskFunc, priority, data)
    end,
    
    cancelTask = function(taskId)
        return TaskScheduler:cancelTask(taskId)
    end,
    
    -- Recurring task operations
    scheduleRecurringTask = function(taskFunc, frequency, priority, data)
        return TaskScheduler:scheduleRecurringTask(taskFunc, frequency, priority, data)
    end,
    
    -- Queue information
    getQueueStats = function()
        return TaskScheduler:getQueueStats()
    end,
}

-- Initialize the system
TaskScheduler:initialize()

-- Register with CoreRegistry
if CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("TaskScheduler", PublicAPI)
end

return PublicAPI