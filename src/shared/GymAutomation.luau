-- GymAutomation.luau
--[[
    This module provides simplified access to gym automation features.
    It wraps the GymAutomationManager functionality for easier use in other scripts.
    
    Author: Updated April 28, 2025
]]

-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Module variables
local GymAutomationManager = nil

-- Try to require GymAutomationManager
local function getGymAutomationManager()
    if GymAutomationManager then
        return GymAutomationManager
    end
    
    -- Try to find the module in different locations
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("server") and
            ReplicatedStorage.src.server:FindFirstChild("GymAutomationManager"),
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and
            ServerStorage.src.server:FindFirstChild("GymAutomationManager"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and
            ServerScriptService.src.server:FindFirstChild("GymAutomationManager"),
        ServerStorage:FindFirstChild("GymAutomation") and ServerStorage.GymAutomation:FindFirstChild("GymAutomationManager"),
        script.Parent and script.Parent:FindFirstChild("GymAutomationManager")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                GymAutomationManager = result
                return GymAutomationManager
            end
        end
    end
    
    return nil
end

-- Create API
local GymAutomation = {}
GymAutomation.initialized = false
GymAutomation.VERSION = "1.0.0"

-- Initialize the module
function GymAutomation.initialize()
    if GymAutomation.initialized then
        return true
    end
    
    local manager = getGymAutomationManager()
    if not manager then
        warn("[GymAutomation] GymAutomationManager not found")
        return false
    end
    
    -- Initialize the manager
    local success = manager:initialize()
    GymAutomation.initialized = success
    
    return success
end

-- Get system status
function GymAutomation.getSystemStatus(systemName)
    local manager = getGymAutomationManager()
    if not manager then
        return nil
    end
    
    return manager:getSystemStatus(systemName)
end

-- Configure automation settings
function GymAutomation.configure(options)
    local manager = getGymAutomationManager()
    if not manager then
        return false
    end
    
    return manager:configure(options)
end

-- Reset automation systems
function GymAutomation.reset()
    local manager = getGymAutomationManager()
    if not manager then
        return false
    end
    
    return manager:reset()
end

-- Get performance metrics
function GymAutomation.getPerformanceMetrics()
    local manager = getGymAutomationManager()
    if not manager then
        return {}
    end
    
    return manager:getPerformanceMetrics()
end

-- Auto-initialize
task.spawn(function()
    GymAutomation.initialize()
end)

return GymAutomation
