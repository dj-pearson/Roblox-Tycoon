-- src/client/MembershipBoostUI.client.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local MembershipBoostEvent = ReplicatedStorage:WaitForChild("MembershipBoostEvent") -- Assuming this is your RemoteEvent

local UI = Instance.new("ScreenGui")
UI.Name = "MembershipBoostUI"
UI.Parent = PlayerGui
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.3, 0, 0.1, 0)
MainFrame.Position = UDim2.new(0.35, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = UI

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0.5, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextScaled = true
TitleLabel.TextStrokeTransparency = 0
TitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Membership Boost Event!"
TitleLabel.Parent = MainFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "TimerLabel"
TimerLabel.Size = UDim2.new(1, 0, 0.5, 0)
TimerLabel.Position = UDim2.new(0, 0, 0.5, 0)
TimerLabel.BackgroundColor3 = Color3.new(1, 1, 1)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextColor3 = Color3.new(1, 1, 1)
TimerLabel.TextScaled = true
TimerLabel.TextStrokeTransparency = 0
TimerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Text = ""
TimerLabel.Parent = MainFrame

local function updateTimer(duration)
	if duration <= 0 then
		UI:Destroy()
		return
	end
	local minutes = math.floor(duration / 60)
	local seconds = math.floor(duration % 60)
	TimerLabel.Text = string.format("Time Remaining: %02d:%02d", minutes, seconds)
end

local function handleMembershipBoostStart(duration)
	UI.Enabled = true
	TitleLabel.Text = "Membership Boost Event!"
	
	local timeLeft = duration

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if timeLeft <= 0 then
			if connection then
				connection:Disconnect()
			end
			UI:Destroy()
		else
			timeLeft -= RunService.Heartbeat:Wait()
			updateTimer(timeLeft)
		end
	end)
end

MembershipBoostEvent.OnClientEvent:Connect(handleMembershipBoostStart)

UI.Enabled = false