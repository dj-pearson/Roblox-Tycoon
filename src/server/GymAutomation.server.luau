--[[
    GymAutomation.server.luau
    
    IMPORTANT: Put this script directly in ServerScriptService (not in any subfolder)
    
    Simple standalone automation script for Gym Tycoon.
    This script will automatically run when placed in ServerScriptService and will register
    global functions that can be called from the Command Bar.
    
    Created: April 20, 2025
]] -- Updated: July 29, 2024

-- Services
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

-- Only run in Studio
if not RunService:IsStudio() then
    return
end

print("\n✅ GYM TYCOON AUTOMATION LOADED")
print("Run _G.AutomateGym() in the Command Bar to automate the gym setup.")

--------------------------------
-- MODULES
--------------------------------

local EquipmentManager = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("EquipmentManager"))
local BoundingBoxManager = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("BoundingBoxManager"))
local FloorAttributeSetup = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("FloorAttributeSetup"))
local TileDataGenerator = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("TileDataGenerator"))
local BuyTileProgressionManager = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("BuyTileProgressionManager"))

--------------------------------
-- AUTOMATION FUNCTIONS
--------------------------------

-- Main automation function
local function automateGym(options)
    options = options or {}
    local showDebug = options.showDebug ~= false -- Default to true
    local override = options.override == true -- Default to false
    
    print("\n===== GYM TYCOON AUTOMATION =====")
    print("Starting automation process...")
    
    local gymModel = workspace:FindFirstChild("GymParts") or workspace:FindFirstChild("Gym") or workspace:FindFirstChild("Tycoon") or workspace:FindFirstChild("GymTycoon")

	if not gymModel then
		warn("Gym Tycoon Model not found in workspace. Please ensure your Gym Tycoon Model is named 'GymParts', 'Gym', 'Tycoon', or 'GymTycoon'.")
		return
	end

	EquipmentManager.SetupEquipment(gymModel, options)
	BoundingBoxManager.GenerateHitboxes(gymModel, options)
	FloorAttributeSetup.ProcessGymParts(gymModel, options)
	TileDataGenerator.GenerateTileData(gymModel, options)
	BuyTileProgressionManager.GenerateBuildOrder(gymModel, options)

	print("\n===== GYM TYCOON AUTOMATION COMPLETE =====")
	print("✓ Automated gym setup, generated hitboxes, set up attributes, and configured buy tile progression.")
end

-- Register global functions
_G.AutomateGym = function(options) automateGym(options) end
_G.GenerateHitboxes = function(options) BoundingBoxManager.GenerateHitboxes(workspace, options) end
_G.SetupAttributes = function(options) EquipmentManager.SetupEquipment(workspace, options) end

-- Additional convenience functions
_G.ShowHitboxes = function()
    for _, hitbox in ipairs(workspace:GetDescendants()) do
        if hitbox.Name == "Hitbox" and hitbox:IsA("BasePart") then
            hitbox.Transparency = 0.8
        end
    end
end

_G.HideHitboxes = function()
    for _, hitbox in ipairs(workspace:GetDescendants()) do
        if hitbox.Name == "Hitbox" and hitbox:IsA("BasePart") then
            hitbox.Transparency = 1
        end
    end
end

print("You can use these commands: _G.AutomateGym(), _G.GenerateHitboxes(), _G.SetupAttributes(), _G.ShowHitboxes(), _G.HideHitboxes()")