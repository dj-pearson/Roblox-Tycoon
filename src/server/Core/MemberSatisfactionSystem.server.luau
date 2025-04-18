--[[
    MemberSatisfactionSystem.luau
    Handles gym member satisfaction and retention mechanics
    Part of the Core systems architecture
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- System Dependencies
local CoreRegistry
local EventBridge
local DataManager
local RevenueSystem
local NPCSystem
local TycoonSystem

-- Configuration
local CONFIG = {
    -- Base satisfaction settings
    baseSatisfactionLevel = 75, -- Default satisfaction (0-100 scale)
    minSatisfaction = 0,
    maxSatisfaction = 100,
    
    -- Factors affecting satisfaction
    equipmentDensityFactor = 0.5,    -- How equipment count per member affects satisfaction
    cleanlinessImpact = 15,          -- Maximum impact of cleanliness
    staffRatioImpact = 10,           -- Maximum impact of staff to member ratio
    equipmentQualityImpact = 20,     -- Maximum impact of equipment quality
    amenitiesImpact = 15,            -- Maximum impact of amenities (showers, lockers, etc)
    eventBoostImpact = 5,            -- Satisfaction boost from special events
    
    -- Effect of satisfaction on revenue and retention
    revenueBonusPerSatisfactionPoint = 0.005, -- 0.5% revenue increase per satisfaction point above neutral
    revenuePenaltyPerSatisfactionPoint = 0.006, -- 0.6% revenue decrease per satisfaction point below neutral
    neutralSatisfactionLevel = 50,    -- Level considered "neutral" for revenue effects
    
    -- Retention mechanics
    baseMembershipLossRate = 0.05,    -- Base rate at which members leave (5% per cycle)
    retentionCheckInterval = 300,     -- Check retention every 5 minutes
    satisfactionRetentionImpact = 0.1, -- How much satisfaction affects retention (0.1 = 10% swing)
    
    -- Decay settings
    satisfactionDecayRate = 0.5,      -- Points lost per decay interval
    satisfactionDecayInterval = 120,  -- Decay interval in seconds (2 minutes)
    
    -- UI refresh rate
    uiUpdateInterval = 10,            -- Update UI every 10 seconds
    
    -- Debug
    debug = true                      -- Show debug messages
}

-- Module table
local MemberSatisfactionSystem = {
    _name = "MemberSatisfactionSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager", "RevenueSystem", "NPCSystem", "TycoonSystem"},
    _satisfactionCache = {}, -- Cache for stored satisfaction data
    _loops = {},             -- Store task loops for cleanup
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Satisfaction System]", ...)
    end
end

--[[ Core Functions ]]--

-- Calculate member satisfaction for a player
function MemberSatisfactionSystem:calculateSatisfaction(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return CONFIG.baseSatisfactionLevel end
    
    local userId = player.UserId
    
    -- Initialize satisfaction cache if needed
    if not self._satisfactionCache[userId] then
        self._satisfactionCache[userId] = {
            baseSatisfaction = CONFIG.baseSatisfactionLevel,
            lastCalculated = os.time()
        }
    end
    
    local cache = self._satisfactionCache[userId]
    
    -- Base satisfaction score
    local satisfaction = cache.baseSatisfaction
    
    -- Calculate factors affecting satisfaction
    
    -- 1. Equipment density (equipment per member)
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    local memberCount = tycoon:GetAttribute("MembershipCount") or 0
    local equipmentDensity = memberCount > 0 and equipmentCount / memberCount or 0
    local densityEffect = math.min(10, equipmentDensity * 10) * CONFIG.equipmentDensityFactor
    
    -- 2. Cleanliness
    local cleanliness = tycoon:GetAttribute("Cleanliness") or 50
    local cleanlinessEffect = (cleanliness / 100) * CONFIG.cleanlinessImpact
    
    -- 3. Staff ratio
    local staffCount = tycoon:GetAttribute("TotalStaff") or 0
    local staffRatio = memberCount > 0 and staffCount / (memberCount / 50) or 0
    local staffEffect = math.min(1, staffRatio) * CONFIG.staffRatioImpact
    
    -- 4. Equipment quality
    local equipmentQuality = tycoon:GetAttribute("EquipmentQuality") or 50
    local qualityEffect = (equipmentQuality / 100) * CONFIG.equipmentQualityImpact
    
    -- 5. Amenities
    local amenitiesLevel = tycoon:GetAttribute("AmenitiesLevel") or 0
    local amenitiesEffect = (amenitiesLevel / 10) * CONFIG.amenitiesImpact
    
    -- 6. Special event boost
    local eventBoost = 0
    if tycoon:GetAttribute("SpecialEventActive") then
        eventBoost = CONFIG.eventBoostImpact
    end
    
    -- Calculate final satisfaction
    satisfaction = CONFIG.baseSatisfactionLevel +
                  densityEffect +
                  cleanlinessEffect +
                  staffEffect +
                  qualityEffect +
                  amenitiesEffect +
                  eventBoost
    
    -- Clamp to valid range
    satisfaction = math.clamp(satisfaction, CONFIG.minSatisfaction, CONFIG.maxSatisfaction)
    
    -- Store the calculated satisfaction
    tycoon:SetAttribute("MemberSatisfaction", satisfaction)
    
    -- Update cache
    cache.baseSatisfaction = satisfaction
    cache.lastCalculated = os.time()
    
    return satisfaction
end

-- Calculate revenue multiplier based on satisfaction
function MemberSatisfactionSystem:calculateRevenueFactor(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 1.0 end
    
    local satisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
    local neutralLevel = CONFIG.neutralSatisfactionLevel
    
    -- Calculate revenue modifier
    local revenueFactor = 1.0
    
    if satisfaction > neutralLevel then
        -- Bonus for high satisfaction
        local bonusPoints = satisfaction - neutralLevel
        revenueFactor = 1.0 + (bonusPoints * CONFIG.revenueBonusPerSatisfactionPoint)
    elseif satisfaction < neutralLevel then
        -- Penalty for low satisfaction
        local penaltyPoints = neutralLevel - satisfaction
        revenueFactor = 1.0 - (penaltyPoints * CONFIG.revenuePenaltyPerSatisfactionPoint)
    end
    
    -- Store for other systems to use
    tycoon:SetAttribute("SatisfactionRevenueFactor", revenueFactor)
    
    return revenueFactor
end

-- Calculate member retention multiplier based on satisfaction
function MemberSatisfactionSystem:calculateRetentionFactor(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 1.0 end
    
    local satisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
    local neutralLevel = CONFIG.neutralSatisfactionLevel
    
    -- Calculate retention factor
    local satisfactionImpact = (satisfaction - neutralLevel) / 100
    local retentionFactor = 1.0 - (CONFIG.baseMembershipLossRate + 
                            (satisfactionImpact * CONFIG.satisfactionRetentionImpact))
    
    -- Clamp to reasonable values (members always have some chance to leave)
    retentionFactor = math.clamp(retentionFactor, 0.5, 0.99)
    
    -- Store for other systems to use
    tycoon:SetAttribute("MemberRetentionFactor", retentionFactor)
    
    return retentionFactor
end

-- Process member retention based on satisfaction
function MemberSatisfactionSystem:processMemberRetention(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0 end
    
    -- Skip if tycoon hasn't been started
    if not tycoon:GetAttribute("TycoonStarted") then return 0 end
    
    -- Get current members and retention factor
    local currentMembers = tycoon:GetAttribute("MembershipCount") or 0
    local retentionFactor = self:calculateRetentionFactor(player)
    
    -- Calculate how many members leave
    local leavingMembers = math.floor(currentMembers * (1 - retentionFactor))
    
    -- Don't reduce below a minimum threshold
    if currentMembers - leavingMembers < 5 and currentMembers > 5 then
        leavingMembers = currentMembers - 5
    end
    
    -- Ensure we don't have negative leaving members
    leavingMembers = math.max(0, leavingMembers)
    
    if leavingMembers > 0 then
        -- Update member count
        local newMemberCount = currentMembers - leavingMembers
        
        -- Update tycoon attributes
        tycoon:SetAttribute("MembershipCount", newMemberCount)
        
        -- Update membership cache if using RevenueSystem
        if RevenueSystem and RevenueSystem._memberCache and RevenueSystem._memberCache[player.UserId] then
            RevenueSystem._memberCache[player.UserId].memberCount = newMemberCount
        end
        
        -- Save data through DataManager
        if DataManager then
            DataManager:updatePlayerData(player, "MembershipCount", newMemberCount)
        end
        
        -- Fire event for other systems
        if EventBridge then
            EventBridge:fireEvent("MembersLeft", player, leavingMembers)
        end
        
        debugPrint(player.Name .. " lost " .. leavingMembers .. " members due to satisfaction")
    end
    
    return leavingMembers
end

-- Apply satisfaction decay over time
function MemberSatisfactionSystem:applySatisfactionDecay(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Skip if tycoon hasn't been started
    if not tycoon:GetAttribute("TycoonStarted") then return end
    
    local userId = player.UserId
    if not self._satisfactionCache[userId] then return end
    
    -- Get current satisfaction
    local currentSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
    
    -- Apply decay
    local newSatisfaction = currentSatisfaction - CONFIG.satisfactionDecayRate
    newSatisfaction = math.max(newSatisfaction, CONFIG.minSatisfaction)
    
    -- Update tycoon attributes
    tycoon:SetAttribute("MemberSatisfaction", newSatisfaction)
    
    -- Update cache
    self._satisfactionCache[userId].baseSatisfaction = newSatisfaction
    
    -- Save data through DataManager
    if DataManager then
        DataManager:updatePlayerData(player, "MemberSatisfaction", newSatisfaction)
    end
end

-- Update cleanliness based on member and staff counts
function MemberSatisfactionSystem:updateCleanliness(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Skip if tycoon hasn't been started
    if not tycoon:GetAttribute("TycoonStarted") then return end
    
    -- Get current values
    local currentCleanliness = tycoon:GetAttribute("Cleanliness") or 50
    local memberCount = tycoon:GetAttribute("MembershipCount") or 0
    local staffCount = tycoon:GetAttribute("Staff_janitor") or 0
    
    -- Calculate cleanliness change
    -- Each janitor can maintain cleanliness for 50 members
    local memberImpact = -0.02 * memberCount -- Members reduce cleanliness
    local staffImpact = 1.0 * staffCount -- Staff improve cleanliness
    
    local cleanlinessChange = staffImpact + memberImpact
    
    -- Apply change
    local newCleanliness = currentCleanliness + cleanlinessChange
    newCleanliness = math.clamp(newCleanliness, 0, 100)
    
    -- Update tycoon attributes
    tycoon:SetAttribute("Cleanliness", newCleanliness)
    
    -- Save data through DataManager
    if DataManager then
        DataManager:updatePlayerData(player, "Cleanliness", newCleanliness)
    end
    
    return newCleanliness
end

-- Update equipment quality (wear and tear)
function MemberSatisfactionSystem:updateEquipmentQuality(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Skip if tycoon hasn't been started
    if not tycoon:GetAttribute("TycoonStarted") then return end
    
    -- Get current values
    local currentQuality = tycoon:GetAttribute("EquipmentQuality") or 100 -- Start with perfect equipment
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    local memberCount = tycoon:GetAttribute("MembershipCount") or 0
    local maintenanceStaff = tycoon:GetAttribute("Staff_maintenance") or 0
    
    -- Calculate quality change
    -- Equipment wears down based on usage (members per equipment)
    local usageRatio = equipmentCount > 0 and memberCount / equipmentCount or 1
    local wearFactor = -0.01 * usageRatio
    
    -- Maintenance staff repairs equipment
    local repairFactor = 0.5 * maintenanceStaff
    
    local qualityChange = wearFactor + repairFactor
    
    -- Apply change
    local newQuality = currentQuality + qualityChange
    newQuality = math.clamp(newQuality, 0, 100)
    
    -- Update tycoon attributes
    tycoon:SetAttribute("EquipmentQuality", newQuality)
    
    -- Save data through DataManager
    if DataManager then
        DataManager:updatePlayerData(player, "EquipmentQuality", newQuality)
    end
    
    return newQuality
end

-- Apply satisfaction impacts for equipment purchases
function MemberSatisfactionSystem:onTilePurchased(player, tileId)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Give a small satisfaction boost for new equipment
    local currentSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
    local newSatisfaction = currentSatisfaction + 2 -- Small boost per equipment piece
    
    -- Clamp to valid range
    newSatisfaction = math.min(newSatisfaction, CONFIG.maxSatisfaction)
    
    -- Update tycoon attributes
    tycoon:SetAttribute("MemberSatisfaction", newSatisfaction)
    
    -- Update equipment quality (new equipment is perfect)
    local equipmentQuality = tycoon:GetAttribute("EquipmentQuality") or 50
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    
    -- Calculate weighted average of quality with new equipment
    local newQuality = (equipmentQuality * (equipmentCount - 1) + 100) / equipmentCount
    if equipmentCount <= 1 then newQuality = 100 end
    
    tycoon:SetAttribute("EquipmentQuality", newQuality)
    
    -- Update cache
    local userId = player.UserId
    if self._satisfactionCache[userId] then
        self._satisfactionCache[userId].baseSatisfaction = newSatisfaction
    end
    
    -- Save data through DataManager
    if DataManager then
        DataManager:updatePlayerData(player, "MemberSatisfaction", newSatisfaction)
        DataManager:updatePlayerData(player, "EquipmentQuality", newQuality)
    end
    
    self:calculateRevenueFactor(player)
end

-- Initialize a player's satisfaction data
function MemberSatisfactionSystem:initializePlayer(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end
    
    -- Set default attributes if they don't exist
    local defaultAttributes = {
        MemberSatisfaction = CONFIG.baseSatisfactionLevel,
        Cleanliness = 50,
        EquipmentQuality = 100,
        AmenitiesLevel = 0,
        SatisfactionRevenueFactor = 1.0,
        MemberRetentionFactor = 0.95
    }
    
    -- Load data from DataManager or use defaults
    local playerData = {}
    if DataManager then
        playerData = DataManager:getPlayerData(player) or {}
    end
    
    -- Apply values from data store or defaults
    for key, defaultValue in pairs(defaultAttributes) do
        local savedValue = playerData[key]
        tycoon:SetAttribute(key, savedValue or defaultValue)
    end
    
    -- Initialize satisfaction cache
    local userId = player.UserId
    self._satisfactionCache[userId] = {
        baseSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel,
        lastCalculated = os.time()
    }
    
    -- Calculate initial satisfaction and factors
    self:calculateSatisfaction(player)
    self:calculateRevenueFactor(player)
    self:calculateRetentionFactor(player)
    
    debugPrint("Initialized satisfaction data for " .. player.Name)
    
    return true
end

-- Utility function to get a player's tycoon
function MemberSatisfactionSystem:_getPlayerTycoon(player)
    if not player then return nil end
    
    if TycoonSystem then
        return TycoonSystem:getPlayerTycoon(player)
    end
    
    -- Fallback
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        debugPrint("Warning: Tycoon not found for player " .. player.Name)
        return nil
    end
    
    return tycoon.Value
end

--[[ Initialization and Event Handling ]]--

function MemberSatisfactionSystem:init()
    debugPrint("Initializing Member Satisfaction System v" .. self._version)
    
    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    RevenueSystem = CoreRegistry:getSystem("RevenueSystem")
    NPCSystem = CoreRegistry:getSystem("NPCSystem")
    TycoonSystem = CoreRegistry:getSystem("TycoonSystem")
    
    -- Register events
    if EventBridge then
        -- Register listeners for relevant events
        EventBridge:registerEvent("TilePurchased", function(player, tileId)
            self:onTilePurchased(player, tileId)
        end)
        
        EventBridge:registerEvent("PlayerDataLoaded", function(player)
            self:initializePlayer(player)
        end)
        
        EventBridge:registerEvent("StaffHired", function(player, staffType, count)
            -- Recalculate satisfaction when staff changes
            self:calculateSatisfaction(player)
        end)
        
        EventBridge:registerEvent("StaffFired", function(player, staffType, count)
            -- Recalculate satisfaction when staff changes
            self:calculateSatisfaction(player)
        end)
        
        EventBridge:registerEvent("SpecialEventStarted", function(player)
            -- Boost satisfaction during special events
            self:calculateSatisfaction(player)
        end)
        
        EventBridge:registerEvent("SpecialEventEnded", function(player)
            -- Re-calculate satisfaction when events end
            self:calculateSatisfaction(player)
        end)
    end
    
    -- Patch RevenueSystem to include satisfaction
    if RevenueSystem then
        local originalCalculateHourlyRevenue = RevenueSystem.calculateHourlyRevenue
        if originalCalculateHourlyRevenue then
            RevenueSystem.calculateHourlyRevenue = function(player)
                -- Get base hourly revenue
                local baseRevenue = originalCalculateHourlyRevenue(player)
                
                -- Apply satisfaction factor
                local satisfactionFactor = self:calculateRevenueFactor(player)
                local adjustedRevenue = baseRevenue * satisfactionFactor
                
                return math.floor(adjustedRevenue)
            end
            
            debugPrint("Patched RevenueSystem.calculateHourlyRevenue to include satisfaction")
        end
    end
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:initializePlayer(player)
        end)
    end
    
    -- Setup player added/removed events
    Players.PlayerAdded:Connect(function(player)
        -- Player initialization is now handled via the PlayerDataLoaded event
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        -- Clean up
        self._satisfactionCache[player.UserId] = nil
    end)
    
    -- Start background processes
    self:startProcessing()
    
    -- Legacy support (create global reference for backward compatibility)
    _G.MemberSatisfactionSystem = self
    
    debugPrint("Member Satisfaction System initialized")
    return true
end

function MemberSatisfactionSystem:startProcessing()
    -- Start decay loop
    self._loops.decay = task.spawn(function()
        while true do
            task.wait(CONFIG.satisfactionDecayInterval)
            
            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:applySatisfactionDecay(player)
                end)
            end
        end
    end)
    
    -- Start retention check loop
    self._loops.retention = task.spawn(function()
        while true do
            task.wait(CONFIG.retentionCheckInterval)
            
            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:updateCleanliness(player)
                    self:updateEquipmentQuality(player)
                    self:calculateSatisfaction(player)
                    self:processMemberRetention(player)
                end)
            end
        end
    end)
    
    -- Start UI update loop
    self._loops.uiUpdate = task.spawn(function()
        while true do
            task.wait(CONFIG.uiUpdateInterval)
            
            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:sendUIUpdate(player)
                end)
            end
        end
    end)
    
    debugPrint("Started satisfaction processing loops")
end

function MemberSatisfactionSystem:stopProcessing()
    -- Cancel all loops
    for _, loop in pairs(self._loops) do
        task.cancel(loop)
    end
    
    self._loops = {}
    
    debugPrint("Stopped satisfaction processing")
end

function MemberSatisfactionSystem:sendUIUpdate(player)
    if not EventBridge then return end
    
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Send satisfaction data to client
    EventBridge:fireEvent("SatisfactionUpdated", player, {
        satisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel,
        cleanliness = tycoon:GetAttribute("Cleanliness") or 50,
        equipmentQuality = tycoon:GetAttribute("EquipmentQuality") or 100,
        revenueFactor = tycoon:GetAttribute("SatisfactionRevenueFactor") or 1.0,
        retentionFactor = tycoon:GetAttribute("MemberRetentionFactor") or 0.95
    })
end

function MemberSatisfactionSystem:start()
    debugPrint("Member Satisfaction System started")
    return true
end

function MemberSatisfactionSystem:stop()
    debugPrint("Stopping Member Satisfaction System")
    self:stopProcessing()
    return true
end

--[[ Public API ]]--

function MemberSatisfactionSystem:GetSatisfaction(player)
    return self:calculateSatisfaction(player)
end

function MemberSatisfactionSystem:GetRevenueFactor(player)
    return self:calculateRevenueFactor(player)
end

function MemberSatisfactionSystem:GetRetentionFactor(player)
    return self:calculateRetentionFactor(player)
end

function MemberSatisfactionSystem:ImproveCleanliness(player, amount)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end
    
    local currentCleanliness = tycoon:GetAttribute("Cleanliness") or 50
    local newCleanliness = currentCleanliness + amount
    newCleanliness = math.clamp(newCleanliness, 0, 100)
    
    tycoon:SetAttribute("Cleanliness", newCleanliness)
    
    -- Recalculate satisfaction
    self:calculateSatisfaction(player)
    
    return true
end

function MemberSatisfactionSystem:ImproveEquipmentQuality(player, amount)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end
    
    local currentQuality = tycoon:GetAttribute("EquipmentQuality") or 50
    local newQuality = currentQuality + amount
    newQuality = math.clamp(newQuality, 0, 100)
    
    tycoon:SetAttribute("EquipmentQuality", newQuality)
    
    -- Recalculate satisfaction
    self:calculateSatisfaction(player)
    
    return true
end

function MemberSatisfactionSystem:BoostSatisfaction(player, amount, duration)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end
    
    local currentSatisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
    local newSatisfaction = currentSatisfaction + amount
    newSatisfaction = math.clamp(newSatisfaction, CONFIG.minSatisfaction, CONFIG.maxSatisfaction)
    
    tycoon:SetAttribute("MemberSatisfaction", newSatisfaction)
    
    -- Update cache
    local userId = player.UserId
    if self._satisfactionCache[userId] then
        self._satisfactionCache[userId].baseSatisfaction = newSatisfaction
    end
    
    -- Recalculate factors
    self:calculateRevenueFactor(player)
    self:calculateRetentionFactor(player)
    
    -- Schedule removal of boost after duration
    if duration then
        task.delay(duration, function()
            if player and player.Parent then
                local tycoon = self:_getPlayerTycoon(player)
                if tycoon then
                    local satisfaction = tycoon:GetAttribute("MemberSatisfaction") or CONFIG.baseSatisfactionLevel
                    tycoon:SetAttribute("MemberSatisfaction", math.max(CONFIG.baseSatisfactionLevel, satisfaction - amount))
                    
                    -- Update cache
                    if self._satisfactionCache[userId] then
                        self._satisfactionCache[userId].baseSatisfaction = tycoon:GetAttribute("MemberSatisfaction")
                    end
                    
                    -- Recalculate factors
                    self:calculateRevenueFactor(player)
                    self:calculateRetentionFactor(player)
                end
            end
        end)
    end
    
    return true
end

function MemberSatisfactionSystem:GetConfig()
    return table.freeze(table.clone(CONFIG)) -- Return immutable copy
end

-- Register with CoreRegistry
return CoreRegistry.registerSystem("MemberSatisfactionSystem", MemberSatisfactionSystem, {"CoreRegistry", "EventBridge", "DataManager", "RevenueSystem", "NPCSystem", "TycoonSystem"})