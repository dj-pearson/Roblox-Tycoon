-- MainMenuUILoader.client.luau
-- This script ensures that the MainMenuUI is properly loaded and registered
-- Fix for the main menu not showing up - April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("MainMenuUILoader: Starting...")

-- Wait for UI Registry
local function waitForRegistry()
    local registry
    local startTime = os.clock()
    local timeout = 10 -- seconds
    
    while not registry and os.clock() - startTime < timeout do
        -- Try to get registry from global
        if _G.UIRegistry then
            registry = _G.UIRegistry
            break
        end
        
        -- Try to find in client registry
        if _G.ClientRegistry and _G.ClientRegistry.getSystem then
            registry = _G.ClientRegistry:getSystem("UIRegistry")
            if registry then
                break
            end
        end
        
        task.wait(0.1)
    end
    
    return registry
end

-- Helper function to safely require modules
local function requireSafely(modulePath)
    if not modulePath or not modulePath:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("MainMenuUILoader: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find and load MainMenuUI
local function loadMainMenuUI()
    -- Find src path
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    if not srcFolder then
        warn("MainMenuUILoader: src folder not found")
        return nil
    end
    
    -- Find client path
    local clientFolder = srcFolder:FindFirstChild("client")
    if not clientFolder then
        warn("MainMenuUILoader: client folder not found")
        return nil
    end
    
    -- Find UI path
    local uiFolder = clientFolder:FindFirstChild("UI")
    if not uiFolder then
        warn("MainMenuUILoader: UI folder not found")
        return nil
    end
    
    -- Find Screens path
    local screensFolder = uiFolder:FindFirstChild("Screens")
    if not screensFolder then
        warn("MainMenuUILoader: Screens folder not found")
        return nil
    end
    
    -- Find MainMenuUI module
    local mainMenuModule = screensFolder:FindFirstChild("MainMenuUI")
    if not mainMenuModule or not mainMenuModule:IsA("ModuleScript") then
        warn("MainMenuUILoader: MainMenuUI module not found")
        return nil
    end
    
    -- Load the module
    local mainMenuUI = requireSafely(mainMenuModule)
    if not mainMenuUI then
        warn("MainMenuUILoader: Failed to load MainMenuUI module")
        return nil
    end
    
    print("MainMenuUILoader: Successfully loaded MainMenuUI module")
    return mainMenuUI
end

-- Main execution
local registry = waitForRegistry()
if not registry then
    warn("MainMenuUILoader: Could not find UIRegistry after timeout")
    return
end

print("MainMenuUILoader: Found UIRegistry")

-- Load MainMenuUI
local mainMenuUI = loadMainMenuUI()
if not mainMenuUI then
    warn("MainMenuUILoader: Could not load MainMenuUI")
    return
end

-- Initialize if needed
if mainMenuUI.initialize then
    mainMenuUI:initialize()
    print("MainMenuUILoader: Initialized MainMenuUI")
end

-- Register with registry
if registry.registerComponent then
    registry:registerComponent("MainMenuUI", mainMenuUI)
    registry:registerComponent("MainMenu", mainMenuUI) -- Also register as MainMenu for compatibility
    print("MainMenuUILoader: Registered MainMenuUI with registry")
else
    warn("MainMenuUILoader: Registry does not have registerComponent method")
end

-- Create a link to main menu in global space for emergency access
_G.MainMenuUI = mainMenuUI
print("MainMenuUILoader: MainMenuUI is now accessible via _G.MainMenuUI")

-- Optional: try to show main menu if it's not visible already
task.delay(1, function()
    -- Try to access UISystem
    local uiSystem
    
    if _G.UISystem then
        uiSystem = _G.UISystem
    elseif _G.ClientRegistry and _G.ClientRegistry.getSystem then
        uiSystem = _G.ClientRegistry:getSystem("UISystem")
    end
    
    if uiSystem and uiSystem.showMainMenu then
        print("MainMenuUILoader: Attempting to show main menu via UISystem")
        uiSystem:showMainMenu()
    else
        print("MainMenuUILoader: UISystem not available, showing MainMenuUI directly")
        -- Direct fallback
        if mainMenuUI.show then
            mainMenuUI:show()
        end
    end
end)

print("MainMenuUILoader: Setup complete")
