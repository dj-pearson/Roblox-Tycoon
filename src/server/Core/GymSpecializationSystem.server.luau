-- GymSpecializationSystem.luau
-- System for managing gym specializations

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager
local EventBridge

-- Module
local GymSpecializationSystem = {
    Name = "GymSpecializationSystem",
    Dependencies = {
        "PlayerDataManager",
        "EventBridge"
    }
}

-- Available specializations with their bonuses
local specializations = {
    {
        id = "cardio",
        name = "Cardio Training",
        description = "Focuses on cardiovascular fitness with treadmills, bikes, and ellipticals. Increases member retention.",
        level_requirement = 5,
        bonuses = {
            member_boost = 0.2,      -- 20% increase to member satisfaction
            equipment_discount = 0.1, -- 10% discount on cardio equipment
            revenue_multiplier = 0.05 -- 5% increase to overall revenue
        }
    },
    {
        id = "strength",
        name = "Strength Training",
        description = "Focuses on free weights and strength machines. Attracts more dedicated members.",
        level_requirement = 5,
        bonuses = {
            member_value = 0.15,      -- 15% increase to member value
            equipment_discount = 0.15, -- 15% discount on strength equipment
            staff_discount = 0.05      -- 5% discount on trainers
        }
    },
    {
        id = "wellness",
        name = "Wellness & Recovery",
        description = "Focuses on yoga, stretching areas, and recovery facilities. Increases member happiness.",
        level_requirement = 8,
        bonuses = {
            member_satisfaction = 0.25, -- 25% increase to satisfaction
            member_retention = 0.1,     -- 10% better member retention
            staff_efficiency = 0.1      -- 10% staff efficiency boost
        }
    },
    {
        id = "functional",
        name = "Functional Fitness",
        description = "Focuses on functional movement training and group workouts. Attracts diverse clientele.",
        level_requirement = 10,
        bonuses = {
            member_boost = 0.1,       -- 10% more members
            revenue_multiplier = 0.1, -- 10% revenue increase
            equipment_discount = 0.05 -- 5% discount on equipment
        }
    },
    {
        id = "premium",
        name = "Premium Experience",
        description = "Luxury amenities and personalized service. Attracts high-value members and increases reputation.",
        level_requirement = 15,
        bonuses = {
            member_value = 0.3,        -- 30% increase to member value
            reputation_boost = 0.2,    -- 20% reputation boost
            staff_cost = 0.1           -- 10% increase to staff cost
        }
    },
    {
        id = "athletic",
        name = "Athletic Performance",
        description = "Specialized equipment for serious athletes. Attracts dedicated customers.",
        level_requirement = 20,
        bonuses = {
            member_value = 0.2,        -- 20% increase to member value
            member_boost = 0.1,        -- 10% more members 
            equipment_cost = 0.15      -- 15% increase to equipment cost
        }
    }
}

-- Initialize the system
function GymSpecializationSystem:Initialize(registry)
    DataManager = registry:GetSystem("PlayerDataManager")
    EventBridge = registry:GetSystem("EventBridge")
    
    if not DataManager or not EventBridge then
        warn("[GymSpecializationSystem] Missing required dependencies")
        return false
    end
    
    -- Register events
    EventBridge:RegisterEvent("OpenSpecializationsMenu")
    EventBridge:RegisterEvent("SpecializationUpdated")
    
    -- Register event handlers
    EventBridge:On("OpenSpecializationsMenu", function(player)
        self:OpenSpecializationsMenu(player)
    end)
    
    -- Register server-side invokable methods
    EventBridge:RegisterInvokable("GetSpecializations", function(player)
        return self:GetPlayerSpecializations(player)
    end)
    
    EventBridge:RegisterInvokable("SetSpecialization", function(player, specializationId, isSecondary)
        return self:SetPlayerSpecialization(player, specializationId, isSecondary)
    end)
    
    print("[GymSpecializationSystem] Initialized")
    return true
end

-- Get a player's current specializations and available options
function GymSpecializationSystem:GetPlayerSpecializations(player)
    if not player then return nil end
    
    local data = DataManager:GetPlayerData(player)
    if not data then return nil end
    
    -- Get player gym data
    local gymData = data.gym or {}
    local currentPrimary = gymData.primary_specialization
    local currentSecondary = gymData.secondary_specialization
    local playerLevel = data.stats and data.stats.gym_level or 1
    
    -- Prepare available specializations
    local availableSpecs = {}
    for _, spec in ipairs(specializations) do
        local isAvailable = playerLevel >= spec.level_requirement
        
        local specData = {
            id = spec.id,
            name = spec.name,
            description = spec.description,
            level_requirement = spec.level_requirement,
            available = isAvailable,
        }
        
        -- Add unavailable reason if needed
        if not isAvailable then
            specData.unavailable_reason = "Requires Level " .. spec.level_requirement
        end
        
        table.insert(availableSpecs, specData)
    end
    
    -- Return current and available specializations
    return {
        current = {
            primary = currentPrimary,
            secondary = currentSecondary
        },
        available = availableSpecs
    }
end

-- Set a player's specialization
function GymSpecializationSystem:SetPlayerSpecialization(player, specializationId, isSecondary)
    if not player or not specializationId then 
        return false, "Invalid request"
    end
    
    -- Validate the specialization exists
    local isValidSpec = false
    for _, spec in ipairs(specializations) do
        if spec.id == specializationId then
            isValidSpec = true
            break
        end
    end
    
    if not isValidSpec then
        return false, "Invalid specialization selected"
    end
    
    local data = DataManager:GetPlayerData(player)
    if not data then 
        return false, "Failed to load player data"
    end
    
    -- Make sure player has gym data
    if not data.gym then
        data.gym = {}
    end
    
    -- Check if player meets level requirements
    local playerLevel = data.stats and data.stats.gym_level or 1
    for _, spec in ipairs(specializations) do
        if spec.id == specializationId then
            if playerLevel < spec.level_requirement then
                return false, "You need to reach level " .. spec.level_requirement .. " to select this specialization"
            end
            break
        end
    end
    
    -- Update the appropriate specialization
    if isSecondary then
        -- Can't have same primary and secondary
        if data.gym.primary_specialization == specializationId then
            return false, "Primary and secondary specializations cannot be the same"
        end
        data.gym.secondary_specialization = specializationId
    else
        -- Can't have same primary and secondary
        if data.gym.secondary_specialization == specializationId then
            return false, "Primary and secondary specializations cannot be the same"
        end
        data.gym.primary_specialization = specializationId
    end
    
    -- Save player data
    DataManager:SavePlayerData(player)
    
    -- Notify the client about the update
    EventBridge:FireClient("SpecializationUpdated", player, {
        primary = data.gym.primary_specialization,
        secondary = data.gym.secondary_specialization
    })
    
    -- Apply bonuses
    self:ApplySpecializationBonuses(player)
    
    local specType = isSecondary and "secondary" or "primary"
    return true, specializationId .. " has been set as your " .. specType .. " specialization"
end

-- Calculate and apply bonuses from specializations
function GymSpecializationSystem:ApplySpecializationBonuses(player)
    if not player then return end
    
    local data = DataManager:GetPlayerData(player)
    if not data or not data.gym then return end
    
    -- Get current specializations
    local primaryId = data.gym.primary_specialization
    local secondaryId = data.gym.secondary_specialization
    
    -- Find specialization data
    local primarySpec, secondarySpec
    for _, spec in ipairs(specializations) do
        if spec.id == primaryId then
            primarySpec = spec
        end
        if spec.id == secondaryId then
            secondarySpec = spec
        end
        
        -- Break early if we found both
        if primarySpec and secondarySpec then
            break
        end
    end
    
    -- Reset bonuses
    data.gym.bonuses = {}
    
    -- Apply primary bonuses at full value
    if primarySpec then
        for bonusType, value in pairs(primarySpec.bonuses) do
            data.gym.bonuses[bonusType] = (data.gym.bonuses[bonusType] or 0) + value
        end
    end
    
    -- Apply secondary bonuses at half value
    if secondarySpec then
        for bonusType, value in pairs(secondarySpec.bonuses) do
            data.gym.bonuses[bonusType] = (data.gym.bonuses[bonusType] or 0) + (value * 0.5)
        end
    end
    
    -- Save the updated data
    DataManager:SavePlayerData(player)
end

-- Open the specializations menu for a player
function GymSpecializationSystem:OpenSpecializationsMenu(player)
    if not player then return end
    
    -- Fire client to open menu
    EventBridge:FireClient("OpenSpecializationsMenu", player)
end

-- Get bonuses for a specific player
function GymSpecializationSystem:GetPlayerBonuses(player)
    if not player then return {} end
    
    local data = DataManager:GetPlayerData(player)
    if not data or not data.gym or not data.gym.bonuses then
        return {}
    end
    
    return data.gym.bonuses
end

-- Get bonus value for a specific player and bonus type
function GymSpecializationSystem:GetBonusValue(player, bonusType)
    if not player or not bonusType then return 0 end
    
    local bonuses = self:GetPlayerBonuses(player)
    return bonuses[bonusType] or 0
end

-- Get specialization details by ID
function GymSpecializationSystem:GetSpecializationById(specializationId)
    if not specializationId then return nil end
    
    for _, spec in ipairs(specializations) do
        if spec.id == specializationId then
            return spec
        end
    end
    
    return nil
end

-- Apply bonuses to all players (call this on server startup or when needed)
function GymSpecializationSystem:ApplyAllPlayerBonuses()
    for _, player in pairs(Players:GetPlayers()) do
        self:ApplySpecializationBonuses(player)
    end
end

-- Handle player joining
function GymSpecializationSystem:HandlePlayerAdded(player)
    if not player then return end
    
    -- Apply specialization bonuses when player joins
    self:ApplySpecializationBonuses(player)
end

return GymSpecializationSystem