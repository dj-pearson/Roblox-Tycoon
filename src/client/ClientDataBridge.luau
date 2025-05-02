--!strict
--[[
    ClientDataBridge.luau
    
    Client-side compatibility layer that connects legacy DataManagementUI
    with the new client data service system.
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- New data system references
local ClientDataService = require(script.Parent:WaitForChild("Data"):WaitForChild("ClientDataService"))

-- Create bridge
local ClientDataBridge = {}

-- Data access functions that map to new system
function ClientDataBridge:GetData(key)
    return ClientDataService:GetData(key)
end

function ClientDataBridge:GetTycoonData(tycoonId, key)
    return ClientDataService:GetTycoonData(tycoonId, key)
end

function ClientDataBridge:GetAllData()
    return ClientDataService:GetAllData()
end

function ClientDataBridge:RequestDataUpdate(key, value)
    return ClientDataService:UpdateData(key, value)
end

function ClientDataBridge:RequestTycoonDataUpdate(tycoonId, key, value)
    return ClientDataService:UpdateTycoonData(tycoonId, key, value)
end

-- Event subscription methods
function ClientDataBridge:SubscribeToDataChanges(key, callback)
    return ClientDataService:SubscribeToDataChanges(key, callback)
end

function ClientDataBridge:SubscribeToTycoonDataChanges(tycoonId, key, callback)
    return ClientDataService:SubscribeToTycoonDataChanges(tycoonId, key, callback)
end

-- UI-specific functions
function ClientDataBridge:OpenDataViewer(dataCategory)
    -- Forward to new UI system if available, otherwise use legacy viewer
    local newUISystem = script.Parent:FindFirstChild("UI"):FindFirstChild("DataViewer")
    if newUISystem and typeof(newUISystem.Open) == "function" then
        return newUISystem.Open(dataCategory)
    else
        -- Return a dummy connection for compatibility
        return {
            Disconnect = function() end
        }
    end
end

function ClientDataBridge:ShowNotification(message, notificationType)
    -- Forward to new notification system if available
    local notificationSystem = script.Parent:FindFirstChild("UI"):FindFirstChild("NotificationSystem")
    if notificationSystem and typeof(notificationSystem.Show) == "function" then
        return notificationSystem.Show(message, notificationType)
    else
        -- Fallback to simple print for debugging
        print("[ClientDataBridge] Notification:", message, "(Type:", notificationType, ")")
    end
end

-- Register with client registry if available
local success, ClientRegistry = pcall(function()
    return require(script.Parent:WaitForChild("Core"):WaitForChild("ClientRegistry"))
end)

if success and ClientRegistry then
    ClientRegistry:RegisterSystem("ClientDataBridge", ClientDataBridge)
end

return ClientDataBridge
