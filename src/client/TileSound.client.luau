local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Try to load SoundSystemManager first
local SoundSystem
local success, result = pcall(function()
	return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("SoundSystemManager"))
end)

if success and result then
	SoundSystem = result
	print("✅ SoundSystemManager loaded successfully")
else
	print("⚠️ SoundSystemManager not found, using fallback")
end

-- Try to get PlaySoundEvent without yielding
local playSoundEvent
local attempts = 0
local maxAttempts = 50 -- 5 seconds max wait

while not playSoundEvent and attempts < maxAttempts do
	playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
	if playSoundEvent then
		break
	end
	attempts = attempts + 1
	task.wait(0.1)
end

if not playSoundEvent then
	warn("⚠️ PlaySoundEvent not found after waiting, creating fallback")
	
	-- Create a local fallback
	playSoundEvent = Instance.new("BindableEvent")
	playSoundEvent.Name = "LocalPlaySoundEvent"
	playSoundEvent.Parent = player:WaitForChild("PlayerGui")
	
	-- Log the fallback creation
	print("⚠️ Created local fallback for PlaySoundEvent")
else
	print("✅ PlaySoundEvent found after " .. attempts .. " attempts")
end

-- Function to play sounds safely
local function playSound(soundId, properties)
	soundId = soundId or "rbxassetid://17245419579" -- Default sound ID
	properties = properties or {Volume = 2}
	
	-- Use SoundSystem if available
	if SoundSystem then
		SoundSystem:PlaySound(soundId, properties)
		return
	end
	
	-- Fallback implementation
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = properties.Volume or 2
	sound.Parent = player.Character or workspace
	
	local playSuccess = pcall(function()
		sound:Play()
	end)
	
	if playSuccess then
		print("🎵 Sound Played on Client!")
		
		-- Auto-cleanup
		task.delay(sound.TimeLength + 1, function()
			if sound and sound.Parent then
				sound:Destroy()
			end
		end)
	else
		warn("❌ Failed to play sound: " .. soundId)
		sound:Destroy()
		
		-- Try fallback sound
		local fallbackSound = Instance.new("Sound")
		fallbackSound.SoundId = "rbxassetid://12222253" -- Known working sound
		fallbackSound.Volume = 1
		fallbackSound.Parent = player.Character or workspace
		fallbackSound:Play()
		
		task.delay(2, function()
			fallbackSound:Destroy()
		end)
	end
end

-- Connect to the appropriate event type
if playSoundEvent:IsA("RemoteEvent") then
	playSoundEvent.OnClientEvent:Connect(function()
		playSound("rbxassetid://17245419579", {Volume = 2})
	end)
else
	playSoundEvent.Event:Connect(function()
		playSound("rbxassetid://17245419579", {Volume = 2})
	end)
end

print("✅ TileSound client initialized successfully")
