--!strict
--[[
    UISystemEnhancer_fixed.client.luau
    
    Enhanced UI system with fallback mechanisms and improved error handling.
    Provides a robust way to show/hide UI components with multiple fallback paths.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Fixed stuck fallback menu issue
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Debug logging
local function log(message, level)
    local prefix = "[UISystemEnhancer]"
    if level == "error" then
        warn(prefix .. " ERROR: " .. message)
    elseif level == "warn" then
        warn(prefix .. " WARNING: " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Global state tracking for fallback UIs
local fallbackUIs = {}
local isInitializing = false
local initializationAttempts = 0
local MAX_INIT_ATTEMPTS = 3

-- Enhanced cleanup function for fallback UIs
local function cleanupFallbackUI(uiName)
    if fallbackUIs[uiName] then
        -- Store reference before cleanup
        local ui = fallbackUIs[uiName]
        
        -- Remove from tracking first to prevent recursion
        fallbackUIs[uiName] = nil
        
        -- Clean up the UI
        if ui.gui then
            -- Disconnect all connections first
            for _, connection in ipairs(getconnections(ui.gui.Changed)) do
                connection:Disconnect()
            end
            
            -- Remove from parent
            ui.gui.Parent = nil
            
            -- Destroy with error handling
            local success, err = pcall(function()
                ui.gui:Destroy()
            end)
            
            if not success then
                log("Error destroying fallback UI " .. uiName .. ": " .. tostring(err), "error")
            end
        end
        
        log("Cleaned up fallback UI: " .. uiName)
        return true
    end
    return false
end

-- Clean up all fallback UIs
local function cleanupAllFallbackUIs()
    log("Cleaning up all fallback UIs")
    
    -- Create a copy of the keys to avoid modification during iteration
    local uiNames = {}
    for name in pairs(fallbackUIs) do
        table.insert(uiNames, name)
    end
    
    -- Clean up each UI
    for _, name in ipairs(uiNames) do
        cleanupFallbackUI(name)
    end
    
    -- Verify cleanup
    for name in pairs(fallbackUIs) do
        log("Warning: Fallback UI " .. name .. " still exists after cleanup", "warn")
    end
end

-- Create fallback UI with improved error handling
local function createFallbackUI(uiName)
    if fallbackUIs[uiName] then
        log("Fallback UI already exists: " .. uiName, "warn")
        return fallbackUIs[uiName]
    end
    
    log("Creating fallback UI: " .. uiName)
    
    local fallbackUI = {
        name = uiName,
        gui = nil,
        visible = false
    }
    
    -- Create the UI with error handling
    local success, result = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = uiName .. "Fallback"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.4, 0, 0.3, 0)
        frame.Position = UDim2.new(0.3, 0, 0.35, 0)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0.2, 0)
        title.Position = UDim2.new(0, 0, 0.1, 0)
        title.BackgroundTransparency = 1
        title.Text = "UI System Error"
        title.Font = Enum.Font.SourceSansBold
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 24
        title.Parent = frame
        
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(0.8, 0, 0.3, 0)
        message.Position = UDim2.new(0.1, 0, 0.4, 0)
        message.BackgroundTransparency = 1
        message.Text = "Failed to load " .. uiName .. "\nPlease try again or contact support"
        message.Font = Enum.Font.SourceSans
        message.TextColor3 = Color3.fromRGB(255, 255, 255)
        message.TextSize = 18
        message.TextWrapped = true
        message.Parent = frame
        
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0.4, 0, 0.1, 0)
        closeButton.Position = UDim2.new(0.3, 0, 0.85, 0)
        closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        closeButton.Text = "Close"
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextSize = 18
        closeButton.Parent = frame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = closeButton
        
        -- Enhanced close button handling with multiple cleanup attempts
        closeButton.MouseButton1Click:Connect(function()
            -- Try normal cleanup first
            if not cleanupFallbackUI(uiName) then
                -- If that fails, try emergency cleanup
                log("Normal cleanup failed, attempting emergency cleanup", "warn")
                EnhancedUISystem.emergencyCleanup()
            end
        end)
        
        -- Add auto-cleanup on game close
        game:BindToClose(function()
            cleanupFallbackUI(uiName)
        end)
        
        screenGui.Parent = playerGui
        return screenGui
    end)
    
    if success and result then
        fallbackUI.gui = result
        fallbackUI.visible = true
        fallbackUIs[uiName] = fallbackUI
        log("Successfully created fallback UI: " .. uiName)
        return fallbackUI
    else
        log("Failed to create fallback UI: " .. uiName .. " - " .. tostring(result), "error")
        return nil
    end
end

-- Initialize with improved error handling and cleanup
local function initialize()
    if isInitializing then
        log("Initialization already in progress", "warn")
        return
    end
    
    isInitializing = true
    initializationAttempts += 1
    
    log("Initializing UISystemEnhancer (Attempt " .. initializationAttempts .. ")")
    
    -- Clean up any existing fallback UIs first
    cleanupAllFallbackUIs()
    
    -- Preload components
    preloadComponents()
    
    -- Patch UISystem
    patchUISystem()
    
    -- Attempt to show main menu after a delay
    task.delay(1, function()
        local retryCount = 0
        local MAX_RETRIES = 3
        local RETRY_DELAY = 1
        
        local function tryShowMainMenu()
            -- Check if any fallback UIs are visible
            for uiName, fallbackUI in pairs(fallbackUIs) do
                if fallbackUI:isVisible() then
                    log("Found visible fallback UI: " .. uiName .. ", cleaning up")
                    cleanupFallbackUI(uiName)
                end
            end
            
            if showUI("MainMenuUI") then
                log("Successfully showed MainMenuUI")
                isInitializing = false
                return
            end
            
            retryCount = retryCount + 1
            if retryCount < MAX_RETRIES then
                log("Retry " .. retryCount .. " of " .. MAX_RETRIES .. " to show MainMenuUI")
                task.delay(RETRY_DELAY, tryShowMainMenu)
            else
                log("Failed to show MainMenuUI after " .. MAX_RETRIES .. " attempts", "Warning")
                -- Create fallback UI as last resort
                local fallbackUI = createFallbackUI("MainMenuUI")
                if fallbackUI then
                    fallbackUI:show()
                end
                isInitializing = false
            end
        end
        
        tryShowMainMenu()
    end)
    
    log("UISystemEnhancer initialization complete")
end

-- Enhanced emergency cleanup
EnhancedUISystem.emergencyCleanup = function()
    log("Performing emergency UI cleanup")
    
    -- Clean up all fallback UIs
    cleanupAllFallbackUIs()
    
    -- Clean up any ScreenGui with "Gui" suffix
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and string.match(gui.Name, "Gui$") then
            log("Emergency cleanup: Removing " .. gui.Name)
            gui:Destroy()
        end
    end
    
    -- Restore original UI methods
    restoreOriginalMethods()
    
    -- Reset initialization state
    isInitializing = false
    initializationAttempts = 0
    
    -- Try to reinitialize the UI system
    task.spawn(function()
        task.wait(1)
        initialize()
    end)
    
    return true
end

-- Add cleanup on game close
game:BindToClose(function()
    cleanupAllFallbackUIs()
end)

-- Initialize on a slight delay to allow other systems to load first
task.spawn(function()
    task.wait(1) -- Wait 1 second before initializing to allow other systems to load
    initialize()
end)

return UISystemEnhancer 