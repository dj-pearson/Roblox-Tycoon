-- CompetitionClient.luau
-- Client-side competition management using the new architecture pattern

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Private variables
local player = Players.LocalPlayer
local ClientRegistry
local ClientEventBridge
local UIManager
local NotificationSystem
local updateInterval = 5 -- Update competition list every 5 seconds

-- Module table
local CompetitionClient = {
	Name = "CompetitionClient",
	Dependencies = {
		"ClientRegistry",
		"ClientEventBridge",
		"UIManager",
		"NotificationSystem"
	}
}

-- Competition data cache
local cachedCompetitions = {}
local activeCompetitions = {}

-- Format time from seconds to MM:SS
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- Format duration from seconds to minutes
local function formatDuration(seconds)
	local minutes = math.floor(seconds / 60)
	if minutes == 1 then
		return "1 minute"
	else
		return minutes .. " minutes"
	end
end

-- Initialize the competition client module
function CompetitionClient:Initialize(registry)
	-- Get dependencies
	ClientRegistry = registry
	ClientEventBridge = ClientRegistry:GetSystem("ClientEventBridge")
	UIManager = ClientRegistry:GetSystem("UIManager")
	NotificationSystem = ClientRegistry:GetSystem("NotificationSystem")
	
	if not ClientEventBridge or not UIManager or not NotificationSystem then
		warn("[CompetitionClient] Missing dependencies, system may not function correctly")
		return false
	end
	
	-- Register click handlers for competition menu
	UIManager:RegisterButton("CompetitionButton", function()
		self:ToggleCompetitionMenu()
	end)
	
	-- Subscribe to competition events
	ClientEventBridge:Subscribe("CompetitionStarted", function(data)
		self:HandleCompetitionStarted(data)
	end)
	
	ClientEventBridge:Subscribe("CompetitionEnded", function(data)
		self:HandleCompetitionEnded(data)
	end)
	
	-- Register methods for UI modules to call
	UIManager:RegisterMethod("StartCompetition", function(competitionId)
		return self:StartCompetition(competitionId)
	end)
	
	UIManager:RegisterMethod("GetCompetitions", function()
		return self:GetCompetitions()
	end)
	
	-- Start periodic updates if competitions menu is open
	self:StartPeriodicUpdates()
	
	print("[CompetitionClient] Initialized successfully")
	return true
end

-- Toggle competition menu visibility
function CompetitionClient:ToggleCompetitionMenu()
	local isVisible = UIManager:ToggleUI("CompetitionMenu")
	
	if isVisible then
		-- Refresh data when opening
		self:RefreshCompetitionData()
	end
end

-- Get competition data from server
function CompetitionClient:GetCompetitions()
	local success, competitions = pcall(function()
		return ClientEventBridge:InvokeServer("GetCompetitions")
	end)
	
	if success and competitions then
		cachedCompetitions = competitions
		return competitions
	else
		warn("[CompetitionClient] Failed to get competition data: ", competitions)
		return cachedCompetitions -- Return last cached data on failure
	end
end

-- Refresh competition data and update UI
function CompetitionClient:RefreshCompetitionData()
	local competitions = self:GetCompetitions()
	
	-- Sort competitions: available first, then by cost
	table.sort(competitions, function(a, b)
		if a.available ~= b.available then
			return a.available
		end
		return a.cost < b.cost
	end)
	
	-- Update UI with competition data
	UIManager:UpdateUI("CompetitionMenu", {
		competitions = competitions,
		formatDuration = formatDuration,
		formatTime = formatTime
	})
end

-- Start a competition
function CompetitionClient:StartCompetition(competitionId)
	local success, result = pcall(function()
		return ClientEventBridge:InvokeServer("StartCompetition", competitionId)
	end)
	
	if success and result then
		-- Close the menu with delay
		delay(1.5, function()
			UIManager:CloseUI("CompetitionMenu")
		end)
		
		-- Play success sound
		UIManager:PlaySound("Success")
		
		-- Show success notification
		NotificationSystem:Show({
			title = "Competition Started",
			message = "Your competition has started successfully!",
			type = "success",
			duration = 5
		})
		
		return true, "Competition started successfully"
	else
		-- Show error notification
		NotificationSystem:Show({
			title = "Error",
			message = tostring(result) or "Failed to start competition",
			type = "error",
			duration = 5
		})
		
		return false, tostring(result) or "Failed to start competition"
	end
end

-- Handle competition started event
function CompetitionClient:HandleCompetitionStarted(data)
	if data.playerName == player.Name then
		-- This is for the player who started it
		NotificationSystem:Show({
			title = "Competition Started",
			message = "You've started a " .. data.competitionName .. "!",
			type = "success",
			duration = 5
		})
	else
		-- This is for other players
		NotificationSystem:Show({
			title = "Competition Announcement",
			message = data.playerName .. " has started a " .. data.competitionName .. "!",
			type = "info",
			duration = 5
		})
	end
end

-- Handle competition ended event
function CompetitionClient:HandleCompetitionEnded(data)
	if data.playerId == player.UserId then
		-- Only notify the player whose competition ended
		NotificationSystem:Show({
			title = "Competition Ended",
			message = "Your " .. data.competitionName .. " has ended.",
			type = "info",
			duration = 5
		})
		
		-- Refresh competition data
		self:RefreshCompetitionData()
	end
end

-- Start periodic updates for competition data
function CompetitionClient:StartPeriodicUpdates()
	spawn(function()
		while true do
			wait(updateInterval)
			
			-- Only refresh if menu is open
			if UIManager:IsUIOpen("CompetitionMenu") then
				self:RefreshCompetitionData()
			end
		end
	end)
end

return CompetitionClient