-- EquipmentUpgrades.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")


-- List of equipment upgrades
local upgrades = {
	{name = "Treadmill Upgrade", cost = 100, benefit = "Increased NPC satisfaction"},
	{name = "Free Weight Upgrade", cost = 200, benefit = "Increased membership fees"}
}

-- Function to upgrade equipment
local function upgradeEquipment(equipmentName, upgradeName)
	for _, upgrade in pairs(upgrades) do
		if upgrade.name == upgradeName then
			-- Logic to apply the upgrade benefits
			print(equipmentName .. " upgraded with " .. upgradeName)
			return
		end
	end
end

-- Example usage
upgradeEquipment("Treadmill", "Treadmill Upgrade")
