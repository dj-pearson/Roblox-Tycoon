-- DataSystemBridge.server.luau
-- This module serves as a bridge between different data systems to resolve integration issues
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Debug function
local DEBUG_ENABLED = true
local function log(...)
    if DEBUG_ENABLED then
        print("[DataSystemBridge]", ...)
    end
end

-- First, try to find CoreRegistry if available
local CoreRegistry
pcall(function()
    CoreRegistry = require(ServerScriptService.Core.CoreRegistry) 
    log("Found CoreRegistry in Core folder")
end)

if not CoreRegistry then
    log("CoreRegistry not found, creating basic version")
    -- Create a basic registry if one doesn't exist
    CoreRegistry = {
        systems = {},
        
        registerSystem = function(self, name, system)
            self.systems[name] = system
            log("Registered system: " .. name)
            return system
        end,
        
        getSystem = function(self, name)
            return self.systems[name]
        end,
        
        hasSystem = function(self, name)
            return self.systems[name] ~= nil
        end
    }
end

-- Module definition
local DataSystemBridge = {}

-- Locate the Data Manager using multiple possible paths
function DataSystemBridge:findDataManager()
    local dataManager = CoreRegistry:getSystem("DataManager")
    
    if dataManager then
        log("Found DataManager in CoreRegistry")
        return dataManager
    end
    
    -- Try to locate DataManager in Core folder
    local success, result = pcall(function()
        return require(ServerScriptService.Core.DataManager)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("DataManager", result)
        log("Found DataManager in Core folder")
        return result
    end
    
    -- Try to locate it in Data folder
    success, result = pcall(function()
        return require(ServerScriptService.Data.GymTycoonDataManager)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("DataManager", result)
        log("Found GymTycoonDataManager in Data folder")
        return result
    end
    
    -- Try to find EnhancedDataStorageSystem as fallback
    success, result = pcall(function()
        return require(ServerScriptService.Data.EnhancedDataStorageSystem)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("DataManager", result)
        log("Using EnhancedDataStorageSystem as fallback")
        return result
    end
    
    log("Unable to locate any data management system")
    return nil
end

-- Locate BuyTile system
function DataSystemBridge:findBuyTileSystem()
    local buyTileSystem = CoreRegistry:getSystem("BuyTileSystem") 
    
    if buyTileSystem then
        log("Found BuyTileSystem in CoreRegistry")
        return buyTileSystem
    end
    
    -- Try Core folder
    local success, result = pcall(function() 
        return require(ServerScriptService.Core.BuyTileSystem)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("BuyTileSystem", result)
        log("Found BuyTileSystem in Core folder")
        return result
    end
    
    -- Try Essentials folder
    success, result = pcall(function() 
        return require(ServerScriptService.Essentials.BuyTile)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("BuyTileSystem", result)
        log("Found BuyTileSystem in Essentials folder")
        return result
    end
    
    -- Try direct path
    success, result = pcall(function() 
        return require(ServerScriptService:FindFirstChild("BuyTile"))
    end)
    
    if success and result then
        CoreRegistry:registerSystem("BuyTileSystem", result)
        log("Found BuyTileSystem in ServerScriptService")
        return result
    end
    
    log("Unable to locate BuyTile system")
    return nil
end

-- Create a standardized function for spawning gym parts that adapts to available functions
function DataSystemBridge:createSpawnGymPartFunction()
    local buyTileSystem = self:findBuyTileSystem()
    
    if not buyTileSystem then
        log("No BuyTile system found, cannot create spawn function")
        return nil
    end
    
    -- Try to find the appropriate function
    local spawnFunction = buyTileSystem.spawnGymPart or 
                         buyTileSystem.spawnBuyTile or 
                         buyTileSystem.spawnEquipment or 
                         buyTileSystem.purchaseEquipment
    
    if not spawnFunction then
        -- Create a basic implementation if necessary
        log("No spawn function found, creating adapter")
        
        if buyTileSystem.createPart or buyTileSystem.createEquipment then
            spawnFunction = function(tileId)
                log("Using createPart adapter for tile: " .. tostring(tileId))
                if buyTileSystem.createPart then
                    return buyTileSystem.createPart(tileId)
                else
                    return buyTileSystem.createEquipment(tileId)
                end
            end
        else
            log("No compatible functions found to create adapter")
            return nil
        end
    end
    
    -- Patch the BuyTileSystem with the standard function if it doesn't have one
    if not buyTileSystem.spawnGymPart then
        buyTileSystem.spawnGymPart = spawnFunction
        log("Added spawnGymPart function to BuyTileSystem")
    end
    
    return spawnFunction
end

-- Create a standardized function for data persistence
function DataSystemBridge:createDataPersistenceInterface()
    local dataManager = self:findDataManager()
    
    if not dataManager then
        log("No data manager found, cannot create data interface")
        return nil
    end
    
    local interface = {}
    
    -- Standardized load function
    interface.loadData = function(player)
        if dataManager.loadData then
            return dataManager.loadData(player)
        elseif dataManager.loadPlayerData then
            return dataManager.loadPlayerData(player)
        elseif dataManager.loadedData and dataManager.loadedData[player.UserId] then
            return dataManager.loadedData[player.UserId]
        end
        log("No compatible load function found for player: " .. player.Name)
        return nil
    end
    
    -- Standardized save function
    interface.saveData = function(player, immediate)
        if dataManager.saveData then
            return dataManager.saveData(player, immediate)
        elseif dataManager.savePlayerData then
            return dataManager.savePlayerData(player, immediate)
        elseif dataManager.save then
            return dataManager.save(player, immediate)
        end
        log("No compatible save function found for player: " .. player.Name)
        return false
    end
    
    -- Standardized equipment restoration
    interface.restoreEquipment = function(player)
        if dataManager.restorePurchasedEquipment then
            return dataManager.restorePurchasedEquipment(player)
        elseif dataManager.restoreEquipment then
            return dataManager.restoreEquipment(player)
        end
        
        -- Try to implement it ourselves
        local spawnFunction = self:createSpawnGymPartFunction()
        if spawnFunction then
            local data = interface.loadData(player)
            if data and data.equipment then
                local count = 0
                for _, tileId in ipairs(data.equipment) do
                    local success = pcall(function()
                        return spawnFunction(tileId)
                    end)
                    if success then
                        count = count + 1
                    end
                end
                log("Restored " .. count .. "/" .. #data.equipment .. " equipment pieces for " .. player.Name)
                return true
            end
        end
        
        log("No compatible restore function found for player: " .. player.Name)
        return false
    end
    
    return interface
end

-- Get data access layer
function DataSystemBridge:getDataAccessLayer()
    local dataAccessLayer = CoreRegistry:getSystem("DataAccessLayer")
    
    if dataAccessLayer then
        log("Found DataAccessLayer in CoreRegistry")
        return dataAccessLayer
    end
    
    -- Try Core folder
    local success, result = pcall(function() 
        return require(ServerScriptService.Core.DataAccessLayer)
    end)
    
    if success and result then
        CoreRegistry:registerSystem("DataAccessLayer", result)
        log("Found DataAccessLayer in Core folder")
        return result
    end
    
    log("Unable to locate DataAccessLayer, creating basic version")
    
    -- Create a basic version
    local interface = self:createDataPersistenceInterface()
    
    if not interface then
        log("Cannot create DataAccessLayer, no data interface available")
        return nil
    end
    
    -- Create basic DataAccessLayer
    dataAccessLayer = {
        GetAllPlayerData = function(player)
            return interface.loadData(player)
        end,
        
        SavePlayerData = function(player, immediate)
            return interface.saveData(player, immediate)
        end,
        
        RestorePlayerEquipment = function(player)
            return interface.restoreEquipment(player)
        end
    }
    
    CoreRegistry:registerSystem("DataAccessLayer", dataAccessLayer)
    return dataAccessLayer
end

-- Fix integration issues between systems
function DataSystemBridge:fixIntegrationIssues()
    log("Starting integration fix process...")
    
    -- 1. Find or create data persistence interface
    local dataInterface = self:createDataPersistenceInterface()
    if not dataInterface then
        log("Failed to create data persistence interface")
    else
        log("Created standardized data persistence interface")
    end
    
    -- 2. Ensure BuyTileSystem has spawnGymPart function
    local spawnFunction = self:createSpawnGymPartFunction()
    if not spawnFunction then
        log("Failed to create spawn function")
    else
        log("Created standardized spawn function")
    end
    
    -- 3. Set up GymTycoonConnector if available
    local connector = CoreRegistry:getSystem("GymTycoonConnector")
    if not connector then
        -- Try to load it
        pcall(function()
            connector = require(ServerScriptService.Core.GymTycoonConnector)
            CoreRegistry:registerSystem("GymTycoonConnector", connector)
        end)
    end
    
    if connector and dataInterface then
        -- Set up connector data bridge
        if not connector.dataManager then
            connector.dataManager = dataInterface
            log("Set up data manager in GymTycoonConnector")
        end
    end
    
    -- 4. Register DataAccessLayer
    self:getDataAccessLayer()
    
    log("Finished fixing integration issues")
    
    -- 5. Ensure GymTycoonDataManager is registered
    local dataManager = self:findDataManager()
    if dataManager and not CoreRegistry:getSystem("GymTycoonDataManager") then
        CoreRegistry:registerSystem("GymTycoonDataManager", dataManager)
        log("Registered GymTycoonDataManager in CoreRegistry")
    end
    
    return true
end

-- Initialize and fix issues
DataSystemBridge:fixIntegrationIssues()

-- Public API to access through require()
return {
    findDataManager = function()
        return DataSystemBridge:findDataManager()
    end,
    
    findBuyTileSystem = function()
        return DataSystemBridge:findBuyTileSystem()
    end,
    
    getDataAccessLayer = function()
        return DataSystemBridge:getDataAccessLayer()
    end,
    
    fixIntegrationIssues = function()
        return DataSystemBridge:fixIntegrationIssues()
    end
}
