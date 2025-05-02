--!strict
-- UnlockManager.luau
-- Manages unlockable features based on rebirth level
-- Created: May 2, 2025

local ServerScriptService = game:GetService("ServerScriptService")

-- Types
type UnlockableFeature = {
    id: string,
    name: string,
    description: string,
    requiredLevel: number,
    icon: string?,
    effects: {[string]: any}?,
    model: string?
}

type RebirthState = {
    level: number,
    totalRebirths: number,
    unlockedFeatures: {[string]: boolean},
    lastRebirthTime: number,
    rebirthMultiplier: number,
}

-- UnlockableFeatures configuration
local FEATURES: {[string]: UnlockableFeature} = {
    PREMIUM_EQUIPMENT = {
        id = "PREMIUM_EQUIPMENT",
        name = "Premium Equipment",
        description = "Unlock premium equipment options",
        requiredLevel = 1,
        icon = "rbxassetid://12696906515",
        effects = {
            equipmentBonus = 0.15 -- 15% equipment effectiveness bonus
        }
    },
    
    VIP_ACCESS = {
        id = "VIP_ACCESS",
        name = "VIP Member Access",
        description = "Attract VIP members more easily",
        requiredLevel = 3,
        icon = "rbxassetid://12696906726",
        effects = {
            vipChanceBonus = 0.2, -- 20% increased VIP chance
            vipValueBonus = 0.15  -- 15% increased VIP value
        }
    },
    
    EXECUTIVE_OFFICE = {
        id = "EXECUTIVE_OFFICE",
        name = "Executive Office",
        description = "Unlock the executive office feature",
        requiredLevel = 5,
        icon = "rbxassetid://12696906940",
        effects = {
            revenueBonus = 0.1 -- 10% passive revenue
        },
        model = "ExecutiveOffice"
    },
    
    CUSTOM_THEMES = {
        id = "CUSTOM_THEMES",
        name = "Custom Gym Themes",
        description = "Unlock premium gym customization options",
        requiredLevel = 10,
        icon = "rbxassetid://12696907122",
        effects = {
            themeBonus = 0.05 -- 5% additional satisfaction from themes
        }
    },
    
    PREMIUM_STAFF = {
        id = "PREMIUM_STAFF",
        name = "Premium Staff Options",
        description = "Unlock specialized staff members",
        requiredLevel = 15,
        icon = "rbxassetid://12696907302",
        effects = {
            staffEfficiencyBonus = 0.2, -- 20% staff efficiency
            unlockPremiumStaff = true
        }
    },
    
    EXCLUSIVE_MARKETING = {
        id = "EXCLUSIVE_MARKETING",
        name = "Exclusive Marketing", 
        description = "Unlock exclusive marketing campaigns",
        requiredLevel = 20,
        icon = "rbxassetid://12696907482",
        effects = {
            marketingEffectivenessBonus = 0.25, -- 25% marketing bonus
            unlockPremiumCampaigns = true
        }
    }
}

-- Feature lookup by level
local FEATURES_BY_LEVEL = {}
for _, feature in pairs(FEATURES) do
    if not FEATURES_BY_LEVEL[feature.requiredLevel] then
        FEATURES_BY_LEVEL[feature.requiredLevel] = {}
    end
    table.insert(FEATURES_BY_LEVEL[feature.requiredLevel], feature)
end

-- UnlockManager implementation
local UnlockManager = {}

-- Get a list of all available features
function UnlockManager:GetFeaturesList(): {UnlockableFeature}
    local list = {}
    for _, feature in pairs(FEATURES) do
        table.insert(list, feature)
    end
    
    -- Sort by required level
    table.sort(list, function(a, b)
        return a.requiredLevel < b.requiredLevel
    end)
    
    return list
end

-- Get details about a specific feature
function UnlockManager:GetFeatureDetails(featureId: string): UnlockableFeature?
    return FEATURES[featureId]
end

-- Get features that unlock at a specific level
function UnlockManager:GetFeaturesAtLevel(level: number): {UnlockableFeature}
    return FEATURES_BY_LEVEL[level] or {}
end

-- Check if a player should have a feature unlocked
function UnlockManager:ShouldUnlockFeature(featureId: string, rebirthLevel: number): boolean
    local feature = FEATURES[featureId]
    if not feature then
        return false
    end
    
    return rebirthLevel >= feature.requiredLevel
end

-- Process unlocks for a player based on their rebirth state
-- Returns a list of newly unlocked features
function UnlockManager:ProcessUnlocks(player: Player, state: RebirthState): {UnlockableFeature}
    local newUnlocks = {}
    
    -- Check each feature to see if it should be unlocked
    for featureId, feature in pairs(FEATURES) do
        if not state.unlockedFeatures[featureId] and state.level >= feature.requiredLevel then
            -- Unlock the feature
            state.unlockedFeatures[featureId] = true
            table.insert(newUnlocks, feature)
            
            -- Apply immediate effects if needed
            self:ApplyFeatureEffects(player, feature)
        end
    end
    
    return newUnlocks
end

-- Apply effects from an unlocked feature
function UnlockManager:ApplyFeatureEffects(player: Player, feature: UnlockableFeature)
    if not feature.effects then
        return
    end
    
    -- Different effects are handled by different systems
    local ServerRegistry = require(ServerScriptService.Core.Registry.ServerRegistry)
    
    -- Equipment effects
    if feature.effects.equipmentBonus then
        local equipmentSystem = ServerRegistry.getSystem("EquipmentSystem")
        if equipmentSystem then
            equipmentSystem:AddBonusMultiplier(player, feature.effects.equipmentBonus)
        end
    end
    
    -- VIP effects
    if feature.effects.vipChanceBonus or feature.effects.vipValueBonus then
        local membershipSystem = ServerRegistry.getSystem("MembershipSystem")
        if membershipSystem then
            if feature.effects.vipChanceBonus then
                membershipSystem:AddVIPChanceBonus(player, feature.effects.vipChanceBonus)
            end
            if feature.effects.vipValueBonus then
                membershipSystem:AddVIPValueBonus(player, feature.effects.vipValueBonus)
            end
        end
    end
    
    -- Revenue effects
    if feature.effects.revenueBonus then
        local revenueSystem = ServerRegistry.getSystem("RevenueSystem")
        if revenueSystem then
            revenueSystem:AddPassiveBonus(player, feature.effects.revenueBonus)
        end
    end
    
    -- Create models if needed
    if feature.model then
        local tycoonSystem = ServerRegistry.getSystem("TycoonSystem")
        if tycoonSystem then
            tycoonSystem:AddPremiumModel(player, feature.model)
        end
    end
end

-- Get bonus information for a player across all unlocked features
function UnlockManager:GetPlayerBonuses(player: Player, state: RebirthState): {[string]: number}
    local bonuses = {}
    
    -- Accumulate bonuses from all unlocked features
    for featureId, unlocked in pairs(state.unlockedFeatures) do
        if unlocked then
            local feature = FEATURES[featureId]
            if feature and feature.effects then
                for effectType, value in pairs(feature.effects) do
                    if type(value) == "number" then
                        bonuses[effectType] = (bonuses[effectType] or 0) + value
                    end
                end
            end
        end
    end
    
    return bonuses
end

-- Check if a player has all features unlocked
function UnlockManager:HasAllFeatures(state: RebirthState): boolean
    for featureId, _ in pairs(FEATURES) do
        if not state.unlockedFeatures[featureId] then
            return false
        end
    end
    
    return true
end

-- Get the next feature a player will unlock
function UnlockManager:GetNextFeature(state: RebirthState): (UnlockableFeature?, number?)
    local nextFeature = nil
    local levelsRemaining = math.huge
    
    for _, feature in pairs(FEATURES) do
        if not state.unlockedFeatures[feature.id] then
            local levelDifference = feature.requiredLevel - state.level
            if levelDifference < levelsRemaining then
                nextFeature = feature
                levelsRemaining = levelDifference
            end
        end
    end
    
    return nextFeature, math.max(0, levelsRemaining)
end

return UnlockManager
