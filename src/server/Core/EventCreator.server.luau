--[[
    EventCreator.server.luau
    
    Creates all required remote events early in game lifecycle to prevent
    "Infinite yield possible on WaitForChild" for events.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- List of events to create
local events = {
    -- Core game events
    "PlayerDataUpdate",
    "TycoonUpdate",
    "UINotification",
    "EquipmentPurchase",
    "StaffHire",
    "CustomerInteraction",
    
    -- Economy events
    "TransactionComplete",
    "ResourceUpdate",
    "PriceUpdate",
    
    -- Gym events
    "GymEquipmentInteraction",
    "WorkoutComplete",
    "MemberSatisfactionChange",
    
    -- System events
    "SystemStatus",
    "ErrorReport",
    "DebugCommand"
}

-- List of RemoteFunctions to create
local remoteFunctions = {
    "GetPlayerData",
    "PurchaseEquipment",
    "HireStaff",
    "UpgradeTycoon",
    "RequestTycoonData"
}

-- List of folders to create for organization
local eventFolders = {
    "UI",
    "Tycoon",
    "Economy",
    "Alliance",
    "SystemEvents"
}

-- Define events that belong in specific folders
local folderEvents = {
    UI = {
        "OpenMenu",
        "CloseMenu",
        "UIResponse",
        "UpdateUI",
        "NotifyPlayer",
        "ShowTooltip",
        "HideTooltip"
    },
    
    Tycoon = {
        "PlaceFurniture",
        "MoveFurniture",
        "SellFurniture",
        "ExpandTycoon",
        "UpgradeTycoon",
        "RemodelTycoon"
    },
    
    Economy = {
        "BankDeposit",
        "BankWithdrawal",
        "LoanRequest",
        "InvestmentUpdate",
        "MarketPriceChange"
    },
    
    Alliance = {
        "JoinAlliance",
        "LeaveAlliance",
        "AllianceInvite",
        "AllianceChat",
        "AllianceResourceShare"
    },
    
    SystemEvents = {
        "ClientReady",
        "ServerRestart",
        "PerformanceReport",
        "FeatureFlag",
        "VersionCheck"
    }
}

print("EventCreator: Starting remote events creation")

-- Ensure RemoteEvents folder exists
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Ensure RemoteFunctions folder exists
local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctionsFolder then
    remoteFunctionsFolder = Instance.new("Folder")
    remoteFunctionsFolder.Name = "RemoteFunctions"
    remoteFunctionsFolder.Parent = ReplicatedStorage
end

-- Create main RemoteEvents
for _, eventName in ipairs(events) do
    local existing = remoteEvents:FindFirstChild(eventName)
    if not existing then
        local event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = remoteEvents
    end
end

-- Create main RemoteFunctions
for _, functionName in ipairs(remoteFunctions) do
    local existing = remoteFunctionsFolder:FindFirstChild(functionName)
    if not existing then
        local func = Instance.new("RemoteFunction")
        func.Name = functionName
        func.Parent = remoteFunctionsFolder
    end
end

-- Create event folders and their events
for _, folderName in ipairs(eventFolders) do
    local folder = remoteEvents:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = remoteEvents
    end
    
    -- Create events in this folder
    if folderEvents[folderName] then
        for _, eventName in ipairs(folderEvents[folderName]) do
            local existing = folder:FindFirstChild(eventName)
            if not existing then
                local event = Instance.new("RemoteEvent")
                event.Name = eventName
                event.Parent = folder
            end
        end
    end
end

print("✅ EventCreator: Remote events creation complete (created " .. #events .. " main events, " .. #remoteFunctions .. " functions, and events in " .. #eventFolders .. " folders)")
