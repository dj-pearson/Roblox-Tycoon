--!strict
-- RebirthData.luau
-- Handles data persistence for rebirth state
-- Created: May 2, 2025

-- Type definitions
export type RebirthState = {
    level: number,
    totalRebirths: number,
    unlockedFeatures: {[string]: boolean},
    lastRebirthTime: number,
    rebirthMultiplier: number,
}

local RebirthData = {}

-- Default state for new players
local DEFAULT_STATE: RebirthState = {
    level = 0,
    totalRebirths = 0,
    unlockedFeatures = {},
    lastRebirthTime = 0,
    rebirthMultiplier = 1,
}

-- Serialize a rebirth state for storage
function RebirthData.serialize(state: RebirthState): {[string]: any}
    -- Create a serialized copy of the state
    local serialized = {
        version = 2, -- For future migration needs
        level = state.level,
        totalRebirths = state.totalRebirths,
        unlockedFeatures = {},
        lastRebirthTime = state.lastRebirthTime,
        rebirthMultiplier = state.rebirthMultiplier,
    }
    
    -- Serialize the unlocked features
    for featureId, unlocked in pairs(state.unlockedFeatures) do
        if unlocked then
            serialized.unlockedFeatures[featureId] = true
        end
    end
    
    return serialized
end

-- Deserialize stored data into a rebirth state
function RebirthData.deserialize(data: any): RebirthState
    -- If data is missing or invalid, return default state
    if not data or type(data) ~= "table" then
        return table.clone(DEFAULT_STATE)
    end
    
    -- Handle legacy format (pre-version field)
    if not data.version then
        return RebirthData.migrateLegacyData(data)
    end
    
    -- Create a state object
    local state: RebirthState = {
        level = data.level or DEFAULT_STATE.level,
        totalRebirths = data.totalRebirths or data.level or DEFAULT_STATE.totalRebirths,
        unlockedFeatures = {},
        lastRebirthTime = data.lastRebirthTime or DEFAULT_STATE.lastRebirthTime,
        rebirthMultiplier = data.rebirthMultiplier or DEFAULT_STATE.rebirthMultiplier,
    }
    
    -- Copy unlocked features
    if type(data.unlockedFeatures) == "table" then
        for featureId, unlocked in pairs(data.unlockedFeatures) do
            if unlocked == true then
                state.unlockedFeatures[featureId] = true
            end
        end
    end
    
    -- Validate and correct any inconsistencies
    RebirthData.validateState(state)
    
    return state
end

-- Migrates legacy data formats
function RebirthData.migrateLegacyData(legacyData: any): RebirthState
    local state = table.clone(DEFAULT_STATE)
    
    -- Try to extract data from legacy format
    if type(legacyData) == "table" then
        -- Handle version 1 format
        if legacyData.rebirthLevel then
            state.level = legacyData.rebirthLevel
            state.totalRebirths = legacyData.totalRebirths or legacyData.rebirthLevel
        end
        
        -- Handle older format with different keys
        if legacyData.level then
            state.level = legacyData.level
            state.totalRebirths = legacyData.rebirths or legacyData.level
        end
        
        -- Extract multiplier if available
        if legacyData.multiplier then
            state.rebirthMultiplier = legacyData.multiplier
        elseif legacyData.rebirthMultiplier then
            state.rebirthMultiplier = legacyData.rebirthMultiplier
        end
        
        -- Extract timestamp if available
        if legacyData.timestamp or legacyData.lastRebirthTime then
            state.lastRebirthTime = legacyData.timestamp or legacyData.lastRebirthTime
        end
        
        -- Extract unlocked features if available
        if type(legacyData.unlocks) == "table" then
            for featureId, unlocked in pairs(legacyData.unlocks) do
                if unlocked == true then
                    state.unlockedFeatures[featureId] = true
                end
            end
        end
        
        -- Handle legacy enum-based unlocks
        if type(legacyData.unlocked) == "table" then
            for _, featureId in ipairs(legacyData.unlocked) do
                state.unlockedFeatures[featureId] = true
            end
        end
    end
    
    -- Validate the migrated state
    RebirthData.validateState(state)
    
    return state
end

-- Validates a rebirth state for consistency
function RebirthData.validateState(state: RebirthState)
    -- Ensure level is non-negative
    state.level = math.max(0, state.level)
    
    -- Ensure total rebirths is at least equal to level
    state.totalRebirths = math.max(state.level, state.totalRebirths)
    
    -- Ensure multiplier is positive
    state.rebirthMultiplier = math.max(1, state.rebirthMultiplier)
    
    -- Ensure lastRebirthTime is valid
    if state.lastRebirthTime < 0 then
        state.lastRebirthTime = 0
    end
    
    -- Ensure unlockedFeatures is a table
    if type(state.unlockedFeatures) ~= "table" then
        state.unlockedFeatures = {}
    end
end

-- Clone a rebirth state
function RebirthData.clone(state: RebirthState): RebirthState
    local newState = {
        level = state.level,
        totalRebirths = state.totalRebirths,
        unlockedFeatures = {},
        lastRebirthTime = state.lastRebirthTime,
        rebirthMultiplier = state.rebirthMultiplier,
    }
    
    -- Copy unlocked features
    for featureId, unlocked in pairs(state.unlockedFeatures) do
        newState.unlockedFeatures[featureId] = unlocked
    end
    
    return newState
end

-- Create a new default state
function RebirthData.createDefaultState(): RebirthState
    return table.clone(DEFAULT_STATE)
end

return RebirthData
