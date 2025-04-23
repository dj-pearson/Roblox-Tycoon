--[[
    NPCAnimationSystem.server.luau
    
    Provides a robust animation system for NPCs in the gym tycoon.
    Handles loading, caching, and playing animations with performance optimizations.
    
    Features:
    - Animation preloading and caching
    - Animation pooling for performance
    - Context-aware animation selection based on NPC activity
    - Distance-based animation quality control
    - Integration with NPCSystem and NPCSystemPerformance
    
    Author: Created April 21, 2025
]]

local game = game
--local CollectionService = game:GetService("CollectionService")

-- Module dependencies
local CoreRegistry
local NPCSystem
local NPCSystemPerformance
--local PerformanceManager
--local GymStructureIntegration
local EventBridge

-- Animation configuration
local ANIMATIONS = {
    -- Walking animations
    WALK = {
        {id = "rbxassetid://913376220", weight = 10}, -- Standard walk
        {id = "rbxassetid://913402848", weight = 8},  -- Confident walk
        {id = "rbxassetid://1330180905", weight = 5}  -- Tired walk
    },
    
    -- Idle animations
    IDLE = {
        {id = "rbxassetid://507766388", weight = 10}, -- Standard idle
        {id = "rbxassetid://507766951", weight = 8},  -- Idle with phone
        {id = "rbxassetid://507766666", weight = 5},  -- Looking around
        {id = "rbxassetid://507766368", weight = 3}   -- Stretching
    },
    
    -- Equipment usage animations
    EQUIPMENT = {
        TREADMILL = {
            {id = "rbxassetid://2522855810", weight = 10} -- Running
        },
        BENCH_PRESS = {
            {id = "rbxassetid://2521781856", weight = 10} -- Bench press
        },
        WEIGHTS = {
            {id = "rbxassetid://2510235063", weight = 10}, -- Lifting weights
            {id = "rbxassetid://2510238627", weight = 8}   -- Curls
        },
        YOGA = {
            {id = "rbxassetid://4211051313", weight = 10} -- Yoga pose
        },
        ELLIPTICAL = {
            {id = "rbxassetid://2522855810", weight = 10} -- Running (reused)
        },
        GENERIC = {
            {id = "rbxassetid://2510235063", weight = 10} -- Default equipment animation
        }
    },
    
    -- Satisfaction-based animations
    SATISFACTION = {
        HIGH = {
            {id = "rbxassetid://507770239", weight = 10} -- Cheer
        },
        LOW = {
            {id = "rbxassetid://507767714", weight = 10} -- Disappointed
        }
    }
}

-- Configuration
local CONFIG = {
    -- Animation settings
    fadeTime = 0.3,                  -- Time to fade between animations
    walkAnimationSpeed = 1.0,        -- Speed multiplier for walk animations
    idleAnimationSpeed = 1.0,        -- Speed multiplier for idle animations
    equipmentAnimationSpeed = 1.0,    -- Speed multiplier for equipment animations
    
    -- Performance settings
    preloadAnimations = true,         -- Whether to preload animations at startup
    useAnimationPooling = true,       -- Whether to use animation object pooling
    initialAnimationPoolSize = 20,    -- Initial size of animation object pool
    distanceBasedAnimQuality = true,  -- Whether to adjust animation quality based on distance
    minDistanceForFullAnim = 50,      -- Distance within which to play full animations
    
    -- Debug settings
    debug = false
}

-- Module table
local NPCAnimationSystem = {
    _name = "NPCAnimationSystem",
    _version = "1.0.0",
    _dependencies = {
        "CoreRegistry", 
        "NPCSystem", 
        "NPCSystemPerformance", 
        "PerformanceManager", 
        "EventBridge",
        "GymStructureIntegration"
    },
    
    -- Internal state
    _animationCache = {},         -- Cache of loaded animations
    _activeAnimations = {},       -- Currently playing animations by NPC
    _animationPool = {},          -- Pool of animation objects
    _animationPoolInUse = {}      -- Animation objects currently in use
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[NPCAnimationSystem]", ...)
    end
end

--[[ Animation Pooling Functions ]]--

-- Initialize the animation object pool
function NPCAnimationSystem:initializeAnimationPool()
    if not CONFIG.useAnimationPooling then return end
    
    -- Create initial pool of Animation objects
    for _ = 1, CONFIG.initialAnimationPoolSize do
        local anim = Instance.new("Animation")
        table.insert(self._animationPool, anim)
    end
    
    debugPrint("Initialized animation pool with", #self._animationPool, "objects")
end

-- Get an Animation object from the pool
function NPCAnimationSystem:getAnimationFromPool()
    if not CONFIG.useAnimationPooling then
        -- If not using pooling, just create a new one
        return Instance.new("Animation")
    end
    
    -- Get from pool or create new if empty
    local anim
    if #self._animationPool > 0 then
        anim = table.remove(self._animationPool)
    else
        anim = Instance.new("Animation")
        debugPrint("Animation pool empty, created new Animation object")
    end
    
    -- Track as in use
    self._animationPoolInUse[anim] = true
    
    return anim
end

-- Return an Animation object to the pool
function NPCAnimationSystem:returnAnimationToPool(anim)
    if not CONFIG.useAnimationPooling or not anim then return end
    
    -- Only return if it was from our pool
    if not self._animationPoolInUse[anim] then return end
    
    -- Clear the animation ID
    anim.AnimationId = ""
    
    -- Remove from in-use tracking
    self._animationPoolInUse[anim] = nil
    
    -- Add back to pool
    table.insert(self._animationPool, anim)
end

--[[ Animation Loading and Caching ]]--

-- Preload commonly used animations
function NPCAnimationSystem:preloadAnimations()
    if not CONFIG.preloadAnimations then return end
    
    debugPrint("Preloading animations...")
    
    -- Preload walk animations
    for _, anim in ipairs(ANIMATIONS.WALK) do
        self:getAnimation(anim.id)
    end
    
    -- Preload idle animations
    for _, anim in ipairs(ANIMATIONS.IDLE) do
        self:getAnimation(anim.id)
    end
    
    -- Preload some equipment animations
    for _, anim in ipairs(ANIMATIONS.EQUIPMENT.GENERIC) do
        self:getAnimation(anim.id)
    end
    
    debugPrint("Preloaded", #self._animationCache, "animations")
end

-- Get an animation by ID (from cache or load new)
function NPCAnimationSystem:getAnimation(animationId)
    -- Check cache first
    if self._animationCache[animationId] then
        return self._animationCache[animationId]
    end
    
    -- Create new animation
    local animation = self:getAnimationFromPool()
    animation.AnimationId = animationId
    
    -- Cache it
    self._animationCache[animationId] = animation
    
    return animation
end

-- Select a random animation from a category based on weights
function NPCAnimationSystem:selectRandomAnimation(category)
    if not category or #category == 0 then
        return nil
    end
    
    -- Calculate total weight
    local totalWeight = 0
    for _, anim in ipairs(category) do
        totalWeight = totalWeight + (anim.weight or 1)
    end
    
    -- Select based on weight
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for _, anim in ipairs(category) do
        currentWeight = currentWeight + (anim.weight or 1)
        if randomValue <= currentWeight then
            return anim.id
        end
    end
    
    -- Fallback to first animation
    return category[1].id
end

--[[ Animation Playback Functions ]]--

-- Play an animation on an NPC
function NPCAnimationSystem:playAnimation(npc, animationType, options)
    if not npc or not npc.Parent then return nil end
    
    options = options or {}
    local fadeTime = options.fadeTime or CONFIG.fadeTime
    local speed = options.speed or 1.0
    local priority = options.priority or Enum.AnimationPriority.Action
    local looped = options.looped ~= false -- Default to true
    
    -- Get the humanoid
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        debugPrint("Cannot play animation - no humanoid found")
        return nil
    end
    
    -- Get animation category
    local category
    if animationType == "WALK" then
        category = ANIMATIONS.WALK
    elseif animationType == "IDLE" then
        category = ANIMATIONS.IDLE
    elseif string.sub(animationType, 1, 10) == "EQUIPMENT_" then
        local equipType = string.sub(animationType, 11)
        category = ANIMATIONS.EQUIPMENT[equipType] or ANIMATIONS.EQUIPMENT.GENERIC
    elseif animationType == "SATISFACTION_HIGH" then
        category = ANIMATIONS.SATISFACTION.HIGH
    elseif animationType == "SATISFACTION_LOW" then
        category = ANIMATIONS.SATISFACTION.LOW
    else
        -- Default to idle
        category = ANIMATIONS.IDLE
    end
    
    -- Select a random animation from the category
    local animationId = self:selectRandomAnimation(category)
    if not animationId then
        debugPrint("No animation found for type:", animationType)
        return nil
    end
    
    -- Get the animation object
    local animation = self:getAnimation(animationId)
    
    -- Stop existing animation of same type if any
    self:stopAnimation(npc, animationType)
    
    -- Load the animation onto the humanoid
    local animTrack = humanoid:LoadAnimation(animation)
    
    -- Configure the animation
    animTrack.Looped = looped
    animTrack.Priority = priority
    animTrack:AdjustSpeed(speed)
    
    -- Store metadata on the track for our system
    animTrack:SetAttribute("AnimationType", animationType)
    animTrack:SetAttribute("AnimationId", animationId)
    
    -- Play the animation
    animTrack:Play(fadeTime)
    
    -- Store in active animations
    if not self._activeAnimations[npc] then
        self._activeAnimations[npc] = {}
    end
    self._activeAnimations[npc][animationType] = animTrack
    
    -- Set up cleanup when animation ends (if not looped)
    if not looped then
        animTrack.Stopped:Connect(function()
            if self._activeAnimations[npc] then
                self._activeAnimations[npc][animationType] = nil                
                -- If no more animations for this NPC, clean up
                local hasAnimations = false
                for _, _ in pairs(self._activeAnimations[npc]) do
                    hasAnimations = true
                    break
                end
                
                if not hasAnimations then
                    self._activeAnimations[npc] = nil
                end
            end
        end)
    end
    
    return animTrack
end

-- Stop a specific animation on an NPC
function NPCAnimationSystem:stopAnimation(npc, animationType, fadeTime)
    if not npc or not self._activeAnimations[npc] then return false end
    
    fadeTime = fadeTime or CONFIG.fadeTime
    
    -- Get the animation track
    local track = self._activeAnimations[npc][animationType]
    if track and track.IsPlaying then
        track:Stop(fadeTime)
        self._activeAnimations[npc][animationType] = nil
        return true
    end
    
    return false
end

-- Stop all animations on an NPC
function NPCAnimationSystem:stopAllAnimations(npc, fadeTime)
    if not npc or not self._activeAnimations[npc] then return false end
    
    fadeTime = fadeTime or CONFIG.fadeTime
    
    -- Stop each active animation
    for animType, track in pairs(self._activeAnimations[npc]) do
        if track and track.IsPlaying then
            track:Stop(fadeTime)
        end
    end
    
    -- Clear tracking
    self._activeAnimations[npc] = nil
    
    return true
end

--[[ Context-Aware Animation Functions ]]--

-- Play appropriate animation based on NPC state
function NPCAnimationSystem:playAppropriateAnimation(npc, npcData)
    if not npc or not npc.Parent or not npcData then return end
    
    -- Get the NPC state
    local state = npcData.state or "Idle"
    
    -- Select animation based on state
    if state == "MovingToEquipment" or state == "Wandering" or state == "Entering" or state == "Leaving" then
        -- Walking animation
        self:playAnimation(npc, "WALK", {
            speed = CONFIG.walkAnimationSpeed,
            priority = Enum.AnimationPriority.Movement
        })
        
    elseif state == "UsingEquipment" and npcData.equipment then
        -- Get equipment type
        local equipmentType = npcData.equipment:GetAttribute("EquipmentType") or "GENERIC"
        
        -- Play appropriate equipment animation
        self:playAnimation(npc, "EQUIPMENT_" .. equipmentType, {
            speed = CONFIG.equipmentAnimationSpeed,
            priority = Enum.AnimationPriority.Action
        })
        
    elseif state == "Standing" or state == "Idle" then
        -- Idle animation
        self:playAnimation(npc, "IDLE", {
            speed = CONFIG.idleAnimationSpeed,
            priority = Enum.AnimationPriority.Idle
        })
    end
    
    -- Add satisfaction-based animations occasionally
    if npcData.satisfaction and math.random() < 0.1 then -- 10% chance
        if npcData.satisfaction > 80 then
            -- Happy animation
            self:playAnimation(npc, "SATISFACTION_HIGH", {
                looped = false,
                priority = Enum.AnimationPriority.Action
            })
        elseif npcData.satisfaction < 30 then
            -- Unhappy animation
            self:playAnimation(npc, "SATISFACTION_LOW", {
                looped = false,
                priority = Enum.AnimationPriority.Action
            })
        end
    end
end

-- Apply distance-based animation quality control
function NPCAnimationSystem:applyDistanceBasedQuality(npc, playerPosition)
    if not CONFIG.distanceBasedAnimQuality or not npc or not npc.Parent then return end
    
    -- Get distance to player
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
    
    -- Apply quality adjustments based on distance
    if distance > CONFIG.minDistanceForFullAnim then
        -- Far away - simplify animations
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Get all playing animations
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                local animType = track:GetAttribute("AnimationType")
                
                -- Keep only essential animations at distance
                if distance > CONFIG.minDistanceForFullAnim * 2 then
                    -- At very far distances, only keep walk animations
                    if animType and animType ~= "WALK" then
                        track:Stop(0.1) -- Quick fade out
                    end
                    
                    -- Reduce animation speed to save CPU
                    if track.IsPlaying then
                        track:AdjustSpeed(0.5) -- Half speed
                    end
                else
                    if animType and string.find(animType, "SATISFACTION") then
                        track:Stop(0.1) -- Remove non-essential animations
                    end
                end
            end
        end
    end
end

--[[ Integration with NPCSystem ]]--

-- Extend the NPCSystem with animation capabilities
function NPCAnimationSystem:extendNPCSystem()
    -- Store original updateSingleNPC function
    local originalUpdateSingleNPC = NPCSystem.updateSingleNPC
    
    -- Override the updateSingleNPC function to add animations
    NPCSystem.updateSingleNPC = function(npcSystem, npc, data)
        -- Call original function first
        originalUpdateSingleNPC(npcSystem, npc, data)

        -- Add animations based on NPC state
        NPCAnimationSystem:playAppropriateAnimation(npc, data)
        
        -- Apply distance-based quality control
        if NPCSystemPerformance then
            -- Get player position from performance system if available
            local _, behaviorLevel = NPCSystemPerformance:applyDistanceBasedOptimizations(npc)
            
            -- Only apply full animations at high behavior levels
            if behaviorLevel and behaviorLevel < 2 then
                NPCAnimationSystem:applyDistanceBasedQuality(npc)
            end
        else
            -- Direct quality control if performance system not available
            NPCAnimationSystem:applyDistanceBasedQuality(npc)
        end
    end
    
    -- Extend the removeNPC function to clean up animations
    local originalRemoveNPC = NPCSystem.removeNPC or NPCSystem.returnToPool
    
    if originalRemoveNPC then
        NPCSystem.removeNPC = function(npcSystem, npc)
            -- Stop all animations
            NPCAnimationSystem:stopAllAnimations(npc, 0.1) -- Quick fade
            
            -- Call original function
            return originalRemoveNPC(npcSystem, npc)
        end
    end
    
    debugPrint("Extended NPCSystem with animation capabilities")
    return true
end

--[[ Initialization and Cleanup ]]--

-- Initialize the animation system
function NPCAnimationSystem:init()
    debugPrint("Initializing NPCAnimationSystem v" .. NPCAnimationSystem._version)
    
    -- Get dependencies from registry
    CoreRegistry = NPCAnimationSystem.CoreRegistry
    
    -- Get required systems
    NPCSystem = CoreRegistry:getSystem("NPCSystem")
    NPCSystemPerformance = CoreRegistry:getSystem("NPCSystemPerformance")

    GymStructureIntegration = CoreRegistry:getSystem("GymStructureIntegration")
    EventBridge = CoreRegistry:getSystem("EventBridge")
    
    -- Check required dependencies
    if not NPCSystem then
        warn("NPCSystem not found, cannot initialize NPCAnimationSystem")
        return false
    end
    
    -- Initialize animation pool
    NPCAnimationSystem:initializeAnimationPool()
    
    -- Preload animations
    NPCAnimationSystem:preloadAnimations()
    
    -- Extend NPCSystem with animation capabilities
    NPCAnimationSystem:extendNPCSystem()
    
    -- Register for events if EventBridge is available
    if EventBridge then
        EventBridge:registerEvent("DetailLevelChanged", function(level)
            -- Adjust animation settings based on detail level
            if level == "Low" then
                CONFIG.distanceBasedAnimQuality = true
                CONFIG.minDistanceForFullAnim = 30 -- Reduce animation quality sooner
            elseif level == "Medium" then
                CONFIG.distanceBasedAnimQuality = true
                CONFIG.minDistanceForFullAnim = 50 -- Default
            elseif level == "High" then
                CONFIG.distanceBasedAnimQuality = true
                CONFIG.minDistanceForFullAnim = 80 -- Keep high quality animations at greater distances
            end
        end)
    end
    
    debugPrint("NPCAnimationSystem initialized successfully")
    return true
end

-- Clean up resources
function NPCAnimationSystem:shutdown()
    debugPrint("Shutting down NPCAnimationSystem")
    
    -- Stop all active animations
    for npc, _ in pairs(self._activeAnimations) do
        self:stopAllAnimations(npc, 0)
    end
    
    -- Clear animation cache
    self._animationCache = {}
    
    -- Return all pooled animations
    for anim, _ in pairs(self._animationPoolInUse) do
        self:returnAnimationToPool(anim)
    end
    
    -- Destroy animation pool
    for _, anim in ipairs(self._animationPool) do
        anim:Destroy()
    end
    self._animationPool = {}
    
    debugPrint("NPCAnimationSystem shutdown complete")
    return true
end

-- Register with CoreRegistry
return CoreRegistry.registerSystem("NPCAnimationSystem", NPCAnimationSystem, {
    "CoreRegistry", "NPCSystem", "NPCSystemPerformance", "PerformanceManager", "EventBridge", "GymStructureIntegration"
})
