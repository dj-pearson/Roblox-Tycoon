--luau
-- ChallengeSystem.server.luau
local ChallengeSystem = {}

--[[
    Represents a challenge between two players or alliances.
]]
local Challenge = {}
Challenge.__index = Challenge

function Challenge.new(challenger, challenged, challengeType, startTime, endTime, objective)
	local self = setmetatable({}, Challenge)
	self.Challenger = challenger -- Player or Alliance ID
	self.Challenged = challenged -- Player or Alliance ID
	self.ChallengeType = challengeType -- Type of challenge (e.g., "MostRevenue", "MostMembers", "HighestSatisfaction")
	self.StartTime = startTime -- When the challenge begins
	self.EndTime = endTime -- When the challenge ends
	self.Objective = objective -- Specific objective of the challenge (e.g., revenue goal, member goal)
	self.Status = "Pending" -- Status of the challenge (e.g., "Pending", "Accepted", "Declined", "Completed")
	self.Progress = {} -- Progress of each participant (e.g., { [challenger] = 0, [challenged] = 0 })
	self.Spectators = {} -- List of spectators

	return self
end

function Challenge:UpdateProgress(participant, progress)
	self.Progress[participant] = progress
end

function Challenge:AddSpectator(spectator)
	table.insert(self.Spectators, spectator)
end

function Challenge:RemoveSpectator(spectator)
	for i,v in ipairs(self.Spectators) do
		if v == spectator then
			table.remove(self.Spectators, i)
			break
		end
	end
end

--[[
    Creates a new challenge.
]]
function ChallengeSystem.CreateChallenge(challenger, challenged, challengeType, startTime, endTime, objective)
	local newChallenge = Challenge.new(challenger, challenged, challengeType, startTime, endTime, objective)

	print("Challenge created between", challenger, "and", challenged, "of type", challengeType)

	-- Store the challenge
	if not ChallengeSystem.Challenges then
		ChallengeSystem.Challenges = {}
	end
	table.insert(ChallengeSystem.Challenges, newChallenge)

	-- Return the challenge created
	return newChallenge
end

--[[
    Accepts a challenge.
]]
function ChallengeSystem.AcceptChallenge(challenge)
	if challenge.Status == "Pending" then
		challenge.Status = "Accepted"
		print("Challenge accepted between", challenge.Challenger, "and", challenge.Challenged)
		return true
	else
		print("Challenge cannot be accepted.")
		return false
	end
end

--[[
    Denies a challenge.
]]
function ChallengeSystem.DenyChallenge(challenge)
	if challenge.Status == "Pending" then
		challenge.Status = "Declined"
		print("Challenge declined between", challenge.Challenger, "and", challenge.Challenged)
		return true
	else
		print("Challenge cannot be declined.")
		return false
	end
end

--[[
    Completes a challenge.
]]
function ChallengeSystem.CompleteChallenge(challenge)
	if challenge.Status == "Accepted" then
		challenge.Status = "Completed"
		print("Challenge completed between", challenge.Challenger, "and", challenge.Challenged)
		-- Determine the winner and distribute rewards
		local winner = ChallengeSystem.DetermineWinner(challenge)
		if winner then
			ChallengeSystem.ManageRewards(challenge, winner)
		end
		return true
	else
		print("Challenge cannot be completed.")
		return false
	end
end

--[[
    Determines the winner of a challenge.
]]
function ChallengeSystem.DetermineWinner(challenge)
	local challengerProgress = challenge.Progress[challenge.Challenger] or 0
	local challengedProgress = challenge.Progress[challenge.Challenged] or 0

	if challengerProgress > challengedProgress then
		return challenge.Challenger
	elseif challengedProgress > challengerProgress then
		return challenge.Challenged
	else
		return nil
	end
end

--[[
    Manages rewards for a challenge.
]]
function ChallengeSystem.ManageRewards(challenge, winner)
	if winner then
		print(winner, "won the challenge!")
		-- Add reward logic here.
	else
		print("The challenge was a tie!")
	end
end

--[[
    Manages engagement for a challenge.
]]
function ChallengeSystem.ManageEngagement(challenge)
	-- Add engagement logic here.
	print("Managing engagement for challenge between", challenge.Challenger, "and", challenge.Challenged)
end

--[[
    Manages spectator mode for a challenge.
]]
function ChallengeSystem.ManageSpectatorMode(challenge, player, action)
	-- Add spectator mode logic here.
	if action == "join" then
		challenge:AddSpectator(player)
		print(player," joined as spectator for challenge between", challenge.Challenger, "and", challenge.Challenged)
	elseif action == "leave" then
		challenge:RemoveSpectator(player)
		print(player," left as spectator for challenge between", challenge.Challenger, "and", challenge.Challenged)
	end
end

return ChallengeSystem