-- LabelGUIAutoFix.server.luau
-- This is an automatic fix for the "Label" GUI issue that creates unwanted grey backgrounds
-- This script will run on server start and continuously monitor for unwanted GUIs

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEBUG_MODE = false -- Set to true for verbose logging
local CHECK_INTERVAL = 5 -- Seconds between checks

-- Logging function
local function log(message)
    if DEBUG_MODE then
        print("[LabelGUIFix] " .. message)
    end
end

log("Initializing Label GUI Auto-Fix...")

-- Function to remove all Label GUIs in workspace
local function removeAllLabelGuis()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Label" and (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) then
            -- Log information about the parent for debugging
            if DEBUG_MODE then
                log("Found Label GUI at: " .. obj:GetFullName())
                if obj.Parent then
                    log("- Parent: " .. obj.Parent:GetFullName())
                    if obj.Parent:IsA("BasePart") and obj.Parent.Parent then
                        log("- Grandparent: " .. obj.Parent.Parent:GetFullName())
                    end
                end
            end
            
            -- Destroy the unwanted GUI
            obj:Destroy()
            count = count + 1
        end
    end
    
    if count > 0 then
        log("Removed " .. count .. " 'Label' GUI objects")
    end
    return count
end

-- Function to clean tycoons for a specific player
local function cleanPlayerTycoon(player)
    if not player or not player:IsA("Player") then return 0 end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return 0 end
    
    local count = 0
    for _, obj in pairs(tycoon.Value:GetDescendants()) do
        if obj.Name == "Label" and (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) then
            obj:Destroy()
            count = count + 1
        end
    end
    
    if count > 0 then
        log("Cleaned " .. count .. " Label GUIs from " .. player.Name .. "'s tycoon")
    end
    return count
end

-- Special function to fix TycoonClient UI issue identified by diagnostic script
local function fixTycoonClientLabels()
    local count = 0
    
    -- Fix in StarterPlayerScripts
    local starterScripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    if starterScripts then
        -- Look for the TycoonClient script
        local tycoonClient = starterScripts:FindFirstChild("Client")
        if tycoonClient then
            tycoonClient = tycoonClient:FindFirstChild("Core")
            if tycoonClient then
                tycoonClient = tycoonClient:FindFirstChild("TycoonClient")
                if tycoonClient and tycoonClient:IsA("ModuleScript") then
                    log("Found TycoonClient in StarterPlayerScripts")
                    -- This is a fix for future instances that will be created when players join
                    local success, result = pcall(function()
                        -- Replace 'Label' with 'InteractButtonLabel' in the script
                        local source = tycoonClient.Source
                        if source:find("label.Name = \"Label\"") then
                            -- Create a backup
                            local backup = tycoonClient:Clone()
                            backup.Name = "TycoonClient_Backup"
                            backup.Parent = tycoonClient.Parent
                            
                            -- Create a fixed version
                            local fixed = source:gsub("label%.Name = \"Label\"", "label.Name = \"InteractButtonLabel\"")
                            if fixed ~= source then
                                -- Cannot directly modify Source in a server script
                                -- Instead, create a notification system to alert developers
                                log("Identified TycoonClient needs fixing. Manual update required.")
                                
                                -- Create a notification in ReplicatedStorage
                                local notification = Instance.new("StringValue")
                                notification.Name = "TycoonClientFixNeeded"
                                notification.Value = "The TycoonClient script contains Label names that need to be updated to InteractButtonLabel"
                                notification.Parent = ReplicatedStorage
                                count = count + 1
                            end
                        end
                    end)
                    
                    if not success then
                        log("Error analyzing TycoonClient: " .. tostring(result))
                    end
                end
            end
        end
    end
    
    -- Fix in existing PlayerScripts for each player
    for _, player in pairs(Players:GetPlayers()) do
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if playerScripts then
            local tycoonClient = playerScripts:FindFirstChild("Client")
            if tycoonClient then
                tycoonClient = tycoonClient:FindFirstChild("Core")
                if tycoonClient then
                    tycoonClient = tycoonClient:FindFirstChild("TycoonClient")
                    if tycoonClient then
                        log("Found TycoonClient in " .. player.Name .. "'s PlayerScripts")
                        -- Can't modify directly, so let's monitor and fix any Labels created
                        -- This is handled by the existing removal functions
                    end
                end
            end
        end
    end
    
    return count
end

-- Create global function for other scripts to use
_G.RemoveAllLabelGuis = removeAllLabelGuis

-- Function to patch BuyTile scripts
local function patchBuyTileSystem()
    -- Create a fix for the instance creation
    local oldInstanceNew = Instance.new
    Instance.new = function(className, parent)
        local instance = oldInstanceNew(className)
        
        -- If creating a BillboardGui, watch for the Name being set to "Label"
        if className == "BillboardGui" then
            instance:GetPropertyChangedSignal("Name"):Connect(function()
                if instance.Name == "Label" then
                    -- Only log if debug mode is on
                    log("Prevented 'Label' GUI creation - destroying it")
                    instance:Destroy()
                end
            end)
        end
        
        -- Also watch TextLabels in case they're being created with "Label" name
        if className == "TextLabel" then
            instance:GetPropertyChangedSignal("Name"):Connect(function()
                if instance.Name == "Label" then
                    -- Redirect to a better name instead of destroying
                    instance.Name = "InteractButtonLabel"
                    log("Renamed 'Label' TextLabel to 'InteractButtonLabel'")
                end
            end)
        end
        
        -- Parent if specified
        if parent then
            instance.Parent = parent
        end
        
        return instance
    end
    
    log("Patched Instance.new to prevent Label GUI creation")
    return true
end

-- Run the initial cleanup
removeAllLabelGuis()

-- Patch the BuyTile system
patchBuyTileSystem()

-- Run specific fix for TycoonClient
fixTycoonClientLabels()

-- Clean existing player tycoons
for _, player in pairs(Players:GetPlayers()) do
    cleanPlayerTycoon(player)
end

-- Set up event connections
Players.PlayerAdded:Connect(function(player)
    -- Give time for their tycoon to load
    task.delay(3, function()
        cleanPlayerTycoon(player)
    end)
end)

-- Run periodic cleanup using heartbeat
local lastCheck = tick()
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastCheck >= CHECK_INTERVAL then
        lastCheck = currentTime
        removeAllLabelGuis()
    end
end)

log("Label GUI Auto-Fix initialized and running")
