--[[
    EquipmentSetupCommands.server.luau
    
    Developer commands to help set up equipment for upgrading.
    Only available to players with proper permissions.
    
    Created: April 2025
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Import modules
local EquipmentSetup = require(script.Parent.Parent["Model Function"].EquipmentSetup)

-- Permitted admin users - add your username here
local ADMIN_USERS = {
    "YourUsernameHere" -- Replace with your Roblox username to access commands
}

-- Check if player has admin permissions
local function IsAdmin(player)
    for _, adminName in ipairs(ADMIN_USERS) do
        if player.Name == adminName then
            return true
        end
    end
    return false
end

-- Process commands
local function ProcessCommand(player, message)
    -- Only allow admin users
    if not IsAdmin(player) then return end
    
    -- Check if message is a command
    if not message:sub(1, 1) == "/" then return end
    
    -- Get command and arguments
    local parts = {}
    for part in string.gmatch(message, "%S+") do
        table.insert(parts, part)
    end
    
    local command = parts[1]:lower()
    
    -- Command to setup equipment in a folder
    if command == "/setupequipment" then
        local folderPath = parts[2] or "Equipment"
        
        -- Get the player's tycoon
        local tycoon = workspace:FindFirstChild(player.Name .. "_Tycoon")
        if not tycoon then
            -- Try to find any tycoon
            for _, child in ipairs(workspace:GetChildren()) do
                if string.find(child.Name, "Tycoon") then
                    tycoon = child
                    break
                end
            end
        end
        
        if tycoon then
            local folder = tycoon:FindFirstChild(folderPath, true)
            if folder then
                local count = EquipmentSetup.SetupEquipmentFolder(folder)
                -- Notify player
                if count > 0 then
                    player:SendMessage("Successfully set up " .. count .. " pieces of equipment in " .. folderPath)
                else
                    player:SendMessage("No equipment was set up in " .. folderPath)
                end
            else
                player:SendMessage("Could not find folder: " .. folderPath)
            end
        else
            player:SendMessage("Could not find your tycoon")
        end
        return
    end
    
    -- Command to setup all equipment in a tycoon
    if command == "/setupalltycoon" then
        -- Get the player's tycoon
        local tycoonName = parts[2]
        local tycoon
        
        if tycoonName then
            tycoon = workspace:FindFirstChild(tycoonName)
        else
            tycoon = workspace:FindFirstChild(player.Name .. "_Tycoon")
        end
        
        if not tycoon then
            -- Try to find any tycoon
            for _, child in ipairs(workspace:GetChildren()) do
                if string.find(child.Name, "Tycoon") then
                    tycoon = child
                    break
                end
            end
        end
        
        if tycoon then
            local count = EquipmentSetup.SetupTycoonEquipment(tycoon)
            -- Notify player
            if count and count > 0 then
                player:SendMessage("Successfully set up " .. count .. " pieces of equipment in " .. tycoon.Name)
            else
                player:SendMessage("No equipment was set up in " .. tycoon.Name)
            end
        else
            player:SendMessage("Could not find tycoon")
        end
        return
    end
    
    -- Command to list setup commands
    if command == "/equipmentcommands" then
        player:SendMessage("Equipment Setup Commands:\n" ..
                        "/setupequipment [folderPath] - Setup equipment in a folder\n" ..
                        "/setupalltycoon [tycoonName] - Setup all equipment in a tycoon\n")
        return
    end
end

-- Listen for chat messages
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        ProcessCommand(player, message)
    end)
end)

print("Equipment Setup Commands Loaded")