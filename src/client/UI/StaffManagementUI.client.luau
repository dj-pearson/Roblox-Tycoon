--[[
    This module manages the Staff Management UI.
]]

local StaffManagementUI = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local tabs = {}
local StaffOverviewPanel
local StaffListContainer

local StaffMenu
local MainFrame

function StaffManagementUI.createIcon(iconId)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.Position = UDim2.fromScale(0, 0)
	icon.Image = "rbxassetid://" .. iconId

	return icon
end

function StaffManagementUI.init()
	-- Create the ScreenGui
	local staffManagementGUI = Instance.new("ScreenGui")
	staffManagementGUI.Name = "StaffManagementGUI"
	staffManagementGUI.Parent = PlayerGui
	staffManagementGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	--Create the Main Frame
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.fromScale(1, 1)
	MainFrame.Position = UDim2.fromScale(0, 0)
	MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.ZIndex = 10
	MainFrame.Parent = staffManagementGUI	

	-- Create the Staff Menu
	StaffMenu = Instance.new("Frame")
	StaffMenu.Name = "StaffMenu"
	StaffMenu.Size = UDim2.fromScale(0.8, 0.8)
	StaffMenu.Position = UDim2.fromScale(0.1, 0.1)
	StaffMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	StaffMenu.Parent = MainFrame

	-- Add corner
	local StaffMenuCorner = Instance.new("UICorner")
	StaffMenuCorner.CornerRadius = UDim.new(0, 10)
	StaffMenuCorner.Parent = StaffMenu

	-- Add title
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.fromScale(1, 0.1)
	Title.Text = "Staff Management"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 24
    Title.BackgroundTransparency = 1
	Title.Position = UDim2.fromScale(0, 0)
	Title.Parent = StaffMenu

    -- Create the Tabs Container
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.fromScale(1, 0.1)
    TabsContainer.Position = UDim2.fromScale(0,0)
    TabsContainer.BackgroundColor3 = Color3.new(0,0,0)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = StaffMenu

    -- Create the Tabs
    local tabTexts = {"Staff Overview", "Hire Staff", "Training", "Assignments"}
	local tabNames = {"StaffOverviewPanel", "HireStaffPanel", "TrainingPanel", "AssignmentsPanel"}
	

    local tabWidth = 1 / #tabTexts

    for i, tabText in ipairs(tabTexts) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabText
        tabButton.Size = UDim2.fromScale(tabWidth, 1)
        tabButton.Position = UDim2.fromScale((i - 1) * tabWidth, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Text = tabText
        tabButton.Font = Enum.Font.GothamBold
        tabButton.TextSize = 14
        tabButton.Parent = TabsContainer

        local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 10)
        tabCorner.Parent = tabButton

		--Function to switch the tabs
		tabButton.MouseButton1Click:Connect(function()
			StaffManagementUI.switchTab(tabs[tabNames[i]])
		end)

        -- Create the panels
        local panel = Instance.new("Frame")
		panel.Name = tabNames[i]
        panel.Size = UDim2.fromScale(1, 0.9)
        panel.Position = UDim2.fromScale(0, 0.1)
        panel.BackgroundColor3 = Color3.new(0,0,0)
        panel.BackgroundTransparency = 1
		panel.Visible = false
        panel.Parent = StaffMenu

		tabs[tabNames[i]] = panel

		if panel.Name == "StaffOverviewPanel" then
			StaffOverviewPanel = panel
			--Create the Staff List Container
			StaffListContainer = Instance.new("Frame")
			StaffListContainer = StaffListContainer
			StaffListContainer.Size = UDim2.fromScale(1, 0.9)
			StaffListContainer.Position = UDim2.fromScale(0, 0.1)
			StaffListContainer.BackgroundColor3 = Color3.new(0, 0, 0)
			StaffListContainer.BackgroundTransparency = 1
			StaffListContainer.Parent = StaffOverviewPanel
		elseif panel.Name == "HireStaffPanel" then
			--Create the Hire Staff List Container
			local HireStaffListContainer = Instance.new("Frame")
			HireStaffListContainer.Name = "HireStaffListContainer"
			HireStaffListContainer.Size = UDim2.fromScale(1, 0.9)
			HireStaffListContainer.Position = UDim2.fromScale(0, 0.1)
			HireStaffListContainer.BackgroundColor3 = Color3.new(0, 0, 0)
			HireStaffListContainer.BackgroundTransparency = 1
			HireStaffListContainer.Parent = panel
			-- Add list layout
			local UIListLayoutHire = Instance.new("UIListLayout")
			UIListLayoutHire.FillDirection = Enum.FillDirection.Vertical
			UIListLayoutHire.Parent = HireStaffListContainer

		elseif panel.Name == "TrainingPanel" then
			-- Create the Training List Container
			local TrainingListContainer = Instance.new("Frame")
			TrainingListContainer.Name = "TrainingListContainer"
			TrainingListContainer.Size = UDim2.fromScale(1, 0.9)
			TrainingListContainer.Position = UDim2.fromScale(0, 0.1)
			TrainingListContainer.BackgroundColor3 = Color3.new(0, 0, 0)
			TrainingListContainer.BackgroundTransparency = 1
			TrainingListContainer.Parent = panel

			-- Add list layout
			local UIListLayoutTraining = Instance.new("UIListLayout")
			UIListLayoutTraining.FillDirection = Enum.FillDirection.Vertical
			UIListLayoutTraining.Parent = TrainingListContainer
		elseif panel.Name == "AssignmentsPanel" then
			-- Create the Assignments List Container
			local AssignmentsListContainer = Instance.new("Frame")
			AssignmentsListContainer.Name = "AssignmentsListContainer"
			AssignmentsListContainer.Size = UDim2.fromScale(1, 0.9)
			AssignmentsListContainer.Position = UDim2.fromScale(0, 0.1)
			AssignmentsListContainer.BackgroundColor3 = Color3.new(0, 0, 0)
			AssignmentsListContainer.BackgroundTransparency = 1
			AssignmentsListContainer.Parent = panel

			-- Add list layout
			local UIListLayoutAssignments = Instance.new("UIListLayout")
			UIListLayoutAssignments.FillDirection = Enum.FillDirection.Vertical
			UIListLayoutAssignments.Parent = AssignmentsListContainer
		end

    end

    -- Add list layout
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.FillDirection = Enum.FillDirection.Vertical
    UIListLayout.Parent = StaffListContainer

	StaffManagementUI.switchTab(tabs["StaffOverviewPanel"])
	MainFrame.Visible = false
end

function StaffManagementUI.switchTab(selectedTab)
	for _, tab in pairs(tabs) do
		if tab == selectedTab then
			tab.Visible = true
		else
			tab.Visible = false
		end
	end

    -- Add title
	MainFrame.Visible = false
end

function StaffManagementUI.createAssignmentOption(staffName, assignment)
	--Create Assignment Option Frame
	local AssignmentOption = Instance.new("Frame")
	AssignmentOption.Name = "AssignmentOption"
	AssignmentOption.Size = UDim2.fromScale(1, 0.2)
	AssignmentOption.Position = UDim2.fromScale(0, 0)
	AssignmentOption.BackgroundColor3 = Color3.fromRGB(100,100,100)

    -- Create the Staff Name Label
    local StaffNameLabel = Instance.new("TextLabel")
    StaffNameLabel.Name = "StaffNameLabel"
    StaffNameLabel.Size = UDim2.fromScale(0.5, 0.5)
    StaffNameLabel.Position = UDim2.fromScale(0.1, 0)
    StaffNameLabel.BackgroundColor3 = Color3.new(0,0,0)
    StaffNameLabel.BackgroundTransparency = 1
    StaffNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StaffNameLabel.Font = Enum.Font.GothamBold
    StaffNameLabel.TextSize = 14
    StaffNameLabel.Text = staffName
    StaffNameLabel.Parent = AssignmentOption

    -- Create the Assignment Label
    local AssignmentLabel = Instance.new("TextLabel")
    AssignmentLabel.Name = "AssignmentLabel"
    AssignmentLabel.Size = UDim2.fromScale(0.5, 0.5)
    AssignmentLabel.Position = UDim2.fromScale(0.1, 0.5)
    AssignmentLabel.BackgroundColor3 = Color3.new(0,0,0)
    AssignmentLabel.BackgroundTransparency = 1
    AssignmentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AssignmentLabel.Font = Enum.Font.GothamBold
    AssignmentLabel.TextSize = 12
    AssignmentLabel.Text = assignment
    AssignmentLabel.Parent = AssignmentOption

	local AssignButton = Instance.new("TextButton")
	AssignButton.Name = "AssignButton"
	AssignButton.Size = UDim2.fromScale(0.2, 0.8)
	AssignButton.Position = UDim2.fromScale(0.8, 0.1)
	AssignButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
	AssignButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AssignButton.Text = "Assign"
	AssignButton.Font = Enum.Font.GothamBold
	AssignButton.TextSize = 14
	AssignButton.Parent = AssignmentOption
	return AssignmentOption
end

function StaffManagementUI.addAssignmentOption(staffName, assignment)
	local assignmentOption = StaffManagementUI.createAssignmentOption(staffName, assignment)
	local AssignmentsListContainer = StaffMenu:FindFirstChild("AssignmentsPanel"):FindFirstChild("AssignmentsListContainer")
	assignmentOption.Parent = AssignmentsListContainer
end

function StaffManagementUI.clearAssignmentOptions()
	local AssignmentsListContainer = StaffMenu:FindFirstChild("AssignmentsPanel"):FindFirstChild("AssignmentsListContainer")
	if not AssignmentsListContainer then return end
	for _, child in pairs(AssignmentsListContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name == "AssignmentOption" then
			child:Destroy()
		end
	end
end


function StaffManagementUI.addTrainingOption(trainingName, cost, iconId, duration)
	local trainingOption = StaffManagementUI.createTrainingOption(trainingName, cost, iconId, duration)
	local TrainingListContainer = StaffMenu:FindFirstChild("TrainingPanel"):FindFirstChild("TrainingListContainer")
	trainingOption.Parent = TrainingListContainer
end

function StaffManagementUI.clearTrainingOptions()
	local TrainingListContainer = StaffMenu:FindFirstChild("TrainingPanel"):FindFirstChild("TrainingListContainer")
	if not TrainingListContainer then return end
	for _, child in pairs(TrainingListContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name == "TrainingOption" then
			child:Destroy()
		end
	end
end

function StaffManagementUI.createTrainingOption(trainingName, cost, iconId, duration)
	--Create Training Option Frame
	local TrainingOption = Instance.new("Frame")
	TrainingOption.Name = "TrainingOption"
	TrainingOption.Size = UDim2.fromScale(1, 0.2)
	TrainingOption.Position = UDim2.fromScale(0, 0)
	TrainingOption.BackgroundColor3 = Color3.fromRGB(100,100,100)

	--Create Staff Icon
	local TrainingIcon = Instance.new("ImageLabel")
	TrainingIcon.Name = "TrainingIcon"
	TrainingIcon.Size = UDim2.fromScale(0.1, 1)
	TrainingIcon.Position = UDim2.fromScale(0, 0)
	TrainingIcon.BackgroundColor3 = Color3.new(0,0,0)
	TrainingIcon.BackgroundTransparency = 1
	TrainingIcon.Image = "rbxassetid://" .. iconId
	TrainingIcon.Parent = TrainingOption

	-- Create the Training Name Label
	local TrainingNameLabel = Instance.new("TextLabel")
	TrainingNameLabel.Name = "TrainingNameLabel"
	TrainingNameLabel.Size = UDim2.fromScale(0.5, 0.33)
	TrainingNameLabel.Position = UDim2.fromScale(0.1, 0)
	TrainingNameLabel.BackgroundColor3 = Color3.new(0,0,0)
	TrainingNameLabel.BackgroundTransparency = 1
	TrainingNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TrainingNameLabel.Font = Enum.Font.GothamBold
	TrainingNameLabel.TextSize = 14
	TrainingNameLabel.Text = trainingName
	TrainingNameLabel.Parent = TrainingOption

    -- Create the Training Duration Label
    local TrainingDurationLabel = Instance.new("TextLabel")
    TrainingDurationLabel.Name = "TrainingDurationLabel"
    TrainingDurationLabel.Size = UDim2.fromScale(0.5, 0.33)
    TrainingDurationLabel.Position = UDim2.fromScale(0.1, 0.66)
    TrainingDurationLabel.BackgroundColor3 = Color3.new(0,0,0)
    TrainingDurationLabel.BackgroundTransparency = 1
    TrainingDurationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TrainingDurationLabel.Font = Enum.Font.GothamBold
    TrainingDurationLabel.TextSize = 12
    TrainingDurationLabel.Text = "Duration: " .. duration
    TrainingDurationLabel.Parent = TrainingOption

	-- Create the Training Cost Label
	local TrainingCostLabel = Instance.new("TextLabel")
	TrainingCostLabel.Name = "TrainingCostLabel"
	TrainingCostLabel.Size = UDim2.fromScale(0.5, 0.33)
	TrainingCostLabel.Position = UDim2.fromScale(0.1, 0.33)
	TrainingCostLabel.BackgroundColor3 = Color3.new(0,0,0)
	TrainingCostLabel.BackgroundTransparency = 1
	TrainingCostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TrainingCostLabel.Font = Enum.Font.GothamBold
	TrainingCostLabel.TextSize = 12
	TrainingCostLabel.Text = "Cost: " .. cost
	TrainingCostLabel.Parent = TrainingOption

	local TrainButton = Instance.new("TextButton")
	TrainButton.Name = "TrainButton"
	TrainButton.Size = UDim2.fromScale(0.2, 0.8)
	TrainButton.Position = UDim2.fromScale(0.8, 0.1)
	TrainButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
	TrainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TrainButton.Text = "Train"
	TrainButton.Font = Enum.Font.GothamBold
	TrainButton.TextSize = 14
	TrainButton.Parent = TrainingOption

	return TrainingOption
end
function StaffManagementUI.createHireStaffOption(staffName, cost, iconId)
	--Create Hire Option Frame
	local HireOption = Instance.new("Frame")
	HireOption.Name = "HireOption"
	HireOption.Size = UDim2.fromScale(1, 0.2)
	HireOption.Position = UDim2.fromScale(0, 0)
	HireOption.BackgroundColor3 = Color3.fromRGB(100,100,100)

    --Create Staff Icon
    local StaffIcon = Instance.new("ImageLabel")
    StaffIcon.Name = "StaffIcon"
    StaffIcon.Size = UDim2.fromScale(0.1, 1)
    StaffIcon.Position = UDim2.fromScale(0, 0)
    StaffIcon.BackgroundColor3 = Color3.new(0,0,0)
	StaffIcon.BackgroundTransparency = 1
    StaffIcon.Image = "rbxassetid://" .. iconId
    StaffIcon.Parent = HireOption

    -- Create the Staff Name Label
    local StaffNameLabel = Instance.new("TextLabel")
    StaffNameLabel.Name = "StaffNameLabel"
    StaffNameLabel.Size = UDim2.fromScale(0.5, 0.5)
    StaffNameLabel.Position = UDim2.fromScale(0.1, 0)
    StaffNameLabel.BackgroundColor3 = Color3.new(0,0,0)
    StaffNameLabel.BackgroundTransparency = 1
    StaffNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StaffNameLabel.Font = Enum.Font.GothamBold
    StaffNameLabel.TextSize = 14
    StaffNameLabel.Text = staffName
    StaffNameLabel.Parent = HireOption

    -- Create the Staff Cost Label
    local StaffCostLabel = Instance.new("TextLabel")
    StaffCostLabel.Name = "StaffCostLabel"
    StaffCostLabel.Size = UDim2.fromScale(0.5, 0.5)
    StaffCostLabel.Position = UDim2.fromScale(0.1, 0.5)
    StaffCostLabel.BackgroundColor3 = Color3.new(0,0,0)
    StaffCostLabel.BackgroundTransparency = 1
    StaffCostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StaffCostLabel.Font = Enum.Font.GothamBold
    StaffCostLabel.TextSize = 12
    StaffCostLabel.Text = "Cost: " .. cost
    StaffCostLabel.Parent = HireOption

	return HireOption
end

function StaffManagementUI.addHireStaffOption(staffName, cost, iconId)
	local hireOption = StaffManagementUI.createHireStaffOption(staffName, cost, iconId)
	local HireStaffListContainer = StaffMenu:FindFirstChild("HireStaffPanel"):FindFirstChild("HireStaffListContainer")
	hireOption.Parent = HireStaffListContainer
end

function StaffManagementUI.clearHireStaffOptions()
	local HireStaffListContainer = StaffMenu:FindFirstChild("HireStaffPanel"):FindFirstChild("HireStaffListContainer")
	if not HireStaffListContainer then return end
	for _, child in pairs(HireStaffListContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name == "HireOption" then
			child:Destroy()
		end
	end
end

function StaffManagementUI.openUI()
	MainFrame.Visible = true
end

function StaffManagementUI.createStaffCard(name, level, status)
	-- Create the staff card
	local StaffCard = Instance.new("Frame")
	StaffCard.Name = "StaffCard"
	StaffCard.Size = UDim2.fromScale(1, 0.1)
	StaffCard.Position = UDim2.fromScale(0, 0)
	StaffCard.BackgroundColor3 = Color3.fromRGB(100,100,100)
    
    --Create Avatar
    local Avatar = Instance.new("ImageLabel")
    Avatar.Name = "Avatar"
    Avatar.Size = UDim2.fromScale(0.1, 1)
    Avatar.Position = UDim2.fromScale(0, 0)
    Avatar.BackgroundColor3 = Color3.new(0,0,0)
    Avatar.BackgroundTransparency = 1
    Avatar.Parent = StaffCard

    -- Create the Name Label
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.Size = UDim2.fromScale(0.5, 0.5)
    NameLabel.Position = UDim2.fromScale(0.1, 0)
    NameLabel.BackgroundColor3 = Color3.new(0,0,0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 14
    NameLabel.Text = name
    NameLabel.Parent = StaffCard

    -- Create the Level Label
    local LevelLabel = Instance.new("TextLabel")
    LevelLabel.Name = "LevelLabel"
    LevelLabel.Size = UDim2.fromScale(0.5, 0.5)
    LevelLabel.Position = UDim2.fromScale(0.1, 0.5)
    LevelLabel.BackgroundColor3 = Color3.new(0,0,0)
    LevelLabel.BackgroundTransparency = 1
    LevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LevelLabel.Font = Enum.Font.GothamBold
    LevelLabel.TextSize = 12
    LevelLabel.Text = "Level " .. level
    LevelLabel.Parent = StaffCard

    -- Create the Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.fromScale(0.2, 1)
    StatusLabel.Position = UDim2.fromScale(0.8, 0)
    StatusLabel.BackgroundColor3 = Color3.new(0,0,0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 14
    StatusLabel.Text = status
	StatusLabel.Parent = StaffCard
	
	return StaffCard
end

function StaffManagementUI.addStaffCard(name, level, status)
	local staffCard = StaffManagementUI.createStaffCard(name, level, status)
	staffCard.Parent = StaffListContainer
end

function StaffManagementUI.clearStaffCards()
	for _, child in pairs(StaffListContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name == "StaffCard" then
			child:Destroy()
		end
	end
end

return {
	init = StaffManagementUI.init,
	openUI = StaffManagementUI.openUI,
    createIcon = StaffManagementUI.createIcon,
    addStaffCard = StaffManagementUI.addStaffCard,
    clearStaffCards = StaffManagementUI.clearStaffCards,
	addHireStaffOption = StaffManagementUI.addHireStaffOption,
	clearHireStaffOptions = StaffManagementUI.clearHireStaffOptions
	addAssignmentOption = StaffManagementUI.addAssignmentOption,
	clearAssignmentOptions = StaffManagementUI.clearAssignmentOptions
	addTrainingOption = StaffManagementUI.addTrainingOption,
	clearTrainingOptions = StaffManagementUI.clearTrainingOptions
	
}
