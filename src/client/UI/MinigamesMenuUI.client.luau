--[[
    MinigamesMenuUI.client.luau
    
    Minigames Menu UI implementation that provides an interface for accessing and playing minigames.
    Uses modern UI modules for consistent appearance and behavior.
    
    Created: April 24, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")

-- Safe require helper
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name)
            return nil
        end
    end
    return nil
end

-- Import UI modules
local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local IconSet = requireSafely(sharedFolder:FindFirstChild("IconSet"))
local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
local DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))

-- Check if modules loaded correctly
if not UIStyle then
    warn("UIStyle module not found, MinigamesMenuUI will have limited functionality")
end

if not IconSet then
    warn("IconSet module not found, MinigamesMenuUI will have limited functionality")
end

if not ButtonFactory then
    warn("ButtonFactory module not found, MinigamesMenuUI will have limited functionality")
end

if not DialogFactory then
    warn("DialogFactory module not found, MinigamesMenuUI will have limited functionality")
end

-- Minigames Menu UI Module
local MinigamesMenuUI = {}
MinigamesMenuUI.__index = MinigamesMenuUI

-- State tracking
local uiState = {
    isInitialized = false,
    menuVisible = false,
    menuElements = {},
    selectedMinigame = nil,
    availableMinigames = {},
    isLoading = false
}

-- Sample minigames data for testing - will be replaced with actual data from MiniGameSystem
-- This is a placeholder until we connect to the actual backend
local PLACEHOLDER_MINIGAMES = {
    {
        id = "basketball",
        name = "Basketball Challenge",
        description = "Test your basketball skills! Score as many points as possible in the time limit.",
        image = "rbxassetid://7734054272",
        difficulty = "Medium",
        rewards = {
            currency = 50,
            experience = 100
        },
        highscore = 0
    },
    {
        id = "weightlifting",
        name = "Weightlifting Competition",
        description = "Compete against other players in a weightlifting challenge. Lift the heaviest weights to win!",
        image = "rbxassetid://7734055216",
        difficulty = "Hard",
        rewards = {
            currency = 100,
            experience = 200
        },
        highscore = 0
    },
    {
        id = "treadmill",
        name = "Treadmill Race",
        description = "Race on treadmills against AI opponents. The faster you run, the better your chance of winning!",
        image = "rbxassetid://7734056108",
        difficulty = "Easy",
        rewards = {
            currency = 25,
            experience = 50
        },
        highscore = 0
    },
    {
        id = "yoga",
        name = "Yoga Challenge",
        description = "Follow the yoga instructor and match the poses precisely for maximum points.",
        image = "rbxassetid://7734058203",
        difficulty = "Medium",
        rewards = {
            currency = 40,
            experience = 90
        },
        highscore = 0
    }
}

-- Initialize the minigames menu
function MinigamesMenuUI:Initialize()
    if uiState.isInitialized then
        return self
    end
    
    -- Create the toggle button
    self:CreateToggleButton()
    
    uiState.isInitialized = true
    return self
end

-- Create the toggle button for minigames menu
function MinigamesMenuUI:CreateToggleButton()
    local position = UDim2.new(1, -50, 0, 110) -- Position below other potential menu buttons
    
    local minigamesToggle = ButtonFactory.createIconButton(
        "Controller", 
        "Minigames", 
        UDim2.new(0, 40, 0, 40), 
        position,
        function()
            self:ToggleMinigamesMenu()
        end
    )
    
    -- Add to player's GUI
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = Instance.new("ScreenGui", player)
        playerGui.Name = "PlayerGui"
    end
    
    local container = playerGui:FindFirstChild("MinigamesToggleContainer")
    if not container then
        container = Instance.new("ScreenGui", playerGui)
        container.Name = "MinigamesToggleContainer"
        container.ResetOnSpawn = false
        container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    end
    
    minigamesToggle.Parent = container
    
    -- Apply tooltip
    DialogFactory.createTooltip(minigamesToggle, "Open Minigames", "bottom", 100)
    
    -- Store for later reference
    uiState.menuElements.toggleButton = minigamesToggle
    return minigamesToggle
end

-- Create the minigames menu
function MinigamesMenuUI:CreateMinigamesMenu()
    -- Create the container GUI
    local screenGui = player:FindFirstChild("MinigamesMenuGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MinigamesMenuGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:FindFirstChild("PlayerGui")
    end
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
    mainFrame.BackgroundColor3 = UIStyle.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UIStyle.Sizes.CornerRadius
    mainCorner.Parent = mainFrame
    
    -- Add title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add rounded corners for title bar (top only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UIStyle.Sizes.CornerRadius
    titleCorner.Parent = titleBar
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 50, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.Fonts.Header
    titleText.TextSize = UIStyle.TextSizes.Header
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.Text = "Minigames"
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Add minigame icon to title
    local titleIcon = IconSet.createIcon("Controller", UDim2.new(0, 30, 0, 30), UDim2.new(0, 10, 0.5, -15))
    titleIcon.Parent = titleBar
    
    -- Add close button
    local closeButton = ButtonFactory.createCloseButton(function()
        self:HideMinigamesMenu()
    end)
    
    closeButton.Position = UDim2.new(1, -40, 0.5, -15)
    closeButton.Parent = titleBar
    
    -- Create content layout
    self:CreateContentLayout(mainFrame)
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -50) -- Subtract title bar height
    contentContainer.Position = UDim2.new(0, 0, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Create the minigames list
    self:CreateMinigamesList(contentContainer)
    
    -- Create minigame details panel
    self:CreateMinigameDetails(contentContainer)
    
    -- Store UI elements
    uiState.menuElements.screenGui = screenGui
    uiState.menuElements.mainFrame = mainFrame
    uiState.menuElements.contentContainer = contentContainer
    
    return mainFrame
end

-- Create content layout
function MinigamesMenuUI:CreateContentLayout(parent)
    -- Add padding to main frame
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UIStyle.Padding.Medium)
    padding.PaddingRight = UDim.new(0, UIStyle.Padding.Medium)
    padding.PaddingTop = UDim.new(0, UIStyle.Padding.Medium)
    padding.PaddingBottom = UDim.new(0, UIStyle.Padding.Medium)
    padding.Parent = parent
    
    -- Add background pattern or design (optional)
    local backgroundDesign = Instance.new("Frame")
    backgroundDesign.Name = "BackgroundDesign"
    backgroundDesign.Size = UDim2.new(1, 0, 1, 0)
    backgroundDesign.BackgroundTransparency = 0.9
    backgroundDesign.BackgroundColor3 = UIStyle.Colors.BackgroundSecondary
    backgroundDesign.ZIndex = 1
    backgroundDesign.BorderSizePixel = 0
    backgroundDesign.Parent = parent
    
    -- Optional: Add pattern or tiles to the background design
    -- This adds a subtle grid pattern using UIGridLayout
    local gridSize = 20
    for i = 1, 10 do
        local designElement = Instance.new("Frame")
        designElement.Name = "DesignElement" .. i
        designElement.Size = UDim2.new(0, gridSize * math.random(5, 15), 0, gridSize * math.random(1, 3))
        designElement.Position = UDim2.new(math.random(), -gridSize, math.random(), -gridSize)
        designElement.BackgroundColor3 = UIStyle.Colors.Primary
        designElement.BackgroundTransparency = 0.9
        designElement.BorderSizePixel = 0
        designElement.ZIndex = 1
        
        -- Add rounded corners
        local elementCorner = Instance.new("UICorner")
        elementCorner.CornerRadius = UDim.new(0, 4)
        elementCorner.Parent = designElement
        
        designElement.Parent = backgroundDesign
    end
end

-- Create the minigames list panel
function MinigamesMenuUI:CreateMinigamesList(parent)
    -- Create list container
    local listContainer = Instance.new("Frame")
    listContainer.Name = "MinigamesListContainer"
    listContainer.Size = UDim2.new(0.3, 0, 1, 0)
    listContainer.BackgroundTransparency = 1
    listContainer.Parent = parent
    
    -- Create header
    local listHeader = Instance.new("TextLabel")
    listHeader.Name = "ListHeader"
    listHeader.Size = UDim2.new(1, 0, 0, 30)
    listHeader.BackgroundTransparency = 1
    listHeader.Font = UIStyle.Fonts.Subheader
    listHeader.TextSize = UIStyle.TextSizes.Subheader
    listHeader.TextColor3 = UIStyle.Colors.TextSecondary
    listHeader.TextXAlignment = Enum.TextXAlignment.Left
    listHeader.Text = "Available Games"
    listHeader.Parent = listContainer
    
    -- Create scrolling frame for list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, -40)
    scrollFrame.Position = UDim2.new(0, 0, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = UIStyle.Colors.ScrollBar
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    scrollFrame.Parent = listContainer
    
    -- Create list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Create padding for the scroll frame
    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingLeft = UDim.new(0, 5)
    scrollPadding.PaddingRight = UDim.new(0, 5)
    scrollPadding.PaddingTop = UDim.new(0, 5)
    scrollPadding.PaddingBottom = UDim.new(0, 5)
    scrollPadding.Parent = scrollFrame
    
    -- Store UI elements
    uiState.menuElements.minigamesList = {
        container = listContainer,
        scrollFrame = scrollFrame,
        listLayout = listLayout
    }
    
    -- Display loading message initially
    self:ShowLoadingState(scrollFrame)
    
    return listContainer
end

-- Create the minigame details panel
function MinigamesMenuUI:CreateMinigameDetails(parent)
    -- Create details container
    local detailsContainer = Instance.new("Frame")
    detailsContainer.Name = "MinigameDetailsContainer"
    detailsContainer.Size = UDim2.new(0.7, -20, 1, 0)
    detailsContainer.Position = UDim2.new(0.3, 20, 0, 0)
    detailsContainer.BackgroundColor3 = UIStyle.Colors.CardBackground
    detailsContainer.BackgroundTransparency = 0.5
    detailsContainer.BorderSizePixel = 0
    detailsContainer.Parent = parent
    
    -- Add rounded corners
    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UIStyle.Sizes.CornerRadius
    detailsCorner.Parent = detailsContainer
    
    -- Create image container
    local imageContainer = Instance.new("Frame")
    imageContainer.Name = "ImageContainer"
    imageContainer.Size = UDim2.new(1, -40, 0.4, 0)
    imageContainer.Position = UDim2.new(0, 20, 0, 20)
    imageContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    imageContainer.BackgroundTransparency = 0.7
    imageContainer.BorderSizePixel = 0
    imageContainer.Parent = detailsContainer
    
    -- Add rounded corners to image container
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 10)
    imageCorner.Parent = imageContainer
    
    -- Create image
    local minigameImage = Instance.new("ImageLabel")
    minigameImage.Name = "MinigameImage"
    minigameImage.Size = UDim2.new(1, 0, 1, 0)
    minigameImage.BackgroundTransparency = 1
    minigameImage.ScaleType = Enum.ScaleType.Crop
    minigameImage.Image = "rbxassetid://0" -- Will be set dynamically
    minigameImage.Parent = imageContainer
    
    -- Add image corner
    local imageRoundCorner = Instance.new("UICorner")
    imageRoundCorner.CornerRadius = UDim.new(0, 10)
    imageRoundCorner.Parent = minigameImage
    
    -- Create info section
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Size = UDim2.new(1, -40, 0.6, -80)
    infoContainer.Position = UDim2.new(0, 20, 0.4, 30)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = detailsContainer
    
    -- Create title
    local minigameTitle = Instance.new("TextLabel")
    minigameTitle.Name = "MinigameTitle"
    minigameTitle.Size = UDim2.new(1, 0, 0, 30)
    minigameTitle.BackgroundTransparency = 1
    minigameTitle.Font = UIStyle.Fonts.Header
    minigameTitle.TextSize = UIStyle.TextSizes.Header
    minigameTitle.TextColor3 = UIStyle.Colors.Text
    minigameTitle.TextXAlignment = Enum.TextXAlignment.Left
    minigameTitle.Text = "Select a Minigame"
    minigameTitle.Parent = infoContainer
    
    -- Create difficulty label
    local difficultyContainer = Instance.new("Frame")
    difficultyContainer.Name = "DifficultyContainer"
    difficultyContainer.Size = UDim2.new(0, 100, 0, 30)
    difficultyContainer.Position = UDim2.new(0, 0, 0, 35)
    difficultyContainer.BackgroundTransparency = 0.5
    difficultyContainer.BackgroundColor3 = UIStyle.Colors.Primary
    difficultyContainer.Parent = infoContainer
    
    -- Add difficulty corner
    local difficultyCorner = Instance.new("UICorner")
    difficultyCorner.CornerRadius = UDim.new(0, 15)
    difficultyCorner.Parent = difficultyContainer
    
    -- Create difficulty text
    local difficultyText = Instance.new("TextLabel")
    difficultyText.Name = "DifficultyText"
    difficultyText.Size = UDim2.new(1, 0, 1, 0)
    difficultyText.BackgroundTransparency = 1
    difficultyText.Font = UIStyle.Fonts.Bold
    difficultyText.TextSize = UIStyle.TextSizes.Small
    difficultyText.TextColor3 = UIStyle.Colors.TextLight
    difficultyText.Text = "Difficulty: -"
    difficultyText.Parent = difficultyContainer
    
    -- Create description
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Size = UDim2.new(0, 80, 0, 20)
    descriptionLabel.Position = UDim2.new(0, 0, 0, 75)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Font = UIStyle.Fonts.Subheader
    descriptionLabel.TextSize = UIStyle.TextSizes.Subheader
    descriptionLabel.TextColor3 = UIStyle.Colors.TextSecondary
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
    descriptionLabel.Text = "Description:"
    descriptionLabel.Parent = infoContainer
    
    local descriptionText = Instance.new("TextLabel")
    descriptionText.Name = "DescriptionText"
    descriptionText.Size = UDim2.new(1, 0, 0, 60)
    descriptionText.Position = UDim2.new(0, 0, 0, 100)
    descriptionText.BackgroundTransparency = 1
    descriptionText.Font = UIStyle.Fonts.Regular
    descriptionText.TextSize = UIStyle.TextSizes.Medium
    descriptionText.TextColor3 = UIStyle.Colors.Text
    descriptionText.TextXAlignment = Enum.TextXAlignment.Left
    descriptionText.TextYAlignment = Enum.TextYAlignment.Top
    descriptionText.TextWrapped = true
    descriptionText.Text = "Select a minigame from the list to view its details."
    descriptionText.Parent = infoContainer
    
    -- Create rewards section
    local rewardsLabel = Instance.new("TextLabel")
    rewardsLabel.Name = "RewardsLabel"
    rewardsLabel.Size = UDim2.new(0, 80, 0, 20)
    rewardsLabel.Position = UDim2.new(0, 0, 0, 170)
    rewardsLabel.BackgroundTransparency = 1
    rewardsLabel.Font = UIStyle.Fonts.Subheader
    rewardsLabel.TextSize = UIStyle.TextSizes.Subheader
    rewardsLabel.TextColor3 = UIStyle.Colors.TextSecondary
    rewardsLabel.TextXAlignment = Enum.TextXAlignment.Left
    rewardsLabel.Text = "Rewards:"
    rewardsLabel.Parent = infoContainer
    
    -- Currency reward
    local currencyReward = Instance.new("Frame")
    currencyReward.Name = "CurrencyReward"
    currencyReward.Size = UDim2.new(0, 120, 0, 30)
    currencyReward.Position = UDim2.new(0, 0, 0, 195)
    currencyReward.BackgroundTransparency = 0.7
    currencyReward.BackgroundColor3 = UIStyle.Colors.Success
    currencyReward.Parent = infoContainer
    
    -- Add currency corner
    local currencyCorner = Instance.new("UICorner")
    currencyCorner.CornerRadius = UDim.new(0, 5)
    currencyCorner.Parent = currencyReward
    
    -- Currency icon
    local currencyIcon = IconSet.createIcon("Coin", UDim2.new(0, 20, 0, 20), UDim2.new(0, 5, 0.5, -10))
    currencyIcon.Parent = currencyReward
    
    -- Currency text
    local currencyText = Instance.new("TextLabel")
    currencyText.Name = "CurrencyText"
    currencyText.Size = UDim2.new(1, -30, 1, 0)
    currencyText.Position = UDim2.new(0, 30, 0, 0)
    currencyText.BackgroundTransparency = 1
    currencyText.Font = UIStyle.Fonts.Bold
    currencyText.TextSize = UIStyle.TextSizes.Small
    currencyText.TextColor3 = UIStyle.Colors.TextLight
    currencyText.Text = "$0"
    currencyText.TextXAlignment = Enum.TextXAlignment.Left
    currencyText.Parent = currencyReward
    
    -- XP reward
    local xpReward = Instance.new("Frame")
    xpReward.Name = "XPReward"
    xpReward.Size = UDim2.new(0, 120, 0, 30)
    xpReward.Position = UDim2.new(0, 130, 0, 195)
    xpReward.BackgroundTransparency = 0.7
    xpReward.BackgroundColor3 = UIStyle.Colors.Info
    xpReward.Parent = infoContainer
    
    -- Add XP corner
    local xpCorner = Instance.new("UICorner")
    xpCorner.CornerRadius = UDim.new(0, 5)
    xpCorner.Parent = xpReward
    
    -- XP icon
    local xpIcon = IconSet.createIcon("Star", UDim2.new(0, 20, 0, 20), UDim2.new(0, 5, 0.5, -10))
    xpIcon.Parent = xpReward
    
    -- XP text
    local xpText = Instance.new("TextLabel")
    xpText.Name = "XPText"
    xpText.Size = UDim2.new(1, -30, 1, 0)
    xpText.Position = UDim2.new(0, 30, 0, 0)
    xpText.BackgroundTransparency = 1
    xpText.Font = UIStyle.Fonts.Bold
    xpText.TextSize = UIStyle.TextSizes.Small
    xpText.TextColor3 = UIStyle.Colors.TextLight
    xpText.Text = "0 XP"
    xpText.TextXAlignment = Enum.TextXAlignment.Left
    xpText.Parent = xpReward
    
    -- Create highscore section
    local highscoreContainer = Instance.new("Frame")
    highscoreContainer.Name = "HighscoreContainer"
    highscoreContainer.Size = UDim2.new(0, 200, 0, 40)
    highscoreContainer.Position = UDim2.new(0, 0, 0, 235)
    highscoreContainer.BackgroundTransparency = 0.7
    highscoreContainer.BackgroundColor3 = UIStyle.Colors.Warning
    highscoreContainer.Parent = infoContainer
    
    -- Add highscore corner
    local highscoreCorner = Instance.new("UICorner")
    highscoreCorner.CornerRadius = UDim.new(0, 5)
    highscoreCorner.Parent = highscoreContainer
    
    -- Trophy icon
    local trophyIcon = IconSet.createIcon("Trophy", UDim2.new(0, 20, 0, 20), UDim2.new(0, 5, 0.5, -10))
    trophyIcon.Parent = highscoreContainer
    
    -- Highscore text
    local highscoreText = Instance.new("TextLabel")
    highscoreText.Name = "HighscoreText"
    highscoreText.Size = UDim2.new(1, -30, 1, 0)
    highscoreText.Position = UDim2.new(0, 30, 0, 0)
    highscoreText.BackgroundTransparency = 1
    highscoreText.Font = UIStyle.Fonts.Bold
    highscoreText.TextSize = UIStyle.TextSizes.Small
    highscoreText.TextColor3 = UIStyle.Colors.TextLight
    highscoreText.Text = "Your Highscore: 0"
    highscoreText.TextXAlignment = Enum.TextXAlignment.Left
    highscoreText.Parent = highscoreContainer
    
    -- Create play button
    local playButton = ButtonFactory.createActionButton("Play", UDim2.new(0, 200, 0, 50), UDim2.new(1, -220, 1, -70), function()
        self:PlaySelectedMinigame()
    end)
    
    playButton.Parent = detailsContainer
    
    -- Create back to menu button
    local backButton = ButtonFactory.createActionButton("Back to Menu", UDim2.new(0, 150, 0, 40), UDim2.new(0, 20, 1, -60), function()
        self:HideMinigamesMenu()
    end)
    
    backButton.Parent = detailsContainer
    
    -- Store UI elements
    uiState.menuElements.minigameDetails = {
        container = detailsContainer,
        image = minigameImage,
        title = minigameTitle,
        difficulty = difficultyText,
        description = descriptionText,
        currencyReward = currencyText,
        xpReward = xpText,
        highscore = highscoreText,
        playButton = playButton,
        backButton = backButton
    }
    
    -- Disable play button initially
    playButton.BackgroundColor3 = UIStyle.Colors.ButtonDisabled
    playButton.AutoButtonColor = false
    
    return detailsContainer
end

-- Show loading state in the minigames list
function MinigamesMenuUI:ShowLoadingState(parent)
    -- Clear existing content
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") and child.Name ~= "NoMinigamesMessage" then
            child:Destroy()
        end
    end
    
    -- Create loading indicator
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Name = "LoadingLabel"
    loadingLabel.Size = UDim2.new(1, -20, 0, 30)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Font = UIStyle.Fonts.Italic
    loadingLabel.TextSize = UIStyle.TextSizes.Medium
    loadingLabel.TextColor3 = UIStyle.Colors.TextSecondary
    loadingLabel.Text = "Loading minigames..."
    loadingLabel.Parent = parent
    
    -- Create animated loading dots
    local loadingDots = Instance.new("Frame")
    loadingDots.Name = "LoadingDots"
    loadingDots.Size = UDim2.new(0, 60, 0, 20)
    loadingDots.Position = UDim2.new(0.5, -30, 0, 40)
    loadingDots.BackgroundTransparency = 1
    loadingDots.Parent = parent
    
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new((i-1)/2, 0, 0.5, -5)
        dot.BackgroundColor3 = UIStyle.Colors.Primary
        dot.BackgroundTransparency = 0
        
        -- Add rounded corners
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        dot.Parent = loadingDots
        
        -- Animate the dot
        local initialTransparency = 0.2
        dot.BackgroundTransparency = initialTransparency
        
        task.spawn(function()
            -- Phase offset based on dot index
            task.wait((i-1) * 0.2)
            
            while loadingDots.Parent do
                -- Pulse animation
                local tween = TweenService:Create(
                    dot,
                    TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = 0.9}
                )
                tween:Play()
                task.wait(0.6)
                
                local tween2 = TweenService:Create(
                    dot,
                    TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = initialTransparency}
                )
                tween2:Play()
                task.wait(0.6)
            end
        end)
    end
    
    uiState.isLoading = true
end

-- Show "no minigames" message
function MinigamesMenuUI:ShowNoMinigamesMessage(parent)
    -- Remove loading indicator if exists
    for _, child in pairs(parent:GetChildren()) do
        if child.Name == "LoadingLabel" or child.Name == "LoadingDots" then
            child:Destroy()
        end
    end
    
    -- Check if message already exists
    local existingMessage = parent:FindFirstChild("NoMinigamesMessage")
    if existingMessage then
        return existingMessage
    end
    
    -- Create message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "NoMinigamesMessage"
    messageLabel.Size = UDim2.new(1, -20, 0, 60)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = UIStyle.Fonts.Regular
    messageLabel.TextSize = UIStyle.TextSizes.Medium
    messageLabel.TextColor3 = UIStyle.Colors.TextSecondary
    messageLabel.Text = "No minigames available at the moment. Please check back later."
    messageLabel.TextWrapped = true
    messageLabel.Parent = parent
    
    return messageLabel
end

-- Load minigames data
function MinigamesMenuUI:LoadMinigames()
    -- Set loading state
    local scrollFrame = uiState.menuElements.minigamesList.scrollFrame
    self:ShowLoadingState(scrollFrame)
    
    -- Request minigames from MiniGameSystem
    local success = false
    local minigames = {}
    
    -- Try to get data from server
    if ReplicatedStorage:FindFirstChild("MiniGameSystem") and 
       ReplicatedStorage.MiniGameSystem:FindFirstChild("GetAvailableGames") then
        
        -- Make remote call to get games
        local function fetchGames()
            -- Create a promise-like mechanism with a timeout
            local bindable = Instance.new("BindableEvent")
            local connection = nil
            connection = ReplicatedStorage.MiniGameSystem.GetAvailableGames.OnClientEvent:Connect(function(games)
                minigames = games
                success = true
                bindable:Fire()
            end)
            
            -- Request games
            ReplicatedStorage.MiniGameSystem.GetAvailableGames:FireServer()
            
            -- Wait for response with timeout
            task.spawn(function()
                task.wait(5) -- 5 second timeout
                bindable:Fire() -- Fire anyway to prevent hanging
            end)
            
            -- Wait for response or timeout
            bindable.Event:Wait()
            connection:Disconnect()
            bindable:Destroy()
        end
        
        -- Execute the fetch with pcall for safety
        local fetchSuccess, errorMsg = pcall(fetchGames)
        if not fetchSuccess then
            warn("Failed to fetch minigames: " .. tostring(errorMsg))
        end
    end
    
    -- If server fetch failed, use placeholder data
    if not success or #minigames == 0 then
        -- In a real implementation, we would log this failure
        -- For now, use the placeholder data for demonstration
        minigames = PLACEHOLDER_MINIGAMES
        
        -- Simulate loading delay for demonstration
        task.wait(1.5)
    end
    
    -- Store minigames
    uiState.availableMinigames = minigames
    
    -- Update UI
    self:PopulateMinigamesList(minigames)
    
    -- End loading state
    uiState.isLoading = false
    
    return minigames
end

-- Populate the minigames list
function MinigamesMenuUI:PopulateMinigamesList(minigames)
    local scrollFrame = uiState.menuElements.minigamesList.scrollFrame
    
    -- Clear existing minigame cards
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "LoadingLabel" then
            child:Destroy()
        end
    end
    
    -- Remove loading indicator
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child.Name == "LoadingLabel" or child.Name == "LoadingDots" then
            child:Destroy()
        end
    end
    
    -- Check if there are any minigames to display
    if not minigames or #minigames == 0 then
        self:ShowNoMinigamesMessage(scrollFrame)
        return
    end
    
    -- Create a card for each minigame
    for i, minigame in ipairs(minigames) do
        -- Create card
        local card = Instance.new("Frame")
        card.Name = "MinigameCard_" .. minigame.id
        card.Size = UDim2.new(1, -10, 0, 80)
        card.BackgroundColor3 = UIStyle.Colors.CardBackground
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        
        -- Add rounded corners
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UIStyle.Sizes.CornerRadius
        cardCorner.Parent = card
        
        -- Add thumbnail
        local thumbnail = Instance.new("ImageLabel")
        thumbnail.Name = "Thumbnail"
        thumbnail.Size = UDim2.new(0, 60, 0, 60)
        thumbnail.Position = UDim2.new(0, 10, 0.5, -30)
        thumbnail.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        thumbnail.Image = minigame.image or ""
        thumbnail.Parent = card
        
        -- Add rounded corners to thumbnail
        local thumbnailCorner = Instance.new("UICorner")
        thumbnailCorner.CornerRadius = UDim.new(0, 8)
        thumbnailCorner.Parent = thumbnail
        
        -- Add title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -90, 0, 25)
        title.Position = UDim2.new(0, 80, 0, 10)
        title.BackgroundTransparency = 1
        title.Font = UIStyle.Fonts.Bold
        title.TextSize = UIStyle.TextSizes.Medium
        title.TextColor3 = UIStyle.Colors.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = minigame.name
        title.Parent = card
        
        -- Add difficulty label
        local difficulty = Instance.new("TextLabel")
        difficulty.Name = "Difficulty"
        difficulty.Size = UDim2.new(0, 70, 0, 20)
        difficulty.Position = UDim2.new(0, 80, 0, 35)
        difficulty.BackgroundColor3 = self:GetDifficultyColor(minigame.difficulty)
        difficulty.BackgroundTransparency = 0.3
        difficulty.Font = UIStyle.Fonts.Regular
        difficulty.TextSize = UIStyle.TextSizes.Small
        difficulty.TextColor3 = UIStyle.Colors.TextLight
        difficulty.Text = minigame.difficulty or "Unknown"
        difficulty.Parent = card
        
        -- Add corner radius to difficulty label
        local diffCorner = Instance.new("UICorner")
        diffCorner.CornerRadius = UDim.new(0, 10)
        diffCorner.Parent = difficulty
        
        -- Add rewards text
        local rewards = Instance.new("TextLabel")
        rewards.Name = "Rewards"
        rewards.Size = UDim2.new(1, -90, 0, 20)
        rewards.Position = UDim2.new(0, 80, 0, 55)
        rewards.BackgroundTransparency = 1
        rewards.Font = UIStyle.Fonts.Regular
        rewards.TextSize = UIStyle.TextSizes.Small
        rewards.TextColor3 = UIStyle.Colors.TextSecondary
        rewards.TextXAlignment = Enum.TextXAlignment.Left
        rewards.Text = "$" .. tostring(minigame.rewards.currency) .. " • " .. tostring(minigame.rewards.experience) .. " XP"
        rewards.Parent = card
        
        -- Add hover effect
        local originalColor = card.BackgroundColor3
        local originalTransparency = card.BackgroundTransparency
        
        card.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundColor3 = UIStyle.Colors.Primary,
                BackgroundTransparency = 0.7
            }):Play()
        end)
        
        card.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundColor3 = originalColor,
                BackgroundTransparency = originalTransparency
            }):Play()
        end)
        
        -- Add selection functionality
        local button = Instance.new("TextButton")
        button.Name = "SelectButton"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = card
        
        button.MouseButton1Click:Connect(function()
            self:SelectMinigame(minigame)
        end)
        
        card.Parent = scrollFrame
    end
    
    -- Update the canvas size
    local listLayout = uiState.menuElements.minigamesList.listLayout
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Get color based on difficulty
function MinigamesMenuUI:GetDifficultyColor(difficulty)
    if difficulty == "Easy" then
        return Color3.fromRGB(52, 168, 83) -- Green
    elseif difficulty == "Medium" then
        return Color3.fromRGB(251, 188, 5) -- Yellow
    elseif difficulty == "Hard" then
        return Color3.fromRGB(234, 67, 53) -- Red
    else
        return Color3.fromRGB(66, 133, 244) -- Blue (default)
    end
end

-- Select a minigame
function MinigamesMenuUI:SelectMinigame(minigame)
    uiState.selectedMinigame = minigame
    
    -- Update details panel
    local details = uiState.menuElements.minigameDetails
    
    -- Update image
    details.image.Image = minigame.image or ""
    
    -- Update title
    details.title.Text = minigame.name
    
    -- Update difficulty
    details.difficulty.Text = "Difficulty: " .. (minigame.difficulty or "Unknown")
    details.difficulty.Parent.BackgroundColor3 = self:GetDifficultyColor(minigame.difficulty)
    
    -- Update description
    details.description.Text = minigame.description or "No description available."
    
    -- Update rewards
    details.currencyReward.Text = "$" .. tostring(minigame.rewards.currency)
    details.xpReward.Text = tostring(minigame.rewards.experience) .. " XP"
    
    -- Update highscore
    details.highscore.Text = "Your Highscore: " .. tostring(minigame.highscore or 0)
    
    -- Enable play button
    details.playButton.BackgroundColor3 = UIStyle.Colors.Success
    details.playButton.AutoButtonColor = true
end

-- Play the selected minigame
function MinigamesMenuUI:PlaySelectedMinigame()
    -- Check if a minigame is selected
    if not uiState.selectedMinigame then
        DialogFactory.createNotification("Please select a minigame first", 3, "warning")
        return
    end
    
    -- Show loading notification
    DialogFactory.createNotification("Loading " .. uiState.selectedMinigame.name .. "...", 2, "info")
    
    -- Start the minigame through MiniGameSystem
    if ReplicatedStorage:FindFirstChild("MiniGameSystem") and 
       ReplicatedStorage.MiniGameSystem:FindFirstChild("StartGame") then
        
        -- Call the remote function
        ReplicatedStorage.MiniGameSystem.StartGame:FireServer(uiState.selectedMinigame.id)
        
        -- Hide the menu
        self:HideMinigamesMenu()
    else
        -- Fallback for testing/development
        DialogFactory.createNotification(
            "Starting " .. uiState.selectedMinigame.name,
            3,
            "success"
        )
        
        task.wait(1)
        self:HideMinigamesMenu()
    end
end

-- Show the minigames menu
function MinigamesMenuUI:ShowMinigamesMenu()
    -- Create menu if it doesn't exist
    if not uiState.menuElements.mainFrame then
        self:CreateMinigamesMenu()
    end
    
    -- Make sure menu is created
    if not uiState.menuElements.mainFrame then
        warn("Failed to create minigames menu")
        return
    end
    
    -- Show the menu with animation
    local mainFrame = uiState.menuElements.mainFrame
    mainFrame.Visible = true
    mainFrame.BackgroundTransparency = 1
    mainFrame.Position = UDim2.new(0.5, -400, 0.6, -250)
    
    -- Fade in animation
    TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0,
            Position = UDim2.new(0.5, -400, 0.5, -250)
        }
    ):Play()
    
    -- Load minigames data
    task.spawn(function()
        self:LoadMinigames()
    end)
    
    -- Update state
    uiState.menuVisible = true
end

-- Hide the minigames menu
function MinigamesMenuUI:HideMinigamesMenu()
    -- If not visible, do nothing
    if not uiState.menuVisible or not uiState.menuElements.mainFrame then
        return
    end
    
    -- Hide the menu with animation
    local mainFrame = uiState.menuElements.mainFrame
    
    -- Fade out animation
    local tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -400, 0.4, -250)
        }
    )
    
    tween.Completed:Connect(function()
        mainFrame.Visible = false
    end)
    
    tween:Play()
    
    -- Update state
    uiState.menuVisible = false
end

-- Toggle the minigames menu
function MinigamesMenuUI:ToggleMinigamesMenu()
    if uiState.menuVisible then
        self:HideMinigamesMenu()
    else
        self:ShowMinigamesMenu()
    end
end

-- Initialize the module when required
return MinigamesMenuUI:Initialize()