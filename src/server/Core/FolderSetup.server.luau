--[[
    FolderSetup.server.luau
    
    Creates essential folders early in the game lifecycle to prevent "Infinite yield possible 
    on WaitForChild" errors. This script is designed to run before other scripts that 
    depend on these folders.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuration
local FOLDERS_TO_CREATE = {
    -- ReplicatedStorage folders
    {parent = ReplicatedStorage, name = "shared", className = "Folder"},
    {parent = ReplicatedStorage, name = "Events", className = "Folder"},
    {parent = ReplicatedStorage, name = "src", className = "Folder"},
    {parent = ReplicatedStorage, name = "GameSystem", className = "Folder"},
    
    -- ServerScriptService folders
    {parent = ServerScriptService, name = "Core", className = "Folder"},
    {parent = ServerScriptService, name = "Server", className = "Folder"},
    {parent = ServerScriptService, name = "Tests", className = "Folder"},
    
    -- Create folders within created folders
    {parent = "ReplicatedStorage.shared", name = "ClientRegistry", className = "ModuleScript"},
}

-- Create Events
local EVENTS_TO_CREATE = {
    {name = "PlaySoundEvent", className = "RemoteEvent", parent = ReplicatedStorage}
}

-- Debug flag
local DEBUG_MODE = true

-- Logging function
local function log(message)
    if DEBUG_MODE then
        print("[FolderSetup] " .. message)
    end
end

-- Get a parent instance from a path string (e.g. "ReplicatedStorage.shared")
local function getParentFromPath(path)
    -- Check if it's a direct reference
    if typeof(path) ~= "string" then
        return path
    end
    
    -- Split path into segments
    local segments = string.split(path, ".")
    
    -- Get the base service or object
    local current
    local firstSegment = segments[1]
    
    if firstSegment == "game" then
        current = game
    else
        -- Try to get service
        local success, service = pcall(function()
            return game:GetService(firstSegment)
        end)
        
        if success then
            current = service
        else
            log("Invalid service name: " .. firstSegment)
            return nil
        end
    end
    
    -- Navigate through segments
    for i = 2, #segments do
        current = current:FindFirstChild(segments[i])
        if not current then
            log("Path segment not found: " .. segments[i] .. " in " .. table.concat(segments, ".", 1, i-1))
            return nil
        end
    end
    
    return current
end

-- Create a folder (or other instance) if it doesn't exist
local function createIfMissing(parent, name, className)
    -- Resolve the parent if it's a path
    local resolvedParent = getParentFromPath(parent)
    if not resolvedParent then
        log("Parent not found for: " .. name)
        return nil
    end
    
    -- Check if the instance already exists
    local instance = resolvedParent:FindFirstChild(name)
    if instance then
        log("Instance already exists: " .. name .. " in " .. resolvedParent:GetFullName())
        return instance
    end
    
    -- Create the instance
    instance = Instance.new(className)
    instance.Name = name
    instance.Parent = resolvedParent
    
    log("Created " .. className .. ": " .. name .. " in " .. resolvedParent:GetFullName())
    return instance
end

-- Setup empty ModuleScript with basic structure
local function setupEmptyModuleScript(moduleScript)
    -- Only set up if it's empty or newly created
    if moduleScript and moduleScript:IsA("ModuleScript") and 
       (moduleScript.Source == "" or moduleScript.Source == "return {}") then
        moduleScript.Source = [[
-- Module created by FolderSetup
local module = {}

function module:initialize()
    print("[]] .. moduleScript.Name .. [[] Initialized")
    return true
end

return module
]]
        log("Set up basic structure for ModuleScript: " .. moduleScript.Name)
    end
end

-- Create all the folders defined in the configuration
local function createFolders()
    log("Creating essential folders...")
    
    for _, folderInfo in ipairs(FOLDERS_TO_CREATE) do
        local instance = createIfMissing(folderInfo.parent, folderInfo.name, folderInfo.className)
        
        -- Set up ModuleScripts
        if folderInfo.className == "ModuleScript" then
            setupEmptyModuleScript(instance)
        end
    end
    
    log("Essential folders created")
end

-- Create all the events defined in the configuration
local function createEvents()
    log("Creating essential events...")
    
    for _, eventInfo in ipairs(EVENTS_TO_CREATE) do
        createIfMissing(eventInfo.parent, eventInfo.name, eventInfo.className)
    end
    
    log("Essential events created")
end

-- Create player folders when players join
local function setupPlayerFolders(player)
    -- Create Core folder in PlayerScripts
    local playerScripts = player:FindFirstChild("PlayerScripts")
    if playerScripts then
        createIfMissing(playerScripts, "Core", "Folder")
        createIfMissing(playerScripts, "Client", "Folder")
        
        -- Create subfolders
        local client = playerScripts:FindFirstChild("Client")
        if client then
            createIfMissing(client, "Core", "Folder")
            createIfMissing(client, "Modules", "Folder")
        end
    end
end

-- Initialize the setup
local function initialize()
    log("Initializing folder setup...")
    
    -- Create basic folders
    createFolders()
    
    -- Create events
    createEvents()
    
    -- Listen for players joining to set up player folders
    Players.PlayerAdded:Connect(setupPlayerFolders)
    
    -- Set up folders for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayerFolders(player)
    end
    
    log("Folder setup complete")
end

-- Run the initializer
initialize()

-- Return the module API
return {
    createIfMissing = createIfMissing,
    initialize = initialize
}
