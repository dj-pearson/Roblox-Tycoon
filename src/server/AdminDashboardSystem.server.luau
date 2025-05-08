--!strict
--[[
    AdminDashboardSystem.server.luau
    
    Enhanced admin dashboard system that provides monitoring and control
    capabilities for administrators.
    
    Features:
    - System status monitoring
    - Health check visualization
    - System recovery controls
    - Admin-only access
    - Centralized admin management
    - System statistics
    - Error reporting
    - Command console
    - Detailed error viewer
    
    Created: May 3, 2025
]]

local GameSystem = require(script.Parent.GameSystem)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Import required modules
local SystemInitializationCoordinator = require(script.Parent.Core.SystemInitializationCoordinator)

-- Configuration
local CONFIG = {
	ADMIN_IDS = {
		[7768610061] = true, -- Only authorized admin
	},
	REFRESH_INTERVAL = 5, -- seconds
	MAX_ERROR_HISTORY = 100,
	MAX_COMMAND_HISTORY = 50,
	COMMANDS = {
		reset = {
			description = "Reset the game state",
			usage = "/reset",
			handler = function(player)
				return AdminDashboardSystem.resetGame(player)
			end
		},
		recover = {
			description = "Attempt to recover a system",
			usage = "/recover <systemName>",
			handler = function(player, args)
				if not args[1] then
					return false, "System name required"
				end
				return AdminDashboardSystem.recoverSystem(player, args[1])
			end
		},
		status = {
			description = "Get system status",
			usage = "/status [systemName]",
			handler = function(player, args)
				local status = AdminDashboardSystem.getSystemStatus(player, args[1])
				return true, HttpService:JSONEncode(status)
			end
		},
		stats = {
			description = "Get system statistics",
			usage = "/stats [systemName]",
			handler = function(player, args)
				local stats = AdminDashboardSystem.getSystemStats(player, args[1])
				return true, HttpService:JSONEncode(stats)
			end
		}
	}
}

-- Admin dashboard state
local AdminDashboardSystem = {
	initialized = false,
	version = "1.0.0",
	errorHistory = {},
	commandHistory = {},
	stats = {
		totalCommands = 0,
		successfulCommands = 0,
		failedCommands = 0,
		systemStats = {}
	}
}

-- Debug logging
local function log(message, level)
	level = level or "Info"
	print(string.format("[AdminDashboardSystem][%s] %s", level, message))
end

-- Check if player is admin
function AdminDashboardSystem.isAdmin(player)
	return CONFIG.ADMIN_IDS[player.UserId] ~= nil
end

-- Execute command
function AdminDashboardSystem.executeCommand(player, command, args)
	if not AdminDashboardSystem.isAdmin(player) then
		log("Non-admin player attempted to execute command", "Warning")
		return false, "Unauthorized"
	end
	
	AdminDashboardSystem.stats.totalCommands += 1
	
	local cmd = CONFIG.COMMANDS[command]
	if not cmd then
		AdminDashboardSystem.stats.failedCommands += 1
		return false, "Unknown command: " .. command
	end
	
	-- Record command in history
	table.insert(AdminDashboardSystem.commandHistory, 1, {
		timestamp = os.time(),
		player = player.Name,
		command = command,
		args = args,
		success = nil
	})
	
	-- Trim command history if needed
	if #AdminDashboardSystem.commandHistory > CONFIG.MAX_COMMAND_HISTORY then
		table.remove(AdminDashboardSystem.commandHistory)
	end
	
	-- Execute command
	local success, result = pcall(function()
		return cmd.handler(player, args)
	end)
	
	if success then
		AdminDashboardSystem.stats.successfulCommands += 1
		AdminDashboardSystem.commandHistory[1].success = true
		log("Command executed successfully: " .. command)
		return true, result
	else
		AdminDashboardSystem.stats.failedCommands += 1
		AdminDashboardSystem.commandHistory[1].success = false
		log("Command failed: " .. command .. " - " .. tostring(result), "Error")
		return false, result
	end
end

-- Get system status
function AdminDashboardSystem.getSystemStatus(player, systemName)
	if not AdminDashboardSystem.isAdmin(player) then
		return nil
	end
	
	return SystemInitializationCoordinator:getSystemStatus(systemName)
end

-- Get system statistics
function AdminDashboardSystem.getSystemStats(player, systemName)
	if not AdminDashboardSystem.isAdmin(player) then
		return nil
	end
	
	local stats = SystemInitializationCoordinator:getStats()
	if systemName then
		return stats[systemName]
	end
	return stats
end

-- Get command history
function AdminDashboardSystem.getCommandHistory(player)
	if not AdminDashboardSystem.isAdmin(player) then
		return nil
	end
	
	return AdminDashboardSystem.commandHistory
end

-- Get error history
function AdminDashboardSystem.getErrorHistory(player)
	if not AdminDashboardSystem.isAdmin(player) then
		return nil
	end
	
	return AdminDashboardSystem.errorHistory
end

-- Add error to history
function AdminDashboardSystem.addError(error)
	table.insert(AdminDashboardSystem.errorHistory, 1, {
		timestamp = os.time(),
		error = error
	})
	
	-- Trim error history if needed
	if #AdminDashboardSystem.errorHistory > CONFIG.MAX_ERROR_HISTORY then
		table.remove(AdminDashboardSystem.errorHistory)
	end
end

-- Reset game
function AdminDashboardSystem.resetGame(player)
	if not AdminDashboardSystem.isAdmin(player) then
		log("Non-admin player attempted to reset the game", "Warning")
		return false
	end
	
	AdminDashboardSystem.stats.totalCommands += 1
	
	local success = pcall(function()
		GameSystem.reset()
	end)
	
	if success then
		AdminDashboardSystem.stats.successfulCommands += 1
		log("Game reset initiated by admin " .. player.Name)
	else
		AdminDashboardSystem.stats.failedCommands += 1
		log("Game reset failed", "Error")
	end
	
	return success
end

-- Initialize admin dashboard
function AdminDashboardSystem:initialize()
	if self.initialized then
		return true
	end
	
	log("Initializing AdminDashboardSystem v" .. self.version)
	
	-- Set up command handling
	local function handleCommand(player, message)
		if not message:match("^/") then
			return
		end
		
		local args = {}
		for arg in message:gmatch("%S+") do
			table.insert(args, arg)
		end
		
		local command = args[1]:sub(2) -- Remove leading slash
		table.remove(args, 1) -- Remove command from args
		
		AdminDashboardSystem.executeCommand(player, command, args)
	end
	
	-- Set up chat commands
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			handleCommand(player, message)
		end)
	end)
	
	self.initialized = true
	log("AdminDashboardSystem initialized successfully")
	return true
end

-- Initialize the admin dashboard
AdminDashboardSystem:initialize()

return AdminDashboardSystem