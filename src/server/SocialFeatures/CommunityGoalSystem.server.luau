--luau
-- src/server/SocialFeatures/CommunityGoalSystem.server.luau

local CommunityGoalSystem = {}
CommunityGoalSystem.__index = CommunityGoalSystem

--[[
    CommunityGoalData Structure:
    {
        goalId = string,
        description = string,
        target = number, -- Total amount needed
        currentProgress = number, -- Current amount completed
        participants = { [Player.UserId] = true },
        rewards = table, -- Rewards to be given
        isActive = boolean, -- is active
        startTime = number, -- Timestamp
        endTime = number -- Timestamp,
    }
]]

local communityGoals = {} -- Table to store all community goals
local activeCommunityGoal = nil

function CommunityGoalSystem.new()
    local self = setmetatable({}, CommunityGoalSystem)
    return self
end

function CommunityGoalSystem:CreateCommunityGoal(goalData)
    if activeCommunityGoal then
        warn("There is already an active community goal.")
        return
    end

    if not goalData or not goalData.goalId or not goalData.description or not goalData.target or not goalData.rewards then
        warn("Missing data for CommunityGoal")
        return
    end

    goalData.currentProgress = 0
    goalData.participants = {}
    goalData.isActive = true
    goalData.startTime = os.time()
    goalData.endTime = os.time() + 86400 -- 1 day

    communityGoals[goalData.goalId] = goalData
    activeCommunityGoal = goalData

    print("Community Goal created: ", goalData.goalId)

    -- Trigger new content when a new goal is created
    self:manageNewContent(goalData)
end

function CommunityGoalSystem:ParticipateInCommunityGoal(player, contributionAmount)
    if not activeCommunityGoal or not activeCommunityGoal.isActive then
        warn("No active community goal.")
        return
    end

    local userId = player.UserId
    if not activeCommunityGoal.participants[userId] then
        activeCommunityGoal.participants[userId] = true
        print("Player ", userId, " started participating in the community goal ", activeCommunityGoal.goalId)
    end

    activeCommunityGoal.currentProgress += contributionAmount

    -- Trigger cooperation management
    self:manageCooperation(player, activeCommunityGoal, contributionAmount)

    self:CheckCommunityGoalProgress()
end

function CommunityGoalSystem:CheckCommunityGoalProgress()
    if not activeCommunityGoal or not activeCommunityGoal.isActive then
        return
    end

    if activeCommunityGoal.currentProgress >= activeCommunityGoal.target then
        print("Community goal completed: ", activeCommunityGoal.goalId)
        self:manageRewards(activeCommunityGoal)
        activeCommunityGoal.isActive = false
        activeCommunityGoal = nil -- Clear the active goal
        --Trigger new content
        self:manageNewContent()
    end
end

function CommunityGoalSystem:manageCooperation(player, communityGoal, contributionAmount)
    -- Example: Give a temporary boost to the player
    print("Managing cooperation, giving a temporary boost to the player ", player.UserId)
end

function CommunityGoalSystem:manageNewContent(goalData)
    if goalData then
        -- Example: Trigger the new content related to the created goal
        print("Managing new content triggered by the creation of: ", goalData.goalId)
    else
        -- Example: Trigger the new content related to the completion of the goal
        print("Managing new content triggered by the completion of a goal.")
    end
end

function CommunityGoalSystem:manageRewards(communityGoal)
    -- Example: give rewards to every participant
    for userId, _ in pairs(communityGoal.participants) do
        print("Giving rewards to participant: ", userId)
    end
end

return CommunityGoalSystem