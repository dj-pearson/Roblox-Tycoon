--!strict
--[[
    EnsureFixScriptsAutorun.server.luau
    Makes sure that all fix scripts properly autorun
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local AUTORUN_TAG = "AprilFixes"
local FIX_SCRIPTS = {
    "CoreRegistryRestorer",
    "BuyTilePositionFixer",
    "ClientFixDistributor",
    "AprilFixesStartup"
}

-- Utility functions
local function log(message)
    print("[EnsureFixScriptsAutorun] " .. message)
end

-- Find script in various paths
local function findScript(scriptName)
    local paths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src"),
        script.Parent
    }
    
    for _, path in ipairs(paths) do
        if path then
            local foundScript = path:FindFirstChild(scriptName)
            if foundScript then
                return foundScript, path
            end
        end
    end
    
    return nil
end

-- Make sure a script is set to autorun
local function ensureScriptAutoruns(scriptName)
    local script, scriptParent = findScript(scriptName)
    
    if not script then
        log("Could not find script: " .. scriptName)
        return false
    end
    
    log("Found script: " .. scriptName .. " at " .. script:GetFullName())
    
    -- Check if the script is properly configured for autorun
    local isServerScript = script:IsA("Script")
    local hasAutorunTag = script:GetAttribute("Autorun") == true or 
                         script:GetAttribute("AutoRun") == true or
                         script:HasTag(AUTORUN_TAG)
    
    -- If it's a server script and not tagged for autorun, tag it
    if isServerScript and not hasAutorunTag then
        log("Tagging script for autorun: " .. scriptName)
        script:SetAttribute("Autorun", true)
        script:AddTag(AUTORUN_TAG)
    end
    
    return isServerScript
end

-- Ensure all fix scripts autorun
local function ensureAllScriptsAutorun()
    log("Ensuring all fix scripts are set to autorun...")
    
    local results = {}
    local allSuccess = true
    
    for _, scriptName in ipairs(FIX_SCRIPTS) do
        local success = ensureScriptAutoruns(scriptName)
        results[scriptName] = success
        
        if not success then
            allSuccess = false
        end
    end
    
    -- Log results
    log("--- AUTORUN CONFIGURATION RESULTS ---")
    for scriptName, success in pairs(results) do
        local status = success and "✅" or "❌"
        log(status .. " " .. scriptName)
    end
    
    return allSuccess
end

-- Run the configuration
local success = ensureAllScriptsAutorun()
log("Autorun configuration " .. (success and "succeeded" or "failed with some issues"))

return success
