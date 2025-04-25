--lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AllianceUI = {} 
local AllianceClient 

local UI = script.Parent:WaitForChild("AllianceUIFrame") -- Replace with your actual UI path
local allianceMenu 

-- UI elements
local joinAllianceButton, joinAllianceButton2
local disbandAllianceButton
local allianceFrame = UI:WaitForChild("AllianceFrame")
local leaveAllianceButton = allianceFrame:WaitForChild("LeaveAllianceButton")
local viewAllianceButton
local removePlayerButton
local removePlayerInput = allianceFrame:WaitForChild("RemovePlayerInput")
local invitePlayerButton = allianceFrame:WaitForChild("InvitePlayerButton")
local invitePlayerInput = allianceFrame:WaitForChild("InvitePlayerInput")
local disbandAllianceButton = allianceFrame:WaitForChild("DisbandAllianceButton")
local noAllianceFrame = UI:FindFirstChild("NoAllianceFrame") or Instance.new("Frame")
local createAllianceName, createAllianceButton
local joinAllianceName
local removePlayerName
local invitePlayerName
local playerToRemove = ""

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
	local memberListContainer
	-- Assigning AllianceClient from the passed module
	AllianceClient = clientModule
	-- Create the AllianceMenu frame
	allianceMenu = Instance.new("Frame")
	allianceMenu.Name = "AllianceMenu"
	allianceMenu.Size = UDim2.fromScale(0.8, 0.8)
	allianceMenu.Position = UDim2.fromScale(0.1, 0.1)
	allianceMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	allianceMenu.ZIndex = 15
	allianceMenu.Visible = false 
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = allianceMenu
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = "Alliance Menu"
	titleLabel.Parent = allianceMenu
	titleLabel.Size = UDim2.fromScale(1,0.1)
	titleLabel.Position = UDim2.fromScale(0,0)
	titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextScaled = true
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	--Create the text box to receive the name of the alliance
	createAllianceName = Instance.new("TextBox")
	createAllianceName.Name = "CreateAllianceName"
	createAllianceName.PlaceholderText = "Alliance Name"
	createAllianceName.Size = UDim2.fromScale(0.4,0.1)
	createAllianceName.Position = UDim2.fromScale(0.1,0.4)
	createAllianceName.Visible = false
	createAllianceName.Parent = allianceMenu

	createAllianceButton = Instance.new("TextButton")
	createAllianceButton.Name = "CreateAllianceButton"
	createAllianceButton.Text = "Create Alliance"
	createAllianceButton.Visible = false
	createAllianceButton.TextColor3 = Color3.new(1, 1, 1)
	createAllianceButton.Parent = allianceMenu

	--Create the text box to receive the name of the alliance to join
	joinAllianceName = Instance.new("TextBox")
	joinAllianceName.Name = "JoinAllianceName"
	joinAllianceName.PlaceholderText = "Alliance Name"
	joinAllianceName.Size = UDim2.fromScale(0.4,0.1)
	joinAllianceName.Position = UDim2.fromScale(0.1,0.55)
	joinAllianceName.Visible = false
	joinAllianceName.Parent = allianceMenu
	joinAllianceButton2 = Instance.new("TextButton")
	joinAllianceButton2.Name = "JoinAllianceButton2"
	joinAllianceButton2.Text = "Join Alliance"
	joinAllianceButton2.Visible = false
	-- Create the Join Alliance button
	joinAllianceButton = Instance.new("TextButton")
	joinAllianceButton.Text = "Join Alliance"
	joinAllianceButton.TextColor3 = Color3.new(1, 1, 1)

	--Create the text box to receive the name of the player to remove
	local removePlayerName = Instance.new("TextBox")
	removePlayerName.Name = "RemovePlayerName"
	removePlayerName.PlaceholderText = "Player Name"
	removePlayerName.Size = UDim2.fromScale(0.4,0.1)
	removePlayerName.Position = UDim2.fromScale(0.1,0.7)
	removePlayerName.Visible = false
	joinAllianceButton.TextColor3 = Color3.new(1, 1, 1)
	joinAllianceButton.Parent = allianceMenu
	
	--Create the text box to receive the name of the player to invite
	invitePlayerName = Instance.new("TextBox")
	invitePlayerName.Name = "InvitePlayerName"
	invitePlayerName.PlaceholderText = "Player Name"
	invitePlayerName.Size = UDim2.fromScale(0.4,0.1)
	invitePlayerName.Position = UDim2.fromScale(0.1,0.85)
	invitePlayerName.Visible = false
	invitePlayerName.Parent = allianceMenu
	
	-- Create the Leave Alliance button
	leaveAllianceButton = Instance.new("TextButton")
	leaveAllianceButton.Name = "LeaveAllianceButton"

	leaveAllianceButton.Text = "Leave Alliance"
	leaveAllianceButton.TextColor3 = Color3.new(1, 1, 1)
	leaveAllianceButton.Parent = allianceMenu

	-- Create the View Alliance button
	viewAllianceButton = Instance.new("TextButton")
	viewAllianceButton.Name = "ViewAllianceButton"
	viewAllianceButton.Text = "View Alliance"
	viewAllianceButton.TextColor3 = Color3.new(1, 1, 1)
	viewAllianceButton.Parent = allianceMenu
	
	removePlayerButton = Instance.new("TextButton")
	removePlayerButton.TextColor3 = Color3.new(1, 1, 1)
	removePlayerButton.Name = "RemovePlayerButton"
	removePlayerButton.Text = "Remove Player"
	removePlayerButton.Visible = false
	removePlayerButton.Parent = allianceMenu
	allianceMenu.Parent = UI

	viewAllianceButton.MouseButton1Click:Connect(function()
			AllianceUI.displayError("Please enter an alliance ID.")
		end)

	leaveAllianceButton.MouseButton1Click:Connect(function()
		AllianceClient.sendLeaveAllianceRequest() 
	end)	

	leaveAllianceButton.MouseButton1Click:Connect(function()
		AllianceUI.displayNoAlliance()
	end)
	
	createAllianceButton.MouseButton1Click:Connect(function()
		AllianceClient.sendCreateAllianceRequest(createAllianceName.Text)
	end)
	
	joinAllianceButton.MouseButton1Click:Connect(function()
			AllianceUI.displayAllianceInfo()
	end)
	
	joinAllianceButton2.MouseButton1Click:Connect(function()
		AllianceClient.sendJoinAllianceRequest(joinAllianceName.Text)
	end)
	
	removePlayerButton.MouseButton1Click:Connect(function()
		if playerToRemove ~= "" then
			AllianceClient.sendRemoveFromAllianceRequest(playerToRemove)
		else
			AllianceUI.displayError("Please enter a player to remove.")
		end
	end)

	local invitePlayerButton = Instance.new("TextButton")
	invitePlayerButton.Name = "InvitePlayerButton"
	invitePlayerButton.Text = "Invite Player"
	invitePlayerButton.TextColor3 = Color3.new(1, 1, 1)
	invitePlayerButton.Visible = false
	invitePlayerButton.Parent = allianceMenu
	invitePlayerButton.MouseButton1Click:Connect(function()
		AllianceClient.sendInviteToAllianceRequest(invitePlayerName.Text)
	end)
	disbandAllianceButton = Instance.new("TextButton")
	disbandAllianceButton.Name = "DisbandAllianceButton"
	disbandAllianceButton.Text = "Disband Alliance"
	disbandAllianceButton.TextColor3 = Color3.new(1, 1, 1)
	disbandAllianceButton.Visible = false
	disbandAllianceButton.Parent = allianceMenu
	

	removePlayerButton.MouseButton1Click:Connect(function()
		AllianceClient.sendRemoveFromAllianceRequest(removePlayerName.Text)
	end)
	disbandAllianceButton.MouseButton1Click:Connect(function()
		AllianceClient.sendDisbandAllianceRequest()
	end)
	
	-- This is a duplicate viewAllianceButton connection - removing duplicate to fix syntax error
	
	-- This is a duplicate disbandAllianceButton connection - removing duplicate to fix syntax error
	removePlayerButton.Parent = allianceMenu
	
	joinAllianceButton.Size = UDim2.fromScale(0.3,0.1)
	disbandAllianceButton.Size = UDim2.fromScale(0.3,0.1)
	joinAllianceButton.Position = UDim2.fromScale(0.1,0.2)
	leaveAllianceButton.Size = UDim2.fromScale(0.3,0.1)
	leaveAllianceButton.Position = UDim2.fromScale(0.1,0.2)
	viewAllianceButton.Size = UDim2.fromScale(0.3,0.1)
	viewAllianceButton.Position = UDim2.fromScale(0.5,0.2)
	AllianceUI.displayNoAlliance()	

	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
end

function AllianceUI.displayAllianceInfo(allianceName, memberList)
	removePlayerName.Visible = true
	removePlayerButton.Visible = true
	invitePlayerName.Visible = true
	disbandAllianceButton.Visible = true
	invitePlayerButton.Visible = true
	if joinAllianceButton then
		joinAllianceButton.Visible = false
	end
	if joinAllianceButton2 then
		joinAllianceButton2.Visible = false
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
	if joinAllianceButton then
		joinAllianceButton.Visible = true
	end
	if leaveAllianceButton then
		leaveAllianceButton.Visible = false
	end
	if viewAllianceButton then
		viewAllianceButton.Visible = false
	end	
	if createAllianceName then
		createAllianceName.Visible = true
	end
	if joinAllianceName then
		joinAllianceName.Visible = true
	end
	joinAllianceButton2.Visible = true
	createAllianceButton.Visible = true
	removePlayerName.Visible = false
	invitePlayerName.Visible = false
	invitePlayerButton.Visible = false
	removePlayerButton.Visible = false

	if disbandAllianceButton then
		disbandAllianceButton.Visible = false
	end
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

function AllianceUI.showAllianceMenu()
	allianceMenu.Visible = true
end

function AllianceUI.hideAllianceMenu()
	allianceMenu.Visible = false
end

return {
	initialize = AllianceUI.initialize,
	displayNoAlliance = AllianceUI.displayNoAlliance,
	displayAllianceInfo = AllianceUI.displayAllianceInfo,
	displayError = AllianceUI.displayError,
	displayAllianceInvitations = AllianceUI.displayAllianceInvitations,
	showAllianceMenu = AllianceUI.showAllianceMenu,
	hideAllianceMenu = AllianceUI.hideAllianceMenu,
	joinAllianceButton = joinAllianceButton,
	viewAllianceButton = viewAllianceButton,
	leaveAllianceButton = leaveAllianceButton,
	removePlayerButton = removePlayerButton,
	joinAllianceButton2 = joinAllianceButton2
}
