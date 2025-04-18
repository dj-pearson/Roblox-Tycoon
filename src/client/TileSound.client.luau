local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSoundEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")

-- ✅ Load Sound on Client
playSoundEvent.OnClientEvent:Connect(function()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://17245419579" -- Replace with your working sound ID!
	sound.Volume = 2
	sound.Parent = game.Players.LocalPlayer.Character or workspace
	sound:Play()

	print("🎵 Sound Played on Client!")
end)
