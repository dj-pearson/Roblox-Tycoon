-- SpecializationSystem.luau
-- Server-side implementation of the gym specialization system
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Import server-side systems
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager")

-- Configuration
local CONFIG = {
    debugEnabled = true,
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SpecializationSystem]", ...)
    end
end

-- The SpecializationSystem object
local SpecializationSystem = {
    playerSpecializations = {},
    initialized = false,
    
    -- Specialization definitions
    specializations = {
        bodybuilding = {
            name = "Bodybuilding",
            description = "Focus on strength training and muscle growth",
            level_requirement = 3,
            benefits = {
                membership_boost = 1.3,  -- 30% more members (increased from 20%)
                vip_chance = 0.12,       -- Increased VIP chance (12%, decreased from 15%)
                strength_bonus = 0.1,   -- 10% strength bonus for NPCs using weights (new benefit)
                equipment_discounts = {  -- Discounts on related equipment
                    weights = 0.2,       -- 20% off weight equipment
                    machines = 0.1       -- 10% off machines
                }
            },
            equipment_tags = {"weights", "bench", "rack", "machine", "IsEquipment", "equipment"} -- Added "machine", "IsEquipment" and "equipment" tag
			-- machine: This tag is added because the NPC_Movement script can identify machines but there was no tag for it.
			-- IsEquipment: This tag will target any model that has the attribute "IsEquipment", allowing more flexibility.
			-- equipment: This tag will target any model that has the name "equipment", allowing more flexibility.
			

        },
        cardio = {
            name = "Cardio Fitness",
            description = "Focus on cardiovascular health and endurance",
            level_requirement = 3,
            benefits = {
                dues_boost = 1.1,        -- Members pay 10% more (decreased from 15%)
                membership_retention = 1.3, -- 30% better member retention (increased from 25%)
                endurance_bonus = 0.1,  -- 10% endurance bonus for NPCs using cardio equipment (new benefit)
                equipment_discounts = {
                    treadmill = 0.2,     -- 20% off treadmills
                    cardio = 0.15        -- 15% off cardio equipment
                }
            }, 
            equipment_tags = {"treadmill", "bike", "cardio", "IsEquipment", "equipment"} -- Added "IsEquipment" and "equipment" tag
			-- IsEquipment: This tag will target any model that has the attribute "IsEquipment", allowing more flexibility.
			-- equipment: This tag will target any model that has the name "equipment", allowing more flexibility.
        },
        luxury = {
            name = "Luxury Wellness",
            description = "Premium experience with spa and wellness features",
            level_requirement = 5,
            benefits = {
                vip_multiplier = 2.0,   -- VIPs pay double the standard boost
                vip_chance = 0.15,       -- 15% chance for VIPs (decreased from 20%)
                membership_boost = 0.95, -- 5% fewer total members (increased from 10% fewer)
                dues_boost = 1.4,        -- 40% higher membership fees (increased from 30%)
                energy_bonus = 0.1      -- 10% energy bonus for NPCs using spa equipment (new benefit)
            },
            equipment_tags = {"spa", "sauna", "luxury", "IsEquipment", "equipment"} -- Added "IsEquipment" and "equipment" tag
			-- IsEquipment: This tag will target any model that has the attribute "IsEquipment", allowing more flexibility.
			-- equipment: This tag will target any model that has the name "equipment", allowing more flexibility.
			
        },
        crossfit = {
            name = "CrossFit Training",
            description = "High-intensity functional training approach",
            level_requirement = 4,
            benefits = {
                membership_boost = 1.2,  -- 20% more members (increased from 10%)
                dues_boost = 1.05,       -- 5% higher dues (decreased from 10%)
                competition_bonus = 1.4  -- 40% better competition results (renamed and increased from 30%)
            },
            equipment_tags = {"functional", "crossfit", "box", "IsEquipment", "equipment"} -- Added "IsEquipment" and "equipment" tag
			-- IsEquipment: This tag will target any model that has the attribute "IsEquipment", allowing more flexibility.
			-- equipment: This tag will target any model that has the name "equipment", allowing more flexibility.
			
        }
    }
}

-- Get available specializations for a player
function SpecializationSystem:getAvailableSpecializations(player)
    if not player then return {} end

    local available = {}
    local gymLevel = 1

    -- Get gym level
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    end

    -- Filter specializations by level requirement
    for id, specialization in pairs(self.specializations) do
        if gymLevel >= specialization.level_requirement then
            table.insert(available, {
                id = id,
                name = specialization.name,
                description = specialization.description,
                level_requirement = specialization.level_requirement
            })
        end
    end

    return available
end

-- Get current specialization(s) for a player
function SpecializationSystem:getPlayerSpecializations(player)
    if not player then return nil end

    local userId = player.UserId

    -- Check cached data
    if self.playerSpecializations[userId] then
        return self.playerSpecializations[userId]
    end

    -- Load from data storage
    if DataManager then
        local data = DataManager.getPlayerData(player)
        if data and data.specializations then
            self.playerSpecializations[userId] = data.specializations
            return data.specializations
        end
    end

    -- Default to no specialization
    return { primary = nil, secondary = nil }
end

-- Set player specialization
function SpecializationSystem:setSpecialization(player, specializationId, isSecondary)
    if not player or not specializationId then return false, "Missing player or specialization ID" end

    -- Check if specialization exists
    if not self.specializations[specializationId] then
        return false, "Invalid specialization"
    end

    local userId = player.UserId
    local gymLevel = 1

    -- Get gym level
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    end

    -- Check level requirement
    local specialization = self.specializations[specializationId]
    if gymLevel < specialization.level_requirement then
        return false, "Gym level too low. Requires level " .. specialization.level_requirement
    end

    -- Get current specializations
    local current = self:getPlayerSpecializations(player)

    -- Update specialization
    if isSecondary then
        -- Can't have same primary and secondary
        if current.primary == specializationId then
            return false, "Cannot set the same specialization as both primary and secondary"
        end
        current.secondary = specializationId
    else
        -- Can't have same primary and secondary
        if current.secondary == specializationId then
            return false, "Cannot set the same specialization as both primary and secondary"
        end
        current.primary = specializationId
    end

    -- Update cache
    self.playerSpecializations[userId] = current

    -- Save to data storage
    if DataManager then
        DataManager.updateData(player, "specializations", current)
    end

    -- Apply specialization benefits
    self:applySpecializationBenefits(player)
    
    -- Create specialization decor
    self:createSpecializationDecor(player)
    
    -- Notify client
    EventBridge.fireClientEvent("SpecializationUpdated", player, current)

    return true, "Specialization set successfully"
end

-- Apply specialization benefits to a player
function SpecializationSystem:applySpecializationBenefits(player)
    if not player then return end

    local specs = self:getPlayerSpecializations(player)

    -- No specializations
    if not specs.primary and not specs.secondary then
        return
    end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return end

    -- Reset to base values
    tycoon:SetAttribute("SpecMembershipBoost", 1.0)
    tycoon:SetAttribute("SpecDuesBoost", 1.0)
    tycoon:SetAttribute("SpecVIPChance", 0.1) -- Default 10%
    tycoon:SetAttribute("SpecVIPMultiplier", 1.0)
    tycoon:SetAttribute("SpecCompetitionBoost", 1.0)
    tycoon:SetAttribute("SpecStrengthBonus", 0.0)
    tycoon:SetAttribute("SpecEnduranceBonus", 0.0)
    tycoon:SetAttribute("SpecEnergyBonus", 0.0)

    -- Apply primary specialization benefits
    if specs.primary then
        local primary = self.specializations[specs.primary]
        if primary then
            -- Membership boost
            if primary.benefits.membership_boost then
                tycoon:SetAttribute("SpecMembershipBoost", primary.benefits.membership_boost)
            end

            -- Dues boost
            if primary.benefits.dues_boost then
                tycoon:SetAttribute("SpecDuesBoost", primary.benefits.dues_boost)
            end

            -- VIP chance
            if primary.benefits.vip_chance then
                tycoon:SetAttribute("SpecVIPChance", primary.benefits.vip_chance)
            end

            -- VIP multiplier
            if primary.benefits.vip_multiplier then
                tycoon:SetAttribute("SpecVIPMultiplier", primary.benefits.vip_multiplier)
            end

            -- Competition bonus
            if primary.benefits.competition_boost then
                tycoon:SetAttribute("SpecCompetitionBoost", primary.benefits.competition_bonus)
            end
            
            -- Strength bonus
            if primary.benefits.strength_bonus then
                tycoon:SetAttribute("SpecStrengthBonus", primary.benefits.strength_bonus)
            end
            
            -- Endurance bonus
            if primary.benefits.endurance_bonus then
                tycoon:SetAttribute("SpecEnduranceBonus", primary.benefits.endurance_bonus)
            end
            
            -- Energy bonus
            if primary.benefits.energy_bonus then
                tycoon:SetAttribute("SpecCompetitionBoost", primary.benefits.competition_boost)
            end
        end
    end

    -- Apply secondary specialization benefits (at half strength)
    if specs.secondary then
        local secondary = self.specializations[specs.secondary]
        if secondary then
            -- Membership boost (half effect)
            if secondary.benefits.membership_boost then
                local currentBoost = tycoon:GetAttribute("SpecMembershipBoost")
                local secondaryEffect = (secondary.benefits.membership_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecMembershipBoost", currentBoost + secondaryEffect)
            end

            -- Dues boost (half effect)
            if secondary.benefits.dues_boost then
                local currentBoost = tycoon:GetAttribute("SpecDuesBoost")
                local secondaryEffect = (secondary.benefits.dues_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecDuesBoost", currentBoost + secondaryEffect)
            end

            -- VIP chance (half effect)
            if secondary.benefits.vip_chance then
                local currentChance = tycoon:GetAttribute("SpecVIPChance")
                local secondaryEffect = (secondary.benefits.vip_chance - 0.1) * 0.5
                tycoon:SetAttribute("SpecVIPChance", currentChance + secondaryEffect)
            end

            -- VIP multiplier (half effect)
            if secondary.benefits.vip_multiplier then
                local currentMultiplier = tycoon:GetAttribute("SpecVIPMultiplier")
                local secondaryEffect = (secondary.benefits.vip_multiplier - 1.0) * 0.5
                tycoon:SetAttribute("SpecVIPMultiplier", currentMultiplier + secondaryEffect)
            end

            -- Competition bonus (half effect)
            if secondary.benefits.competition_boost then
                local currentBoost = tycoon:GetAttribute("SpecCompetitionBoost")
                local secondaryEffect = (secondary.benefits.competition_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecCompetitionBoost", currentBoost + secondaryEffect)
            end
            
             -- Strength bonus (half effect)
            if secondary.benefits.strength_bonus then
                local currentBoost = tycoon:GetAttribute("SpecStrengthBonus")
                local secondaryEffect = secondary.benefits.strength_bonus * 0.5
                tycoon:SetAttribute("SpecStrengthBonus", currentBoost + secondaryEffect)
            end
            
            -- Other bonus (half effect)
            if secondary.benefits.other_bonus then
                local currentBoost = tycoon:GetAttribute("SpecOtherBonus")
                local secondaryEffect = (secondary.benefits.competition_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecCompetitionBoost", currentBoost + secondaryEffect)
            end
        end
    end

    -- Update revenue system if available
    local GymRevenueSystem = CoreRegistry.getSystem("GymRevenueSystem")
    if GymRevenueSystem then

