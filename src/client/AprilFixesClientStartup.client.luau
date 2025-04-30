--!strict
--[[
    AprilFixesClientStartup.client.luau
    Initializes all client-side fixes implemented for April 29 issues
    
    Created: April 29, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility functions
local function log(message)
    print("[AprilFixesClientStartup] " .. message)
end

local function requireSafely(moduleScript)
    if not moduleScript then return nil end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("[AprilFixesClientStartup] Failed to require module:", moduleScript:GetFullName(), "-", result)
        return nil
    end
end

-- Wait for player to be fully loaded
local player = Players.LocalPlayer
if not player then
    player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Find script in various paths
local function findScript(scriptName)
    local paths = {
        player:WaitForChild("PlayerScripts"),
        player:WaitForChild("PlayerScripts"):FindFirstChild("src"):FindFirstChild("client"),
        player:WaitForChild("PlayerScripts"):FindFirstChild("Client"),
        script.Parent
    }
    
    for _, path in ipairs(paths) do
        if path then
            local script = path:FindFirstChild(scriptName)
            if script then
                return script
            end
        end
    end
    
    return nil
end

-- Check if fixes should be enabled
local function shouldEnableFixes()
    local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
    if clientConfig then
        local uiAccessFlag = clientConfig:FindFirstChild("EnableUIAccessRestrictor")
        if uiAccessFlag and uiAccessFlag:IsA("BoolValue") then
            return uiAccessFlag.Value
        end
    end
    
    -- Default to enabled if configuration not found
    return true
end

-- Initialize client-side fixes
local function initializeClientFixes()
    if not shouldEnableFixes() then
        log("Client fixes are disabled via configuration")
        return
    end
    
    log("Starting initialization of April 29 client fixes...")
    
    -- Load UIAccessRestrictor
    local uiAccessRestrictorScript = findScript("UIAccessRestrictor")
    if uiAccessRestrictorScript then
        log("Executing UIAccessRestrictor...")
        requireSafely(uiAccessRestrictorScript)
    else
        -- If script not found, create it on the fly
        log("UIAccessRestrictor script not found, creating...")
        
        -- Script creation moved to server-side distribution
        -- We'll just notify that it needs to be added
        warn("[AprilFixesClientStartup] UIAccessRestrictor script not found - please ensure it's added to PlayerScripts")
    end
    
    -- Connect to handle script additions
    player.PlayerScripts.ChildAdded:Connect(function(child)
        if child.Name == "UIAccessRestrictor" and child:IsA("ModuleScript") then
            log("UIAccessRestrictor script added, executing...")
            requireSafely(child)
        end
    end)
    
    log("All April 29 client fixes initialized!")
end

-- Execute with a slight delay to ensure player is fully loaded
task.delay(1, function()
    initializeClientFixes()
end)

return true
