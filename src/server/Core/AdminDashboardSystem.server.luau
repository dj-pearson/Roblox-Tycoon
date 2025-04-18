-- AdminDashboardSystem.server.luau
-- System for managing admin dashboard functionality
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create remote events for admin dashboard
local remotes = Instance.new("Folder")
remotes.Name = "AdminRemotes"
remotes.Parent = ReplicatedStorage

local getStatsEvent = Instance.new("RemoteFunction")
getStatsEvent.Name = "GetGameStats"
getStatsEvent.Parent = remotes

local executeCommandEvent = Instance.new("RemoteFunction")
executeCommandEvent.Name = "ExecuteAdminCommand"
executeCommandEvent.Parent = remotes

local refreshDataEvent = Instance.new("RemoteEvent")
refreshDataEvent.Name = "RefreshAdminData"
refreshDataEvent.Parent = remotes

local AdminDashboardSystem = {
    -- Configuration
    CONFIG = {
        -- List of admin user IDs (replace with actual admin IDs)
        ADMIN_IDS = {
            7768610061, -- Replace with actual admin user IDs
            -- Add more admin IDs here
        },
        -- How often to auto-refresh stats (in seconds)
        REFRESH_INTERVAL = 30
    },
    
    -- Cache for current game stats
    cachedStats = {},
    
    -- Player action logs
    actionLogs = {},
    
    -- Maximum logs to keep
    MAX_LOGS = 1000
}

-- Check if player is an admin
function AdminDashboardSystem:isAdmin(player)
    if not player then return false end

    -- Check if player's ID is in the admin list
    for _, adminId in ipairs(self.CONFIG.ADMIN_IDS) do
        if player.UserId == adminId then
            return true
        end
    end

    return false
end

-- Initialize the system
function AdminDashboardSystem:initialize()
    self:setupRemotes()
    self:startStatsRefreshLoop()
    self:connectPlayerEvents()
    
    print("AdminDashboardSystem initialized")
end

-- Set up remote events
function AdminDashboardSystem:setupRemotes()
    -- Handle requests for game statistics
    getStatsEvent.OnServerInvoke = function(player)
        if not self:isAdmin(player) then
            return {success = false, message = "Unauthorized access"}
        end
        
        return self:getGameStats()
    end
    
    -- Handle admin commands
    executeCommandEvent.OnServerInvoke = function(player, commandData)
        if not self:isAdmin(player) then
            return {success = false, message = "Unauthorized access"}
        end
        
        return self:executeCommand(player, commandData)
    end
end

-- Start a loop to periodically refresh cached game stats
function AdminDashboardSystem:startStatsRefreshLoop()
    spawn(function()
        while true do
            self:refreshGameStats()
            
            -- Notify admin clients that data has been updated
            for _, player in ipairs(Players:GetPlayers()) do
                if self:isAdmin(player) then
                    refreshDataEvent:FireClient(player)
                end
            end
            
            wait(self.CONFIG.REFRESH_INTERVAL)
        end
    end)
end

-- Connect to player events to track activity
function AdminDashboardSystem:connectPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        self:logAction("PlayerJoin", {
            player = player.Name,
            userId = player.UserId,
            timestamp = os.time()
        })
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:logAction("PlayerLeave", {
            player = player.Name,
            userId = player.UserId,
            timestamp = os.time()
        })
    end)
end

-- Collect game statistics
function AdminDashboardSystem:refreshGameStats()
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local DataManager = CoreRegistry.getSystem("DataManager")
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    local NPCSystem = CoreRegistry.getSystem("NPCSystem")
    local RevenueSystem = CoreRegistry.getSystem("RevenueSystem")
    
    -- Build statistics
    local stats = {
        general = {
            playerCount = #Players:GetPlayers(),
            serverUptime = os.time() - game:GetService("Stats"):GetStartTime(),
            serverMemoryUsageMB = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()),
            timestamp = os.time()
        },
        players = {},
        revenue = {},
        npcs = {
            count = NPCSystem and NPCSystem:getTotalNPCCount() or 0
        },
        tycoons = {
            count = TycoonSystem and TycoonSystem:getTotalTycoonCount() or 0
        }
    }
    
    -- Player stats
    for _, player in ipairs(Players:GetPlayers()) do
        local playerData = DataManager and DataManager:getPlayerData(player) or {}
        local tycoon = TycoonSystem and TycoonSystem:getTycoonForPlayer(player) or nil
        
        stats.players[player.Name] = {
            id = player.UserId,
            money = playerData.money or 0,
            level = playerData.level or 0,
            equipment = playerData.equipment and #playerData.equipment or 0,
            membersCount = tycoon and tycoon:getMemberCount() or 0,
            revenue = RevenueSystem and RevenueSystem:getPlayerTotalRevenue(player) or 0,
            joinTime = player:GetJoinTime(),
            premium = player.MembershipType == Enum.MembershipType.Premium
        }
    end
    
    -- Game revenue stats
    if RevenueSystem then
        stats.revenue = {
            totalRevenue = RevenueSystem:getTotalGameRevenue(),
            averageRevenue = RevenueSystem:getAveragePlayerRevenue(),
            topEarners = RevenueSystem:getTopEarners(5)
        }
    end
    
    -- Update cached stats
    self.cachedStats = stats
end

-- Get current game stats
function AdminDashboardSystem:getGameStats()
    return {
        success = true,
        stats = self.cachedStats,
        logs = self:getRecentLogs(50) -- Return last 50 logs
    }
end

-- Log an admin action
function AdminDashboardSystem:logAction(actionType, data)
    local logEntry = {
        type = actionType,
        data = data,
        timestamp = os.time()
    }
    
    -- Add to logs
    table.insert(self.actionLogs, logEntry)
    
    -- Trim logs if necessary
    if #self.actionLogs > self.MAX_LOGS then
        table.remove(self.actionLogs, 1)
    end
end

-- Get recent logs
function AdminDashboardSystem:getRecentLogs(count)
    count = count or 50
    local logs = {}
    
    local startIdx = math.max(1, #self.actionLogs - count + 1)
    for i = startIdx, #self.actionLogs do
        table.insert(logs, self.actionLogs[i])
    end
    
    return logs
end

-- Execute an admin command
function AdminDashboardSystem:executeCommand(player, commandData)
    local commandType = commandData.type
    local params = commandData.params or {}
    
    -- Log the command
    self:logAction("AdminCommand", {
        admin = player.Name,
        command = commandType,
        params = params,
        timestamp = os.time()
    })
    
    -- Handle different command types
    if commandType == "resetPlayerMoney" then
        return self:resetPlayerMoney(params.targetName)
    elseif commandType == "resetPlayerProgress" then
        return self:resetPlayerProgress(params.targetName)
    elseif commandType == "kickPlayer" then
        return self:kickPlayer(params.targetName, params.reason)
    elseif commandType == "banPlayer" then
        return self:banPlayer(params.targetName, params.duration, params.reason)
    elseif commandType == "giveRewards" then
        return self:giveRewards(params.targetName, params.rewardType, params.amount)
    elseif commandType == "broadcast" then
        return self:broadcastMessage(params.message)
    elseif commandType == "toggleSeason" then
        return self:toggleSeasonalEvent(params.seasonName, params.enabled)
    elseif commandType == "removeEquipment" then
        return self:removePlayerEquipment(params.targetName, params.equipmentId)
    elseif commandType == "modifyGameConfig" then
        return self:modifyGameConfiguration(params.configKey, params.configValue)
    end
    
    return {success = false, message = "Unknown command type: " .. commandType}
end

-- Reset a player's money
function AdminDashboardSystem:resetPlayerMoney(targetName)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local DataManager = CoreRegistry.getSystem("DataManager")
    
    if DataManager then
        local success = pcall(function()
            local playerData = DataManager:getPlayerData(targetPlayer)
            playerData.money = 0
            DataManager:savePlayerData(targetPlayer, playerData)
        end)
        
        if success then
            return {success = true, message = "Reset money for " .. targetPlayer.Name}
        else
            return {success = false, message = "Failed to reset money for " .. targetPlayer.Name}
        end
    else
        return {success = false, message = "DataManager not available"}
    end
end

-- Reset a player's progress
function AdminDashboardSystem:resetPlayerProgress(targetName)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local DataManager = CoreRegistry.getSystem("DataManager")
    
    if DataManager then
        local success = pcall(function()
            DataManager:resetPlayerData(targetPlayer)
        end)
        
        if success then
            return {success = true, message = "Reset progress for " .. targetPlayer.Name}
        else
            return {success = false, message = "Failed to reset progress for " .. targetPlayer.Name}
        end
    else
        return {success = false, message = "DataManager not available"}
    end
end

-- Kick a player
function AdminDashboardSystem:kickPlayer(targetName, reason)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    reason = reason or "Kicked by an administrator"
    
    local success = pcall(function()
        targetPlayer:Kick(reason)
    end)
    
    if success then
        return {success = true, message = "Kicked " .. targetPlayer.Name .. " for: " .. reason}
    else
        return {success = false, message = "Failed to kick " .. targetPlayer.Name}
    end
end

-- Ban a player
function AdminDashboardSystem:banPlayer(targetName, duration, reason)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local SanctionSystem = CoreRegistry.getSystem("PlayerSanctionSystem")
    
    if SanctionSystem then
        local sanctionType = duration and SanctionSystem.CONFIG.sanctionLevels.TEMP_BAN or SanctionSystem.CONFIG.sanctionLevels.PERM_BAN
        
        local success = pcall(function()
            SanctionSystem.applySanction(
                targetPlayer, 
                sanctionType, 
                reason or "Banned by an administrator", 
                "Admin Dashboard",
                duration
            )
        end)
        
        if success then
            local banType = duration and ("for " .. duration .. " days") or "permanently"
            return {success = true, message = "Banned " .. targetPlayer.Name .. " " .. banType}
        else
            return {success = false, message = "Failed to ban " .. targetPlayer.Name}
        end
    else
        return {success = false, message = "SanctionSystem not available"}
    end
end

-- Give rewards to a player
function AdminDashboardSystem:giveRewards(targetName, rewardType, amount)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then
        return {success = false, message = "Invalid reward amount"}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local DataManager = CoreRegistry.getSystem("DataManager")
    
    if DataManager then
        local playerData = DataManager:getPlayerData(targetPlayer)
        local success = false
        local message = ""
        
        if rewardType == "money" then
            playerData.money = (playerData.money or 0) + amount
            success = true
            message = "Gave $" .. amount .. " to " .. targetPlayer.Name
        elseif rewardType == "level" then
            playerData.level = (playerData.level or 0) + amount
            success = true
            message = "Gave " .. amount .. " levels to " .. targetPlayer.Name
        else
            return {success = false, message = "Unknown reward type: " .. rewardType}
        end
        
        if success then
            DataManager:savePlayerData(targetPlayer, playerData)
            return {success = true, message = message}
        end
    end
    
    return {success = false, message = "Failed to give rewards to " .. targetPlayer.Name}
end

-- Broadcast a message to all players
function AdminDashboardSystem:broadcastMessage(message)
    if not message or message == "" then
        return {success = false, message = "Empty message"}
    end
    
    -- Create and show message to all players
    for _, player in ipairs(Players:GetPlayers()) do
        -- Create a GUI message for each player
        pcall(function()
            local notification = Instance.new("Message")
            notification.Text = "[ADMIN BROADCAST] " .. message
            notification.Parent = player
            game:GetService("Debris"):AddItem(notification, 5)
        end)
    end
    
    return {success = true, message = "Broadcast sent to all players"}
end

-- Toggle seasonal event
function AdminDashboardSystem:toggleSeasonalEvent(seasonName, enabled)
    if not seasonName or seasonName == "" then
        return {success = false, message = "Invalid season name"}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local SeasonalSystem = CoreRegistry.getSystem("SeasonalSystem")
    
    if SeasonalSystem then
        local success = pcall(function()
            if enabled then
                SeasonalSystem:startSeason(seasonName)
            else
                SeasonalSystem:endSeason(seasonName)
            end
        end)
        
        if success then
            local action = enabled and "Started" or "Ended"
            return {success = true, message = action .. " seasonal event: " .. seasonName}
        else
            return {success = false, message = "Failed to toggle seasonal event: " .. seasonName}
        end
    else
        return {success = false, message = "SeasonalSystem not available"}
    end
end

-- Remove player equipment
function AdminDashboardSystem:removePlayerEquipment(targetName, equipmentId)
    local targetPlayer = self:findPlayerByName(targetName)
    if not targetPlayer then
        return {success = false, message = "Player not found: " .. targetName}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local DataManager = CoreRegistry.getSystem("DataManager")
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    
    if DataManager and TycoonSystem then
        local playerData = DataManager:getPlayerData(targetPlayer)
        local tycoon = TycoonSystem:getTycoonForPlayer(targetPlayer)
        
        if not playerData.equipment then
            return {success = false, message = "Player has no equipment data"}
        end
        
        local success = pcall(function()
            -- Remove from data
            for i, equip in ipairs(playerData.equipment) do
                if equip.id == equipmentId then
                    table.remove(playerData.equipment, i)
                    break
                end
            end
            
            -- Remove from tycoon if it exists
            if tycoon then
                tycoon:removeEquipment(equipmentId)
            end
            
            -- Save updated data
            DataManager:savePlayerData(targetPlayer, playerData)
        end)
        
        if success then
            return {success = true, message = "Removed equipment " .. equipmentId .. " from " .. targetPlayer.Name}
        else
            return {success = false, message = "Failed to remove equipment"}
        end
    else
        return {success = false, message = "Required systems not available"}
    end
end

-- Modify game configuration
function AdminDashboardSystem:modifyGameConfiguration(configKey, configValue)
    if not configKey or configKey == "" then
        return {success = false, message = "Invalid configuration key"}
    end
    
    local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry"))
    local ConfigManager = CoreRegistry.getSystem("ConfigManager")
    
    if ConfigManager then
        local success = pcall(function()
            ConfigManager:setConfigValue(configKey, configValue)
        end)
        
        if success then
            return {success = true, message = "Modified game configuration: " .. configKey .. " = " .. tostring(configValue)}
        else
            return {success = false, message = "Failed to modify game configuration"}
        end
    else
        return {success = false, message = "ConfigManager not available"}
    end
end

-- Helper function to find player by name
function AdminDashboardSystem:findPlayerByName(name)
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

return AdminDashboardSystem