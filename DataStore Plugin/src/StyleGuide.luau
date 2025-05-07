--luau
-- DataStore Plugin/StyleGuide.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "StyleGuide" 
-- without the .server extension
return require(script.Parent:FindFirstChild("StyleGuide"))
