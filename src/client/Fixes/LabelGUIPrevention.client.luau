-- LabelGUIPrevention.client.luau
-- This script provides a client-side mechanism to prevent grey Label GUIs from appearing
-- It uses metatable hooks to intercept the creation of any GUI named "Label"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local REMOVE_INTERVAL = 0.5 -- Check every half second
local DEBUG_MODE = false -- Set to true for verbose logging

-- Logging function
local function log(message)
    if DEBUG_MODE then
        print("[LabelGUIPrevention] " .. message)
    end
end

log("Starting Label GUI Prevention client script...")

-- Function to find and remove all Label GUIs
local function removeAllLabelGuis()
    local count = 0
    
    -- From PlayerGui
    for _, obj in pairs(PlayerGui:GetDescendants()) do
        if obj.Name == "Label" and (obj:IsA("BillboardGui") or obj:IsA("TextLabel") or obj:IsA("SurfaceGui")) then
            obj:Destroy()
            count = count + 1
        end
    end
    
    -- From workspace that might affect this player
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Label" and obj:IsA("BillboardGui") then
            local adornee = obj.Adornee
            -- Only remove if it's related to the player's character
            if adornee and (adornee == LocalPlayer.Character or adornee:IsDescendantOf(LocalPlayer.Character)) then
                obj:Destroy()
                count = count + 1
            end
        end
    end
    
    -- From camera
    local camera = workspace.CurrentCamera
    if camera then
        for _, obj in pairs(camera:GetDescendants()) do
            if obj.Name == "Label" and obj:IsA("BillboardGui") then
                obj:Destroy()
                count = count + 1
            end
        end
    end
    
    if count > 0 then
        log("Removed " .. count .. " Label GUIs")
    end
    
    return count
end

-- Set up event connections
local function setupConnections()
    -- Listen for changes in PlayerGui
    PlayerGui.DescendantAdded:Connect(function(obj)
        if obj.Name == "Label" then
            log("Caught Label creation in PlayerGui: " .. obj:GetFullName())
            obj:Destroy()
        end
    end)
    
    -- Listen for changes in Character
    LocalPlayer.CharacterAdded:Connect(function(character)
        character.DescendantAdded:Connect(function(obj)
            if obj.Name == "Label" then
                log("Caught Label creation in Character: " .. obj:GetFullName())
                obj:Destroy()
            end
        end)
    end)
    
    if LocalPlayer.Character then
        LocalPlayer.Character.DescendantAdded:Connect(function(obj)
            if obj.Name == "Label" then
                log("Caught Label creation in existing Character: " .. obj:GetFullName())
                obj:Destroy()
            end
        end)
    end
    
    -- Listen for changes in Camera
    workspace.CurrentCamera.DescendantAdded:Connect(function(obj)
        if obj.Name == "Label" then
            log("Caught Label creation in Camera: " .. obj:GetFullName())
            obj:Destroy()
        end
    end)
    
    log("Event connections established")
end

-- Hook Instance.new to prevent Label creation
local function hookInstanceNew()
    local oldInstanceNew = Instance.new
    Instance.new = function(className, parent)
        local instance = oldInstanceNew(className)
        
        -- If creating a GUI object, watch for name changes to prevent "Label"
        if className == "BillboardGui" or className == "TextLabel" or className == "SurfaceGui" then
            -- Watch for name changes
            instance:GetPropertyChangedSignal("Name"):Connect(function()
                if instance.Name == "Label" then
                    log("Prevented Label GUI via name change")
                    
                    -- Rename instead of destroying if it's a TextLabel
                    if instance:IsA("TextLabel") then
                        instance.Name = "RenamedLabel"
                    else
                        -- Small delay to allow setup before destroying
                        task.defer(function()
                            if instance and instance.Parent then
                                instance:Destroy()
                            end
                        end)
                    end
                end
            end)
            
            -- Check initial name
            if instance.Name == "Label" then
                log("Prevented Label GUI at creation")
                
                -- Rename instead of destroying if it's a TextLabel
                if instance:IsA("TextLabel") then
                    instance.Name = "RenamedLabel"
                else
                    -- Return a dummy object for BillboardGui/SurfaceGui to prevent errors
                    local dummy = oldInstanceNew("Folder")
                    if parent then
                        dummy.Parent = parent
                    end
                    instance:Destroy()
                    return dummy
                end
            end
        end
        
        -- Parent if specified (normal behavior)
        if parent then
            instance.Parent = parent
        end
        
        return instance
    end
    
    log("Instance.new hooked to prevent Label GUI creation")
end

-- Set up regular cleanup on a timer as a backup
local function setupPeriodicCleanup()
    local lastCleanupTime = tick()
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastCleanupTime >= REMOVE_INTERVAL then
            lastCleanupTime = currentTime
            removeAllLabelGuis()
        end
    end)
    
    log("Periodic cleanup initialized")
end

-- Run initial cleanup
removeAllLabelGuis()

-- Set up event connections
setupConnections()

-- Hook Instance.new 
hookInstanceNew()

-- Set up periodic cleanup
setupPeriodicCleanup()

log("Label GUI Prevention client script active and running")

-- Return a public API
return {
    removeAllLabelGuis = removeAllLabelGuis
}
