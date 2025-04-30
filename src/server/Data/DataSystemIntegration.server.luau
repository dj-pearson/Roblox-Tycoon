--!strict
--[[
    DataSystemIntegration.server.luau
    
    This module handles integration between the data system and other game systems,
    providing a unified interface and integrating with CoreRegistry.
    
    Updated: April 26, 2025
]]

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find CoreRegistry using advanced methods
local CoreRegistry
local hasRegistry = false
local CoreRegistryAccess
local UniversalSystemFinder

-- Try to use our new utilities first
pcall(function()
    CoreRegistryAccess = require(ReplicatedStorage.shared.CoreRegistryAccess)
    if CoreRegistryAccess then
        CoreRegistry = CoreRegistryAccess:GetRegistry()
        hasRegistry = CoreRegistry ~= nil
    end
end)

-- If that fails, try UniversalSystemFinder
if not hasRegistry then
    pcall(function()
        UniversalSystemFinder = require(ReplicatedStorage.shared.UniversalSystemFinder)
        if UniversalSystemFinder then
            CoreRegistry = UniversalSystemFinder:GetCoreRegistry()
            hasRegistry = CoreRegistry ~= nil
        end
    end)
end

-- Final fallback to direct requiring
if not hasRegistry then
    hasRegistry = pcall(function()
        CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
    end)
end

-- System modules
local DataManager
local DataBackup
local VersionedDataStore
local DataValidator
local DataMigrationUtility
local EnhancedDataStorage

-- Find required modules
local function findRequiredModules()
    -- Try to find all the data system modules
    pcall(function()
        DataManager = require(ServerScriptService.Core.DataManager)
    end)
    
    pcall(function()
        DataBackup = require(ServerScriptService.Core.DataBackup)
    end)
    
    pcall(function()
        VersionedDataStore = require(ServerScriptService.Core.VersionedDataStore)
    end)
    
    pcall(function()
        DataValidator = require(ReplicatedStorage.shared.DataValidator)
    end)
    
    pcall(function()
        DataMigrationUtility = require(ServerScriptService.Core.DataMigrationUtility)
    end)
    
    pcall(function()
        EnhancedDataStorage = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"))
    end)
    
    if not EnhancedDataStorage then
        pcall(function()
            EnhancedDataStorage = require(ServerScriptService:FindFirstChild("Data"):FindFirstChild("EnhancedDataStorageSystem"))
        end)
    end
end

-- Debug logging
local DEBUG_MODE = true
local function log(message)
    if DEBUG_MODE then
        print("[DataSystemIntegration] " .. message)
    end
end

-- Utility function to safely call functions
local function safeCall(funcOrObj, method, ...)
    if not funcOrObj then
        return nil
    end
    
    local func = method and funcOrObj[method] or funcOrObj
    
    if typeof(func) ~= "function" then
        return nil
    end
    
    local args = {...}  -- Store varargs in a local table
    
    local success, result = pcall(function()
        if method then
            return funcOrObj[method](funcOrObj, table.unpack(args))
        else
            return funcOrObj(table.unpack(args))
        end
    end)
    
    if not success then
        log("Error: " .. tostring(result))
        return nil
    end
    
    return result
end

-- The integration module
local DataSystemIntegration = {
    initialized = false,
    hasRegistry = hasRegistry,
    systemsLoaded = false
}

-- Helper functions for event handlers
function DataSystemIntegration:HandleMilestoneEvent(player, milestone)
    -- Create a backup and version for important milestones
    if DataBackup then
        task.spawn(function()
            DataBackup:CreateCriticalBackup(player, "Milestone_" .. milestone)
        end)
    end
    
    if VersionedDataStore then
        task.spawn(function()
            VersionedDataStore:CreateVersion(player, "Milestone_" .. milestone)
        end)
    end
end

function DataSystemIntegration:HandleLevelUpEvent(player, newLevel)
    -- Create a backup and version for gym level ups
    if DataBackup then
        task.spawn(function()
            DataBackup:CreateCriticalBackup(player, "GymLevelUp_" .. newLevel)
        end)
    end
    
    if VersionedDataStore then
        task.spawn(function()
            VersionedDataStore:CreateVersion(player, "GymLevelUp_" .. newLevel)
        end)
    end
end

function DataSystemIntegration:HandleTransactionEvent(player, amount, reason)
    if amount >= 10000 then -- Only for really large transactions
        -- Create a version for significant cash changes
        if VersionedDataStore then
            task.spawn(function()
                VersionedDataStore:CreateVersion(player, "LargeTransaction_" .. reason .. "_" .. amount)
            end)
        end
    end
end

-- Initialize the integration
function DataSystemIntegration:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing Data System Integration")
    
    -- Find all required modules
    findRequiredModules()
    
    -- Check if we found the core system
    if not DataManager then
        log("DataManager not found, data system integration will be limited")
    else
        self.systemsLoaded = true
    end
    
    -- Register with CoreRegistry if available
    if hasRegistry and CoreRegistry.registerSystem then
        CoreRegistry:registerSystem("DataSystemIntegration", self)
        log("Registered with CoreRegistry")
    end
    
    -- Create compatibility wrappers
    self:CreateCompatibilityLayer()
    
    -- Set up event connections
    self:ConnectEvents()
    
    self.initialized = true
    log("Data System Integration initialized")
    
    -- Register event handlers if the registry exists
    if hasRegistry then
        self:RegisterEventHandlers()
    end
    
    return true
end

-- Create compatibility layer for older systems
function DataSystemIntegration:CreateCompatibilityLayer()
    log("Creating compatibility layer")
    
    -- Create compatibility folder in ReplicatedStorage
    local compatFolder = ReplicatedStorage:FindFirstChild("DataSystemCompat")
    if not compatFolder then
        compatFolder = Instance.new("Folder")
        compatFolder.Name = "DataSystemCompat"
        compatFolder.Parent = ReplicatedStorage
    end
    
    -- Create wrapper functions using BindableFunctions for legacy code
    local functions = {
        GetPlayerData = function(player)
            if DataManager then
                return DataManager:GetPlayerData(player)
            elseif EnhancedDataStorage then
                return EnhancedDataStorage.getPlayerData(player)
            end
            return nil
        end,
        
        SavePlayerData = function(player, immediate)
            if DataManager then
                return DataManager:SavePlayerData(player, immediate)
            elseif EnhancedDataStorage then
                return EnhancedDataStorage.saveData(player, immediate)
            end
            return false
        end,
        
        UpdatePlayerData = function(player, dataPath, value)
            if DataManager then
                return DataManager.updatePlayerData(player, dataPath, value)
            elseif EnhancedDataStorage then
                -- EnhancedDataStorageSystem doesn't have direct path updates
                if EnhancedDataStorage.loadedData and EnhancedDataStorage.loadedData[player.UserId] then
                    -- Simple flat paths only
                    EnhancedDataStorage.loadedData[player.UserId][dataPath] = value
                    return true
                end
            end
            return false
        end,
        
        RestorePlayerEquipment = function(player)
            if DataManager then
                return DataManager:RestorePlayerEquipment(player)
            elseif EnhancedDataStorage then
                return EnhancedDataStorage.restorePurchasedEquipment(player)
            end
            return false
        end,
        
        CreateBackup = function(player, reason)
            if DataBackup then
                return DataBackup:CreateCriticalBackup(player, reason)
            elseif EnhancedDataStorage and EnhancedDataStorage.createBackup then
                return EnhancedDataStorage.createBackup(player)
            end
            return false
        end
    }
    
    -- Create bindable functions for each
    for name, func in pairs(functions) do
        local bindable = compatFolder:FindFirstChild(name)
        if not bindable then
            bindable = Instance.new("BindableFunction")
            bindable.Name = name
            bindable.Parent = compatFolder
        end
        
        bindable.OnInvoke = func
    end
    
    -- Count functions
    local functionCount = 0
    for _ in pairs(functions) do
        functionCount = functionCount + 1
    end
    
    log("Compatibility layer created with " .. functionCount .. " functions")
end

-- Connect to events
function DataSystemIntegration:ConnectEvents()
    log("Connecting events")
    
    -- Player added events
    Players.PlayerAdded:Connect(function(_player)
        -- Nothing special to do on join - DataManager handles this
    end)
    
    -- Player removing events
    Players.PlayerRemoving:Connect(function(_player)
        -- Nothing special to do on leave - DataManager handles this
    end)
    
    -- Watch for equipment purchases
    local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
    if EventBridge then
        local tilePurchasedEvent = EventBridge:FindFirstChild("TilePurchased")
        if tilePurchasedEvent then
            tilePurchasedEvent.Event:Connect(function(player, tileId)
                if DataManager then
                    -- Record immediately and save
                    local userId = player.UserId
                    if DataManager.loadedData and DataManager.loadedData[userId] then
                        if not DataManager.loadedData[userId].equipmentPurchased then
                            DataManager.loadedData[userId].equipmentPurchased = {}
                        end
                        
                        DataManager.loadedData[userId].equipmentPurchased[tostring(tileId)] = true
                        
                        -- Create a version point for important purchases
                        if VersionedDataStore then
                            task.spawn(function()
                                VersionedDataStore:CreateVersion(player, "EquipmentPurchase_" .. tileId)
                            end)
                        end
                    end
                end
            end)
        end
    end
    
    log("Events connected")
end

-- Register event handlers with CoreRegistry
function DataSystemIntegration:RegisterEventHandlers()
    -- Different ways to register events based on what's available
    local registerSuccess = false
    
    -- Try using CoreRegistryAccess if available
    if CoreRegistryAccess then
        log("Using CoreRegistryAccess for event registration")
        registerSuccess = true
        
        -- Use CoreRegistryAccess.OnEvent for safety
        CoreRegistryAccess:OnEvent("PlayerMilestoneReached", function(player, milestone)
            self:HandleMilestoneEvent(player, milestone)
        end)
        
        CoreRegistryAccess:OnEvent("GymLevelUp", function(player, newLevel)
            self:HandleLevelUpEvent(player, newLevel)
        end)
        
        CoreRegistryAccess:OnEvent("LargeTransaction", function(player, amount, reason)
            self:HandleTransactionEvent(player, amount, reason)
        end)
    elseif hasRegistry and CoreRegistry.onEvent then
        log("Using direct CoreRegistry for event registration")
        registerSuccess = true
        
        -- Handle player milestone events
        CoreRegistry:onEvent("PlayerMilestoneReached", function(player, milestone)
            self:HandleMilestoneEvent(player, milestone)
        end)
        
        -- Handle gym level up events
        CoreRegistry:onEvent("GymLevelUp", function(player, newLevel)
            self:HandleLevelUpEvent(player, newLevel)
        end)
        
        -- Handle large cash transactions
        CoreRegistry:onEvent("LargeTransaction", function(player, amount, reason)
            self:HandleTransactionEvent(player, amount, reason)
        end)
    else
        log("No suitable event registration system found")
        return false
    end
    
    log("Event handlers registered")
    return registerSuccess
end

-- Public API for accessing the data system
function DataSystemIntegration:GetPlayerData(player)
    if not player then return nil end
    
    if DataManager then
        if DataManager.loadedData and DataManager.loadedData[player.UserId] then
            return DataManager.loadedData[player.UserId]
        elseif DataManager.LoadPlayerData then
            return DataManager:LoadPlayerData(player)
        end
    elseif EnhancedDataStorage then
        if EnhancedDataStorage.loadedData and EnhancedDataStorage.loadedData[player.UserId] then
            return EnhancedDataStorage.loadedData[player.UserId]
        elseif EnhancedDataStorage.loadData then
            return EnhancedDataStorage.loadData(player)
        end
    end
    
    return nil
end

-- Save player data
function DataSystemIntegration:SavePlayerData(player, immediate)
    if not player then return false end
    immediate = immediate == nil and true or immediate
    
    if DataManager then
        return safeCall(DataManager, "SavePlayerData", player, immediate)
    elseif EnhancedDataStorage then
        return safeCall(EnhancedDataStorage, "saveData", player, immediate)
    end
    
    return false
end

-- Update a specific player data value
function DataSystemIntegration:UpdatePlayerData(player, path, value)
    if not player or not path then return false end
    
    if DataManager and DataManager.updatePlayerData then
        return DataManager.updatePlayerData(player, path, value)
    elseif EnhancedDataStorage and EnhancedDataStorage.loadedData and EnhancedDataStorage.loadedData[player.UserId] then
        -- Handle simple paths only
        EnhancedDataStorage.loadedData[player.UserId][path] = value
        
        -- Queue save
        if EnhancedDataStorage.saveData then
            EnhancedDataStorage.saveData(player, false)
        end
        
        return true
    end
    
    return false
end

-- Restore player equipment
function DataSystemIntegration:RestorePlayerEquipment(player)
    if not player then return false end
    
    if DataManager then
        return safeCall(DataManager, "RestorePlayerEquipment", player)
    elseif EnhancedDataStorage then
        return safeCall(EnhancedDataStorage, "restorePurchasedEquipment", player)
    end
    
    return false
end

-- Create a backup
function DataSystemIntegration:CreateBackup(player, reason)
    if not player then return false end
    reason = reason or "Manual"
    
    if DataBackup then
        return safeCall(DataBackup, "CreateCriticalBackup", player, reason)
    elseif VersionedDataStore then
        return safeCall(VersionedDataStore, "CreateVersion", player, "Backup_" .. reason)
    elseif EnhancedDataStorage and EnhancedDataStorage.createBackup then
        return safeCall(EnhancedDataStorage, "createBackup", player)
    end
    
    return false
end

-- Get system statistics
function DataSystemIntegration:GetSystemStats()
    local stats = {
        systemsAvailable = {
            DataManager = DataManager ~= nil,
            DataBackup = DataBackup ~= nil,
            VersionedDataStore = VersionedDataStore ~= nil,
            DataValidator = DataValidator ~= nil,
            DataMigrationUtility = DataMigrationUtility ~= nil,
            EnhancedDataStorage = EnhancedDataStorage ~= nil,
            CoreRegistry = hasRegistry
        }
    }
    
    -- Gather stats from systems
    if DataManager and DataManager.GetStats then
        stats.dataManagerStats = DataManager:GetStats()
    end
    
    if DataMigrationUtility and DataMigrationUtility.GetMigrationStats then
        stats.migrationStats = DataMigrationUtility:GetMigrationStats()
    end
    
    -- Get loaded player count
    local loadedPlayerCount = 0
    if DataManager and DataManager.loadedData then
        for _ in pairs(DataManager.loadedData) do
            loadedPlayerCount = loadedPlayerCount + 1
        end
    elseif EnhancedDataStorage and EnhancedDataStorage.loadedData then
        for _ in pairs(EnhancedDataStorage.loadedData) do
            loadedPlayerCount = loadedPlayerCount + 1
        end
    end
    
    stats.loadedPlayerCount = loadedPlayerCount
    stats.connectedPlayerCount = #Players:GetPlayers()
    
    return stats
end

-- Migrate player data
function DataSystemIntegration:MigratePlayerData(player, source, destination)
    if not player or not DataMigrationUtility then 
        return false, "Migration utility not available"
    end
    
    return DataMigrationUtility:MigratePlayerData(player, source, destination)
end

-- Roll back player data to a previous version
function DataSystemIntegration:RollbackPlayerData(player, version)
    if not player or not VersionedDataStore then
        return false, "Versioned data store not available"
    end
    
    return VersionedDataStore:ApplyVersion(player, version)
end

-- Initialize
DataSystemIntegration:Initialize()

return DataSystemIntegration
