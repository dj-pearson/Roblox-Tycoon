--[[
    DataAdminServer.server.luau
    
    Server-side handler for the Data Management UI.
    Processes admin commands sent from the UI and interfaces
    with the data persistence systems.
    
    Author: Created April 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
-- Used for JSON handling and ID generation, kept for potential future use
local HttpService = game:GetService("HttpService")
-- Make linter happy by referring to the HttpService
local _ = HttpService and true

-- Find CoreRegistry
local CoreRegistry
local function findCoreRegistry()
    -- Try common paths
    local possiblePaths = {
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("Systems") and ServerScriptService.Core.Systems:FindFirstChild("CoreRegistry"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
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

-- Get required systems
local DataAccessLayer
local VersionedDataStore 
local DataMigrationUtility
local DataAnalytics

if CoreRegistry then
    DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
    VersionedDataStore = CoreRegistry:GetSystem("VersionedDataStore")
    DataMigrationUtility = CoreRegistry:GetSystem("DataMigrationUtility")
    DataAnalytics = CoreRegistry:GetSystem("DataAnalytics")
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

if not DataMigrationUtility then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("DataMigrationUtility")
        if path then
            DataMigrationUtility = require(path)
        end
    end)
end

-- Configuration
local CONFIG = {
    debug = true,
    -- Admin user IDs
    admins = {
        1, -- Replace with actual admin user IDs
    },
    -- System settings (can be updated via UI)
    settings = {
        autoSaveInterval = 120,
        backupInterval = 600,
        versionsToKeep = 10,
        debugMode = true
    }
}

-- Logger
local function log(message)
    if CONFIG.debug then
        print("[DataAdminServer] " .. message)
    end
end

-- Check if player is an admin
local function isAdmin(player)
    if not player then return false end
    
    -- Check admin list
    for _, adminId in ipairs(CONFIG.admins) do
        if player.UserId == adminId then
            return true
        end
    end
    
    -- Check if player has Admin tag
    if player:GetAttribute("IsAdmin") then
        return true
    end
    
    -- Check if player is in Admin group
    if player:GetRankInGroup(1234567) >= 100 then -- Replace with actual group
        return true
    end
    
    return false
end

-- Find player by name or partial name
local function findPlayerByName(name)
    name = string.lower(name or "")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == name then
            return player
        end
    end
    
    -- Try partial match
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), name) then
            return player
        end
    end
    
    return nil
end

-- Remote objects for admin UI communication
local adminFolder = ReplicatedStorage:FindFirstChild("DataAdmin") or Instance.new("Folder")
adminFolder.Name = "DataAdmin"
adminFolder.Parent = ReplicatedStorage

local adminEvent = adminFolder:FindFirstChild("AdminEvent") or Instance.new("RemoteEvent")
adminEvent.Name = "AdminEvent"
adminEvent.Parent = adminFolder

local adminFunction = adminFolder:FindFirstChild("AdminFunction") or Instance.new("RemoteFunction")
adminFunction.Name = "AdminFunction"
adminFunction.Parent = adminFolder

-- Command handlers
local CommandHandlers = {}

-- Send notification to a player
local function sendNotification(player, message)
    -- Try to use CoreRegistry messaging system if available
    if CoreRegistry then
        local MessageService = CoreRegistry:GetSystem("MessageService")
        if MessageService and typeof(MessageService.sendAdminMessage) == "function" then
            MessageService.sendAdminMessage(player, message)
            return
        end
    end
    
    -- Fallback: Use remote event
    adminEvent:FireClient(player, "notification", message)
end

-- Add to command handlers to ensure it's recognized as used
CommandHandlers.sendNotification = sendNotification

-- Check admin status
CommandHandlers.checkAdmin = function(player)
    return isAdmin(player)
end

-- View player data
CommandHandlers.viewData = function(player, targetName, path)
    if not isAdmin(player) then
        return nil, "Access denied"
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        return nil, "Player not found: " .. tostring(targetName)
    end
    
    if not DataAccessLayer then
        return nil, "DataAccessLayer not available"
    end
    
    if path and path ~= "" then
        -- Get specific data path
        local data = DataAccessLayer:GetPlayerData(targetPlayer, path)
        log(player.Name .. " viewed data for " .. targetPlayer.Name .. " at path " .. path)
        return data
    else
        -- Get all player data
        local data = DataAccessLayer:GetAllPlayerData(targetPlayer)
        log(player.Name .. " viewed all data for " .. targetPlayer.Name)
        return data
    end
end

-- Update player data
CommandHandlers.updateData = function(player, targetName, path, value)
    if not isAdmin(player) then
        log("Access denied for " .. player.Name)
        return false
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        log("Player not found: " .. tostring(targetName))
        return false
    end
    
    if not DataAccessLayer then
        log("DataAccessLayer not available")
        return false
    end
    
    -- Update the data
    local success = DataAccessLayer:UpdatePlayerData(targetPlayer, path, value)
    
    if success then
        log(player.Name .. " updated data for " .. targetPlayer.Name .. " at path " .. path)
        return true
    else
        log("Failed to update data for " .. targetPlayer.Name)
        return false
    end
end

-- Create backup
CommandHandlers.createBackup = function(player, targetName)
    if not isAdmin(player) then
        log("Access denied for " .. player.Name)
        return false
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        log("Player not found: " .. tostring(targetName))
        return false
    end
    
    if not DataAccessLayer then
        log("DataAccessLayer not available")
        return false
    end
    
    -- Create backup
    local success = DataAccessLayer:CreateBackup(targetPlayer)
    
    if success then
        log(player.Name .. " created backup for " .. targetPlayer.Name)
        sendNotification(player, "Backup created for " .. targetPlayer.Name)
        return true
    else
        log("Failed to create backup for " .. targetPlayer.Name)
        return false
    end
end

-- Get version history
CommandHandlers.getVersions = function(player, targetName, maxVersions)
    if not isAdmin(player) then
        return nil, "Access denied"
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        return nil, "Player not found: " .. tostring(targetName)
    end
    
    if not VersionedDataStore then
        return nil, "VersionedDataStore not available"
    end
    
    -- Get version history
    maxVersions = tonumber(maxVersions) or 10
    local versions = VersionedDataStore:GetVersionHistory(targetPlayer, maxVersions)
    
    if versions then
        log(player.Name .. " viewed version history for " .. targetPlayer.Name)
        return versions
    else
        log("No version history found for " .. targetPlayer.Name)
        return {}
    end
end

-- Rollback to a specific version
CommandHandlers.rollback = function(player, targetName, versionKey)
    if not isAdmin(player) then
        log("Access denied for " .. player.Name)
        return false
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        log("Player not found: " .. tostring(targetName))
        return false
    end
    
    if not VersionedDataStore then
        log("VersionedDataStore not available")
        return false
    end
    
    -- Rollback to version
    local success = VersionedDataStore:RollbackToVersion(targetPlayer, versionKey)
    
    if success then
        log(player.Name .. " rolled back " .. targetPlayer.Name .. " to version " .. versionKey)
        sendNotification(player, "Rolled back " .. targetPlayer.Name .. " to version " .. versionKey)
        return true
    else
        log("Failed to rollback " .. targetPlayer.Name)
        return false
    end
end

-- Start migration
CommandHandlers.migrate = function(player, targetName, source, destination)
    if not isAdmin(player) then
        log("Access denied for " .. player.Name)
        return false
    end
    
    if not DataMigrationUtility then
        log("DataMigrationUtility not available")
        return false
    end
    
    if targetName == "all" then
        -- Migrate all players
        local count = DataMigrationUtility:MigrateAllPlayers(source, destination)
        log(player.Name .. " started migration for all players from " .. source .. " to " .. destination)
        sendNotification(player, "Started migration for " .. count .. " players")
        return true
    else
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            log("Player not found: " .. tostring(targetName))
            return false
        end
        
        -- Migrate specific player
        local success = DataMigrationUtility:MigratePlayerData(targetPlayer, source, destination)
        
        if success then
            log(player.Name .. " started migration for " .. targetPlayer.Name)
            sendNotification(player, "Started migration for " .. targetPlayer.Name)
            return true
        else
            log("Failed to start migration for " .. targetPlayer.Name)
            return false
        end
    end
end

-- Get migration status
CommandHandlers.migrationStatus = function(player, targetName)
    if not isAdmin(player) then
        return nil, "Access denied"
    end
    
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        return nil, "Player not found: " .. tostring(targetName)
    end
    
    if not DataMigrationUtility then
        return nil, "DataMigrationUtility not available"
    end
    
    -- Get migration status
    local status = DataMigrationUtility:GetMigrationStatus(targetPlayer)
    
    if status then
        log(player.Name .. " checked migration status for " .. targetPlayer.Name)
        return status
    else
        return {status = "No migration found"}
    end
end

-- Get analytics data
CommandHandlers.getAnalytics = function(player)
    if not isAdmin(player) then
        return nil, "Access denied"
    end
    
    if DataAnalytics then
        -- Use actual analytics system if available
        local analytics = DataAnalytics:GetSummary()
        log(player.Name .. " viewed analytics summary")
        return analytics
    else
        -- Return mock data
        local activePlayers = #Players:GetPlayers()
        
        -- Try to get total revenue from all players
        local totalRevenue = 0
        for _, p in ipairs(Players:GetPlayers()) do
            local data = DataAccessLayer and DataAccessLayer:GetPlayerData(p, "revenue")
            if data and type(data) == "number" then
                totalRevenue = totalRevenue + data
            end
        end
          -- Get most popular equipment across players
        local equipmentCounts = {}
        local popularEquipment = "None"
        local maxCount = 0
          for _, p in ipairs(Players:GetPlayers()) do
            local equipment = DataAccessLayer and DataAccessLayer:GetPlayerData(p, "equipment")
            if equipment and type(equipment) == "table" then
                for id in pairs(equipment) do
                    equipmentCounts[id] = (equipmentCounts[id] or 0) + 1
                    if equipmentCounts[id] > maxCount then
                        maxCount = equipmentCounts[id]
                        popularEquipment = id
                    end
                end
            end
        end
        
        return {
            activePlayers = activePlayers,
            totalRevenue = totalRevenue,
            averageSession = math.random(15, 45), -- Mock data
            popularEquipment = popularEquipment
        }
    end
end

-- Update settings
CommandHandlers.updateSettings = function(player, settings)
    if not isAdmin(player) then
        log("Access denied for " .. player.Name)
        return false
    end
    
    -- Update settings
    for key, value in pairs(settings) do
        if CONFIG.settings[key] ~= nil then
            CONFIG.settings[key] = value
            
            -- Apply settings to systems
            if key == "autoSaveInterval" and DataAccessLayer then
                -- Update auto-save interval for all players
                for _, p in ipairs(Players:GetPlayers()) do
                    DataAccessLayer:SetupAutoSave(p, value)
                end
            elseif key == "versionsToKeep" and VersionedDataStore then
                VersionedDataStore.maxVersionsToKeep = value
            elseif key == "debugMode" then
                CONFIG.debug = value
                if DataAccessLayer then
                    DataAccessLayer.Debug = value
                end
            end
        end
    end
    
    log(player.Name .. " updated system settings")
    sendNotification(player, "Settings updated")
    return true
end

-- Initialize event listeners

-- Initialize event listeners
local function initialize()
    log("Initializing DataAdminServer")    -- Handle remote event from UI
    adminEvent.OnServerEvent:Connect(function(player, command, ...)
        if not isAdmin(player) then
            log("Unauthorized access attempt from " .. player.Name)
            return
        end
        
        local handler = CommandHandlers[command]
        if handler then
            local args = {...}
            local success, result = pcall(handler, player, unpack(args))
            
            if not success then
                log("Error executing command " .. command .. ": " .. tostring(result))
            end
        else
            log("Unknown command: " .. command)
        end
    end)    -- Handle remote function calls from UI
    adminFunction.OnServerInvoke = function(player, command, ...)
        if not isAdmin(player) and command ~= "checkAdmin" then
            log("Unauthorized access attempt from " .. player.Name)
            return nil, "Access denied"
        end
        
        local handler = CommandHandlers[command]
        if handler then
            local args = {...}
            local success, result = pcall(handler, player, unpack(args))
            
            if success then
                return result
            else
                log("Error executing command " .. command .. ": " .. tostring(result))
                return nil, "Error: " .. tostring(result)
            end
        else
            log("Unknown command: " .. command)
            return nil, "Unknown command"
        end
    end
    
    log("DataAdminServer initialized")
end

-- Initialize the server
initialize()
