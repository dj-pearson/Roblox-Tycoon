--[[
    FolderSetup.server.luau
    
    Creates essential folders to prevent "Infinite yield possible on WaitForChild" errors.
    Runs early in game lifecycle to ensure proper folder hierarchy.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        print("🛠️ [FolderSetup] Created folder: " .. name .. " in " .. parent.Name)
    end
    return folder
end

-- Server-side folders
local serverCore = ensureFolder(ServerScriptService, "Core")
local serverSystems = ensureFolder(ServerScriptService, "Systems")
local serverTests = ensureFolder(ServerScriptService, "Tests")

-- ServerStorage folders
local gymStructure = ensureFolder(ServerStorage, "GymStructure")
local buyTiles = ensureFolder(ServerStorage, "BuyTiles")
local gymParts = ensureFolder(ServerStorage, "GymParts")

-- Replicated folders
local shared = ensureFolder(ReplicatedStorage, "shared")
local remoteEvents = ensureFolder(ReplicatedStorage, "RemoteEvents")
local remoteFunctions = ensureFolder(ReplicatedStorage, "RemoteFunctions")

print("[FolderSetup] Folder structure initialization complete")
print("[FolderSetup] Created or verified " .. serverCore:GetFullName())
print("[FolderSetup] Created or verified " .. gymStructure:GetFullName())
print("[FolderSetup] Created or verified " .. shared:GetFullName())

-- Return success
return true
