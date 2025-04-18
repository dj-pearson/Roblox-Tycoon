--lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AllianceUI = {} 
local AllianceClient 

local UI = script.Parent:WaitForChild("AllianceUIFrame") -- Replace with your actual UI path

local allianceNameLabel = UI:WaitForChild("AllianceNameLabel")
local memberListContainer = UI:WaitForChild("MemberListContainer")

local noAllianceFrame = UI:WaitForChild("NoAllianceFrame")
local createAllianceButton = noAllianceFrame:WaitForChild("CreateAllianceButton")
local createAllianceInput = noAllianceFrame:WaitForChild("CreateAllianceInput")
local joinAllianceButton = noAllianceFrame:WaitForChild("JoinAllianceButton")
local joinAllianceInput = noAllianceFrame:WaitForChild("JoinAllianceInput")
local noAllianceMessage = noAllianceFrame:WaitForChild("NoAllianceMessage")

local allianceFrame = UI:WaitForChild("AllianceFrame")
local leaveAllianceButton = allianceFrame:WaitForChild("LeaveAllianceButton")
local removePlayerButton = allianceFrame:WaitForChild("RemovePlayerButton")
local removePlayerInput = allianceFrame:WaitForChild("RemovePlayerInput")
local invitePlayerButton = allianceFrame:WaitForChild("InvitePlayerButton")
local invitePlayerInput = allianceFrame:WaitForChild("InvitePlayerInput")
local disbandAllianceButton = allianceFrame:WaitForChild("DisbandAllianceButton")

local invitationsFrame = UI:WaitForChild("InvitationsFrame")
local invitationsContainer = invitationsFrame:WaitForChild("InvitationsContainer")

local errorLabel = UI:WaitForChild("ErrorLabel")

local function createMemberUI(playerName)
	local textLabel = Instance.new("TextLabel")
	textLabel.Text = playerName
	textLabel.Size = UDim2.new(1, 0, 0, 20)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	return textLabel
end

function AllianceUI.initialize(clientModule)
	AllianceClient = clientModule

	-- Connect UI events to AllianceClient functions
	createAllianceButton.MouseButton1Click:Connect(function()
		local allianceName = createAllianceInput.Text
		if allianceName ~= "" then
			AllianceClient.sendCreateAllianceRequest(allianceName)
			AllianceUI.hideCreateAllianceUI()
		else
			AllianceUI.displayError("Please enter an alliance name.")
		end
	end)

	joinAllianceButton.MouseButton1Click:Connect(function()
		local allianceId = joinAllianceInput.Text
		if allianceId ~= "" then
			AllianceClient.sendJoinAllianceRequest(allianceId)
		else
			AllianceUI.displayError("Please enter an alliance ID.")
		end
	end)

	leaveAllianceButton.MouseButton1Click:Connect(function()
		AllianceClient.sendLeaveAllianceRequest()
	end)

	removePlayerButton.MouseButton1Click:Connect(function()
		local playerToRemove = removePlayerInput.Text
		if playerToRemove ~= "" then
			AllianceClient.sendRemoveFromAllianceRequest(playerToRemove)
		else
			AllianceUI.displayError("Please enter a player to remove.")
		end
	end)

	invitePlayerButton.MouseButton1Click:Connect(function()
		local playerToInvite = invitePlayerInput.Text
		if playerToInvite ~= "" then
			AllianceClient.sendInviteToAllianceRequest(playerToInvite)
		else
			AllianceUI.displayError("Please enter a player to invite.")
		end
	end)

	disbandAllianceButton.MouseButton1Click:Connect(function()
		AllianceClient.sendDisbandAllianceRequest()
	end)

	AllianceUI.displayNoAlliance()
end

function AllianceUI.displayAllianceInfo(allianceName, memberList)
	allianceNameLabel.Text = allianceName

	-- Clear previous member list
	for _, child in ipairs(memberListContainer:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	-- Display member list
	for _, playerName in ipairs(memberList) do
		local memberUI = createMemberUI(playerName)
		memberUI.Parent = memberListContainer
	end

	allianceFrame.Visible = true
	noAllianceFrame.Visible = false
	invitationsFrame.Visible = false
end

function AllianceUI.displayAllianceInvitations(invitations)
	-- Clear previous invitations
	for _, child in ipairs(invitationsContainer:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	if next(invitations) == nil then
		invitationsFrame.Visible = false
		return
	end

	for allianceName, _ in pairs(invitations) do
		local textButton = Instance.new("TextButton")
		textButton.Text = "Join " .. allianceName
		textButton.Size = UDim2.new(1, 0, 0, 30)
		textButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
		textButton.TextColor3 = Color3.new(1, 1, 1)
		textButton.Font = Enum.Font.SourceSansBold
		textButton.MouseButton1Click:Connect(function()
			AllianceClient.sendAcceptAllianceInviteRequest()
		end)
		textButton.Parent = invitationsContainer
	end
	invitationsFrame.Visible = true
end

function AllianceUI.displayNoAlliance()
	allianceFrame.Visible = false
	noAllianceFrame.Visible = true
	invitationsFrame.Visible = false
	noAllianceMessage.Text = "You are not in an alliance."
end

function AllianceUI.showCreateAllianceUI()
	createAllianceInput.Visible = true
	createAllianceButton.Visible = true
end

function AllianceUI.hideCreateAllianceUI()
	createAllianceInput.Visible = false
	createAllianceButton.Visible = false
end

function AllianceUI.displayError(message)
	errorLabel.Text = message
	if message and message ~= "" then
		print("Alliance UI Error: ", message)
		errorLabel.Visible = true
	else
		errorLabel.Visible = false
	end
end

return AllianceUI