--!strict
--[[
    DataSystemBridge.luau
    
    Compatibility layer that bridges the legacy DataManager API with the new modular data system.
    This allows existing code to continue working while migration proceeds.
    
    Created: May 2, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import new data system components
local DataFolder = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Data")
local NewDataManager = require(DataFolder:WaitForChild("DataManager"))
local PlayerDataService = require(DataFolder:WaitForChild("PlayerDataService"))
local TycoonDataService = require(DataFolder:WaitForChild("TycoonDataService"))

-- Create compatibility wrapper
local DataSystemBridge = {}

-- Migrate core functions from old DataManager to new system
function DataSystemBridge:GetPlayerData(player, key)
    return PlayerDataService:GetData(player, key)
end

function DataSystemBridge:SetPlayerData(player, key, value)
    return PlayerDataService:SetData(player, key, value)
end

function DataSystemBridge:UpdatePlayerData(player, key, updateFunction)
    return PlayerDataService:UpdateData(player, key, updateFunction)
end

function DataSystemBridge:SavePlayerData(player)
    return PlayerDataService:SaveData(player)
end

function DataSystemBridge:GetTycoonData(tycoonId, key)
    return TycoonDataService:GetData(tycoonId, key)
end

function DataSystemBridge:SetTycoonData(tycoonId, key, value)
    return TycoonDataService:SetData(tycoonId, key, value)
end

function DataSystemBridge:UpdateTycoonData(tycoonId, key, updateFunction)
    return TycoonDataService:UpdateData(tycoonId, key, updateFunction)
end

function DataSystemBridge:SaveTycoonData(tycoonId)
    return TycoonDataService:SaveData(tycoonId)
end

-- Session management compatibility
function DataSystemBridge:PlayerAdded(player)
    return NewDataManager.PlayerAdded(player)
end

function DataSystemBridge:PlayerRemoving(player)
    return NewDataManager.PlayerRemoving(player)
end

-- Backup and version management compatibility
function DataSystemBridge:CreateBackup(player)
    return NewDataManager.CreateBackup(player)
end

function DataSystemBridge:RestoreFromBackup(player, backupId)
    return NewDataManager.RestoreFromBackup(player, backupId)
end

function DataSystemBridge:GetDataVersion(player)
    return NewDataManager.GetDataVersion(player)
end

-- Admin tools compatibility
function DataSystemBridge:WipePlayerData(player)
    return PlayerDataService:WipeData(player)
end

function DataSystemBridge:IsDataLoaded(player)
    return PlayerDataService:IsDataLoaded(player)
end

-- Register with CoreRegistry if it exists
local success, CoreRegistry = pcall(function()
    return require(ServerScriptService.Core.CoreRegistry)
end)

if success and CoreRegistry then
    CoreRegistry:RegisterSystem("DataManager", DataSystemBridge)
end

return DataSystemBridge
