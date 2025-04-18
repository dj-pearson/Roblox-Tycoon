--luau
-- TradingSystem.server.luau

local TradingSystem = {}
TradingSystem.__index = TradingSystem

function TradingSystem.new()
	local self = setmetatable({}, TradingSystem)
	self.tradeRequests = {} -- Store pending trade requests
	return self
end

function TradingSystem:SendTradeRequest(sender, receiver, offeredItems, requestedItems)
	-- Check if the sender and receiver are valid players
	if not sender or not receiver then
		warn("Invalid sender or receiver in SendTradeRequest")
		return false
	end

	-- Check if the players are already in a trade
	if self.tradeRequests[sender] or self.tradeRequests[receiver] then
		warn("Player already in a trade")
		return false
	end

	-- Check if the offered items are valid
	if not offeredItems or type(offeredItems) ~= "table" then
		warn("Invalid offered items in SendTradeRequest")
		return false
	end

	-- Check if the requested items are valid
	if not requestedItems or type(requestedItems) ~= "table" then
		warn("Invalid requested items in SendTradeRequest")
		return false
	end
	
	-- Create a new trade request
	local newTradeRequest = {
		sender = sender,
		receiver = receiver,
		offeredItems = offeredItems,
		requestedItems = requestedItems,
		status = "Pending",
	}

	-- Store the trade request
	self.tradeRequests[sender] = newTradeRequest
	self.tradeRequests[receiver] = newTradeRequest

	print(sender.Name .. " sent a trade request to " .. receiver.Name)

	-- TODO: Send a notification to the receiver

	return true
end

function TradingSystem:AcceptTradeRequest(player)
	-- Check if the player is in a trade request
	local tradeRequest = self.tradeRequests[player]
	if not tradeRequest then
		warn("No trade request found for player")
		return false
	end

	if tradeRequest.status ~= "Pending" then
		warn("Trade request is not pending")
		return false
	end

	print(player.Name .. " accepted the trade request from " .. tradeRequest.sender.Name)
	
	tradeRequest.status = "Accepted"

	-- Transfer items
	local successSender = self:TransferItems(tradeRequest.sender, tradeRequest.offeredItems)
	local successReceiver = self:TransferItems(tradeRequest.receiver, tradeRequest.requestedItems)

	if not successSender or not successReceiver then
		warn("Trade was not succesful")
		tradeRequest.status = "Error"
		self:DenyTradeRequest(player)
		return false
	end
	
	self:TransferItems(tradeRequest.receiver, tradeRequest.offeredItems)
	self:TransferItems(tradeRequest.sender, tradeRequest.requestedItems)

	-- Clean up the trade request
	self.tradeRequests[tradeRequest.sender] = nil
	self.tradeRequests[tradeRequest.receiver] = nil
	
	return true
end

function TradingSystem:DenyTradeRequest(player)
	-- Check if the player is in a trade request
	local tradeRequest = self.tradeRequests[player]
	if not tradeRequest then
		warn("No trade request found for player")
		return false
	end
	
	print(player.Name .. " denied the trade request from " .. tradeRequest.sender.Name)
	tradeRequest.status = "Denied"

	-- Clean up the trade request
	self.tradeRequests[tradeRequest.sender] = nil
	self.tradeRequests[tradeRequest.receiver] = nil

	return true
end

function TradingSystem:TransferItems(player, items)
	-- Check if the player is valid
	if not player then
		warn("Invalid player in TransferItems")
		return false
	end
	
	if not items or type(items) ~= "table" then
		warn("Invalid items in TransferItems")
		return false
	end

	-- Check if the player has the offered items
	for itemName, quantity in pairs(items) do
		if not player.leaderstats or not player.leaderstats:FindFirstChild(itemName) or player.leaderstats[itemName].Value < quantity then
			warn(player.Name .. " does not have enough " .. itemName)
			return false
		end
	end
	
	-- Remove the items from the player
	for itemName, quantity in pairs(items) do
		player.leaderstats[itemName].Value -= quantity
	end

	return true
end

--[[
    Functions to manage Progression and Interaction
]]
function TradingSystem:ManageProgression()
	-- TODO: Implement the logic to manage the progression of the players
	print("Managing Progression")
end

function TradingSystem:ManageInteraction()
	-- TODO: Implement the logic to manage the interaction of the players
	print("Managing Interaction")
end

return TradingSystem