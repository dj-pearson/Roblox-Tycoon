--[[
    DarkOverlayFix.client.luau
    
    This script identifies and fixes dark overlays and hazes that may be stuck on screen.
    It runs on game start and can be triggered again via an admin command.
    
    Updated: May 1, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Configuration
local DEBUG_MODE = true
local FIX_ON_LOAD = true
local CHECK_INTERVAL = 10 -- seconds between automatic checks
local SPECIAL_UI_CHECK_INTERVAL = 3 -- seconds between checks for special UIs

-- Known problematic UI names
local KNOWN_OVERLAY_NAMES = {
    "DarkOverlay",
    "ScreenDimmer",
    "BlackoutFrame",
    "LoadingScreen",
    "TransitionOverlay",
    "FadeOverlay",
    "FullscreenBlur"
}

-- Special UIs that need state-based visibility
local SPECIAL_UIS = {
    "EmergencyUI",
    "RebirthButton",
    "DevConsole",
    "DebugPanel",
    "AdminPanel"
}

-- State tracking
local State = {
    isEmergency = false,
    isRebirthEnabled = false,
    lastFixTime = 0,
    runCount = 0,
    fixedOverlays = 0,
    emergencyUIHidden = false,
    rebirthUIHidden = false
}

-- Local functions
local function log(message)
    if DEBUG_MODE then
        print("[DarkOverlayFix] " .. message)
    end
end

-- Check if player is in emergency state
local function isInEmergencyState()
    -- Try to get emergency state from various sources
    local playerData = player:FindFirstChild("PlayerData")
    if playerData then
        local emergency = playerData:FindFirstChild("EmergencyState")
        if emergency and emergency:IsA("BoolValue") then
            return emergency.Value
        end
    end
    
    -- Check ReplicatedStorage for game state
    local gameState = ReplicatedStorage:FindFirstChild("GameState")
    if gameState then
        local emergency = gameState:FindFirstChild("EmergencyActive")
        if emergency and emergency:IsA("BoolValue") then
            return emergency.Value
        end
    end
    
    -- Default: assume not in emergency
    return false
end

-- Check if rebirth is available for player
local function isRebirthAvailable()
    -- Try to get rebirth state from various sources
    local playerData = player:FindFirstChild("PlayerData")
    if playerData then
        local rebirthData = playerData:FindFirstChild("RebirthData")
        if rebirthData then
            local canRebirth = rebirthData:FindFirstChild("CanRebirth")
            if canRebirth and canRebirth:IsA("BoolValue") then
                return canRebirth.Value
            end
            
            -- Alternative: check if player meets rebirth requirements
            local rebirthLevel = rebirthData:FindFirstChild("RebirthLevel")
            local currentCash = playerData:FindFirstChild("Cash")
            
            if rebirthLevel and currentCash and 
               rebirthLevel:IsA("NumberValue") and 
               currentCash:IsA("NumberValue") then
                -- Basic logic: need at least 1M cash per rebirth level to rebirth again
                local requiredCash = (rebirthLevel.Value + 1) * 1000000
                return currentCash.Value >= requiredCash
            end
        end
    end
    
    -- Check ReplicatedStorage for game configuration
    local gameConfig = ReplicatedStorage:FindFirstChild("GameConfig")
    if gameConfig then
        local rebirthEnabled = gameConfig:FindFirstChild("RebirthEnabled")
        if rebirthEnabled and rebirthEnabled:IsA("BoolValue") then
            return rebirthEnabled.Value
        end
    end
    
    -- Default: allow rebirth for safety (we'd rather show it than hide it if unsure)
    return true
end

-- Main fix function 
local function fixDarkOverlays()
    log("Running dark overlay fix...")
    local fixCount = 0
    
    -- Get player GUI
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then 
        log("PlayerGui not found")
        return 0
    end
    
    -- Loop through all ScreenGuis
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Check the direct children first
            for _, element in pairs(gui:GetChildren()) do
                if element:IsA("Frame") and 
                   element.Size.X.Scale >= 0.9 and
                   element.Size.Y.Scale >= 0.9 and
                   element.BackgroundTransparency < 0.95 and
                   element.BackgroundColor3.R < 0.3 and
                   element.BackgroundColor3.G < 0.3 and
                   element.BackgroundColor3.B < 0.3 then
                   
                    log("Fixed full-screen overlay: " .. element:GetFullName())
                    element.BackgroundTransparency = 1
                    fixCount = fixCount + 1
                    
                    -- Make it invisible after a slight delay
                    task.delay(0.2, function()
                        if element and element.Parent then
                            element.Visible = false
                        end
                    end)
                end
            end
            
            -- Special case for MainMenuUI
            if gui.Name == "MainMenuGui" then
                local background = gui:FindFirstChild("Background")
                if background and background:IsA("Frame") and background.BackgroundTransparency < 1 then
                    background.BackgroundTransparency = 1
                    log("Fixed MainMenuUI background")
                    fixCount = fixCount + 1
                end
            end
            
            -- Check for emergency UI
            if gui.Name == "EmergencyUI" or gui.Name == "AlertUI" then
                -- Check if we should show emergency UI
                local isEmergency = false
                
                -- Try to get game state from ClientRegistry
                local success, ClientRegistry = pcall(function()
                    local shared = ReplicatedStorage:FindFirstChild("shared")
                    if shared and shared:FindFirstChild("SafeRequire") then
                        local safeRequire = require(shared.SafeRequire)
                        return safeRequire.requireFromPath("ClientRegistry")
                    end
                    return nil
                end)
                
                if success and ClientRegistry then
                    local GameState = ClientRegistry.getSystem and ClientRegistry.getSystem("GameState")
                    if GameState then
                        isEmergency = GameState.isEmergency and GameState.isEmergency() or false
                    end
                end
                
                -- Hide emergency UI if we're not in an emergency
                if not isEmergency then
                    gui.Visible = false
                    log("Fixed emergency UI visibility: " .. gui.Name)
                    fixCount = fixCount + 1
                end
            end
            
            -- Check for rebirth button
            local rebirthButton = gui:FindFirstChild("RebirthButton", true)
            if rebirthButton and (rebirthButton:IsA("TextButton") or rebirthButton:IsA("ImageButton")) then
                -- Check if rebirth should be available
                local isRebirthAvailable = false
                
                -- Try to get player data from ClientRegistry
                local success, ClientRegistry = pcall(function()
                    local shared = ReplicatedStorage:FindFirstChild("shared")
                    if shared and shared:FindFirstChild("SafeRequire") then
                        local safeRequire = require(shared.SafeRequire)
                        return safeRequire.requireFromPath("ClientRegistry")
                    end
                    return nil
                end)
                
                if success and ClientRegistry then
                    local PlayerData = ClientRegistry.getSystem and ClientRegistry.getSystem("PlayerData")
                    if PlayerData then
                        isRebirthAvailable = PlayerData.isRebirthAvailable and PlayerData.isRebirthAvailable() or false
                    end
                end
                
                -- Hide rebirth button if it shouldn't be available
                if not isRebirthAvailable and rebirthButton.Visible then
                    rebirthButton.Visible = false
                    log("Fixed rebirth button visibility")
                    fixCount = fixCount + 1
                end
            end
        end
    end
    
    if fixCount > 0 then
        log("Fixed " .. fixCount .. " UI issues")
    else
        log("No UI issues found")
    end
    
    return fixCount
end

-- Run fix on script load if enabled
if FIX_ON_LOAD then
    task.spawn(function()
        -- Wait a moment to let UI initialize
        task.wait(1)
        fixDarkOverlays()
        
        -- Set up periodic check if enabled
        if CHECK_INTERVAL > 0 then
            while true do
                task.wait(CHECK_INTERVAL)
                fixDarkOverlays()
            end
        end
    end)
end

-- Register with admin system if available
if ReplicatedStorage:FindFirstChild("AdminRemotes") then
    local registerCommand = ReplicatedStorage.AdminRemotes:FindFirstChild("RegisterAdminCommand")
    if registerCommand then
        registerCommand:FireServer("fixDarkOverlay", fixDarkOverlays)
    end
end

-- Run fix immediately
fixDarkOverlays()

return {
    fixDarkOverlays = fixDarkOverlays
}
