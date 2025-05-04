-- LabelGUIDiagnostics.luau
-- This script can be run from the command bar to diagnose Label GUI issues
-- Just paste the contents into the command bar and run it

local function diagnoseAllLabelGuis()
    print("\n=== LABEL GUI DIAGNOSTICS REPORT ===")
    
    local totalCount = 0
    local locations = {}
    
    -- Check PlayerGui
    local player = game.Players.LocalPlayer
    if player and player:FindFirstChild("PlayerGui") then
        local guiCount = 0
        for _, obj in pairs(player.PlayerGui:GetDescendants()) do
            if obj.Name == "Label" then
                guiCount = guiCount + 1
                table.insert(locations, {
                    path = obj:GetFullName(),
                    type = obj.ClassName,
                    parent = obj.Parent and obj.Parent:GetFullName() or "nil"
                })
            end
        end
        print("- PlayerGui: " .. guiCount .. " Label GUIs found")
        totalCount = totalCount + guiCount
    end
    
    -- Check workspace
    local workspaceCount = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Label" then
            workspaceCount = workspaceCount + 1
            table.insert(locations, {
                path = obj:GetFullName(),
                type = obj.ClassName,
                parent = obj.Parent and obj.Parent:GetFullName() or "nil"
            })
        end
    end
    print("- Workspace: " .. workspaceCount .. " Label GUIs found")
    totalCount = totalCount + workspaceCount
    
    -- Check character
    if player and player.Character then
        local characterCount = 0
        for _, obj in pairs(player.Character:GetDescendants()) do
            if obj.Name == "Label" then
                characterCount = characterCount + 1
                table.insert(locations, {
                    path = obj:GetFullName(),
                    type = obj.ClassName,
                    parent = obj.Parent and obj.Parent:GetFullName() or "nil"
                })
            end
        end
        print("- Character: " .. characterCount .. " Label GUIs found")
        totalCount = totalCount + characterCount
    end
    
    -- Check camera
    local camera = workspace.CurrentCamera
    if camera then
        local cameraCount = 0
        for _, obj in pairs(camera:GetDescendants()) do
            if obj.Name == "Label" then
                cameraCount = cameraCount + 1
                table.insert(locations, {
                    path = obj:GetFullName(),
                    type = obj.ClassName,
                    parent = obj.Parent and obj.Parent:GetFullName() or "nil"
                })
            end
        end
        print("- Camera: " .. cameraCount .. " Label GUIs found")
        totalCount = totalCount + cameraCount
    end
    
    print("\nTOTAL: " .. totalCount .. " Label GUIs found")
    
    -- Print details if any were found
    if totalCount > 0 then
        print("\nDETAILS:")
        for i, info in ipairs(locations) do
            print(i .. ". " .. info.type .. " at " .. info.path)
            print("   Parent: " .. info.parent)
        end
        
        print("\nTo remove these GUIs, run:")
        print("_G.RemoveAllLabelGuis()")
    end
    
    -- Check if prevention script is loaded
    local preventionActive = false
    for _, obj in pairs(player:FindFirstChild("PlayerScripts"):GetDescendants()) do
        if obj.Name == "LabelGUIFixDirect" then
            preventionActive = true
            break
        end
    end
    
    print("\nPrevention Script Status: " .. (preventionActive and "ACTIVE" or "NOT FOUND"))
    print("=== END OF REPORT ===\n")
    
    return totalCount, locations
end

-- Run the diagnostics
return diagnoseAllLabelGuis()
