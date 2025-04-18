--[[
    RevenueSystem.luau
    Handles gym membership calculations, revenue generation, and special events
    Part of the Core systems architecture
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- System Dependencies
local CoreRegistry
local EventBridge
local DataManager
local NPCSystem

-- Configuration
local CONFIG = {
    -- Base membership calculations
    minMembersPerEquipment = 1,   -- Minimum members gained per equipment
    maxMembersPerEquipment = 10,  -- Maximum members gained per equipment
    membershipFeeBase = 15,       -- Revenue per regular member per interval
    vipMembershipFeeBase = 50,    -- Revenue per VIP member per interval

    -- Tiered scaling (affects member cap and acquisition rate)
    tierThresholds = {
        [1] = 25,   -- First membership tier threshold (equipment count)
        [2] = 50,   -- Second threshold
        [3] = 100,  -- Third threshold
        [4] = 200,  -- Fourth threshold
        [5] = 300   -- Fifth threshold
    },

    tierMultipliers = {
        [0] = 1.0,  -- Base tier multiplier
        [1] = 1.2,  -- Tier 1 multiplier
        [2] = 1.5,  -- Tier 2 multiplier
        [3] = 1.8,  -- Tier 3 multiplier
        [4] = 2.2,  -- Tier 4 multiplier
        [5] = 3.0   -- Tier 5 multiplier
    },

    -- VIP members
    vipPercentBase = 0.05,        -- Base percentage of VIP members (5%)
    vipPercentIncreasePerTier = 0.02, -- How much VIP percentage increases per tier

    -- Revenue calculation
    revenueInterval = 60,         -- Generate revenue every 60 seconds
    incomeDisplayUpdateInterval = 10, -- Update income displays every 10 seconds

    -- Special events
    specialEventBoostMultiplier = 1.5, -- Membership boost during special events
    specialEventDuration = 300,    -- Duration of special events (5 min)
    specialEventCooldown = 1800,   -- Cooldown between events (30 min)

    -- Debug
    debug = true                  -- Show debug messages
}

-- Module table
local RevenueSystem = {
    _name = "RevenueSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager", "NPCSystem"},
    _memberCache = {}, -- Cache for stored membership data
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Revenue System]", ...)
    end
end

--[[ Core Functions ]]--

-- Calculate current membership tier based on equipment count
function RevenueSystem:calculateMembershipTier(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0 end

    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0

    -- Determine tier based on equipment thresholds
    for tier = 5, 1, -1 do
        if equipmentCount >= CONFIG.tierThresholds[tier] then
            return tier
        end
    end

    return 0 -- Base tier
end

-- Calculate total membership count with randomization
function RevenueSystem:calculateMembershipCount(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0, false end
    
    local userId = player.UserId

    -- Initialize membership cache if needed
    if not self._memberCache[userId] then
        self._memberCache[userId] = {
            equipmentCount = 0,
            memberCount = 0,
            lastEquipmentCount = 0
        }
    end

    local cache = self._memberCache[userId]
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    local newMembersAdded = false

    -- If equipment count has changed, add new members
    if equipmentCount > cache.lastEquipmentCount then
        newMembersAdded = true
        local newEquipmentCount = equipmentCount - cache.lastEquipmentCount
        local currentTier = self:calculateMembershipTier(player)
        local tierMultiplier = CONFIG.tierMultipliers[currentTier]

        -- Add random number of members for each new equipment piece
        for i = 1, newEquipmentCount do
            local baseMembers = math.random(
                CONFIG.minMembersPerEquipment, 
                CONFIG.maxMembersPerEquipment
            )

            -- Apply tier multiplier
            local adjustedMembers = math.floor(baseMembers * tierMultiplier)
            cache.memberCount = cache.memberCount + adjustedMembers

            debugPrint(player.Name .. " gained " .. adjustedMembers .. " new members from equipment")
        end

        cache.lastEquipmentCount = equipmentCount
    end

    -- Apply any special modifiers from other systems
    local specialBonus = tycoon:GetAttribute("MembershipBonus") or 0
    local memberCount = math.floor(cache.memberCount * (1 + specialBonus))

    -- Store the value for other systems to use
    tycoon:SetAttribute("MembershipCount", memberCount)

    return memberCount, newMembersAdded
end

-- Calculate VIP membership count
function RevenueSystem:calculateVIPMemberCount(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0 end

    local totalMembers = self:calculateMembershipCount(player)
    local currentTier = self:calculateMembershipTier(player)

    -- VIP percentage increases with tier
    local vipPercentage = CONFIG.vipPercentBase + (currentTier * CONFIG.vipPercentIncreasePerTier)

    local vipCount = math.floor(totalMembers * vipPercentage)

    -- Store for other systems
    tycoon:SetAttribute("VIPMemberCount", vipCount)

    return vipCount
end

-- Calculate hourly revenue from memberships
function RevenueSystem:calculateHourlyRevenue(player)
    local totalMembers = self:calculateMembershipCount(player)
    local vipMembers = self:calculateVIPMemberCount(player)
    local regularMembers = totalMembers - vipMembers

    -- Calculate individual revenue components
    local regularRevenue = regularMembers * CONFIG.membershipFeeBase
    local vipRevenue = vipMembers * CONFIG.vipMembershipFeeBase

    local hourlyRevenue = regularRevenue + vipRevenue

    -- Apply special event multiplier if active
    local tycoon = self:_getPlayerTycoon(player)
    if tycoon and tycoon:GetAttribute("SpecialEventActive") then
        hourlyRevenue = hourlyRevenue * CONFIG.specialEventBoostMultiplier
    end

    -- Apply multipliers from other systems (specialization, seasons, etc.)
    local revenueMultiplier = tycoon:GetAttribute("RevenueMultiplier") or 1
    hourlyRevenue = hourlyRevenue * revenueMultiplier

    -- Store for other systems
    if tycoon then
        tycoon:SetAttribute("HourlyRevenue", math.floor(hourlyRevenue))
    end

    return math.floor(hourlyRevenue)
end

-- Calculate revenue per interval
function RevenueSystem:calculateIntervalRevenue(player)
    local hourlyRevenue = self:calculateHourlyRevenue(player)
    local intervalRevenue = hourlyRevenue * (CONFIG.revenueInterval / 3600)
    return math.floor(intervalRevenue)
end

-- Generate income for a player
function RevenueSystem:generateIncome(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0 end

    -- Only generate income if player has started their tycoon
    if not tycoon:GetAttribute("TycoonStarted") then return 0 end

    -- Calculate income for this interval
    local income = self:calculateIntervalRevenue(player)

    -- Add NPC-based income if NPCSystem is available
    if NPCSystem and NPCSystem.generateIncomeFromNPCs then
        local npcIncome = NPCSystem:generateIncomeFromNPCs(player)
        income = income + npcIncome
    end

    -- Add to accrued dues
    local currentDues = tycoon:GetAttribute("AccruedDues") or 0
    local newDues = currentDues + income
    tycoon:SetAttribute("AccruedDues", newDues)
    
    -- Save data through DataManager
    if DataManager then
        DataManager:updatePlayerData(player, "AccruedDues", newDues)
    end

    -- Fire event for other systems
    if EventBridge then
        EventBridge:fireEvent("IncomeGenerated", player, income)
    end

    return income
end

-- Start a special event for a player
function RevenueSystem:startSpecialEvent(player, eventType)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end

    -- Set special event flag
    tycoon:SetAttribute("SpecialEventActive", true)
    tycoon:SetAttribute("SpecialEventType", eventType or "Membership Drive")
    tycoon:SetAttribute("SpecialEventEndTime", os.time() + CONFIG.specialEventDuration)
    
    -- Save event data
    if DataManager then
        DataManager:updatePlayerData(player, "SpecialEventActive", true)
        DataManager:updatePlayerData(player, "SpecialEventType", eventType or "Membership Drive")
        DataManager:updatePlayerData(player, "SpecialEventEndTime", os.time() + CONFIG.specialEventDuration)
    end

    -- Fire event for UI and other systems
    if EventBridge then
        EventBridge:fireEvent("SpecialEventStarted", player, {
            eventType = eventType or "Membership Drive",
            duration = CONFIG.specialEventDuration,
            boostMultiplier = CONFIG.specialEventBoostMultiplier
        })
    end

    -- Schedule event end
    task.delay(CONFIG.specialEventDuration, function()
        if player and player.Parent then
            self:endSpecialEvent(player)
        end
    end)

    debugPrint("Started special event for " .. player.Name .. ": " .. (eventType or "Membership Drive"))
    return true
end

-- End a special event
function RevenueSystem:endSpecialEvent(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end

    -- Event already ended
    if not tycoon:GetAttribute("SpecialEventActive") then return false end

    -- Reset event flags
    tycoon:SetAttribute("SpecialEventActive", false)
    tycoon:SetAttribute("SpecialEventType", nil)
    tycoon:SetAttribute("SpecialEventEndTime", nil)
    tycoon:SetAttribute("SpecialEventCooldown", os.time() + CONFIG.specialEventCooldown)
    
    -- Update data
    if DataManager then
        DataManager:updatePlayerData(player, "SpecialEventActive", false)
        DataManager:updatePlayerData(player, "SpecialEventType", nil)
        DataManager:updatePlayerData(player, "SpecialEventEndTime", nil)
        DataManager:updatePlayerData(player, "SpecialEventCooldown", os.time() + CONFIG.specialEventCooldown)
    end

    -- Fire event for UI and other systems
    if EventBridge then
        EventBridge:fireEvent("SpecialEventEnded", player)
    end

    debugPrint("Ended special event for " .. player.Name)
    return true
end

-- Update membership displays
function RevenueSystem:updateMembershipDisplays(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return end

    -- Calculate current values
    local memberCount = self:calculateMembershipCount(player)
    local vipCount = self:calculateVIPMemberCount(player)
    local hourlyRevenue = self:calculateHourlyRevenue(player)
    local currentTier = self:calculateMembershipTier(player)

    -- Update attributes for UI and other systems
    tycoon:SetAttribute("MembershipCount", memberCount)
    tycoon:SetAttribute("VIPMemberCount", vipCount)
    tycoon:SetAttribute("HourlyRevenue", hourlyRevenue)
    tycoon:SetAttribute("MembershipTier", currentTier)

    -- Calculate and store next tier threshold if not at max
    if currentTier < 5 then
        local nextThreshold = CONFIG.tierThresholds[currentTier + 1]
        tycoon:SetAttribute("NextTierThreshold", nextThreshold)
    else
        tycoon:SetAttribute("NextTierThreshold", nil)
    end

    -- Send update to client via EventBridge
    if EventBridge then
        EventBridge:fireEvent("MembershipUpdated", player, {
            memberCount = memberCount,
            vipCount = vipCount,
            hourlyRevenue = hourlyRevenue,
            currentTier = currentTier,
            nextThreshold = tycoon:GetAttribute("NextTierThreshold")
        })
    end
end

-- Initialize a player's membership data
function RevenueSystem:initializePlayer(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end

    -- Set default attributes if they don't exist
    local defaultAttributes = {
        MembershipCount = 0,
        VIPMemberCount = 0,
        HourlyRevenue = 0,
        MembershipTier = 0,
        AccruedDues = 0
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

    -- Initialize member cache
    local userId = player.UserId
    self._memberCache[userId] = {
        memberCount = tycoon:GetAttribute("MembershipCount") or 0,
        lastEquipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    }

    -- Update displays with initial values
    self:updateMembershipDisplays(player)

    -- Listen for equipment purchases
    if EventBridge then
        -- Already handled through the tile purchased event listener in init
    end

    debugPrint("Initialized membership data for " .. player.Name)
    return true
end

-- Handle tile purchase
function RevenueSystem:onTilePurchased(player, tileId)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end

    -- Mark tycoon as started if this is the first purchase
    if not tycoon:GetAttribute("TycoonStarted") then
        tycoon:SetAttribute("TycoonStarted", true)
        
        if DataManager then
            DataManager:updatePlayerData(player, "TycoonStarted", true)
        end
    end

    -- Check if membership tier changed
    local oldTier = tycoon:GetAttribute("MembershipTier") or 0
    self:updateMembershipDisplays(player)
    local newTier = tycoon:GetAttribute("MembershipTier") or 0

    -- Notify player if tier increased
    if newTier > oldTier then
        if EventBridge then
            EventBridge:fireEvent("MembershipTierUp", player, {
                newTier = newTier,
                multiplier = CONFIG.tierMultipliers[newTier]
            })
        end

        debugPrint(player.Name .. " increased to membership tier " .. newTier)
    end

    return true
end

-- Start income generation
function RevenueSystem:startIncomeGeneration()
    -- Generate income loop
    self._incomeLoop = task.spawn(function()
        while true do
            task.wait(CONFIG.revenueInterval)

            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    local income = self:generateIncome(player)
                    if income > 0 then
                        debugPrint(player.Name .. " earned $" .. income .. " from memberships")
                    end
                end)
            end
        end
    end)

    -- Update displays loop (more frequent than income generation)
    self._displayLoop = task.spawn(function()
        while true do
            task.wait(CONFIG.incomeDisplayUpdateInterval)

            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:updateMembershipDisplays(player)
                end)
            end
        end
    end)

    -- Special event manager
    self._eventLoop = task.spawn(function()
        while true do
            task.wait(30) -- Check every 30 seconds

            for _, player in pairs(Players:GetPlayers()) do
                local tycoon = self:_getPlayerTycoon(player)
                if tycoon and tycoon:GetAttribute("TycoonStarted") then
                    -- Check if event is active and update if needed
                    if tycoon:GetAttribute("SpecialEventActive") then
                        local endTime = tycoon:GetAttribute("SpecialEventEndTime") or 0
                        if os.time() >= endTime then
                            self:endSpecialEvent(player)
                        end
                    end

                    -- Random chance to start special event if not on cooldown
                    if not tycoon:GetAttribute("SpecialEventActive") then
                        local cooldownTime = tycoon:GetAttribute("SpecialEventCooldown") or 0
                        if os.time() >= cooldownTime then
                            -- 1% chance every 30 seconds
                            if math.random(1, 100) <= 1 then
                                self:startSpecialEvent(player)
                            end
                        end
                    end
                end
            end
        end
    end)

    debugPrint("Started income generation")
    return true
end

-- Stop the income generation loops
function RevenueSystem:stopIncomeGeneration()
    if self._incomeLoop then
        task.cancel(self._incomeLoop)
        self._incomeLoop = nil
    end
    
    if self._displayLoop then
        task.cancel(self._displayLoop)
        self._displayLoop = nil
    end
    
    if self._eventLoop then
        task.cancel(self._eventLoop)
        self._eventLoop = nil
    end
    
    debugPrint("Stopped income generation")
    return true
end

-- Utility function to get a player's tycoon
function RevenueSystem:_getPlayerTycoon(player)
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        -- Log error but don't create here - should be handled by TycoonSystem
        debugPrint("Warning: Tycoon not found for player " .. player.Name)
        return nil
    end
    return tycoon
end

--[[ Public API ]]--

function RevenueSystem:GetMembershipCount(player)
    return self:calculateMembershipCount(player)
end

function RevenueSystem:GetVIPCount(player)
    return self:calculateVIPMemberCount(player)
end

function RevenueSystem:GetHourlyRevenue(player)
    return self:calculateHourlyRevenue(player)
end

function RevenueSystem:GetMembershipTier(player)
    return self:calculateMembershipTier(player)
end

function RevenueSystem:CollectAccruedDues(player)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return 0 end
    
    local amount = tycoon:GetAttribute("AccruedDues") or 0
    tycoon:SetAttribute("AccruedDues", 0)
    
    if DataManager then
        DataManager:updatePlayerData(player, "AccruedDues", 0)
    end
    
    if amount > 0 and EventBridge then
        EventBridge:fireEvent("DuesCollected", player, amount)
    end
    
    return amount
end

function RevenueSystem:TriggerSpecialEvent(player, eventType)
    return self:startSpecialEvent(player, eventType)
end

function RevenueSystem:EndSpecialEvent(player)
    return self:endSpecialEvent(player)
end

function RevenueSystem:AddMembershipBonus(player, bonusMultiplier, duration)
    local tycoon = self:_getPlayerTycoon(player)
    if not tycoon then return false end
    
    local currentBonus = tycoon:GetAttribute("MembershipBonus") or 0
    tycoon:SetAttribute("MembershipBonus", currentBonus + bonusMultiplier)
    
    -- Schedule removal of bonus after duration
    if duration then
        task.delay(duration, function()
            if player and player.Parent then
                local tycoon = self:_getPlayerTycoon(player)
                if tycoon then
                    local bonus = tycoon:GetAttribute("MembershipBonus") or 0
                    tycoon:SetAttribute("MembershipBonus", math.max(0, bonus - bonusMultiplier))
                    
                    if DataManager then
                        DataManager:updatePlayerData(
                            player, 
                            "MembershipBonus", 
                            tycoon:GetAttribute("MembershipBonus")
                        )
                    end
                end
            end
        end)
    end
    
    if DataManager then
        DataManager:updatePlayerData(player, "MembershipBonus", tycoon:GetAttribute("MembershipBonus"))
    end
    
    return true
end

function RevenueSystem:GetConfig()
    return table.freeze(table.clone(CONFIG)) -- Return immutable copy
end

--[[ Initialization and Event Handling ]]--

function RevenueSystem:init()
    debugPrint("Initializing Revenue System v" .. self._version)
    
    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    NPCSystem = CoreRegistry:getSystem("NPCSystem")
    
    -- Register events
    if EventBridge then
        -- Register listeners for relevant events
        EventBridge:registerEvent("TilePurchased", function(player, tileId)
            self:onTilePurchased(player, tileId)
        end)
        
        EventBridge:registerEvent("PlayerDataLoaded", function(player)
            self:initializePlayer(player)
        end)
        
        EventBridge:registerEvent("SpecializationChanged", function(player, specialization)
            self:updateMembershipDisplays(player)
        end)
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
        -- Clear cache for player
        self._memberCache[player.UserId] = nil
    end)
    
    -- Start income generation
    self:startIncomeGeneration()
    
    -- Legacy support (create global reference for backward compatibility)
    _G.MembershipSystem = self
    
    debugPrint("Revenue System initialized")
    return true
end

function RevenueSystem:start()
    debugPrint("Revenue System started")
    return true
end

function RevenueSystem:stop()
    debugPrint("Stopping Revenue System")
    self:stopIncomeGeneration()
    return true
end

return RevenueSystem
