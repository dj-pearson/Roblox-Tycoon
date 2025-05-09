--!strict
--[[
    ImprovedUIScriptEliminator.server.luau
    
    An improved tool to systematically disable or eliminate redundant UI scripts.
    This works based on our list of redundant scripts but is more flexible in finding them.
]]

local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------
-- CONFIGURATION
----------------------------------------
local eliminate = true  -- Set to true to permanently remove scripts, false to just disable
local phase = 3  -- Current elimination phase (1-3)
----------------------------------------

print("===== IMPROVED UI SCRIPT ELIMINATOR =====")
print("Mode: " .. (eliminate and "PERMANENT ELIMINATION" or "DISABLE FOR TESTING"))
print("Phase: " .. phase)
print("----------------------------------------")

-- Helper function to find a script by name in the game
local function findScriptByName(scriptName, additionalPatterns)
    local results = {}
    
    -- Try with different name variations
    local namesToTry = {scriptName}
    
    -- Remove file extensions for more flexible searching
    local cleanName = scriptName:gsub("%.client%.luau$", ""):gsub("%.luau$", ""):gsub("%.lua$", "")
    table.insert(namesToTry, cleanName)
    
    -- Add additional patterns specific to this script
    if additionalPatterns then
        for _, pattern in ipairs(additionalPatterns) do
            table.insert(namesToTry, pattern)
        end
    end
    
    -- Try common UI script naming patterns
    table.insert(namesToTry, cleanName .. "UI")
    table.insert(namesToTry, cleanName .. "Gui")
    table.insert(namesToTry, cleanName .. "Menu")
    table.insert(namesToTry, cleanName .. "Client")
    
    -- Also check for scripts that already have .disabled suffix
    table.insert(namesToTry, cleanName .. ".disabled")
    table.insert(namesToTry, cleanName .. "UI.disabled")
    table.insert(namesToTry, cleanName .. "Gui.disabled")
    
    -- Search for each name pattern
    for _, namePattern in ipairs(namesToTry) do
        -- First try a direct search
        local found = game:FindFirstChild(namePattern, true)
        if found and (found:IsA("Script") or found:IsA("LocalScript") or found:IsA("ModuleScript")) then
            table.insert(results, found)
        end
        
        -- Additional search locations based on phase
        if phase == 2 then
            -- Specific search for StarterPlayerScripts items
            for _, child in ipairs(StarterPlayer.StarterPlayerScripts:GetDescendants()) do
                if (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript")) then
                    if string.find(child.Name:lower(), namePattern:lower()) then
                        if not table.find(results, child) then
                            table.insert(results, child)
                        end
                    end
                end
            end
        elseif phase == 3 then
            -- For Phase 3, focus on client UI folders and ReplicatedStorage
            local searchLocations = {
                game:GetService("ReplicatedStorage"),
                game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.PlayerScripts,
            }
            
            -- Also search specific UI directories if we can find them
            local clientUI = ReplicatedStorage:FindFirstChild("src") and 
                             ReplicatedStorage.src:FindFirstChild("client") and 
                             ReplicatedStorage.src.client:FindFirstChild("UI")
            
            if clientUI then
                table.insert(searchLocations, clientUI)
            end
            
            -- Search each location
            for _, location in ipairs(searchLocations) do
                if location then
                    for _, child in ipairs(location:GetDescendants()) do
                        if (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript")) then
                            if string.find(child.Name:lower(), namePattern:lower()) then
                                if not table.find(results, child) then
                                    table.insert(results, child)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return results
end

-- Helper function to disable or eliminate a script
local function processScript(scriptInstance)
    if not scriptInstance then return false end
    
    -- Get the full path for logging
    local path = ""
    local current = scriptInstance
    while current and current ~= game do
        path = current.Name .. (path == "" and "" or ("." .. path))
        current = current.Parent
    end
    
    -- Check if the script is already disabled
    local isAlreadyDisabled = string.match(scriptInstance.Name, "%.disabled$") ~= nil
    
    if eliminate then
        -- Permanently remove the script
        print("ELIMINATING: " .. path)
        scriptInstance:Destroy()
        return true
    else
        -- Just disable the script by renaming (if not already disabled)
        if not isAlreadyDisabled then
            print("DISABLING: " .. path)
            scriptInstance.Name = scriptInstance.Name .. ".disabled"
            return true
        else
            print("ALREADY DISABLED: " .. path)
            return false
        end
    end
end

-- Scripts to process in each phase with additional search patterns
local phaseData = {
    -- Phase 1: StarterGui scripts
    {
        name = "StarterGui Scripts",
        scripts = {
            {name = "MainMenuUI", patterns = {"MainMenu"}},
            {name = "SettingsUI", patterns = {"Settings"}},
            {name = "StatsGui", patterns = {"Stats", "PlayerStats"}},
            {name = "RebirthUI", patterns = {}},
            {name = "RebirthUI_Enhanced", patterns = {}},
            {name = "RebirthMenuUI", patterns = {}},
            {name = "RebirthUIFixes", patterns = {}},
            {name = "CloseButtonFactory", patterns = {"ButtonFactory"}}
        }
    },
    
    -- Phase 2: StarterPlayerScripts
    {
        name = "StarterPlayerScripts",
        scripts = {
            {name = "UIComponentDemo", patterns = {"ComponentDemo", "UIDemos"}},
            {name = "UIComponentDemo-PearsonASUS", patterns = {"Demo-PearsonASUS"}},
            {name = "UITestScript", patterns = {"UITest"}},
            {name = "UIInitializeTemporary", patterns = {"InitializeTemp", "TempUIInit"}}
        }
    },
    
    -- Phase 3: Other UI scripts
    {
        name = "Other UI Scripts",
        scripts = {
            {name = "MainMenuUI", patterns = {"MainMenu"}},
            {name = "MainMenuUILoader", patterns = {}},
            {name = "AchievementsUI", patterns = {"Achievements"}},
            {name = "RebirthUI", patterns = {}},
            {name = "GuestPassUI", patterns = {"GuestPass"}},
            {name = "GymMenuUI", patterns = {"GymMenu"}},
            {name = "PlayerStatsDisplay", patterns = {"PlayerStats"}},
            {name = "ProgressBar", patterns = {"ProgressBar"}}
        }
    }
}

-- Scripts to review (not eliminate)
local reviewScripts = {
    {name = "TemperatureDisplay", patterns = {}},
    {name = "DoubleMemberPurchaseGui", patterns = {}},
    {name = "BuilderBoostPurchaseGui", patterns = {}}
}

-- Process scripts for the current phase
local currentPhaseData = phaseData[phase]
if not currentPhaseData then
    error("Invalid phase number. Choose 1-3.")
end

print("\nProcessing " .. currentPhaseData.name .. ":")
print("----------------------------------------")

local processedCount = 0
local successCount = 0

-- Process the scripts for this phase
for _, scriptData in ipairs(currentPhaseData.scripts) do
    processedCount = processedCount + 1
    local scripts = findScriptByName(scriptData.name, scriptData.patterns)
    
    if #scripts > 0 then
        print("Found " .. #scripts .. " matching scripts for: " .. scriptData.name)
        for _, script in ipairs(scripts) do
            if processScript(script) then
                successCount = successCount + 1
            end
        end
    else
        print("No scripts found for: " .. scriptData.name)
    end
end

print("\n----------------------------------------")
print("PROCESS COMPLETE")
print("Successfully processed " .. successCount .. " of at least " .. processedCount .. " scripts")
print("----------------------------------------")

-- Print next steps
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
for _, scriptData in ipairs(reviewScripts) do
    local scripts = findScriptByName(scriptData.name, scriptData.patterns)
    print("- " .. scriptData.name .. " (" .. #scripts .. " found)")
    for _, script in ipairs(scripts) do
        local path = ""
        local current = script
        while current and current ~= game do
            path = current.Name .. (path == "" and "" or ("." .. path))
            current = current.Parent
        end
        print("  * " .. path)
    end
end
