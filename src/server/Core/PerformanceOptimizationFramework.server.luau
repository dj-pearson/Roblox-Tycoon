-- PerformanceOptimizationFramework.server.luau
-- Central system that coordinates performance optimization across the game
-- Part of the Performance Optimization Framework

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local ConfigManager
local TaskScheduler
local MemoryStoreManager
local PerformanceProfiler
local PerformanceManager -- Existing system
local EventBridge -- Existing system

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    enabled = true,
    
    -- Auto-optimization settings
    autoOptimizeEnabled = true,
    optimizationCheckInterval = 15, -- How often to check if optimization is needed (seconds)
    clientStatsUpdateInterval = 30, -- How often to collect client stats (seconds)
    
    -- Optimization thresholds
    serverFramerateThreshold = 25,   -- Server framerate below this triggers optimization
    serverMemoryThreshold = 3000,    -- Memory usage (MB) above this triggers optimization
    clientFramerateThreshold = 20,   -- Average client framerate below this triggers optimization
    clientPercentThreshold = 0.3,    -- Percentage of clients below threshold to trigger optimization
    
    -- Component-specific settings
    objectPoolingEnabled = true,
    staggeredUpdatesEnabled = true,
    dynamicDetailLevelsEnabled = true,
    distanceBasedOptimizationEnabled = true
}

-- Module table
local PerformanceOptimizationFramework = {
    Name = "PerformanceOptimizationFramework",
    Dependencies = {
        "CoreRegistry",
        "ConfigManager",
        "TaskScheduler",
        "MemoryStoreManager",
        "PerformanceProfiler",
        "PerformanceManager",
        "EventBridge"
    },
    
    -- Internal state
    _optimizationLoops = {},      -- Monitoring and optimization loops
    _clientStats = {},            -- Stats from connected clients
    _lastOptimization = 0,        -- Time of last optimization
    _initialized = false          -- Whether the system is initialized
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[PerformanceOptimizationFramework]", ...)
    end
end

--[[ Optimization Management ]]--

-- Check if optimization is needed based on server and client metrics
function PerformanceOptimizationFramework:checkNeedsOptimization()
    if not CONFIG.autoOptimizeEnabled then
        return false
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if currentTime - self._lastOptimization < 60 then -- At least 60 seconds between optimizations
        return false
    end
    
    local needsOptimization = false
    local reasons = {}
    
    -- Check server metrics if PerformanceProfiler is available
    if PerformanceProfiler then
        local serverMetrics = PerformanceProfiler:getServerPerformance()
        
        -- Check server framerate
        if serverMetrics.heartbeatTimeMs > (1000 / CONFIG.serverFramerateThreshold) then
            table.insert(reasons, "High server frametime: " .. serverMetrics.heartbeatTimeMs .. "ms")
            needsOptimization = true
        end
        
        -- Check server memory
        if serverMetrics.memoryUsageMB > CONFIG.serverMemoryThreshold then
            table.insert(reasons, "High server memory usage: " .. serverMetrics.memoryUsageMB .. "MB")
            needsOptimization = true
        end
    end
    
    -- Check client metrics
    if #self._clientStats > 0 then
        local lowFramerateClients = 0
        local totalClients = #self._clientStats
        
        for _, stats in ipairs(self._clientStats) do
            if stats.averageFramerate < CONFIG.clientFramerateThreshold then
                lowFramerateClients = lowFramerateClients + 1
            end
        end
        
        local percentLowFramerate = lowFramerateClients / totalClients
        if percentLowFramerate > CONFIG.clientPercentThreshold then
            table.insert(reasons, string.format("%.0f%% of clients have low framerate", percentLowFramerate * 100))
            needsOptimization = true
        end
    end
    
    if needsOptimization then
        debugPrint("Optimization needed, reasons:", table.concat(reasons, ", "))
    end
    
    return needsOptimization, reasons
end

-- Apply optimizations based on current metrics
function PerformanceOptimizationFramework:applyOptimizations()
    self._lastOptimization = os.time()
    debugPrint("Applying performance optimizations...")
    
    -- Record optimization start time for profiling
    local optimizationStartTime = os.clock()
    if PerformanceProfiler then
        PerformanceProfiler:startTracking("ApplyOptimizations", "performance")
    end
    
    -- 1. Apply server-side optimizations
    local currentDetailLevel = "High" -- Default
    if PerformanceManager then
        currentDetailLevel = PerformanceManager:getDetailLevel()
        
        -- Consider reducing detail level if not already at minimum
        if currentDetailLevel ~= "Minimal" then
            local serverPerformance = PerformanceProfiler and PerformanceProfiler:getServerPerformance() or {}
            
            -- Evaluate if we need to decrease detail level
            if serverPerformance.memoryUsageMB and serverPerformance.memoryUsageMB > CONFIG.serverMemoryThreshold * 1.2 then
                PerformanceManager:decreaseDetailLevel()
                debugPrint("Decreased server detail level due to high memory usage")
            end
            
            if serverPerformance.heartbeatTimeMs and serverPerformance.heartbeatTimeMs > (1000 / (CONFIG.serverFramerateThreshold * 0.8)) then
                PerformanceManager:decreaseDetailLevel()
                debugPrint("Decreased server detail level due to low framerate")
            end
            
            -- Apply detail level globally
            currentDetailLevel = PerformanceManager:getDetailLevel()
        end
    end
    
    -- 2. Apply system-specific optimizations
    
    -- NPC System optimizations
    local NPCSystem = CoreRegistry:getSystem("NPCSystem")
    if NPCSystem and CONFIG.staggeredUpdatesEnabled then
        -- This assumes NPCSystemPerformance extension is already set up
        local updateInterval = 1
        if currentDetailLevel == "Medium" then updateInterval = 2
        elseif currentDetailLevel == "Low" then updateInterval = 3
        elseif currentDetailLevel == "Minimal" then updateInterval = 4
        end
        
        -- Queue task to optimize NPC updates
        if TaskScheduler then
            TaskScheduler:queueTask(function()
                if NPCSystem.setupStaggeredUpdates then
                    NPCSystem:setupStaggeredUpdates(updateInterval)
                    debugPrint("Applied staggered updates to NPCSystem with interval:", updateInterval)
                end
            end, "high")
        end
    end
    
    -- Revenue System optimizations
    local RevenueSystem = CoreRegistry:getSystem("RevenueSystem")
    if RevenueSystem and CONFIG.staggeredUpdatesEnabled then
        -- Queue task to optimize revenue updates
        if TaskScheduler then
            TaskScheduler:queueTask(function()
                if RevenueSystem.setUpdateInterval then
                    local interval = 5 -- Default (seconds)
                    if currentDetailLevel == "Medium" then interval = 10
                    elseif currentDetailLevel == "Low" then interval = 15 
                    elseif currentDetailLevel == "Minimal" then interval = 30
                    end
                    
                    RevenueSystem:setUpdateInterval(interval)
                    debugPrint("Applied update interval to RevenueSystem:", interval)
                end
            end, "normal")
        end
    end
    
    -- Member Satisfaction System optimizations
    local MemberSatisfactionSystem = CoreRegistry:getSystem("MemberSatisfactionSystem")
    if MemberSatisfactionSystem and CONFIG.staggeredUpdatesEnabled then
        -- Queue task to optimize satisfaction updates
        if TaskScheduler then
            TaskScheduler:queueTask(function()
                if MemberSatisfactionSystem.setDecayInterval then
                    local interval = 10 -- Default (seconds)
                    if currentDetailLevel == "Medium" then interval = 15
                    elseif currentDetailLevel == "Low" then interval = 25
                    elseif currentDetailLevel == "Minimal" then interval = 40
                    end
                    
                    MemberSatisfactionSystem:setDecayInterval(interval)
                    debugPrint("Applied decay interval to MemberSatisfactionSystem:", interval)
                end
            end, "normal")
        end
    end
    
    -- 3. Apply client-side optimizations
    self:propagateClientOptimizations(currentDetailLevel)
    
    -- Record optimization metrics
    if PerformanceProfiler then
        local optimizationTime = os.clock() - optimizationStartTime
        PerformanceProfiler:endTracking("ApplyOptimizations", "performance", {
            detailLevel = currentDetailLevel,
            duration = optimizationTime
        })
        debugPrint("Optimizations applied in", optimizationTime, "seconds")
    end
    
    return true
end

-- Send optimizations to clients
function PerformanceOptimizationFramework:propagateClientOptimizations(detailLevel)
    if not EventBridge then return false end
    
    detailLevel = detailLevel or (PerformanceManager and PerformanceManager:getDetailLevel() or "High")
    
    -- Package optimization settings
    local optimizationSettings = {
        level = detailLevel,
        particleDensity = ConfigManager and ConfigManager:getValue("effectQuality." .. detailLevel .. ".particleDensity", 1.0) or 1.0,
        cullingDistances = ConfigManager and ConfigManager:getValue("distanceOptimization.cullingDistances") or CONFIG.cullingDistances
    }
    
    -- Send to all clients
    EventBridge:fireAllClients("DetailLevelChanged", optimizationSettings)
    debugPrint("Sent optimization settings to clients:", detailLevel)
    
    return true
end

--[[ Client Performance Tracking ]]--

-- Request performance statistics from a client
function PerformanceOptimizationFramework:requestClientStats(player)
    if not EventBridge then return nil end
    
    local success, stats
    
    -- Try to get enhanced stats first, fall back to regular stats
    success, stats = pcall(function()
        return EventBridge:invokeClient("RequestMemoryStats", player)
    end)
    
    if not success or not stats then
        success, stats = pcall(function()
            return EventBridge:invokeClient("GetPerformanceStats", player)
        end)
    end
    
    -- Process stats if successfully retrieved
    if success and stats then
        -- Store the client stats
        self._clientStats[player.UserId] = {
            player = player.Name,
            userId = player.UserId,
            averageFramerate = stats.averageFramerate,
            memorySizeMB = stats.memorySizeMB,
            detailLevel = stats.detailLevel,
            timestamp = os.time()
        }
        
        -- If enhanced stats are available, store additional info
        if stats.peakMemorySizeMB then
            self._clientStats[player.UserId].peakMemorySizeMB = stats.peakMemorySizeMB
        end
        
        if stats.playingSounds then
            self._clientStats[player.UserId].playingSounds = stats.playingSounds
        end
        
        return self._clientStats[player.UserId]
    end
    
    return nil
end

-- Get all client performance statistics
function PerformanceOptimizationFramework:getAllClientStats()
    -- Clean up stale stats first
    for userId, stats in pairs(self._clientStats) do
        -- Remove stats older than 2 minutes
        if os.time() - stats.timestamp > 120 then
            self._clientStats[userId] = nil
        end
    end
    
    return self._clientStats
end

-- Update client stats for all players
function PerformanceOptimizationFramework:updateAllClientStats()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:requestClientStats(player)
        end)
    end
    
    return true
end

--[[ Object Pooling Support ]]--

-- Initialize object pools for common game objects
function PerformanceOptimizationFramework:initializeObjectPools()
    if not CONFIG.objectPoolingEnabled or not PerformanceManager then
        return false
    end
    
    -- Check if pools are already initialized
    local NPCPoolStats = PerformanceManager:getPoolStats("NPCs")
    if NPCPoolStats then
        -- Pools already exist
        return true
    end
    
    debugPrint("Initializing object pools...")
    
    -- Initialize NPC pool
    if CoreRegistry:getSystem("NPCSystem") then
        local NPCSystem = CoreRegistry:getSystem("NPCSystem")
        local initialSize = ConfigManager and ConfigManager:getValue("pooling.initialPoolSizes.NPCs", 20) or 20
        
        -- Create a factory function for NPCs
        local npcCreateFunc = function()
            -- Find NPC template
            local template = ReplicatedStorage:FindFirstChild("NPC_Template")
            
            -- If not found in ReplicatedStorage, try other locations
            if not template then
                local serverStorage = game:GetService("ServerStorage")
                template = serverStorage:FindFirstChild("NPC_Template")
                
                -- If still not found, try looking inside a container
                if not template then
                    template = serverStorage:FindFirstChild("NPC_Character")
                    if template and template:FindFirstChild("NPC_Template") then
                        template = template:FindFirstChild("NPC_Template")
                    end
                end
            end
            
            -- Clone template if found
            if template then
                local npc = template:Clone()
                npc:SetAttribute("Pooled", true)
                npc:SetAttribute("InUse", false)
                return npc
            else
                warn("Could not find NPC template for pooling")
                return nil
            end
        end
        
        -- Initialize the pool
        PerformanceManager:initializePool("NPCs", npcCreateFunc, initialSize)
        debugPrint("Initialized NPC pool with size:", initialSize)
    end
    
    -- Initialize Effects pool
    local initialEffectSize = ConfigManager and ConfigManager:getValue("pooling.initialPoolSizes.Effects", 15) or 15
    
    -- Create a factory function for effects
    local effectCreateFunc = function()
        local effect = Instance.new("Part")
        effect.Name = "PooledEffect"
        effect.Anchored = true
        effect.CanCollide = false
        effect.Transparency = 1
        effect.Size = Vector3.new(0.5, 0.5, 0.5)
        
        local attachment = Instance.new("Attachment")
        attachment.Name = "EffectAttachment"
        attachment.Parent = effect
        
        effect:SetAttribute("Pooled", true)
        effect:SetAttribute("InUse", false)
        
        return effect
    end
    
    -- Initialize the effect pool
    PerformanceManager:initializePool("Effects", effectCreateFunc, initialEffectSize)
    debugPrint("Initialized Effects pool with size:", initialEffectSize)
    
    -- Initialize Basketball pool if needed
    if game.Workspace:FindFirstChild("Basketball") or ReplicatedStorage:FindFirstChild("Basketball") then
        local initialBasketballSize = ConfigManager and ConfigManager:getValue("pooling.initialPoolSizes.Basketballs", 5) or 5
        
        -- Create a factory function for basketballs
        local basketballCreateFunc = function()
            local template = ReplicatedStorage:FindFirstChild("Basketball")
            if not template then
                template = game.Workspace:FindFirstChild("Basketball")
            end
            
            if template then
                local ball = template:Clone()
                ball:SetAttribute("Pooled", true)
                ball:SetAttribute("InUse", false)
                return ball
            else
                warn("Could not find Basketball template for pooling")
                return nil
            end
        end
        
        -- Initialize the basketball pool
        PerformanceManager:initializePool("Basketballs", basketballCreateFunc, initialBasketballSize)
        debugPrint("Initialized Basketballs pool with size:", initialBasketballSize)
    end
    
    return true
end

--[[ Asset Preloading Management ]]--

-- Queue assets for client preloading
function PerformanceOptimizationFramework:preloadAssets(assets, player)
    if not EventBridge then return false end
    
    -- Package asset list
    local assetPackage = {}
    for _, assetInfo in ipairs(assets) do
        table.insert(assetPackage, {
            id = assetInfo.id,
            priority = assetInfo.priority or "normal"
        })
    end
    
    -- Send to specific player or all players
    if player then
        EventBridge:fireClient("PreloadAssets", player, assetPackage)
    else
        EventBridge:fireAllClients("PreloadAssets", assetPackage)
    end
    
    return true
end

--[[ Initialization and Core Functions ]]--

-- Start performance monitoring
function PerformanceOptimizationFramework:startPerformanceMonitoring()
    -- Set up auto-optimization loop
    if CONFIG.autoOptimizeEnabled then
        self._optimizationLoops.autoOptimize = task.spawn(function()
            while task.wait(CONFIG.optimizationCheckInterval) do
                local needsOptimization = self:checkNeedsOptimization()
                
                if needsOptimization then
                    self:applyOptimizations()
                end
            end
        end)
    end
    
    -- Set up client stats collection
    self._optimizationLoops.clientStats = task.spawn(function()
        while task.wait(CONFIG.clientStatsUpdateInterval) do
            self:updateAllClientStats()
        end
    end)
    
    -- Handle player joining to set up their client
    self._optimizationLoops.playerAdded = Players.PlayerAdded:Connect(function(player)
        -- Wait a bit for client to fully load
        task.delay(5, function()
            -- Send current detail level to new players
            local detailLevel = PerformanceManager and PerformanceManager:getDetailLevel() or "High"
            self:propagateClientOptimizations(detailLevel)
            
            -- Request initial stats
            task.delay(10, function()
                self:requestClientStats(player)
            end)
        end)
    end)
    
    -- Handle player leaving to clean up stats
    self._optimizationLoops.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self._clientStats[player.UserId] = nil
    end)
    
    debugPrint("Performance monitoring started")
    return true
end

-- Stop performance monitoring
function PerformanceOptimizationFramework:stopPerformanceMonitoring()
    for name, loop in pairs(self._optimizationLoops) do
        if typeof(loop) == "RBXScriptConnection" then
            loop:Disconnect()
        else
            task.cancel(loop)
        end
        self._optimizationLoops[name] = nil
    end
    
    debugPrint("Performance monitoring stopped")
    return true
end

-- Initialize the PerformanceOptimizationFramework
function PerformanceOptimizationFramework:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing PerformanceOptimizationFramework...")
    
    -- Get dependencies
    ConfigManager = CoreRegistry:getSystem("ConfigManager")
    if not ConfigManager then
        warn("ConfigManager not found, using default config values")
    else
        -- Update configuration with values from ConfigManager
        local configValues = {
            "debug",
            "enabled", 
            "autoOptimizeEnabled",
            "optimizationCheckInterval",
            "clientStatsUpdateInterval",
            "serverFramerateThreshold",
            "serverMemoryThreshold",
            "clientFramerateThreshold",
            "clientPercentThreshold",
            "objectPoolingEnabled",
            "staggeredUpdatesEnabled",
            "dynamicDetailLevelsEnabled",
            "distanceBasedOptimizationEnabled"
        }
        
        for _, key in ipairs(configValues) do
            local value = ConfigManager:getValue("performance." .. key)
            if value ~= nil then
                CONFIG[key] = value
            end
        end
    end
    
    TaskScheduler = CoreRegistry:getSystem("TaskScheduler")
    if not TaskScheduler then
        warn("TaskScheduler not found, optimization tasks will be limited")
    end
    
    MemoryStoreManager = CoreRegistry:getSystem("MemoryStoreManager")
    if not MemoryStoreManager then
        warn("MemoryStoreManager not found, performance metrics persistence will be disabled")
    end
    
    PerformanceProfiler = CoreRegistry:getSystem("PerformanceProfiler")
    if not PerformanceProfiler then
        warn("PerformanceProfiler not found, performance tracking will be limited")
    end
    
    PerformanceManager = CoreRegistry:getSystem("PerformanceManager")
    if not PerformanceManager then
        warn("PerformanceManager not found, optimization capabilities will be limited")
    end
    
    EventBridge = CoreRegistry:getSystem("EventBridge")
    if not EventBridge then
        warn("EventBridge not found, client-server communication will be disabled")
    end
    
    -- Register events
    if EventBridge then
        -- Register server function for requesting optimization
        EventBridge:registerEvent("RequestOptimization")
        EventBridge:listenToEvent("RequestOptimization", function(_, reason)
            local source = "Unknown"
            if source and source.Name then
                source = source.Name
            end
            
            debugPrint("Optimization requested by", source, "reason:", reason or "unspecified")
            self:applyOptimizations()
        end)
        
        -- Register client remote function for reporting issues
        EventBridge:registerRemoteFunction("ReportPerformanceIssue", function(player, issueData)
            debugPrint("Performance issue reported by", player.Name, ":", issueData.issue)
            
            -- Log issue to MemoryStore if available
            if MemoryStoreManager then
                issueData.playerName = player.Name
                issueData.userId = player.UserId
                issueData.timestamp = os.time()
                
                MemoryStoreManager:setValue("performance_issues", HttpService:GenerateGUID(false), issueData)
            end
            
            -- If serious issue, consider immediate optimization
            if issueData.severity == "high" then
                self:applyOptimizations()
            end
            
            return true
        end)
    end
    
    -- Initialize object pools
    self:initializeObjectPools()
    
    -- Start performance monitoring
    self:startPerformanceMonitoring()
    
    -- Apply initial optimizations based on server capabilities
    task.delay(10, function()
        self:applyOptimizations()
    end)
    
    self._initialized = true
    debugPrint("PerformanceOptimizationFramework initialized")
    return true
end

-- Stop the PerformanceOptimizationFramework
function PerformanceOptimizationFramework:shutdown()
    self:stopPerformanceMonitoring()
    self._initialized = false
    debugPrint("PerformanceOptimizationFramework shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- Core functions
    initialize = function()
        return PerformanceOptimizationFramework:initialize()
    end,
    
    shutdown = function()
        return PerformanceOptimizationFramework:shutdown()
    end,
    
    -- Optimization management
    checkNeedsOptimization = function()
        return PerformanceOptimizationFramework:checkNeedsOptimization()
    end,
    
    applyOptimizations = function()
        return PerformanceOptimizationFramework:applyOptimizations()
    end,
    
    propagateClientOptimizations = function(detailLevel)
        return PerformanceOptimizationFramework:propagateClientOptimizations(detailLevel)
    end,
    
    -- Client performance tracking
    requestClientStats = function(player)
        return PerformanceOptimizationFramework:requestClientStats(player)
    end,
    
    getAllClientStats = function()
        return PerformanceOptimizationFramework:getAllClientStats()
    end,
    
    updateAllClientStats = function()
        return PerformanceOptimizationFramework:updateAllClientStats()
    end,
    
    -- Object pooling
    initializeObjectPools = function()
        return PerformanceOptimizationFramework:initializeObjectPools()
    end,
    
    -- Asset preloading
    preloadAssets = function(assets, player)
        return PerformanceOptimizationFramework:preloadAssets(assets, player)
    end
}

-- Initialize the system
PerformanceOptimizationFramework:initialize()

-- Register with CoreRegistry
if CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("PerformanceOptimizationFramework", PublicAPI)
end

return PublicAPI