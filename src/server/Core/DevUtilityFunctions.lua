--!strict
--[[
    DevUtilityFunctions.lua
    Utility functions for development and administration purposes
    
    Author: Pearson
    Date: April 25, 2025
]]

local DevUtilityFunctions = {}

-- Set of player IDs or names that have admin permissions
local adminUsers = {
    ["Xdjpearsonx"] = true,
    -- Add other admin users here
}

-- Check if a player has admin permissions
function DevUtilityFunctions.isAdmin(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return adminUsers[player.Name] or adminUsers[tostring(player.UserId)] or false
    elseif typeof(player) == "string" then
        return adminUsers[player] or false
    elseif typeof(player) == "number" then
        return adminUsers[tostring(player)] or false
    end
    return false
end

-- Apply a sanction to a player
function DevUtilityFunctions.applySanction(targetPlayer, sanctionType, duration, reason, adminPlayer)
    if not targetPlayer then
        warn("Cannot apply sanction: Target player is nil")
        return false
    end
    
    -- Log the sanction
    print(string.format("[Sanction] %s applied to %s by %s for %s. Reason: %s",
        sanctionType,
        targetPlayer.Name,
        adminPlayer and adminPlayer.Name or "System",
        duration and ("duration " .. tostring(duration)) or "indefinitely",
        reason or "No reason provided"
    ))
    
    -- Apply the specific sanction
    if sanctionType == "Kick" then
        task.spawn(function()
            targetPlayer:Kick(reason or "Kicked by an administrator")
        end)
        return true
    elseif sanctionType == "TempBan" then
        -- Implement temporary ban logic here
        return true
    elseif sanctionType == "Mute" then
        -- Implement muting logic here
        return true
    end
    
    return false
end

-- Remove a sanction from a player
function DevUtilityFunctions.removeSanction(targetPlayer, sanctionType, adminPlayer)
    print(string.format("[Sanction] %s removed from %s by %s",
        sanctionType,
        typeof(targetPlayer) == "Instance" and targetPlayer.Name or tostring(targetPlayer),
        adminPlayer and adminPlayer.Name or "System"
    ))
    
    -- Implement sanction removal logic here
    
    return true
end

-- Get a player by name or partial name match
function DevUtilityFunctions.getPlayerByName(nameOrPartial)
    local Players = game:GetService("Players")
    nameOrPartial = string.lower(nameOrPartial)
    
    -- Try exact match first
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == nameOrPartial then
            return player
        end
    end
    
    -- Try partial match
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), nameOrPartial) then
            return player
        end
    end
    
    return nil
end

-- Run a command with arguments
function DevUtilityFunctions.runCommand(player, commandName, args)
    if not DevUtilityFunctions.isAdmin(player) then
        return false, "You don't have permission to run admin commands"
    end
    
    if commandName == "kick" then
        local targetName = args[1]
        local reason = table.concat(args, " ", 2) or "No reason provided"
        
        local targetPlayer = DevUtilityFunctions.getPlayerByName(targetName)
        if not targetPlayer then
            return false, "Player not found: " .. targetName
        end
        
        return DevUtilityFunctions.applySanction(targetPlayer, "Kick", nil, reason, player)
    elseif commandName == "teleport" or commandName == "tp" then
        -- Implement teleport command
        return true
    end
    
    return false, "Unknown command: " .. commandName
end

-- Log a message to server console and potentially external systems
function DevUtilityFunctions.logMessage(category, message)
    print(string.format("[%s] %s", category, message))
    -- Add data store logging here if needed
end

return DevUtilityFunctions
