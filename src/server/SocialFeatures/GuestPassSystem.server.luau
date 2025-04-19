--lua
-- src/server/SocialFeatures/GuestPassSystem.server.luau

local GuestPassSystem = {}
GuestPassSystem.__index = GuestPassSystem

function GuestPassSystem.new()
	local self = setmetatable({}, GuestPassSystem)
	self.activePasses = {} -- Table to track active guest passes {guestPlayerId = {hostPlayerId, expirationTime}}
	return self
end

function GuestPassSystem:SendGuestPass(hostPlayer, guestPlayer)
	-- Check if the guest player is valid
	if not guestPlayer then
		warn("Invalid guest player specified.")
		return false
	end
	
	-- Check if the guest player is online
	if not game.Players:FindFirstChild(guestPlayer.Name) then
		warn("Guest player is not online.")
		return false
	end

	-- Check if host player has available guest passes (Implement a limit if needed)

	-- Check if a guest pass already exists between these players
	for guestPlayerId, passData in pairs(self.activePasses) do
		if passData.hostPlayerId == hostPlayer.UserId then
			if guestPlayer.UserId == guestPlayerId then
				warn("A guest pass already exists between these players.")
				return false
			end
		end
	end

	-- Set expiration time (e.g., 24 hours)
	local expirationTime = os.time() + 86400

	-- Store the guest pass data
	self.activePasses[guestPlayer.UserId] = {
		hostPlayerId = hostPlayer.UserId,
		expirationTime = expirationTime,
	}

	-- Send a notification or visual cue to the guest player
	print(hostPlayer.Name .. " sent a guest pass to " .. guestPlayer.Name)

	-- Handle Incentives for Inviting (add rewards for the host)
	-- ...

	return true
end

function GuestPassSystem:AcceptGuestPass(guestPlayer, hostPlayer)
	-- Check if a guest pass exists
	local passData = self.activePasses[guestPlayer.UserId]
	if not passData then
		warn("No guest pass found for this player.")
		return false
	end
	
	-- Check if the host player is the valid one.
	if passData.hostPlayerId ~= hostPlayer.UserId then
		warn("Invalid host player for this guest pass.")
		return false
	end
	
	-- Check if the pass is expired
	if os.time() > passData.expirationTime then
		warn("This guest pass has expired.")
		self:RemoveGuestPass(guestPlayer)
		return false
	end
	
	-- Allow the guest to enter the host's gym
	print(guestPlayer.Name .. " accepted the guest pass from " .. hostPlayer.Name)

	-- Handle Discoverability (add a visual cue or notification for the host and other players)
	-- ...

	return true
end

function GuestPassSystem:RemoveGuestPass(guestPlayer)
	-- Remove the guest pass
	if self.activePasses[guestPlayer.UserId] then
		self.activePasses[guestPlayer.UserId] = nil
		return true
	else
		warn("No guest pass to remove.")
		return false
	end
end

function GuestPassSystem:CheckIfGuestPassIsValid(guestPlayer)
	-- Check if a guest pass exists
	local passData = self.activePasses[guestPlayer.UserId]
	if not passData then
		warn("No guest pass found for this player.")
		return false
	end
	
	-- Check if the pass is expired
	if os.time() > passData.expirationTime then
		warn("This guest pass has expired.")
		self:RemoveGuestPass(guestPlayer)
		return false
	end
	
	return true
end

--Manage Unique Challenges
function GuestPassSystem:CreateUniqueChallenge(hostPlayer)
	-- Check if host player has available challenges (Implement a limit if needed)

	-- Create a new challenge for a player
	print(hostPlayer.Name .. " created a unique challenge for their gym")

	-- Handle Unique Challenges
	-- ...
end

return GuestPassSystem.new()