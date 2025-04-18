-- MilestoneSystem.luau
-- Unified system for tracking player achievements, milestones, and progression
-- Consolidated from GymMilestonesSystem
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager")
local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
local NPCSystem = CoreRegistry.getSystem("NPCSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,           -- Enable debug logging
    badgesEnabled = true,          -- Whether to award Roblox badges
    notificationsEnabled = true,   -- Whether to show notifications
    
    -- Badge IDs (replace with actual badge IDs)
    badges = {
        first_equipment = 0,       -- First equipment purchase
        gym_tier_5 = 0,            -- Reach Gym Tier 5
        gym_tier_10 = 0,           -- Reach Gym Tier 10
        millionaire = 0,           -- Earn 1,000,000 cash
    },
    
    -- Equipment milestone thresholds
    equipmentMilestones = {
        {count = 1, reward = 500, title = "First Equipment"},
        {count = 5, reward = 1000, title = "Gym Starter"},
        {count = 10, reward = 2000, title = "Growing Gym"},
        {count = 25, reward = 5000, title = "Established Gym"},
        {count = 50, reward = 10000, title = "Advanced Gym"},
        {count = 100, reward = 25000, title = "Premium Fitness Center"}
    },
    
    -- Tier milestone thresholds
    tierMilestones = {
        {tier = 2, reward = 1000, title = "Tier 2 Gym"},
        {tier = 5, reward = 5000, title = "Tier 5 Gym"},
        {tier = 10, reward = 15000, title = "Tier 10 Gym"},
        {tier = 15, reward = 30000, title = "Tier 15 Gym"},
        {tier = 20, reward = 50000, title = "Tier 20 Gym"},
        {tier = 25, reward = 100000, title = "Tier 25 Gym"}
    },
    
    -- Revenue milestones thresholds
    revenueMilestones = {
        {amount = 10000, reward = 1000, title = "Small Business"},
        {amount = 100000, reward = 5000, title = "Growing Business"},
        {amount = 1000000, reward = 25000, title = "Millionaire"},
        {amount = 10000000, reward = 100000, title = "Multi-Millionaire"},
        {amount = 100000000, reward = 500000, title = "Fitness Tycoon"}
    },
    
    -- NPC milestones thresholds
    npcMilestones = {
        {count = 5, reward = 1000, title = "First Members"},
        {count = 15, reward = 3000, title = "Growing Membership"},
        {count = 30, reward = 8000, title = "Popular Gym"},
        {count = 50, reward = 15000, title = "Full House"}
    },
    
    -- Time played milestones (in minutes)
    timeMilestones = {
        {minutes = 60, reward = 2000, title = "1 Hour Played"},
        {minutes = 180, reward = 5000, title = "3 Hours Played"},
        {minutes = 600, reward = 10000, title = "10 Hours Played"},
        {minutes = 1200, reward = 25000, title = "20 Hours Played"}
    },
    
    -- Special achievements
    specialAchievements = {
        firstSpecialization = {reward = 2000, title = "First Specialization"},
        maxSpecialization = {reward = 10000, title = "Specialization Mastery"},
        completeAllEquipment = {reward = 50000, title = "Equipment Collector"}
    }
}

-- Create the MilestoneSystem
local MilestoneSystem = {
    -- Internal state
    playerData = {},
    trackedPlayers = {},
    milestoneDefinitions = {},
    totalPlayTime = {}
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[MilestoneSystem]", ...)
    end
end

-- Initialize the module
function MilestoneSystem:initialize()
    log("Initializing MilestoneSystem...")
    
    -- Register event handlers
    self:registerEvents()
    
    -- Build milestone definitions
    self:initializeMilestoneDefinitions()
    
    -- Initialize player tracking
    Players.PlayerAdded:Connect(function(player)
        self:setupPlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:cleanupPlayer(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:setupPlayer(player)
        end)
    end
    
    -- Start the playtime tracker
    self:startPlayTimeTracking()
    
    log("MilestoneSystem initialized")
    return true
end

-- Register for various events
function MilestoneSystem:registerEvents()
    if not EventBridge then
        log("EventBridge not found, could not register for events")
        return
    end
    
    -- Listen for equipment purchases
    EventBridge:connectEvent("TilePurchased", function(player, tileId)
        self:onTilePurchased(player, tileId)
    end)
    
    -- Listen for income collection
    EventBridge:connectEvent("DuesCollected", function(player, amount)
        self:onRevenueCollected(player, amount)
    end)
    
    -- Listen for gym level up
    EventBridge:connectEvent("GymLevelUp", function(player, newLevel)
        self:onGymLevelUp(player, newLevel)
    end)
    
    -- Listen for specialization changes
    EventBridge:connectEvent("SpecializationChanged", function(player, newSpecialization)
        self:onSpecializationChanged(player, newSpecialization)
    end)
    
    -- Listen for specialization level up
    EventBridge:connectEvent("SpecializationLevelUp", function(player, specialization, newLevel)
        self:onSpecializationLevelUp(player, specialization, newLevel)
    end)
    
    -- Listen for NPC spawning
    EventBridge:connectEvent("NPCSpawned", function(player)
        self:checkNPCMilestones(player)
    end)
    
    log("Registered for events")
end

-- Initialize milestone definitions
function MilestoneSystem:initializeMilestoneDefinitions()
    self.milestoneDefinitions = {
        equipment = {},
        tier = {},
        revenue = {},
        npc = {},
        time = {},
        special = {}
    }
    
    -- Process equipment milestones
    for _, milestone in ipairs(CONFIG.equipmentMilestones) do
        self.milestoneDefinitions.equipment[milestone.count] = {
            id = "equipment_" .. milestone.count,
            title = milestone.title,
            description = "Purchase " .. milestone.count .. " pieces of equipment",
            reward = milestone.reward,
            badgeId = milestone.count == 1 and CONFIG.badges.first_equipment or nil
        }
    end
    
    -- Process tier milestones
    for _, milestone in ipairs(CONFIG.tierMilestones) do
        self.milestoneDefinitions.tier[milestone.tier] = {
            id = "tier_" .. milestone.tier,
            title = milestone.title,
            description = "Reach Gym Tier " .. milestone.tier,
            reward = milestone.reward,
            badgeId = (milestone.tier == 5 and CONFIG.badges.gym_tier_5) or 
                     (milestone.tier == 10 and CONFIG.badges.gym_tier_10) or nil
        }
    end
    
    -- Process revenue milestones
    for _, milestone in ipairs(CONFIG.revenueMilestones) do
        self.milestoneDefinitions.revenue[milestone.amount] = {
            id = "revenue_" .. milestone.amount,
            title = milestone.title,
            description = "Earn a total of $" .. milestone.amount,
            reward = milestone.reward,
            badgeId = milestone.amount == 1000000 and CONFIG.badges.millionaire or nil
        }
    end
    
    -- Process NPC milestones
    for _, milestone in ipairs(CONFIG.npcMilestones) do
        self.milestoneDefinitions.npc[milestone.count] = {
            id = "npc_" .. milestone.count,
            title = milestone.title,
            description = "Have " .. milestone.count .. " active gym members",
            reward = milestone.reward
        }
    end
    
    -- Process time milestones
    for _, milestone in ipairs(CONFIG.timeMilestones) do
        self.milestoneDefinitions.time[milestone.minutes] = {
            id = "time_" .. milestone.minutes,
            title = milestone.title,
            description = "Play for " .. milestone.minutes .. " minutes",
            reward = milestone.reward
        }
    end
    
    -- Process special achievements
    self.milestoneDefinitions.special = {
        firstSpecialization = {
            id = "special_first_specialization",
            title = CONFIG.specialAchievements.firstSpecialization.title,
            description = "Choose your first gym specialization",
            reward = CONFIG.specialAchievements.firstSpecialization.reward
        },
        maxSpecialization = {
            id = "special_max_specialization",
            title = CONFIG.specialAchievements.maxSpecialization.title,
            description = "Reach maximum level with any specialization",
            reward = CONFIG.specialAchievements.maxSpecialization.reward
        },
        completeAllEquipment = {
            id = "special_all_equipment",
            title = CONFIG.specialAchievements.completeAllEquipment.title,
            description = "Purchase at least one of every equipment type",
            reward = CONFIG.specialAchievements.completeAllEquipment.reward
        }
    }
    
    log("Initialized milestone definitions")
end

-- Set up tracking for a player
function MilestoneSystem:setupPlayer(player)
    if not player then return end
    
    task.wait(3) -- Wait for other systems to initialize player data
    
    -- Initialize player data
    self.playerData[player.UserId] = self.playerData[player.UserId] or {
        completedMilestones = {},
        totalRevenue = 0,
        equipmentOwned = {},
        joinTime = os.time(),
        lastUpdate = os.time()
    }
    
    -- Load existing milestone data from DataManager if available
    if DataManager and DataManager.loadData then
        local data = DataManager.loadData(player)
        if data and data.milestones then
            -- Merge with existing data
            for id, completed in pairs(data.milestones) do
                if completed then
                    self.playerData[player.UserId].completedMilestones[id] = true
                end
            end
        end
    end
    
    -- Start tracking this player
    self.trackedPlayers[player.UserId] = true
    self.totalPlayTime[player.UserId] = self.totalPlayTime[player.UserId] or 0
    
    log("Set up player tracking for " .. player.Name)
    
    -- Check initial milestones
    task.spawn(function()
        task.wait(5) -- Give time for tycoon to be fully set up
        self:checkAllMilestones(player)
    end)
end

-- Clean up when a player leaves
function MilestoneSystem:cleanupPlayer(player)
    if not player then return end
    
    -- Save milestone data if needed
    if DataManager and DataManager.saveData then
        local data = self.playerData[player.UserId]
        if data then
            -- Update play time before saving
            self:updatePlayerPlayTime(player)
            
            task.spawn(function()
                DataManager.saveData(player, true) -- Save immediately
            end)
        end
    end
    
    -- Stop tracking
    self.trackedPlayers[player.UserId] = nil
    
    log("Cleaned up player tracking for " .. player.Name)
end

-- Start the playtime tracking loop
function MilestoneSystem:startPlayTimeTracking()
    task.spawn(function()
        while true do
            task.wait(60) -- Update every minute
            
            -- Update playtime for all players
            for userId in pairs(self.trackedPlayers) do
                local player = self:getPlayerByUserId(userId)
                if player then
                    self:updatePlayerPlayTime(player)
                end
            end
        end
    end)
    
    log("Started play time tracking")
end

-- Update a player's tracked playtime
function MilestoneSystem:updatePlayerPlayTime(player)
    if not player then return end
    
    local data = self.playerData[player.UserId]
    if not data then return end
    
    local now = os.time()
    local elapsedMinutes = (now - data.lastUpdate) / 60
    
    -- Add to total play time
    self.totalPlayTime[player.UserId] = (self.totalPlayTime[player.UserId] or 0) + elapsedMinutes
    data.lastUpdate = now
    
    -- Check time milestones
    self:checkTimeMilestones(player)
end

-- Handle equipment purchase events
function MilestoneSystem:onTilePurchased(player, tileId)
    if not player or not tileId then return end
    
    local data = self.playerData[player.UserId]
    if not data then
        self:setupPlayer(player) -- Initialize if not set up
        data = self.playerData[player.UserId]
        if not data then return end
    end
    
    -- Track this equipment type
    data.equipmentOwned[tileId] = (data.equipmentOwned[tileId] or 0) + 1
    
    -- Check equipment milestones
    self:checkEquipmentMilestones(player)
    
    -- Check for special "all equipment" milestone
    self:checkAllEquipmentMilestone(player)
end

-- Handle revenue collection events
function MilestoneSystem:onRevenueCollected(player, amount)
    if not player or not amount then return end
    
    local data = self.playerData[player.UserId]
    if not data then
        self:setupPlayer(player)
        data = self.playerData[player.UserId]
        if not data then return end
    end
    
    -- Add to total revenue
    data.totalRevenue = (data.totalRevenue or 0) + amount
    
    -- Check revenue milestones
    self:checkRevenueMilestones(player)
end

-- Handle gym level up events
function MilestoneSystem:onGymLevelUp(player, newLevel)
    if not player or not newLevel then return end
    
    -- Check tier milestones
    self:checkTierMilestones(player, newLevel)
end

-- Handle specialization change events
function MilestoneSystem:onSpecializationChanged(player, newSpecialization)
    if not player then return end
    
    -- If this is the first specialization (not "None"), award the milestone
    if newSpecialization and newSpecialization ~= "None" then
        self:checkSpecialMilestone(player, "firstSpecialization")
    end
end

-- Handle specialization level up events
function MilestoneSystem:onSpecializationLevelUp(player, specialization, newLevel)
    if not player or not specialization or not newLevel then return end
    
    local SpecializationSystem = CoreRegistry.getSystem("SpecializationSystem")
    if SpecializationSystem then
        local maxLevel = SpecializationSystem.getConfig().specializationLevel.maxLevel
        
        if newLevel >= maxLevel then
            -- Reached max specialization level
            self:checkSpecialMilestone(player, "maxSpecialization")
        end
    end
end

-- Check equipment milestones for a player
function MilestoneSystem:checkEquipmentMilestones(player)
    if not player then return end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return end
    
    local equipmentCount = tycoon.Value:GetAttribute("EquipmentCount") or 0
    
    -- Check each equipment milestone
    for _, milestone in ipairs(CONFIG.equipmentMilestones) do
        if equipmentCount >= milestone.count then
            self:awardMilestone(player, "equipment", milestone.count)
        end
    end
end

-- Check tier milestones for a player
function MilestoneSystem:checkTierMilestones(player, specificTier)
    if not player then return end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return end
    
    local gymTier = specificTier or tycoon.Value:GetAttribute("GymTier") or 1
    
    -- Check each tier milestone
    for _, milestone in ipairs(CONFIG.tierMilestones) do
        if gymTier >= milestone.tier then
            self:awardMilestone(player, "tier", milestone.tier)
        end
    end
end

-- Check revenue milestones for a player
function MilestoneSystem:checkRevenueMilestones(player)
    if not player then return end
    
    local data = self.playerData[player.UserId]
    if not data then return end
    
    local totalRevenue = data.totalRevenue or 0
    
    -- Check each revenue milestone
    for _, milestone in ipairs(CONFIG.revenueMilestones) do
        if totalRevenue >= milestone.amount then
            self:awardMilestone(player, "revenue", milestone.amount)
        end
    end
end

-- Check NPC milestones for a player
function MilestoneSystem:checkNPCMilestones(player)
    if not player then return end
    
    -- Get current NPC count
    local NPCCount = 0
    
    if NPCSystem and NPCSystem.countNPCs then
        NPCCount = NPCSystem.countNPCs(player)
    else
        -- Fallback if NPCSystem isn't available
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
            if npcsFolder then
                NPCCount = #npcsFolder:GetChildren()
            end
        end
    end
    
    -- Check each NPC milestone
    for _, milestone in ipairs(CONFIG.npcMilestones) do
        if NPCCount >= milestone.count then
            self:awardMilestone(player, "npc", milestone.count)
        end
    end
end

-- Check time milestones for a player
function MilestoneSystem:checkTimeMilestones(player)
    if not player then return end
    
    local playTime = self.totalPlayTime[player.UserId] or 0
    
    -- Check each time milestone
    for _, milestone in ipairs(CONFIG.timeMilestones) do
        if playTime >= milestone.minutes then
            self:awardMilestone(player, "time", milestone.minutes)
        end
    end
end

-- Check special milestones
function MilestoneSystem:checkSpecialMilestone(player, milestoneKey)
    if not player or not milestoneKey then return end
    
    if not self.milestoneDefinitions.special[milestoneKey] then
        log("Unknown special milestone: " .. milestoneKey)
        return
    end
    
    -- Award the special milestone
    local milestone = self.milestoneDefinitions.special[milestoneKey]
    self:awardMilestone(player, "special", milestoneKey)
end

-- Check if the player has at least one of every equipment type
function MilestoneSystem:checkAllEquipmentMilestone(player)
    if not player then return end
    
    local data = self.playerData[player.UserId]
    if not data then return end
    
    -- Get the BuyTileSystem
    local BuyTileSystem = CoreRegistry.getSystem("BuyTileSystem")
    if not BuyTileSystem or not BuyTileSystem.getEquipmentTemplates then
        return false -- Can't check without the system
    end
    
    local templates = BuyTileSystem.getEquipmentTemplates()
    if not templates then return false end
    
    -- Count how many unique equipment types exist
    local totalTypes = 0
    for _ in pairs(templates) do
        totalTypes = totalTypes + 1
    end
    
    -- Count how many unique types the player has
    local playerTypesCount = 0
    for equipType in pairs(data.equipmentOwned) do
        playerTypesCount = playerTypesCount + 1
    end
    
    -- If player has at least 90% of all equipment types, award the milestone
    -- (90% allows for some equipment to be special and not required)
    if playerTypesCount >= (totalTypes * 0.9) then
        self:checkSpecialMilestone(player, "completeAllEquipment")
        return true
    end
    
    return false
end

-- Check all possible milestones for a player
function MilestoneSystem:checkAllMilestones(player)
    if not player then return end
    
    task.spawn(function()
        self:checkEquipmentMilestones(player)
    end)
    
    task.spawn(function()
        self:checkTierMilestones(player)
    end)
    
    task.spawn(function()
        self:checkRevenueMilestones(player)
    end)
    
    task.spawn(function()
        self:checkNPCMilestones(player)
    end)
    
    task.spawn(function()
        self:checkTimeMilestones(player)
    end)
    
    task.spawn(function()
        -- Check if player has a specialization
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            local specialization = tycoon.Value:GetAttribute("Specialization")
            if specialization and specialization ~= "None" then
                self:checkSpecialMilestone(player, "firstSpecialization")
            end
        end
    end)
    
    task.spawn(function()
        self:checkAllEquipmentMilestone(player)
    end)
    
    log("Checked all milestones for " .. player.Name)
end

-- Award a milestone to a player if they haven't received it already
function MilestoneSystem:awardMilestone(player, category, key)
    if not player or not category or not key then return false end
    
    -- Get milestone definition
    local milestoneDefinition
    if category == "special" then
        milestoneDefinition = self.milestoneDefinitions[category][key]
    else
        milestoneDefinition = self.milestoneDefinitions[category][key]
    end
    
    if not milestoneDefinition then
        log("Unknown milestone: " .. category .. " - " .. tostring(key))
        return false
    end
    
    local milestoneId = milestoneDefinition.id
    
    -- Check if player already has this milestone
    local data = self.playerData[player.UserId]
    if not data then return false end
    
    if data.completedMilestones[milestoneId] then
        -- Already awarded
        return false
    end
    
    -- Award milestone
    data.completedMilestones[milestoneId] = true
    log(player.Name .. " earned milestone: " .. milestoneDefinition.title)
    
    -- Award cash reward
    if milestoneDefinition.reward and milestoneDefinition.reward > 0 then
        -- Give cash to player
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cash = leaderstats:FindFirstChild("Cash")
            if cash then
                cash.Value = cash.Value + milestoneDefinition.reward
            end
        end
    end
    
    -- Award badge if applicable
    if CONFIG.badgesEnabled and milestoneDefinition.badgeId and milestoneDefinition.badgeId > 0 then
        task.spawn(function()
            pcall(function()
                BadgeService:AwardBadge(player.UserId, milestoneDefinition.badgeId)
            end)
        end)
    end
    
    -- Send notification to player
    if CONFIG.notificationsEnabled then
        self:sendMilestoneNotification(player, milestoneDefinition)
    end
    
    -- Fire event
    if EventBridge then
        EventBridge:fireEvent("MilestoneAchieved", player, milestoneId, milestoneDefinition)
        EventBridge:fireClientEvent("MilestoneAchieved", player, milestoneId, milestoneDefinition)
    end
    
    -- Save milestone data
    if DataManager and DataManager.saveData then
        -- Delay slightly to batch multiple achievements
        task.delay(3, function()
            DataManager.saveData(player, false) -- Not immediate
        end)
    end
    
    return true
end

-- Send notification to player
function MilestoneSystem:sendMilestoneNotification(player, milestoneInfo)
    if not player or not milestoneInfo then return end
    
    -- Create notification data
    local notificationData = {
        title = "Milestone Achieved!",
        message = milestoneInfo.title .. "\n" .. milestoneInfo.description,
        reward = milestoneInfo.reward > 0 and ("Reward: $" .. milestoneInfo.reward) or nil,
        duration = 8 -- Show for 8 seconds
    }
    
    -- Send to client
    if EventBridge then
        EventBridge:fireClientEvent("ShowNotification", player, notificationData)
    end
end

-- Get a player by their UserId
function MilestoneSystem:getPlayerByUserId(userId)
    for _, player in pairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end

-- Get all milestones for a player
function MilestoneSystem:getPlayerMilestones(player)
    if not player then return {} end
    
    local data = self.playerData[player.UserId]
    if not data then return {} end
    
    local result = {
        completed = {},
        available = {},
        next = {}
    }
    
    -- Process equipment milestones
    local tycoon = player:FindFirstChild("Tycoon")
    local equipmentCount = tycoon and tycoon.Value and tycoon.Value:GetAttribute("EquipmentCount") or 0
    local nextEquipmentMilestone = nil
    
    for _, milestone in ipairs(CONFIG.equipmentMilestones) do
        local milestoneInfo = self.milestoneDefinitions.equipment[milestone.count]
        if milestoneInfo then
            if data.completedMilestones[milestoneInfo.id] then
                table.insert(result.completed, milestoneInfo)
            elseif equipmentCount >= milestone.count then
                table.insert(result.available, milestoneInfo)
            elseif not nextEquipmentMilestone or milestone.count < nextEquipmentMilestone.count then
                nextEquipmentMilestone = {
                    id = milestoneInfo.id,
                    title = milestoneInfo.title,
                    description = milestoneInfo.description,
                    progress = equipmentCount / milestone.count,
                    current = equipmentCount,
                    target = milestone.count,
                    category = "equipment"
                }
            end
        end
    end
    
    if nextEquipmentMilestone then
        table.insert(result.next, nextEquipmentMilestone)
    end
    
    -- Add similar processing for other milestone types
    -- (tier, revenue, npc, time, special)
    
    return result
end

-- Public API
local PublicAPI = {
    initialize = function()
        return MilestoneSystem:initialize()
    end,
    
    checkAllMilestones = function(player)
        return MilestoneSystem:checkAllMilestones(player)
    end,
    
    awardMilestone = function(player, category, key)
        return MilestoneSystem:awardMilestone(player, category, key)
    end,
    
    getPlayerMilestones = function(player)
        return MilestoneSystem:getPlayerMilestones(player)
    end,
    
    getMilestoneDefinitions = function()
        return MilestoneSystem.milestoneDefinitions
    end,
    
    getConfig = function()
        return CONFIG
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("MilestoneSystem", PublicAPI, {"EventBridge", "DataManager", "TycoonSystem", "NPCSystem"})