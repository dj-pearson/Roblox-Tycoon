--[[
    DarkOverlayFix.client.luau
    
    This script identifies and fixes dark overlays and hazes that may be stuck on screen.
    It runs on game start and can be triggered again via an admin command.
    
    April 28, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configuration
local DEBUG_MODE = true
local FIX_ON_LOAD = true
local CHECK_INTERVAL = 10 -- seconds between automatic checks

-- Local functions
local function log(message)
    if DEBUG_MODE then
        print("[DarkOverlayFix] " .. message)
    end
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
                   element.Size == UDim2.new(1, 0, 1, 0) and
                   element.BackgroundTransparency < 0.95 then
                   
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
        end
    end
    
    if fixCount > 0 then
        log("Fixed " .. fixCount .. " dark overlays")
    else
        log("No dark overlays found")
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
