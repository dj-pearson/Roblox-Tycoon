-- EnhancedFrontDeskSystem.lua
-- Improved front desk system with better UI and functionality
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Load dependencies
local DataStorage
local SystemConfig
local PlayerDataManager

pcall(function()
	DataStorage = require(ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"))
end)

pcall(function()
	SystemConfig = require(ReplicatedStorage:FindFirstChild("SystemConfig"))
end)

pcall(function()
	PlayerDataManager = require(ServerScriptService:FindFirstChild("PlayerDataManager"))
end)

-- Configuration
local CONFIG = {
	-- Front desk settings
	frontDeskId = 1,                  -- ID of the front desk part
	collectionCooldown = 60,          -- Seconds between collections
	minCollectionAmount = 50,         -- Minimum amount to collect

	-- UI settings
	guiOffset = Vector3.new(0, 3, 0), -- Billboard GUI offset
	guiSize = UDim2.new(3, 0, 2, 0),  -- Billboard GUI size
	textColor = Color3.fromRGB(255, 255, 0), -- Text color
	backgroundColor = Color3.fromRGB(0, 0, 0), -- Background color
	backgroundTransparency = 0.5,     -- Background transparency
	animatedText = true,              -- Animate text when dues increase

	-- Effects
	collectionSound = "rbxassetid://131323304", -- Sound when collecting dues
	collectionParticles = true,       -- Show particles when collecting

	-- Debug settings
	debug = true                      -- Enable debug logging
}

-- Override with SystemConfig if available
if SystemConfig and SystemConfig.FrontDesk then
	for key, value in pairs(SystemConfig.FrontDesk) do
		CONFIG[key] = value
	end
end

-- Module table
local FrontDeskSystem = {
	frontDesks = {},     -- Player front desks
	lastCollection = {}, -- Track last collection time per player
	initialized = false
}

-- Debug logger
local function log(...)
	if CONFIG.debug then
		print("[FrontDeskSystem]", ...)
	end
end

-- Format currency with commas
local function formatCurrency(amount)
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return "$" .. formatted
end

-- Initialize sound effects
local function initSoundEffect()
	if not SoundService:FindFirstChild("CollectionSound") then
		local sound = Instance.new("Sound")
		sound.Name = "CollectionSound"
		sound.SoundId = CONFIG.collectionSound
		sound.Volume = 0.8
		sound.Parent = SoundService
		log("Created collection sound effect")
	end
end

-- Create or update the front desk GUI for a player
function FrontDeskSystem.createFrontDeskGui(frontDesk, player)
	if not frontDesk or not player then return nil end

	-- Remove existing GUI if present
	local existingGui = frontDesk:FindFirstChild("BillboardGui")
	if existingGui then
		existingGui:Destroy()
	end

	-- Create new billboard GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "BillboardGui"
	billboardGui.Size = CONFIG.guiSize
	billboardGui.StudsOffset = CONFIG.guiOffset
	billboardGui.Adornee = frontDesk
	billboardGui.Parent = frontDesk

	-- Create background frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = CONFIG.backgroundColor
	frame.BackgroundTransparency = CONFIG.backgroundTransparency
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	-- Create gym name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "GymNameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = CONFIG.textColor
	nameLabel.TextScaled = true
	nameLabel.Text = player.Name .. "'s Gym"
	nameLabel.Parent = frame

	-- Create dues label
	local duesLabel = Instance.new("TextLabel")
	duesLabel.Name = "DuesLabel"
	duesLabel.Size = UDim2.new(1, 0, 0.3, 0)
	duesLabel.Position = UDim2.new(0, 0, 0.3, 0)
	duesLabel.BackgroundTransparency = 1
	duesLabel.Font = Enum.Font.GothamBold
	duesLabel.TextColor3 = CONFIG.textColor
	duesLabel.TextScaled = true
	duesLabel.Parent = frame

	-- Create status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0.2, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.65, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextColor3 = CONFIG.textColor
	statusLabel.TextScaled = true
	statusLabel.Text = "Ready to collect!"
	statusLabel.Parent = frame

	-- Create proximity prompt for collection
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "CollectPrompt"
	proximityPrompt.ObjectText = "Membership Dues"
	proximityPrompt.ActionText = "Collect"
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.Parent = frontDesk

	-- Connect the prompt
	proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			FrontDeskSystem.collectDues(player)
		else
			-- Show message for other players
			local message = Instance.new("Message")
			message.Text = "This is " .. player.Name .. "'s gym. You can only collect dues from your own gym."
			message.Parent = playerWhoTriggered
			game:GetService("Debris"):AddItem(message, 3)
		end
	end)

	-- Store reference
	FrontDeskSystem.frontDesks[player.UserId] = frontDesk

	-- Update the display immediately
	FrontDeskSystem.updateFrontDeskDisplay(player)

	return billboardGui
end

-- Find the front desk for a player
function FrontDeskSystem.findFrontDesk(player)
	if not player then return nil end

	-- Check cache first
	if FrontDeskSystem.frontDesks[player.UserId] then
		return FrontDeskSystem.frontDesks[player.UserId]
	end

	-- Get tycoon reference
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		log("Player " .. player.Name .. " has no tycoon")
		return nil
	end

	-- Look for front desk in tycoon
	local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
	if frontDesk then
		FrontDeskSystem.frontDesks[player.UserId] = frontDesk
		return frontDesk
	end

	-- Look for part with ID = 1 (usually the front desk)
	for _, part in pairs(tycoon.Value:GetDescendants()) do
		if part:GetAttribute("ID") == CONFIG.frontDeskId then
			FrontDeskSystem.frontDesks[player.UserId] = part
			return part
		end
	end

	log("Could not find front desk for " .. player.Name)
	return nil
end

-- Update the front desk display for a player
function FrontDeskSystem.updateFrontDeskDisplay(player)
	if not player then return false end

	-- Find front desk
	local frontDesk = FrontDeskSystem.findFrontDesk(player)
	if not frontDesk then
		log("No front desk found for " .. player.Name)
		return false
	end

	-- Get billboard GUI
	local billboardGui = frontDesk:FindFirstChild("BillboardGui")
	if not billboardGui then
		billboardGui = FrontDeskSystem.createFrontDeskGui(frontDesk, player)
	end

	if not billboardGui then
		log("Failed to create GUI for " .. player.Name)
		return false
	end

	-- Get labels
	local frame = billboardGui:FindFirstChild("Frame")
	if not frame then
		log("GUI structure invalid for " .. player.Name)
		return false
	end

	local duesLabel = frame:FindFirstChild("DuesLabel")
	local statusLabel = frame:FindFirstChild("StatusLabel")

	if not duesLabel or not statusLabel then
		log("GUI labels missing for " .. player.Name)
		return false
	end

	-- Get accrued dues
	local tycoon = player:FindFirstChild("Tycoon")
	local accruedDues = 0

	if tycoon then
		accruedDues = tycoon:GetAttribute("AccruedDues") or 0
	end

	-- Update dues label
	duesLabel.Text = "Membership Dues: " .. formatCurrency(accruedDues)

	-- Update status label
	local lastTime = FrontDeskSystem.lastCollection[player.UserId] or 0
	local timeSince = os.time() - lastTime

	if timeSince < CONFIG.collectionCooldown then
		local timeLeft = CONFIG.collectionCooldown - timeSince
		statusLabel.Text = "Collect again in " .. timeLeft .. " seconds"
		statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
	elseif accruedDues < CONFIG.minCollectionAmount then
		statusLabel.Text = "Need " .. formatCurrency(CONFIG.minCollectionAmount) .. " minimum to collect"
		statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
	else
		statusLabel.Text = "Ready to collect!"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
	end

	return true
end

-- Collect dues from the front desk
function FrontDeskSystem.collectDues(player)
	if not player then return 0 end

	-- Get tycoon
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then
		log("Player " .. player.Name .. " has no tycoon")
		return 0
	end

	-- Get accrued dues
	local accruedDues = tycoon:GetAttribute("AccruedDues") or 0

	-- Check minimum amount
	if accruedDues < CONFIG.minCollectionAmount then
		-- Create notification
		local message = Instance.new("Message")
		message.Text = "Not enough dues to collect. Minimum: " .. formatCurrency(CONFIG.minCollectionAmount)
		message.Parent = player
		game:GetService("Debris"):AddItem(message, 3)

		log(player.Name .. " tried to collect but had insufficient dues")
		return 0
	end

	-- Check cooldown
	local lastTime = FrontDeskSystem.lastCollection[player.UserId] or 0
	local timeSince = os.time() - lastTime

	if timeSince < CONFIG.collectionCooldown then
		-- Create notification
		local message = Instance.new("Message")
		message.Text = "Collection on cooldown. Try again in " .. (CONFIG.collectionCooldown - timeSince) .. " seconds."
		message.Parent = player
		game:GetService("Debris"):AddItem(message, 3)

		log(player.Name .. " tried to collect but was on cooldown")
		return 0
	end

	-- Reset accrued dues
	tycoon:SetAttribute("AccruedDues", 0)

	-- Add to player's cash
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + accruedDues
	end

	-- Update collection time
	FrontDeskSystem.lastCollection[player.UserId] = os.time()

	-- Create notification
	local message = Instance.new("Message")
	message.Text = "Collected " .. formatCurrency(accruedDues) .. " in membership dues!"
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 3)

	-- Play collection sound
	if SoundService:FindFirstChild("CollectionSound") then
		SoundService.CollectionSound:Play()
	end

	-- Create particles if enabled
	if CONFIG.collectionParticles then
		local frontDesk = FrontDeskSystem.findFrontDesk(player)
		if frontDesk then
			local particle = Instance.new("ParticleEmitter")
			particle.Texture = "rbxassetid://131361529" -- Money texture
			particle.Speed = NumberRange.new(5, 10)
			particle.Lifetime = NumberRange.new(1, 2)
			particle.SpreadAngle = Vector2.new(0, 180)
			particle.Rate = 100
			particle.Parent = frontDesk

			-- Remove particles after a moment
			game:GetService("Debris"):AddItem(particle, 2)
		end
	end

	-- Fire collection event
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if eventBridge and eventBridge:FindFirstChild("DuesCollected") then
		eventBridge.DuesCollected:Fire(player, accruedDues)
	end

	-- Update display
	FrontDeskSystem.updateFrontDeskDisplay(player)

	log(player.Name .. " collected " .. accruedDues .. " in dues")
	return accruedDues
end

-- Find or create the front desk for a player
function FrontDeskSystem.ensureFrontDesk(player)
	if not player then return nil end

	-- Try to find existing front desk
	local frontDesk = FrontDeskSystem.findFrontDesk(player)
	if frontDesk then
		return frontDesk
	end

	-- Get tycoon reference
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then
		log("Player " .. player.Name .. " has no tycoon")
		return nil
	end

	-- Try to create a front desk
	local newFrontDesk = Instance.new("Part")
	newFrontDesk.Name = "Front Desk"
	newFrontDesk.Size = Vector3.new(6, 3, 2)
	newFrontDesk.Position = tycoon.Value:GetPivot().Position
	newFrontDesk.Anchored = true
	newFrontDesk.BrickColor = BrickColor.new("Brown")
	newFrontDesk.Material = Enum.Material.Wood
	newFrontDesk:SetAttribute("ID", CONFIG.frontDeskId)
	newFrontDesk.Parent = tycoon.Value

	-- Create front desk decorations
	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Size = Vector3.new(5.8, 0.2, 1.8)
	counter.Position = newFrontDesk.Position + Vector3.new(0, 1.5, 0)
	counter.Anchored = true
	counter.BrickColor = BrickColor.new("Really black")
	counter.Material = Enum.Material.SmoothPlastic
	counter.Parent = newFrontDesk

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(4, 1, 0.2)
	sign.Position = newFrontDesk.Position + Vector3.new(0, 2, -0.9)
	sign.Anchored = true
	sign.BrickColor = BrickColor.new("Deep blue")
	sign.Material = Enum.Material.Neon
	sign.Parent = newFrontDesk

	-- Create GUI
	FrontDeskSystem.createFrontDeskGui(newFrontDesk, player)

	-- Cache the reference
	FrontDeskSystem.frontDesks[player.UserId] = newFrontDesk

	log("Created new front desk for " .. player.Name)
	return newFrontDesk
end

-- Start the display update loop
function FrontDeskSystem.startUpdateLoop()
	spawn(function()
		while true do
			wait(5) -- Update every 5 seconds

			for _, player in pairs(Players:GetPlayers()) do
				task.spawn(function()
					FrontDeskSystem.updateFrontDeskDisplay(player)
				end)
			end
		end
	end)

	log("Started front desk update loop")
end

-- Initialize the system
function FrontDeskSystem.initialize()
	if FrontDeskSystem.initialized then
		return
	end

	log("Initializing Front Desk System...")

	-- Initialize sound effects
	initSoundEffect()

	-- Create EventBridge if it doesn't exist
	if not ReplicatedStorage:FindFirstChild("EventBridge") then
		local eventBridge = Instance.new("Folder")
		eventBridge.Name = "EventBridge"
		eventBridge.Parent = ReplicatedStorage
		log("Created EventBridge in ReplicatedStorage")
	end

	-- Create DuesCollected event if it doesn't exist
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not eventBridge:FindFirstChild("DuesCollected") then
		local event = Instance.new("BindableEvent")
		event.Name = "DuesCollected"
		event.Parent = eventBridge
		log("Created DuesCollected event")
	end

	-- Setup for existing players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			FrontDeskSystem.ensureFrontDesk(player)
		end)
	end

	-- Connect to PlayerAdded event
	Players.PlayerAdded:Connect(function(player)
		task.wait(3) -- Wait for tycoon to be created
		FrontDeskSystem.ensureFrontDesk(player)
	end)

	-- Start update loop
	FrontDeskSystem.startUpdateLoop()

	FrontDeskSystem.initialized = true
	log("Front Desk System initialized")
end

-- Initialize on module load
FrontDeskSystem.initialize()

-- Return the module
return FrontDeskSystem