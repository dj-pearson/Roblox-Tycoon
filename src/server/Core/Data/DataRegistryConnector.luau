--!strict
--[[
    DataRegistryConnector.luau
    
    Integration module that connects the new Data system with 
    both the new unified Registry system and the legacy CoreRegistry.
    
    Created: May 2, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data System Components
local DataFolder = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Data")
local DataManager = require(DataFolder:WaitForChild("DataManager"))
local PlayerDataService = require(DataFolder:WaitForChild("PlayerDataService"))
local TycoonDataService = require(DataFolder:WaitForChild("TycoonDataService"))

-- Attempt to find the new Registry system
local RegistryModule = ServerScriptService:WaitForChild("src"):WaitForChild("shared"):WaitForChild("Registry")
local success, SharedRegistry = pcall(function()
    return require(RegistryModule:WaitForChild("SharedRegistry"))
end)

-- Also try to connect to the legacy CoreRegistry
local legacySuccess, CoreRegistry = pcall(function()
    return require(ServerScriptService:WaitForChild("Core"):WaitForChild("CoreRegistry"))
end)

local DataRegistryConnector = {}

function DataRegistryConnector:Initialize()
    -- Register with the new Registry system
    if success and SharedRegistry then
        SharedRegistry:RegisterSystem("DataManager", {
            Manager = DataManager,
            PlayerData = PlayerDataService,
            TycoonData = TycoonDataService,
            Version = "1.0.0",
            Priority = 10 -- High priority as many systems depend on data
        })
        
        print("[DataRegistryConnector] Registered with SharedRegistry")
    else
        warn("[DataRegistryConnector] Could not register with SharedRegistry")
    end
    
    -- Also register with the legacy system for backward compatibility
    if legacySuccess and CoreRegistry then
        CoreRegistry:RegisterSystem("DataManager", DataManager)
        CoreRegistry:RegisterSystem("PlayerDataService", PlayerDataService)
        CoreRegistry:RegisterSystem("TycoonDataService", TycoonDataService)
        
        print("[DataRegistryConnector] Registered with legacy CoreRegistry")
    else
        warn("[DataRegistryConnector] Could not register with legacy CoreRegistry")
    end
    
    return true
end

-- Run initialization
DataRegistryConnector:Initialize()

return DataRegistryConnector
