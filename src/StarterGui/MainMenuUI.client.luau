--lua
--[[
    MainMenuUI.client.luau
    Handles the creation and functionality of the Main Menu UI.

    Updated: Today
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Rebirth functionality has been removed
local SettingsUI = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("StarterGui"):WaitForChild("SettingsUI"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Import modern UI framework components
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle"))
local ButtonFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("ButtonFactory"))

-- Import game systems.
local GameSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("GameSystem"))

-- Create main menu UI elements
local function createMainMenuUI()	
    -- Create main frame using UIStyle
	local mainFrame = UIStyle.createFrame({
        name = "MainFrame",
        size = UDim2.new(1, 0, 1, 0),
        zIndex = UIStyle.ZIndex.Standard
	})

	-- 1. Game Logo
	local gameLogo = Instance.new("ImageLabel")
	gameLogo.Name = "GameLogo"
	gameLogo.Size = UDim2.new(0, 100, 0, 100)
	gameLogo.Position = UDim2.new(0, 10, 0, 10)
	gameLogo.BackgroundTransparency = 1
	gameLogo.Image = "rbxassetid://14197602619"
	gameLogo.Parent = mainFrame

	-- 2. Player Profile Container
	local playerProfileContainer = Instance.new("Frame")
	playerProfileContainer.Name = "PlayerProfileContainer"
	playerProfileContainer.Size = UDim2.new(0, 200, 0, 80)
	playerProfileContainer.Position = UDim2.new(1, -210, 0, 20)
	playerProfileContainer.BackgroundTransparency = 1
	playerProfileContainer.Parent = mainFrame

	-- 3. Player Name
	local playerNameLabel = Instance.new("TextLabel")
	playerNameLabel.Name = "PlayerNameLabel"
	playerNameLabel.Size = UDim2.new(1, 0, 0, 30)
	playerNameLabel.Position = UDim2.new(0, 0, 0, 0)
	playerNameLabel.Text = LocalPlayer.Name
	playerNameLabel.TextSize = 16
	playerNameLabel.Font = Enum.Font.GothamBold
	playerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerNameLabel.BackgroundTransparency = 1
	playerNameLabel.Parent = playerProfileContainer
	
    -- 4. Player Level
	local playerLevelLabel = Instance.new("TextLabel")
	playerLevelLabel.Name = "PlayerLevelLabel"
	playerLevelLabel.Size = UDim2.new(1, 0, 0, 30)
	playerLevelLabel.Position = UDim2.new(0,0,0,30)
	playerLevelLabel.BackgroundTransparency = 1
	playerLevelLabel.Font = Enum.Font.Gotham
	playerLevelLabel.Text = "Level: 1"
	playerLevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerLevelLabel.TextSize = 14
	playerLevelLabel.Parent = playerProfileContainer

	-- 5. Player Resources
	local playerResourcesLabel = Instance.new("TextLabel")
	playerResourcesLabel.Name = "PlayerResourcesLabel"
	playerResourcesLabel.Size = UDim2.new(1, 0, 0, 30)
	playerResourcesLabel.Position = UDim2.new(0,0,0,60)
	playerResourcesLabel.BackgroundTransparency = 1
	playerResourcesLabel.Font = Enum.Font.Gotham
	playerResourcesLabel.Text = "Resources: 0"
	playerResourcesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerResourcesLabel.TextSize = 14
	playerResourcesLabel.Parent = playerProfileContainer

	-- Center Buttons Container
	local centerButtonsContainer = Instance.new("Frame")
	centerButtonsContainer.Name = "CenterButtonsContainer"
	centerButtonsContainer.Size = UDim2.new(0, 400, 0, 300)
	centerButtonsContainer.Position = UDim2.new(0.5, -200, 0.5, -150)
	centerButtonsContainer.BackgroundTransparency = 1
	centerButtonsContainer.Parent = mainFrame

	-- 1. Play Button
	local playButton = ButtonFactory.createButton({name = "PlayButton", size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 0), text = "Play", font = Enum.Font.GothamBold, textSize = 18, textColor = Color3.fromRGB(255, 255, 255), backgroundColor = Color3.fromRGB(50, 150, 255)})
	playButton.Parent = centerButtonsContainer
    playButton.Activated:Connect(function()
		GameSystem.startGame()
	end)

	-- 2. Alliance Button
	local allianceButton = ButtonFactory.createButton({name = "AllianceButton", size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 50), text = "Alliance", font = Enum.Font.GothamMedium, textSize = 16, textColor = Color3.fromRGB(255, 255, 255), backgroundColor = Color3.fromRGB(60, 60, 120)})
	allianceButton.Parent = centerButtonsContainer

	-- 3. Specialization Button
	local specializationButton = ButtonFactory.createButton({name = "SpecializationButton", size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 100), text = "Specialization", font = Enum.Font.GothamMedium, textSize = 16, textColor = Color3.fromRGB(255, 255, 255), backgroundColor = Color3.fromRGB(60, 60, 120)})
    specializationButton.Activated:Connect(function()
		print("Specialization Button Clicked")
	end)
	specializationButton.Parent = centerButtonsContainer

	-- 4. Seasonal Events Button
	local seasonalEventsButton = ButtonFactory.createButton({name = "SeasonalEventsButton", size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 150), text = "Seasonal Events", font = Enum.Font.GothamMedium, textSize = 16, textColor = Color3.fromRGB(255, 255, 255), backgroundColor = Color3.fromRGB(60, 60, 120)})
	seasonalEventsButton.Parent = centerButtonsContainer
	-- 5. Settings Button
	local settingsButton = ButtonFactory.createButton({name = "SettingsButton", size = UDim2.new(1, 0, 0, 40), position = UDim2.new(0, 0, 0, 200), text = "Settings", font = Enum.Font.GothamMedium, textSize = 16, textColor = Color3.fromRGB(255, 255, 255), backgroundColor = Color3.fromRGB(60, 60, 120)})
	settingsButton.Parent = centerButtonsContainer
    -- 6. Minigames Button
	
	-- Bottom Section Container
	local bottomSectionContainer = Instance.new("Frame")
	bottomSectionContainer.Name = "BottomSectionContainer"
	bottomSectionContainer.Size = UDim2.new(1, -20, 0, 50)
	bottomSectionContainer.Position = UDim2.new(0, 10, 1, -60)
	bottomSectionContainer.BackgroundTransparency = 1
	bottomSectionContainer.Parent = mainFrame
	-- Social Links Label
	local socialLinksLabel = Instance.new("TextLabel")
	socialLinksLabel.Name = "SocialLinksLabel"
	socialLinksLabel.Size = UDim2.new(1, 0, 1, 0)
	socialLinksLabel.BackgroundTransparency = 1
	socialLinksLabel.Text = "Social Links"
	socialLinksLabel.Font = Enum.Font.Gotham
	socialLinksLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	socialLinksLabel.TextSize = 14
	socialLinksLabel.Parent = bottomSectionContainer
    return mainFrame
end

-- Load the UI
local function loadUI()
    -- Check if the ScreenGui already exists
    local screenGui = PlayerGui:FindFirstChild("MainMenuUI")
    if not screenGui then
        -- If it doesn't, create it
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MainMenuUI"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = PlayerGui
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    end

    -- Create the main frame
    local mainFrame = createMainMenuUI()

    -- Set the screenGui as the parent
    mainFrame.Parent = screenGui
    
	-- Get the center buttons container
	local centerButtonsContainer = mainFrame:WaitForChild("CenterButtonsContainer")
		-- Get the buttons
	local settingsButton = centerButtonsContainer:WaitForChild("SettingsButton")
	local allianceButton = centerButtonsContainer:WaitForChild("AllianceButton")
	local minigamesButton = centerButtonsContainer:WaitForChild("MinigamesButton")
	local seasonalEventsButton = centerButtonsContainer:WaitForChild("SeasonalEventsButton")
	
	allianceButton.Activated:Connect(function()
		print("Alliance Button Clicked")
	end)
	seasonalEventsButton.Activated:Connect(function()
		print("Seasonal Events Button Clicked")
	end)
	settingsButton.Activated:Connect(function()
		SettingsUI.loadUI()
	end)
	minigamesButton.Activated:Connect(function()
		print("Minigames Button Clicked")
	end)
end

return {
    loadUI = loadUI,
}