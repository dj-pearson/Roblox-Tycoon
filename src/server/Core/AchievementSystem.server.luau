-- AchievementSystem.luau
-- Comprehensive achievement system for gameplay milestones
-- Builds upon MilestoneSystem with more advanced features
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge
local DataManager
local TycoonSystem
local MilestoneSystem
local NPCSystem
local BasketballSystem
local SaunaSystem
local MemberSatisfactionSystem
local RevenueSystem

-- Configuration
local CONFIG = {
    debugEnabled = true,           -- Enable debug logging
    badgesEnabled = true,          -- Whether to award Roblox badges
    notificationsEnabled = true,   -- Whether to show notifications
    achievementSoundId = "rbxassetid://9125601193",  -- Sound effect for unlocking achievements
    
    -- Badge IDs (to be replaced with actual badge IDs)
    badges = {
        -- Business achievements
        tycoon_master = 0,              -- Own a top-tier gym
        millionaire = 0,                -- Earn 1,000,000 cash
        
        -- Basketball achievements
        basketball_pro = 0,             -- Score 100 points in basketball
        basketball_champion = 0,        -- Win 50 basketball games
        
        -- Membership achievements
        popular_gym = 0,                -- Have 100 members simultaneously
        membership_guru = 0,            -- Reach maximum membership tier
        
        -- Staff achievements
        full_staff = 0,                 -- Hire every type of staff
        
        -- Specialization achievements
        specialization_master = 0,      -- Max out a specialization
        all_specializations = 0,        -- Try every specialization
    },
    
    -- Achievement categories
    categories = {
        business = {
            name = "Business Achievements",
            color = Color3.fromRGB(50, 200, 100), -- Green
            icon = "rbxassetid://6035078892" -- Money icon
        },
        fitness = {
            name = "Fitness Achievements",
            color = Color3.fromRGB(50, 120, 200), -- Blue
            icon = "rbxassetid://6035047391" -- Dumbbell icon
        },
        membership = {
            name = "Membership Achievements",
            color = Color3.fromRGB(200, 120, 50), -- Orange
            icon = "rbxassetid://6026657478" -- Person icon
        },
        staff = {
            name = "Staff Achievements",
            color = Color3.fromRGB(200, 50, 50), -- Red
            icon = "rbxassetid://6034287516" -- Person with clipboard icon
        },
        facilities = {
            name = "Facilities Achievements",
            color = Color3.fromRGB(100, 200, 200), -- Teal
            icon = "rbxassetid://6034509225" -- Building icon
        },
        specialization = {
            name = "Specialization Achievements",
            color = Color3.fromRGB(150, 50, 200), -- Purple
            icon = "rbxassetid://6031225816" -- Star icon
        }
    },
    
    -- Achievement definitions by category
    achievements = {
        -- Business achievements
        business = {
            first_day = {
                id = "business_first_day",
                name = "First Day Open",
                description = "Complete your first day as a gym owner",
                difficulty = 1,
                rewardCash = 500,
                icon = "rbxassetid://6035078892",
                progressMax = 1
            },
            steady_income = {
                id = "business_steady_income",
                name = "Steady Income",
                description = "Collect revenue 10 times",
                difficulty = 2,
                rewardCash = 1000,
                icon = "rbxassetid://6035078892",
                progressMax = 10
            },
            business_tycoon = {
                id = "business_tycoon",
                name = "Business Tycoon",
                description = "Earn 1,000,000 in total revenue",
                difficulty = 4,
                rewardCash = 25000,
                icon = "rbxassetid://6035078892",
                progressMax = 1000000,
                badgeId = "millionaire"
            }
        },
        
        -- Fitness achievements
        fitness = {
            basketball_beginner = {
                id = "fitness_basketball_beginner",
                name = "Basketball Beginner",
                description = "Score your first basket",
                difficulty = 1,
                rewardCash = 500,
                icon = "rbxassetid://6031263289", -- Basketball icon
                progressMax = 1
            },
            basketball_amateur = {
                id = "fitness_basketball_amateur",
                name = "Basketball Amateur",
                description = "Score 50 total points in basketball",
                difficulty = 2,
                rewardCash = 1500,
                icon = "rbxassetid://6031263289",
                progressMax = 50
            },
            basketball_pro = {
                id = "fitness_basketball_pro",
                name = "Basketball Pro",
                description = "Score 200 total points in basketball",
                difficulty = 3,
                rewardCash = 5000,
                icon = "rbxassetid://6031263289",
                progressMax = 200,
                badgeId = "basketball_pro"
            },
            sauna_master = {
                id = "fitness_sauna_master",
                name = "Sauna Master",
                description = "Maintain perfect sauna temperature for 10 minutes total",
                difficulty = 3,
                rewardCash = 3000,
                icon = "rbxassetid://6035095184", -- Steam icon
                progressMax = 600 -- 10 minutes in seconds
            }
        },
        
        -- Membership achievements
        membership = {
            first_member = {
                id = "membership_first_member",
                name = "First Member",
                description = "Get your first gym member",
                difficulty = 1,
                rewardCash = 200,
                icon = "rbxassetid://6026657478",
                progressMax = 1
            },
            growing_community = {
                id = "membership_growing_community",
                name = "Growing Community",
                description = "Have 25 gym members simultaneously",
                difficulty = 2,
                rewardCash = 1000,
                icon = "rbxassetid://6026657478",
                progressMax = 25
            },
            popular_gym = {
                id = "membership_popular_gym",
                name = "Popular Gym",
                description = "Have 100 gym members simultaneously",
                difficulty = 3,
                rewardCash = 5000,
                icon = "rbxassetid://6026657478",
                progressMax = 100,
                badgeId = "popular_gym"
            },
            gym_empire = {
                id = "membership_gym_empire",
                name = "Gym Empire",
                description = "Have 500 gym members simultaneously",
                difficulty = 5,
                rewardCash = 20000,
                icon = "rbxassetid://6026657478",
                progressMax = 500
            }
        },
        
        -- Staff achievements
        staff = {
            first_hire = {
                id = "staff_first_hire",
                name = "First Hire",
                description = "Hire your first staff member",
                difficulty = 1,
                rewardCash = 500,
                icon = "rbxassetid://6034287516",
                progressMax = 1
            },
            growing_team = {
                id = "staff_growing_team",
                name = "Growing Team",
                description = "Hire 5 staff members",
                difficulty = 2,
                rewardCash = 1500,
                icon = "rbxassetid://6034287516",
                progressMax = 5
            },
            full_staff = {
                id = "staff_full_staff",
                name = "Full Staff",
                description = "Hire at least one of each staff type",
                difficulty = 3,
                rewardCash = 5000,
                icon = "rbxassetid://6034287516",
                progressMax = 4, -- Assuming 4 different staff types
                badgeId = "full_staff"
            }
        },
        
        -- Facilities achievements
        facilities = {
            first_equipment = {
                id = "facilities_first_equipment",
                name = "First Equipment",
                description = "Purchase your first piece of gym equipment",
                difficulty = 1,
                rewardCash = 100,
                icon = "rbxassetid://6035047391",
                progressMax = 1
            },
            equipment_variety = {
                id = "facilities_equipment_variety",
                name = "Equipment Variety",
                description = "Own at least 5 different types of equipment",
                difficulty = 2,
                rewardCash = 2000,
                icon = "rbxassetid://6035047391",
                progressMax = 5
            },
            gym_expansion = {
                id = "facilities_gym_expansion",
                name = "Gym Expansion",
                description = "Purchase 25 pieces of equipment",
                difficulty = 3,
                rewardCash = 5000,
                icon = "rbxassetid://6034509225",
                progressMax = 25
            },
            luxury_gym = {
                id = "facilities_luxury_gym",
                name = "Luxury Gym",
                description = "Reach 95% or higher member satisfaction",
                difficulty = 4,
                rewardCash = 10000,
                icon = "rbxassetid://6031094670", -- Star icon
                progressMax = 95
            }
        },
        
        -- Specialization achievements
        specialization = {
            first_specialization = {
                id = "specialization_first_choice",
                name = "First Specialization",
                description = "Choose your first gym specialization",
                difficulty = 1,
                rewardCash = 1000,
                icon = "rbxassetid://6031225816",
                progressMax = 1
            },
            specialization_master = {
                id = "specialization_master",
                name = "Specialization Master",
                description = "Reach maximum level with any specialization",
                difficulty = 4,
                rewardCash = 15000,
                icon = "rbxassetid://6031225816",
                progressMax = 10, -- Assuming max level is 10
                badgeId = "specialization_master"
            },
            specialization_explorer = {
                id = "specialization_explorer",
                name = "Specialization Explorer",
                description = "Try out all available specializations",
                difficulty = 3,
                rewardCash = 10000,
                icon = "rbxassetid://6031225816",
                progressMax = 4, -- Assuming 4 specializations
                badgeId = "all_specializations"
            }
        }
    },
    
    -- Sequential achievement chains
    achievementChains = {
        basketball_chain = {
            "fitness_basketball_beginner",
            "fitness_basketball_amateur",
            "fitness_basketball_pro"
        },
        membership_chain = {
            "membership_first_member",
            "membership_growing_community",
            "membership_popular_gym",
            "membership_gym_empire"
        },
        staff_chain = {
            "staff_first_hire",
            "staff_growing_team",
            "staff_full_staff"
        },
        equipment_chain = {
            "facilities_first_equipment",
            "facilities_equipment_variety",
            "facilities_gym_expansion"
        },
        specialization_chain = {
            "specialization_first_choice",
            "specialization_master",
            "specialization_explorer"
        }
    }
}

-- Create the AchievementSystem
local AchievementSystem = {
    -- Internal state
    _name = "AchievementSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager", "TycoonSystem", 
                     "MilestoneSystem", "NPCSystem", "BasketballSystem", 
                     "SaunaSystem", "MemberSatisfactionSystem", "RevenueSystem"},
    _playerData = {},
    _achievementDefinitions = {},
    _achievementCategoryCounts = {},
    _achievementProgress = {}
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[AchievementSystem]", ...)
    end
end

--[[ Core Functions ]]--

-- Initialize the module
function AchievementSystem:initialize()
    log("Initializing AchievementSystem v" .. self._version)
    
    -- Get dependencies
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    TycoonSystem = CoreRegistry:getSystem("TycoonSystem")
    MilestoneSystem = CoreRegistry:getSystem("MilestoneSystem")
    NPCSystem = CoreRegistry:getSystem("NPCSystem")
    BasketballSystem = CoreRegistry:tryGetSystem("BasketballSystem")
    SaunaSystem = CoreRegistry:tryGetSystem("SaunaSystem")
    MemberSatisfactionSystem = CoreRegistry:tryGetSystem("MemberSatisfactionSystem")
    RevenueSystem = CoreRegistry:getSystem("RevenueSystem")
    
    -- Register event handlers
    self:registerEvents()
    
    -- Build achievement definitions
    self:initializeAchievements()
    
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
    
    -- Register for legacy milestone events from MilestoneSystem
    self:connectToMilestoneSystem()
    
    log("AchievementSystem initialized")
    return true
end

-- Register for various events
function AchievementSystem:registerEvents()
    if not EventBridge then
        log("EventBridge not found, could not register for events")
        return
    end
    
    -- Basketball events
    EventBridge:connectEvent("BasketballScored", function(player, points)
        self:onBasketballScored(player, points)
    end)
    
    EventBridge:connectEvent("BasketballGameCompleted", function(player, score)
        self:onBasketballGameCompleted(player, score)
    end)
    
    -- Membership events
    EventBridge:connectEvent("MembersAdded", function(player, count)
        self:onMembersAdded(player, count)
    end)
    
    EventBridge:connectEvent("MembershipTierUp", function(player, newTier)
        self:onMembershipTierUp(player, newTier)
    end)
    
    -- Revenue events
    EventBridge:connectEvent("DuesCollected", function(player, amount)
        self:onRevenueCollected(player, amount)
    end)
    
    -- Staff events
    EventBridge:connectEvent("StaffHired", function(player, staffType, count)
        self:onStaffHired(player, staffType, count)
    end)
    
    -- Sauna events
    EventBridge:connectEvent("SaunaPerfectTemperature", function(player, duration)
        self:onSaunaPerfectTemperature(player, duration)
    end)
    
    -- Equipment events
    EventBridge:connectEvent("TilePurchased", function(player, tileInfo)
        self:onTilePurchased(player, tileInfo)
    end)
    
    -- Specialization events
    EventBridge:connectEvent("SpecializationChanged", function(player, specialization)
        self:onSpecializationChanged(player, specialization)
    end)
    
    EventBridge:connectEvent("SpecializationLevelUp", function(player, specialization, newLevel)
        self:onSpecializationLevelUp(player, specialization, newLevel)
    end)
    
    -- Member satisfaction events
    EventBridge:connectEvent("SatisfactionThresholdReached", function(player, satisfaction)
        self:onSatisfactionThresholdReached(player, satisfaction)
    end)
    
    -- Custom achievement events
    EventBridge:registerEvent("AchievementUnlocked")
    EventBridge:registerEvent("AchievementProgressUpdated")

    log("Registered for events")
end

-- Connect to legacy MilestoneSystem
function AchievementSystem:connectToMilestoneSystem()
    if not MilestoneSystem then
        log("MilestoneSystem not found, could not connect")
        return
    end
    
    -- Listen for milestone events and map them to achievements
    EventBridge:connectEvent("MilestoneAchieved", function(player, milestoneId, milestoneData)
        -- Map milestone IDs to achievements
        local milestoneToAchievementMap = {
            ["equipment_1"] = "facilities_first_equipment",
            ["equipment_25"] = "facilities_gym_expansion",
            ["npc_1"] = "membership_first_member",
            ["npc_25"] = "membership_growing_community",
            ["npc_100"] = "membership_popular_gym",
            ["revenue_1000000"] = "business_tycoon",
            ["special_first_specialization"] = "specialization_first_choice",
            ["special_max_specialization"] = "specialization_master"
        }
        
        local achievementId = milestoneToAchievementMap[milestoneId]
        if achievementId then
            self:awardAchievement(player, achievementId)
        end
    end)
    
    log("Connected to MilestoneSystem")
end

-- Initialize achievement definitions
function AchievementSystem:initializeAchievements()
    -- Count achievements per category
    for category, achievements in pairs(CONFIG.achievements) do
        self._achievementCategoryCounts[category] = 0
        for _ in pairs(achievements) do
            self._achievementCategoryCounts[category] = self._achievementCategoryCounts[category] + 1
        end
    end
    
    -- Store achievement definitions
    self._achievementDefinitions = CONFIG.achievements
    
    log("Initialized achievement definitions")
end

-- Set up tracking for a player
function AchievementSystem:setupPlayer(player)
    if not player then return end
    
    task.wait(3) -- Wait for other systems to initialize player data
    
    -- Initialize player data
    self._playerData[player.UserId] = self._playerData[player.UserId] or {
        unlockedAchievements = {},
        achievementProgress = {}
    }
    
    -- Load existing achievement data from DataManager if available
    if DataManager and DataManager.getPlayerData then
        local data = DataManager:getPlayerData(player)
        if data and data.achievements then
            -- Merge with existing data
            for id, completed in pairs(data.achievements.unlocked or {}) do
                if completed then
                    self._playerData[player.UserId].unlockedAchievements[id] = true
                end
            end
            
            -- Load progress
            for id, progress in pairs(data.achievements.progress or {}) do
                self._playerData[player.UserId].achievementProgress[id] = progress
            end
        end
    end
    
    log("Set up player tracking for " .. player.Name)
    
    -- Check all achievements in case some are already met
    self:checkAllAchievements(player)
    
    -- Send initial achievement data to client
    self:sendAchievementDataToClient(player)
end

-- Clean up when a player leaves
function AchievementSystem:cleanupPlayer(player)
    if not player then return end
    
    -- Save achievement data if needed
    if DataManager and DataManager.updatePlayerData then
        local data = self._playerData[player.UserId]
        if data then
            task.spawn(function()
                DataManager:updatePlayerData(player, "achievements", {
                    unlocked = data.unlockedAchievements,
                    progress = data.achievementProgress
                })
            end)
        end
    end
    
    -- Remove player data
    self._playerData[player.UserId] = nil
    
    log("Cleaned up player tracking for " .. player.Name)
end

-- Get achievement progress for a player
function AchievementSystem:getAchievementProgress(player, achievementId)
    if not player or not achievementId then return 0 end
    
    local userId = player.UserId
    if not self._playerData[userId] then
        self:setupPlayer(player)
    end
    
    return self._playerData[userId].achievementProgress[achievementId] or 0
end

-- Update achievement progress for a player
function AchievementSystem:updateAchievementProgress(player, achievementId, progress)
    if not player or not achievementId then return false end
    
    -- Find the achievement definition
    local achievementDef = self:findAchievementById(achievementId)
    if not achievementDef then
        log("Achievement not found: " .. achievementId)
        return false
    end
    
    local userId = player.UserId
    if not self._playerData[userId] then
        self:setupPlayer(player)
    end
    
    -- Update progress
    self._playerData[userId].achievementProgress[achievementId] = progress
    
    -- Check if achievement should be awarded
    if progress >= achievementDef.progressMax and not self._playerData[userId].unlockedAchievements[achievementId] then
        self:awardAchievement(player, achievementId)
    else
        -- Notify client of progress update
        if EventBridge then
            EventBridge:fireClientEvent("AchievementProgressUpdated", player, achievementId, progress, achievementDef.progressMax)
        end
    end
    
    return true
end

-- Award an achievement to a player
function AchievementSystem:awardAchievement(player, achievementId)
    if not player or not achievementId then return false end
    
    -- Find the achievement definition
    local achievementDef = self:findAchievementById(achievementId)
    if not achievementDef then
        log("Achievement not found: " .. achievementId)
        return false
    end
    
    local userId = player.UserId
    if not self._playerData[userId] then
        self:setupPlayer(player)
    end
    
    -- Check if already awarded
    if self._playerData[userId].unlockedAchievements[achievementId] then
        return false
    end
    
    -- Award achievement
    self._playerData[userId].unlockedAchievements[achievementId] = true
    
    log(player.Name .. " earned achievement: " .. achievementDef.name)
    
    -- Award cash reward
    if achievementDef.rewardCash and achievementDef.rewardCash > 0 then
        -- Give cash to player
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local cash = leaderstats:FindFirstChild("Cash")
            if cash then
                cash.Value = cash.Value + achievementDef.rewardCash
            end
        end
    end
    
    -- Award badge if applicable
    if CONFIG.badgesEnabled and achievementDef.badgeId and CONFIG.badges[achievementDef.badgeId] and CONFIG.badges[achievementDef.badgeId] > 0 then
        task.spawn(function()
            pcall(function()
                BadgeService:AwardBadge(player.UserId, CONFIG.badges[achievementDef.badgeId])
            end)
        end)
    end
    
    -- Play achievement sound
    if player.Character then
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.achievementSoundId
        sound.Volume = 1
        sound.Parent = player.Character
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end
    
    -- Send notification to player
    if CONFIG.notificationsEnabled then
        self:sendAchievementNotification(player, achievementDef)
    end
    
    -- Fire event
    if EventBridge then
        EventBridge:fireEvent("AchievementUnlocked", player, achievementId, achievementDef)
        EventBridge:fireClientEvent("AchievementUnlocked", player, achievementId, achievementDef)
    end
    
    -- Save data
    if DataManager and DataManager.updatePlayerData then
        task.delay(1, function()
            DataManager:updatePlayerData(player, "achievements.unlocked." .. achievementId, true)
        end)
    end
    
    -- Check achievement chain unlocks
    self:checkAchievementChain(player, achievementId)
    
    return true
end

-- Send achievement notification to player
function AchievementSystem:sendAchievementNotification(player, achievementInfo)
    if not player or not achievementInfo then return end
    
    -- Create notification data
    local notificationData = {
        title = "Achievement Unlocked!",
        message = achievementInfo.name .. "\n" .. achievementInfo.description,
        reward = achievementInfo.rewardCash > 0 and ("Reward: $" .. achievementInfo.rewardCash) or nil,
        icon = achievementInfo.icon,
        duration = 8, -- Show for 8 seconds
        category = "achievement",
        color = CONFIG.categories[achievementInfo.category] and CONFIG.categories[achievementInfo.category].color or Color3.fromRGB(200, 180, 30)
    }
    
    -- Send to client
    if EventBridge then
        EventBridge:fireClientEvent("ShowNotification", player, notificationData)
    end
end

-- Check all achievement chains for a player
function AchievementSystem:checkAchievementChain(player, achievementId)
    for chainName, chain in pairs(CONFIG.achievementChains) do
        -- Find position in chain
        local position = table.find(chain, achievementId)
        if position and position < #chain then
            -- Get next achievement in chain
            local nextAchievementId = chain[position + 1]
            if nextAchievementId then
                -- Start tracking progress for next achievement
                local nextAchievement = self:findAchievementById(nextAchievementId)
                if nextAchievement then
                    self:checkAchievement(player, nextAchievementId)
                end
            end
        end
    end
end

-- Find an achievement definition by ID
function AchievementSystem:findAchievementById(achievementId)
    for category, achievements in pairs(self._achievementDefinitions) do
        for id, achievement in pairs(achievements) do
            if achievement.id == achievementId then
                achievement.category = category
                return achievement
            end
        end
    end
    return nil
end

-- Check all achievements for a player
function AchievementSystem:checkAllAchievements(player)
    if not player then return end
    
    task.spawn(function()
        self:checkBusinessAchievements(player)
    end)
    
    task.spawn(function()
        self:checkFitnessAchievements(player)
    end)
    
    task.spawn(function()
        self:checkMembershipAchievements(player)
    end)
    
    task.spawn(function()
        self:checkStaffAchievements(player)
    end)
    
    task.spawn(function()
        self:checkFacilitiesAchievements(player)
    end)
    
    task.spawn(function()
        self:checkSpecializationAchievements(player)
    end)
    
    log("Checked all achievements for " .. player.Name)
end

-- Check a specific achievement for a player
function AchievementSystem:checkAchievement(player, achievementId)
    if not player or not achievementId then return false end
    
    local achievementDef = self:findAchievementById(achievementId)
    if not achievementDef then return false end
    
    local category = achievementDef.category
    
    if category == "business" then
        self:checkSpecificBusinessAchievement(player, achievementId)
    elseif category == "fitness" then
        self:checkSpecificFitnessAchievement(player, achievementId)
    elseif category == "membership" then
        self:checkSpecificMembershipAchievement(player, achievementId)
    elseif category == "staff" then
        self:checkSpecificStaffAchievement(player, achievementId)
    elseif category == "facilities" then
        self:checkSpecificFacilitiesAchievement(player, achievementId)
    elseif category == "specialization" then
        self:checkSpecificSpecializationAchievement(player, achievementId)
    end
    
    return true
end

--[[ Category-Specific Achievement Checks ]]--

-- Check business achievements
function AchievementSystem:checkBusinessAchievements(player)
    if not player then return end
    
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    -- First Day Open
    if tycoon:GetAttribute("TycoonStarted") then
        self:awardAchievement(player, "business_first_day")
    end
    
    -- Steady Income - handled in onRevenueCollected
    
    -- Business Tycoon
    local totalRevenue = tycoon:GetAttribute("TotalRevenue") or 0
    if totalRevenue >= 1000000 then
        self:awardAchievement(player, "business_tycoon")
    else
        self:updateAchievementProgress(player, "business_tycoon", totalRevenue)
    end
end

-- Check specific business achievement
function AchievementSystem:checkSpecificBusinessAchievement(player, achievementId)
    if achievementId == "business_first_day" then
        local tycoon = self:getPlayerTycoon(player)
        if tycoon and tycoon:GetAttribute("TycoonStarted") then
            self:awardAchievement(player, "business_first_day")
        end
    elseif achievementId == "business_steady_income" then
        -- Handled in onRevenueCollected
    elseif achievementId == "business_tycoon" then
        local tycoon = self:getPlayerTycoon(player)
        if tycoon then
            local totalRevenue = tycoon:GetAttribute("TotalRevenue") or 0
            self:updateAchievementProgress(player, "business_tycoon", totalRevenue)
        end
    end
end

-- Check fitness achievements
function AchievementSystem:checkFitnessAchievements(player)
    if not player then return end
    
    if BasketballSystem then
        local stats = BasketballSystem:getPlayerStats(player)
        if stats then
            -- Basketball Beginner
            if stats.basketsMade and stats.basketsMade > 0 then
                self:awardAchievement(player, "fitness_basketball_beginner")
            end
            
            -- Basketball Amateur
            if stats.totalPoints and stats.totalPoints >= 50 then
                self:awardAchievement(player, "fitness_basketball_amateur")
            else if stats.totalPoints then
                self:updateAchievementProgress(player, "fitness_basketball_amateur", stats.totalPoints)
            end
            end
            
            -- Basketball Pro
            if stats.totalPoints and stats.totalPoints >= 200 then
                self:awardAchievement(player, "fitness_basketball_pro")
            else if stats.totalPoints then
                self:updateAchievementProgress(player, "fitness_basketball_pro", stats.totalPoints)
            end
            end
        end
    end
    
    if SaunaSystem then
        local perfectTime = SaunaSystem:getPlayerPerfectTemperatureTime(player) or 0
        
        -- Sauna Master
        if perfectTime >= 600 then
            self:awardAchievement(player, "fitness_sauna_master")
        else
            self:updateAchievementProgress(player, "fitness_sauna_master", perfectTime)
        end
    end
end

-- Check specific fitness achievement
function AchievementSystem:checkSpecificFitnessAchievement(player, achievementId)
    if BasketballSystem and (achievementId == "fitness_basketball_beginner" 
                           or achievementId == "fitness_basketball_amateur"
                           or achievementId == "fitness_basketball_pro") then
        local stats = BasketballSystem:getPlayerStats(player)
        if stats then
            if achievementId == "fitness_basketball_beginner" and stats.basketsMade and stats.basketsMade > 0 then
                self:awardAchievement(player, "fitness_basketball_beginner")
            elseif achievementId == "fitness_basketball_amateur" and stats.totalPoints then
                self:updateAchievementProgress(player, "fitness_basketball_amateur", stats.totalPoints)
            elseif achievementId == "fitness_basketball_pro" and stats.totalPoints then
                self:updateAchievementProgress(player, "fitness_basketball_pro", stats.totalPoints)
            end
        end
    elseif SaunaSystem and achievementId == "fitness_sauna_master" then
        local perfectTime = SaunaSystem:getPlayerPerfectTemperatureTime(player) or 0
        self:updateAchievementProgress(player, "fitness_sauna_master", perfectTime)
    end
end

-- Check membership achievements
function AchievementSystem:checkMembershipAchievements(player)
    if not player then return end
    
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local memberCount = tycoon:GetAttribute("MembershipCount") or 0
    
    -- First Member
    if memberCount >= 1 then
        self:awardAchievement(player, "membership_first_member")
    end
    
    -- Growing Community
    if memberCount >= 25 then
        self:awardAchievement(player, "membership_growing_community")
    else
        self:updateAchievementProgress(player, "membership_growing_community", memberCount)
    end
    
    -- Popular Gym
    if memberCount >= 100 then
        self:awardAchievement(player, "membership_popular_gym")
    else
        self:updateAchievementProgress(player, "membership_popular_gym", memberCount)
    end
    
    -- Gym Empire
    if memberCount >= 500 then
        self:awardAchievement(player, "membership_gym_empire")
    else
        self:updateAchievementProgress(player, "membership_gym_empire", memberCount)
    end
    
    -- Check membership tier
    local membershipTier = tycoon:GetAttribute("MembershipTier") or 0
    if membershipTier >= 5 then -- Assuming 5 is max tier
        self:awardAchievement(player, "membership_tier_master")
    end
end

-- Check specific membership achievement
function AchievementSystem:checkSpecificMembershipAchievement(player, achievementId)
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local memberCount = tycoon:GetAttribute("MembershipCount") or 0
    
    if achievementId == "membership_first_member" and memberCount >= 1 then
        self:awardAchievement(player, "membership_first_member")
    elseif achievementId == "membership_growing_community" then
        self:updateAchievementProgress(player, "membership_growing_community", memberCount)
    elseif achievementId == "membership_popular_gym" then
        self:updateAchievementProgress(player, "membership_popular_gym", memberCount)
    elseif achievementId == "membership_gym_empire" then
        self:updateAchievementProgress(player, "membership_gym_empire", memberCount)
    elseif achievementId == "membership_tier_master" then
        local membershipTier = tycoon:GetAttribute("MembershipTier") or 0
        if membershipTier >= 5 then -- Assuming 5 is max tier
            self:awardAchievement(player, "membership_tier_master")
        end
    end
end

-- Check staff achievements
function AchievementSystem:checkStaffAchievements(player)
    if not player then return end
    
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    -- Count total staff and types
    local staffTypes = {"trainer", "janitor", "receptionist", "maintenance"}
    local totalStaff = 0
    local uniqueStaffTypes = 0
    
    for _, staffType in ipairs(staffTypes) do
        local count = tycoon:GetAttribute("Staff_" .. staffType) or 0
        totalStaff = totalStaff + count
        if count > 0 then
            uniqueStaffTypes = uniqueStaffTypes + 1
        end
    end
    
    -- First Hire
    if totalStaff >= 1 then
        self:awardAchievement(player, "staff_first_hire")
    end
    
    -- Growing Team
    if totalStaff >= 5 then
        self:awardAchievement(player, "staff_growing_team")
    else
        self:updateAchievementProgress(player, "staff_growing_team", totalStaff)
    end
    
    -- Full Staff
    if uniqueStaffTypes >= #staffTypes then
        self:awardAchievement(player, "staff_full_staff")
    else
        self:updateAchievementProgress(player, "staff_full_staff", uniqueStaffTypes)
    end
end

-- Check specific staff achievement
function AchievementSystem:checkSpecificStaffAchievement(player, achievementId)
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local staffTypes = {"trainer", "janitor", "receptionist", "maintenance"}
    local totalStaff = 0
    local uniqueStaffTypes = 0
    
    for _, staffType in ipairs(staffTypes) do
        local count = tycoon:GetAttribute("Staff_" .. staffType) or 0
        totalStaff = totalStaff + count
        if count > 0 then
            uniqueStaffTypes = uniqueStaffTypes + 1
        end
    end
    
    if achievementId == "staff_first_hire" and totalStaff >= 1 then
        self:awardAchievement(player, "staff_first_hire")
    elseif achievementId == "staff_growing_team" then
        self:updateAchievementProgress(player, "staff_growing_team", totalStaff)
    elseif achievementId == "staff_full_staff" then
        self:updateAchievementProgress(player, "staff_full_staff", uniqueStaffTypes)
    end
end

-- Check facilities achievements
function AchievementSystem:checkFacilitiesAchievements(player)
    if not player then return end
    
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
    
    -- First Equipment
    if equipmentCount >= 1 then
        self:awardAchievement(player, "facilities_first_equipment")
    end
    
    -- Equipment Variety
    -- Need to count unique equipment types
    local uniqueTypes = 0
    local BuyTileSystem = CoreRegistry:tryGetSystem("BuyTileSystem")
    
    if BuyTileSystem and BuyTileSystem.getPlayerEquipmentTypes then
        uniqueTypes = BuyTileSystem:getPlayerEquipmentTypes(player) or 0
        
        if uniqueTypes >= 5 then
            self:awardAchievement(player, "facilities_equipment_variety")
        else
            self:updateAchievementProgress(player, "facilities_equipment_variety", uniqueTypes)
        end
    end
    
    -- Gym Expansion
    if equipmentCount >= 25 then
        self:awardAchievement(player, "facilities_gym_expansion")
    else
        self:updateAchievementProgress(player, "facilities_gym_expansion", equipmentCount)
    end
    
    -- Luxury Gym
    if MemberSatisfactionSystem then
        local satisfaction = tycoon:GetAttribute("MemberSatisfaction") or 0
        if satisfaction >= 95 then
            self:awardAchievement(player, "facilities_luxury_gym")
        else
            self:updateAchievementProgress(player, "facilities_luxury_gym", satisfaction)
        end
    end
end

-- Check specific facilities achievement
function AchievementSystem:checkSpecificFacilitiesAchievement(player, achievementId)
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    if achievementId == "facilities_first_equipment" then
        local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
        if equipmentCount >= 1 then
            self:awardAchievement(player, "facilities_first_equipment")
        end
    elseif achievementId == "facilities_equipment_variety" then
        local BuyTileSystem = CoreRegistry:tryGetSystem("BuyTileSystem")
        if BuyTileSystem and BuyTileSystem.getPlayerEquipmentTypes then
            local uniqueTypes = BuyTileSystem:getPlayerEquipmentTypes(player) or 0
            self:updateAchievementProgress(player, "facilities_equipment_variety", uniqueTypes)
        end
    elseif achievementId == "facilities_gym_expansion" then
        local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
        self:updateAchievementProgress(player, "facilities_gym_expansion", equipmentCount)
    elseif achievementId == "facilities_luxury_gym" and MemberSatisfactionSystem then
        local satisfaction = tycoon:GetAttribute("MemberSatisfaction") or 0
        self:updateAchievementProgress(player, "facilities_luxury_gym", satisfaction)
    end
end

-- Check specialization achievements
function AchievementSystem:checkSpecializationAchievements(player)
    if not player then return end
    
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local SpecializationSystem = CoreRegistry:tryGetSystem("SpecializationSystem")
    if not SpecializationSystem then return end
    
    -- First Specialization
    local currentSpecialization = tycoon:GetAttribute("Specialization")
    if currentSpecialization and currentSpecialization ~= "None" then
        self:awardAchievement(player, "specialization_first_choice")
    end
    
    -- Specialization Master
    if SpecializationSystem.getPlayerMaxLevelSpecialization then
        local maxLevel = SpecializationSystem:getPlayerMaxLevelSpecialization(player)
        if maxLevel and maxLevel.level and maxLevel.level >= 10 then -- Assuming max level is 10
            self:awardAchievement(player, "specialization_master")
        end
    end
    
    -- Specialization Explorer
    if SpecializationSystem.getPlayerTriedSpecializations then
        local triedCount = SpecializationSystem:getPlayerTriedSpecializations(player) or 0
        local totalSpecializations = SpecializationSystem:getTotalSpecializationCount() or 4 -- Default to 4 if can't get actual count
        
        if triedCount >= totalSpecializations then
            self:awardAchievement(player, "specialization_explorer")
        else
            self:updateAchievementProgress(player, "specialization_explorer", triedCount)
        end
    end
end

-- Check specific specialization achievement
function AchievementSystem:checkSpecificSpecializationAchievement(player, achievementId)
    local tycoon = self:getPlayerTycoon(player)
    if not tycoon then return end
    
    local SpecializationSystem = CoreRegistry:tryGetSystem("SpecializationSystem")
    if not SpecializationSystem then return end
    
    if achievementId == "specialization_first_choice" then
        local currentSpecialization = tycoon:GetAttribute("Specialization")
        if currentSpecialization and currentSpecialization ~= "None" then
            self:awardAchievement(player, "specialization_first_choice")
        end
    elseif achievementId == "specialization_master" and SpecializationSystem.getPlayerMaxLevelSpecialization then
        local maxLevel = SpecializationSystem:getPlayerMaxLevelSpecialization(player)
        if maxLevel and maxLevel.level then
            self:updateAchievementProgress(player, "specialization_master", maxLevel.level)
        end
    elseif achievementId == "specialization_explorer" and SpecializationSystem.getPlayerTriedSpecializations then
        local triedCount = SpecializationSystem:getPlayerTriedSpecializations(player) or 0
        self:updateAchievementProgress(player, "specialization_explorer", triedCount)
    end
end

--[[ Event Handlers ]]--

-- Handle basketball scoring events
function AchievementSystem:onBasketballScored(player, points)
    if not player then return end
    
    -- Update progress for basketball achievements
    local currentProgress = self:getAchievementProgress(player, "fitness_basketball_amateur")
    self:updateAchievementProgress(player, "fitness_basketball_amateur", currentProgress + points)
    
    currentProgress = self:getAchievementProgress(player, "fitness_basketball_pro")
    self:updateAchievementProgress(player, "fitness_basketball_pro", currentProgress + points)
    
    -- Basketball Beginner only needs one basket
    if points > 0 then
        self:awardAchievement(player, "fitness_basketball_beginner")
    end
end

-- Handle basketball game completion events
function AchievementSystem:onBasketballGameCompleted(player, score)
    -- Update basketball achievement progress
    self:checkSpecificFitnessAchievement(player, "fitness_basketball_amateur")
    self:checkSpecificFitnessAchievement(player, "fitness_basketball_pro")
end

-- Handle member addition events
function AchievementSystem:onMembersAdded(player, count)
    self:checkSpecificMembershipAchievement(player, "membership_first_member")
    self:checkSpecificMembershipAchievement(player, "membership_growing_community")
    self:checkSpecificMembershipAchievement(player, "membership_popular_gym")
    self:checkSpecificMembershipAchievement(player, "membership_gym_empire")
end

-- Handle membership tier up events
function AchievementSystem:onMembershipTierUp(player, newTier)
    if newTier >= 5 then
        self:awardAchievement(player, "membership_tier_master")
    end
end

-- Handle revenue collection events
function AchievementSystem:onRevenueCollected(player, amount)
    -- Update business tycoon progress
    local currentProgress = self:getAchievementProgress(player, "business_tycoon")
    self:updateAchievementProgress(player, "business_tycoon", currentProgress + amount)
    
    -- Steady income - counts number of collections
    local collectionsProgress = self:getAchievementProgress(player, "business_steady_income")
    self:updateAchievementProgress(player, "business_steady_income", collectionsProgress + 1)
end

-- Handle staff hiring events
function AchievementSystem:onStaffHired(player, staffType, count)
    self:checkStaffAchievements(player)
end

-- Handle sauna temperature events
function AchievementSystem:onSaunaPerfectTemperature(player, duration)
    local currentTime = self:getAchievementProgress(player, "fitness_sauna_master")
    self:updateAchievementProgress(player, "fitness_sauna_master", currentTime + duration)
end

-- Handle tile purchase events
function AchievementSystem:onTilePurchased(player, tileInfo)
    self:checkFacilitiesAchievements(player)
end

-- Handle specialization change events
function AchievementSystem:onSpecializationChanged(player, specialization)
    if specialization and specialization ~= "None" then
        self:awardAchievement(player, "specialization_first_choice")
    end
    
    -- Update specialization explorer achievement
    self:checkSpecificSpecializationAchievement(player, "specialization_explorer")
end

-- Handle specialization level up events
function AchievementSystem:onSpecializationLevelUp(player, specialization, newLevel)
    if newLevel >= 10 then -- Assuming max level is 10
        self:awardAchievement(player, "specialization_master")
    else
        self:updateAchievementProgress(player, "specialization_master", newLevel)
    end
end

-- Handle satisfaction threshold events
function AchievementSystem:onSatisfactionThresholdReached(player, satisfaction)
    if satisfaction >= 95 then
        self:awardAchievement(player, "facilities_luxury_gym")
    else
        self:updateAchievementProgress(player, "facilities_luxury_gym", satisfaction)
    end
end

--[[ Client Communication ]]--

-- Send achievement data to client
function AchievementSystem:sendAchievementDataToClient(player)
    if not player or not EventBridge then return end
    
    local userId = player.UserId
    if not self._playerData[userId] then return end
    
    -- Build achievement data structure for client
    local achievementData = {
        unlocked = {},
        progress = {},
        definitions = {}
    }
    
    -- Get unlocked achievements and progress
    achievementData.unlocked = self._playerData[userId].unlockedAchievements
    achievementData.progress = self._playerData[userId].achievementProgress
    
    -- Build simplified achievement definitions for client
    for category, achievements in pairs(self._achievementDefinitions) do
        for _, achievement in pairs(achievements) do
            achievementData.definitions[achievement.id] = {
                name = achievement.name,
                description = achievement.description,
                icon = achievement.icon,
                progressMax = achievement.progressMax,
                difficulty = achievement.difficulty,
                category = category,
                categoryColor = CONFIG.categories[category] and CONFIG.categories[category].color or Color3.fromRGB(200, 180, 30)
            }
        end
    end
    
    -- Send to client
    EventBridge:fireClientEvent("AchievementDataReceived", player, achievementData)
end

--[[ Utility Functions ]]--

-- Get a player's tycoon instance
function AchievementSystem:getPlayerTycoon(player)
    if not player then return nil end
    
    if TycoonSystem then
        return TycoonSystem:getPlayerTycoon(player)
    end
    
    -- Fallback method
    local tycoonValue = player:FindFirstChild("Tycoon")
    if tycoonValue and tycoonValue.Value then
        return tycoonValue.Value
    end
    
    return nil
end

-- Get player by user ID
function AchievementSystem:getPlayerByUserId(userId)
    for _, player in pairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end

-- Get total achievements count
function AchievementSystem:getTotalAchievementsCount()
    local total = 0
    for _, count in pairs(self._achievementCategoryCounts) do
        total = total + count
    end
    return total
end

-- Get player achievement stats
function AchievementSystem:getPlayerAchievementStats(player)
    if not player then return nil end
    
    local userId = player.UserId
    if not self._playerData[userId] then
        self:setupPlayer(player)
    end
    
    local stats = {
        unlocked = 0,
        total = self:getTotalAchievementsCount(),
        byCategory = {}
    }
    
    -- Count unlocked achievements
    for id, _ in pairs(self._playerData[userId].unlockedAchievements) do
        stats.unlocked = stats.unlocked + 1
        
        -- Find category for this achievement
        local achievement = self:findAchievementById(id)
        if achievement and achievement.category then
            stats.byCategory[achievement.category] = (stats.byCategory[achievement.category] or 0) + 1
        end
    end
    
    -- Add total counts by category
    for category, count in pairs(self._achievementCategoryCounts) do
        if not stats.byCategory[category] then
            stats.byCategory[category] = 0
        end
        
        stats.byCategory[category] = {
            unlocked = stats.byCategory[category] or 0,
            total = count
        }
    end
    
    return stats
end

--[[ Public API ]]--

-- Create exposed API
local PublicAPI = {
    initialize = function()
        return AchievementSystem:initialize()
    end,
    
    getAchievementProgress = function(player, achievementId)
        return AchievementSystem:getAchievementProgress(player, achievementId)
    end,
    
    updateAchievementProgress = function(player, achievementId, progress)
        return AchievementSystem:updateAchievementProgress(player, achievementId, progress)
    end,
    
    awardAchievement = function(player, achievementId)
        return AchievementSystem:awardAchievement(player, achievementId)
    end,
    
    getPlayerAchievementStats = function(player)
        return AchievementSystem:getPlayerAchievementStats(player)
    end,
    
    checkAchievement = function(player, achievementId)
        return AchievementSystem:checkAchievement(player, achievementId)
    end,
    
    checkAllAchievements = function(player)
        return AchievementSystem:checkAllAchievements(player)
    end,
    
    sendAchievementDataToClient = function(player)
        return AchievementSystem:sendAchievementDataToClient(player)
    end,
    
    getConfig = function()
        return table.freeze(table.clone(CONFIG))
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("AchievementSystem", PublicAPI, {"CoreRegistry", "EventBridge", "DataManager", "TycoonSystem", "MilestoneSystem"})