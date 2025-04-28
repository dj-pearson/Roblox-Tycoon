-- GymAutomationLoader.server.luau
-- Script to load the GymAutomation module and make it available
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local MAX_RETRIES = 3
local RETRY_DELAY = 5 -- seconds
local DEBUG = true

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[GymAutomationLoader][%s] %s", level, message))
end

-- Define possible search paths for the GymAutomation modules
local searchPaths = {
	ServerScriptService:WaitForChild("GymAutomation", 1),
	ServerScriptService:FindFirstChild("Core"):FindFirstChild("GymAutomation"),
	ServerScriptService:FindFirstChild("Modules"):FindFirstChild("GymAutomation"),
	ServerStorage:FindFirstChild("GymAutomation"),
	ServerStorage:FindFirstChild("Modules"):FindFirstChild("GymAutomation"),
	ServerScriptService:FindFirstChild("Systems"):FindFirstChild("GymAutomation"),
	ServerScriptService:FindFirstChild("server"):FindFirstChild("GymAutomation")
}

-- Add the new path we just created
local serverFolder = ServerScriptService:FindFirstChild("server")
if not serverFolder then
	serverFolder = Instance.new("Folder")
	serverFolder.Name = "server"
	serverFolder.Parent = ServerScriptService
	log("Created server folder in ServerScriptService", "Warning")
end

local gymAutomationFolder = serverFolder:FindFirstChild("GymAutomation")
if not gymAutomationFolder then
	gymAutomationFolder = Instance.new("Folder")
	gymAutomationFolder.Name = "GymAutomation"
	gymAutomationFolder.Parent = serverFolder
	log("Created GymAutomation folder in server", "Warning")
end

table.insert(searchPaths, gymAutomationFolder)

-- Try to find the GymAutomation module in the search paths
local function findGymAutomationModule()
	for _, path in ipairs(searchPaths) do
		if path then
			-- Look for GymAutomationManager first
			local manager = path:FindFirstChild("GymAutomationManager")
			if manager and manager:IsA("ModuleScript") then
				log("Found GymAutomationManager in " .. path:GetFullName())
				return manager
			end
			
			-- Look for GymAutomation as a fallback
			local module = path:FindFirstChild("GymAutomation")
			if module and module:IsA("ModuleScript") then
				log("Found GymAutomation in " .. path:GetFullName())
				return module
			end
		end
	end
	
	log("Could not find GymAutomationManager in any search path", "Error")
	log("Could not find GymAutomation in any search path", "Error")
	return nil
end

-- Load the GymAutomation module
local function loadGymAutomation()
	local moduleScript = findGymAutomationModule()
	if not moduleScript then
		log("Failed to find any GymAutomation module", "Error")
		return nil
	end
	
	local success, module = pcall(function()
		return require(moduleScript)
	end)
	
	if success and module then
		log("Successfully loaded GymAutomation module")
		return module
	else
		log("Failed to load GymAutomation module: " .. tostring(module), "Error")
		return nil
	end
end

-- Try to load the module with retries
local function tryLoadWithRetries()
	local retries = 0
	local gymAutomation = nil
	
	while retries < MAX_RETRIES and not gymAutomation do
		gymAutomation = loadGymAutomation()
		
		if not gymAutomation then
			retries = retries + 1
			if retries < MAX_RETRIES then
				log("Failed to load GymAutomation, retrying in " .. RETRY_DELAY .. " seconds... (" .. retries .. "/" .. MAX_RETRIES .. ")", "Warning")
				wait(RETRY_DELAY)
			end
		end
	end
	
	if gymAutomation then
		-- Make GymAutomation available globally
		_G.GymAutomation = gymAutomation
		
		-- Also expose it in ReplicatedStorage for easy access
		local valueObject = Instance.new("ObjectValue")
		valueObject.Name = "GymAutomationReference"
		valueObject.Value = moduleScript
		valueObject.Parent = ReplicatedStorage
		
		log("✅ GYM TYCOON AUTOMATION LOADED")
		return gymAutomation
	else
		log("Failed to load GymAutomation after " .. MAX_RETRIES .. " attempts", "Error")
		
		-- Schedule a retry in the background
		spawn(function()
			log("Failed to load GymAutomation, scheduling retry...", "Warning")
			wait(RETRY_DELAY * 2)
			tryLoadWithRetries()
		end)
		
		return nil
	end
end

-- Kick off the loading process
local gymAutomation = tryLoadWithRetries()

-- Return the loaded module (might be nil if loading failed)
return gymAutomation
