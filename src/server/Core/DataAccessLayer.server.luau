--[[
    DataAccessLayer.server.luau
    
    A standardized interface for accessing player data across all systems.
    This module provides a consistent API for data operations and handles
    validation, error recovery, and deep copying to prevent accidental data corruption.
    
    Key features:
    - Unified interface for all data operations
    - Automatic data validation
    - Error handling with retries
    - Deep copying to prevent accidental data corruption
    - Automatic logging of data operations
    
    Author: Created May 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Find CoreRegistry
local CoreRegistry
local function findCoreRegistry()
    -- Try to require from common locations
    local success, result
    local possiblePaths = {
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("Systems") and ServerScriptService.Core.Systems:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
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

-- Get DataPersistence from CoreRegistry or directly
local DataPersistence
if CoreRegistry then
    DataPersistence = CoreRegistry.getSystem("DataPersistence")
end

if not DataPersistence then
    -- Try direct require
    local success, result = pcall(function()
        return require(ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataPersistence"))
    end)
    
    if success then
        DataPersistence = result
    end
end

-- Get DataManager from CoreRegistry or directly
local DataManager
if CoreRegistry then
    DataManager = CoreRegistry.getSystem("DataManager")
end

if not DataManager then
    -- Try direct require
    local success, result = pcall(function()
        return require(ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataManager"))
    end)
    
    if success then
        DataManager = result
    else
        success, result = pcall(function()
            -- Legacy path
            return require(ServerScriptService:FindFirstChild("GymTycoonDataManager"))
        end)
        
        if success then
            DataManager = result
        end
    end
end

-- Try to get EnhancedDataStorageSystem as fallback
local EnhancedDataStorageSystem
if not DataManager then
    local success, result = pcall(function()
        return require(ServerScriptService:FindFirstChild("Data"):FindFirstChild("EnhancedDataStorageSystem"))
    end)
    
    if success then
        EnhancedDataStorageSystem = result
    end
end

-- Retry configuration
local RETRY_CONFIG = {
    maxAttempts = 3,
    baseDelay = 1
}

-- Internal debugging
local DEBUG_ENABLED = true
local function log(message)
    if DEBUG_ENABLED then
        print("[DataAccessLayer] " .. message)
    end
end

-- Deep copy function to prevent accidental data mutation
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

-- Data Access Layer singleton
local DataAccessLayer = {
    Version = "1.0.0",
    Debug = DEBUG_ENABLED,
    -- Session tracking
    SessionLocks = {},     -- Format: {userId = true}
    SaveQueue = {},        -- Format: {userId = true} - Players waiting for save
    SaveLocks = {},        -- Format: {userId = true} - Players being saved
    AutoSaveTimers = {},   -- Format: {userId = timer}
    ShutdownInProgress = false,
}

-- Schema definitions for data validation
local DataSchemas = {
    -- Main player data schema
    playerData = {
        required = {"cash", "equipment", "members", "revenue"},
        properties = {
            cash = {type = "number", minimum = 0},
            equipment = {type = "table"},
            members = {
                type = "table",
                properties = {
                    regular = {type = "number", minimum = 0},
                    vip = {type = "number", minimum = 0},
                    premium = {type = "number", minimum = 0}
                }
            },
            revenue = {type = "number", minimum = 0}
        }
    },
    
    -- Equipment schema
    equipment = {
        type = "table",
        itemProperties = {
            id = {type = "number"},
            level = {type = "number", minimum = 1, maximum = 10},
            purchased = {type = "boolean"}
        }
    },
    
    -- Rebirth data schema
    rebirthData = {
        required = {"rebirthCount", "lastRebirthTime"},
        properties = {
            rebirthCount = {type = "number", minimum = 0},
            lastRebirthTime = {type = "number"},
            unlockedFeatures = {type = "table"},
            activePerks = {type = "table"}
        }
    }
}

-- Advanced data validation system
function DataAccessLayer:ValidateData(data, schemaName)
    if not data then return false, "Data is nil" end
    
    -- If no schema specified, use playerData schema
    local schema = DataSchemas[schemaName or "playerData"]
    if not schema then return true end  -- No schema to validate against
    
    -- Check data type
    if type(data) ~= "table" then
        return false, "Data must be a table"
    end
    
    -- Check required fields
    if schema.required then
        for _, field in ipairs(schema.required) do
            if data[field] == nil then
                return false, "Missing required field: " .. field
            end
        end
    end
    
    -- Check property types and constraints
    if schema.properties then
        for field, rules in pairs(schema.properties) do
            local value = data[field]
            
            -- Skip if field is not present and not required
            if value == nil then
                continue
            end
            
            -- Check type
            if rules.type and type(value) ~= rules.type then
                return false, "Field " .. field .. " should be " .. rules.type .. ", got " .. type(value)
            end
            
            -- Check number constraints
            if rules.type == "number" then
                if rules.minimum and value < rules.minimum then
                    return false, "Field " .. field .. " must be at least " .. rules.minimum
                end
                
                if rules.maximum and value > rules.maximum then
                    return false, "Field " .. field .. " must not exceed " .. rules.maximum
                end
            end
            
            -- Check table property constraints recursively
            if rules.type == "table" and rules.properties and type(value) == "table" then
                local subSchema = {
                    required = rules.required,
                    properties = rules.properties
                }
                
                local isValid, errorMsg = self:ValidateData(value, nil, subSchema)
                if not isValid then
                    return false, field .. "." .. errorMsg
                end
            end
            
            -- Check array items if this is an array-like table
            if rules.type == "table" and rules.itemProperties and type(value) == "table" then
                for i, item in pairs(value) do
                    if type(item) ~= "table" then
                        return false, field .. "[" .. i .. "] should be a table"
                    end
                    
                    local itemSchema = {
                        required = rules.itemRequired,
                        properties = rules.itemProperties
                    }
                    
                    local isValid, errorMsg = self:ValidateData(item, nil, itemSchema)
                    if not isValid then
                        return false, field .. "[" .. i .. "]." .. errorMsg
                    end
                end
            end
        end
    end
    
    -- Custom validation rules based on schema name
    if schemaName == "playerData" then
        -- Ensure members counts are not negative
        if data.members then
            if (data.members.regular and data.members.regular < 0) or
               (data.members.vip and data.members.vip < 0) or
               (data.members.premium and data.members.premium < 0) then
                return false, "Member counts cannot be negative"
            end
        end
        
        -- Ensure equipment is properly structured if present
        if data.equipment and type(data.equipment) == "table" then
            for id, info in pairs(data.equipment) do
                if type(info) ~= "table" and type(info) ~= "boolean" then
                    return false, "Equipment entry must be a table or boolean"
                end
            end
        end
    end
    
    return true
end

-- Initialize
function DataAccessLayer:Initialize()
    log("Initializing DataAccessLayer v" .. self.Version)
    
    -- Check if we found DataPersistence
    if not DataPersistence then
        warn("DataPersistence not found! Data operations will fail!")
        return false
    end
    
    -- Check if we found DataManager
    if not DataManager then
        warn("DataManager not found! Some data operations may be limited!")
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("DataAccessLayer", self)
        log("Registered with CoreRegistry")
    end
    
    -- Connect player events
    self:SetupPlayerEvents()
    
    -- Connect events
    self:ConnectEvents()
    
    -- Set up game shutdown handler
    game:BindToClose(function()
        self:HandleShutdown()
    end)
    
    log("DataAccessLayer fully initialized")
    return self
end

-- Get all player data 
function DataAccessLayer:GetAllPlayerData(player)
    if not player then return nil, "Invalid player" end
    if not DataPersistence then return nil, "DataPersistence not initialized" end
    
    local data
    local success, result = pcall(function()
        return DataPersistence:GetPlayerData(player.UserId)
    end)
    
    if success and data then
        log("Retrieved all data for " .. player.Name)
        return deepCopy(data)
    else
        warn("Failed to get data: " .. tostring(result))
        return nil, "Failed to retrieve player data"
    end
end

-- Get specific player data path
function DataAccessLayer:GetPlayerData(player, dataPath)
    if not player then return nil, "Invalid player" end
    if not dataPath then return nil, "Invalid data path" end
    if not DataManager then return nil, "DataManager not initialized" end
    
    local allData = self:GetAllPlayerData(player)
    if not allData then
        return nil, "Failed to get player data"
    end
    
    -- Navigate to the specific data path (supports nested paths like "gym.satisfaction")
    local currentData = allData
    for segment in string.gmatch(dataPath, "[^.]+") do
        if not currentData[segment] then
            return nil, "Data path not found: " .. dataPath
        end
        currentData = currentData[segment]
    end
    
    log("Retrieved data at path: " .. dataPath .. " for " .. player.Name)
    return deepCopy(currentData)
end

-- Update specific player data path
function DataAccessLayer:UpdatePlayerData(player, dataPath, newValue)
    if not player then return false, "Invalid player" end
    if not dataPath then return false, "Invalid data path" end
    if not DataManager then return false, "DataManager not initialized" end
    
    local attempts = 0
    local success, result
    
    repeat
        attempts = attempts + 1
        success, result = pcall(function()
            if DataManager.updatePlayerData then
                return DataManager.updatePlayerData(player, dataPath, deepCopy(newValue))
            elseif DataManager.updateData then
                return DataManager.updateData(player, dataPath, deepCopy(newValue))
            elseif DataManager.loadedData then
                -- EnhancedDataStorageSystem style
                local userId = player.UserId
                local data = DataManager.loadedData[userId]
                if not data then
                    return false
                end
                
                -- Navigate to and update the specific data path
                local currentData = data
                local segments = {}
                
                for segment in string.gmatch(dataPath, "[^.]+") do
                    table.insert(segments, segment)
                end
                
                for i = 1, #segments - 1 do
                    local segment = segments[i]
                    if not currentData[segment] then
                        currentData[segment] = {}
                    end
                    currentData = currentData[segment]
                end
                
                local finalSegment = segments[#segments]
                currentData[finalSegment] = deepCopy(newValue)
                
                -- Auto-save
                if DataManager.saveData then
                    DataManager.saveData(player, false) -- Non-immediate save
                end
                
                return true
            end
            
            return false
        end)
        
        if not success then
            log("Update attempt " .. attempts .. " failed: " .. tostring(result))
            task.wait(RETRY_CONFIG.baseDelay * attempts)
        end
    until success or attempts >= RETRY_CONFIG.maxAttempts
    
    if success and result then
        log("Updated data at path: " .. dataPath .. " for " .. player.Name)
        return true
    else
        warn("Failed to update data after " .. attempts .. " attempts")
        return false, "Update operation failed"
    end
end

-- Save player data immediately
function DataAccessLayer:SavePlayerData(player, immediate)
    if not player then return false, "Invalid player" end
    if not DataPersistence then return false, "DataPersistence not initialized" end
    
    immediate = (immediate == nil) and true or immediate
    
    local success, result = pcall(function()
        return DataPersistence:SavePlayerData(player.UserId, immediate)
    end)
    
    if success and result then
        log("Saved data for " .. player.Name .. (immediate and " (immediate)" or ""))
        return true
    else
        warn("Failed to save data: " .. tostring(result))
        return false, "Save operation failed"
    end
end

-- Enhanced save with validation
function DataAccessLayer:SavePlayerDataWithValidation(player, immediate)
    if not player then return false, "Invalid player" end
    
    -- Get the player data
    local data = self:GetAllPlayerData(player)
    if not data then
        return false, "No data to save"
    end
    
    -- Validate the data
    local isValid, errorMsg = self:ValidateData(data)
    if not isValid then
        warn("Data validation failed for " .. player.Name .. ": " .. errorMsg)
        
        -- Try to create a backup of the invalid data for debugging
        pcall(function()
            local backupKey = "InvalidData_" .. player.UserId .. "_" .. os.time()
            if DataManager and DataManager.backupStore then
                DataManager.backupStore:SetAsync(backupKey, data)
                log("Created backup of invalid data: " .. backupKey)
            end
        end)
        
        return false, "Data validation failed: " .. errorMsg
    end
    
    -- Data is valid, proceed with save
    return self:SavePlayerData(player, immediate)
end

-- Load player data
function DataAccessLayer:LoadPlayerData(player)
    if not player then return nil, "Invalid player" end
    if not DataPersistence then return nil, "DataPersistence not initialized" end
    
    local data
    local success, result = pcall(function()
        return DataPersistence:LoadPlayerData(player.UserId)
    end)
    
    if success and data then
        log("Loaded data for " .. player.Name)
        return deepCopy(data)
    else
        warn("Failed to load data: " .. tostring(result))
        return nil, "Load operation failed"
    end
end

-- Register event handlers
function DataAccessLayer:ConnectEvents()
    -- Listen for player data changes from CoreRegistry
    if CoreRegistry and CoreRegistry.onEvent then
        CoreRegistry.onEvent("PlayerDataChanged", function(player, dataPath)
            log("Data changed event: " .. player.Name .. "." .. dataPath)
            -- Event handling code here
        end)
    end
    
    -- Listen for save events
    if CoreRegistry and CoreRegistry.onEvent then
        CoreRegistry.onEvent("PlayerDataSaved", function(player)
            log("Data saved event: " .. player.Name)
            -- Event handling code here
        end)
    end
end

-- Apply data to player (for common operations like setting cash)
function DataAccessLayer:ApplyDataToPlayer(player, data)
    if not player or not data then return false, "Invalid parameters" end
    if not DataManager then return false, "DataManager not initialized" end
    
    local success, result = pcall(function()
        if DataManager.applyDataToPlayer then
            return DataManager.applyDataToPlayer(player, data)
        end
        
        -- Manual application if not available
        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then
            leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"
            leaderstats.Parent = player
        end
        
        -- Set cash
        if data.cash then
            local cash = leaderstats:FindFirstChild("Cash")
            if cash then
                cash.Value = data.cash
            else
                cash = Instance.new("IntValue")
                cash.Name = "Cash"
                cash.Value = data.cash
                cash.Parent = leaderstats
            end
        end
        
        return true
    end)
    
    if success and result then
        log("Applied data to " .. player.Name)
        return true
    else
        warn("Failed to apply data: " .. tostring(result))
        return false, "Apply operation failed"
    end
end

-- Get tycoon reference for player
function DataAccessLayer:GetPlayerTycoon(player)
    if not player then return nil, "Invalid player" end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then
        return nil, "No tycoon found"
    end
    
    return tycoon.Value
end

-- Restore player equipment from data
function DataAccessLayer:RestorePlayerEquipment(player)
    if not player then return false, "Invalid player" end
    if not DataManager then return false, "DataManager not initialized" end
    
    local success, result = pcall(function()
        if DataManager.restorePurchasedEquipment then
            return DataManager.restorePurchasedEquipment(player)
        end
        return false
    end)
    
    if success and result then
        log("Restored equipment for " .. player.Name)
        return true
    else
        warn("Failed to restore equipment: " .. tostring(result))
        return false, "Restore operation failed"
    end
end

-- Has the player started their tycoon?
function DataAccessLayer:HasPlayerStartedTycoon(player)
    if not player then return false, "Invalid player" end
    if not DataManager then return false, "DataManager not initialized" end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then 
        return false
    end
    
    return tycoon:GetAttribute("TycoonStarted") == true
end

-- Create a backup of player data
function DataAccessLayer:CreateBackup(player)
    if not player then return false, "Invalid player" end
    if not DataManager then return false, "DataManager not initialized" end
    
    local success, result = pcall(function()
        if DataManager.createBackup then
            return DataManager.createBackup(player)
        elseif DataManager.backupPlayerData then
            return DataManager.backupPlayerData(player)
        end
        return false
    end)
    
    if success and result then
        log("Created backup for " .. player.Name)
        return true
    else
        warn("Failed to create backup: " .. tostring(result))
        return false, "Backup operation failed"
    end
end

-- Session locking to prevent data duplication
function DataAccessLayer:AcquireSessionLock(player)
    if not player then return false, "Invalid player" end
    
    local userId = player.UserId
    
    -- Check if we already have the lock
    if self.SessionLocks[userId] then
        return true
    end
    
    -- Check for existing session lock in DataStore
    local success, result = pcall(function()
        if DataManager.checkSessionLock then
            return DataManager.checkSessionLock(player)
        end
        return false
    end)
    
    if success and result then
        -- Another server has the lock
        log("Session lock exists for " .. player.Name)
        return false, "Session already locked"
    end
    
    -- Try to acquire the lock
    success, result = pcall(function()
        if DataManager.acquireSessionLock then
            return DataManager.acquireSessionLock(player)
        elseif DataManager.setSessionLock then
            return DataManager.setSessionLock(player, true)
        end
        return false
    end)
    
    if success and result then
        -- Successfully acquired lock
        self.SessionLocks[userId] = true
        log("Acquired session lock for " .. player.Name)
        return true
    else
        -- Failed to acquire lock
        warn("Failed to acquire session lock: " .. tostring(result))
        return false, "Failed to acquire session lock"
    end
end

-- Release the session lock
function DataAccessLayer:ReleaseSessionLock(player)
    if not player then return false, "Invalid player" end
    
    local userId = player.UserId
    
    -- Check if we have the lock
    if not self.SessionLocks[userId] then
        return false, "No session lock to release"
    end
    
    -- Try to release the lock
    local success, result = pcall(function()
        if DataManager.releaseSessionLock then
            return DataManager.releaseSessionLock(player)
        elseif DataManager.setSessionLock then
            return DataManager.setSessionLock(player, false)
        end
        return false
    end)
    
    if success and result then
        -- Successfully released lock
        self.SessionLocks[userId] = nil
        log("Released session lock for " .. player.Name)
        return true
    else
        -- Failed to release lock
        warn("Failed to release session lock: " .. tostring(result))
        return false, "Failed to release session lock"
    end
end

-- Setup auto-save for a player
function DataAccessLayer:SetupAutoSave(player, interval)
    if not player then return false, "Invalid player" end
    
    interval = interval or 60 -- Default to 60 seconds
    local userId = player.UserId
    
    -- Clear existing timer if any
    if self.AutoSaveTimers[userId] then
        task.cancel(self.AutoSaveTimers[userId])
        self.AutoSaveTimers[userId] = nil
    end
    
    -- Create new auto-save timer
    self.AutoSaveTimers[userId] = task.spawn(function()
        while true do
            task.wait(interval)
            
            -- Skip if shutting down
            if self.ShutdownInProgress then break end
            
            -- Auto-save
            pcall(function()
                self:SavePlayerData(player, false) -- Non-immediate save
            end)
        end
    end)
    
    log("Set up auto-save for " .. player.Name .. " (interval: " .. interval .. "s)")
    return true
end

-- Stop auto-save for a player
function DataAccessLayer:StopAutoSave(player)
    if not player then return false, "Invalid player" end
    
    local userId = player.UserId
    
    -- Clear existing timer
    if self.AutoSaveTimers[userId] then
        task.cancel(self.AutoSaveTimers[userId])
        self.AutoSaveTimers[userId] = nil
        log("Stopped auto-save for " .. player.Name)
        return true
    end
    
    return false, "No auto-save timer to stop"
end

-- Handle player connections and initialize data layer
function DataAccessLayer:SetupPlayerEvents()
    local Players = game:GetService("Players")
    
    -- Set up player join event
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            log("Player joined: " .. player.Name)
            
            -- Try to acquire session lock
            local lockAcquired = self:AcquireSessionLock(player)
            if not lockAcquired then
                log("Warning: Session lock acquisition failed for " .. player.Name .. ". May be active in another server.")
            end
            
            -- Load data - wait a short time to ensure player is fully loaded
            task.wait(1)
            local data = self:LoadPlayerData(player)
            
            if data then
                -- Apply data to player
                self:ApplyDataToPlayer(player, data)
                
                -- Set up auto-save
                self:SetupAutoSave(player, 120) -- Every 2 minutes
            else
                warn("Failed to load data for " .. player.Name)
            end
            
            -- Fire event through CoreRegistry if available
            if CoreRegistry and CoreRegistry.fireEvent then
                CoreRegistry:FireEvent("PlayerDataLoaded", player)
            end
        end)
    end)
    
    -- Set up player leave event
    Players.PlayerRemoving:Connect(function(player)
        task.spawn(function()
            log("Player leaving: " .. player.Name)
            
            -- Stop auto-save
            self:StopAutoSave(player)
            
            -- Save data immediately
            self:SavePlayerData(player, true)
            
            -- Release session lock
            self:ReleaseSessionLock(player)
            
            -- Clear internal tracking
            local userId = player.UserId
            self.SessionLocks[userId] = nil
            self.SaveQueue[userId] = nil
            self.SaveLocks[userId] = nil
            
            -- Fire event through CoreRegistry if available
            if CoreRegistry and CoreRegistry.fireEvent then
                CoreRegistry:FireEvent("PlayerDataSaved", player)
            end
        end)
    end)
    
    log("Player events connected")
end

-- Handle game shutdown
function DataAccessLayer:HandleShutdown()
    if self.ShutdownInProgress then
        return
    end
    
    self.ShutdownInProgress = true
    log("Processing shutdown, saving all player data")
    
    local Players = game:GetService("Players")
    local players = Players:GetPlayers()
    local savedCount = 0
    
    for _, player in pairs(players) do
        task.spawn(function()
            -- Stop auto-save
            self:StopAutoSave(player)
            
            -- Save data immediately
            local success = self:SavePlayerData(player, true)
            if success then
                savedCount = savedCount + 1
            end
        end)
    end
    
    -- Wait for all saves to complete (with timeout)
    local timeout = os.time() + 10 -- 10 second maximum wait
    while savedCount < #players and os.time() < timeout do
        task.wait(0.1)
    end
    
    log("Saved " .. savedCount .. " player data records during shutdown")
    
    -- Notify VersionedDataStore if available
    if CoreRegistry then
        local VersionedDataStore = CoreRegistry:GetSystem("VersionedDataStore")
        if VersionedDataStore and typeof(VersionedDataStore.HandleShutdown) == "function" then
            VersionedDataStore:HandleShutdown()
        end
    end
end

-- Initialize and return
return DataAccessLayer:Initialize()
