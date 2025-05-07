--!strict
-- TestPlugin.server.luau
-- This script helps test the DataStore Manager Pro plugin

local ServerScriptService = game:GetService("ServerScriptService")
local PluginDebugService = game:GetService("PluginDebugService")

-- Log that the test script is running
print("TestPlugin script is running!")

-- Attempt to access the plugin module
local DataStoreManagerPro = PluginDebugService:FindFirstChild("DataStoreManagerPro")
if not DataStoreManagerPro then
	warn("DataStore Manager Pro plugin not found in PluginDebugService!")
	return
end

print("Found DataStore Manager Pro plugin!")

-- Try to require the plugin module
local success, result = pcall(function()
	return require(DataStoreManagerPro)
end)

if not success then
	warn("Failed to require DataStoreManagerPro module:", result)
	return
end

print("Successfully required DataStoreManagerPro module!")
print("Plugin version:", result.Version or "Unknown")

-- You can add more test code here to interact with your plugin

-- Keep the script alive to maintain any connections
while task.wait(5) do
	print("Test script is still running...")
end
