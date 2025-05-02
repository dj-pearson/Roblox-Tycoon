--!strict
--[[
    UIAccessRestrictor.client.luau
    Restricts development UI tools to admin users only
    
    Created: April 29, 2025
    Updated: April 29, 2025 - Simplified implementation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local isStudioMode = RunService:IsStudio()

-- Admin status cache
local isAdminValue = nil

-- Simple admin check function
local function checkIsAdmin()
    -- Use cached value if available
    if isAdminValue ~= nil then
        return isAdminValue
    end
    
    local adminResult = false
    
    -- Check player attributes
    if player:GetAttribute("IsAdmin") or 
       player:GetAttribute("Admin") or 
       player:GetAttribute("IsDeveloper") then
        adminResult = true
    end
    
    -- Check studio mode
    if isStudioMode then
        adminResult = true
    end
    
    -- Try to check admin lists in ReplicatedStorage
    local checkAdminUsers = function()
        if ReplicatedStorage:FindFirstChild("AdminUsers") then
            local adminUsers = require(ReplicatedStorage.AdminUsers)
            if type(adminUsers) == "table" then
                for _, id in pairs(adminUsers) do
                    if id == player.UserId then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    pcall(function()
        if checkAdminUsers() then
            adminResult = true
        end
    end)
    
    -- Cache the result
    isAdminValue = adminResult
    print("[UIAccessRestrictor] Player admin status:", adminResult)
    
    return adminResult
end

-- Find and remove unauthorized UI elements
local function removeUnauthorizedUI()
    if checkIsAdmin() then
        -- In studio mode or for admin users, we still want to keep some UIs hidden
        -- to avoid screen clutter unless they're explicitly enabled
        local studioOnlyUIs = {
            "EmergencyUIAccess", 
            "EmergencyUI",
            "AlertUI"
        }
        
        -- Check if we should force-hide emergency UI
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, name in ipairs(studioOnlyUIs) do
                local ui = playerGui:FindFirstChild(name)
                if ui and ui:IsA("ScreenGui") then
                    -- Only hide if not specifically enabled with attribute
                    if not ui:GetAttribute("ForceShow") then
                        print("[UIAccessRestrictor] Hiding studio UI:", name)
                        ui.Enabled = false
                    end
                end
            end
        end
        
        print("[UIAccessRestrictor] Admin user detected, keeping most developer UIs")
        return
    end
    
    print("[UIAccessRestrictor] Removing development UIs for non-admin user")
    
    -- UI elements to remove
    local uiNames = {
        "EmergencyUIAccess",
        "AdminDashboard",
        "AdminPanel",
        "AdminControls",
        "DeveloperConsole",
        "UISystemDebugger",
        "WaitForChildFinder",
        "RebirthMenuUI",
        "DevTools",
        "DevConsole",
        "DebugDisplay",
        "PerfStats",
        "PerformanceMonitor",
        "SystemMonitor",
        "DiagnosticsGui"
    }
    
    -- Remove from PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, name in ipairs(uiNames) do
            local ui = playerGui:FindFirstChild(name)
            if ui then
                print("[UIAccessRestrictor] Removing:", name)
                ui:Destroy()
            end
        end
        
        -- Also look for all screen GUIs with "Dev" in their name
        for _, ui in pairs(playerGui:GetChildren()) do
            if ui:IsA("ScreenGui") and 
              (string.find(ui.Name, "Dev") or 
               string.find(ui.Name, "Admin") or 
               string.find(ui.Name, "Debug")) then
                print("[UIAccessRestrictor] Removing developer UI:", ui.Name)
                ui:Destroy()
            end
        end
    end
    
    -- Disable emergency UI creation
    local function patchEnhancer(scriptObj)
        if scriptObj then
            scriptObj:SetAttribute("DisableEmergencyUI", true)
            print("[UIAccessRestrictor] Patched:", scriptObj.Name)
        end
    end
    
    -- Find and patch enhancer scripts
    local playerScripts = player:FindFirstChild("PlayerScripts")
    if playerScripts then
        patchEnhancer(playerScripts:FindFirstChild("UISystemEnhancer"))
        patchEnhancer(playerScripts:FindFirstChild("UISystemEnhancer_fixed"))
    end
end

-- Monitor for new UIs being added
local function setupUIMonitoring()
    local playerGui = player:WaitForChild("PlayerGui")
    
    playerGui.ChildAdded:Connect(function(child)
        if not checkIsAdmin() and table.find({
            "EmergencyUIAccess", "AdminDashboard", "AdminPanel"
        }, child.Name) then
            print("[UIAccessRestrictor] Blocking new UI:", child.Name)
            child:Destroy()
        end
    end)
    
    print("[UIAccessRestrictor] UI monitoring enabled")
end

-- Run initial cleanup
removeUnauthorizedUI()

-- Set up monitoring
setupUIMonitoring()

-- Periodically check for new UIs
task.spawn(function()
    while task.wait(5) do
        removeUnauthorizedUI()
    end
end)

return {
    isAdmin = checkIsAdmin,
    removeUnauthorizedUI = removeUnauthorizedUI
}
