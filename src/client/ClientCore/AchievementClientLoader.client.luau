-- AchievementClientLoader.client.luau
-- Registers the AchievementClient with the ClientRegistry
-- Place in StarterPlayer/StarterPlayerScripts/ClientCore

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local CoreFolder = PlayerScripts:WaitForChild("Core")
local ClientCoreFolder = PlayerScripts:WaitForChild("ClientCore")

-- Get the ClientRegistry
local ClientRegistry = require(CoreFolder:WaitForChild("ClientRegistry"))

-- Get the AchievementClient
local AchievementClient = require(ClientCoreFolder:WaitForChild("AchievementClient"))

-- Register the AchievementClient with the ClientRegistry
ClientRegistry.registerSystem("AchievementClient", AchievementClient)

-- Define dependencies for the AchievementClient
ClientRegistry.defineDependencies("AchievementClient", {"ClientEventBridge", "UIManager", "NotificationSystem"})

print("[AchievementClientLoader] AchievementClient registered with ClientRegistry")