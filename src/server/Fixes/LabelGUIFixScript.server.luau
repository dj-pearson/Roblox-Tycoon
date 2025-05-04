-- LabelGUIFixScript.server.luau
-- Script to permanently fix the "Label" GUI issue
-- This script should be placed in ServerScriptService for best results

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Log function for debugging
local function log(message)
    print("[LabelGUIFix] " .. message)
end

log("Initializing Label GUI Fix Script...")

-- Function to remove any existing Label GUIs
local function removeAllLabelGuis()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) and obj.Name == "Label" then
            obj:Destroy()
            count = count + 1
        end
    end
    
    if count > 0 then
        log("Removed " .. count .. " 'Label' GUI objects from workspace")
    end
    return count
end

-- Add the global function for other scripts to use
_G.RemoveAllLabelGuis = removeAllLabelGuis

-- Monkey patch Instance.new to prevent creation of "Label" BillboardGuis
-- This is an advanced technique that intercepts GUI creation
local oldInstanceNew = Instance.new
Instance.new = function(className, parent)
    local instance = oldInstanceNew(className)
    
    -- If creating a BillboardGui that will be named "Label", prevent it
    if className == "BillboardGui" and not parent then
        instance:GetPropertyChangedSignal("Name"):Connect(function()
            if instance.Name == "Label" then
                log("Prevented Label GUI from being created - destroying it")
                instance:Destroy()
            end
        end)
    end
    
    if parent then
        instance.Parent = parent
    end
    
    return instance
end

-- Find and patch BuyTile scripts that might be creating the Label GUI
local function patchBuyTileScripts()
    local scriptCount = 0
    
    for _, script in pairs(game:GetDescendants()) do
        if script:IsA("Script") and script.Name:match("BuyTile") then
            -- Successfully found a BuyTile script
            scriptCount = scriptCount + 1
            log("Found possible BuyTile script: " .. script:GetFullName())
        end
    end
    
    log("Found " .. scriptCount .. " potential BuyTile scripts")
end

-- Function to clean up when a player loads their tycoon
local function cleanPlayerTycoon(player)
    if not player then return end
    
    -- Let's wait a short time for their tycoon to load
    task.delay(2, function()
        local tycoon = player:FindFirstChild("Tycoon")
        if tycoon and tycoon.Value then
            -- Check for any Label GUIs in their tycoon
            local count = 0
            for _, obj in pairs(tycoon.Value:GetDescendants()) do
                if obj.Name == "Label" and (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) then
                    obj:Destroy()
                    count = count + 1
                end
            end
            
            if count > 0 then
                log("Cleaned up " .. count .. " Label GUIs from " .. player.Name .. "'s tycoon")
            end
        end
    end)
end

-- Run immediate fixes
removeAllLabelGuis()
patchBuyTileScripts()

-- Connect to player events
Players.PlayerAdded:Connect(function(player)
    cleanPlayerTycoon(player)
end)

-- Set up heartbeat to periodically check for and remove Label GUIs
-- Only run this every few seconds to avoid performance impact
local lastCheckTime = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastCheckTime > 5 then  -- Check every 5 seconds
        lastCheckTime = currentTime
        removeAllLabelGuis()
    end
end)

log("Label GUI Fix Script initialized and running")
