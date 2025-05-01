--[[
    MainMenuUILoader.client.luau
    
    Ensures that MainMenuUI is properly loaded and displayed for users.
    This script fixes the persistent issue where MainMenuUI fails to display.
    
    Created: May 1, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

print("MainMenuUILoader: Starting...")

-- Find module helper
local function findModule(moduleName)
    local searchPaths = {
        player.PlayerScripts:FindFirstChild("UI"),
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts:FindFirstChild("Client"),
        player.PlayerScripts,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    -- Special case for StarterGui location
    if game:GetService("StarterGui"):FindFirstChild(moduleName) then
        local starterModule = game:GetService("StarterGui"):FindFirstChild(moduleName)
        return starterModule
    end
    
    return nil
end

-- Safe require
local function safeRequire(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
            return nil
        end
    end
    return nil
end

-- Find and load ClientRegistry
local clientRegistryModule = findModule("ClientRegistry")
local ClientRegistry = safeRequire(clientRegistryModule)

-- Find and load MainMenuUI
local mainMenuModule = findModule("MainMenuUI")
if not mainMenuModule then
    warn("MainMenuUILoader: MainMenuUI module not found!")
    return
end

local MainMenuUI = safeRequire(mainMenuModule)
if not MainMenuUI then
    warn("MainMenuUILoader: Failed to load MainMenuUI module!")
    return
end

-- Register with ClientRegistry
if ClientRegistry then
    -- Try different registration methods for compatibility
    if typeof(ClientRegistry.registerComponent) == "function" then
        ClientRegistry.registerComponent("MainMenuUI", MainMenuUI)
        ClientRegistry.registerComponent("MainMenu", MainMenuUI) -- Also register as MainMenu for backward compatibility
        print("MainMenuUILoader: Registered MainMenuUI with ClientRegistry using registerComponent")
    elseif typeof(ClientRegistry.RegisterComponent) == "function" then
        ClientRegistry.RegisterComponent("MainMenuUI", MainMenuUI)
        ClientRegistry.RegisterComponent("MainMenu", MainMenuUI) -- Also register as MainMenu for backward compatibility
        print("MainMenuUILoader: Registered MainMenuUI with ClientRegistry using RegisterComponent")
    end
end

-- Initialize MainMenuUI if it has an initialize function
if typeof(MainMenuUI.Initialize) == "function" then
    local success, result = pcall(function()
        return MainMenuUI:Initialize()
    end)
    
    if success then
        print("MainMenuUILoader: MainMenuUI initialized successfully")
    else
        warn("MainMenuUILoader: Failed to initialize MainMenuUI - " .. tostring(result))
    end
elseif typeof(MainMenuUI.initialize) == "function" then
    local success, result = pcall(function()
        return MainMenuUI:initialize()
    end)
    
    if success then
        print("MainMenuUILoader: MainMenuUI initialized successfully")
    else
        warn("MainMenuUILoader: Failed to initialize MainMenuUI - " .. tostring(result))
    end
end

-- Create a global reference for emergency access
_G.MainMenuUI = MainMenuUI

-- Try to show MainMenuUI
local function showMainMenuUI()
    -- Try different show methods for compatibility
    if typeof(MainMenuUI.ShowMainMenu) == "function" then
        MainMenuUI:ShowMainMenu(true)
        print("MainMenuUILoader: Showed MainMenuUI using ShowMainMenu")
        return true
    elseif typeof(MainMenuUI.Show) == "function" then
        MainMenuUI:Show()
        print("MainMenuUILoader: Showed MainMenuUI using Show")
        return true
    elseif typeof(MainMenuUI.show) == "function" then
        MainMenuUI:show()
        print("MainMenuUILoader: Showed MainMenuUI using show")
        return true
    end
    
    warn("MainMenuUILoader: No show method found for MainMenuUI")
    return false
end

-- Wait a moment to let other systems initialize
task.wait(1)

-- Try to show the UI
local showSuccess = showMainMenuUI()

-- If showing failed, try using UISystemEnhancer
if not showSuccess then
    print("MainMenuUILoader: Direct show failed, trying through UISystemEnhancer...")
    
    local uiSystemEnhancerModule = findModule("UISystemEnhancer")
    if uiSystemEnhancerModule then
        local UISystemEnhancer = safeRequire(uiSystemEnhancerModule)
        if UISystemEnhancer and typeof(UISystemEnhancer.showUI) == "function" then
            UISystemEnhancer.showUI("MainMenuUI")
            print("MainMenuUILoader: Requested UISystemEnhancer to show MainMenuUI")
        end
    end
end

print("MainMenuUILoader: Completed")
