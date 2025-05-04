-- LabelGUIRemovalCommand.server.luau
-- This script adds an admin command to remove Label GUIs for all players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a RemoteEvent for invoking the client-side cleanup
local cleanupEvent = Instance.new("RemoteEvent")
cleanupEvent.Name = "LabelGUICleanupCommand"
cleanupEvent.Parent = ReplicatedStorage

-- Function to run cleanup for a specific player
local function cleanupForPlayer(player)
    -- Invoke the client-side cleanup
    cleanupEvent:FireClient(player)
    print("Triggered Label GUI cleanup for " .. player.Name)
end

-- Function to run cleanup for all players
local function cleanupForAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        cleanupForPlayer(player)
    end
    print("Triggered Label GUI cleanup for all players")
end

-- Create the actual client-side script that will be triggered
local clientScript = Instance.new("LocalScript")
clientScript.Name = "LabelGUICleanupClientScript"
clientScript.Source = [[
-- Cleanup script for Label GUIs
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local cleanupEvent = ReplicatedStorage:WaitForChild("LabelGUICleanupCommand")

-- Function to remove all Label GUIs
local function removeAllLabelGuis()
    local count = 0
    
    -- Check PlayerGui
    if player and player:FindFirstChild("PlayerGui") then
        for _, obj in pairs(player.PlayerGui:GetDescendants()) do
            if obj.Name == "Label" then
                obj:Destroy()
                count = count + 1
            end
        end
    end
    
    -- Check workspace for BillboardGuis
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Label" and obj:IsA("BillboardGui") then
            obj:Destroy()
            count = count + 1
        end
    end
    
    -- Check character
    if player and player.Character then
        for _, obj in pairs(player.Character:GetDescendants()) do
            if obj.Name == "Label" then
                obj:Destroy()
                count = count + 1
            end
        end
    end
    
    if count > 0 then
        print("[LabelGUIFix] Removed", count, "Label GUIs")
    end
    
    return count
end

-- Connect to the event
cleanupEvent.OnClientEvent:Connect(function()
    local count = removeAllLabelGuis()
    print("Removed " .. count .. " Label GUIs")
end)

-- Create global function 
_G.RemoveAllLabelGuis = removeAllLabelGuis
]]
clientScript.Parent = cleanupEvent

-- Add to available admin commands
local adminCommands = ReplicatedStorage:FindFirstChild("AdminCommands")
if not adminCommands then
    adminCommands = Instance.new("Folder")
    adminCommands.Name = "AdminCommands"
    adminCommands.Parent = ReplicatedStorage
end

-- Add the command
local command = Instance.new("StringValue")
command.Name = "RemoveLabelGUIs"
command.Value = "Removes all Label GUIs from the game for all players"
command.Parent = adminCommands

-- Connect to the command event
local commandEvent = ReplicatedStorage:FindFirstChild("AdminCommandEvent")
if commandEvent and commandEvent:IsA("RemoteEvent") then
    commandEvent.OnServerEvent:Connect(function(player, commandName, ...)
        -- Check if player is admin
        local isAdmin = false
        
        -- Basic admin check - replace with your actual admin verification
        if player:GetAttribute("IsAdmin") or player:GetRankInGroup(1) >= 254 then
            isAdmin = true
        end
        
        if isAdmin and commandName == "RemoveLabelGUIs" then
            cleanupForAllPlayers()
            -- Notify the admin that command was executed
            local args = {...}
            if #args > 0 and Players:FindFirstChild(args[1]) then
                -- If a specific player was specified
                cleanupForPlayer(Players:FindFirstChild(args[1]))
                print("Admin " .. player.Name .. " ran RemoveLabelGUIs for " .. args[1])
            else
                -- For all players
                cleanupForAllPlayers()
                print("Admin " .. player.Name .. " ran RemoveLabelGUIs for all players")
            end
        end
    end)
end

-- Also create a server-side way to invoke this
local function setupServerCommand()
    -- Create server command 
    _G.RemoveAllLabelGUIs = function(playerName)
        if playerName and Players:FindFirstChild(playerName) then
            cleanupForPlayer(Players:FindFirstChild(playerName))
            return "Removed Label GUIs for " .. playerName
        else
            cleanupForAllPlayers()
            return "Removed Label GUIs for all players"
        end
    end
    
    print("Server command _G.RemoveAllLabelGUIs() is now available")
end

setupServerCommand()
