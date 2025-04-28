-- FolderSetup.server.luau
-- Early-loading script to ensure all required folders exist
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Constants and configuration
local DEBUG = true

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[FolderSetup][%s] %s", level, message))
end

-- Ensure a folder exists, create it if it doesn't
local function ensureFolderExists(parent, name)
	if not parent:FindFirstChild(name) then
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
		log("Created folder: " .. parent.Name .. "/" .. name, "Warning")
		return folder, true
	end
	return parent:FindFirstChild(name), false
end

-- List of required folder structures
local requiredFolders = {
	-- ServerScriptService structure
	{
		parent = ServerScriptService,
		name = "Core",
		subfolders = {
			"CoreRegistry",
			"TutorialManager",
			"MigrationUtils",
			"SystemBootstrap"
		}
	},
	{
		parent = ServerScriptService,
		name = "Server",
		subfolders = {
			"Tests"
		}
	},
	{
		parent = ServerScriptService,
		name = "GymAutomation",
		subfolders = {}
	},
	
	-- ReplicatedStorage structure
	{
		parent = ReplicatedStorage,
		name = "shared",
		subfolders = {
			"SafeRequire",
			"ClientRegistry",
			"SoundSystemManager",
			"UIComponents"
		}
	},
	{
		parent = ReplicatedStorage,
		name = "src",
		subfolders = {
			"shared",
			"server",
			"client",
			"GameSystem"
		}
	},
	
	-- ServerStorage structure
	{
		parent = ServerStorage,
		name = "MemberSatisfactionSystem",
		subfolders = {}
	}
}

-- Create all required folders
log("Starting folder setup")

local foldersCreated = 0
local subfoldersCreated = 0

for _, folderInfo in ipairs(requiredFolders) do
	local folder, created = ensureFolderExists(folderInfo.parent, folderInfo.name)
	if created then
		foldersCreated = foldersCreated + 1
	end
	
	for _, subfolderName in ipairs(folderInfo.subfolders) do
		local _, subCreated = ensureFolderExists(folder, subfolderName)
		if subCreated then
			subfoldersCreated = subfoldersCreated + 1
		end
	end
end

-- Create src structure
local srcFolder = ReplicatedStorage:FindFirstChild("src")
if srcFolder then
	-- Create client folder structure
	local clientFolder = ensureFolderExists(srcFolder, "client")
	local clientCore = ensureFolderExists(clientFolder, "Core")
	ensureFolderExists(clientFolder, "UI")
	
	-- Create server folder structure
	local serverFolder = ensureFolderExists(srcFolder, "server")
	local serverCore = ensureFolderExists(serverFolder, "Core")
	ensureFolderExists(serverFolder, "GymAutomation")
	
	-- Create shared folder structure
	local sharedFolder = ensureFolderExists(srcFolder, "shared")
	ensureFolderExists(sharedFolder, "Utils")
end

log("Folder setup complete - Created " .. foldersCreated .. " folders and " .. subfoldersCreated .. " subfolders")

-- Return true to indicate successful setup
return true
