local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AllianceSystem = {}

local alliances = {}
local playerAlliance = {}

function AllianceSystem.CreateAlliance(leader, allianceName)
    local allianceId = #alliances + 1
    alliances[allianceId] = {
        name = allianceName,
        leader = leader.UserId,
        members = {leader.UserId},
        invited = {},
        level = 1, -- Example attribute: Alliance level
        bonuses = {}  -- Example attribute: Store alliance bonuses
    }
    playerAlliance[leader.UserId] = allianceId
    return true, allianceId
end

function AllianceSystem.InvitePlayer(leader, playerToInvite, allianceId)
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
            event:FireAllClients(alliance.name, player.UserId)
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
    table.remove(alliance.members, table.find(alliance.members, player.UserId))
    playerAlliance[player.UserId] = nil
    return true
end

function AllianceSystem.GetAllianceMembers(allianceId)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found or does not exist yet."
    end
    local members = {}
    for _, userId in ipairs(alliance.members) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            table.insert(members, player.Name)
        end
    end
    return members
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

    -- Remove all members from the alliance
    for _, userId in ipairs(alliance.members) do
        playerAlliance[userId] = nil
    end

    -- Remove the alliance
    alliances[allianceId] = nil
    return true
end



return AllianceSystem