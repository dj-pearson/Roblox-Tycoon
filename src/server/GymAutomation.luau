--[[
    GymAutomation.luau
    
    A simplified wrapper for GymAutomationManager.
    This module provides easy access to GymAutomation functionality.
    It wraps the GymAutomationManager functionality for easier use in other scripts.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Try to require GymAutomationManager
local GymAutomationManagerInstance
local function getGymAutomationManager()
    if GymAutomationManagerInstance then
        return GymAutomationManagerInstance
    end
    
    -- Define search paths
    local searchPaths = {
        -- First check in the same folder
        script.Parent and script.Parent:FindFirstChild("GymAutomationManager"),
        
        -- Check standard server script paths
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation") and ServerScriptService.src.server.GymAutomation:FindFirstChild("GymAutomationManager"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("GymAutomationManager"),
        ServerScriptService:FindFirstChild("GymAutomation") and ServerScriptService.GymAutomation:FindFirstChild("GymAutomationManager"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("GymAutomationManager"),
        
        -- Check server storage
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("GymAutomation") and ServerStorage.src.server.GymAutomation:FindFirstChild("GymAutomationManager"),
        ServerStorage:FindFirstChild("GymAutomation") and ServerStorage.GymAutomation:FindFirstChild("GymAutomationManager"),
    }
    
    -- Try each path
    for _, path in ipairs(searchPaths) do
        if path then
            local success, result = pcall(function()
                return require(path)
            end)
              if success and result then
                print("[GymAutomation] Found GymAutomationManager at", path:GetFullName())
                GymAutomationManagerInstance = result
                return GymAutomationManagerInstance
            end
        end
    end
    
    -- Try ModuleScriptAccessor if available
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, ModuleScriptAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and ModuleScriptAccessor and typeof(ModuleScriptAccessor.requireModule) == "function" then            local manager = ModuleScriptAccessor.requireModule("GymAutomationManager")
            if manager then
                print("[GymAutomation] Found GymAutomationManager through ModuleScriptAccessor")
                GymAutomationManagerInstance = manager
                return GymAutomationManagerInstance
            end
        end
    end
    
    warn("[GymAutomation] Failed to find GymAutomationManager")
    return nil
end

-- Create a simplified API
local GymAutomation = {
    initialized = false
}

-- Initialize the system
function GymAutomation.initialize()
    if GymAutomation.initialized then
        return true
    end
    
    local manager = getGymAutomationManager()
    if manager then
        print("[GymAutomation] Successfully loaded GymAutomationManager")
        GymAutomation.initialized = true
        return true
    end
    
    return false
end

-- Automate a specific gym
function GymAutomation:AutomateGym(tycoonName)
    local manager = getGymAutomationManager()
    if manager then
        return manager:AutomateGym(tycoonName)
    end
    
    warn("[GymAutomation] GymAutomationManager not found, cannot automate gym")
    return false
end

-- Automate all gyms
function GymAutomation:AutomateAllGyms()
    local manager = getGymAutomationManager()
    if manager then
        return manager:AutomateAllGyms()
    end
    
    warn("[GymAutomation] GymAutomationManager not found, cannot automate gyms")
    return false
end

-- Process equipment in a gym
function GymAutomation:ProcessEquipment(tycoonName)
    local manager = getGymAutomationManager()
    if manager then
        return manager:ProcessEquipment(tycoonName)
    end
    
    warn("[GymAutomation] GymAutomationManager not found, cannot process equipment")
    return false
end

-- Try to initialize on load
GymAutomation.initialize()

return GymAutomation
