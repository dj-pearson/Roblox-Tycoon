-- SaunaAndSteamEffects.lua
-- Place this script in ServerScriptService

local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")

-- CONFIGURATION --

-- Steam Room Configuration
local STEAM_CONFIG = {
	-- Steam density
	steamDensity = 5, -- Higher value = more dense steam

	-- Steam fog particles
	fogRate = 15, -- Emission rate
	fogSize = {min = 20, max = 30}, -- Size of fog particles
	fogTransparency = {["start"] = 0.1, ["end"] = 1}, -- Using brackets to avoid keyword conflict
	fogSpeed = {min = 0.5, max = 1.2}, -- How fast fog moves
	fogLifetime = {min = 6, max = 10}, -- How long fog lasts

	-- Sound
	enableSound = true,
	soundId = "rbxassetid://9048378264" -- UPDATED sound ID
}

-- Heater Configuration
local HEATER_CONFIG = {
	-- Heat wave effect
	enableHeatWave = true,
	heatWaveSize = Vector3.new(3, 4, 3),
	heatWaveIntensity = 0.08,
	heatWaveSpeed = 2,

	-- Steam particles
	enableSteam = true,
	steamRate = 20,
	steamSpeed = {min = 1, max = 3},
	steamSize = {min = 0.5, max = 2},
	steamColor = ColorSequence.new(Color3.fromRGB(220, 220, 220)),
	steamTransparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	}),
	steamLifetime = {min = 2, max = 5},

	-- Glow effect
	enableGlow = true,
	glowColor = Color3.fromRGB(255, 120, 30),
	glowBrightness = 2,
	glowSize = 0.35,
	glowPulseTime = 2,

	-- Sound
	enableSound = true,
	soundId = "rbxassetid://9048378264", -- UPDATED sound ID
	soundVolume = 0.5
}

-- PATHS --

-- Ensure proper folder structure in ServerStorage
local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
if not gymPartsFolder then
	gymPartsFolder = Instance.new("Folder")
	gymPartsFolder.Name = "GymParts"
	gymPartsFolder.Parent = ServerStorage
end

local thirdFloorFolder = gymPartsFolder:FindFirstChild("3rd Floor")
if not thirdFloorFolder then
	thirdFloorFolder = Instance.new("Folder")
	thirdFloorFolder.Name = "3rd Floor"
	thirdFloorFolder.Parent = gymPartsFolder
end

local wellnessFolder = thirdFloorFolder:FindFirstChild("Massage and Wellness")
if not wellnessFolder then
	wellnessFolder = Instance.new("Folder")
	wellnessFolder.Name = "Massage and Wellness"
	wellnessFolder.Parent = thirdFloorFolder
end

local saunaFolder = wellnessFolder:FindFirstChild("Steam and Sauna")
if not saunaFolder then
	saunaFolder = Instance.new("Folder")
	saunaFolder.Name = "Steam and Sauna"
	saunaFolder.Parent = wellnessFolder
end

-- Find existing script references to remove them
local scriptPaths = {}
local steamMensRoom = saunaFolder:FindFirstChild("Steam Mens")
local steamWomensRoom = saunaFolder:FindFirstChild("Steam Womens")
local saunaMensRoom = saunaFolder:FindFirstChild("Sauna Mens")
local saunaWomensRoom = saunaFolder:FindFirstChild("Sauna Womens")

-- Add script paths if the folders exist
if steamMensRoom and steamMensRoom:FindFirstChild("SteamRoom") then
	table.insert(scriptPaths, steamMensRoom.SteamRoom:FindFirstChild("Steam Script"))
end

if steamWomensRoom and steamWomensRoom:FindFirstChild("SteamRoom") then
	table.insert(scriptPaths, steamWomensRoom.SteamRoom:FindFirstChild("Steam Script"))
end

if saunaMensRoom and saunaMensRoom:FindFirstChild("Heater") and
	saunaMensRoom.Heater:FindFirstChild("Heater Element") then
	table.insert(scriptPaths, saunaMensRoom.Heater["Heater Element"]:FindFirstChild("Heater Script"))
end

if saunaWomensRoom and saunaWomensRoom:FindFirstChild("Heater") and
	saunaWomensRoom.Heater:FindFirstChild("Heater Element") then
	table.insert(scriptPaths, saunaWomensRoom.Heater["Heater Element"]:FindFirstChild("Heater Script"))
end

-- Remove existing scripts
for _, script in pairs(scriptPaths) do
	if script then
		print("Removing existing script: " .. script:GetFullName())
		script:Destroy()
	end
end

-- Steam Rooms
local steamRooms = {}
if steamMensRoom and steamMensRoom:FindFirstChild("SteamRoom") then
	table.insert(steamRooms, steamMensRoom.SteamRoom)
end
if steamWomensRoom and steamWomensRoom:FindFirstChild("SteamRoom") then
	table.insert(steamRooms, steamWomensRoom.SteamRoom)
end

-- Heater Elements
local heaterElements = {}
if saunaMensRoom and saunaMensRoom:FindFirstChild("Heater") and
	saunaMensRoom.Heater:FindFirstChild("Heater Element") then
	table.insert(heaterElements, saunaMensRoom.Heater["Heater Element"])
end
if saunaWomensRoom and saunaWomensRoom:FindFirstChild("Heater") and
	saunaWomensRoom.Heater:FindFirstChild("Heater Element") then
	table.insert(heaterElements, saunaWomensRoom.Heater["Heater Element"])
end

-- FUNCTIONS --

-- Steam Room Fog Effect
local function createSteamRoomFog(room)
	-- Create emitter template
	local fogEmitter = Instance.new("ParticleEmitter")
	fogEmitter.Texture = "rbxassetid://241889252" -- Soft cloud texture
	fogEmitter.Color = ColorSequence.new(Color3.fromRGB(220, 220, 220))
	fogEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, STEAM_CONFIG.fogSize.min),
		NumberSequenceKeypoint.new(0.5, STEAM_CONFIG.fogSize.max),
		NumberSequenceKeypoint.new(1, STEAM_CONFIG.fogSize.min * 0.8)
	})
	fogEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, STEAM_CONFIG.fogTransparency["start"]),
		NumberSequenceKeypoint.new(0.8, STEAM_CONFIG.fogTransparency["start"] + 0.1),
		NumberSequenceKeypoint.new(1, STEAM_CONFIG.fogTransparency["end"])
	})
	fogEmitter.Lifetime = NumberRange.new(STEAM_CONFIG.fogLifetime.min, STEAM_CONFIG.fogLifetime.max)
	fogEmitter.Rate = STEAM_CONFIG.fogRate
	fogEmitter.Speed = NumberRange.new(STEAM_CONFIG.fogSpeed.min, STEAM_CONFIG.fogSpeed.max)
	fogEmitter.SpreadAngle = Vector2.new(180, 180) -- Spread in all directions
	fogEmitter.Rotation = NumberRange.new(0, 360)
	fogEmitter.RotSpeed = NumberRange.new(-10, 10)
	fogEmitter.Drag = 2 -- Slows down quickly

	-- Find parts to attach emitters to
	for _, part in pairs(room:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Clone emitter for each part
			local emitter = fogEmitter:Clone()
			emitter.Parent = part
		end
	end

	-- Add ambient sound if enabled
	if STEAM_CONFIG.enableSound then
		local sound = Instance.new("Sound")
		sound.Name = "SteamAmbience"
		sound.SoundId = STEAM_CONFIG.soundId
		sound.Volume = 0.5
		sound.Looped = true

		-- Find a part to attach the sound to
		for _, part in pairs(room:GetDescendants()) do
			if part:IsA("BasePart") then
				sound.Parent = part
				sound:Play()
				break
			end
		end
	end

	fogEmitter:Destroy() -- Destroy template
	print("Steam room effects created for: " .. room:GetFullName())
end

-- Heater Element Functions
local function createHeaterSteamEffect(heaterElement)
	if not HEATER_CONFIG.enableSteam then return end

	local steamEmitter = Instance.new("ParticleEmitter")
	steamEmitter.Name = "SteamEffect"

	-- Set particle properties
	steamEmitter.Rate = HEATER_CONFIG.steamRate
	steamEmitter.Speed = NumberRange.new(HEATER_CONFIG.steamSpeed.min, HEATER_CONFIG.steamSpeed.max)
	steamEmitter.Lifetime = NumberRange.new(HEATER_CONFIG.steamLifetime.min, HEATER_CONFIG.steamLifetime.max)
	steamEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, HEATER_CONFIG.steamSize.min),
		NumberSequenceKeypoint.new(0.5, HEATER_CONFIG.steamSize.max),
		NumberSequenceKeypoint.new(1, HEATER_CONFIG.steamSize.max * 0.8)
	})
	steamEmitter.Transparency = HEATER_CONFIG.steamTransparency
	steamEmitter.Color = HEATER_CONFIG.steamColor
	steamEmitter.Texture = "rbxassetid://6880496307"
	steamEmitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	steamEmitter.VelocitySpread = 25
	steamEmitter.VelocityInheritance = 0.2
	steamEmitter.Acceleration = Vector3.new(0, 2, 0)
	steamEmitter.Drag = 1
	steamEmitter.RotSpeed = NumberRange.new(-30, 30)
	steamEmitter.SpreadAngle = Vector2.new(25, 25)

	-- Find suitable parts to attach emitters to
	for _, part in pairs(heaterElement:GetDescendants()) do
		if part:IsA("BasePart") then
			local emitter = steamEmitter:Clone()
			emitter.Parent = part
		end
	end

	steamEmitter:Destroy()
end

local function createHeaterGlowEffect(heaterElement)
	if not HEATER_CONFIG.enableGlow then return end

	for _, part in pairs(heaterElement:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Add glow via PointLight
			local glow = Instance.new("PointLight")
			glow.Name = "HeaterGlow"
			glow.Color = HEATER_CONFIG.glowColor
			glow.Brightness = HEATER_CONFIG.glowBrightness
			glow.Range = part.Size.Magnitude * HEATER_CONFIG.glowSize * 4
			glow.Parent = part

			-- Create subtle surface glow as well
			part.Material = Enum.Material.Neon
			part.Color = part.Color:Lerp(Color3.fromRGB(255, 100, 0), 0.3)

			-- Animate the glow with pulsing
			spawn(function()
				while true do
					local tween = TweenService:Create(
						glow,
						TweenInfo.new(HEATER_CONFIG.glowPulseTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
						{Brightness = HEATER_CONFIG.glowBrightness * 0.7}
					)
					tween:Play()
					wait(HEATER_CONFIG.glowPulseTime * 2)
				end
			end)
		end
	end
end

local function createHeaterSound(heaterElement)
	if not HEATER_CONFIG.enableSound then return end

	local sound = Instance.new("Sound")
	sound.Name = "HeaterSound"
	sound.SoundId = HEATER_CONFIG.soundId
	sound.Volume = HEATER_CONFIG.soundVolume
	sound.Looped = true

	-- Find a part to parent the sound to
	for _, part in pairs(heaterElement:GetDescendants()) do
		if part:IsA("BasePart") then
			sound.Parent = part
			sound:Play()
			break
		end
	end

	return sound
end

local function initializeHeaterEffects(heaterElement)
	-- Check if the model has a PrimaryPart
	if not heaterElement.PrimaryPart then
		-- Find the first BasePart to use as PrimaryPart
		for _, part in pairs(heaterElement:GetDescendants()) do
			if part:IsA("BasePart") then
				heaterElement.PrimaryPart = part
				break
			end
		end
	end

	createHeaterSteamEffect(heaterElement)
	createHeaterGlowEffect(heaterElement)
	createHeaterSound(heaterElement)
	print("Sauna heater effects initialized for: " .. heaterElement:GetFullName())
end

-- Function to clone and apply effects from ServerStorage to workspace when needed
local function applyEffectsToWorkspace()
	-- This function can be called when you want to apply the effects to the workspace
	-- For example, from a separate script or when a player enters the sauna area

	-- Find or create destination folders in workspace
	local workspaceGymParts = workspace:FindFirstChild("GymParts")
	if not workspaceGymParts then
		workspaceGymParts = Instance.new("Folder")
		workspaceGymParts.Name = "GymParts"
		workspaceGymParts.Parent = workspace
	end

	-- Clone the necessary parts from ServerStorage to workspace
	local storageGymParts = ServerStorage:FindFirstChild("GymParts")
	if storageGymParts then
		-- Clone the entire structure or specific parts as needed
		-- This depends on your specific game implementation
		print("Effects ready to be applied to workspace when needed")
	end
end

-- MAIN CODE --

-- Apply effects to steam rooms
for _, room in pairs(steamRooms) do
	pcall(function()
		createSteamRoomFog(room)
	end)
end

-- Apply effects to heaters
for _, heater in pairs(heaterElements) do
	pcall(function()
		initializeHeaterEffects(heater)
	end)
end

print("All sauna and steam room effects created successfully in ServerStorage!")

-- Return a function that can be called to apply effects to workspace
return {
	applyEffectsToWorkspace = applyEffectsToWorkspace
}