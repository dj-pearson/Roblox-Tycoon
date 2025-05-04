--[[
    FixUISystem.client.luau
    
    This is the main entry point for fixing all UI system issues. It orchestrates
    the entire UI fixing process by running the necessary fix scripts in the correct order.
    
    Created: May 4, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run in the client
if not RunService:IsClient() then
    return
end

-- Wait for player to be available
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Helper logging function
local function log(message, isError)
    if isError then
        warn("[FixUISystem] " .. message)
    else
        print("[FixUISystem] " .. message)
    end
end

-- Find script in various locations
local function findScript(scriptName)
    local searchPaths = {
        player:FindFirstChild("PlayerScripts"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            -- Try exact name
            local script = path:FindFirstChild(scriptName)
            if script and (script:IsA("ModuleScript") or script:IsA("Script") or script:IsA("LocalScript")) then
                return script
            end
            
            -- Try with extensions
            for _, ext in ipairs({".client.luau", ".luau", ".lua"}) do
                script = path:FindFirstChild(scriptName .. ext)
                if script and (script:IsA("ModuleScript") or script:IsA("Script") or script:IsA("LocalScript")) then
                    return script
                end
            end
        end
    end
    
    return nil
end

-- Execute a script and wait for it to complete
local function executeScript(scriptName)
    log("Executing: " .. scriptName)
    
    local script = findScript(scriptName)
    if not script then
        log("Script not found: " .. scriptName, true)
        return false
    end
    
    log("Found script at: " .. script:GetFullName())
    
    if script:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(script)
        end)
        
        if success then
            log("Successfully executed: " .. scriptName)
            return true, result
        else
            log("Failed to execute: " .. scriptName .. " - " .. tostring(result), true)
            return false
        end
    else
        log("Script is not a ModuleScript, cannot execute directly: " .. scriptName, true)
        return false
    end
end

-- The sequence of scripts to execute for fixing the UI system
local fixSequence = {
    "ClientRegistryFixer",
    "UISystemFixer",
    "UISystemFixVerifier"
}

print("\n==== STARTING UI SYSTEM FIX SEQUENCE ====")

-- Execute scripts in sequence
local results = {}
for _, scriptName in ipairs(fixSequence) do
    log("Step: " .. scriptName)
    local success, result = executeScript(scriptName)
    
    results[scriptName] = {
        success = success,
        result = result
    }
    
    -- Short delay between script executions to allow for initialization
    task.wait(0.5)
end

-- Print summary
print("\n==== UI SYSTEM FIX SEQUENCE COMPLETE ====")
log("Fix sequence summary:")

for scriptName, result in pairs(results) do
    log(scriptName .. ": " .. (result.success and "SUCCESS" or "FAILED"))
end

-- Final status check
local successCount = 0
for _, result in pairs(results) do
    if result.success then
        successCount += 1
    end
end

if successCount == #fixSequence then
    log("All fixes successfully applied!")
else
    log("Some fixes failed to apply. Check the logs for details.", true)
end

-- Set global status
_G.UISystemFixSequenceComplete = true
_G.UISystemFixSequenceTime = os.time()

return {
    success = successCount == #fixSequence,
    results = results
}
