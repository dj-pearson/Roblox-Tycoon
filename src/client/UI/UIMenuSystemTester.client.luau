-- UIMenuSystemTester.client.luau
-- A testing script to demonstrate the UIMenuSystem
-- Created: May 3, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for player to load
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load the UI menu system
local UIMenuSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("UIMenuSystem"))

-- Function to test the menu system
local function testMenuSystem()
    -- Create the menu screen gui
    local menuGui = UIMenuSystem.CreateMenuUI()
    
    -- Print a message to confirm it's loaded
    print("UIMenuSystem has been loaded and initialized!")
    
    -- You can add additional testing here as needed
    -- For example, you could programmatically click buttons after a delay:
    
    task.wait(2)
    print("UIMenuSystem test complete - the menu should now be visible on screen")
end

-- Run the test
testMenuSystem()
