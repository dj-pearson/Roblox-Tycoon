-- Sauna Temperature System
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
	-- Sauna room detection
	saunaRoomTagName = "SaunaRoom", -- Tag the room parts with this

	-- Temperature settings
	minTemperature = 20, -- Room temperature in Celsius
	maxTemperature = 90, -- Maximum sauna temperature
	heatingRate = 2, -- Degrees per minute heaters raise temperature
	coolingRate = 5, -- Degrees per minute room cools down without heaters

	-- Gameplay effects
	healthRestoreRate = 0.5, -- Health restored per second in sauna
	maxHealthRestoreTime = 60, -- Maximum time health restores (seconds)
	staminaRestoreRate = 1, -- Stamina restored per second (if you have a stamina system)

	-- UI settings
	showTemperatureUI = true, -- Whether to show temperature UI
	temperatureTextColor = Color3.fromRGB(255, 100, 0), -- Orange text
	uiUpdateInterval = 1, -- How often to update UI (seconds)

	-- Door effects
	doorSteamEffect = true, -- Create steam when door is opened
	doorSteamDuration = 3, -- How long door steam lasts

	-- NPC behaviors (if you have NPCs)
	enableNPCBehaviors = false, -- Set to true if you have NPCs
	npcMaxSaunaTime = 300, -- Maximum time NPCs stay in sauna (seconds)

	-- Sound
	ambientSoundId = "rbxassetid://9116569437", -- Ambient sauna sound
	ambientSoundVolume = 0.3
}

-- Create RemoteEvents for client communication
local remotes = {
	updateTemperature = Instance.new("RemoteEvent"),
	enterSauna = Instance.new("RemoteEvent"),
	exitSauna = Instance.new("RemoteEvent")
}

for name, remote in pairs(remotes) do
	remote.Name = name
	remote.Parent = ReplicatedStorage
end

-- Temperature module to share with other scripts
local TemperatureModule = {}

-- Store all sauna rooms
local saunaRooms = {}

-- Store player data
local playerData = {}

-- Find all sauna heaters
local function findSaunaHeaters()
	local heaters = {}

	-- Look for models named "Heater" or with attribute "IsSaunaHeater"
	for _, obj in pairs(workspace:GetDescendants()) do
		if (obj.Name == "Heater" or obj.Name == "Heater Element" or 
			(obj:GetAttribute("IsSaunaHeater") == true)) then
			table.insert(heaters, obj)
		end
	end

	print("Found " .. #heaters .. " sauna heaters")
	return heaters
end

-- Find all sauna rooms
local function findSaunaRooms()
	local rooms = {}
	local CollectionService = game:GetService("CollectionService")

	-- Get all parts tagged as SaunaRoom
	local taggedParts = CollectionService:GetTagged(CONFIG.saunaRoomTagName)

	-- Group parts by model/folder
	local roomGroups = {}

	for _, part in pairs(taggedParts) do
		local parent = part.Parent
		if parent then
			if not roomGroups[parent] then
				roomGroups[parent] = {}
			end
			table.insert(roomGroups[parent], part)
		end
	end

	-- Create room data for each group
	for parent, parts in pairs(roomGroups) do
		local room = {
			name = parent.Name,
			parts = parts,
			heaters = {},
			temperature = CONFIG.minTemperature,
			players = {},
			boundingBox = {
				min = Vector3.new(math.huge, math.huge, math.huge),
				max = Vector3.new(-math.huge, -math.huge, -math.huge)
			}
		}

		-- Calculate bounding box for the room
		for _, part in pairs(parts) do
			local size
			if part:IsA("BasePart") then
				size = part.Size
			elseif part:IsA("Model") and part.PrimaryPart then
				size = part.PrimaryPart.Size
			else
				-- Find any part to use for size
				for _, subpart in pairs(part:GetDescendants()) do
					if subpart:IsA("BasePart") then
						size = subpart.Size
						break
					end
				end

				-- If still no size found, use a default
				if not size then
					size = Vector3.new(1, 1, 1)
					warn("Could not determine size for " .. part:GetFullName())
				end
			end
		end

		table.insert(rooms, room)
	end

	print("Found " .. #rooms .. " sauna rooms")
	return rooms
end

-- Function to check if a position is inside a room
local function isPositionInRoom(position, room)
	return position.X >= room.boundingBox.min.X and position.X <= room.boundingBox.max.X and
		position.Y >= room.boundingBox.min.Y and position.Y <= room.boundingBox.max.Y and
		position.Z >= room.boundingBox.min.Z and position.Z <= room.boundingBox.max.Z
end

-- Function to find which room a player is in
local function findPlayerRoom(player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local position = player.Character.HumanoidRootPart.Position

	for _, room in pairs(saunaRooms) do
		if isPositionInRoom(position, room) then
			return room
		end
	end

	return nil
end

-- Function to assign heaters to rooms
local function assignHeatersToRooms(heaters, rooms)
	for _, heater in pairs(heaters) do
		local heaterPosition
		if heater:IsA("BasePart") then
			heaterPosition = heater.Position
		elseif heater:IsA("Model") then
			if heater.PrimaryPart then
				heaterPosition = heater.PrimaryPart.Position
			else
				-- Find any part to use
				for _, part in pairs(heater:GetDescendants()) do
					if part:IsA("BasePart") then
						heaterPosition = part.Position
						break
					end
				end
			end
		end

		if heaterPosition then
			-- Find which room this heater belongs to
			for _, room in pairs(rooms) do
				if isPositionInRoom(heaterPosition, room) then
					table.insert(room.heaters, heater)
					break
				end
			end
		end
	end

	-- Print heater assignments
	for _, room in pairs(rooms) do
		print(room.name .. " has " .. #room.heaters .. " heaters")
	end
end

-- Function to update room temperature
local function updateRoomTemperature(room, deltaTime)
	local activeHeaters = 0

	-- Check which heaters are active
	for _, heater in pairs(room.heaters) do
		-- Check if heater has a "HeaterEnabled" attribute
		local enabled = heater:GetAttribute("HeaterEnabled")

		-- If attribute doesn't exist, assume always on
		if enabled == nil then
			enabled = true
		end

		if enabled then
			activeHeaters = activeHeaters + 1
		end
	end

	-- Calculate temperature change
	local temperatureChange = 0

	if activeHeaters > 0 then
		-- Heating rate depends on number of active heaters
		local heatingMultiplier = 1 + (activeHeaters - 1) * 0.5 -- Diminishing returns for multiple heaters
		temperatureChange = (CONFIG.heatingRate / 60) * deltaTime * heatingMultiplier
	else
		-- Room cools down when no heaters are active
		temperatureChange = -(CONFIG.coolingRate / 60) * deltaTime
	end

	-- Update temperature with limits
	room.temperature = math.clamp(
		room.temperature + temperatureChange,
		CONFIG.minTemperature,
		CONFIG.maxTemperature
	)

	-- Apply temperature effects to players in the room
	for player, _ in pairs(room.players) do
		-- Apply health regeneration
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			local humanoid = character.Humanoid

			-- Only restore health if not full
			if humanoid.Health < humanoid.MaxHealth then
				-- Scale regen rate with temperature (higher temp = faster regen)
				local tempFactor = (room.temperature - CONFIG.minTemperature) / 
					(CONFIG.maxTemperature - CONFIG.minTemperature)

				local regenAmount = CONFIG.healthRestoreRate * deltaTime * tempFactor
				humanoid.Health = math.min(humanoid.Health + regenAmount, humanoid.MaxHealth)
			end
		end

		-- Update player's temperature UI
		remotes.updateTemperature:FireClient(player, room.temperature)
	end

	return temperatureChange
end

-- Function to check player entry/exit from rooms
local function updatePlayerRoomStatus()
	for _, player in pairs(Players:GetPlayers()) do
		local currentRoom = findPlayerRoom(player)

		-- If player data doesn't exist, initialize it
		if not playerData[player] then
			playerData[player] = {
				currentRoom = nil,
				timeInSauna = 0
			}
		end

		local data = playerData[player]

		-- Player entered a new room
		if currentRoom and data.currentRoom ~= currentRoom then
			-- If leaving a room
			if data.currentRoom then
				data.currentRoom.players[player] = nil
				remotes.exitSauna:FireClient(player)
			end

			-- Enter new room
			data.currentRoom = currentRoom
			data.timeInSauna = 0
			currentRoom.players[player] = true
			remotes.enterSauna:FireClient(player, currentRoom.temperature)

			-- Reset their sauna time
			data.timeInSauna = 0

			-- Player left a room
		elseif not currentRoom and data.currentRoom then
			data.currentRoom.players[player] = nil
			data.currentRoom = nil
			remotes.exitSauna:FireClient(player)

			-- Player is still in the same room
		elseif currentRoom and data.currentRoom == currentRoom then
			data.timeInSauna = data.timeInSauna + 1
		end
	end
end

-- Main update loop
local function startTemperatureSystem()
	local lastUpdateTime = tick()

	while true do
		wait(1) -- Update every second

		local currentTime = tick()
		local deltaTime = currentTime - lastUpdateTime
		lastUpdateTime = currentTime

		-- Update player positions
		updatePlayerRoomStatus()

		-- Update temperature in all rooms
		for _, room in pairs(saunaRooms) do
			local temperatureChange = updateRoomTemperature(room, deltaTime)

			-- Debug output
			if temperatureChange ~= 0 then
				-- Only log significant changes
				if math.abs(temperatureChange) > 0.1 then
					--print(room.name .. " temperature: " .. string.format("%.1f", room.temperature) .. "°C")
				end
			end
		end
	end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if playerData[player] then
		local data = playerData[player]

		-- Remove from current room if they're in one
		if data.currentRoom then
			data.currentRoom.players[player] = nil
		end

		-- Clean up player data
		playerData[player] = nil
	end
end)

-- Functions to expose to other scripts
function TemperatureModule.getRoomTemperature(roomName)
	for _, room in pairs(saunaRooms) do
		if room.name == roomName then
			return room.temperature
		end
	end
	return CONFIG.minTemperature
end

function TemperatureModule.getHeaters()
	local allHeaters = {}
	for _, room in pairs(saunaRooms) do
		for _, heater in pairs(room.heaters) do
			table.insert(allHeaters, heater)
		end
	end
	return allHeaters
end

function TemperatureModule.getRooms()
	return saunaRooms
end

function TemperatureModule.setHeaterEnabled(heater, enabled)
	heater:SetAttribute("HeaterEnabled", enabled)
end

-- Initialize the system
local function initialize()
	-- Find all heaters and rooms
	local heaters = findSaunaHeaters()
	saunaRooms = findSaunaRooms()

	-- Assign heaters to rooms
	assignHeatersToRooms(heaters, saunaRooms)

	-- Start the update loop
	startTemperatureSystem()

	print("Sauna temperature system initialized")
end

-- Start everything
initialize()

-- Return the module for other scripts
return TemperatureModule