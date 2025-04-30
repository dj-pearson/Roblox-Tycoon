-- AdminAccessRestrictor.client.lua
-- Restricts access to admin features to authorized users only
-- Created: April 29, 2025

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Variables to store original functions for restoration in Studio
local originalFunctions = {}

-- Check if the current player is an admin
local function isAdmin()
	-- Check player attributes (most reliable method)
	if player:GetAttribute("IsAdmin") or player:GetAttribute("Admin") or player:GetAttribute("IsDeveloper") then
		return true
	end
	
	-- Check if in Studio (always allow in Studio)
	if RunService:IsStudio() then
		return true
	end
	
	-- Try to check GameSystem if available
	local success, result = pcall(function()
		local GameSystem = game.ReplicatedStorage:FindFirstChild("GameSystem")
		if GameSystem and typeof(GameSystem.isPlayerAdmin) == "function" then
			return GameSystem.isPlayerAdmin(player)
		end
		return false
	end)
	
	if success and result then
		return true
	end
	
	-- Try to find admin list in ReplicatedStorage
	pcall(function()
		local possiblePaths = {
			game.ReplicatedStorage:FindFirstChild("AdminUsers"),
			game.ReplicatedStorage:FindFirstChild("GameConfig")
		}
		
		for _, path in ipairs(possiblePaths) do
			if path and path:IsA("ModuleScript") then
				local success, data = pcall(function() return require(path) end)
				if success and type(data) == "table" then
					-- Check direct admin list
					if data.AdminUsers then
						for _, id in pairs(data.AdminUsers) do
							if id == player.UserId then
								return true
							end
						end
					end
					
					-- Check if player is in the list directly
					for _, id in pairs(data) do
						if id == player.UserId then
							return true
						end
					end
				end
			end
		end
	end)
	
	-- By default, not an admin
	return false
end

-- Function to remove admin UIs from PlayerGui
local function removeAdminUIs()
	if isAdmin() then
		print("[AdminAccessRestrictor] Player is an admin, admin UIs permitted")
		return
	end
	
	print("[AdminAccessRestrictor] Player is not an admin, removing admin UIs...")
	
	-- Remove AdminDashboard if it exists
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local adminDashboard = playerGui:FindFirstChild("AdminDashboard")
		if adminDashboard then
			print("[AdminAccessRestrictor] Removing AdminDashboard")
			adminDashboard:Destroy()
		end
	end
	
	-- Monitor for new admin UIs being added
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "AdminDashboard" and not isAdmin() then
			print("[AdminAccessRestrictor] Blocking unauthorized AdminDashboard")
			child:Destroy()
		end
	end)
end

-- Function to patch the AdminControlsUI module
local function patchAdminControlsUI()
	-- Find AdminControlsUI module
	local success, adminControlsUI = pcall(function()
		local possiblePaths = {
			player.PlayerScripts:FindFirstChild("UI"):FindFirstChild("AdminControlsUI"),
			player.PlayerScripts:FindFirstChild("UI"),
			player.PlayerScripts:FindFirstChild("src"):FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("AdminControlsUI"),
			player.PlayerScripts -- Check entire PlayerScripts in case we need to search
		}
		
		for _, path in ipairs(possiblePaths) do
			if path then
				if path.Name == "AdminControlsUI" then
					return require(path)
				else
					-- Search recursively in folder
					for _, child in pairs(path:GetDescendants()) do
						if child.Name == "AdminControlsUI" and child:IsA("ModuleScript") then
							return require(child)
						end
					end
				end
			end
		end
		return nil
	end)
	
	if not success or not adminControlsUI then
		print("[AdminAccessRestrictor] Could not find AdminControlsUI module")
		return
	end
	
	-- Store original functions before patching
	if RunService:IsStudio() then
		originalFunctions.initialize = adminControlsUI.initialize
		originalFunctions.ToggleAdminPanel = adminControlsUI.ToggleAdminPanel
	end
	
	-- Patch initialize function
	if typeof(adminControlsUI.initialize) == "function" then
		adminControlsUI.initialize = function(...)
			if not isAdmin() then
				print("[AdminAccessRestrictor] Non-admin attempted to initialize AdminControlsUI")
				return false
			end
			if originalFunctions.initialize then
				return originalFunctions.initialize(...)
			end
		end
	end
	
	-- Patch ToggleAdminPanel function
	if typeof(adminControlsUI.ToggleAdminPanel) == "function" then
		adminControlsUI.ToggleAdminPanel = function(...)
			if not isAdmin() then
				print("[AdminAccessRestrictor] Non-admin attempted to toggle admin panel")
				return false
			end
			if originalFunctions.ToggleAdminPanel then
				return originalFunctions.ToggleAdminPanel(...)
			end
		end
	end
	
	print("[AdminAccessRestrictor] AdminControlsUI successfully patched")
end

-- Listen for Keybinds that might open admin panel
local function blockAdminKeybinds()
	local UserInputService = game:GetService("UserInputService")
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not isAdmin() and not gameProcessed then
			-- Common admin panel keys
			if (input.KeyCode == Enum.KeyCode.F4) or 
			   (input.KeyCode == Enum.KeyCode.Semicolon) or
			   (input.KeyCode == Enum.KeyCode.F10) then
				print("[AdminAccessRestrictor] Blocked attempt to open admin panel via keybind")
				-- Consume the input by setting gameProcessed
				return true
			end
		end
	end)
end

-- Main function
local function initialize()
	print("[AdminAccessRestrictor] Initializing...")
	
	-- Remove existing admin UIs
	removeAdminUIs()
	
	-- Patch AdminControlsUI module
	patchAdminControlsUI()
	
	-- Block keybinds
	blockAdminKeybinds()
	
	-- Periodically check for admin UIs (in case they're added after we initialize)
	task.spawn(function()
		while task.wait(10) do
			removeAdminUIs()
		end
	end)
	
	print("[AdminAccessRestrictor] Initialization complete")
end

-- Run the initializer
initialize()
