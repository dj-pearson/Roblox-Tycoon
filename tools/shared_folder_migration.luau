--[[
    shared_folder_migration.luau
    
    This script creates a backup of the ReplicatedStorage\shared folder
    and helps with migrating to the standardized structure using src\shared.
    
    Created: May 3, 2025
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    BACKUP_FOLDER = "backup_shared_" .. os.date("%Y%m%d_%H%M%S"),
    MODULES_TO_CHECK = {
        "AssetValidator",
        "ModuleLoader",
        "SafeRequire",
        "SafeWaitForChild",
        "UIComponents",
        "UIRegistry"
    }
}

-- Create a timestamp for logging
local function timestamp()
    return "[" .. os.date("%H:%M:%S") .. "]"
end

-- Log messages with timestamps
local function log(message, level)
    level = level or "INFO"
    
    local colors = {
        INFO = "\27[34m",  -- Blue
        SUCCESS = "\27[32m",  -- Green
        WARNING = "\27[33m",  -- Yellow
        ERROR = "\27[31m",  -- Red
        RESET = "\27[0m"
    }
    
    print(colors[level] .. timestamp() .. " [" .. level .. "] " .. message .. colors.RESET)
end

-- Create backup folder
local function createBackup()
    log("Creating backup of ReplicatedStorage\\shared folder...", "INFO")
    
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        log("ReplicatedStorage\\shared folder not found.", "ERROR")
        return false
    end
    
    -- Create backup folder in workspace
    local backupFolder = Instance.new("Folder")
    backupFolder.Name = CONFIG.BACKUP_FOLDER
    
    -- Clone all contents from shared folder
    for _, child in ipairs(sharedFolder:GetChildren()) do
        local clone = child:Clone()
        clone.Parent = backupFolder
    end
    
    -- Move backup folder to ServerStorage or somewhere else safe
    local serverStorage = game:GetService("ServerStorage")
    backupFolder.Parent = serverStorage
    
    log("Backup created at ServerStorage\\" .. CONFIG.BACKUP_FOLDER, "SUCCESS")
    return true
end

-- Check if we can safely remove ReplicatedStorage\shared
local function checkSafeToRemove()
    log("Checking if it's safe to remove ReplicatedStorage\\shared...", "INFO")
    
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        log("ReplicatedStorage\\shared folder not found.", "ERROR")
        return false
    end
    
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    if not Shared then
        log("ReplicatedStorage\\Shared folder not found. Make sure src/shared is properly synced.", "ERROR")
        return false
    end
    
    -- Check each module
    local allModulesFound = true
    local modulesWithIssues = {}
    local moduleCompatNotes = {}
    
    for _, moduleName in ipairs(CONFIG.MODULES_TO_CHECK) do
        -- Check for module in old location (with .luau extension)
        local oldModule = sharedFolder:FindFirstChild(moduleName .. ".luau")
        
        -- Check for module in new location (without extension in instance name)
        local newModule = Shared:FindFirstChild(moduleName)
        
        if not oldModule then
            log("Module " .. moduleName .. ".luau not found in old location.", "WARNING")
            table.insert(moduleCompatNotes, {
                name = moduleName,
                note = "Not found in ReplicatedStorage\\shared - newer module only"
            })
            continue
        end
        
        if not newModule then
            log("Module " .. moduleName .. " not found in new location.", "ERROR")
            allModulesFound = false
            table.insert(modulesWithIssues, moduleName)
            table.insert(moduleCompatNotes, {
                name = moduleName,
                note = "Missing in src\\shared - compatibility issue"
            })
        else
            -- Try to load both modules to check compatibility
            local oldModuleSuccess, oldModuleResult = pcall(function()
                return require(oldModule)
            end)
            
            local newModuleSuccess, newModuleResult = pcall(function()
                return require(newModule)
            end)
            
            if not oldModuleSuccess then
                log("Error loading old " .. moduleName .. ": " .. tostring(oldModuleResult), "WARNING")
                table.insert(moduleCompatNotes, {
                    name = moduleName,
                    note = "Error loading from ReplicatedStorage\\shared: " .. tostring(oldModuleResult)
                })
            end
            
            if not newModuleSuccess then
                log("Error loading new " .. moduleName .. ": " .. tostring(newModuleResult), "ERROR")
                allModulesFound = false
                table.insert(modulesWithIssues, moduleName)
                table.insert(moduleCompatNotes, {
                    name = moduleName,
                    note = "Error loading from src\\shared: " .. tostring(newModuleResult)
                })
            end
            
            if oldModuleSuccess and newModuleSuccess then
                log("Module " .. moduleName .. " found in both locations and loads successfully.", "SUCCESS")
                
                -- Basic type compatibility check
                if type(oldModuleResult) ~= type(newModuleResult) then
                    log("Module " .. moduleName .. " has different return types.", "WARNING")
                    table.insert(moduleCompatNotes, {
                        name = moduleName,
                        note = "Different return types: old=" .. type(oldModuleResult) .. ", new=" .. type(newModuleResult)
                    })
                    
                    -- Check if ModuleAdapterWrapper exists to handle compatibility
                    local adapterExists = Shared:FindFirstChild("ModuleAdapterWrapper")
                    if not adapterExists then
                        log("ModuleAdapterWrapper not found - recommend creating it for compatibility.", "WARNING")
                    else
                        log("ModuleAdapterWrapper found - can handle compatibility issues.", "INFO")
                    end
                end
            end
        end
    end
    
    return allModulesFound, modulesWithIssues, moduleCompatNotes
end

-- Generate report
local function generateReport(safeToRemove, modulesWithIssues, moduleCompatNotes)
    log("Generating migration report...", "INFO")
    
    local reportText = [[
# Shared Folder Migration Report
Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[

## Status

]]
    
    if safeToRemove then
        reportText = reportText .. "✅ It appears safe to remove the ReplicatedStorage\\shared folder.\n\n"
    else
        reportText = reportText .. "❌ Issues found that need to be addressed before removing ReplicatedStorage\\shared folder.\n\n"
        
        if modulesWithIssues and #modulesWithIssues > 0 then
            reportText = reportText .. "### Modules with Issues\n\n"
            for _, moduleName in ipairs(modulesWithIssues) do
                reportText = reportText .. "- " .. moduleName .. "\n"
            end
            reportText = reportText .. "\n"
        end
    end
    
    if moduleCompatNotes and #moduleCompatNotes > 0 then
        reportText = reportText .. "### Module Compatibility Notes\n\n"
        for _, note in ipairs(moduleCompatNotes) do
            reportText = reportText .. "- " .. note.name .. ": " .. note.note .. "\n"
        end
        reportText = reportText .. "\n"
    end
    
    -- Add information about ModuleAdapterWrapper
    local adapterExists = ReplicatedStorage.Shared:FindFirstChild("ModuleAdapterWrapper")
    if adapterExists then
        reportText = reportText .. "### Compatibility Support\n\n"
        reportText = reportText .. "The ModuleAdapterWrapper is available at `ReplicatedStorage.Shared.ModuleAdapterWrapper` "
        reportText = reportText .. "to help with any compatibility issues during the transition.\n\n"
        reportText = reportText .. "Example usage:\n```lua\n"
        reportText = reportText .. "local ModuleAdapterWrapper = require(ReplicatedStorage.Shared.ModuleAdapterWrapper)\n"
        reportText = reportText .. "local UIComponents = ModuleAdapterWrapper.requireCompatible(\"UIComponents\")\n```\n\n"
    end
    
    reportText = reportText .. [[
## Next Steps

1. Verify all scripts reference modules using `ReplicatedStorage.Shared` or `ReplicatedStorage.shared`
2. Run the verification script to confirm all modules function correctly
3. Remove the ReplicatedStorage\shared folder once verified
4. Update documentation to reference the new structure

## Backup Information

A backup of the original modules has been created at ServerStorage\]] .. CONFIG.BACKUP_FOLDER .. [[

]]
    
    -- Save report to ServerStorage
    local serverStorage = game:GetService("ServerStorage")
    local reportScript = Instance.new("StringValue")
    reportScript.Name = "SharedMigrationReport_" .. os.date("%Y%m%d")
    reportScript.Value = reportText
    reportScript.Parent = serverStorage
    
    log("Report generated and saved to ServerStorage", "SUCCESS")
    print("\n" .. reportText)
end

-- Main function
local function main()
    log("Starting shared folder migration process...", "INFO")
    
    -- Create backup
    local backupSuccess = createBackup()
    if not backupSuccess then
        log("Backup failed. Aborting migration.", "ERROR")
        return
    end
    
    -- Check for ModuleAdapterWrapper
    local adapterExists = ReplicatedStorage.Shared:FindFirstChild("ModuleAdapterWrapper")
    if not adapterExists then
        log("ModuleAdapterWrapper not found. This utility helps with compatibility during migration.", "WARNING")
        log("Consider creating it before proceeding.", "WARNING")
    else
        log("ModuleAdapterWrapper found. This will help with module compatibility.", "SUCCESS")
    end
    
    -- Check for SafeRequireShim
    local shimExists = ReplicatedStorage.Shared:FindFirstChild("SafeRequireShim")
    if not shimExists then
        log("SafeRequireShim not found. This utility helps with SafeRequire compatibility.", "WARNING")
        log("Consider creating it before proceeding.", "WARNING")
    else
        log("SafeRequireShim found. This will help with SafeRequire compatibility.", "SUCCESS")
    end
    
    -- Check if safe to remove
    local safeToRemove, modulesWithIssues, moduleCompatNotes = checkSafeToRemove()
    
    -- Generate report
    generateReport(safeToRemove, modulesWithIssues, moduleCompatNotes)
    
    if safeToRemove then
        log("All modules exist in the new location.", "SUCCESS")
        
        if moduleCompatNotes and #moduleCompatNotes > 0 then
            log("Some compatibility notes exist - review the report for details.", "WARNING")
            log("Using ModuleAdapterWrapper is recommended for smooth transition.", "INFO")
        else
            log("All checks passed. You can safely remove the ReplicatedStorage\\shared folder.", "SUCCESS")
        end
    else
        log("Issues found. Please address them before removing the folder.", "WARNING")
    end
end

-- Run the migration process
main()
