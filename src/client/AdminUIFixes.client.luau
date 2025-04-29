-- AdminUIFixes.client.luau
-- Client-side functionality for fixing common UI issues

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Store loaded cleanup functions
local loadedCleanupFunctions = {}

-- Try to load a cleanup function from a provided name in shared globals
local function tryGetCleanupFunction(name)
    local getGlobalFn = getfenv(0)[name]
    if typeof(getGlobalFn) == "function" then
        loadedCleanupFunctions[name] = getGlobalFn
        return getGlobalFn
    end
    return nil
end

-- Module
local AdminUIFixes = {}

-- Function to clean up any dark haze/overlay elements
function AdminUIFixes.cleanupHeatOverlay()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    print("Searching for haze overlay elements...")
    local overlaysFound = 0
    
    -- Call the MainMenuUI cleanup function if it exists
    if _G.CleanMainMenuUI then
        local success = pcall(_G.CleanMainMenuUI)
        if success then
            print("Successfully called MainMenuUI cleanup function")
            overlaysFound += 1
        end
    end
    
    -- Look for specific heat overlay from the temperature display
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "HeatOverlayGui" or gui.Name == "SaunaTemperatureUI" or gui.Name == "MainMenuGui" then
            -- Don't destroy MainMenuGui, just make its background transparent
            if gui.Name == "MainMenuGui" then
                for _, child in pairs(gui:GetDescendants()) do
                    if child:IsA("Frame") and child.Size == UDim2.new(1, 0, 1, 0) and child.BackgroundTransparency < 1 then
                        child.BackgroundTransparency = 1
                        child.Visible = false
                        overlaysFound += 1
                        print("Fixed MainMenuUI background transparency")
                    end
                end
            else
                gui:Destroy()
                overlaysFound += 1
                print("Removed overlay: " .. gui.Name)
            end
        end
    end
    
    -- Look for any frame that could be causing a dark haze
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, element in ipairs(gui:GetDescendants()) do
                if element:IsA("Frame") and 
                   element.Size == UDim2.new(1, 0, 1, 0) and
                   element.BackgroundTransparency < 1 and
                   element.BackgroundTransparency > 0 then
                    
                    print("Found potential overlay: " .. element:GetFullName())
                    print("Transparency: " .. element.BackgroundTransparency)
                    
                    -- Check if it's likely an overlay
                    if element.Name:find("Overlay") or 
                       element.Name:find("Modal") or
                       element.Name:find("Background") or
                       element.Name:find("Haze") then
                        element.BackgroundTransparency = 1
                        element.Visible = false
                        overlaysFound += 1
                        print("Fixed overlay transparency for: " .. element:GetFullName())
                    end
                end
            end
        end
    end
    
    -- Call the temperature overlay cleanup function if it exists
    if _G.CleanupSaunaOverlay then
        pcall(_G.CleanupSaunaOverlay)
        print("Called _G.CleanupSaunaOverlay")
    end
    
    -- Try to manually access and reset the TemperatureDisplay's overlay
    local attempt = pcall(function()
        -- Try to find the script
        local tempScript = playerGui:FindFirstChild("SaunaTemperatureUI", true)
        if tempScript and tempScript:IsA("ScreenGui") then
            tempScript:Destroy()
            print("Removed temperature display UI")
            overlaysFound += 1
        end
    end)
    
    return overlaysFound > 0
end

-- Fix stuck modals
function AdminUIFixes.fixStuckModals()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local modalsFixed = 0
    
    -- Look for common modal names
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (
           gui.Name:find("Modal") or
           gui.Name:find("Popup") or
           gui.Name:find("Dialog") or
           gui.Name:find("Confirm") or
           gui.Name:find("Alert")) then
            
            gui:Destroy()
            modalsFixed += 1
        end
    end
    
    return modalsFixed > 0
end

-- Reset UI scales
function AdminUIFixes.resetUIScales()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local scalesReset = 0
    
    -- Reset UI scale properties
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui.IgnoreGuiInset = false
            scalesReset += 1
        end
    end
    
    return scalesReset > 0
end

-- Register with admin system if available
if ReplicatedStorage:FindFirstChild("AdminRemotes") then
    local registerModule = ReplicatedStorage.AdminRemotes:FindFirstChild("RegisterAdminModule")
    if registerModule then
        registerModule:FireServer("UIFixes", {
            fixHeatOverlay = AdminUIFixes.cleanupHeatOverlay,
            fixStuckModals = AdminUIFixes.fixStuckModals,
            resetUIScales = AdminUIFixes.resetUIScales
        })
    end
end

return AdminUIFixes
