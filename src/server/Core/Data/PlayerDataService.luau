--!strict
--[[
    PlayerDataService.luau
    
    Player-specific data service layer that provides a convenient API for
    working with player data using the DataManager.
    
    Features:
    - Player-focused data operations
    - Common player data patterns
    - Statistical tracking
    - Cash and currency management
    - Experience and leveling
    - Inventory operations
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local ServerScripts = script.Parent.Parent
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")

local DataManager = require(script.Parent:WaitForChild("DataManager"))
local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Module and state variables
local PlayerDataService = {}
local initialized = false

--[[ Private Utility Functions ]]--

-- Calculate experience required for a level
local function calculateExperienceForLevel(level)
    return math.floor(DataConstants.EXPERIENCE.BASE_LEVEL_REQUIREMENT * 
                     (level ^ DataConstants.EXPERIENCE.LEVEL_SCALING_FACTOR))
end

-- Calculate the level based on experience
local function calculateLevelFromExperience(experience)
    local level = 1
    local requiredXP = calculateExperienceForLevel(level)
    
    while experience >= requiredXP do
        level += 1
        requiredXP = calculateExperienceForLevel(level)
    end
    
    return math.max(1, level - 1)
end

--[[ Public API Functions ]]--

-- Initialize the service
function PlayerDataService:initialize()
    if initialized then
        return true
    end
    
    -- Ensure DataManager is initialized
    if not DataManager:initialize() then
        warn("Failed to initialize DataManager")
        return false
    end
    
    initialized = true
    return true
end

-- Get the core player data
function PlayerDataService:getPlayerData(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.CORE)
end

-- Update core player data
function PlayerDataService:updatePlayerData(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.CORE, updateFunction)
end

-- Get player inventory
function PlayerDataService:getInventory(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.INVENTORY)
end

-- Update player inventory
function PlayerDataService:updateInventory(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.INVENTORY, updateFunction)
end

-- Get player statistics
function PlayerDataService:getStatistics(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.STATS)
end

-- Update player statistics
function PlayerDataService:updateStatistics(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.STATS, updateFunction)
end

-- Get player achievements
function PlayerDataService:getAchievements(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.ACHIEVEMENTS)
end

-- Update player achievements
function PlayerDataService:updateAchievements(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.ACHIEVEMENTS, updateFunction)
end

-- Get player quests
function PlayerDataService:getQuests(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.QUESTS)
end

-- Update player quests
function PlayerDataService:updateQuests(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.QUESTS, updateFunction)
end

-- Get player settings
function PlayerDataService:getSettings(player)
    self:initialize()
    return DataManager:getPlayerData(player, DataConstants.PLAYER_SCOPES.SETTINGS)
end

-- Update player settings
function PlayerDataService:updateSettings(player, updateFunction)
    self:initialize()
    return DataManager:updatePlayerData(player, DataConstants.PLAYER_SCOPES.SETTINGS, updateFunction)
end

-- Get player's cash amount
function PlayerDataService:getCash(player)
    self:initialize()
    local data = self:getPlayerData(player)
    return data and data.cash or 0
end

-- Set player's cash to a specific amount
function PlayerDataService:setCash(player, amount)
    self:initialize()
    
    -- Enforce limits
    amount = math.min(amount, DataConstants.LIMITS.MAX_CASH)
    amount = math.max(amount, 0)
    
    return self:updatePlayerData(player, function(data)
        data.cash = amount
        return data
    end)
end

-- Add cash to player
function PlayerDataService:addCash(player, amount)
    self:initialize()
    
    if not amount or amount <= 0 then
        return false, 0
    end
    
    local success, newData = self:updatePlayerData(player, function(data)
        data.cash = math.min(data.cash + amount, DataConstants.LIMITS.MAX_CASH)
        return data
    end)
    
    return success, newData and newData.cash or 0
end

-- Deduct cash from player
function PlayerDataService:deductCash(player, amount)
    self:initialize()
    
    if not amount or amount <= 0 then
        return false, 0, "Invalid amount"
    end
    
    local currentCash = self:getCash(player)
    
    if currentCash < amount then
        return false, currentCash, "Insufficient funds"
    end
    
    local success, newData = self:updatePlayerData(player, function(data)
        data.cash = data.cash - amount
        return data
    end)
    
    return success, newData and newData.cash or 0, "Success"
end

-- Get player's level
function PlayerDataService:getLevel(player)
    self:initialize()
    local data = self:getPlayerData(player)
    return data and data.gymLevel or 1
end

-- Set player's level
function PlayerDataService:setLevel(player, level)
    self:initialize()
    
    -- Enforce limits
    level = math.min(level, DataConstants.LIMITS.MAX_LEVEL)
    level = math.max(level, 1)
    
    return self:updatePlayerData(player, function(data)
        data.gymLevel = level
        return data
    end)
end

-- Get player's rebirth level
function PlayerDataService:getRebirthLevel(player)
    self:initialize()
    local data = self:getPlayerData(player)
    return data and data.rebirthLevel or 0
end

-- Set player's rebirth level
function PlayerDataService:setRebirthLevel(player, level)
    self:initialize()
    
    -- Enforce limits
    level = math.min(level, DataConstants.LIMITS.MAX_REBIRTH)
    level = math.max(level, 0)
    
    return self:updatePlayerData(player, function(data)
        data.rebirthLevel = level
        return data
    end)
end

-- Get player's experience
function PlayerDataService:getExperience(player)
    self:initialize()
    local data = self:getPlayerData(player)
    return data and data.experience or 0
end

-- Add experience to player and handle level ups
function PlayerDataService:addExperience(player, amount)
    self:initialize()
    
    if not amount or amount <= 0 then
        return false, 0, 0, false
    end
    
    local currentData = self:getPlayerData(player)
    if not currentData then
        return false, 0, 0, false
    end
    
    local currentExp = currentData.experience
    local currentLevel = currentData.gymLevel
    
    -- Calculate new experience and level
    local newExp = currentExp + amount
    local newLevel = calculateLevelFromExperience(newExp)
    local leveledUp = newLevel > currentLevel
    
    local success, newData = self:updatePlayerData(player, function(data)
        data.experience = newExp
        data.gymLevel = newLevel
        return data
    end)
    
    return success, newExp, newLevel, leveledUp
end

-- Calculate experience needed for next level
function PlayerDataService:getExperienceToNextLevel(player)
    self:initialize()
    local data = self:getPlayerData(player)
    if not data then
        return 0, 0, 0
    end
    
    local currentLevel = data.gymLevel
    local currentExp = data.experience
    local requiredExp = calculateExperienceForLevel(currentLevel + 1)
    local remaining = requiredExp - currentExp
    
    return remaining, currentExp, requiredExp
end

-- Check if player has a specific item in inventory
function PlayerDataService:hasItem(player, itemId)
    self:initialize()
    local inventory = self:getInventory(player)
    if not inventory then
        return false, 0
    end
    
    return inventory[itemId] and inventory[itemId] > 0, inventory[itemId] or 0
end

-- Add item to player inventory
function PlayerDataService:addItem(player, itemId, quantity)
    self:initialize()
    quantity = quantity or 1
    
    if not itemId or quantity <= 0 then
        return false, 0
    end
    
    local success, newInventory = self:updateInventory(player, function(inventory)
        inventory[itemId] = (inventory[itemId] or 0) + quantity
        return inventory
    end)
    
    return success, newInventory and newInventory[itemId] or 0
end

-- Remove item from player inventory
function PlayerDataService:removeItem(player, itemId, quantity)
    self:initialize()
    quantity = quantity or 1
    
    if not itemId or quantity <= 0 then
        return false, 0, "Invalid item or quantity"
    end
    
    local hasItem, currentQuantity = self:hasItem(player, itemId)
    
    if not hasItem or currentQuantity < quantity then
        return false, currentQuantity, "Insufficient quantity"
    end
    
    local success, newInventory = self:updateInventory(player, function(inventory)
        inventory[itemId] = inventory[itemId] - quantity
        
        if inventory[itemId] <= 0 then
            inventory[itemId] = nil
        end
        
        return inventory
    end)
    
    return success, newInventory and (newInventory[itemId] or 0), "Success"
end

-- Get all player achievements
function PlayerDataService:getAllAchievements(player)
    self:initialize()
    return self:getAchievements(player) or {}
end

-- Check if player has completed an achievement
function PlayerDataService:hasCompletedAchievement(player, achievementId)
    self:initialize()
    local achievements = self:getAchievements(player)
    
    if not achievements or not achievements[achievementId] then
        return false
    end
    
    return achievements[achievementId].completed
end

-- Update achievement progress
function PlayerDataService:updateAchievementProgress(player, achievementId, progress)
    self:initialize()
    
    if not achievementId or not progress then
        return false, 0, false
    end
    
    local success, newAchievements = self:updateAchievements(player, function(achievements)
        if not achievements[achievementId] then
            -- Initialize achievement if it doesn't exist
            achievements[achievementId] = DataTypes.create("Achievement", achievementId)
        end
        
        local achievement = achievements[achievementId]
        local oldProgress = achievement.progress
        local wasCompleted = achievement.completed
        
        -- Update progress
        achievement.progress = progress
        
        -- Check if newly completed
        if not wasCompleted and progress >= achievement.goal then
            achievement.completed = true
            achievement.completionTime = os.time()
        end
        
        achievements[achievementId] = achievement
        return achievements
    end)
    
    local newProgress = 0
    local newlyCompleted = false
    
    if success and newAchievements and newAchievements[achievementId] then
        newProgress = newAchievements[achievementId].progress
        newlyCompleted = newAchievements[achievementId].completed and 
                        (not wasCompleted)
    end
    
    return success, newProgress, newlyCompleted
end

-- Mark a tutorial step as completed
function PlayerDataService:completeTutorialStep(player, step)
    self:initialize()
    
    if not step then
        return false
    end
    
    return self:updatePlayerData(player, function(data)
        if not data.tutorial then
            data.tutorial = {
                completed = false,
                currentStep = 1,
                seenTips = {}
            }
        end
        
        data.tutorial.currentStep = step + 1
        
        -- Check if this was the last step
        local gameConfig = DataManager:getPlayerData(player, "gameConfig")
        if gameConfig and gameConfig.tutorialSteps and 
           step >= #gameConfig.tutorialSteps then
            data.tutorial.completed = true
        end
        
        return data
    end)
end

-- Record a player statistic
function PlayerDataService:recordStat(player, statName, value, operation)
    self:initialize()
    operation = operation or "add"
    
    if not statName then
        return false
    end
    
    return self:updateStatistics(player, function(stats)
        if operation == "add" then
            stats[statName] = (stats[statName] or 0) + (value or 1)
        elseif operation == "set" then
            stats[statName] = value
        elseif operation == "max" then
            stats[statName] = math.max(stats[statName] or 0, value or 0)
        elseif operation == "min" then
            stats[statName] = math.min(stats[statName] or 0, value or 0)
        end
        
        return stats
    end)
end

-- Get a player statistic
function PlayerDataService:getStat(player, statName)
    self:initialize()
    local stats = self:getStatistics(player)
    return stats and stats[statName] or 0
end

-- Update player settings
function PlayerDataService:setSetting(player, settingName, value)
    self:initialize()
    
    if not settingName then
        return false
    end
    
    return self:updateSettings(player, function(settings)
        settings[settingName] = value
        return settings
    end)
end

-- Get a player setting
function PlayerDataService:getSetting(player, settingName)
    self:initialize()
    local settings = self:getSettings(player)
    
    if not settings or settings[settingName] == nil then
        -- Return default if available
        return DataConstants.DEFAULT_PLAYER_SETTINGS[settingName]
    end
    
    return settings[settingName]
end

-- Reset all player data (used during rebirth)
function PlayerDataService:resetPlayerData(player, options)
    self:initialize()
    options = options or {}
    
    local rebirthLevel = self:getRebirthLevel(player)
    local newRebirthLevel = options.incrementRebirth and (rebirthLevel + 1) or rebirthLevel
    
    -- Create fresh player data
    local success, newData = self:updatePlayerData(player, function(_)
        local data = DataTypes.create("PlayerData", player.UserId, player.Name, player.DisplayName)
        
        -- Preserve certain values if specified
        if options.preserveSettings and self:getSettings(player) then
            data.settings = self:getSettings(player)
        end
        
        -- Apply rebirth bonuses
        data.rebirthLevel = newRebirthLevel
        data.cash = DataConstants.ECONOMY.STARTING_CASH * 
                    (1 + (newRebirthLevel * DataConstants.ECONOMY.REBIRTH_MULTIPLIER / 10))
        
        return data
    end)
    
    -- Reset other scopes if needed
    if success and options.resetInventory then
        self:updateInventory(player, function(_)
            return {}
        end)
    end
    
    if success and options.resetStatistics then
        self:updateStatistics(player, function(stats)
            -- Preserve certain stats if needed
            local preserved = {}
            
            if options.preserveStats and type(options.preserveStats) == "table" then
                for _, statName in ipairs(options.preserveStats) do
                    preserved[statName] = stats[statName]
                end
            end
            
            -- Add lifetime stats
            preserved.lifetimeRebirths = (stats.lifetimeRebirths or 0) + 1
            preserved.previousRebirthTime = os.time()
            
            return preserved
        end)
    end
    
    if success and options.resetAchievements then
        self:updateAchievements(player, function(_)
            return {}
        end)
    end
    
    if success and options.resetQuests then
        self:updateQuests(player, function(_)
            return {}
        end)
    end
    
    return success, newData
end

-- Force save all data for a player
function PlayerDataService:saveAll(player)
    self:initialize()
    return DataManager:savePlayerData(player, true)
end

return PlayerDataService
