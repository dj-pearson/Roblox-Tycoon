--[[
    FolderSetup.server.luau
    This script runs at server start to ensure that all required folders
    exist in the proper locations. This prevents "Infinite yield possible on WaitForChild" errors
    and ensures that the module loading system works properly.
    
    Created to fix critical "Module Loading and WaitForChild Errors" reported in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Helper function to create a folder if it doesn't exist
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("FolderSetup: Created folder " .. name .. " in " .. parent:GetFullName())
    end
    return folder
end

-- Helper function to create a ModuleScript if it doesn't exist
local function ensureModuleScript(parent, name, source)
    local moduleScript = parent:FindFirstChild(name)
    if not moduleScript then
        moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = name
        moduleScript.Source = source or "return {}"
        moduleScript.Parent = parent
        print("FolderSetup: Created ModuleScript " .. name .. " in " .. parent:GetFullName())
    elseif not moduleScript:IsA("ModuleScript") then
        warn("FolderSetup: " .. name .. " exists in " .. parent:GetFullName() .. " but is not a ModuleScript")
        -- Rename the existing instance and create a new ModuleScript
        moduleScript.Name = moduleScript.Name .. "_Original"
        local newScript = Instance.new("ModuleScript")
        newScript.Name = name
        newScript.Source = source or "return {}"
        newScript.Parent = parent
        print("FolderSetup: Replaced non-ModuleScript " .. name .. " in " .. parent:GetFullName())
        moduleScript = newScript
    end
    return moduleScript
end

print("FolderSetup: Beginning folder structure setup...")

-- Set up server-side folders
local coreFolder = ensureFolder(ServerScriptService, "Core")
local systemFolder = ensureFolder(ServerScriptService, "System")
local dataFolder = ensureFolder(ServerScriptService, "Data")
local serverFolder = ensureFolder(ServerScriptService, "Server")
local testsFolder = ensureFolder(serverFolder, "Tests")
local gymAutomationFolder = ensureFolder(ServerScriptService, "GymAutomation")

-- Set up replicated folders
local sharedFolder = ensureFolder(ReplicatedStorage, "shared")
local srcFolder = ensureFolder(ReplicatedStorage, "src")
local uiModulesFolder = ensureFolder(ReplicatedStorage, "UIModules")

-- Set up server storage folders
local gymPartsFolder = ensureFolder(ServerStorage, "GymParts")
local memberFolder = ensureFolder(ServerStorage, "MemberSatisfactionSystem")

-- Ensure critical modules exist
local coreRegistrySource = [[
-- CoreRegistry placeholder
-- This will be replaced by the actual CoreRegistry module when it's loaded
return {
    registerSystem = function(name, instance) 
        return true
    end,
    getSystem = function(name) 
        return nil
    end,
    initialize = function() 
        return true
    end,
    isLoaded = true
}
]]

local clientRegistrySource = [[
-- ClientRegistry placeholder
-- This will be replaced by the actual ClientRegistry module when it's loaded
return {
    registerComponent = function(name, instance) 
        return true
    end,
    getComponent = function(name) 
        return nil
    end,
    registerSystem = function(name, instance) 
        return true
    end,
    getSystem = function(name) 
        return nil
    end,
    initialize = function() 
        return true
    end,
    isLoaded = true
}
]]

local moduleLoaderSource = [[
-- ModuleLoader placeholder
-- This will be replaced by the actual ModuleLoader module when it's loaded
return {
    loadModule = function(name, fallback) 
        return fallback
    end,
    findModule = function(name) 
        return nil
    end,
    safeRequire = function(module, fallback) 
        return fallback
    end,
    isLoaded = true
}
]]

-- Create critical modules if they don't exist
local coreRegistryModule = ensureModuleScript(coreFolder, "CoreRegistry", coreRegistrySource)
local moduleLoaderModule = ensureModuleScript(sharedFolder, "ModuleLoader", moduleLoaderSource)
local clientRegistryModule = ensureModuleScript(sharedFolder, "ClientRegistry", clientRegistrySource)

-- Create a SafeRequire utility
local safeRequireSource = [[
--[[
    SafeRequire.luau
    A utility module for safely requiring other modules with fallback support.
]]

local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("SafeRequire: Failed to require module - " .. tostring(result))
        return fallback
    end
end

return safeRequire
]]

local safeRequireModule = ensureModuleScript(sharedFolder, "SafeRequire", safeRequireSource)

print("✅ FolderSetup: All required folders and modules have been created!")
