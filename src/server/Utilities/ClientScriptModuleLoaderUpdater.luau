--[[
    ClientScriptModuleLoaderUpdater.luau
    
    This script helps migrate client scripts to use the new ModuleLoader system.
    It updates scripts to use the ModuleLoaderHelper for loading modules.
    
    Created: May 3, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load ModuleLoaderHelper
local ModuleLoaderHelper = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoaderHelper"))

-- Get the ModuleLoader
local ModuleLoader = ModuleLoaderHelper.getModuleLoader()

-- Stats for tracking update progress
local stats = {
    scriptsUpdated = 0,
    scriptsSkipped = 0,
    errors = 0
}

-- Log function
local function log(message)
    print("[ClientScriptUpdater] " .. message)
end

-- Get all client scripts
local function getClientScripts()
    local scripts = {}
    
    -- Function to recursively find scripts
    local function findScripts(parent, collection)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                -- Skip system scripts and already processed scripts
                local skipMarkers = {"Updater", "ModuleLoader", "CoreRegistry"}
                local skip = false
                for _, marker in ipairs(skipMarkers) do
                    if child.Name:find(marker) then
                        skip = true
                        break
                    end
                end
                
                if not skip then
                    table.insert(collection, child)
                end
            end
            
            findScripts(child, collection)
        end
    end
    
    -- Check PlayerScripts for all players
    for _, player in ipairs(Players:GetPlayers()) do
        findScripts(player.PlayerScripts, scripts)
    end
    
    -- Check ReplicatedStorage
    if ReplicatedStorage:FindFirstChild("src") then
        findScripts(ReplicatedStorage.src, scripts)
    end
    
    return scripts
end

-- Check if a script already uses ModuleLoader
local function usesModuleLoader(script)
    local scriptSource = script.Source
    return scriptSource:find("ModuleLoader") ~= nil or scriptSource:find("ModuleLoaderHelper") ~= nil
end

-- Check if a script uses custom module loading
local function usesCustomLoading(script)
    local scriptSource = script.Source
    local patterns = {
        "safeRequire",
        "requireSafely",
        "loadModule",
        "findModule",
        "pcall%s*%(%s*function%s*%(%s*%)%s*return%s*require",
        "if%s+not%s+success"
    }
    
    for _, pattern in ipairs(patterns) do
        if scriptSource:find(pattern) then
            return true
        end
    end
    
    return false
end

-- Update script to use ModuleLoader
local function updateScript(script)
    if usesModuleLoader(script) then
        log("Script already uses ModuleLoader: " .. script:GetFullName())
        stats.scriptsSkipped = stats.scriptsSkipped + 1
        return false
    end
    
    if not usesCustomLoading(script) then
        log("Script doesn't use custom loading: " .. script:GetFullName())
        stats.scriptsSkipped = stats.scriptsSkipped + 1
        return false
    end
    
    log("Updating script: " .. script:GetFullName())
    
    -- Make a backup
    local backup = script:Clone()
    backup.Name = script.Name .. "_Backup_May3"
    backup.Parent = script.Parent
    
    -- Update the script
    local source = script.Source
    
    -- 1. Add ModuleLoaderHelper import
    if not source:find("ModuleLoaderHelper") then
        local importCode = [[
-- Load ModuleLoaderHelper for consistent module loading
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoaderHelper = nil

-- Try to load ModuleLoaderHelper
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    end
end
]]
        
        -- Find a good place to insert the code - after the service declarations
        local serviceImportEnd = source:find("%)%s*\n", source:find("GetService"))
        if serviceImportEnd then
            source = source:sub(1, serviceImportEnd) .. "\n" .. importCode .. source:sub(serviceImportEnd + 1)
        else
            -- Insert after the first block of comments
            local commentEnd = source:find("%]%]%s*\n")
            if commentEnd then
                source = source:sub(1, commentEnd + 2) .. "\n" .. importCode .. source:sub(commentEnd + 3)
            else
                -- Just add at the top
                source = importCode .. source
            end
        end
    end
    
    -- 2. Replace custom require implementations with ModuleLoaderHelper
    source = source:gsub("local%s+function%s+requireSafely%s*%(", "local function requireSafely_DEPRECATED(")
    source = source:gsub("local%s+function%s+safeRequire%s*%(", "local function safeRequire_DEPRECATED(")
    source = source:gsub("local%s+function%s+loadModule%s*%(", "local function loadModule_DEPRECATED(")
    source = source:gsub("local%s+function%s+findModule%s*%(", "local function findModule_DEPRECATED(")
    
    -- 3. Add fallback implementation for backward compatibility
    local fallbackCode = [[

-- Backward compatibility - use ModuleLoaderHelper when available
local function safeRequire(moduleOrName, fallback)
    if ModuleLoaderHelper then
        return ModuleLoaderHelper.safeRequire(moduleOrName, fallback)
    else
        return safeRequire_DEPRECATED(moduleOrName, fallback)
    end
end

local function loadModule(moduleName, searchPaths, fallback)
    if ModuleLoaderHelper then
        return ModuleLoaderHelper.loadModule(moduleName, fallback)
    else
        return loadModule_DEPRECATED(moduleName, searchPaths, fallback)
    end
end
]]
    
    -- Find an appropriate place to insert fallback code
    if source:find("_DEPRECATED") then
        local lastDeprecated = source:find("_DEPRECATED[^_]+end%s*\n")
        if lastDeprecated then
            source = source:sub(1, lastDeprecated) .. fallbackCode .. source:sub(lastDeprecated + 1)
        else
            -- Add after all functions
            source = source .. "\n" .. fallbackCode
        end
    end
    
    -- Update the script source
    script.Source = source
    
    log("Successfully updated script: " .. script:GetFullName())
    stats.scriptsUpdated = stats.scriptsUpdated + 1
    return true
end

-- Main update function
local function updateClientScripts()
    log("Beginning client script updates...")
    
    local scripts = getClientScripts()
    log("Found " .. #scripts .. " scripts to check")
    
    for i, script in ipairs(scripts) do
        local success, result = pcall(function()
            return updateScript(script)
        end)
        
        if not success then
            log("Error updating script " .. script:GetFullName() .. ": " .. tostring(result))
            stats.errors = stats.errors + 1
        end
        
        if i % 10 == 0 then
            log("Progress: " .. i .. "/" .. #scripts)
        end
    end
    
    log("Script update complete")
    log("Statistics:")
    log("- Scripts updated: " .. stats.scriptsUpdated)
    log("- Scripts skipped: " .. stats.scriptsSkipped)
    log("- Errors: " .. stats.errors)
end

return {
    updateClientScripts = updateClientScripts,
    updateScript = updateScript
}
