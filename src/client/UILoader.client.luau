-- UILoader.client.luau
-- Loads and initializes all UI modules
-- Created April 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Log function
local function log(message)
    print("[UILoader] " .. message)
end

-- UI modules to load
local UI_MODULES = {
    "MenuButtonCreator",
    "GymTycoonMenuUI",
    "AdminButtonCreator"
}

-- Function to load a UI module
local function loadModule(moduleName)
    local success, result = pcall(function()
        local module = require(script.Parent:FindFirstChild(moduleName))
        return module
    end)
    
    if success then
        log("Successfully loaded: " .. moduleName)
        return result
    else
        log("Failed to load: " .. moduleName .. " - " .. tostring(result))
        return nil
    end
end

-- Wait for player to be fully loaded
local function onPlayerLoaded()
    log("Player loaded, initializing UI modules")
    
    -- Wait to ensure player is fully set up
    task.wait(2)
    
    -- Load all UI modules
    for _, moduleName in ipairs(UI_MODULES) do
        loadModule(moduleName)
    end
    
    log("UI initialization complete")
end

-- If player is already in game
if LocalPlayer:IsDescendantOf(game) then
    onPlayerLoaded()
else
    -- Wait for player to load
    LocalPlayer.CharacterAdded:Connect(function()
        onPlayerLoaded()
    end)
end

-- Expose the loader API
local UILoader = {}

-- Function to manually load a specific UI module
function UILoader.LoadModule(moduleName)
    return loadModule(moduleName)
end

return UILoader
