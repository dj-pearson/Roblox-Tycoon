--[[
    ClientRegistryFixer.client.luau
    This script ensures ClientRegistry is properly accessible to all client scripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the actual ClientRegistry module
local clientCore = script.Parent:FindFirstChild("Core")
local clientRegistry = clientCore and clientCore:FindFirstChild("ClientRegistry")

-- Create a reference in ReplicatedStorage for easy access
if clientRegistry then
    print("ClientRegistryFixer: Found ClientRegistry, creating global reference")
    
    -- Create references folder if it doesn't exist
    local clientReferences = ReplicatedStorage:FindFirstChild("ClientReferences") 
        or Instance.new("Folder", ReplicatedStorage)
    clientReferences.Name = "ClientReferences"
    
    -- Create a ModuleScript reference
    local reference = Instance.new("ModuleScript")
    reference.Name = "ClientRegistryReference"
    reference.Source = 'return require(game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("Core"):WaitForChild("ClientRegistry"))'
    reference.Parent = clientReferences
    
    print("ClientRegistryFixer: Global reference created successfully")
else
    warn("ClientRegistryFixer: Could not find ClientRegistry module!")
end
