--[[
    FolderSetup.server.luau
    
    Creates all necessary folders for the game to work properly.
    Runs early in the game lifecycle to ensure folder paths exist before any scripts try to access them.
    
    This helps prevent "Infinite yield possible on WaitForChild" errors.
    
    Created: April 25, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Debug logging
local function log(message)
    print("[FolderSetup] " .. message)
end

-- Create a folder if it doesn't exist
local function ensureFolderExists(parent, name)
    if not parent then
        warn("[FolderSetup] Cannot create folder '" .. name .. "' in nil parent")
        return nil
    end
    
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder: " .. name .. " in " .. parent:GetFullName())
    else
        log("Found existing folder: " .. name .. " in " .. parent:GetFullName())
    end
    
    return folder
end

-- Create hierarchy of folders from a path string like "a/b/c"
local function createFolderPath(parent, path)
    local pathParts = string.split(path, "/")
    local currentParent = parent
    
    for _, part in ipairs(pathParts) do
        currentParent = ensureFolderExists(currentParent, part)
    end
    
    return currentParent
end

-- Main folder setup function
local function setupFolders()
    log("Starting folder setup...")
    
    -- ReplicatedStorage structure
    local replicatedShared = ensureFolderExists(ReplicatedStorage, "shared")
    ensureFolderExists(ReplicatedStorage, "Events")
    ensureFolderExists(ReplicatedStorage, "src")
    
    -- Inside shared folder
    createFolderPath(replicatedShared, "UI")
    createFolderPath(replicatedShared, "Constants")
    createFolderPath(replicatedShared, "Utils")
    
    -- ServerScriptService structure
    ensureFolderExists(ServerScriptService, "Core")
    ensureFolderExists(ServerScriptService, "Data")
    ensureFolderExists(ServerScriptService, "Systems")
    ensureFolderExists(ServerScriptService, "Connectors")
    ensureFolderExists(ServerScriptService, "Essentials")
    ensureFolderExists(ServerScriptService, "Enhancements")
    
    -- Inside Core folder
    local core = ServerScriptService.Core
    ensureFolderExists(core, "ModelValidation")
    ensureFolderExists(core, "Systems")
    
    -- ServerStorage structure
    ensureFolderExists(ServerStorage, "Models")
    ensureFolderExists(ServerStorage, "BuyTiles")
    ensureFolderExists(ServerStorage, "EquipmentModels")
    ensureFolderExists(ServerStorage, "NPC_Models")
    
    log("Folder setup complete")
end

-- Run the setup
setupFolders()

return {
    ensureFolderExists = ensureFolderExists,
    createFolderPath = createFolderPath
}
