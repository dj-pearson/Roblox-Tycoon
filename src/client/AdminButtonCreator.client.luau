-- AdminButtonCreator.client.luau
-- Script to create the admin button that provides access to global commands
-- Updated May 4, 2025 - Simple launcher for emergency admin UI

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Only authorized admin ID
local ADMIN_ID = 7768610061

-- Log function with timestamp
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    print("[AdminButtonCreator " .. timestamp .. "] " .. message)
end

-- Check if player is admin
local function isAdmin()
    return LocalPlayer.UserId == ADMIN_ID
end

-- When the game starts, check if we can use admin systems
if isAdmin() then
    log("Admin detected, attempting to create admin interface")
    
    -- Try to use the EmergencyAdminButton first
    local emergencyScript = script.Parent:FindFirstChild("EmergencyAdminButton.client.luau")
    
    if emergencyScript then
        log("Found emergency admin script, it will auto-execute")
    else
        -- If emergency admin isn't available, try to use AdminCommandsExtension
        local adminExtension = script.Parent:FindFirstChild("AdminCommandsExtension.client.luau")
        
        if adminExtension then
            log("Found AdminCommandsExtension, attempting to use it")
            -- The extension will auto-execute as a client script
        else
            log("Admin extensions not found, consider adding EmergencyAdminButton.client.luau")
        end
    end
end
