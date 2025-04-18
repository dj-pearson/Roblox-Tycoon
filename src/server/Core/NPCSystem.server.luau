--[[
    NPCSystem.server.luau
    Handles all NPC behaviors, spawning, and movement in the gym.
    Part of the Core systems architecture.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Module dependencies
local CoreRegistry
local EventBridge
local TycoonSystem
local DataManager
local MemberSatisfactionSystem
local RevenueSystem

-- Configuration
local CONFIG = {
    -- Spawning
    maxMembersPerTycoon = 20,
    spawnInterval = 15,  -- seconds between spawn attempts
    spawnChance = 0.7,   -- 70% chance to spawn on each attempt
    
    -- Member types
    memberTypes = {
        {name = "Regular", chance = 0.8, model = "Regular_Member", multiplier = 1, satisfaction = 1},
        {name = "VIP", chance = 0.2, model = "VIP_Member", multiplier = 3, satisfaction = 1.5}
    },
    
    -- Movement
    movementSpeed = 12,         -- walkSpeed for NPCs
    destinationRadius = 4,      -- How close NPC must be to count as "arrived"
    standTime = {5, 15},        -- Range of seconds NPCs will stand at equipment
    useEquipmentChance = 0.85,  -- Chance NPC will use equipment vs just walk around
    maxPathfindingRetries = 3,  -- Max number of times to retry pathfinding
    
    -- Object pooling
    initialPoolSize = 20,       -- Initial number of NPCs to create in the pool
    poolGrowthRate = 5,         -- How many NPCs to add when pool is empty
    
    -- Performance
    updateStaggering = 3,       -- Distribute NPC updates across this many frames
    cullingDistance = 100,      -- Distance beyond which NPCs will be culled
    preloadModels = true,       -- Whether to preload NPC models at startup
    
    -- VIP
    vipUnlockLevel = 3,         -- Gym level needed to start getting VIP members
    
    -- Debug
    debug = false
}

-- Module table
local NPCSystem = {
    _name = "NPCSystem",
    _version = "2.1.0",
    _dependencies = {
        "CoreRegistry", 
        "EventBridge", 
        "TycoonSystem", 
        "DataManager",
        "MemberSatisfactionSystem", 
        "RevenueSystem"
    },
    
    -- Internal state
    _npcPools = {},         -- Object pools for NPCs, separated by tycoon
    _activeTycoons = {},    -- List of active tycoons with NPCs
    _activeNPCs = {},       -- Currently active NPCs
    _spawnTimers = {},      -- Timers for spawning NPCs, keyed by tycoon
    _models = {},           -- Cached NPC models
    _nextUpdateGroup = 0    -- For staggered updates
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[NPC System]", ...)
    end
end

--[[ Utility Functions ]]--

-- Get a random position within a part
local function getRandomPositionInPart(part)
    local size = part.Size
    local position = part.Position
    
    local x = position.X + (math.random() - 0.5) * size.X * 0.8
    local y = position.Y + size.Y/2 -- Place on top of the part
    local z = position.Z + (math.random() - 0.5) * size.Z * 0.8
    
    return Vector3.new(x, y, z)
end

-- Find all equipment in a tycoon
local function findEquipmentInTycoon(tycoon)
    local equipment = {}
    
    -- Check tycoon parts for equipment
    for _, child in ipairs(tycoon:GetDescendants()) do
        if child:IsA("Model") and child:GetAttribute("IsEquipment") then
            table.insert(equipment, child)
        elseif child:IsA("BasePart") and child:GetAttribute("IsEquipment") then
            table.insert(equipment, child)
        end
    end
    
    return equipment
end

-- Check if a player is near the tycoon
local function isPlayerNearTycoon(tycoon, range)
    if not tycoon then return false end
    
    local owner = TycoonSystem:getTycoonOwner(tycoon)
    if not owner or not owner.Character then return false end
    
    -- Check if player is in range of tycoon
    local playerPos = owner.Character:GetPivot().Position
    local tycoonPos = tycoon:GetPivot().Position
    local distance = (playerPos - tycoonPos).Magnitude
    
    return distance <= range
end

--[[ Object Pooling ]]--

-- Initialize an NPC pool for a tycoon
function NPCSystem:initializePool(tycoonId)
    if self._npcPools[tycoonId] then return end
    
    self._npcPools[tycoonId] = {
        available = {}, -- NPCs ready to use
        inUse = {}     -- NPCs currently in use
    }
    
    -- Preallocate NPCs for the pool
    self:growPool(tycoonId, CONFIG.initialPoolSize)
    
    debugPrint("Initialized NPC pool for tycoon", tycoonId, "with", CONFIG.initialPoolSize, "NPCs")
end

-- Create more NPCs for the pool
function NPCSystem:growPool(tycoonId, count)
    local pool = self._npcPools[tycoonId]
    if not pool then return end
    
    for i = 1, count do
        local npc = self:createNPC(tycoonId)
        if npc then
            -- Hide and disable NPC until used
            npc.Parent = workspace
            npc:PivotTo(CFrame.new(0, -100, 0)) -- Move below map
            npc.Humanoid.WalkSpeed = 0
            
            table.insert(pool.available, npc)
        end
    end
    
    debugPrint("Grew NPC pool for tycoon", tycoonId, "by", count, "NPCs")
end

-- Get an NPC from the pool, or create a new one if needed
function NPCSystem:getPooledNPC(tycoonId, npcType)
    local pool = self._npcPools[tycoonId]
    if not pool then
        self:initializePool(tycoonId)
        pool = self._npcPools[tycoonId]
    end
    
    -- If no available NPCs, grow the pool
    if #pool.available == 0 then
        self:growPool(tycoonId, CONFIG.poolGrowthRate)
    end
    
    -- Get an NPC from the pool
    local npc = table.remove(pool.available)
    if npc then
        -- Customize NPC based on type if needed
        self:customizeNPC(npc, npcType)
        
        -- Track NPC as in use
        pool.inUse[npc] = true
    end
    
    return npc
end

-- Return an NPC to the pool
function NPCSystem:returnToPool(npc)
    if not npc then return end
    
    local tycoonId = npc:GetAttribute("TycoonId")
    if not tycoonId then return end
    
    local pool = self._npcPools[tycoonId]
    if not pool then return end
    
    -- Remove from tracking
    self._activeNPCs[npc] = nil
    pool.inUse[npc] = nil
    
    -- Reset NPC state
    npc.Humanoid.WalkSpeed = 0
    npc:PivotTo(CFrame.new(0, -100, 0)) -- Move below map
    
    -- Add back to available pool
    table.insert(pool.available, npc)
    
    debugPrint("Returned NPC to pool for tycoon", tycoonId)
end

-- Clean up unused NPCs from a tycoon pool
function NPCSystem:cleanupPool(tycoonId)
    local pool = self._npcPools[tycoonId]
    if not pool then return end
    
    -- Remove all available NPCs
    for _, npc in ipairs(pool.available) do
        npc:Destroy()
    end
    
    -- Return in-use NPCs
    for npc, _ in pairs(pool.inUse) do
        if npc then
            npc:Destroy()
        end
    end
    
    -- Clear the pool
    self._npcPools[tycoonId] = nil
    self._spawnTimers[tycoonId] = nil
    
    debugPrint("Cleaned up NPC pool for tycoon", tycoonId)
end

--[[ NPC Creation and Management ]]--

-- Create a new NPC
function NPCSystem:createNPC(tycoonId)
    -- Get base model to clone
    if not self._models.Regular_Member then
        self:preloadNPCModels()
    end
    
    -- Get a random member type (defaulting to Regular)
    local npcType = "Regular_Member"
    local baseModel = self._models[npcType]
    
    if not baseModel then
        warn("NPCSystem: Missing NPC model for type:", npcType)
        return nil
    end
    
    -- Clone the model
    local npc = baseModel:Clone()
    npc:SetAttribute("TycoonId", tycoonId)
    npc:SetAttribute("MemberType", "Regular")
    npc:SetAttribute("WalkSpeed", CONFIG.movementSpeed)
    
    -- Add a unique identifier
    npc.Name = "NPC_" .. tycoonId .. "_" .. tostring(math.random(100000, 999999))
    
    -- Store humanoid reference
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = CONFIG.movementSpeed
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    return npc
end

-- Preload NPC models for better performance
function NPCSystem:preloadNPCModels()
    -- Look for NPC models in ServerStorage
    local npcStorage = ServerStorage:FindFirstChild("NPC_Character")
    
    if not npcStorage then
        warn("NPCSystem: Could not find NPC_Character folder in ServerStorage")
        return
    end
    
    -- Cache each model type
    for _, model in ipairs(npcStorage:GetChildren()) do
        if model:IsA("Model") then
            self._models[model.Name] = model
            debugPrint("Cached NPC model:", model.Name)
        end
    end
end

-- Customize NPC based on member type
function NPCSystem:customizeNPC(npc, memberType)
    -- Default to regular member
    memberType = memberType or "Regular"
    
    -- Set attributes based on type
    npc:SetAttribute("MemberType", memberType)
    
    -- Find the member type configuration
    local typeConfig
    for _, config in ipairs(CONFIG.memberTypes) do
        if config.name == memberType then
            typeConfig = config
            break
        end
    end
    
    -- Apply the configuration if found
    if typeConfig then
        npc:SetAttribute("RevenueMultiplier", typeConfig.multiplier)
        npc:SetAttribute("SatisfactionMultiplier", typeConfig.satisfaction)
        
        -- Visual customization based on type
        if memberType == "VIP" then
            -- Add visual indicators for VIPs
            for _, part in ipairs(npc:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == "VIPBadge" then
                    part.Transparency = 0
                end
            end
        end
    end
    
    return npc
end

-- Spawn an NPC in a tycoon
function NPCSystem:spawnNPC(tycoon, forcedType)
    if not tycoon then return nil end
    
    local tycoonId = tycoon:GetAttribute("TycoonId")
    if not tycoonId then return nil end
    
    -- Check if we've reached the NPC limit for this tycoon
    local activeCount = 0
    local pool = self._npcPools[tycoonId]
    if pool then
        for _ in pairs(pool.inUse) do
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= CONFIG.maxMembersPerTycoon then
        debugPrint("Reached max NPCs for tycoon", tycoonId, "- not spawning")
        return nil
    end
    
    -- Choose member type
    local memberType = "Regular"
    
    -- Determine if we can spawn VIP members
    local gymLevel = 1
    local owner = TycoonSystem:getTycoonOwner(tycoon)
    if owner then
        gymLevel = DataManager:getValue(owner, "GymLevel") or 1
    end
    
    local canSpawnVIP = gymLevel >= CONFIG.vipUnlockLevel
    
    -- Forced type or random selection
    if forcedType then
        memberType = forcedType
    else
        -- Use probabilities to determine member type
        local roll = math.random()
        local cumulativeChance = 0
        
        for _, typeConfig in ipairs(CONFIG.memberTypes) do
            -- Skip VIP types if not unlocked
            if typeConfig.name == "VIP" and not canSpawnVIP then
                continue
            end
            
            cumulativeChance = cumulativeChance + typeConfig.chance
            if roll <= cumulativeChance then
                memberType = typeConfig.name
                break
            end
        end
    end
    
    -- Get spawn location (front desk)
    local spawnLocation = tycoon:FindFirstChild("FrontDesk")
    if not spawnLocation then
        spawnLocation = tycoon:FindFirstChild("Start")
    end
    
    if not spawnLocation then
        warn("NPCSystem: No spawn location found in tycoon", tycoonId)
        return nil
    end
    
    -- Get NPC from pool
    local npc = self:getPooledNPC(tycoonId, memberType)
    if not npc then
        warn("NPCSystem: Failed to get NPC from pool for tycoon", tycoonId)
        return nil
    end
    
    -- Position NPC
    local spawnPos = getRandomPositionInPart(spawnLocation)
    npc:PivotTo(CFrame.new(spawnPos))
    npc.Parent = workspace
    
    -- Enable NPC
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = CONFIG.movementSpeed
    end
    
    -- Track active NPC
    self._activeNPCs[npc] = {
        tycoonId = tycoonId,
        state = "Entering",
        memberType = memberType,
        lastUpdate = tick(),
        destination = nil,
        equipment = nil,
        pathfindRetries = 0,
        revenue = 0,
        satisfaction = 100 -- Start with full satisfaction
    }
    
    -- Fire event for new member
    EventBridge:fireEvent("NPCSpawned", {
        tycoonId = tycoonId,
        memberType = memberType,
        npc = npc
    })
    
    -- Log
    debugPrint("Spawned", memberType, "NPC in tycoon", tycoonId)
    
    -- Set up the next state for this NPC
    self:findNextDestination(npc)
    
    return npc
end

-- Find the next destination for an NPC
function NPCSystem:findNextDestination(npc)
    if not npc or not npc.Parent then return end
    
    local npcData = self._activeNPCs[npc]
    if not npcData then return end
    
    -- Get the tycoon
    local tycoonId = npcData.tycoonId
    local tycoon = TycoonSystem:getTycoonById(tycoonId)
    if not tycoon then return end
    
    -- Get all available equipment in the tycoon
    local equipment = findEquipmentInTycoon(tycoon)
    
    -- Random choice: use equipment or wander
    local willUseEquipment = math.random() < CONFIG.useEquipmentChance and #equipment > 0
    
    if willUseEquipment then
        -- Pick a random piece of equipment
        local targetEquipment = equipment[math.random(1, #equipment)]
        local equipmentPos
        
        -- Get interaction point
        if targetEquipment:FindFirstChild("InteractionPoint") then
            equipmentPos = targetEquipment.InteractionPoint.Position
        else
            equipmentPos = targetEquipment:GetPivot().Position
        end
        
        npcData.destination = equipmentPos
        npcData.equipment = targetEquipment
        npcData.state = "MovingToEquipment"
        
        -- Try to pathfind there
        self:navigateNPCToDestination(npc, equipmentPos)
        
    else
        -- Just wander to a random spot in the tycoon
        local base = tycoon:FindFirstChild("Base") or tycoon:FindFirstChild("Floor")
        if base then
            local wanderPos = getRandomPositionInPart(base)
            npcData.destination = wanderPos
            npcData.equipment = nil
            npcData.state = "Wandering"
            
            -- Navigate there
            self:navigateNPCToDestination(npc, wanderPos)
        end
    end
end

-- Make an NPC leave the tycoon
function NPCSystem:makeNPCLeave(npc)
    if not npc or not npc.Parent then return end
    
    local npcData = self._activeNPCs[npc]
    if not npcData then return end
    
    -- Get the tycoon
    local tycoonId = npcData.tycoonId
    local tycoon = TycoonSystem:getTycoonById(tycoonId)
    if not tycoon then return end
    
    -- Find exit point
    local exitPoint = tycoon:FindFirstChild("FrontDesk") or tycoon:FindFirstChild("Start")
    if not exitPoint then return end
    
    -- Set destination to exit
    local exitPos = getRandomPositionInPart(exitPoint)
    npcData.destination = exitPos
    npcData.state = "Leaving"
    
    -- Navigate to exit
    self:navigateNPCToDestination(npc, exitPos)
end

-- Navigate an NPC to a destination
function NPCSystem:navigateNPCToDestination(npc, destination)
    if not npc or not npc.Parent then return end
    
    local humanoid = npc:FindFirstChild("Humanoid") 
    if not humanoid then return end
    
    local npcData = self._activeNPCs[npc]
    if not npcData then return end
    
    -- Get current position
    local rootPart = npc:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Use pathfinding service for navigation
    local path = game:GetService("PathfindingService"):CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })
    
    -- Try to compute the path
    local success, errorMessage = pcall(function()
        path:ComputeAsync(rootPart.Position, destination)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        -- Get path waypoints
        local waypoints = path:GetWaypoints()
        
        -- Move to each waypoint
        for i, waypoint in ipairs(waypoints) do
            if not npc or not npc.Parent or not humanoid or humanoid.Health <= 0 then
                break
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            -- Wait until reaching waypoint or timeout
            local startTime = tick()
            local timeout = 5 -- 5 seconds timeout
            
            while npc and npc.Parent and humanoid and humanoid.Health > 0 and 
                  rootPart and (rootPart.Position - waypoint.Position).Magnitude > 1 do
                
                -- Check if we've timed out
                if tick() - startTime > timeout then
                    break
                end
                
                task.wait(0.1)
            end
        end
        
        -- Reset pathfinding retries
        npcData.pathfindRetries = 0
        
    else
        -- Increment retry counter
        npcData.pathfindRetries = (npcData.pathfindRetries or 0) + 1
        
        -- If we've retried too many times, move on
        if npcData.pathfindRetries >= CONFIG.maxPathfindingRetries then
            -- Fallback: try to directly move to destination
            humanoid:MoveTo(destination)
            task.delay(5, function()
                -- After timeout, find a new destination
                if npc and npc.Parent and self._activeNPCs[npc] then
                    self:findNextDestination(npc)
                end
            end)
        else
            -- Try again with a delay
            task.delay(1, function()
                if npc and npc.Parent and self._activeNPCs[npc] then
                    self:navigateNPCToDestination(npc, destination)
                end
            end)
        end
        
        debugPrint("Pathfinding failed for NPC in tycoon", npcData.tycoonId, "retry:", npcData.pathfindRetries)
    end
end

-- Update all NPCs
function NPCSystem:updateNPCs()
    -- Use update grouping for performance
    local currentGroup = self._nextUpdateGroup
    self._nextUpdateGroup = (self._nextUpdateGroup + 1) % CONFIG.updateStaggering
    
    -- Count for performance tracking
    local npcCount = 0
    local startTime = tick()
    
    -- Process each active NPC
    for npc, data in pairs(self._activeNPCs) do
        -- Skip NPCs not in current update group
        if npc and npc:GetAttribute("UpdateGroup") ~= currentGroup then
            continue
        end
        
        npcCount = npcCount + 1
        
        -- Update this NPC
        if npc and npc.Parent then
            self:updateSingleNPC(npc, data)
        else
            -- NPC has been removed, clean up tracking
            self._activeNPCs[npc] = nil
        end
    end
    
    -- Performance logging
    if CONFIG.debug and npcCount > 0 then
        local elapsed = tick() - startTime
        if elapsed > 0.016 then -- 16ms is 1 frame at 60fps
            debugPrint("NPC Update for group", currentGroup, "took", elapsed, "seconds for", npcCount, "NPCs")
        end
    end
end

-- Update a single NPC
function NPCSystem:updateSingleNPC(npc, data)
    if not npc or not npc.Parent then return end
    
    local tycoonId = data.tycoonId
    local tycoon = TycoonSystem:getTycoonById(tycoonId)
    if not tycoon then
        -- Tycoon doesn't exist anymore, remove NPC
        self:returnToPool(npc)
        return
    end
    
    -- Check distance to destination if we have one
    if data.destination then
        local rootPart = npc:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local distance = (rootPart.Position - data.destination).Magnitude
            
            -- If we've reached our destination
            if distance < CONFIG.destinationRadius then
                -- Handle what to do based on current state
                if data.state == "MovingToEquipment" then
                    -- Start using the equipment
                    data.state = "UsingEquipment"
                    data.stateStartTime = tick()
                    data.stateDuration = math.random(CONFIG.standTime[1], CONFIG.standTime[2])
                    
                    -- Play animation if available
                    local humanoid = npc:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        -- Stop moving
                        humanoid.WalkSpeed = 0
                        
                        -- Face the equipment
                        if data.equipment then
                            local equipPos = data.equipment:GetPivot().Position
                            local npcPos = npc:GetPivot().Position
                            local direction = (equipPos - npcPos).Unit
                            local lookCFrame = CFrame.lookAt(npcPos, npcPos + direction)
                            npc:PivotTo(CFrame.new(npcPos) * CFrame.Angles(0, lookCFrame.Y, 0))
                        end
                        
                        -- Play appropriate animation based on equipment
                        local equipmentType = data.equipment and data.equipment:GetAttribute("EquipmentType") or "Generic"
                        -- Animation handling would go here
                    end
                    
                    -- Generate revenue while using equipment
                    local owner = TycoonSystem:getTycoonOwner(tycoon)
                    if owner and RevenueSystem and data.equipment then
                        -- Calculate revenue based on equipment and member type
                        local baseRevenue = data.equipment:GetAttribute("Revenue") or 1
                        local memberMultiplier = npc:GetAttribute("RevenueMultiplier") or 1
                        
                        -- Track accumulated revenue for this session
                        data.revenue = data.revenue + (baseRevenue * memberMultiplier)
                        
                        -- Update satisfaction based on equipment quality
                        if MemberSatisfactionSystem then
                            local equipmentQuality = data.equipment:GetAttribute("Quality") or 1
                            local satisfactionChange = equipmentQuality - 1 -- -1 to +4 typically
                            
                            -- Apply satisfaction change
                            MemberSatisfactionSystem:updateMemberSatisfaction(tycoonId, satisfactionChange, npc)
                        end
                    end
                    
                elseif data.state == "Leaving" then
                    -- Generate revenue before leaving
                    local owner = TycoonSystem:getTycoonOwner(tycoon)
                    if owner and RevenueSystem and data.revenue > 0 then
                        -- Add accumulated revenue to player
                        RevenueSystem:addRevenue(owner, data.revenue, "member_visit")
                        
                        -- Fire event
                        EventBridge:fireEvent("MemberGeneratedRevenue", {
                            tycoonId = tycoonId,
                            memberType = data.memberType,
                            amount = data.revenue
                        })
                    end
                    
                    -- Remove NPC
                    self:returnToPool(npc)
                    
                elseif data.state == "UsingEquipment" then
                    -- Check if we've been using the equipment long enough
                    local elapsed = tick() - data.stateStartTime
                    if elapsed >= data.stateDuration then
                        -- Done using equipment, find a new destination
                        local humanoid = npc:FindFirstChild("Humanoid")
                        if humanoid then 
                            humanoid.WalkSpeed = CONFIG.movementSpeed
                        end
                        
                        -- Decide what to do next
                        local leaveChance = 1 - (data.satisfaction / 100)
                        if math.random() < leaveChance or 
                           math.random() < 0.1 then -- 10% base chance to leave
                            -- Leave the gym
                            self:makeNPCLeave(npc)
                        else
                            -- Find something else to do
                            self:findNextDestination(npc)
                        end
                    end
                    
                elseif data.state == "Wandering" then
                    -- We've reached our wandering destination, find a new one
                    data.stateStartTime = tick()
                    data.stateDuration = math.random(2, 5) -- Stand for a few seconds
                    data.state = "Standing"
                    
                elseif data.state == "Standing" then
                    -- Check if we've been standing long enough
                    local elapsed = tick() - data.stateStartTime
                    if elapsed >= data.stateDuration then
                        -- Done standing, find a new destination
                        self:findNextDestination(npc)
                    end
                end
            end
        end
    end
    
    -- Apply culling - hide NPCs when player is far away
    local shouldCull = not isPlayerNearTycoon(tycoon, CONFIG.cullingDistance)
    
    local humanoid = npc:FindFirstChild("Humanoid")
    if humanoid then
        -- Pause NPCs when culled
        if shouldCull and humanoid.WalkSpeed > 0 then
            humanoid.WalkSpeed = 0
        elseif not shouldCull and data.state ~= "UsingEquipment" and humanoid.WalkSpeed == 0 then
            humanoid.WalkSpeed = CONFIG.movementSpeed
        end
    end
    
    -- Handle despawning based on satisfaction
    if data.satisfaction < 10 and data.state ~= "Leaving" then
        -- Very unsatisfied member is leaving
        self:makeNPCLeave(npc)
    end
end

--[[ Tycoon Management ]]--

-- Start spawning NPCs for a tycoon
function NPCSystem:startNPCSpawning(tycoon)
    if not tycoon then return end
    
    local tycoonId = tycoon:GetAttribute("TycoonId")
    if not tycoonId then return end
    
    -- Initialize pool if needed
    if not self._npcPools[tycoonId] then
        self:initializePool(tycoonId)
    end
    
    -- Check if already spawning
    if self._spawnTimers[tycoonId] then return end
    
    -- Create spawning loop
    self._spawnTimers[tycoonId] = task.spawn(function()
        while true do
            -- Check if the tycoon still exists
            if not tycoon or not tycoon.Parent then
                self:stopNPCSpawning(tycoon)
                break
            end
            
            -- Spawn chance check
            if math.random() < CONFIG.spawnChance then
                self:spawnNPC(tycoon)
            end
            
            -- Wait until next spawn attempt
            task.wait(CONFIG.spawnInterval)
        end
    end)
    
    -- Track this tycoon as active
    self._activeTycoons[tycoonId] = tycoon
    
    debugPrint("Started NPC spawning for tycoon", tycoonId)
end

-- Stop spawning NPCs for a tycoon
function NPCSystem:stopNPCSpawning(tycoon)
    if not tycoon then return end
    
    local tycoonId = tycoon:GetAttribute("TycoonId")
    if not tycoonId then return end
    
    -- Cancel spawn timer
    if self._spawnTimers[tycoonId] then
        task.cancel(self._spawnTimers[tycoonId])
        self._spawnTimers[tycoonId] = nil
    end
    
    -- Clean up existing NPCs
    for npc, data in pairs(self._activeNPCs) do
        if data.tycoonId == tycoonId then
            self:returnToPool(npc)
        end
    end
    
    -- Clean up the pool
    self:cleanupPool(tycoonId)
    
    -- Remove from active tycoons
    self._activeTycoons[tycoonId] = nil
    
    debugPrint("Stopped NPC spawning for tycoon", tycoonId)
end

--[[ Public API ]]--

-- Get active NPC count for a tycoon
function NPCSystem:getActiveMemberCount(tycoonId)
    local count = 0
    local regularCount = 0
    local vipCount = 0
    
    for npc, data in pairs(self._activeNPCs) do
        if data.tycoonId == tycoonId then
            count = count + 1
            
            if data.memberType == "VIP" then
                vipCount = vipCount + 1
            else
                regularCount = regularCount + 1
            end
        end
    end
    
    return {
        total = count,
        regular = regularCount,
        vip = vipCount
    }
end

-- Force spawn a specific member type
function NPCSystem:forceSpawnMember(tycoon, memberType)
    if not tycoon then return nil end
    
    -- Default to regular if not specified
    memberType = memberType or "Regular"
    
    return self:spawnNPC(tycoon, memberType)
end

-- Fill a tycoon with members (for testing or special events)
function NPCSystem:fillTycoon(tycoon, count, memberType)
    if not tycoon then return end
    
    count = count or CONFIG.maxMembersPerTycoon
    
    -- Spawn up to the specified count
    local spawned = 0
    for i = 1, count do
        local npc = self:forceSpawnMember(tycoon, memberType)
        if npc then
            spawned = spawned + 1
        end
        
        task.wait(0.1) -- Small delay between spawns for performance
    end
    
    return spawned
end

-- Remove all NPCs from a tycoon
function NPCSystem:clearTycoon(tycoon)
    if not tycoon then return end
    
    local tycoonId = tycoon:GetAttribute("TycoonId")
    if not tycoonId then return end
    
    -- Count how many we're removing
    local count = 0
    
    -- Find all NPCs from this tycoon
    for npc, data in pairs(table.clone(self._activeNPCs)) do
        if data.tycoonId == tycoonId then
            self:returnToPool(npc)
            count = count + 1
        end
    end
    
    return count
end

-- Update configuration
function NPCSystem:updateConfig(newConfig)
    -- Update only specified values
    for key, value in pairs(newConfig) do
        CONFIG[key] = value
    end
    
    debugPrint("Updated configuration")
end

--[[ Event Handlers ]]--

-- Handle tycoon creation
function NPCSystem:handleTycoonCreated(data)
    if not data or not data.tycoon then return end
    
    -- Start spawning NPCs for this tycoon
    self:startNPCSpawning(data.tycoon)
end

-- Handle tycoon deletion
function NPCSystem:handleTycoonRemoved(data)
    if not data or not data.tycoon then return end
    
    -- Stop spawning NPCs for this tycoon
    self:stopNPCSpawning(data.tycoon)
end

-- Handle player leaving
function NPCSystem:handlePlayerRemoving(player)
    -- Find tycoons owned by this player
    if TycoonSystem then
        local tycoon = TycoonSystem:getTycoonByOwner(player)
        if tycoon then
            -- Stop NPCs for this tycoon
            self:stopNPCSpawning(tycoon)
        end
    end
end

--[[ Initialization and Cleanup ]]--

-- Initialize the NPC system
function NPCSystem:init()
    debugPrint("Initializing NPCSystem v" .. self._version)
    
    -- Get dependencies from registry
    CoreRegistry = self.CoreRegistry
    
    -- Get required systems
    EventBridge = CoreRegistry:getSystem("EventBridge")
    TycoonSystem = CoreRegistry:getSystem("TycoonSystem")
    DataManager = CoreRegistry:getSystem("DataManager")
    MemberSatisfactionSystem = CoreRegistry:getSystem("MemberSatisfactionSystem")
    RevenueSystem = CoreRegistry:getSystem("RevenueSystem")
    
    -- Initialize state
    self._npcPools = {}
    self._activeTycoons = {}
    self._activeNPCs = {}
    self._spawnTimers = {}
    self._models = {}
    
    -- Register events
    if EventBridge then
        EventBridge:registerEvent("TycoonCreated", function(data)
            self:handleTycoonCreated(data)
        end)
        
        EventBridge:registerEvent("TycoonRemoved", function(data)
            self:handleTycoonRemoved(data)
        end)
    end
    
    -- Handle player leaving to clean up resources
    Players.PlayerRemoving:Connect(function(player)
        self:handlePlayerRemoving(player)
    end)
    
    -- Preload models
    if CONFIG.preloadModels then
        self:preloadNPCModels()
    end
    
    return true
end

-- Start the system
function NPCSystem:start()
    debugPrint("Starting NPCSystem")
    
    -- Start update loop
    self._updateConnection = RunService.Heartbeat:Connect(function()
        self:updateNPCs()
    end)
    
    -- Initialize NPCs for existing tycoons
    if TycoonSystem then
        local tycoons = TycoonSystem:getAllTycoons()
        for _, tycoon in pairs(tycoons) do
            self:startNPCSpawning(tycoon)
        end
    end
    
    return true
end

-- Stop the system
function NPCSystem:stop()
    debugPrint("Stopping NPCSystem")
    
    -- Disconnect update loop
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    
    -- Clear all active tycoons
    for tycoonId, tycoon in pairs(self._activeTycoons) do
        self:stopNPCSpawning(tycoon)
    end
    
    -- Clear state
    self._npcPools = {}
    self._activeTycoons = {}
    self._activeNPCs = {}
    self._spawnTimers = {}
    
    return true
end

return NPCSystem