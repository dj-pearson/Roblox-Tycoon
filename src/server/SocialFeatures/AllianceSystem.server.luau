local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AllianceSystem = {}
local alliances = {}
local playerAlliance = {}

local allianceRewards = {
    [2] = {memberCapacity = 5}, -- Example: Level 2 reward
    [3] = {gymRevenue = 1.1},    -- Example: Level 3 reward (10% increase)
    [4] = {equipmentDiscount = 0.9}, -- Example: Level 4 reward (10% discount)
}
local levelThresholds = {    
    [2] = 100,
	[3] = 250,
	[4] = 500,
}
local alliances = {}
local playerAlliance = {}

function AllianceSystem.CreateAlliance(leader, allianceName)
    local allianceId = #alliances + 1
    alliances[allianceId] = {
        name = allianceName,
        xp = 0,
        level = 1,
        membersRoles = {[leader.UserId] = "Leader"},
        invited = {},
        bank = {},
        bonuses = {},
		members = {leader.UserId}
    }
    playerAlliance[leader.UserId] = allianceId
    return true, allianceId
end

function AllianceSystem.AddAllianceXP(allianceId, amount)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found."
    end
    alliance.xp = alliance.xp + amount    
    AllianceSystem.CheckAllianceLevelUp(allianceId)
    return true
end

function AllianceSystem.CheckAllianceLevelUp(allianceId)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end

	local currentLevel = alliance.level
	local nextLevel = currentLevel + 1
	local requiredXP = levelThresholds[nextLevel]

	if requiredXP and alliance.xp >= requiredXP then
		alliance.level = nextLevel
		-- Implement rewards here if needed
		local event = ReplicatedStorage:WaitForChild("AllianceLevelUp")
		if event then
			for _, userId in ipairs(alliance.members) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					event:FireClient(player, alliance.name, nextLevel)
				end
			end
		end
	end
	return true
end

function AllianceSystem.GetAllianceRewards(allianceId)
    local alliance = alliances[allianceId]
    if not alliance then return false, "Alliance not found" end

    local rewards = allianceRewards[alliance.level]
    if rewards then
        for rewardType, value in pairs(rewards) do
            if rewardType == "memberCapacity" then
                alliance.bonuses.memberCapacity = (alliance.bonuses.memberCapacity or 0) + value
            elseif rewardType == "gymRevenue" then
                alliance.bonuses.gymRevenue = (alliance.bonuses.gymRevenue or 1) * value
            elseif rewardType == "equipmentDiscount" then
                alliance.bonuses.equipmentDiscount = (alliance.bonuses.equipmentDiscount or 1) * value
            end
        end
    end
end

function AllianceSystem.GetAllianceRole(allianceId, userId)
    local alliance = alliances[allianceId]
    if not alliance then
        return false, "Alliance not found"
    end

    return alliance.membersRoles[userId] or "Member" -- Default to "Member" if no role is found
end

function AllianceSystem.ChangeAllianceRole(allianceId, userId, newRole, leader)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end
	
	if alliance.membersRoles[leader.UserId] ~= "Leader" then return false, "Only the leader can change roles" end
	if userId == leader.UserId then return false, "The leader can't change his own role" end

	alliance.membersRoles[userId] = newRole
	return true
end

function AllianceSystem.HasAlliancePermission(allianceId, userId, permission)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end
	
	local role = alliance.membersRoles[userId]
	if role == "Leader" then return true end
	if role == "Officer" and (permission == "invite" or permission == "kick" or permission == "manageEvents") then return true end

	return false
end

function AllianceSystem.DepositToAllianceBank(allianceId, userId, resource, amount)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end

	local isMember = false
	for k,v in pairs(alliance.membersRoles) do
		if k == userId then isMember = true end
	end
	if not isMember then return false, "You are not a member of this alliance" end

	alliance.bank[resource] = (alliance.bank[resource] or 0) + amount
	return true
end

function AllianceSystem.WithdrawFromAllianceBank(allianceId, userId, resource, amount)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end
	
	if not AllianceSystem.HasAlliancePermission(allianceId, userId, "manageBank") then
		return false, "You do not have permission to withdraw from the bank"
	end
	
	if (alliance.bank[resource] or 0) < amount then
		return false, "Not enough resources in the bank"
	end
	
	alliance.bank[resource] = alliance.bank[resource] - amount
	return true
end

function AllianceSystem.GetAllianceBank(allianceId)
	local alliance = alliances[allianceId]
	if not alliance then return false, "Alliance not found" end
	
	return alliance.bank
end
function AllianceSystem.InvitePlayer(leader, playerToInvite, allianceId)
    local allianceId = playerAlliance[leader.UserId]
    if not allianceId then
        return false, "You are not in an alliance."
    end

    local alliance = alliances[allianceId]
        if alliance.membersRoles[leader.UserId] ~= "Leader" then
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
        if alliance.membersRoles[leader.UserId] ~= "Leader" then
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