--!strict
--[[
    DeleteDisabledScripts.server.luau
    
    A utility script to bulk delete scripts with the .disabled suffix.
    This can be used to clean up after the UI Script Eliminator has been run.
]]

local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------
-- CONFIGURATION
----------------------------------------
local targetLocation = "all"  -- Options: "all", "StarterGui", "StarterPlayer", "ReplicatedStorage"
local recursive = true  -- Set to true to search in all descendants, false for direct children only
local dryRun = false  -- Set to true to just list the files without deleting them, false to actually delete
----------------------------------------

print("===== DISABLED SCRIPTS BULK DELETION =====")
print("Target Location: " .. targetLocation)
print("Recursive Search: " .. (recursive and "Yes" or "No"))
print("Dry Run Mode: " .. (dryRun and "Yes (will not delete)" or "No (will delete)"))
print("----------------------------------------")

-- Helper function to check if a script has .disabled suffix
local function hasDisabledSuffix(instance)
    return string.match(instance.Name, "%.disabled$") ~= nil
end

-- Function to process instances in a container
local function processContainer(container, prefix)
    local count = 0
    
    -- Get all children to process
    local children = recursive and container:GetDescendants() or container:GetChildren()
    
    for _, instance in ipairs(children) do
        if (instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")) and hasDisabledSuffix(instance) then
            count = count + 1
            local path = prefix .. "." .. instance.Name
            
            if dryRun then
                print("Would delete: " .. path)
            else
                print("Deleting: " .. path)
                instance:Destroy()
            end
        end
    end
    
    return count
end

-- Main processing logic
local totalProcessed = 0

-- Process based on target location
if targetLocation == "all" or targetLocation == "StarterGui" then
    print("\nProcessing StarterGui:")
    totalProcessed = totalProcessed + processContainer(StarterGui, "StarterGui")
end

if targetLocation == "all" or targetLocation == "StarterPlayer" then
    print("\nProcessing StarterPlayer:")
    totalProcessed = totalProcessed + processContainer(StarterPlayer, "StarterPlayer")
end

if targetLocation == "all" or targetLocation == "ReplicatedStorage" then
    print("\nProcessing ReplicatedStorage:")
    totalProcessed = totalProcessed + processContainer(ReplicatedStorage, "ReplicatedStorage")
end

print("\n----------------------------------------")
print("PROCESS COMPLETE")
print("Total scripts with .disabled suffix " .. (dryRun and "found" or "deleted") .. ": " .. totalProcessed)
print("----------------------------------------")

-- Safety warnings and usage instructions
if dryRun then
    print("\nWARNING: This script will permanently delete files with .disabled suffix.")
    print("To actually delete the files, set dryRun = false and run again.")
    print("Make sure you have backups before proceeding with deletion.")
else
    print("\nNOTE: The disabled scripts have been permanently deleted.")
    print("If you need to recover them, check your backups in ServerStorage/Legacy_UI_Backup_20250508/")
end
