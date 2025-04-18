-- JobClient.luau
-- Client-side job management using the new architecture pattern

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Private variables
local player = Players.LocalPlayer
local ClientRegistry
local ClientEventBridge
local UIManager
local NotificationSystem

-- Module table
local JobClient = {
	Name = "JobClient",
	Dependencies = {
		"ClientRegistry",
		"ClientEventBridge",
		"UIManager",
		"NotificationSystem"
	}
}

-- Data cache
local cachedJobs = {}
local cachedNPCs = {}
local cachedStaff = {}

-- Initialize the job client module
function JobClient:Initialize(registry)
	-- Get dependencies
	ClientRegistry = registry
	ClientEventBridge = ClientRegistry:GetSystem("ClientEventBridge")
	UIManager = ClientRegistry:GetSystem("UIManager")
	NotificationSystem = ClientRegistry:GetSystem("NotificationSystem")
	
	if not ClientEventBridge or not UIManager or not NotificationSystem then
		warn("[JobClient] Missing dependencies, system may not function correctly")
		return false
	end
	
	-- Register click handlers for job menu
	UIManager:RegisterButton("JobsButton", function()
		self:ToggleJobMenu()
	end)
	
	-- Subscribe to job events
	ClientEventBridge:Subscribe("StaffHired", function(data)
		self:HandleStaffHired(data)
	end)
	
	ClientEventBridge:Subscribe("StaffFired", function(data)
		self:HandleStaffFired(data)
	end)
	
	ClientEventBridge:Subscribe("SalariesPaid", function(data)
		self:HandleSalariesPaid(data)
	end)
	
	ClientEventBridge:Subscribe("InsufficientFunds", function(data)
		self:HandleInsufficientFunds(data)
	end)
	
	-- Register methods for UI modules to call
	UIManager:RegisterMethod("GetAvailableJobs", function()
		return self:GetAvailableJobs()
	end)
	
	UIManager:RegisterMethod("GetAvailableNPCs", function()
		return self:GetAvailableNPCs()
	end)
	
	UIManager:RegisterMethod("GetPlayerStaff", function()
		return self:GetPlayerStaff()
	end)
	
	UIManager:RegisterMethod("HireStaff", function(jobId, npcId)
		return self:HireStaff(jobId, npcId)
	end)
	
	UIManager:RegisterMethod("FireStaff", function(npcId)
		return self:FireStaff(npcId)
	end)
	
	print("[JobClient] Initialized successfully")
	return true
end

-- Toggle job menu visibility
function JobClient:ToggleJobMenu()
	local isVisible = UIManager:ToggleUI("JobsMenu")
	
	if isVisible then
		-- Refresh data when opening
		self:RefreshJobData()
	end
end

-- Get available jobs from server
function JobClient:GetAvailableJobs()
	local success, jobs = pcall(function()
		return ClientEventBridge:InvokeServer("GetAvailableJobs")
	end)
	
	if success and jobs then
		cachedJobs = jobs
		return jobs
	else
		warn("[JobClient] Failed to get job data: ", jobs)
		return cachedJobs -- Return last cached data on failure
	end
end

-- Get available NPCs that can be assigned jobs
function JobClient:GetAvailableNPCs()
	local success, npcs = pcall(function()
		return ClientEventBridge:InvokeServer("GetAvailableNPCs")
	end)
	
	if success and npcs then
		cachedNPCs = npcs
		return npcs
	else
		warn("[JobClient] Failed to get NPC data: ", npcs)
		return cachedNPCs -- Return last cached data on failure
	end
end

-- Get staff members for the player
function JobClient:GetPlayerStaff()
	local success, staff = pcall(function()
		return ClientEventBridge:InvokeServer("GetPlayerStaff")
	end)
	
	if success and staff then
		cachedStaff = staff
		return staff
	else
		warn("[JobClient] Failed to get staff data: ", staff)
		return cachedStaff -- Return last cached data on failure
	end
end

-- Hire staff
function JobClient:HireStaff(jobId, npcId)
	local success, result, message = pcall(function()
		return ClientEventBridge:InvokeServer("HireStaff", jobId, npcId)
	end)
	
	if success then
		if result then
			-- Refresh data
			self:RefreshJobData()
			
			-- Show success notification
			NotificationSystem:Show({
				title = "Staff Hired",
				message = message or "You've hired a new staff member!",
				type = "success",
				duration = 5
			})
			
			-- Play success sound
			UIManager:PlaySound("Success")
			
			return true, message
		else
			-- Show error notification
			NotificationSystem:Show({
				title = "Hiring Failed",
				message = message or "Could not hire staff member",
				type = "error",
				duration = 5
			})
			
			return false, message
		end
	else
		-- Handle error
		warn("[JobClient] Error hiring staff: ", result)
		
		NotificationSystem:Show({
			title = "Error",
			message = "An error occurred while hiring staff",
			type = "error",
			duration = 5
		})
		
		return false, "Error communicating with server"
	end
end

-- Fire staff
function JobClient:FireStaff(npcId)
	local success, result, message = pcall(function()
		return ClientEventBridge:InvokeServer("FireStaff", npcId)
	end)
	
	if success then
		if result then
			-- Refresh data
			self:RefreshJobData()
			
			-- Show notification
			NotificationSystem:Show({
				title = "Staff Member Fired",
				message = message or "You've fired a staff member",
				type = "info",
				duration = 5
			})
			
			return true, message
		else
			-- Show error notification
			NotificationSystem:Show({
				title = "Error",
				message = message or "Could not fire staff member",
				type = "error",
				duration = 5
			})
			
			return false, message
		end
	else
		-- Handle error
		warn("[JobClient] Error firing staff: ", result)
		
		NotificationSystem:Show({
			title = "Error",
			message = "An error occurred while firing staff",
			type = "error",
			duration = 5
		})
		
		return false, "Error communicating with server"
	end
end

-- Refresh all job-related data
function JobClient:RefreshJobData()
	-- Get updated data
	local jobs = self:GetAvailableJobs()
	local npcs = self:GetAvailableNPCs()
	local staff = self:GetPlayerStaff()
	
	-- Update UI with job data
	UIManager:UpdateUI("JobsMenu", {
		jobs = jobs,
		npcs = npcs,
		staff = staff
	})
end

-- Handle staff hired event
function JobClient:HandleStaffHired(data)
	NotificationSystem:Show({
		title = "Staff Hired",
		message = "You've hired a new " .. data.jobName,
		type = "success",
		duration = 5
	})
	
	-- Refresh data
	self:RefreshJobData()
end

-- Handle staff fired event
function JobClient:HandleStaffFired(data)
	NotificationSystem:Show({
		title = "Staff Member Left",
		message = "Your " .. data.jobName .. " is no longer employed",
		type = "info",
		duration = 5
	})
	
	-- Refresh data
	self:RefreshJobData()
end

-- Handle salaries paid event
function JobClient:HandleSalariesPaid(data)
	NotificationSystem:Show({
		title = "Staff Salaries Paid",
		message = "$" .. data.amount .. " has been paid to your " .. data.staffCount .. " staff members",
		type = "info",
		duration = 5
	})
end

-- Handle insufficient funds event
function JobClient:HandleInsufficientFunds(data)
	NotificationSystem:Show({
		title = "Payment Failed",
		message = "You need $" .. data.amount .. " to pay your staff salaries!",
		type = "warning",
		duration = 8
	})
	
	-- Play warning sound
	UIManager:PlaySound("Warning")
end

return JobClient