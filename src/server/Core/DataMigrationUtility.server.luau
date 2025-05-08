--!strict
--[[
    DataMigrationUtility.server.luau
    
    Enhanced data migration utility that handles data format changes,
    versioning, and migration between different data formats.
    
    Features:
    - Version-based data migration
    - Automatic schema validation
    - Migration rollback support
    - Migration history tracking
    - Detailed error reporting
    - Multiple migration strategies
    - Data transformation pipelines
    - Migration verification
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Import required modules
local CoreRegistry = require(script.Parent:WaitForChild("CoreRegistry_enhanced"))
local DataAccessLayer = require(script.Parent:WaitForChild("DataAccessLayer"))

-- Configuration
local CONFIG = {
    debug = true,
    currentVersion = 2,
    migrationTimeout = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds
    backupBeforeMigration = true,
    schemaValidation = true,
    -- Data schemas for each version
    schemas = {
        [1] = {
            required = {
                "version",
                "cash",
                "experience",
                "level",
                "ownedItems",
                "stats",
                "settings"
            },
            types = {
                version = "number",
                cash = "number",
                experience = "number",
                level = "number",
                ownedItems = "table",
                stats = "table",
                settings = "table"
            }
        },
        [2] = {
            required = {
                "version",
                "cash",
                "experience",
                "level",
                "ownedItems",
                "stats",
                "settings",
                "achievements",
                "lastLogin"
            },
            types = {
                version = "number",
                cash = "number",
                experience = "number",
                level = "number",
                ownedItems = "table",
                stats = "table",
                settings = "table",
                achievements = "table",
                lastLogin = "number"
            }
        }
    }
}

-- Migration strategies
local MIGRATION_STRATEGIES = {
    -- Direct migration: Simple field mapping
    DIRECT = function(data, fieldMap)
        local result = table.clone(data)
        for oldField, newField in pairs(fieldMap) do
            if data[oldField] ~= nil then
                result[newField] = data[oldField]
                result[oldField] = nil
            end
        end
        return result
    end,
    
    -- Transform migration: Apply transformation function to fields
    TRANSFORM = function(data, transformations)
        local result = table.clone(data)
        for field, transformFunc in pairs(transformations) do
            if data[field] ~= nil then
                result[field] = transformFunc(data[field])
            end
        end
        return result
    end,
    
    -- Merge migration: Combine multiple fields into one
    MERGE = function(data, mergeConfig)
        local result = table.clone(data)
        for newField, sourceFields in pairs(mergeConfig) do
            local mergedValue = {}
            for _, sourceField in ipairs(sourceFields) do
                if data[sourceField] then
                    if type(data[sourceField]) == "table" then
                        for k, v in pairs(data[sourceField]) do
                            mergedValue[k] = v
                        end
                    else
                        mergedValue[sourceField] = data[sourceField]
                    end
                    result[sourceField] = nil
                end
            end
            result[newField] = mergedValue
        end
        return result
    end,
    
    -- Split migration: Split one field into multiple fields
    SPLIT = function(data, splitConfig)
        local result = table.clone(data)
        for sourceField, targetFields in pairs(splitConfig) do
            if data[sourceField] then
                for newField, extractFunc in pairs(targetFields) do
                    result[newField] = extractFunc(data[sourceField])
                end
                result[sourceField] = nil
            end
        end
        return result
    end,
    
    -- Default migration: Set default values for new fields
    DEFAULT = function(data, defaults)
        local result = table.clone(data)
        for field, defaultValue in pairs(defaults) do
            if result[field] == nil then
                result[field] = type(defaultValue) == "function" and defaultValue() or defaultValue
            end
        end
        return result
    end
}

-- Migration utility state
local migration = {
    initialized = false,
    version = "1.0.0",
    migrations = {},
    history = {},
    verificationResults = {},
    stats = {
        totalMigrations = 0,
        successfulMigrations = 0,
        failedMigrations = 0,
        rollbacks = 0,
        verifications = 0,
        verificationFailures = 0
    }
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[DataMigrationUtility][%s] %s", level, message))
end

-- Validate data against schema
local function validateData(data, version)
    if not CONFIG.schemaValidation then
        return true
    end
    
    local schema = CONFIG.schemas[version]
    if not schema then
        log("No schema found for version " .. version, "Error")
        return false
    end
    
    -- Check required fields
    for _, field in ipairs(schema.required) do
        if data[field] == nil then
            log("Missing required field: " .. field, "Error")
            return false
        end
    end
    
    -- Check field types
    for field, expectedType in pairs(schema.types) do
        if data[field] ~= nil then
            local actualType = typeof(data[field])
            if actualType ~= expectedType then
                log("Invalid type for field " .. field .. ": expected " .. expectedType .. ", got " .. actualType, "Error")
                return false
            end
        end
    end
    
    return true
end

-- Create backup of data
local function createBackup(data, userId)
    if not CONFIG.backupBeforeMigration then
        return true
    end
    
    local backupKey = "backup_" .. userId .. "_" .. os.time()
    local success = DataAccessLayer.saveData("Backups", backupKey, data)
    
    if success then
        log("Created backup: " .. backupKey)
        return true
    else
        log("Failed to create backup", "Error")
        return false
    end
end

-- Verify migrated data
local function verifyMigration(data, fromVersion, toVersion)
    -- Basic verification
    if not data then
        return false, "No data to verify"
    end
    
    -- Version check
    if data.version ~= toVersion then
        return false, "Version mismatch"
    end
    
    -- Schema validation
    if not validateData(data, toVersion) then
        return false, "Schema validation failed"
    end
    
    -- Data integrity checks
    local integrityChecks = {
        -- Check for required fields
        function(data)
            for _, field in ipairs(CONFIG.schemas[toVersion].required) do
                if data[field] == nil then
                    return false, "Missing required field: " .. field
                end
            end
            return true
        end,
        
        -- Check for data type consistency
        function(data)
            for field, expectedType in pairs(CONFIG.schemas[toVersion].types) do
                if data[field] ~= nil and typeof(data[field]) ~= expectedType then
                    return false, "Invalid type for field " .. field
                end
            end
            return true
        end,
        
        -- Check for data value ranges
        function(data)
            if data.cash and data.cash < 0 then
                return false, "Invalid cash value"
            end
            if data.experience and data.experience < 0 then
                return false, "Invalid experience value"
            end
            if data.level and data.level < 1 then
                return false, "Invalid level value"
            end
            return true
        end
    }
    
    -- Run all integrity checks
    for _, check in ipairs(integrityChecks) do
        local success, error = check(data)
        if not success then
            return false, error
        end
    end
    
    return true
end

-- Apply migration strategy
local function applyMigrationStrategy(data, strategy, config)
    local strategyFunc = MIGRATION_STRATEGIES[strategy]
    if not strategyFunc then
        return nil, "Unknown migration strategy: " .. strategy
    end
    
    local success, result = pcall(function()
        return strategyFunc(data, config)
    end)
    
    if not success then
        return nil, "Strategy application failed: " .. tostring(result)
    end
    
    return result
end

-- Migrate data from one version to another
local function migrateData(data, fromVersion, toVersion)
    if fromVersion == toVersion then
        return data
    end
    
    -- Create backup
    if not createBackup(data, data.userId) then
        return nil
    end
    
    -- Apply migrations in order
    for version = fromVersion + 1, toVersion do
        local migrationConfig = migration.migrations[version]
        if migrationConfig then
            -- Apply each strategy in the pipeline
            for _, strategyConfig in ipairs(migrationConfig) do
                local success, result = pcall(function()
                    return applyMigrationStrategy(data, strategyConfig.strategy, strategyConfig.config)
                end)
                
                if not success then
                    log("Migration failed for version " .. version .. ": " .. tostring(result), "Error")
                    return nil
                end
                
                data = result
            end
            
            data.version = version
            
            -- Verify migration
            local verified, error = verifyMigration(data, fromVersion, version)
            if not verified then
                log("Migration verification failed: " .. error, "Error")
                return nil
            end
            
            -- Record verification
            migration.stats.verifications += 1
            table.insert(migration.verificationResults, {
                userId = data.userId,
                fromVersion = fromVersion,
                toVersion = version,
                timestamp = os.time(),
                success = true
            })
        end
    end
    
    return data
end

-- Rollback migration
local function rollbackMigration(userId, backupKey)
    local success, backupData = pcall(function()
        return DataAccessLayer.loadData("Backups", backupKey)
    end)
    
    if not success or not backupData then
        log("Failed to load backup: " .. backupKey, "Error")
        return false
    end
    
    -- Restore data
    success = DataAccessLayer.saveData("PlayerData", userId, backupData)
    
    if success then
        migration.stats.rollbacks += 1
        log("Successfully rolled back migration for user " .. userId)
        return true
    else
        log("Failed to restore backup data", "Error")
        return false
    end
end

-- Register migration function
function migration:registerMigration(version, strategies)
    if type(strategies) ~= "table" then
        log("Invalid migration strategies for version " .. version, "Error")
        return false
    end
    
    -- Validate each strategy
    for _, strategyConfig in ipairs(strategies) do
        if not MIGRATION_STRATEGIES[strategyConfig.strategy] then
            log("Unknown migration strategy: " .. strategyConfig.strategy, "Error")
            return false
        end
    end
    
    self.migrations[version] = strategies
    log("Registered migration pipeline for version " .. version)
    return true
end

-- Migrate player data
function migration:migratePlayerData(player)
    if not player or not player.UserId then
        log("Invalid player", "Error")
        return false
    end
    
    local userId = player.UserId
    self.stats.totalMigrations += 1
    
    -- Load current data
    local success, data = pcall(function()
        return DataAccessLayer:GetPlayerData(player)
    end)
    
    if not success or not data then
        log("Failed to load player data for migration", "Error")
        self.stats.failedMigrations += 1
        return false
    end
    
    -- Check if migration is needed
    local currentVersion = data.version or 1
    if currentVersion >= CONFIG.currentVersion then
        return true
    end
    
    -- Perform migration
    local migratedData = migrateData(data, currentVersion, CONFIG.currentVersion)
    if not migratedData then
        self.stats.failedMigrations += 1
        return false
    end
    
    -- Save migrated data
    success = pcall(function()
        return DataAccessLayer:SavePlayerData(player, migratedData)
    end)
    
    if success then
        self.stats.successfulMigrations += 1
        log("Successfully migrated data for player " .. player.Name)
        
        -- Record migration in history
        table.insert(self.history, {
            userId = userId,
            fromVersion = currentVersion,
            toVersion = CONFIG.currentVersion,
            timestamp = os.time(),
            success = true
        })
        
        return true
    else
        self.stats.failedMigrations += 1
        log("Failed to save migrated data", "Error")
        return false
    end
end

-- Get migration history
function migration:getMigrationHistory(userId)
    if userId then
        local userHistory = {}
        for _, record in ipairs(self.history) do
            if record.userId == userId then
                table.insert(userHistory, record)
            end
        end
        return userHistory
    end
    return self.history
end

-- Get migration statistics
function migration:getStats()
    return {
        totalMigrations = self.stats.totalMigrations,
        successfulMigrations = self.stats.successfulMigrations,
        failedMigrations = self.stats.failedMigrations,
        rollbacks = self.stats.rollbacks
    }
end

-- Initialize migration utility
function migration:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataMigrationUtility v" .. self.version)
    
    -- Register default migrations
    self:registerMigration(2, {
        {
            strategy = "DEFAULT",
            config = {
                achievements = {},
                lastLogin = os.time
            }
        },
        {
            strategy = "TRANSFORM",
            config = {
                stats = function(stats)
                    stats.totalPlayTime = stats.totalPlayTime or 0
                    stats.totalVisitors = stats.totalVisitors or 0
                    stats.tilesUnlocked = stats.tilesUnlocked or 0
                    return stats
                end
            }
        }
    })
    
    self.initialized = true
    log("DataMigrationUtility initialized successfully")
    return true
end

-- Initialize the migration utility
migration:initialize()

return migration

