--!strict
-- RebirthCalculator.luau
-- Pure calculation service for rebirth costs and multipliers
-- Created: May 2, 2025

-- Configuration
local CONFIG = {
    -- Basic rebirth settings
    baseRebirthCost = 100000,             -- Starting cost for first rebirth
    rebirthCostMultiplier = 2.0,          -- How much the cost increases per level
    maxRebirthLevel = 50,                 -- Maximum rebirth level
    
    -- Revenue multipliers
    baseBonusMultiplier = 0.2,            -- Base 20% bonus per rebirth
    tierBonusMultipliers = {
        [5] = 0.1,                        -- Extra 10% at rebirth level 5
        [10] = 0.2,                       -- Extra 20% at rebirth level 10
        [20] = 0.25,                      -- Extra 25% at rebirth level 20
        [30] = 0.3,                       -- Extra 30% at rebirth level 30
        [50] = 0.4                        -- Extra 40% at rebirth level 50
    }
}

local RebirthCalculator = {}

-- Calculate the cost for a specific rebirth level
function RebirthCalculator:CalculateCost(currentLevel: number): number
    -- If at max level, return infinity
    if currentLevel >= CONFIG.maxRebirthLevel then
        return math.huge
    end
    
    -- Base cost for the next level (level + 1)
    local cost = CONFIG.baseRebirthCost * (CONFIG.rebirthCostMultiplier ^ currentLevel)
    
    -- Round to nearest whole number
    return math.floor(cost)
end

-- Calculate the multiplier for a specific rebirth level
function RebirthCalculator:CalculateMultiplier(level: number): number
    -- Base multiplier: 1 + (level * base bonus)
    local multiplier = 1 + (level * CONFIG.baseBonusMultiplier)
    
    -- Add tier bonuses for reaching specific thresholds
    for tierLevel, bonus in pairs(CONFIG.tierBonusMultipliers) do
        if level >= tierLevel then
            multiplier += bonus
        end
    end
    
    -- Round to 2 decimal places for cleaner display
    return math.floor(multiplier * 100) / 100
end

-- Get the next significant tier level after the current level
function RebirthCalculator:GetNextTierLevel(currentLevel: number): (number?, number?)
    local nextTier = nil
    local nextBonus = nil
    
    for tierLevel, bonus in pairs(CONFIG.tierBonusMultipliers) do
        if tierLevel > currentLevel and (nextTier == nil or tierLevel < nextTier) then
            nextTier = tierLevel
            nextBonus = bonus
        end
    end
    
    return nextTier, nextBonus
end

-- Calculate progression info for UI display
function RebirthCalculator:GetProgressionInfo(currentLevel: number): {[string]: any}
    local currentCost = self:CalculateCost(currentLevel)
    local currentMultiplier = self:CalculateMultiplier(currentLevel)
    local nextLevel = currentLevel + 1
    local nextMultiplier = self:CalculateMultiplier(nextLevel)
    local multiplierIncrease = nextMultiplier - currentMultiplier
    
    local nextTier, nextTierBonus = self:GetNextTierLevel(currentLevel)
    
    return {
        currentLevel = currentLevel,
        currentMultiplier = currentMultiplier,
        nextLevel = nextLevel,
        nextCost = currentCost,
        nextMultiplier = nextMultiplier,
        multiplierIncrease = multiplierIncrease,
        nextTierLevel = nextTier,
        nextTierBonus = nextTierBonus,
        maxLevel = CONFIG.maxRebirthLevel,
        atMaxLevel = currentLevel >= CONFIG.maxRebirthLevel
    }
end

-- Get a formatted version of the cost (e.g., "1.5M" instead of 1500000)
function RebirthCalculator:FormatCost(cost: number): string
    if cost >= 1000000000 then
        return string.format("%.1fB", cost / 1000000000)
    elseif cost >= 1000000 then
        return string.format("%.1fM", cost / 1000000)
    elseif cost >= 1000 then
        return string.format("%.1fK", cost / 1000)
    else
        return tostring(cost)
    end
end

-- Update configuration (for testing or runtime adjustments)
function RebirthCalculator:UpdateConfig(newConfig: {[string]: any})
    for key, value in pairs(newConfig) do
        if typeof(CONFIG[key]) == typeof(value) then
            CONFIG[key] = value
        end
    end
end

-- Get current configuration (for reference)
function RebirthCalculator:GetConfig(): {[string]: any}
    return table.clone(CONFIG)
end

return RebirthCalculator
