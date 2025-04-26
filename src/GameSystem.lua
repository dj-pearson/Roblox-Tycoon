--lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local function startGame()
	print("Game started!")
end

local function getPlayerCash(player: Player)
    local leaderstats = player:WaitForChild("leaderstats")
    local cash = leaderstats:WaitForChild("Cash")
    return cash.Value
end
return {
	startGame = startGame,
	getPlayerCash = getPlayerCash,
}