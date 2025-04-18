-- NPCSystemPerformance.server.luau
-- Performance extensions for the NPC System
-- Place in ServerScriptService/Core

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local PerformanceManager
local NPCSystem
local EventBridge

-- Configuration
local CONFIG = {
    -- General settings
    debug = true,
    
    -- Object pooling settings
    initialPoolSize = 20,         -- Initial number of NPCs to create
    poolGrowSize = 5,             -- How many NPCs to add when pool runs low
    
    -- Distribution settings
    updateGroupCount = 4,         -- Number of update groups for staggering
    
    -- NPC type ratios
    npcTypeRatios = {
        regular = 0.60,           -- 60% regular NPCs
        vip = 0.25,               -- 25% VIP NPCs
        premium = 0.15            -- 15% premium NPCs
    },
    
    -- Performance settings
    distanceBasedBehavior = true, -- Reduce behavior complexity at distance
    minDistanceForFullBehavior = 50, -- Studs within which NPCs have full behavior
    poolIdleAnimationsCount = 5,  -- Number of idle animations to pool
    poolWalkAnimationsCount = 4,  -- Number of walk animations to pool
}

-- Module table
local NPCSystemPerformance = {
    Name = "NPCSystemPerformance",
    Dependencies = {
        "CoreRegistry",
        "PerformanceManager",
        "NPCSystem",
        "EventBridge"
    }
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[NPCSystemPerformance]", ...)
    end
end

-- Initialize NPC object pool
function NPCSystemPerformance:initializeNPCPool()
    debugPrint("Initializing NPC Object Pool")
    
    -- Define the NPC creation function
    local function createPooledNPC()
        -- Get NPC model template
        local template = NPCSystem:getNPCTemplate() -- Assuming this function exists or we create it
        
        if not template then
            warn("Failed to get NPC template for pooling")
            return nil
        end
        
        -- Clone the model
        local npc = template:Clone()
        
        -- Mark as pooled
        npc:SetAttribute("Pooled", true)
        
        -- Add pooling attributes
        npc:SetAttribute("InUse", false)
        
        -- Pre-configure general NPC properties
        -- These will be set properly when the NPC is activated
        
        -- Disable rendering initially
        for _, part in ipairs(npc:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        
        -- Parent to a holding area
        npc.Parent = ServerStorage
        
        return npc
    end
    
    -- Initialize the NPC pool with our creation function
    PerformanceManager:initializePool("NPCs", createPooledNPC, CONFIG.initialPoolSize)
    
    -- Initialize animation pools
    self:initializeAnimationPools()
    
    return true
end

-- Initialize animation object pools
function NPCSystemPerformance:initializeAnimationPools()
    -- Pool for idle animations
    PerformanceManager:initializePool("IdleAnimations", function()
        local anim = Instance.new("Animation")
        -- We'll set the AnimationId when we actually use the animation
        return anim
    end, CONFIG.poolIdleAnimationsCount)
    
    -- Pool for walking animations
    PerformanceManager:initializePool("WalkAnimations", function()
        local anim = Instance.new("Animation")
        -- We'll set the AnimationId when we actually use the animation
        return anim
    end, CONFIG.poolWalkAnimationsCount)
    
    debugPrint("Initialized animation pools")
    return true
end

-- Get an NPC from the pool and configure it
function NPCSystemPerformance:getNPCFromPool(npcType, tycoon)
    -- Get base NPC from pool
    local npc = PerformanceManager:getFromPool("NPCs")
    
    if not npc then
        debugPrint("Failed to get NPC from pool, pool may be empty")
        return nil
    end
    
    -- Determine NPC type if not specified
    if not npcType then
        local rand = math.random()
        if rand < CONFIG.npcTypeRatios.regular then
            npcType = "regular"
        elseif rand < CONFIG.npcTypeRatios.regular + CONFIG.npcTypeRatios.vip then
            npcType = "vip"
        else
            npcType = "premium"
        end
    end
    
    -- Configure NPC for use
    npc:SetAttribute("Type", npcType)
    npc:SetAttribute("InUse", true)
    npc:SetAttribute("Tycoon", tycoon and tycoon.Name or nil)
    
    -- Assign an update group for staggered updates
    npc:SetAttribute("UpdateGroup", math.random(0, CONFIG.updateGroupCount - 1))
    
    -- Restore visibility
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
        end
    end
    
    -- Set the parent (should be workspace or a container)
    if tycoon then
        local npcContainer = tycoon:FindFirstChild("NPCs")
        if not npcContainer then
            npcContainer = Instance.new("Folder")
            npcContainer.Name = "NPCs"
            npcContainer.Parent = tycoon
        end
        npc.Parent = npcContainer
    else
        npc.Parent = workspace
    end
    
    -- Always mark the last interaction time for cleanup purposes
    npc:SetAttribute("LastInteraction", workspace:GetServerTimeNow())
    
    debugPrint("Got NPC from pool:", npc.Name, "Type:", npcType)
    return npc
end

-- Return an NPC to the pool
function NPCSystemPerformance:returnNPCToPool(npc)
    if not npc or not npc:GetAttribute("Pooled") then
        return false
    end
    
    -- Reset NPC state
    npc:SetAttribute("InUse", false)
    npc:SetAttribute("Tycoon", nil)
    
    -- Hide the NPC
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
        end
    end
    
    -- Reset any other state
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid:MoveTo(humanoid.RootPart.Position) -- Stop moving
    end
    
    -- Move back to storage
    npc.Parent = ServerStorage
    
    -- Return to pool
    local success = PerformanceManager:returnToPool("NPCs", npc)
    debugPrint("Returned NPC to pool:", success)
    return success
end

-- Apply performance optimizations based on distance
function NPCSystemPerformance:applyDistanceBasedOptimizations(npc, playerPosition)
    if not CONFIG.distanceBasedBehavior or not npc or not npc:GetAttribute("InUse") then
        return false
    end
    
    -- Get distance to nearest player
    local distance = math.huge
    
    if playerPosition then
        -- Use provided position
        local npcPosition = npc:GetPivot().Position
        distance = (npcPosition - playerPosition).Magnitude
    else
        -- Calculate on our own - more expensive
        local npcPosition = npc:GetPivot().Position
        
        -- Check distance to closest player
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local playerPos = player.Character.HumanoidRootPart.Position
                local distToPlayer = (npcPosition - playerPos).Magnitude
                
                if distToPlayer < distance then
                    distance = distToPlayer
                end
            end
        end
    end
    
    -- Apply optimizations based on distance
    if distance > CONFIG.minDistanceForFullBehavior then
        -- Far away - reduce update frequency
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Simplify animations
            if distance > CONFIG.minDistanceForFullBehavior * 2 then
                -- Stop playing complex animations
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track:GetAttribute("Complex") then
                        track:Stop()
                    end
                end
            end
            
            -- Reduce movement updates at extreme distances
            if distance > CONFIG.minDistanceForFullBehavior * 3 then
                -- Just use basic movement or freeze
                humanoid.WalkSpeed = humanoid.WalkSpeed * 0.5
            end
        end
        
        -- Return reduced behavior level for the caller to use
        local behaviorLevel = 0
        if distance <= CONFIG.minDistanceForFullBehavior then
            behaviorLevel = 3 -- Full behavior
        elseif distance <= CONFIG.minDistanceForFullBehavior * 2 then
            behaviorLevel = 2 -- Reduced behavior
        elseif distance <= CONFIG.minDistanceForFullBehavior * 3 then
            behaviorLevel = 1 -- Minimal behavior
        else
            behaviorLevel = 0 -- Basic existence only
        end
        
        return true, behaviorLevel
    end
    
    -- Close enough for full behavior
    return true, 3
end

-- Set up performance-optimized NPC update
function NPCSystemPerformance:setupOptimizedUpdates()
    -- Get current update interval based on detail level
    local function getUpdateInterval()
        return PerformanceManager:getUpdateFrequency("NPCSystem") or 1
    end
    
    -- Connection to update NPCs
    self._updateConnection = RunService.Heartbeat:Connect(function()
        -- Use update grouping for performance
        local currentGroup = NPCSystem._nextUpdateGroup or 0
        
        -- Update the group for next frame
        NPCSystem._nextUpdateGroup = (currentGroup + 1) % CONFIG.updateGroupCount
        
        -- Apply update interval from performance manager
        if NPCSystem._updateSkipCounter then
            NPCSystem._updateSkipCounter = NPCSystem._updateSkipCounter + 1
            
            local updateInterval = getUpdateInterval()
            if NPCSystem._updateSkipCounter < updateInterval then
                return -- Skip this frame
            end
            
            NPCSystem._updateSkipCounter = 0
        else
            NPCSystem._updateSkipCounter = 0
        end
        
        -- Process NPCs in current update group
        for npc, data in pairs(NPCSystem._activeNPCs or {}) do
            -- Skip NPCs not in current update group
            if npc:GetAttribute("UpdateGroup") ~= currentGroup then
                continue
            end
            
            -- Update this NPC
            if npc and npc.Parent and npc:GetAttribute("InUse") then
                -- Reference the existing update function to avoid duplicating code
                NPCSystem:updateSingleNPC(npc, data)
            else
                -- NPC no longer valid, return to pool or remove tracking
                if npc and npc:GetAttribute("Pooled") then
                    self:returnNPCToPool(npc)
                end
                NPCSystem._activeNPCs[npc] = nil
            end
        end
        
        -- Auto-grow pool if running low
        local stats = PerformanceManager:getPoolStats("NPCs")
        if stats and stats.available < 5 and stats.total < 100 then -- Limit to 100 max pooled NPCs
            PerformanceManager:growPool("NPCs", CONFIG.poolGrowSize)
        end
    end)
    
    debugPrint("Set up optimized NPC updates")
    return true
end

-- Extend the NPCSystem with these performance optimizations
function NPCSystemPerformance:extendNPCSystem()
    -- Store original functions that we want to override
    local originalSpawnNPC = NPCSystem.spawnNPC
    local originalRemoveNPC = NPCSystem.removeNPC
    
    -- Override the spawnNPC function to use pooling
    NPCSystem.spawnNPC = function(self, tycoon, npcType, position)
        -- Use our pooling version
        local npc = NPCSystemPerformance:getNPCFromPool(npcType, tycoon)
        
        if not npc then
            -- Fallback to original if pool is empty
            debugPrint("Pool empty, falling back to original spawnNPC")
            return originalSpawnNPC(self, tycoon, npcType, position)
        end
        
        -- Position the NPC if position is provided
        if position then
            npc:PivotTo(CFrame.new(position))
        end
        
        -- Add to active NPCs tracking
        self._activeNPCs = self._activeNPCs or {}
        self._activeNPCs[npc] = {
            tycoon = tycoon,
            spawnTime = os.time(),
            lastUpdate = os.time()
        }
        
        -- Any additional initialization from the original function
        -- (depends on your implementation)
        
        return npc
    end
    
    -- Override the removeNPC function to return to pool
    NPCSystem.removeNPC = function(self, npc)
        if npc and npc:GetAttribute("Pooled") then
            -- Return to our NPC pool
            NPCSystemPerformance:returnNPCToPool(npc)
            
            -- Remove from active tracking
            if self._activeNPCs then
                self._activeNPCs[npc] = nil
            end
            
            return true
        else
            -- Fallback to original for non-pooled NPCs
            return originalRemoveNPC(self, npc)
        end
    end
    
    -- Add helper function to get NPC template if it doesn't exist
    if not NPCSystem.getNPCTemplate then
        NPCSystem.getNPCTemplate = function(self)
            -- Look in common places for NPC template
            local template = ServerStorage:FindFirstChild("NPC_Template")
            
            if not template then
                -- Try other locations
                template = ServerStorage:FindFirstChild("NPC_Character")
                if template and template:FindFirstChild("NPC_Template") then
                    template = template:FindFirstChild("NPC_Template")
                end
            end
            
            -- Clone template if found
            if template then
                return template
            else
                warn("Could not find NPC template for pooling")
                return nil
            end
        end
    end
    
    -- Add our applyDistanceBasedOptimizations function to NPCSystem
    NPCSystem.applyDistanceBasedOptimizations = function(self, npc, playerPosition)
        return NPCSystemPerformance:applyDistanceBasedOptimizations(npc, playerPosition)
    end
    
    -- Initialize update grouping if not already present
    NPCSystem._nextUpdateGroup = NPCSystem._nextUpdateGroup or 0
    NPCSystem._updateSkipCounter = 0
    
    -- Set up our optimized update cycle (will replace or complement existing updates)
    self:setupOptimizedUpdates()
    
    debugPrint("Extended NPCSystem with performance optimizations")
    return true
end

-- Initialize the module
function NPCSystemPerformance:initialize()
    debugPrint("Initializing NPCSystemPerformance...")
    
    -- Get dependencies
    PerformanceManager = CoreRegistry:getSystem("PerformanceManager")
    NPCSystem = CoreRegistry:getSystem("NPCSystem")
    EventBridge = CoreRegistry:getSystem("EventBridge")
    
    -- Check all dependencies
    if not PerformanceManager then
        warn("PerformanceManager system not found, cannot initialize NPCSystemPerformance")
        return false
    end
    
    if not NPCSystem then
        warn("NPCSystem not found, cannot initialize NPCSystemPerformance")
        return false
    end
    
    -- Initialize NPC object pool
    self:initializeNPCPool()
    
    -- Extend the NPCSystem with our optimizations
    self:extendNPCSystem()
    
    -- Listen to detail level changes
    if EventBridge then
        EventBridge:listenToEvent("DetailLevelChanged", function(level)
            debugPrint("Detail level changed to:", level)
            -- No specific action needed, update frequency is fetched dynamically
        end)
    end
    
    debugPrint("NPCSystemPerformance initialized")
    return true
end

-- Clean up
function NPCSystemPerformance:shutdown()
    -- Disconnect update
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    
    debugPrint("NPCSystemPerformance shutdown")
    return true
end

-- Register with CoreRegistry
return CoreRegistry.registerSystem("NPCSystemPerformance", NPCSystemPerformance, {
    "CoreRegistry", "PerformanceManager", "NPCSystem", "EventBridge"
})