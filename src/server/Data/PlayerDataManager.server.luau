-- PlayerDataManager.lua
local PlayerDataManager = {
	attributes = {
		-- Standard attributes all systems should use
		gym = {
			"AccruedDues",
			"GymTier",
			"EquipmentCount",
			"Cleanliness",
			"Morale" 
		}
	}
}

-- Get a player attribute with type checking and default values
function PlayerDataManager.getAttribute(player, name, default)
	if not player then return default end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return default end

	return tycoon:GetAttribute(name) or default
end

-- Set a player attribute
function PlayerDataManager.setAttribute(player, name, value)
	if not player then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	tycoon:SetAttribute(name, value)
	return true
end

-- Initialize standard attributes for a player
function PlayerDataManager.initializePlayer(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	-- Initialize default values
	if not tycoon:GetAttribute("AccruedDues") then
		tycoon:SetAttribute("AccruedDues", 0)
	end

	if not tycoon:GetAttribute("GymTier") then
		tycoon:SetAttribute("GymTier", 1)
	end

	if not tycoon:GetAttribute("EquipmentCount") then
		tycoon:SetAttribute("EquipmentCount", 0)
	end

	if not tycoon:GetAttribute("Cleanliness") then
		tycoon:SetAttribute("Cleanliness", 5)
	end

	if not tycoon:GetAttribute("Morale") then
		tycoon:SetAttribute("Morale", 5)
	end

	return true
end

return PlayerDataManager