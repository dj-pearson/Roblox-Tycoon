--[[
    MainMenuUI.client.luau
    
    Main Menu implementation that serves as the central hub for accessing all major game features.
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

-- Try to load UI Components first
local UIComponents = requireSafely(sharedFolder:FindFirstChild("UIComponents"))

-- Import UI modules with fallbacks
local UIStyle, IconSet, ButtonFactory, DialogFactory

if UIComponents then
    -- Use consolidated UI components if available
    UIStyle = UIComponents.UIStyle
    IconSet = UIComponents.IconSet
    ButtonFactory = UIComponents.ButtonFactory
    DialogFactory = UIComponents.DialogFactory
    print("MainMenuUI loaded UI components from UIComponents module")
else
    -- Legacy loading as fallback
    UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
    IconSet = requireSafely(sharedFolder:FindFirstChild("IconSet"))
    ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
    DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))
    
    -- Check if modules loaded correctly
    if not UIStyle then
        warn("UIStyle module not found, MainMenuUI will have limited functionality")
    end
    
    if not IconSet then
        warn("IconSet module not found, MainMenuUI will have limited functionality")
    end
    
    if not ButtonFactory then
        warn("ButtonFactory module not found, MainMenuUI will have limited functionality")
    end
    
    if not DialogFactory then
        warn("DialogFactory module not found, MainMenuUI will have limited functionality")
    end
end

-- Load other game modules
local AllianceUI = requireSafely(script.Parent:FindFirstChild("AllianceUI"))
local AdminControlsUI = requireSafely(script.Parent:FindFirstChild("AdminControlsUI"))
local AdminDashboardSystem = requireSafely(ReplicatedStorage:FindFirstChild("AdminDashboardSystem"))

-- Main Menu UI Module
local MainMenuUI = {}
MainMenuUI.__index = MainMenuUI

-- State tracking
local uiState = {
    isInitialized = false,
    menuVisible = true,
    menuElements = {}
}

-- Initialize the main menu
function MainMenuUI:Initialize()
    if uiState.isInitialized then
        return self
    end
    
    -- Create the main menu
    self:CreateMainMenu()
    
    uiState.isInitialized = true
    
    -- Show the main menu initially
    self:ShowMainMenu(true)
    
    return self
end

-- Create the main menu
function MainMenuUI:CreateMainMenu()
    -- Create the container GUI
    local screenGui = player:FindFirstChild("MainMenuGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MainMenuGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:FindFirstChild("PlayerGui")
    end
    
    -- Clear any existing UI elements to prevent duplication
    for _, child in ipairs(screenGui:GetChildren()) do
        child:Destroy()
    end
    
    -- Create background with tween-in effect
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = UIStyle and UIStyle.Colors and UIStyle.Colors.Background or Color3.fromRGB(10, 10, 20)
    background.BackgroundTransparency = 1.0  -- Start fully transparent (fix for dark haze issue)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Store for future reference
    uiState.menuElements.background = background
      -- Create logo/title at top
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0.4, 0, 0, 120)
    logoContainer.Position = UDim2.new(0.3, 0, 0, 0) -- Moved to top, horizontally centered
    logoContainer.BackgroundTransparency = 1
    logoContainer.Parent = background
    
    -- Check if the game logo already exists elsewhere and skip creating the title text if it does
    local existingLogo = false
    for _, child in pairs(background:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name == "GameLogo" then
            existingLogo = true
            break
        end
    end
    
    -- Only create title if no logo exists
    if not existingLogo then
        local gameTitle = Instance.new("TextLabel")
        gameTitle.Name = "GameTitle"
        gameTitle.Size = UDim2.new(1, 0, 1, 0)
        gameTitle.BackgroundTransparency = 1
        gameTitle.Font = UIStyle.Fonts.Title
        gameTitle.TextSize = 48 -- Slightly smaller
        gameTitle.TextColor3 = UIStyle.Colors.Text
        gameTitle.Text = "GYM TYCOON"
        gameTitle.Visible = false -- Hide title text to fix issue
        gameTitle.Parent = logoContainer
    end
    
    -- Create player profile section (top-left corner)
    local profileContainer = Instance.new("Frame")
    profileContainer.Name = "ProfileContainer"
    profileContainer.Size = UDim2.new(0, 250, 0, 100)
    profileContainer.Position = UDim2.new(0, 20, 0, 20)
    profileContainer.BackgroundColor3 = UIStyle.Colors.BackgroundLight
    profileContainer.BackgroundTransparency = 0.3
    profileContainer.BorderSizePixel = 0
    profileContainer.Parent = background
    
    -- Add rounded corners
    local profileCorner = Instance.new("UICorner")
    profileCorner.CornerRadius = UIStyle.Sizes.CornerRadius
    profileCorner.Parent = profileContainer
    
    -- Player name
    local playerName = Instance.new("TextLabel")
    playerName.Name = "PlayerName"
    playerName.Size = UDim2.new(1, -20, 0, 30)
    playerName.Position = UDim2.new(0, 50, 0, 10)
    playerName.BackgroundTransparency = 1
    playerName.Font = UIStyle.Fonts.Bold
    playerName.TextSize = UIStyle.TextSizes.Medium
    playerName.TextColor3 = UIStyle.Colors.Text
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.Text = player.DisplayName
    playerName.Parent = profileContainer
    
    -- Player level and resources
    local playerLevel = Instance.new("TextLabel")
    playerLevel.Name = "PlayerLevel"
    playerLevel.Size = UDim2.new(1, -20, 0, 25)
    playerLevel.Position = UDim2.new(0, 50, 0, 40)
    playerLevel.BackgroundTransparency = 1
    playerLevel.Font = UIStyle.Fonts.Regular
    playerLevel.TextSize = UIStyle.TextSizes.Medium
    playerLevel.TextColor3 = UIStyle.Colors.Text
    playerLevel.TextXAlignment = Enum.TextXAlignment.Left
    playerLevel.Text = "Level 10"
    playerLevel.Parent = profileContainer
    
    local playerMoney = Instance.new("TextLabel")
    playerMoney.Name = "PlayerMoney"
    playerMoney.Size = UDim2.new(1, -20, 0, 25)
    playerMoney.Position = UDim2.new(0, 50, 0, 65)
    playerMoney.BackgroundTransparency = 1
    playerMoney.Font = UIStyle.Fonts.Regular
    playerMoney.TextSize = UIStyle.TextSizes.Medium
    playerMoney.TextColor3 = UIStyle.Colors.Success
    playerMoney.TextXAlignment = Enum.TextXAlignment.Left
    playerMoney.Text = "$10,000"
    playerMoney.Parent = profileContainer
    
    -- Add player icon
    local playerIcon = IconSet.createIcon("User", UDim2.new(0, 30, 0, 30), UDim2.new(0, 10, 0, 10))
    playerIcon.Parent = profileContainer
    
    -- Add money icon
    local moneyIcon = IconSet.createIcon("Coin", UDim2.new(0, 20, 0, 20), UDim2.new(0, 20, 0, 67))
    moneyIcon.Parent = profileContainer
    
    -- Create main buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Name = "ButtonsContainer"
    buttonsContainer.Size = UDim2.new(0, 320, 0, 500)
    buttonsContainer.Position = UDim2.new(0.5, -160, 0.5, -100)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = background
    
    -- Create main menu buttons
    self:CreateMainButtons(buttonsContainer)
    
    --Create close button
    local closeButton = ButtonFactory.createStandardButton("Close", UDim2.fromScale(0.15,0.1), UDim2.new(0, 0, -0.1, 0),function()
        self:ToggleMenu()
    end)
    closeButton.Parent = background
      --Create Alliance Button
    local allianceButton = self:CreateAllianceButton(background, closeButton)
    uiState.menuElements.allianceButton = allianceButton
    
    -- Create Admin Button if the player is an admin
    if AdminDashboardSystem and AdminDashboardSystem.isAdmin and AdminDashboardSystem.isAdmin(player) then
        --Create Admin Button
        self:CreateAdminButton(background, closeButton)
    end

    -- Create social links at the bottom
    local socialContainer = Instance.new("Frame")
    socialContainer.Name = "SocialContainer"
    socialContainer.Size = UDim2.new(1, 0, 0, 40)
    socialContainer.Position = UDim2.new(0, 0, 1, -60)
    socialContainer.BackgroundTransparency = 1
    socialContainer.Parent = background
    
    local announcementText = Instance.new("TextLabel")
    announcementText.Name = "AnnouncementText"
    announcementText.Size = UDim2.new(1, 0, 1, 0)
    announcementText.BackgroundTransparency = 1
    announcementText.Font = UIStyle.Fonts.Italic
    announcementText.TextSize = UIStyle.TextSizes.Medium
    announcementText.TextColor3 = UIStyle.Colors.TextSecondary
    announcementText.Text = "Welcome to Gym Tycoon! New seasonal event coming soon!"
    announcementText.Parent = socialContainer
    
    -- Store UI elements for later access
    uiState.menuElements.screenGui = screenGui
    uiState.menuElements.background = background
    
    return screenGui
end

function MainMenuUI:CreateAdminButton(parent, closeButton)
        local AdminButton = Instance.new("TextButton")
    AdminButton.Name = "AdminButton"
    AdminButton.Size = UDim2.fromScale(0.15, 0.1)
    AdminButton.Position = UDim2.new(0, closeButton.Position.X.Offset, 0, closeButton.Position.Y.Offset + closeButton.Size.Y.Offset + 110)
    AdminButton.Text = "Admin"
    AdminButton.TextColor3 = UIStyle.Colors.Text
    AdminButton.BackgroundColor3 = UIStyle.Colors.Button
    AdminButton.Parent = parent
    AdminButton.MouseButton1Click:Connect(function()
        AdminControlsUI.showAdminDashboard()
    end)
end

function MainMenuUI:CreateAllianceButton(parent,closeButton)
    local allianceButton = Instance.new("TextButton")
    allianceButton.Name = "AllianceButton"
    allianceButton.Size = UDim2.fromScale(0.15,0.1)
    allianceButton.Position = UDim2.new(0, closeButton.Position.X.Offset, 0, closeButton.Position.Y.Offset + closeButton.Size.Y.Offset + 10)
    allianceButton.Text = "Alliance"
    allianceButton.TextColor3 = UIStyle.Colors.Text
    allianceButton.BackgroundColor3 = UIStyle.Colors.Button
    allianceButton.Parent = parent
    allianceButton.MouseButton1Click:Connect(function()
        AllianceUI.showAllianceMenu()
    end)
    
    return allianceButton
end

-- Create the main buttons of the menu
function MainMenuUI:CreateMainButtons(parent)
    local buttonHeight = 70
    local buttonSpacing = 15
    local yOffset = 0
    
    -- Create play button
    local playButton = ButtonFactory.createFeatureButton("Play", UDim2.new(1, 0, 0, buttonHeight), UDim2.new(0, 0, 0, yOffset), function()
        -- Connect to GameSystem.startGame()
        self:ConnectToBackend("GameSystem", "StartGame", function()
            DialogFactory.createNotification("Starting game...", 2, "info")
            -- Hide main menu after slight delay to allow transition
            task.delay(0.5, function()
                self:ShowMainMenu(false)
            end)
        end)
    end)
    playButton.Parent = parent
    
    yOffset = yOffset + buttonHeight + buttonSpacing
    
    -- Create specialization button
    local specializationButton = ButtonFactory.createFeatureButton("Specialization", UDim2.new(1, 0, 0, buttonHeight), UDim2.new(0, 0, 0, yOffset), function()
        -- Connect to SpecializationSystem
        self:ConnectToBackend("SpecializationSystem", "OpenSpecializationMenu", function()
            DialogFactory.createNotification("Opening Specialization menu...", 2, "info")
            -- This would normally open the SpecializationUI
        end)
    end)
    specializationButton.Parent = parent
    
    yOffset = yOffset + buttonHeight + buttonSpacing
    
    -- Create seasonal events button
    local eventsButton = ButtonFactory.createFeatureButton("SeasonalEvents", UDim2.new(1, 0, 0, buttonHeight), UDim2.new(0, 0, 0, yOffset), function()
        -- Connect to SeasonalSystem
        self:ConnectToBackend("SeasonalSystem", "GetAvailableSeasons", function()
            DialogFactory.createNotification("Opening Seasonal Events menu...", 2, "info")
            -- This would normally open the SeasonalEventsUI
        end)
    end)
    eventsButton.Parent = parent
    
    yOffset = yOffset + buttonHeight + buttonSpacing
    
    -- Create minigames button
    local minigamesButton = ButtonFactory.createFeatureButton("Minigames", UDim2.new(1, 0, 0, buttonHeight), UDim2.new(0, 0, 0, yOffset), function()
        -- Connect to MiniGameSystem
        self:ConnectToBackend("MiniGameSystem", "GetAvailableGames", function()
            DialogFactory.createNotification("Opening Minigames menu...", 2, "info")
            -- This would normally open the MinigamesUI
        end)
    end)
    minigamesButton.Parent = parent
    
    yOffset = yOffset + buttonHeight + buttonSpacing
    
    -- Create settings button
    local settingsButton = ButtonFactory.createFeatureButton("Settings", UDim2.new(1, 0, 0, buttonHeight), UDim2.new(0, 0, 0, yOffset), function()
        DialogFactory.createNotification("Opening Settings menu...", 2, "info")
        -- This would normally open the SettingsUI
    end)
    settingsButton.Parent = parent
      -- Store buttons for later reference
    uiState.menuElements.playButton = playButton
    -- Alliance button is stored when it's created
    uiState.menuElements.specializationButton = specializationButton
    uiState.menuElements.eventsButton = eventsButton
    uiState.menuElements.minigamesButton = minigamesButton
    uiState.menuElements.settingsButton = settingsButton
end

-- Helper to connect to backend systems
function MainMenuUI:ConnectToBackend(systemName, eventName, callback)
    local success = false
    
    if ReplicatedStorage:FindFirstChild(systemName) then
        local system = ReplicatedStorage[systemName]
        
        if system:FindFirstChild(eventName) then
            success = true
            system[eventName]:FireServer()
            
            if callback and typeof(callback) == "function" then
                callback()
            end
        else
            warn(systemName .. "." .. eventName .. " not found")
            DialogFactory.createNotification("This feature is not available yet", 3, "warning")
        end
    else
        warn(systemName .. " not found")
        DialogFactory.createNotification("This feature is not available yet", 3, "warning")
    end
    
    -- If not successful, still call callback for demo purposes
    if not success and callback and typeof(callback) == "function" then
        callback()
    end
    
    return success
end

-- Show/hide main menu with animation
function MainMenuUI:ShowMainMenu(visible)
    local background = uiState.menuElements.background
    if not background then 
        warn("MainMenuUI:ShowMainMenu - Background element not found, trying to recreate menu")
        self:CreateMainMenu()
        background = uiState.menuElements.background
        if not background then
            warn("MainMenuUI:ShowMainMenu - Failed to recreate menu")
            return false
        end
    end
    
    -- Set visibility state
    uiState.menuVisible = visible
    
    local playerGui = player:FindFirstChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("MainMenuGui")
    if not screenGui then
        warn("MainMenuUI:ShowMainMenu - Screen GUI not found")
        return false
    end
    
    -- Ensure the ScreenGui is visible
    screenGui.Enabled = true
    
    -- Safely get animation info
    local animationInfo = (UIStyle and UIStyle.Animations and UIStyle.Animations.Standard) or 
                          TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    if visible then
        -- Show menu with animation
        background.Visible = true
        background.BackgroundTransparency = 1
        
        -- Fade in background
        local backgroundTween = TweenService:Create(
            background, 
            animationInfo, 
            { BackgroundTransparency = 0.2 }
        )
        backgroundTween:Play()
        
        -- Animate in buttons
        for i, buttonName in ipairs({"playButton", "allianceButton", "specializationButton", "eventsButton", "minigamesButton", "settingsButton"}) do
            local button = uiState.menuElements[buttonName]
            if button then
                button.Position = UDim2.new(-1, 0, button.Position.Y.Scale, button.Position.Y.Offset)
                button.Visible = true
                  -- Stagger button animations
                TweenService:Create(
                    button,
                    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1 * (i - 1)),
                    { Position = UDim2.new(0, 0, button.Position.Y.Scale, button.Position.Y.Offset) }
                ):Play()
            end
        end
        
        -- Make sure the Emergency UI is not visible
        if playerGui:FindFirstChild("EmergencyUI") then
            playerGui.EmergencyUI.Enabled = false
        end
        
        return true
    else
        -- Hide menu with animation
        local animationInfo = (UIStyle and UIStyle.Animations and UIStyle.Animations.Standard) or 
                              TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        local hideAnim = TweenService:Create(
            background, 
            animationInfo, 
            { BackgroundTransparency = 1 }
        )
        
        -- When tween completes, make sure the UI is invisible
        hideAnim.Completed:Connect(function()
            if not uiState.menuVisible and background then
                background.Visible = false
            end
        end)
        
        hideAnim:Play()
        
        -- Animate out buttons
        for i, buttonName in ipairs({"playButton", "allianceButton", "specializationButton", "eventsButton", "minigamesButton", "settingsButton"}) do
            local button = uiState.menuElements[buttonName]
            if button then
                -- Stagger button animations
                TweenService:Create(
                    button,
                    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0.05 * (i - 1)),
                    { Position = UDim2.new(1, 0, button.Position.Y.Scale, button.Position.Y.Offset) }
                ):Play()
            end
        end
        
        -- Hide background after animation
        task.delay(UIStyle.Animations.Standard.Time, function()
            if not uiState.menuVisible then
                background.Visible = false
            end
        end)
    end
end

-- Update player profile information
function MainMenuUI:UpdatePlayerProfile()
    -- This would normally connect to PlayerDataManager to get current player data
    -- For now, we'll simulate it with placeholder values
    
    local playerName = uiState.menuElements.background:FindFirstChild("ProfileContainer"):FindFirstChild("PlayerName")
    local playerLevel = uiState.menuElements.background:FindFirstChild("ProfileContainer"):FindFirstChild("PlayerLevel")
    local playerMoney = uiState.menuElements.background:FindFirstChild("ProfileContainer"):FindFirstChild("PlayerMoney")
    
    if playerName then
        playerName.Text = player.DisplayName
    end
    
    if playerLevel then
        playerLevel.Text = "Level 10"  -- Would normally get from PlayerDataManager
    end
    
    if playerMoney then
        playerMoney.Text = "$10,000"   -- Would normally get from PlayerDataManager
    end
end

-- Toggle main menu visibility
function MainMenuUI:ToggleMenu()
    self:ShowMainMenu(not uiState.menuVisible)
end

-- Force cleanup of any lingering UI elements
function MainMenuUI:CleanupUI()
    -- Set state to not visible
    uiState.menuVisible = false
    
    -- Clean up any existing background elements
    if uiState.menuElements.background then
        uiState.menuElements.background.BackgroundTransparency = 1
        uiState.menuElements.background.Visible = false
    end
    
    -- Check for orphaned backgrounds - this fixes the dark haze issue
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            -- Look for our MainMenuGui
            if gui.Name == "MainMenuGui" or gui.Name == "MainMenuBG" then
                for _, child in ipairs(gui:GetChildren()) do
                    if child:IsA("Frame") and child.Size == UDim2.new(1, 0, 1, 0) then
                        -- Found a full-screen frame, likely our background causing the dark haze
                        child.BackgroundTransparency = 1
                        child.Visible = false
                    end
                end
            end
        end
    end
    
    return true
end

-- Expose cleanup function globally for easy access from console
_G.CleanMainMenuUI = function()
    return MainMenuUI:CleanupUI()
end

-- Initialize the module when required
local instance = MainMenuUI:Initialize()

-- Immediately cleanup any existing UI to fix the dark haze issue
task.spawn(function()
    -- Clean up UI elements
    MainMenuUI:CleanupUI()
    
    -- Make sure the background is fixed in case there are errors elsewhere
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name == "MainMenuGui" then
                for _, element in pairs(gui:GetDescendants()) do
                    if element:IsA("Frame") and element.Size == UDim2.new(1, 0, 1, 0) then
                        -- Ensure any full-screen frames are totally transparent
                        element.BackgroundTransparency = 1
                        task.delay(0.5, function()
                            element.Visible = false
                        end)
                        print("Fixed MainMenuUI frame transparency")
                    end
                end
            end
        end
    end
end)

-- Ensure Background is transparent
if uiState.menuElements.background then
    uiState.menuElements.background.BackgroundTransparency = 1
    task.delay(0.5, function()
        if not uiState.menuVisible then
            uiState.menuElements.background.Visible = false
        end
    end)
end

return instance