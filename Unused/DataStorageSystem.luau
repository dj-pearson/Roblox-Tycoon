-- DataStorageSystem.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

-- Configuration
local CONFIG = {
	mainDataStoreName = "GymTycoonDatav2", -- Updated version for schema changes
	saveInterval = 60, -- Save every 60 seconds
	defaultData = {
		cash = 1000,
		totalEarned = 0,
		equipmentPurchased = {}, -- Tracks purchased items
		equipmentCount = 0,
		gymLevel = 1,
		memberCount = 0,
		vipCount = 0,
		playTime = 0,
		lastPlayed = 0,
	},
}

local DataStorage = {}
DataStorage.loadedData = {}

-- Initialize DataStore
function DataStorage.initialize()
	local success, result = pcall(function()
		DataStorage.dataStore = DataStoreService:GetDataStore(CONFIG.mainDataStoreName)
	end)
	if not success then
		warn("Failed to initialize data stores: " .. tostring(result))
		return false
	end
	return true
end

-- Load player data
function DataStorage.loadData(player)
	local userId = player.UserId
	if DataStorage.loadedData[userId] then return DataStorage.loadedData[userId] end

	local success, data = pcall(function()
		return DataStorage.dataStore:GetAsync(tostring(userId))
	end)

	if not success or not data then
		data = CONFIG.defaultData -- Use default data if no previous data exists
	end

	-- Store loaded data in memory
	DataStorage.loadedData[userId] = data
	return data
end

-- Save player data
function DataStorage.saveData(player)
	local userId = player.UserId
	local data = DataStorage.loadedData[userId]
	if not data then return false end

	-- Update from player state before saving
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		data.cash = player:FindFirstChild("leaderstats").Cash.Value or CONFIG.defaultData.cash
		data.equipmentCount = tycoon:GetAttribute("EquipmentCount") or CONFIG.defaultData.equipmentCount
		data.memberCount = tycoon:GetAttribute("MemberCount") or CONFIG.defaultData.memberCount
		data.vipCount = tycoon:GetAttribute("VIPCount") or CONFIG.defaultData.vipCount

		-- Log purchased items by checking GymParts folder in Workspace
		local gymPartsFolder = Workspace:FindFirstChild("GymParts")
		if gymPartsFolder then
			for _, item in pairs(gymPartsFolder:GetChildren()) do
				local id = item:GetAttribute("ID")
				if id then
					data.equipmentPurchased[tostring(id)] = true -- Record purchased item IDs
				end
			end
		end

		data.totalEarned += tycoon:GetAttribute("TotalCashCollected") or 0 -- Update total earnings
	end

	-- Save back to datastore asynchronously
	local success, errorMessage = pcall(function()
		DataStorage.dataStore:SetAsync(tostring(userId), data)
	end)

	if not success then warn("Failed to save data for " .. player.Name .. ": " .. tostring(errorMessage)) end

	return success
end

-- Apply saved data to player's tycoon state on rejoin
function DataStorage.applyDataToPlayer(player)
	local userId = player.UserId
	local data = DataStorage.loadedData[userId]
	if not data then return false end

	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local cashValue = leaderstats:FindFirstChild("Cash") or Instance.new("IntValue", leaderstats)
	cashValue.Name = "Cash"
	cashValue.Value = data.cash

	local tycoon = player:FindFirstChild("Tycoon") or Instance.new("ObjectValue", player)
	tycoon.Name = "Tycoon"

	tycoon:SetAttribute("EquipmentCount", data.equipmentCount)
	tycoon:SetAttribute("MemberCount", data.memberCount)
	tycoon:SetAttribute("VIPCount", data.vipCount)

	-- Restore purchased items by spawning them into the map from GymParts folder in Workspace.
	local gymPartsFolder = Workspace:FindFirstChild("GymParts")
	if gymPartsFolder then
		for id, _ in pairs(data.equipmentPurchased) do
			local partTemplate = gymPartsFolder:FindFirstChild(tostring(id))
			if partTemplate then partTemplate:Clone().Parent = Workspace end -- Spawn item back into Workspace.
		end
	end

	return true
end

-- In DataStorageSystem.lua (restorePurchasedEquipment function)
function DataStorage.restorePurchasedEquipment(player)
	local userId = player.UserId
	local data = DataStorage.loadedData[userId]
	if not data or not data.equipmentPurchased then return false end

	-- Iterate through purchased tiles and spawn them using BuyTile system.
	local BuyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
	for tileId, _ in pairs(data.equipmentPurchased) do
		task.spawn(function()
			local success = BuyTileSystem.spawnGymPart(tileId)
			if success then
				print("Restored gym part with ID:", tileId, "for player:", player.Name)
			else
				warn("Failed to restore gym part with ID:", tileId)
			end
		end)
	end

	return true
end


-- Auto-save routine for all players every interval seconds.
function DataStorage.autoSave()
	while true do wait(CONFIG.saveInterval)
		for _, player in pairs(Players:GetPlayers()) do task.spawn(function() DataStorage.saveData(player) end) end
	end
end

-- Player events for loading and saving on join/leave.
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local dataLoadedSuccessfully = DataStorage.loadData(player)
		if dataLoadedSuccessfully then DataStorage.applyDataToPlayer(player) end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	task.spawn(function()
		DataStorage.saveData(player) -- Save immediately on leave.
		DataStorage.loadedData[player.UserId] = nil -- Clear memory.
	end)
end)

-- Initialize system and start auto-save loop.
if DataStorage.initialize() then task.spawn(DataStorage.autoSave) end

return DataStorage
