-- HealthCheckSystem.luau
-- Monitors the health of various game systems and reports issues
-- Created: April 28, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local CHECK_INTERVAL = 60 -- seconds
local ISSUE_THRESHOLD = 3 -- How many consecutive failures before declaring an issue
local RECOVERY_THRESHOLD = 3 -- How many consecutive successes before declaring recovery
local HISTORY_LENGTH = 10 -- Number of results to keep in history

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" and level ~= "Warning" then return end
	print(string.format("[HealthCheckSystem][%s] %s", level, message))
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or 5
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- HealthCheckSystem object
local HealthCheckSystem = {
	_version = VERSION,
	_checks = {}, -- Registered health checks
	_results = {}, -- Latest check results
	_history = {}, -- History of check results
	_issues = {}, -- Active issues
	_stats = {
		checksRun = 0,
		issuesFound = 0,
		issuesResolved = 0
	},
	_healthStatus = "OK", -- Overall health status (OK, WARNING, CRITICAL)
	_subscribers = {}, -- Callbacks for health updates
	_lastCheckTime = 0,
	_checkConnection = nil,
	_initialized = false
}

-- Health check statuses
local Status = {
	OK = "OK",
	WARNING = "WARNING",
	CRITICAL = "CRITICAL"
}

-- Get CoreRegistry if available
local function getCoreRegistry()
	local core = ServerScriptService:FindFirstChild("Core")
	if not core then
		log("Core folder not found", "Warning")
		return nil
	end
	
	local coreRegistry = core:FindFirstChild("CoreRegistry")
	if not coreRegistry then
		log("CoreRegistry not found", "Warning")
		return nil
	end
	
	local success, result = pcall(function()
		return require(coreRegistry)
	end)
	
	if success then
		return result
	else
		log("Failed to require CoreRegistry: " .. tostring(result), "Error")
		return nil
	end
end

-- Initialize the health check system
function HealthCheckSystem:Initialize()
	if self._initialized then
		return true
	end
	
	log("Initializing HealthCheckSystem v" .. VERSION)
	
	-- Register with CoreRegistry if available
	local coreRegistry = getCoreRegistry()
	if coreRegistry then
		coreRegistry:Register("HealthCheckSystem", self)
		log("Registered with CoreRegistry")
	else
		log("CoreRegistry not available, skipping registration", "Warning")
	end
	
	-- Start the health check timer
	self:StartChecks()
	
	self._initialized = true
	log("HealthCheckSystem initialized")
	return true
end

-- Start periodic health checks
function HealthCheckSystem:StartChecks()
	-- Cancel existing connection if any
	if self._checkConnection then
		self._checkConnection:Disconnect()
	end
	
	log("Starting periodic health checks with interval: " .. CHECK_INTERVAL .. " seconds")
	
	-- Use RunService.Heartbeat for timers
	local lastCheck = os.clock()
	self._checkConnection = RunService.Heartbeat:Connect(function()
		-- Only run every CHECK_INTERVAL seconds
		if os.clock() - lastCheck >= CHECK_INTERVAL then
			self:RunAllChecks()
			lastCheck = os.clock()
		end
	end)
	
	-- Run an initial check
	self:RunAllChecks()
	
	return true
end

-- Register a new health check
function HealthCheckSystem:RegisterCheck(checkInfo)
	-- Validate check info
	if not checkInfo or not checkInfo.name or not checkInfo.check then
		log("Invalid check registration", "Error")
		return false
	end
	
	-- Add to registered checks
	self._checks[checkInfo.name] = {
		name = checkInfo.name,
		description = checkInfo.description or "",
		check = checkInfo.check,
		severity = checkInfo.severity or "WARNING",
		category = checkInfo.category or "System"
	}
	
	log("Registered check: " .. checkInfo.name)
	return true
end

-- Run a specific health check
function HealthCheckSystem:RunCheck(checkName)
	local check = self._checks[checkName]
	if not check then
		log("Check not found: " .. checkName, "Error")
		return false
	end
	
	-- Run the check
	local success, result = pcall(function()
		return check.check()
	end)
	
	-- Handle error in check function
	if not success then
		log("Error in health check '" .. checkName .. "': " .. tostring(result), "Error")
		return false
	end
	
	-- Save the result
	local checkResult = {
		status = result.status or Status.CRITICAL,
		message = result.message or "No message provided",
		details = result.details or {},
		timestamp = os.time()
	}
	
	-- Update results
	self._results[checkName] = checkResult
	
	-- Update history
	self._history[checkName] = self._history[checkName] or {}
	table.insert(self._history[checkName], 1, checkResult)
	
	-- Trim history
	if #self._history[checkName] > HISTORY_LENGTH then
		self._history[checkName][HISTORY_LENGTH + 1] = nil
	end
	
	-- Check for new issues or recovery
	self:UpdateIssueStatus(checkName)
	
	log("Check '" .. checkName .. "' status: " .. checkResult.status .. 
		(checkResult.status ~= Status.OK and " - " .. checkResult.message or ""), 
		checkResult.status == Status.CRITICAL and "Error" or (checkResult.status == Status.WARNING and "Warning" or "Info"))
	
	return true
end

-- Run all health checks
function HealthCheckSystem:RunAllChecks()
	log("Running all health checks")
	
	local startTime = os.clock()
	local checksRun = 0
	
	for checkName, _ in pairs(self._checks) do
		self:RunCheck(checkName)
		checksRun += 1
	end
	
	local duration = os.clock() - startTime
	
	-- Update stats
	self._stats.checksRun += checksRun
	self._lastCheckTime = os.time()
	
	-- Update overall health status
	self:UpdateOverallHealth()
	
	log("Completed " .. checksRun .. " health checks in " .. string.format("%.2f", duration) .. " seconds")
	
	-- Notify subscribers
	self:NotifySubscribers()
	
	return true
end

-- Update issue status for a check
function HealthCheckSystem:UpdateIssueStatus(checkName)
	local history = self._history[checkName]
	if not history or #history < 1 then
		return
	end
	
	local check = self._checks[checkName]
	if not check then
		return
	end
	
	-- Get consecutive status
	local currentStatus = history[1].status
	local consecutiveCount = 0
	
	for i, result in ipairs(history) do
		if result.status == currentStatus then
			consecutiveCount += 1
		else
			break
		end
	end
	
	-- Check if this is an issue
	if currentStatus ~= Status.OK then
		-- Check if we've reached the threshold for declaring an issue
		if consecutiveCount >= ISSUE_THRESHOLD then
			-- Create or update issue
			if not self._issues[checkName] then
				-- New issue
				self._issues[checkName] = {
					name = checkName,
					description = check.description,
					status = currentStatus,
					message = history[1].message,
					details = history[1].details,
					firstDetected = history[1].timestamp,
					lastUpdated = history[1].timestamp,
					severity = check.severity,
					category = check.category
				}
				
				self._stats.issuesFound += 1
				
				log("New issue detected: " .. checkName .. " - " .. history[1].message, 
					currentStatus == Status.CRITICAL and "Error" or "Warning")
			else
				-- Update existing issue
				self._issues[checkName].status = currentStatus
				self._issues[checkName].message = history[1].message
				self._issues[checkName].details = history[1].details
				self._issues[checkName].lastUpdated = history[1].timestamp
			end
		end
	else
		-- Check for recovery
		if consecutiveCount >= RECOVERY_THRESHOLD then
			-- Check if we had an issue before
			if self._issues[checkName] then
				-- Issue resolved
				log("Issue resolved: " .. checkName, "Info")
				self._stats.issuesResolved += 1
				self._issues[checkName] = nil
			end
		end
	end
end

-- Update overall health status
function HealthCheckSystem:UpdateOverallHealth()
	local hasCritical = false
	local hasWarning = false
	
	-- Check all issues
	for _, issue in pairs(self._issues) do
		if issue.status == Status.CRITICAL then
			hasCritical = true
		elseif issue.status == Status.WARNING then
			hasWarning = true
		end
	end
	
	-- Determine overall status
	local previousStatus = self._healthStatus
	
	if hasCritical then
		self._healthStatus = Status.CRITICAL
	elseif hasWarning then
		self._healthStatus = Status.WARNING
	else
		self._healthStatus = Status.OK
	end
	
	-- Log status change
	if previousStatus ~= self._healthStatus then
		log("Health status changed from " .. previousStatus .. " to " .. self._healthStatus, 
			self._healthStatus == Status.CRITICAL and "Error" or 
			(self._healthStatus == Status.WARNING and "Warning" or "Info"))
	end
end

-- Subscribe to health updates
function HealthCheckSystem:Subscribe(callback)
	if type(callback) ~= "function" then
		log("Subscribe callback must be a function", "Error")
		return false
	end
	
	table.insert(self._subscribers, callback)
	log("Added health update subscriber")
	return true
end

-- Notify all subscribers
function HealthCheckSystem:NotifySubscribers()
	-- Create update info
	local updateInfo = {
		timestamp = os.time(),
		status = self._healthStatus,
		issueCount = 0,
		issues = {}
	}
	
	-- Count issues
	for checkName, issue in pairs(self._issues) do
		updateInfo.issueCount += 1
		updateInfo.issues[checkName] = {
			name = issue.name,
			status = issue.status,
			message = issue.message,
			severity = issue.severity,
			category = issue.category
		}
	end
	
	-- Notify subscribers
	for _, callback in ipairs(self._subscribers) do
		pcall(function()
			callback(updateInfo)
		end)
	end
end

-- Register standard health checks
function HealthCheckSystem:RegisterStandardChecks()
	-- Check CoreRegistry
	self:RegisterCheck({
		name = "CoreRegistry",
		description = "Checks if the CoreRegistry is available and operational",
		category = "Core Systems",
		severity = "CRITICAL",
		check = function()
			local coreRegistry = getCoreRegistry()
			if not coreRegistry then
				return {
					status = Status.CRITICAL,
					message = "CoreRegistry not found or not operational"
				}
			end
			
			return {
				status = Status.OK,
				message = "CoreRegistry operational"
			}
		end
	})
	
	-- Check ModuleLoader
	self:RegisterCheck({
		name = "ModuleLoader",
		description = "Checks if the ModuleLoader is available and operational",
		category = "Core Systems",
		severity = "CRITICAL",
		check = function()
			-- Try to find ModuleLoader
			local moduleLoader = nil
			
			-- Look in ReplicatedStorage
			local shared = ReplicatedStorage:FindFirstChild("shared")
			if shared and shared:FindFirstChild("ModuleLoader") then
				local success, result = pcall(function()
					return require(shared.ModuleLoader)
				end)
				
				if success then
					moduleLoader = result
				end
			end
			
			if not moduleLoader then
				return {
					status = Status.CRITICAL,
					message = "ModuleLoader not found"
				}
			end
			
			-- Check basic functionality
			local success = pcall(function()
				return moduleLoader:GetVersion()
			end)
			
			if not success then
				return {
					status = Status.WARNING,
					message = "ModuleLoader found but not functioning properly"
				}
			end
			
			return {
				status = Status.OK,
				message = "ModuleLoader operational"
			}
		end
	})
	
	-- Check DataManager
	self:RegisterCheck({
		name = "DataManager",
		description = "Checks if the DataManager is available and operational",
		category = "Data Systems",
		severity = "CRITICAL",
		check = function()
			-- Try to find DataManager through CoreRegistry
			local dataManager = nil
			local coreRegistry = getCoreRegistry()
			
			if coreRegistry then
				dataManager = coreRegistry:Get("DataManager")
			end
			
			if not dataManager then
				-- Try to find directly
				local data = ServerScriptService:FindFirstChild("Data")
				if data and data:FindFirstChild("DataManager") then
					local success, result = pcall(function()
						return require(data.DataManager)
					end)
					
					if success then
						dataManager = result
					end
				end
			end
			
			if not dataManager then
				return {
					status = Status.CRITICAL,
					message = "DataManager not found"
				}
			end
			
			-- Check if initialized
			if dataManager._initialized ~= true then
				return {
					status = Status.WARNING,
					message = "DataManager found but not initialized"
				}
			end
			
			return {
				status = Status.OK,
				message = "DataManager operational"
			}
		end
	})
	
	-- Check Memory Usage
	self:RegisterCheck({
		name = "MemoryUsage",
		description = "Monitors memory usage of the game",
		category = "Performance",
		severity = "WARNING",
		check = function()
			local stats = stats or game:GetService("Stats")
			local memoryUsageMB = stats:GetTotalMemoryUsageMb()
			
			-- Thresholds can be adjusted based on your game's needs
			if memoryUsageMB > 8000 then
				return {
					status = Status.CRITICAL,
					message = "Memory usage critically high: " .. string.format("%.2f", memoryUsageMB) .. " MB",
					details = {
						memoryUsageMB = memoryUsageMB,
						threshold = 8000
					}
				}
			elseif memoryUsageMB > 4000 then
				return {
					status = Status.WARNING,
					message = "Memory usage high: " .. string.format("%.2f", memoryUsageMB) .. " MB",
					details = {
						memoryUsageMB = memoryUsageMB,
						threshold = 4000
					}
				}
			end
			
			return {
				status = Status.OK,
				message = "Memory usage normal: " .. string.format("%.2f", memoryUsageMB) .. " MB",
				details = {
					memoryUsageMB = memoryUsageMB
				}
			}
		end
	})
	
	-- Check Server FPS
	self:RegisterCheck({
		name = "ServerFPS",
		description = "Monitors server framerate",
		category = "Performance",
		severity = "WARNING",
		check = function()
			local stats = stats or game:GetService("Stats")
			local fps = 1 / stats:GetValue(Enum.DeveloperMemoryTag.LuaHeap)
			
			if fps < 20 then
				return {
					status = Status.CRITICAL,
					message = "Server FPS critically low: " .. string.format("%.1f", fps),
					details = {
						fps = fps,
						threshold = 20
					}
				}
			elseif fps < 30 then
				return {
					status = Status.WARNING,
					message = "Server FPS low: " .. string.format("%.1f", fps),
					details = {
						fps = fps,
						threshold = 30
					}
				}
			end
			
			return {
				status = Status.OK,
				message = "Server FPS normal: " .. string.format("%.1f", fps),
				details = {
					fps = fps
				}
			}
		end
	})
	
	-- Check Player Count
	self:RegisterCheck({
		name = "PlayerCount",
		description = "Monitors number of players in the game",
		category = "Server",
		severity = "INFO",
		check = function()
			local playerCount = #Players:GetPlayers()
			
			return {
				status = Status.OK,
				message = "Player count: " .. playerCount,
				details = {
					playerCount = playerCount
				}
			}
		end
	})
	
	log("Registered standard health checks")
end

-- Get current health status
function HealthCheckSystem:GetHealthStatus()
	return {
		status = self._healthStatus,
		lastCheckTime = self._lastCheckTime,
		issueCount = 0, -- Calculated below
		issues = self._issues,
		stats = self._stats
	}
end

-- Get detailed health report
function HealthCheckSystem:GetHealthReport()
	-- Count issues by severity
	local issueCounts = {
		CRITICAL = 0,
		WARNING = 0,
		INFO = 0
	}
	
	for _, issue in pairs(self._issues) do
		if issue.severity == "CRITICAL" then
			issueCounts.CRITICAL += 1
		elseif issue.severity == "WARNING" then
			issueCounts.WARNING += 1
		else
			issueCounts.INFO += 1
		end
	end
	
	return {
		status = self._healthStatus,
		lastCheckTime = self._lastCheckTime,
		checkCount = #self._checks,
		issueCounts = issueCounts,
		issues = self._issues,
		results = self._results,
		stats = self._stats
	}
end

-- Get system version
function HealthCheckSystem:GetVersion()
	return self._version
end

-- Initialize the system
HealthCheckSystem:Initialize()
HealthCheckSystem:RegisterStandardChecks()

return HealthCheckSystem
