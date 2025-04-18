-- RebirthSystem.server.luau
-- Enhanced system for rebirthing with unlockable content progression
-- Place in ServerScriptService/Enhancements

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Try to load CoreRegistry if available
local CoreRegistry
pcall(function()
    CoreRegistry = require(ServerScriptService:FindFirstChild("CoreRegistry"))
end)

-- Try to load systems from CoreRegistry or directly
local DataManager, TycoonSystem, RevenueSystem, SpecializationSystem
if CoreRegistry then
    DataManager = CoreRegistry.getSystem("DataManager")
    TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    RevenueSystem = CoreRegistry.getSystem("RevenueSystem")
    SpecializationSystem = CoreRegistry.getSystem("SpecializationSystem")
else
    -- Legacy fallback
    pcall(function() DataManager = require(ServerScriptService:FindFirstChild("GymTycoonDataManager")) end)
    pcall(function() TycoonSystem = require(ServerScriptService:FindFirstChild("TycoonSystem")) end)
    pcall(function() RevenueSystem = require(ServerScriptService:FindFirstChild("RevenueSystem") or ServerScriptService:FindFirstChild("GymRevenueSystem")) end)
    pcall(function() SpecializationSystem = require(ServerScriptService:FindFirstChild("SpecializationSystem") or ServerScriptService:FindFirstChild("GymSpecializationSystem")) end)
end

-- Set up EventBridge
local EventBridge
if CoreRegistry then
    EventBridge = CoreRegistry.getSystem("EventBridge")
else
    EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
    if not EventBridge then
        EventBridge = Instance.new("Folder")
        EventBridge.Name = "EventBridge"
        EventBridge.Parent = ReplicatedStorage
    end
end

-- Configuration
local CONFIG = {
    -- Basic rebirth settings
    baseRebirthCost = 100000, -- Starting cost for first rebirth
    rebirthCostMultiplier = 2.5, -- How much the cost increases per level
    maxRebirthLevel = 50, -- Maximum rebirth level
    
    -- Revenue multipliers
    baseBonusMultiplier = 0.1, -- Base 10% bonus per rebirth
    tierBonusMultipliers = {
        [5] = 0.05,   -- Extra 5% at rebirth level 5
        [10] = 0.1,   -- Extra 10% at rebirth level 10
        [20] = 0.15,  -- Extra 15% at rebirth level 20
        [30] = 0.2,   -- Extra 20% at rebirth level 30
        [50] = 0.25   -- Extra 25% at rebirth level 50
    },
    
    -- Unlockable gym features by rebirth level
    unlockableFeatures = {
        [1] = {
            name = "Premium Equipment",
            description = "Unlock premium equipment options",
            equipmentBonus = 0.15, -- 15% equipment effectiveness bonus
            icon = "rbxassetid://12696906515"
        },
        [3] = {
            name = "VIP Member Access",
            description = "Attract VIP members more easily",
            vipChanceBonus = 0.2, -- 20% increased VIP chance
            vipValueBonus = 0.15, -- 15% increased VIP value
            icon = "rbxassetid://12696906726"
        },
        [5] = {
            name = "Executive Office",
            description = "Unlock the executive office feature",
            revenueBonus = 0.1, -- 10% passive revenue
            model = "ExecutiveOffice",
            icon = "rbxassetid://12696906940"
        },
        [7] = {
            name = "Specialized Training Areas",
            description = "Unlock specialized training areas",
            specializationEffectiveness = 0.25, -- 25% specialization bonus
            icon = "rbxassetid://12696907112"
        },
        [10] = {
            name = "Advanced Analytics",
            description = "Get insights into member preferences",
            memberRetentionBonus = 0.2, -- 20% better member retention
            membershipDuration = 0.3, -- 30% longer memberships
            icon = "rbxassetid://12696907316"
        },
        [15] = {
            name = "Celebrity Endorsements",
            description = "Attract celebrity gym members",
            celebrityChance = 0.05, -- 5% chance for celebrity visits
            revenueBonus = 0.15, -- 15% extra revenue
            model = "CelebrityLounge",
            icon = "rbxassetid://12696907575"
        },
        [20] = {
            name = "Franchise Rights",
            description = "Build a second gym location",
            franchiseUnlock = true,
            icon = "rbxassetid://12696907750"
        },
        [25] = {
            name = "Luxury Amenities",
            description = "Add luxury amenities to your gym",
            vipValueBonus = 0.3, -- 30% VIP value bonus
            satisfactionBonus = 0.25, -- 25% satisfaction bonus
            model = "LuxuryAmenities",
            icon = "rbxassetid://12696907989"
        },
        [30] = {
            name = "Elite Performance Center",
            description = "Create an elite performance center",
            specializationEffectiveness = 0.4, -- 40% specialization bonus
            equipmentBonus = 0.3, -- 30% equipment effectiveness
            model = "PerformanceCenter",
            icon = "rbxassetid://12696908188"
        },
        [40] = {
            name = "International Brand",
            description = "Take your gym brand international",
            globalRevenueBonus = 0.5, -- 50% overall revenue bonus
            icon = "rbxassetid://12696908391"
        },
        [50] = {
            name = "Fitness Empire",
            description = "Complete fitness industry domination",
            empireStatus = true, -- Special endgame features
            allBonuses = 0.25, -- 25% bonus to all stats
            model = "FitnessEmpireHQ",
            icon = "rbxassetid://12696908712"
        }
    },
    
    -- Rebirth perks (passive abilities unlocked at certain levels)
    rebirthPerks = {
        [2] = {
            name = "Quick Start",
            description = "Start with $10,000 after each rebirth",
            startingCash = 10000,
            icon = "rbxassetid://12696908920"
        },
        [4] = {
            name = "Member Loyalty",
            description = "Members are 25% less likely to leave",
            memberRetentionBonus = 0.25,
            icon = "rbxassetid://12696909133"
        },
        [6] = {
            name = "Equipment Mastery",
            description = "Equipment is 15% more effective",
            equipmentBonus = 0.15,
            icon = "rbxassetid://12696909340"
        },
        [8] = {
            name = "Staff Expertise",
            description = "Staff are 20% more effective",
            staffEffectivenessBonus = 0.2,
            icon = "rbxassetid://12696909543"
        },
        [12] = {
            name = "Efficient Management",
            description = "10% lower operating costs",
            costReduction = 0.1,
            icon = "rbxassetid://12696909758"
        },
        [16] = {
            name = "Auto Maintenance",
            description = "Equipment auto-repairs over time",
            autoMaintenance = true,
            icon = "rbxassetid://12696909961"
        },
        [22] = {
            name = "Marketing Genius",
            description = "Passively attract new members",
            passiveMemberGain = true,
            icon = "rbxassetid://12696910156"
        },
        [28] = {
            name = "VIP Network",
            description = "VIP members bring friends",
            vipReferralChance = 0.3, -- 30% chance for VIPs to refer new VIPs
            icon = "rbxassetid://12696910370"
        },
        [35] = {
            name = "Celebrity Magnet",
            description = "Triple chance for celebrity visits",
            celebrityChanceMultiplier = 3,
            icon = "rbxassetid://12696910595"
        },
        [45] = {
            name = "Industry Pioneer",
            description = "Unlock unique equipment options",
            uniqueEquipmentAccess = true,
            icon = "rbxassetid://12696910795"
        }
    },
    
    -- Special achievements tied to rebirth
    rebirthAchievements = {
        {
            id = "first_rebirth",
            name = "Phoenix Rising",
            description = "Complete your first rebirth",
            requirementType = "rebirthCount",
            requirement = 1,
            reward = 10000,
            icon = "rbxassetid://12696911020"
        },
        {
            id = "rebirth_milestone_5",
            name = "Reborn Legend",
            description = "Reach rebirth level 5",
            requirementType = "rebirthCount",
            requirement = 5,
            reward = 50000,
            icon = "rbxassetid://12696911256"
        },
        {
            id = "rebirth_milestone_10",
            name = "Rebirth Master",
            description = "Reach rebirth level 10",
            requirementType = "rebirthCount",
            requirement = 10,
            reward = 100000,
            icon = "rbxassetid://12696911473"
        },
        {
            id = "rebirth_milestone_25",
            name = "Transcendent",
            description = "Reach rebirth level 25",
            requirementType = "rebirthCount",
            requirement = 25,
            reward = 500000,
            icon = "rbxassetid://12696911700"
        },
        {
            id = "rebirth_milestone_50",
            name = "Immortal Legend",
            description = "Reach rebirth level 50 (maximum)",
            requirementType = "rebirthCount",
            requirement = 50,
            reward = 1000000,
            icon = "rbxassetid://12696911907"
        },
        {
            id = "speed_rebirth",
            name = "Quick Revolution",
            description = "Complete a rebirth within 2 hours of the previous one",
            requirementType = "rebirthSpeed",
            requirement = 7200, -- 2 hours in seconds
            reward = 25000,
            icon = "rbxassetid://12696912152"
        },
        {
            id = "rebirth_collector",
            name = "Feature Collector",
            description = "Unlock 5 different rebirth features",
            requirementType = "featuresUnlocked",
            requirement = 5,
            reward = 50000,
            icon = "rbxassetid://12696912374"
        }
    },
    
    -- Visual effects for rebirth
    visualEffects = {
        transformDuration = 3, -- seconds
        particleColor = Color3.fromRGB(255, 215, 0), -- Gold
        particleImage = "rbxassetid://3084116722", -- Star particle
        soundEffect = "rbxassetid://1753832226" -- Success sound
    },
    
    -- Franchise system for high-level rebirths
    franchiseSystem = {
        unlockLevel = 20,
        maxLocations = 3,
        revenueSharePercent = 0.2 -- 20% bonus from each franchise
    },
    
    -- Debug
    debug = true
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[RebirthSystem]", ...)
    end
end

-- Module table
local RebirthSystem = {
    CONFIG = CONFIG, -- export config for other systems
    
    -- Stored state
    playerRebirthData = {}, -- Format: {userId = {rebirthCount, lastRebirthTime, unlockedFeatures, perks}}
}

-- Get player rebirth data
function RebirthSystem:getPlayerRebirthData(player)
    if not player then return nil end
    
    local userId = player.UserId
    
    -- Return existing data if available
    if self.playerRebirthData[userId] then
        return self.playerRebirthData[userId]
    end
    
    -- Try to load from DataManager
    if DataManager then
        local loadedData
        
        -- Try different data access methods based on available implementations
        if typeof(DataManager.getPlayerData) == "function" then
            loadedData = DataManager.getPlayerData(player, "rebirthData")
        elseif typeof(DataManager.getData) == "function" then
            loadedData = DataManager.getData(player, "rebirthData")
        end
        
        if loadedData then
            self.playerRebirthData[userId] = loadedData
            debugPrint("Loaded rebirth data for", player.Name)
            return loadedData
        end
    end
    
    -- Initialize new data
    local newData = {
        rebirthCount = 0,
        lastRebirthTime = 0,
        unlockedFeatures = {},
        activePerks = {},
        achievements = {},
        franchiseLocations = 0,
        totalRebirthsCompleted = 0,
        fastestRebirthTime = math.huge,
        currentRebirthStartTime = os.time()
    }
    
    self.playerRebirthData[userId] = newData
    
    -- Save immediately
    self:savePlayerRebirthData(player)
    
    return newData
end

-- Save player rebirth data
function RebirthSystem:savePlayerRebirthData(player)
    if not player then return end
    
    local userId = player.UserId
    local data = self.playerRebirthData[userId]
    
    if not data then return end
    
    -- Try to save using DataManager
    if DataManager then
        if typeof(DataManager.updatePlayerData) == "function" then
            DataManager.updatePlayerData(player, "rebirthData", data)
            debugPrint("Saved rebirth data for", player.Name)
        elseif typeof(DataManager.updateData) == "function" then
            DataManager.updateData(player, "rebirthData", data)
            debugPrint("Saved rebirth data for", player.Name)
        end
    end
end

-- Calculate rebirth cost based on current level
function RebirthSystem:calculateRebirthCost(rebirthCount)
    local cost = CONFIG.baseRebirthCost
    
    for i = 1, rebirthCount do
        cost = cost * CONFIG.rebirthCostMultiplier
    end
    
    return math.floor(cost)
end

-- Calculate rebirth bonus multiplier based on level and unlocked features
function RebirthSystem:calculateRebirthMultiplier(rebirthCount)
    -- Base multiplier: rebirthCount * baseBonusMultiplier
    local multiplier = rebirthCount * CONFIG.baseBonusMultiplier
    
    -- Add tier bonuses
    for tier, bonus in pairs(CONFIG.tierBonusMultipliers) do
        if rebirthCount >= tier then
            multiplier = multiplier + bonus
        end
    end
    
    return multiplier
end

-- Check if player can rebirth
function RebirthSystem:canPlayerRebirth(player)
    if not player then return false, "Invalid player" end
    
    -- Check if player has Tycoon object
    local tycoon = player:FindFirstChild("Tycoon") 
    if not tycoon then
        return false, "No tycoon found"
    end
    
    -- Get current rebirth data
    local rebirthData = self:getPlayerRebirthData(player)
    
    -- Calculate cost for next rebirth
    local nextRebirthCost = self:calculateRebirthCost(rebirthData.rebirthCount)
    
    -- Check if player has enough cash
    local cash = 0
    
    -- Try to get from leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cashValue = leaderstats:FindFirstChild("Cash")
        if cashValue then
            cash = cashValue.Value
        end
    end
    
    -- Or try to get from tycoon
    if cash == 0 and tycoon:FindFirstChild("Cash") then
        cash = tycoon.Cash.Value
    end
    
    -- Check if at max rebirth level
    if rebirthData.rebirthCount >= CONFIG.maxRebirthLevel then
        return false, "Maximum rebirth level reached", nextRebirthCost, cash
    end
    
    if cash < nextRebirthCost then
        return false, "Not enough cash", nextRebirthCost, cash
    end
    
    return true, "Ready for rebirth", nextRebirthCost, cash
end

-- Unlock features for a rebirth level
function RebirthSystem:unlockFeaturesForLevel(player, level)
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return end
    
    -- Check for new features at this rebirth level
    local feature = CONFIG.unlockableFeatures[level]
    if feature then
        rebirthData.unlockedFeatures[level] = true
        
        -- Fire unlock event
        if EventBridge then
            if typeof(EventBridge.fireEvent) == "function" then
                EventBridge:fireEvent("RebirthFeatureUnlocked", player, feature)
            else
                local featureEvent = EventBridge:FindFirstChild("RebirthFeatureUnlocked") or Instance.new("RemoteEvent")
                featureEvent.Name = "RebirthFeatureUnlocked"
                featureEvent.Parent = EventBridge
                featureEvent:FireClient(player, feature)
            end
        end
        
        -- If feature has a model, place it in tycoon
        if feature.model and TycoonSystem then
            if typeof(TycoonSystem.addModelToTycoon) == "function" then
                TycoonSystem.addModelToTycoon(player, feature.model, feature.name)
            end
        end
        
        -- Notify player
        debugPrint("Unlocked feature for", player.Name, ":", feature.name)
        
        -- Apply the feature's bonuses
        if feature.revenueBonus and RevenueSystem then
            if typeof(RevenueSystem.addRevenueBonus) == "function" then
                RevenueSystem.addRevenueBonus(player, "rebirthFeature_" .. level, feature.revenueBonus)
            end
        end
        
        -- Apply specialization bonus if applicable
        if feature.specializationEffectiveness and SpecializationSystem then
            if typeof(SpecializationSystem.addSpecializationBonus) == "function" then
                SpecializationSystem.addSpecializationBonus(player, feature.specializationEffectiveness)
            end
        end
        
        -- Apply VIP bonuses if applicable
        if feature.vipChanceBonus and RevenueSystem then
            if typeof(RevenueSystem.addVIPChanceBonus) == "function" then
                RevenueSystem.addVIPChanceBonus(player, feature.vipChanceBonus)
            end
        end
        
        -- Save data since we've made changes
        self:savePlayerRebirthData(player)
    end
    
    -- Check for new perks at this level
    local perk = CONFIG.rebirthPerks[level]
    if perk then
        rebirthData.activePerks[level] = true
        
        -- Fire unlock event
        if EventBridge then
            if typeof(EventBridge.fireEvent) == "function" then
                EventBridge:fireEvent("RebirthPerkUnlocked", player, perk)
            else
                local perkEvent = EventBridge:FindFirstChild("RebirthPerkUnlocked") or Instance.new("RemoteEvent")
                perkEvent.Name = "RebirthPerkUnlocked"
                perkEvent.Parent = EventBridge
                perkEvent:FireClient(player, perk)
            end
        end
        
        -- Apply perk effects
        self:applyPerkEffects(player, perk, level)
        
        -- Save data since we've made changes
        self:savePlayerRebirthData(player)
    end
end

-- Apply perk effects to player
function RebirthSystem:applyPerkEffects(player, perk, perkLevel)
    if not player or not perk then return end
    
    -- Apply starting cash if applicable
    if perk.startingCash and perk.startingCash > 0 then
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Cash") then
            leaderstats.Cash.Value = leaderstats.Cash.Value + perk.startingCash
            debugPrint("Applied starting cash bonus of", perk.startingCash, "to", player.Name)
        end
    end
    
    -- Apply equipment bonus if applicable
    if perk.equipmentBonus and perk.equipmentBonus > 0 then
        -- Implement through TycoonSystem or other systems
        if TycoonSystem and typeof(TycoonSystem.addEquipmentBonus) == "function" then
            TycoonSystem.addEquipmentBonus(player, "rebirthPerk_" .. perkLevel, perk.equipmentBonus)
        end
    end
    
    -- Apply staff effectiveness bonus if applicable
    if perk.staffEffectivenessBonus and perk.staffEffectivenessBonus > 0 then
        -- Apply staff bonus through appropriate system
        local StaffSystem = CoreRegistry and CoreRegistry.getSystem("StaffSystem")
        if StaffSystem and typeof(StaffSystem.addStaffBonus) == "function" then
            StaffSystem.addStaffBonus(player, perk.staffEffectivenessBonus)
        end
    end
    
    -- Implement other perk effects based on type
    -- This would connect to various systems in your game
    
    debugPrint("Applied perk effects for", player.Name, ":", perk.name)
end

-- Check and award achievements
function RebirthSystem:checkAchievements(player)
    if not player then return end
    
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return end
    
    for _, achievement in ipairs(CONFIG.rebirthAchievements) do
        -- Skip if already awarded
        if rebirthData.achievements[achievement.id] then continue end
        
        local awarded = false
        
        -- Check different requirement types
        if achievement.requirementType == "rebirthCount" and rebirthData.rebirthCount >= achievement.requirement then
            awarded = true
        elseif achievement.requirementType == "rebirthSpeed" and 
               rebirthData.lastRebirthTime > 0 and
               (os.time() - rebirthData.lastRebirthTime) <= achievement.requirement then
            awarded = true
        elseif achievement.requirementType == "featuresUnlocked" then
            local featureCount = 0
            for _, _ in pairs(rebirthData.unlockedFeatures) do
                featureCount = featureCount + 1
            end
            if featureCount >= achievement.requirement then
                awarded = true
            end
        end
        
        -- Award achievement if conditions met
        if awarded then
            rebirthData.achievements[achievement.id] = os.time()
            
            -- Award reward if applicable
            if achievement.reward and achievement.reward > 0 then
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats and leaderstats:FindFirstChild("Cash") then
                    leaderstats.Cash.Value = leaderstats.Cash.Value + achievement.reward
                end
            end
            
            -- Fire achievement event
            if EventBridge then
                if typeof(EventBridge.fireEvent) == "function" then
                    EventBridge:fireEvent("RebirthAchievementUnlocked", player, achievement)
                else
                    local achievementEvent = EventBridge:FindFirstChild("RebirthAchievementUnlocked") or Instance.new("RemoteEvent")
                    achievementEvent.Name = "RebirthAchievementUnlocked"
                    achievementEvent.Parent = EventBridge
                    achievementEvent:FireClient(player, achievement)
                end
            end
            
            debugPrint("Awarded achievement to", player.Name, ":", achievement.name)
            
            -- Save data since we've made changes
            self:savePlayerRebirthData(player)
        end
    end
end

-- Perform rebirth for a player
function RebirthSystem:performRebirth(player)
    if not player then return false, "Invalid player" end
    
    -- Check if player can rebirth
    local canRebirth, reason, rebirthCost, playerCash = self:canPlayerRebirth(player)
    
    if not canRebirth then
        debugPrint("Rebirth failed for", player.Name, ":", reason)
        return false, reason, rebirthCost, playerCash
    end
    
    -- Get rebirth data
    local rebirthData = self:getPlayerRebirthData(player)
    
    -- Check for achievements before rebirth
    self:checkAchievements(player)
    
    -- Deduct cost and reset progression
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Cash") then
        leaderstats.Cash.Value = 0
    end
    
    -- Get tycoon object
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        -- Reset tycoon values
        local tycoonModel = tycoon.Value
        if tycoonModel then
            -- Reset equipment (should be handled by the TycoonSystem if available)
            if TycoonSystem and typeof(TycoonSystem.resetTycoon) == "function" then
                TycoonSystem.resetTycoon(player)
            else
                -- Basic reset as fallback
                -- This should be customized for your specific equipment system
                for _, item in pairs(tycoonModel:GetChildren()) do
                    if item:IsA("Model") and item:GetAttribute("EquipmentType") then
                        item:Destroy()
                    end
                end
            end
        end
        
        -- Reset tycoon attributes
        tycoon:SetAttribute("GymLevel", 0)
    end
    
    -- Update rebirth data
    rebirthData.rebirthCount = rebirthData.rebirthCount + 1
    rebirthData.totalRebirthsCompleted = rebirthData.totalRebirthsCompleted + 1
    
    -- Calculate rebirth time
    local currentTime = os.time()
    local rebirthTime = currentTime - (rebirthData.currentRebirthStartTime or currentTime)
    rebirthData.lastRebirthTime = currentTime
    
    -- Check for fastest rebirth
    if rebirthTime < rebirthData.fastestRebirthTime then
        rebirthData.fastestRebirthTime = rebirthTime
    end
    
    -- Reset for new rebirth
    rebirthData.currentRebirthStartTime = currentTime
    
    -- Apply new revenue multiplier
    local newMultiplier = self:calculateRebirthMultiplier(rebirthData.rebirthCount)
    
    if tycoon then
        -- Set the multiplier value
        if tycoon:FindFirstChild("MembershipFeeMultiplier") then
            tycoon.MembershipFeeMultiplier.Value = newMultiplier
        else
            local multiplierValue = Instance.new("NumberValue")
            multiplierValue.Name = "MembershipFeeMultiplier"
            multiplierValue.Value = newMultiplier
            multiplierValue.Parent = tycoon
        end
        
        -- Also set as attribute for systems that may use it
        tycoon:SetAttribute("RebirthMultiplier", newMultiplier)
        tycoon:SetAttribute("RebirthCount", rebirthData.rebirthCount)
    end
    
    -- Apply RevenueSystem bonus if available
    if RevenueSystem and typeof(RevenueSystem.setRebirthMultiplier) == "function" then
        RevenueSystem.setRebirthMultiplier(player, newMultiplier)
    end
    
    -- Unlock any new features for the new rebirth level
    self:unlockFeaturesForLevel(player, rebirthData.rebirthCount)
    
    -- Re-apply all active perks after reset
    for level, active in pairs(rebirthData.activePerks) do
        if active then
            local perk = CONFIG.rebirthPerks[level]
            if perk then
                self:applyPerkEffects(player, perk, level)
            end
        end
    end
    
    -- Check for new achievements after rebirth
    self:checkAchievements(player)
    
    -- Save updated rebirth data
    self:savePlayerRebirthData(player)
    
    -- Show rebirth effects
    self:showRebirthEffects(player)
    
    -- Fire rebirth event for other systems
    if EventBridge then
        local rebirthEvent = EventBridge:FindFirstChild("PlayerRebirthed")
        if rebirthEvent then
            rebirthEvent:FireClient(player, {
                rebirthCount = rebirthData.rebirthCount,
                multiplier = newMultiplier
            })
        elseif typeof(EventBridge.fireEvent) == "function" then
            EventBridge:fireEvent("PlayerRebirthed", player, {
                rebirthCount = rebirthData.rebirthCount,
                multiplier = newMultiplier
            })
        end
    end
    
    debugPrint("Rebirth successful for", player.Name, "- New level:", rebirthData.rebirthCount)
    
    return true, "Rebirth successful", rebirthData.rebirthCount, newMultiplier
end

-- Show visual effects for rebirth
function RebirthSystem:showRebirthEffects(player)
    if not player then return end
    
    -- Create effects on client via remote event
    if EventBridge then
        local effectsEvent = EventBridge:FindFirstChild("RebirthEffects")
        
        if not effectsEvent then
            effectsEvent = Instance.new("RemoteEvent")
            effectsEvent.Name = "RebirthEffects"
            effectsEvent.Parent = EventBridge
        end
        
        effectsEvent:FireClient(player, CONFIG.visualEffects)
    end
    
    -- We could add some server-side effects visible to other players here
    local character = player.Character
    if character then
        -- Create a temporary particle effect
        local attachment = Instance.new("Attachment")
        attachment.Parent = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        
        local particleEmitter = Instance.new("ParticleEmitter")
        particleEmitter.Texture = CONFIG.visualEffects.particleImage
        particleEmitter.Color = ColorSequence.new(CONFIG.visualEffects.particleColor)
        particleEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1.5),
            NumberSequenceKeypoint.new(1, 0)
        })
        particleEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        particleEmitter.Speed = NumberRange.new(5, 10)
        particleEmitter.Acceleration = Vector3.new(0, 5, 0)
        particleEmitter.Lifetime = NumberRange.new(1, 2)
        particleEmitter.Rate = 50
        particleEmitter.SpreadAngle = Vector2.new(0, 180)
        particleEmitter.Parent = attachment
        
        -- Play effect for a few seconds then clean up
        task.delay(CONFIG.visualEffects.transformDuration, function()
            particleEmitter.Enabled = false
            -- Wait for particles to finish before removing
            task.delay(3, function()
                if attachment and attachment.Parent then
                    attachment:Destroy()
                end
            end)
        end)
        
        -- Play sound effect
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.visualEffects.soundEffect
        sound.Volume = 0.8
        sound.RollOffMode = Enum.RollOffMode.LinearSquare
        sound.RollOffMaxDistance = 100
        sound.Parent = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        sound:Play()
        
        -- Clean up sound
        task.delay(5, function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
    end
end

-- Get unlocked features for player
function RebirthSystem:getUnlockedFeatures(player)
    if not player then return {} end
    
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return {} end
    
    -- Create list of unlocked features
    local unlockedFeatures = {}
    for level, isUnlocked in pairs(rebirthData.unlockedFeatures) do
        if isUnlocked and CONFIG.unlockableFeatures[level] then
            table.insert(unlockedFeatures, {
                level = level,
                info = CONFIG.unlockableFeatures[level]
            })
        end
    end
    
    -- Sort by level
    table.sort(unlockedFeatures, function(a, b)
        return a.level < b.level
    end)
    
    return unlockedFeatures
end

-- Get active perks for player
function RebirthSystem:getActivePerks(player)
    if not player then return {} end
    
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return {} end
    
    -- Create list of active perks
    local activePerks = {}
    for level, isActive in pairs(rebirthData.activePerks) do
        if isActive and CONFIG.rebirthPerks[level] then
            table.insert(activePerks, {
                level = level,
                info = CONFIG.rebirthPerks[level]
            })
        end
    end
    
    -- Sort by level
    table.sort(activePerks, function(a, b)
        return a.level < b.level
    end)
    
    return activePerks
end

-- Get rebirth achievements for player
function RebirthSystem:getAchievements(player)
    if not player then return {} end
    
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return {} end
    
    -- Create list of earned achievements
    local achievements = {}
    for _, achievementInfo in ipairs(CONFIG.rebirthAchievements) do
        local earned = rebirthData.achievements[achievementInfo.id] ~= nil
        table.insert(achievements, {
            id = achievementInfo.id,
            info = achievementInfo,
            earned = earned,
            earnedTimestamp = rebirthData.achievements[achievementInfo.id] or 0
        })
    end
    
    return achievements
end

-- Get rebirth requirement progress for a player
function RebirthSystem:getRebirthProgress(player)
    if not player then return 0, 0, 0 end
    
    local _, _, rebirthCost, playerCash = self:canPlayerRebirth(player)
    
    local progress = playerCash / rebirthCost
    if progress > 1 then progress = 1 end
    
    return progress, playerCash, rebirthCost
end

-- Get rebirth info for a player
function RebirthSystem:getRebirthInfo(player)
    if not player then return nil end
    
    local rebirthData = self:getPlayerRebirthData(player)
    if not rebirthData then return nil end
    
    -- Calculate rebirth cost and multiplier
    local rebirthCost = self:calculateRebirthCost(rebirthData.rebirthCount)
    local multiplier = self:calculateRebirthMultiplier(rebirthData.rebirthCount)
    
    -- Get progress toward next rebirth
    local progress, playerCash, _ = self:getRebirthProgress(player)
    
    -- Get unlockable features for next level
    local nextLevel = rebirthData.rebirthCount + 1
    local nextFeature = CONFIG.unlockableFeatures[nextLevel]
    local nextPerk = CONFIG.rebirthPerks[nextLevel]
    
    -- Return info
    return {
        rebirthCount = rebirthData.rebirthCount,
        cost = rebirthCost,
        multiplier = multiplier,
        progress = progress,
        cash = playerCash,
        unlockedFeatures = self:getUnlockedFeatures(player),
        activePerks = self:getActivePerks(player),
        achievements = self:getAchievements(player),
        nextFeature = nextFeature,
        nextPerk = nextPerk,
        nextLevel = nextLevel,
        totalRebirths = rebirthData.totalRebirthsCompleted,
        fastestTime = rebirthData.fastestRebirthTime,
        timeInCurrentRebirth = os.time() - (rebirthData.currentRebirthStartTime or os.time())
    }
end

-- Initialize a player
function RebirthSystem:initializePlayer(player)
    if not player then return end
    
    debugPrint("Initializing rebirth system for", player.Name)
    
    -- Get or initialize rebirth data
    local rebirthData = self:getPlayerRebirthData(player)
    
    -- Set up tycoon values
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then
        tycoon = Instance.new("Folder")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
    end
    
    -- Set multiplier value
    local multiplier = self:calculateRebirthMultiplier(rebirthData.rebirthCount)
    
    if not tycoon:FindFirstChild("MembershipFeeMultiplier") then
        local multiplierValue = Instance.new("NumberValue")
        multiplierValue.Name = "MembershipFeeMultiplier"
        multiplierValue.Value = multiplier
        multiplierValue.Parent = tycoon
    else
        tycoon.MembershipFeeMultiplier.Value = multiplier
    end
    
    -- Set attributes for easy access
    tycoon:SetAttribute("RebirthMultiplier", multiplier)
    tycoon:SetAttribute("RebirthCount", rebirthData.rebirthCount)
    
    -- Re-apply unlocked features and perks
    for level, isUnlocked in pairs(rebirthData.unlockedFeatures) do
        if isUnlocked and level <= rebirthData.rebirthCount then
            local feature = CONFIG.unlockableFeatures[level]
            if feature then
                -- Apply the feature's bonuses
                if feature.revenueBonus and RevenueSystem then
                    if typeof(RevenueSystem.addRevenueBonus) == "function" then
                        RevenueSystem.addRevenueBonus(player, "rebirthFeature_" .. level, feature.revenueBonus)
                    end
                end
                
                -- Apply specialization bonus if applicable
                if feature.specializationEffectiveness and SpecializationSystem then
                    if typeof(SpecializationSystem.addSpecializationBonus) == "function" then
                        SpecializationSystem.addSpecializationBonus(player, feature.specializationEffectiveness)
                    end
                end
            end
        end
    end
    
    -- Re-apply active perks
    for level, isActive in pairs(rebirthData.activePerks) do
        if isActive then
            local perk = CONFIG.rebirthPerks[level]
            if perk then
                self:applyPerkEffects(player, perk, level)
            end
        end
    end
    
    -- Connect to events
    task.spawn(function()
        -- Give some time for things to load
        task.wait(2)
        
        -- Apply RevenueSystem bonus if available
        if RevenueSystem and typeof(RevenueSystem.setRebirthMultiplier) == "function" then
            RevenueSystem.setRebirthMultiplier(player, multiplier)
        end
    end)
    
    debugPrint("Rebirth system initialized for", player.Name, "with rebirth level", rebirthData.rebirthCount)
    
    -- Return rebirth level
    return rebirthData.rebirthCount
end

-- Set up remote functions
function RebirthSystem:setupRemotes()
    -- Create rebirth remote
    local rebirthRemote = ReplicatedStorage:FindFirstChild("RebirthRemote")
    if not rebirthRemote then
        rebirthRemote = Instance.new("RemoteEvent")
        rebirthRemote.Name = "RebirthRemote"
        rebirthRemote.Parent = ReplicatedStorage
    end
    
    -- Handle rebirth requests
    rebirthRemote.OnServerEvent:Connect(function(player, messageType)
        if messageType == "GetInfo" then
            -- Send player rebirth info
            local infoData = self:getRebirthInfo(player)
            rebirthRemote:FireClient(player, "RebirthInfo", infoData)
        else
            -- Handle rebirth request
            local success, message, rebirthLevel, newMultiplier = self:performRebirth(player)
            
            if success then
                rebirthRemote:FireClient(player, "RebirthSuccess", {
                    rebirthCount = rebirthLevel,
                    newMultiplier = newMultiplier
                })
            else
                -- Check if it's a cash issue
                if message:find("enough cash") then
                    rebirthRemote:FireClient(player, "NotEnoughCash", {
                        required = rebirthLevel, -- This is rebirthCost in this context
                        current = newMultiplier  -- This is playerCash in this context
                    })
                else
                    -- Some other issue
                    rebirthRemote:FireClient(player, "RebirthFailed", {
                        reason = message
                    })
                end
            end
        end
    end)
    
    debugPrint("Rebirth remotes set up")
end

-- Initialize the system
function RebirthSystem:initialize()
    debugPrint("Initializing RebirthSystem")
    
    -- Set up remote functions
    self:setupRemotes()
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            task.wait(3) -- Give time for other systems to initialize
            self:initializePlayer(player)
        end)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:initializePlayer(player)
        end)
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("RebirthSystem", self)
        debugPrint("Registered RebirthSystem with CoreRegistry")
    end
    
    -- Create RemoteFunction for direct data access
    local rebirthInfoFunction = ReplicatedStorage:FindFirstChild("GetRebirthInfoFunction")
    if not rebirthInfoFunction then
        rebirthInfoFunction = Instance.new("RemoteFunction")
        rebirthInfoFunction.Name = "GetRebirthInfoFunction"
        rebirthInfoFunction.Parent = ReplicatedStorage
    end
    
    -- Set handler
    rebirthInfoFunction.OnServerInvoke = function(player)
        return self:getRebirthInfo(player)
    end
    
    debugPrint("RebirthSystem initialized")
    return true
end

-- Initialize the system
RebirthSystem:initialize()

-- Return the module
return RebirthSystem
