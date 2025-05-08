--[[
    InitializeUI.client.luau
    
    Initializes the UISystem and UISystemMonitor.
    Ensures proper setup and integration with CoreRegistry.
    
    Features:
    - Initializes UISystem and UISystemMonitor
    - Handles initialization failures
    - Provides detailed logging
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    debug = true,
    initTimeout = 10, -- seconds
    retryDelay = 2, -- seconds
    maxRetries = 3
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[InitializeUI]", ...)
    end
end

-- Initialize UISystem
local function initializeUISystem()
    log("Initializing UISystem...")
    
    -- Try to require UISystem
    local uiSystem
    local success, result = pcall(function()
        return require(LocalPlayer.PlayerScripts.src.client.Core.UISystem)
    end)
    
    if not success then
        log("Failed to require UISystem: " .. tostring(result), true)
        return false
    end
    
    uiSystem = result
    
    -- Initialize UISystem
    success, result = pcall(function()
        return uiSystem.initialize()
    end)
    
    if not success then
        log("Failed to initialize UISystem: " .. tostring(result), true)
        return false
    end
    
    -- Store in global
    _G.UISystem = uiSystem
    
    log("UISystem initialized successfully")
    return true
end

-- Initialize UISystemMonitor
local function initializeUISystemMonitor()
    log("Initializing UISystemMonitor...")
    
    -- Try to require UISystemMonitor
    local uiSystemMonitor
    local success, result = pcall(function()
        return require(LocalPlayer.PlayerScripts.src.client.Core.UISystemMonitor)
    end)
    
    if not success then
        log("Failed to require UISystemMonitor: " .. tostring(result), true)
        return false
    end
    
    uiSystemMonitor = result
    
    -- Initialize UISystemMonitor
    success, result = pcall(function()
        return uiSystemMonitor.initialize()
    end)
    
    if not success then
        log("Failed to initialize UISystemMonitor: " .. tostring(result), true)
        return false
    end
    
    -- Store in global
    _G.UISystemMonitor = uiSystemMonitor
    
    log("UISystemMonitor initialized successfully")
    return true
end

-- Main initialization
local function initialize()
    log("Starting UI system initialization...")
    
    -- Initialize UISystem with retries
    local uiSystemInitialized = false
    for i = 1, CONFIG.maxRetries do
        if initializeUISystem() then
            uiSystemInitialized = true
            break
        end
        
        if i < CONFIG.maxRetries then
            log("Retrying UISystem initialization... (" .. i .. "/" .. CONFIG.maxRetries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    if not uiSystemInitialized then
        log("Failed to initialize UISystem after " .. CONFIG.maxRetries .. " attempts", true)
        return false
    end
    
    -- Initialize UISystemMonitor
    if not initializeUISystemMonitor() then
        log("Failed to initialize UISystemMonitor", true)
        return false
    end
    
    log("UI system initialization completed successfully")
    return true
end

-- Run initialization
local success = initialize()
if not success then
    log("UI system initialization failed", true)
end 