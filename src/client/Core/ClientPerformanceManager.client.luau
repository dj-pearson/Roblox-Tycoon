-- ClientPerformanceManager.client.luau
-- Client-side performance optimization system
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core")

-- Load ClientRegistry
local ClientRegistry = require(CoreFolder:FindFirstChild("ClientRegistry"))
local ClientEventBridge

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    enabled = true,
    
    -- Performance monitoring
    monitoringEnabled = true,
    monitorInterval = 5,        -- How often to check performance stats (seconds)
    minAcceptableFrameRate = 20, -- Minimum acceptable client frame rate
    framerateAverageWindow = 6,  -- Number of samples to average for framerate
    
    -- Detail levels (matching server configuration)
    detailLevels = {
        "High",                  -- Full detail, all features enabled
        "Medium",                -- Reduced particle effects, fewer ambient sounds
        "Low",                   -- Minimal visual effects, reduced update frequency
        "Minimal"                -- Only essential systems running, bare minimum visuals
    },
    defaultDetailLevel = "High", -- Default detail level to start with
    autoAdjustDetailLevel = true, -- Automatically adjust detail level based on performance
    
    -- Particle optimization
    particleDensity = {
        High = 1.0,              -- 100% particle count
        Medium = 0.7,            -- 70% particle count
        Low = 0.3,               -- 30% particle count
        Minimal = 0.1            -- 10% particle count
    },
    
    -- Culling distances
    cullingDistances = {
        NPCs = 150,              -- Distance beyond which NPCs are culled (studs)
        Effects = 100,           -- Distance beyond which effects are culled
        DetailProps = 75,        -- Distance beyond which decorative props are culled
        Sounds = 50              -- Distance beyond which ambient sounds are culled
    },
    
    -- Visual effects
    disableBlur = {
        High = false,
        Medium = false,
        Low = true,
        Minimal = true
    },
    disableBloom = {
        High = false,
        Medium = false,
        Low = true,
        Minimal = true
    },
    disableDepthOfField = {
        High = false,
        Medium = true,
        Low = true,
        Minimal = true
    },
    disableColorCorrection = {
        High = false,
        Medium = false,
        Low = true,
        Minimal = true
    },
    
    -- Rendering options
    renderDistance = {
        High = 2000,             -- Default Roblox render distance
        Medium = 1200,
        Low = 800,
        Minimal = 500
    },
    
    -- UI optimizations
    animateUI = {
        High = true,
        Medium = true,
        Low = false,
        Minimal = false
    },
    
    -- Task scheduling
    taskDistributionTicks = 3,   -- Distribute tasks across this many heartbeats
    
    -- Performance telemetry
    recordPerformanceStats = true, -- Record performance stats for later analysis
    maxStatsHistory = 100,       -- Maximum number of performance stats to keep
    
    -- Asset management
    assetPreloadingEnabled = true,   -- Whether to preload frequently used assets
    assetPreloadBatchSize = 5,       -- How many assets to preload per frame
    assetPreloadDelay = 0.1,         -- Delay between preload batches
    
    -- Memory management
    gcCollectInterval = 300,         -- How often to suggest garbage collection (seconds)
    textureReductionEnabled = true,  -- Whether to reduce textures in low memory situations
    textureQuality = {
        High = 1.0,                  -- 100% texture quality
        Medium = 0.75,               -- 75% texture quality
        Low = 0.5,                   -- 50% texture quality
        Minimal = 0.25               -- 25% texture quality
    },
    
    -- Sound management
    maxConcurrentSounds = {
        High = 32,                   -- Maximum concurrent sounds at high detail
        Medium = 24,                 -- Maximum concurrent sounds at medium detail
        Low = 16,                    -- Maximum concurrent sounds at low detail
        Minimal = 8                  -- Maximum concurrent sounds at minimal detail
    },
    soundDistanceMultiplier = {
        High = 1.0,                  -- 100% sound distance
        Medium = 0.8,                -- 80% sound distance (sounds fade out sooner)
        Low = 0.6,                   -- 60% sound distance
        Minimal = 0.4                -- 40% sound distance
    }
}

-- Module table
local ClientPerformanceManager = {
    -- Internal state
    _currentDetailLevel = CONFIG.defaultDetailLevel,
    _scheduledTasks = {},        -- Tasks scheduled for future execution
    _taskDistributionIndex = 0,  -- Current index for distributing tasks
    _frameRateHistory = {},      -- Track framerate over time
    _lastFrameTime = tick(),     -- Last frame time for framerate calculation
    _originalEffects = {},       -- Original Lighting effects storage
    _framerateBuffer = {},       -- Buffer for averaging framerate
    _systemMonitoring = {},      -- Track performance of individual systems
    _initialized = false,        -- Whether the system has been initialized
    _soundRegistry = {},         -- Registry of active sounds
    _textureCache = {},          -- Cache of texture reduction state
    _assetLoadQueue = {},        -- Queue for asset loading
    _lastGC = os.clock(),        -- Time of last garbage collection
    _memoryUsageHistory = {}     -- Track memory usage over time
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[ClientPerformanceManager]", ...)
    end
end

--[[ Detail Level Management ]]--

-- Set detail level and apply optimizations
function ClientPerformanceManager:setDetailLevel(level, skipEffects)
    if not table.find(CONFIG.detailLevels, level) then
        debugPrint("Invalid detail level:", level)
        return false
    end
    
    self._currentDetailLevel = level
    debugPrint("Detail level set to:", level)
    
    -- Apply visual effects settings based on detail level
    if not skipEffects then
        self:applyVisualEffects(level)
    end
    
    -- Notify other client systems about the detail level change
    if ClientEventBridge then
        ClientEventBridge:fireEvent("ClientDetailLevelChanged", {
            level = level,
            particleDensity = CONFIG.particleDensity[level] or 1.0,
            animateUI = CONFIG.animateUI[level]
        })
    end
    
    return true
end

-- Get the current detail level
function ClientPerformanceManager:getDetailLevel()
    return self._currentDetailLevel
end

-- Apply visual effects based on detail level
function ClientPerformanceManager:applyVisualEffects(detailLevel)
    local currentLevel = detailLevel or self._currentDetailLevel
    
    -- Handle lighting effects
    -- First time, store original values
    if not self._effectsStored then
        self:storeOriginalEffects()
        self._effectsStored = true
    end
    
    -- Note: We no longer try to set workspace.FalloffEnd directly as it's read-only
    -- Instead we'll use other optimization methods
    
    -- Adjust blur
    local blur = Lighting:FindFirstChildOfClass("BlurEffect")
    if blur then
        blur.Enabled = not CONFIG.disableBlur[currentLevel]
    end
    
    -- Adjust bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        bloom.Enabled = not CONFIG.disableBloom[currentLevel]
    end
    
    -- Adjust depth of field
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if dof then
        dof.Enabled = not CONFIG.disableDepthOfField[currentLevel]
    end
    
    -- Adjust color correction
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if colorCorrection then
        colorCorrection.Enabled = not CONFIG.disableColorCorrection[currentLevel]
    end
    
    -- Apply any other visual settings
    if currentLevel == "Minimal" then
        -- Most aggressive optimizations for minimal mode
        pcall(function()
            settings().Rendering.QualityLevel = 1 -- Lowest quality level
        end)
    elseif currentLevel == "Low" then
        pcall(function()
            settings().Rendering.QualityLevel = 4
        end)
    elseif currentLevel == "Medium" then
        pcall(function()
            settings().Rendering.QualityLevel = 7
        end)
    else -- High
        pcall(function()
            settings().Rendering.QualityLevel = 10 -- Highest quality level
        end)
    end
    
    debugPrint("Applied visual effects for detail level:", currentLevel)
    return true
end

-- Store the original lighting effects settings
function ClientPerformanceManager:storeOriginalEffects()
    self._originalEffects = {}
    
    -- No longer try to store FalloffEnd as it's read-only
    
    -- Store Lighting effects
    local blur = Lighting:FindFirstChildOfClass("BlurEffect")
    if blur then
        self._originalEffects.blur = {
            Enabled = blur.Enabled,
            Size = blur.Size
        }
    end
    
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        self._originalEffects.bloom = {
            Enabled = bloom.Enabled,
            Intensity = bloom.Intensity,
            Size = bloom.Size,
            Threshold = bloom.Threshold
        }
    end
    
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if dof then
        self._originalEffects.dof = {
            Enabled = dof.Enabled,
            FarIntensity = dof.FarIntensity,
            FocusDistance = dof.FocusDistance,
            InFocusRadius = dof.InFocusRadius,
            NearIntensity = dof.NearIntensity
        }
    end
    
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if colorCorrection then
        self._originalEffects.colorCorrection = {
            Enabled = colorCorrection.Enabled,
            Brightness = colorCorrection.Brightness,
            Contrast = colorCorrection.Contrast,
            Saturation = colorCorrection.Saturation,
            TintColor = colorCorrection.TintColor
        }
    end
    
    debugPrint("Stored original lighting effects")
end

-- Restore original lighting effects settings
function ClientPerformanceManager:restoreOriginalEffects()
    if not self._effectsStored then
        return false
    end
    
    -- No longer try to restore FalloffEnd as it's read-only
    
    -- Restore blur
    local blur = Lighting:FindFirstChildOfClass("BlurEffect")
    if blur and self._originalEffects.blur then
        blur.Enabled = self._originalEffects.blur.Enabled
        blur.Size = self._originalEffects.blur.Size
    end
    
    -- Restore bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom and self._originalEffects.bloom then
        bloom.Enabled = self._originalEffects.bloom.Enabled
        bloom.Intensity = self._originalEffects.bloom.Intensity
        bloom.Size = self._originalEffects.bloom.Size
        bloom.Threshold = self._originalEffects.bloom.Threshold
    end
    
    -- Restore depth of field
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if dof and self._originalEffects.dof then
        dof.Enabled = self._originalEffects.dof.Enabled
        dof.FarIntensity = self._originalEffects.dof.FarIntensity
        dof.FocusDistance = self._originalEffects.dof.FocusDistance
        dof.InFocusRadius = self._originalEffects.dof.InFocusRadius
        dof.NearIntensity = self._originalEffects.dof.NearIntensity
    end
    
    -- Restore color correction
    local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if colorCorrection and self._originalEffects.colorCorrection then
        colorCorrection.Enabled = self._originalEffects.colorCorrection.Enabled
        colorCorrection.Brightness = self._originalEffects.colorCorrection.Brightness
        colorCorrection.Contrast = self._originalEffects.colorCorrection.Contrast
        colorCorrection.Saturation = self._originalEffects.colorCorrection.Saturation
        colorCorrection.TintColor = self._originalEffects.colorCorrection.TintColor
    end
    
    debugPrint("Restored original lighting effects")
    return true
end

--[[ Particle System Management ]]--

-- Adjust particle emitter properties based on current detail level
function ClientPerformanceManager:optimizeParticleEmitter(emitter)
    local level = self._currentDetailLevel
    local multiplier = CONFIG.particleDensity[level] or 1.0
    
    if not emitter:IsA("ParticleEmitter") then
        return false
    end
    
    -- Store original values if not already stored
    if not emitter:GetAttribute("OriginalRate") then
        emitter:SetAttribute("OriginalRate", emitter.Rate)
    end
    
    -- Apply rate adjustment
    local originalRate = emitter:GetAttribute("OriginalRate")
    emitter.Rate = originalRate * multiplier
    
    -- For minimal detail level, also reduce lifetime and speed
    if level == "Minimal" or level == "Low" then
        if not emitter:GetAttribute("OriginalLifetime") then
            if typeof(emitter.Lifetime) == "NumberRange" then
                emitter:SetAttribute("OriginalLifetimeMin", emitter.Lifetime.Min)
                emitter:SetAttribute("OriginalLifetimeMax", emitter.Lifetime.Max)
            else
                emitter:SetAttribute("OriginalLifetime", emitter.Lifetime)
            end
        end
        
        -- Reduce lifetime by 25%
        if typeof(emitter.Lifetime) == "NumberRange" then
            local min = emitter:GetAttribute("OriginalLifetimeMin") * 0.75
            local max = emitter:GetAttribute("OriginalLifetimeMax") * 0.75
            emitter.Lifetime = NumberRange.new(min, max)
        else
            emitter.Lifetime = emitter:GetAttribute("OriginalLifetime") * 0.75
        end
    else
        -- Restore original lifetime
        if emitter:GetAttribute("OriginalLifetime") then
            emitter.Lifetime = emitter:GetAttribute("OriginalLifetime")
        elseif emitter:GetAttribute("OriginalLifetimeMin") then
            local min = emitter:GetAttribute("OriginalLifetimeMin")
            local max = emitter:GetAttribute("OriginalLifetimeMax")
            emitter.Lifetime = NumberRange.new(min, max)
        end
    end
    
    return true
end

-- Optimize all particle emitters in a model
function ClientPerformanceManager:optimizeParticles(model)
    if not model then return 0 end
    
    local count = 0
    
    -- Process all ParticleEmitters
    for _, emitter in ipairs(model:GetDescendants()) do
        if emitter:IsA("ParticleEmitter") then
            if self:optimizeParticleEmitter(emitter) then
                count = count + 1
            end
        end
    end
    
    return count
end

--[[ Task Scheduling ]]--

-- Schedule a task for distributed execution
function ClientPerformanceManager:scheduleTask(taskFunc, priority)
    local taskId = HttpService:GenerateGUID(false)
    
    self._scheduledTasks[taskId] = {
        func = taskFunc,
        priority = priority or "normal",
        added = os.clock()
    }
    
    return taskId
end

-- Cancel a scheduled task
function ClientPerformanceManager:cancelTask(taskId)
    if self._scheduledTasks[taskId] then
        self._scheduledTasks[taskId] = nil
        return true
    end
    return false
end

-- Distribute tasks across heartbeats (called internally)
function ClientPerformanceManager:_processScheduledTasks()
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

--[[ Performance Monitoring ]]--

-- Start monitoring client performance
function ClientPerformanceManager:startPerformanceMonitoring()
    if not CONFIG.monitoringEnabled then
        return
    end
    
    debugPrint("Starting performance monitoring")
    
    -- Set up framerate monitoring
    self._monitoringLoops = self._monitoringLoops or {}
    
    -- Measure framerate on RenderStepped
    self._monitoringLoops.framerate = RunService.RenderStepped:Connect(function(deltaTime)
        -- Calculate framerate
        local fps = 1 / deltaTime
        
        -- Add to buffer for averaging
        table.insert(self._framerateBuffer, fps)
        
        -- Keep buffer at proper size
        if #self._framerateBuffer > CONFIG.framerateAverageWindow then
            table.remove(self._framerateBuffer, 1)
        end
    end)
    
    -- Process framerate and make adjustments
    self._monitoringLoops.process = task.spawn(function()
        while task.wait(CONFIG.monitorInterval) do
            -- Get average framerate
            local averageFPS = self:getAverageFramerate()
            
            -- Record in history
            table.insert(self._frameRateHistory, {
                timestamp = os.time(),
                fps = averageFPS
            })
            
            -- Trim history if needed
            if #self._frameRateHistory > CONFIG.maxStatsHistory then
                table.remove(self._frameRateHistory, 1)
            end
            
            -- Check if framerate is too low
            if averageFPS < CONFIG.minAcceptableFrameRate and self._currentDetailLevel ~= "Minimal" then
                debugPrint("Warning: Low framerate:", averageFPS, "FPS")
                
                if CONFIG.autoAdjustDetailLevel then
                    self:decreaseDetailLevel()
                end
            elseif averageFPS > CONFIG.minAcceptableFrameRate * 2 and self._currentDetailLevel ~= "High" then
                -- Possibly increase detail level if framerate is very good
                if CONFIG.autoAdjustDetailLevel then
                    -- Only increase if consistently good performance
                    if #self._frameRateHistory >= 3 then
                        local consistentlyGood = true
                        for i = #self._frameRateHistory - 2, #self._frameRateHistory do
                            if self._frameRateHistory[i].fps < CONFIG.minAcceptableFrameRate * 1.8 then
                                consistentlyGood = false
                                break
                            end
                        end
                        
                        if consistentlyGood then
                            self:increaseDetailLevel()
                        end
                    end
                end
            end
        end
    end)
    
    return true
end

-- Stop performance monitoring
function ClientPerformanceManager:stopPerformanceMonitoring()
    if self._monitoringLoops then
        for _, loop in pairs(self._monitoringLoops) do
            if typeof(loop) == "RBXScriptConnection" then
                loop:Disconnect()
            else
                task.cancel(loop)
            end
        end
        self._monitoringLoops = {}
    end
    
    debugPrint("Performance monitoring stopped")
    return true
end

-- Get average framerate from buffer
function ClientPerformanceManager:getAverageFramerate()
    if #self._framerateBuffer == 0 then
        return 60 -- Default if no data
    end
    
    local sum = 0
    for _, fps in ipairs(self._framerateBuffer) do
        sum = sum + fps
    end
    
    return sum / #self._framerateBuffer
end

-- Get current performance statistics
function ClientPerformanceManager:getPerformanceStats()
    local stats = {}
    
    -- Framerate
    stats.averageFramerate = self:getAverageFramerate()
    stats.framerateHistory = self._frameRateHistory
    
    -- Memory usage
    stats.memorySizeMB = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb() * 100) / 100
    
    -- Task queue size
    stats.scheduledTaskCount = 0
    for _ in pairs(self._scheduledTasks) do
        stats.scheduledTaskCount = stats.scheduledTaskCount + 1
    end
    
    -- Detail level
    stats.detailLevel = self._currentDetailLevel
    
    -- GPU stats if available
    pcall(function()
        stats.gpuMemory = game:GetService("Stats").VideoMemory
    end)
    
    return stats
end

--[[ Performance Metrics ]]--

-- Record system performance metrics
function ClientPerformanceManager:recordSystemPerformance(systemName, executionTime, operationType)
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
function ClientPerformanceManager:getTimingFunction(systemName, operationType)
    local startTime = os.clock()
    
    return function()
        local executionTime = os.clock() - startTime
        self:recordSystemPerformance(systemName, executionTime, operationType)
        return executionTime
    end
end

-- Get performance metrics for a specific system
function ClientPerformanceManager:getSystemPerformance(systemName)
    return self._systemMonitoring[systemName] or {
        totalOperations = 0,
        totalExecutionTime = 0,
        maxExecutionTime = 0,
        operationTimes = {}
    }
end

-- Get all system performance metrics
function ClientPerformanceManager:getAllSystemPerformance()
    return self._systemMonitoring
end

-- Reset performance metrics
function ClientPerformanceManager:resetPerformanceMetrics()
    self._systemMonitoring = {}
    self._frameRateHistory = {}
    debugPrint("Performance metrics reset")
    return true
end

--[[ Detail Level Adjustment ]]--

-- Automatically decrease detail level
function ClientPerformanceManager:decreaseDetailLevel()
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
function ClientPerformanceManager:increaseDetailLevel()
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

--[[ Initialization and Core Functions ]]--

-- Initialize the ClientPerformanceManager
function ClientPerformanceManager:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing ClientPerformanceManager...")
    
    -- Get dependencies
    ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
    if not ClientEventBridge then
        warn("ClientEventBridge system not found, functionality will be limited")
        -- Still continue initialization
    end
    
    -- Register event handlers
    if ClientEventBridge then
        -- Handle server detail level changes
        ClientEventBridge:registerServerEvent("DetailLevelChanged", function(data)
            -- Server is requesting a detail level change
            self:setDetailLevel(data.level)
            
            -- Update culling distances
            CONFIG.cullingDistances = data.cullingDistances or CONFIG.cullingDistances
            
            -- Update other config values that may be sent from server
            if data.particleDensity then
                CONFIG.particleDensity[data.level] = data.particleDensity
            end
        end)
        
        -- Register for local events
        ClientEventBridge:registerEvent("OptimizeParticles")
        ClientEventBridge:listenToEvent("OptimizeParticles", function(model)
            self:optimizeParticles(model)
        end)
        
        -- Register client detail level change event
        ClientEventBridge:registerEvent("ClientDetailLevelChanged")
    end
    
    -- Set up task distribution
    self._taskDistribution = RunService.Heartbeat:Connect(function()
        self:_processScheduledTasks()
    end)
    
    -- Start performance monitoring
    self:startPerformanceMonitoring()
    
    -- Set initial detail level
    self:setDetailLevel(CONFIG.defaultDetailLevel)
    
    self._initialized = true
    debugPrint("ClientPerformanceManager initialized")
    return true
end

-- Apply optimizations to the character
function ClientPerformanceManager:optimizeCharacter(character)
    if not character then
        return false
    end
    
    -- Optimize any particles in the character
    self:optimizeParticles(character)
    
    -- Apply additional character-specific optimizations based on detail level
    local level = self._currentDetailLevel
    
    -- Example: Adjust animations or accessories based on detail level
    if level == "Minimal" or level == "Low" then
        -- Possibly disable some cosmetic accessories
        for _, accessory in ipairs(character:GetChildren()) do
            if accessory:IsA("Accessory") and accessory:GetAttribute("Cosmetic") then
                accessory.Handle.Transparency = 1
            end
        end
    end
    
    return true
end

-- Stop the ClientPerformanceManager
function ClientPerformanceManager:shutdown()
    -- Stop monitoring
    self:stopPerformanceMonitoring()
    
    -- Disconnect task distribution
    if self._taskDistribution then
        self._taskDistribution:Disconnect()
        self._taskDistribution = nil
    end
    
    -- Restore original effects
    self:restoreOriginalEffects()
    
    self._initialized = false
    debugPrint("ClientPerformanceManager shut down")
    return true
end

-- Initialize when character spawns
local function onCharacterAdded(character)
    -- Optimize the character
    task.spawn(function()
        ClientPerformanceManager:optimizeCharacter(character)
    end)
end

-- Handle character spawning
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- If character already exists, optimize it
if LocalPlayer.Character then
    task.spawn(function()
        ClientPerformanceManager:optimizeCharacter(LocalPlayer.Character)
    end)
end

--[[ Asset Loading Management ]]--

-- Schedule an asset for preloading
function ClientPerformanceManager:preloadAsset(assetId, priority)
    if not CONFIG.assetPreloadingEnabled then
        return false
    end
    
    local currentLevel = self._currentDetailLevel
    if currentLevel == "Low" or currentLevel == "Minimal" then
        -- Don't preload assets at low detail levels
        return false
    end
    
    -- Add to loading queue with priority
    table.insert(self._assetLoadQueue, {
        id = assetId,
        priority = priority or "normal",
        added = os.clock()
    })
    
    return true
end

-- Process asset preload queue
function ClientPerformanceManager:processAssetLoadQueue()
    if #self._assetLoadQueue == 0 or not CONFIG.assetPreloadingEnabled then
        return 0
    end
    
    -- Sort by priority
    table.sort(self._assetLoadQueue, function(a, b)
        if a.priority == b.priority then
            return a.added < b.added -- Older first
        end
        
        if a.priority == "high" then return true end
        if b.priority == "high" then return false end
        if a.priority == "normal" then return true end
        return false
    end)
    
    -- Create a batch to preload
    local batch = {}
    local batchSize = math.min(CONFIG.assetPreloadBatchSize, #self._assetLoadQueue)
    
    for i = 1, batchSize do
        table.insert(batch, self._assetLoadQueue[i])
    end
    
    -- Remove batch from queue
    for i = 1, #batch do
        table.remove(self._assetLoadQueue, 1)
    end
    
    -- Preload assets in batch
    task.spawn(function()
        for _, asset in ipairs(batch) do
            pcall(function()
                ContentProvider:PreloadAsync({asset.id})
            end)
            task.wait(CONFIG.assetPreloadDelay)
        end
    end)
    
    return #batch
end

-- Start asset preload processing
function ClientPerformanceManager:startAssetPreloader()
    task.spawn(function()
        while task.wait(1) do -- Check every second
            if self._initialized and #self._assetLoadQueue > 0 then
                self:processAssetLoadQueue()
            end
        end
    end)
    
    debugPrint("Asset preloader started")
    return true
end

--[[ Memory Management ]]--

-- Check memory usage and optimize if needed
function ClientPerformanceManager:checkMemoryUsage()
    local memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
    
    -- Record memory usage
    table.insert(self._memoryUsageHistory, {
        timestamp = os.time(),
        memoryMB = memoryUsage
    })
    
    -- Limit history size
    if #self._memoryUsageHistory > CONFIG.maxStatsHistory then
        table.remove(self._memoryUsageHistory, 1)
    end
    
    -- Check for high memory usage
    local highMemoryThreshold = 1800 -- 1.8GB is a reasonable warning threshold
    
    if memoryUsage > highMemoryThreshold then
        debugPrint("Warning: High memory usage:", memoryUsage, "MB")
        
        -- Suggest garbage collection
        if os.clock() - self._lastGC > CONFIG.gcCollectInterval then
            self._lastGC = os.clock()
            
            -- Use proper Luau garbage collection
            task.desynchronize()
            task.synchronize()
            
            debugPrint("Suggested garbage collection due to high memory usage")
        end
        
        -- If still too high after garbage collection, apply more aggressive optimizations
        task.wait(1) -- Wait for GC to complete
        memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
        
        if memoryUsage > highMemoryThreshold and CONFIG.textureReductionEnabled then
            self:applyTextureReduction()
        end
        
        -- If extreme case, decrease detail level
        if memoryUsage > highMemoryThreshold * 1.2 and CONFIG.autoAdjustDetailLevel and self._currentDetailLevel ~= "Minimal" then
            self:decreaseDetailLevel()
        end
    end
    
    return memoryUsage
end

-- Apply texture quality reduction
function ClientPerformanceManager:applyTextureReduction()
    local currentLevel = self._currentDetailLevel
    local qualityMultiplier = CONFIG.textureQuality[currentLevel] or 1.0
    
    -- Try to enable texture quality reduction
    pcall(function()
        settings().Rendering.TextureQuality = qualityMultiplier
    end)
    
    -- Queue clearing cached content
    self:scheduleTask(function()
        pcall(function()
            game:GetService("ContentProvider"):SetBaseUrl("")
            game:GetService("ContentProvider"):SetBaseUrl("https://www.roblox.com/")
        end)
    end, "low")
    
    debugPrint("Applied texture quality reduction:", qualityMultiplier)
    return true
end

--[[ Sound Management ]]--

-- Register a sound for tracking
function ClientPerformanceManager:registerSound(sound, priority)
    if not sound then return nil end
    
    -- Generate unique ID
    local soundId = HttpService:GenerateGUID(false)
    
    self._soundRegistry[soundId] = {
        sound = sound,
        priority = priority or "normal", -- "high", "normal", "low"
        originalVolume = sound.Volume,
        originalMaxDistance = sound.MaxDistance,
        playing = sound.Playing,
        registerTime = os.time()
    }
    
    -- Apply current settings
    self:applySoundOptimizations()
    
    debugPrint("Registered sound:", soundId)
    return soundId
end

-- Unregister a sound from tracking
function ClientPerformanceManager:unregisterSound(soundId)
    if not self._soundRegistry[soundId] then
        return false
    end
    
    -- Restore original values
    local soundData = self._soundRegistry[soundId]
    if soundData.sound and soundData.sound:IsDescendantOf(game) then
        soundData.sound.Volume = soundData.originalVolume
        soundData.sound.MaxDistance = soundData.originalMaxDistance
    end
    
    self._soundRegistry[soundId] = nil
    return true
end

-- Update the playing state of a registered sound
function ClientPerformanceManager:updateSoundPlaying(soundId, isPlaying)
    if not self._soundRegistry[soundId] then
        return false
    end
    
    self._soundRegistry[soundId].playing = isPlaying
    return true
end

-- Apply sound optimizations based on current detail level
function ClientPerformanceManager:applySoundOptimizations()
    local currentLevel = self._currentDetailLevel
    local maxSounds = CONFIG.maxConcurrentSounds[currentLevel] or 32
    local distanceMultiplier = CONFIG.soundDistanceMultiplier[currentLevel] or 1.0
    
    -- Count playing sounds
    local playingSounds = {}
    
    for id, soundData in pairs(self._soundRegistry) do
        if soundData.sound and soundData.sound:IsDescendantOf(game) and soundData.playing then
            table.insert(playingSounds, {
                id = id,
                data = soundData
            })
        end
    end
    
    -- If too many sounds playing, silence lowest priority
    if #playingSounds > maxSounds then
        -- Sort by priority
        table.sort(playingSounds, function(a, b)
            if a.data.priority == b.data.priority then
                -- If same priority, newer sounds take precedence
                return a.data.registerTime > b.data.registerTime
            end
            
            if a.data.priority == "high" then return true end
            if b.data.priority == "high" then return false end
            if a.data.priority == "normal" then return true end
            return false
        end)
        
        -- Silence lowest priority sounds
        for i = maxSounds + 1, #playingSounds do
            local soundId = playingSounds[i].id
            local soundData = playingSounds[i].data
            
            if soundData.sound then
                soundData.sound.Volume = 0
            end
        end
        
        -- Restore volume for highest priority sounds
        for i = 1, maxSounds do
            local soundId = playingSounds[i].id
            local soundData = playingSounds[i].data
            
            if soundData.sound then
                soundData.sound.Volume = soundData.originalVolume
            end
        end
    end
    
    -- Apply distance multiplier to all sounds
    for id, soundData in pairs(self._soundRegistry) do
        if soundData.sound and soundData.sound:IsDescendantOf(game) then
            soundData.sound.MaxDistance = soundData.originalMaxDistance * distanceMultiplier
        end
    end
    
    debugPrint("Applied sound optimizations. Max sounds:", maxSounds)
    return true
end

-- Optimize sounds in a model
function ClientPerformanceManager:optimizeSounds(model)
    if not model then return 0 end
    
    local count = 0
    
    -- Process all Sounds
    for _, sound in ipairs(model:GetDescendants()) do
        if sound:IsA("Sound") then
            self:registerSound(sound)
            count = count + 1
        end
    end
    
    return count
end

--[[ Extended Performance Monitoring ]]--

-- Enhanced performance monitoring to include memory and asset tracking
function ClientPerformanceManager:startEnhancedPerformanceMonitoring()
    if not CONFIG.monitoringEnabled then
        return false
    end
    
    -- Start basic performance monitoring
    self:startPerformanceMonitoring()
    
    -- Add memory monitoring
    self._monitoringLoops.memory = task.spawn(function()
        while task.wait(CONFIG.monitorInterval * 2) do -- Check less frequently than framerate
            self:checkMemoryUsage()
            
            -- Clean up sound registry
            for id, soundData in pairs(self._soundRegistry) do
                if not soundData.sound or not soundData.sound:IsDescendantOf(game) then
                    self._soundRegistry[id] = nil
                end
            end
        end
    end)
    
    -- Start asset preloader
    self:startAssetPreloader()
    
    return true
end

-- Enhanced performance stats that include memory and asset information
function ClientPerformanceManager:getEnhancedPerformanceStats()
    local stats = self:getPerformanceStats()
    
    -- Add asset queue information
    stats.assetQueueLength = #self._assetLoadQueue
    
    -- Add sound information
    local soundCount = 0
    local playingSoundCount = 0
    
    for _, soundData in pairs(self._soundRegistry) do
        soundCount = soundCount + 1
        if soundData.playing then
            playingSoundCount = playingSoundCount + 1
        end
    end
    
    stats.registeredSounds = soundCount
    stats.playingSounds = playingSoundCount
    stats.maxSounds = CONFIG.maxConcurrentSounds[self._currentDetailLevel] or 32
    
    -- Add texture information
    stats.textureQuality = CONFIG.textureQuality[self._currentDetailLevel] or 1.0
    
    -- Add extended memory stats
    if #self._memoryUsageHistory > 0 then
        local memoryPeak = 0
        local memorySum = 0
        
        for _, sample in ipairs(self._memoryUsageHistory) do
            memoryPeak = math.max(memoryPeak, sample.memoryMB)
            memorySum = memorySum + sample.memoryMB
        end
        
        stats.averageMemorySizeMB = memorySum / #self._memoryUsageHistory
        stats.peakMemorySizeMB = memoryPeak
    end
    
    return stats
end

--[[ Enhanced Initialization ]]--

-- Initialize the ClientPerformanceManager with enhanced features
function ClientPerformanceManager:enhancedInitialize()
    if self._initialized then
        return true
    end
    
    -- Run basic initialization
    self:initialize()
    
    -- Start enhanced monitoring
    self:startEnhancedPerformanceMonitoring()
    
    -- Register with event bridge for client-server synchronization
    if ClientEventBridge then
        -- Register events for asset preloading
        ClientEventBridge:registerEvent("PreloadAssets")
        ClientEventBridge:listenToEvent("PreloadAssets", function(assets)
            for _, asset in ipairs(assets) do
                self:preloadAsset(asset.id, asset.priority)
            end
        end)
        
        -- Register events for memory info
        ClientEventBridge:registerServerEvent("RequestMemoryStats", function()
            return self:getEnhancedPerformanceStats()
        end)
    end
    
    return true
end

-- Initialize with enhanced features
ClientPerformanceManager:enhancedInitialize()

-- Register with ClientRegistry
ClientRegistry.registerSystem("ClientPerformanceManager", ClientPerformanceManager)

return ClientPerformanceManager