-- Simplified Milestone System
-- Place in ServerScriptService
-- Handles gym achievements, rewards, and progress tracking

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
	-- Achievement display
	notificationDuration = 5,  -- Duration to show achievement notifications (seconds)
	achievementSoundId = "rbxassetid://9125601193",  -- Sound for achievement unlocks

	-- Debug
	debug = true  -- Enable debug messages
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[Milestones]", ...)
	end
end

-- Module table
local MilestoneSystem = {}

-- Define all milestones
local gymMilestones = {
	{
		id = "first_tile",
		name = "First Steps",
		description = "Purchase your first equipment",
		condition = function(player)
			local tycoon = player:FindFirstChild("Tycoon")
			return tycoon and tycoon:GetAttribute("EquipmentCount") and 
				tycoon:GetAttribute("EquipmentCount") >= 1
		end,
		reward = {
			cash = 100
		},
		applyReward = function(player)
			-- Give cash
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Cash") then
				leaderstats.Cash.Value = leaderstats.Cash.Value + 100
			end

			-- Show notification instead of creating physical banner
			local message = Instance.new("Message")
			message.Text = "ACHIEVEMENT: First Steps\nYou've started your gym journey! +$100"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, CONFIG.notificationDuration)
		end
	},
	{
		id = "level_3",
		name = "Growing Business",
		description = "Reach Gym Level 3",
		condition = function(player)
			local tycoon = player:FindFirstChild("Tycoon")
			return tycoon and tycoon:GetAttribute("GymTier") and 
				tycoon:GetAttribute("GymTier") >= 3
		end,
		reward = {
			cash = 500
		},
		applyReward = function(player)
			-- Give cash
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Cash") then
				leaderstats.Cash.Value = leaderstats.Cash.Value + 500
			end

			-- Show notification instead of creating physical trophy
			local message = Instance.new("Message")
			message.Text = "ACHIEVEMENT: Growing Business\nYour gym has reached Level 3! +$500"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, CONFIG.notificationDuration)
		end
	},
	{
		id = "first_npc",
		name = "First Member",
		description = "Have your first gym member join",
		condition = function(player)
			local tycoon = player:FindFirstChild("Tycoon")
			if not tycoon or not tycoon.Value then return false end

			local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
			return npcsFolder and #npcsFolder:GetChildren() >= 1
		end,
		reward = {
			cash = 200
		},
		applyReward = function(player)
			-- Give cash
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Cash") then
				leaderstats.Cash.Value = leaderstats.Cash.Value + 200
			end

			-- Show notification instead of creating physical certificate
			local message = Instance.new("Message")
			message.Text = "ACHIEVEMENT: First Member\nYou've attracted your first gym member! +$200"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, CONFIG.notificationDuration)
		end
	},
	{
		id = "ten_equipment",
		name = "Serious Business",
		description = "Purchase 10 pieces of equipment",
		condition = function(player)
			local tycoon = player:FindFirstChild("Tycoon")
			return tycoon and tycoon:GetAttribute("EquipmentCount") and 
				tycoon:GetAttribute("EquipmentCount") >= 10
		end,
		reward = {
			cash = 1000
		},
		applyReward = function(player)
			-- Give cash
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Cash") then
				leaderstats.Cash.Value = leaderstats.Cash.Value + 1000
			end

			-- Show notification instead of creating physical award plaque
			local message = Instance.new("Message")
			message.Text = "ACHIEVEMENT: Serious Business\nYour gym now has 10+ pieces of equipment! +$1000"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, CONFIG.notificationDuration)
		end
	}
}

-- Function to check if a player has earned a milestone
function MilestoneSystem.checkPlayerMilestones(player)
	if not player then return end

	debugPrint("Checking milestones for " .. player.Name)

	for _, milestone in ipairs(gymMilestones) do
		-- Get milestone attribute name
		local milestoneAttr = "Milestone_" .. milestone.id

		-- Check if milestone already completed
		local isComplete = player:GetAttribute(milestoneAttr) == true

		-- If not complete, check condition
		if not isComplete then
			-- Check if the condition is now met
			local success, result = pcall(function()
				return milestone.condition(player)
			end)

			if success and result == true then
				debugPrint(player.Name .. " achieved milestone: " .. milestone.name)

				-- Mark milestone as complete
				player:SetAttribute(milestoneAttr, true)

				-- Apply the reward
				pcall(function()
					milestone.applyReward(player)
				end)

				-- Play achievement sound
				if player.Character then
					local sound = Instance.new("Sound")
					sound.SoundId = CONFIG.achievementSoundId
					sound.Volume = 1
					sound.Parent = player.Character
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 3)
				end

				-- Fire event for other systems
				local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
				if eventBridge then
					local milestoneEvent = eventBridge:FindFirstChild("MilestoneReached")
					if milestoneEvent then
						milestoneEvent:Fire(player, milestone.id, milestone.name)
					end
				end
			end
		end
	end
end

-- Function to initialize milestones for a player
function MilestoneSystem.initializePlayer(player)
	if not player then return end

	debugPrint("Initializing milestones for " .. player.Name)

	-- Check all milestones for this player (they might have already met some conditions)
	MilestoneSystem.checkPlayerMilestones(player)

	-- Set up connections to track player's progress
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		-- Check milestones whenever relevant attributes change
		tycoon.AttributeChanged:Connect(function(attrName)
			if attrName == "EquipmentCount" or attrName == "GymTier" then
				MilestoneSystem.checkPlayerMilestones(player)
			end
		end)
	end

	-- Create a connection to check whenever NPCs are added to the tycoon
	if tycoon and tycoon.Value then
		local npcsFolder = tycoon.Value:FindFirstChild("NPCs")
		if not npcsFolder then
			npcsFolder = Instance.new("Folder")
			npcsFolder.Name = "NPCs"
			npcsFolder.Parent = tycoon.Value
		end

		npcsFolder.ChildAdded:Connect(function()
			MilestoneSystem.checkPlayerMilestones(player)
		end)
	end
end

-- Initialize the system
function MilestoneSystem.initialize()
	debugPrint("Initializing Milestone System")

	-- Set up event connections
	Players.PlayerAdded:Connect(function(player)
		task.delay(5, function() -- Wait for player to be fully set up
			MilestoneSystem.initializePlayer(player)
		end)
	end)

	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			MilestoneSystem.initializePlayer(player)
		end)
	end

	-- Connect to the GymTycoonConnector if available
	if _G.GymTycoonConnector then
		local originalUpdateGymLevel = _G.GymTycoonConnector.updateGymLevel
		if originalUpdateGymLevel then
			_G.GymTycoonConnector.updateGymLevel = function(player)
				local result = originalUpdateGymLevel(player)

				-- Check milestones after gym level changes
				if result then
					task.delay(0.5, function()
						MilestoneSystem.checkPlayerMilestones(player)
					end)
				end

				return result
			end
		end
	end

	debugPrint("Milestone System initialized")
	return true
end

-- Run initialization
MilestoneSystem.initialize()

-- Export the module
return MilestoneSystem