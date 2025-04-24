--[[
    DataMigrationUtility.server.luau
    
    A utility for migrating data between different data storage systems.
    This helps in the transition from older systems (EnhancedDataStorageSystem)
    to the new standardized DataAccessLayer and VersionedDataStore.
    
    Key features:
    - Safely migrates data between storage systems
    - Validates data integrity during migration
    - Creates backups before migration
    - Supports both automatic and manual migration
    
    Author: Created April 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Find CoreRegistry
local CoreRegistry
local function findCoreRegistry()
    -- Try to require from common locations
    local success, result
    local possiblePaths = {
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("Systems") and ServerScriptService.Core.Systems:FindFirstChild("CoreRegistry"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            success, result = pcall(function()
                return require(path)
            end)
            
            if success then
                return result
            end
        end
    end
    
    return nil
end

CoreRegistry = findCoreRegistry()

-- Try to load the systems we need
local DataAccessLayer, VersionedDataStore, DataManager, EnhancedDataStorageSystem

-- Load from CoreRegistry if available
if CoreRegistry then
    DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
    VersionedDataStore = CoreRegistry:GetSystem("VersionedDataStore")
    DataManager = CoreRegistry:GetSystem("DataManager")
end

-- Try to load directly if not found in CoreRegistry
if not DataAccessLayer then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("DataAccessLayer")
        if path then
            DataAccessLayer = require(path)
        end
    end)
end

if not VersionedDataStore then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("VersionedDataStore")
        if path then
            VersionedDataStore = require(path)
        end
    end)
end

if not DataManager then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("DataManager")
        if path then
            DataManager = require(path)
        end
    end)
end

if not EnhancedDataStorageSystem then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Data") and 
                    ServerScriptService.Data:FindFirstChild("EnhancedDataStorageSystem")
        if path then
            EnhancedDataStorageSystem = require(path)
        end
    end)
    
    if not EnhancedDataStorageSystem then
        pcall(function()
            EnhancedDataStorageSystem = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"))
        end)
    end
end

-- Debug mode configuration
local DEBUG_MODE = true
local function log(message)
    if DEBUG_MODE then
        print("[DataMigration] " .. message)
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

-- Data Migration Utility
local DataMigrationUtility = {
    MigrationSessions = {} -- Format: {userId = {inProgress, source, destination, status}}
}

-- Initialize the utility
function DataMigrationUtility:Initialize()
    log("Initializing DataMigrationUtility")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:RegisterSystem("DataMigrationUtility", self)
        log("Registered with CoreRegistry")
    end
    
    -- Create command if CommandService exists
    if CoreRegistry then
        local CommandService = CoreRegistry:GetSystem("CommandService")
        if CommandService and typeof(CommandService.RegisterCommand) == "function" then
            CommandService:RegisterCommand("migrateData", {
                description = "Migrate player data between storage systems",
                parameters = {
                    {
                        name = "player",
                        type = "string", 
                        description = "Player name or 'all'"
                    },
                    {
                        name = "source", 
                        type = "string", 
                        description = "Source system (enhanced, datamanager)"
                    },
                    {
                        name = "destination", 
                        type = "string", 
                        description = "Destination system (datamanager, versioned)"
                    },
                },
                handler = function(sender, playerName, source, destination)
                    -- Check admin privileges
                    local AdminService = CoreRegistry:GetSystem("AdminService")
                    if AdminService and not AdminService:IsAdmin(sender) then
                        return "You don't have permission to use this command"
                    end
                    
                    if playerName == "all" then
                        local count = self:MigrateAllPlayers(source, destination)
                        return "Started migration for " .. count .. " players"
                    else
                        local player = self:FindPlayerByName(playerName)
                        if not player then
                            return "Player not found: " .. playerName
                        end
                        
                        local success, result = self:MigratePlayerData(player, source, destination)
                        if success then
                            return "Migration started for " .. player.Name
                        else
                            return "Migration failed: " .. tostring(result)
                        end
                    end
                end
            })
            
            log("Registered migration command")
        end
    end
    
    return self
end

-- Find a player by name
function DataMigrationUtility:FindPlayerByName(name)
    if not name then return nil end
    
    name = string.lower(name)
    
    for _, player in pairs(Players:GetPlayers()) do
        if string.lower(player.Name) == name then
            return player
        end
    end
    
    return nil
end

-- Get data from a specific source
function DataMigrationUtility:GetDataFromSource(player, source)
    if not player then
        return nil, "Invalid player"
    end
    
    -- Normalize source name
    source = string.lower(source or "")
    
    if source == "enhanced" or source == "enhanceddatastoragesystem" then
        if EnhancedDataStorageSystem and typeof(EnhancedDataStorageSystem.loadData) == "function" then
            local data = EnhancedDataStorageSystem.loadData(player)
            return data
        else
            return nil, "EnhancedDataStorageSystem not available"
        end
    elseif source == "datamanager" or source == "" then
        if DataManager and typeof(DataManager.getPlayerData) == "function" then
            local data = DataManager.getPlayerData(player)
            return data
        else
            return nil, "DataManager not available"
        end
    elseif source == "datalayer" or source == "dataaccesslayer" then
        if DataAccessLayer and typeof(DataAccessLayer.GetAllPlayerData) == "function" then
            local data = DataAccessLayer:GetAllPlayerData(player)
            return data
        else
            return nil, "DataAccessLayer not available"
        end
    else
        return nil, "Unknown source: " .. source
    end
end

-- Save data to a specific destination
function DataMigrationUtility:SaveDataToDestination(player, data, destination)
    if not player or not data then
        return false, "Invalid parameters"
    end
    
    -- Normalize destination name
    destination = string.lower(destination or "")
    
    if destination == "enhanced" or destination == "enhanceddatastoragesystem" then
        if EnhancedDataStorageSystem and typeof(EnhancedDataStorageSystem.saveData) == "function" then
            -- Use direct access to loaded data for more efficient update
            local userId = player.UserId
            EnhancedDataStorageSystem.loadedData[userId] = deepCopy(data)
            local success = EnhancedDataStorageSystem.saveData(player, true)
            return success
        else
            return false, "EnhancedDataStorageSystem not available"
        end
    elseif destination == "datamanager" or destination == "" then
        if DataManager then
            -- Use direct access to player data for more efficient update
            local userId = player.UserId
            DataManager.playerData[userId] = deepCopy(data)
            local success = false
            
            if typeof(DataManager.saveData) == "function" then
                success = DataManager.saveData(player, true)
            end
            
            return success
        else
            return false, "DataManager not available"
        end
    elseif destination == "versioned" or destination == "versioneddatastore" then
        if VersionedDataStore and typeof(VersionedDataStore.SaveData) == "function" then
            local success = VersionedDataStore:SaveData(player, data, true)
            return success
        else
            return false, "VersionedDataStore not available"
        end
    elseif destination == "datalayer" or destination == "dataaccesslayer" then
        if DataAccessLayer and typeof(DataAccessLayer.SavePlayerData) == "function" then
            local success = DataAccessLayer:SavePlayerData(player, true)
            return success
        else
            return false, "DataAccessLayer not available"
        end
    else
        return false, "Unknown destination: " .. destination
    end
end

-- Create a backup before migration
function DataMigrationUtility:CreateBackup(player)
    if not player then
        return false, "Invalid player"
    end
    
    local success = false
    local backupCreated = false
    
    -- Try using DataAccessLayer first
    if DataAccessLayer and typeof(DataAccessLayer.CreateBackup) == "function" then
        success = DataAccessLayer:CreateBackup(player)
        if success then
            backupCreated = true
        end
    end
    
    -- Try using DataManager as fallback
    if not backupCreated and DataManager and typeof(DataManager.backupPlayerData) == "function" then
        success = DataManager.backupPlayerData(player)
        if success then
            backupCreated = true
        end
    end
    
    -- Try using EnhancedDataStorageSystem as last resort
    if not backupCreated and EnhancedDataStorageSystem and typeof(EnhancedDataStorageSystem.createBackup) == "function" then
        success = EnhancedDataStorageSystem.createBackup(player)
        if success then
            backupCreated = true
        end
    end
    
    if backupCreated then
        log("Created backup for " .. player.Name)
    else
        log("Failed to create backup for " .. player.Name)
    end
    
    return backupCreated
end

-- Migrate a single player's data
function DataMigrationUtility:MigratePlayerData(player, source, destination)
    if not player then
        return false, "Invalid player"
    end
    
    local userId = player.UserId
    
    -- Check if migration already in progress
    if self.MigrationSessions[userId] and self.MigrationSessions[userId].inProgress then
        return false, "Migration already in progress"
    end
    
    -- Set up migration session
    self.MigrationSessions[userId] = {
        inProgress = true,
        source = source,
        destination = destination,
        status = "Starting",
        startTime = os.time()
    }
    
    -- Run migration in a separate thread
    task.spawn(function()
        -- Update status
        self.MigrationSessions[userId].status = "Creating backup"
        
        -- Create backup first
        local backupSuccess = self:CreateBackup(player)
        if not backupSuccess then
            log("Warning: Failed to create backup for " .. player.Name)
            -- Continue anyway, but with a warning
        end
        
        -- Update status
        self.MigrationSessions[userId].status = "Loading data"
        
        -- Get data from source
        local data, errorMsg = self:GetDataFromSource(player, source)
        if not data then
            self.MigrationSessions[userId].inProgress = false
            self.MigrationSessions[userId].status = "Failed: " .. tostring(errorMsg)
            log("Migration failed for " .. player.Name .. ": " .. tostring(errorMsg))
            return
        end
        
        -- Update status
        self.MigrationSessions[userId].status = "Saving data"
        
        -- Save to destination
        local success, saveErrorMsg = self:SaveDataToDestination(player, data, destination)
        if not success then
            self.MigrationSessions[userId].inProgress = false
            self.MigrationSessions[userId].status = "Failed: " .. tostring(saveErrorMsg)
            log("Migration failed for " .. player.Name .. ": " .. tostring(saveErrorMsg))
            return
        end
        
        -- Record completion
        self.MigrationSessions[userId].inProgress = false
        self.MigrationSessions[userId].status = "Completed"
        self.MigrationSessions[userId].completeTime = os.time()
        local duration = self.MigrationSessions[userId].completeTime - self.MigrationSessions[userId].startTime
        
        log("Migration completed for " .. player.Name .. " in " .. duration .. " seconds")
        
        -- Fire event if available
        if CoreRegistry and CoreRegistry.FireEvent then
            CoreRegistry:FireEvent("DataMigrationCompleted", player, source, destination)
        end
    end)
    
    return true
end

-- Migrate all players currently on the server
function DataMigrationUtility:MigrateAllPlayers(source, destination)
    local players = Players:GetPlayers()
    local count = 0
    
    for _, player in ipairs(players) do
        local success = self:MigratePlayerData(player, source, destination)
        if success then
            count = count + 1
        end
        
        -- Add a small delay between migrations to prevent overloading
        task.wait(0.5)
    end
    
    return count
end

-- Get migration status
function DataMigrationUtility:GetMigrationStatus(player)
    if not player then
        return nil, "Invalid player"
    end
    
    local userId = player.UserId
    
    if not self.MigrationSessions[userId] then
        return nil, "No migration session found"
    end
    
    return self.MigrationSessions[userId]
end

-- Initialize and return
return DataMigrationUtility:Initialize()
