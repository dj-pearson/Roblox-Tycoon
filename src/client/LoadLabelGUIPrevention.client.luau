-- LoadLabelGUIPrevention.client.luau
-- Placed in StarterPlayerScripts to load before other scripts
-- This ensures the Label GUI Prevention system is always active

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Wait for player to be fully loaded
local function waitForPlayerLoaded()
    if not LocalPlayer then
        LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
            LocalPlayer = Players.LocalPlayer
        end
    end
    return LocalPlayer
end

local player = waitForPlayerLoaded()
print("Loading Label GUI Prevention system...")

-- Try to require the module
local success, preventionSystem = pcall(function()
    return require(script.Parent.Client.Fixes.LabelGUIPrevention)
end)

if success then
    print("Label GUI Prevention system loaded successfully")
    -- Run an initial cleanup
    preventionSystem.removeAllLabelGuis()
else
    warn("Failed to load Label GUI Prevention system: " .. tostring(preventionSystem))
    -- Fallback prevention method
    local function removeAllLabelGuis()
        local count = 0
        for _, obj in pairs(player.PlayerGui:GetDescendants()) do
            if obj.Name == "Label" and (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) then
                obj:Destroy()
                count = count + 1
            end
        end
        return count
    end
    
    -- Set up a global function
    _G.RemoveClientLabelGuis = removeAllLabelGuis
    
    -- Do initial cleanup
    removeAllLabelGuis()
    
    -- Set up a basic event connection for PlayerGui
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj.Name == "Label" then
            obj:Destroy()
        end
    end)
    
    print("Basic Label GUI prevention active as fallback")
end

-- Create a local function that can be manually called from the command bar
local function removeAllLabels()
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
    
    -- Check workspace for any billboardguis
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Label" and obj:IsA("BillboardGui") then
            obj:Destroy()
            count = count + 1
        end
    end
    
    print("Removed " .. count .. " Label GUIs")
end

-- Expose to global scope for manual triggering
_G.RemoveAllLabels = removeAllLabels
