-- .lua
local ServerScriptService = game:GetService("ServerScriptService")

local SystemManager = {
	systems = {},
	initialized = false
}

-- Define system dependencies and load order
local systemDefinitions = {
	{name = "GymRevenueSystem", path = "GymRevenueSystem"},
	{name = "NPCSystem", path = "UnifiedNPCSystem", dependencies = {"GymRevenueSystem"}},
	{name = "TycoonSystem", path = "UnifiedTycoonSystem", dependencies = {"GymRevenueSystem"}},
	{name = "FrontDeskSystem", path = "UnifiedFrontDeskSystem", dependencies = {"GymRevenueSystem"}},
	{name = "BuyTileSystem", path = "BuyTile", dependencies = {"GymRevenueSystem", "TycoonSystem"}}
}

-- Load all systems in the correct order
function SystemManager.initialize()
	if SystemManager.initialized then return true end

	-- Track which systems are loaded
	local loaded = {}

	-- Helper function to load a system and its dependencies
	local function loadSystem(definition)
		-- Skip if already loaded
		if loaded[definition.name] then
			return true
		end

		-- Load dependencies first
		if definition.dependencies then
			for _, depName in ipairs(definition.dependencies) do
				-- Find dependency definition
				local depDef = nil
				for _, sys in ipairs(systemDefinitions) do
					if sys.name == depName then
						depDef = sys
						break
					end
				end

				if depDef and not loadSystem(depDef) then
					warn("Failed to load dependency: " .. depName)
					return false
				end
			end
		end

		-- Load the system
		local success = pcall(function()
			local system = require(ServerScriptService:FindFirstChild(definition.path))
			SystemManager.systems[definition.name] = system
			loaded[definition.name] = true
			print("Loaded system: " .. definition.name)
		end)

		return success
	end

	-- Load all systems
	for _, definition in ipairs(systemDefinitions) do
		loadSystem(definition)
	end

	SystemManager.initialized = true
	return true
end

-- Get a system
function SystemManager.getSystem(name)
	return SystemManager.systems[name]
end

return SystemManager