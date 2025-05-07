--luau
-- DataStore Plugin/SessionManager.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "SessionManager" 
-- without the .server extension
return require(script.Parent:FindFirstChild("SessionManager"))
