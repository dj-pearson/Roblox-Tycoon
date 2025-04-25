lua
local GameSystem = require(script.Parent.GameSystem)
local Players = game:GetService("Players")
local AdminDashboardSystem = {}

local CONFIG = {
	ADMIN_IDS = {
		[288646837] = true, -- Example User ID
	},
}

function AdminDashboardSystem.isAdmin(player)
	return CONFIG.ADMIN_IDS[player.UserId] ~= nil
end

function AdminDashboardSystem.resetGame(player)
	print("Attempting to reset the game...")
	if not AdminDashboardSystem.isAdmin(player) then
		warn("Non-admin player attempted to reset the game.")
		return
	end

	GameSystem.reset()
	print("Game reset initiated by admin",player.Name)
end

return AdminDashboardSystem