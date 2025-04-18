-- Fixed BuyTile System
-- Handles tile purchasing, gym part spawning, and animations
-- Place in ServerScriptService

-- Services
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration - Inline to avoid require errors
local CONFIG = {
	-- Folders
	buyTilesFolder = "BuyTiles", -- Folder in ServerStorage
	gymPartsFolder = "GymParts", -- Folder in ServerStorage

	-- Animation
	animationDuration = 1,      -- Duration in seconds
	animationStyle = Enum.EasingStyle.Sine,
	animationDirection = Enum.EasingDirection.Out,

	-- Sound
	purchaseSoundId = "rbxassetid://17245419579", -- Purchase sound
	errorSoundId = "rbxassetid://3201481530",     -- Not enough money sound

	-- Debug
	debug = true  -- Show debug prints
}

-- Try to load SystemConfig but don't fail if it doesn't exist
local success, SystemConfig = pcall(function()
	return require(game.ServerScriptService:FindFirstChild("SystemConfig"))
end)

if success and SystemConfig and SystemConfig.BuyTile then
	-- Merge config if available
	for key, value in pairs(SystemConfig.BuyTile) do
		CONFIG[key] = value
	end
	print("Loaded configuration from SystemConfig")
end

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[BuyTile]", ...)
	end
end

debugPrint("Initializing Buy Tile System...")

-- Find required folders
local BuyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
if not BuyTilesFolder then
	-- Check in Workspace if not found in ServerStorage
	BuyTilesFolder = workspace:FindFirstChild("BuyTiles")

	-- Create if it doesn't exist
	if not BuyTilesFolder then
		BuyTilesFolder = Instance.new("Folder")
		BuyTilesFolder.Name = "BuyTiles"
		BuyTilesFolder.Parent = ServerStorage
		debugPrint("Created missing BuyTiles folder in ServerStorage")
	end
end

local GymPartsFolder = ServerStorage:FindFirstChild("GymParts")
if not GymPartsFolder then
	-- Check in Workspace if not found in ServerStorage
	GymPartsFolder = workspace:FindFirstChild("GymParts")

	-- Create if it doesn't exist
	if not GymPartsFolder then
		GymPartsFolder = Instance.new("Folder")
		GymPartsFolder.Name = "GymParts"
		GymPartsFolder.Parent = ServerStorage
		debugPrint("Created missing GymParts folder in ServerStorage")
	end
end

-- Function to find a BuyTile by ID (cached for performance)
local tileCache = {}
local function findBuyTileByID(id)
	-- Return from cache if available
	if tileCache[id] then
		return tileCache[id]
	end

	debugPrint("Looking for BuyTile with ID: " .. id)

	-- Helper function to search recursively
	local function recursiveSearch(folder)
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Model") and item:GetAttribute("ID") == id then
				debugPrint("Found BuyTile with ID: " .. id .. " and Name: " .. item.Name)
				return item
			elseif item:IsA("Folder") then
				local found = recursiveSearch(item)
				if found then return found end
			end
		end
		return nil
	end

	-- Check BuyTilesFolder first
	local tile = nil
	if BuyTilesFolder then
		tile = recursiveSearch(BuyTilesFolder)
	end

	-- If not found, check if we need to create a default one
	if not tile and id == 1 then
		debugPrint("No buy tile with ID 1 found, creating default")

		-- Create a default buy tile
		local defaultTile = Instance.new("Model")
		defaultTile.Name = "DefaultBuyTile"

		-- Set attributes
		defaultTile:SetAttribute("ID", 1)
		defaultTile:SetAttribute("Price", 100)
		defaultTile:SetAttribute("Name", "First Tile")

		-- Create the BuyTilePart
		local buyTilePart = Instance.new("Part")
		buyTilePart.Name = "BuyTilePart"
		buyTilePart.Size = Vector3.new(4, 1, 4)
		buyTilePart.Position = Vector3.new(0, 0.5, 0)
		buyTilePart.Anchored = true
		buyTilePart.BrickColor = BrickColor.new("Bright green")
		buyTilePart.Parent = defaultTile

		-- Set as primary part
		defaultTile.PrimaryPart = buyTilePart

		-- Add to BuyTiles folder
		defaultTile.Parent = BuyTilesFolder

		tile = defaultTile
		debugPrint("Created default buy tile with ID 1")
	end

	-- Cache the result
	if tile then
		tileCache[id] = tile
		debugPrint("Cached BuyTile ID: " .. id)
	else
		debugPrint("Failed to find BuyTile with ID: " .. id)
	end

	return tile
end

-- Function to create a BillboardGui for a BuyTile
local function createBillboardGui(buyTilePart, name, price)
	-- Remove any existing BillboardGui
	local existingBillboard = buyTilePart:FindFirstChild("BillboardGui")
	if existingBillboard then
		existingBillboard:Destroy()
	end

	-- Create new BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "BillboardGui"
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 100 -- Add max distance to prevent disappearing
	billboardGui.Adornee = buyTilePart -- Explicitly set the adornee
	billboardGui.Parent = buyTilePart

	-- Create Frame with transparency
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.5
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.1, 0)
	uiCorner.Parent = frame

	-- Create TextLabel for Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)  -- Yellow text
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = "Buy " .. name
	nameLabel.Parent = frame

	-- Create TextLabel for Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)  -- Yellow text
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = "$" .. tostring(price)
	priceLabel.Parent = frame

	debugPrint("Created BillboardGui for: " .. name)
	return billboardGui
end

-- Function to create a Sound for a BuyTile
local function createSound(buyTilePart)
	-- Remove any existing Sound
	local existingSound = buyTilePart:FindFirstChild("PurchaseSound")
	if existingSound then
		existingSound:Destroy()
	end

	-- Create new Sound
	local sound = Instance.new("Sound")
	sound.Name = "PurchaseSound"
	sound.SoundId = CONFIG.purchaseSoundId
	sound.Volume = 1
	sound.Parent = buyTilePart

	return sound
end

-- Function to handle model appearance without animation
local function animateModelAppearance(model)
	if not model then return false end

	-- Just ensure the model has a primary part
	local primaryPart = model.PrimaryPart
	if not primaryPart then
		-- If no primary part, try to set one
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				primaryPart = part
				model.PrimaryPart = part
				debugPrint("Set " .. part.Name .. " as primary part for " .. model.Name)
				break
			end
		end

		if not primaryPart then
			debugPrint("Can't process model - no suitable part found for " .. model.Name)
			return false
		end
	end

	-- DO NOT modify transparency of ANY parts - this causes issues with glass
	-- Just log the position for debugging
	debugPrint("Model " .. model.Name .. " placed at position: " .. tostring(model:GetPivot().Position))
	return true
end

-- Function to spawn a BuyTile into the workspace
local function spawnBuyTile(id)
	local tile = findBuyTileByID(id)
	if not tile then
		debugPrint("ERROR: Could not find BuyTile with ID " .. tostring(id))
		return nil
	end

	-- Clone the tile
	local tileClone = tile:Clone()

	-- Set all parts to anchored
	for _, part in pairs(tileClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Add to workspace immediately with correct positioning
	tileClone.Parent = Workspace

	-- Find the BuyTilePart
	local buyTilePart = tileClone:FindFirstChild("BuyTilePart")
	if not buyTilePart then
		debugPrint("BuyTilePart missing in Buy Tile with ID:", id)
		-- Create it if it doesn't exist
		buyTilePart = Instance.new("Part")
		buyTilePart.Name = "BuyTilePart"
		buyTilePart.Size = Vector3.new(4, 1, 4)
		buyTilePart.Position = tileClone:GetPivot().Position
		buyTilePart.Anchored = true
		buyTilePart.BrickColor = BrickColor.new("Bright green")
		buyTilePart.Parent = tileClone
		tileClone.PrimaryPart = buyTilePart
	end

	-- Get name from the model attribute
	local tileName = tileClone:GetAttribute("Name") or "Wall"
	local tilePrice = tileClone:GetAttribute("Price") or 0

	-- Create BillboardGui and Sound
	createBillboardGui(buyTilePart, tileName, tilePrice)
	createSound(buyTilePart)

	-- Simply make the model visible (no animation)
	animateModelAppearance(tileClone)

	debugPrint("Spawned BuyTile ID:", id, "at position:", tostring(tileClone:GetPivot().Position))
	return tileClone
end

-- Function to find and spawn a Gym Part by ID
local function spawnGymPart(partId)
	local function recursiveSearch(folder)
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Model") and item:GetAttribute("ID") == partId then
				local partClone = item:Clone()

				-- Make sure all parts are anchored
				for _, part in pairs(partClone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
					end
				end

				-- Get the position before parenting
				local originalPosition = nil
				if partClone.PrimaryPart then
					originalPosition = partClone.PrimaryPart.Position
				end

				-- Parent to workspace
				partClone.Parent = Workspace

				-- Log position for debugging
				debugPrint("Spawned gym part " .. partId .. " at position: " .. tostring(partClone:GetPivot().Position))

				-- Simply ensure visibility
				animateModelAppearance(partClone)

				return partClone
			elseif item:IsA("Folder") then
				local found = recursiveSearch(item)
				if found then return found end
			end
		end
		return nil
	end

	-- Search in GymPartsFolder
	local part = recursiveSearch(GymPartsFolder)

	-- If not found, provide debug information
	if not part then
		debugPrint("Could not find gym part with ID: " .. partId)
	else
		debugPrint("Successfully spawned gym part with ID: " .. partId)
	end

	return part
end

local function removeUnwantedGUIs(player)
	-- Get player's tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	-- Look for all specific GUIs with the green text format
	for _, obj in pairs(tycoon.Value:GetDescendants()) do
		-- Look for "$0" style GUI and 0 Members GUI
		if obj:IsA("BillboardGui") and (obj.Name == "RevenueDisplay" or obj.Name == "DuesDisplayGui") then
			-- Check if this is the green GUI we want to remove
			local frame = obj:FindFirstChild("Frame")
			if frame then
				local duesLabel = frame:FindFirstChild("DuesLabel")
				local collectLabel = frame:FindFirstChild("CollectLabel")

				if duesLabel and collectLabel and 
					(string.find(collectLabel.Text, "[E] Collect") or 
						string.find(duesLabel.Text, "$0")) then

					print("Removing unwanted GUI: " .. obj.Name)
					obj:Destroy()
				end
			end
		end
	end
end

-- Function to setup front desk GUI
local function setupFrontDeskGUI(frontDesk, player)
	if not frontDesk or not player then return nil end

	debugPrint("Setting up DUES GUI for: " .. player.Name)
	removeUnwantedGUIs(player)
	-- Get main part
	local mainPart = nil
	if frontDesk:IsA("BasePart") then
		mainPart = frontDesk
	elseif frontDesk:IsA("Model") then
		mainPart = frontDesk.PrimaryPart or frontDesk:FindFirstChild("Counter")

		if not mainPart then
			for _, part in pairs(frontDesk:GetDescendants()) do
				if part:IsA("BasePart") then
					mainPart = part
					break
				end
			end
		end
	end

	if not mainPart then
		debugPrint("No suitable part found for Front Desk GUI")
		return nil
	end

	-- IMPORTANT: Remove ALL existing GUIs from this part (not just BillboardGui)
	for _, child in pairs(mainPart:GetChildren()) do
		if child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ScreenGui") then
			child:Destroy()
		end
	end

	-- Create dues-only BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DuesDisplayGui" -- Unique name to avoid conflicts
	billboardGui.Size = UDim2.new(3, 0, 2, 0) -- Adjusted size for more content
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 100
	billboardGui.Adornee = mainPart
	billboardGui.Active = true
	billboardGui.ClipsDescendants = true
	billboardGui.Parent = mainPart

	-- Create frame with black background and yellow border
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Gold border
	frame.Parent = billboardGui

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.05, 0)
	uiCorner.Parent = frame

	-- Create gym name label (top line)
	local gymNameLabel = Instance.new("TextLabel")
	gymNameLabel.Name = "GymNameLabel"
	gymNameLabel.Position = UDim2.new(0, 0, 0.05, 0)
	gymNameLabel.Size = UDim2.new(1, 0, 0.25, 0)
	gymNameLabel.BackgroundTransparency = 1
	gymNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
	gymNameLabel.TextScaled = true
	gymNameLabel.Font = Enum.Font.GothamBold
	gymNameLabel.Text = player.Name .. "'s Gym"
	gymNameLabel.Parent = frame

	-- Create "Membership Dues" header
	local duesHeaderLabel = Instance.new("TextLabel")
	duesHeaderLabel.Name = "DuesHeaderLabel"
	duesHeaderLabel.Position = UDim2.new(0, 0, 0.3, 0)
	duesHeaderLabel.Size = UDim2.new(1, 0, 0.2, 0)
	duesHeaderLabel.BackgroundTransparency = 1
	duesHeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
	duesHeaderLabel.TextScaled = true
	duesHeaderLabel.Font = Enum.Font.Gotham
	duesHeaderLabel.Text = "Membership Dues"
	duesHeaderLabel.Parent = frame

	-- Create dues amount label
	local duesLabel = Instance.new("TextLabel")
	duesLabel.Name = "DuesLabel"
	duesLabel.Position = UDim2.new(0, 0, 0.5, 0)
	duesLabel.Size = UDim2.new(1, 0, 0.25, 0)
	duesLabel.BackgroundTransparency = 1
	duesLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
	duesLabel.TextScaled = true
	duesLabel.Font = Enum.Font.GothamBold

	-- Get current dues
	local tycoon = player:FindFirstChild("Tycoon")
	local currentDues = 0
	if tycoon then
		currentDues = tycoon:GetAttribute("AccruedDues") or 0
	end

	duesLabel.Text = "$" .. currentDues
	duesLabel.Parent = frame

	-- Create "Collect Dues" text
	local collectLabel = Instance.new("TextLabel")
	collectLabel.Name = "CollectLabel"
	collectLabel.Position = UDim2.new(0, 0, 0.75, 0)
	collectLabel.Size = UDim2.new(1, 0, 0.2, 0)
	collectLabel.BackgroundTransparency = 1
	collectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectLabel.TextScaled = true
	collectLabel.Font = Enum.Font.Gotham
	collectLabel.Text = "[E] Collect Dues"
	collectLabel.Parent = frame

	-- Add proximity prompt if not exists
	if not mainPart:FindFirstChild("CollectionPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CollectionPrompt"
		prompt.ActionText = "Collect Membership Dues"
		prompt.ObjectText = player.Name .. "'s Gym"
		prompt.HoldDuration = 0.5
		prompt.RequiresLineOfSight = false
		prompt.Parent = mainPart

		-- Connect prompt to collection function
		prompt.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer ~= player then return end -- Only owner can collect

			-- Get tycoon reference
			local tycoon = player:FindFirstChild("Tycoon")
			if not tycoon then return end

			-- Check if player has accrued dues
			local accruedDues = tycoon:GetAttribute("AccruedDues") or 0

			if accruedDues > 0 then
				-- Add to player's cash
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Cash") then
					leaderstats.Cash.Value = leaderstats.Cash.Value + accruedDues

					-- Reset accrued dues
					tycoon:SetAttribute("AccruedDues", 0)

					-- Update display
					duesLabel.Text = "$0"

					-- Play collection sound
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://142472270" -- Cash register sound
					sound.Volume = 1
					sound.Parent = mainPart
					sound:Play()
					game:GetService("Debris"):AddItem(sound, 3)

					-- Show message to player
					local message = Instance.new("Message")
					message.Text = "Collected $" .. accruedDues .. " in membership dues!"
					message.Parent = player
					game:GetService("Debris"):AddItem(message, 3)

					-- Fire event for other systems
					local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
					if EventBridge then
						local duesEvent = EventBridge:FindFirstChild("DuesCollected")
						if duesEvent then
							duesEvent:Fire(player, accruedDues)
						end
					end
				end
			else
				-- Play empty sound
				local emptySound = Instance.new("Sound")
				emptySound.SoundId = CONFIG.errorSoundId
				emptySound.Volume = 0.8
				emptySound.Parent = mainPart
				emptySound:Play()
				game:GetService("Debris"):AddItem(emptySound, 2)

				-- Notify player
				local message = Instance.new("Message")
				message.Text = "No membership dues to collect yet!"
				message.Parent = player
				game:GetService("Debris"):AddItem(message, 3)
			end
		end)
	end

	-- Set up periodic updates
	spawn(function()
		while mainPart and mainPart.Parent do
			wait(3) -- Update every 3 seconds

			-- Get current dues
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon then
				local currentDues = tycoon:GetAttribute("AccruedDues") or 0

				-- Update label if it exists
				if duesLabel and duesLabel.Parent then
					duesLabel.Text = "$" .. currentDues
				else
					-- GUI was removed, terminate the loop
					break
				end
			end
		end
	end)

	return billboardGui
end

-- Function to remove all revenue GUIs
local function removeAllRevenueGUIs(player)
	if not player then return end

	-- First check Player's PlayerGui for RevenueDisplayGui
	for _, guiItem in ipairs(player.PlayerGui:GetChildren()) do
		if guiItem.Name == "RevenueDisplayGui" then
			debugPrint("Found RevenueDisplayGui in PlayerGui - this is the official GUI")
			-- This is the correct one in PlayerGui, don't touch it
		end
	end

	-- Now find and remove ALL revenue-related GUIs in the WORKSPACE
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BillboardGui") and 
			(obj.Name == "RevenueDisplay" or 
				string.find(string.lower(obj.Name), "revenue") or
				string.find(string.lower(obj.Name), "gym revenue")) then

			debugPrint("REMOVING revenue GUI from workspace: " .. obj:GetFullName())
			obj:Destroy()
		end

		-- Also check for any ScreenGuis that might be revenue displays
		if obj:IsA("ScreenGui") and 
			(obj.Name == "RevenueDisplay" or 
				string.find(string.lower(obj.Name), "revenue")) then

			debugPrint("REMOVING revenue ScreenGui from workspace: " .. obj:GetFullName())
			obj:Destroy()
		end
	end

	-- Remove revenue GUIs from anywhere in the player's tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	for _, obj in ipairs(tycoon.Value:GetDescendants()) do
		if (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") or obj:IsA("ScreenGui")) and
			(obj.Name == "RevenueDisplay" or 
				string.find(string.lower(obj.Name), "revenue") or
				string.find(string.lower(obj.Name), "gym revenue")) then

			debugPrint("REMOVING revenue GUI from tycoon: " .. obj:GetFullName())
			obj:Destroy()
		end
	end
end

-- Function to clean up duplicate front desks
local function cleanupDuplicateFrontDesks(player)
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	-- Get all front desk-like models
	local frontDesks = {}
	for _, child in ipairs(tycoon.Value:GetChildren()) do
		if child:IsA("Model") and 
			(child.Name == "Front Desk" or 
				string.find(string.lower(child.Name), "front") or
				string.find(string.lower(child.Name), "desk") or
				string.find(string.lower(child.Name), "counter")) then

			table.insert(frontDesks, child)
		end
	end

	-- If more than one, keep only the one at the correct position or the first one
	if #frontDesks > 1 then
		debugPrint("Found " .. #frontDesks .. " front desk models, cleaning up")

		-- Try to find one at the specified position
		local keptDesk = nil
		for _, desk in ipairs(frontDesks) do
			local position = desk:GetPivot().Position
			-- Check if it's near the target position (-164.467, 2.201, 118.141)
			if math.abs(position.X + 164.467) < 10 and 
				math.abs(position.Y - 2.201) < 5 and
				math.abs(position.Z - 118.141) < 10 then

				keptDesk = desk
				break
			end
		end

		-- If none at that position, keep the first one
		if not keptDesk then
			keptDesk = frontDesks[1]
		end

		-- Remove the others
		for _, desk in ipairs(frontDesks) do
			if desk ~= keptDesk then
				desk:Destroy()
			end
		end

		-- Rename the kept one to "Front Desk" if needed
		if keptDesk.Name ~= "Front Desk" then
			keptDesk.Name = "Front Desk"
		end

		debugPrint("Kept front desk at position: " .. tostring(keptDesk:GetPivot().Position))
	end
end

-- Function to ensure a player's tycoon reference is valid
local function ensurePlayerTycoon(player)
	if not player then return nil end

	-- Check if player has Tycoon value
	local tycoonValue = player:FindFirstChild("Tycoon")
	if not tycoonValue then
		tycoonValue = Instance.new("ObjectValue")
		tycoonValue.Name = "Tycoon"
		tycoonValue.Parent = player
		debugPrint("Created Tycoon value for " .. player.Name)
	end

	-- Check if the Tycoon value is valid
	if not tycoonValue.Value or not tycoonValue.Value:IsA("Model") then
		-- Try to find the player's tycoon in the workspace
		local tycoonName = player.Name .. "'s Gym"
		local tycoon = nil

		-- Check in Tycoons folder if it exists
		local tycoonsFolder = Workspace:FindFirstChild("Tycoons")
		if tycoonsFolder then
			tycoon = tycoonsFolder:FindFirstChild(tycoonName)
		end

		-- Check in workspace if not found
		if not tycoon then
			tycoon = Workspace:FindFirstChild(tycoonName)
		end

		-- Set the value if found
		if tycoon then
			tycoonValue.Value = tycoon
			debugPrint("Found and set existing tycoon for " .. player.Name)
		end
	end

	return tycoonValue.Value
end

-- Function to find a front desk at a specific position or create one
local function spawnFrontDesk(player)
	if not player then return nil end

	debugPrint("Setting up front desk for " .. player.Name)

	-- Get player's tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		debugPrint("Player has no valid tycoon")
		return nil
	end

	-- First try to find existing front desk by name
	local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
	local frontDeskCreated = false

	if frontDesk then
		debugPrint("Found existing front desk named 'Front Desk' at position: " .. tostring(frontDesk:GetPivot().Position))
	else
		-- Look for a model at the specific position: (-164.467, 2.201, 118.141)
		-- or nearby within a reasonable tolerance
		local targetPos = Vector3.new(-164.467, 2.201, 118.141)
		local closestModel = nil
		local closestDistance = 20 -- Max distance to consider as "at the position"

		for _, obj in ipairs(tycoon.Value:GetDescendants()) do
			if obj:IsA("Model") or obj:IsA("BasePart") then
				local pos = obj:GetPivot().Position
				local distance = (pos - targetPos).Magnitude

				if distance < closestDistance then
					closestDistance = distance
					closestModel = obj
				end
			end
		end

		-- If we found something close to that position, use it
		if closestModel then
			-- If it's a part, create a model around it
			if closestModel:IsA("BasePart") then
				frontDesk = Instance.new("Model")
				frontDesk.Name = "Front Desk"
				frontDesk.PrimaryPart = closestModel
				closestModel.Parent = frontDesk
				frontDesk.Parent = tycoon.Value
				debugPrint("Created Front Desk model around existing part at: " .. tostring(closestModel.Position))
			else
				frontDesk = closestModel
				frontDesk.Name = "Front Desk"
				debugPrint("Using existing model at the target position as Front Desk: " .. tostring(frontDesk:GetPivot().Position))
			end
		else
			-- Create a new one at the target position
			frontDesk = Instance.new("Model")
			frontDesk.Name = "Front Desk"

			-- Create the main part
			local mainPart = Instance.new("Part")
			mainPart.Name = "Counter"
			mainPart.Size = Vector3.new(4, 2, 2)
			mainPart.BrickColor = BrickColor.new("Dark stone grey")
			mainPart.Material = Enum.Material.SmoothPlastic
			mainPart.Anchored = true
			mainPart.CanCollide = true
			mainPart.Parent = frontDesk

			-- Set primary part
			frontDesk.PrimaryPart = mainPart

			-- Use the specific position you mentioned
			mainPart.CFrame = CFrame.new(targetPos)

			-- Add to tycoon
			frontDesk.Parent = tycoon.Value

			frontDeskCreated = true
			debugPrint("Created new front desk at target position: " .. tostring(targetPos))
		end
	end

	-- Remove ALL revenue GUIs before setting up the correct one
	removeAllRevenueGUIs(player)

	-- Set up the billboard GUI for the front desk
	setupFrontDeskGUI(frontDesk, player)

	return frontDesk
end

-- Function to update all front desks for existing players
local function updateAllFrontDesks()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			-- First, remove ALL revenue-related GUIs to start with a clean slate
			removeAllRevenueGUIs(player)

			-- Clean up any duplicate front desks
			cleanupDuplicateFrontDesks(player)

			-- Check if player has a front desk, if not create one
			local tycoon = player:FindFirstChild("Tycoon")
			if tycoon and tycoon.Value then
				local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
				if frontDesk then
					-- Update the GUI
					setupFrontDeskGUI(frontDesk, player)
					debugPrint("Updated front desk GUI for " .. player.Name)
				else
					-- Create a new front desk if needed
					frontDesk = spawnFrontDesk(player)
					if frontDesk then
						debugPrint("Created new front desk for " .. player.Name)
					end
				end
			end
		end)
	end
end

-- Function to handle buying logic
local function handleTilePurchase(buyTile)
	local id = buyTile:GetAttribute("ID")
	local price = buyTile:GetAttribute("Price")

	-- Get name or use default
	local name = buyTile:GetAttribute("Name") or "Wall"

	if not id or not price then
		debugPrint("ERROR: Buy Tile is missing required attributes (ID, Price)")
		return
	end

	local buyTilePart = buyTile:FindFirstChild("BuyTilePart")
	if not buyTilePart then
		debugPrint("BuyTilePart missing in Buy Tile with ID:", id)
		return
	end

	-- Make sure the BillboardGui exists
	if not buyTilePart:FindFirstChild("BillboardGui") then
		createBillboardGui(buyTilePart, name, price)
	end

	-- Make sure the Sound exists
	if not buyTilePart:FindFirstChild("PurchaseSound") then
		createSound(buyTilePart)
	end

	local debounce = false

	buyTilePart.Touched:Connect(function(hit)
		if debounce then return end

		-- Find the player who touched the part
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		debounce = true

		-- Check if player has leaderstats and Cash stat
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats or not leaderstats:FindFirstChild("Cash") then
			debugPrint(player.Name .. " does not have proper leaderstats!")
			debounce = false
			return
		end

		local cashStat = leaderstats.Cash

		-- Check if player has enough cash
		if cashStat.Value >= price then
			-- Deduct cash
			cashStat.Value = cashStat.Value - price
			debugPrint(player.Name .. " purchased BuyTile " .. id)

			-- Immediately remove from workspace to prevent double purchasing
			buyTile.Parent = nil

			-- Play the sound effect
			local sound = buyTilePart:FindFirstChild("PurchaseSound")
			if sound then
				-- Clone the sound to ensure it plays completely
				local soundClone = sound:Clone()
				soundClone.Parent = workspace
				soundClone:Play()
				game:GetService("Debris"):AddItem(soundClone, 3)
			end

			-- First tile purchase is special - create front desk
			if id == 1 then
				task.spawn(function()
					-- Ensure player has a valid tycoon
					local tycoon = ensurePlayerTycoon(player)

					-- Create front desk and set up GUI
					debugPrint("First tile purchased, setting up front desk for " .. player.Name)
					local desk = spawnFrontDesk(player)

					if desk then
						debugPrint("Front desk GUI set up successfully for " .. player.Name)
					else
						debugPrint("Failed to set up front desk for " .. player.Name)
					end
				end)
			end

			-- Try to use GymTycoonConnector
			if _G.GymTycoonConnector and _G.GymTycoonConnector.onTilePurchased then
				_G.GymTycoonConnector.onTilePurchased(player, id)
				debugPrint("Notified GymTycoonConnector about purchase")
			else
				-- Fallback handling
				debugPrint("GymTycoonConnector not found, using fallback")

				-- Update equipment count
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
					tycoon:SetAttribute("EquipmentCount", equipmentCount + 1)
				end

				-- Fire event
				local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
				if EventBridge then
					local tileEvent = EventBridge:FindFirstChild("TilePurchased")
					if tileEvent then
						tileEvent:Fire(player, id)
					end
				end
			end

			-- Spawn corresponding Gym Part
			task.spawn(function()
				local gymPartSpawned = spawnGymPart(id)
				if gymPartSpawned then
					debugPrint("Gym Part spawned for ID:", id)
				else
					debugPrint("Failed to spawn Gym Part for ID:", id)
				end
			end)

			-- Spawn the next Buy Tile
			task.spawn(function()
				local nextID = id + 1
				local nextTile = spawnBuyTile(nextID)

				if nextTile then
					debugPrint("Spawned next BuyTile ID:", nextID)
					handleTilePurchase(nextTile)
				else
					debugPrint("Failed to find next Buy Tile with ID:", nextID)
				end
			end)

		else
			debugPrint(player.Name .. " does not have enough Cash! Needed:", price, "Has:", cashStat.Value)

			-- Play error sound
			local failSound = Instance.new("Sound")
			failSound.SoundId = CONFIG.errorSoundId
			failSound.Volume = 1
			failSound.Parent = workspace
			failSound:Play()
			game:GetService("Debris"):AddItem(failSound, 2)
		end

		-- Reset debounce after a short delay to prevent spam
		task.delay(1, function()
			debounce = false
		end)
	end)
end

-- Function to create the EventBridge if it doesn't exist
local function ensureEventBridge()
	local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not EventBridge then
		EventBridge = Instance.new("Folder")
		EventBridge.Name = "EventBridge"
		EventBridge.Parent = ReplicatedStorage
		debugPrint("Created EventBridge folder in ReplicatedStorage")
	end

	-- Create essential events
	local eventNames = {"TilePurchased", "DuesCollected", "GymLevelUp"}

	for _, eventName in ipairs(eventNames) do
		if not EventBridge:FindFirstChild(eventName) then
			local event = Instance.new("BindableEvent")
			event.Name = eventName
			event.Parent = EventBridge
			debugPrint("Created " .. eventName .. " event")
		end
	end

	return EventBridge
end

-- Function to create a minimal GymTycoonConnector if needed
local function ensureGymTycoonConnector()
	if not _G.GymTycoonConnector then
		debugPrint("GymTycoonConnector not found, creating minimal version")

		_G.GymTycoonConnector = {
			onTilePurchased = function(player, tileId)
				debugPrint("Tile " .. tileId .. " purchased by " .. player.Name)

				-- Update equipment count
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
					tycoon:SetAttribute("EquipmentCount", equipmentCount + 1)
				end

				-- Handle special cases
				if tileId == 1 then
					-- Mark player as having started their tycoon
					if tycoon then
						tycoon:SetAttribute("TycoonStarted", true)
					end
				end

				-- Fire event for other systems
				local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
				if EventBridge then
					local tileEvent = EventBridge:FindFirstChild("TilePurchased")
					if tileEvent then
						tileEvent:Fire(player, tileId)
					end
				end
			end
		}
	end

	return _G.GymTycoonConnector
end

-- Function to spawn the initial buy tile
local function spawnInitialBuyTile()
	debugPrint("Attempting to spawn initial BuyTile with ID: 1")

	local tile = spawnBuyTile(1)
	if tile then
		debugPrint("Successfully spawned initial BuyTile with ID: 1")
		handleTilePurchase(tile)
	else
		debugPrint("Failed to spawn initial BuyTile with ID: 1 - creating emergency tile")

		-- Create emergency buy tile directly in workspace
		local emergencyTile = Instance.new("Model")
		emergencyTile.Name = "EmergencyBuyTile"

		-- Set attributes
		emergencyTile:SetAttribute("ID", 1)
		emergencyTile:SetAttribute("Price", 100)
		emergencyTile:SetAttribute("Name", "Membership Desk")

		-- Create the BuyTilePart
		local buyTilePart = Instance.new("Part")
		buyTilePart.Name = "BuyTilePart"
		buyTilePart.Size = Vector3.new(4, 1, 4)
		buyTilePart.Position = Vector3.new(0, 0.5, 0)
		buyTilePart.Anchored = true
		buyTilePart.BrickColor = BrickColor.new("Really blue")
		buyTilePart.Parent = emergencyTile

		-- Set as primary part
		emergencyTile.PrimaryPart = buyTilePart

		-- Add directly to workspace
		emergencyTile.Parent = workspace

		-- Create billboard GUI
		createBillboardGui(buyTilePart, "Membership Desk", 100)
		createSound(buyTilePart)

		-- Set up purchase handling
		handleTilePurchase(emergencyTile)

		debugPrint("Created emergency buy tile directly in workspace")
	end
end

-- Initialize system
debugPrint("Starting Buy Tile system initialization")

-- Ensure event bridge exists
ensureEventBridge()

-- Ensure GymTycoonConnector exists
ensureGymTycoonConnector()

-- Clean up and update front desks for existing players
spawn(function()
	wait(1) -- Wait for the system to fully load
	updateAllFrontDesks()
end)

-- Spawn the initial buy tile
spawnInitialBuyTile()

debugPrint("Buy Tile system initialization complete")

-- Return public API
return {
	spawnBuyTile = spawnBuyTile,
	spawnGymPart = spawnGymPart,
	animateModelAppearance = animateModelAppearance,
	createFrontDesk = spawnFrontDesk,
	setupFrontDeskGUI = setupFrontDeskGUI,
	updateAllFrontDesks = updateAllFrontDesks,
	handleTilePurchase = handleTilePurchase
}