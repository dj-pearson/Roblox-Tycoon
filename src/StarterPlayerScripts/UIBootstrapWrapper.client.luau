--!strict
--[[
    UIBootstrapWrapper.client.luau
    
    A wrapper for UIBootstrap that integrates with the toggle system to allow
    easy switching between old and new UI systems during migration.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the UIToggleSystem
local UIToggleSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIToggleSystem"))

-- Initialize when player is ready
local player = Players.LocalPlayer

local function initializeNewUI()
    UIToggleSystem.logAction("Initializing new UI system")
    
    -- Require and initialize the new UI Bootstrap
    local success, result = pcall(function()
        local UIBootstrap = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("UIBootstrap"))
        UIBootstrap.initialize()
        return true
    end)
    
    if success then
        UIToggleSystem.logAction("New UI system initialized successfully")
    else
        warn("Failed to initialize new UI system: " .. tostring(result))
    end
end

-- Initialize UI based on toggle setting
local function initialize()
    if UIToggleSystem.shouldUseNewUI() then
        initializeNewUI()
    else
        UIToggleSystem.logAction("Using old UI system, new UI initialization skipped")
    end
end

-- Initialize when player's PlayerGui is ready
if player:FindFirstChild("PlayerGui") then
    initialize()
else
    player.ChildAdded:Connect(function(child)
        if child:IsA("PlayerGui") then
            initialize()
        end
    end)
end

-- Export functions for use in other scripts
return {
    initialize = initialize,
    toggleNewUI = function(useNewUI)
        UIToggleSystem.setUseNewUI(useNewUI)
        
        -- Logic to hide all UI and reinitialize with the selected system
        -- This could be extended to dynamically switch between systems at runtime
    end
}
