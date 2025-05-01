--[[
    UISystemEnhancer.client.luau
    
    Enhances UI system functionality by handling UI component display,
    error recovery, and visibility management. This helps resolve issues
    with MainMenuUI display failures and other UI visibility problems.
    
    Created: May 1, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    MAX_DISPLAY_ATTEMPTS = 10,
    RETRY_DELAY = 0.5,
    DEBUG_MODE = true
}

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    if not module:IsA("ModuleScript") then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        if CONFIG.DEBUG_MODE then
            warn("[UISystemEnhancer] Failed to require module: " .. module:GetFullName())
        end
        return nil
    end
end

-- Module search function
local function findModule(moduleName)
    local searchPaths = {
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts:FindFirstChild("Client"),
        player.PlayerScripts,
        player.PlayerScripts:FindFirstChild("UI"),
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
    
    return nil
end

-- Logging function
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[UISystemEnhancer] " .. message)
    end
end

-- Find ClientRegistry
local clientRegistryModule = findModule("ClientRegistry")
local ClientRegistry = safeRequire(clientRegistryModule)

-- Check if UI is loaded
local function isUILoaded(uiName)
    -- Try through ClientRegistry first
    if ClientRegistry and ClientRegistry.getComponent then
        local component = ClientRegistry.getComponent(uiName)
        if component then
            return true
        end
    end
    
    -- Check if UI exists in PlayerGui
    local ui = playerGui:FindFirstChild(uiName) or playerGui:FindFirstChild(uiName .. "Gui")
    if ui then
        return true
    end
    
    -- Check if UI exists in _G
    if _G[uiName] then
        return true
    end
    
    return false
end

-- Attempt to show UI
local function showUI(uiName)
    log("Attempting to show UI: " .. uiName)
    
    local attempts = 0
    local showComplete = false
    
    -- Function to attempt showing UI
    local function attemptShow()
        attempts = attempts + 1
        
        -- Try through ClientRegistry first
        if ClientRegistry and ClientRegistry.getComponent then
            local component = ClientRegistry.getComponent(uiName)
            if component and component.show then
                component:show()
                showComplete = true
                log("Successfully showed UI through ClientRegistry: " .. uiName)
                return true
            end
        end
        
        -- Try to find the UI module
        local uiModule = findModule(uiName)
        if uiModule then
            local ui = safeRequire(uiModule)
            if ui then
                -- Try various known show patterns
                if ui.show then
                    ui:show()
                    showComplete = true
                    log("Successfully showed UI using show(): " .. uiName)
                    return true
                elseif ui.Show then
                    ui:Show()
                    showComplete = true
                    log("Successfully showed UI using Show(): " .. uiName)
                    return true
                elseif ui.ShowMainMenu then
                    ui:ShowMainMenu(true)
                    showComplete = true
                    log("Successfully showed UI using ShowMainMenu(): " .. uiName)
                    return true
                elseif ui.Initialize then
                    ui:Initialize()
                    showComplete = true
                    log("Successfully showed UI using Initialize(): " .. uiName)
                    return true
                end
            end
        end
        
        -- Check _G for UI components
        if _G[uiName] and typeof(_G[uiName]) == "table" then
            local ui = _G[uiName]
            if ui.show then
                ui:show()
                showComplete = true
                log("Successfully showed UI from _G using show(): " .. uiName)
                return true
            elseif ui.Show then
                ui:Show()
                showComplete = true
                log("Successfully showed UI from _G using Show(): " .. uiName)
                return true
            elseif ui.ShowMainMenu then
                ui:ShowMainMenu(true)
                showComplete = true
                log("Successfully showed UI from _G using ShowMainMenu(): " .. uiName)
                return true
            end
        end
        
        return false
    end
    
    -- Try immediately
    if attemptShow() then
        return true
    end
    
    -- Retry with delay if failed
    while not showComplete and attempts < CONFIG.MAX_DISPLAY_ATTEMPTS do
        task.wait(CONFIG.RETRY_DELAY)
        if attemptShow() then
            return true
        end
    end
    
    if not showComplete then
        warn("[UISystemEnhancer] All attempts to show UI failed: " .. uiName)
    end
    
    return showComplete
end

-- Check if MainMenuUI is loaded and show it
if not isUILoaded("MainMenuUI") then
    log("MainMenuUI not loaded, attempting to load and show it")
    
    -- Try to find and require MainMenuUI
    local mainMenuModule = findModule("MainMenuUI")
    if mainMenuModule then
        local MainMenuUI = safeRequire(mainMenuModule)
        if MainMenuUI then
            -- Initialize and show
            if MainMenuUI.Initialize then
                MainMenuUI:Initialize()
                log("MainMenuUI initialized")
            end
            
            -- Register with ClientRegistry if available
            if ClientRegistry and ClientRegistry.registerComponent then
                ClientRegistry.registerComponent("MainMenuUI", MainMenuUI)
                log("Registered MainMenuUI with ClientRegistry")
            end
            
            -- Store in _G for emergency access
            _G.MainMenuUI = MainMenuUI
            
            -- Show the UI
            showUI("MainMenuUI")
        else
            warn("[UISystemEnhancer] Failed to load MainMenuUI module")
        end
    else
        warn("[UISystemEnhancer] Could not find MainMenuUI module")
    end
else
    log("MainMenuUI already loaded, attempting to show it")
    showUI("MainMenuUI")
end

-- Create a function to help other scripts show UIs
local UISystemEnhancer = {
    showUI = showUI,
    isUILoaded = isUILoaded,
    findModule = findModule,
    CONFIG = CONFIG
}

-- Register with ClientRegistry if available
if ClientRegistry and ClientRegistry.registerComponent then
    ClientRegistry.registerComponent("UISystemEnhancer", UISystemEnhancer)
    log("Registered UISystemEnhancer with ClientRegistry")
end

-- Store in _G for emergency access
_G.UISystemEnhancer = UISystemEnhancer

return UISystemEnhancer
