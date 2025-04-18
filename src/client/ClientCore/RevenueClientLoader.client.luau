-- RevenueClientLoader.client.luau
-- Registers the RevenueClient with the ClientRegistry
-- Placed in StarterPlayer/StarterPlayerScripts/ClientCore

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core")
local ClientCoreFolder = PlayerScripts:WaitForChild("ClientCore")

-- Get the ClientRegistry
local ClientRegistry = require(CoreFolder:WaitForChild("ClientRegistry"))

-- Get the RevenueClient
local RevenueClient = require(ClientCoreFolder:WaitForChild("RevenueClient"))

-- Register the RevenueClient with the ClientRegistry
RevenueClient.ClientRegistry = ClientRegistry
ClientRegistry.registerSystem("RevenueClient", RevenueClient)

-- Define dependencies for the RevenueClient
ClientRegistry.defineDependencies("RevenueClient", {"ClientEventBridge", "UIManager"})

print("[RevenueClientLoader] RevenueClient registered with ClientRegistry")