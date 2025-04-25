--!strict
--[[
    AdminCommands.server.luau
    System for admin commands to manage player sanctions
    
    Updated: April 25, 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of admin user IDs (replace with your actual admin IDs)
local ADMIN_IDS = {
	7768610061, -- Replace with actual admin user IDs
	-- Add more admin IDs here
}

-- First try to get SafeWaitForChild utility
local SafeWaitForChild
local success, safeWaitResult = pcall(function()
    local moduleScript = ReplicatedStorage:FindFirstChild("src")
    if moduleScript then
        moduleScript = moduleScript:FindFirstChild("shared")
        if moduleScript then
            moduleScript = moduleScript:FindFirstChild("SafeWaitForChild")
            if moduleScript then
                return require(moduleScript)
            end
        end
    end
    return nil
end)

if success and safeWaitResult then
    SafeWaitForChild = safeWaitResult
else
    -- Simple fallback implementation
    SafeWaitForChild = {}
    function SafeWaitForChild.waitForChild(parent, childName, timeout)
        timeout = timeout or 10
        local startTime = os.clock()
        while os.clock() - startTime < timeout do
            local child = parent:FindFirstChild(childName)
            if child then return child end
            task.wait(0.1)
        end
        warn("Timeout waiting for " .. parent:GetFullName() .. ":" .. childName)
        return nil
    end
end

-- Try various paths to find the DevUtilityFunctions module
local SanctionSystem

-- First try direct path in ServerScriptService.Core
local core = SafeWaitForChild.waitForChild(ServerScriptService, "Core", 2)
if core then
    local devUtils = SafeWaitForChild.waitForChild(core, "DevUtilityFunctions", 2)
    if devUtils then
        SanctionSystem = require(devUtils)
    end
end

-- If not found, try in src/server/Core
if not SanctionSystem then
    local srcModule = SafeWaitForChild.waitForChild(ReplicatedStorage, "src", 2)
    if srcModule then
        local serverModule = SafeWaitForChild.waitForChild(srcModule, "server", 2)
        if serverModule then
            local serverCore = SafeWaitForChild.waitForChild(serverModule, "Core", 2)
            if serverCore then
                local devUtils = SafeWaitForChild.waitForChild(serverCore, "DevUtilityFunctions", 2)
                if devUtils then
                    SanctionSystem = require(devUtils)
                end
            end
        end
    end
end

-- Create minimal fallback if still not found
if not SanctionSystem then
    warn("DevUtilityFunctions module not found, using fallback implementation")
    SanctionSystem = {
        isAdmin = function(player)
            return table.find(ADMIN_IDS, player.UserId) ~= nil
        end,
        
        applySanction = function(targetPlayer, sanctionType, duration, reason, adminPlayer)
            warn(string.format("[Fallback Sanction] %s applied to %s by %s: %s", 
                sanctionType, 
                targetPlayer.Name, 
                adminPlayer and adminPlayer.Name or "System", 
                reason or "No reason provided"))
                
            if sanctionType == "Kick" then
                targetPlayer:Kick(reason or "Kicked by an administrator")
                return true
            end
            return false
        end,
        
        getPlayerByName = function(nameOrPartial)
            nameOrPartial = string.lower(nameOrPartial)
            for _, player in ipairs(Players:GetPlayers()) do
                if string.find(string.lower(player.Name), nameOrPartial) then
                    return player
                end
            end
            return nil
        end,
        
        unbanPlayer = function(userId)
            warn("Unban attempted with fallback implementation - no actual unbanning occurred")
            return false
        end
    }
end

-- Function to check if a user is an admin
local function isAdmin(player)
    if SanctionSystem.isAdmin then
        return SanctionSystem.isAdmin(player)
    else
        return table.find(ADMIN_IDS, player.UserId) ~= nil
    end
end

-- Function to parse command arguments
local function parseCommand(message)
    -- Check if message starts with the command prefix
    if string.sub(message, 1, 1) ~= "/" then
        return nil, nil
    end
    
    -- Remove the prefix and split by spaces
    local parts = {}
    for part in string.gmatch(string.sub(message, 2), "%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        return nil, nil
    end
    
    local command = string.lower(parts[1])
    table.remove(parts, 1)
    
    return command, parts
end

-- Function to handle admin commands
local function handleCommand(player, message)
    local command, args = parseCommand(message)
    if not command then return false end
    
    if not isAdmin(player) then
        -- Silently ignore commands from non-admins
        return false
    end
    
    -- Process commands
    if command == "kick" then
        if #args < 1 then
            sendSystemMessage(player, "Usage: /kick [player] [reason]")
            return true
        end
        
        local targetName = args[1]
        table.remove(args, 1)
        local reason = #args > 0 and table.concat(args, " ") or "No reason provided"
        
        local targetPlayer = SanctionSystem.getPlayerByName(targetName)
        if targetPlayer then
            SanctionSystem.applySanction(targetPlayer, "Kick", nil, reason, player)
            sendSystemMessage(player, "Kicked " .. targetPlayer.Name .. " for: " .. reason)
        else
            sendSystemMessage(player, "Player not found: " .. targetName)
        end
        
        return true
        
    elseif command == "ban" then
        if #args < 2 then
            sendSystemMessage(player, "Usage: /ban [player] [duration] [reason]")
            return true
        end
        
        local targetName = args[1]
        local duration = tonumber(args[2]) or 0
        table.remove(args, 1)
        table.remove(args, 1)
        local reason = #args > 0 and table.concat(args, " ") or "No reason provided"
        
        local targetPlayer = SanctionSystem.getPlayerByName(targetName)
        if targetPlayer then
            SanctionSystem.applySanction(targetPlayer, "Ban", duration, reason, player)
            sendSystemMessage(player, "Banned " .. targetPlayer.Name .. " for: " .. reason)
        else
            sendSystemMessage(player, "Player not found: " .. targetName)
        end
        
        return true
        
    elseif command == "unban" then
        if #args < 1 then
            sendSystemMessage(player, "Usage: /unban [userId or username]")
            return true
        end
        
        local userIdentifier = args[1]
        local userId = tonumber(userIdentifier)
        
        if not userId then
            -- Try to resolve username to ID
            local foundUserId = SanctionSystem.getUserIdFromName and SanctionSystem.getUserIdFromName(userIdentifier)
            if not foundUserId then
                sendSystemMessage(player, "Could not find user: " .. userIdentifier)
                return true
            end
            userId = foundUserId
        end
        
        if SanctionSystem.unbanPlayer then
            local unbanned = SanctionSystem.unbanPlayer(userId)
            if unbanned then
                sendSystemMessage(player, "Successfully unbanned user ID: " .. userId)
            else
                sendSystemMessage(player, "Failed to unban user ID: " .. userId)
            end
        else
            sendSystemMessage(player, "Unban function not available")
        end
        
        return true
    end
    
    return false
end

-- Create a system message to the player
function sendSystemMessage(player, text)
    if not player or not text then return end
    
    -- Try to use standard chat system first
    local chatSuccess, chatError = pcall(function()
        local ChatService = require(game:GetService("ServerScriptService"):FindFirstChild("ChatServiceRunner") 
            and game:GetService("ServerScriptService").ChatServiceRunner.ChatService)
        
        if ChatService then
            ChatService:InternalSendSystemMessageToPlayer("Admin System: " .. text, player, nil)
            return true
        end
        return false
    end)
    
    if chatSuccess then return end
    
    -- Fallback to GUI notification
    local notificationSuccess, notificationError = pcall(function()
        local notification = Instance.new("Message")
        notification.Text = "Admin System: " .. text
        notification.Parent = player
        
        -- Remove after 3 seconds
        game:GetService("Debris"):AddItem(notification, 3)
    end)
    
    if not notificationSuccess then
        warn("Failed to send system message: " .. tostring(notificationError))
    end
end

-- Connect to chat events
local function onPlayerChatted(player, message, recipientType)
    if not player or not message then return end
    
    local handled = handleCommand(player, message)
    if handled then
        -- The message was a command, might want to hide it from other players
    end
end

-- Connect various chat systems based on what's available
local ChatService = game:GetService("Chat")
ChatService.Chatted:Connect(onPlayerChatted)

-- Also try to connect to TextChatService if available
local textChatService = game:GetService("TextChatService")
if textChatService then
    pcall(function()
        textChatService.MessageReceived:Connect(function(textChatMessage)
            local player = Players:GetPlayerByUserId(textChatMessage.TextSource.UserId)
            if player then
                onPlayerChatted(player, textChatMessage.Text)
            end
        end)
    end)
end

-- Handle commands from BubbleChat as well if it exists
pcall(function()
    local ReplicatedModules = game:GetService("ReplicatedStorage"):FindFirstChild("rbxts_include")
    if ReplicatedModules then
        local BubbleChatModule = ReplicatedModules:FindFirstChild("node_modules")
            and ReplicatedModules.node_modules:FindFirstChild("@rbxts")
            and ReplicatedModules.node_modules["@rbxts"]:FindFirstChild("bubble-chat")
        
        if BubbleChatModule then
            local BubbleChatSystem = require(BubbleChatModule)
            BubbleChatSystem.Chatted:Connect(function(chatData)
                local player = chatData.Player
                local message = chatData.Message
                
                if player and message then
                    onPlayerChatted(player, message)
                end
            end)
        end
    end
end)

print("Admin Commands System initialized")