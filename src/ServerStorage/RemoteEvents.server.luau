lua
--[[
    This script stores the RemoteEvents for the Alliance System.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ServerStorage

-- Alliance System RemoteEvents
local AllianceCreated = Instance.new("RemoteEvent")
AllianceCreated.Name = "AllianceCreated"
AllianceCreated.Parent = RemoteEvents

local PlayerJoinedAlliance = Instance.new("RemoteEvent")
PlayerJoinedAlliance.Name = "PlayerJoinedAlliance"
PlayerJoinedAlliance.Parent = RemoteEvents

local PlayerLeftAlliance = Instance.new("RemoteEvent")
PlayerLeftAlliance.Name = "PlayerLeftAlliance"
PlayerLeftAlliance.Parent = RemoteEvents

local PlayerRemovedFromAlliance = Instance.new("RemoteEvent")
PlayerRemovedFromAlliance.Name = "PlayerRemovedFromAlliance"
PlayerRemovedFromAlliance.Parent = RemoteEvents

local PlayerInvitedToAlliance = Instance.new("RemoteEvent")
PlayerInvitedToAlliance.Name = "PlayerInvitedToAlliance"
PlayerInvitedToAlliance.Parent = RemoteEvents

local AllianceDisbanded = Instance.new("RemoteEvent")
AllianceDisbanded.Name = "AllianceDisbanded"
AllianceDisbanded.Parent = RemoteEvents

local AllianceError = Instance.new("RemoteEvent")
AllianceError.Name = "AllianceError"
AllianceError.Parent = RemoteEvents

local CreateAllianceRequest = Instance.new("RemoteEvent")
CreateAllianceRequest.Name = "CreateAllianceRequest"
CreateAllianceRequest.Parent = RemoteEvents

local JoinAllianceRequest = Instance.new("RemoteEvent")
JoinAllianceRequest.Name = "JoinAllianceRequest"
JoinAllianceRequest.Parent = RemoteEvents

local LeaveAllianceRequest = Instance.new("RemoteEvent")
LeaveAllianceRequest.Name = "LeaveAllianceRequest"
LeaveAllianceRequest.Parent = RemoteEvents

local RemoveFromAllianceRequest = Instance.new("RemoteEvent")
RemoveFromAllianceRequest.Name = "RemoveFromAllianceRequest"
RemoveFromAllianceRequest.Parent = RemoteEvents

local InviteToAllianceRequest = Instance.new("RemoteEvent")
InviteToAllianceRequest.Name = "InviteToAllianceRequest"
InviteToAllianceRequest.Parent = RemoteEvents

local AcceptAllianceInviteRequest = Instance.new("RemoteEvent")
AcceptAllianceInviteRequest.Name = "AcceptAllianceInviteRequest"
AcceptAllianceInviteRequest.Parent = RemoteEvents

local DenyAllianceInviteRequest = Instance.new("RemoteEvent")
DenyAllianceInviteRequest.Name = "DenyAllianceInviteRequest"
DenyAllianceInviteRequest.Parent = RemoteEvents

local DisbandAllianceRequest = Instance.new("RemoteEvent")
DisbandAllianceRequest.Name = "DisbandAllianceRequest"
DisbandAllianceRequest.Parent = RemoteEvents