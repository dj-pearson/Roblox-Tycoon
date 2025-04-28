--[[
    FolderSetup.server.luau
    
    This script runs first to ensure all required folder structures exist in the game.
    It prevents "Infinite yield possible on WaitForChild" errors by creating folders
    that other scripts expect to find.
    
    This script has the highest RunContext.Priority to ensure it runs before other scripts.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    debug = true,
    folders = {
        -- ReplicatedStorage folders
        {parent = ReplicatedStorage, name = "shared"},
        {parent = ReplicatedStorage, name = "src"},
        {parent = ReplicatedStorage, name = "EventBridge"},
        {parent = ReplicatedStorage, name = "CoreRegistryRemotes"},
        {parent = ReplicatedStorage, name = "AccruedDues"},
        
        -- ServerScriptService folders
        {parent = ServerScriptService, name = "Core"},
        {parent = ServerScriptService, name = "Server"},
        {parent = ServerScriptService, name = "GymAutomation"},
        {parent = ServerScriptService, name = "Tests"},
        
        -- ServerStorage folders
        {parent = ServerStorage, name = "GymParts"},
        {parent = ServerStorage, name = "BuyTiles"},
        {parent = ServerStorage, name = "Modules"}
    },
    
    -- Specific nested folder paths
    nestedPaths = {
        "ReplicatedStorage.shared.Data",
        "ReplicatedStorage.src.shared",
        "ServerScriptService.Core.Registry",
        "ServerStorage.Modules.Data"
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[FolderSetup]", ...)
    end
end

-- Create a folder if it doesn't exist
local function ensureFolder(parent, name)
    if not parent then
        log("Parent is nil for folder:", name)
        return nil
    end
    
    local folder = parent:FindFirstChild(name)
    
    if folder and not folder:IsA("Folder") then
        log("Found", name, "but it's not a Folder, it's a", folder.ClassName, "- recreating it")
        folder:Destroy()
        folder = nil
    end
    
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder:", name, "in", parent:GetFullName())
    end
    
    return folder
end

-- Create a nested folder path
local function createPath(pathString)
    local parts = pathString:split(".")
    local current = game
    
    for i, part in ipairs(parts) do
        current = ensureFolder(current, part)
        if not current then
            log("Failed to create path at part", i, ":", part, "in", pathString)
            return nil
        end
    end
    
    log("Created full path:", pathString)
    return current
end

-- Create initial folder structure
log("Setting up required folder structure...")

-- Create main folders
for _, folderInfo in ipairs(CONFIG.folders) do
    ensureFolder(folderInfo.parent, folderInfo.name)
end

-- Create nested paths
for _, path in ipairs(CONFIG.nestedPaths) do
    createPath(path)
end

-- Listen for player added events to ensure Tycoon folder structure
Players.PlayerAdded:Connect(function(player)
    -- Wait a moment for the player to fully load
    task.delay(0.5, function()
        -- Ensure player has basic folders needed
        ensureFolder(player, "Tycoon")
        
        -- Delayed check for more player structures (after other scripts might have created values)
        task.delay(2, function()
            -- Get existing Tycoon value or folder
            local tycoon = player:FindFirstChild("Tycoon")
            
            -- If Tycoon exists but isn't a folder or ObjectValue, something's wrong
            if tycoon and not (tycoon:IsA("Folder") or tycoon:IsA("ObjectValue")) then
                log("Tycoon for", player.Name, "is not a Folder or ObjectValue, it's a", tycoon.ClassName)
                -- Don't destroy it, let the TycoonFolderFixer handle it
            end
        end)
    end)
end)

log("Folder setup complete")

-- Return a simple API that other scripts can use
return {
    ensureFolder = ensureFolder,
    createPath = createPath
}
