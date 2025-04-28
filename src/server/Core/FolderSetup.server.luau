--[[
    FolderSetup.server.luau
    
    This script ensures that all necessary folder structures exist early in the game lifecycle.
    It prevents "Infinite yield possible on WaitForChild" errors by creating required folders
    before other scripts try to access them.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Ensure a path exists
local function ensurePath(parent, pathArray)
    local current = parent
    for _, name in ipairs(pathArray) do
        local child = current:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = current
            print("FolderSetup: Created folder " .. name .. " in " .. current:GetFullName())
        end
        current = child
    end
    return current
end

print("FolderSetup: Starting essential folder structure creation")

-- Server-side critical paths
ensurePath(ServerScriptService, {"Core"})
ensurePath(ServerScriptService, {"Server", "Systems"})
ensurePath(ServerScriptService, {"Server", "Tests"})
ensurePath(ServerScriptService, {"Server", "GymAutomation"})
ensurePath(ServerScriptService, {"Server", "DataManagement"})
ensurePath(ServerScriptService, {"Server", "TycoonManagement"})
ensurePath(ServerScriptService, {"Server", "Events"})

-- Shared folders
ensurePath(ReplicatedStorage, {"shared"})
ensurePath(ReplicatedStorage, {"shared", "Systems"})
ensurePath(ReplicatedStorage, {"shared", "Utils"})
ensurePath(ReplicatedStorage, {"shared", "Types"})
ensurePath(ReplicatedStorage, {"shared", "Constants"})
ensurePath(ReplicatedStorage, {"UIModules"})
ensurePath(ReplicatedStorage, {"RemoteEvents"})
ensurePath(ReplicatedStorage, {"RemoteFunctions"})

-- Server storage paths
ensurePath(ServerStorage, {"MemberSatisfactionSystem"})
ensurePath(ServerStorage, {"Assets"})
ensurePath(ServerStorage, {"Data"})
ensurePath(ServerStorage, {"GymParts"})

-- Handle player-specific folder creation
local function setupPlayerFolders(player)
    -- Required during gameplay
    task.spawn(function()
        local folder = Instance.new("Folder")
        folder.Name = "Tycoon"
        folder.Parent = player
        
        -- Create essential tycoon subfolders
        ensurePath(folder, {"Data"})
        ensurePath(folder, {"Equipment"})
        ensurePath(folder, {"Staff"})
        ensurePath(folder, {"Customers"})
        ensurePath(folder, {"Stats"})
        
        print("FolderSetup: Created Tycoon folder structure for " .. player.Name)
    end)
    
    -- Setup PlayerScripts folders
    task.spawn(function()
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if playerScripts then
            ensurePath(playerScripts, {"Core"})
            ensurePath(playerScripts, {"Client"})
            ensurePath(playerScripts, {"Client", "Systems"})
            ensurePath(playerScripts, {"Client", "UI"})
            ensurePath(playerScripts, {"shared"})
        end
    end)
end

-- Set up folders for existing players
for _, player in pairs(Players:GetPlayers()) do
    setupPlayerFolders(player)
end

-- Set up folders for new players
Players.PlayerAdded:Connect(setupPlayerFolders)

print("✅ FolderSetup: Essential folder structure creation complete")
