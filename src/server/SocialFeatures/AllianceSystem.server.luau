-- AllianceSystem.client.lua
local AllianceSystem = {}

--[[
    Alliance Data Structure:
    alliances = {
        [allianceId] = {
            name = "Alliance Name",
            leader = playerId,
            members = { playerId, playerId, ... },
            invited = { playerId, playerId, ... },
            bonuses = { ... }, -- Alliance-wide bonuses
            resources = { ... }, -- Shared resources
            events = { ... },    -- Active alliance events
            score = 0            -- Alliance leaderboard score
        },
        ...
    }
]]

local alliances = {}
local playerAlliance = {} -- Track which alliance a player belongs to

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function generateAllianceId()
    -- Implement a unique ID generator (e.g., random string or number)
    return os.time() .. math.random(1, 1000)
end

function AllianceSystem.CreateAlliance(player, allianceName)
    if playerAlliance[player.UserId] then
        return false, "You are already in an alliance."
    end

    local allianceId = generateAllianceId()
    alliances[allianceId] = {
        name = allianceName,
        leader = player.UserId,
        members = { player.UserId },
        invited = {},
        bonuses = {},
        resources = {},
        events = {},
        score = 0
    }
    playerAlliance[player.UserId] = allianceId
    
    local event = ReplicatedStorage:WaitForChild("AllianceCreated")
    if event then
        event:FireClient(player, allianceName, allianceId)
    else
        warn("AllianceCreated event not found in ReplicatedStorage")
    end
    return true, allianceId
end

function AllianceSystem.JoinAlliance(player, allianceId)
    if playerAlliance[player.UserId] then
        return false, "You are already in an alliance."
    end

    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end

    if table.find(alliance.invited, player.UserId) then
        table.remove(alliance.invited, table.find(alliance.invited, player.UserId))
        table.insert(alliance.members, player.UserId)
        playerAlliance[player.UserId] = allianceId
        
        local event = ReplicatedStorage:WaitForChild("PlayerJoinedAlliance")
        if event then
            event:FireAllClients(allianceName, player.UserId)
        else
            warn("PlayerJoinedAlliance event not found in ReplicatedStorage")
        end
        return true, allianceId
    else
        return false, "You are not invited to this alliance."
    end
end

function AllianceSystem.LeaveAlliance(player)
    local allianceId = playerAlliance[player.UserId]
    if not allianceId then
        return false, "You are not in an alliance."
    end

    local alliance = alliances[allianceId]
    if player.UserId == alliance.leader then
        return false, "The leader can't leave the alliance."
    end
    
    table.remove(alliance.members, table.find(alliance.members, player.UserId))
    playerAlliance[player.UserId] = nil

    local event = ReplicatedStorage:WaitForChild("PlayerLeftAlliance")
    if event then
        event:FireAllClients(alliance.name, player.UserId)
    else
        warn("PlayerLeftAlliance event not found in ReplicatedStorage")
    end
    
    return true
end

function AllianceSystem.RemoveFromAlliance(leader, playerToRemove)
    local allianceId = playerAlliance[leader.UserId]
    if not allianceId then
        return false, "You are not in an alliance."
    end

    local alliance = alliances[allianceId]
    if alliance.leader ~= leader.UserId then
        return false, "You are not the leader of this alliance."
    end

    if not playerAlliance[playerToRemove.UserId] or playerAlliance[playerToRemove.UserId] ~= allianceId then
        return false, "Player is not in this alliance."
    end
    
    table.remove(alliance.members, table.find(alliance.members, playerToRemove.UserId))
    playerAlliance[playerToRemove.UserId] = nil
    
    local event = ReplicatedStorage:WaitForChild("PlayerRemovedFromAlliance")
    if event then
        event:FireAllClients(alliance.name, playerToRemove.UserId)
    else
        warn("PlayerRemovedFromAlliance event not found in ReplicatedStorage")
    end
    return true
end

function AllianceSystem.InviteToAlliance(leader, playerToInvite)
    local allianceId = playerAlliance[leader.UserId]
    if not allianceId then
        return false, "You are not in an alliance."
    end

    local alliance = alliances[allianceId]
    if alliance.leader ~= leader.UserId then
        return false, "You are not the leader of this alliance."
    end
    
     if playerAlliance[playerToInvite.UserId] then
        return false, "Player is already in an alliance."
    end

    if table.find(alliance.invited, playerToInvite.UserId) then
        return false, "Player is already invited to this alliance."
    end

    table.insert(alliance.invited, playerToInvite.UserId)
    
    local event = ReplicatedStorage:WaitForChild("PlayerInvitedToAlliance")
    if event then
        event:FireClient(game.Players:GetPlayerByUserId(playerToInvite.UserId), alliance.name)
    else
        warn("PlayerInvitedToAlliance event not found in ReplicatedStorage")
    end
    return true
end

function AllianceSystem.AcceptAllianceInvite(player)
    local allianceId = playerAlliance[player.UserId]
    if allianceId then
        return false, "You are already in an alliance."
    end
    local playerInvite = nil
    for id, alliance in pairs(alliances) do
        if table.find(alliance.invited, player.UserId) then
            playerInvite = id
            break
        end
    end
    if not playerInvite then
        return false, "You have no invitations to any alliance."
    end
    
    AllianceSystem.JoinAlliance(player, playerInvite)

    return true
end

function AllianceSystem.DenyAllianceInvite(player)
     local playerInvite = nil
    for id, alliance in pairs(alliances) do
        if table.find(alliance.invited, player.UserId) then
            playerInvite = id
            break
        end
    end
    if not playerInvite then
        return false, "You have no invitations to any alliance."
    end
     local alliance = alliances[playerInvite]
    table.remove(alliance.invited, table.find(alliance.invited, player.UserId))

    local event = ReplicatedStorage:WaitForChild("AllianceError")
    if event then
        event:FireClient(player, "You have denied the invitation to join " .. alliance.name)
    else
        warn("AllianceError event not found in ReplicatedStorage")
    end
    
    return true
end

function AllianceSystem.DisbandAlliance(leader)
    local allianceId = playerAlliance[leader.UserId]
    if not allianceId then
        return false, "You are not in an alliance."
    end

    local alliance = alliances[allianceId]
    if alliance.leader ~= leader.UserId then
        return false, "You are not the leader of this alliance."
    end

    for _, memberId in ipairs(alliance.members) do
        playerAlliance[memberId] = nil
    end
    for _, memberId in ipairs(alliance.invited) do
        playerAlliance[memberId] = nil
    end

    local event = ReplicatedStorage:WaitForChild("AllianceDisbanded")
    if event then
        event:FireAllClients(alliance.name)
    else
        warn("AllianceDisbanded event not found in ReplicatedStorage")
    end
    alliances[allianceId] = nil

    return true
end

function AllianceSystem.manageAllianceBonuses(allianceId, bonuses)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end
    alliance.bonuses = bonuses
    return true
end

function AllianceSystem.manageSharedResources(allianceId, resources)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end
    alliance.resources = resources
    return true
end

function AllianceSystem.manageAllianceEvents(allianceId, events)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end
    alliance.events = events
    return true
end

function AllianceSystem.manageAllianceLeaderboards(allianceId, score)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end
    alliance.score = score
    return true
end

return AllianceSystem