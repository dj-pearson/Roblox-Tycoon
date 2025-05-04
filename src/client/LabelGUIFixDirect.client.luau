-- LabelGUIFixDirect.client.luau
-- This script directly prevents and removes any GUI elements named "Label"
-- This script should be placed in StarterPlayerScripts to run early

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CHECK_INTERVAL = 0.5 -- seconds

-- Function to remove Label GUIs
local function removeAllLabelGuis()
    local count = 0
    
    -- Check player GUI
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

-- Create a function available globally
_G.RemoveAllLabelGuis = removeAllLabelGuis

-- Setup event connections
local function setupEvents()
    -- Listen for PlayerGui changes
    if player:FindFirstChild("PlayerGui") then
        player.PlayerGui.DescendantAdded:Connect(function(obj)
            if obj.Name == "Label" then
                obj:Destroy()
                print("[LabelGUIFix] Removed Label GUI from PlayerGui")
            end
        end)
    end
    
    -- Listen for Character changes
    player.CharacterAdded:Connect(function(character)
        character.DescendantAdded:Connect(function(obj)
            if obj.Name == "Label" then
                obj:Destroy()
                print("[LabelGUIFix] Removed Label GUI from Character")
            end
        end)
    end)
    
    if player.Character then
        player.Character.DescendantAdded:Connect(function(obj)
            if obj.Name == "Label" then
                obj:Destroy()
                print("[LabelGUIFix] Removed Label GUI from existing Character")
            end
        end)
    end
    
    print("[LabelGUIFix] Event listeners set up")
end

-- Hook Instance.new
local function hookInstanceNew()
    local oldInstanceNew = Instance.new
    Instance.new = function(className, parent)
        local instance = oldInstanceNew(className)
        
        -- Watch for GUIs being created with "Label" name
        if className == "BillboardGui" or className == "TextLabel" or className == "SurfaceGui" then
            -- Check initial name
            if instance.Name == "Label" then
                -- For TextLabel, rename instead of destroy
                if instance:IsA("TextLabel") then
                    instance.Name = "InteractButtonLabel"
                    print("[LabelGUIFix] Renamed TextLabel from Label to InteractButtonLabel")
                else
                    -- For BillboardGui/SurfaceGui, destroy and return dummy
                    instance:Destroy()
                    print("[LabelGUIFix] Prevented Label GUI creation")
                    
                    -- Return a dummy to prevent errors
                    local dummy = oldInstanceNew("Folder")
                    if parent then
                        dummy.Parent = parent
                    end
                    return dummy
                end
            end
            
            -- Also watch for name changes
            instance:GetPropertyChangedSignal("Name"):Connect(function()
                if instance.Name == "Label" then
                    if instance:IsA("TextLabel") then
                        instance.Name = "InteractButtonLabel"
                        print("[LabelGUIFix] Renamed TextLabel from Label to InteractButtonLabel")
                    else
                        -- For non-TextLabel GUIs, destroy
                        instance:Destroy()
                        print("[LabelGUIFix] Removed renamed GUI with Label name")
                    end
                end
            end)
        end
        
        -- Parent if specified
        if parent then
            instance.Parent = parent
        end
        
        return instance
    end
    
    print("[LabelGUIFix] Instance.new hooked")
end

-- Set up periodic cleanup
local function setupPeriodicCheck()
    local lastCheck = tick()
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastCheck >= CHECK_INTERVAL then
            lastCheck = currentTime
            removeAllLabelGuis()
        end
    end)
    
    print("[LabelGUIFix] Periodic cleanup started")
end

-- Initialize everything
print("[LabelGUIFix] Starting Label GUI prevention system...")

-- Run initial cleanup
removeAllLabelGuis()

-- Set up events
setupEvents()

-- Hook Instance.new
hookInstanceNew()

-- Set up periodic check
setupPeriodicCheck()

print("[LabelGUIFix] Label GUI prevention system active")

-- Make the removal function available globally
_G.RemoveAllLabels = removeAllLabelGuis
