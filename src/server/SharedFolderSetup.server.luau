--[[
    SharedFolderSetup.server.luau
    
    Creates the shared folder in ReplicatedStorage if it doesn't exist
    and moves the ModuleScriptAccessor there for global access.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Find or create shared folder
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[SharedFolderSetup] Created shared folder in ReplicatedStorage")
end

-- Look for ModuleScriptAccessor in src/shared
local srcShared = ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared")
if srcShared then
    local moduleAccessor = srcShared:FindFirstChild("ModuleScriptAccessor") or srcShared:FindFirstChild("ModuleScriptAccessor.luau")
    
    if moduleAccessor and not shared:FindFirstChild("ModuleScriptAccessor") then
        local clone = moduleAccessor:Clone()
        clone.Parent = shared
        print("[SharedFolderSetup] Moved ModuleScriptAccessor to ReplicatedStorage/shared")
    end
end

print("[SharedFolderSetup] Shared folder setup complete")
