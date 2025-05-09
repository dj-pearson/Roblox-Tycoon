--!strict
--[[
    UIScriptEliminator.server.luau
    
    A tool to systematically eliminate redundant UI scripts.
    This script should be placed in ServerScriptService.
    It will disable scripts by renaming them with a ".disabled" suffix.
    
    Usage:
    - Run with eliminate = false to test (scripts will be disabled, not removed)
    - Run with eliminate = true to permanently remove scripts
]]

local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------
-- CONFIGURATION
----------------------------------------
local eliminate = false  -- Set to true to permanently remove scripts, false to just disable
local phase = 1  -- Change this to the current elimination phase (1-3)
----------------------------------------

-- Helper function to find a script in the game
local function findScript(path)
    local parts = string.split(path, "/")
    local current = game
    
    for i, part in ipairs(parts) do
        local child = current:FindFirstChild(part)
        if not child then
            return nil
        end
        current = child
    end
    
    return current
end

-- Helper function to disable or eliminate a script
local function processScript(path)
    local script = findScript(path)
    
    if script then
        if eliminate then
            -- Permanently remove the script
            print("ELIMINATING: " .. path)
            script:Destroy()
        else
            -- Just disable the script by renaming
            print("DISABLING: " .. path)
            script.Name = script.Name .. ".disabled"
        end
        return true
    else
        print("NOT FOUND: " .. path)
        return false
    end
end

-- Scripts to eliminate in each phase
local phaseScripts = {
    -- Phase 1: StarterGui scripts
    {
        "StarterGui/MainMenuUI.client.luau",
        "StarterGui/SettingsUI.client.luau",
        "StarterGui/StatsGui.client.luau",
        "StarterGui/RebirthUI.client.luau",
        "StarterGui/RebirthUI_Enhanced.client.luau",
        "StarterGui/RebirthMenuUI.client.luau",
        "StarterGui/RebirthUIFixes.luau",
        "StarterGui/CloseButtonFactory.lua",
    },
    
    -- Phase 2: StarterPlayerScripts
    {
        "StarterPlayer/StarterPlayerScripts/UIComponentDemo.client.luau",
        "StarterPlayer/StarterPlayerScripts/UIComponentDemo.client-PearsonASUS.luau",
    },
    
    -- Phase 3: Other UI scripts
    {
        "ReplicatedStorage/src/client/UI/MainMenuUI.client.luau",
        "ReplicatedStorage/src/client/UI/MainMenuUILoader.client.luau",
        "ReplicatedStorage/src/client/UI/AchievementsUI.client.luau",
        "ReplicatedStorage/src/client/UI/RebirthUI.client.luau",
        "ReplicatedStorage/src/client/UI/GuestPassUI.client.luau",
        "ReplicatedStorage/src/client/UI/GymMenuUI.client.luau",
        "ReplicatedStorage/src/client/UI/PlayerStatsDisplay.client.luau",
        "ReplicatedStorage/src/client/UI/ProgressBar.client.luau",
    }
}

-- Scripts that require review (not elimination)
local reviewScripts = {
    "StarterGui/TemperatureDisplay.client.luau",
    "StarterGui/DoubleMemberPurchaseGui.client.luau",
    "StarterGui/BuilderBoostPurchaseGui.client.luau",
}

-- Process the scripts for the current phase
local scriptsToProcess = phaseScripts[phase]
if not scriptsToProcess then
    error("Invalid phase number. Choose 1-3.")
end

print("====================================================")
print("UI SCRIPT ELIMINATOR - PHASE " .. phase)
print("Mode: " .. (eliminate and "PERMANENT ELIMINATION" or "DISABLE FOR TESTING"))
print("====================================================")

local processedCount = 0
local successCount = 0

-- Process the scripts
for _, path in ipairs(scriptsToProcess) do
    processedCount = processedCount + 1
    if processScript(path) then
        successCount = successCount + 1
    end
end

print("====================================================")
print("PROCESS COMPLETE")
print("Successfully processed " .. successCount .. " of " .. processedCount .. " scripts")
print("====================================================")

if phase == 3 and eliminate then
    print("All elimination phases complete! The UI system migration is now finalized.")
else
    print("NEXT STEPS:")
    if eliminate then
        print("1. Test the game thoroughly to ensure everything works")
        print("2. If all is well, change phase to " .. (phase + 1) .. " and run again")
    else
        print("1. Test the game thoroughly to ensure everything works")
        print("2. If all is well, set eliminate = true and run again")
        print("3. Then change phase to " .. (phase + 1) .. " and continue")
    end
end

-- Print reminder about scripts that need review
print("\nREMINDER: The following scripts need manual review:")
for _, path in ipairs(reviewScripts) do
    print("- " .. path)
end
