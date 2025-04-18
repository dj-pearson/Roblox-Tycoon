--lua
local StaffTrainingSystem = {}

--[[
    StaffTrainingSystem:
    This module manages the staff training system, allowing players to send staff for training, 
    accept or deny training requests, and share staff between gyms.
]]

--[[
    Data Structure:
    staffTrainingRequests = {
        [player1Id] = { -- The player sending the request
            [player2Id] = { -- The player receiving the request
                staff = {staffId1, staffId2},
                status = "pending", -- "accepted", "denied"
            }
        }
    }
]]

local staffTrainingRequests = {}
local sharedStaff = {} --Table to track shared staff

--[[
    SendStaffForTraining(senderPlayerId, receiverPlayerId, staffIds)
    Sends a request to train staff to another player.

    Parameters:
        senderPlayerId (number): The ID of the player sending the staff.
        receiverPlayerId (number): The ID of the player receiving the staff.
        staffIds (table): A table of staff IDs to be trained.
]]
function StaffTrainingSystem.SendStaffForTraining(senderPlayerId, receiverPlayerId, staffIds)
    if not staffTrainingRequests[senderPlayerId] then
        staffTrainingRequests[senderPlayerId] = {}
    end

    if staffTrainingRequests[senderPlayerId][receiverPlayerId] then
        warn("Staff training request already sent to this player.")
        return
    end

    staffTrainingRequests[senderPlayerId][receiverPlayerId] = {
        staff = staffIds,
        status = "pending",
    }

    --[[
        Notify the receiver player here (e.g., send a remote event)
        ...
    ]]
    print("Sent staff training request from", senderPlayerId, "to", receiverPlayerId, "with staff:", staffIds)
end

--[[
    AcceptStaffTraining(receiverPlayerId, senderPlayerId)
    Accepts a staff training request.

    Parameters:
        receiverPlayerId (number): The ID of the player accepting the staff.
        senderPlayerId (number): The ID of the player who sent the staff.
]]
function StaffTrainingSystem.AcceptStaffTraining(receiverPlayerId, senderPlayerId)
    if not staffTrainingRequests[senderPlayerId] or not staffTrainingRequests[senderPlayerId][receiverPlayerId] then
        warn("No staff training request found from this player.")
        return
    end

    local request = staffTrainingRequests[senderPlayerId][receiverPlayerId]
    request.status = "accepted"
    for _, staffId in ipairs(request.staff) do
        if not sharedStaff[staffId] then
            sharedStaff[staffId] = {}
        end
        table.insert(sharedStaff[staffId], {senderPlayerId, receiverPlayerId})
    end
    
    --[[
        Process training here (e.g., modify staff stats, add training time)
        ...
    ]]
    print("Accepted staff training request from", senderPlayerId, "by", receiverPlayerId)

    -- Clean the request
    staffTrainingRequests[senderPlayerId][receiverPlayerId] = nil
end

--[[
    DenyStaffTraining(receiverPlayerId, senderPlayerId)
    Denies a staff training request.

    Parameters:
        receiverPlayerId (number): The ID of the player denying the staff.
        senderPlayerId (number): The ID of the player who sent the staff.
]]
function StaffTrainingSystem.DenyStaffTraining(receiverPlayerId, senderPlayerId)
    if not staffTrainingRequests[senderPlayerId] or not staffTrainingRequests[senderPlayerId][receiverPlayerId] then
        warn("No staff training request found from this player.")
        return
    end

    local request = staffTrainingRequests[senderPlayerId][receiverPlayerId]
    request.status = "denied"
    
    --[[
        Notify the sender player here (e.g., send a remote event)
        ...
    ]]
    print("Denied staff training request from", senderPlayerId, "by", receiverPlayerId)
    
    -- Clean the request
    staffTrainingRequests[senderPlayerId][receiverPlayerId] = nil
end

--[[
    manageCooperativeProgression()
    Handles the logic for cooperative progression.
]]
function StaffTrainingSystem.manageCooperativeProgression()
    --[[
        Implement the logic here, for example, give bonus to the staff, or reward players when training staff.
        ...
    ]]
    print("Managing cooperative progression.")
end

--[[
    manageRelationshipBuilding()
    Handles the logic for relationship building between players.
]]
function StaffTrainingSystem.manageRelationshipBuilding()
    --[[
        Implement the logic here, for example, increase relationship level of players that have shared staff.
        ...
    ]]
    print("Managing relationship building.")
end

--[[
    manageSharedStaff()
    Handles the logic for managing shared staff.
]]
function StaffTrainingSystem.manageSharedStaff()
    --[[
        Implement the logic here.
        ...
    ]]
    print("Managing shared staff.")
end

return StaffTrainingSystem