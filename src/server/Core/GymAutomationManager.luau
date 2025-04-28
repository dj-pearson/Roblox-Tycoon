--[[
    GymAutomationManager.luau
    Manager module for gym automation systems
    
    This module provides the management layer for gym automation,
    handling configuration, scheduling, and coordination between systems.
    
    Created: April 28, 2025
]]

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Module
local GymAutomationManager = {}

-- Constants
GymAutomationManager.VERSION = "1.0.0"
GymAutomationManager.DEBUG = true

-- Private variables
local initialized = false
local systemModules = {}
local taskSchedule = {}
local activeRoutines = {}
local maxConcurrentTasks = 5
local activeTaskCount = 0

-- GymAutomation core reference
local GymAutomation

-- Private functions
local function log(message, level)
    level = level or "Info"
    if not GymAutomationManager.DEBUG and level == "Debug" then return end
    
    print("[GymAutomationManager] " .. message)
end

local function findCoreRegistry()
    -- Try global access first
    if _G.CoreRegistry then
        return _G.CoreRegistry
    end
    
    -- Try common paths
    local coreFolder = ServerScriptService:FindFirstChild("Core") or ServerScriptService:FindFirstChild("Server")
    
    if coreFolder then
        local registryModule = coreFolder:FindFirstChild("CoreRegistry")
        
        if registryModule and registryModule:IsA("ModuleScript") then
            local success, registry = pcall(function() 
                return require(registryModule)
            end)
            
            if success then
                return registry
            end
        end
    end
    
    return nil
end

local function findGymAutomation()
    -- Try common paths
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    local gymAutomationModule = serverFolder and serverFolder:FindFirstChild("GymAutomation")
    
    if gymAutomationModule and gymAutomationModule:IsA("ModuleScript") then
        local success, module = pcall(function()
            return require(gymAutomationModule)
        end)
        
        if success then
            return module
        end
    end
    
    -- Try in src folder
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    if srcFolder then
        local serverSrcFolder = srcFolder:FindFirstChild("server")
        gymAutomationModule = serverSrcFolder and serverSrcFolder:FindFirstChild("GymAutomation")
        
        if gymAutomationModule and gymAutomationModule:IsA("ModuleScript") then
            local success, module = pcall(function()
                return require(gymAutomationModule)
            end)
            
            if success then
                return module
            end
        end
    end
    
    return nil
end

-- Initialization
function GymAutomationManager:initialize()
    if initialized then
        log("GymAutomationManager already initialized")
        return self
    end
    
    log("Initializing GymAutomationManager...")
    
    -- Try to register with CoreRegistry if available
    local coreRegistry = findCoreRegistry()
    if coreRegistry then
        log("Registering with CoreRegistry...")
        if coreRegistry.registerSystem then
            coreRegistry.registerSystem("GymAutomationManager", self)
            log("Successfully registered with CoreRegistry")
        else
            log("CoreRegistry missing registerSystem method", "Warning")
        end
    else
        log("CoreRegistry not found", "Warning")
    end
    
    -- Find and initialize GymAutomation
    GymAutomation = findGymAutomation()
    if GymAutomation then
        log("Found GymAutomation module, initializing...")
        
        -- Initialize if it has initialization method
        if GymAutomation.initialize then
            GymAutomation:initialize()
        end
        
        -- Register it as a system module
        self:registerSystemModule("GymAutomation", GymAutomation)
    else
        log("GymAutomation module not found", "Warning")
    end
    
    -- Set up task scheduler
    self:setupTaskScheduler()
    
    initialized = true
    log("GymAutomationManager initialized successfully")
    
    return self
end

-- Register system module
function GymAutomationManager:registerSystemModule(name, module)
    if not name or not module then
        log("Failed to register system module: missing parameters", "Warning")
        return false
    end
    
    -- Store module
    systemModules[name] = module
    
    log("Registered system module: " .. name)
    return true
end

-- Schedule a task
function GymAutomationManager:scheduleTask(taskName, taskFunc, interval, priority, options)
    if not taskName or not taskFunc or not interval then
        log("Failed to schedule task: missing parameters", "Warning")
        return false
    end
    
    -- Set default options
    options = options or {}
    priority = priority or 1 -- Higher number = higher priority
    
    -- Store task
    taskSchedule[taskName] = {
        func = taskFunc,
        interval = interval,
        priority = priority,
        options = options,
        lastRun = 0,
        running = false
    }
    
    log("Scheduled task: " .. taskName)
    return true
end

-- Run a scheduled task
function GymAutomationManager:runTask(taskName)
    local task = taskSchedule[taskName]
    if not task then
        log("Task not found: " .. taskName, "Warning")
        return false
    end
    
    if task.running then
        log("Task already running: " .. taskName, "Warning")
        return false
    end
    
    -- Check if we can run another task
    if activeTaskCount >= maxConcurrentTasks then
        log("Maximum concurrent tasks reached, deferring: " .. taskName, "Warning")
        return false
    end
    
    -- Mark as running
    task.running = true
    activeTaskCount = activeTaskCount + 1
    
    -- Run task
    task.lastRun = os.time()
    
    -- Start in a new thread to not block
    local routineId = taskName .. "_" .. os.time()
    log("Starting task: " .. taskName)
    
    activeRoutines[routineId] = task.spawn(function()
        local success, result = pcall(function()
            return task.func()
        end)
        
        -- Handle completion
        if success then
            log("Task completed successfully: " .. taskName)
        else
            log("Task failed: " .. taskName .. " - " .. tostring(result), "Error")
        end
        
        -- Mark as no longer running
        task.running = false
        activeTaskCount = activeTaskCount - 1
        activeRoutines[routineId] = nil
    end)
    
    return true
end

-- Setup task scheduler
function GymAutomationManager:setupTaskScheduler()
    log("Setting up task scheduler...")
    
    -- Start periodic task checking
    task.spawn(function()
        while true do
            task.wait(1) -- Check every second
            
            local now = os.time()
            local tasksByPriority = {}
            
            -- Collect tasks that are ready to run
            for name, task in pairs(taskSchedule) do
                if not task.running and (now - task.lastRun) >= task.interval then
                    -- Add to priority queue
                    local priority = task.priority
                    if not tasksByPriority[priority] then
                        tasksByPriority[priority] = {}
                    end
                    
                    table.insert(tasksByPriority[priority], name)
                end
            end
            
            -- Process tasks by priority
            for priority = 10, 1, -1 do -- 10 = highest priority
                local tasks = tasksByPriority[priority]
                if tasks then
                    for _, taskName in ipairs(tasks) do
                        if activeTaskCount < maxConcurrentTasks then
                            self:runTask(taskName)
                        else
                            break -- No more slots available
                        end
                    end
                end
            end
        end
    end)
end

-- Get status of all system modules
function GymAutomationManager:getSystemStatus()
    local status = {
        initialized = initialized,
        systemModules = {},
        activeTaskCount = activeTaskCount,
        scheduledTasks = 0
    }
    
    -- Count scheduled tasks
    for _ in pairs(taskSchedule) do
        status.scheduledTasks = status.scheduledTasks + 1
    end
    
    -- Get system module status
    for name, module in pairs(systemModules) do
        status.systemModules[name] = {
            available = true
        }
        
        -- Try to get version if available
        if module.VERSION then
            status.systemModules[name].version = module.VERSION
        end
        
        -- Try to get stats if available
        if module.getStats then
            local success, stats = pcall(function()
                return module:getStats()
            end)
            
            if success then
                status.systemModules[name].stats = stats
            end
        end
    end
    
    return status
end

-- Return the module
return GymAutomationManager
