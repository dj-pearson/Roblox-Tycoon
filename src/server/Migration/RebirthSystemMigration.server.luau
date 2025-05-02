--!strict
-- RebirthSystemMigration.server.luau
-- Utility module to assist in migrating from legacy rebirth systems to the new consolidated system
-- Created: May 2, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import Registry systems
local ServerRegistry = require(ServerScriptService.Core.Registry.ServerRegistry)
local EventBridge = ServerRegistry.getSystem("EventBridge")
local DataManager = ServerRegistry.getSystem("DataManager")
local TelemetrySystem = ServerRegistry.getSystem("TelemetrySystem")

-- Import new rebirth system
local NewRebirthSystem = require(script.Parent.Parent.Systems.Rebirth.RebirthSystem)
local RebirthData = require(script.Parent.Parent.Systems.Rebirth.RebirthData)

-- Configuration
local DEBUG_MODE = true
local CONFIG = {
    -- Path to legacy systems
    legacyCorePath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("RebirthSystem"),
    legacyEnhancedPath = ServerScriptService:FindFirstChild("Enhancements"):FindFirstChild("RebirthSystem"),
    
    -- Data keys
    legacyDataKeys = {
        "RebirthData",
        "GymRebirth",
        "Rebirth_Data",
        "EnhancedRebirth"
    },
    
    -- Migration settings
    autoMigrateData = true,
    preserveLegacyData = true,
    migrationTimeout = 30, -- seconds
    
    -- Telemetry settings
    reportMigrations = true,
    
    -- Feature mapping for legacy versions
    featureMapping = {
        -- Legacy enhanced system
        ["PREMIUM_EQUIPMENT"] = "premiumEquipment",
        ["VIP_ACCESS"] = "vipAccess",
        ["EXECUTIVE_OFFICE"] = "execOffice",
        ["CUSTOM_THEMES"] = "customThemes",
        ["PREMIUM_STAFF"] = "premiumStaff",
        ["EXCLUSIVE_MARKETING"] = "marketing",
        
        -- Legacy core system
        ["PREMIUM_EQUIPMENT"] = "equipment_premium",
        ["VIP_ACCESS"] = "vip_access",
        ["EXECUTIVE_OFFICE"] = "office_executive",
    }
}

-- Debug logging
local function logDebug(...)
    if DEBUG_MODE then
        print("[RebirthMigration]", ...)
    end
}

-- The migration manager
local RebirthSystemMigration = {}

-- Attempt to load legacy systems for compatibility
function RebirthSystemMigration:_loadLegacySystems()
    local legacySystems = {}
    
    -- Try to load the core system
    if CONFIG.legacyCorePath then
        pcall(function()
            legacySystems.core = require(CONFIG.legacyCorePath)
            logDebug("Loaded legacy core system")
        end)
    end
    
    -- Try to load the enhanced system
    if CONFIG.legacyEnhancedPath then
        pcall(function()
            legacySystems.enhanced = require(CONFIG.legacyEnhancedPath)
            logDebug("Loaded legacy enhanced system")
        end)
    end
    
    return legacySystems
}

-- Identify the best legacy system to use for migrations
function RebirthSystemMigration:_identifyActiveLegacySystem(legacySystems)
    -- Prefer enhanced system if it has more data
    if legacySystems.enhanced and typeof(legacySystems.enhanced) == "table" and 
       legacySystems.enhanced.GetRebirthLevel and legacySystems.enhanced.GetRebirthCost then
        return "enhanced", legacySystems.enhanced
    end
    
    -- Fall back to core system
    if legacySystems.core and typeof(legacySystems.core) == "table" and 
       legacySystems.core.GetRebirthLevel then
        return "core", legacySystems.core
    end
    
    return nil, nil
}

-- Extract rebirth data from a legacy system for a player
function RebirthSystemMigration:_extractLegacyData(player, legacySystem, legacyType)
    -- Default structure
    local legacyData = {
        level = 0,
        totalRebirths = 0,
        unlockedFeatures = {},
        lastRebirthTime = 0,
        rebirthMultiplier = 1
    }
    
    -- Enhanced system data extraction
    if legacyType == "enhanced" and legacySystem then
        pcall(function()
            -- Get basic rebirth data
            legacyData.level = legacySystem.GetRebirthLevel(player) or 0
            legacyData.totalRebirths = legacySystem.GetTotalRebirths(player) or legacyData.level or 0
            legacyData.rebirthMultiplier = legacySystem.GetRebirthMultiplier(player) or 1
            
            -- Try to get last rebirth time
            if legacySystem.GetLastRebirthTime then
                legacyData.lastRebirthTime = legacySystem.GetLastRebirthTime(player) or 0
            end
            
            -- Try to get unlocked features
            if legacySystem.GetUnlockedFeatures then
                local features = legacySystem.GetUnlockedFeatures(player)
                if typeof(features) == "table" then
                    for _, feature in ipairs(features) do
                        -- Convert legacy feature names to new format
                        local newFeatureId = self:_mapLegacyFeature(feature, "enhanced")
                        if newFeatureId then
                            legacyData.unlockedFeatures[newFeatureId] = true
                        end
                    end
                end
            else
                -- Infer unlocked features from rebirth level
                for newFeatureId, legacyName in pairs(CONFIG.featureMapping) do
                    -- Check if this should be unlocked based on level
                    if legacyData.level >= self:_getRequiredLevelForFeature(newFeatureId) then
                        legacyData.unlockedFeatures[newFeatureId] = true
                    end
                end
            end
        end)
    end
    
    -- Core system data extraction (more limited)
    if legacyType == "core" and legacySystem then
        pcall(function()
            -- Basic data
            legacyData.level = legacySystem.GetRebirthLevel(player) or 0
            legacyData.totalRebirths = legacySystem.GetTotalRebirths and legacySystem.GetTotalRebirths(player) or legacyData.level
            
            -- Most core systems don't store multiplier directly, infer it
            if legacySystem.GetRebirthMultiplier then
                legacyData.rebirthMultiplier = legacySystem.GetRebirthMultiplier(player) or 1
            else
                legacyData.rebirthMultiplier = 1 + (legacyData.level * 0.2) -- Assume 20% per level
            end
            
            -- Infer unlocked features from level
            for newFeatureId, legacyName in pairs(CONFIG.featureMapping) do
                if legacyData.level >= self:_getRequiredLevelForFeature(newFeatureId) then
                    legacyData.unlockedFeatures[newFeatureId] = true
                end
            end
        end)
    end
    
    return legacyData
}

-- Map a legacy feature name to the new format
function RebirthSystemMigration:_mapLegacyFeature(legacyName, legacyType)
    -- Direct mapping if possible
    for newName, oldName in pairs(CONFIG.featureMapping) do
        if oldName == legacyName then
            return newName
        end
    end
    
    -- Fuzzy matching for similar names
    for newName, oldName in pairs(CONFIG.featureMapping) do
        -- Simple check for substring
        if string.find(string.lower(legacyName), string.lower(oldName)) then
            return newName
        end
    end
    
    return nil
}

-- Get the required level for a feature in the new system
function RebirthSystemMigration:_getRequiredLevelForFeature(featureId)
    -- Reference to UnlockManager
    local UnlockManager = require(script.Parent.Parent.Systems.Rebirth.UnlockManager)
    local feature = UnlockManager:GetFeatureDetails(featureId)
    
    if feature then
        return feature.requiredLevel
    end
    
    -- Default levels for common features if UnlockManager isn't available
    local defaultLevels = {
        PREMIUM_EQUIPMENT = 1,
        VIP_ACCESS = 3,
        EXECUTIVE_OFFICE = 5,
        CUSTOM_THEMES = 10,
        PREMIUM_STAFF = 15,
        EXCLUSIVE_MARKETING = 20
    }
    
    return defaultLevels[featureId] or 1
}

-- Look up rebirth data from legacy data stores
function RebirthSystemMigration:_findLegacyDataStoreData(player)
    if not DataManager then
        return nil
    end
    
    for _, dataKey in ipairs(CONFIG.legacyDataKeys) do
        local data = DataManager:GetPlayerData(player, dataKey)
        if data and type(data) == "table" then
            -- Check if this has rebirth-related fields
            if data.rebirthLevel or data.level or data.rebirth then
                logDebug("Found legacy data in key:", dataKey)
                return data, dataKey
            end
        end
    end
    
    return nil, nil
}

-- Convert legacy data store format to the new format
function RebirthSystemMigration:_convertLegacyDataStoreData(data)
    if not data or type(data) ~= "table" then
        return nil
    end
    
    -- Create a new state object
    local state = {
        level = data.rebirthLevel or data.level or data.rebirth or 0,
        totalRebirths = data.totalRebirths or data.rebirths or data.rebirth_count or 0,
        unlockedFeatures = {},
        lastRebirthTime = data.lastRebirthTime or data.timestamp or 0,
        rebirthMultiplier = data.rebirthMultiplier or data.multiplier or 1,
    }
    
    -- Ensure total rebirths is at least equal to level
    state.totalRebirths = math.max(state.level, state.totalRebirths)
    
    -- Convert unlocked features
    if type(data.unlockedFeatures) == "table" then
        for featureId, unlocked in pairs(data.unlockedFeatures) do
            if unlocked == true then
                state.unlockedFeatures[featureId] = true
            end
        end
    elseif type(data.unlocks) == "table" then
        for featureId, unlocked in pairs(data.unlocks) do
            if unlocked == true then
                local newFeatureId = self:_mapLegacyFeature(featureId, "datastore")
                if newFeatureId then
                    state.unlockedFeatures[newFeatureId] = true
                end
            end
        end
    elseif type(data.features) == "table" then
        for _, featureId in ipairs(data.features) do
            local newFeatureId = self:_mapLegacyFeature(featureId, "datastore")
            if newFeatureId then
                state.unlockedFeatures[newFeatureId] = true
            end
        end
    end
    
    return state
}

-- Migrate a player's rebirth data from legacy to new system
function RebirthSystemMigration:MigratePlayer(player)
    if not player or not player:IsA("Player") then
        return false, "Invalid player"
    end
    
    logDebug("Starting migration for player:", player.Name)
    
    -- Step 1: Attempt to extract data from running legacy systems
    local legacySystems = self:_loadLegacySystems()
    local legacyType, activeLegacySystem = self:_identifyActiveLegacySystem(legacySystems)
    
    local legacyData
    if legacyType and activeLegacySystem then
        legacyData = self:_extractLegacyData(player, activeLegacySystem, legacyType)
        logDebug("Extracted data from legacy", legacyType, "system")
    end
    
    -- Step 2: Check for data in legacy data stores
    local dataStoreData, dataStoreKey = self:_findLegacyDataStoreData(player)
    local convertedData
    
    if dataStoreData then
        convertedData = self:_convertLegacyDataStoreData(dataStoreData)
        logDebug("Converted data from legacy data store:", dataStoreKey)
    end
    
    -- Step 3: Determine best data source
    local finalData
    
    -- If both sources exist, use the one with higher level
    if legacyData and convertedData then
        if convertedData.level > legacyData.level then
            finalData = convertedData
            logDebug("Using data store data (higher level)")
        else
            finalData = legacyData
            logDebug("Using runtime legacy system data (higher or equal level)")
        end
    elseif legacyData then
        finalData = legacyData
        logDebug("Using runtime legacy system data (only source)")
    elseif convertedData then
        finalData = convertedData
        logDebug("Using data store data (only source)")
    else
        logDebug("No legacy data found, migration not needed")
        return false, "No legacy data found"
    end
    
    -- Step 4: Save to new system
    if finalData then
        -- Convert to the new format
        local serialized = RebirthData.serialize(finalData)
        
        -- Save to new data store
        if DataManager then
            DataManager:SetPlayerData(player, "Rebirth_v2", serialized)
            logDebug("Saved migrated data to new data store")
        end
        
        -- Report telemetry
        if TelemetrySystem and CONFIG.reportMigrations then
            TelemetrySystem:ReportEvent("RebirthMigrationCompleted", {
                player = player.Name,
                sourceType = legacyType or "datastore",
                sourceKey = dataStoreKey,
                level = finalData.level,
                featuresCount = self:_countFeatures(finalData.unlockedFeatures)
            })
        end
        
        return true, "Migration successful"
    end
    
    return false, "Failed to generate migration data"
}

-- Count the number of unlocked features
function RebirthSystemMigration:_countFeatures(featuresTable)
    local count = 0
    for _, unlocked in pairs(featuresTable) do
        if unlocked then
            count += 1
        end
    end
    return count
}

-- Initialize migration for all current players
function RebirthSystemMigration:Initialize()
    logDebug("Initializing migration system")
    
    -- Auto-migrate for existing players if enabled
    if CONFIG.autoMigrateData then
        -- Get all players
        local Players = game:GetService("Players")
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                local success, message = self:MigratePlayer(player)
                logDebug("Auto-migration for", player.Name, ":", success, message)
            end)
        end
        
        -- Set up for future joining players
        Players.PlayerAdded:Connect(function(player)
            task.spawn(function()
                local success, message = self:MigratePlayer(player)
                logDebug("Auto-migration for newly joined", player.Name, ":", success, message)
            end)
        end)
    end
    
    logDebug("Migration system initialized")
    return true
end

-- Public API
local PublicAPI = {
    Initialize = function()
        return RebirthSystemMigration:Initialize()
    end,
    
    MigratePlayer = function(player)
        return RebirthSystemMigration:MigratePlayer(player)
    end,
}

-- Return the API
return PublicAPI
