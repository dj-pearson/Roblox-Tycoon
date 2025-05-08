--!strict
--[[
    init.client.luau
    
    Initializes the UI system and handles screen navigation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the module loader and registry
local ModuleLoader = require(script.Parent.Core.ModuleLoader)
local UIRegistry = require(script.Parent.Core.UIRegistry)

-- Initialize registry
local registry = UIRegistry.new()
registry:initialize()

-- UI System
local UISystem = {
    currentScreen = nil,
    screens = {},
    initialized = false
}

-- Show a screen
function UISystem.showScreen(screenName)
    -- Get the screen component
    local screen = registry:getComponent(screenName)
    if not screen then
        warn("Screen not found:", screenName)
        return
    end
    
    -- Hide current screen if exists
    if UISystem.currentScreen then
        UISystem.currentScreen:hide()
    end
    
    -- Show new screen
    screen:show()
    UISystem.currentScreen = screen
end

-- Initialize UI
function UISystem.initialize()
    if UISystem.initialized then return end
    
    -- Load core components
    local UIManager = ModuleLoader.loadCore("UIManager")
    if not UIManager then
        warn("Failed to load UIManager")
        return
    end
    
    -- Load screens
    local MainMenu = ModuleLoader.loadScreen("MainMenu")
    local Settings = ModuleLoader.loadScreen("Settings")
    local LoadingScreen = ModuleLoader.loadScreen("LoadingScreen")
    local PauseMenu = ModuleLoader.loadScreen("PauseMenu")
    
    -- Register screens
    registry:registerComponent("MainMenu", "SCREENS", "1.0.0")
    registry:registerComponent("Settings", "SCREENS", "1.0.0")
    registry:registerComponent("LoadingScreen", "SCREENS", "1.0.0")
    registry:registerComponent("PauseMenu", "SCREENS", "1.0.0")
    
    -- Set up screen navigation
    UISystem.screens = {
        MainMenu = MainMenu,
        Settings = Settings,
        LoadingScreen = LoadingScreen,
        PauseMenu = PauseMenu
    }
    
    -- Set up button handlers
    if MainMenu then
        MainMenu.settingsButton.MouseButton1Click:Connect(function()
            UISystem.showScreen("Settings")
        end)
        
        MainMenu.playButton.MouseButton1Click:Connect(function()
            -- TODO: Start game
        end)
    end
    
    UISystem.initialized = true
end

-- Handle player ready
local function onPlayerReady()
    UISystem.initialize()
    UISystem.showScreen("LoadingScreen")
    
    -- Simulate loading
    local loadingScreen = UISystem.screens.LoadingScreen
    if loadingScreen then
        for i = 0, 100, 10 do
            loadingScreen:updateProgress(i)
            task.wait(0.1)
        end
        
        UISystem.showScreen("MainMenu")
    end
end

-- Clean up
local function cleanup()
    if UISystem.currentScreen then
        UISystem.currentScreen:hide()
    end
    
    registry:cleanup()
    UISystem.initialized = false
end

-- Initialize when player is ready
if Players.LocalPlayer then
    onPlayerReady()
else
    Players.LocalPlayerAdded:Connect(onPlayerReady)
end

-- Clean up when player leaves
Players.LocalPlayerRemoving:Connect(cleanup)

return UISystem 