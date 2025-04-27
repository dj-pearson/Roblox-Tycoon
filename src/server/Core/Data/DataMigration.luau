--!strict
--[[
    DataMigration.luau
    
    Provides tools for migrating data between different formats and versions.
    Handles schema changes, data transformations, and ensures backward compatibility.
    
    Features:
    - Version-to-version migration
    - Schema validation and repair
    - Data transformation utilities
    - Automatic migration detection
    - Migration tracking and logging
    
    Author: Updated April 27, 2025
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local ServerScripts = script.Parent.Parent
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")

local DataTypes = require(SharedModules:WaitForChild("Data"):WaitForChild("DataTypes"))
local DataConstants = require(SharedModules:WaitForChild("Data"):WaitForChild("DataConstants"))

-- Module and state variables
local DataMigration = {}
local migrations = {}
local migrationTracking = {}

--[[ Private Utility Functions ]]--

-- Check if data needs migration based on version
local function needsMigration(scope, data)
    if not data or type(data) ~= "table" then
        return true, "Invalid data format"
    end
    
    -- Check if data has a version field
    if not data.version then
        return true, "No version information"
    end
    
    -- Get latest version for this scope
    local latestVersion = DataMigration:getLatestVersion(scope)
    
    -- Compare versions
    if data.version ~= latestVersion then
        return true, "Version mismatch: " .. tostring(data.version) .. " vs " .. latestVersion
    end
    
    return false, ""
end

-- Parse version string into components
local function parseVersion(versionString)
    local major, minor, patch = string.match(versionString, "(%d+)%.(%d+)%.(%d+)")
    
    if not major then
        return 0, 0, 0
    end
    
    return tonumber(major), tonumber(minor), tonumber(patch)
end

-- Compare two version strings
local function compareVersions(version1, version2)
    local major1, minor1, patch1 = parseVersion(version1)
    local major2, minor2, patch2 = parseVersion(version2)
    
    if major1 > major2 then
        return 1
    elseif major1 < major2 then
        return -1
    elseif minor1 > minor2 then
        return 1
    elseif minor1 < minor2 then
        return -1
    elseif patch1 > patch2 then
        return 1
    elseif patch1 < patch2 then
        return -1
    else
        return 0
    end
end

-- Track migration for analytics
local function trackMigration(userId, scope, fromVersion, toVersion, success)
    if not migrationTracking[userId] then
        migrationTracking[userId] = {}
    end
    
    table.insert(migrationTracking[userId], {
        scope = scope,
        fromVersion = fromVersion,
        toVersion = toVersion,
        timestamp = os.time(),
        success = success
    })
    
    -- TODO: Persist migration tracking data
end

-- Check if a field exists in the schema
local function fieldExistsInSchema(schemaName, fieldName)
    local schema = DataTypes.Schemas[schemaName]
    return schema and schema[fieldName] ~= nil
end

-- Apply migration steps in order
local function applyMigrations(data, scope, fromVersion, toVersion)
    local currentVersion = fromVersion
    local currentData = data
    
    -- Get all migrations for this scope
    local scopeMigrations = migrations[scope] or {}
    
    -- Sort migrations by fromVersion
    table.sort(scopeMigrations, function(a, b)
        return compareVersions(a.fromVersion, b.fromVersion) < 0
    end)
    
    -- Apply each migration that applies to our version range
    for _, migration in ipairs(scopeMigrations) do
        if compareVersions(migration.fromVersion, currentVersion) >= 0 and
           compareVersions(migration.toVersion, toVersion) <= 0 then
            
            -- Apply the migration
            local success, result = pcall(function()
                return migration.migrate(currentData)
            end)
            
            if success then
                currentData = result
                currentVersion = migration.toVersion
            else
                warn("Migration failed:", result)
                return false, currentData, "Migration failed: " .. tostring(result)
            end
        end
    end
    
    -- Ensure the version is updated
    if type(currentData) == "table" then
        currentData.version = toVersion
    end
    
    return true, currentData, ""
end

--[[ Public API Functions ]]--

-- Register a migration function
function DataMigration:registerMigration(scope, fromVersion, toVersion, migrateFunction)
    if not scope or not fromVersion or not toVersion or not migrateFunction then
        warn("Invalid migration registration parameters")
        return false
    end
    
    if not migrations[scope] then
        migrations[scope] = {}
    end
    
    table.insert(migrations[scope], {
        fromVersion = fromVersion,
        toVersion = toVersion,
        migrate = migrateFunction
    })
    
    return true
end

-- Get latest version for a scope
function DataMigration:getLatestVersion(scope)
    if scope == "core" or scope == DataConstants.PLAYER_SCOPES.CORE then
        return DataConstants.STORAGE_VERSION
    elseif scope == "settings" or scope == DataConstants.PLAYER_SCOPES.SETTINGS then
        return DataConstants.STORAGE_VERSION
    elseif scope == "inventory" or scope == DataConstants.PLAYER_SCOPES.INVENTORY then
        return DataConstants.STORAGE_VERSION
    elseif scope == "stats" or scope == DataConstants.PLAYER_SCOPES.STATS then
        return DataConstants.STORAGE_VERSION
    elseif scope == "achievements" or scope == DataConstants.PLAYER_SCOPES.ACHIEVEMENTS then
        return DataConstants.STORAGE_VERSION
    elseif scope == "quests" or scope == DataConstants.PLAYER_SCOPES.QUESTS then
        return DataConstants.STORAGE_VERSION
    elseif scope == "social" or scope == DataConstants.PLAYER_SCOPES.SOCIAL then
        return DataConstants.STORAGE_VERSION
    else
        -- Default for custom scopes
        return DataConstants.STORAGE_VERSION
    end
end

-- Check if data needs migration
function DataMigration:checkMigration(scope, data)
    return needsMigration(scope, data)
end

-- Migrate data to the latest version
function DataMigration:migrateData(scope, data)
    if not scope or not data then
        return false, data
    end
    
    local needsMigrate, reason = self:checkMigration(scope, data)
    
    if not needsMigrate then
        return false, data
    end
    
    local fromVersion = (type(data) == "table" and data.version) or "0.0.0"
    local toVersion = self:getLatestVersion(scope)
    
    local success, migratedData, errorMsg = applyMigrations(data, scope, fromVersion, toVersion)
    
    if not success then
        warn("Failed to migrate data for scope", scope, ":", errorMsg)
        return false, data
    end
    
    -- Apply schema validation if appropriate
    if scope == DataConstants.PLAYER_SCOPES.CORE then
        local valid, validationError = DataTypes.validate(migratedData, "PlayerData")
        
        if not valid then
            warn("Migrated data failed validation:", validationError)
            
            -- Attempt to sanitize
            local sanitized = DataTypes.sanitize(migratedData, "PlayerData")
            
            if sanitized then
                migratedData = sanitized
            else
                return false, data
            end
        end
    end
    
    -- Track successful migration
    if type(data) == "table" and data.userId then
        trackMigration(data.userId, scope, fromVersion, toVersion, true)
    end
    
    return true, migratedData
end

-- Add a missing field with default value
function DataMigration:addMissingField(data, schemaName, fieldName)
    if not data or type(data) ~= "table" then
        return data
    end
    
    if data[fieldName] ~= nil then
        return data
    end
    
    if not fieldExistsInSchema(schemaName, fieldName) then
        return data
    end
    
    -- Get default value from schema defaults
    local defaultData = DataTypes.create(schemaName)
    
    if defaultData and defaultData[fieldName] ~= nil then
        data[fieldName] = DataTypes.deepCopy(defaultData[fieldName])
    end
    
    return data
end

-- Rename a field
function DataMigration:renameField(data, oldField, newField)
    if not data or type(data) ~= "table" then
        return data
    end
    
    if data[oldField] == nil then
        return data
    end
    
    data[newField] = data[oldField]
    data[oldField] = nil
    
    return data
end

-- Transform a field using a function
function DataMigration:transformField(data, fieldName, transformFunction)
    if not data or type(data) ~= "table" or not fieldName or not transformFunction then
        return data
    end
    
    if data[fieldName] == nil then
        return data
    end
    
    local success, result = pcall(function()
        return transformFunction(data[fieldName])
    end)
    
    if success then
        data[fieldName] = result
    else
        warn("Field transformation failed:", result)
    end
    
    return data
end

-- Remove a field that is no longer needed
function DataMigration:removeField(data, fieldName)
    if not data or type(data) ~= "table" or not fieldName then
        return data
    end
    
    data[fieldName] = nil
    return data
end

-- Upgrade a version number without changing data
function DataMigration:upgradeVersion(data, newVersion)
    if not data or type(data) ~= "table" then
        return data
    end
    
    data.version = newVersion
    return data
end

-- Get migration history for a user
function DataMigration:getMigrationHistory(userId)
    return migrationTracking[userId] or {}
end

--[[ Default Migrations ]]--

-- From version 0.0.0 (no version) to 1.0.0
DataMigration:registerMigration(DataConstants.PLAYER_SCOPES.CORE, "0.0.0", "1.0.0", function(data)
    if not data or type(data) ~= "table" then
        -- If no data or invalid, create new data
        return DataTypes.create("PlayerData")
    end
    
    -- Add missing fields with defaults
    data = DataMigration:addMissingField(data, "PlayerData", "cash")
    data = DataMigration:addMissingField(data, "PlayerData", "gymLevel")
    data = DataMigration:addMissingField(data, "PlayerData", "rebirthLevel")
    data = DataMigration:addMissingField(data, "PlayerData", "experience")
    data = DataMigration:addMissingField(data, "PlayerData", "inventory")
    data = DataMigration:addMissingField(data, "PlayerData", "lastSeen")
    data = DataMigration:addMissingField(data, "PlayerData", "loginStreak")
    data = DataMigration:addMissingField(data, "PlayerData", "settings")
    data = DataMigration:addMissingField(data, "PlayerData", "tutorial")
    
    -- Rename legacy fields if they exist
    if data.currency ~= nil then
        data = DataMigration:renameField(data, "currency", "cash")
    end
    
    if data.level ~= nil then
        data = DataMigration:renameField(data, "level", "gymLevel")
    end
    
    if data.rebirths ~= nil then
        data = DataMigration:renameField(data, "rebirths", "rebirthLevel")
    end
    
    -- Update settings structure
    if data.settings and type(data.settings) == "table" then
        if data.settings.soundEnabled ~= nil then
            -- Convert boolean to volume level
            data.settings.sound = data.settings.soundEnabled and 0.5 or 0
            data.settings.soundEnabled = nil
        end
        
        if data.settings.musicEnabled ~= nil then
            -- Convert boolean to volume level
            data.settings.music = data.settings.musicEnabled and 0.5 or 0
            data.settings.musicEnabled = nil
        end
    end
    
    -- Add version
    data.version = "1.0.0"
    
    return data
end))

-- Initialize default migrations for other scopes
for _, scope in pairs(DataConstants.PLAYER_SCOPES) do
    if scope ~= DataConstants.PLAYER_SCOPES.CORE and not migrations[scope] then
        DataMigration:registerMigration(scope, "0.0.0", DataConstants.STORAGE_VERSION, function(data)
            if not data or type(data) ~= "table" then
                return {}
            end
            
            -- Add version
            data.version = DataConstants.STORAGE_VERSION
            
            return data
        end)
    end
end

return DataMigration
