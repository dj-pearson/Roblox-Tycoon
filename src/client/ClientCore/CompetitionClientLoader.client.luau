-- CompetitionClientLoader.client.luau
-- Registers the CompetitionClient with the ClientRegistry
-- Place in StarterPlayer/StarterPlayerScripts/ClientCore

local Players = game:GetService("Players")
local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core")
local ClientCoreFolder = PlayerScripts:WaitForChild("ClientCore")

-- Get the ClientRegistry
local ClientRegistry = require(CoreFolder:FindFirstChild("ClientRegistry"))

-- Get the CompetitionClient
local CompetitionClient = require(ClientCoreFolder:FindFirstChild("CompetitionClient"))

-- Register the client with the registry
if ClientRegistry and CompetitionClient then
    ClientRegistry.registerSystem("CompetitionClient", CompetitionClient)
    print("CompetitionClient registered with ClientRegistry")
end