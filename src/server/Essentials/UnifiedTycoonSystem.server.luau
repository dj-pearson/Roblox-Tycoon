-- UnifiedTycoonSystem.lua
-- A consolidated system for creating, managing, and assigning tycoons to players
-- Place in ServerScriptService

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")


-- Load Economy System
local EconomySystem
pcall(function()
	EconomySystem = require(ServerScriptService:FindFirstChild("UnifiedGymEconomySystem"))
end)

-- Load Front Desk System
local FrontDeskSystem
pcall(function()
	FrontDeskSystem = require(ServerScriptService:FindFirstChild("UnifiedFrontDeskSystem"))
end)

-- Configuration
local CONFIG = {
	-- Tycoon layout
	tycoonSpacing = 50,         -- Space between tycoons
	basePosition = Vector3.new(0, 0, 0),  -- Starting position for the grid
	createTycoonsFolder = true, -- Whether to create a dedicated folder

	-- Visual properties
	platformSize = Vector3.new(40, 1, 40),  -- Base platform size
	platformColor = BrickColor.new("Medium stone grey"),
	platformMaterial = Enum.Material.Concrete,

	-- Sign properties
	signSize = Vector3.new(20, 5, 1),
	signColor = BrickColor.new("Bright blue"),
	signTextColor = Color3.new(1, 1, 1),

	-- Animation
	appearanceDuration = 1.2,
	appearanceStyle = Enum.EasingStyle.Bounce,
	appearanceDirection = Enum.EasingDirection.Out,

	-- Maintenance
	validationInterval = 30,  -- How often to check tycoon validity (seconds)
	playerCheckDelay = 5      -- Delay before checking new players (seconds)
}

-- Create a Tycoons folder if specified
local tycoonsFolder
if CONFIG.createTycoonsFolder then
	tycoonsFolder = Workspace:FindFirstChild("Tycoons")
	if not tycoonsFolder then
		tycoonsFolder = Instance.new("Folder")
		tycoonsFolder.Name = "Tycoons"
		tycoonsFolder.Parent = Workspace
		print("Created Tycoons folder in Workspace")
	end
end

-- Function to find a player's existing tycoon
local function findPlayerTycoon(player)
	print("Looking for tycoon for: " .. player.Name)

	-- First check the player's Tycoon value
	local tycoonValue = player:FindFirstChild("Tycoon")
	if tycoonValue and tycoonValue.Value and tycoonValue.Value:IsA("Model") then
		if tycoonValue.Value ~= player.Character then  -- Ensure it's not set to their character
			print("Found tycoon in player's Tycoon value: " .. tycoonValue.Value:GetFullName())
			return tycoonValue.Value
		end
	end

	-- Check in Tycoons folder if it exists
	local tycoonName = player.Name .. "'s Gym"
	if tycoonsFolder then
		local tycoon = tycoonsFolder:FindFirstChild(tycoonName)
		if tycoon then
			print("Found tycoon in Tycoons folder: " .. tycoon:GetFullName())
			return tycoon
		end

		-- Try partial name match in Tycoons folder
		for _, model in pairs(tycoonsFolder:GetChildren()) do
			if model:IsA("Model") and string.find(model.Name, player.Name) then
				print("Found tycoon with partial name match in Tycoons folder: " .. model:GetFullName())
				return model
			end
		end
	end

	-- Check in Workspace directly
	local tycoon = Workspace:FindFirstChild(tycoonName)
	if tycoon then
		print("Found tycoon in workspace: " .. tycoon:GetFullName())
		return tycoon
	end

	-- Try partial name match in workspace
	for _, model in pairs(Workspace:GetChildren()) do
		if model:IsA("Model") and string.find(model.Name, player.Name) and string.find(model.Name, "Gym") then
			print("Found tycoon with partial name match in workspace: " .. model:GetFullName())
			return model
		end
	end

	-- Deep search in the whole workspace
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and string.find(obj.Name, player.Name) and string.find(obj.Name, "Gym") then
			print("Found tycoon in deeper hierarchy: " .. obj:GetFullName())
			return obj
		end
	end

	print("No existing tycoon found for " .. player.Name)
	return nil
end

-- Function to animate a model's appearance
local function animateModelAppearance(model)
	if not model or not model:IsA("Model") then return end

	-- Find all parts in the model
	local parts = {}
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)

			-- Store original properties and prepare for animation
			part:SetAttribute("OriginalPos", part.Position)
			part:SetAttribute("OriginalTransparency", part.Transparency)

			-- Set initial state
			part.Transparency = 1
			part.Position = part.Position - Vector3.new(0, 5, 0)
		end
	end

	-- Animate parts
	for _, part in ipairs(parts) do
		-- Create position tween
		local posInfo = TweenInfo.new(
			CONFIG.appearanceDuration,
			CONFIG.appearanceStyle,
			CONFIG.appearanceDirection
		)

		local posGoal = {
			Position = part:GetAttribute("OriginalPos")
		}

		local posTween = TweenService:Create(part, posInfo, posGoal)
		posTween:Play()

		-- Create transparency tween
		local transInfo = TweenInfo.new(
			CONFIG.appearanceDuration * 0.8,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		)

		local transGoal = {
			Transparency = part:GetAttribute("OriginalTransparency") or 0
		}

		local transTween = TweenService:Create(part, transInfo, transGoal)
		transTween:Play()
	end
end

local function createNewTycoon(player)
	print("Creating new tycoon for " .. player.Name)

	-- Get the tycoon template if it exists
	local tycoonTemplate = ServerStorage:FindFirstChild("TycoonTemplate")
	local newTycoon

	if tycoonTemplate and tycoonTemplate:IsA("Model") then
		newTycoon = tycoonTemplate:Clone()
	else
		-- Create a new model from scratch
		newTycoon = Instance.new("Model")

		-- Create the base platform
		local platform = Instance.new("Part")
		platform.Name = "Platform"
		platform.Size = CONFIG.platformSize
		platform.BrickColor = CONFIG.platformColor
		platform.Material = CONFIG.platformMaterial
		platform.Anchored = true
		platform.CanCollide = true
		platform.Parent = newTycoon

		-- Set the platform as PrimaryPart
		newTycoon.PrimaryPart = platform

		-- We're removing the sign creation to avoid the eyesore
	end

	-- Name the tycoon
	newTycoon.Name = player.Name .. "'s Gym"

	-- Find a suitable position
	local position
	local tycoonCount = 0

	if tycoonsFolder then
		tycoonCount = #tycoonsFolder:GetChildren()
	else
		-- Count existing tycoons in workspace
		for _, obj in pairs(Workspace:GetChildren()) do
			if obj:IsA("Model") and string.find(obj.Name, "'s Gym") then
				tycoonCount = tycoonCount + 1
			end
		end
	end

	-- Calculate grid position based on count
	local gridSize = math.ceil(math.sqrt(tycoonCount + 1))
	local row = math.floor(tycoonCount / gridSize)
	local col = tycoonCount % gridSize

	position = CONFIG.basePosition + Vector3.new(
		col * CONFIG.tycoonSpacing, 
		0, 
		row * CONFIG.tycoonSpacing
	)

	-- Position the tycoon
	if newTycoon.PrimaryPart then
		newTycoon:SetPrimaryPartCFrame(CFrame.new(position))
	else
		-- Find a part to use if no primary part
		for _, part in pairs(newTycoon:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Position = part.Position + position
			end
		end
	end

	-- Parent the tycoon
	if tycoonsFolder then
		newTycoon.Parent = tycoonsFolder
	else
		newTycoon.Parent = Workspace
	end

	-- Animate the appearance
	animateModelAppearance(newTycoon)

	print("Created new tycoon at position: " .. tostring(position))
	return newTycoon
end

-- Function to ensure player has a valid Tycoon object value
local function ensureTycoonValue(player)
	local tycoonValue = player:FindFirstChild("Tycoon")
	if not tycoonValue then
		tycoonValue = Instance.new("ObjectValue")
		tycoonValue.Name = "Tycoon"
		tycoonValue.Parent = player
		print("Created Tycoon value for " .. player.Name)
	end
	return tycoonValue
end

-- Function to ensure player has a valid tycoon
local function ensurePlayerTycoon(player)
	print("Ensuring tycoon for " .. player.Name)

	-- Get or create the Tycoon value
	local tycoonValue = ensureTycoonValue(player)

	-- Check if Tycoon value already points to something valid
	if tycoonValue.Value and tycoonValue.Value:IsA("Model") and tycoonValue.Value.Parent ~= nil then
		-- Make sure it's not the player's character (which was a bug)
		if tycoonValue.Value == player.Character then
			print("ERROR: Tycoon value incorrectly set to player character for " .. player.Name)
			tycoonValue.Value = nil -- Reset the value
		else
			print("Tycoon value already set to: " .. tycoonValue.Value:GetFullName())
			return tycoonValue.Value
		end
	end

	-- Find or create the player's tycoon
	local tycoon = findPlayerTycoon(player)

	if not tycoon then
		tycoon = createNewTycoon(player)
	end

	-- Set the Tycoon value
	tycoonValue.Value = tycoon
	print("Set Tycoon value to: " .. tycoon:GetFullName())

	-- Initialize tycoon attributes via the economy system if available
	if EconomySystem then
		-- Let the economy system handle initialization
	else
		-- Fallback initialization if economy system not available
		if not tycoonValue:GetAttribute("AccruedDues") then
			tycoonValue:SetAttribute("AccruedDues", 0)
		end

		if not tycoonValue:GetAttribute("GymLevel") then
			tycoonValue:SetAttribute("GymLevel", 1)
		end

		if not tycoonValue:GetAttribute("EquipmentCount") then
			tycoonValue:SetAttribute("EquipmentCount", 0)
		end

		if not tycoonValue:GetAttribute("RebirthCount") then
			tycoonValue:SetAttribute("RebirthCount", 0)
		end
	end

	-- Make sure tycoon has an NPCs folder
	if not tycoon:FindFirstChild("NPCs") then
		local npcFolder = Instance.new("Folder")
		npcFolder.Name = "NPCs"
		npcFolder.Parent = tycoon
		print("Added NPCs folder to tycoon")
	end

	return tycoon
end

-- Function to handle when a player joins
local function onPlayerJoin(player)
	-- Wait a moment for the player to fully load
	task.delay(CONFIG.playerCheckDelay, function()
		local tycoon = ensurePlayerTycoon(player)
		print("Tycoon setup complete for " .. player.Name)

		-- Set up character tracking to fix issues with character being set as tycoon
		player.CharacterAdded:Connect(function(character)
			task.delay(1, function()
				local tycoonValue = player:FindFirstChild("Tycoon")
				if tycoonValue and tycoonValue.Value == character then
					print("FIXING: Tycoon incorrectly set to character for " .. player.Name)

					-- Find the correct tycoon
					local correctTycoon = findPlayerTycoon(player)
					if correctTycoon then
						tycoonValue.Value = correctTycoon
					else
						-- Create a new one if not found
						tycoonValue.Value = createNewTycoon(player)
					end
				end
			end)
		end)
	end)
end

-- Function to run periodic validation to ensure tycoons remain valid
local function startTycoonValidation()
	while true do
		task.wait(CONFIG.validationInterval)

		print("Running periodic tycoon validation check")
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function()
				local tycoonValue = player:FindFirstChild("Tycoon")

				-- Check if tycoon is invalid
				if not tycoonValue or not tycoonValue.Value or not tycoonValue.Value.Parent then
					print("Found invalid tycoon for " .. player.Name .. ", fixing...")
					ensurePlayerTycoon(player)
				elseif tycoonValue.Value == player.Character then
					print("Found tycoon set to character for " .. player.Name .. ", fixing...")

					local correctTycoon = findPlayerTycoon(player)
					if correctTycoon and correctTycoon ~= player.Character then
						tycoonValue.Value = correctTycoon
					else
						tycoonValue.Value = createNewTycoon(player)
					end
				end
			end)
		end
	end
end

-- Set up existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerJoin(player)
	end)
end

-- Connect to PlayerAdded event
Players.PlayerAdded:Connect(onPlayerJoin)

-- Start periodic validation
task.spawn(startTycoonValidation)

print("=== Unified Tycoon System Initialized ===")

-- Return the module with public functions
return {
	ensurePlayerTycoon = ensurePlayerTycoon,
	findPlayerTycoon = findPlayerTycoon,
	createNewTycoon = createNewTycoon
}