--[[
    DataAdminSystem.server.luau
    
    An admin system for debugging and managing player data.
    This provides in-game commands for data operations such as
    viewing, saving, and restoring player data.
    
    Author: Created April 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
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

-- Get required systems
local DataAccessLayer
local VersionedDataStore 
local DataMigrationUtility

if CoreRegistry then
    DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
    VersionedDataStore = CoreRegistry:GetSystem("VersionedDataStore")
    DataMigrationUtility = CoreRegistry:GetSystem("DataMigrationUtility")
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
    -- Admin user IDs
    admins = {
        7768610061, -- Only authorized admin
    },
    
    -- Command prefix
    prefix = "/data",
    
    -- Debug mode
    debug = true
}

-- Debug function
local function log(message)
    if CONFIG.debug then
        print("[DataAdminSystem] " .. message)
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

-- Pretty print table for output
local function prettyPrint(value, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    if type(value) == "table" then
        local result = "{\n"
        
        -- Process table entries
        for k, v in pairs(value) do
            result = result .. indentStr .. "  [" .. tostring(k) .. "] = "
            
            if type(v) == "table" then
                result = result .. prettyPrint(v, indent + 1)
            else
                result = result .. tostring(v)
            end
            
            result = result .. ",\n"
        end
        
        return result .. indentStr .. "}"
    else
        return tostring(value)
    end
end

-- Format size of table
local function formatSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
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

-- DataAdminSystem singleton
local DataAdminSystem = {
    CommandHandlers = {}
}

-- Initialize the system
function DataAdminSystem:Initialize()
    log("Initializing DataAdminSystem")
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry:RegisterSystem("DataAdminSystem", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up chat commands
    self:SetupChatCommands()
    
    -- Register command handlers
    self:RegisterCommands()
    
    return self
end

-- Set up chat commands
function DataAdminSystem:SetupChatCommands()
    -- Check if legacy chat is being used
    local success, _ = pcall(function()
        return game:GetService("Chat"):RegisterChatCallback(Enum.ChatCallbackType.OnServerReceivingMessage, function() end)
    end)
    
    if success then
        -- Use legacy chat system
        game:GetService("Chat"):RegisterChatCallback(Enum.ChatCallbackType.OnServerReceivingMessage, function(speakerName, message, channelName)
            local player = Players:FindFirstChild(speakerName)
            if player and isAdmin(player) then
                if message:sub(1, #CONFIG.prefix) == CONFIG.prefix then
                    -- Handle as command
                    self:HandleCommand(player, message:sub(#CONFIG.prefix + 2))
                    return true
                end
            end
            return false
        end)
    else
        -- Use PlayerAdded event for TextChatService 
        Players.PlayerAdded:Connect(function(player)
            if isAdmin(player) then
                player.Chatted:Connect(function(message)
                    if message:sub(1, #CONFIG.prefix) == CONFIG.prefix then
                        -- Handle as command
                        self:HandleCommand(player, message:sub(#CONFIG.prefix + 2))
                    end
                end)
            end
        end)
        
        -- Connect existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if isAdmin(player) then
                player.Chatted:Connect(function(message)
                    if message:sub(1, #CONFIG.prefix) == CONFIG.prefix then
                        -- Handle as command
                        self:HandleCommand(player, message:sub(#CONFIG.prefix + 2))
                    end
                end)
            end
        end
    end
    
    log("Chat commands initialized")
end

-- Handle admin commands
function DataAdminSystem:HandleCommand(player, commandString)
    if not player or not isAdmin(player) then
        return
    end
    
    -- Parse command and args
    local args = {}
    for arg in commandString:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    -- Extract command name
    local command = table.remove(args, 1)
    if not command then
        self:SendMessage(player, "Available commands:\n" .. self:GetHelpText())
        return
    end
    
    -- Execute handler if exists
    local handler = self.CommandHandlers[string.lower(command)]
    if handler then
        local success, result = pcall(function()
            return handler(player, args)
        end)
        
        if success then
            if result then
                self:SendMessage(player, result)
            end
        else
            self:SendMessage(player, "Error executing command: " .. tostring(result))
        end
    else
        self:SendMessage(player, "Unknown command: " .. command .. "\nAvailable commands:\n" .. self:GetHelpText())
    end
end

-- Register all command handlers
function DataAdminSystem:RegisterCommands()
    -- Help command
    self.CommandHandlers.help = function(player, args)
        return self:GetHelpText()
    end
    
    -- View player data
    self.CommandHandlers.view = function(player, args)
        local targetName = args[1] or player.Name
        local path = args[2]
        
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            return "Player not found: " .. targetName
        end
        
        if not DataAccessLayer then
            return "DataAccessLayer not available"
        end
        
        local data
        if path then
            data = DataAccessLayer:GetPlayerData(targetPlayer, path)
            if data then
                return "Data for " .. targetPlayer.Name .. " at path " .. path .. ":\n" .. prettyPrint(data)
            else
                return "No data found at path: " .. path
            end
        else
            data = DataAccessLayer:GetAllPlayerData(targetPlayer)
            if data then
                local summary = "Data summary for " .. targetPlayer.Name .. ":\n"
                summary = summary .. "- Cash: " .. tostring(data.cash) .. "\n"
                
                if data.equipment then
                    summary = summary .. "- Equipment: " .. formatSize(data.equipment) .. " items\n"
                end
                
                if data.members then
                    summary = summary .. "- Members: "
                    summary = summary .. "Regular=" .. tostring(data.members.regular or 0) .. ", "
                    summary = summary .. "VIP=" .. tostring(data.members.vip or 0) .. ", "
                    summary = summary .. "Premium=" .. tostring(data.members.premium or 0) .. "\n"
                end
                
                summary = summary .. "- Revenue: " .. tostring(data.revenue or 0) .. "\n"
                summary = summary .. "\nUse '/data view " .. targetPlayer.Name .. " [path]' to view specific data paths"
                
                return summary
            else
                return "No data found for player: " .. targetPlayer.Name
            end
        end
    end
    
    -- Save player data
    self.CommandHandlers.save = function(player, args)
        local targetName = args[1] or player.Name
        local immediate = args[2] == "true" or args[2] == "1"
        
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            return "Player not found: " .. targetName
        end
        
        if not DataAccessLayer then
            return "DataAccessLayer not available"
        end
        
        local success = DataAccessLayer:SavePlayerData(targetPlayer, immediate)
        if success then
            return "Successfully saved data for " .. targetPlayer.Name .. (immediate and " (immediate)" or "")
        else
            return "Failed to save data for " .. targetPlayer.Name
        end
    end
    
    -- Save with validation
    self.CommandHandlers.validate = function(player, args)
        local targetName = args[1] or player.Name
        
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            return "Player not found: " .. targetName
        end
        
        if not DataAccessLayer then
            return "DataAccessLayer not available"
        end
        
        local success, errorMsg = DataAccessLayer:SavePlayerDataWithValidation(targetPlayer, true)
        if success then
            return "Successfully validated and saved data for " .. targetPlayer.Name
        else
            return "Validation failed for " .. targetPlayer.Name .. ": " .. tostring(errorMsg)
        end
    end
    
    -- Create backup
    self.CommandHandlers.backup = function(player, args)
        local targetName = args[1] or player.Name
        
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            return "Player not found: " .. targetName
        end
        
        if not DataAccessLayer then
            return "DataAccessLayer not available"
        end
        
        local success = DataAccessLayer:CreateBackup(targetPlayer)
        if success then
            return "Successfully created backup for " .. targetPlayer.Name
        else
            return "Failed to create backup for " .. targetPlayer.Name
        end
    end
    
    -- Versioned store commands
    if VersionedDataStore then
        -- View version history
        self.CommandHandlers.versions = function(player, args)
            local targetName = args[1] or player.Name
            local maxVersions = tonumber(args[2]) or 5
            
            local targetPlayer = findPlayerByName(targetName)
            if not targetPlayer then
                return "Player not found: " .. targetName
            end
            
            local history = VersionedDataStore:GetVersionHistory(targetPlayer, maxVersions)
            if not history then
                return "No version history found for " .. targetPlayer.Name
            end
            
            local result = "Version history for " .. targetPlayer.Name .. ":\n"
            for i, version in ipairs(history) do
                local time = os.date("%Y-%m-%d %H:%M:%S", version.timestamp)
                result = result .. i .. ". " .. version.key .. " - " .. time .. "\n"
            end
            
            return result
        end
        
        -- Rollback to specific version
        self.CommandHandlers.rollback = function(player, args)
            local targetName = args[1]
            local versionKey = args[2]
            
            if not targetName or not versionKey then
                return "Usage: /data rollback [player] [version_key]"
            end
            
            local targetPlayer = findPlayerByName(targetName)
            if not targetPlayer then
                return "Player not found: " .. targetName
            end
            
            local success = VersionedDataStore:RollbackToVersion(targetPlayer, versionKey)
            if success then
                return "Successfully rolled back " .. targetPlayer.Name .. " to version " .. versionKey
            else
                return "Failed to rollback to version " .. versionKey
            end
        end
    end
    
    -- Migration commands
    if DataMigrationUtility then
        -- Start migration
        self.CommandHandlers.migrate = function(player, args)
            local targetName = args[1]
            local source = args[2] or "datamanager"
            local destination = args[3] or "versioned"
            
            if not targetName then
                return "Usage: /data migrate [player] [source] [destination]"
            end
            
            if targetName == "all" then
                local count = DataMigrationUtility:MigrateAllPlayers(source, destination)
                return "Started migration for " .. count .. " players"
            else
                local targetPlayer = findPlayerByName(targetName)
                if not targetPlayer then
                    return "Player not found: " .. targetName
                end
                
                local success = DataMigrationUtility:MigratePlayerData(targetPlayer, source, destination)
                if success then
                    return "Started migration for " .. targetPlayer.Name .. " from " .. source .. " to " .. destination
                else
                    return "Failed to start migration"
                end
            end
        end
        
        -- Check migration status
        self.CommandHandlers.migratestatus = function(player, args)
            local targetName = args[1]
            
            if not targetName then
                return "Usage: /data migratestatus [player]"
            end
            
            local targetPlayer = findPlayerByName(targetName)
            if not targetPlayer then
                return "Player not found: " .. targetName
            end
            
            local status = DataMigrationUtility:GetMigrationStatus(targetPlayer)
            if not status then
                return "No migration found for " .. targetPlayer.Name
            end
            
            local result = "Migration status for " .. targetPlayer.Name .. ":\n"
            result = result .. "- Source: " .. tostring(status.source) .. "\n"
            result = result .. "- Destination: " .. tostring(status.destination) .. "\n"
            result = result .. "- Status: " .. tostring(status.status) .. "\n"
            result = result .. "- In progress: " .. tostring(status.inProgress) .. "\n"
            
            if status.startTime then
                result = result .. "- Started: " .. os.date("%Y-%m-%d %H:%M:%S", status.startTime) .. "\n"
            end
            
            if status.completeTime then
                result = result .. "- Completed: " .. os.date("%Y-%m-%d %H:%M:%S", status.completeTime) .. "\n"
                local duration = status.completeTime - status.startTime
                result = result .. "- Duration: " .. duration .. " seconds\n"
            end
            
            return result
        end
    end
    
    -- Debug commands
    self.CommandHandlers.debug = function(player, args)
        local enable = args[1]
        
        if enable == "on" or enable == "true" or enable == "1" then
            CONFIG.debug = true
            return "Debug mode enabled"
        elseif enable == "off" or enable == "false" or enable == "0" then
            CONFIG.debug = false
            return "Debug mode disabled"
        else
            return "Debug mode is currently: " .. tostring(CONFIG.debug) .. "\nUse '/data debug on' or '/data debug off'"
        end
    end
    
    -- Force reload player data
    self.CommandHandlers.reload = function(player, args)
        local targetName = args[1] or player.Name
        
        local targetPlayer = findPlayerByName(targetName)
        if not targetPlayer then
            return "Player not found: " .. targetName
        end
        
        if not DataAccessLayer then
            return "DataAccessLayer not available"
        end
        
        local data = DataAccessLayer:LoadPlayerData(targetPlayer)
        if data then
            DataAccessLayer:ApplyDataToPlayer(targetPlayer, data)
            return "Successfully reloaded data for " .. targetPlayer.Name
        else
            return "Failed to reload data for " .. targetPlayer.Name
        end
    end
end

-- Get help text for commands
function DataAdminSystem:GetHelpText()
    local help = "Data Admin Commands:\n"
    help = help .. "- help: Show this help text\n"
    help = help .. "- view [player] [path]: View player data\n"
    help = help .. "- save [player] [immediate]: Save player data\n"
    help = help .. "- validate [player]: Validate and save player data\n"
    help = help .. "- backup [player]: Create data backup\n"
    
    if VersionedDataStore then
        help = help .. "- versions [player] [max]: View version history\n"
        help = help .. "- rollback [player] [version]: Rollback to a version\n"
    end
    
    if DataMigrationUtility then
        help = help .. "- migrate [player/all] [source] [dest]: Migrate data\n"
        help = help .. "- migratestatus [player]: Check migration status\n"
    end
    
    help = help .. "- debug [on/off]: Toggle debug mode\n"
    help = help .. "- reload [player]: Force reload player data\n"
    
    return help
end

-- Send a message to a player
function DataAdminSystem:SendMessage(player, message)
    -- Try to use CoreRegistry messaging system if available
    if CoreRegistry then
        local MessageService = CoreRegistry:GetSystem("MessageService")
        if MessageService and typeof(MessageService.sendAdminMessage) == "function" then
            MessageService.sendAdminMessage(player, message)
            return
        end
    end
    
    -- Fallback: Send a chat message
    pcall(function()
        local ServerMessage = Instance.new("Message")
        ServerMessage.Text = message
        ServerMessage.Parent = player
        task.delay(5, function()
            ServerMessage:Destroy()
        end)
    end)
end

-- Initialize and return
return DataAdminSystem:Initialize()
