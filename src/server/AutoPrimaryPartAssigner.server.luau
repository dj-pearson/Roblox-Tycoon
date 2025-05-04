-- AutoPrimaryPartAssigner.server.luau
-- Server script to automatically run the primary part assignment at startup if specified
-- Created: May 4, 2025

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Only run in Studio edit mode when specifically enabled
local AUTO_ASSIGN_ON_STARTUP = false -- Set to true to automatically run on startup

-- Wait for the command module to load
local CommandsFolder = game:GetService("ServerScriptService"):WaitForChild("src"):WaitForChild("server"):WaitForChild("Commands")
local PrimaryPartCommand = require(CommandsFolder:WaitForChild("PrimaryPartAssignmentCommand"))

if RunService:IsStudio() and AUTO_ASSIGN_ON_STARTUP then
    -- Wait a bit to ensure everything is loaded
    task.wait(5)
    
    -- Run the command
    print("Auto-assigning primary parts...")
    local result = PrimaryPartCommand.AssignPrimaryParts("GymParts")
    print("Result: " .. result)
end

-- Create a configuration value that can be modified in Studio
local configValue = Instance.new("BoolValue")
configValue.Name = "AutoAssignPrimaryParts"
configValue.Value = AUTO_ASSIGN_ON_STARTUP
configValue.Parent = ReplicatedStorage

-- When the value changes, potentially run the assignment
configValue.Changed:Connect(function()
    if configValue.Value and RunService:IsStudio() then
        print("Running primary part assignment due to configuration change...")
        local result = PrimaryPartCommand.AssignPrimaryParts("GymParts")
        print("Result: " .. result)
        
        -- Reset the value after running
        configValue.Value = false
    end
end)
