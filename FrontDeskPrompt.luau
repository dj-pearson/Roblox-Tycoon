-- MODIFIED FrontDeskSystem.lua
-- Keeps functionality but removes duplicate GUI creation
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
	-- Collection settings
	promptActionText = "Collect Membership Dues",
	promptHoldDuration = 0.5,

	-- Animation
	collectionAnimationDuration = 1.5,

	-- Sounds
	collectionSoundId = "rbxassetid://142472270", -- Cash register sound
	noFundsSound = "rbxassetid://159798530", -- Empty register sound

	-- Effects
	enableParticleEffects = true,
	particleCount = 50,
	particleLifetime = 2,

	-- Debug
	debug = false
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[FrontDesk]", ...)
	end
end

-- Module table
local FrontDeskSystem = {}

-- Try to load dependencies
local MembershipSystem
pcall(function()
	MembershipSystem = require(ServerScriptService:FindFirstChild("GymMembershipSystem"))
	if MembershipSystem then
		debugPrint("Successfully loaded GymMembershipSystem")
	end
end)

-- Create/get EventBridge
local EventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
if not EventBridge then
	EventBridge = Instance.new("Folder")
	EventBridge.Name = "EventBridge"
	EventBridge.Parent = ReplicatedStorage
	debugPrint("Created EventBridge in ReplicatedStorage")
end

-- Format large numbers with commas
local function formatWithCommas(number)
	local formatted = tostring(number)
	local formattedWithCommas = ""

	for i = #formatted, 1, -1 do
		if (#formatted - i) % 3 == 0 and i ~= #formatted then
			formattedWithCommas = "," .. formattedWithCommas
		end
		formattedWithCommas = string.sub(formatted, i, i) .. formattedWithCommas
	end

	return formattedWithCommas
end

---- Track if player has started tycoon
function FrontDeskSystem.hasPlayerStartedTycoon(player)
	if not player then return false end

	-- Use MembershipSystem if available
	if MembershipSystem and MembershipSystem.hasPlayerStartedTycoon then
		return MembershipSystem.hasPlayerStartedTycoon(player)
	end

	-- Fallback check
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return false end

	local equipmentCount = tycoon:GetAttribute("EquipmentCount") or 0
	local started = tycoon:GetAttribute("TycoonStarted") or false

	return equipmentCount > 0 or started
end

-- Add a ProximityPrompt for collection
function FrontDeskSystem.addProximityPrompt(frontDesk, player)
	if not frontDesk or not player then return nil end

	-- Remove any existing ProximityPrompt
	local existingPrompt = frontDesk:FindFirstChild("CollectionPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end

	-- Create new ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectionPrompt"
	prompt.ActionText = CONFIG.promptActionText
	prompt.ObjectText = player.Name .. "'s Gym"
	prompt.HoldDuration = CONFIG.promptHoldDuration
	prompt.RequiresLineOfSight = false
	prompt.Parent = frontDesk

	-- Connect to the Triggered event
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

				-- Play collection effects
				FrontDeskSystem.playCollectionEffects(frontDesk, accruedDues)

				-- Show message to player
				local message = Instance.new("Message")
				message.Text = "Collected $" .. formatWithCommas(accruedDues) .. " in membership dues!"
				message.Parent = player
				game:GetService("Debris"):AddItem(message, 3)

				-- Fire event for other systems
				local duesEvent = EventBridge:FindFirstChild("DuesCollected")
				if not duesEvent then
					duesEvent = Instance.new("BindableEvent")
					duesEvent.Name = "DuesCollected"
					duesEvent.Parent = EventBridge
				end
				duesEvent:Fire(player, accruedDues)

				debugPrint(player.Name .. " collected $" .. tostring(accruedDues) .. " from membership fees")
			end
		else
			-- Play empty sound
			local emptySound = Instance.new("Sound")
			emptySound.SoundId = CONFIG.noFundsSound
			emptySound.Volume = 0.8
			emptySound.Parent = frontDesk
			emptySound:Play()
			game:GetService("Debris"):AddItem(emptySound, 2)

			-- Notify player
			local message = Instance.new("Message")
			message.Text = "No membership dues to collect yet!"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 3)
		end
	end)

	return prompt
end

-- Play collection effects
function FrontDeskSystem.playCollectionEffects(frontDesk, amount)
	if not frontDesk then return end

	-- Play collection sound
	local sound = Instance.new("Sound")
	sound.SoundId = CONFIG.collectionSoundId
	sound.Volume = 1
	sound.Parent = frontDesk
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 3)

	-- Create visual effects if enabled
	if CONFIG.enableParticleEffects then
		-- Create particle emitter for money effect
		local particle = Instance.new("ParticleEmitter")
		particle.Color = ColorSequence.new(Color3.fromRGB(0, 255, 127)) -- Money green
		particle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0)
		})
		particle.Texture = "rbxassetid://131332797" -- Dollar sign texture
		particle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		particle.Lifetime = NumberRange.new(1, CONFIG.particleLifetime)
		particle.Rate = 0
		particle.Speed = NumberRange.new(5, 10)
		particle.SpreadAngle = Vector2.new(0, 180)
		particle.Acceleration = Vector3.new(0, 5, 0)
		particle.Parent = frontDesk

		-- Emit particles in a burst - more particles for larger amounts
		local particleCount = math.min(CONFIG.particleCount, math.floor(CONFIG.particleCount * (amount / 1000)))
		particle:Emit(math.max(10, particleCount))

		-- Remove particle after effect completes
		game:GetService("Debris"):AddItem(particle, CONFIG.particleLifetime)
	end
end

-- Update front desk display - REMOVED GUI CREATION, ONLY ADDS PROMPT NOW
function FrontDeskSystem.updateFrontDeskDisplay(player)
	if not player then return false end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return false end

	local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
	if not frontDesk then return false end

	-- Only ensure proximity prompt exists
	if not frontDesk:FindFirstChild("CollectionPrompt") then
		FrontDeskSystem.addProximityPrompt(frontDesk, player)
	end

	-- REMOVED GUI CREATION CODE - Let BuyTile handle this

	return true
end

-- Function to handle first tile purchase
function FrontDeskSystem.handleFirstTilePurchase(player)
	if not player then return false end

	-- Mark tycoon as started
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		tycoon:SetAttribute("TycoonStarted", true)
	end

	-- ONLY add proximity prompt, don't create GUI
	task.delay(1, function()
		-- Make sure front desk exists
		if tycoon and tycoon.Value then
			local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
			if frontDesk and not frontDesk:FindFirstChild("CollectionPrompt") then
				FrontDeskSystem.addProximityPrompt(frontDesk, player)
			end
		end
	end)

	return true
end

-- Function to update all front desks (ONLY PROMPTS, NO GUI)
function FrontDeskSystem.updateAllFrontDesks()
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			FrontDeskSystem.updateFrontDeskDisplay(player)
		end)
	end
end

-- Function to clean up any existing GUIs created by this system
function FrontDeskSystem.cleanupDuplicateGUIs()
	for _, player in pairs(Players:GetPlayers()) do
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon and tycoon.Value then
			for _, obj in ipairs(tycoon.Value:GetDescendants()) do
				-- Look for GUIs created by this system
				if obj:IsA("BillboardGui") and obj.Name == "DuesDisplayGui" then
					debugPrint("Removing duplicate GUI: " .. obj:GetFullName())
					obj:Destroy()
				end
			end
		end
	end
end

-- Initialize the system
function FrontDeskSystem.initialize()
	debugPrint("Initializing Front Desk System")

	-- Clean up any duplicate GUIs from previous runs
	FrontDeskSystem.cleanupDuplicateGUIs()

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		-- Wait for tycoon to be ready
		task.delay(5, function()
			if FrontDeskSystem.hasPlayerStartedTycoon(player) then
				-- Only add the proximity prompt, no GUI
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon and tycoon.Value then
					local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
					if frontDesk and not frontDesk:FindFirstChild("CollectionPrompt") then
						FrontDeskSystem.addProximityPrompt(frontDesk, player)
					end
				end
			end
		end)
	end)

	-- Connect to EventBridge
	if not EventBridge:FindFirstChild("TilePurchased") then
		local tilePurchasedEvent = Instance.new("BindableEvent")
		tilePurchasedEvent.Name = "TilePurchased"
		tilePurchasedEvent.Parent = EventBridge
	end

	EventBridge:FindFirstChild("TilePurchased").Event:Connect(function(player, tileId)
		if tileId == 1 then
			FrontDeskSystem.handleFirstTilePurchase(player)
		end
	end)

	debugPrint("Front Desk System initialized")
	return true
end

-- Initialize the system
FrontDeskSystem.initialize()

-- Return the module
return FrontDeskSystem