-- Elevator System Script
-- Handles elevator movement between 5 floors with proper floor transparency and GUI elements

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Configuration (adjust as needed)
local CONFIG = {
	ELEVATOR_SPEED = 0.5, -- Lower value = faster elevator
	DOOR_OPEN_TIME = 2, -- How long doors stay open
	FLOOR_POSITIONS = {
		["1stFloor"] = Vector3.new(3.896, 1.394, -155.009),
		["2ndFloor"] = Vector3.new(3.896, 28.433, -155.009),
		["3rdFloor"] = Vector3.new(3.896, 54.4, -155.009),
		["4thFloor"] = Vector3.new(3.896, 80.255, -155.009),
		["5thFloor"] = Vector3.new(3.896, 121.84, -155.009)
	},
	MOVEMENT_MODELS = {
		"Movement_1",
		"Movement_2",
		"Movement_3",
		"Movement_4",
		"Movement_5"
	},
	FLOOR_TAGS = {
		"1stFloor",
		"2ndFloor",
		"3rdFloor",
		"4thFloor",
		"5thFloor"
	}
}

-- Reference to the elevator model
local elevator = script.Parent

-- Keep track of elevator state
local currentFloor = "1stFloor" -- Start at 1st floor
local isMoving = false
local buttonDebounce = false

-- Get floor folders
local floorFolders = {
	Workspace.Floor["1st Floor"],
	Workspace.Floor["2nd Floor"],
	Workspace.Floor["3rd Floor"],
	Workspace.Floor["4th Floor"],
	Workspace.Floor["5th Floor"]
}

-- Function to check which floors are available
local function getAvailableFloors()
	local availableFloors = {"1stFloor"} -- 1st floor is always available

	-- Check for existence of tagged models for floors 2-5
	for i = 2, 5 do
		local floorTag = CONFIG.FLOOR_TAGS[i]
		local taggedModels = Workspace:GetTagged(floorTag)

		if #taggedModels > 0 then
			table.insert(availableFloors, floorTag)
		end
	end

	return availableFloors
end

-- Function to manage floor transparency during elevator movement
local function manageFloorTransparency(startFloorIndex, endFloorIndex)
	-- Reset all movement models to visible
	for _, folder in ipairs(floorFolders) do
		for _, movementModel in pairs(folder:GetChildren()) do
			if string.find(movementModel.Name, "Movement_") then
				for _, part in pairs(movementModel:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
			end
		end
	end

	-- Determine which movement models need to be transparent
	local minFloor = math.min(startFloorIndex, endFloorIndex)
	local maxFloor = math.max(startFloorIndex, endFloorIndex)

	-- Make necessary movement models transparent
	for i = minFloor, maxFloor do
		local floorFolder = floorFolders[i]
		local movementModel = floorFolder:FindFirstChild(CONFIG.MOVEMENT_MODELS[i])

		if movementModel then
			for _, part in pairs(movementModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
					part.CanCollide = false
				end
			end
		end
	end
end

-- Function to get floor index from floor name
local function getFloorIndex(floorName)
	for i, name in ipairs(CONFIG.FLOOR_TAGS) do
		if name == floorName then
			return i
		end
	end
	return 1 -- Default to 1st floor
end

-- Function to move elevator to target floor
local function moveElevator(targetFloor)
	if isMoving or currentFloor == targetFloor then return end

	isMoving = true

	-- Get floor indices
	local startFloorIndex = getFloorIndex(currentFloor)
	local endFloorIndex = getFloorIndex(targetFloor)

	-- Manage floor transparency
	manageFloorTransparency(startFloorIndex, endFloorIndex)

	-- Create tween to move elevator smoothly
	local targetPosition = CONFIG.FLOOR_POSITIONS[targetFloor]
	local tweenInfo = TweenInfo.new(
		CONFIG.ELEVATOR_SPEED * math.abs(endFloorIndex - startFloorIndex), 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.InOut
	)

	local tween = TweenService:Create(
		elevator,
		tweenInfo,
		{CFrame = CFrame.new(targetPosition)}
	)

	-- Play elevator movement sound if available
	local movementSound = elevator:FindFirstChild("ElevatorMoving")
	if movementSound and movementSound:IsA("Sound") then
		movementSound:Play()
	end

	-- Start movement
	tween:Play()

	-- Wait for tween to complete
	tween.Completed:Wait()

	-- Play ding sound when arriving at floor
	local dingSound = elevator:FindFirstChild("ElevatorDing")
	if dingSound and dingSound:IsA("Sound") then
		dingSound:Play()
	end

	-- Update current floor
	currentFloor = targetFloor
	isMoving = false

	-- Update buttons to show current floor
	updateButtonDisplays()
end

-- Function to create and configure the GUI
local function createElevatorGUI(player)
	-- Create the ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ElevatorControl"
	screenGui.ResetOnSpawn = false

	-- Create the main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "ElevatorPanel"
	mainFrame.Size = UDim2.new(0, 200, 0, 250)
	mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 2
	mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	mainFrame.Parent = screenGui

	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	titleLabel.BorderSizePixel = 0
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "Elevator Control"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 16
	titleLabel.Parent = mainFrame

	-- Add floor display
	local floorDisplay = Instance.new("TextLabel")
	floorDisplay.Name = "FloorDisplay"
	floorDisplay.Size = UDim2.new(1, -20, 0, 40)
	floorDisplay.Position = UDim2.new(0, 10, 0, 40)
	floorDisplay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	floorDisplay.BorderColor3 = Color3.fromRGB(100, 100, 100)
	floorDisplay.Font = Enum.Font.GothamSemibold
	floorDisplay.Text = "Current Floor: 1"
	floorDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
	floorDisplay.TextSize = 16
	floorDisplay.Parent = mainFrame

	-- Create container for floor buttons
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -20, 0, 150)
	buttonContainer.Position = UDim2.new(0, 10, 0, 90)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = mainFrame

	-- Add the close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.Parent = mainFrame

	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	-- Add floor buttons (will be updated dynamically)
	updateFloorButtons(buttonContainer)

	-- Parent the ScreenGui to the player
	screenGui.Parent = player.PlayerGui

	return screenGui
end

-- Function to update floor buttons based on available floors
function updateFloorButtons(container)
	-- Clear existing buttons
	for _, child in pairs(container:GetChildren()) do
		child:Destroy()
	end

	-- Get available floors
	local availableFloors = getAvailableFloors()

	-- Create buttons for each available floor
	for i, floorName in ipairs(availableFloors) do
		local floorNumber = floorName:sub(1, 1)

		local button = Instance.new("TextButton")
		button.Name = "Floor" .. floorNumber .. "Button"
		button.Size = UDim2.new(0, 50, 0, 50)
		button.Position = UDim2.new(((i-1) % 3) * 0.33, 5, math.floor((i-1) / 3) * 0.33, 5)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		button.BorderColor3 = Color3.fromRGB(100, 100, 100)
		button.Text = floorNumber
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 18
		button.Parent = container

		-- Highlight current floor
		if floorName == currentFloor then
			button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
		end

		-- Connect button click
		button.MouseButton1Click:Connect(function()
			if buttonDebounce or isMoving then return end

			buttonDebounce = true
			moveElevator(floorName)
			buttonDebounce = false
		end)
	end
end

-- Function to update floor indicators on all controls
function updateButtonDisplays()
	for _, player in pairs(Players:GetPlayers()) do
		local gui = player.PlayerGui:FindFirstChild("ElevatorControl")
		if gui then
			-- Update floor display
			local floorDisplay = gui.ElevatorPanel:FindFirstChild("FloorDisplay")
			if floorDisplay then
				local floorNumber = currentFloor:sub(1, 1)
				floorDisplay.Text = "Current Floor: " .. floorNumber
			end

			-- Update button colors
			local buttonContainer = gui.ElevatorPanel:FindFirstChild("ButtonContainer")
			if buttonContainer then
				for _, button in pairs(buttonContainer:GetChildren()) do
					local buttonFloorNumber = button.Text
					local buttonFloorName = buttonFloorNumber .. "thFloor"
					if buttonFloorNumber == "1" then
						buttonFloorName = "1stFloor"
					elseif buttonFloorNumber == "2" then
						buttonFloorName = "2ndFloor"
					elseif buttonFloorNumber == "3" then
						buttonFloorName = "3rdFloor"
					end

					if buttonFloorName == currentFloor then
						button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
					else
						button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					end
				end
			end
		end
	end
end

-- Create call button for each floor
local function createCallButtons()
	for i, floorTag in ipairs(CONFIG.FLOOR_TAGS) do
		local taggedModels = Workspace:GetTagged(floorTag)

		for _, model in ipairs(taggedModels) do
			-- Create call button
			local callButton = Instance.new("Part")
			callButton.Name = "ElevatorCallButton_" .. floorTag
			callButton.Size = Vector3.new(0.5, 0.5, 0.1)
			callButton.Position = CONFIG.FLOOR_POSITIONS[floorTag] + Vector3.new(2, 1, 1)
			callButton.Anchored = true
			callButton.CanCollide = false
			callButton.BrickColor = BrickColor.new("Really red")
			callButton.Material = Enum.Material.Neon

			-- Add button label
			local buttonLabel = Instance.new("BillboardGui")
			buttonLabel.Name = "ButtonLabel"
			buttonLabel.Size = UDim2.new(0, 100, 0, 50)
			buttonLabel.Adornee = callButton
			buttonLabel.AlwaysOnTop = true

			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.Text = "Call Elevator"
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextSize = 12
			textLabel.Parent = buttonLabel

			buttonLabel.Parent = callButton
			callButton.Parent = Workspace

			-- Create ClickDetector for the call button
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 10
			clickDetector.Parent = callButton

			-- Connect call button functionality
			clickDetector.MouseClick:Connect(function(player)
				if isMoving then return end
				moveElevator(floorTag)
			end)
		end
	end
end

-- Function to open GUI when player enters elevator
local function setupElevatorTrigger()
	local trigger = Instance.new("Part")
	trigger.Name = "ElevatorTrigger"
	trigger.Size = Vector3.new(5, 7, 5)
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.Anchored = true
	trigger.Parent = elevator

	local touchConnection
	touchConnection = trigger.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(humanoid.Parent)
			if player then
				local gui = player.PlayerGui:FindFirstChild("ElevatorControl")
				if not gui then
					gui = createElevatorGUI(player)
				end
				gui.Enabled = true

				-- Update floor buttons in case available floors changed
				local buttonContainer = gui.ElevatorPanel:FindFirstChild("ButtonContainer")
				if buttonContainer then
					updateFloorButtons(buttonContainer)
				end
			end
		end
	end)
end

-- Initialize the elevator system
local function initialize()
	-- Create sounds
	local movementSound = Instance.new("Sound")
	movementSound.Name = "ElevatorMoving"
	movementSound.SoundId = "rbxassetid://142376088" -- Replace with actual sound ID
	movementSound.Volume = 0.5
	movementSound.Parent = elevator

	local dingSound = Instance.new("Sound")
	dingSound.Name = "ElevatorDing"
	dingSound.SoundId = "rbxassetid://138081509" -- Replace with actual sound ID
	dingSound.Volume = 0.8
	dingSound.Parent = elevator

	-- Set initial position
	elevator:SetPrimaryPartCFrame(CFrame.new(CONFIG.FLOOR_POSITIONS[currentFloor]))

	-- Create call buttons for each floor
	createCallButtons()

	-- Set up trigger for GUI
	setupElevatorTrigger()

	-- Connect player joining to create GUI
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Optionally create GUI when character spawns
			-- createElevatorGUI(player)
		end)
	end)

	print("Elevator system initialized!")
end

-- Start the elevator system
initialize()