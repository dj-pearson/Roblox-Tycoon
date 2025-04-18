local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Value = 1000 -- Starting cash value
	cashStat.Parent = leaderstats

	print(player.Name .. "'s leaderstats initialized.")
end)
