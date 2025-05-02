--[[
    PlayerProgressRestoration.luau
    
    This module helps restore player progress when data is corrupted or missing.
    It works with DataManagerFix to provide fallback data and recovery options.
    
    Created as part of Phase 3 fixes: May 2, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    AUTOMATIC_RESTORATION = true,
    PROGRESS_THRESHOLD = 0.7, -- Threshold for partial data restoration (70%)
    MAX_HISTORY_ENTRIES = 5,  -- Number of historical data points to keep
    SAVE_HISTORY = true       -- Whether to save historical data
}

-- Debug logging
local function log(message, messageType)
    if CONFIG.DEBUG_MODE or messageType == "error" or messageType == "warn" then
        local prefix = "[PlayerProgressRestoration] "
        if messageType == "error" then
            warn(prefix .. "ERROR: " .. message)
        elseif messageType == "warn" then
            warn(prefix .. "WARNING: " .. message)
        else
            print(prefix .. message)
        end
    end
end

-- Try to require DataManagerFix
local DataManagerFix
pcall(function()
    local dataManagerFixModule = ServerScriptService:FindFirstChild("Core") and 
                               ServerScriptService.Core:FindFirstChild("DataManagerFix")
    
    if dataManagerFixModule then
        DataManagerFix = require(dataManagerFixModule)
    end
end)

-- Try to get DataManager from CoreRegistry
local CoreRegistry
local DataManager

pcall(function()
    local coreRegistryModule = ServerScriptService:FindFirstChild("Core") and 
                              ServerScriptService.Core:FindFirstChild("CoreRegistry") or
                              (ReplicatedStorage:FindFirstChild("shared") and 
                               ReplicatedStorage.shared:FindFirstChild("CoreRegistryRef"))
    
    if coreRegistryModule then
        CoreRegistry = require(coreRegistryModule)
        if CoreRegistry and CoreRegistry.getSystem then
            DataManager = CoreRegistry.getSystem("DataManager")
        end
    end
end)

-- The PlayerProgressRestoration module
local PlayerProgressRestoration = {
    initialized = false,
    dataHistory = {}, -- Store historical data for recovery
    restorationStats = {
        successfulRestorations = 0,
        failedRestorations = 0,
        partialRestorations = 0
    }
}

-- Initialize the module
function PlayerProgressRestoration:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing PlayerProgressRestoration...")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("PlayerProgressRestoration", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up player events
    self:setupPlayerEvents()
    
    self.initialized = true
    log("PlayerProgressRestoration initialized successfully")
    return true
end

-- Set up player events
function PlayerProgressRestoration:setupPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        if not CONFIG.AUTOMATIC_RESTORATION then return end
        
        log("Monitoring data for player: " .. player.Name)
        
        -- Wait a moment for data to load
        task.delay(3, function()
            self:validatePlayerData(player)
        end)
    end)
    
    -- Handle data saving
    if DataManager and typeof(DataManager.savePlayerData) == "function" then
        -- Original function
        local originalSave = DataManager.savePlayerData
        
        -- Enhanced function that keeps history
        DataManager.savePlayerData = function(player, ...)
            if CONFIG.SAVE_HISTORY then
                -- Save current data to history before it's updated
                local currentData = DataManager.getPlayerData and DataManager.getPlayerData(player)
                if currentData then
                    self:addDataToHistory(player, currentData)
                end
            end
            
            -- Call original function
            return originalSave(player, ...)
        end
    end
end

-- Add data to history
function PlayerProgressRestoration:addDataToHistory(player, data)
    if not player or not data then return end
    
    if not self.dataHistory[player.UserId] then
        self.dataHistory[player.UserId] = {}
    end
    
    -- Create a deep copy of the data
    local dataCopy = table.clone(data)
    dataCopy._timestamp = os.time()
    
    -- Add to history
    table.insert(self.dataHistory[player.UserId], 1, dataCopy)
    
    -- Trim history to maximum length
    while #self.dataHistory[player.UserId] > CONFIG.MAX_HISTORY_ENTRIES do
        table.remove(self.dataHistory[player.UserId])
    end
    
    log("Added data snapshot to history for " .. player.Name)
end

-- Validate player data and restore if necessary
function PlayerProgressRestoration:validatePlayerData(player)
    if not player then return false end
    
    log("Validating data for player: " .. player.Name)
    
    -- Get current data
    local currentData = DataManager and DataManager.getPlayerData and DataManager.getPlayerData(player)
    if not currentData then
        log("No data found for " .. player.Name .. ", attempting restoration", "warn")
        return self:restorePlayerData(player)
    end
    
    -- Check for data corruption or incompleteness
    local isValid, issues = self:checkDataValidity(currentData)
    if not isValid then
        log("Data validation failed for " .. player.Name .. ": " .. table.concat(issues, ", "), "warn")
        return self:restorePlayerData(player)
    end
    
    log("Data validated successfully for " .. player.Name)
    return true
end

-- Check if data is valid
function PlayerProgressRestoration:checkDataValidity(data)
    if not data then return false, {"Data is nil"} end
    
    local issues = {}
    
    -- Check for required fields
    if not data.coins and data.coins ~= 0 then table.insert(issues, "Missing coins") end
    if not data.level and data.level ~= 0 then table.insert(issues, "Missing level") end
    if not data.tycoon then table.insert(issues, "Missing tycoon data") end
    
    -- Check for corrupt values
    if data.coins and (typeof(data.coins) ~= "number" or data.coins < 0) then
        table.insert(issues, "Invalid coins value")
    end
    
    if data.level and (typeof(data.level) ~= "number" or data.level < 0) then
        table.insert(issues, "Invalid level value")
    end
    
    -- More detailed validation could be added here
    
    return #issues == 0, issues
end

-- Restore player data from history or template
function PlayerProgressRestoration:restorePlayerData(player)
    if not player then return false end
    
    log("Attempting to restore data for " .. player.Name)
    
    -- Check history first
    local restoredFromHistory = self:restoreFromHistory(player)
    if restoredFromHistory then
        log("Successfully restored data from history for " .. player.Name)
        self.restorationStats.successfulRestorations += 1
        return true
    end
    
    -- If no history, use template
    local restoredFromTemplate = self:restoreFromTemplate(player)
    if restoredFromTemplate then
        log("Restored default template data for " .. player.Name, "warn")
        self.restorationStats.partialRestorations += 1
        return true
    end
    
    log("Failed to restore any data for " .. player.Name, "error")
    self.restorationStats.failedRestorations += 1
    return false
end

-- Restore from history
function PlayerProgressRestoration:restoreFromHistory(player)
    if not player or not self.dataHistory[player.UserId] or #self.dataHistory[player.UserId] == 0 then
        return false
    end
    
    -- Get most recent historical data
    local historicalData = self.dataHistory[player.UserId][1]
    if not historicalData then return false end
    
    -- Validate historical data
    local isValid = self:checkDataValidity(historicalData)
    if not isValid then
        log("Historical data is invalid for " .. player.Name, "warn")
        return false
    end
    
    -- Apply historical data
    if DataManager and typeof(DataManager.updatePlayerData) == "function" then
        -- Remove timestamp before applying
        historicalData._timestamp = nil
        
        local success = DataManager.updatePlayerData(player, historicalData)
        if success then
            log("Restored historical data from " .. os.date("%c", historicalData._timestamp or 0) .. " for " .. player.Name)
            return true
        end
    end
    
    return false
end

-- Restore from template
function PlayerProgressRestoration:restoreFromTemplate(player)
    if not player then return false end
    
    -- Get template data
    local templateData
    
    -- Try to get template from DataManagerFix
    if DataManagerFix and typeof(DataManagerFix.getFallbackTemplate) == "function" then
        templateData = DataManagerFix:getFallbackTemplate("playerData")
    end
    
    -- If no template from DataManagerFix, use our own
    if not templateData then
        templateData = {
            coins = 0,
            level = 1,
            inventory = {},
            tutorial = {
                completed = false,
                step = 0
            },
            tycoon = {
                tiles = {},
                lastSave = os.time()
            }
        }
    end
    
    -- Apply template data
    if DataManager and typeof(DataManager.updatePlayerData) == "function" then
        local success = DataManager.updatePlayerData(player, templateData)
        if success then
            log("Applied template data for " .. player.Name)
            return true
        end
    end
    
    return false
end

-- Get statistics about restorations
function PlayerProgressRestoration:getStats()
    return {
        successfulRestorations = self.restorationStats.successfulRestorations,
        failedRestorations = self.restorationStats.failedRestorations,
        partialRestorations = self.restorationStats.partialRestorations,
        totalAttempts = self.restorationStats.successfulRestorations + 
                        self.restorationStats.failedRestorations + 
                        self.restorationStats.partialRestorations,
        historySize = {
            players = 0,
            entries = 0
        }
    }
end

-- Automatically initialize
task.spawn(function()
    PlayerProgressRestoration:initialize()
end)

return PlayerProgressRestoration
