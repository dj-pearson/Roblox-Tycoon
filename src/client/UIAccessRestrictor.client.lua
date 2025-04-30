-- UIAccessRestrictor.client.lua
-- Restricts development UI tools to admin users only
-- Created: April 29, 2025

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local inStudioMode = RunService:IsStudio()
local adminStatusCache = nil

-- Check if player is an admin
local function isPlayerAdmin()
	-- Return cached result if available
	if adminStatusCache ~= nil then
		return adminStatusCache
	end
	
	-- First check: Player attributes
	if player:GetAttribute("IsAdmin") or player:GetAttribute("Admin") then
		adminStatusCache = true
		return true
	end
	
	-- Second check: Studio mode
	if inStudioMode then
		adminStatusCache = true
		return true
	end
	
	-- Third check: Try to find admin users list
	local success, result = pcall(function()
		if ReplicatedStorage:FindFirstChild("AdminUsers") then
			local adminList = require(ReplicatedStorage.AdminUsers)
			if type(adminList) == "table" then
				for _, id in pairs(adminList) do
					if id == player.UserId then
						return true
					end
				end
			end
		end
		return false
	end)
	
	if success and result then
		adminStatusCache = true
		return true
	end
	
	-- Default to not admin
	adminStatusCache = false
	return false
end

-- Remove unauthorized UIs
local function removeDevUIs()
	if isPlayerAdmin() then
		print("[UIAccessRestrictor] Player is admin, keeping dev UIs")
		return
	end
	
	print("[UIAccessRestrictor] Removing dev UIs for non-admin player")
	
	-- Remove UI elements from PlayerGui
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local uiNames = {
			"EmergencyUIAccess",
			"AdminDashboard",
			"AdminPanel", 
			"DeveloperConsole",
			"WaitForChildFinder"
		}
		
		for _, name in ipairs(uiNames) do
			local ui = playerGui:FindFirstChild(name)
			if ui then
				ui:Destroy()
			end
		end
	end
	
	-- Disable emergency UI creation
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if playerScripts then
		local function patchScript(script)
			if script then
				script:SetAttribute("DisableEmergencyUI", true)
			end
		end
		
		patchScript(playerScripts:FindFirstChild("UISystemEnhancer"))
		patchScript(playerScripts:FindFirstChild("UISystemEnhancer_fixed"))
	end
end

-- Monitor for new UIs
local function setupMonitoring()
	local playerGui = player:WaitForChild("PlayerGui")
	
	playerGui.ChildAdded:Connect(function(child)
		if not isPlayerAdmin() and table.find({
			"EmergencyUIAccess", "AdminDashboard", "AdminPanel"
		}, child.Name) then
			task.delay(0.1, function()
				if child and child.Parent then
					child:Destroy()
				end
			end)
		end
	end)
end

-- Run initial cleanup
removeDevUIs()

-- Setup monitoring
setupMonitoring()

-- Periodically check for UIs
task.spawn(function()
	while task.wait(5) do
		removeDevUIs()
	end
end)

return {
	isAdmin = isPlayerAdmin,
	removeUIs = removeDevUIs
}
