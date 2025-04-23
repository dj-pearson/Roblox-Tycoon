--lua
--[[
    SafetyService.server.luau
    
    This module provides a centralized service for managing player safety and anti-cheat measures.
    It handles various checks and actions to ensure a safe and fair game environment.
    
    Features:
    - Handles player sanctions (bans, kicks, warnings)
    - Checks for unusual player behavior (e.g., speed, movement)
    - Manages rate limiting for certain actions
    - Logs suspicious activities
    - Integrates with other systems like AdminService and DataStorage
    
    Author: [Your Name or Team Name]
    Date: [Current Date]
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Find CoreRegistry
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

local SanctionSystem


local SafetyService = {}

function SafetyService:Initialize()
    -- Initialization logic here
    print("SafetyService initialized")

    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("SafetyService", self)
        print("SafetyService Registered with CoreRegistry")
    end

	SanctionSystem = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("PlayerSanctionSystem"))
end

function SafetyService:getPlayerSanctions(player)
	-- Returns the number of sanctions a player has
	if not player then return 0 end
	return SanctionSystem.getPlayerSanctionCount(player)
end

function SafetyService:getLastSanctionReason(player)
	-- Returns the reason for the player's last sanction
	if not player then return "" end
	return SanctionSystem.getLastSanctionReason(player)
end

function SafetyService:getBanTimeLeft(player)
	-- Returns the remaining time of a player's ban in a formatted string, or "Not Banned"
	if not player then return "Not Banned" end
	local banned, _, expiration = SanctionSystem.isPlayerBanned(player)
	if banned then
		return SanctionSystem.formatTimeRemaining(expiration)
	else
		return "Not Banned"
	end
end









return SafetyService