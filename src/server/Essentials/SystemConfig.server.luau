-- SystemConfig.lua
local SystemConfig = {
	-- Economy settings
	Economy = {
		baseIncomeAmount = 15,
		incomeInterval = 60,
		vipMultiplier = 3,
		cleanlinessMultiplierRange = {min = 0.7, max = 1.3},
		moraleMultiplierRange = {min = 0.8, max = 1.2}
	},

	-- NPC settings
	NPC = {
		maxNPCsPerGym = 15,
		spawnInterval = 60,
		moveSpeed = 8,
		equipmentTargetChance = 0.7
	},

	-- Buy Tile settings
	BuyTile = {
		animationDuration = 1,
		animationStyle = Enum.EasingStyle.Sine,
		animationDirection = Enum.EasingDirection.Out
	}
}

return SystemConfig