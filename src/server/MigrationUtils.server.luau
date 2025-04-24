--!strict
--[[
    MigrationUtils.server.luau
    This module provides utilities for migrating data between old and new script formats
    Part of the Automation Scripts Consolidation Plan - Phase 3
]]

local MigrationUtils = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Constants
local DATA_VERSION = 1
local ENABLE_VALIDATION = true
local ENABLE_ROLLBACK = true

-- Storage for original data in case rollback is needed
local originalDataStore = {}

-- Migration Functions
--[[
    Migrates equipment data from the old format to the new format
    @param oldFormat table - The equipment data in the old format
    @param newFormat table - Optional pre-initialized table for the new format
    @return table - The equipment data in the new format
]]
function MigrationUtils.MigrateEquipmentData(oldFormat, newFormat)
    newFormat = newFormat or {}
    
    -- Store original data for potential rollback
    if ENABLE_ROLLBACK then
        originalDataStore.equipment = oldFormat
    end
    
    -- Basic structure validation
    if type(oldFormat) ~= "table" then
        warn("MigrationUtils: Invalid equipment data format - expected table")
        return newFormat
    end
    
    -- Handle old format variations
    if oldFormat.equipment then
        -- Old format stored equipment in a nested table
        for id, equipData in pairs(oldFormat.equipment) do
            newFormat[id] = {
                id = id,
                level = equipData.level or 1,
                xp = equipData.xp or 0,
                upgrades = equipData.upgrades or {},
                attributes = {},
            }
            
            -- Migrate attributes with new naming convention
            if equipData.attributes then
                for attrName, attrValue in pairs(equipData.attributes) do
                    -- Convert old attribute names to new format
                    local newAttrName = attrName:gsub("_", ":")
                    newFormat[id].attributes[newAttrName] = attrValue
                end
            end
            
            -- Handle legacy stats field if present
            if equipData.stats then
                newFormat[id].stats = equipData.stats
            end
        end
    else
        -- Direct equipment data without nesting
        for id, equipData in pairs(oldFormat) do
            -- Skip if not a valid equipment entry
            if type(equipData) ~= "table" then continue end
            
            newFormat[id] = {
                id = id,
                level = equipData.level or 1,
                xp = equipData.xp or 0,
                upgrades = {},
                attributes = {},
            }
            
            -- Copy upgrades if they exist
            if equipData.upgrades then
                for upgradeId, upgradeData in pairs(equipData.upgrades) do
                    newFormat[id].upgrades[upgradeId] = upgradeData
                end
            end
            
            -- Handle attributes
            if equipData.attributes then
                for attrName, attrValue in pairs(equipData.attributes) do
                    local newAttrName = attrName:gsub("_", ":")
                    newFormat[id].attributes[newAttrName] = attrValue
                end
            end
        end
    end
    
    -- Validate the migrated data if enabled
    if ENABLE_VALIDATION then
        MigrationUtils.ValidateEquipmentData(newFormat)
    end
    
    return newFormat
end

--[[
    Migrates tile purchase data from the old format to the new format
    @param oldFormat table - The tile data in the old format
    @param newFormat table - Optional pre-initialized table for the new format
    @return table - The tile data in the new format
]]
function MigrationUtils.MigrateTileData(oldFormat, newFormat)
    newFormat = newFormat or {}
    
    -- Store original data for potential rollback
    if ENABLE_ROLLBACK then
        originalDataStore.tiles = oldFormat
    end
    
    -- Basic structure validation
    if type(oldFormat) ~= "table" then
        warn("MigrationUtils: Invalid tile data format - expected table")
        return newFormat
    end
    
    -- Different handling based on old format structure
    if oldFormat.tiles then
        -- Old format stored tiles in a nested table
        for tileId, tileData in pairs(oldFormat.tiles) do
            newFormat[tileId] = {
                id = tileId,
                purchased = tileData.purchased or false,
                purchaseTime = tileData.purchaseTime or 0,
                category = tileData.category or "Unknown",
                floor = tileData.floor or 1,
            }
            
            -- Convert metadata if present
            if tileData.metadata then
                newFormat[tileId].metadata = tileData.metadata
            end
        end
    else
        -- Direct tile data mapping
        for tileId, tileData in pairs(oldFormat) do
            -- Skip if not a valid tile entry
            if type(tileData) ~= "table" then continue end
            
            -- If it's just a boolean (old format sometimes just stored purchased status)
            if type(tileData) == "boolean" then
                newFormat[tileId] = {
                    id = tileId,
                    purchased = tileData,
                    purchaseTime = 0,
                }
            else
                newFormat[tileId] = {
                    id = tileId,
                    purchased = tileData.purchased or tileData.isPurchased or false,
                    purchaseTime = tileData.purchaseTime or tileData.timestamp or 0,
                    category = tileData.category or "Unknown",
                    floor = tileData.floor or tileData.floorNumber or 1,
                }
                
                -- Copy any custom metadata
                if tileData.metadata or tileData.meta then
                    newFormat[tileId].metadata = tileData.metadata or tileData.meta or {}
                end
            end
        end
    end
    
    -- Validate the migrated data if enabled
    if ENABLE_VALIDATION then
        MigrationUtils.ValidateTileData(newFormat)
    end
    
    return newFormat
end

--[[
    Migrates progression data from the old format to the new format
    @param oldFormat table - The progression data in the old format
    @param newFormat table - Optional pre-initialized table for the new format
    @return table - The progression data in the new format
]]
function MigrationUtils.MigrateProgressionData(oldFormat, newFormat)
    newFormat = newFormat or {
        floors = {},
        milestones = {},
        achievements = {},
        unlockedFeatures = {},
    }
    
    -- Store original data for potential rollback
    if ENABLE_ROLLBACK then
        originalDataStore.progression = oldFormat
    end
    
    -- Basic structure validation
    if type(oldFormat) ~= "table" then
        warn("MigrationUtils: Invalid progression data format - expected table")
        return newFormat
    end
    
    -- Handle floors data
    if oldFormat.floors or oldFormat.floorProgress then
        local floorSource = oldFormat.floors or oldFormat.floorProgress or {}
        for floorId, floorData in pairs(floorSource) do
            newFormat.floors[floorId] = {
                id = floorId,
                unlocked = floorData.unlocked or floorData.isUnlocked or false,
                progress = floorData.progress or 0,
                completed = floorData.completed or false,
            }
        end
    end
    
    -- Handle milestones and achievements
    if oldFormat.milestones then
        for id, data in pairs(oldFormat.milestones) do
            newFormat.milestones[id] = {
                id = id,
                completed = type(data) == "boolean" and data or data.completed or false,
                progress = type(data) == "table" and data.progress or 0,
                completionTime = type(data) == "table" and data.completionTime or 0,
            }
        end
    end
    
    if oldFormat.achievements then
        for id, data in pairs(oldFormat.achievements) do
            newFormat.achievements[id] = {
                id = id,
                completed = type(data) == "boolean" and data or data.completed or false,
                progress = type(data) == "table" and data.progress or 0,
                completionTime = type(data) == "table" and data.completionTime or 0,
            }
        end
    end
    
    -- Handle features
    if oldFormat.unlockedFeatures or oldFormat.features then
        local featureSource = oldFormat.unlockedFeatures or oldFormat.features or {}
        for featureId, isUnlocked in pairs(featureSource) do
            newFormat.unlockedFeatures[featureId] = isUnlocked
        end
    end
    
    -- Validate the migrated data if enabled
    if ENABLE_VALIDATION then
        MigrationUtils.ValidateProgressionData(newFormat)
    end
    
    return newFormat
end

-- Validation Functions
--[[
    Validates equipment data structure and logs issues
    @param data table - The equipment data to validate
    @return boolean - Whether the data is valid
]]
function MigrationUtils.ValidateEquipmentData(data)
    local isValid = true
    
    for id, equipData in pairs(data) do
        -- Check required fields
        if type(equipData) ~= "table" then
            warn("MigrationUtils: Invalid equipment data for ID", id, "- expected table")
            isValid = false
            continue
        end
        
        -- Validate required fields
        if not equipData.id then 
            warn("MigrationUtils: Missing ID in equipment data", id)
            isValid = false
        end
        
        if type(equipData.level) ~= "number" then
            warn("MigrationUtils: Invalid level for equipment", id)
            isValid = false
        end
        
        -- Check attributes
        if equipData.attributes and type(equipData.attributes) ~= "table" then
            warn("MigrationUtils: Invalid attributes for equipment", id)
            isValid = false
        end
    end
    
    return isValid
end

--[[
    Validates tile data structure and logs issues
    @param data table - The tile data to validate
    @return boolean - Whether the data is valid
]]
function MigrationUtils.ValidateTileData(data)
    local isValid = true
    
    for id, tileData in pairs(data) do
        -- Check required fields
        if type(tileData) ~= "table" then
            warn("MigrationUtils: Invalid tile data for ID", id, "- expected table")
            isValid = false
            continue
        end
        
        -- Validate required fields
        if not tileData.id then 
            warn("MigrationUtils: Missing ID in tile data", id)
            isValid = false
        end
        
        if type(tileData.purchased) ~= "boolean" then
            warn("MigrationUtils: Invalid purchased status for tile", id)
            isValid = false
        end
    end
    
    return isValid
end

--[[
    Validates progression data structure and logs issues
    @param data table - The progression data to validate
    @return boolean - Whether the data is valid
]]
function MigrationUtils.ValidateProgressionData(data)
    local isValid = true
    
    -- Validate floors
    if not data.floors or type(data.floors) ~= "table" then
        warn("MigrationUtils: Missing or invalid floors data")
        isValid = false
    end
    
    -- Check floor entries
    for floorId, floorData in pairs(data.floors or {}) do
        if type(floorData) ~= "table" then
            warn("MigrationUtils: Invalid floor data for floor", floorId)
            isValid = false
            continue
        end
        
        if type(floorData.unlocked) ~= "boolean" then
            warn("MigrationUtils: Invalid unlocked status for floor", floorId)
            isValid = false
        end
    end
    
    return isValid
end

-- Rollback Functions
--[[
    Rolls back to the original data if migration fails
    @param dataType string - The type of data to roll back
    @return table - The original data
]]
function MigrationUtils.RollbackMigration(dataType)
    if not ENABLE_ROLLBACK then
        warn("MigrationUtils: Rollback is disabled")
        return nil
    end
    
    local originalData = originalDataStore[dataType]
    if not originalData then
        warn("MigrationUtils: No original data found for", dataType)
        return nil
    end
    
    print("MigrationUtils: Rolling back", dataType, "to original state")
    return originalData
end

--[[
    Clears stored original data to free memory
    @param dataType string - The type of data to clear, or nil to clear all
]]
function MigrationUtils.ClearOriginalData(dataType)
    if dataType then
        originalDataStore[dataType] = nil
    else
        originalDataStore = {}
    end
end

return MigrationUtils
