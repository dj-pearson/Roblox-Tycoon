--!strict
--[[
    DataMigrationUtility.server.luau
    
    A utility module for migrating data between different data systems,
    ensuring safe transitions and backwards compatibility.
    
    Created: April 26, 2025
]]

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Find CoreRegistry
local CoreRegistry
pcall(function()
    CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
end)

-- Module imports
local SafeRequire = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SafeRequire"))
local DataValidator = SafeRequire(ReplicatedStorage.shared.DataValidator)

-- Configuration
local CONFIG = {
    -- General settings
    backupBeforeMigration = true,     -- Create backup before migration
    validateBeforeMigration = true,   -- Validate data before migration
    validateAfterMigration = true,    -- Validate data after migration
    
    -- Migration paths
    migrationPaths = {
        -- Format: {source = "SourceSystem", destination = "DestinationSystem"}
        {source = "EnhancedDataStorageSystem", destination = "DataManager"},
        {source = "DataStorageSystem", destination = "DataManager"},
        {source = "DataManager", destination = "VersionedDataStore"}
    },
    
    -- Legacy system locations
    legacySystemPaths = {
        EnhancedDataStorageSystem = "ServerScriptService.Data.EnhancedDataStorageSystem",
        DataStorageSystem = "ServerScriptService.DataStorageSystem",
        GymTycoonDataManager = "ServerScriptService.GymTycoonDataManager"
    },
    
    -- Security
    adminIdsForMigration = {
        1234567, -- Replace with actual admin IDs
        2345678
    },
    
    -- Debug options
    debug = true,                     -- Enable debug logging
    dryRun = false                    -- Test migrations without saving
}

-- Debug logging
local function log(message)
    if CONFIG.debug then
        print("[DataMigrationUtility] " .. message)
    end
end

-- Deep copy function
local function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    
    return copy
end

-- Module table
local DataMigrationUtility = {
    initialized = false,
    migrationStatus = {},     -- Status of migrations by player: {userId = {inProgress = bool, source = string, destination = string}}
    activeMigrations = 0,     -- Count of active migrations
    completedMigrations = 0,  -- Count of completed migrations
    failedMigrations = 0      -- Count of failed migrations
}

-- Initialize migration utility
function DataMigrationUtility:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataMigrationUtility")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:registerSystem("DataMigrationUtility", self)
        log("Registered with CoreRegistry")
    end
    
    -- Add admin commands if enabled
    self:SetupAdminCommands()
    
    self.initialized = true
    log("DataMigrationUtility initialized")
    return true
end

-- Set up admin commands
function DataMigrationUtility:SetupAdminCommands()
    -- Create a remote function for admin commands
    local adminRemote = Instance.new("RemoteFunction")
    adminRemote.Name = "DataMigrationAdmin"
    adminRemote.Parent = ReplicatedStorage
    
    -- Handle admin commands
    adminRemote.OnServerInvoke = function(player, command, ...)
        -- Check if player is an admin
        local isAdmin = false
        for _, adminId in ipairs(CONFIG.adminIdsForMigration) do
            if player.UserId == adminId then
                isAdmin = true
                break
            end
        end
        
        if not isAdmin then
            log("Non-admin " .. player.Name .. " attempted to use migration command: " .. command)
            return {success = false, message = "Not authorized"}
        end
        
        local args = {...}
        
        -- Process commands
        if command == "StartMigration" then
            local targetPlayer = args[1]
            local source = args[2]
            local destination = args[3]
            
            if not Players:FindFirstChild(targetPlayer) then
                return {success = false, message = "Player not found"}
            end
            
            local player = Players:FindFirstChild(targetPlayer)
            local success, message = self:MigratePlayerData(player, source, destination)
            
            return {success = success, message = message}
        elseif command == "GetStatus" then
            return {
                success = true,
                activeMigrations = self.activeMigrations,
                completedMigrations = self.completedMigrations,
                failedMigrations = self.failedMigrations,
                migrationStatus = self.migrationStatus
            }
        elseif command == "TestMigration" then
            local targetPlayer = args[1]
            local source = args[2]
            local destination = args[3]
            
            if not Players:FindFirstChild(targetPlayer) then
                return {success = false, message = "Player not found"}
            end
            
            local player = Players:FindFirstChild(targetPlayer)
            local oldConfig = CONFIG.dryRun
            CONFIG.dryRun = true
            local success, message = self:MigratePlayerData(player, source, destination)
            CONFIG.dryRun = oldConfig
            
            return {success = success, message = message}
        end
        
        return {success = false, message = "Unknown command"}
    end
    
    log("Admin commands set up")
end

-- Get a system module by name
function DataMigrationUtility:GetSystem(systemName)
    -- Try CoreRegistry first
    if CoreRegistry then
        local system = CoreRegistry.getSystem(systemName)
        if system then
            return system
        end
    end
    
    -- Try direct require
    local pathString = CONFIG.legacySystemPaths[systemName]
    
    if pathString then
        local path = pathString:split(".")
        local instance = game
        
        for _, segment in ipairs(path) do
            instance = instance:FindFirstChild(segment)
            if not instance then
                break
            end
        end
        
        if instance and instance:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(instance)
            end)
            
            if success then
                return result
            end
        end
    end
    
    -- Try standard locations
    local standardLocations = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild(systemName),
        ServerScriptService:FindFirstChild("Data") and ServerScriptService.Data:FindFirstChild(systemName),
        ServerScriptService:FindFirstChild(systemName),
        ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild(systemName),
    }
    
    for _, location in ipairs(standardLocations) do
        if location and location:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(location)
            end)
            
            if success then
                return result
            end
        end
    end
    
    return nil
end

-- Load player data from a specific system
function DataMigrationUtility:LoadDataFromSystem(player, systemName)
    if not player then
        return nil, "Invalid player"
    end
    
    local system = self:GetSystem(systemName)
    if not system then
        return nil, "System not found: " .. systemName
    end
    
    local data
    local userId = player.UserId
    
    -- Extract data based on system type
    if systemName == "EnhancedDataStorageSystem" then
        -- EnhancedDataStorageSystem format
        if system.loadedData and system.loadedData[userId] then
            data = system.loadedData[userId]
        elseif system.loadData then
            data = system.loadData(player)
        end
    elseif systemName == "DataManager" then
        -- DataManager format
        if system.loadedData and system.loadedData[userId] then
            data = system.loadedData[userId]
        elseif system.LoadPlayerData then
            data = system:LoadPlayerData(player)
        elseif system.getPlayerData then
            data = system.getPlayerData(player)
        end
    elseif systemName == "DataStorageSystem" then
        -- Legacy DataStorageSystem format
        if system.loadedData and system.loadedData[userId] then
            data = system.loadedData[userId]
        elseif system.loadData then
            data = system.loadData(player)
        end
    elseif systemName == "VersionedDataStore" then
        -- VersionedDataStore format
        if system.LoadVersion then
            data = system:LoadVersion(player)
        end
    end
    
    if not data then
        return nil, "Failed to load data from " .. systemName
    end
    
    -- Make a deep copy to avoid modifying the original
    return deepCopy(data)
end

-- Save player data to a specific system
function DataMigrationUtility:SaveDataToSystem(player, systemName, data)
    if not player then
        return false, "Invalid player"
    end
    
    if CONFIG.dryRun then
        log("DRY RUN: Would save data to " .. systemName .. " for " .. player.Name)
        return true
    end
    
    local system = self:GetSystem(systemName)
    if not system then
        return false, "System not found: " .. systemName
    end
    
    local success = false
    local userId = player.UserId
    
    -- Save based on system type
    if systemName == "EnhancedDataStorageSystem" then
        -- EnhancedDataStorageSystem format
        if system.loadedData then
            system.loadedData[userId] = data
        end
        
        if system.saveData then
            success = system.saveData(player, true)
        end
    elseif systemName == "DataManager" then
        -- DataManager format
        if system.loadedData then
            system.loadedData[userId] = data
        end
        
        if system.SavePlayerData then
            success = system:SavePlayerData(player, true)
        elseif system.saveData then
            success = system.saveData(player, true)
        end
    elseif systemName == "DataStorageSystem" then
        -- Legacy DataStorageSystem format
        if system.loadedData then
            system.loadedData[userId] = data
        end
        
        if system.saveData then
            success = system.saveData(player)
        end
    elseif systemName == "VersionedDataStore" then
        -- VersionedDataStore format
        if system.CreateVersion then
            local result
            success, result = system:CreateVersion(player, "DataMigration")
        end
    end
    
    if success then
        log("Successfully saved data to " .. systemName .. " for " .. player.Name)
    else
        log("Failed to save data to " .. systemName .. " for " .. player.Name)
    end
    
    return success
end

-- Create a backup before migration
function DataMigrationUtility:CreateBackupBeforeMigration(player, source, data)
    if not player or not CONFIG.backupBeforeMigration then
        return true
    end
    
    local DataBackup = self:GetSystem("DataBackup")
    if not DataBackup then
        log("DataBackup system not found, skipping backup creation")
        return true
    end
    
    log("Creating migration backup for " .. player.Name)
    local success = DataBackup:CreateCriticalBackup(player, "BeforeMigration_From_" .. source)
    
    if not success then
        log("Failed to create backup for " .. player.Name)
    end
    
    return success
end

-- Standardize data format for the target system
function DataMigrationUtility:StandardizeDataFormat(data, source, destination)
    -- Create a copy to work with
    local standardizedData = deepCopy(data)
    
    -- Handle specific format conversions
    if source == "DataStorageSystem" and destination == "DataManager" then
        -- DataStorageSystem to DataManager
        if not standardizedData.dataVersion then
            standardizedData.dataVersion = 1
        end
        
        -- Add timestamps
        standardizedData.__lastModified = os.time()
        
    elseif source == "EnhancedDataStorageSystem" and destination == "DataManager" then
        -- EnhancedDataStorageSystem to DataManager
        -- Format is already compatible, just ensure version
        if not standardizedData.dataVersion then
            standardizedData.dataVersion = 1
        end
        
        -- Add timestamps
        standardizedData.__lastModified = os.time()
        
    elseif source == "DataManager" and destination == "VersionedDataStore" then
        -- DataManager to VersionedDataStore
        -- Add version metadata
        standardizedData.__version = {
            versionNumber = 1,
            timestamp = os.time(),
            reason = "InitialMigration",
            previousVersion = nil
        }
    end
    
    -- Add migration metadata
    standardizedData.__migrationMeta = {
        migratedFrom = source,
        migratedTo = destination,
        timestamp = os.time(),
        originalFormat = source
    }
    
    return standardizedData
end

-- Migrate player data between systems
function DataMigrationUtility:MigratePlayerData(player, source, destination)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    source = source or "EnhancedDataStorageSystem"
    destination = destination or "DataManager"
    
    -- Check if migration already in progress
    if self.migrationStatus[userId] and self.migrationStatus[userId].inProgress then
        return false, "Migration already in progress for " .. player.Name
    end
    
    -- Set up migration status
    self.migrationStatus[userId] = {
        inProgress = true,
        source = source,
        destination = destination,
        startTime = os.time(),
        status = "starting",
        error = nil
    }
    
    -- Increment active migrations
    self.activeMigrations = self.activeMigrations + 1
    
    -- Log start
    log("Starting migration for " .. player.Name .. " from " .. source .. " to " .. destination)
    
    -- Load data from source system
    self.migrationStatus[userId].status = "loading_source"
    local sourceData, loadError = self:LoadDataFromSystem(player, source)
    
    if not sourceData then
        self.migrationStatus[userId].inProgress = false
        self.migrationStatus[userId].status = "failed"
        self.migrationStatus[userId].error = "Failed to load data from source: " .. (loadError or "unknown error")
        
        self.activeMigrations = self.activeMigrations - 1
        self.failedMigrations = self.failedMigrations + 1
        
        log("Migration failed for " .. player.Name .. ": " .. self.migrationStatus[userId].error)
        return false, self.migrationStatus[userId].error
    end
    
    -- Validate source data if needed
    if CONFIG.validateBeforeMigration and DataValidator then
        self.migrationStatus[userId].status = "validating_source"
        local isValid, validatedData = DataValidator.validatePlayerData(sourceData)
        
        if not isValid then
            log("Source data validation failed for " .. player.Name .. ", attempting to use repaired data")
            
            if validatedData then
                sourceData = validatedData
            else
                self.migrationStatus[userId].inProgress = false
                self.migrationStatus[userId].status = "failed"
                self.migrationStatus[userId].error = "Source data validation failed and couldn't be repaired"
                
                self.activeMigrations = self.activeMigrations - 1
                self.failedMigrations = self.failedMigrations + 1
                
                log("Migration failed for " .. player.Name .. ": " .. self.migrationStatus[userId].error)
                return false, self.migrationStatus[userId].error
            end
        end
    end
    
    -- Create backup if configured
    if CONFIG.backupBeforeMigration then
        self.migrationStatus[userId].status = "creating_backup"
        self:CreateBackupBeforeMigration(player, source, sourceData)
    end
    
    -- Standardize data format
    self.migrationStatus[userId].status = "standardizing"
    local standardizedData = self:StandardizeDataFormat(sourceData, source, destination)
    
    -- Validate standardized data if needed
    if CONFIG.validateAfterMigration and DataValidator then
        self.migrationStatus[userId].status = "validating_target"
        local isValid, validatedData = DataValidator.validatePlayerData(standardizedData)
        
        if not isValid then
            log("Target data validation failed for " .. player.Name .. ", attempting to use repaired data")
            
            if validatedData then
                standardizedData = validatedData
            else
                self.migrationStatus[userId].inProgress = false
                self.migrationStatus[userId].status = "failed"
                self.migrationStatus[userId].error = "Target data validation failed and couldn't be repaired"
                
                self.activeMigrations = self.activeMigrations - 1
                self.failedMigrations = self.failedMigrations + 1
                
                log("Migration failed for " .. player.Name .. ": " .. self.migrationStatus[userId].error)
                return false, self.migrationStatus[userId].error
            end
        end
    end
    
    -- Save to destination system
    self.migrationStatus[userId].status = "saving_target"
    local saveSuccess, saveError = self:SaveDataToSystem(player, destination, standardizedData)
    
    if not saveSuccess then
        self.migrationStatus[userId].inProgress = false
        self.migrationStatus[userId].status = "failed"
        self.migrationStatus[userId].error = "Failed to save to destination: " .. (saveError or "unknown error")
        
        self.activeMigrations = self.activeMigrations - 1
        self.failedMigrations = self.failedMigrations + 1
        
        log("Migration failed for " .. player.Name .. ": " .. self.migrationStatus[userId].error)
        return false, self.migrationStatus[userId].error
    end
    
    -- Update migration status
    self.migrationStatus[userId].inProgress = false
    self.migrationStatus[userId].status = "completed"
    self.migrationStatus[userId].completionTime = os.time()
    
    -- Update counters
    self.activeMigrations = self.activeMigrations - 1
    self.completedMigrations = self.completedMigrations + 1
    
    log("Migration completed successfully for " .. player.Name .. " from " .. source .. " to " .. destination)
    return true, "Migration completed successfully"
end

-- Migrate all current players from one system to another
function DataMigrationUtility:MigrateAllPlayers(source, destination)
    source = source or "EnhancedDataStorageSystem"
    destination = destination or "DataManager"
    
    local players = Players:GetPlayers()
    local migrationResults = {}
    
    log("Starting migration for " .. #players .. " players from " .. source .. " to " .. destination)
    
    for _, player in ipairs(players) do
        local success, message = self:MigratePlayerData(player, source, destination)
        migrationResults[player.Name] = {success = success, message = message}
        
        -- Add slight delay between players to avoid DataStore throttling
        task.wait(0.5)
    end
    
    return migrationResults
end

-- Get migration statistics
function DataMigrationUtility:GetMigrationStats()
    local stats = {
        activeMigrations = self.activeMigrations,
        completedMigrations = self.completedMigrations,
        failedMigrations = self.failedMigrations,
        totalAttempted = self.activeMigrations + self.completedMigrations + self.failedMigrations,
        playerStatus = {}
    }
    
    -- Add per-player status
    for userId, status in pairs(self.migrationStatus) do
        local playerName = "Unknown"
        for _, player in ipairs(Players:GetPlayers()) do
            if player.UserId == userId then
                playerName = player.Name
                break
            end
        end
        
        stats.playerStatus[playerName] = {
            inProgress = status.inProgress,
            source = status.source,
            destination = status.destination,
            status = status.status,
            error = status.error,
            startTime = status.startTime,
            completionTime = status.completionTime,
            duration = status.completionTime and (status.completionTime - status.startTime) or 
                      (status.inProgress and (os.time() - status.startTime) or nil)
        }
    end
    
    return stats
end

-- Initialize on module load
DataMigrationUtility:Initialize()

return DataMigrationUtility
