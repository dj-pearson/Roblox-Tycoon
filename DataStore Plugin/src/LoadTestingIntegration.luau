--luau
-- DataStore Plugin/LoadTestingIntegration.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "LoadTestingIntegration" 
-- without the .server extension
return require(script.Parent:FindFirstChild("LoadTestingIntegration"))
