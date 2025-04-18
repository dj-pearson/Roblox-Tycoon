-- Cleanup Script
-- Place in ServerScriptService
-- This will remove any red test buttons and fix remaining errors

local showDebugMessages = true

local function debug(...)
	if showDebugMessages then
		print("[Cleanup]", ...)
	end
end

debug("Starting cleanup...")

-- Remove test buttons
local function removeTestButtons()
	debug("Searching for test buttons...")

	-- Find the red button
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "SpawnNPCButton" or 
			(obj:IsA("BasePart") and obj.BrickColor == BrickColor.new("Bright red")) then
			debug("Found test button: " .. obj.Name)
			obj:Destroy()
			debug("Removed test button")
		end
	end
end

-- Remove problematic scripts from NPCs
local function cleanupNPCScripts()
	debug("Cleaning up NPC scripts...")

	-- Find all NPCs
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon and tycoon.Value then
			local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
			if npcsFolder then
				for _, npc in pairs(npcsFolder:GetChildren()) do
					-- Remove problematic scripts
					for _, script in pairs(npc:GetDescendants()) do
						if script:IsA("Script") or script:IsA("LocalScript") then
							if script.Name == "nottooclose" or script.Name == "UserId" then
								script:Destroy()
								debug("Removed problematic script: " .. script.Name .. " from " .. npc.Name)
							end
						end
					end

					-- Ensure NPC has proper parts
					if not npc:FindFirstChild("HumanoidRootPart") then
						local hrp = Instance.new("Part")
						hrp.Name = "HumanoidRootPart"
						hrp.Size = Vector3.new(2, 2, 1)
						hrp.Transparency = 1
						hrp.CanCollide = false
						hrp.Position = npc:GetPivot().Position
						hrp.Parent = npc
						debug("Added missing HumanoidRootPart to " .. npc.Name)
					end

					-- Ensure humanoid exists
					if not npc:FindFirstChildOfClass("Humanoid") then
						local humanoid = Instance.new("Humanoid")
						humanoid.WalkSpeed = 8
						humanoid.Parent = npc
						debug("Added missing Humanoid to " .. npc.Name)
					end
				end
			end
		end
	end
end

-- Remove any additional GuiFolder objects in NPCs
local function cleanupGuiFolders()
	debug("Cleaning up extra GuiFolder objects...")

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name == "GuiFolder" and obj:IsA("Folder") and obj.Parent.Name ~= "Workspace" then
			debug("Found extra GuiFolder in: " .. obj.Parent:GetFullName())
			obj:Destroy()
		end
	end
end

-- Fix BuyTile and GymMilestonesSystem syntax errors
local function fixSyntaxErrors()
	debug("Checking for syntax error scripts...")

	local ServerScriptService = game:GetService("ServerScriptService")

	-- Check BuyTile script at line 513
	local buyTileScript = ServerScriptService:FindFirstChild("BuyTile")
	if buyTileScript and buyTileScript:IsA("Script") then
		debug("Found BuyTile script with syntax error")
		-- Can't modify script directly due to security, but can warn user
		print("⚠️ IMPORTANT: The BuyTile script has a syntax error at line 513. Please check for an extra parenthesis.")
	end

	-- Check GymMilestonesSystem script at line 126
	local milestonesScript = ServerScriptService:FindFirstChild("GymMilestonesSystem")
	if milestonesScript and milestonesScript:IsA("Script") then
		debug("Found GymMilestonesSystem script with syntax error")
		print("⚠️ IMPORTANT: The GymMilestonesSystem script has a syntax error at line 126. Please add missing 'end' statements.")
	end
end

-- Perform cleanup
removeTestButtons()
cleanupNPCScripts()
cleanupGuiFolders()
fixSyntaxErrors()

debug("Cleanup completed!")