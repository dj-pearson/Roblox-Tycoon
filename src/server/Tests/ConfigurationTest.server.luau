--[[
	ConfigurationTest.server.luau
	A test script to demonstrate the TycoonConfigurationManager functionality.
	
	This script:
	- Creates a new configuration instance
	- Loads sample configuration data
	- Demonstrates how to get and set configuration values
	- Shows how to export and import configurations
]]

-- Only run in Studio
if not game:GetService("RunService"):IsStudio() then
	return
end

-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local TycoonConfigurationManager = require(script.Parent:WaitForChild("TycoonConfigurationManager"))
local FileSystem = nil
pcall(function()
	FileSystem = require(ReplicatedStorage:WaitForChild("FileSystem"))
end)

-- Initialize the configuration manager
TycoonConfigurationManager.init()
print("Configuration test script started")

-- Load the sample configuration data if FileSystem is available
local hasSampleConfig = false

if FileSystem then
	-- Read the sample configuration file
	local jsonString = FileSystem:ReadFile("src/server/Core/SampleGymConfig.json")
	if jsonString then
		-- Create a StringValue to hold the sample config
		local sampleConfig = ServerStorage:FindFirstChild("TycoonConfigurations"):FindFirstChild("SampleGymConfig")
		if not sampleConfig then
			sampleConfig = Instance.new("StringValue")
			sampleConfig.Name = "SampleGymConfig"
			sampleConfig.Parent = ServerStorage:FindFirstChild("TycoonConfigurations")
		end
		sampleConfig.Value = jsonString
		hasSampleConfig = true
		print("Loaded sample configuration data")
	else
		print("Sample configuration file not found")
	end
else
	print("FileSystem module not available, sample configuration cannot be loaded automatically")
end

-- Test the configuration manager
local function runConfigTest()
	-- Create a test configuration
	local configManager = TycoonConfigurationManager.new("TestConfig")
	print("Created test configuration manager")
	
	-- Set some values
	configManager:SetSetting("settings.economyMultiplier", 1.5)
	configManager:SetSetting("settings.maxFloors", 5)
	configManager:SetSetting("roomTypes", {
		{name = "Cardio", color = Color3.fromRGB(255, 200, 200)},
		{name = "Weights", color = Color3.fromRGB(200, 200, 255)},
		{name = "Specialized", color = Color3.fromRGB(200, 255, 200)},
		{name = "Premium", color = Color3.fromRGB(255, 220, 180)}
	})
	
	-- Save the configuration
	local success = configManager:SaveConfig()
	print("Configuration saved:", success)
	
	-- Read values back
	local economyMultiplier = configManager:GetSetting("settings.economyMultiplier")
	local maxFloors = configManager:GetSetting("settings.maxFloors")
	local roomTypes = configManager:GetSetting("roomTypes")
	
	print("Economy multiplier:", economyMultiplier)
	print("Max floors:", maxFloors)
	print("Room types count:", #roomTypes)
	
	-- Export to JSON string
	local jsonString = configManager:ExportConfig()
	print("Configuration exported to JSON:", jsonString ~= nil)
	
	-- Create a new manager and load the sample config if available
	if hasSampleConfig then
		local sampleManager = TycoonConfigurationManager.new("SampleGymConfig")
		print("Loaded sample configuration")
		
		-- Read some values from the sample config
		local sampleEconomy = sampleManager:GetSetting("settings.economyMultiplier")
		local sampleRooms = sampleManager:GetSetting("roomTypes")
		
		print("Sample economy multiplier:", sampleEconomy)
		print("Sample room types count:", #sampleRooms)
		
		-- Verify prerequisites loading
		local prerequisites = sampleManager:GetSetting("prerequisites.floor3")
		if prerequisites then
			print("Prerequisites for floor 3:", table.concat(prerequisites, ", "))
		end
	end
end

-- Delay to ensure everything is loaded properly
task.delay(1, function()
	print("Running configuration test...")
	runConfigTest()
end)

-- Register studio test command
if _G.TestConfiguration == nil then
	_G.TestConfiguration = runConfigTest
	print("Global function _G.TestConfiguration registered. Run this in the command bar to test the configuration system.")
end
