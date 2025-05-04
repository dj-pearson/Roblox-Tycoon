-- PasteInCommandBar.lua
-- Copy and paste this into the command bar to immediately remove any Label GUIs

-- Function to remove all Label GUIs
local function removeAllLabelGuis()
    local player = game.Players.LocalPlayer
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
    
    print("Removed " .. count .. " Label GUIs")
    return count
end

-- Run the function and assign it to _G
local count = removeAllLabelGuis()
_G.RemoveAllLabels = removeAllLabelGuis
print("Removed " .. count .. " Label GUIs. Function _G.RemoveAllLabels is now available.")

-- Also set up an event connection to catch new ones
local player = game.Players.LocalPlayer
if player and player:FindFirstChild("PlayerGui") then
    player.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj.Name == "Label" then
            obj:Destroy()
            print("Caught and removed new Label GUI")
        end
    end)
    print("Now monitoring for new Label GUIs...")
end
