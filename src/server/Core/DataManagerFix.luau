--[[
    DataManagerFix.luau
    
    This module fixes data management issues by extending the DataManager with 
    robust error handling and retry mechanisms.
    
    Created as part of Phase 3 fixes: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    MAX_RETRIES = 3,
    RETRY_DELAY = 2, -- Seconds between retries
    AUTO_FALLBACK = true -- Automatically use fallback data if loading fails
}

-- Debug logging
local function log(message, messageType)
    if CONFIG.DEBUG_MODE or messageType == "error" or messageType == "warn" then
        local prefix = "[DataManagerFix] "
        if messageType == "error" then
            warn(prefix .. "ERROR: " .. message)
        elseif messageType == "warn" then
            warn(prefix .. "WARNING: " .. message)
        else
            print(prefix .. message)
        end
    end
end

-- Try to require CoreRegistry
local CoreRegistry
pcall(function()
    local coreRegistryModule = ServerScriptService:FindFirstChild("Core") and 
                              ServerScriptService.Core:FindFirstChild("CoreRegistry") or
                              (ReplicatedStorage:FindFirstChild("shared") and 
                               ReplicatedStorage.shared:FindFirstChild("CoreRegistryRef"))
    
    if coreRegistryModule then
        CoreRegistry = require(coreRegistryModule)
    end
end)

-- Try to get DataManager from CoreRegistry first
local DataManager = CoreRegistry and CoreRegistry.getSystem and CoreRegistry.getSystem("DataManager")

-- If not found in CoreRegistry, try to require directly
if not DataManager then
    pcall(function()
        local dataManagerModule = ServerScriptService:FindFirstChild("Core") and 
                                 ServerScriptService.Core:FindFirstChild("DataManager") or
                                 (ServerScriptService:FindFirstChild("DataManager"))
        
        if dataManagerModule then
            DataManager = require(dataManagerModule)
        end
    end)
end

-- The DataManagerFix module
local DataManagerFix = {
    initialized = false,
    pendingOperations = {},
    fallbackTemplates = {
        -- Default player data template
        playerData = {
            coins = 0,
            level = 1,
            inventory = {},
            tutorial = {
                completed = false,
                step = 0
            },
            tycoon = {
                tiles = {},
                lastSave = 0
            }
        }
    }
}

-- Initialize the module
function DataManagerFix:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataManagerFix...")
    
    -- Check if DataManager exists
    if not DataManager then
        log("DataManager not found, creating fallback implementation", "warn")
        self:createFallbackDataManager()
    else
        -- Enhance existing DataManager with our fixes
        self:enhanceDataManager()
    end
    
    -- Set up player events
    self:setupPlayerEvents()
    
    -- Connect to CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("DataManagerFix", self)
        log("Registered with CoreRegistry")
    end
    
    self.initialized = true
    log("DataManagerFix initialized successfully")
    return true
end

-- Create a fallback DataManager if the original isn't found
function DataManagerFix:createFallbackDataManager()
    -- Create a minimal implementation that won't break the game
    DataManager = {
        playerData = {},
        
        getPlayerData = function(player)
            if typeof(player) ~= "Instance" or not player:IsA("Player") then
                return nil
            end
            
            -- Create default data if it doesn't exist
            if not DataManager.playerData[player.UserId] then
                DataManager.playerData[player.UserId] = table.clone(DataManagerFix.fallbackTemplates.playerData)
            end
            
            return DataManager.playerData[player.UserId]
        end,
        
        updatePlayerData = function(player, data)
            if typeof(player) ~= "Instance" or not player:IsA("Player") then
                return false
            end
            
            local playerData = DataManager.getPlayerData(player)
            if not playerData then
                return false
            end
            
            -- Update data fields
            for key, value in pairs(data) do
                playerData[key] = value
            end
            
            return true
        end,
        
        savePlayerData = function(player)
            -- In fallback mode, we just log that saving was attempted
            log("Fallback DataManager: savePlayerData called for " .. player.Name, "warn")
            return true
        end,
        
        loadPlayerData = function(player)
            -- In fallback mode, we create default data
            DataManager.playerData[player.UserId] = table.clone(DataManagerFix.fallbackTemplates.playerData)
            log("Fallback DataManager: Created default data for " .. player.Name, "warn")
            return true
        end
    }
    
    log("Created fallback DataManager implementation")
end

-- Enhance the existing DataManager with robust error handling
function DataManagerFix:enhanceDataManager()
    if not DataManager then return end
    
    log("Enhancing DataManager with fixes...")
    
    -- Store original functions
    local originalSave = DataManager.savePlayerData
    local originalLoad = DataManager.loadPlayerData
    local originalUpdate = DataManager.updatePlayerData
    
    -- Enhance save function with retries
    if typeof(originalSave) == "function" then
        DataManager.savePlayerData = function(player, ...)
            local success, result
            local attempts = 0
            
            while attempts < CONFIG.MAX_RETRIES do
                success, result = pcall(function() 
                    return originalSave(player, ...) 
                end)
                
                if success then
                    return result
                end
                
                attempts = attempts + 1
                log("Save attempt " .. attempts .. " failed for " .. player.Name .. ": " .. tostring(result), "warn")
                
                if attempts < CONFIG.MAX_RETRIES then
                    task.wait(CONFIG.RETRY_DELAY)
                end
            end
            
            log("All save attempts failed for " .. player.Name, "error")
            return false
        end
    end
    
    -- Enhance load function with fallback
    if typeof(originalLoad) == "function" then
        DataManager.loadPlayerData = function(player, ...)
            local success, result
            local attempts = 0
            
            while attempts < CONFIG.MAX_RETRIES do
                success, result = pcall(function() 
                    return originalLoad(player, ...) 
                end)
                
                if success and result then
                    return result
                end
                
                attempts = attempts + 1
                log("Load attempt " .. attempts .. " failed for " .. player.Name, "warn")
                
                if attempts < CONFIG.MAX_RETRIES then
                    task.wait(CONFIG.RETRY_DELAY)
                end
            end
            
            -- If loading failed and auto fallback is enabled, use fallback data
            if CONFIG.AUTO_FALLBACK then
                log("Using fallback data for " .. player.Name, "warn")
                
                -- Create default data
                local fallbackData = table.clone(self.fallbackTemplates.playerData)
                
                -- Update the player's data with fallback
                if typeof(DataManager.playerData) == "table" then
                    DataManager.playerData[player.UserId] = fallbackData
                end
                
                return true
            end
            
            log("All load attempts failed for " .. player.Name, "error")
            return false
        end
    end
    
    log("DataManager enhanced with robust error handling")
end

-- Set up player events
function DataManagerFix:setupPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        log("Player joined: " .. player.Name)
        
        -- Attempt to load data with our enhanced DataManager
        task.spawn(function()
            if DataManager and typeof(DataManager.loadPlayerData) == "function" then
                local success = DataManager.loadPlayerData(player)
                log("Data load " .. (success and "succeeded" or "failed") .. " for " .. player.Name)
            end
        end)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        log("Player leaving: " .. player.Name)
        
        -- Attempt to save data before player leaves
        if DataManager and typeof(DataManager.savePlayerData) == "function" then
            local success = DataManager.savePlayerData(player)
            log("Final data save " .. (success and "succeeded" or "failed") .. " for " .. player.Name)
        end
    end)
end

-- Get fallback data template
function DataManagerFix:getFallbackTemplate(templateName)
    return table.clone(self.fallbackTemplates[templateName] or {})
end

-- Add a pending operation
function DataManagerFix:addPendingOperation(player, operationType, data)
    if not self.pendingOperations[player.UserId] then
        self.pendingOperations[player.UserId] = {}
    end
    
    table.insert(self.pendingOperations[player.UserId], {
        type = operationType,
        data = data,
        timestamp = os.time()
    })
    
    log("Added pending " .. operationType .. " operation for " .. player.Name)
end

-- Process pending operations
function DataManagerFix:processPendingOperations(player)
    if not self.pendingOperations[player.UserId] then
        return
    end
    
    local operations = self.pendingOperations[player.UserId]
    log("Processing " .. #operations .. " pending operations for " .. player.Name)
    
    for _, operation in ipairs(operations) do
        if operation.type == "save" then
            if DataManager and typeof(DataManager.savePlayerData) == "function" then
                DataManager.savePlayerData(player)
            end
        elseif operation.type == "update" then
            if DataManager and typeof(DataManager.updatePlayerData) == "function" then
                DataManager.updatePlayerData(player, operation.data)
            end
        end
    end
    
    -- Clear processed operations
    self.pendingOperations[player.UserId] = {}
end

-- Automatically initialize if DataManager is available
task.spawn(function()
    DataManagerFix:initialize()
end)

return DataManagerFix
