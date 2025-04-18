--lua
local AllianceClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CreateAllianceEvent = ReplicatedStorage:WaitForChild("CreateAllianceEvent")
local JoinAllianceEvent = ReplicatedStorage:WaitForChild("JoinAllianceEvent")
local LeaveAllianceEvent = ReplicatedStorage:WaitForChild("LeaveAllianceEvent")
local RemoveFromAllianceEvent = ReplicatedStorage:WaitForChild("RemoveFromAllianceEvent")
local InviteToAllianceEvent = ReplicatedStorage:WaitForChild("InviteToAllianceEvent")
local AcceptAllianceInviteEvent = ReplicatedStorage:WaitForChild("AcceptAllianceInviteEvent")
local DenyAllianceInviteEvent = ReplicatedStorage:WaitForChild("DenyAllianceInviteEvent")
local DisbandAllianceEvent = ReplicatedStorage:WaitForChild("DisbandAllianceEvent")
local ServerToClientEvents = ReplicatedStorage:WaitForChild("ServerToClientEvents")

local AllianceCreatedEvent = ReplicatedStorage:WaitForChild("AllianceCreatedEvent")
local PlayerJoinedAllianceEvent = ReplicatedStorage:WaitForChild("PlayerJoinedAllianceEvent")
local PlayerLeftAllianceEvent = ReplicatedStorage:WaitForChild("PlayerLeftAllianceEvent")
local PlayerRemovedFromAllianceEvent = ReplicatedStorage:WaitForChild("PlayerRemovedFromAllianceEvent")
local PlayerInvitedToAllianceEvent = ReplicatedStorage:WaitForChild("PlayerInvitedToAllianceEvent")
local AllianceDisbandedEvent = ReplicatedStorage:WaitForChild("AllianceDisbandedEvent")
local ErrorEvent = ReplicatedStorage:WaitForChild("ErrorEvent")

function AllianceClient.initialize()
	print("AllianceClient initialized")
	ServerToClientEvents.OnClientEvent:Connect(function(eventName, ...)
		if eventName == "AllianceCreated" then
			AllianceClient.handleAllianceCreated(...)
		elseif eventName == "PlayerJoinedAlliance" then
			AllianceClient.handlePlayerJoinedAlliance(...)
		elseif eventName == "PlayerLeftAlliance" then
			AllianceClient.handlePlayerLeftAlliance(...)
		elseif eventName == "PlayerRemovedFromAlliance" then
			AllianceClient.handlePlayerRemovedFromAlliance(...)
		elseif eventName == "PlayerInvitedToAlliance" then
			AllianceClient.handlePlayerInvitedToAlliance(...)
		elseif eventName == "AllianceDisbanded" then
			AllianceClient.handleAllianceDisbanded(...)
		elseif eventName == "AllianceError" then
			AllianceClient.handleError(...)
		end
	end)
end

function AllianceClient.sendCreateAllianceRequest(allianceName)
	print("Sending create alliance request:", allianceName)
	CreateAllianceEvent:FireServer(allianceName)
end

function AllianceClient.sendJoinAllianceRequest(allianceId)
	print("Sending join alliance request:", allianceId)
	JoinAllianceEvent:FireServer(allianceId)
end

function AllianceClient.sendLeaveAllianceRequest()
	print("Sending leave alliance request")
	LeaveAllianceEvent:FireServer()
end

function AllianceClient.sendRemoveFromAllianceRequest(playerToRemove)
	print("Sending remove from alliance request:", playerToRemove.UserId)
	RemoveFromAllianceEvent:FireServer(playerToRemove)
end

function AllianceClient.sendInviteToAllianceRequest(playerToInvite)
	print("Sending invite to alliance request:", playerToInvite.UserId)
	InviteToAllianceEvent:FireServer(playerToInvite)
end

function AllianceClient.sendAcceptAllianceInviteRequest()
	print("Sending accept alliance invite request")
	AcceptAllianceInviteEvent:FireServer()
end

function AllianceClient.sendDenyAllianceInviteRequest()
	print("Sending deny alliance invite request")
	DenyAllianceInviteEvent:FireServer()
end

function AllianceClient.sendDisbandAllianceRequest()
	print("Sending disband alliance request")
	DisbandAllianceEvent:FireServer()
end

function AllianceClient.handleAllianceCreated(allianceId)
	print("Alliance created:", allianceId)
	-- Call UI function to update alliance info
	-- Example: AllianceUI.displayAllianceInfo(allianceId, {})
end

function AllianceClient.handlePlayerJoinedAlliance(player, allianceId)
	print("Player joined alliance:", player.UserId, "Alliance:", allianceId)
	-- Call UI function to update alliance member list
	-- Example: AllianceUI.updateMemberList(allianceId, members)
end

function AllianceClient.handlePlayerLeftAlliance(player, allianceId)
	print("Player left alliance:", player.UserId, "Alliance:", allianceId)
	if player.UserId == LocalPlayer.UserId then
		-- Call UI function to display no alliance
		-- Example: AllianceUI.displayNoAlliance()
	else
		-- Call UI function to update alliance member list
		-- Example: AllianceUI.updateMemberList(allianceId, members)
	end
end

function AllianceClient.handlePlayerRemovedFromAlliance(player, allianceId)
	print("Player removed from alliance:", player.UserId, "Alliance:", allianceId)
	-- Call UI function to update alliance member list
	-- Example: AllianceUI.updateMemberList(allianceId, members)
end



function AllianceClient.handleError(message)
	print("Alliance Error:", message)
end

return AllianceClient