local ReputationUI = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReputationFrame -- Define this in your GUI

local function updateUI(reputation: number, level: string?, benefits: {string}?)
	if not ReputationFrame then
		warn("Reputation Frame not found!")
		return
	end

	-- Example: Assuming you have a TextLabel inside ReputationFrame to display the reputation
	local reputationLabel = ReputationFrame:FindFirstChild("ReputationLabel")
	if reputationLabel and reputationLabel:IsA("TextLabel") then
		reputationLabel.Text = "Reputation: " .. tostring(reputation) .. "/100"
		if level then
			reputationLabel.Text ..= " (" .. level .. ")"
		end
		if benefits and #benefits > 0 then
			reputationLabel.Text ..= "\nBenefits: " .. table.concat(benefits, ", ")
		end
	else
		warn("ReputationLabel not found or is not a TextLabel inside ReputationFrame")
	end

	local levelLabel = ReputationFrame:FindFirstChild("LevelLabel")
	if levelLabel and levelLabel:IsA("TextLabel") then
		if level then
			levelLabel.Text = "Level: " .. level
		else
			levelLabel.Text = ""
		end
	else
		warn("ReputationLabel not found or is not a TextLabel inside ReputationFrame")
	end

	-- Example: You could also update a progress bar or other UI elements here
	-- if ReputationFrame:FindFirstChild("ReputationProgressBar") and ReputationFrame.ReputationProgressBar:IsA("Frame") then
	--      ReputationFrame.ReputationProgressBar.Size = UDim2.new(reputation / 100, 0, 1, 0)
	-- end
end

function ReputationUI.init(frame)
	ReputationFrame = frame
	print("Reputation UI initialized.")
end

function ReputationUI.UpdateReputation(reputation: number, level: string?)
	updateUI(reputation, level)
end

function ReputationUI.UpdateBenefits(benefits: {string}?)
	updateUI(nil, nil, benefits) -- Pass nil for reputation and level, only updating benefits
end

return ReputationUI