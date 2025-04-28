--[[
    ShowDoubleMemberUI.client.luau
    This client script receives the event when the player touches the DoubleMember model
    and shows the appropriate UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for UIManager to be available
local UIManager
local function findUIManager()
    local success, result = pcall(function()
        -- Try common paths for UIManager
        local paths = {
            ReplicatedStorage:FindFirstChild("UIManager"),
            LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("UIManager"),
            LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("UI") and 
                LocalPlayer.PlayerScripts.UI:FindFirstChild("UIManager")
        }
        
        for _, path in ipairs(paths) do
            if path and path:IsA("ModuleScript") then
                return require(path)
            end
        end
        
        -- Look for UIManager in the client context
        local clients = {
            LocalPlayer:FindFirstChild("PlayerScripts"):FindFirstChild("client"),
            ReplicatedStorage:FindFirstChild("client"),
            ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client")
        }
        
        for _, client in ipairs(clients) do
            if client then
                local ui = client:FindFirstChild("UI") or client
                local uiCore = ui:FindFirstChild("Core") or ui
                
                if uiCore:FindFirstChild("UIManager") and uiCore.UIManager:IsA("ModuleScript") then
                    return require(uiCore.UIManager)
                end
            end
        end
        
        return nil
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

-- Wait for the ShowDoubleMemberUIEvent
local showDoubleMemberUIEvent = ReplicatedStorage:WaitForChild("ShowDoubleMemberUIEvent")

-- Handle the event
showDoubleMemberUIEvent.OnClientEvent:Connect(function()
    print("Received ShowDoubleMemberUIEvent")
    
    -- Try to get UIManager if we don't have it yet
    if not UIManager then
        UIManager = findUIManager()
    end
    
    -- Use UIManager if available
    if UIManager and UIManager.showUI then
        print("Using UIManager to show DoubleMemberPurchaseUI")
        
        -- Try to hide any current UI that might be showing
        if UIManager.hideAllUI then
            UIManager.hideAllUI()
        end
        
        -- Show the Double Member Purchase UI
        UIManager:showUI("DoubleMemberPurchaseUI")
    else
        -- Fallback if UIManager isn't available - try to find the GUI directly
        print("UIManager not found, trying direct GUI access")
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local doubleMemberPurchaseUI = playerGui:FindFirstChild("DoubleMemberPurchaseUI") or 
                                       playerGui:FindFirstChild("DoubleMemberPurchaseGui")
        
        if doubleMemberPurchaseUI then
            doubleMemberPurchaseUI.Enabled = true
        else
            warn("Could not find DoubleMemberPurchaseUI")
        end
    end
end)

print("ShowDoubleMemberUI client script initialized")
